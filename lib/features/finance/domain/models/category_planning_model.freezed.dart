// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_planning_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CategoryPlanningModel {

 String get id; CategoryModel get category; double get amount; String get startMonth; String get endMonth;
/// Create a copy of CategoryPlanningModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryPlanningModelCopyWith<CategoryPlanningModel> get copyWith => _$CategoryPlanningModelCopyWithImpl<CategoryPlanningModel>(this as CategoryPlanningModel, _$identity);

  /// Serializes this CategoryPlanningModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryPlanningModel&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.startMonth, startMonth) || other.startMonth == startMonth)&&(identical(other.endMonth, endMonth) || other.endMonth == endMonth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,category,amount,startMonth,endMonth);

@override
String toString() {
  return 'CategoryPlanningModel(id: $id, category: $category, amount: $amount, startMonth: $startMonth, endMonth: $endMonth)';
}


}

/// @nodoc
abstract mixin class $CategoryPlanningModelCopyWith<$Res>  {
  factory $CategoryPlanningModelCopyWith(CategoryPlanningModel value, $Res Function(CategoryPlanningModel) _then) = _$CategoryPlanningModelCopyWithImpl;
@useResult
$Res call({
 String id, CategoryModel category, double amount, String startMonth, String endMonth
});


$CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class _$CategoryPlanningModelCopyWithImpl<$Res>
    implements $CategoryPlanningModelCopyWith<$Res> {
  _$CategoryPlanningModelCopyWithImpl(this._self, this._then);

  final CategoryPlanningModel _self;
  final $Res Function(CategoryPlanningModel) _then;

/// Create a copy of CategoryPlanningModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? category = null,Object? amount = null,Object? startMonth = null,Object? endMonth = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,startMonth: null == startMonth ? _self.startMonth : startMonth // ignore: cast_nullable_to_non_nullable
as String,endMonth: null == endMonth ? _self.endMonth : endMonth // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of CategoryPlanningModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [CategoryPlanningModel].
extension CategoryPlanningModelPatterns on CategoryPlanningModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryPlanningModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryPlanningModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryPlanningModel value)  $default,){
final _that = this;
switch (_that) {
case _CategoryPlanningModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryPlanningModel value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryPlanningModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  CategoryModel category,  double amount,  String startMonth,  String endMonth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryPlanningModel() when $default != null:
return $default(_that.id,_that.category,_that.amount,_that.startMonth,_that.endMonth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  CategoryModel category,  double amount,  String startMonth,  String endMonth)  $default,) {final _that = this;
switch (_that) {
case _CategoryPlanningModel():
return $default(_that.id,_that.category,_that.amount,_that.startMonth,_that.endMonth);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  CategoryModel category,  double amount,  String startMonth,  String endMonth)?  $default,) {final _that = this;
switch (_that) {
case _CategoryPlanningModel() when $default != null:
return $default(_that.id,_that.category,_that.amount,_that.startMonth,_that.endMonth);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryPlanningModel implements CategoryPlanningModel {
  const _CategoryPlanningModel({required this.id, required this.category, required this.amount, required this.startMonth, required this.endMonth});
  factory _CategoryPlanningModel.fromJson(Map<String, dynamic> json) => _$CategoryPlanningModelFromJson(json);

@override final  String id;
@override final  CategoryModel category;
@override final  double amount;
@override final  String startMonth;
@override final  String endMonth;

/// Create a copy of CategoryPlanningModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryPlanningModelCopyWith<_CategoryPlanningModel> get copyWith => __$CategoryPlanningModelCopyWithImpl<_CategoryPlanningModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryPlanningModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryPlanningModel&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.startMonth, startMonth) || other.startMonth == startMonth)&&(identical(other.endMonth, endMonth) || other.endMonth == endMonth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,category,amount,startMonth,endMonth);

@override
String toString() {
  return 'CategoryPlanningModel(id: $id, category: $category, amount: $amount, startMonth: $startMonth, endMonth: $endMonth)';
}


}

/// @nodoc
abstract mixin class _$CategoryPlanningModelCopyWith<$Res> implements $CategoryPlanningModelCopyWith<$Res> {
  factory _$CategoryPlanningModelCopyWith(_CategoryPlanningModel value, $Res Function(_CategoryPlanningModel) _then) = __$CategoryPlanningModelCopyWithImpl;
@override @useResult
$Res call({
 String id, CategoryModel category, double amount, String startMonth, String endMonth
});


@override $CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class __$CategoryPlanningModelCopyWithImpl<$Res>
    implements _$CategoryPlanningModelCopyWith<$Res> {
  __$CategoryPlanningModelCopyWithImpl(this._self, this._then);

  final _CategoryPlanningModel _self;
  final $Res Function(_CategoryPlanningModel) _then;

/// Create a copy of CategoryPlanningModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? amount = null,Object? startMonth = null,Object? endMonth = null,}) {
  return _then(_CategoryPlanningModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,startMonth: null == startMonth ? _self.startMonth : startMonth // ignore: cast_nullable_to_non_nullable
as String,endMonth: null == endMonth ? _self.endMonth : endMonth // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of CategoryPlanningModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

// dart format on
