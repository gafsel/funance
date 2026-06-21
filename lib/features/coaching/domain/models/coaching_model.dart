import 'package:freezed_annotation/freezed_annotation.dart';

part 'coaching_model.freezed.dart';

part 'coaching_model.g.dart';

enum CoachingType {
  @JsonValue('insight')
  insight,
  @JsonValue('warning')
  warning,
  @JsonValue('tip')
  tip,
}

@freezed
sealed class SlideModel with _$SlideModel {
  const factory SlideModel({
    required String title,
    required String message,
    required String icon,
    required String color,
    String? secondaryColor,
    @Default([]) List<String> icons,
    String? animationType,
    String? actionLabel,
    String? actionPath,
  }) = _SlideModel;

  factory SlideModel.fromJson(Map<String, dynamic> json) =>
      _$SlideModelFromJson(json);
}

@freezed
sealed class CoachingModel with _$CoachingModel {
  @JsonSerializable(explicitToJson: true)
  const factory CoachingModel({
    required String id,
    required String message,
    String? summary,
    required DateTime date,
    required CoachingType type,
    @Default([]) List<SlideModel> slides,
  }) = _CoachingModel;

  const CoachingModel._();

  factory CoachingModel.fromJson(Map<String, dynamic> json) =>
      _$CoachingModelFromJson(json);

  bool get isDeprecated => DateTime.now().difference(date).inDays >= 7;
}
