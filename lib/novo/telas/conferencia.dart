import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/observability/app_logger.dart';
import '../../firebase_ambiente.dart';
import '../caminhos.dart';
import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/conferencia.dart';
import '../regras/faturas.dart';
import '../regras/formatos.dart';
import '../regras/importar.dart';
import '../regras/mascara.dart';
import '../tema/tema_novo.dart';
import 'conta.dart';
import 'detalhe.dart';
import 'entrada.dart';
import 'fatura.dart';
import 'formulario.dart';
import 'lancar.dart';
import 'pecas.dart';

/// Conferência guiada: percorre as contas e os cartões na ordem em que a
/// pessoa confere no banco (as dela primeiro, por banco, o cartão antes da
/// conta) e ajuda a achar a diferença quando um saldo ou uma fatura não bate.

final _comprasDaFaturaProvider = StreamProvider.family<List<Lancamento>, Fatura>((ref, fatura) {
  final repo = ref.watch(repositorioProvider);
  return repo == null ? Stream.value(const []) : repo.comprasDaFatura(fatura);
});

/// Lançamentos feitos de um dia em diante (para o saldo dia a dia de uma conta).
final _feitosDesdeProvider = StreamProvider.family<List<Lancamento>, String>((ref, desde) {
  final repo = ref.watch(repositorioProvider);
  return repo == null ? Stream.value(const []) : repo.lancamentosEntre(desde, ref.watch(hojeProvider));
});

/// Lê um valor com sinal digitado num campo de saldo; nulo se vazio.
int? _lerSaldo(String texto) {
  final t = texto.trim();
  if (t.isEmpty) return null;
  final absoluto = lerCentavos(t.replaceFirst('-', '')) ?? (RegExp(r'^-?0+([.,]0+)?$').hasMatch(t) ? 0 : null);
  return absoluto == null ? null : (t.startsWith('-') ? -absoluto : absoluto);
}

/// Convite no início: quantos passos estão sem conferir há uma semana.
class ConviteParaConferir extends ConsumerWidget {
  const ConviteParaConferir({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    final hoje = ref.watch(hojeProvider);
    final passos = passosDaConferencia(
      ref.watch(contasProvider).valueOrNull ?? const <Conta>[],
      ref.watch(authProvider).valueOrNull?.uid,
      ref.watch(situacoesDasFaturasProvider),
    );
    final parados = passos.where((x) => (diasSemConferir(x, hoje) ?? 999) >= 7).length;
    if (passos.isEmpty || parados == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Espacos.p),
      child: Cartao(
        onTap: () => Navigator.of(context).pushNamed(caminhoDaConferencia),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Icon(Icons.fact_check_outlined, size: 18, color: c.tinta2),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$parados de ${passos.length} contas e faturas sem conferir há uma semana ou mais',
              style: t.bodyMedium?.copyWith(fontSize: 13),
            ),
          ),
          Text('Conferir', style: t.labelLarge?.copyWith(color: c.primaria)),
        ]),
      ),
    );
  }
}

/// Como chamar a fatura de um passo para ela não se confundir com a outra
/// do mesmo cartão: o mês em que vence e se está aberta ou fechada.
String _nomeDaFatura(SituacaoDaFatura s) =>
    'fatura de ${nomeDoMes(s.fatura.vencimento.substring(0, 7)).split(' ').first.toLowerCase()}, ${s.aberta ? 'aberta' : 'fechada'}';

class TelaConferencia extends ConsumerStatefulWidget {
  const TelaConferencia({super.key});

  @override
  ConsumerState<TelaConferencia> createState() => _TelaConferenciaState();
}

class _TelaConferenciaState extends ConsumerState<TelaConferencia> {
  /// O passo em que a pessoa está; nulo = o primeiro que ainda falta.
  String? _atual;

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    final hoje = ref.watch(hojeProvider);
    final eu = ref.watch(authProvider).valueOrNull?.uid;
    final membros = ref.watch(membrosProvider).valueOrNull ?? const <Membro>[];
    final passos = passosDaConferencia(
      ref.watch(contasProvider).valueOrNull ?? const <Conta>[],
      eu,
      ref.watch(situacoesDasFaturasProvider),
    );
    bool feito(Passo x) => diasSemConferir(x, hoje) == 0;
    final faltam = passos.where((x) => !feito(x)).toList();
    final atual = passos.where((x) => x.id == _atual).firstOrNull ?? faltam.firstOrNull ?? passos.firstOrNull;

    void proximo() {
      final depois = passos.skipWhile((x) => x.id != atual?.id).skip(1).where((x) => !feito(x)).firstOrNull;
      setState(() => _atual = depois?.id ?? faltam.where((x) => x.id != atual?.id).firstOrNull?.id);
    }

    final lista = Lista(filhos: [
      for (final x in passos)
        Linha(
          antes: SeloDaConta(conta: x.conta, membros: membros),
          // Cada fatura do cartão é um passo: o título diz qual é.
          // No roteiro o nome é curto para caber: "Cartão Nubank · nov fechada".
          titulo: x.fatura == null
              ? x.conta.nome
              : '${x.conta.nome} · ${mesAbreviado(x.fatura!.fatura.vencimento)} ${x.fatura!.aberta ? 'aberta' : 'fechada'}',
          // A data da conferência vem primeiro: é o que não pode ser cortado.
          detalhe: [
            switch (diasSemConferir(x, hoje)) {
              null => 'nunca conferida',
              0 => 'conferida hoje',
              _ => 'conferida até ${diaPorExtenso(x.conferidoAte!, hoje)}',
            },
            if (x.fatura == null) titularidade(x.conta, membros, eu),
          ].where((p) => p.isNotEmpty).join(' · '),
          corDoDetalhe: (diasSemConferir(x, hoje) ?? 999) >= 7 ? c.atencao : null,
          direita: Icon(
            feito(x) ? Icons.check_circle_rounded : (x.id == atual?.id ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded),
            size: 20,
            color: feito(x) ? c.positivo : (x.id == atual?.id ? c.primaria : c.tinta3),
          ),
          aoTocar: () => setState(() => _atual = x.id),
        ),
    ]);

    final painel = atual == null
        ? const Cartao(padding: EdgeInsets.zero, child: Vazio('Nenhuma conta para conferir.'))
        : atual.conta.ehCartao
            ? _PassoDoCartao(key: ValueKey(atual.id), cartao: atual.conta, fatura: atual.fatura, aoConcluir: proximo)
            : _PassoDaConta(key: ValueKey(atual.id), conta: atual.conta, aoConcluir: proximo);

    final resumo = Text(
      faltam.isEmpty
          ? 'Tudo conferido hoje. A ordem é por titular e banco; em cada banco, as faturas do cartão antes da conta.'
          : '${passos.length - faltam.length} de ${passos.length} conferidos hoje. A ordem é por titular e banco; em cada banco, as faturas do cartão antes da conta.',
      style: t.bodySmall,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Conferência')),
      body: Pagina(
        larguraMaxima: 1100,
        centralizada: true,
        filhos: ehMesa(context)
            ? [
                resumo,
                const SizedBox(height: Espacos.g),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 360, child: lista),
                  const SizedBox(width: Espacos.xg),
                  Expanded(child: painel),
                ]),
              ]
            : [resumo, const SizedBox(height: Espacos.g), painel, const TituloDeSecao('Roteiro'), lista],
      ),
    );
  }
}

/// Cabeçalho comum de um passo: a conta, um número grande e os atalhos.
class _Cabecalho extends ConsumerWidget {
  const _Cabecalho({required this.conta, required this.rotulo, required this.valor, required this.acoes, this.titulo});
  final Conta conta;

  /// No lugar do nome da conta (a fatura de um cartão diz qual é).
  final String? titulo;
  final String rotulo;
  final int valor;
  final List<Widget> acoes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final membros = ref.watch(membrosProvider).valueOrNull ?? const <Membro>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        SeloDaConta(conta: conta, membros: membros, tamanho: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo ?? conta.nome, style: t.titleMedium),
            Text(rotulo, style: t.bodySmall),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(reais(valor), style: Textos.numerao(context, tamanho: 28)),
            ),
          ]),
        ),
      ]),
      const SizedBox(height: Espacos.m),
      Wrap(spacing: Espacos.p, runSpacing: Espacos.p, children: acoes),
    ]);
  }
}

/// Até quando a conta foi conferida, em destaque: é a partir desse dia que
/// a pessoa precisa olhar no app do banco.
class _UltimaConferencia extends StatelessWidget {
  const _UltimaConferencia({required this.ate, required this.hoje, this.complemento, this.nunca});

  /// Até quando foi conferido; nulo se nunca foi.
  final String? ate;
  final String hoje;

  /// O que dizer quando nunca foi conferido.
  final String? nunca;

  /// O que ficou registrado naquela conferência (o saldo, o total da fatura).
  final String? complemento;

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    final ate = this.ate;
    final dias = ate == null ? null : diaDaChave(hoje).difference(diaDaChave(ate)).inDays;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: c.suave, borderRadius: Raios.m),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.event_available_rounded, size: 18, color: c.tinta2),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              ate == null
                  ? 'Nunca conferida'
                  : 'Última conferência: ${diaPorExtenso(ate, hoje)}'
                      '${dias == null || dias < 2 ? '' : ' (há $dias dias)'}',
              style: t.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              ate == null
                  ? (nunca ?? 'Confira no banco desde o começo do que está lançado aqui.')
                  : dias == 0
                      ? 'Já conferida hoje.${complemento == null ? '' : ' $complemento'}'
                      : 'No banco, olhe a partir de ${diaPorExtenso(somarDias(ate, 1), hoje)}.${complemento == null ? '' : ' $complemento'}',
              style: t.bodySmall,
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Campo "quanto o banco mostra" com o resultado da comparação embaixo.
class _CampoDoBanco extends StatelessWidget {
  const _CampoDoBanco({required this.controle, required this.rotulo, required this.noApp, required this.aoMudar, this.comSinal = false});
  final TextEditingController controle;
  final String rotulo;
  final int noApp;
  final VoidCallback aoMudar;
  final bool comSinal;

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    final informado = _lerSaldo(controle.text);
    final diferenca = informado == null ? null : informado - noApp;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        controller: controle,
        keyboardType: TextInputType.numberWithOptions(decimal: true, signed: comSinal),
        inputFormatters: [MascaraDeValor(comSinal: comSinal)],
        onChanged: (_) => aoMudar(),
        decoration: InputDecoration(labelText: rotulo, prefixText: r'R$ '),
      ),
      if (diferenca != null) ...[
        const SizedBox(height: Espacos.p),
        Text(
          diferenca == 0
              ? 'Bate com o app.'
              : diferenca > 0
                  ? 'O banco tem ${reais(diferenca, sempre: true)} a mais que o app.'
                  : 'O banco tem ${reais(-diferenca, sempre: true)} a menos que o app.',
          style: t.bodyMedium?.copyWith(fontSize: 13, color: diferenca == 0 ? c.positivo : c.atencao),
        ),
      ],
    ]);
  }
}

/// Uma fatura de um cartão: o total do banco contra o do app, o que foi
/// lançado nela desde a última vez que ela foi conferida, e o pagamento.
class _PassoDoCartao extends ConsumerStatefulWidget {
  const _PassoDoCartao({super.key, required this.cartao, required this.fatura, required this.aoConcluir});
  final Conta cartao;

  /// Nula quando o cartão não tem fatura a conferir.
  final SituacaoDaFatura? fatura;
  final VoidCallback aoConcluir;

  @override
  ConsumerState<_PassoDoCartao> createState() => _PassoDoCartaoState();
}

class _PassoDoCartaoState extends ConsumerState<_PassoDoCartao> {
  final _total = TextEditingController();

  @override
  void dispose() {
    _total.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    final cartao = widget.cartao;
    final hoje = ref.watch(hojeProvider);
    final repo = ref.watch(repositorioProvider);
    final categorias = {for (final x in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) x.id: x};
    final s = widget.fatura;

    if (s == null) {
      return Cartao(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(cartao.nome, style: t.titleMedium),
          const SizedBox(height: 4),
          Text('Sem fatura em aberto neste cartão. Se há compra nova no banco, lance e a fatura aparece aqui.', style: t.bodySmall),
          const SizedBox(height: Espacos.m),
          _UltimaConferencia(ate: cartao.conferidoAte, hoje: hoje),
          const SizedBox(height: Espacos.m),
          Acoes(filhos: [
            FilledButton(
              onPressed: () async {
                await repo?.gravarConta(cartao.id, {'conferidoAte': hoje});
                widget.aoConcluir();
              },
              child: const Text('Nada a conferir, próxima'),
            ),
            OutlinedButton(onPressed: () => abrirLancar(context, contaId: cartao.id), child: const Text('Lançar neste cartão')),
          ]),
        ]),
      );
    }

    final f = s.fatura;
    // A data é desta fatura: a fechada e a aberta do mesmo cartão são
    // conferidas em momentos diferentes.
    final desde = cartao.faturasConferidasEm[f.id];
    final carregando = ref.watch(_comprasDaFaturaProvider(f)).isLoading;
    final compras = (ref.watch(_comprasDaFaturaProvider(f)).valueOrNull ?? const <Lancamento>[])
        .where((l) => !l.ehTransferencia)
        .toList()
      ..sort((a, b) => b.dia.compareTo(a.dia));
    final novas = desde == null ? compras : compras.where((l) => l.dia.compareTo(desde) > 0).toList();
    final informado = _lerSaldo(_total.text);
    final bate = informado != null && informado == f.totalCentavos;
    final conferidaEm = cartao.faturasConferidas[f.id];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Cartao(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Cabecalho(
            conta: cartao,
            titulo: '${cartao.nome} · ${_nomeDaFatura(s)}',
            rotulo: s.aberta
                ? 'Fecha ${diaPorExtenso(f.fechamento, hoje)} · vence ${diaPorExtenso(f.vencimento, hoje)}'
                : 'Fechou ${diaPorExtenso(f.fechamento, hoje)} · ${s.atrasada ? 'venceu' : 'vence'} ${diaPorExtenso(f.vencimento, hoje)}'
                    '${s.paga ? ' · paga' : ' · sem pagamento'}',
            valor: f.totalCentavos,
            acoes: [
              BotaoPequeno('Lançar neste cartão', icone: Icons.add_rounded, cheio: true, aoTocar: () => abrirLancar(context, contaId: cartao.id)),
              BotaoPequeno('Importar fatura', icone: Icons.upload_file_rounded, aoTocar: () => abrirImportacao(context, contaId: cartao.id)),
              BotaoPequeno('Abrir a fatura', aoTocar: () => abrirFatura(context, cartao, f.id)),
            ],
          ),
          const SizedBox(height: Espacos.m),
          _UltimaConferencia(
            ate: desde,
            hoje: hoje,
            nunca: 'Esta fatura ainda não foi conferida. Confira no banco todas as compras dela, de ${diaPorExtenso(f.inicio, hoje)} a ${diaPorExtenso(f.fim, hoje)}.',
            complemento: conferidaEm == null ? null : 'O total era ${reais(conferidaEm)}.',
          ),
          if (s.transportadoCentavos != 0) ...[
            const SizedBox(height: Espacos.p),
            Text('Compras do ciclo. Com o que veio da fatura anterior, o devido é ${reais(s.devidoCentavos)}.', style: t.bodySmall),
          ],
          const SizedBox(height: Espacos.g),
          _CampoDoBanco(
            controle: _total,
            rotulo: 'Total das compras que o banco mostra',
            noApp: f.totalCentavos,
            aoMudar: () => setState(() {}),
          ),
          const SizedBox(height: Espacos.m),
          Acoes(filhos: [
            FilledButton(
              onPressed: !bate
                  ? null
                  : () async {
                      await repo?.gravarConta(cartao.id, {
                        'conferidoAte': hoje,
                        'faturasConferidas': {f.id: f.totalCentavos},
                        'faturasConferidasEm': {f.id: hoje},
                      });
                      widget.aoConcluir();
                    },
              child: const Text('Conferida, próxima'),
            ),
            if (informado != null && !bate)
              OutlinedButton(
                onPressed: () => abrirFolha<void>(context, (_) => _CompararFatura(cartao: cartao, fatura: f), largura: 620, alta: true),
                child: const Text('Comparar item a item'),
              ),
            // O pagamento sai da conta: registrado aqui, com o valor conferido,
            // ele já está certo quando a conta for conferida.
            if (s.pendente && s.aPagarCentavos > 0)
              OutlinedButton(
                onPressed: () => pagarFatura(context, ref, cartao, f, base: s.aPagarCentavos, aberta: false),
                child: Text('Registrar o pagamento de ${reais(s.aPagarCentavos, sempre: true)}'),
              ),
          ]),
        ]),
      ),
      TituloDeSecao(
        desde == null ? 'Compras desta fatura' : 'Lançado nesta fatura desde a última conferência',
        detalhe: desde == null ? '${compras.length}' : '${novas.length} desde ${diaPorExtenso(desde, hoje)}',
      ),
      if (carregando)
        const Cartao(child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))))
      else if (novas.isEmpty)
        Cartao(
          padding: EdgeInsets.zero,
          child: Vazio(desde == null ? 'Nenhuma compra nesta fatura.' : 'Nada lançado nesta fatura desde a última conferência dela.'),
        )
      else
        Lista(filhos: [
          for (final (i, l) in novas.take(30).indexed) ...[
            if (i == 0 || novas[i - 1].dia != l.dia) CabecalhoDoDia(dia: l.dia, hoje: hoje),
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
      if (novas.length > 30)
        Padding(
          padding: const EdgeInsets.only(top: Espacos.p),
          child: Text('Mostrando 30 de ${novas.length}. Abra a fatura para ver todas.', style: t.bodySmall?.copyWith(color: c.tinta3)),
        ),
    ]);
  }
}

/// Comparação da fatura do app com a do banco, item a item.
class _CompararFatura extends ConsumerStatefulWidget {
  const _CompararFatura({required this.cartao, required this.fatura});
  final Conta cartao;
  final Fatura fatura;

  @override
  ConsumerState<_CompararFatura> createState() => _CompararFaturaState();
}

class _CompararFaturaState extends ConsumerState<_CompararFatura> {
  final _texto = TextEditingController();
  bool _lendo = false;
  String? _erro;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _abrirArquivo() async {
    final escolha = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'ofx', 'csv', 'txt', 'tsv'],
      withData: true,
    );
    final arquivo = escolha?.files.single;
    final bytes = arquivo?.bytes;
    if (arquivo == null || bytes == null) return;
    if (!arquivo.name.toLowerCase().endsWith('.pdf')) {
      String conteudo;
      try {
        conteudo = utf8.decode(bytes);
      } on FormatException {
        conteudo = latin1.decode(bytes);
      }
      return setState(() => _texto.text = conteudo);
    }
    final espaco = ref.read(espacoAtualProvider);
    if (espaco == null) return;
    setState(() {
      _lendo = true;
      _erro = null;
    });
    try {
      final resposta = await funcoesDoAmbiente.httpsCallable('lerDocumento').call<Map<Object?, Object?>>({
        'espacoId': espaco.id,
        'pdfBase64': base64Encode(bytes),
        'hoje': ref.read(hojeProvider),
        'ehCartao': true,
      });
      if (mounted) setState(() => _texto.text = tabelaDoDocumento(resposta.data['linhas'] as List? ?? const []));
    } on FirebaseFunctionsException catch (erro, pilha) {
      AppLogger.error('Leitura de PDF falhou', erro, pilha);
      if (mounted) setState(() => _erro = erro.message ?? 'Não consegui ler o PDF agora.');
    } catch (erro, pilha) {
      AppLogger.error('Leitura de PDF falhou', erro, pilha);
      if (mounted) setState(() => _erro = 'Não consegui ler o PDF agora.');
    } finally {
      if (mounted) setState(() => _lendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    final hoje = ref.watch(hojeProvider);
    final repo = ref.watch(repositorioProvider);
    final cartao = widget.cartao;
    final compras = ref.watch(_comprasDaFaturaProvider(widget.fatura)).valueOrNull ?? const <Lancamento>[];
    final doBanco = _texto.text.trim().isEmpty ? null : lerExtrato(_texto.text, contaId: cartao.id, hoje: hoje);
    final comparacao = doBanco == null || doBanco.itens.isEmpty
        ? null
        : compararFatura([for (final l in compras) if (!l.ehTransferencia) l], doBanco.itens);

    Widget secao(String titulo, List<Widget> linhas) => linhas.isEmpty
        ? const SizedBox.shrink()
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [TituloDeSecao(titulo, detalhe: '${linhas.length}'), Lista(filhos: linhas)]);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Espacos.g, 0, Espacos.g, Espacos.g),
      children: [
        Text('Comparar com a fatura do banco', style: t.titleLarge),
        const SizedBox(height: 4),
        Text('Abra o arquivo da fatura ou cole as linhas dela. O app casa item a item e mostra só o que difere.', style: t.bodySmall),
        const SizedBox(height: Espacos.m),
        Row(children: [
          OutlinedButton.icon(
            onPressed: _lendo ? null : _abrirArquivo,
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Abrir arquivo (PDF, OFX ou CSV)'),
          ),
          if (_lendo) ...[
            const SizedBox(width: Espacos.m),
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ]),
        if (_erro != null) Padding(padding: const EdgeInsets.only(top: Espacos.p), child: Text(_erro!, style: t.bodySmall?.copyWith(color: c.atencao))),
        const SizedBox(height: Espacos.m),
        TextField(
          controller: _texto,
          minLines: 3,
          maxLines: 6,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Ou cole aqui as linhas da fatura:\n08/11/2026\tMercado\t384,50'),
        ),
        const SizedBox(height: Espacos.m),
        if (doBanco != null && doBanco.itens.isEmpty)
          Text('Não achei nenhuma linha com data e valor.', style: t.bodyMedium?.copyWith(color: c.atencao))
        else if (comparacao != null) ...[
          Text(
            comparacao.bate
                ? 'Os ${comparacao.iguais.length} itens batem um a um. Se o total ainda difere, confira se o arquivo é do mesmo ciclo.'
                : '${comparacao.iguais.length} ${comparacao.iguais.length == 1 ? 'item bate' : 'itens batem'}. O que difere está abaixo.',
            style: t.bodyMedium?.copyWith(color: comparacao.bate ? c.positivo : null),
          ),
          secao('Valor diferente', [
            for (final (l, item) in comparacao.valorDiferente)
              Linha(
                titulo: l.descricao.isEmpty ? item.descricao : l.descricao,
                detalhe: 'app ${reais(l.valorCentavos, sempre: true)} · banco ${reais(item.valorCentavos, sempre: true)}',
                direita: BotaoPequeno(
                  'Usar o do banco',
                  aoTocar: repo == null ? null : () => salvarEdicao(context, repo, l, l.copiar(realizadoCentavos: () => item.valorCentavos)),
                ),
                aoTocar: () => abrirLancamento(context, ref, l),
              ),
          ]),
          secao('No banco e não no app', [
            for (final item in comparacao.soNoBanco)
              Linha(
                titulo: item.descricao,
                detalhe: '${diaPorExtenso(item.data, hoje)} · ${reais(item.valorCentavos, sempre: true)}',
                direita: BotaoPequeno(
                  'Lançar',
                  cheio: true,
                  aoTocar: repo == null
                      ? null
                      : () => repo.gravar(Lancamento(
                            id: const Uuid().v4(),
                            tipo: item.tipo,
                            descricao: item.descricao,
                            realizadoCentavos: item.valorCentavos,
                            data: item.data,
                            dataEfetiva: item.data,
                            situacao: 'efetivado',
                            contaId: cartao.id,
                            origem: 'extrato',
                            autorId: ref.read(authProvider).valueOrNull?.uid,
                          )),
                ),
              ),
          ]),
          secao('No app e não no banco', [
            for (final l in comparacao.soNoApp)
              Linha(
                titulo: l.descricao.isEmpty ? 'Sem descrição' : l.descricao,
                detalhe: '${diaPorExtenso(l.dia, hoje)} · ${reais(l.valorCentavos, sempre: true)}',
                direita: BotaoPequeno('Abrir', aoTocar: () => abrirLancamento(context, ref, l)),
              ),
          ]),
        ],
      ],
    );
  }
}

class _PassoDaConta extends ConsumerStatefulWidget {
  const _PassoDaConta({super.key, required this.conta, required this.aoConcluir});
  final Conta conta;
  final VoidCallback aoConcluir;

  @override
  ConsumerState<_PassoDaConta> createState() => _PassoDaContaState();
}

class _PassoDaContaState extends ConsumerState<_PassoDaConta> {
  final _saldo = TextEditingController();
  final _noDia = TextEditingController();

  /// Último dia em que o saldo do banco bateu com o do app, e o primeiro em
  /// que não bateu. Nulos = a busca ainda não começou.
  String? _bate;
  String? _naoBate;

  @override
  void dispose() {
    _saldo.dispose();
    _noDia.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    final conta = widget.conta;
    final hoje = ref.watch(hojeProvider);
    final repo = ref.watch(repositorioProvider);
    final categorias = {for (final x in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) x.id: x};
    final saldoHoje = ref.watch(saldosProvider)[conta.id] ?? 0;
    final informado = _lerSaldo(_saldo.text);
    final bate = informado != null && informado == saldoHoje;

    // A busca parte da última conferência (quando o saldo batia). Sem
    // conferência anterior, olha os últimos 45 dias.
    final desde = conta.conferidoAte != null && conta.conferidoAte!.compareTo(hoje) < 0 ? conta.conferidoAte! : somarDias(hoje, -45);
    final feitos = (ref.watch(_feitosDesdeProvider(somarDias(desde, 1))).valueOrNull ?? const <Lancamento>[])
        .where((l) => l.efetivado && (l.contaId == conta.id || l.contaDestinoId == conta.id))
        .toList();
    final movimentoPorDia = <String, int>{};
    for (final l in feitos) {
      movimentoPorDia[l.dia] = (movimentoPorDia[l.dia] ?? 0) + movimentoNaConta(l, conta.id);
    }
    final saldos = saldosNoFimDeCadaDia(saldoHoje: saldoHoje, hoje: hoje, desde: desde, movimentoPorDia: movimentoPorDia);
    final ultimoQueBate = _bate ?? desde;
    final primeiroQueNao = _naoBate ?? hoje;
    final meio = diaDoMeio(ultimoQueBate, primeiroQueNao);
    final doDia = feitos.where((l) => l.dia == primeiroQueNao).toList();
    final dias = saldos.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Cartao(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Cabecalho(
            conta: conta,
            rotulo: 'Saldo no app hoje',
            valor: saldoHoje,
            acoes: [
              BotaoPequeno('Lançar nesta conta', icone: Icons.add_rounded, cheio: true, aoTocar: () => abrirLancar(context, contaId: conta.id)),
              BotaoPequeno('Importar extrato', icone: Icons.upload_file_rounded, aoTocar: () => abrirImportacao(context, contaId: conta.id)),
              BotaoPequeno('Abrir o extrato', aoTocar: () => abrirConta(context, conta.id)),
            ],
          ),
          const SizedBox(height: Espacos.m),
          _UltimaConferencia(
            ate: conta.conferidoAte,
            hoje: hoje,
            complemento: conta.conferidoSaldoCentavos == null ? null : 'O saldo era ${reais(conta.conferidoSaldoCentavos!)}.',
          ),
          const SizedBox(height: Espacos.g),
          _CampoDoBanco(
            controle: _saldo,
            rotulo: 'Saldo que o banco mostra agora',
            noApp: saldoHoje,
            comSinal: true,
            aoMudar: () => setState(() {
              _bate = null;
              _naoBate = null;
            }),
          ),
          const SizedBox(height: Espacos.m),
          Acoes(filhos: [
            FilledButton(
              onPressed: !bate
                  ? null
                  : () async {
                      await repo?.gravarConta(conta.id, {'conferidoAte': hoje, 'conferidoSaldoCentavos': informado});
                      widget.aoConcluir();
                    },
              child: const Text('Conferido, próxima'),
            ),
          ]),
        ]),
      ),
      if (informado != null && !bate) ...[
        const TituloDeSecao('Achar o dia da diferença'),
        Cartao(
          cor: c.atencaoSuave,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (meio != null) ...[
              Text(
                'Qual era o saldo no banco no fim de ${diaPorExtenso(meio, hoje)}?',
                style: t.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                'No app era ${reais(saldos[meio] ?? 0, sempre: true)}. Batia até ${diaPorExtenso(ultimoQueBate, hoje)}; a cada resposta o intervalo cai pela metade.',
                style: t.bodySmall,
              ),
              const SizedBox(height: Espacos.m),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _noDia,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    inputFormatters: const [MascaraDeValor(comSinal: true)],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Saldo no banco nesse dia', prefixText: r'R$ '),
                  ),
                ),
                const SizedBox(width: Espacos.m),
                FilledButton(
                  onPressed: _lerSaldo(_noDia.text) == null
                      ? null
                      : () => setState(() {
                            if (_lerSaldo(_noDia.text) == saldos[meio]) {
                              _bate = meio;
                            } else {
                              _naoBate = meio;
                            }
                            _noDia.clear();
                          }),
                  child: const Text('Responder'),
                ),
              ]),
            ] else ...[
              Text('A diferença aparece em ${diaPorExtenso(primeiroQueNao, hoje)}.', style: t.titleSmall),
              const SizedBox(height: 2),
              Text(
                doDia.isEmpty
                    ? 'O app não tem nenhum movimento nesse dia: falta lançar o que o banco mostra.'
                    : 'O saldo batia no fim de ${diaPorExtenso(ultimoQueBate, hoje)}. Confira os ${doDia.length} movimentos desse dia com o banco.',
                style: t.bodySmall,
              ),
              const SizedBox(height: Espacos.m),
              Wrap(spacing: Espacos.p, children: [
                BotaoPequeno('Lançar o que falta', cheio: true, aoTocar: () => abrirLancar(context, contaId: conta.id)),
                BotaoPequeno('Recomeçar a busca', aoTocar: () => setState(() {
                      _bate = null;
                      _naoBate = null;
                    })),
              ]),
            ],
          ]),
        ),
        if (meio == null && doDia.isNotEmpty) ...[
          const SizedBox(height: Espacos.p),
          Lista(filhos: [
            for (final l in doDia)
              LinhaDeLancamento(
                lancamento: l,
                hoje: hoje,
                conta: conta,
                categoria: categorias[l.categoriaId],
                semData: true,
                onTap: () => abrirLancamento(context, ref, l),
              ),
          ]),
        ],
        const TituloDeSecao('Saldo do app no fim de cada dia', detalhe: 'para bater com o banco'),
        Lista(filhos: [
          for (final dia in dias.take(46))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(children: [
                Icon(
                  dia.compareTo(ultimoQueBate) <= 0
                      ? Icons.check_rounded
                      : (dia.compareTo(primeiroQueNao) >= 0 ? Icons.close_rounded : Icons.remove_rounded),
                  size: 16,
                  color: dia.compareTo(ultimoQueBate) <= 0 ? c.positivo : (dia.compareTo(primeiroQueNao) >= 0 ? c.atencao : c.tinta3),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(diaPorExtenso(dia, hoje), style: t.bodyMedium?.copyWith(fontSize: 13))),
                if ((movimentoPorDia[dia] ?? 0) != 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      '${movimentoPorDia[dia]! > 0 ? '+' : ''}${reais(movimentoPorDia[dia]!)}',
                      style: t.bodySmall,
                    ),
                  ),
                Text(reais(saldos[dia] ?? 0), style: Textos.valor(context, tamanho: 13)),
              ]),
            ),
        ]),
      ],
    ]);
  }
}
