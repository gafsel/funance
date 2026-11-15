import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../tema/tema_novo.dart';
import 'pecas.dart';

void abrirFechamento(BuildContext context, String mes) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TelaFechamento(mes: mes)));

/// Fechamento do mês: conferir cada conta com o extrato e travar o mês.
///
/// O mês só fecha quando três coisas são verdade: a caixa de entrada está
/// vazia, não sobrou agendado sem resolver e o saldo de cada conta bate com
/// o do extrato.
class TelaFechamento extends ConsumerStatefulWidget {
  const TelaFechamento({super.key, required this.mes});
  final String mes;

  @override
  ConsumerState<TelaFechamento> createState() => _TelaFechamentoState();
}

class _TelaFechamentoState extends ConsumerState<TelaFechamento> {
  final _campos = <String, TextEditingController>{};
  bool _carregado = false;

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
    final mes = widget.mes;
    final hoje = ref.watch(hojeProvider);
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final contas = (ref.watch(contasProvider).valueOrNull ?? const <Conta>[])
        .where((x) => !x.arquivada && !x.ehCartao)
        .toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    final saldos = ref.watch(saldosNoFimDoMesProvider(mes));
    final fechamento = (ref.watch(fechamentosProvider).valueOrNull ?? const <Fechamento>[]).where((f) => f.mes == mes && f.situacao != 'historico').firstOrNull;
    final pendentesNaCaixa = (ref.watch(entradaProvider).valueOrNull ?? const <ItemEntrada>[]).where((i) => i.data.startsWith(mes)).length;
    final agendados = (ref.watch(lancamentosDoMesProvider(mes)).valueOrNull ?? const <Lancamento>[])
        .where((l) => l.previsto && l.data.startsWith(mes) && l.data.compareTo(hoje) < 0)
        .length;

    if (!_carregado && fechamento != null && contas.isNotEmpty) {
      _carregado = true;
      for (final conta in contas) {
        final valor = fechamento.extratoCentavos[conta.id];
        if (valor != null) _campo(conta.id).text = reais(valor, comSimbolo: false);
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

    return Scaffold(
      appBar: AppBar(title: Text('Fechar ${nomeDoMes(mes)}'), backgroundColor: c.fundo, surfaceTintColor: c.fundo),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(Espacos.g),
            children: [
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
                        '$agendados ${agendados == 1 ? 'agendado venceu' : 'agendados venceram'} e não ${agendados == 1 ? 'foi marcado' : 'foram marcados'} como pago, nem apagado.'),
                    passo(contas.isNotEmpty && batendo == contas.length, 'Todas as contas batem com o extrato.',
                        conferidas == 0 ? 'Informe abaixo o saldo de cada conta no fim do mês.' : '$batendo de ${contas.length} contas batem com o extrato.'),
                  ],
                ),
              ),
              const TituloDeSecao('Saldo no fim do mês'),
              Cartao(
                padding: const EdgeInsets.symmetric(vertical: Espacos.p),
                child: Column(children: [
                  for (final conta in contas)
                    Builder(builder: (context) {
                      final calculado = saldos[conta.id] ?? 0;
                      final informado = _informado(conta.id);
                      final diferenca = informado == null ? null : informado - calculado;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Espacos.g, vertical: Espacos.p),
                        child: Wrap(
                          spacing: Espacos.g,
                          runSpacing: Espacos.p,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: 220,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(conta.nome, style: texto.bodyLarge),
                                Text('No app: ${reais(calculado)}', style: texto.bodySmall),
                              ]),
                            ),
                            SizedBox(
                              width: 180,
                              child: TextField(
                                controller: _campo(conta.id),
                                enabled: !fechado,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-\d.,]'))],
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(isDense: true, hintText: 'Saldo no extrato'),
                              ),
                            ),
                            if (diferenca != null)
                              Text(
                                diferenca == 0
                                    ? 'Bate.'
                                    : (diferenca > 0
                                        ? 'O extrato tem ${reais(diferenca)} a mais: falta lançar uma entrada, ou há uma saída a mais no app.'
                                        : 'O extrato tem ${reais(-diferenca)} a menos: falta lançar uma saída, ou há uma entrada a mais no app.'),
                                style: texto.bodySmall?.copyWith(color: diferenca == 0 ? c.positivo : c.atencao),
                              ),
                          ],
                        ),
                      );
                    }),
                  if (contas.isEmpty) const Vazio('Nenhuma conta para conferir.'),
                ]),
              ),
              const SizedBox(height: Espacos.m),
              Text('Cartões de crédito são conferidos pela fatura, na tela do cartão.', style: texto.bodySmall),
              const SizedBox(height: Espacos.g),
              if (fechado)
                OutlinedButton(onPressed: () => salvar(fechar: false), child: const Text('Reabrir o mês'))
              else ...[
                FilledButton(onPressed: podeFechar ? () => salvar(fechar: true) : null, child: Text('Fechar ${nomeDoMes(mes)}')),
                const SizedBox(height: Espacos.p),
                OutlinedButton(onPressed: conferidas > 0 ? () => salvar(fechar: false) : null, child: const Text('Salvar a conferência e continuar depois')),
              ],
            ],
          ),
        ),
      ),
    );
  }

  TextEditingController _campo(String contaId) => _campos.putIfAbsent(contaId, TextEditingController.new);
}
