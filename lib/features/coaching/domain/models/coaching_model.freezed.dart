// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coaching_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CoachingModel {

 String get id; String get message; DateTime get date; CoachingType get type;
/// Create a copy of CoachingModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachingModelCopyWith<CoachingModel> get copyWith => _$CoachingModelCopyWithImpl<CoachingModel>(this as CoachingModel, _$identity);

  /// Serializes this CoachingModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachingModel&&(identical(other.id, id) || other.id == id)&&(identical(other.message, message) || other.message == message)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,message,date,type);

@override
String toString() {
  return 'CoachingModel(id: $id, message: $message, date: $date, type: $type)';
}


}

/// @nodoc
abstract mixin class $CoachingModelCopyWith<$Res>  {
  factory $CoachingModelCopyWith(CoachingModel value, $Res Function(CoachingModel) _then) = _$CoachingModelCopyWithImpl;
@useResult
$Res call({
 String id, String message, DateTime date, CoachingType type
});




}
/// @nodoc
class _$CoachingModelCopyWithImpl<$Res>
    implements $CoachingModelCopyWith<$Res> {
  _$CoachingModelCopyWithImpl(this._self, this._then);

  final CoachingModel _self;
  final $Res Function(CoachingModel) _then;

/// Create a copy of CoachingModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? message = null,Object? date = null,Object? type = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CoachingType,
  ));
}

}


/// Adds pattern-matching-related methods to [CoachingModel].
extension CoachingModelPatterns on CoachingModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoachingModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoachingModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoachingModel value)  $default,){
final _that = this;
switch (_that) {
case _CoachingModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoachingModel value)?  $default,){
final _that = this;
switch (_that) {
case _CoachingModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String message,  DateTime date,  CoachingType type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoachingModel() when $default != null:
return $default(_that.id,_that.message,_that.date,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String message,  DateTime date,  CoachingType type)  $default,) {final _that = this;
switch (_that) {
case _CoachingModel():
return $default(_that.id,_that.message,_that.date,_that.type);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String message,  DateTime date,  CoachingType type)?  $default,) {final _that = this;
switch (_that) {
case _CoachingModel() when $default != null:
return $default(_that.id,_that.message,_that.date,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CoachingModel implements CoachingModel {
  const _CoachingModel({required this.id, required this.message, required this.date, required this.type});
  factory _CoachingModel.fromJson(Map<String, dynamic> json) => _$CoachingModelFromJson(json);

@override final  String id;
@override final  String message;
@override final  DateTime date;
@override final  CoachingType type;

/// Create a copy of CoachingModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoachingModelCopyWith<_CoachingModel> get copyWith => __$CoachingModelCopyWithImpl<_CoachingModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoachingModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoachingModel&&(identical(other.id, id) || other.id == id)&&(identical(other.message, message) || other.message == message)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,message,date,type);

@override
String toString() {
  return 'CoachingModel(id: $id, message: $message, date: $date, type: $type)';
}


}

/// @nodoc
abstract mixin class _$CoachingModelCopyWith<$Res> implements $CoachingModelCopyWith<$Res> {
  factory _$CoachingModelCopyWith(_CoachingModel value, $Res Function(_CoachingModel) _then) = __$CoachingModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String message, DateTime date, CoachingType type
});




}
/// @nodoc
class __$CoachingModelCopyWithImpl<$Res>
    implements _$CoachingModelCopyWith<$Res> {
  __$CoachingModelCopyWithImpl(this._self, this._then);

  final _CoachingModel _self;
  final $Res Function(_CoachingModel) _then;

/// Create a copy of CoachingModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? message = null,Object? date = null,Object? type = null,}) {
  return _then(_CoachingModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CoachingType,
  ));
}


}

// dart format on
