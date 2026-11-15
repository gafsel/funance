import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../dados/provedores.dart';
import '../dados/repositorio.dart';
import '../modelo/modelos.dart';
import '../regras/empresa.dart';
import '../regras/formatos.dart';
import '../tema/tema_novo.dart';
import 'detalhe.dart';
import 'formulario.dart';
import 'pecas.dart';

/// Visão da empresa: caixa previsto, o que está a receber e a pagar,
/// clientes e fornecedores, e o resultado do mês por centro de custo.
class TelaEmpresa extends ConsumerWidget {
  const TelaEmpresa({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = ref.watch(hojeProvider);
    final mes = hoje.substring(0, 7);
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final caixa = ref.watch(caixaPrevistoProvider);
    final previstos = ref.watch(previstosProvider).valueOrNull ?? const <Lancamento>[];
    final categorias = {for (final x in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) x.id: x};
    final contrapartes = ref.watch(contrapartesProvider).valueOrNull ?? const <Contraparte>[];
    final resumo = (ref.watch(resumosProvider).valueOrNull ?? const <ResumoMes>[]).where((r) => r.mes == mes).firstOrNull;
    final resultado = resultadoDoMes(resumo, categorias, ref.watch(proLaboreIdsProvider));
    final aReceber = porPrazo(previstos, hoje, aReceber: true);
    final aPagar = porPrazo(previstos, hoje, aReceber: false);

    final mesa = ehMesa(context);

    Widget numero(String rotulo, int centavos, {Color? cor, String? detalhe}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rotulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: texto.bodySmall),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(reais(centavos), style: Textos.numerao(context, tamanho: mesa ? 24 : 19).copyWith(color: cor)),
              ),
              if (detalhe != null) Text(detalhe, maxLines: 1, overflow: TextOverflow.ellipsis, style: texto.bodySmall),
            ],
          ),
        );

    Widget prazos(String titulo, Map<Prazo, int> totais) => Cartao(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: texto.titleMedium),
              const SizedBox(height: 6),
              for (final p in Prazo.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Expanded(child: Text(rotulosDePrazo[p]!, style: texto.bodyMedium?.copyWith(fontSize: 13, color: c.tinta2))),
                    Text(
                      reais(totais[p]!),
                      style: Textos.valor(context, tamanho: 13, cor: p == Prazo.vencido && totais[p]! > 0 ? c.atencao : c.tinta2),
                    ),
                  ]),
                ),
              const Divider(height: 14),
              Row(children: [
                Expanded(child: Text('Total', style: texto.titleSmall)),
                Text(reais(totais.values.fold(0, (s, v) => s + v)), style: Textos.valor(context)),
              ]),
            ],
          ),
        );

    Widget linhaDoResultado(String rotulo, int previsto, int realizado, {bool forte = false, Color? cor}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Expanded(
              flex: 5,
              child: Text(rotulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: forte ? texto.titleSmall : texto.bodyMedium?.copyWith(fontSize: 13.5)),
            ),
            Expanded(
              flex: 3,
              child: Text(previsto == 0 ? '—' : reais(previsto), maxLines: 1, textAlign: TextAlign.end, style: Textos.valor(context, tamanho: 12.5, cor: c.tinta3)),
            ),
            Expanded(
              flex: 3,
              child: Text(reais(realizado), maxLines: 1, textAlign: TextAlign.end, style: Textos.valor(context, tamanho: forte ? 14 : 13.5, cor: cor)),
            ),
          ]),
        );

    // Em aberto por cliente e fornecedor.
    final emAberto = <String, List<Lancamento>>{};
    for (final l in previstos) {
      if (l.contraparteId != null && !l.ehTransferencia) emAberto.putIfAbsent(l.contraparteId!, () => []).add(l);
    }
    final ordenadas = [...contrapartes]..sort((a, b) => a.nome.compareTo(b.nome));

    final blocoCaixa = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloDeSecao('Caixa previsto', detalhe: 'próximos 30 dias', semTopo: true),
        Cartao(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                numero('Em caixa hoje', caixa.hojeCentavos),
                const SizedBox(width: 10),
                numero(
                  'Ponto mais baixo',
                  caixa.minimoCentavos,
                  cor: caixa.minimoCentavos < 0 ? c.problema : null,
                  detalhe: caixa.diaDoMinimo == null ? 'hoje' : diaPorExtenso(caixa.diaDoMinimo!, hoje),
                ),
                const SizedBox(width: 10),
                numero('Em 30 dias', caixa.finalCentavos),
              ]),
              const SizedBox(height: 10),
              Text(
                caixa.minimoCentavos < 0
                    ? 'O caixa fica negativo ${diaPorExtenso(caixa.diaDoMinimo ?? hoje, hoje)}. Antecipe um recebimento ou adie um pagamento antes dessa data.'
                    : 'O caixa se mantém positivo no período.',
                style: texto.bodyMedium?.copyWith(fontSize: 13, color: caixa.minimoCentavos < 0 ? c.problema : c.tinta2),
              ),
              if (caixa.aReceberVencidoCentavos > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Etiqueta('${reais(caixa.aReceberVencidoCentavos)} a receber vencidos, fora da previsão', tom: Tom.atencao),
                ),
            ],
          ),
        ),
        const SizedBox(height: Espacos.m),
        if (mesa)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: prazos('A receber', aReceber)),
            const SizedBox(width: Espacos.m),
            Expanded(child: prazos('A pagar', aPagar)),
          ])
        else ...[
          prazos('A receber', aReceber),
          const SizedBox(height: Espacos.m),
          prazos('A pagar', aPagar),
        ],
        const TituloDeSecao('Clientes e fornecedores'),
        if (ordenadas.isEmpty)
          const Cartao(
            padding: EdgeInsets.zero,
            child: Vazio('Ninguém cadastrado ainda. Clientes e fornecedores são criados ao lançar, no modo avançado.'),
          )
        else
          Lista(filhos: [
            for (final x in ordenadas)
              Builder(builder: (context) {
                final itens = emAberto[x.id] ?? const <Lancamento>[];
                final total = itens.fold<int>(0, (s, l) => s + l.valorCentavos);
                final vencidos = itens.where((l) => l.data.compareTo(hoje) < 0).length;
                return Linha(
                  titulo: x.nome,
                  detalhe: itens.isEmpty
                      ? (x.tipo == 'cliente' ? 'Cliente · nada em aberto' : 'Fornecedor · nada em aberto')
                      : '${x.tipo == 'cliente' ? 'Cliente · a receber' : 'Fornecedor · a pagar'}'
                          '${vencidos > 0 ? ' · $vencidos ${vencidos == 1 ? 'vencido' : 'vencidos'}' : ''}',
                  corDoDetalhe: vencidos > 0 ? c.atencao : null,
                  direita: Text(reais(total), style: Textos.valor(context)),
                  aoTocar: () => Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => TelaContraparte(contraparte: x))),
                );
              }),
          ]),
      ],
    );

    final blocoResultado = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloDeSecao(
          'Resultado de ${nomeDoMes(mes)}',
          semTopo: mesa,
          acao: BotaoPequeno(
            'Pagar pró-labore',
            aoTocar: () => showDialog<void>(context: context, builder: (_) => const _PagarProLabore()),
          ),
        ),
        Cartao(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(children: [
                Expanded(flex: 5, child: Text('CENTRO DE CUSTO', style: Textos.sobrancelha(context))),
                Expanded(flex: 3, child: Text('PREVISTO', textAlign: TextAlign.end, style: Textos.sobrancelha(context))),
                Expanded(flex: 3, child: Text('REALIZADO', textAlign: TextAlign.end, style: Textos.sobrancelha(context))),
              ]),
            ),
            for (final (id, previsto, realizado) in resultado.receitas)
              linhaDoResultado(categorias[id]?.nome ?? 'Sem centro de custo', previsto, realizado, cor: c.positivo),
            for (final (id, previsto, realizado) in resultado.despesas)
              linhaDoResultado(categorias[id]?.nome ?? 'Sem centro de custo', previsto, realizado == 0 ? 0 : -realizado),
            if (resultado.receitas.isEmpty && resultado.despesas.isEmpty) const Vazio('Nenhum lançamento neste mês ainda.'),
            const Divider(),
            linhaDoResultado('Resultado', 0, resultado.antesDoProLaboreCentavos,
                forte: true, cor: resultado.antesDoProLaboreCentavos < 0 ? c.problema : c.tinta),
            linhaDoResultado('Pró-labore', resultado.proLabore.$1, resultado.proLabore.$2 == 0 ? 0 : -resultado.proLabore.$2),
            linhaDoResultado('Depois do pró-labore', 0, resultado.depoisDoProLaboreCentavos,
                forte: true, cor: resultado.depoisDoProLaboreCentavos < 0 ? c.atencao : c.tinta),
          ]),
        ),
        const SizedBox(height: 6),
        Text(
          'O pró-labore aparece à parte: o resultado mostra a operação; a retirada do dono vem depois.',
          style: texto.bodySmall,
        ),
      ],
    );

    if (mesa) {
      return Pagina(filhos: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: blocoCaixa),
            const SizedBox(width: Espacos.xg),
            Expanded(child: blocoResultado),
          ],
        ),
      ]);
    }
    return Pagina(filhos: [blocoCaixa, blocoResultado]);
  }
}

/// Um cliente ou fornecedor: o que está em aberto e, se houver atraso, a
/// mensagem de cobrança pronta para copiar.
class TelaContraparte extends ConsumerWidget {
  const TelaContraparte({super.key, required this.contraparte});
  final Contraparte contraparte;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = ref.watch(hojeProvider);
    final c = Cores.de(context);
    final texto = Theme.of(context).textTheme;
    final contas = {for (final x in ref.watch(contasProvider).valueOrNull ?? const <Conta>[]) x.id: x};
    final itens = (ref.watch(previstosProvider).valueOrNull ?? const <Lancamento>[])
        .where((l) => l.contraparteId == contraparte.id)
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));
    final vencidos = itens.where((l) => l.ehEntrada && l.data.compareTo(hoje) < 0).toList();
    final mensagem = vencidos.isEmpty ? null : mensagemDeCobranca(contraparte.nome, vencidos, hoje);

    return Scaffold(
      appBar: AppBar(title: Text(contraparte.nome)),
      body: Pagina(
        larguraMaxima: 640,
        centralizada: true,
        filhos: [
              if (mensagem != null) ...[
                Cartao(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Cobrança', style: texto.titleMedium),
                      Text('O app não envia nada. Copie e mande pelo canal que você usa com este cliente.', style: texto.bodySmall),
                      const SizedBox(height: Espacos.m),
                      Container(
                        padding: const EdgeInsets.all(Espacos.m),
                        decoration: BoxDecoration(color: c.suave, borderRadius: Raios.p),
                        child: SelectableText(mensagem, style: texto.bodyMedium),
                      ),
                      const SizedBox(height: Espacos.m),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                        onPressed: () async {
                          final mensageiro = ScaffoldMessenger.of(context);
                          var copiou = true;
                          try {
                            await Clipboard.setData(ClipboardData(text: mensagem));
                          } catch (_) {
                            // Alguns navegadores negam a área de transferência.
                            copiou = false;
                          }
                          mensageiro
                            ..clearSnackBars()
                            ..showSnackBar(SnackBar(
                              content: Text(copiou
                                  ? 'Mensagem copiada.'
                                  : 'O navegador não deixou copiar. Selecione o texto acima e copie.'),
                            ));
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copiar mensagem'),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: Espacos.m),
              ],
              const TituloDeSecao('Em aberto'),
              if (itens.isEmpty)
                const Cartao(padding: EdgeInsets.zero, child: Vazio('Nada em aberto.'))
              else
                Lista(filhos: [
                  for (final l in itens)
                    LinhaDeLancamento(
                      lancamento: l,
                      hoje: hoje,
                      conta: contas[l.contaId],
                      onTap: () => abrirLancamento(context, ref, l),
                    ),
                ]),
        ],
      ),
    );
  }
}

/// Pró-labore: a retirada sai da empresa e entra no espaço pessoal como um
/// par ligado, criado e desfeito junto.
class _PagarProLabore extends ConsumerStatefulWidget {
  const _PagarProLabore();

  @override
  ConsumerState<_PagarProLabore> createState() => _PagarProLaboreState();
}

class _PagarProLaboreState extends ConsumerState<_PagarProLabore> {
  final _valor = TextEditingController();
  String? _contaId;
  Espaco? _pessoal;
  Conta? _contaPessoal;
  String? _erro;
  bool _salvando = false;

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final repo = ref.read(repositorioProvider);
    final valor = lerCentavos(_valor.text);
    if (repo == null) return;
    if (valor == null) return setState(() => _erro = 'Informe o valor.');
    if (_contaId == null) return setState(() => _erro = 'Escolha a conta da empresa.');
    final proLabore = ref.read(proLaboreIdsProvider);
    if (proLabore.isEmpty) return setState(() => _erro = 'Crie um centro de custo chamado "Pró-labore" antes.');

    setState(() => _salvando = true);
    final hoje = ref.read(hojeProvider);
    final autor = ref.read(authProvider).valueOrNull?.uid;
    final vinculo = const Uuid().v4();
    final empresa = ref.read(espacoAtualProvider);
    final mensageiro = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    final saida = Lancamento(
      id: 'pl-$vinculo',
      tipo: 'saida',
      descricao: 'Pró-labore',
      realizadoCentavos: valor,
      data: hoje,
      dataEfetiva: hoje,
      situacao: 'efetivado',
      contaId: _contaId!,
      categoriaId: proLabore.first,
      autorId: autor,
      vinculoId: vinculo,
    );
    await repo.gravar(saida);

    Repositorio? repoPessoal;
    if (_pessoal != null && _contaPessoal != null) {
      repoPessoal = Repositorio(FirebaseFirestore.instance, _pessoal!.id);
      final categoriasPessoais = await repoPessoal.categorias().first;
      final salario = categoriasPessoais.where((x) => !x.arquivada && x.tipo == 'entrada').firstOrNull;
      await repoPessoal.gravar(Lancamento(
        id: 'pl-$vinculo',
        tipo: 'entrada',
        descricao: 'Pró-labore${empresa == null ? '' : ' · ${empresa.nome}'}',
        realizadoCentavos: valor,
        data: hoje,
        dataEfetiva: hoje,
        situacao: 'efetivado',
        contaId: _contaPessoal!.id,
        categoriaId: salario?.id,
        autorId: autor,
        vinculoId: vinculo,
      ));
    }

    navegador.pop();
    mensageiro
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 8),
        content: Text(repoPessoal == null
            ? 'Pró-labore lançado na empresa.'
            : 'Pró-labore lançado: saiu da empresa e entrou em ${_pessoal!.nome}.'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () async {
            await repo.apagar(saida.id);
            await repoPessoal?.apagar(saida.id);
          },
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final contas = (ref.watch(contasProvider).valueOrNull ?? const <Conta>[]).where((x) => x.ehDeUso && !x.arquivada).toList();
    final conta = contas.where((x) => x.id == _contaId).firstOrNull;
    final pessoais = (ref.watch(espacosProvider).valueOrNull ?? const <Espaco>[]).where((e) => !e.ehEmpresa).toList();

    Widget campo(String rotulo, String valor, VoidCallback aoTocar, {String? ajuda}) => InkWell(
          borderRadius: Raios.m,
          onTap: aoTocar,
          child: InputDecorator(
            decoration: InputDecoration(labelText: rotulo, helperText: ajuda, helperMaxLines: 2, suffixIcon: const Icon(Icons.expand_more_rounded)),
            child: Text(valor, style: texto.bodyLarge),
          ),
        );

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(Espacos.g),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(child: Text('Pagar pró-labore', style: texto.titleLarge)),
                IconButton(tooltip: 'Fechar', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ]),
              const SizedBox(height: Espacos.p),
              TextField(
                controller: _valor,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                decoration: const InputDecoration(labelText: 'Valor', prefixText: r'R$ '),
              ),
              const SizedBox(height: Espacos.m),
              campo('Sai da conta da empresa', conta?.nome ?? 'Escolher', () async {
                final escolhida = await escolher<Conta>(context, titulo: 'Conta da empresa', itens: contas, rotulo: (x) => x.nome, atual: conta);
                if (escolhida != null) setState(() => _contaId = escolhida.id);
              }),
              const SizedBox(height: Espacos.m),
              campo(
                'Entra no espaço pessoal',
                _pessoal == null ? 'Não lançar no pessoal' : '${_pessoal!.nome} · ${_contaPessoal?.nome ?? ''}',
                () async {
                  final espaco = await escolher<Espaco?>(context,
                      titulo: 'Espaço pessoal', itens: [null, ...pessoais], rotulo: (e) => e?.nome ?? 'Não lançar no pessoal', atual: _pessoal);
                  if (!context.mounted) return;
                  if (espaco == null) return setState(() => _pessoal = _contaPessoal = null);
                  final contasPessoais = (await Repositorio(FirebaseFirestore.instance, espaco.id).contas().first)
                      .where((x) => x.ehDeUso && !x.arquivada)
                      .toList();
                  if (!context.mounted) return;
                  final destino = await escolher<Conta>(context, titulo: 'Conta em ${espaco.nome}', itens: contasPessoais, rotulo: (x) => x.nome);
                  if (destino != null) {
                    setState(() {
                      _pessoal = espaco;
                      _contaPessoal = destino;
                    });
                  }
                },
                ajuda: 'Com um espaço pessoal escolhido, a retirada vira renda lá, ligada a este lançamento.',
              ),
              if (_erro != null) ...[
                const SizedBox(height: Espacos.m),
                Text(_erro!, style: texto.bodyMedium?.copyWith(color: c.problema)),
              ],
              const SizedBox(height: Espacos.g),
              FilledButton(onPressed: _salvando ? null : _salvar, child: const Text('Lançar pró-labore')),
            ],
          ),
        ),
      ),
    );
  }
}
