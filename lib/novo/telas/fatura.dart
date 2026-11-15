import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../tema/tema_novo.dart';
import 'conta.dart';
import 'detalhe.dart';
import 'entrada.dart';
import 'lancar.dart';
import 'formulario.dart';
import 'pecas.dart';

void abrirCartao(BuildContext context, Conta cartao) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TelaCartao(cartao: cartao)));

/// Faturas de um cartão: a em aberto em destaque, as outras em lista.
class TelaCartao extends ConsumerWidget {
  const TelaCartao({super.key, required this.cartao});
  final Conta cartao;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = ref.watch(hojeProvider);
    final c = Cores.de(context);
    final faturas = (ref.watch(faturasProvider).valueOrNull ?? const <Fatura>[])
        .where((f) => f.contaId == cartao.id && (f.totalCentavos != 0 || f.pagoCentavos != 0))
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
          const TituloDeSecao('Faturas'),
          if (faturas.isEmpty)
            const Cartao(padding: EdgeInsets.zero, child: Vazio('Nenhuma fatura neste cartão ainda.'))
          else
            Lista(filhos: [
              for (final f in faturas)
                Linha(
                  titulo: 'Vence ${diaPorExtenso(f.vencimento, hoje)}',
                  detalhe: f.quitada
                      ? 'Paga'
                      : (f.fechamento.compareTo(hoje) > 0 ? 'Aberta, fecha ${diaPorExtenso(f.fechamento, hoje)}' : 'Fechada'),
                  corDoDetalhe: !f.quitada && f.vencimento.compareTo(hoje) < 0 ? c.atencao : null,
                  direita: Text(reais(f.totalCentavos), style: Textos.valor(context)),
                  aoTocar: () => Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => TelaFatura(cartao: cartao, faturaId: f.id))),
                ),
            ]),
        ],
      ),
    );
  }
}

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

  /// Pagar a fatura: valor (pode ser parcial), data e conta de onde sai.
  Future<void> _pagar(Fatura f) async {
    final repo = ref.read(repositorioProvider);
    if (repo == null) return;
    final hoje = ref.read(hojeProvider);
    final mensageiro = ScaffoldMessenger.of(context);
    final campo = TextEditingController(text: reais(f.abertoCentavos, comSimbolo: false));
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
              Text('${cartao.nome} · em aberto ${reais(f.abertoCentavos)}', style: t.bodyMedium?.copyWith(fontSize: 13, color: c.tinta2)),
              const SizedBox(height: Espacos.m),
              TextField(
                controller: campo,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                onChanged: (_) => definir(() => erro = null),
                decoration: InputDecoration(
                  labelText: 'Valor pago',
                  prefixText: r'R$ ',
                  helperText: valor != null && valor < f.abertoCentavos
                      ? 'Pagamento parcial: ficam ${reais(f.abertoCentavos - valor)} em aberto nesta fatura.'
                      : null,
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
      pagaFaturaId: f.id,
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
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
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
    final venceu = !f.quitada && f.vencimento.compareTo(hoje) < 0;
    final aberta = f.fechamento.compareTo(hoje) > 0;

    final listaDeCompras = compras.isEmpty
        ? const Cartao(padding: EdgeInsets.zero, child: Vazio('Nenhuma compra nesta fatura.'))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Lista(filhos: [
                for (final l in compras.take(_visiveis))
                  LinhaDeLancamento(
                    lancamento: l,
                    hoje: hoje,
                    conta: cartao,
                    categoria: categorias[l.categoriaId],
                    onTap: () => abrirLancamento(context, ref, l),
                  ),
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
                      child: Text(reais(f.totalCentavos), style: Textos.numerao(context, tamanho: 34)),
                    ),
                    Text('Compras de ${diaPorExtenso(f.inicio, hoje)} a ${diaPorExtenso(f.fim, hoje)}', style: t.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Espacos.m),
          Wrap(spacing: 6, runSpacing: 4, children: [
            if (f.quitada)
              const Etiqueta('Paga', tom: Tom.bom)
            else if (venceu)
              const Etiqueta('Atrasada', tom: Tom.atencao)
            else
              Etiqueta(aberta ? 'Aberta, fecha ${diaPorExtenso(f.fechamento, hoje)}' : 'Fechada', tom: aberta ? Tom.calor : Tom.neutro),
            if (f.pagoCentavos > 0 && !f.quitada) Etiqueta('${reais(f.pagoCentavos)} pagos · ${reais(f.abertoCentavos)} em aberto'),
            if (conferida != null)
              Etiqueta(
                conferida == f.totalCentavos ? 'Conferida' : 'Mudou depois da conferência',
                tom: conferida == f.totalCentavos ? Tom.bom : Tom.atencao,
              ),
          ]),
          const SizedBox(height: Espacos.g),
          Wrap(spacing: Espacos.p, runSpacing: Espacos.p, children: [
            if (f.abertoCentavos > 0)
              BotaoPequeno('Pagar ${reais(f.abertoCentavos)}', icone: Icons.check_rounded, cheio: true, aoTocar: () => _pagar(f)),
            BotaoPequeno('Lançar neste cartão', icone: Icons.add_rounded, cheio: f.abertoCentavos <= 0, aoTocar: () => abrirLancar(context, contaId: cartao.id)),
            BotaoPequeno('Importar fatura', icone: Icons.upload_file_rounded, aoTocar: () => abrirImportacao(context, contaId: cartao.id)),
            BotaoPequeno('Conferir total', icone: Icons.fact_check_outlined, aoTocar: () => _conferir(f)),
          ]),
          if ((ref.watch(entradaProvider).valueOrNull ?? const <ItemEntrada>[]).any((i) => i.contaId == cartao.id)) ...[
            const SizedBox(height: Espacos.xg),
            CaixaDeEntrada(contaId: cartao.id),
          ],
          const SizedBox(height: Espacos.xg),
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
              opcoes: [('compras', 'Compras (${compras.length})'), ('categorias', 'Por categoria')],
              valor: _aba,
              aoMudar: (v) => setState(() => _aba = v),
            ),
            const SizedBox(height: Espacos.m),
            if (_aba == 'compras') listaDeCompras else blocoCategorias,
          ],
        ],
      ),
    );
  }
}
