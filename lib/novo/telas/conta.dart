import '../caminhos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/mascara.dart';
import '../regras/formatos.dart';
import '../regras/livre.dart';
import '../tema/tema_novo.dart';
import 'detalhe.dart';
import 'entrada.dart';
import 'formulario.dart';
import 'lancar.dart';
import 'pecas.dart';

void abrirConta(BuildContext context, String contaId) =>
    Navigator.of(context).pushNamed(caminhoDaConta(contaId));

/// Movimento de uma conta num lançamento: positivo entra, negativo sai.
int movimentoNaConta(Lancamento l, String contaId) {
  final valor = l.realizadoCentavos ?? 0;
  var m = 0;
  if (l.contaId == contaId) m += l.ehEntrada ? valor : -valor;
  if (l.ehTransferencia && l.contaDestinoId == contaId) m += valor;
  return m;
}

/// Detalhe de uma conta: o extrato dela, com saldo corrido, e tudo o que se
/// faz no contexto dela — lançar, importar o extrato do banco, confirmar o
/// que veio e conferir o saldo.
class TelaConta extends ConsumerStatefulWidget {
  const TelaConta({super.key, required this.contaId});
  final String contaId;

  @override
  ConsumerState<TelaConta> createState() => _TelaContaState();
}

class _TelaContaState extends ConsumerState<TelaConta> {
  String? _mes;
  String _aba = 'extrato';

  /// Linhas do extrato à mostra; o resto vem com "Mostrar mais".
  int _visiveis = _passo;
  static const _passo = 40;

  @override
  Widget build(BuildContext context) {
    final hoje = ref.watch(hojeProvider);
    final mes = _mes ?? hoje.substring(0, 7);
    final t = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final conta = (ref.watch(contasProvider).valueOrNull ?? const <Conta>[]).where((x) => x.id == widget.contaId).firstOrNull;
    if (conta == null) {
      return Scaffold(appBar: AppBar(), body: const Vazio('Esta conta não existe mais.'));
    }
    final contasPorId = {for (final x in ref.watch(contasProvider).valueOrNull ?? const <Conta>[]) x.id: x};
    final membros = ref.watch(membrosProvider).valueOrNull ?? const <Membro>[];
    final eu = ref.watch(authProvider).valueOrNull?.uid;
    final categorias = {for (final x in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) x.id: x};
    final saldoHoje = ref.watch(saldosProvider)[conta.id] ?? 0;
    final saldoAntes = ref.watch(saldosNoFimDoMesProvider(somarMeses(mes, -1)))[conta.id] ?? 0;
    final doMes = (ref.watch(lancamentosDoMesProvider(mes)).valueOrNull ?? const <Lancamento>[])
        .where((l) => l.contaId == conta.id || l.contaDestinoId == conta.id)
        .toList();

    // Extrato: o que aconteceu no mês, em ordem, com o saldo depois de cada um.
    final feitos = doMes.where((l) => l.efetivado && l.dataEfetiva != null && l.dia.startsWith(mes)).toList()
      ..sort((a, b) => a.dia.compareTo(b.dia));
    var corrido = saldoAntes;
    final linhas = <(Lancamento, int)>[];
    for (final l in feitos) {
      corrido += movimentoNaConta(l, conta.id);
      linhas.add((l, corrido));
    }
    final agendados = doMes.where((l) => l.previsto && l.data.startsWith(mes)).toList()
      ..sort((a, b) => a.data.compareTo(b.data));
    final conferido = conta.conferidoAte;
    final desdeAConferencia = conferido == null ? null : feitos.where((l) => l.dia.compareTo(conferido) > 0).length;

    final mesa = ehMesa(context);
    final navegacaoDoMes = Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        tooltip: 'Mês anterior',
        visualDensity: VisualDensity.compact,
        onPressed: () => setState(() {
          _mes = somarMeses(mes, -1);
          _visiveis = _passo;
        }),
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      Text(nomeDoMes(mes), style: t.labelLarge),
      IconButton(
        tooltip: 'Mês seguinte',
        visualDensity: VisualDensity.compact,
        onPressed: () => setState(() {
          _mes = somarMeses(mes, 1);
          _visiveis = _passo;
        }),
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ]);

    final recentesPrimeiro = linhas.reversed.toList();
    final extrato = linhas.isEmpty
        ? Cartao(padding: EdgeInsets.zero, child: Vazio('Nenhum movimento em ${nomeDoMes(mes)}.'))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Lista(filhos: [
                Linha(
                  titulo: 'Saldo no fim de ${nomeDoMes(mes)}',
                  detalhe: 'Começou o mês com ${reais(saldoAntes)} · ${linhas.length} ${linhas.length == 1 ? 'movimento' : 'movimentos'}',
                  direita: Text(reais(corrido), style: Textos.valor(context)),
                ),
                for (final (l, saldo) in recentesPrimeiro.take(_visiveis))
                  Linha(
                    antes: l.ehTransferencia
                        ? Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(color: c.suave, shape: BoxShape.circle),
                            child: Icon(Icons.swap_horiz_rounded, size: 16, color: c.tinta2),
                          )
                        : SeloDaCategoria(categoria: categorias[l.categoriaId]),
                    titulo: l.descricao.isEmpty ? 'Sem descrição' : l.descricao,
                    // Numa transferência, o selo mostra a OUTRA conta.
                    antesDoDetalhe: l.ehTransferencia
                        ? SelosDoLancamento(
                            origem: contasPorId[l.contaId == conta.id ? l.contaDestinoId : l.contaId],
                            membros: membros,
                            tamanho: 20,
                          )
                        : null,
                    detalhe: [
                      if (l.ehTransferencia) (l.contaId == conta.id ? 'foi para' : 'veio de'),
                      diaPorExtenso(l.dia, hoje),
                      if (categorias[l.categoriaId] != null) categorias[l.categoriaId]!.nome,
                      if (l.parcelaNumero != null) '${l.parcelaNumero}/${l.parcelaTotal}',
                      if (conferido != null && l.dia.compareTo(conferido) <= 0) 'conferido',
                    ].join(' · '),
                    aoTocar: () => abrirLancamento(context, ref, l),
                    direita: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Builder(builder: (context) {
                          final m = movimentoNaConta(l, conta.id);
                          return Text('${m > 0 ? '+' : ''}${reais(m)}', style: Textos.valor(context, cor: m > 0 ? c.positivo : c.tinta));
                        }),
                        Text(reais(saldo), style: t.bodySmall),
                      ],
                    ),
                  ),
              ]),
              if (recentesPrimeiro.length > _visiveis)
                Padding(
                  padding: const EdgeInsets.only(top: Espacos.m),
                  child: Center(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _visiveis += _passo),
                      child: Text('Mostrar mais ${(recentesPrimeiro.length - _visiveis).clamp(0, _passo)} de ${recentesPrimeiro.length - _visiveis}'),
                    ),
                  ),
                ),
            ],
          );

    final listaDeAgendados = agendados.isEmpty
        ? Cartao(padding: EdgeInsets.zero, child: Vazio('Nada agendado nesta conta em ${nomeDoMes(mes)}.'))
        : Lista(filhos: [
            for (final l in agendados)
              LinhaDeLancamento(
                lancamento: l,
                hoje: hoje,
                conta: conta,
                categoria: categorias[l.categoriaId],
                onTap: () => abrirLancamento(context, ref, l),
              ),
          ]);

    return Scaffold(
      appBar: AppBar(
        title: Text(conta.nome),
        actions: [
          IconButton(tooltip: 'Editar conta', onPressed: () => _editar(conta, membros), icon: const Icon(Icons.edit_outlined, size: 20)),
        ],
      ),
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
                      [rotulosDeConta[conta.tipo] ?? conta.tipo, titularidade(conta, membros, eu)].where((p) => p.isNotEmpty).join(' · '),
                      style: t.bodyMedium?.copyWith(fontSize: 13, color: c.tinta2),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(reais(saldoHoje), style: Textos.numerao(context, tamanho: 34).copyWith(color: saldoHoje < 0 && conta.ehDeUso ? c.problema : c.tinta)),
                    ),
                    Text('saldo hoje', style: t.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Espacos.g),
          Wrap(spacing: Espacos.p, runSpacing: Espacos.p, children: [
            BotaoPequeno('Lançar nesta conta', icone: Icons.add_rounded, cheio: true, aoTocar: () => abrirLancar(context, contaId: conta.id)),
            BotaoPequeno('Importar extrato', icone: Icons.upload_file_rounded, aoTocar: () => abrirImportacao(context, contaId: conta.id)),
            BotaoPequeno('Conferir saldo', icone: Icons.fact_check_outlined, aoTocar: () => _conferir(conta)),
          ]),
          const SizedBox(height: Espacos.m),
          Cartao(
            cor: conferido == null ? c.suave : c.positivoSuave,
            semBorda: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Icon(
                conferido == null ? Icons.radio_button_unchecked_rounded : Icons.check_circle_rounded,
                size: 18,
                color: conferido == null ? c.tinta3 : c.positivo,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  conferido == null
                      ? 'Ainda não conferida com o extrato do banco.'
                      : 'Conferida até ${diaPorExtenso(conferido, hoje)}, com saldo de ${reais(conta.conferidoSaldoCentavos ?? 0)}.'
                          '${desdeAConferencia != null && desdeAConferencia > 0 && conferido.startsWith(mes) ? ' $desdeAConferencia ${desdeAConferencia == 1 ? 'lançamento' : 'lançamentos'} depois disso.' : ''}',
                  style: t.bodyMedium?.copyWith(fontSize: 13),
                ),
              ),
            ]),
          ),
          if ((ref.watch(entradaProvider).valueOrNull ?? const <ItemEntrada>[]).any((i) => i.contaId == conta.id)) ...[
            const SizedBox(height: Espacos.xg),
            CaixaDeEntrada(contaId: conta.id),
          ],
          const SizedBox(height: Espacos.xg),
          // Extrato e agendados em abas: com um mês cheio, os agendados não
          // podem ficar no fim de uma lista comprida. Na mesa, lado a lado.
          Row(children: [
            if (!mesa)
              Expanded(
                child: Segmentos<String>(
                  opcoes: [('extrato', 'Extrato (${linhas.length})'), ('agendados', 'Agendados (${agendados.length})')],
                  valor: _aba,
                  aoMudar: (v) => setState(() => _aba = v),
                ),
              )
            else
              Expanded(child: Text('Extrato', style: t.titleMedium)),
            if (mesa) navegacaoDoMes,
          ]),
          if (!mesa) Align(alignment: Alignment.centerLeft, child: navegacaoDoMes),
          const SizedBox(height: Espacos.p),
          if (mesa)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: extrato),
                const SizedBox(width: Espacos.xg),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Agendados (${agendados.length})', style: t.titleMedium),
                      const SizedBox(height: Espacos.p),
                      listaDeAgendados,
                    ],
                  ),
                ),
              ],
            )
          else if (_aba == 'extrato')
            extrato
          else
            listaDeAgendados,
        ],
      ),
    );
  }

  /// Saldo da conta no fim de um dia qualquer.
  Future<int> _saldoEm(Conta conta, String dia) async {
    final doMes = await ref.read(lancamentosDoMesProvider(dia.substring(0, 7)).future);
    return saldoDaConta(
      conta: conta,
      hoje: dia,
      resumos: ref.read(resumosProvider).valueOrNull ?? const [],
      lancamentosDoMes: doMes,
    );
  }

  /// Conferência com o extrato: a pessoa diz o saldo do banco num dia. Se
  /// bate, tudo até ali fica conferido e a próxima conferência parte dali.
  Future<void> _conferir(Conta conta) async {
    final hoje = ref.read(hojeProvider);
    final campo = TextEditingController();
    var dia = hoje;
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
              Text('Conferir ${conta.nome}', style: t.titleLarge),
              const SizedBox(height: 4),
              Text('Informe o saldo que o banco mostra num dia. Se bater com o app, tudo até esse dia fica conferido.', style: t.bodyMedium?.copyWith(fontSize: 13, color: c.tinta2)),
              const SizedBox(height: Espacos.m),
              InkWell(
                borderRadius: Raios.m,
                onTap: () async {
                  final escolhido = await escolherDia(context, dia);
                  if (escolhido != null) definir(() => dia = escolhido);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Dia', suffixIcon: Icon(Icons.expand_more_rounded, size: 20)),
                  child: Text(diaPorExtenso(dia, hoje), style: t.bodyMedium),
                ),
              ),
              const SizedBox(height: Espacos.m),
              TextField(
                controller: campo,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                inputFormatters: [const MascaraDeValor(comSinal: true)],
                decoration: const InputDecoration(labelText: 'Saldo no extrato do banco', prefixText: r'R$ '),
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
                    final texto = campo.text.trim();
                    final absoluto = lerCentavos(texto.replaceFirst('-', '')) ?? (RegExp(r'^-?0+([.,]0+)?$').hasMatch(texto) ? 0 : null);
                    if (absoluto == null) return definir(() => resultado = 'Informe o saldo do extrato.');
                    final informado = texto.startsWith('-') ? -absoluto : absoluto;
                    final noApp = await _saldoEm(conta, dia);
                    final diferenca = informado - noApp;
                    if (diferenca == 0) {
                      await ref.read(repositorioProvider)?.gravarConta(conta.id, {'conferidoAte': dia, 'conferidoSaldoCentavos': informado});
                      definir(() {
                        bate = true;
                        resultado = 'Bate. Conta conferida até ${diaPorExtenso(dia, hoje)}.';
                      });
                    } else {
                      definir(() {
                        bate = false;
                        resultado = 'No app o saldo desse dia é ${reais(noApp)}. '
                            '${diferenca > 0 ? 'O extrato tem ${reais(diferenca)} a mais: falta uma entrada, ou há uma saída a mais no app.' : 'O extrato tem ${reais(-diferenca)} a menos: falta uma saída, ou há uma entrada a mais no app.'} '
                            'Importe o extrato desta conta para achar a diferença linha a linha.';
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
      largura: 480,
    );
    campo.dispose();
  }

  /// Nome, apelido e titulares. Só quem tem acesso ao espaço pode ser titular.
  Future<void> _editar(Conta conta, List<Membro> membros) async {
    final nome = TextEditingController(text: conta.nome);
    final apelido = TextEditingController(text: conta.apelido ?? '');
    final donos = {...conta.donos};

    final salvar = await abrirFolha<bool>(
      context,
      (context) => StatefulBuilder(builder: (context, definir) {
        final t = Theme.of(context).textTheme;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Espacos.g, 0, Espacos.g, Espacos.g),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Editar conta', style: t.titleLarge),
              const SizedBox(height: Espacos.m),
              TextField(controller: nome, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nome')),
              const SizedBox(height: Espacos.m),
              TextField(
                controller: apelido,
                decoration: const InputDecoration(
                  labelText: 'Apelido para lançar por texto (opcional)',
                  helperText: 'Um jeito curto de citar esta conta numa frase, como "nu bia".',
                ),
              ),
              const TituloDeSecao('De quem é'),
              Lista(filhos: [
                for (final m in membros)
                  Linha(
                    antes: Avatar(membro: m, tamanho: 30, contorno: false),
                    titulo: m.nome ?? 'Sem nome',
                    direita: Icon(
                      donos.contains(m.uid) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      size: 22,
                      color: donos.contains(m.uid) ? Cores.de(context).primaria : Cores.de(context).tinta3,
                    ),
                    aoTocar: () => definir(() => donos.contains(m.uid) ? donos.remove(m.uid) : donos.add(m.uid)),
                  ),
              ]),
              const SizedBox(height: 6),
              Text('Com dois titulares, a conta aparece como conjunta.', style: t.bodySmall),
              const SizedBox(height: Espacos.g),
              Acoes(filhos: [FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salvar'))]),
            ],
          ),
        );
      }),
      largura: 480,
    );
    if (salvar == true && nome.text.trim().isNotEmpty) {
      await ref.read(repositorioProvider)?.gravarConta(conta.id, {
        'nome': nome.text.trim(),
        'apelido': apelido.text.trim().isEmpty ? null : apelido.text.trim(),
        // Mantém a ordem dos membros, para o selo mostrar sempre igual.
        'donos': [for (final m in membros) if (donos.contains(m.uid)) m.uid],
      });
    }
    nome.dispose();
    apelido.dispose();
  }
}
