// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_month_summary_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CategoryMonthSummaryModel {

 String get id; int get year; int get month; CategoryModel get category; double get totalDebit; double get totalCredit; double get plannedAmount; double get actualAmount; int get count; DateTime get lastUpdate;
/// Create a copy of CategoryMonthSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryMonthSummaryModelCopyWith<CategoryMonthSummaryModel> get copyWith => _$CategoryMonthSummaryModelCopyWithImpl<CategoryMonthSummaryModel>(this as CategoryMonthSummaryModel, _$identity);

  /// Serializes this CategoryMonthSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryMonthSummaryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&(identical(other.category, category) || other.category == category)&&(identical(other.totalDebit, totalDebit) || other.totalDebit == totalDebit)&&(identical(other.totalCredit, totalCredit) || other.totalCredit == totalCredit)&&(identical(other.plannedAmount, plannedAmount) || other.plannedAmount == plannedAmount)&&(identical(other.actualAmount, actualAmount) || other.actualAmount == actualAmount)&&(identical(other.count, count) || other.count == count)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,year,month,category,totalDebit,totalCredit,plannedAmount,actualAmount,count,lastUpdate);

@override
String toString() {
  return 'CategoryMonthSummaryModel(id: $id, year: $year, month: $month, category: $category, totalDebit: $totalDebit, totalCredit: $totalCredit, plannedAmount: $plannedAmount, actualAmount: $actualAmount, count: $count, lastUpdate: $lastUpdate)';
}


}

/// @nodoc
abstract mixin class $CategoryMonthSummaryModelCopyWith<$Res>  {
  factory $CategoryMonthSummaryModelCopyWith(CategoryMonthSummaryModel value, $Res Function(CategoryMonthSummaryModel) _then) = _$CategoryMonthSummaryModelCopyWithImpl;
@useResult
$Res call({
 String id, int year, int month, CategoryModel category, double totalDebit, double totalCredit, double plannedAmount, double actualAmount, int count, DateTime lastUpdate
});


$CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class _$CategoryMonthSummaryModelCopyWithImpl<$Res>
    implements $CategoryMonthSummaryModelCopyWith<$Res> {
  _$CategoryMonthSummaryModelCopyWithImpl(this._self, this._then);

  final CategoryMonthSummaryModel _self;
  final $Res Function(CategoryMonthSummaryModel) _then;

/// Create a copy of CategoryMonthSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? year = null,Object? month = null,Object? category = null,Object? totalDebit = null,Object? totalCredit = null,Object? plannedAmount = null,Object? actualAmount = null,Object? count = null,Object? lastUpdate = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,totalDebit: null == totalDebit ? _self.totalDebit : totalDebit // ignore: cast_nullable_to_non_nullable
as double,totalCredit: null == totalCredit ? _self.totalCredit : totalCredit // ignore: cast_nullable_to_non_nullable
as double,plannedAmount: null == plannedAmount ? _self.plannedAmount : plannedAmount // ignore: cast_nullable_to_non_nullable
as double,actualAmount: null == actualAmount ? _self.actualAmount : actualAmount // ignore: cast_nullable_to_non_nullable
as double,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,lastUpdate: null == lastUpdate ? _self.lastUpdate : lastUpdate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of CategoryMonthSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [CategoryMonthSummaryModel].
extension CategoryMonthSummaryModelPatterns on CategoryMonthSummaryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryMonthSummaryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryMonthSummaryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryMonthSummaryModel value)  $default,){
final _that = this;
switch (_that) {
case _CategoryMonthSummaryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryMonthSummaryModel value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryMonthSummaryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int year,  int month,  CategoryModel category,  double totalDebit,  double totalCredit,  double plannedAmount,  double actualAmount,  int count,  DateTime lastUpdate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryMonthSummaryModel() when $default != null:
return $default(_that.id,_that.year,_that.month,_that.category,_that.totalDebit,_that.totalCredit,_that.plannedAmount,_that.actualAmount,_that.count,_that.lastUpdate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int year,  int month,  CategoryModel category,  double totalDebit,  double totalCredit,  double plannedAmount,  double actualAmount,  int count,  DateTime lastUpdate)  $default,) {final _that = this;
switch (_that) {
case _CategoryMonthSummaryModel():
return $default(_that.id,_that.year,_that.month,_that.category,_that.totalDebit,_that.totalCredit,_that.plannedAmount,_that.actualAmount,_that.count,_that.lastUpdate);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int year,  int month,  CategoryModel category,  double totalDebit,  double totalCredit,  double plannedAmount,  double actualAmount,  int count,  DateTime lastUpdate)?  $default,) {final _that = this;
switch (_that) {
case _CategoryMonthSummaryModel() when $default != null:
return $default(_that.id,_that.year,_that.month,_that.category,_that.totalDebit,_that.totalCredit,_that.plannedAmount,_that.actualAmount,_that.count,_that.lastUpdate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryMonthSummaryModel implements CategoryMonthSummaryModel {
  const _CategoryMonthSummaryModel({required this.id, required this.year, required this.month, required this.category, required this.totalDebit, required this.totalCredit, required this.plannedAmount, required this.actualAmount, required this.count, required this.lastUpdate});
  factory _CategoryMonthSummaryModel.fromJson(Map<String, dynamic> json) => _$CategoryMonthSummaryModelFromJson(json);

@override final  String id;
@override final  int year;
@override final  int month;
@override final  CategoryModel category;
@override final  double totalDebit;
@override final  double totalCredit;
@override final  double plannedAmount;
@override final  double actualAmount;
@override final  int count;
@override final  DateTime lastUpdate;

/// Create a copy of CategoryMonthSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryMonthSummaryModelCopyWith<_CategoryMonthSummaryModel> get copyWith => __$CategoryMonthSummaryModelCopyWithImpl<_CategoryMonthSummaryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryMonthSummaryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryMonthSummaryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&(identical(other.category, category) || other.category == category)&&(identical(other.totalDebit, totalDebit) || other.totalDebit == totalDebit)&&(identical(other.totalCredit, totalCredit) || other.totalCredit == totalCredit)&&(identical(other.plannedAmount, plannedAmount) || other.plannedAmount == plannedAmount)&&(identical(other.actualAmount, actualAmount) || other.actualAmount == actualAmount)&&(identical(other.count, count) || other.count == count)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,year,month,category,totalDebit,totalCredit,plannedAmount,actualAmount,count,lastUpdate);

@override
String toString() {
  return 'CategoryMonthSummaryModel(id: $id, year: $year, month: $month, category: $category, totalDebit: $totalDebit, totalCredit: $totalCredit, plannedAmount: $plannedAmount, actualAmount: $actualAmount, count: $count, lastUpdate: $lastUpdate)';
}


}

/// @nodoc
abstract mixin class _$CategoryMonthSummaryModelCopyWith<$Res> implements $CategoryMonthSummaryModelCopyWith<$Res> {
  factory _$CategoryMonthSummaryModelCopyWith(_CategoryMonthSummaryModel value, $Res Function(_CategoryMonthSummaryModel) _then) = __$CategoryMonthSummaryModelCopyWithImpl;
@override @useResult
$Res call({
 String id, int year, int month, CategoryModel category, double totalDebit, double totalCredit, double plannedAmount, double actualAmount, int count, DateTime lastUpdate
});


@override $CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class __$CategoryMonthSummaryModelCopyWithImpl<$Res>
    implements _$CategoryMonthSummaryModelCopyWith<$Res> {
  __$CategoryMonthSummaryModelCopyWithImpl(this._self, this._then);

  final _CategoryMonthSummaryModel _self;
  final $Res Function(_CategoryMonthSummaryModel) _then;

/// Create a copy of CategoryMonthSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? year = null,Object? month = null,Object? category = null,Object? totalDebit = null,Object? totalCredit = null,Object? plannedAmount = null,Object? actualAmount = null,Object? count = null,Object? lastUpdate = null,}) {
  return _then(_CategoryMonthSummaryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,totalDebit: null == totalDebit ? _self.totalDebit : totalDebit // ignore: cast_nullable_to_non_nullable
as double,totalCredit: null == totalCredit ? _self.totalCredit : totalCredit // ignore: cast_nullable_to_non_nullable
as double,plannedAmount: null == plannedAmount ? _self.plannedAmount : plannedAmount // ignore: cast_nullable_to_non_nullable
as double,actualAmount: null == actualAmount ? _self.actualAmount : actualAmount // ignore: cast_nullable_to_non_nullable
as double,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,lastUpdate: null == lastUpdate ? _self.lastUpdate : lastUpdate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of CategoryMonthSummaryModel
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
