// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'monthly_available_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MonthlyAvailable {

/// Soma de `max(generalPlannedAmount, specificPlannedAmount)` das
/// categorias de receita no `period_summaries` do mês.
 double get expectedIncome;/// Soma de `actualAmount` das categorias de despesa (sem as de sistema).
 double get realizedExpenses;/// Parcelas de despesa ainda `pending` com vencimento até o fim do mês.
 double get pendingExpenses;/// Soma dos limites de despesa do mês, para a linha "realizado/previsto".
 double get plannedExpenses;
/// Create a copy of MonthlyAvailable
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthlyAvailableCopyWith<MonthlyAvailable> get copyWith => _$MonthlyAvailableCopyWithImpl<MonthlyAvailable>(this as MonthlyAvailable, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthlyAvailable&&(identical(other.expectedIncome, expectedIncome) || other.expectedIncome == expectedIncome)&&(identical(other.realizedExpenses, realizedExpenses) || other.realizedExpenses == realizedExpenses)&&(identical(other.pendingExpenses, pendingExpenses) || other.pendingExpenses == pendingExpenses)&&(identical(other.plannedExpenses, plannedExpenses) || other.plannedExpenses == plannedExpenses));
}


@override
int get hashCode => Object.hash(runtimeType,expectedIncome,realizedExpenses,pendingExpenses,plannedExpenses);

@override
String toString() {
  return 'MonthlyAvailable(expectedIncome: $expectedIncome, realizedExpenses: $realizedExpenses, pendingExpenses: $pendingExpenses, plannedExpenses: $plannedExpenses)';
}


}

/// @nodoc
abstract mixin class $MonthlyAvailableCopyWith<$Res>  {
  factory $MonthlyAvailableCopyWith(MonthlyAvailable value, $Res Function(MonthlyAvailable) _then) = _$MonthlyAvailableCopyWithImpl;
@useResult
$Res call({
 double expectedIncome, double realizedExpenses, double pendingExpenses, double plannedExpenses
});




}
/// @nodoc
class _$MonthlyAvailableCopyWithImpl<$Res>
    implements $MonthlyAvailableCopyWith<$Res> {
  _$MonthlyAvailableCopyWithImpl(this._self, this._then);

  final MonthlyAvailable _self;
  final $Res Function(MonthlyAvailable) _then;

/// Create a copy of MonthlyAvailable
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? expectedIncome = null,Object? realizedExpenses = null,Object? pendingExpenses = null,Object? plannedExpenses = null,}) {
  return _then(_self.copyWith(
expectedIncome: null == expectedIncome ? _self.expectedIncome : expectedIncome // ignore: cast_nullable_to_non_nullable
as double,realizedExpenses: null == realizedExpenses ? _self.realizedExpenses : realizedExpenses // ignore: cast_nullable_to_non_nullable
as double,pendingExpenses: null == pendingExpenses ? _self.pendingExpenses : pendingExpenses // ignore: cast_nullable_to_non_nullable
as double,plannedExpenses: null == plannedExpenses ? _self.plannedExpenses : plannedExpenses // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthlyAvailable].
extension MonthlyAvailablePatterns on MonthlyAvailable {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthlyAvailable value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthlyAvailable() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthlyAvailable value)  $default,){
final _that = this;
switch (_that) {
case _MonthlyAvailable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthlyAvailable value)?  $default,){
final _that = this;
switch (_that) {
case _MonthlyAvailable() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double expectedIncome,  double realizedExpenses,  double pendingExpenses,  double plannedExpenses)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthlyAvailable() when $default != null:
return $default(_that.expectedIncome,_that.realizedExpenses,_that.pendingExpenses,_that.plannedExpenses);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double expectedIncome,  double realizedExpenses,  double pendingExpenses,  double plannedExpenses)  $default,) {final _that = this;
switch (_that) {
case _MonthlyAvailable():
return $default(_that.expectedIncome,_that.realizedExpenses,_that.pendingExpenses,_that.plannedExpenses);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double expectedIncome,  double realizedExpenses,  double pendingExpenses,  double plannedExpenses)?  $default,) {final _that = this;
switch (_that) {
case _MonthlyAvailable() when $default != null:
return $default(_that.expectedIncome,_that.realizedExpenses,_that.pendingExpenses,_that.plannedExpenses);case _:
  return null;

}
}

}

/// @nodoc


class _MonthlyAvailable extends MonthlyAvailable {
  const _MonthlyAvailable({required this.expectedIncome, required this.realizedExpenses, required this.pendingExpenses, required this.plannedExpenses}): super._();
  

/// Soma de `max(generalPlannedAmount, specificPlannedAmount)` das
/// categorias de receita no `period_summaries` do mês.
@override final  double expectedIncome;
/// Soma de `actualAmount` das categorias de despesa (sem as de sistema).
@override final  double realizedExpenses;
/// Parcelas de despesa ainda `pending` com vencimento até o fim do mês.
@override final  double pendingExpenses;
/// Soma dos limites de despesa do mês, para a linha "realizado/previsto".
@override final  double plannedExpenses;

/// Create a copy of MonthlyAvailable
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthlyAvailableCopyWith<_MonthlyAvailable> get copyWith => __$MonthlyAvailableCopyWithImpl<_MonthlyAvailable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthlyAvailable&&(identical(other.expectedIncome, expectedIncome) || other.expectedIncome == expectedIncome)&&(identical(other.realizedExpenses, realizedExpenses) || other.realizedExpenses == realizedExpenses)&&(identical(other.pendingExpenses, pendingExpenses) || other.pendingExpenses == pendingExpenses)&&(identical(other.plannedExpenses, plannedExpenses) || other.plannedExpenses == plannedExpenses));
}


@override
int get hashCode => Object.hash(runtimeType,expectedIncome,realizedExpenses,pendingExpenses,plannedExpenses);

@override
String toString() {
  return 'MonthlyAvailable(expectedIncome: $expectedIncome, realizedExpenses: $realizedExpenses, pendingExpenses: $pendingExpenses, plannedExpenses: $plannedExpenses)';
}


}

/// @nodoc
abstract mixin class _$MonthlyAvailableCopyWith<$Res> implements $MonthlyAvailableCopyWith<$Res> {
  factory _$MonthlyAvailableCopyWith(_MonthlyAvailable value, $Res Function(_MonthlyAvailable) _then) = __$MonthlyAvailableCopyWithImpl;
@override @useResult
$Res call({
 double expectedIncome, double realizedExpenses, double pendingExpenses, double plannedExpenses
});




}
/// @nodoc
class __$MonthlyAvailableCopyWithImpl<$Res>
    implements _$MonthlyAvailableCopyWith<$Res> {
  __$MonthlyAvailableCopyWithImpl(this._self, this._then);

  final _MonthlyAvailable _self;
  final $Res Function(_MonthlyAvailable) _then;

/// Create a copy of MonthlyAvailable
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? expectedIncome = null,Object? realizedExpenses = null,Object? pendingExpenses = null,Object? plannedExpenses = null,}) {
  return _then(_MonthlyAvailable(
expectedIncome: null == expectedIncome ? _self.expectedIncome : expectedIncome // ignore: cast_nullable_to_non_nullable
as double,realizedExpenses: null == realizedExpenses ? _self.realizedExpenses : realizedExpenses // ignore: cast_nullable_to_non_nullable
as double,pendingExpenses: null == pendingExpenses ? _self.pendingExpenses : pendingExpenses // ignore: cast_nullable_to_non_nullable
as double,plannedExpenses: null == plannedExpenses ? _self.plannedExpenses : plannedExpenses // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
