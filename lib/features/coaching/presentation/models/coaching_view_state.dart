import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';

part 'coaching_view_state.freezed.dart';

@freezed
sealed class CoachingState with _$CoachingState {
  factory CoachingState({CoachingModel? latestCoaching, String? error}) =
      _CoachingState;
}
