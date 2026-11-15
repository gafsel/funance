import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../regras/leitura_frase.dart';
import '../tema/tema_novo.dart';
import 'formulario.dart';

/// Ações sobre um lançamento existente: pagar, editar, apagar. Toda ação
/// pode ser desfeita pelo aviso que aparece depois.
Future<void> abrirLancamento(BuildContext context, WidgetRef ref, Lancamento l) async {
  final repo = ref.read(repositorioProvider);
  if (repo == null) return;
  final hoje = ref.read(hojeProvider);
  final contas = ref.read(contasProvider).valueOrNull ?? const <Conta>[];
  final categorias = ref.read(categoriasProvider).valueOrNull ?? const <Categoria>[];
  final mensageiro = ScaffoldMessenger.of(context);

  void avisar(String texto, Future<void> Function() desfazer) => mensageiro
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      duration: const Duration(seconds: 8),
      content: Text(texto),
      action: SnackBarAction(label: 'Desfazer', onPressed: desfazer),
    ));

  final acao = await abrirFolha<String>(
    context,
    largura: 440,
    (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(l.descricao.isEmpty ? 'Sem descrição' : l.descricao, style: Theme.of(context).textTheme.titleLarge),
            subtitle: Text('${reais(l.valorCentavos)} · ${diaPorExtenso(l.dia, hoje)}'),
          ),
          if (l.previsto)
            ListTile(
              leading: const Icon(Icons.check_circle_outline_rounded),
              title: Text(l.ehEntrada ? 'Recebi hoje' : 'Paguei hoje'),
              onTap: () => Navigator.pop(context, 'efetivar'),
            ),
          if (l.efetivado && l.previstoCentavos != null)
            ListTile(
              leading: const Icon(Icons.undo_rounded),
              title: const Text('Voltar para agendado'),
              onTap: () => Navigator.pop(context, 'desefetivar'),
            ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Editar'),
            onTap: () => Navigator.pop(context, 'editar'),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: Cores.de(context).problema),
            title: const Text('Apagar'),
            onTap: () => Navigator.pop(context, 'apagar'),
          ),
        ],
      ),
    ),
  );
  if (acao == null || !context.mounted) return;

  switch (acao) {
    case 'efetivar':
      await repo.efetivar(l, dia: hoje);
      avisar(l.ehEntrada ? 'Marcado como recebido.' : 'Marcado como pago.', () => repo.gravar(l));
    case 'desefetivar':
      await repo.gravar(l.copiar(situacao: 'previsto', realizadoCentavos: () => null, dataEfetiva: () => null));
      avisar('Voltou para agendado.', () => repo.gravar(l));
    case 'apagar':
      await repo.apagar(l.id);
      avisar('Lançamento apagado.', () => repo.gravar(l));
    case 'editar':
      final editada = await Navigator.of(context).push<Leitura>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FormularioAvancado(
          titulo: 'Editar lançamento',
          rotuloDeSalvar: 'Salvar',
          permiteRepetir: false,
          hoje: hoje,
          contas: contas,
          categorias: categorias,
          inicial: Leitura(
            tipo: l.tipo,
            descricao: l.descricao,
            valorCentavos: l.valorCentavos,
            data: l.dia,
            contaId: l.contaId,
            contaDestinoId: l.contaDestinoId,
            categoriaId: l.categoriaId,
            efetivado: l.efetivado,
            contraparteId: l.contraparteId,
          ),
          contrapartes: (ref.read(espacoAtualProvider)?.ehEmpresa ?? false)
              ? (ref.read(contrapartesProvider).valueOrNull ?? const <Contraparte>[])
              : null,
          aoCriarContraparte: (nome, tipo) async {
            final id = 'cp-${DateTime.now().microsecondsSinceEpoch}';
            await repo.gravarContraparte(id, nome: nome, tipo: tipo);
            return Contraparte(id: id, nome: nome, tipo: tipo);
          },
        ),
      ));
      if (editada == null) return;
      final novo = l.copiar(
        tipo: editada.tipo,
        descricao: editada.descricao,
        contaId: editada.contaId,
        contaDestinoId: () => editada.contaDestinoId,
        categoriaId: () => editada.categoriaId,
        contraparteId: () => editada.contraparteId,
        situacao: editada.efetivado ? 'efetivado' : 'previsto',
        // O planejado só muda se o lançamento continua agendado; pagar com
        // valor diferente não reescreve o que tinha sido previsto.
        previstoCentavos: () => editada.efetivado ? l.previstoCentavos : editada.valorCentavos,
        realizadoCentavos: () => editada.efetivado ? editada.valorCentavos : null,
        data: editada.efetivado && l.previstoCentavos != null ? l.data : editada.data,
        dataEfetiva: () => editada.efetivado ? editada.data : null,
      );
      await repo.gravar(novo);
      avisar('Alteração salva.', () => repo.gravar(l));
  }
}
