import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../dados/provedores.dart';
import '../dados/repositorio.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../regras/importar.dart';
import '../regras/leitura_frase.dart';
import '../tema/tema_novo.dart';
import 'formulario.dart';
import 'pecas.dart';

const _uuid = Uuid();

/// O que o app propõe para um item da caixa: categoria e, se houver, o
/// lançamento que já existia e parece ser o mesmo.
class _Proposta {
  const _Proposta(this.item, this.categoriaId, this.correspondente);
  final ItemEntrada item;
  final String? categoriaId;
  final Lancamento? correspondente;

  /// Dá para confirmar sem perguntar nada?
  bool get pronta => item.contaId != null && (correspondente != null || categoriaId != null);
}

final _propostasProvider = Provider<List<_Proposta>>((ref) {
  final itens = [...ref.watch(entradaProvider).valueOrNull ?? const <ItemEntrada>[]]
    ..sort((a, b) => b.data.compareTo(a.data));
  final regras = ref.watch(regrasProvider).valueOrNull ?? const <Regra>[];
  final categorias = ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[];
  final recentes = ref.watch(recentesProvider);
  final aprendido = aprenderCategorias(recentes);
  final usados = <String>{};
  return [
    for (final item in itens)
      () {
        final par = acharCorrespondente(item, recentes, usados: usados);
        if (par != null) usados.add(par.id);
        return _Proposta(
          item,
          item.categoriaId ??
              sugerirCategoria(item.descricao, item.tipo, regras: regras, aprendido: aprendido, categorias: categorias),
          par,
        );
      }(),
  ];
});

class TelaEntrada extends ConsumerWidget {
  const TelaEntrada({super.key});

  Lancamento _novoLancamento(_Proposta p, String? autor) => Lancamento(
        id: _uuid.v4(),
        // O que vem de fora é entrada ou saída; transferência a pessoa
        // acerta depois, no lançamento.
        tipo: p.item.tipo == 'entrada' ? 'entrada' : 'saida',
        descricao: p.item.descricao,
        realizadoCentavos: p.item.valorCentavos,
        data: p.item.data,
        dataEfetiva: p.item.data,
        situacao: 'efetivado',
        contaId: p.item.contaId!,
        categoriaId: p.categoriaId,
        origem: p.item.origem,
        loteId: p.item.loteId,
        autorId: autor,
      );

  /// O lançamento que já existia, atualizado com o que o extrato confirmou.
  Lancamento _ligado(_Proposta p) {
    final l = p.correspondente!;
    return l.efetivado
        ? l
        : l.copiar(situacao: 'efetivado', realizadoCentavos: () => p.item.valorCentavos, dataEfetiva: () => p.item.data);
  }

  Future<void> _confirmar(BuildContext context, WidgetRef ref, List<_Proposta> propostas) async {
    final repo = ref.read(repositorioProvider);
    if (repo == null || propostas.isEmpty) return;
    final autor = ref.read(authProvider).valueOrNull?.uid;
    final mensageiro = ScaffoldMessenger.of(context);
    final desfazer = <Future<void> Function()>[];
    for (final p in propostas) {
      if (p.correspondente != null) {
        final anterior = p.correspondente!;
        await repo.confirmarItem(p.item, existente: _ligado(p));
        desfazer.add(() => repo.desconfirmarItem(p.item, anterior: anterior));
      } else {
        final novo = _novoLancamento(p, autor);
        await repo.confirmarItem(p.item, novo: novo);
        desfazer.add(() => repo.desconfirmarItem(p.item, criadoId: novo.id));
      }
    }
    mensageiro
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 8),
        content: Text(propostas.length == 1 ? 'Item confirmado.' : '${propostas.length} itens confirmados.'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () async {
            for (final d in desfazer) {
              await d();
            }
          },
        ),
      ));
  }

  Future<void> _abrirItem(BuildContext context, WidgetRef ref, _Proposta p) async {
    final resultado = await showModalBottomSheet<_Proposta>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FolhaDoItem(proposta: p),
    );
    if (resultado != null && context.mounted) await _confirmar(context, ref, [resultado]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = ref.watch(hojeProvider);
    final propostas = ref.watch(_propostasProvider);
    final contas = {for (final c in ref.watch(contasProvider).valueOrNull ?? const <Conta>[]) c.id: c};
    final categorias = {for (final c in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) c.id: c};
    final prontas = propostas.where((p) => p.pronta).toList();
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final repo = ref.watch(repositorioProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Espacos.g, Espacos.g, Espacos.g, 96),
          children: [
            Wrap(
              spacing: Espacos.m,
              runSpacing: Espacos.p,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Caixa de entrada', style: texto.titleLarge),
                OutlinedButton.icon(
                  onPressed: () => showDialog<void>(context: context, builder: (_) => const _Importar()),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Importar extrato'),
                ),
                if (prontas.length > 1)
                  FilledButton(
                    onPressed: () => _confirmar(context, ref, prontas),
                    child: Text('Confirmar ${prontas.length} prontos'),
                  ),
              ],
            ),
            const SizedBox(height: Espacos.p),
            Text(
              'O que vem de extrato, planilha ou notificação espera aqui. Nada entra no saldo antes de você confirmar.',
              style: texto.bodySmall,
            ),
            const SizedBox(height: Espacos.m),
            if (propostas.isEmpty)
              const Cartao(child: Vazio('Caixa vazia. Importe um extrato para conferir o mês.'))
            else
              Cartao(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  for (final p in propostas)
                    InkWell(
                      onTap: () => _abrirItem(context, ref, p),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(Espacos.g, Espacos.m, Espacos.p, Espacos.m),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.item.descricao, maxLines: 1, overflow: TextOverflow.ellipsis, style: texto.bodyLarge),
                                  const SizedBox(height: Espacos.xp),
                                  Wrap(spacing: Espacos.p, runSpacing: Espacos.xp, children: [
                                    Etiqueta(diaPorExtenso(p.item.data, hoje)),
                                    Etiqueta(contas[p.item.contaId]?.nome ?? 'sem conta'),
                                    if (p.correspondente != null)
                                      Etiqueta(
                                        p.correspondente!.efetivado ? 'já lançado' : 'era agendado',
                                        cor: c.positivo,
                                      )
                                    else
                                      Etiqueta(
                                        categorias[p.categoriaId]?.nome ?? 'sem categoria',
                                        cor: p.categoriaId == null ? c.atencao : null,
                                      ),
                                  ]),
                                ],
                              ),
                            ),
                            const SizedBox(width: Espacos.p),
                            Text(
                              '${p.item.tipo == 'entrada' ? '+' : '-'}${reais(p.item.valorCentavos)}',
                              style: texto.titleMedium?.copyWith(color: p.item.tipo == 'entrada' ? c.positivo : c.tinta),
                            ),
                            IconButton(
                              tooltip: 'Confirmar',
                              onPressed: p.pronta ? () => _confirmar(context, ref, [p]) : () => _abrirItem(context, ref, p),
                              icon: Icon(Icons.check_circle_outline_rounded, color: p.pronta ? c.primaria : c.tintaSuave),
                            ),
                            IconButton(
                              tooltip: 'Ignorar',
                              onPressed: repo == null
                                  ? null
                                  : () async {
                                      final mensageiro = ScaffoldMessenger.of(context);
                                      await repo.marcarItem(p.item.id, 'ignorado');
                                      mensageiro
                                        ..clearSnackBars()
                                        ..showSnackBar(SnackBar(
                                          content: const Text('Item ignorado.'),
                                          action: SnackBarAction(label: 'Desfazer', onPressed: () => repo.marcarItem(p.item.id, 'pendente')),
                                        ));
                                    },
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

/// Detalhe de um item: escolher categoria, criar regra, confirmar.
class _FolhaDoItem extends ConsumerStatefulWidget {
  const _FolhaDoItem({required this.proposta});
  final _Proposta proposta;

  @override
  ConsumerState<_FolhaDoItem> createState() => _FolhaDoItemState();
}

class _FolhaDoItemState extends ConsumerState<_FolhaDoItem> {
  late String? _categoriaId = widget.proposta.categoriaId;
  late bool _ligar = widget.proposta.correspondente != null;
  bool _lembrar = false;
  late final _textoDaRegra = TextEditingController(text: _palavraChave(widget.proposta.item.descricao));

  static String _palavraChave(String descricao) {
    final palavras = descricao
        .split(RegExp(r'[^A-Za-zÀ-ÿ]+'))
        .where((p) => p.length >= 3 && !{'pix', 'ted', 'doc', 'compra', 'pagamento', 'cartao', 'debito', 'credito'}.contains(normalizar(p)))
        .take(2);
    return palavras.join(' ');
  }

  @override
  void dispose() {
    _textoDaRegra.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.proposta;
    final hoje = ref.watch(hojeProvider);
    final texto = Theme.of(context).textTheme;
    final categorias = (ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[])
        .where((c) => !c.arquivada && c.tipo == (p.item.tipo == 'entrada' ? 'entrada' : 'saida'))
        .toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    final categoria = categorias.where((c) => c.id == _categoriaId).firstOrNull;
    final par = p.correspondente;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(Espacos.g, 0, Espacos.g, Espacos.g + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(p.item.descricao, style: texto.titleLarge),
            Text('${reais(p.item.valorCentavos)} · ${diaPorExtenso(p.item.data, hoje)}', style: texto.bodyMedium),
            const SizedBox(height: Espacos.m),
            if (par != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(par.efetivado ? 'É o mesmo que já lancei' : 'É o que estava agendado'),
                subtitle: Text('"${par.descricao}", ${diaPorExtenso(par.dia, hoje)}. Ligado, não cria outro lançamento.'),
                value: _ligar,
                onChanged: (v) => setState(() => _ligar = v),
              ),
            if (par == null || !_ligar) ...[
              InkWell(
                borderRadius: Raios.m,
                onTap: () async {
                  final escolhida = await escolher<Categoria>(context,
                      titulo: 'Categoria', itens: categorias, rotulo: (c) => c.nome, atual: categoria);
                  if (escolhida != null) setState(() => _categoriaId = escolhida.id);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Categoria', suffixIcon: Icon(Icons.expand_more_rounded)),
                  child: Text(categoria?.nome ?? 'Escolher', style: texto.bodyLarge),
                ),
              ),
              if (_categoriaId != null) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Lembrar para os próximos'),
                  subtitle: const Text('Cria uma regra: o que tiver este texto já chega classificado.'),
                  value: _lembrar,
                  onChanged: (v) => setState(() => _lembrar = v),
                ),
                if (_lembrar)
                  TextField(controller: _textoDaRegra, decoration: const InputDecoration(labelText: 'Texto que identifica')),
              ],
            ],
            const SizedBox(height: Espacos.g),
            FilledButton(
              onPressed: (par != null && _ligar) || _categoriaId != null
                  ? () async {
                      final repo = ref.read(repositorioProvider);
                      final navegador = Navigator.of(context);
                      if (_lembrar && _categoriaId != null && _textoDaRegra.text.trim().length >= 2) {
                        await repo?.salvarRegra(_uuid.v4(), texto: _textoDaRegra.text.trim(), categoriaId: _categoriaId!);
                      }
                      navegador.pop(_Proposta(p.item, _categoriaId, _ligar ? par : null));
                    }
                  : null,
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Importar: escolher a conta, colar ou abrir o arquivo, conferir e mandar
/// para a caixa de entrada.
class _Importar extends ConsumerStatefulWidget {
  const _Importar();

  @override
  ConsumerState<_Importar> createState() => _ImportarState();
}

class _ImportarState extends ConsumerState<_Importar> {
  final _texto = TextEditingController();
  String? _contaId;
  String? _arquivo;
  bool _enviando = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _abrirArquivo() async {
    final escolha = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['ofx', 'csv', 'txt', 'tsv'],
      withData: true,
    );
    final bytes = escolha?.files.single.bytes;
    if (bytes == null) return;
    String conteudo;
    try {
      conteudo = utf8.decode(bytes);
    } on FormatException {
      // Extrato de banco brasileiro ainda vem muito em Latin-1.
      conteudo = latin1.decode(bytes);
    }
    setState(() {
      _arquivo = escolha!.files.single.name;
      _texto.text = conteudo;
    });
  }

  Future<void> _enviar(Repositorio repo, ResultadoDaImportacao lido, Conta conta) async {
    setState(() => _enviando = true);
    final mensageiro = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    final origem = lido.formato == 'OFX' ? 'extrato' : 'planilha';
    try {
      final r = await repo.importar(
        [
          for (final i in lido.itens)
            ItemEntrada(id: i.id, descricao: i.descricao, valorCentavos: i.valorCentavos, data: i.data, tipo: i.tipo, contaId: conta.id, origem: origem),
        ],
        loteId: _uuid.v4(),
        autorId: ref.read(authProvider).valueOrNull?.uid,
      );
      navegador.pop();
      final repetidos = lido.itens.length - r.novos;
      mensageiro
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(r.novos == 0
              ? 'Tudo isso já tinha sido importado.'
              : '${r.novos} ${r.novos == 1 ? 'item' : 'itens'} na caixa de entrada${repetidos > 0 ? ' ($repetidos já estavam)' : ''}.'),
          action: r.novos == 0 ? null : SnackBarAction(label: 'Desfazer', onPressed: () => repo.desfazerImportacao(r.loteId)),
        ));
    } catch (_) {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoje = ref.watch(hojeProvider);
    final contas = (ref.watch(contasProvider).valueOrNull ?? const <Conta>[]).where((c) => !c.arquivada).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    final conta = contas.where((c) => c.id == _contaId).firstOrNull;
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final repo = ref.watch(repositorioProvider);
    final lido = conta == null || _texto.text.trim().isEmpty ? null : lerExtrato(_texto.text, contaId: conta.id, hoje: hoje);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(Espacos.g),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(child: Text('Importar extrato', style: texto.titleLarge)),
                IconButton(tooltip: 'Fechar', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ]),
              const SizedBox(height: Espacos.p),
              InkWell(
                borderRadius: Raios.m,
                onTap: () async {
                  final escolhida = await escolher<Conta>(context,
                      titulo: 'De qual conta é o extrato?', itens: contas, rotulo: (x) => x.nome, detalhe: (x) => rotulosDeConta[x.tipo], atual: conta);
                  if (escolhida != null) setState(() => _contaId = escolhida.id);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Conta', suffixIcon: Icon(Icons.expand_more_rounded)),
                  child: Text(conta?.nome ?? 'Escolher', style: texto.bodyLarge),
                ),
              ),
              const SizedBox(height: Espacos.m),
              Row(children: [
                OutlinedButton.icon(
                  onPressed: _abrirArquivo,
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text('Abrir arquivo (OFX ou CSV)'),
                ),
                const SizedBox(width: Espacos.m),
                if (_arquivo != null) Expanded(child: Text(_arquivo!, maxLines: 1, overflow: TextOverflow.ellipsis, style: texto.bodySmall)),
              ]),
              const SizedBox(height: Espacos.m),
              TextField(
                controller: _texto,
                minLines: 4,
                maxLines: 8,
                onChanged: (_) => setState(() => _arquivo = null),
                decoration: const InputDecoration(
                  hintText: 'Ou cole aqui as linhas do extrato ou da planilha:\n03/11/2026\tMercado\t-45,90',
                ),
              ),
              const SizedBox(height: Espacos.m),
              if (lido != null)
                Text(
                  lido.itens.isEmpty
                      ? 'Não achei nenhuma linha com data e valor.'
                      : '${lido.itens.length} ${lido.itens.length == 1 ? 'linha lida' : 'linhas lidas'} (${lido.formato}), '
                          'de ${diaPorExtenso(lido.itens.map((i) => i.data).reduce((a, b) => a.compareTo(b) < 0 ? a : b), hoje)} '
                          'a ${diaPorExtenso(lido.itens.map((i) => i.data).reduce((a, b) => a.compareTo(b) > 0 ? a : b), hoje)}.'
                          '${lido.ignoradas > 0 ? ' ${lido.ignoradas} ${lido.ignoradas == 1 ? 'linha ignorada' : 'linhas ignoradas'} (cabeçalho, total ou sem valor).' : ''}',
                  style: texto.bodyMedium?.copyWith(color: lido.itens.isEmpty ? c.atencao : null),
                ),
              const SizedBox(height: Espacos.m),
              FilledButton(
                onPressed: repo == null || conta == null || lido == null || lido.itens.isEmpty || _enviando
                    ? null
                    : () => _enviar(repo, lido, conta),
                child: const Text('Mandar para a caixa de entrada'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
