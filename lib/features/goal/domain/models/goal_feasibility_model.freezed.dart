// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'goal_feasibility_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GoalFeasibilityModel {

 GoalFeasibilityStatus get status; String get reason; String get suggestion;
/// Create a copy of GoalFeasibilityModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GoalFeasibilityModelCopyWith<GoalFeasibilityModel> get copyWith => _$GoalFeasibilityModelCopyWithImpl<GoalFeasibilityModel>(this as GoalFeasibilityModel, _$identity);

  /// Serializes this GoalFeasibilityModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GoalFeasibilityModel&&(identical(other.status, status) || other.status == status)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.suggestion, suggestion) || other.suggestion == suggestion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,reason,suggestion);

@override
String toString() {
  return 'GoalFeasibilityModel(status: $status, reason: $reason, suggestion: $suggestion)';
}


}

/// @nodoc
abstract mixin class $GoalFeasibilityModelCopyWith<$Res>  {
  factory $GoalFeasibilityModelCopyWith(GoalFeasibilityModel value, $Res Function(GoalFeasibilityModel) _then) = _$GoalFeasibilityModelCopyWithImpl;
@useResult
$Res call({
 GoalFeasibilityStatus status, String reason, String suggestion
});




}
/// @nodoc
class _$GoalFeasibilityModelCopyWithImpl<$Res>
    implements $GoalFeasibilityModelCopyWith<$Res> {
  _$GoalFeasibilityModelCopyWithImpl(this._self, this._then);

  final GoalFeasibilityModel _self;
  final $Res Function(GoalFeasibilityModel) _then;

/// Create a copy of GoalFeasibilityModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? reason = null,Object? suggestion = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GoalFeasibilityStatus,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,suggestion: null == suggestion ? _self.suggestion : suggestion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GoalFeasibilityModel].
extension GoalFeasibilityModelPatterns on GoalFeasibilityModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GoalFeasibilityModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GoalFeasibilityModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GoalFeasibilityModel value)  $default,){
final _that = this;
switch (_that) {
case _GoalFeasibilityModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GoalFeasibilityModel value)?  $default,){
final _that = this;
switch (_that) {
case _GoalFeasibilityModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GoalFeasibilityStatus status,  String reason,  String suggestion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GoalFeasibilityModel() when $default != null:
return $default(_that.status,_that.reason,_that.suggestion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GoalFeasibilityStatus status,  String reason,  String suggestion)  $default,) {final _that = this;
switch (_that) {
case _GoalFeasibilityModel():
return $default(_that.status,_that.reason,_that.suggestion);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GoalFeasibilityStatus status,  String reason,  String suggestion)?  $default,) {final _that = this;
switch (_that) {
case _GoalFeasibilityModel() when $default != null:
return $default(_that.status,_that.reason,_that.suggestion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GoalFeasibilityModel implements GoalFeasibilityModel {
  const _GoalFeasibilityModel({required this.status, required this.reason, required this.suggestion});
  factory _GoalFeasibilityModel.fromJson(Map<String, dynamic> json) => _$GoalFeasibilityModelFromJson(json);

@override final  GoalFeasibilityStatus status;
@override final  String reason;
@override final  String suggestion;

/// Create a copy of GoalFeasibilityModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoalFeasibilityModelCopyWith<_GoalFeasibilityModel> get copyWith => __$GoalFeasibilityModelCopyWithImpl<_GoalFeasibilityModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GoalFeasibilityModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GoalFeasibilityModel&&(identical(other.status, status) || other.status == status)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.suggestion, suggestion) || other.suggestion == suggestion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,reason,suggestion);

@override
String toString() {
  return 'GoalFeasibilityModel(status: $status, reason: $reason, suggestion: $suggestion)';
}


}

/// @nodoc
abstract mixin class _$GoalFeasibilityModelCopyWith<$Res> implements $GoalFeasibilityModelCopyWith<$Res> {
  factory _$GoalFeasibilityModelCopyWith(_GoalFeasibilityModel value, $Res Function(_GoalFeasibilityModel) _then) = __$GoalFeasibilityModelCopyWithImpl;
@override @useResult
$Res call({
 GoalFeasibilityStatus status, String reason, String suggestion
});




}
/// @nodoc
class __$GoalFeasibilityModelCopyWithImpl<$Res>
    implements _$GoalFeasibilityModelCopyWith<$Res> {
  __$GoalFeasibilityModelCopyWithImpl(this._self, this._then);

  final _GoalFeasibilityModel _self;
  final $Res Function(_GoalFeasibilityModel) _then;

/// Create a copy of GoalFeasibilityModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? reason = null,Object? suggestion = null,}) {
  return _then(_GoalFeasibilityModel(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GoalFeasibilityStatus,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,suggestion: null == suggestion ? _self.suggestion : suggestion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
