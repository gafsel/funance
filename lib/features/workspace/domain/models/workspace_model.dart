import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_model.freezed.dart';
part 'workspace_model.g.dart';

enum WorkspaceType {
  @JsonValue('personal')
  personal,
  @JsonValue('business')
  business,
}

@freezed
sealed class WorkspaceModel with _$WorkspaceModel {
  const factory WorkspaceModel({
    required String id,
    required String name,
    required WorkspaceType type,
    required List<String> members,
    required DateTime createdAt,
  }) = _WorkspaceModel;

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) => _$WorkspaceModelFromJson(json);
}
