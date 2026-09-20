import 'package:freezed_annotation/freezed_annotation.dart';
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
  /// "type 'Null' is not a subtype of type 'String'". Não é hipótese: a
  /// categoria vem EMBUTIDA no documento de `automatic_transactions`, escrita
  /// pelo leitor de notificação, e ela chega sem `name` — às vezes sem `id` —
  /// quando a notificação do banco não dava para classificar. O resultado era
  /// `AutomaticTransactionRepositoryImpl.getPendingTransactions` derrubando a
  /// lista INTEIRA de pendências por causa de um documento: quem tinha uma
  /// notificação malformada ficava sem conseguir consolidar nenhuma.
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
    final broken = textFields.where((f) => json[f] is! String);
    if (broken.isEmpty) return json;

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

  /// Categoria que o usuário pode escolher ou editar num seletor da UI.
  /// Categorias de sistema e excluídas logicamente ficam de fora.
  bool get isSelectable => !isSystem && !isDeleted;
}
