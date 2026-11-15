import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/caminho.dart';
import '../regras/faturas.dart';
import '../regras/formatos.dart';
import '../regras/metas.dart';
import '../tema/tema_novo.dart';
import 'casca.dart';
import 'conta.dart';
import 'detalhe.dart';
import 'fatura.dart';
import 'lancar.dart';
import 'meta.dart';
import 'pecas.dart';
import 'revisao.dart';

const _meses = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

class TelaInicio extends ConsumerWidget {
  const TelaInicio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mesa = ehMesa(context);
    const espaco = SizedBox(height: Espacos.g);
    final esquerda = <Widget>[const _Heroi(), espaco, const _CampoRapido(), const _AVencer()];
    final direita = <Widget>[const _Passo(), const _Avisos(), const _MetasResumo(), const _Contas()];
    const ultimos = _Ultimos();

    // Tela larga: três colunas. O que se faz agora, o que orienta, e as contas.
    if (ehTelaLarga(context)) {
      return Pagina(filhos: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...esquerda, ultimos])),
            const SizedBox(width: Espacos.xg),
            const Expanded(
              flex: 4,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_Passo(), _Avisos(), _MetasResumo()]),
            ),
            const SizedBox(width: Espacos.xg),
            const Expanded(flex: 4, child: _Contas(semTopo: true)),
          ],
        ),
      ]);
    }

    if (mesa) {
      return Pagina(filhos: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...esquerda, ultimos])),
            const SizedBox(width: Espacos.xg),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: direita)),
          ],
        ),
      ]);
    }
    return Pagina(filhos: [...esquerda, espaco, ...direita, ultimos]);
  }
}

/// O número central: quanto ainda dá para gastar neste mês.
class _Heroi extends ConsumerStatefulWidget {
  const _Heroi();

  @override
  ConsumerState<_Heroi> createState() => _HeroiState();
}

class _HeroiState extends ConsumerState<_Heroi> {
  bool _aberto = false;

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(livreProvider);
    final hoje = ref.watch(hojeProvider);
    final t = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final negativo = r.livreCentavos < 0;
    final mes = hoje.substring(0, 7);
    final fimDoMes = '${diasNoMes(mes)} de ${_meses[int.parse(mes.substring(5, 7)) - 1]}';

    Widget parcela(String rotulo, String valor, {bool total = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Expanded(child: Text(rotulo, style: t.bodyMedium?.copyWith(fontSize: 13, color: total ? c.tinta : c.tinta2, fontWeight: total ? FontWeight.w700 : null))),
            Text(valor, style: Textos.valor(context, tamanho: 13, cor: total ? c.tinta : c.tinta2)),
          ]),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Livre para gastar', style: t.bodyMedium?.copyWith(fontSize: 13, color: c.tinta2, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(reais(r.livreCentavos), style: Textos.numerao(context).copyWith(color: negativo ? c.problema : c.tinta)),
        ),
        const SizedBox(height: 2),
        Text(
          r.rendaCentavos == 0
              ? 'Lance o que você recebe no mês para este número fazer sentido.'
              : negativo
                  ? 'até $fimDoMes · o mês está apertado'
                  : 'até $fimDoMes · cerca de ${reais(r.porDiaCentavos)} por dia',
          style: t.bodyMedium?.copyWith(color: c.tinta2),
        ),
        if (r.rendaCentavos > 0) ...[
          const SizedBox(height: 4),
          InkWell(
            onTap: () => setState(() => _aberto = !_aberto),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                _aberto ? 'Esconder a conta' : 'Como chegamos nesse número',
                style: t.labelLarge?.copyWith(color: c.primaria),
              ),
            ),
          ),
          if (_aberto) ...[
            const SizedBox(height: 6),
            parcela('Renda do mês', reais(r.rendaCentavos)),
            parcela('Contas do mês', '− ${reais(r.compromissosCentavos)}'),
            parcela('Parcela das metas', '− ${reais(r.metasCentavos)}'),
            parcela('Já gasto', '− ${reais(r.gastoCentavos)}'),
            const Divider(height: 10),
            parcela('Livre para gastar', reais(r.livreCentavos), total: true),
          ],
        ],
      ],
    );
  }
}

/// Campo de entrada rápida: abre o lançar por texto.
class _CampoRapido extends StatelessWidget {
  const _CampoRapido();

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    return Material(
      color: c.superficie,
      shape: RoundedRectangleBorder(borderRadius: Raios.g, side: BorderSide(color: c.primaria, width: 1.5)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => abrirLancar(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Icon(Icons.add_rounded, size: 20, color: c.primaria),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Escreva um lançamento: "café 15"',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.tinta3),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// O que vence nos próximos sete dias, mais o que já venceu.
class _AVencer extends ConsumerWidget {
  const _AVencer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = ref.watch(hojeProvider);
    final mes = hoje.substring(0, 7);
    final contas = {for (final x in ref.watch(contasProvider).valueOrNull ?? const <Conta>[]) x.id: x};
    final categorias = {for (final x in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) x.id: x};
    final doMes = ref.watch(lancamentosDoMesProvider(mes)).valueOrNull ?? const <Lancamento>[];
    final atrasados = ref.watch(atrasadosProvider).valueOrNull ?? const <Lancamento>[];
    final limite = somarDias(hoje, 7);
    final itens = {
      for (final l in atrasados) l.id: l,
      for (final l in doMes)
        if (l.previsto && l.data.compareTo(limite) <= 0) l.id: l,
    }.values.toList()
      ..sort((a, b) => a.data.compareTo(b.data));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloDeSecao('A vencer', detalhe: itens.isEmpty ? null : '${itens.length} em aberto'),
        if (itens.isEmpty)
          const Cartao(padding: EdgeInsets.zero, child: Vazio('Nada a pagar ou receber nos próximos sete dias.'))
        else
          Lista(filhos: [
            for (final l in itens.take(6))
              LinhaDeLancamento(
                lancamento: l,
                hoje: hoje,
                conta: contas[l.contaId],
                destino: contas[l.contaDestinoId],
                categoria: categorias[l.categoriaId],
                onTap: () => abrirLancamento(context, ref, l),
                acao: BotaoPequeno(
                  l.ehEntrada ? 'Recebi' : 'Paguei',
                  aoTocar: () async {
                    final repo = ref.read(repositorioProvider);
                    if (repo == null) return;
                    final mensageiro = ScaffoldMessenger.of(context);
                    await repo.efetivar(l, dia: hoje);
                    mensageiro
                      ..clearSnackBars()
                      ..showSnackBar(SnackBar(
                        duration: const Duration(seconds: 8),
                        content: Text(l.ehEntrada ? 'Marcado como recebido hoje.' : 'Marcado como pago hoje.'),
                        action: SnackBarAction(label: 'Desfazer', onPressed: () => repo.gravar(l)),
                      ));
                  },
                ),
              ),
          ]),
      ],
    );
  }
}

/// O passo de agora no caminho, em destaque.
class _Passo extends ConsumerWidget {
  const _Passo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caminho = ref.watch(caminhoProvider);
    final atual = degrauAtual(caminho);
    if (atual == null) return const SizedBox.shrink();
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    final numero = caminho.indexWhere((g) => g.id == atual.id) + 1;

    return Cartao(
      cor: c.calorSuave,
      semBorda: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SEU PRÓXIMO PASSO · $numero DE ${caminho.length}', style: Textos.sobrancelha(context).copyWith(color: c.tinta2)),
          const SizedBox(height: 2),
          Text(atual.titulo, style: t.titleLarge?.copyWith(fontSize: 17)),
          const SizedBox(height: 4),
          Text('${atual.porque} ${atual.situacao}', style: t.bodyMedium?.copyWith(fontSize: 13, color: c.tinta2)),
          if (atual.fracao != null) ...[
            const SizedBox(height: 8),
            Barra(atual.fracao!, cor: c.calor, trilho: c.superficie),
          ],
          const SizedBox(height: 8),
          Text(atual.proximoPasso, style: t.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => ref.read(secaoProvider.notifier).state = Secao.metas,
            child: Text('Ver o caminho inteiro', style: t.labelLarge?.copyWith(color: c.primaria)),
          ),
        ],
      ),
    );
  }
}

/// Avisos do Início: revisão da semana, mês apertado e limites estourando.
/// Só aparece o que pede atenção agora.
class _Avisos extends ConsumerWidget {
  const _Avisos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = ref.watch(hojeProvider);
    final mes = hoje.substring(0, 7);
    final t = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final livre = ref.watch(livreProvider);
    final pausadas = ref.watch(metasPausadasProvider);
    final repo = ref.watch(repositorioProvider);
    final revisada = ref.watch(marcasProvider).valueOrNull?.containsKey(marcaDaSemana(hoje)) ?? false;
    final resumo = (ref.watch(resumosProvider).valueOrNull ?? const <ResumoMes>[]).where((r) => r.mes == mes).firstOrNull;
    final estourando = [
      for (final x in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[])
        if (!x.arquivada && (x.limiteMensalCentavos ?? 0) > 0 && (resumo?.categorias[x.id]?.$2 ?? 0) * 10 >= x.limiteMensalCentavos! * 8) x,
    ];

    Widget aviso({required Color ponto, required String texto, Color? fundo, String? acao, VoidCallback? aoTocar}) => Padding(
          padding: const EdgeInsets.only(top: Espacos.m),
          child: Cartao(
            cor: fundo,
            semBorda: fundo != null,
            onTap: acao == null ? aoTocar : null,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: ponto, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(texto, style: t.bodyMedium?.copyWith(fontSize: 13))),
                if (acao != null) ...[const SizedBox(width: 10), BotaoPequeno(acao, aoTocar: aoTocar)],
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!revisada)
          aviso(ponto: c.calor, texto: 'Sua revisão da semana está pronta · 2 minutos', aoTocar: () => abrirRevisao(context)),
        if (livre.livreCentavos < 0 && livre.rendaCentavos > 0 && livre.metasCentavos > 0)
          aviso(
            ponto: c.atencao,
            fundo: c.atencaoSuave,
            texto: 'Faltam ${reais(-livre.livreCentavos)} para fechar o mês. Pausar as metas libera ${reais(livre.metasCentavos)}; só o prazo delas estica.',
            acao: 'Pausar',
            aoTocar: () => repo?.marcar('pausa-$mes', {'em': hoje}),
          ),
        if (pausadas)
          aviso(
            ponto: c.tinta3,
            texto: 'As metas estão pausadas neste mês.',
            acao: 'Retomar',
            aoTocar: () => repo?.desmarcar('pausa-$mes'),
          ),
        for (final x in estourando)
          aviso(
            ponto: c.atencao,
            fundo: c.atencaoSuave,
            texto: '${x.nome}: ${reais(resumo?.categorias[x.id]?.$2 ?? 0)} de ${reais(x.limiteMensalCentavos!)}. '
                '${(resumo?.categorias[x.id]?.$2 ?? 0) > x.limiteMensalCentavos! ? 'Passou do limite do mês.' : 'Passou de 80% do limite.'}',
          ),
      ],
    );
  }
}

class _MetasResumo extends ConsumerWidget {
  const _MetasResumo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = ref.watch(hojeProvider);
    final t = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final metas = (ref.watch(metasProvider).valueOrNull ?? const <Meta>[]).where((m) => m.emAberto).toList()
      ..sort((a, b) => a.prazo.compareTo(b.prazo));
    if (metas.isEmpty) return const SizedBox.shrink();
    final contas = {for (final x in ref.watch(contasProvider).valueOrNull ?? const <Conta>[]) x.id: x};
    final saldos = ref.watch(saldosProvider);
    final resumos = ref.watch(resumosProvider).valueOrNull ?? const <ResumoMes>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloDeSecao(
          'Metas',
          acao: InkWell(
            onTap: () => ref.read(secaoProvider.notifier).state = Secao.metas,
            child: Text('Ver todas', style: t.labelLarge?.copyWith(color: c.primaria)),
          ),
        ),
        Lista(filhos: [
          for (final meta in metas.take(3))
            Builder(builder: (context) {
              final p = progressoDaMeta(meta, hoje: hoje, contas: contas, saldos: saldos, resumos: resumos);
              return InkWell(
                onTap: () => abrirMeta(context, meta.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(meta.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall)),
                        const SizedBox(width: 8),
                        Text('${(p.fracao * 100).round()}%', style: Textos.valor(context, tamanho: 13)),
                      ]),
                      const SizedBox(height: 6),
                      Barra(p.fracao, cor: p.menorEhMelhor && !p.atingida ? c.atencao : null),
                      const SizedBox(height: 4),
                      Text(
                        '${reais(p.atualCentavos)} de ${reais(p.alvoCentavos)} · até ${diaPorExtenso(meta.prazo, hoje)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ]),
      ],
    );
  }
}

class _Contas extends ConsumerWidget {
  const _Contas({this.semTopo = false});

  /// Primeira coisa da coluna: o título não precisa de respiro em cima.
  final bool semTopo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = ref.watch(hojeProvider);
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    final contas = (ref.watch(contasProvider).valueOrNull ?? const <Conta>[]).where((x) => !x.arquivada).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    final saldos = ref.watch(saldosProvider);
    final membros = ref.watch(membrosProvider).valueOrNull ?? const <Membro>[];
    final eu = ref.watch(authProvider).valueOrNull?.uid;
    // As de quem está usando vêm primeiro; depois por banco.
    int ordem(Conta x) => x.donos.contains(eu) && !x.conjunta ? 0 : (x.donos.contains(eu) ? 1 : 2);
    contas.sort((a, b) {
      final o = ordem(a).compareTo(ordem(b));
      if (o != 0) return o;
      final banco = (a.banco ?? 'zz').compareTo(b.banco ?? 'zz');
      return banco != 0 ? banco : a.nome.compareTo(b.nome);
    });
    String detalhe(Conta x, String tipo) => [tipo, titularidade(x, membros, eu)].where((p) => p.isNotEmpty).join(' · ');
    final outras = contas.where((x) => !x.ehCartao).toList();
    final cartoes = contas.where((x) => x.ehCartao).toList();
    const tipos = {'corrente': 'Conta corrente', 'dinheiro': 'Dinheiro', 'investimento': 'Investimento', 'divida': 'Dívida'};

    final situacoes = ref.watch(situacoesDasFaturasProvider);
    SituacaoDaFatura? faturaAtual(Conta cartao) => faturaEmDestaque(situacoes, cartao.id);
    int valorDa(SituacaoDaFatura? s) => s == null ? 0 : valorEmDestaque(s);

    final reservado = cartoes.fold<int>(0, (s, x) => s + (valorDa(faturaAtual(x)) > 0 ? valorDa(faturaAtual(x)) : 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloDeSecao('Contas', semTopo: semTopo),
        if (outras.isEmpty)
          const Cartao(padding: EdgeInsets.zero, child: Vazio('Nenhuma conta cadastrada.'))
        else
          Lista(filhos: [
            for (final x in outras)
              Linha(
                antes: SeloDaConta(conta: x, membros: membros),
                titulo: x.nome,
                detalhe: detalhe(x, tipos[x.tipo] ?? ''),
                aoTocar: () => abrirConta(context, x.id),
                direita: Text(
                  reais(saldos[x.id] ?? 0),
                  style: Textos.valor(context, cor: (saldos[x.id] ?? 0) < 0 && x.tipo != 'divida' ? c.problema : null),
                ),
              ),
          ]),
        if (cartoes.isNotEmpty) ...[
          const TituloDeSecao('Cartões'),
          Lista(filhos: [
            for (final x in cartoes)
              Builder(builder: (context) {
                final s = faturaAtual(x);
                final f = s?.fatura;
                final venceu = s != null && s.atrasada;
                return Linha(
                  antes: SeloDaConta(conta: x, membros: membros),
                  titulo: x.nome,
                  detalhe: detalhe(
                    x,
                    f == null
                        ? 'Sem fatura em aberto'
                        : s!.emParte
                            ? 'Paga em parte: o resto vai para a próxima'
                            : 'Fatura ${venceu ? 'venceu' : 'vence'} ${diaPorExtenso(f.vencimento, hoje)}',
                  ),
                  corDoDetalhe: venceu || (s?.emParte ?? false) ? c.atencao : null,
                  direita: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(reais(valorDa(s)), style: Textos.valor(context)),
                    IconButton(
                      tooltip: 'Todas as faturas',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                      onPressed: () => abrirCartao(context, x),
                    ),
                  ]),
                  // Vai direto à fatura que pede atenção; a lista fica no ⋮.
                  aoTocar: () => f == null ? abrirCartao(context, x) : abrirFatura(context, x, f.id),
                );
              }),
          ]),
          if (reservado > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('${reais(reservado)} do saldo das contas já estão reservados para as faturas.', style: t.bodySmall),
            ),
        ],
      ],
    );
  }
}

class _Ultimos extends ConsumerWidget {
  const _Ultimos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = ref.watch(hojeProvider);
    final contas = {for (final x in ref.watch(contasProvider).valueOrNull ?? const <Conta>[]) x.id: x};
    final categorias = {for (final x in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) x.id: x};
    final doMes = ref.watch(lancamentosDoMesProvider(hoje.substring(0, 7))).valueOrNull ?? const <Lancamento>[];
    final ultimos = doMes.where((l) => l.efetivado && l.dia.compareTo(hoje) <= 0).toList()
      ..sort((a, b) => b.dia.compareTo(a.dia));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloDeSecao(
          'Últimos lançamentos',
          acao: ultimos.isEmpty
              ? null
              : InkWell(
                  onTap: () => ref.read(secaoProvider.notifier).state = Secao.lancamentos,
                  child: Text('Ver todos', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Cores.de(context).primaria)),
                ),
        ),
        if (ultimos.isEmpty)
          const Cartao(padding: EdgeInsets.zero, child: Vazio('Nenhum lançamento neste mês ainda.'))
        else
          Lista(filhos: [
            for (final l in ultimos.take(6))
              LinhaDeLancamento(
                lancamento: l,
                hoje: hoje,
                conta: contas[l.contaId],
                destino: contas[l.contaDestinoId],
                categoria: categorias[l.categoriaId],
                onTap: () => abrirLancamento(context, ref, l),
              ),
          ]),
      ],
    );
  }
}
