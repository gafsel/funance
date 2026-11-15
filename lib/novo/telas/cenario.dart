import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../caminhos.dart';
import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/cenario.dart';
import '../regras/formatos.dart';
import '../regras/organizacao.dart';
import '../tema/tema_novo.dart';
import 'detalhe.dart';
import 'formulario.dart';
import 'pecas.dart';

/// Os blocos da "foto do mês" que abre o app. Cada um responde uma pergunta
/// com um número e um estado; tocar abre o detalhe.

final _comprometimentoProvider = Provider.family<Comprometimento, String>((ref, mes) {
  return calcularComprometimento(
    mes: mes,
    lancamentos: ref.watch(lancamentosDoMesProvider(mes)).valueOrNull ?? const <Lancamento>[],
    contas: {for (final c in ref.watch(contasProvider).valueOrNull ?? const <Conta>[]) c.id: c},
    faturas: ref.watch(situacoesDasFaturasProvider).values,
  );
});

final _restosProvider = Provider<(List<Resto>, Resto?)>((ref) {
  final mes = ref.watch(hojeProvider).substring(0, 7);
  final resumo = (ref.watch(resumosProvider).valueOrNull ?? const <ResumoMes>[]).where((r) => r.mes == mes).firstOrNull;
  final categorias = ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[];
  return (
    restosPorCategoria(resumo, categorias),
    restoDoEstiloDeVida(resumo, categorias, ref.watch(diagnosticoProvider)?.tetoCentavos('conforto')),
  );
});

final _pendenciasProvider = Provider<Pendencias>((ref) => calcularPendencias(
      ref.watch(previstosProvider).valueOrNull ?? const <Lancamento>[],
      ref.watch(hojeProvider),
    ));

/// Do que entra em cada mês, quanto já tem destino: contas e faturas.
/// Mostra o mês corrente e o seguinte, que é onde as faturas de agora caem.
class BlocoDoComprometimento extends ConsumerWidget {
  const BlocoDoComprometimento({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    final mes = ref.watch(hojeProvider).substring(0, 7);
    final meses = [mes, somarMeses(mes, 1)];

    Widget linha(String m) {
      final k = ref.watch(_comprometimentoProvider(m));
      final pct = k.percentual;
      final base = k.entraCentavos > k.comprometidoCentavos ? k.entraCentavos : k.comprometidoCentavos;
      final nome = nomeDoMes(m).split(' ').first;
      return InkWell(
        onTap: () => abrirFolha<void>(context, (_) => _DetalheDoComprometimento(k: k, mes: m), largura: 460),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(nome, style: t.titleSmall)),
              Text(
                pct == null ? (k.comprometidoCentavos > 0 ? 'sem entrada lançada' : 'nada lançado') : '$pct% do que entra',
                style: t.bodySmall?.copyWith(color: pct != null && pct > 100 ? c.atencao : null),
              ),
            ]),
            if (base > 0) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: Raios.pilula,
                child: SizedBox(
                  height: 10,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (k.contasCentavos > 0) Expanded(flex: k.contasCentavos, child: ColoredBox(color: c.primaria)),
                    if (k.faturasCentavos > 0) Expanded(flex: k.faturasCentavos, child: ColoredBox(color: c.calor)),
                    if (k.sobraCentavos > 0) Expanded(flex: k.sobraCentavos, child: ColoredBox(color: c.suave)),
                  ]),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(spacing: Espacos.g, runSpacing: 2, children: [
                _Legenda(cor: c.primaria, texto: 'Contas ${reais(k.contasCentavos)}'),
                _Legenda(cor: c.calor, texto: 'Faturas ${reais(k.faturasCentavos)}'),
                _Legenda(cor: c.tinta3, texto: 'Entra ${reais(k.entraCentavos)}'),
              ]),
              const SizedBox(height: 4),
              Text(
                k.sobraCentavos >= 0
                    ? 'Sobram ${reais(k.sobraCentavos)} depois do que já tem destino.'
                    : 'Faltam ${reais(-k.sobraCentavos)} para cobrir o que já tem destino.',
                style: t.bodySmall?.copyWith(color: k.sobraCentavos < 0 ? c.atencao : null),
              ),
            ],
          ]),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloDeSecao('Comprometimento', detalhe: 'este mês e o próximo'),
        Lista(filhos: [for (final m in meses) linha(m)]),
      ],
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.cor, required this.texto});
  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(texto, style: Theme.of(context).textTheme.bodySmall),
      ]);
}

class _DetalheDoComprometimento extends StatelessWidget {
  const _DetalheDoComprometimento({required this.k, required this.mes});
  final Comprometimento k;
  final String mes;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget linha(String rotulo, String valor, {bool forte = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(child: Text(rotulo, style: forte ? t.titleSmall : t.bodyMedium)),
            Text(valor, style: Textos.valor(context)),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(Espacos.g, 0, Espacos.g, Espacos.g),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Comprometimento de ${nomeDoMes(mes)}', style: t.titleLarge),
          const SizedBox(height: Espacos.m),
          linha('Entra no mês (recebido e a receber)', reais(k.entraCentavos)),
          linha('Sai das contas (pago e a pagar)', '− ${reais(k.contasCentavos)}'),
          linha('Faturas que vencem no mês', '− ${reais(k.faturasCentavos)}'),
          const Divider(height: Espacos.xg),
          linha(k.sobraCentavos >= 0 ? 'Sobra' : 'Falta', reais(k.sobraCentavos.abs()), forte: true),
          const SizedBox(height: Espacos.m),
          Text(
            'É uma conta de caixa: compra no cartão não entra aqui no dia da compra, e sim dentro da fatura. '
            'A parte das faturas é a que dá para ajustar gastando menos no cartão.',
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Quanto ainda dá em cada categoria com limite e no resto do estilo de vida.
///
/// Quem já atingiu ou passou do limite sai da lista e vai para uma caixa de
/// alerta só, com o selo de cada categoria: barra cheia não diz nada, e o
/// mesmo aviso repetido em três lugares também não.
class BlocoDoQuantoAindaDa extends ConsumerStatefulWidget {
  const BlocoDoQuantoAindaDa({super.key});

  @override
  ConsumerState<BlocoDoQuantoAindaDa> createState() => _BlocoDoQuantoAindaDaState();
}

class _BlocoDoQuantoAindaDaState extends ConsumerState<BlocoDoQuantoAindaDa> {
  /// Quantas categorias aparecem antes de "ver todas".
  static const _resumidas = 5;
  bool _todas = false;

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    final categorias = {for (final x in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) x.id: x};
    final (restos, estilo) = ref.watch(_restosProvider);
    String nomeDe(Resto r) => r.categoriaId == null ? 'Estilo de vida, o resto' : (categorias[r.categoriaId]?.nome ?? 'Categoria');

    final estouradas = [...restos.where((r) => r.passou), if (estilo != null && estilo.passou) estilo];
    final dentro = restos.where((r) => !r.passou).toList();
    final estiloDentro = estilo != null && !estilo.passou ? estilo : null;
    final visiveis = _todas ? dentro : dentro.take(_resumidas).toList();

    Widget linha(Resto r, {Widget? antes}) {
      final cor = r.perto ? c.atencao : c.primaria;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(children: [
          if (antes != null) ...[antes, const SizedBox(width: 10)],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text(nomeDe(r), maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall)),
                Text('restam ${reais(r.restaCentavos)}', style: Textos.valor(context, tamanho: 13, cor: r.perto ? c.atencao : c.tinta)),
              ]),
              const SizedBox(height: 5),
              Barra(r.fracao, cor: cor),
              const SizedBox(height: 3),
              Text('${reais(r.gastoCentavos)} de ${reais(r.limiteCentavos)}', style: t.bodySmall),
            ]),
          ),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloDeSecao('Quanto ainda dá'),
        if (estouradas.isNotEmpty) ...[
          Cartao(
            cor: c.problemaSuave,
            semBorda: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(
                estouradas.length == 1 ? 'Já atingiu o limite do mês' : '${estouradas.length} já atingiram o limite do mês',
                style: t.titleSmall?.copyWith(color: c.problema),
              ),
              const SizedBox(height: Espacos.p),
              for (final r in estouradas)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    if (r.categoriaId != null) ...[
                      SeloDaCategoria(categoria: categorias[r.categoriaId], tamanho: 26),
                      const SizedBox(width: 10),
                    ],
                    Expanded(child: Text(nomeDe(r), maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall)),
                    Text(
                      r.restaCentavos == 0 ? 'no limite de ${reais(r.limiteCentavos)}' : 'passou ${reais(-r.restaCentavos)} de ${reais(r.limiteCentavos)}',
                      style: t.bodySmall?.copyWith(color: c.problema),
                    ),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: Espacos.p),
        ],
        if (dentro.isEmpty && estiloDentro == null)
          if (estouradas.isEmpty)
            const Cartao(
              padding: EdgeInsets.zero,
              child: Vazio('Nenhuma categoria com limite ainda. A organização financeira sugere os limites para você.'),
            )
          else
            const SizedBox.shrink()
        else
          Lista(filhos: [
            for (final r in visiveis) linha(r, antes: SeloDaCategoria(categoria: categorias[r.categoriaId])),
            // O resto do estilo de vida (50-30-20) fica sempre à vista.
            if (estiloDentro != null) linha(estiloDentro),
            if (dentro.length > _resumidas)
              InkWell(
                onTap: () => setState(() => _todas = !_todas),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    _todas ? 'Mostrar só as $_resumidas mais apertadas' : 'Ver todas as ${dentro.length} categorias',
                    style: t.labelLarge?.copyWith(color: c.primaria),
                  ),
                ),
              ),
          ]),
      ],
    );
  }
}

/// O que está atrasado e o que vence nos próximos sete dias, em dois
/// totais. Tocar abre a lista, com o botão de pagar.
class BlocoDasPendencias extends ConsumerWidget {
  const BlocoDasPendencias({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    final p = ref.watch(_pendenciasProvider);

    Widget total(String rotulo, List<Lancamento> itens, int centavos, {required bool atrasado}) => Expanded(
          child: Cartao(
            onTap: itens.isEmpty
                ? null
                : () => abrirFolha<void>(context, (_) => _ListaDePendencias(atrasados: atrasado), largura: 520, alta: true),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '$rotulo · ${itens.length}',
                style: t.bodySmall?.copyWith(color: atrasado && itens.isNotEmpty ? c.atencao : null),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(reais(centavos), style: Textos.valor(context, tamanho: 18)),
              ),
            ]),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloDeSecao('Contas a pagar'),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          total('Atrasado', p.atrasados, p.atrasadoCentavos, atrasado: true),
          const SizedBox(width: Espacos.p),
          total('Próximos 7 dias', p.proximos, p.proximoCentavos, atrasado: false),
        ]),
      ],
    );
  }
}

class _ListaDePendencias extends ConsumerWidget {
  const _ListaDePendencias({required this.atrasados});
  final bool atrasados;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = ref.watch(hojeProvider);
    final p = ref.watch(_pendenciasProvider);
    final itens = atrasados ? p.atrasados : p.proximos;
    final contas = {for (final x in ref.watch(contasProvider).valueOrNull ?? const <Conta>[]) x.id: x};
    final categorias = {for (final x in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) x.id: x};
    final t = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Espacos.g, 0, Espacos.g, Espacos.g),
      children: [
        Text(atrasados ? 'Atrasado' : 'Próximos 7 dias', style: t.titleLarge),
        const SizedBox(height: Espacos.m),
        if (itens.isEmpty)
          const Cartao(padding: EdgeInsets.zero, child: Vazio('Nada por aqui.'))
        else
          Lista(filhos: [
            for (final l in itens)
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

/// O convite para a organização financeira, de três em três meses.
class ConviteParaOrganizar extends ConsumerWidget {
  const ConviteParaOrganizar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    final hoje = ref.watch(hojeProvider);
    final marcas = ref.watch(marcasProvider);
    final marca = marcas.valueOrNull?['organizacao'];
    final espaco = ref.watch(espacoAtualProvider);
    if (!marcas.hasValue || espaco == null || espaco.ehEmpresa) return const SizedBox.shrink();
    if (!horaDeOrganizar(hoje: hoje, feitaEm: marca?['feitaEm'] as String?, adiadaEm: marca?['adiadaEm'] as String?)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: Espacos.g),
      child: Cartao(
        cor: c.primariaSuave,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(marca?['feitaEm'] == null ? 'Vamos organizar as finanças?' : 'Hora de rever a organização', style: t.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Três minutos: você confere a renda e os gastos fixos, e o app sugere um limite saudável para cada categoria.',
            style: t.bodySmall,
          ),
          const SizedBox(height: Espacos.m),
          Wrap(spacing: Espacos.p, children: [
            BotaoPequeno('Organizar agora', cheio: true, aoTocar: () => Navigator.of(context).pushNamed(caminhoDaOrganizacao)),
            BotaoPequeno('Agora não', aoTocar: () => ref.read(repositorioProvider)?.marcar('organizacao', {'adiadaEm': hoje})),
          ]),
        ]),
      ),
    );
  }
}
