import '../caminhos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/mascara.dart';
import '../regras/faturas.dart';
import '../regras/formatos.dart';
import '../tema/tema_novo.dart';
import 'conta.dart';
import 'detalhe.dart';
import 'entrada.dart';
import 'lancar.dart';
import 'formulario.dart';
import 'pecas.dart';

void abrirCartao(BuildContext context, Conta cartao) =>
    Navigator.of(context).pushNamed(caminhoDoCartao(cartao.id));

void abrirFatura(BuildContext context, Conta cartao, String faturaId) =>
    Navigator.of(context).pushNamed(caminhoDaFatura(cartao.id, faturaId));

/// Faturas de um cartão: a em aberto em destaque, as outras em lista.
class TelaCartao extends ConsumerWidget {
  const TelaCartao({super.key, required this.cartao});
  final Conta cartao;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = ref.watch(hojeProvider);
    final c = Cores.de(context);
    // Assinaturas e compras previstas que ainda vão cair neste cartão.
    final agendados = (ref.watch(previstosProvider).valueOrNull ?? const <Lancamento>[])
        .where((l) => l.contaId == cartao.id)
        .toList();
    final situacoes = ref.watch(situacoesDasFaturasProvider);
    int agendadosDa(Fatura f) => agendados.where((l) => _caiNaFatura(l, f)).length;
    final faturas = (ref.watch(faturasProvider).valueOrNull ?? const <Fatura>[])
        .where((f) => f.contaId == cartao.id && (f.totalCentavos != 0 || f.pagoCentavos != 0 || agendadosDa(f) > 0))
        .toList()
      ..sort((a, b) => b.vencimento.compareTo(a.vencimento));
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(cartao.nome)),
      body: Pagina(
        larguraMaxima: 640,
        centralizada: true,
        filhos: [
          Text(
            'Fecha dia ${cartao.diaFechamento ?? 5}, vence dia ${cartao.diaVencimento ?? 10}. '
            'A compra conta como gasto no mês em que foi feita; pagar a fatura não conta de novo.',
            style: texto.bodySmall,
          ),
          const SizedBox(height: Espacos.m),
          Wrap(spacing: Espacos.p, runSpacing: Espacos.p, children: [
            BotaoPequeno('Lançar neste cartão', icone: Icons.add_rounded, cheio: true, aoTocar: () => abrirLancar(context, contaId: cartao.id)),
            BotaoPequeno('Importar fatura', icone: Icons.upload_file_rounded, aoTocar: () => abrirImportacao(context, contaId: cartao.id)),
            BotaoPequeno('Extrato e titulares', aoTocar: () => abrirConta(context, cartao.id)),
          ]),
          if (faturas.length > 1) ...[
            const TituloDeSecao('Como as faturas variam'),
            Cartao(child: _GraficoDeFaturas(faturas: faturas.take(12).toList().reversed.toList(), cartao: cartao, situacoes: situacoes)),
          ],
          const TituloDeSecao('Faturas'),
          if (faturas.isEmpty)
            const Cartao(padding: EdgeInsets.zero, child: Vazio('Nenhuma fatura neste cartão ainda.'))
          else
            Lista(filhos: [
              for (final (i, f) in faturas.indexed)
                Linha(
                  titulo: 'Vence ${diaPorExtenso(f.vencimento, hoje)}',
                  detalhe: [
                    switch (situacoes[f.id]) {
                      null => '',
                      final s when s.aberta => 'Aberta, fecha ${diaPorExtenso(f.fechamento, hoje)}',
                      final s when s.emParte => 'Paga em parte: ${reais(s.levadoCentavos)} foram para a próxima',
                      final s when s.paga => 'Paga',
                      final s when s.atrasada => 'Atrasada',
                      _ => 'Fechada, esperando pagamento',
                    },
                    switch (variacaoPercentual(f.totalCentavos, i + 1 < faturas.length ? faturas[i + 1].totalCentavos : null)) {
                      null || 0 => '',
                      final v when v > 0 => '$v% a mais que a anterior',
                      final v => '${-v}% a menos que a anterior',
                    },
                    switch (agendadosDa(f)) { 0 => '', 1 => '1 agendado', final n => '$n agendados' },
                  ].where((p) => p.isNotEmpty).join(' · '),
                  corDoDetalhe: (situacoes[f.id]?.atrasada ?? false) || (situacoes[f.id]?.emParte ?? false) ? c.atencao : null,
                  direita: Text(reais(f.totalCentavos), style: Textos.valor(context)),
                  aoTocar: () => abrirFatura(context, cartao, f.id),
                ),
            ]),
        ],
      ),
    );
  }
}

/// As últimas faturas em barras, da mais antiga para a mais nova: mostra
/// de relance se o cartão está subindo ou descendo. Tocar abre a fatura.
class _GraficoDeFaturas extends StatelessWidget {
  const _GraficoDeFaturas({required this.faturas, required this.cartao, required this.situacoes});
  final List<Fatura> faturas;
  final Conta cartao;
  final Map<String, SituacaoDaFatura> situacoes;

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    final maior = faturas.fold<int>(1, (m, f) => f.totalCentavos > m ? f.totalCentavos : m);
    final media = faturas.fold<int>(0, (s, f) => s + f.totalCentavos) ~/ faturas.length;
    const altura = 96.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Média de ${reais(media)} nas últimas ${faturas.length} faturas', style: t.bodySmall),
        const SizedBox(height: Espacos.m),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final f in faturas)
              Expanded(
                child: InkWell(
                  borderRadius: Raios.p,
                  onTap: () => abrirFatura(context, cartao, f.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(reaisCurtos(f.totalCentavos), style: t.labelSmall?.copyWith(color: c.tinta2)),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: (altura * f.totalCentavos / maior).clamp(3.0, altura),
                          constraints: const BoxConstraints(maxWidth: 56),
                          decoration: BoxDecoration(
                            borderRadius: Raios.p,
                            color: switch (situacoes[f.id]) {
                              final s? when s.quitada => c.primariaSuave,
                              final s? when s.atrasada || s.emParte => c.atencao,
                              _ => c.primaria,
                            },
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(mesAbreviado(f.vencimento), style: t.labelSmall?.copyWith(color: c.tinta3)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// O agendado cai nesta fatura quando a data dele está no ciclo de compras.
bool _caiNaFatura(Lancamento l, Fatura f) =>
    l.contaId == f.contaId && l.data.compareTo(f.inicio) >= 0 && l.data.compareTo(f.fim) <= 0;

final _pagamentosProvider = StreamProvider.family<List<Lancamento>, String>((ref, faturaId) {
  final repo = ref.watch(repositorioProvider);
  return repo == null ? Stream.value(const []) : repo.pagamentosDaFatura(faturaId);
});

final _comprasProvider = StreamProvider.family<List<Lancamento>, Fatura>((ref, fatura) {
  final repo = ref.watch(repositorioProvider);
  return repo == null ? Stream.value(const []) : repo.comprasDaFatura(fatura);
});

/// Detalhe de uma fatura: quanto é, para onde foi (por categoria), as
/// compras, e o que se faz no contexto dela — lançar no cartão, importar a
/// fatura do banco, conferir o total e pagar.
class TelaFatura extends ConsumerStatefulWidget {
  const TelaFatura({super.key, required this.cartao, required this.faturaId});
  final Conta cartao;
  final String faturaId;

  @override
  ConsumerState<TelaFatura> createState() => _TelaFaturaState();
}

class _TelaFaturaState extends ConsumerState<TelaFatura> {
  String _aba = 'compras';
  int _visiveis = _passo;
  static const _passo = 40;

  Conta get cartao => widget.cartao;

  Future<void> _pagar(Fatura f, {required int base, required bool aberta}) =>
      pagarFatura(context, ref, cartao, f, base: base, aberta: aberta);

  /// Conferência: o total que o banco mostra na fatura contra o do app.
  Future<void> _conferir(Fatura f) async {
    final campo = TextEditingController();
    String? resultado;
    var bate = false;
    await abrirFolha<void>(
      context,
      (context) => StatefulBuilder(builder: (context, definir) {
        final t = Theme.of(context).textTheme;
        final c = Cores.de(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(Espacos.g, 0, Espacos.g, Espacos.g),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Conferir a fatura', style: t.titleLarge),
              const SizedBox(height: 4),
              Text('Informe o total que o banco mostra nesta fatura. No app ela soma ${reais(f.totalCentavos)}.', style: t.bodyMedium?.copyWith(fontSize: 13, color: c.tinta2)),
              const SizedBox(height: Espacos.m),
              TextField(
                controller: campo,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [const MascaraDeValor()],
                decoration: const InputDecoration(labelText: 'Total na fatura do banco', prefixText: r'R$ '),
              ),
              if (resultado != null) ...[
                const SizedBox(height: Espacos.m),
                Cartao(
                  cor: bate ? c.positivoSuave : c.atencaoSuave,
                  semBorda: true,
                  padding: const EdgeInsets.all(12),
                  child: Text(resultado!, style: t.bodyMedium?.copyWith(fontSize: 13, color: bate ? c.positivo : c.atencao)),
                ),
              ],
              const SizedBox(height: Espacos.g),
              Acoes(filhos: [
                FilledButton(
                  onPressed: () async {
                    final informado = lerCentavos(campo.text);
                    if (informado == null) return definir(() => resultado = 'Informe o total da fatura.');
                    final diferenca = informado - f.totalCentavos;
                    if (diferenca == 0) {
                      await ref.read(repositorioProvider)?.gravarConta(cartao.id, {
                        'conferidoAte': ref.read(hojeProvider),
                        'faturasConferidas': {f.id: informado},
                      });
                      definir(() {
                        bate = true;
                        resultado = 'Bate. Fatura conferida.';
                      });
                    } else {
                      definir(() {
                        bate = false;
                        resultado = diferenca > 0
                            ? 'A fatura do banco tem ${reais(diferenca)} a mais: falta lançar alguma compra. Importe a fatura para achar qual.'
                            : 'A fatura do banco tem ${reais(-diferenca)} a menos: há uma compra a mais no app, ou em outro ciclo. Importe a fatura para comparar.';
                      });
                    }
                  },
                  child: const Text('Conferir'),
                ),
                if (bate) OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
              ]),
            ],
          ),
        );
      }),
      largura: 460,
    );
    campo.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hoje = ref.watch(hojeProvider);
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    final mesa = ehMesa(context);
    final f = (ref.watch(faturasProvider).valueOrNull ?? const <Fatura>[]).where((x) => x.id == widget.faturaId).firstOrNull;
    if (f == null) {
      return Scaffold(appBar: AppBar(), body: const Vazio('Esta fatura não existe mais.'));
    }
    // O cartão como está agora (a conferência é gravada nele).
    final conta = (ref.watch(contasProvider).valueOrNull ?? const <Conta>[]).where((x) => x.id == cartao.id).firstOrNull ?? cartao;
    final membros = ref.watch(membrosProvider).valueOrNull ?? const <Membro>[];
    final compras = (ref.watch(_comprasProvider(f)).valueOrNull ?? const <Lancamento>[]).toList()
      ..sort((a, b) => b.dia.compareTo(a.dia));
    final categorias = {for (final x in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) x.id: x};
    final pagamentos = (ref.watch(_pagamentosProvider(f.id)).valueOrNull ?? const <Lancamento>[]).toList()
      ..sort((a, b) => b.dia.compareTo(a.dia));
    // Dinheiro mandado para o cartão sem dizer que fatura paga: está valendo
    // como crédito neste ciclo, e provavelmente era pagamento.
    final soltas = compras.where((l) => l.ehTransferencia && l.contaDestinoId == cartao.id).toList();
    final todas = ref.watch(faturasProvider).valueOrNull ?? const <Fatura>[];
    final contas = {for (final x in ref.watch(contasProvider).valueOrNull ?? const <Conta>[]) x.id: x};
    // Assinaturas e compras previstas que ainda vão entrar nesta fatura.
    final agendados = (ref.watch(previstosProvider).valueOrNull ?? const <Lancamento>[])
        .where((l) => _caiNaFatura(l, f))
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));
    final somaAgendada = agendados.fold<int>(0, (s, l) => s + (l.ehEntrada ? -l.valorCentavos : l.valorCentavos));
    int naFatura(Lancamento l) => l.contaId == cartao.id && !l.ehEntrada ? l.valorCentavos : -l.valorCentavos;
    final somaListada = compras.fold<int>(0, (s, l) => s + naFatura(l));

    // Para onde foi: total por categoria, da maior para a menor.
    final porCategoria = <String?, int>{};
    for (final l in compras) {
      if (l.ehTransferencia) continue;
      porCategoria[l.categoriaId] = (porCategoria[l.categoriaId] ?? 0) + naFatura(l);
    }
    final fatias = porCategoria.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
    final totalDasFatias = fatias.fold<int>(0, (s, e) => s + e.value);
    Color corDe(String? id) => categorias[id] == null ? c.tinta3 : corDaCategoria(categorias[id]!);

    final conferida = conta.faturasConferidas[f.id];
    final s = ref.watch(situacoesDasFaturasProvider)[f.id] ?? SituacaoDaFatura(f, 0, hoje);
    final venceu = s.atrasada;
    final aberta = s.aberta;
    // O que o botão de pagar propõe: o que falta, o complemento, ou (na
    // fatura aberta) o que já se acumulou.
    final aPagar = s.pendente ? s.aPagarCentavos : (s.emParte ? s.levadoCentavos : (aberta ? s.devidoCentavos : 0));

    final listaDeAgendados = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Lista(filhos: [
          for (final l in agendados)
            LinhaDeLancamento(
              lancamento: l,
              hoje: hoje,
              conta: cartao,
              categoria: categorias[l.categoriaId],
              onTap: () => abrirLancamento(context, ref, l),
            ),
        ]),
        const SizedBox(height: Espacos.p),
        Text(
          'Ainda não contam no total. Com eles, a fatura vai a ${reais(f.totalCentavos + somaAgendada)}.',
          style: t.bodySmall,
        ),
      ],
    );

    final avisoDeSoltas = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final l in soltas)
          if (faturaQueOPagamentoQuita(todas.where((x) => x.contaId == cartao.id), l.dia) case final alvo?)
            Padding(
              padding: const EdgeInsets.only(bottom: Espacos.m),
              child: Cartao(
                child: Row(children: [
                  Expanded(
                    child: Text(
                      '${reais(l.valorCentavos)} foram mandados para este cartão ${diaPorExtenso(l.dia, hoje)} sem dizer que fatura pagam. '
                      'Hoje contam como crédito neste ciclo.',
                      style: t.bodySmall,
                    ),
                  ),
                  const SizedBox(width: Espacos.m),
                  BotaoPequeno(
                    'Pagar a de ${diaPorExtenso(alvo.vencimento, hoje)}',
                    cheio: true,
                    aoTocar: () => ref.read(repositorioProvider)?.gravar(l.copiar(pagaFaturaId: () => alvo.id)),
                  ),
                ]),
              ),
            ),
      ],
    );

    final listaDePagamentos = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Lista(filhos: [
          for (final l in pagamentos)
            Linha(
              antes: contas[l.contaId] == null ? null : SeloDaConta(conta: contas[l.contaId]!, membros: membros),
              titulo: 'Pago ${diaPorExtenso(l.dia, hoje)}',
              detalhe: contas[l.contaId]?.nome ?? '',
              direita: Text(reais(l.valorCentavos), style: Textos.valor(context)),
              aoTocar: () => abrirLancamento(context, ref, l),
            ),
        ]),
        const SizedBox(height: Espacos.p),
        Text(
          s.emParte
              ? '${reais(s.pagoCentavos)} pagos de ${reais(s.devidoCentavos)}. Os ${reais(s.levadoCentavos)} que faltaram foram para a próxima fatura.'
              : s.levadoCentavos < 0
                  ? '${reais(-s.levadoCentavos)} pagos a mais viraram crédito na próxima fatura.'
                  : s.paga
                      ? 'Fatura quitada.'
                      : '${reais(s.pagoCentavos)} já mandados para este cartão neste ciclo.',
          style: t.bodySmall,
        ),
      ],
    );

    final listaDeCompras = compras.isEmpty
        ? const Cartao(padding: EdgeInsets.zero, child: Vazio('Nenhuma compra nesta fatura.'))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Lista(filhos: [
                for (final (i, l) in compras.take(_visiveis).indexed) ...[
                  // Um divisor por dia, com o total das compras dele.
                  if (i == 0 || compras[i - 1].dia != l.dia)
                    CabecalhoDoDia(
                      dia: l.dia,
                      hoje: hoje,
                      direita: reais(compras.where((x) => x.dia == l.dia).fold<int>(0, (s, x) => s + naFatura(x))),
                    ),
                  LinhaDeLancamento(
                    lancamento: l,
                    hoje: hoje,
                    conta: cartao,
                    categoria: categorias[l.categoriaId],
                    semData: true,
                    onTap: () => abrirLancamento(context, ref, l),
                  ),
                ],
              ]),
              if (compras.length > _visiveis)
                Padding(
                  padding: const EdgeInsets.only(top: Espacos.m),
                  child: Center(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _visiveis += _passo),
                      child: Text('Mostrar mais ${(compras.length - _visiveis).clamp(0, _passo)} de ${compras.length - _visiveis}'),
                    ),
                  ),
                ),
              if (somaListada != f.totalCentavos)
                Padding(
                  padding: const EdgeInsets.only(top: Espacos.p),
                  child: Text(
                    'As compras listadas somam ${reais(somaListada)}. A diferença para o total pode vir de compras em fim de semana ou feriado perto do fechamento, que entram no ciclo seguinte, ou da dívida inicial do cartão.',
                    style: t.bodySmall,
                  ),
                ),
            ],
          );

    final blocoCategorias = fatias.isEmpty
        ? const Cartao(padding: EdgeInsets.zero, child: Vazio('Sem compras para agrupar.'))
        : Cartao(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: Raios.pilula,
                  child: SizedBox(
                    height: 12,
                    child: Row(children: [
                      for (final e in fatias)
                        Expanded(flex: (e.value * 1000 ~/ totalDasFatias).clamp(1, 1000), child: Container(color: corDe(e.key))),
                    ]),
                  ),
                ),
                const SizedBox(height: 6),
                for (final e in fatias)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      SeloDaCategoria(categoria: categorias[e.key]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(
                                  categorias[e.key]?.nome ?? 'Sem categoria',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(reais(e.value), style: Textos.valor(context)),
                            ]),
                            const SizedBox(height: 4),
                            Barra(e.value / totalDasFatias, cor: corDe(e.key)),
                            const SizedBox(height: 2),
                            Text(
                              '${(e.value * 100 / totalDasFatias).round()}% da fatura · '
                              '${switch (compras.where((l) => !l.ehTransferencia && l.categoriaId == e.key).length) {
                                1 => '1 compra',
                                final n => '$n compras',
                              }}',
                              style: t.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
              ],
            ),
          );

    return Scaffold(
      appBar: AppBar(title: Text('Fatura de ${cartao.nome}')),
      body: Pagina(
        larguraMaxima: 1100,
        centralizada: true,
        filhos: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SeloDaConta(conta: conta, membros: membros, tamanho: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${venceu ? 'Venceu' : 'Vence'} ${diaPorExtenso(f.vencimento, hoje)}',
                      style: t.bodyMedium?.copyWith(fontSize: 13, color: venceu ? c.atencao : c.tinta2),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(reais(s.devidoCentavos), style: Textos.numerao(context, tamanho: 34)),
                    ),
                    Text('Compras de ${diaPorExtenso(f.inicio, hoje)} a ${diaPorExtenso(f.fim, hoje)}', style: t.bodySmall),
                    if (s.transportadoCentavos != 0)
                      Text(
                        s.transportadoCentavos > 0
                            ? '${reais(f.totalCentavos)} em compras + ${reais(s.transportadoCentavos)} que ficaram da fatura anterior'
                            : '${reais(f.totalCentavos)} em compras − ${reais(-s.transportadoCentavos)} de crédito da fatura anterior',
                        style: t.bodySmall?.copyWith(color: s.transportadoCentavos > 0 ? c.atencao : c.positivo),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Espacos.m),
          Wrap(spacing: 6, runSpacing: 4, children: [
            if (s.emParte)
              const Etiqueta('Paga em parte', tom: Tom.atencao)
            else if (s.paga)
              const Etiqueta('Paga', tom: Tom.bom)
            else if (venceu)
              const Etiqueta('Atrasada', tom: Tom.atencao)
            else
              Etiqueta(aberta ? 'Aberta, fecha ${diaPorExtenso(f.fechamento, hoje)}' : 'Fechada', tom: aberta ? Tom.calor : Tom.neutro),
            if (s.emParte) Etiqueta('${reais(s.pagoCentavos)} pagos · ${reais(s.levadoCentavos)} na próxima fatura'),
            if (conferida != null)
              Etiqueta(
                conferida == f.totalCentavos ? 'Conferida' : 'Mudou depois da conferência',
                tom: conferida == f.totalCentavos ? Tom.bom : Tom.atencao,
              ),
            // Até quando o cartão foi conferido: é dali em diante que se olha no banco.
            if (conta.conferidoAte != null) Etiqueta('Cartão conferido até ${diaPorExtenso(conta.conferidoAte!, hoje)}'),
          ]),
          const SizedBox(height: Espacos.g),
          Wrap(spacing: Espacos.p, runSpacing: Espacos.p, children: [
            if (aPagar > 0)
              BotaoPequeno(
                '${s.emParte ? 'Completar com' : (aberta ? 'Adiantar' : 'Pagar')} ${reais(aPagar)}',
                icone: Icons.check_rounded,
                cheio: !aberta,
                aoTocar: () => _pagar(f, base: aPagar, aberta: aberta),
              ),
            BotaoPequeno('Lançar neste cartão', icone: Icons.add_rounded, cheio: aPagar <= 0 || aberta, aoTocar: () => abrirLancar(context, contaId: cartao.id)),
            BotaoPequeno('Importar fatura', icone: Icons.upload_file_rounded, aoTocar: () => abrirImportacao(context, contaId: cartao.id)),
            BotaoPequeno('Conferir total', icone: Icons.fact_check_outlined, aoTocar: () => _conferir(f)),
          ]),
          if ((ref.watch(entradaProvider).valueOrNull ?? const <ItemEntrada>[]).any((i) => i.contaId == cartao.id)) ...[
            const SizedBox(height: Espacos.xg),
            CaixaDeEntrada(contaId: cartao.id),
          ],
          if (s.emParte) ...[
            const SizedBox(height: Espacos.g),
            Cartao(
              cor: c.atencaoSuave,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${reais(s.levadoCentavos)} entraram no rotativo', style: t.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'O que não foi pago vai para a próxima fatura com juros, e os juros do rotativo do cartão estão entre os mais altos que existem. '
                    'Completar o pagamento agora sai mais barato do que qualquer aplicação rende. '
                    'Os juros aparecem como um lançamento do banco na próxima fatura.',
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Espacos.xg),
          if (soltas.isNotEmpty) avisoDeSoltas,
          if (mesa)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('Compras (${compras.length})', style: t.titleMedium),
                    const SizedBox(height: Espacos.p),
                    listaDeCompras,
                    if (pagamentos.isNotEmpty) ...[
                      const SizedBox(height: Espacos.xg),
                      Text('Pagamentos (${pagamentos.length})', style: t.titleMedium),
                      const SizedBox(height: Espacos.p),
                      listaDePagamentos,
                    ],
                    if (agendados.isNotEmpty) ...[
                      const SizedBox(height: Espacos.xg),
                      Text('Agendados (${agendados.length})', style: t.titleMedium),
                      const SizedBox(height: Espacos.p),
                      listaDeAgendados,
                    ],
                  ]),
                ),
                const SizedBox(width: Espacos.xg),
                Expanded(
                  flex: 2,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('Para onde foi', style: t.titleMedium),
                    const SizedBox(height: Espacos.p),
                    blocoCategorias,
                  ]),
                ),
              ],
            )
          else ...[
            Segmentos<String>(
              opcoes: [
                ('compras', 'Compras (${compras.length})'),
                if (agendados.isNotEmpty) ('agendados', 'Agendados (${agendados.length})'),
                if (pagamentos.isNotEmpty) ('pagamentos', 'Pagos (${pagamentos.length})'),
                ('categorias', 'Por categoria'),
              ],
              valor: _aba,
              aoMudar: (v) => setState(() => _aba = v),
            ),
            const SizedBox(height: Espacos.m),
            if (_aba == 'agendados' && agendados.isNotEmpty)
              listaDeAgendados
            else if (_aba == 'pagamentos' && pagamentos.isNotEmpty)
              listaDePagamentos
            else if (_aba == 'categorias')
              blocoCategorias
            else
              listaDeCompras,
          ],
        ],
      ),
    );
  }
}

/// Pagar a fatura: valor (pode ser parcial), data e conta de onde sai.
Future<void> pagarFatura(BuildContext context, WidgetRef ref, Conta cartao, Fatura f, {required int base, required bool aberta}) async {
  final repo = ref.read(repositorioProvider);
  if (repo == null) return;
  final hoje = ref.read(hojeProvider);
  final mensageiro = ScaffoldMessenger.of(context);
  final campo = TextEditingController(text: reais(base, comSimbolo: false));
  // Já vem selecionado: digitar substitui o valor sugerido em vez de emendar nele.
  campo.selection = TextSelection(baseOffset: 0, extentOffset: campo.text.length);
  var dia = hoje;
  Conta? origem = (ref.read(contasProvider).valueOrNull ?? const <Conta>[])
      .where((x) => x.id == ref.read(contaPadraoProvider) && x.ehDeUso)
      .firstOrNull;
  String? erro;

  final ok = await abrirFolha<bool>(
    context,
    (context) => StatefulBuilder(builder: (context, definir) {
      final t = Theme.of(context).textTheme;
      final c = Cores.de(context);
      final membros = ref.read(membrosProvider).valueOrNull ?? const <Membro>[];
      final valor = lerCentavos(campo.text);
      Widget seletor(String rotulo, Widget filho, VoidCallback aoTocar) => InkWell(
            borderRadius: Raios.m,
            onTap: aoTocar,
            child: InputDecorator(
              decoration: InputDecoration(labelText: rotulo, suffixIcon: const Icon(Icons.expand_more_rounded, size: 20)),
              child: filho,
            ),
          );
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Espacos.g, 0, Espacos.g, Espacos.g),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pagar fatura', style: t.titleLarge),
            Text('${cartao.nome} · a pagar ${reais(base)}', style: t.bodyMedium?.copyWith(fontSize: 13, color: c.tinta2)),
            const SizedBox(height: Espacos.m),
            TextField(
              controller: campo,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [const MascaraDeValor()],
              onChanged: (_) => definir(() => erro = null),
              decoration: InputDecoration(
                labelText: 'Valor pago',
                prefixText: r'R$ ',
                helperMaxLines: 3,
                helperText: valor == null || aberta || valor == base
                    ? null
                    : valor < base
                        ? 'Pagamento parcial: os ${reais(base - valor)} que faltam vão para a próxima fatura e pagam os juros do rotativo.'
                        : 'Os ${reais(valor - base)} a mais viram crédito na próxima fatura.',
              ),
            ),
            const SizedBox(height: Espacos.m),
            seletor('Data', Text(diaPorExtenso(dia, hoje), style: t.bodyMedium), () async {
              final escolhido = await escolherDia(context, dia);
              if (escolhido != null) definir(() => dia = escolhido);
            }),
            const SizedBox(height: Espacos.m),
            seletor(
              'Saiu de',
              Row(children: [
                if (origem != null) ...[SeloDaConta(conta: origem!, membros: membros, tamanho: 26), const SizedBox(width: 8)],
                Expanded(
                  child: Text(
                    origem == null ? 'Escolher' : (ref.read(nomesDasContasProvider)[origem!.id] ?? origem!.nome),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium,
                  ),
                ),
              ]),
              () async {
                final escolhida = await escolherConta(context, ref, titulo: 'Pagar com qual conta?', filtro: (x) => x.ehDeUso, atualId: origem?.id);
                if (escolhida != null) definir(() => origem = escolhida);
              },
            ),
            const SizedBox(height: 6),
            Text('Pagar a fatura não conta como gasto: as compras já contaram.', style: t.bodySmall),
            if (erro != null) ...[
              const SizedBox(height: Espacos.m),
              Text(erro!, style: t.bodyMedium?.copyWith(fontSize: 13, color: c.problema)),
            ],
            const SizedBox(height: Espacos.g),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
              onPressed: () {
                if (lerCentavos(campo.text) == null) return definir(() => erro = 'Informe o valor.');
                if (origem == null) return definir(() => erro = 'Escolha a conta de onde saiu.');
                Navigator.pop(context, true);
              },
              child: const Text('Confirmar pagamento'),
            ),
          ],
        ),
      );
    }),
    largura: 440,
  );
  final valor = lerCentavos(campo.text);
  campo.dispose();
  if (ok != true || valor == null || origem == null) return;

  final pagamento = Lancamento(
    id: const Uuid().v4(),
    tipo: 'transferencia',
    descricao: 'Fatura ${cartao.nome}',
    realizadoCentavos: valor,
    data: f.vencimento,
    dataEfetiva: dia,
    situacao: 'efetivado',
    contaId: origem!.id,
    contaDestinoId: cartao.id,
    // Fatura ainda aberta não tem o que pagar: o dinheiro abate o ciclo
    // (ou paga uma pendente mais antiga, se houver).
    pagaFaturaId: aberta ? null : f.id,
    autorId: ref.read(authProvider).valueOrNull?.uid,
  );
  await repo.gravar(pagamento);
  mensageiro
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      duration: const Duration(seconds: 8),
      content: Text('${reais(valor)} pagos com ${origem!.nome}.'),
      action: SnackBarAction(label: 'Desfazer', onPressed: () => repo.apagar(pagamento.id)),
    ));
}
