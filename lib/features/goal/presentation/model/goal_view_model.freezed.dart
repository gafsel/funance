// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'goal_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GoalFormState {

 String? get id; String get name; double get targetAmount; double get currentAmount; DateTime get startDate; DateTime get deadline; GoalType get type; CategoryModel? get category; String? get accountId;
/// Create a copy of GoalFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GoalFormStateCopyWith<GoalFormState> get copyWith => _$GoalFormStateCopyWithImpl<GoalFormState>(this as GoalFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GoalFormState&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.targetAmount, targetAmount) || other.targetAmount == targetAmount)&&(identical(other.currentAmount, currentAmount) || other.currentAmount == currentAmount)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category)&&(identical(other.accountId, accountId) || other.accountId == accountId));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,targetAmount,currentAmount,startDate,deadline,type,category,accountId);

@override
String toString() {
  return 'GoalFormState(id: $id, name: $name, targetAmount: $targetAmount, currentAmount: $currentAmount, startDate: $startDate, deadline: $deadline, type: $type, category: $category, accountId: $accountId)';
}


}

/// @nodoc
abstract mixin class $GoalFormStateCopyWith<$Res>  {
  factory $GoalFormStateCopyWith(GoalFormState value, $Res Function(GoalFormState) _then) = _$GoalFormStateCopyWithImpl;
@useResult
$Res call({
 String? id, String name, double targetAmount, double currentAmount, DateTime startDate, DateTime deadline, GoalType type, CategoryModel? category, String? accountId
});


$CategoryModelCopyWith<$Res>? get category;

}
/// @nodoc
class _$GoalFormStateCopyWithImpl<$Res>
    implements $GoalFormStateCopyWith<$Res> {
  _$GoalFormStateCopyWithImpl(this._self, this._then);

  final GoalFormState _self;
  final $Res Function(GoalFormState) _then;

/// Create a copy of GoalFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = null,Object? targetAmount = null,Object? currentAmount = null,Object? startDate = null,Object? deadline = null,Object? type = null,Object? category = freezed,Object? accountId = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,targetAmount: null == targetAmount ? _self.targetAmount : targetAmount // ignore: cast_nullable_to_non_nullable
as double,currentAmount: null == currentAmount ? _self.currentAmount : currentAmount // ignore: cast_nullable_to_non_nullable
as double,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,deadline: null == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as GoalType,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of GoalFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [GoalFormState].
extension GoalFormStatePatterns on GoalFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GoalFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GoalFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GoalFormState value)  $default,){
final _that = this;
switch (_that) {
case _GoalFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GoalFormState value)?  $default,){
final _that = this;
switch (_that) {
case _GoalFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String name,  double targetAmount,  double currentAmount,  DateTime startDate,  DateTime deadline,  GoalType type,  CategoryModel? category,  String? accountId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GoalFormState() when $default != null:
return $default(_that.id,_that.name,_that.targetAmount,_that.currentAmount,_that.startDate,_that.deadline,_that.type,_that.category,_that.accountId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String name,  double targetAmount,  double currentAmount,  DateTime startDate,  DateTime deadline,  GoalType type,  CategoryModel? category,  String? accountId)  $default,) {final _that = this;
switch (_that) {
case _GoalFormState():
return $default(_that.id,_that.name,_that.targetAmount,_that.currentAmount,_that.startDate,_that.deadline,_that.type,_that.category,_that.accountId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String name,  double targetAmount,  double currentAmount,  DateTime startDate,  DateTime deadline,  GoalType type,  CategoryModel? category,  String? accountId)?  $default,) {final _that = this;
switch (_that) {
case _GoalFormState() when $default != null:
return $default(_that.id,_that.name,_that.targetAmount,_that.currentAmount,_that.startDate,_that.deadline,_that.type,_that.category,_that.accountId);case _:
  return null;

}
}

}

/// @nodoc


class _GoalFormState extends GoalFormState {
  const _GoalFormState({this.id, required this.name, required this.targetAmount, required this.currentAmount, required this.startDate, required this.deadline, required this.type, this.category, this.accountId}): super._();
  

@override final  String? id;
@override final  String name;
@override final  double targetAmount;
@override final  double currentAmount;
@override final  DateTime startDate;
@override final  DateTime deadline;
@override final  GoalType type;
@override final  CategoryModel? category;
@override final  String? accountId;

/// Create a copy of GoalFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoalFormStateCopyWith<_GoalFormState> get copyWith => __$GoalFormStateCopyWithImpl<_GoalFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GoalFormState&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.targetAmount, targetAmount) || other.targetAmount == targetAmount)&&(identical(other.currentAmount, currentAmount) || other.currentAmount == currentAmount)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category)&&(identical(other.accountId, accountId) || other.accountId == accountId));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,targetAmount,currentAmount,startDate,deadline,type,category,accountId);

@override
String toString() {
  return 'GoalFormState(id: $id, name: $name, targetAmount: $targetAmount, currentAmount: $currentAmount, startDate: $startDate, deadline: $deadline, type: $type, category: $category, accountId: $accountId)';
}


}

/// @nodoc
abstract mixin class _$GoalFormStateCopyWith<$Res> implements $GoalFormStateCopyWith<$Res> {
  factory _$GoalFormStateCopyWith(_GoalFormState value, $Res Function(_GoalFormState) _then) = __$GoalFormStateCopyWithImpl;
@override @useResult
$Res call({
 String? id, String name, double targetAmount, double currentAmount, DateTime startDate, DateTime deadline, GoalType type, CategoryModel? category, String? accountId
});


@override $CategoryModelCopyWith<$Res>? get category;

}
/// @nodoc
class __$GoalFormStateCopyWithImpl<$Res>
    implements _$GoalFormStateCopyWith<$Res> {
  __$GoalFormStateCopyWithImpl(this._self, this._then);

  final _GoalFormState _self;
  final $Res Function(_GoalFormState) _then;

/// Create a copy of GoalFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = null,Object? targetAmount = null,Object? currentAmount = null,Object? startDate = null,Object? deadline = null,Object? type = null,Object? category = freezed,Object? accountId = freezed,}) {
  return _then(_GoalFormState(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,targetAmount: null == targetAmount ? _self.targetAmount : targetAmount // ignore: cast_nullable_to_non_nullable
as double,currentAmount: null == currentAmount ? _self.currentAmount : currentAmount // ignore: cast_nullable_to_non_nullable
as double,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,deadline: null == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as GoalType,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of GoalFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

// dart format on
