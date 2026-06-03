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

/// @nodoc
mixin _$PeriodSummaryCategoryModel {

 double get generalPlannedAmount; double get specificPlannedAmount; double get actualAmount;
/// Create a copy of PeriodSummaryCategoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodSummaryCategoryModelCopyWith<PeriodSummaryCategoryModel> get copyWith => _$PeriodSummaryCategoryModelCopyWithImpl<PeriodSummaryCategoryModel>(this as PeriodSummaryCategoryModel, _$identity);

  /// Serializes this PeriodSummaryCategoryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodSummaryCategoryModel&&(identical(other.generalPlannedAmount, generalPlannedAmount) || other.generalPlannedAmount == generalPlannedAmount)&&(identical(other.specificPlannedAmount, specificPlannedAmount) || other.specificPlannedAmount == specificPlannedAmount)&&(identical(other.actualAmount, actualAmount) || other.actualAmount == actualAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,generalPlannedAmount,specificPlannedAmount,actualAmount);

@override
String toString() {
  return 'PeriodSummaryCategoryModel(generalPlannedAmount: $generalPlannedAmount, specificPlannedAmount: $specificPlannedAmount, actualAmount: $actualAmount)';
}


}

/// @nodoc
abstract mixin class $PeriodSummaryCategoryModelCopyWith<$Res>  {
  factory $PeriodSummaryCategoryModelCopyWith(PeriodSummaryCategoryModel value, $Res Function(PeriodSummaryCategoryModel) _then) = _$PeriodSummaryCategoryModelCopyWithImpl;
@useResult
$Res call({
 double generalPlannedAmount, double specificPlannedAmount, double actualAmount
});




}
/// @nodoc
class _$PeriodSummaryCategoryModelCopyWithImpl<$Res>
    implements $PeriodSummaryCategoryModelCopyWith<$Res> {
  _$PeriodSummaryCategoryModelCopyWithImpl(this._self, this._then);

  final PeriodSummaryCategoryModel _self;
  final $Res Function(PeriodSummaryCategoryModel) _then;

/// Create a copy of PeriodSummaryCategoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? generalPlannedAmount = null,Object? specificPlannedAmount = null,Object? actualAmount = null,}) {
  return _then(_self.copyWith(
generalPlannedAmount: null == generalPlannedAmount ? _self.generalPlannedAmount : generalPlannedAmount // ignore: cast_nullable_to_non_nullable
as double,specificPlannedAmount: null == specificPlannedAmount ? _self.specificPlannedAmount : specificPlannedAmount // ignore: cast_nullable_to_non_nullable
as double,actualAmount: null == actualAmount ? _self.actualAmount : actualAmount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PeriodSummaryCategoryModel].
extension PeriodSummaryCategoryModelPatterns on PeriodSummaryCategoryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodSummaryCategoryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodSummaryCategoryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodSummaryCategoryModel value)  $default,){
final _that = this;
switch (_that) {
case _PeriodSummaryCategoryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodSummaryCategoryModel value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodSummaryCategoryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double generalPlannedAmount,  double specificPlannedAmount,  double actualAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodSummaryCategoryModel() when $default != null:
return $default(_that.generalPlannedAmount,_that.specificPlannedAmount,_that.actualAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double generalPlannedAmount,  double specificPlannedAmount,  double actualAmount)  $default,) {final _that = this;
switch (_that) {
case _PeriodSummaryCategoryModel():
return $default(_that.generalPlannedAmount,_that.specificPlannedAmount,_that.actualAmount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double generalPlannedAmount,  double specificPlannedAmount,  double actualAmount)?  $default,) {final _that = this;
switch (_that) {
case _PeriodSummaryCategoryModel() when $default != null:
return $default(_that.generalPlannedAmount,_that.specificPlannedAmount,_that.actualAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodSummaryCategoryModel extends PeriodSummaryCategoryModel {
  const _PeriodSummaryCategoryModel({this.generalPlannedAmount = 0, this.specificPlannedAmount = 0, this.actualAmount = 0}): super._();
  factory _PeriodSummaryCategoryModel.fromJson(Map<String, dynamic> json) => _$PeriodSummaryCategoryModelFromJson(json);

@override@JsonKey() final  double generalPlannedAmount;
@override@JsonKey() final  double specificPlannedAmount;
@override@JsonKey() final  double actualAmount;

/// Create a copy of PeriodSummaryCategoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodSummaryCategoryModelCopyWith<_PeriodSummaryCategoryModel> get copyWith => __$PeriodSummaryCategoryModelCopyWithImpl<_PeriodSummaryCategoryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodSummaryCategoryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodSummaryCategoryModel&&(identical(other.generalPlannedAmount, generalPlannedAmount) || other.generalPlannedAmount == generalPlannedAmount)&&(identical(other.specificPlannedAmount, specificPlannedAmount) || other.specificPlannedAmount == specificPlannedAmount)&&(identical(other.actualAmount, actualAmount) || other.actualAmount == actualAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,generalPlannedAmount,specificPlannedAmount,actualAmount);

@override
String toString() {
  return 'PeriodSummaryCategoryModel(generalPlannedAmount: $generalPlannedAmount, specificPlannedAmount: $specificPlannedAmount, actualAmount: $actualAmount)';
}


}

/// @nodoc
abstract mixin class _$PeriodSummaryCategoryModelCopyWith<$Res> implements $PeriodSummaryCategoryModelCopyWith<$Res> {
  factory _$PeriodSummaryCategoryModelCopyWith(_PeriodSummaryCategoryModel value, $Res Function(_PeriodSummaryCategoryModel) _then) = __$PeriodSummaryCategoryModelCopyWithImpl;
@override @useResult
$Res call({
 double generalPlannedAmount, double specificPlannedAmount, double actualAmount
});




}
/// @nodoc
class __$PeriodSummaryCategoryModelCopyWithImpl<$Res>
    implements _$PeriodSummaryCategoryModelCopyWith<$Res> {
  __$PeriodSummaryCategoryModelCopyWithImpl(this._self, this._then);

  final _PeriodSummaryCategoryModel _self;
  final $Res Function(_PeriodSummaryCategoryModel) _then;

/// Create a copy of PeriodSummaryCategoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? generalPlannedAmount = null,Object? specificPlannedAmount = null,Object? actualAmount = null,}) {
  return _then(_PeriodSummaryCategoryModel(
generalPlannedAmount: null == generalPlannedAmount ? _self.generalPlannedAmount : generalPlannedAmount // ignore: cast_nullable_to_non_nullable
as double,specificPlannedAmount: null == specificPlannedAmount ? _self.specificPlannedAmount : specificPlannedAmount // ignore: cast_nullable_to_non_nullable
as double,actualAmount: null == actualAmount ? _self.actualAmount : actualAmount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

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

 int get year; Map<String, PeriodSummaryCategoryModel> get categories; DateTime get lastUpdate;
/// Create a copy of PeriodSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodSummaryModelCopyWith<PeriodSummaryModel> get copyWith => _$PeriodSummaryModelCopyWithImpl<PeriodSummaryModel>(this as PeriodSummaryModel, _$identity);

  /// Serializes this PeriodSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodSummaryModel&&(identical(other.year, year) || other.year == year)&&const DeepCollectionEquality().equals(other.categories, categories)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,year,const DeepCollectionEquality().hash(categories),lastUpdate);

@override
String toString() {
  return 'PeriodSummaryModel(year: $year, categories: $categories, lastUpdate: $lastUpdate)';
}


}

/// @nodoc
abstract mixin class $PeriodSummaryModelCopyWith<$Res>  {
  factory $PeriodSummaryModelCopyWith(PeriodSummaryModel value, $Res Function(PeriodSummaryModel) _then) = _$PeriodSummaryModelCopyWithImpl;
@useResult
$Res call({
 int year, Map<String, PeriodSummaryCategoryModel> categories, DateTime lastUpdate
});




}
/// @nodoc
class _$PeriodSummaryModelCopyWithImpl<$Res>
    implements $PeriodSummaryModelCopyWith<$Res> {
  _$PeriodSummaryModelCopyWithImpl(this._self, this._then);

  final PeriodSummaryModel _self;
  final $Res Function(PeriodSummaryModel) _then;

/// Create a copy of PeriodSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? year = null,Object? categories = null,Object? lastUpdate = null,}) {
  return _then(_self.copyWith(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as Map<String, PeriodSummaryCategoryModel>,lastUpdate: null == lastUpdate ? _self.lastUpdate : lastUpdate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int year,  Map<String, PeriodSummaryCategoryModel> categories,  DateTime lastUpdate)?  year,TResult Function( int year,  int month,  Map<String, PeriodSummaryCategoryModel> categories,  DateTime lastUpdate)?  month,TResult Function( int year,  int week,  Map<String, PeriodSummaryCategoryModel> categories,  DateTime lastUpdate)?  week,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodSummaryModelYear() when year != null:
return year(_that.year,_that.categories,_that.lastUpdate);case _PeriodSummaryModelMonth() when month != null:
return month(_that.year,_that.month,_that.categories,_that.lastUpdate);case _PeriodSummaryModelWeek() when week != null:
return week(_that.year,_that.week,_that.categories,_that.lastUpdate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int year,  Map<String, PeriodSummaryCategoryModel> categories,  DateTime lastUpdate)  year,required TResult Function( int year,  int month,  Map<String, PeriodSummaryCategoryModel> categories,  DateTime lastUpdate)  month,required TResult Function( int year,  int week,  Map<String, PeriodSummaryCategoryModel> categories,  DateTime lastUpdate)  week,}) {final _that = this;
switch (_that) {
case _PeriodSummaryModelYear():
return year(_that.year,_that.categories,_that.lastUpdate);case _PeriodSummaryModelMonth():
return month(_that.year,_that.month,_that.categories,_that.lastUpdate);case _PeriodSummaryModelWeek():
return week(_that.year,_that.week,_that.categories,_that.lastUpdate);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int year,  Map<String, PeriodSummaryCategoryModel> categories,  DateTime lastUpdate)?  year,TResult? Function( int year,  int month,  Map<String, PeriodSummaryCategoryModel> categories,  DateTime lastUpdate)?  month,TResult? Function( int year,  int week,  Map<String, PeriodSummaryCategoryModel> categories,  DateTime lastUpdate)?  week,}) {final _that = this;
switch (_that) {
case _PeriodSummaryModelYear() when year != null:
return year(_that.year,_that.categories,_that.lastUpdate);case _PeriodSummaryModelMonth() when month != null:
return month(_that.year,_that.month,_that.categories,_that.lastUpdate);case _PeriodSummaryModelWeek() when week != null:
return week(_that.year,_that.week,_that.categories,_that.lastUpdate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodSummaryModelYear extends PeriodSummaryModel {
  const _PeriodSummaryModelYear({required this.year, required final  Map<String, PeriodSummaryCategoryModel> categories, required this.lastUpdate, final  String? $type}): _categories = categories,$type = $type ?? 'year',super._();
  factory _PeriodSummaryModelYear.fromJson(Map<String, dynamic> json) => _$PeriodSummaryModelYearFromJson(json);

@override final  int year;
 final  Map<String, PeriodSummaryCategoryModel> _categories;
@override Map<String, PeriodSummaryCategoryModel> get categories {
  if (_categories is EqualUnmodifiableMapView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categories);
}

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodSummaryModelYear&&(identical(other.year, year) || other.year == year)&&const DeepCollectionEquality().equals(other._categories, _categories)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,year,const DeepCollectionEquality().hash(_categories),lastUpdate);

@override
String toString() {
  return 'PeriodSummaryModel.year(year: $year, categories: $categories, lastUpdate: $lastUpdate)';
}


}

/// @nodoc
abstract mixin class _$PeriodSummaryModelYearCopyWith<$Res> implements $PeriodSummaryModelCopyWith<$Res> {
  factory _$PeriodSummaryModelYearCopyWith(_PeriodSummaryModelYear value, $Res Function(_PeriodSummaryModelYear) _then) = __$PeriodSummaryModelYearCopyWithImpl;
@override @useResult
$Res call({
 int year, Map<String, PeriodSummaryCategoryModel> categories, DateTime lastUpdate
});




}
/// @nodoc
class __$PeriodSummaryModelYearCopyWithImpl<$Res>
    implements _$PeriodSummaryModelYearCopyWith<$Res> {
  __$PeriodSummaryModelYearCopyWithImpl(this._self, this._then);

  final _PeriodSummaryModelYear _self;
  final $Res Function(_PeriodSummaryModelYear) _then;

/// Create a copy of PeriodSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? year = null,Object? categories = null,Object? lastUpdate = null,}) {
  return _then(_PeriodSummaryModelYear(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as Map<String, PeriodSummaryCategoryModel>,lastUpdate: null == lastUpdate ? _self.lastUpdate : lastUpdate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
@JsonSerializable()

class _PeriodSummaryModelMonth extends PeriodSummaryModel {
  const _PeriodSummaryModelMonth({required this.year, required this.month, required final  Map<String, PeriodSummaryCategoryModel> categories, required this.lastUpdate, final  String? $type}): _categories = categories,$type = $type ?? 'month',super._();
  factory _PeriodSummaryModelMonth.fromJson(Map<String, dynamic> json) => _$PeriodSummaryModelMonthFromJson(json);

@override final  int year;
 final  int month;
 final  Map<String, PeriodSummaryCategoryModel> _categories;
@override Map<String, PeriodSummaryCategoryModel> get categories {
  if (_categories is EqualUnmodifiableMapView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categories);
}

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodSummaryModelMonth&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&const DeepCollectionEquality().equals(other._categories, _categories)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,year,month,const DeepCollectionEquality().hash(_categories),lastUpdate);

@override
String toString() {
  return 'PeriodSummaryModel.month(year: $year, month: $month, categories: $categories, lastUpdate: $lastUpdate)';
}


}

/// @nodoc
abstract mixin class _$PeriodSummaryModelMonthCopyWith<$Res> implements $PeriodSummaryModelCopyWith<$Res> {
  factory _$PeriodSummaryModelMonthCopyWith(_PeriodSummaryModelMonth value, $Res Function(_PeriodSummaryModelMonth) _then) = __$PeriodSummaryModelMonthCopyWithImpl;
@override @useResult
$Res call({
 int year, int month, Map<String, PeriodSummaryCategoryModel> categories, DateTime lastUpdate
});




}
/// @nodoc
class __$PeriodSummaryModelMonthCopyWithImpl<$Res>
    implements _$PeriodSummaryModelMonthCopyWith<$Res> {
  __$PeriodSummaryModelMonthCopyWithImpl(this._self, this._then);

  final _PeriodSummaryModelMonth _self;
  final $Res Function(_PeriodSummaryModelMonth) _then;

/// Create a copy of PeriodSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? year = null,Object? month = null,Object? categories = null,Object? lastUpdate = null,}) {
  return _then(_PeriodSummaryModelMonth(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as Map<String, PeriodSummaryCategoryModel>,lastUpdate: null == lastUpdate ? _self.lastUpdate : lastUpdate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
@JsonSerializable()

class _PeriodSummaryModelWeek extends PeriodSummaryModel {
  const _PeriodSummaryModelWeek({required this.year, required this.week, required final  Map<String, PeriodSummaryCategoryModel> categories, required this.lastUpdate, final  String? $type}): _categories = categories,$type = $type ?? 'week',super._();
  factory _PeriodSummaryModelWeek.fromJson(Map<String, dynamic> json) => _$PeriodSummaryModelWeekFromJson(json);

@override final  int year;
 final  int week;
 final  Map<String, PeriodSummaryCategoryModel> _categories;
@override Map<String, PeriodSummaryCategoryModel> get categories {
  if (_categories is EqualUnmodifiableMapView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categories);
}

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodSummaryModelWeek&&(identical(other.year, year) || other.year == year)&&(identical(other.week, week) || other.week == week)&&const DeepCollectionEquality().equals(other._categories, _categories)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,year,week,const DeepCollectionEquality().hash(_categories),lastUpdate);

@override
String toString() {
  return 'PeriodSummaryModel.week(year: $year, week: $week, categories: $categories, lastUpdate: $lastUpdate)';
}


}

/// @nodoc
abstract mixin class _$PeriodSummaryModelWeekCopyWith<$Res> implements $PeriodSummaryModelCopyWith<$Res> {
  factory _$PeriodSummaryModelWeekCopyWith(_PeriodSummaryModelWeek value, $Res Function(_PeriodSummaryModelWeek) _then) = __$PeriodSummaryModelWeekCopyWithImpl;
@override @useResult
$Res call({
 int year, int week, Map<String, PeriodSummaryCategoryModel> categories, DateTime lastUpdate
});




}
/// @nodoc
class __$PeriodSummaryModelWeekCopyWithImpl<$Res>
    implements _$PeriodSummaryModelWeekCopyWith<$Res> {
  __$PeriodSummaryModelWeekCopyWithImpl(this._self, this._then);

  final _PeriodSummaryModelWeek _self;
  final $Res Function(_PeriodSummaryModelWeek) _then;

/// Create a copy of PeriodSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? year = null,Object? week = null,Object? categories = null,Object? lastUpdate = null,}) {
  return _then(_PeriodSummaryModelWeek(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as int,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as Map<String, PeriodSummaryCategoryModel>,lastUpdate: null == lastUpdate ? _self.lastUpdate : lastUpdate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
