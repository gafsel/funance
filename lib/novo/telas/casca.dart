import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/provedores.dart';
import '../tema/tema_novo.dart';
import 'entrada.dart';
import 'inicio.dart';
import 'lancamentos.dart';
import 'lancar.dart';
import 'mais.dart';
import 'metas.dart';
import 'comeco.dart';
import 'empresa.dart';
import 'pecas.dart';

/// Navegação do app: barra embaixo no celular, trilho ao lado na mesa. O
/// botão de lançar está sempre a um toque.
class Casca extends ConsumerStatefulWidget {
  const Casca({super.key});

  @override
  ConsumerState<Casca> createState() => _CascaState();
}

class _CascaState extends ConsumerState<Casca> {
  int _aba = 0;

  static const _abasBase = [
    (Icons.home_outlined, Icons.home_rounded, 'Início', TelaInicio()),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Lançamentos', TelaLancamentos()),
    (Icons.inbox_outlined, Icons.inbox_rounded, 'Entrada', TelaEntrada()),
    (Icons.storefront_outlined, Icons.storefront_rounded, 'Empresa', TelaEmpresa()),
    (Icons.flag_outlined, Icons.flag_rounded, 'Metas', TelaMetas()),
    (Icons.more_horiz_rounded, Icons.more_horiz_rounded, 'Mais', TelaMais()),
  ];

  @override
  void initState() {
    super.initState();
    espacoLembrado().then((id) {
      if (id != null && mounted && ref.read(espacoEscolhidoProvider) == null) {
        ref.read(espacoEscolhidoProvider.notifier).state = id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final espacos = ref.watch(espacosProvider);
    final espaco = ref.watch(espacoAtualProvider);
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final pendentes = ref.watch(entradaProvider).valueOrNull?.length ?? 0;

    if (espacos.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (espaco == null && !espacos.hasError) return const TelaComeco();
    if (espaco == null) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: const Vazio(
              'Não foi possível carregar os seus espaços. Confira a conexão e abra de novo.',
              acao: _BotaoSair(),
            ),
          ),
        ),
      );
    }

    // A aba Empresa só existe em espaço de empresa.
    final abas = [
      for (final aba in _abasBase)
        if (aba.$3 != 'Empresa' || espaco.ehEmpresa) aba,
    ];
    final indice = _aba.clamp(0, abas.length - 1);
    final corpo = IndexedStack(index: indice, children: [for (final aba in abas) aba.$4]);
    final titulo = Row(
      children: [
        const Marca(),
        const SizedBox(width: Espacos.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(espaco.nome, style: texto.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(espaco.ehEmpresa ? 'Empresa' : 'Pessoal', style: texto.bodySmall),
            ],
          ),
        ),
      ],
    );

    if (ehMesa(context)) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: MediaQuery.sizeOf(context).width >= 1200,
              selectedIndex: indice,
              onDestinationSelected: (i) => setState(() => _aba = i),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: Espacos.g),
                child: FloatingActionButton.extended(
                  elevation: 0,
                  backgroundColor: c.calor,
                  foregroundColor: c.sobreCalor,
                  onPressed: () => abrirLancar(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Lançar'),
                ),
              ),
              destinations: [
                for (final (icone, ativo, rotulo, _) in abas)
                  NavigationRailDestination(
                    icon: _comContagem(Icon(icone), rotulo == 'Entrada' ? pendentes : 0),
                    selectedIcon: _comContagem(Icon(ativo), rotulo == 'Entrada' ? pendentes : 0),
                    label: Text(rotulo),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  Padding(padding: const EdgeInsets.fromLTRB(Espacos.xg, Espacos.g, Espacos.xg, 0), child: titulo),
                  Expanded(child: corpo),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: titulo,
        backgroundColor: c.fundo,
        surfaceTintColor: c.fundo,
        titleSpacing: Espacos.g,
      ),
      body: corpo,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.calor,
        foregroundColor: c.sobreCalor,
        onPressed: () => abrirLancar(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Lançar'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indice,
        onDestinationSelected: (i) => setState(() => _aba = i),
        destinations: [
          for (final (icone, ativo, rotulo, _) in abas)
            NavigationDestination(
              icon: _comContagem(Icon(icone), rotulo == 'Entrada' ? pendentes : 0),
              selectedIcon: _comContagem(Icon(ativo), rotulo == 'Entrada' ? pendentes : 0),
              label: rotulo,
            ),
        ],
      ),
    );
  }
}

Widget _comContagem(Widget icone, int n) =>
    n == 0 ? icone : Badge(label: Text(n > 99 ? '99+' : '$n'), child: icone);

class _BotaoSair extends ConsumerWidget {
  const _BotaoSair();

  @override
  Widget build(BuildContext context, WidgetRef ref) => OutlinedButton(
        onPressed: () => sair(),
        child: const Text('Sair'),
      );
}
