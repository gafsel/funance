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

  static const _abas = [
    (Icons.home_outlined, Icons.home_rounded, 'Início'),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Lançamentos'),
    (Icons.inbox_outlined, Icons.inbox_rounded, 'Entrada'),
    (Icons.flag_outlined, Icons.flag_rounded, 'Metas'),
    (Icons.more_horiz_rounded, Icons.more_horiz_rounded, 'Mais'),
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

    final corpo = IndexedStack(
      index: _aba,
      children: const [TelaInicio(), TelaLancamentos(), TelaEntrada(), TelaMetas(), TelaMais()],
    );
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
              selectedIndex: _aba,
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
                for (final (icone, ativo, rotulo) in _abas)
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
        selectedIndex: _aba,
        onDestinationSelected: (i) => setState(() => _aba = i),
        destinations: [
          for (final (icone, ativo, rotulo) in _abas)
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
