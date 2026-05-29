// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlanningSuggestions {

 List<CategoryPlanningModel> get plannings; List<GoalModel> get goals;
/// Create a copy of PlanningSuggestions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanningSuggestionsCopyWith<PlanningSuggestions> get copyWith => _$PlanningSuggestionsCopyWithImpl<PlanningSuggestions>(this as PlanningSuggestions, _$identity);

  /// Serializes this PlanningSuggestions to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanningSuggestions&&const DeepCollectionEquality().equals(other.plannings, plannings)&&const DeepCollectionEquality().equals(other.goals, goals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(plannings),const DeepCollectionEquality().hash(goals));

@override
String toString() {
  return 'PlanningSuggestions(plannings: $plannings, goals: $goals)';
}


}

/// @nodoc
abstract mixin class $PlanningSuggestionsCopyWith<$Res>  {
  factory $PlanningSuggestionsCopyWith(PlanningSuggestions value, $Res Function(PlanningSuggestions) _then) = _$PlanningSuggestionsCopyWithImpl;
@useResult
$Res call({
 List<CategoryPlanningModel> plannings, List<GoalModel> goals
});




}
/// @nodoc
class _$PlanningSuggestionsCopyWithImpl<$Res>
    implements $PlanningSuggestionsCopyWith<$Res> {
  _$PlanningSuggestionsCopyWithImpl(this._self, this._then);

  final PlanningSuggestions _self;
  final $Res Function(PlanningSuggestions) _then;

/// Create a copy of PlanningSuggestions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plannings = null,Object? goals = null,}) {
  return _then(_self.copyWith(
plannings: null == plannings ? _self.plannings : plannings // ignore: cast_nullable_to_non_nullable
as List<CategoryPlanningModel>,goals: null == goals ? _self.goals : goals // ignore: cast_nullable_to_non_nullable
as List<GoalModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanningSuggestions].
extension PlanningSuggestionsPatterns on PlanningSuggestions {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanningSuggestions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanningSuggestions() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanningSuggestions value)  $default,){
final _that = this;
switch (_that) {
case _PlanningSuggestions():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanningSuggestions value)?  $default,){
final _that = this;
switch (_that) {
case _PlanningSuggestions() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CategoryPlanningModel> plannings,  List<GoalModel> goals)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanningSuggestions() when $default != null:
return $default(_that.plannings,_that.goals);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CategoryPlanningModel> plannings,  List<GoalModel> goals)  $default,) {final _that = this;
switch (_that) {
case _PlanningSuggestions():
return $default(_that.plannings,_that.goals);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CategoryPlanningModel> plannings,  List<GoalModel> goals)?  $default,) {final _that = this;
switch (_that) {
case _PlanningSuggestions() when $default != null:
return $default(_that.plannings,_that.goals);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanningSuggestions implements PlanningSuggestions {
   _PlanningSuggestions({final  List<CategoryPlanningModel> plannings = const [], final  List<GoalModel> goals = const []}): _plannings = plannings,_goals = goals;
  factory _PlanningSuggestions.fromJson(Map<String, dynamic> json) => _$PlanningSuggestionsFromJson(json);

 final  List<CategoryPlanningModel> _plannings;
@override@JsonKey() List<CategoryPlanningModel> get plannings {
  if (_plannings is EqualUnmodifiableListView) return _plannings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_plannings);
}

 final  List<GoalModel> _goals;
@override@JsonKey() List<GoalModel> get goals {
  if (_goals is EqualUnmodifiableListView) return _goals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_goals);
}


/// Create a copy of PlanningSuggestions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanningSuggestionsCopyWith<_PlanningSuggestions> get copyWith => __$PlanningSuggestionsCopyWithImpl<_PlanningSuggestions>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanningSuggestionsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanningSuggestions&&const DeepCollectionEquality().equals(other._plannings, _plannings)&&const DeepCollectionEquality().equals(other._goals, _goals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_plannings),const DeepCollectionEquality().hash(_goals));

@override
String toString() {
  return 'PlanningSuggestions(plannings: $plannings, goals: $goals)';
}


}

/// @nodoc
abstract mixin class _$PlanningSuggestionsCopyWith<$Res> implements $PlanningSuggestionsCopyWith<$Res> {
  factory _$PlanningSuggestionsCopyWith(_PlanningSuggestions value, $Res Function(_PlanningSuggestions) _then) = __$PlanningSuggestionsCopyWithImpl;
@override @useResult
$Res call({
 List<CategoryPlanningModel> plannings, List<GoalModel> goals
});




}
/// @nodoc
class __$PlanningSuggestionsCopyWithImpl<$Res>
    implements _$PlanningSuggestionsCopyWith<$Res> {
  __$PlanningSuggestionsCopyWithImpl(this._self, this._then);

  final _PlanningSuggestions _self;
  final $Res Function(_PlanningSuggestions) _then;

/// Create a copy of PlanningSuggestions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plannings = null,Object? goals = null,}) {
  return _then(_PlanningSuggestions(
plannings: null == plannings ? _self._plannings : plannings // ignore: cast_nullable_to_non_nullable
as List<CategoryPlanningModel>,goals: null == goals ? _self._goals : goals // ignore: cast_nullable_to_non_nullable
as List<GoalModel>,
  ));
}


}

// dart format on
