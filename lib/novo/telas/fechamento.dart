import '../caminhos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/mascara.dart';
import '../regras/formatos.dart';
import '../tema/tema_novo.dart';
import 'pecas.dart';

void abrirFechamento(BuildContext context, [String? mes]) =>
    Navigator.of(context).pushNamed(mes == null ? '/fechamento' : caminhoDoFechamento(mes));

/// Fechamento do mês: conferir cada conta com o extrato e travar o mês.
///
/// O mês só fecha quando três coisas são verdade: a caixa de entrada está
/// vazia, não sobrou agendado sem resolver e o saldo de cada conta bate com
/// o do extrato.
class TelaFechamento extends ConsumerStatefulWidget {
  const TelaFechamento({super.key, this.mes, this.embutida = false});

  /// Mês a fechar; sem ele, começa no mês de hoje.
  final String? mes;

  /// Dentro da casca (menu lateral), sem barra própria.
  final bool embutida;

  @override
  ConsumerState<TelaFechamento> createState() => _TelaFechamentoState();
}

class _TelaFechamentoState extends ConsumerState<TelaFechamento> {
  final _campos = <String, TextEditingController>{};
  String? _carregadoDe;
  String? _mes;

  @override
  void dispose() {
    for (final c in _campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Saldo digitado, com sinal. Vazio = ainda não conferido.
  int? _informado(String contaId) {
    final t = _campos[contaId]?.text.trim() ?? '';
    if (t.isEmpty) return null;
    final negativo = t.startsWith('-');
    final valor = lerCentavos(t.replaceFirst('-', '')) ?? (RegExp(r'^-?0+([.,]0+)?$').hasMatch(t) ? 0 : null);
    return valor == null ? null : (negativo ? -valor : valor);
  }

  @override
  Widget build(BuildContext context) {
    final mes = _mes ?? widget.mes ?? ref.watch(hojeProvider).substring(0, 7);
    final hoje = ref.watch(hojeProvider);
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final contas = (ref.watch(contasProvider).valueOrNull ?? const <Conta>[])
        .where((x) => !x.arquivada && !x.ehCartao)
        .toList();
    final membros = ref.watch(membrosProvider).valueOrNull ?? const <Membro>[];
    final eu = ref.watch(authProvider).valueOrNull?.uid;
    // As de quem está fechando primeiro; depois por banco, como no seletor.
    int ordem(Conta x) => x.donos.contains(eu) && !x.conjunta ? 0 : (x.donos.contains(eu) ? 1 : 2);
    contas.sort((a, b) {
      final o = ordem(a).compareTo(ordem(b));
      if (o != 0) return o;
      final banco = (a.banco ?? 'zz').compareTo(b.banco ?? 'zz');
      return banco != 0 ? banco : a.nome.compareTo(b.nome);
    });
    final saldos = ref.watch(saldosNoFimDoMesProvider(mes));
    final fechamento = (ref.watch(fechamentosProvider).valueOrNull ?? const <Fechamento>[]).where((f) => f.mes == mes && f.situacao != 'historico').firstOrNull;
    final pendentesNaCaixa = (ref.watch(entradaProvider).valueOrNull ?? const <ItemEntrada>[]).where((i) => i.data.startsWith(mes)).length;
    final agendados = (ref.watch(lancamentosDoMesProvider(mes)).valueOrNull ?? const <Lancamento>[])
        .where((l) => l.previsto && l.data.startsWith(mes) && l.data.compareTo(hoje) < 0)
        .length;

    // Ao entrar num mês, os campos mostram a conferência que já foi salva.
    if (_carregadoDe != mes && contas.isNotEmpty) {
      _carregadoDe = mes;
      for (final conta in contas) {
        final valor = fechamento?.extratoCentavos[conta.id];
        _campo(conta.id).text = valor == null ? '' : reais(valor, comSimbolo: false);
      }
    }

    final conferidas = contas.where((x) => _informado(x.id) != null).length;
    final batendo = contas.where((x) => _informado(x.id) == (saldos[x.id] ?? 0)).length;
    final mesAcabou = diaNoMes(mes, 31).compareTo(hoje) < 0;
    final podeFechar = pendentesNaCaixa == 0 && agendados == 0 && contas.isNotEmpty && batendo == contas.length;
    final fechado = fechamento?.fechado ?? false;

    Widget passo(bool ok, String certo, String falta) => Padding(
          padding: const EdgeInsets.symmetric(vertical: Espacos.xp),
          child: Row(children: [
            Icon(ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 20, color: ok ? c.positivo : c.tintaSuave),
            const SizedBox(width: Espacos.p),
            Expanded(child: Text(ok ? certo : falta, style: texto.bodyMedium)),
          ]),
        );

    Future<void> salvar({required bool fechar}) async {
      final repo = ref.read(repositorioProvider);
      if (repo == null) return;
      final mensageiro = ScaffoldMessenger.of(context);
      await repo.salvarFechamento(
        mes,
        extratoCentavos: {for (final x in contas) if (_informado(x.id) != null) x.id: _informado(x.id)!},
        fechado: fechar,
        autorId: ref.read(authProvider).valueOrNull?.uid,
      );
      mensageiro
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(fechar ? '${nomeDoMes(mes)} fechado.' : 'Conferência salva. O mês continua aberto.')));
    }

    final conteudo = <Widget>[
      Row(children: [
        IconButton(
          tooltip: 'Mês anterior',
          visualDensity: VisualDensity.compact,
          onPressed: () => setState(() => _mes = somarMeses(mes, -1)),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Flexible(child: Text('Fechar ${nomeDoMes(mes)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: texto.titleLarge)),
        IconButton(
          tooltip: 'Mês seguinte',
          visualDensity: VisualDensity.compact,
          onPressed: () => setState(() => _mes = somarMeses(mes, 1)),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        const Spacer(),
        if (fechado) const Etiqueta('Fechado', tom: Tom.bom),
      ]),
      const SizedBox(height: Espacos.m),
      Cartao(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fechado ? 'Mês fechado' : 'O que falta para fechar', style: texto.titleMedium),
            const SizedBox(height: Espacos.p),
            if (!mesAcabou && !fechado)
              Padding(
                padding: const EdgeInsets.only(bottom: Espacos.p),
                child: Text('O mês ainda não acabou: dá para conferir, mas o saldo ainda vai mudar.', style: texto.bodySmall),
              ),
            passo(pendentesNaCaixa == 0, 'Caixa de entrada vazia para este mês.',
                '$pendentesNaCaixa ${pendentesNaCaixa == 1 ? 'item' : 'itens'} na caixa de entrada esperando confirmação.'),
            passo(agendados == 0, 'Nenhum agendado vencido sem resolver.',
                '$agendados ${agendados == 1 ? 'agendado venceu' : 'agendados venceram'} e não ${agendados == 1 ? 'foi resolvido' : 'foram resolvidos'}.'),
            passo(contas.isNotEmpty && batendo == contas.length, 'Todas as contas batem com o extrato.',
                conferidas == 0 ? 'Informe abaixo o saldo de cada conta no fim do mês.' : '$batendo de ${contas.length} contas batem com o extrato.'),
          ],
        ),
      ),
      const TituloDeSecao('Saldo no fim do mês', detalhe: 'app × extrato'),
      if (contas.isEmpty)
        const Cartao(padding: EdgeInsets.zero, child: Vazio('Nenhuma conta para conferir.'))
      else
        Lista(filhos: [
          for (final conta in contas)
            Builder(builder: (context) {
              final calculado = saldos[conta.id] ?? 0;
              final informado = _informado(conta.id);
              final diferenca = informado == null ? null : informado - calculado;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      SeloDaConta(conta: conta, membros: membros),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(conta.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: texto.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            [titularidade(conta, membros, eu), 'No app: ${reais(calculado)}'].where((p) => p.isNotEmpty).join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: texto.bodySmall,
                          ),
                        ]),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 132,
                        child: TextField(
                          controller: _campo(conta.id),
                          enabled: !fechado,
                          textAlign: TextAlign.end,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          inputFormatters: [const MascaraDeValor(comSinal: true)],
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(hintText: 'No extrato'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 28,
                        child: diferenca == null
                            ? null
                            : Icon(
                                diferenca == 0 ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                                size: 20,
                                color: diferenca == 0 ? c.positivo : c.atencao,
                              ),
                      ),
                    ]),
                    if (diferenca != null && diferenca != 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          diferenca > 0
                              ? 'O extrato tem ${reais(diferenca)} a mais: falta lançar uma entrada, ou há uma saída a mais no app.'
                              : 'O extrato tem ${reais(-diferenca)} a menos: falta lançar uma saída, ou há uma entrada a mais no app.',
                          style: texto.bodySmall?.copyWith(color: c.atencao),
                        ),
                      ),
                  ],
                ),
              );
            }),
        ]),
      const SizedBox(height: Espacos.p),
      Text('Cartões de crédito são conferidos pela fatura, na tela do cartão.', style: texto.bodySmall),
      const SizedBox(height: Espacos.g),
      Acoes(filhos: [
        if (fechado)
          OutlinedButton(onPressed: () => salvar(fechar: false), child: const Text('Reabrir o mês'))
        else ...[
          FilledButton(onPressed: podeFechar ? () => salvar(fechar: true) : null, child: Text('Fechar ${nomeDoMes(mes)}')),
          OutlinedButton(onPressed: conferidas > 0 ? () => salvar(fechar: false) : null, child: const Text('Salvar e continuar depois')),
        ],
      ]),
    ];

    if (widget.embutida) return Pagina(larguraMaxima: 760, filhos: conteudo);
    return Scaffold(
      appBar: AppBar(title: const Text('Fechamento')),
      body: Pagina(larguraMaxima: 760, centralizada: true, filhos: conteudo),
    );
  }

  TextEditingController _campo(String contaId) => _campos.putIfAbsent(contaId, TextEditingController.new);
}
