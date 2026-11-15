import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/icons_extension.dart';
import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../tema/tema_novo.dart';
import 'formulario.dart';
import 'pecas.dart';

void abrirCategorias(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TelaCategorias()));

/// Categorias (ou centros de custo, na empresa) e o limite mensal de cada
/// uma. O limite é opcional: sem ele, a categoria só organiza.
class TelaCategorias extends ConsumerWidget {
  const TelaCategorias({super.key});

  Future<void> _editar(BuildContext context, WidgetRef ref, Categoria? categoria, String tipo) async {
    final nome = TextEditingController(text: categoria?.nome ?? '');
    final limite = TextEditingController(
        text: (categoria?.limiteMensalCentavos ?? 0) > 0 ? reais(categoria!.limiteMensalCentavos!, comSimbolo: false) : '');
    var icone = categoria?.icone ?? 'category';
    var cor = categoria?.cor ?? paletaDeCategorias[(categoria?.id ?? nome.hashCode.toString()).length % paletaDeCategorias.length];

    final acao = await abrirFolha<String>(
      context,
      (context) => StatefulBuilder(builder: (context, definir) {
        final c = Cores.de(context);
        final t = Theme.of(context).textTheme;
        final previa = Categoria(id: categoria?.id ?? 'nova', nome: nome.text, tipo: tipo, icone: icone, cor: cor);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Espacos.g, 0, Espacos.g, Espacos.g),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                SeloDaCategoria(categoria: previa, tamanho: 40),
                const SizedBox(width: 12),
                Expanded(child: Text(categoria == null ? 'Nova categoria' : 'Categoria', style: t.titleLarge)),
              ]),
              const SizedBox(height: Espacos.m),
              TextField(
                controller: nome,
                autofocus: categoria == null,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => definir(() {}),
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              if (tipo == 'saida') ...[
                const SizedBox(height: Espacos.m),
                TextField(
                  controller: limite,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  decoration: const InputDecoration(labelText: 'Limite por mês (opcional)', prefixText: r'R$ ', helperText: 'O app avisa quando o gasto passar de 80% do limite.'),
                ),
              ],
              const TituloDeSecao('Cor'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final hex in paletaDeCategorias)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => definir(() => cor = hex),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: corDeHex(hex),
                        shape: BoxShape.circle,
                        border: Border.all(color: hex == cor ? c.tinta : c.superficie, width: 2.5),
                      ),
                    ),
                  ),
              ]),
              const TituloDeSecao('Ícone'),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final entrada in IconsExtension.availableIcons.entries)
                  InkWell(
                    borderRadius: Raios.p,
                    onTap: () => definir(() => icone = entrada.key),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: entrada.key == icone ? c.primariaSuave : c.suave,
                        borderRadius: Raios.p,
                        border: Border.all(color: entrada.key == icone ? c.primaria : c.suave),
                      ),
                      child: Icon(entrada.value, size: 19, color: c.tinta2),
                    ),
                  ),
              ]),
              const SizedBox(height: Espacos.g),
              Acoes(filhos: [
                FilledButton(onPressed: () => Navigator.pop(context, 'salvar'), child: const Text('Salvar')),
                if (categoria != null)
                  TextButton(onPressed: () => Navigator.pop(context, 'arquivar'), child: const Text('Arquivar categoria')),
              ]),
            ],
          ),
        );
      }),
      largura: 480,
    );
    if (acao != null && nome.text.trim().isNotEmpty) {
      await ref.read(repositorioProvider)?.gravarCategoria(categoria?.id ?? const Uuid().v4(), {
        'nome': nome.text.trim(),
        'tipo': tipo,
        'icone': icone,
        'cor': cor,
        'limiteMensalCentavos': tipo == 'saida' ? lerCentavos(limite.text) : null,
        'arquivada': acao == 'arquivar',
        if (categoria == null) 'grupo': null,
      });
    }
    nome.dispose();
    limite.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Cores.de(context);
    final empresa = ref.watch(espacoAtualProvider)?.ehEmpresa ?? false;
    final mes = ref.watch(hojeProvider).substring(0, 7);
    final resumo = (ref.watch(resumosProvider).valueOrNull ?? const <ResumoMes>[]).where((r) => r.mes == mes).firstOrNull;
    final todas = (ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]).where((x) => !x.arquivada).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));

    Widget grupo(String titulo, String tipo, {bool semTopo = false}) {
      final doTipo = todas.where((x) => x.tipo == tipo).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TituloDeSecao(
            titulo,
            semTopo: semTopo,
            acao: BotaoPequeno('Nova', icone: Icons.add_rounded, aoTocar: () => _editar(context, ref, null, tipo)),
          ),
          if (doTipo.isEmpty)
            const Cartao(padding: EdgeInsets.zero, child: Vazio('Nenhuma ainda.'))
          else
            Lista(filhos: [
              for (final x in doTipo)
                Builder(builder: (context) {
                  final gasto = resumo?.categorias[x.id]?.$2 ?? 0;
                  final limite = x.limiteMensalCentavos;
                  final passou = limite != null && gasto > limite;
                  return Linha(
                    antes: SeloDaCategoria(categoria: x),
                    titulo: x.nome,
                    detalhe: limite == null ? 'Sem limite' : 'Limite de ${reais(limite)} por mês',
                    corDoDetalhe: passou ? c.atencao : null,
                    direita: Text(reais(gasto), style: Textos.valor(context, cor: passou ? c.atencao : null)),
                    aoTocar: () => _editar(context, ref, x, tipo),
                  );
                }),
            ]),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(empresa ? 'Centros de custo' : 'Categorias')),
      body: Pagina(
        larguraMaxima: 640,
        centralizada: true,
        filhos: [
          Text('O valor à direita é o que já saiu ou entrou neste mês.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: Espacos.m),
          grupo('Saídas', 'saida', semTopo: true),
          grupo('Entradas', 'entrada'),
        ],
      ),
    );
  }
}
