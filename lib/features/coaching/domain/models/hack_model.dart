import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'hack_model.g.dart';

@JsonSerializable()
class HackModel {
  final String id;
  final String title;
  final String content;
  final String category;

  HackModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
  });

  factory HackModel.fromJson(Map<String, dynamic> json) => _$HackModelFromJson(json);
  Map<String, dynamic> toJson() => _$HackModelToJson(this);

  factory HackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HackModel.fromJson({
      ...data,
      'id': doc.id,
    });
  }
}
