import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../regras/relatorios.dart';
import '../tema/tema_novo.dart';
import 'pecas.dart';

const _abreviados = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

/// Relatórios: para onde o dinheiro foi no mês, comparado ao mês anterior,
/// e como cada categoria evolui. Tudo sai dos resumos mensais que o servidor
/// já mantém; abrir esta tela não lê nenhum lançamento.
class TelaRelatorios extends ConsumerStatefulWidget {
  const TelaRelatorios({super.key, this.embutida = true});
  final bool embutida;

  @override
  ConsumerState<TelaRelatorios> createState() => _TelaRelatoriosState();
}

class _TelaRelatoriosState extends ConsumerState<TelaRelatorios> {
  String? _mes;
  String _tipo = 'saida';

  /// Categoria em foco na evolução; `null` = o total.
  String? _categoriaId;

  @override
  Widget build(BuildContext context) {
    final hoje = ref.watch(hojeProvider);
    final mes = _mes ?? hoje.substring(0, 7);
    final t = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final resumos = ref.watch(resumosProvider).valueOrNull ?? const <ResumoMes>[];
    final categorias = {for (final x in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) x.id: x};
    final porMes = {for (final r in resumos) r.mes: r};
    final atual = porMes[mes];
    final anterior = porMes[somarMeses(mes, -1)];
    final fatias = fatiasDoMes(atual, anterior, categorias, tipo: _tipo);
    final total = fatias.fold<int>(0, (s, f) => s + f.centavos);
    final totalAnterior = _tipo == 'saida' ? (anterior?.saidasCentavos ?? 0) : (anterior?.entradasCentavos ?? 0);
    final foco = categorias[_categoriaId];
    final serie = serieMensal(resumos, mes, categoriaId: foco?.id, entradas: _tipo == 'entrada');
    final teto = serie.fold<int>(1, (m, x) => x.$2 > m ? x.$2 : m);
    final corDoFoco = foco == null ? c.primaria : corDaCategoria(foco);

    Color corDe(Fatia f) => f.categoriaId == null ? c.tinta3 : corDaCategoria(categorias[f.categoriaId] ?? Categoria(id: f.categoriaId!, nome: '', tipo: _tipo));

    final cabecalho = Wrap(
      spacing: Espacos.g,
      runSpacing: Espacos.p,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            tooltip: 'Mês anterior',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _mes = somarMeses(mes, -1)),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(nomeDoMes(mes), style: t.titleLarge),
          IconButton(
            tooltip: 'Mês seguinte',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _mes = somarMeses(mes, 1)),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ]),
        Segmentos<String>(
          largo: false,
          opcoes: const [('saida', 'Saídas'), ('entrada', 'Entradas')],
          valor: _tipo,
          aoMudar: (v) => setState(() {
            _tipo = v;
            _categoriaId = null;
          }),
        ),
      ],
    );

    final blocoFatias = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloDeSecao(_tipo == 'saida' ? 'Para onde foi' : 'De onde veio', detalhe: 'toque para ver a evolução', semTopo: true),
        Cartao(
          padding: const EdgeInsets.all(12),
          child: fatias.isEmpty
              ? Vazio(_tipo == 'saida' ? 'Nenhuma saída em ${nomeDoMes(mes)}.' : 'Nenhuma entrada em ${nomeDoMes(mes)}.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(reais(total), style: Textos.numerao(context, tamanho: 30)),
                        ),
                      ),
                      if (totalAnterior > 0) _Variacao(total - totalAnterior, despesa: _tipo == 'saida'),
                    ]),
                    const SizedBox(height: 10),
                    // A barra inteira é o mês; cada pedaço, uma categoria.
                    ClipRRect(
                      borderRadius: Raios.pilula,
                      child: SizedBox(
                        height: 12,
                        child: Row(children: [
                          for (final f in fatias)
                            Expanded(flex: (f.fracao * 1000).round().clamp(1, 1000), child: Container(color: corDe(f))),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final f in fatias)
                      InkWell(
                        borderRadius: Raios.p,
                        onTap: f.categoriaId == null ? null : () => setState(() => _categoriaId = f.categoriaId == _categoriaId ? null : f.categoriaId),
                        child: Container(
                          decoration: BoxDecoration(
                            color: f.categoriaId != null && f.categoriaId == _categoriaId ? c.suave : null,
                            borderRadius: Raios.p,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                          child: Row(children: [
                            f.categoriaId == null
                                ? Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(color: c.suave, shape: BoxShape.circle),
                                    child: Icon(Icons.more_horiz_rounded, size: 16, color: c.tinta2),
                                  )
                                : SeloDaCategoria(categoria: categorias[f.categoriaId]),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(
                                        f.categoriaId == null ? 'Outras' : (categorias[f.categoriaId]?.nome ?? 'Sem categoria'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Text(reais(f.centavos), style: Textos.valor(context)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Barra(f.fracao, cor: corDe(f)),
                                  const SizedBox(height: 3),
                                  Row(children: [
                                    Expanded(child: Text('${(f.fracao * 100).round()}% do mês', style: t.bodySmall)),
                                    if (f.anteriorCentavos > 0) _Variacao(f.variacaoCentavos, despesa: _tipo == 'saida', pequena: true),
                                  ]),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );

    final blocoEvolucao = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloDeSecao(
          foco == null ? (_tipo == 'saida' ? 'Saídas nos últimos 6 meses' : 'Entradas nos últimos 6 meses') : '${foco.nome} nos últimos 6 meses',
          semTopo: ehMesa(context),
          acao: foco == null ? null : BotaoPequeno('Ver o total', aoTocar: () => setState(() => _categoriaId = null)),
        ),
        Cartao(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
          child: SizedBox(
            height: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (m, valor) in serie)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(valor == 0 ? '—' : reais(valor, comSimbolo: false), style: t.bodySmall?.copyWith(fontSize: 11)),
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: FractionallySizedBox(
                              heightFactor: (valor / teto).clamp(0.015, 1).toDouble(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: m == mes ? corDoFoco : corDoFoco.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.vertical(top: Raios.p.topLeft),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(_abreviados[int.parse(m.substring(5, 7)) - 1], style: t.bodySmall?.copyWith(color: m == mes ? c.tinta : null, fontWeight: m == mes ? FontWeight.w700 : null)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const TituloDeSecao('Entrou, saiu e sobrou'),
        Lista(filhos: [
          for (final (m, _) in serie.reversed)
            Builder(builder: (context) {
              final r = porMes[m];
              final sobra = r?.resultadoCentavos ?? 0;
              return Linha(
                titulo: nomeDoMes(m),
                detalhe: r == null ? 'Sem lançamentos' : 'Entrou ${reais(r.entradasCentavos)} · saiu ${reais(r.saidasCentavos)}',
                direita: Text(
                  r == null ? '—' : '${sobra > 0 ? '+' : ''}${reais(sobra)}',
                  style: Textos.valor(context, cor: sobra < 0 ? c.problema : (sobra > 0 ? c.positivo : c.tinta2)),
                ),
                aoTocar: () => setState(() => _mes = m),
              );
            }),
        ]),
      ],
    );

    final filhos = <Widget>[
      cabecalho,
      const SizedBox(height: Espacos.g),
      if (ehMesa(context))
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: blocoFatias),
          const SizedBox(width: Espacos.xg),
          Expanded(child: blocoEvolucao),
        ])
      else ...[blocoFatias, blocoEvolucao],
    ];

    if (widget.embutida) return Pagina(filhos: filhos);
    return Scaffold(appBar: AppBar(title: const Text('Relatórios')), body: Pagina(filhos: filhos));
  }
}

/// Diferença para o mês anterior. Em despesa, subir é atenção e cair é bom;
/// em entrada, o contrário.
class _Variacao extends StatelessWidget {
  const _Variacao(this.centavos, {required this.despesa, this.pequena = false});
  final int centavos;
  final bool despesa;
  final bool pequena;

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    if (centavos == 0) return Text('igual ao mês anterior', style: Theme.of(context).textTheme.bodySmall);
    final subiu = centavos > 0;
    final bom = despesa ? !subiu : subiu;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(subiu ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: pequena ? 12 : 14, color: bom ? c.positivo : c.atencao),
      const SizedBox(width: 2),
      Text(
        '${reais(centavos.abs())}${pequena ? '' : ' a ${subiu ? 'mais' : 'menos'} que no mês anterior'}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: bom ? c.positivo : c.atencao, fontWeight: FontWeight.w600),
      ),
    ]);
  }
}
