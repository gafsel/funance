import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../tema/tema_novo.dart';
import 'pecas.dart';

/// Segunda-feira da semana de `dia`, como chave.
String inicioDaSemana(String dia) => somarDias(dia, -(diaDaChave(dia).weekday - 1));

String marcaDaSemana(String dia) => 'semana-${inicioDaSemana(dia)}';

/// O que a revisão mostra: os últimos sete dias em quatro números.
class ResumoDaSemana {
  const ResumoDaSemana({
    required this.gastoCentavos,
    required this.maiores,
    required this.semCategoria,
    required this.vencidos,
  });

  final int gastoCentavos;

  /// (categoriaId ou `null`, total), do maior para o menor.
  final List<(String?, int)> maiores;
  final int semCategoria;
  final int vencidos;
}

ResumoDaSemana resumirSemana(Iterable<Lancamento> lancamentos, String hoje) {
  final desde = somarDias(hoje, -6);
  var gasto = 0;
  var semCategoria = 0;
  var vencidos = 0;
  final porCategoria = <String?, int>{};
  final vistos = <String>{};
  for (final l in lancamentos) {
    if (!vistos.add(l.id)) continue;
    if (l.previsto && l.data.compareTo(hoje) < 0) vencidos++;
    if (!l.efetivado || !l.ehSaida) continue;
    if (l.dia.compareTo(desde) < 0 || l.dia.compareTo(hoje) > 0) continue;
    gasto += l.valorCentavos;
    porCategoria[l.categoriaId] = (porCategoria[l.categoriaId] ?? 0) + l.valorCentavos;
    if (l.categoriaId == null) semCategoria++;
  }
  final maiores = porCategoria.entries.map((e) => (e.key, e.value)).toList()..sort((a, b) => b.$2.compareTo(a.$2));
  return ResumoDaSemana(gastoCentavos: gasto, maiores: maiores.take(3).toList(), semCategoria: semCategoria, vencidos: vencidos);
}

void abrirRevisao(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TelaRevisao()));

class TelaRevisao extends ConsumerWidget {
  const TelaRevisao({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = ref.watch(hojeProvider);
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final categorias = {for (final x in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) x.id: x};
    final resumo = resumirSemana([...ref.watch(recentesProvider), ...ref.watch(atrasadosProvider).valueOrNull ?? const <Lancamento>[]], hoje);
    final livre = ref.watch(livreProvider);
    final pendentes = ref.watch(entradaProvider).valueOrNull?.length ?? 0;
    final feita = ref.watch(marcasProvider).valueOrNull?.containsKey(marcaDaSemana(hoje)) ?? false;

    Widget item(IconData icone, String titulo, String detalhe, {bool atencao = false}) => ListTile(
          leading: Icon(icone, color: atencao ? c.atencao : c.tintaSuave),
          title: Text(titulo),
          subtitle: Text(detalhe),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Revisão da semana'), backgroundColor: c.fundo, surfaceTintColor: c.fundo),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(Espacos.g),
            children: [
              Text('Cinco minutos, uma vez por semana, para nada se acumular.', style: texto.bodyMedium),
              const SizedBox(height: Espacos.m),
              Cartao(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gasto nos últimos 7 dias', style: texto.bodyMedium?.copyWith(color: c.tintaSuave)),
                    Text(reais(resumo.gastoCentavos), style: texto.displaySmall),
                    if (resumo.maiores.isNotEmpty) ...[
                      const SizedBox(height: Espacos.p),
                      for (final (id, total) in resumo.maiores)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(children: [
                            Expanded(child: Text(categorias[id]?.nome ?? 'Sem categoria', style: texto.bodyMedium)),
                            Text(reais(total), style: texto.bodyMedium),
                          ]),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Espacos.m),
              Cartao(
                padding: const EdgeInsets.symmetric(vertical: Espacos.p),
                child: Column(children: [
                  item(
                    Icons.inbox_outlined,
                    pendentes == 0 ? 'Caixa de entrada vazia' : '$pendentes ${pendentes == 1 ? 'item' : 'itens'} na caixa de entrada',
                    pendentes == 0 ? 'Nada esperando confirmação.' : 'Confirme ou ignore na aba Entrada.',
                    atencao: pendentes > 0,
                  ),
                  item(
                    Icons.event_busy_outlined,
                    resumo.vencidos == 0 ? 'Nenhum agendado vencido' : '${resumo.vencidos} ${resumo.vencidos == 1 ? 'agendado venceu' : 'agendados venceram'}',
                    resumo.vencidos == 0 ? 'Tudo o que tinha data foi resolvido.' : 'Marque como pago, mude a data ou apague.',
                    atencao: resumo.vencidos > 0,
                  ),
                  item(
                    Icons.label_off_outlined,
                    resumo.semCategoria == 0 ? 'Tudo classificado' : '${resumo.semCategoria} ${resumo.semCategoria == 1 ? 'gasto sem categoria' : 'gastos sem categoria'}',
                    resumo.semCategoria == 0 ? 'Os gastos da semana têm categoria.' : 'Classifique na lista de lançamentos.',
                    atencao: resumo.semCategoria > 0,
                  ),
                  item(
                    Icons.savings_outlined,
                    '${reais(livre.livreCentavos)} livres até o fim do mês',
                    livre.livreCentavos < 0 ? 'O mês está apertado. Veja as opções no Início.' : 'Cerca de ${reais(livre.porDiaCentavos)} por dia.',
                    atencao: livre.livreCentavos < 0,
                  ),
                ]),
              ),
              const SizedBox(height: Espacos.g),
              FilledButton(
                onPressed: feita
                    ? null
                    : () async {
                        final navegador = Navigator.of(context);
                        await ref.read(repositorioProvider)?.marcar(marcaDaSemana(hoje), {'em': hoje});
                        navegador.pop();
                      },
                child: Text(feita ? 'Revisão desta semana já feita' : 'Revisão feita'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
