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
    final t = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final contas = {
      for (final x in ref.watch(contasProvider).valueOrNull ?? const <Conta>[])
        x.id: x,
    };
    final saldos = ref.watch(saldosProvider);
    final resumos =
        ref.watch(resumosProvider).valueOrNull ?? const <ResumoMes>[];
    final metas =
        (ref.watch(metasProvider).valueOrNull ?? const <Meta>[])
            .where((m) => m.emAberto)
            .toList()
          ..sort((a, b) => a.prazo.compareTo(b.prazo));

    final blocoCaminho = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloDeSecao(
          'Seu caminho',
          detalhe: 'um passo por vez',
          semTopo: true,
        ),
        Lista(
          filhos: [
            for (var i = 0; i < caminho.length; i++)
              _LinhaDoDegrau(
                numero: i + 1,
                degrau: caminho[i],
                ehAtual: caminho[i].id == atual?.id,
              ),
          ],
        ),
        if (atual == null)
          Padding(
            padding: const EdgeInsets.only(top: Espacos.p),
            child: Text(
              'Você passou por todos os degraus. Agora é manter.',
              style: t.bodyMedium?.copyWith(color: c.positivo),
            ),
          ),
      ],
    );

    final blocoMetas = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloDeSecao(
          'Metas',
          semTopo: ehMesa(context),
          acao: BotaoPequeno(
            'Nova meta',
            icone: Icons.add_rounded,
            aoTocar: () => editarMeta(context, ref, null),
          ),
        ),
        if (metas.isEmpty)
          const Cartao(
            padding: EdgeInsets.zero,
            child: Vazio(
              'Nenhuma meta ainda. Uma meta tem um valor, um prazo e uma conta onde o dinheiro fica.',
            ),
          )
        else
          for (final meta in metas)
            Padding(
              padding: const EdgeInsets.only(bottom: Espacos.p),
              child: Builder(
                builder: (context) {
                  final p = progressoDaMeta(
                    meta,
                    hoje: hoje,
                    contas: contas,
                    saldos: saldos,
                    resumos: resumos,
                  );
                  return Cartao(
                    onTap: () => editarMeta(context, ref, meta),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                meta.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.titleSmall,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${reais(p.atualCentavos)} de ${reais(p.alvoCentavos)}',
                              style: Textos.valor(context, tamanho: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Barra(
                          p.fracao,
                          cor: p.menorEhMelhor && !p.atingida
                              ? c.atencao
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          situacaoDaMeta(meta, p, hoje),
                          style: t.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: c.tinta2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Etiqueta('até ${diaPorExtenso(meta.prazo, hoje)}'),
                            if (contas[meta.contaId] != null)
                              Etiqueta(contas[meta.contaId]!.nome),
                            if (meta.adiamentos > 0)
                              Etiqueta(
                                'adiada ${meta.adiamentos}x',
                                tom: Tom.atencao,
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      ],
    );

    if (ehMesa(context)) {
      return Pagina(
        filhos: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: blocoCaminho),
              const SizedBox(width: Espacos.xg),
              Expanded(child: blocoMetas),
            ],
          ),
        ],
      );
    }
    return Pagina(filhos: [blocoCaminho, blocoMetas]);
  }
}

class _LinhaDoDegrau extends StatelessWidget {
  const _LinhaDoDegrau({
    required this.numero,
    required this.degrau,
    required this.ehAtual,
  });
  final int numero;
  final Degrau degrau;
  final bool ehAtual;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Cores.de(context);
    return Container(
      color: ehAtual ? c.calorSuave : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: degrau.feito ? c.positivo : (ehAtual ? c.calor : c.suave),
              shape: BoxShape.circle,
            ),
            child: degrau.feito
                ? Icon(Icons.check_rounded, size: 15, color: c.superficie)
                : Text(
                    '$numero',
                    style: t.labelMedium?.copyWith(
                      color: ehAtual ? c.sobreCalor : c.tinta3,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  degrau.titulo,
                  style: t.titleSmall?.copyWith(
                    color: degrau.feito || ehAtual ? c.tinta : c.tinta2,
                  ),
                ),
                if (ehAtual) ...[
                  const SizedBox(height: 2),
                  Text(
                    degrau.porque,
                    style: t.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: c.tinta2,
                    ),
                  ),
                  if (degrau.fracao != null) ...[
                    const SizedBox(height: 8),
                    Barra(degrau.fracao!, cor: c.calor, trilho: c.superficie),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    degrau.situacao,
                    style: t.bodySmall?.copyWith(color: c.tinta2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Próximo passo: ${degrau.proximoPasso}',
                    style: t.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else
                  Text(degrau.situacao, style: t.bodySmall),
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FormularioDeMeta(meta: meta),
      ),
    );

class _FormularioDeMeta extends ConsumerStatefulWidget {
  const _FormularioDeMeta({this.meta});
  final Meta? meta;

  @override
  ConsumerState<_FormularioDeMeta> createState() => _FormularioDeMetaState();
}

class _FormularioDeMetaState extends ConsumerState<_FormularioDeMeta> {
  late final _nome = TextEditingController(text: widget.meta?.nome ?? '');
  late final _alvo = TextEditingController(
    text: widget.meta == null
        ? ''
        : reais(widget.meta!.alvoCentavos, comSimbolo: false),
  );
  late final _parcela = TextEditingController(
    text: (widget.meta?.parcelaMensalCentavos ?? 0) > 0
        ? reais(widget.meta!.parcelaMensalCentavos!, comSimbolo: false)
        : '',
  );
  late String _tipo = widget.meta?.tipo ?? 'juntar';
  late String? _contaId = widget.meta?.contaId;
  late String _prazo =
      widget.meta?.prazo ??
      somarMeses(ref.read(hojeProvider).substring(0, 7), 12) +
          ref.read(hojeProvider).substring(7);
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
    if (_nome.text.trim().isEmpty) {
      return setState(() => _erro = 'Dê um nome para a meta.');
    }
    if (alvo == null) return setState(() => _erro = 'Informe o valor da meta.');
    final hoje = ref.read(hojeProvider);
    final navegador = Navigator.of(context);
    final prazo = adiar > 0
        ? diaNoMes(
            somarMeses(_prazo.substring(0, 7), adiar),
            int.parse(_prazo.substring(8, 10)),
          )
        : _prazo;
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
    final todas = (ref.watch(contasProvider).valueOrNull ?? const <Conta>[])
        .where((x) => !x.arquivada)
        .toList();
    final contas =
        todas
            .where(
              (x) => _tipo == 'quitar'
                  ? x.tipo == 'divida' || x.ehCartao
                  : x.tipo == 'investimento' || x.ehDeUso,
            )
            .toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));
    final conta = todas.where((x) => x.id == _contaId).firstOrNull;
    final alvo = lerCentavos(_alvo.text);
    final saldos = ref.watch(saldosProvider);
    final meses = mesesAte(hoje, _prazo);
    final jaTem = _tipo == 'juntar' && conta?.tipo == 'investimento'
        ? (saldos[conta!.id] ?? 0).clamp(0, 1 << 52)
        : 0;
    final sugerida = alvo == null || meses == 0
        ? null
        : ((alvo - jaTem).clamp(0, alvo) / meses).ceil();
    final livre = ref.watch(livreProvider);
    final legado = _tipo == 'reduzirGasto' || _tipo == 'reduzirCartao';

    return Scaffold(
      appBar: AppBar(title: Text(widget.meta == null ? 'Nova meta' : 'Meta')),
      body: Pagina(
        larguraMaxima: 520,
        centralizada: true,
        filhos: [
          if (!legado)
            Segmentos<String>(
              opcoes: const [
                ('juntar', 'Juntar dinheiro'),
                ('quitar', 'Quitar dívida'),
              ],
              valor: _tipo,
              aoMudar: (v) => setState(() {
                _tipo = v;
                _contaId = null;
              }),
            ),
          const SizedBox(height: Espacos.g),
          TextField(
            controller: _nome,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nome da meta'),
          ),
          const SizedBox(height: Espacos.m),
          TextField(
            controller: _alvo,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _tipo == 'quitar' ? 'Quanto quitar' : 'Valor da meta',
              prefixText: r'R$ ',
            ),
          ),
          const SizedBox(height: Espacos.m),
          InkWell(
            borderRadius: Raios.m,
            onTap: () async {
              final dia = await escolherDia(context, _prazo);
              if (dia != null) setState(() => _prazo = dia);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Prazo',
                suffixIcon: Icon(Icons.expand_more_rounded),
              ),
              child: Text(diaPorExtenso(_prazo, hoje), style: texto.bodyLarge),
            ),
          ),
          if (!legado) ...[
            const SizedBox(height: Espacos.m),
            InkWell(
              borderRadius: Raios.m,
              onTap: () async {
                final escolhida = await escolher<Conta>(
                  context,
                  titulo: _tipo == 'quitar'
                      ? 'Qual dívida?'
                      : 'Onde o dinheiro fica?',
                  itens: contas,
                  rotulo: (x) => x.nome,
                  detalhe: (x) =>
                      '${rotulosDeConta[x.tipo]} · ${reais(saldos[x.id] ?? 0)}',
                  atual: conta,
                );
                if (escolhida != null) setState(() => _contaId = escolhida.id);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: _tipo == 'quitar' ? 'Dívida' : 'Conta ligada',
                  helperText: _tipo == 'quitar'
                      ? null
                      : 'O progresso da meta é o saldo real desta conta.',
                  suffixIcon: const Icon(Icons.expand_more_rounded),
                ),
                child: Text(conta?.nome ?? 'Escolher', style: texto.bodyLarge),
              ),
            ),
            const SizedBox(height: Espacos.m),
            TextField(
              controller: _parcela,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
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
          Acoes(
            filhos: [
              FilledButton(
                onPressed: _salvar,
                child: const Text('Salvar meta'),
              ),
              if (widget.meta != null) ...[
                OutlinedButton(
                  onPressed: () => _salvar(adiar: 1),
                  child: const Text('Adiar um mês'),
                ),
                TextButton(
                  onPressed: () => _salvar(arquivar: true),
                  child: const Text('Arquivar meta'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
