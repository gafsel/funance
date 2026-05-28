import 'package:freezed_annotation/freezed_annotation.dart';

part 'hack_model.freezed.dart';
part 'hack_model.g.dart';

@freezed
sealed class HackModel with _$HackModel {
  const factory HackModel({
    required String id,
    required String title,
    required String content,
    required String category,
  }) = _HackModel;

  factory HackModel.fromJson(Map<String, dynamic> json) => _$HackModelFromJson(json);
}
