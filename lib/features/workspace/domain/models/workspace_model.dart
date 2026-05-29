import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

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
    @Default([]) List<String> members,
    required DateTime createdAt,
  }) = _WorkspaceModel;

  factory WorkspaceModel.empty() {
    return WorkspaceModel(
      id: Uuid().v4(),
      name: "",
      type: WorkspaceType.personal,
      createdAt: DateTime.now(),
    );
  }

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceModelFromJson(json);
}
