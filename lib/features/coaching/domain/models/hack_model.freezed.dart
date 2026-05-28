// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hack_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HackModel {

 String get id; String get title; String get content; String get category;
/// Create a copy of HackModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HackModelCopyWith<HackModel> get copyWith => _$HackModelCopyWithImpl<HackModel>(this as HackModel, _$identity);

  /// Serializes this HackModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HackModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,content,category);

@override
String toString() {
  return 'HackModel(id: $id, title: $title, content: $content, category: $category)';
}


}

/// @nodoc
abstract mixin class $HackModelCopyWith<$Res>  {
  factory $HackModelCopyWith(HackModel value, $Res Function(HackModel) _then) = _$HackModelCopyWithImpl;
@useResult
$Res call({
 String id, String title, String content, String category
});




}
/// @nodoc
class _$HackModelCopyWithImpl<$Res>
    implements $HackModelCopyWith<$Res> {
  _$HackModelCopyWithImpl(this._self, this._then);

  final HackModel _self;
  final $Res Function(HackModel) _then;

/// Create a copy of HackModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? content = null,Object? category = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [HackModel].
extension HackModelPatterns on HackModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HackModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HackModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HackModel value)  $default,){
final _that = this;
switch (_that) {
case _HackModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HackModel value)?  $default,){
final _that = this;
switch (_that) {
case _HackModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String content,  String category)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HackModel() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.category);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String content,  String category)  $default,) {final _that = this;
switch (_that) {
case _HackModel():
return $default(_that.id,_that.title,_that.content,_that.category);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String content,  String category)?  $default,) {final _that = this;
switch (_that) {
case _HackModel() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.category);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HackModel implements HackModel {
  const _HackModel({required this.id, required this.title, required this.content, required this.category});
  factory _HackModel.fromJson(Map<String, dynamic> json) => _$HackModelFromJson(json);

@override final  String id;
@override final  String title;
@override final  String content;
@override final  String category;

/// Create a copy of HackModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HackModelCopyWith<_HackModel> get copyWith => __$HackModelCopyWithImpl<_HackModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HackModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HackModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,content,category);

@override
String toString() {
  return 'HackModel(id: $id, title: $title, content: $content, category: $category)';
}


}

/// @nodoc
abstract mixin class _$HackModelCopyWith<$Res> implements $HackModelCopyWith<$Res> {
  factory _$HackModelCopyWith(_HackModel value, $Res Function(_HackModel) _then) = __$HackModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String content, String category
});




}
/// @nodoc
class __$HackModelCopyWithImpl<$Res>
    implements _$HackModelCopyWith<$Res> {
  __$HackModelCopyWithImpl(this._self, this._then);

  final _HackModel _self;
  final $Res Function(_HackModel) _then;

/// Create a copy of HackModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? content = null,Object? category = null,}) {
  return _then(_HackModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
