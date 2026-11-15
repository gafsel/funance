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
        'network-request-failed' => 'Sem conexão com o servidor. Confira a internet e tente de novo.',
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
    final c = Cores.de(context);
    final mesa = ehMesa(context);

    final formulario = AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Entrar', style: texto.titleLarge),
          const SizedBox(height: 2),
          Text('Use a mesma conta do Funances que você já tem.', style: texto.bodyMedium?.copyWith(fontSize: 13, color: c.tinta2)),
          const SizedBox(height: Espacos.xg),
          OutlinedButton(
            onPressed: _ocupado ? null : _comGoogle,
            style: OutlinedButton.styleFrom(backgroundColor: c.superficie, minimumSize: const Size(0, 46)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo/google.png', width: 18, height: 18),
                const SizedBox(width: 10),
                const Text('Entrar com Google'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Espacos.g),
            child: Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('ou com e-mail', style: texto.bodySmall),
              ),
              const Expanded(child: Divider()),
            ]),
          ),
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
            Cartao(
              cor: c.problemaSuave,
              semBorda: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(_erro!, style: texto.bodyMedium?.copyWith(fontSize: 13, color: c.problema)),
            ),
          ],
          const SizedBox(height: Espacos.g),
          FilledButton(
            onPressed: _ocupado ? null : _comSenha,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
            child: Text(_ocupado ? 'Entrando…' : 'Entrar'),
          ),
        ],
      ),
    );

    Widget ponto(IconData icone, String titulo, String corpo) => Padding(
          padding: const EdgeInsets.only(top: Espacos.g),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: c.superficie, borderRadius: Raios.m),
                child: Icon(icone, size: 18, color: c.primaria),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: texto.titleSmall),
                    Text(corpo, style: texto.bodyMedium?.copyWith(fontSize: 13, color: c.tinta2)),
                  ],
                ),
              ),
            ],
          ),
        );

    final apresentacao = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [const Marca(tamanho: 36), const SizedBox(width: 10), Text('funances', style: Textos.marca(context, tamanho: 26))]),
        const SizedBox(height: Espacos.xg),
        Text('Suas metas,\num passo por vez.', style: texto.headlineMedium?.copyWith(fontSize: mesa ? 34 : 26, height: 1.12)),
        const SizedBox(height: Espacos.p),
        Text(
          'Saiba quanto ainda dá para gastar no mês, sem perder de vista o que você quer alcançar.',
          style: texto.bodyLarge?.copyWith(color: c.tinta2),
        ),
        if (mesa) ...[
          const SizedBox(height: Espacos.p),
          ponto(Icons.edit_note_rounded, 'Lance escrevendo', '"mercado 45 no cartão" e pronto. Vários de uma vez, se quiser.'),
          ponto(Icons.flag_outlined, 'Um caminho em ordem', 'O app mostra o próximo passo, do primeiro mês organizado até as metas.'),
          ponto(Icons.fact_check_outlined, 'Contas que batem', 'Confira cada conta com o extrato e feche o mês com segurança.'),
        ],
      ],
    );

    if (mesa) {
      return Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 11,
              child: Container(
                color: c.primariaSuave,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(48),
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: apresentacao),
              ),
            ),
            Expanded(
              flex: 9,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360), child: formulario),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Espacos.xg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  apresentacao,
                  const SizedBox(height: Espacos.xxg),
                  Cartao(padding: const EdgeInsets.all(Espacos.xg), child: formulario),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
