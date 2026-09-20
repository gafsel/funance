import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/core/observability/app_logger.dart';
import 'package:funances/features/workspace/domain/models/virtual_category.dart';

part 'category_model.freezed.dart';

part 'category_model.g.dart';

enum CategoryType {
  @JsonValue('income')
  income,
  @JsonValue('expense')
  expense,
}

enum CategoryAllocation {
  @JsonValue('essential')
  essential,
  @JsonValue('comfort')
  comfort,
  @JsonValue('investment')
  investment;

  double get idealPercentage => switch (this) {
    essential => .5,
    comfort => .3,
    investment => .2,
  };
}

@freezed
sealed class CategoryModel with _$CategoryModel {
  const CategoryModel._();

  const factory CategoryModel({
    required String id,
    required String name,
    required String icon, // Icon name/code
    required String color, // Hex color string
    @Default(CategoryType.expense) CategoryType type,
    @Default(CategoryAllocation.comfort) CategoryAllocation allocation,
    // Categoria criada e mantida pelo backend (ex.: saldo inicial). O usuário
    // não escolhe nem edita; ela só aparece em relatórios/extrato.
    @Default(false) bool isSystem,
    // Exclusão lógica feita pelo backend: some dos seletores, mas continua
    // resolvível por id para nomear lançamentos antigos.
    @Default(false) bool isDeleted,
  }) = _CategoryModel;

  /// Leitura TOLERANTE dos quatro campos de texto.
  ///
  /// O gerado faz `json['name'] as String`, e um `null` ali estoura com
  /// "type 'Null' is not a subtype of type 'String'".
  ///
  /// Os dois produtores conhecidos escrevem a categoria inteira ou não
  /// escrevem nada: o leitor de notificação OMITE `suggestedCategory` quando
  /// não classifica, e a sugestão da IA sempre vem com `name`, `icon` e
  /// `color`. A tolerância aqui não descreve nenhum dos dois — ela existe
  /// porque a categoria vem EMBUTIDA num documento que o app não escreve, e
  /// uma forma que ninguém promete é exatamente a que não tem quem a corrija.
  /// A defesa de verdade é a fronteira da leitura
  /// (`parsePendingTransactions`), que pula o documento inteiro; esta aqui
  /// salva o caso em que só o texto falta e o resto do documento serve.
  ///
  /// O default é string vazia e não um texto inventado, porque a camada de
  /// dados não escolhe palavra: `displayName` já troca vazio por "Sem
  /// categoria" no idioma de quem lê, `asIcon()` cai em `Icons.category` e
  /// `asColor()` tem `orElse`. [toJson] não muda — o app continua gravando
  /// exatamente o que tem.
  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(_withTextDefaults(json));

  static Map<String, dynamic> _withTextDefaults(Map<String, dynamic> json) {
    const textFields = ['id', 'name', 'icon', 'color'];

    // Só copia o mapa se houver algo a consertar: o caminho normal é o de
    // todo lançamento da lista e não deve pagar uma alocação por categoria.
    final broken = textFields.where((f) => json[f] is! String).toList();
    if (broken.isEmpty) return json;

    // O fallback é registrado. Ele é silencioso por desenho — a tela continua
    // funcionando —, e silêncio por desenho é exatamente o que faz um
    // documento malformado virar normal sem ninguém notar. Os NOMES dos
    // campos entram; o conteúdo, não.
    AppLogger.info(
      'CategoryModel: campos sem texto, usando vazio — ${broken.join(', ')}',
      name: 'parse',
    );

    return {...json, for (final field in broken) field: ''};
  }

  /// Categoria SINTÉTICA do agrupamento "Outros": não existe no Firestore, é
  /// montada pela apresentação quando a lista passa de dez linhas. O nome sai
  /// do l10n (ver `CategoryDisplayName.displayName`), não deste modelo.
  static const String othersId = 'others';

  /// Categoria criada pelo servidor como contrapartida de uma transferência
  /// (ver [VirtualCategory]).
  ///
  /// A regra é a MESMA do backend — prefixo `virtual_`, não uma lista de
  /// quatro ids. Com a lista, uma categoria virtual nova publicada pelo
  /// servidor apareceria nos seletores do app como se fosse do usuário.
  bool get isVirtual => VirtualCategory.isVirtualId(id);

  /// A categoria é do SISTEMA pela mesma regra do backend
  /// (`isSystemCategory` em `functions/.../category.model.ts`): a flag, o
  /// prefixo `virtual_` ou o id do saldo inicial.
  ///
  /// São três testes e não um porque **a flag sozinha não chega em workspace
  /// legado**: `isSystem` só existe nos documentos que passaram pelo
  /// `migrate_system_categories`, e no cofre do dono nenhuma das 33
  /// categorias o tem. Confiar só nela fazia `virtual_investment_expense` e
  /// `virtual_debt_expense` entrarem como ALDEÃS do HUD — duas categorias
  /// que o usuário nunca criou, com allocation de investimento e alvo de
  /// R\$ 4.000 sem aporte nenhum, derrubando sozinhas o envelope de
  /// investimento da vila. O app dizia "9/18, vila em risco, +135 XP" onde o
  /// servidor pagava "9/16, vila viva, 235 XP".
  ///
  /// A regra é do backend porque é ele quem grava e quem paga o XP; o app
  /// que peneira diferente diverge do placar.
  bool get isSystemCategory =>
      isSystem || isVirtual || id == VirtualCategory.initialBalanceId;

  /// Categoria que o usuário pode escolher ou editar num seletor da UI.
  /// Categorias de sistema e excluídas logicamente ficam de fora.
  bool get isSelectable => !isSystem && !isDeleted;
}
