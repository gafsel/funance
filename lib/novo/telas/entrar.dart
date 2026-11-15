import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../tema/tema_novo.dart';
import 'pecas.dart';

class TelaEntrar extends StatefulWidget {
  const TelaEntrar({super.key});

  @override
  State<TelaEntrar> createState() => _TelaEntrarState();
}

class _TelaEntrarState extends State<TelaEntrar> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  String? _erro;
  bool _ocupado = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _tentar(Future<void> Function() acao) async {
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    try {
      await acao();
    } on FirebaseAuthException catch (e) {
      setState(() => _erro = _mensagem(e.code));
    } catch (_) {
      setState(() => _erro = 'Não foi possível entrar agora. Tente de novo.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  String _mensagem(String codigo) => switch (codigo) {
        'invalid-credential' || 'wrong-password' || 'user-not-found' => 'E-mail ou senha não conferem.',
        'invalid-email' => 'Esse e-mail não parece válido.',
        'too-many-requests' => 'Muitas tentativas. Espere um pouco e tente de novo.',
        'operation-not-allowed' => 'Essa forma de entrar ainda não está ligada neste ambiente.',
        'popup-closed-by-user' || 'cancelled-popup-request' => 'A janela do Google foi fechada antes de terminar.',
        _ => 'Não foi possível entrar agora. Tente de novo.',
      };

  Future<void> _comSenha() => _tentar(() => FirebaseAuth.instance
      .signInWithEmailAndPassword(email: _email.text.trim(), password: _senha.text));

  Future<void> _comGoogle() => _tentar(() async {
        final provedor = GoogleAuthProvider()..addScope('email');
        if (kIsWeb) {
          await FirebaseAuth.instance.signInWithPopup(provedor);
        } else {
          await FirebaseAuth.instance.signInWithProvider(provedor);
        }
      });

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Espacos.xg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(alignment: Alignment.centerLeft, child: Marca(tamanho: 44)),
                  const SizedBox(height: Espacos.g),
                  Text('Funances', style: texto.headlineMedium),
                  Text('Suas metas, um passo por vez.', style: texto.bodyLarge),
                  const SizedBox(height: Espacos.xxg),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                  ),
                  const SizedBox(height: Espacos.m),
                  TextField(
                    controller: _senha,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _comSenha(),
                    decoration: const InputDecoration(labelText: 'Senha'),
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: Espacos.m),
                    Text(_erro!, style: texto.bodyMedium?.copyWith(color: Cores.de(context).problema)),
                  ],
                  const SizedBox(height: Espacos.g),
                  FilledButton(onPressed: _ocupado ? null : _comSenha, child: const Text('Entrar')),
                  const SizedBox(height: Espacos.m),
                  OutlinedButton(
                    onPressed: _ocupado ? null : _comGoogle,
                    child: const Text('Entrar com Google'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
