// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_view_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CategoryFormState {

 CategoryModel? get category; String get name; CategoryType get type; String get color; String get icon;
/// Create a copy of CategoryFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryFormStateCopyWith<CategoryFormState> get copyWith => _$CategoryFormStateCopyWithImpl<CategoryFormState>(this as CategoryFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryFormState&&(identical(other.category, category) || other.category == category)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon));
}


@override
int get hashCode => Object.hash(runtimeType,category,name,type,color,icon);

@override
String toString() {
  return 'CategoryFormState(category: $category, name: $name, type: $type, color: $color, icon: $icon)';
}


}

/// @nodoc
abstract mixin class $CategoryFormStateCopyWith<$Res>  {
  factory $CategoryFormStateCopyWith(CategoryFormState value, $Res Function(CategoryFormState) _then) = _$CategoryFormStateCopyWithImpl;
@useResult
$Res call({
 CategoryModel? category, String name, CategoryType type, String color, String icon
});


$CategoryModelCopyWith<$Res>? get category;

}
/// @nodoc
class _$CategoryFormStateCopyWithImpl<$Res>
    implements $CategoryFormStateCopyWith<$Res> {
  _$CategoryFormStateCopyWithImpl(this._self, this._then);

  final CategoryFormState _self;
  final $Res Function(CategoryFormState) _then;

/// Create a copy of CategoryFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = freezed,Object? name = null,Object? type = null,Object? color = null,Object? icon = null,}) {
  return _then(_self.copyWith(
category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CategoryType,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of CategoryFormState
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


/// Adds pattern-matching-related methods to [CategoryFormState].
extension CategoryFormStatePatterns on CategoryFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryFormState value)  $default,){
final _that = this;
switch (_that) {
case _CategoryFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryFormState value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CategoryModel? category,  String name,  CategoryType type,  String color,  String icon)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryFormState() when $default != null:
return $default(_that.category,_that.name,_that.type,_that.color,_that.icon);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CategoryModel? category,  String name,  CategoryType type,  String color,  String icon)  $default,) {final _that = this;
switch (_that) {
case _CategoryFormState():
return $default(_that.category,_that.name,_that.type,_that.color,_that.icon);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CategoryModel? category,  String name,  CategoryType type,  String color,  String icon)?  $default,) {final _that = this;
switch (_that) {
case _CategoryFormState() when $default != null:
return $default(_that.category,_that.name,_that.type,_that.color,_that.icon);case _:
  return null;

}
}

}

/// @nodoc


class _CategoryFormState extends CategoryFormState {
  const _CategoryFormState({required this.category, required this.name, required this.type, required this.color, required this.icon}): super._();
  

@override final  CategoryModel? category;
@override final  String name;
@override final  CategoryType type;
@override final  String color;
@override final  String icon;

/// Create a copy of CategoryFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryFormStateCopyWith<_CategoryFormState> get copyWith => __$CategoryFormStateCopyWithImpl<_CategoryFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryFormState&&(identical(other.category, category) || other.category == category)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon));
}


@override
int get hashCode => Object.hash(runtimeType,category,name,type,color,icon);

@override
String toString() {
  return 'CategoryFormState(category: $category, name: $name, type: $type, color: $color, icon: $icon)';
}


}

/// @nodoc
abstract mixin class _$CategoryFormStateCopyWith<$Res> implements $CategoryFormStateCopyWith<$Res> {
  factory _$CategoryFormStateCopyWith(_CategoryFormState value, $Res Function(_CategoryFormState) _then) = __$CategoryFormStateCopyWithImpl;
@override @useResult
$Res call({
 CategoryModel? category, String name, CategoryType type, String color, String icon
});


@override $CategoryModelCopyWith<$Res>? get category;

}
/// @nodoc
class __$CategoryFormStateCopyWithImpl<$Res>
    implements _$CategoryFormStateCopyWith<$Res> {
  __$CategoryFormStateCopyWithImpl(this._self, this._then);

  final _CategoryFormState _self;
  final $Res Function(_CategoryFormState) _then;

/// Create a copy of CategoryFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = freezed,Object? name = null,Object? type = null,Object? color = null,Object? icon = null,}) {
  return _then(_CategoryFormState(
category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CategoryType,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of CategoryFormState
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

/// @nodoc
mixin _$CategoryGlobalProgressModel {

 double get totalPlanned; double get totalActual; double get totalIncome; double get actualPercentage; double get expenseActualPercentage;
/// Create a copy of CategoryGlobalProgressModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryGlobalProgressModelCopyWith<CategoryGlobalProgressModel> get copyWith => _$CategoryGlobalProgressModelCopyWithImpl<CategoryGlobalProgressModel>(this as CategoryGlobalProgressModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryGlobalProgressModel&&(identical(other.totalPlanned, totalPlanned) || other.totalPlanned == totalPlanned)&&(identical(other.totalActual, totalActual) || other.totalActual == totalActual)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.actualPercentage, actualPercentage) || other.actualPercentage == actualPercentage)&&(identical(other.expenseActualPercentage, expenseActualPercentage) || other.expenseActualPercentage == expenseActualPercentage));
}


@override
int get hashCode => Object.hash(runtimeType,totalPlanned,totalActual,totalIncome,actualPercentage,expenseActualPercentage);

@override
String toString() {
  return 'CategoryGlobalProgressModel(totalPlanned: $totalPlanned, totalActual: $totalActual, totalIncome: $totalIncome, actualPercentage: $actualPercentage, expenseActualPercentage: $expenseActualPercentage)';
}


}

/// @nodoc
abstract mixin class $CategoryGlobalProgressModelCopyWith<$Res>  {
  factory $CategoryGlobalProgressModelCopyWith(CategoryGlobalProgressModel value, $Res Function(CategoryGlobalProgressModel) _then) = _$CategoryGlobalProgressModelCopyWithImpl;
@useResult
$Res call({
 double totalPlanned, double totalActual, double totalIncome, double actualPercentage, double expenseActualPercentage
});




}
/// @nodoc
class _$CategoryGlobalProgressModelCopyWithImpl<$Res>
    implements $CategoryGlobalProgressModelCopyWith<$Res> {
  _$CategoryGlobalProgressModelCopyWithImpl(this._self, this._then);

  final CategoryGlobalProgressModel _self;
  final $Res Function(CategoryGlobalProgressModel) _then;

/// Create a copy of CategoryGlobalProgressModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalPlanned = null,Object? totalActual = null,Object? totalIncome = null,Object? actualPercentage = null,Object? expenseActualPercentage = null,}) {
  return _then(_self.copyWith(
totalPlanned: null == totalPlanned ? _self.totalPlanned : totalPlanned // ignore: cast_nullable_to_non_nullable
as double,totalActual: null == totalActual ? _self.totalActual : totalActual // ignore: cast_nullable_to_non_nullable
as double,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as double,actualPercentage: null == actualPercentage ? _self.actualPercentage : actualPercentage // ignore: cast_nullable_to_non_nullable
as double,expenseActualPercentage: null == expenseActualPercentage ? _self.expenseActualPercentage : expenseActualPercentage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryGlobalProgressModel].
extension CategoryGlobalProgressModelPatterns on CategoryGlobalProgressModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryGlobalProgressModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryGlobalProgressModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryGlobalProgressModel value)  $default,){
final _that = this;
switch (_that) {
case _CategoryGlobalProgressModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryGlobalProgressModel value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryGlobalProgressModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double totalPlanned,  double totalActual,  double totalIncome,  double actualPercentage,  double expenseActualPercentage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryGlobalProgressModel() when $default != null:
return $default(_that.totalPlanned,_that.totalActual,_that.totalIncome,_that.actualPercentage,_that.expenseActualPercentage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double totalPlanned,  double totalActual,  double totalIncome,  double actualPercentage,  double expenseActualPercentage)  $default,) {final _that = this;
switch (_that) {
case _CategoryGlobalProgressModel():
return $default(_that.totalPlanned,_that.totalActual,_that.totalIncome,_that.actualPercentage,_that.expenseActualPercentage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double totalPlanned,  double totalActual,  double totalIncome,  double actualPercentage,  double expenseActualPercentage)?  $default,) {final _that = this;
switch (_that) {
case _CategoryGlobalProgressModel() when $default != null:
return $default(_that.totalPlanned,_that.totalActual,_that.totalIncome,_that.actualPercentage,_that.expenseActualPercentage);case _:
  return null;

}
}

}

/// @nodoc


class _CategoryGlobalProgressModel implements CategoryGlobalProgressModel {
  const _CategoryGlobalProgressModel({required this.totalPlanned, required this.totalActual, required this.totalIncome, required this.actualPercentage, required this.expenseActualPercentage});
  

@override final  double totalPlanned;
@override final  double totalActual;
@override final  double totalIncome;
@override final  double actualPercentage;
@override final  double expenseActualPercentage;

/// Create a copy of CategoryGlobalProgressModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryGlobalProgressModelCopyWith<_CategoryGlobalProgressModel> get copyWith => __$CategoryGlobalProgressModelCopyWithImpl<_CategoryGlobalProgressModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryGlobalProgressModel&&(identical(other.totalPlanned, totalPlanned) || other.totalPlanned == totalPlanned)&&(identical(other.totalActual, totalActual) || other.totalActual == totalActual)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.actualPercentage, actualPercentage) || other.actualPercentage == actualPercentage)&&(identical(other.expenseActualPercentage, expenseActualPercentage) || other.expenseActualPercentage == expenseActualPercentage));
}


@override
int get hashCode => Object.hash(runtimeType,totalPlanned,totalActual,totalIncome,actualPercentage,expenseActualPercentage);

@override
String toString() {
  return 'CategoryGlobalProgressModel(totalPlanned: $totalPlanned, totalActual: $totalActual, totalIncome: $totalIncome, actualPercentage: $actualPercentage, expenseActualPercentage: $expenseActualPercentage)';
}


}

/// @nodoc
abstract mixin class _$CategoryGlobalProgressModelCopyWith<$Res> implements $CategoryGlobalProgressModelCopyWith<$Res> {
  factory _$CategoryGlobalProgressModelCopyWith(_CategoryGlobalProgressModel value, $Res Function(_CategoryGlobalProgressModel) _then) = __$CategoryGlobalProgressModelCopyWithImpl;
@override @useResult
$Res call({
 double totalPlanned, double totalActual, double totalIncome, double actualPercentage, double expenseActualPercentage
});




}
/// @nodoc
class __$CategoryGlobalProgressModelCopyWithImpl<$Res>
    implements _$CategoryGlobalProgressModelCopyWith<$Res> {
  __$CategoryGlobalProgressModelCopyWithImpl(this._self, this._then);

  final _CategoryGlobalProgressModel _self;
  final $Res Function(_CategoryGlobalProgressModel) _then;

/// Create a copy of CategoryGlobalProgressModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalPlanned = null,Object? totalActual = null,Object? totalIncome = null,Object? actualPercentage = null,Object? expenseActualPercentage = null,}) {
  return _then(_CategoryGlobalProgressModel(
totalPlanned: null == totalPlanned ? _self.totalPlanned : totalPlanned // ignore: cast_nullable_to_non_nullable
as double,totalActual: null == totalActual ? _self.totalActual : totalActual // ignore: cast_nullable_to_non_nullable
as double,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as double,actualPercentage: null == actualPercentage ? _self.actualPercentage : actualPercentage // ignore: cast_nullable_to_non_nullable
as double,expenseActualPercentage: null == expenseActualPercentage ? _self.expenseActualPercentage : expenseActualPercentage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$CategoryAllocationProgressModel {

 double get currentTotal; double get currentActual; double get idealValue; double get currentPercentage; double get actualPercentage; bool get isWithinRange; bool get isOver;
/// Create a copy of CategoryAllocationProgressModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryAllocationProgressModelCopyWith<CategoryAllocationProgressModel> get copyWith => _$CategoryAllocationProgressModelCopyWithImpl<CategoryAllocationProgressModel>(this as CategoryAllocationProgressModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryAllocationProgressModel&&(identical(other.currentTotal, currentTotal) || other.currentTotal == currentTotal)&&(identical(other.currentActual, currentActual) || other.currentActual == currentActual)&&(identical(other.idealValue, idealValue) || other.idealValue == idealValue)&&(identical(other.currentPercentage, currentPercentage) || other.currentPercentage == currentPercentage)&&(identical(other.actualPercentage, actualPercentage) || other.actualPercentage == actualPercentage)&&(identical(other.isWithinRange, isWithinRange) || other.isWithinRange == isWithinRange)&&(identical(other.isOver, isOver) || other.isOver == isOver));
}


@override
int get hashCode => Object.hash(runtimeType,currentTotal,currentActual,idealValue,currentPercentage,actualPercentage,isWithinRange,isOver);

@override
String toString() {
  return 'CategoryAllocationProgressModel(currentTotal: $currentTotal, currentActual: $currentActual, idealValue: $idealValue, currentPercentage: $currentPercentage, actualPercentage: $actualPercentage, isWithinRange: $isWithinRange, isOver: $isOver)';
}


}

/// @nodoc
abstract mixin class $CategoryAllocationProgressModelCopyWith<$Res>  {
  factory $CategoryAllocationProgressModelCopyWith(CategoryAllocationProgressModel value, $Res Function(CategoryAllocationProgressModel) _then) = _$CategoryAllocationProgressModelCopyWithImpl;
@useResult
$Res call({
 double currentTotal, double currentActual, double idealValue, double currentPercentage, double actualPercentage, bool isWithinRange, bool isOver
});




}
/// @nodoc
class _$CategoryAllocationProgressModelCopyWithImpl<$Res>
    implements $CategoryAllocationProgressModelCopyWith<$Res> {
  _$CategoryAllocationProgressModelCopyWithImpl(this._self, this._then);

  final CategoryAllocationProgressModel _self;
  final $Res Function(CategoryAllocationProgressModel) _then;

/// Create a copy of CategoryAllocationProgressModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentTotal = null,Object? currentActual = null,Object? idealValue = null,Object? currentPercentage = null,Object? actualPercentage = null,Object? isWithinRange = null,Object? isOver = null,}) {
  return _then(_self.copyWith(
currentTotal: null == currentTotal ? _self.currentTotal : currentTotal // ignore: cast_nullable_to_non_nullable
as double,currentActual: null == currentActual ? _self.currentActual : currentActual // ignore: cast_nullable_to_non_nullable
as double,idealValue: null == idealValue ? _self.idealValue : idealValue // ignore: cast_nullable_to_non_nullable
as double,currentPercentage: null == currentPercentage ? _self.currentPercentage : currentPercentage // ignore: cast_nullable_to_non_nullable
as double,actualPercentage: null == actualPercentage ? _self.actualPercentage : actualPercentage // ignore: cast_nullable_to_non_nullable
as double,isWithinRange: null == isWithinRange ? _self.isWithinRange : isWithinRange // ignore: cast_nullable_to_non_nullable
as bool,isOver: null == isOver ? _self.isOver : isOver // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryAllocationProgressModel].
extension CategoryAllocationProgressModelPatterns on CategoryAllocationProgressModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryAllocationProgressModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryAllocationProgressModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryAllocationProgressModel value)  $default,){
final _that = this;
switch (_that) {
case _CategoryAllocationProgressModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryAllocationProgressModel value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryAllocationProgressModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double currentTotal,  double currentActual,  double idealValue,  double currentPercentage,  double actualPercentage,  bool isWithinRange,  bool isOver)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryAllocationProgressModel() when $default != null:
return $default(_that.currentTotal,_that.currentActual,_that.idealValue,_that.currentPercentage,_that.actualPercentage,_that.isWithinRange,_that.isOver);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double currentTotal,  double currentActual,  double idealValue,  double currentPercentage,  double actualPercentage,  bool isWithinRange,  bool isOver)  $default,) {final _that = this;
switch (_that) {
case _CategoryAllocationProgressModel():
return $default(_that.currentTotal,_that.currentActual,_that.idealValue,_that.currentPercentage,_that.actualPercentage,_that.isWithinRange,_that.isOver);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double currentTotal,  double currentActual,  double idealValue,  double currentPercentage,  double actualPercentage,  bool isWithinRange,  bool isOver)?  $default,) {final _that = this;
switch (_that) {
case _CategoryAllocationProgressModel() when $default != null:
return $default(_that.currentTotal,_that.currentActual,_that.idealValue,_that.currentPercentage,_that.actualPercentage,_that.isWithinRange,_that.isOver);case _:
  return null;

}
}

}

/// @nodoc


class _CategoryAllocationProgressModel implements CategoryAllocationProgressModel {
  const _CategoryAllocationProgressModel({required this.currentTotal, required this.currentActual, required this.idealValue, required this.currentPercentage, required this.actualPercentage, required this.isWithinRange, required this.isOver});
  

@override final  double currentTotal;
@override final  double currentActual;
@override final  double idealValue;
@override final  double currentPercentage;
@override final  double actualPercentage;
@override final  bool isWithinRange;
@override final  bool isOver;

/// Create a copy of CategoryAllocationProgressModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryAllocationProgressModelCopyWith<_CategoryAllocationProgressModel> get copyWith => __$CategoryAllocationProgressModelCopyWithImpl<_CategoryAllocationProgressModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryAllocationProgressModel&&(identical(other.currentTotal, currentTotal) || other.currentTotal == currentTotal)&&(identical(other.currentActual, currentActual) || other.currentActual == currentActual)&&(identical(other.idealValue, idealValue) || other.idealValue == idealValue)&&(identical(other.currentPercentage, currentPercentage) || other.currentPercentage == currentPercentage)&&(identical(other.actualPercentage, actualPercentage) || other.actualPercentage == actualPercentage)&&(identical(other.isWithinRange, isWithinRange) || other.isWithinRange == isWithinRange)&&(identical(other.isOver, isOver) || other.isOver == isOver));
}


@override
int get hashCode => Object.hash(runtimeType,currentTotal,currentActual,idealValue,currentPercentage,actualPercentage,isWithinRange,isOver);

@override
String toString() {
  return 'CategoryAllocationProgressModel(currentTotal: $currentTotal, currentActual: $currentActual, idealValue: $idealValue, currentPercentage: $currentPercentage, actualPercentage: $actualPercentage, isWithinRange: $isWithinRange, isOver: $isOver)';
}


}

/// @nodoc
abstract mixin class _$CategoryAllocationProgressModelCopyWith<$Res> implements $CategoryAllocationProgressModelCopyWith<$Res> {
  factory _$CategoryAllocationProgressModelCopyWith(_CategoryAllocationProgressModel value, $Res Function(_CategoryAllocationProgressModel) _then) = __$CategoryAllocationProgressModelCopyWithImpl;
@override @useResult
$Res call({
 double currentTotal, double currentActual, double idealValue, double currentPercentage, double actualPercentage, bool isWithinRange, bool isOver
});




}
/// @nodoc
class __$CategoryAllocationProgressModelCopyWithImpl<$Res>
    implements _$CategoryAllocationProgressModelCopyWith<$Res> {
  __$CategoryAllocationProgressModelCopyWithImpl(this._self, this._then);

  final _CategoryAllocationProgressModel _self;
  final $Res Function(_CategoryAllocationProgressModel) _then;

/// Create a copy of CategoryAllocationProgressModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentTotal = null,Object? currentActual = null,Object? idealValue = null,Object? currentPercentage = null,Object? actualPercentage = null,Object? isWithinRange = null,Object? isOver = null,}) {
  return _then(_CategoryAllocationProgressModel(
currentTotal: null == currentTotal ? _self.currentTotal : currentTotal // ignore: cast_nullable_to_non_nullable
as double,currentActual: null == currentActual ? _self.currentActual : currentActual // ignore: cast_nullable_to_non_nullable
as double,idealValue: null == idealValue ? _self.idealValue : idealValue // ignore: cast_nullable_to_non_nullable
as double,currentPercentage: null == currentPercentage ? _self.currentPercentage : currentPercentage // ignore: cast_nullable_to_non_nullable
as double,actualPercentage: null == actualPercentage ? _self.actualPercentage : actualPercentage // ignore: cast_nullable_to_non_nullable
as double,isWithinRange: null == isWithinRange ? _self.isWithinRange : isWithinRange // ignore: cast_nullable_to_non_nullable
as bool,isOver: null == isOver ? _self.isOver : isOver // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
