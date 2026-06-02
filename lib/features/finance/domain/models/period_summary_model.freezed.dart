// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'period_summary_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
PeriodSummaryModel _$PeriodSummaryModelFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'year':
          return _PeriodSummaryModelYear.fromJson(
            json
          );
                case 'month':
          return _PeriodSummaryModelMonth.fromJson(
            json
          );
                case 'week':
          return _PeriodSummaryModelWeek.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'PeriodSummaryModel',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$PeriodSummaryModel {

 int get year; CategoryModel get category; double get generalPlannedAmount;// Valores vindos da category planning
 double get specificPlannedAmount;// Valores vindos de installments
 double get actualAmount; DateTime get lastUpdate;
/// Create a copy of PeriodSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodSummaryModelCopyWith<PeriodSummaryModel> get copyWith => _$PeriodSummaryModelCopyWithImpl<PeriodSummaryModel>(this as PeriodSummaryModel, _$identity);

  /// Serializes this PeriodSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodSummaryModel&&(identical(other.year, year) || other.year == year)&&(identical(other.category, category) || other.category == category)&&(identical(other.generalPlannedAmount, generalPlannedAmount) || other.generalPlannedAmount == generalPlannedAmount)&&(identical(other.specificPlannedAmount, specificPlannedAmount) || other.specificPlannedAmount == specificPlannedAmount)&&(identical(other.actualAmount, actualAmount) || other.actualAmount == actualAmount)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,year,category,generalPlannedAmount,specificPlannedAmount,actualAmount,lastUpdate);

@override
String toString() {
  return 'PeriodSummaryModel(year: $year, category: $category, generalPlannedAmount: $generalPlannedAmount, specificPlannedAmount: $specificPlannedAmount, actualAmount: $actualAmount, lastUpdate: $lastUpdate)';
}


}

/// @nodoc
abstract mixin class $PeriodSummaryModelCopyWith<$Res>  {
  factory $PeriodSummaryModelCopyWith(PeriodSummaryModel value, $Res Function(PeriodSummaryModel) _then) = _$PeriodSummaryModelCopyWithImpl;
@useResult
$Res call({
 int year, CategoryModel category, double generalPlannedAmount, double specificPlannedAmount, double actualAmount, DateTime lastUpdate
});


$CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class _$PeriodSummaryModelCopyWithImpl<$Res>
    implements $PeriodSummaryModelCopyWith<$Res> {
  _$PeriodSummaryModelCopyWithImpl(this._self, this._then);

  final PeriodSummaryModel _self;
  final $Res Function(PeriodSummaryModel) _then;

/// Create a copy of PeriodSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? year = null,Object? category = null,Object? generalPlannedAmount = null,Object? specificPlannedAmount = null,Object? actualAmount = null,Object? lastUpdate = null,}) {
  return _then(_self.copyWith(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,generalPlannedAmount: null == generalPlannedAmount ? _self.generalPlannedAmount : generalPlannedAmount // ignore: cast_nullable_to_non_nullable
as double,specificPlannedAmount: null == specificPlannedAmount ? _self.specificPlannedAmount : specificPlannedAmount // ignore: cast_nullable_to_non_nullable
as double,actualAmount: null == actualAmount ? _self.actualAmount : actualAmount // ignore: cast_nullable_to_non_nullable
as double,lastUpdate: null == lastUpdate ? _self.lastUpdate : lastUpdate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of PeriodSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [PeriodSummaryModel].
extension PeriodSummaryModelPatterns on PeriodSummaryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _PeriodSummaryModelYear value)?  year,TResult Function( _PeriodSummaryModelMonth value)?  month,TResult Function( _PeriodSummaryModelWeek value)?  week,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodSummaryModelYear() when year != null:
return year(_that);case _PeriodSummaryModelMonth() when month != null:
return month(_that);case _PeriodSummaryModelWeek() when week != null:
return week(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _PeriodSummaryModelYear value)  year,required TResult Function( _PeriodSummaryModelMonth value)  month,required TResult Function( _PeriodSummaryModelWeek value)  week,}){
final _that = this;
switch (_that) {
case _PeriodSummaryModelYear():
return year(_that);case _PeriodSummaryModelMonth():
return month(_that);case _PeriodSummaryModelWeek():
return week(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _PeriodSummaryModelYear value)?  year,TResult? Function( _PeriodSummaryModelMonth value)?  month,TResult? Function( _PeriodSummaryModelWeek value)?  week,}){
final _that = this;
switch (_that) {
case _PeriodSummaryModelYear() when year != null:
return year(_that);case _PeriodSummaryModelMonth() when month != null:
return month(_that);case _PeriodSummaryModelWeek() when week != null:
return week(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int year,  CategoryModel category,  double generalPlannedAmount,  double specificPlannedAmount,  double actualAmount,  DateTime lastUpdate)?  year,TResult Function( int year,  int month,  CategoryModel category,  double generalPlannedAmount,  double specificPlannedAmount,  double actualAmount,  DateTime lastUpdate)?  month,TResult Function( int year,  int week,  CategoryModel category,  double generalPlannedAmount,  double specificPlannedAmount,  double actualAmount,  DateTime lastUpdate)?  week,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodSummaryModelYear() when year != null:
return year(_that.year,_that.category,_that.generalPlannedAmount,_that.specificPlannedAmount,_that.actualAmount,_that.lastUpdate);case _PeriodSummaryModelMonth() when month != null:
return month(_that.year,_that.month,_that.category,_that.generalPlannedAmount,_that.specificPlannedAmount,_that.actualAmount,_that.lastUpdate);case _PeriodSummaryModelWeek() when week != null:
return week(_that.year,_that.week,_that.category,_that.generalPlannedAmount,_that.specificPlannedAmount,_that.actualAmount,_that.lastUpdate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int year,  CategoryModel category,  double generalPlannedAmount,  double specificPlannedAmount,  double actualAmount,  DateTime lastUpdate)  year,required TResult Function( int year,  int month,  CategoryModel category,  double generalPlannedAmount,  double specificPlannedAmount,  double actualAmount,  DateTime lastUpdate)  month,required TResult Function( int year,  int week,  CategoryModel category,  double generalPlannedAmount,  double specificPlannedAmount,  double actualAmount,  DateTime lastUpdate)  week,}) {final _that = this;
switch (_that) {
case _PeriodSummaryModelYear():
return year(_that.year,_that.category,_that.generalPlannedAmount,_that.specificPlannedAmount,_that.actualAmount,_that.lastUpdate);case _PeriodSummaryModelMonth():
return month(_that.year,_that.month,_that.category,_that.generalPlannedAmount,_that.specificPlannedAmount,_that.actualAmount,_that.lastUpdate);case _PeriodSummaryModelWeek():
return week(_that.year,_that.week,_that.category,_that.generalPlannedAmount,_that.specificPlannedAmount,_that.actualAmount,_that.lastUpdate);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int year,  CategoryModel category,  double generalPlannedAmount,  double specificPlannedAmount,  double actualAmount,  DateTime lastUpdate)?  year,TResult? Function( int year,  int month,  CategoryModel category,  double generalPlannedAmount,  double specificPlannedAmount,  double actualAmount,  DateTime lastUpdate)?  month,TResult? Function( int year,  int week,  CategoryModel category,  double generalPlannedAmount,  double specificPlannedAmount,  double actualAmount,  DateTime lastUpdate)?  week,}) {final _that = this;
switch (_that) {
case _PeriodSummaryModelYear() when year != null:
return year(_that.year,_that.category,_that.generalPlannedAmount,_that.specificPlannedAmount,_that.actualAmount,_that.lastUpdate);case _PeriodSummaryModelMonth() when month != null:
return month(_that.year,_that.month,_that.category,_that.generalPlannedAmount,_that.specificPlannedAmount,_that.actualAmount,_that.lastUpdate);case _PeriodSummaryModelWeek() when week != null:
return week(_that.year,_that.week,_that.category,_that.generalPlannedAmount,_that.specificPlannedAmount,_that.actualAmount,_that.lastUpdate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodSummaryModelYear extends PeriodSummaryModel {
  const _PeriodSummaryModelYear({required this.year, required this.category, this.generalPlannedAmount = 0, required this.specificPlannedAmount, this.actualAmount = 0, required this.lastUpdate, final  String? $type}): $type = $type ?? 'year',super._();
  factory _PeriodSummaryModelYear.fromJson(Map<String, dynamic> json) => _$PeriodSummaryModelYearFromJson(json);

@override final  int year;
@override final  CategoryModel category;
@override@JsonKey() final  double generalPlannedAmount;
// Valores vindos da category planning
@override final  double specificPlannedAmount;
// Valores vindos de installments
@override@JsonKey() final  double actualAmount;
@override final  DateTime lastUpdate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of PeriodSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodSummaryModelYearCopyWith<_PeriodSummaryModelYear> get copyWith => __$PeriodSummaryModelYearCopyWithImpl<_PeriodSummaryModelYear>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodSummaryModelYearToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodSummaryModelYear&&(identical(other.year, year) || other.year == year)&&(identical(other.category, category) || other.category == category)&&(identical(other.generalPlannedAmount, generalPlannedAmount) || other.generalPlannedAmount == generalPlannedAmount)&&(identical(other.specificPlannedAmount, specificPlannedAmount) || other.specificPlannedAmount == specificPlannedAmount)&&(identical(other.actualAmount, actualAmount) || other.actualAmount == actualAmount)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,year,category,generalPlannedAmount,specificPlannedAmount,actualAmount,lastUpdate);

@override
String toString() {
  return 'PeriodSummaryModel.year(year: $year, category: $category, generalPlannedAmount: $generalPlannedAmount, specificPlannedAmount: $specificPlannedAmount, actualAmount: $actualAmount, lastUpdate: $lastUpdate)';
}


}

/// @nodoc
abstract mixin class _$PeriodSummaryModelYearCopyWith<$Res> implements $PeriodSummaryModelCopyWith<$Res> {
  factory _$PeriodSummaryModelYearCopyWith(_PeriodSummaryModelYear value, $Res Function(_PeriodSummaryModelYear) _then) = __$PeriodSummaryModelYearCopyWithImpl;
@override @useResult
$Res call({
 int year, CategoryModel category, double generalPlannedAmount, double specificPlannedAmount, double actualAmount, DateTime lastUpdate
});


@override $CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class __$PeriodSummaryModelYearCopyWithImpl<$Res>
    implements _$PeriodSummaryModelYearCopyWith<$Res> {
  __$PeriodSummaryModelYearCopyWithImpl(this._self, this._then);

  final _PeriodSummaryModelYear _self;
  final $Res Function(_PeriodSummaryModelYear) _then;

/// Create a copy of PeriodSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? year = null,Object? category = null,Object? generalPlannedAmount = null,Object? specificPlannedAmount = null,Object? actualAmount = null,Object? lastUpdate = null,}) {
  return _then(_PeriodSummaryModelYear(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,generalPlannedAmount: null == generalPlannedAmount ? _self.generalPlannedAmount : generalPlannedAmount // ignore: cast_nullable_to_non_nullable
as double,specificPlannedAmount: null == specificPlannedAmount ? _self.specificPlannedAmount : specificPlannedAmount // ignore: cast_nullable_to_non_nullable
as double,actualAmount: null == actualAmount ? _self.actualAmount : actualAmount // ignore: cast_nullable_to_non_nullable
as double,lastUpdate: null == lastUpdate ? _self.lastUpdate : lastUpdate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of PeriodSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class _PeriodSummaryModelMonth extends PeriodSummaryModel {
  const _PeriodSummaryModelMonth({required this.year, required this.month, required this.category, this.generalPlannedAmount = 0, required this.specificPlannedAmount, this.actualAmount = 0, required this.lastUpdate, final  String? $type}): $type = $type ?? 'month',super._();
  factory _PeriodSummaryModelMonth.fromJson(Map<String, dynamic> json) => _$PeriodSummaryModelMonthFromJson(json);

@override final  int year;
 final  int month;
@override final  CategoryModel category;
@override@JsonKey() final  double generalPlannedAmount;
// Valores vindos da category planning
@override final  double specificPlannedAmount;
// Valores vindos de installments
@override@JsonKey() final  double actualAmount;
@override final  DateTime lastUpdate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of PeriodSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodSummaryModelMonthCopyWith<_PeriodSummaryModelMonth> get copyWith => __$PeriodSummaryModelMonthCopyWithImpl<_PeriodSummaryModelMonth>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodSummaryModelMonthToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodSummaryModelMonth&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&(identical(other.category, category) || other.category == category)&&(identical(other.generalPlannedAmount, generalPlannedAmount) || other.generalPlannedAmount == generalPlannedAmount)&&(identical(other.specificPlannedAmount, specificPlannedAmount) || other.specificPlannedAmount == specificPlannedAmount)&&(identical(other.actualAmount, actualAmount) || other.actualAmount == actualAmount)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,year,month,category,generalPlannedAmount,specificPlannedAmount,actualAmount,lastUpdate);

@override
String toString() {
  return 'PeriodSummaryModel.month(year: $year, month: $month, category: $category, generalPlannedAmount: $generalPlannedAmount, specificPlannedAmount: $specificPlannedAmount, actualAmount: $actualAmount, lastUpdate: $lastUpdate)';
}


}

/// @nodoc
abstract mixin class _$PeriodSummaryModelMonthCopyWith<$Res> implements $PeriodSummaryModelCopyWith<$Res> {
  factory _$PeriodSummaryModelMonthCopyWith(_PeriodSummaryModelMonth value, $Res Function(_PeriodSummaryModelMonth) _then) = __$PeriodSummaryModelMonthCopyWithImpl;
@override @useResult
$Res call({
 int year, int month, CategoryModel category, double generalPlannedAmount, double specificPlannedAmount, double actualAmount, DateTime lastUpdate
});


@override $CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class __$PeriodSummaryModelMonthCopyWithImpl<$Res>
    implements _$PeriodSummaryModelMonthCopyWith<$Res> {
  __$PeriodSummaryModelMonthCopyWithImpl(this._self, this._then);

  final _PeriodSummaryModelMonth _self;
  final $Res Function(_PeriodSummaryModelMonth) _then;

/// Create a copy of PeriodSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? year = null,Object? month = null,Object? category = null,Object? generalPlannedAmount = null,Object? specificPlannedAmount = null,Object? actualAmount = null,Object? lastUpdate = null,}) {
  return _then(_PeriodSummaryModelMonth(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,generalPlannedAmount: null == generalPlannedAmount ? _self.generalPlannedAmount : generalPlannedAmount // ignore: cast_nullable_to_non_nullable
as double,specificPlannedAmount: null == specificPlannedAmount ? _self.specificPlannedAmount : specificPlannedAmount // ignore: cast_nullable_to_non_nullable
as double,actualAmount: null == actualAmount ? _self.actualAmount : actualAmount // ignore: cast_nullable_to_non_nullable
as double,lastUpdate: null == lastUpdate ? _self.lastUpdate : lastUpdate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of PeriodSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class _PeriodSummaryModelWeek extends PeriodSummaryModel {
  const _PeriodSummaryModelWeek({required this.year, required this.week, required this.category, this.generalPlannedAmount = 0, required this.specificPlannedAmount, this.actualAmount = 0, required this.lastUpdate, final  String? $type}): $type = $type ?? 'week',super._();
  factory _PeriodSummaryModelWeek.fromJson(Map<String, dynamic> json) => _$PeriodSummaryModelWeekFromJson(json);

@override final  int year;
 final  int week;
@override final  CategoryModel category;
@override@JsonKey() final  double generalPlannedAmount;
@override final  double specificPlannedAmount;
@override@JsonKey() final  double actualAmount;
@override final  DateTime lastUpdate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of PeriodSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodSummaryModelWeekCopyWith<_PeriodSummaryModelWeek> get copyWith => __$PeriodSummaryModelWeekCopyWithImpl<_PeriodSummaryModelWeek>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodSummaryModelWeekToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodSummaryModelWeek&&(identical(other.year, year) || other.year == year)&&(identical(other.week, week) || other.week == week)&&(identical(other.category, category) || other.category == category)&&(identical(other.generalPlannedAmount, generalPlannedAmount) || other.generalPlannedAmount == generalPlannedAmount)&&(identical(other.specificPlannedAmount, specificPlannedAmount) || other.specificPlannedAmount == specificPlannedAmount)&&(identical(other.actualAmount, actualAmount) || other.actualAmount == actualAmount)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,year,week,category,generalPlannedAmount,specificPlannedAmount,actualAmount,lastUpdate);

@override
String toString() {
  return 'PeriodSummaryModel.week(year: $year, week: $week, category: $category, generalPlannedAmount: $generalPlannedAmount, specificPlannedAmount: $specificPlannedAmount, actualAmount: $actualAmount, lastUpdate: $lastUpdate)';
}


}

/// @nodoc
abstract mixin class _$PeriodSummaryModelWeekCopyWith<$Res> implements $PeriodSummaryModelCopyWith<$Res> {
  factory _$PeriodSummaryModelWeekCopyWith(_PeriodSummaryModelWeek value, $Res Function(_PeriodSummaryModelWeek) _then) = __$PeriodSummaryModelWeekCopyWithImpl;
@override @useResult
$Res call({
 int year, int week, CategoryModel category, double generalPlannedAmount, double specificPlannedAmount, double actualAmount, DateTime lastUpdate
});


@override $CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class __$PeriodSummaryModelWeekCopyWithImpl<$Res>
    implements _$PeriodSummaryModelWeekCopyWith<$Res> {
  __$PeriodSummaryModelWeekCopyWithImpl(this._self, this._then);

  final _PeriodSummaryModelWeek _self;
  final $Res Function(_PeriodSummaryModelWeek) _then;

/// Create a copy of PeriodSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? year = null,Object? week = null,Object? category = null,Object? generalPlannedAmount = null,Object? specificPlannedAmount = null,Object? actualAmount = null,Object? lastUpdate = null,}) {
  return _then(_PeriodSummaryModelWeek(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,generalPlannedAmount: null == generalPlannedAmount ? _self.generalPlannedAmount : generalPlannedAmount // ignore: cast_nullable_to_non_nullable
as double,specificPlannedAmount: null == specificPlannedAmount ? _self.specificPlannedAmount : specificPlannedAmount // ignore: cast_nullable_to_non_nullable
as double,actualAmount: null == actualAmount ? _self.actualAmount : actualAmount // ignore: cast_nullable_to_non_nullable
as double,lastUpdate: null == lastUpdate ? _self.lastUpdate : lastUpdate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of PeriodSummaryModel
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
