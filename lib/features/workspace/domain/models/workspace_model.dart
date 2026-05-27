import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'workspace_model.g.dart';

enum WorkspaceType {
  @JsonValue('personal')
  personal,
  @JsonValue('business')
  business,
}

@JsonSerializable()
class WorkspaceModel {
  final String id;
  final String name;
  final WorkspaceType type;
  final List<String> members;
  final DateTime createdAt;

  WorkspaceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.members,
    required this.createdAt,
  });

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) => _$WorkspaceModelFromJson(json);
  Map<String, dynamic> toJson() => _$WorkspaceModelToJson(this);

  factory WorkspaceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Workspace data is null');
    
    return WorkspaceModel.fromJson({
      'type': 'personal',
      'members': [],
      ...data,
      'id': doc.id,
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
    });
  }
}
