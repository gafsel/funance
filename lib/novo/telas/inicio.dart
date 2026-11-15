import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../tema/tema_novo.dart';
import 'detalhe.dart';
import 'fatura.dart';
import 'lancar.dart';
import 'pecas.dart';

class TelaInicio extends ConsumerWidget {
  const TelaInicio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = ref.watch(hojeProvider);
    final mes = hoje.substring(0, 7);
    final contas = (ref.watch(contasProvider).valueOrNull ?? const <Conta>[]).where((c) => !c.arquivada).toList();
    final categorias = {for (final c in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) c.id: c};
    final porId = {for (final c in contas) c.id: c};
    final saldos = ref.watch(saldosProvider);
    final faturas = ref.watch(faturasProvider).valueOrNull ?? const <Fatura>[];
    final doMes = ref.watch(lancamentosDoMesProvider(mes)).valueOrNull ?? const <Lancamento>[];
    final atrasados = ref.watch(atrasadosProvider).valueOrNull ?? const <Lancamento>[];

    final limite = somarDias(hoje, 7);
    final proximos = {
      for (final l in atrasados) l.id: l,
      for (final l in doMes)
        if (l.previsto && l.data.compareTo(limite) <= 0) l.id: l,
    }.values.toList()
      ..sort((a, b) => a.data.compareTo(b.data));

    final ultimos = doMes.where((l) => l.efetivado && l.dia.compareTo(hoje) <= 0).toList()
      ..sort((a, b) => b.dia.compareTo(a.dia));

    Widget linha(Lancamento l) => LinhaDeLancamento(
          lancamento: l,
          hoje: hoje,
          conta: porId[l.contaId],
          destino: porId[l.contaDestinoId],
          categoria: categorias[l.categoriaId],
          onTap: () => abrirLancamento(context, ref, l),
        );

    final livre = const _Livre();
    final blocoContas = _Contas(contas: contas, saldos: saldos, faturas: faturas, hoje: hoje);
    final blocoProximos = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloDeSecao('Próximos 7 dias'),
        Cartao(
          padding: EdgeInsets.zero,
          child: proximos.isEmpty
              ? const Vazio('Nada a pagar ou receber nos próximos dias.')
              : Column(children: [for (final l in proximos.take(8)) linha(l)]),
        ),
      ],
    );
    final blocoUltimos = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloDeSecao('Últimos lançamentos'),
        Cartao(
          padding: EdgeInsets.zero,
          child: ultimos.isEmpty
              ? Vazio(
                  'Nenhum lançamento neste mês ainda.',
                  acao: FilledButton(onPressed: () => abrirLancar(context), child: const Text('Lançar o primeiro')),
                )
              : Column(children: [for (final l in ultimos.take(8)) linha(l)]),
        ),
      ],
    );

    if (ehMesa(context)) {
      return ListView(
        padding: const EdgeInsets.all(Espacos.xg),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [livre, blocoProximos, blocoUltimos])),
              const SizedBox(width: Espacos.xg),
              Expanded(flex: 4, child: blocoContas),
            ],
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(Espacos.g, Espacos.g, Espacos.g, 96),
      children: [livre, blocoProximos, blocoContas, blocoUltimos],
    );
  }
}

/// O número central: quanto ainda dá para gastar neste mês.
class _Livre extends ConsumerStatefulWidget {
  const _Livre();

  @override
  ConsumerState<_Livre> createState() => _LivreState();
}

class _LivreState extends ConsumerState<_Livre> {
  bool _aberto = false;

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(livreProvider);
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final negativo = r.livreCentavos < 0;

    Widget parcela(String rotulo, int valor, {bool soma = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: Espacos.xp),
          child: Row(
            children: [
              Expanded(child: Text(rotulo, style: texto.bodyMedium)),
              Text('${soma ? '' : '− '}${reais(valor)}', style: texto.bodyMedium),
            ],
          ),
        );

    return Cartao(
      onTap: () => setState(() => _aberto = !_aberto),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Livre para gastar neste mês', style: texto.bodyMedium?.copyWith(color: c.tintaSuave)),
          const SizedBox(height: Espacos.xp),
          Text(
            reais(r.livreCentavos),
            style: texto.displaySmall?.copyWith(color: negativo ? c.atencao : c.tinta),
          ),
          const SizedBox(height: Espacos.xp),
          Text(
            r.rendaCentavos == 0
                ? r.explicacao
                : negativo
                    ? 'O mês está apertado: os compromissos e gastos já passam da renda lançada.'
                    : 'Dá cerca de ${reais(r.porDiaCentavos)} por dia até o fim do mês (${r.diasRestantes} dias).',
            style: texto.bodyMedium,
          ),
          if (_aberto && r.rendaCentavos > 0) ...[
            const Divider(height: Espacos.xg),
            parcela('Renda do mês', r.rendaCentavos, soma: true),
            parcela('Contas do mês', r.compromissosCentavos),
            parcela('Parcela das metas', r.metasCentavos),
            parcela('Já gasto', r.gastoCentavos),
          ] else if (r.rendaCentavos > 0)
            Padding(
              padding: const EdgeInsets.only(top: Espacos.p),
              child: Text('Ver a conta', style: texto.labelLarge?.copyWith(color: c.primaria)),
            ),
        ],
      ),
    );
  }
}

class _Contas extends StatelessWidget {
  const _Contas({required this.contas, required this.saldos, required this.faturas, required this.hoje});
  final List<Conta> contas;
  final Map<String, int> saldos;
  final List<Fatura> faturas;
  final String hoje;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final deUso = contas.where((x) => !x.ehCartao).toList();
    final cartoes = contas.where((x) => x.ehCartao).toList();

    Fatura? faturaAtual(Conta cartao) {
      final abertas = faturas.where((f) => f.contaId == cartao.id && f.abertoCentavos > 0 && f.vencimento.compareTo(somarMeses(hoje.substring(0, 7), 2)) < 0).toList()
        ..sort((a, b) => a.vencimento.compareTo(b.vencimento));
      return abertas.firstOrNull;
    }

    final reservado = cartoes.fold<int>(0, (soma, x) => soma + (faturaAtual(x)?.abertoCentavos ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloDeSecao('Contas'),
        Cartao(
          padding: const EdgeInsets.symmetric(vertical: Espacos.p),
          child: deUso.isEmpty
              ? const Vazio('Nenhuma conta cadastrada.')
              : Column(children: [
                  for (final x in deUso)
                    ListTile(
                      title: Text(x.nome),
                      subtitle: Text(x.tipo == 'divida' ? 'Dívida' : (x.tipo == 'investimento' ? 'Investimento' : 'Saldo')),
                      trailing: Text(
                        reais(saldos[x.id] ?? 0),
                        style: texto.titleMedium?.copyWith(color: (saldos[x.id] ?? 0) < 0 && x.tipo != 'divida' ? c.atencao : c.tinta),
                      ),
                    ),
                ]),
        ),
        if (cartoes.isNotEmpty) ...[
          const TituloDeSecao('Cartões'),
          Cartao(
            padding: const EdgeInsets.symmetric(vertical: Espacos.p),
            child: Column(children: [
              for (final x in cartoes)
                Builder(builder: (context) {
                  final f = faturaAtual(x);
                  return ListTile(
                    title: Text(x.nome),
                    subtitle: Text(f == null
                        ? 'Sem fatura em aberto'
                        : 'Fatura ${f.vencimento.compareTo(hoje) < 0 ? 'venceu' : 'vence'} ${diaPorExtenso(f.vencimento, hoje)}'),
                    trailing: Text(reais(f?.abertoCentavos ?? 0), style: texto.titleMedium),
                    onTap: () => abrirCartao(context, x),
                  );
                }),
              if (reservado > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Espacos.g, Espacos.p, Espacos.g, Espacos.p),
                  child: Text(
                    '${reais(reservado)} do saldo das contas já estão reservados para as faturas.',
                    style: texto.bodySmall,
                  ),
                ),
            ]),
          ),
        ],
      ],
    );
  }
}
