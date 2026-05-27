import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'category_model.g.dart';

enum CategoryType {
  @JsonValue('income')
  income,
  @JsonValue('expense')
  expense,
  @JsonValue('both')
  both,
}

@JsonSerializable()
class CategoryModel {
  final String id;
  final String name;
  final String icon; // Icon name/code
  final String color; // Hex color string
  CategoryType type;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.type = CategoryType.expense,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => _$CategoryModelFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Category data is null');

    return CategoryModel.fromJson({
      'type': 'expense', // Default value
      ...data,
      'id': doc.id,
    });
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    CategoryType? type,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
    );
  }
}
