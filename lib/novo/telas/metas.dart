import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/caminho.dart';
import '../regras/formatos.dart';
import '../regras/metas.dart';
import '../tema/tema_novo.dart';
import 'formulario.dart';
import 'pecas.dart';

/// Caminho e metas: onde a pessoa está, o próximo passo e o que ela quer
/// alcançar.
class TelaMetas extends ConsumerWidget {
  const TelaMetas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = ref.watch(hojeProvider);
    final caminho = ref.watch(caminhoProvider);
    final atual = degrauAtual(caminho);
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final contas = {for (final x in ref.watch(contasProvider).valueOrNull ?? const <Conta>[]) x.id: x};
    final saldos = ref.watch(saldosProvider);
    final resumos = ref.watch(resumosProvider).valueOrNull ?? const <ResumoMes>[];
    final metas = (ref.watch(metasProvider).valueOrNull ?? const <Meta>[]).where((m) => m.emAberto).toList()
      ..sort((a, b) => a.prazo.compareTo(b.prazo));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Espacos.g, Espacos.g, Espacos.g, 96),
          children: [
            Text('Seu caminho', style: texto.titleLarge),
            Text('Um passo por vez, nesta ordem. O passo de agora está em destaque.', style: texto.bodySmall),
            const SizedBox(height: Espacos.m),
            Cartao(
              padding: const EdgeInsets.symmetric(vertical: Espacos.p),
              child: Column(children: [
                for (var i = 0; i < caminho.length; i++)
                  _LinhaDoDegrau(numero: i + 1, degrau: caminho[i], ehAtual: caminho[i].id == atual?.id),
                if (atual == null)
                  Padding(
                    padding: const EdgeInsets.all(Espacos.g),
                    child: Text('Você passou por todos os degraus. Agora é manter.', style: texto.bodyLarge?.copyWith(color: c.positivo)),
                  ),
              ]),
            ),
            TituloDeSecao(
              'Metas',
              acao: TextButton.icon(
                onPressed: () => editarMeta(context, ref, null),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nova meta'),
              ),
            ),
            if (metas.isEmpty)
              const Cartao(child: Vazio('Nenhuma meta ainda. Uma meta tem um valor, um prazo e uma conta onde o dinheiro fica.'))
            else
              for (final meta in metas)
                Padding(
                  padding: const EdgeInsets.only(bottom: Espacos.p),
                  child: Builder(builder: (context) {
                    final p = progressoDaMeta(meta, hoje: hoje, contas: contas, saldos: saldos, resumos: resumos);
                    return Cartao(
                      onTap: () => editarMeta(context, ref, meta),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(child: Text(meta.nome, style: texto.titleMedium)),
                            Text('${reais(p.atualCentavos)} de ${reais(p.alvoCentavos)}', style: texto.bodyMedium),
                          ]),
                          const SizedBox(height: Espacos.p),
                          ClipRRect(
                            borderRadius: Raios.pilula,
                            child: LinearProgressIndicator(
                              value: p.fracao,
                              minHeight: 8,
                              backgroundColor: c.superficieAlta,
                              color: p.menorEhMelhor && !p.atingida ? c.atencao : c.primaria,
                            ),
                          ),
                          const SizedBox(height: Espacos.p),
                          Text(situacaoDaMeta(meta, p, hoje), style: texto.bodySmall),
                          Text(
                            'Até ${diaPorExtenso(meta.prazo, hoje)}${contas[meta.contaId] != null ? ' · ${contas[meta.contaId]!.nome}' : ''}'
                            '${meta.adiamentos > 0 ? ' · adiada ${meta.adiamentos}x' : ''}',
                            style: texto.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
          ],
        ),
      ),
    );
  }
}

class _LinhaDoDegrau extends StatelessWidget {
  const _LinhaDoDegrau({required this.numero, required this.degrau, required this.ehAtual});
  final int numero;
  final Degrau degrau;
  final bool ehAtual;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    return Container(
      color: ehAtual ? c.superficieAlta : null,
      padding: const EdgeInsets.symmetric(horizontal: Espacos.g, vertical: Espacos.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: degrau.feito ? c.positivo : (ehAtual ? c.calor : c.superficieAlta),
              borderRadius: Raios.pilula,
            ),
            child: degrau.feito
                ? Icon(Icons.check_rounded, size: 18, color: c.superficie)
                : Text('$numero', style: texto.labelLarge?.copyWith(color: ehAtual ? c.sobreCalor : c.tintaSuave)),
          ),
          const SizedBox(width: Espacos.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(degrau.titulo, style: texto.titleMedium?.copyWith(color: degrau.feito || ehAtual ? c.tinta : c.tintaSuave)),
                if (ehAtual) ...[
                  const SizedBox(height: Espacos.xp),
                  Text(degrau.porque, style: texto.bodyMedium),
                  const SizedBox(height: Espacos.p),
                  if (degrau.fracao != null) ...[
                    ClipRRect(
                      borderRadius: Raios.pilula,
                      child: LinearProgressIndicator(value: degrau.fracao, minHeight: 6, backgroundColor: c.superficie, color: c.calor),
                    ),
                    const SizedBox(height: Espacos.p),
                  ],
                  Text(degrau.situacao, style: texto.bodySmall),
                  const SizedBox(height: Espacos.xp),
                  Text('Próximo passo: ${degrau.proximoPasso}', style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ] else
                  Text(degrau.situacao, style: texto.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Criar ou editar uma meta.
Future<void> editarMeta(BuildContext context, WidgetRef ref, Meta? meta) =>
    Navigator.of(context).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => _FormularioDeMeta(meta: meta)));

class _FormularioDeMeta extends ConsumerStatefulWidget {
  const _FormularioDeMeta({this.meta});
  final Meta? meta;

  @override
  ConsumerState<_FormularioDeMeta> createState() => _FormularioDeMetaState();
}

class _FormularioDeMetaState extends ConsumerState<_FormularioDeMeta> {
  late final _nome = TextEditingController(text: widget.meta?.nome ?? '');
  late final _alvo = TextEditingController(text: widget.meta == null ? '' : reais(widget.meta!.alvoCentavos, comSimbolo: false));
  late final _parcela = TextEditingController(
      text: (widget.meta?.parcelaMensalCentavos ?? 0) > 0 ? reais(widget.meta!.parcelaMensalCentavos!, comSimbolo: false) : '');
  late String _tipo = widget.meta?.tipo ?? 'juntar';
  late String? _contaId = widget.meta?.contaId;
  late String _prazo = widget.meta?.prazo ?? somarMeses(ref.read(hojeProvider).substring(0, 7), 12) + ref.read(hojeProvider).substring(7);
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _alvo.dispose();
    _parcela.dispose();
    super.dispose();
  }

  Future<void> _salvar({int adiar = 0, bool arquivar = false}) async {
    final repo = ref.read(repositorioProvider);
    final alvo = lerCentavos(_alvo.text);
    if (repo == null) return;
    if (_nome.text.trim().isEmpty) return setState(() => _erro = 'Dê um nome para a meta.');
    if (alvo == null) return setState(() => _erro = 'Informe o valor da meta.');
    final hoje = ref.read(hojeProvider);
    final navegador = Navigator.of(context);
    final prazo = adiar > 0 ? diaNoMes(somarMeses(_prazo.substring(0, 7), adiar), int.parse(_prazo.substring(8, 10))) : _prazo;
    await repo.gravarMeta(widget.meta?.id ?? const Uuid().v4(), {
      'nome': _nome.text.trim(),
      'tipo': _tipo,
      'alvoCentavos': alvo,
      'inicio': widget.meta?.inicio ?? hoje,
      'prazo': prazo,
      'parcelaMensalCentavos': lerCentavos(_parcela.text),
      'contaId': _contaId,
      'categoriaId': widget.meta?.categoriaId,
      'adiamentos': (widget.meta?.adiamentos ?? 0) + (adiar > 0 ? 1 : 0),
      'arquivada': arquivar,
      'resultado': widget.meta?.resultado,
      'encerradaEm': null,
    });
    navegador.pop();
  }

  @override
  Widget build(BuildContext context) {
    final hoje = ref.watch(hojeProvider);
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final todas = (ref.watch(contasProvider).valueOrNull ?? const <Conta>[]).where((x) => !x.arquivada).toList();
    final contas = todas.where((x) => _tipo == 'quitar' ? x.tipo == 'divida' || x.ehCartao : x.tipo == 'investimento' || x.ehDeUso).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    final conta = todas.where((x) => x.id == _contaId).firstOrNull;
    final alvo = lerCentavos(_alvo.text);
    final saldos = ref.watch(saldosProvider);
    final meses = mesesAte(hoje, _prazo);
    final jaTem = _tipo == 'juntar' && conta?.tipo == 'investimento' ? (saldos[conta!.id] ?? 0).clamp(0, 1 << 52) : 0;
    final sugerida = alvo == null || meses == 0 ? null : ((alvo - jaTem).clamp(0, alvo) / meses).ceil();
    final livre = ref.watch(livreProvider);
    final legado = _tipo == 'reduzirGasto' || _tipo == 'reduzirCartao';

    return Scaffold(
      appBar: AppBar(title: Text(widget.meta == null ? 'Nova meta' : 'Meta'), backgroundColor: c.fundo, surfaceTintColor: c.fundo),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(Espacos.g),
            children: [
              if (!legado)
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'juntar', label: Text('Juntar dinheiro')),
                    ButtonSegment(value: 'quitar', label: Text('Quitar dívida')),
                  ],
                  selected: {_tipo},
                  onSelectionChanged: (s) => setState(() {
                    _tipo = s.first;
                    _contaId = null;
                  }),
                ),
              const SizedBox(height: Espacos.g),
              TextField(controller: _nome, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Nome da meta')),
              const SizedBox(height: Espacos.m),
              TextField(
                controller: _alvo,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: _tipo == 'quitar' ? 'Quanto quitar' : 'Valor da meta', prefixText: r'R$ '),
              ),
              const SizedBox(height: Espacos.m),
              InkWell(
                borderRadius: Raios.m,
                onTap: () async {
                  final dia = await escolherDia(context, _prazo);
                  if (dia != null) setState(() => _prazo = dia);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Prazo', suffixIcon: Icon(Icons.expand_more_rounded)),
                  child: Text(diaPorExtenso(_prazo, hoje), style: texto.bodyLarge),
                ),
              ),
              if (!legado) ...[
                const SizedBox(height: Espacos.m),
                InkWell(
                  borderRadius: Raios.m,
                  onTap: () async {
                    final escolhida = await escolher<Conta>(context,
                        titulo: _tipo == 'quitar' ? 'Qual dívida?' : 'Onde o dinheiro fica?',
                        itens: contas,
                        rotulo: (x) => x.nome,
                        detalhe: (x) => '${rotulosDeConta[x.tipo]} · ${reais(saldos[x.id] ?? 0)}',
                        atual: conta);
                    if (escolhida != null) setState(() => _contaId = escolhida.id);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: _tipo == 'quitar' ? 'Dívida' : 'Conta ligada',
                      helperText: _tipo == 'quitar' ? null : 'O progresso da meta é o saldo real desta conta.',
                      suffixIcon: const Icon(Icons.expand_more_rounded),
                    ),
                    child: Text(conta?.nome ?? 'Escolher', style: texto.bodyLarge),
                  ),
                ),
                const SizedBox(height: Espacos.m),
                TextField(
                  controller: _parcela,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  decoration: InputDecoration(
                    labelText: 'Quanto separar por mês',
                    prefixText: r'R$ ',
                    helperMaxLines: 3,
                    helperText: sugerida == null
                        ? 'Esse valor sai do seu "livre para gastar" todo mês.'
                        : 'Para chegar no prazo: ${reais(sugerida)} por mês ($meses ${meses == 1 ? 'mês' : 'meses'}). '
                            'Hoje sobram ${reais(livre.livreCentavos)} livres no mês.',
                  ),
                ),
              ],
              if (_erro != null) ...[
                const SizedBox(height: Espacos.m),
                Text(_erro!, style: texto.bodyMedium?.copyWith(color: c.problema)),
              ],
              const SizedBox(height: Espacos.xg),
              FilledButton(onPressed: _salvar, child: const Text('Salvar meta')),
              if (widget.meta != null) ...[
                const SizedBox(height: Espacos.p),
                OutlinedButton(onPressed: () => _salvar(adiar: 1), child: const Text('Adiar o prazo em um mês')),
                const SizedBox(height: Espacos.p),
                TextButton(onPressed: () => _salvar(arquivar: true), child: const Text('Arquivar meta')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
