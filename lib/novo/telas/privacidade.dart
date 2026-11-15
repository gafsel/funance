import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dados/provedores.dart';
import '../regras/formatos.dart';
import '../regras/trava.dart';
import '../tema/tema_novo.dart';
import '../trava/biometria.dart';
import 'pecas.dart';

/// Privacidade neste aparelho: o "olho" que esconde os valores e a trava
/// que pede a biometria para abrir o app. As duas coisas ficam guardadas no
/// aparelho, não na conta.

const _chaveDoOlho = 'novo.valoresOcultos';
String _chaveDaTrava(String uid) => 'novo.trava.$uid';

/// Os valores em reais estão escondidos?
final valoresOcultosProvider = StateProvider<bool>((ref) => false);

/// A credencial de biometria deste aparelho para quem está logado; nula
/// quando a trava está desligada.
final credencialDaTravaProvider = StateProvider<String?>((ref) => null);

/// Os valores são formatados por uma função sem contexto (`reais`), então
/// nada na árvore "sabe" que precisa se redesenhar quando o olho muda. Isto
/// manda redesenhar tudo, uma vez.
void _redesenharTudo() {
  void visitar(Element e) {
    e.markNeedsBuild();
    e.visitChildren(visitar);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visitar);
}

Future<void> definirValoresOcultos(WidgetRef ref, bool ocultos) async {
  valoresOcultos = ocultos;
  ref.read(valoresOcultosProvider.notifier).state = ocultos;
  _redesenharTudo();
  await (await SharedPreferences.getInstance()).setBool(_chaveDoOlho, ocultos);
}

/// O olho do topo: mostra ou esconde os valores em reais do app inteiro.
class BotaoDoOlho extends ConsumerWidget {
  const BotaoDoOlho({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocultos = ref.watch(valoresOcultosProvider);
    return IconButton(
      tooltip: ocultos ? 'Mostrar valores' : 'Esconder valores',
      visualDensity: VisualDensity.compact,
      onPressed: () => definirValoresOcultos(ref, !ocultos),
      icon: Icon(
        ocultos ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 21,
        color: Cores.de(context).tinta2,
      ),
    );
  }
}

/// Liga ou desliga, em "Você", a biometria para abrir o app neste aparelho.
class ItemDaTrava extends ConsumerStatefulWidget {
  const ItemDaTrava({super.key});

  @override
  ConsumerState<ItemDaTrava> createState() => _ItemDaTravaState();
}

class _ItemDaTravaState extends ConsumerState<ItemDaTrava> {
  bool? _disponivel;
  bool _mexendo = false;
  String? _aviso;

  @override
  void initState() {
    super.initState();
    biometriaDisponivel().then((d) {
      if (mounted) setState(() => _disponivel = d);
    });
  }

  Future<void> _alternar(bool ligar) async {
    final usuario = ref.read(authProvider).valueOrNull;
    if (usuario == null) return;
    setState(() {
      _mexendo = true;
      _aviso = null;
    });
    final prefs = await SharedPreferences.getInstance();
    if (ligar) {
      final credencial = await cadastrarBiometria(usuario.email ?? usuario.displayName ?? 'Funances');
      if (credencial == null) {
        if (mounted) setState(() => _aviso = 'Não deu para cadastrar a biometria. Tente de novo.');
      } else {
        await prefs.setString(_chaveDaTrava(usuario.uid), credencial);
        ref.read(credencialDaTravaProvider.notifier).state = credencial;
      }
    } else {
      await prefs.remove(_chaveDaTrava(usuario.uid));
      ref.read(credencialDaTravaProvider.notifier).state = null;
    }
    if (mounted) setState(() => _mexendo = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final ligada = ref.watch(credencialDaTravaProvider) != null;
    return SwitchListTile(
      dense: true,
      title: Text('Pedir biometria para abrir', style: t.titleSmall),
      subtitle: Text(
        _aviso ??
            switch (_disponivel) {
              null => 'Conferindo este aparelho…',
              false => 'Este aparelho ou navegador não tem digital nem reconhecimento de rosto disponível.',
              true => ligada
                  ? 'Ligada neste aparelho: ao abrir e ao voltar depois de 5 minutos.'
                  : 'Digital ou rosto ao abrir o app e ao voltar depois de 5 minutos. Vale só neste aparelho.',
            },
        style: t.bodySmall,
      ),
      value: ligada,
      onChanged: _disponivel != true || _mexendo ? null : _alternar,
    );
  }
}

/// Fica em volta do app inteiro. Recupera o olho e a trava guardados no
/// aparelho e, com a trava ligada, cobre tudo até a biometria ser aceita:
/// ao abrir e ao voltar depois de [tempoForaParaTravar].
class Trava extends ConsumerStatefulWidget {
  const Trava({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<Trava> createState() => _TravaState();
}

class _TravaState extends ConsumerState<Trava> with WidgetsBindingObserver {
  /// Ainda não se sabe se há trava para quem está entrando.
  bool _decidindo = true;
  bool _travado = false;
  bool _verificando = false;
  DateTime? _saiuEm;

  /// Para quem a decisão foi pedida por último (e se já foi pedida alguma).
  String? _uid;
  bool _pediu = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SharedPreferences.getInstance().then((prefs) {
      if (prefs.getBool(_chaveDoOlho) ?? false) {
        valoresOcultos = true;
        if (mounted) ref.read(valoresOcultosProvider.notifier).state = true;
        _redesenharTudo();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Quem está logado mudou: vê se há trava para essa pessoa neste aparelho.
  Future<void> _decidir(String? uid) async {
    String? credencial;
    if (uid != null) {
      final guardada = (await SharedPreferences.getInstance()).getString(_chaveDaTrava(uid));
      // Sem biometria disponível agora, entra direto.
      if (guardada != null && await biometriaDisponivel()) credencial = guardada;
    }
    if (!mounted || _uid != uid) return;
    ref.read(credencialDaTravaProvider.notifier).state = credencial;
    setState(() {
      _decidindo = false;
      _travado = credencial != null;
    });
    if (credencial != null) await _destravar();
  }

  Future<void> _destravar() async {
    final credencial = ref.read(credencialDaTravaProvider);
    if (credencial == null || _verificando) return;
    setState(() => _verificando = true);
    final ok = await verificarBiometria(credencial);
    if (!mounted) return;
    setState(() {
      _verificando = false;
      if (ok) _travado = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _saiuEm ??= DateTime.now();
      return;
    }
    final travar = deveTravarAoVoltar(
      travaLigada: ref.read(credencialDaTravaProvider) != null,
      saiuEm: _saiuEm,
      agora: DateTime.now(),
    );
    _saiuEm = null;
    if (travar && !_travado) {
      setState(() => _travado = true);
      _destravar();
    }
  }

  @override
  Widget build(BuildContext context) {
    // A cada mudança de quem está logado, decide de novo se há trava.
    final sessao = ref.watch(authProvider);
    if (!sessao.isLoading) {
      final uid = sessao.valueOrNull?.uid;
      if (!_pediu || uid != _uid) {
        _pediu = true;
        _uid = uid;
        // Alguém entrou: cobre o app até saber se essa pessoa tem trava.
        if (uid != null) _decidindo = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _decidir(uid));
      }
    }

    if (_decidindo) return const TelaDeAbertura();
    if (!_travado) return widget.child;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Marca(tamanho: 72),
            const SizedBox(height: Espacos.g),
            Text('funances', style: Textos.marca(context, tamanho: 24)),
            const SizedBox(height: Espacos.xg),
            Text('Use a sua digital ou o rosto para abrir.', textAlign: TextAlign.center, style: t.bodyMedium),
            const SizedBox(height: Espacos.g),
            FilledButton.icon(
              onPressed: _verificando ? null : _destravar,
              icon: const Icon(Icons.fingerprint_rounded),
              label: Text(_verificando ? 'Aguardando…' : 'Desbloquear'),
            ),
            const SizedBox(height: Espacos.p),
            TextButton(
              onPressed: () async {
                await sair();
                if (mounted) setState(() => _travado = false);
              },
              child: const Text('Sair da conta'),
            ),
          ]),
        ),
      ),
    );
  }
}
