// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weekly_mission_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WeeklyMissionModel {

 String get id; String get name; WeeklyMissionType get type; WeeklyMissionStatus get status; String get weekId;/// Alvo da missão (3 categorias planejadas, 5 dias no limite, ...).
 int get target; int get progress;/// XP que a missão paga. O servidor chama o campo de `rewardXp`; o
/// contrato do produto fala em `xp`. O mapper aceita os dois.
 int get xp;
/// Create a copy of WeeklyMissionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyMissionModelCopyWith<WeeklyMissionModel> get copyWith => _$WeeklyMissionModelCopyWithImpl<WeeklyMissionModel>(this as WeeklyMissionModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyMissionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.weekId, weekId) || other.weekId == weekId)&&(identical(other.target, target) || other.target == target)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.xp, xp) || other.xp == xp));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,type,status,weekId,target,progress,xp);

@override
String toString() {
  return 'WeeklyMissionModel(id: $id, name: $name, type: $type, status: $status, weekId: $weekId, target: $target, progress: $progress, xp: $xp)';
}


}

/// @nodoc
abstract mixin class $WeeklyMissionModelCopyWith<$Res>  {
  factory $WeeklyMissionModelCopyWith(WeeklyMissionModel value, $Res Function(WeeklyMissionModel) _then) = _$WeeklyMissionModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, WeeklyMissionType type, WeeklyMissionStatus status, String weekId, int target, int progress, int xp
});




}
/// @nodoc
class _$WeeklyMissionModelCopyWithImpl<$Res>
    implements $WeeklyMissionModelCopyWith<$Res> {
  _$WeeklyMissionModelCopyWithImpl(this._self, this._then);

  final WeeklyMissionModel _self;
  final $Res Function(WeeklyMissionModel) _then;

/// Create a copy of WeeklyMissionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? status = null,Object? weekId = null,Object? target = null,Object? progress = null,Object? xp = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as WeeklyMissionType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WeeklyMissionStatus,weekId: null == weekId ? _self.weekId : weekId // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as int,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklyMissionModel].
extension WeeklyMissionModelPatterns on WeeklyMissionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyMissionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyMissionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyMissionModel value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyMissionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyMissionModel value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyMissionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  WeeklyMissionType type,  WeeklyMissionStatus status,  String weekId,  int target,  int progress,  int xp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyMissionModel() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.status,_that.weekId,_that.target,_that.progress,_that.xp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  WeeklyMissionType type,  WeeklyMissionStatus status,  String weekId,  int target,  int progress,  int xp)  $default,) {final _that = this;
switch (_that) {
case _WeeklyMissionModel():
return $default(_that.id,_that.name,_that.type,_that.status,_that.weekId,_that.target,_that.progress,_that.xp);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  WeeklyMissionType type,  WeeklyMissionStatus status,  String weekId,  int target,  int progress,  int xp)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyMissionModel() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.status,_that.weekId,_that.target,_that.progress,_that.xp);case _:
  return null;

}
}

}

/// @nodoc


class _WeeklyMissionModel extends WeeklyMissionModel {
  const _WeeklyMissionModel({required this.id, required this.name, required this.type, required this.status, required this.weekId, this.target = 0, this.progress = 0, this.xp = 0}): super._();
  

@override final  String id;
@override final  String name;
@override final  WeeklyMissionType type;
@override final  WeeklyMissionStatus status;
@override final  String weekId;
/// Alvo da missão (3 categorias planejadas, 5 dias no limite, ...).
@override@JsonKey() final  int target;
@override@JsonKey() final  int progress;
/// XP que a missão paga. O servidor chama o campo de `rewardXp`; o
/// contrato do produto fala em `xp`. O mapper aceita os dois.
@override@JsonKey() final  int xp;

/// Create a copy of WeeklyMissionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyMissionModelCopyWith<_WeeklyMissionModel> get copyWith => __$WeeklyMissionModelCopyWithImpl<_WeeklyMissionModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyMissionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.weekId, weekId) || other.weekId == weekId)&&(identical(other.target, target) || other.target == target)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.xp, xp) || other.xp == xp));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,type,status,weekId,target,progress,xp);

@override
String toString() {
  return 'WeeklyMissionModel(id: $id, name: $name, type: $type, status: $status, weekId: $weekId, target: $target, progress: $progress, xp: $xp)';
}


}

/// @nodoc
abstract mixin class _$WeeklyMissionModelCopyWith<$Res> implements $WeeklyMissionModelCopyWith<$Res> {
  factory _$WeeklyMissionModelCopyWith(_WeeklyMissionModel value, $Res Function(_WeeklyMissionModel) _then) = __$WeeklyMissionModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, WeeklyMissionType type, WeeklyMissionStatus status, String weekId, int target, int progress, int xp
});




}
/// @nodoc
class __$WeeklyMissionModelCopyWithImpl<$Res>
    implements _$WeeklyMissionModelCopyWith<$Res> {
  __$WeeklyMissionModelCopyWithImpl(this._self, this._then);

  final _WeeklyMissionModel _self;
  final $Res Function(_WeeklyMissionModel) _then;

/// Create a copy of WeeklyMissionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? status = null,Object? weekId = null,Object? target = null,Object? progress = null,Object? xp = null,}) {
  return _then(_WeeklyMissionModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as WeeklyMissionType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WeeklyMissionStatus,weekId: null == weekId ? _self.weekId : weekId // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as int,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
