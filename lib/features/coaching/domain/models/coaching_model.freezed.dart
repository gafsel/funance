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
mixin _$SlideModel {

 String get title; String get message; String get icon; String get color; String? get secondaryColor; List<String> get icons; String? get animationType;
/// Create a copy of SlideModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SlideModelCopyWith<SlideModel> get copyWith => _$SlideModelCopyWithImpl<SlideModel>(this as SlideModel, _$identity);

  /// Serializes this SlideModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SlideModel&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.secondaryColor, secondaryColor) || other.secondaryColor == secondaryColor)&&const DeepCollectionEquality().equals(other.icons, icons)&&(identical(other.animationType, animationType) || other.animationType == animationType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,message,icon,color,secondaryColor,const DeepCollectionEquality().hash(icons),animationType);

@override
String toString() {
  return 'SlideModel(title: $title, message: $message, icon: $icon, color: $color, secondaryColor: $secondaryColor, icons: $icons, animationType: $animationType)';
}


}

/// @nodoc
abstract mixin class $SlideModelCopyWith<$Res>  {
  factory $SlideModelCopyWith(SlideModel value, $Res Function(SlideModel) _then) = _$SlideModelCopyWithImpl;
@useResult
$Res call({
 String title, String message, String icon, String color, String? secondaryColor, List<String> icons, String? animationType
});




}
/// @nodoc
class _$SlideModelCopyWithImpl<$Res>
    implements $SlideModelCopyWith<$Res> {
  _$SlideModelCopyWithImpl(this._self, this._then);

  final SlideModel _self;
  final $Res Function(SlideModel) _then;

/// Create a copy of SlideModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? message = null,Object? icon = null,Object? color = null,Object? secondaryColor = freezed,Object? icons = null,Object? animationType = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,secondaryColor: freezed == secondaryColor ? _self.secondaryColor : secondaryColor // ignore: cast_nullable_to_non_nullable
as String?,icons: null == icons ? _self.icons : icons // ignore: cast_nullable_to_non_nullable
as List<String>,animationType: freezed == animationType ? _self.animationType : animationType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SlideModel].
extension SlideModelPatterns on SlideModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SlideModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SlideModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SlideModel value)  $default,){
final _that = this;
switch (_that) {
case _SlideModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SlideModel value)?  $default,){
final _that = this;
switch (_that) {
case _SlideModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String message,  String icon,  String color,  String? secondaryColor,  List<String> icons,  String? animationType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SlideModel() when $default != null:
return $default(_that.title,_that.message,_that.icon,_that.color,_that.secondaryColor,_that.icons,_that.animationType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String message,  String icon,  String color,  String? secondaryColor,  List<String> icons,  String? animationType)  $default,) {final _that = this;
switch (_that) {
case _SlideModel():
return $default(_that.title,_that.message,_that.icon,_that.color,_that.secondaryColor,_that.icons,_that.animationType);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String message,  String icon,  String color,  String? secondaryColor,  List<String> icons,  String? animationType)?  $default,) {final _that = this;
switch (_that) {
case _SlideModel() when $default != null:
return $default(_that.title,_that.message,_that.icon,_that.color,_that.secondaryColor,_that.icons,_that.animationType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SlideModel implements SlideModel {
  const _SlideModel({required this.title, required this.message, required this.icon, required this.color, this.secondaryColor, final  List<String> icons = const [], this.animationType}): _icons = icons;
  factory _SlideModel.fromJson(Map<String, dynamic> json) => _$SlideModelFromJson(json);

@override final  String title;
@override final  String message;
@override final  String icon;
@override final  String color;
@override final  String? secondaryColor;
 final  List<String> _icons;
@override@JsonKey() List<String> get icons {
  if (_icons is EqualUnmodifiableListView) return _icons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_icons);
}

@override final  String? animationType;

/// Create a copy of SlideModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SlideModelCopyWith<_SlideModel> get copyWith => __$SlideModelCopyWithImpl<_SlideModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SlideModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SlideModel&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.secondaryColor, secondaryColor) || other.secondaryColor == secondaryColor)&&const DeepCollectionEquality().equals(other._icons, _icons)&&(identical(other.animationType, animationType) || other.animationType == animationType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,message,icon,color,secondaryColor,const DeepCollectionEquality().hash(_icons),animationType);

@override
String toString() {
  return 'SlideModel(title: $title, message: $message, icon: $icon, color: $color, secondaryColor: $secondaryColor, icons: $icons, animationType: $animationType)';
}


}

/// @nodoc
abstract mixin class _$SlideModelCopyWith<$Res> implements $SlideModelCopyWith<$Res> {
  factory _$SlideModelCopyWith(_SlideModel value, $Res Function(_SlideModel) _then) = __$SlideModelCopyWithImpl;
@override @useResult
$Res call({
 String title, String message, String icon, String color, String? secondaryColor, List<String> icons, String? animationType
});




}
/// @nodoc
class __$SlideModelCopyWithImpl<$Res>
    implements _$SlideModelCopyWith<$Res> {
  __$SlideModelCopyWithImpl(this._self, this._then);

  final _SlideModel _self;
  final $Res Function(_SlideModel) _then;

/// Create a copy of SlideModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? message = null,Object? icon = null,Object? color = null,Object? secondaryColor = freezed,Object? icons = null,Object? animationType = freezed,}) {
  return _then(_SlideModel(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,secondaryColor: freezed == secondaryColor ? _self.secondaryColor : secondaryColor // ignore: cast_nullable_to_non_nullable
as String?,icons: null == icons ? _self._icons : icons // ignore: cast_nullable_to_non_nullable
as List<String>,animationType: freezed == animationType ? _self.animationType : animationType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CoachingModel {

 String get id; String get message; DateTime get date; CoachingType get type; List<SlideModel> get slides;
/// Create a copy of CoachingModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachingModelCopyWith<CoachingModel> get copyWith => _$CoachingModelCopyWithImpl<CoachingModel>(this as CoachingModel, _$identity);

  /// Serializes this CoachingModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachingModel&&(identical(other.id, id) || other.id == id)&&(identical(other.message, message) || other.message == message)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.slides, slides));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,message,date,type,const DeepCollectionEquality().hash(slides));

@override
String toString() {
  return 'CoachingModel(id: $id, message: $message, date: $date, type: $type, slides: $slides)';
}


}

/// @nodoc
abstract mixin class $CoachingModelCopyWith<$Res>  {
  factory $CoachingModelCopyWith(CoachingModel value, $Res Function(CoachingModel) _then) = _$CoachingModelCopyWithImpl;
@useResult
$Res call({
 String id, String message, DateTime date, CoachingType type, List<SlideModel> slides
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? message = null,Object? date = null,Object? type = null,Object? slides = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CoachingType,slides: null == slides ? _self.slides : slides // ignore: cast_nullable_to_non_nullable
as List<SlideModel>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String message,  DateTime date,  CoachingType type,  List<SlideModel> slides)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoachingModel() when $default != null:
return $default(_that.id,_that.message,_that.date,_that.type,_that.slides);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String message,  DateTime date,  CoachingType type,  List<SlideModel> slides)  $default,) {final _that = this;
switch (_that) {
case _CoachingModel():
return $default(_that.id,_that.message,_that.date,_that.type,_that.slides);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String message,  DateTime date,  CoachingType type,  List<SlideModel> slides)?  $default,) {final _that = this;
switch (_that) {
case _CoachingModel() when $default != null:
return $default(_that.id,_that.message,_that.date,_that.type,_that.slides);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CoachingModel implements CoachingModel {
  const _CoachingModel({required this.id, required this.message, required this.date, required this.type, final  List<SlideModel> slides = const []}): _slides = slides;
  factory _CoachingModel.fromJson(Map<String, dynamic> json) => _$CoachingModelFromJson(json);

@override final  String id;
@override final  String message;
@override final  DateTime date;
@override final  CoachingType type;
 final  List<SlideModel> _slides;
@override@JsonKey() List<SlideModel> get slides {
  if (_slides is EqualUnmodifiableListView) return _slides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_slides);
}


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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoachingModel&&(identical(other.id, id) || other.id == id)&&(identical(other.message, message) || other.message == message)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._slides, _slides));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,message,date,type,const DeepCollectionEquality().hash(_slides));

@override
String toString() {
  return 'CoachingModel(id: $id, message: $message, date: $date, type: $type, slides: $slides)';
}


}

/// @nodoc
abstract mixin class _$CoachingModelCopyWith<$Res> implements $CoachingModelCopyWith<$Res> {
  factory _$CoachingModelCopyWith(_CoachingModel value, $Res Function(_CoachingModel) _then) = __$CoachingModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String message, DateTime date, CoachingType type, List<SlideModel> slides
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? message = null,Object? date = null,Object? type = null,Object? slides = null,}) {
  return _then(_CoachingModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CoachingType,slides: null == slides ? _self._slides : slides // ignore: cast_nullable_to_non_nullable
as List<SlideModel>,
  ));
}


}

// dart format on
