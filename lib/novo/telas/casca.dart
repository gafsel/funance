import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../tema/tema_novo.dart';
import 'avisos.dart';
import 'comeco.dart';
import 'empresa.dart';
import 'fechamento.dart';
import 'formulario.dart';
import 'inicio.dart';
import 'lancamentos.dart';
import 'lancar.dart';
import 'mais.dart';
import 'metas.dart';
import 'pecas.dart';
import 'relatorios.dart';

/// Seção em exibição. Fica num provedor para que qualquer tela possa levar
/// a pessoa a outra ("Ver o caminho inteiro").
enum Secao { inicio, lancamentos, empresa, metas, relatorios, fechamento, mais }

final secaoProvider = StateProvider<Secao>((ref) => Secao.inicio);

const _rotulos = {
  Secao.inicio: 'Início',
  Secao.lancamentos: 'Lançamentos',
  Secao.empresa: 'Empresa',
  Secao.metas: 'Metas e caminho',
  Secao.relatorios: 'Relatórios',
  Secao.fechamento: 'Fechamento',
  Secao.mais: 'Contas e cadastros',
};

/// Casca do app: barra do topo com a marca e o espaço; na mesa, menu ao
/// lado; no celular, barra embaixo com o botão de lançar no centro.
class Casca extends ConsumerStatefulWidget {
  const Casca({super.key});

  @override
  ConsumerState<Casca> createState() => _CascaState();
}

class _CascaState extends ConsumerState<Casca> {
  @override
  void initState() {
    super.initState();
    espacoLembrado().then((id) {
      if (id != null && mounted && ref.read(espacoEscolhidoProvider) == null) {
        ref.read(espacoEscolhidoProvider.notifier).state = id;
      }
    });
  }

  Widget _tela(Secao secao) => switch (secao) {
        Secao.inicio => const TelaInicio(),
        Secao.lancamentos => const TelaLancamentos(),
        Secao.empresa => const TelaEmpresa(),
        Secao.metas => const TelaMetas(),
        Secao.relatorios => const TelaRelatorios(),
        Secao.fechamento => const TelaFechamento(embutida: true),
        Secao.mais => const TelaMais(),
      };

  @override
  Widget build(BuildContext context) {
    final espacos = ref.watch(espacosProvider);
    final espaco = ref.watch(espacoAtualProvider);
    final c = Cores.de(context);

    if (espacos.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (espaco == null && !espacos.hasError) return const TelaComeco();
    if (espaco == null) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Vazio(
              'Não foi possível carregar os seus espaços. Confira a conexão e abra de novo.',
              acao: OutlinedButton(onPressed: sair, child: const Text('Sair')),
            ),
          ),
        ),
      );
    }

    final mesa = ehMesa(context);
    final pendentes = ref.watch(entradaProvider).valueOrNull?.length ?? 0;
    var secao = ref.watch(secaoProvider);
    if (secao == Secao.empresa && !espaco.ehEmpresa) secao = Secao.inicio;
    // No celular, Fechamento e Empresa moram dentro de "Mais".
    final secaoDoCelular = switch (secao) {
      Secao.fechamento || Secao.empresa || Secao.relatorios => Secao.mais,
      _ => secao,
    };
    void ir(Secao s) => ref.read(secaoProvider.notifier).state = s;

    final barra = _BarraDoTopo(espaco: espaco);

    if (mesa) {
      final itens = [
        Secao.inicio,
        Secao.lancamentos,
        if (espaco.ehEmpresa) Secao.empresa,
        Secao.metas,
        Secao.relatorios,
        Secao.fechamento,
        Secao.mais,
      ];
      return Scaffold(
        body: Column(
          children: [
            barra,
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 208,
                    decoration: BoxDecoration(color: c.superficie, border: Border(right: BorderSide(color: c.linha))),
                    padding: const EdgeInsets.all(Espacos.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: () => abrirLancar(context),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Lançar'),
                        ),
                        const SizedBox(height: Espacos.m),
                        for (final s in itens)
                          _ItemDoMenu(
                            rotulo: _rotulos[s]!,
                            ativo: s == secao,
                            contagem: s == Secao.lancamentos ? pendentes : 0,
                            aoTocar: () => ir(s),
                          ),
                      ],
                    ),
                  ),
                  Expanded(child: _tela(secao)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [barra, Expanded(child: _tela(secaoDoCelular))]),
      ),
      bottomNavigationBar: _BarraDeBaixo(
        secao: secaoDoCelular,
        pendentes: pendentes,
        aoTocar: ir,
        aoLancar: () => abrirLancar(context),
      ),
    );
  }
}

class _BarraDoTopo extends ConsumerWidget {
  const _BarraDoTopo({required this.espaco});
  final Espaco espaco;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: Espacos.g),
      decoration: BoxDecoration(color: c.superficie, border: Border(bottom: BorderSide(color: c.linha))),
      child: Row(
        children: [
          const Marca(),
          const SizedBox(width: 8),
          Text('funances', style: Textos.marca(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Material(
              color: c.suave,
              borderRadius: Raios.pilula,
              child: InkWell(
                borderRadius: Raios.pilula,
                onTap: () => _trocarEspaco(context, ref),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(espaco.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.labelLarge),
                      ),
                      const SizedBox(width: 6),
                      Text(espaco.ehEmpresa ? 'Empresa' : 'Pessoal', style: t.bodySmall?.copyWith(fontSize: 11)),
                      const SizedBox(width: 2),
                      Icon(Icons.swap_horiz_rounded, size: 14, color: c.tinta3),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ),
          const SizedBox(width: 4),
          const BotaoDeAvisos(),
        ],
      ),
    );
  }

  Future<void> _trocarEspaco(BuildContext context, WidgetRef ref) async {
    final espacos = ref.read(espacosProvider).valueOrNull ?? const <Espaco>[];
    final escolha = await abrirFolha<String>(
      context,
      largura: 440,
      (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Espacos.g, 0, Espacos.g, Espacos.p),
              child: Text('Seus espaços', style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final e in espacos)
              ListTile(
                leading: Icon(e.ehEmpresa ? Icons.storefront_outlined : Icons.home_outlined),
                title: Text(e.nome),
                subtitle: Text(e.ehEmpresa ? 'Empresa' : 'Pessoal'),
                trailing: e.id == espaco.id ? const Icon(Icons.check_rounded) : null,
                onTap: () => Navigator.pop(context, e.id),
              ),
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: const Text('Novo espaço'),
              onTap: () => Navigator.pop(context, ''),
            ),
            const SizedBox(height: Espacos.p),
          ],
        ),
      ),
    );
    if (escolha == null || !context.mounted) return;
    if (escolha.isEmpty) {
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TelaComeco(podeVoltar: true)));
    } else {
      await lembrarEspaco(ref, escolha);
      ref.read(secaoProvider.notifier).state = Secao.inicio;
    }
  }
}

class _ItemDoMenu extends StatelessWidget {
  const _ItemDoMenu({required this.rotulo, required this.ativo, required this.aoTocar, this.contagem = 0});
  final String rotulo;
  final bool ativo;
  final VoidCallback aoTocar;
  final int contagem;

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: ativo ? c.primariaSuave : c.superficie,
        borderRadius: Raios.p,
        child: InkWell(
          borderRadius: Raios.p,
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    rotulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: ativo ? c.tinta : c.tinta2),
                  ),
                ),
                if (contagem > 0) _Contagem(contagem),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Contagem extends StatelessWidget {
  const _Contagem(this.n);
  final int n;

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: c.primaria, borderRadius: Raios.pilula),
      child: Text(
        n > 99 ? '99+' : '$n',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c.sobrePrimaria, fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Barra inferior do celular: quatro destinos e o botão de lançar no meio.
class _BarraDeBaixo extends StatelessWidget {
  const _BarraDeBaixo({required this.secao, required this.pendentes, required this.aoTocar, required this.aoLancar});
  final Secao secao;
  final int pendentes;
  final ValueChanged<Secao> aoTocar;
  final VoidCallback aoLancar;

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;

    Widget destino(Secao s, IconData icone, String rotulo, {int contagem = 0}) {
      final ativo = s == secao;
      final cor = ativo ? c.primaria : c.tinta3;
      return Expanded(
        child: InkWell(
          onTap: () => aoTocar(s),
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icone, size: 22, color: cor),
                    if (contagem > 0) Positioned(right: -12, top: -4, child: _Contagem(contagem)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(rotulo, maxLines: 1, style: t.labelMedium?.copyWith(fontSize: 11, color: cor)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: c.superficie, border: Border(top: BorderSide(color: c.linha))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Row(
                children: [
                  destino(Secao.inicio, Icons.home_outlined, 'Início'),
                  destino(Secao.lancamentos, Icons.receipt_long_outlined, 'Lançamentos', contagem: pendentes),
                  const SizedBox(width: 68),
                  destino(Secao.metas, Icons.flag_outlined, 'Metas'),
                  destino(Secao.mais, Icons.more_horiz_rounded, 'Mais'),
                ],
              ),
              // O botão de lançar sobe um pouco acima da barra.
              Positioned(
                top: -14,
                child: Material(
                  color: c.primaria,
                  shape: const CircleBorder(),
                  elevation: 3,
                  shadowColor: c.tinta,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: aoLancar,
                    child: Semantics(
                      button: true,
                      label: 'Lançar',
                      child: SizedBox(width: 54, height: 54, child: Icon(Icons.add_rounded, size: 30, color: c.sobrePrimaria)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
