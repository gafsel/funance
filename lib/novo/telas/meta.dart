import '../caminhos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../regras/metas.dart';
import '../regras/relatorios.dart';
import '../tema/tema_novo.dart';
import 'conta.dart';
import 'detalhe.dart';
import 'formulario.dart';
import 'metas.dart';
import 'pecas.dart';

const _abreviados = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

void abrirMeta(BuildContext context, String metaId) =>
    Navigator.of(context).pushNamed(caminhoDaMeta(metaId));

/// Detalhe de uma meta: quanto falta, se o ritmo dá, o que entrou mês a mês
/// na conta ligada e os lançamentos que a moveram. O botão de guardar já
/// lança na conta certa.
class TelaMeta extends ConsumerWidget {
  const TelaMeta({super.key, required this.metaId});
  final String metaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = ref.watch(hojeProvider);
    final t = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final meta = (ref.watch(metasProvider).valueOrNull ?? const <Meta>[]).where((m) => m.id == metaId).firstOrNull;
    if (meta == null) return Scaffold(appBar: AppBar(), body: const Vazio('Esta meta não existe mais.'));

    final contas = {for (final x in ref.watch(contasProvider).valueOrNull ?? const <Conta>[]) x.id: x};
    final membros = ref.watch(membrosProvider).valueOrNull ?? const <Membro>[];
    final categorias = {for (final x in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) x.id: x};
    final resumos = ref.watch(resumosProvider).valueOrNull ?? const <ResumoMes>[];
    final conta = contas[meta.contaId];
    final p = progressoDaMeta(meta, hoje: hoje, contas: contas, saldos: ref.watch(saldosProvider), resumos: resumos);
    final porMes = {for (final r in resumos) r.mes: r};
    final mes = hoje.substring(0, 7);

    // O que a conta ligada (ou a categoria) andou em cada mês.
    final serie = meta.tipo == 'reduzirGasto'
        ? serieMensal(resumos, mes, categoriaId: meta.categoriaId)
        : [
            for (var i = 5; i >= 0; i--)
              (somarMeses(mes, -i), conta == null ? 0 : (porMes[somarMeses(mes, -i)]?.deltaPorConta[conta.id] ?? 0)),
          ];
    final teto = serie.fold<int>(1, (m, x) => x.$2.abs() > m ? x.$2.abs() : m);
    final relacionados = ref
        .watch(recentesProvider)
        .where((l) =>
            l.efetivado &&
            (meta.tipo == 'reduzirGasto'
                ? l.categoriaId != null && l.categoriaId == meta.categoriaId
                : conta != null && (l.contaId == conta.id || l.contaDestinoId == conta.id)))
        .toList()
      ..sort((a, b) => b.dia.compareTo(a.dia));
    final podeGuardar = conta != null && (meta.tipo == 'juntar' || meta.tipo == 'quitar') && !p.atingida;

    return Scaffold(
      appBar: AppBar(
        title: Text(meta.nome),
        actions: [
          IconButton(tooltip: 'Editar meta', onPressed: () => editarMeta(context, ref, meta), icon: const Icon(Icons.edit_outlined, size: 20)),
        ],
      ),
      body: Pagina(
        larguraMaxima: 720,
        centralizada: true,
        filhos: [
          Text(
            p.menorEhMelhor ? 'Gasto no período' : (meta.tipo == 'quitar' ? 'Já quitado' : 'Já guardado'),
            style: t.bodyMedium?.copyWith(fontSize: 13, color: c.tinta2),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(reais(p.atualCentavos), style: Textos.numerao(context, tamanho: 38)),
          ),
          Text('de ${reais(p.alvoCentavos)} · até ${diaPorExtenso(meta.prazo, hoje)}', style: t.bodyMedium?.copyWith(color: c.tinta2)),
          const SizedBox(height: Espacos.m),
          Barra(p.fracao, cor: p.menorEhMelhor && !p.atingida ? c.atencao : null),
          const SizedBox(height: Espacos.m),
          Cartao(
            cor: p.atingida && !p.menorEhMelhor ? c.positivoSuave : c.suave,
            semBorda: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(situacaoDaMeta(meta, p, hoje), style: t.bodyMedium?.copyWith(fontSize: 13)),
          ),
          const SizedBox(height: Espacos.m),
          Wrap(spacing: Espacos.p, runSpacing: Espacos.p, children: [
            if (podeGuardar)
              BotaoPequeno(
                meta.tipo == 'quitar' ? 'Pagar parcela' : 'Guardar agora',
                icone: Icons.add_rounded,
                cheio: true,
                aoTocar: () => _guardar(context, ref, meta, conta, p),
              ),
            if (conta != null) BotaoPequeno('Ver a conta', aoTocar: () => abrirConta(context, conta.id)),
          ]),
          if (conta != null) ...[
            const TituloDeSecao('Onde o dinheiro fica'),
            Lista(filhos: [
              Linha(
                antes: SeloDaConta(conta: conta, membros: membros),
                titulo: ref.watch(nomesDasContasProvider)[conta.id] ?? conta.nome,
                detalhe: rotulosDeConta[conta.tipo],
                direita: Text(reais(ref.watch(saldosProvider)[conta.id] ?? 0), style: Textos.valor(context)),
                aoTocar: () => abrirConta(context, conta.id),
              ),
            ]),
          ],
          TituloDeSecao(
            meta.tipo == 'reduzirGasto' ? 'Gasto por mês' : 'Movimento por mês',
            detalhe: (meta.parcelaMensalCentavos ?? 0) > 0 ? 'combinado: ${reais(meta.parcelaMensalCentavos!)}' : null,
          ),
          Cartao(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
            child: SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (m, valor) in serie)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(valor == 0 ? '—' : reais(valor, comSimbolo: false), style: t.bodySmall?.copyWith(fontSize: 11)),
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: FractionallySizedBox(
                                heightFactor: (valor.abs() / teto).clamp(0.015, 1).toDouble(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: valor < 0 ? c.atencao : c.primaria,
                                    borderRadius: BorderRadius.vertical(top: Raios.p.topLeft),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(_abreviados[int.parse(m.substring(5, 7)) - 1], style: t.bodySmall),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const TituloDeSecao('Lançamentos relacionados'),
          if (relacionados.isEmpty)
            const Cartao(padding: EdgeInsets.zero, child: Vazio('Nenhum lançamento recente ligado a esta meta.'))
          else
            Lista(filhos: [
              for (final l in relacionados.take(10))
                LinhaDeLancamento(
                  lancamento: l,
                  hoje: hoje,
                  conta: contas[l.contaId],
                  destino: contas[l.contaDestinoId],
                  categoria: categorias[l.categoriaId],
                  onTap: () => abrirLancamento(context, ref, l),
                ),
            ]),
        ],
      ),
    );
  }

  /// Guardar para a meta: uma transferência para a conta ligada, já com o
  /// valor combinado. Não conta como gasto.
  Future<void> _guardar(BuildContext context, WidgetRef ref, Meta meta, Conta destino, ProgressoDaMeta p) async {
    final repo = ref.read(repositorioProvider);
    if (repo == null) return;
    final hoje = ref.read(hojeProvider);
    final sugerido = (meta.parcelaMensalCentavos ?? 0) > 0 ? meta.parcelaMensalCentavos! : p.parcelaNecessariaCentavos;
    final campo = TextEditingController(text: sugerido > 0 ? reais(sugerido, comSimbolo: false) : '');
    Conta? origem = (ref.read(contasProvider).valueOrNull ?? const <Conta>[])
        .where((x) => x.id == ref.read(contaPadraoProvider) && x.id != destino.id)
        .firstOrNull;
    final mensageiro = ScaffoldMessenger.of(context);

    final valor = await abrirFolha<int>(
      context,
      (context) => StatefulBuilder(builder: (context, definir) {
        final t = Theme.of(context).textTheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(Espacos.g, 0, Espacos.g, Espacos.g),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(meta.tipo == 'quitar' ? 'Pagar parcela' : 'Guardar para ${meta.nome}', style: t.titleLarge),
              const SizedBox(height: Espacos.m),
              TextField(
                controller: campo,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                decoration: const InputDecoration(labelText: 'Valor', prefixText: r'R$ '),
              ),
              const SizedBox(height: Espacos.m),
              InkWell(
                borderRadius: Raios.m,
                onTap: () async {
                  final escolhida = await escolherConta(context, ref,
                      titulo: 'Sai de qual conta?', filtro: (x) => x.id != destino.id && x.ehDeUso, atualId: origem?.id);
                  if (escolhida != null) definir(() => origem = escolhida);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Sai de', suffixIcon: Icon(Icons.expand_more_rounded, size: 20)),
                  child: Text(origem == null ? 'Escolher' : (ref.read(nomesDasContasProvider)[origem!.id] ?? origem!.nome), style: t.bodyMedium),
                ),
              ),
              const SizedBox(height: 6),
              Text('Entra em ${destino.nome}. Não conta como gasto.', style: t.bodySmall),
              const SizedBox(height: Espacos.g),
              Acoes(filhos: [
                FilledButton(
                  onPressed: () {
                    final v = lerCentavos(campo.text);
                    if (v != null && origem != null) Navigator.pop(context, v);
                  },
                  child: Text(meta.tipo == 'quitar' ? 'Pagar' : 'Guardar'),
                ),
              ]),
            ],
          ),
        );
      }),
      largura: 440,
    );
    campo.dispose();
    if (valor == null || origem == null) return;

    final lancamento = Lancamento(
      id: const Uuid().v4(),
      tipo: 'transferencia',
      descricao: meta.nome,
      realizadoCentavos: valor,
      data: hoje,
      dataEfetiva: hoje,
      situacao: 'efetivado',
      contaId: origem!.id,
      contaDestinoId: destino.id,
      autorId: ref.read(authProvider).valueOrNull?.uid,
    );
    await repo.gravar(lancamento);
    mensageiro
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 8),
        content: Text('${reais(valor)} ${meta.tipo == 'quitar' ? 'pagos em' : 'guardados em'} ${destino.nome}.'),
        action: SnackBarAction(label: 'Desfazer', onPressed: () => repo.apagar(lancamento.id)),
      ));
  }
}
