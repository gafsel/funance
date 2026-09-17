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

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

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
