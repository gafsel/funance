import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/distribuicao.dart';
import '../regras/formatos.dart';
import '../tema/tema_novo.dart';
import 'formulario.dart';
import 'pecas.dart';

Color _corDoGrupo(Cores c, String grupo) => switch (grupo) {
      'essencial' => c.primaria,
      'conforto' => c.calor,
      _ => c.positivo,
    };

/// A renda dividida nos três grupos, numa barra só.
class _BarraDosGrupos extends StatelessWidget {
  const _BarraDosGrupos(this.d, {this.altura = 14});
  final Diagnostico d;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    // Futuro negativo (gastou mais do que entrou) não tem fatia.
    final partes = [for (final g in gruposDeGasto) (g, (d.porGrupo[g] ?? 0) < 0 ? 0 : (d.porGrupo[g] ?? 0))];
    return ClipRRect(
      borderRadius: Raios.pilula,
      child: SizedBox(
        height: altura,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (g, valor) in partes)
            if (valor > 0) Expanded(flex: valor, child: ColoredBox(color: _corDoGrupo(c, g))),
        ]),
      ),
    );
  }
}

String _periodo(Diagnostico d) => d.parcial
    ? 'Só ${nomeDoMes(d.meses.first)} até aqui, ainda incompleto'
    : d.meses.length == 1
        ? 'Média de ${nomeDoMes(d.meses.first)}'
        : 'Média de ${mesAbreviado(d.meses.first)} a ${mesAbreviado(d.meses.last)} (${d.meses.length} meses)';

/// Resumo do diagnóstico para a tela de metas e caminho: o retrato e o
/// apontamento mais importante. Tocar abre o diagnóstico inteiro.
class CartaoDaDistribuicao extends ConsumerWidget {
  const CartaoDaDistribuicao({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(diagnosticoProvider);
    final t = Theme.of(context).textTheme;
    final c = Cores.de(context);
    void abrir() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TelaDistribuicao()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloDeSecao('Para onde vai a renda', detalhe: d?.referencia.rotulo),
        if (d == null)
          const Cartao(padding: EdgeInsets.zero, child: Vazio('Quando houver um mês com renda lançada, o app mostra aqui como ela se divide e o que vale ajustar.'))
        else
          Cartao(
            onTap: abrir,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BarraDosGrupos(d),
                const SizedBox(height: Espacos.p),
                Wrap(spacing: Espacos.g, runSpacing: 4, children: [
                  for (final g in gruposDeGasto)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: _corDoGrupo(c, g), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('${nomeDoGrupo(g)} ${d.percentual(g)}%', style: t.bodySmall),
                    ]),
                ]),
                const SizedBox(height: Espacos.m),
                Text(d.apontamentos.first.titulo, style: t.titleSmall),
                const SizedBox(height: 2),
                Text(d.apontamentos.first.texto, maxLines: 3, overflow: TextOverflow.ellipsis, style: t.bodySmall),
                const SizedBox(height: Espacos.p),
                Text(
                  d.apontamentos.length > 1 ? 'Ver o diagnóstico (${d.apontamentos.length} apontamentos)' : 'Ver o diagnóstico',
                  style: t.labelLarge?.copyWith(color: c.primaria),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// O diagnóstico inteiro: o retrato contra a referência, o que o app aponta
/// e as categorias de cada grupo. Não é orçamento: não pede um valor por
/// categoria, só diz quanto o grupo pode somar.
class TelaDistribuicao extends ConsumerWidget {
  const TelaDistribuicao({super.key});

  Future<void> _mudarGrupo(BuildContext context, WidgetRef ref, Categoria categoria) async {
    final escolhido = await escolher<String>(
      context,
      titulo: '${categoria.nome} é',
      itens: gruposDeGasto,
      rotulo: nomeDoGrupo,
      detalhe: (g) => switch (g) {
        'essencial' => 'O que não dá para deixar de pagar: casa, comida, saúde, transporte.',
        'conforto' => 'O que você escolhe gastar: lazer, restaurantes, compras, assinaturas.',
        _ => 'O que fica para depois: investimento, reserva, previdência.',
      },
      atual: grupoDa(categoria),
    );
    if (escolhido != null) await ref.read(repositorioProvider)?.gravarCategoria(categoria.id, {'grupo': escolhido});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(diagnosticoProvider);
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    final categorias = {for (final x in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) x.id: x};
    final repo = ref.watch(repositorioProvider);

    if (d == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Para onde vai a renda')),
        body: const Vazio('Ainda não há um mês com renda lançada para comparar.'),
      );
    }

    Widget linhaDoGrupo(String g) {
      final valor = d.porGrupo[g] ?? 0;
      final teto = d.tetoCentavos(g);
      final fora = d.foraCentavos(g);
      final futuro = g == 'investimento';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: _corDoGrupo(c, g), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(nomeDoGrupo(g), style: t.titleSmall)),
              Text('${d.percentual(g)}%', style: Textos.valor(context, tamanho: 15)),
              Text('  de ${d.referencia.de(g)}%', style: t.bodySmall),
            ]),
            const SizedBox(height: 6),
            Barra(
              teto <= 0 ? 0 : (valor / (teto * 1.5)).clamp(0.0, 1.0),
              cor: fora > 0 ? c.atencao : _corDoGrupo(c, g),
            ),
            const SizedBox(height: 4),
            Text(
              '${reais(valor)} por mês · ${futuro ? 'piso' : 'teto'} de ${reais(teto)}'
              '${fora > 0 ? (futuro ? ' · faltam ${reais(fora)}' : ' · ${reais(fora)} acima') : ''}',
              style: t.bodySmall?.copyWith(color: fora > 0 ? c.atencao : null),
            ),
          ],
        ),
      );
    }

    final retrato = Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${_periodo(d)} · renda de ${reais(d.rendaCentavos)} por mês', style: t.bodySmall),
          const SizedBox(height: Espacos.m),
          _BarraDosGrupos(d, altura: 18),
          const SizedBox(height: Espacos.p),
          for (final g in gruposDeGasto) linhaDoGrupo(g),
          const SizedBox(height: Espacos.p),
          Text('Futuro é o que foi guardado de propósito mais o que sobrou da renda.', style: t.bodySmall),
        ],
      ),
    );

    final referencia = Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Segmentos<String>(
            opcoes: [for (final r in referencias) (r.id, r.nome)],
            valor: d.referencia.id,
            aoMudar: (id) => repo?.marcar('distribuicao', {'referencia': id}),
          ),
          const SizedBox(height: Espacos.m),
          Text('${d.referencia.rotulo} — essencial, estilo de vida, futuro', style: t.titleSmall),
          const SizedBox(height: 2),
          Text(d.referencia.quando, style: t.bodySmall),
        ],
      ),
    );

    Widget apontamento(Apontamento a) => Padding(
          padding: const EdgeInsets.only(bottom: Espacos.m),
          child: Cartao(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Etiqueta(
                  switch (a.tipo) { 'resolver' => 'Para resolver', 'reduzir' => 'Para baixar', _ => 'Tudo certo' },
                  tom: switch (a.tipo) { 'resolver' => Tom.atencao, 'reduzir' => Tom.calor, _ => Tom.bom },
                ),
                const SizedBox(height: Espacos.p),
                Text(a.titulo, style: t.titleMedium),
                const SizedBox(height: 4),
                Text(a.texto, style: t.bodyMedium),
                if (a.alternativas.isNotEmpty) ...[
                  const SizedBox(height: Espacos.m),
                  Text(a.alternativas.length > 1 ? 'Caminhos possíveis' : 'Um caminho', style: Textos.sobrancelha(context)),
                  for (final (i, alternativa) in a.alternativas.indexed)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${String.fromCharCode(65 + i)}.  ', style: t.titleSmall?.copyWith(color: c.primaria)),
                        Expanded(child: Text(alternativa, style: t.bodyMedium)),
                      ]),
                    ),
                ],
                if (a.categorias.isNotEmpty) ...[
                  const SizedBox(height: Espacos.m),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final id in a.categorias)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        SeloDaCategoria(categoria: categorias[id], tamanho: 22),
                        const SizedBox(width: 6),
                        Text(categorias[id]?.nome ?? 'Sem categoria', style: t.bodySmall),
                        const SizedBox(width: 8),
                      ]),
                  ]),
                ],
              ],
            ),
          ),
        );

    Widget grupo(String g) {
      final itens = d.categorias[g] ?? const <CategoriaNoGrupo>[];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TituloDeSecao(nomeDoGrupo(g), detalhe: g == 'investimento' && itens.isEmpty ? null : reais(itens.fold<int>(0, (s, x) => s + x.mediaCentavos))),
          if (itens.isEmpty)
            Cartao(
              padding: EdgeInsets.zero,
              child: Vazio(g == 'investimento'
                  ? 'Nenhuma categoria de futuro com gasto. O que sobra da renda já conta aqui.'
                  : 'Nenhuma categoria com gasto neste grupo.'),
            )
          else
            Lista(filhos: [
              for (final x in itens)
                Linha(
                  antes: SeloDaCategoria(categoria: categorias[x.categoriaId]),
                  titulo: categorias[x.categoriaId]?.nome ?? 'Sem categoria',
                  detalhe: switch ([
                    if (x.crescimentoCentavos > 0 && d.meses.length > 1) 'subiu ${reais(x.crescimentoCentavos)} no último mês',
                    if (x.crescimentoCentavos < 0 && d.meses.length > 1) 'caiu ${reais(-x.crescimentoCentavos)} no último mês',
                    if (categorias[x.categoriaId]?.grupo == null) 'grupo sugerido',
                  ].join(' · ')) {
                    '' => null,
                    final texto => texto,
                  },
                  corDoDetalhe: x.crescimentoCentavos > 0 && d.meses.length > 1 ? c.atencao : null,
                  direita: Text(reais(x.mediaCentavos), style: Textos.valor(context)),
                  aoTocar: categorias[x.categoriaId] == null ? null : () => _mudarGrupo(context, ref, categorias[x.categoriaId]!),
                ),
            ]),
        ],
      );
    }

    final esquerda = <Widget>[
      const TituloDeSecao('O retrato', semTopo: true),
      retrato,
      const TituloDeSecao('Referência'),
      referencia,
    ];
    final direita = <Widget>[
      TituloDeSecao('O que o app aponta', semTopo: ehMesa(context)),
      for (final a in d.apontamentos) apontamento(a),
    ];
    final grupos = <Widget>[
      const SizedBox(height: Espacos.p),
      Text('Toque numa categoria para mudar o grupo dela. Os valores são a média por mês.', style: t.bodySmall),
      for (final g in gruposDeGasto) grupo(g),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Para onde vai a renda')),
      body: Pagina(
        larguraMaxima: 1100,
        centralizada: true,
        filhos: ehMesa(context)
            ? [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...esquerda, ...grupos])),
                  const SizedBox(width: Espacos.xg),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: direita)),
                ]),
              ]
            : [...esquerda, ...direita, ...grupos],
      ),
    );
  }
}
