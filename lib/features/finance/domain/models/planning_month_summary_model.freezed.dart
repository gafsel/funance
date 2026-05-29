// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'planning_month_summary_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlanningMonthSummaryModel {

 String get id; int get year; int get month; double get plannedAmount; double get actualAmount; DateTime get lastUpdate;
/// Create a copy of PlanningMonthSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanningMonthSummaryModelCopyWith<PlanningMonthSummaryModel> get copyWith => _$PlanningMonthSummaryModelCopyWithImpl<PlanningMonthSummaryModel>(this as PlanningMonthSummaryModel, _$identity);

  /// Serializes this PlanningMonthSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanningMonthSummaryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&(identical(other.plannedAmount, plannedAmount) || other.plannedAmount == plannedAmount)&&(identical(other.actualAmount, actualAmount) || other.actualAmount == actualAmount)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,year,month,plannedAmount,actualAmount,lastUpdate);

@override
String toString() {
  return 'PlanningMonthSummaryModel(id: $id, year: $year, month: $month, plannedAmount: $plannedAmount, actualAmount: $actualAmount, lastUpdate: $lastUpdate)';
}


}

/// @nodoc
abstract mixin class $PlanningMonthSummaryModelCopyWith<$Res>  {
  factory $PlanningMonthSummaryModelCopyWith(PlanningMonthSummaryModel value, $Res Function(PlanningMonthSummaryModel) _then) = _$PlanningMonthSummaryModelCopyWithImpl;
@useResult
$Res call({
 String id, int year, int month, double plannedAmount, double actualAmount, DateTime lastUpdate
});




}
/// @nodoc
class _$PlanningMonthSummaryModelCopyWithImpl<$Res>
    implements $PlanningMonthSummaryModelCopyWith<$Res> {
  _$PlanningMonthSummaryModelCopyWithImpl(this._self, this._then);

  final PlanningMonthSummaryModel _self;
  final $Res Function(PlanningMonthSummaryModel) _then;

/// Create a copy of PlanningMonthSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? year = null,Object? month = null,Object? plannedAmount = null,Object? actualAmount = null,Object? lastUpdate = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,plannedAmount: null == plannedAmount ? _self.plannedAmount : plannedAmount // ignore: cast_nullable_to_non_nullable
as double,actualAmount: null == actualAmount ? _self.actualAmount : actualAmount // ignore: cast_nullable_to_non_nullable
as double,lastUpdate: null == lastUpdate ? _self.lastUpdate : lastUpdate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanningMonthSummaryModel].
extension PlanningMonthSummaryModelPatterns on PlanningMonthSummaryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanningMonthSummaryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanningMonthSummaryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanningMonthSummaryModel value)  $default,){
final _that = this;
switch (_that) {
case _PlanningMonthSummaryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanningMonthSummaryModel value)?  $default,){
final _that = this;
switch (_that) {
case _PlanningMonthSummaryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int year,  int month,  double plannedAmount,  double actualAmount,  DateTime lastUpdate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanningMonthSummaryModel() when $default != null:
return $default(_that.id,_that.year,_that.month,_that.plannedAmount,_that.actualAmount,_that.lastUpdate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int year,  int month,  double plannedAmount,  double actualAmount,  DateTime lastUpdate)  $default,) {final _that = this;
switch (_that) {
case _PlanningMonthSummaryModel():
return $default(_that.id,_that.year,_that.month,_that.plannedAmount,_that.actualAmount,_that.lastUpdate);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int year,  int month,  double plannedAmount,  double actualAmount,  DateTime lastUpdate)?  $default,) {final _that = this;
switch (_that) {
case _PlanningMonthSummaryModel() when $default != null:
return $default(_that.id,_that.year,_that.month,_that.plannedAmount,_that.actualAmount,_that.lastUpdate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanningMonthSummaryModel extends PlanningMonthSummaryModel {
  const _PlanningMonthSummaryModel({required this.id, required this.year, required this.month, required this.plannedAmount, required this.actualAmount, required this.lastUpdate}): super._();
  factory _PlanningMonthSummaryModel.fromJson(Map<String, dynamic> json) => _$PlanningMonthSummaryModelFromJson(json);

@override final  String id;
@override final  int year;
@override final  int month;
@override final  double plannedAmount;
@override final  double actualAmount;
@override final  DateTime lastUpdate;

/// Create a copy of PlanningMonthSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanningMonthSummaryModelCopyWith<_PlanningMonthSummaryModel> get copyWith => __$PlanningMonthSummaryModelCopyWithImpl<_PlanningMonthSummaryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanningMonthSummaryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanningMonthSummaryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.year, year) || other.year == year)&&(identical(other.month, month) || other.month == month)&&(identical(other.plannedAmount, plannedAmount) || other.plannedAmount == plannedAmount)&&(identical(other.actualAmount, actualAmount) || other.actualAmount == actualAmount)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,year,month,plannedAmount,actualAmount,lastUpdate);

@override
String toString() {
  return 'PlanningMonthSummaryModel(id: $id, year: $year, month: $month, plannedAmount: $plannedAmount, actualAmount: $actualAmount, lastUpdate: $lastUpdate)';
}


}

/// @nodoc
abstract mixin class _$PlanningMonthSummaryModelCopyWith<$Res> implements $PlanningMonthSummaryModelCopyWith<$Res> {
  factory _$PlanningMonthSummaryModelCopyWith(_PlanningMonthSummaryModel value, $Res Function(_PlanningMonthSummaryModel) _then) = __$PlanningMonthSummaryModelCopyWithImpl;
@override @useResult
$Res call({
 String id, int year, int month, double plannedAmount, double actualAmount, DateTime lastUpdate
});




}
/// @nodoc
class __$PlanningMonthSummaryModelCopyWithImpl<$Res>
    implements _$PlanningMonthSummaryModelCopyWith<$Res> {
  __$PlanningMonthSummaryModelCopyWithImpl(this._self, this._then);

  final _PlanningMonthSummaryModel _self;
  final $Res Function(_PlanningMonthSummaryModel) _then;

/// Create a copy of PlanningMonthSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? year = null,Object? month = null,Object? plannedAmount = null,Object? actualAmount = null,Object? lastUpdate = null,}) {
  return _then(_PlanningMonthSummaryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,plannedAmount: null == plannedAmount ? _self.plannedAmount : plannedAmount // ignore: cast_nullable_to_non_nullable
as double,actualAmount: null == actualAmount ? _self.actualAmount : actualAmount // ignore: cast_nullable_to_non_nullable
as double,lastUpdate: null == lastUpdate ? _self.lastUpdate : lastUpdate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
