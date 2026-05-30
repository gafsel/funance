// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'overview_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SummaryState {

 List<PeriodSummaryModel> get summary; double get specificPlannedAmountOthers; double get generalPlannedAmountOthers; double get actualAmountOthers; double get totalAmount;
/// Create a copy of SummaryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SummaryStateCopyWith<SummaryState> get copyWith => _$SummaryStateCopyWithImpl<SummaryState>(this as SummaryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SummaryState&&const DeepCollectionEquality().equals(other.summary, summary)&&(identical(other.specificPlannedAmountOthers, specificPlannedAmountOthers) || other.specificPlannedAmountOthers == specificPlannedAmountOthers)&&(identical(other.generalPlannedAmountOthers, generalPlannedAmountOthers) || other.generalPlannedAmountOthers == generalPlannedAmountOthers)&&(identical(other.actualAmountOthers, actualAmountOthers) || other.actualAmountOthers == actualAmountOthers)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(summary),specificPlannedAmountOthers,generalPlannedAmountOthers,actualAmountOthers,totalAmount);

@override
String toString() {
  return 'SummaryState(summary: $summary, specificPlannedAmountOthers: $specificPlannedAmountOthers, generalPlannedAmountOthers: $generalPlannedAmountOthers, actualAmountOthers: $actualAmountOthers, totalAmount: $totalAmount)';
}


}

/// @nodoc
abstract mixin class $SummaryStateCopyWith<$Res>  {
  factory $SummaryStateCopyWith(SummaryState value, $Res Function(SummaryState) _then) = _$SummaryStateCopyWithImpl;
@useResult
$Res call({
 List<PeriodSummaryModel> summary, double specificPlannedAmountOthers, double generalPlannedAmountOthers, double actualAmountOthers, double totalAmount
});




}
/// @nodoc
class _$SummaryStateCopyWithImpl<$Res>
    implements $SummaryStateCopyWith<$Res> {
  _$SummaryStateCopyWithImpl(this._self, this._then);

  final SummaryState _self;
  final $Res Function(SummaryState) _then;

/// Create a copy of SummaryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summary = null,Object? specificPlannedAmountOthers = null,Object? generalPlannedAmountOthers = null,Object? actualAmountOthers = null,Object? totalAmount = null,}) {
  return _then(_self.copyWith(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as List<PeriodSummaryModel>,specificPlannedAmountOthers: null == specificPlannedAmountOthers ? _self.specificPlannedAmountOthers : specificPlannedAmountOthers // ignore: cast_nullable_to_non_nullable
as double,generalPlannedAmountOthers: null == generalPlannedAmountOthers ? _self.generalPlannedAmountOthers : generalPlannedAmountOthers // ignore: cast_nullable_to_non_nullable
as double,actualAmountOthers: null == actualAmountOthers ? _self.actualAmountOthers : actualAmountOthers // ignore: cast_nullable_to_non_nullable
as double,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [SummaryState].
extension SummaryStatePatterns on SummaryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SummaryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SummaryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SummaryState value)  $default,){
final _that = this;
switch (_that) {
case _SummaryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SummaryState value)?  $default,){
final _that = this;
switch (_that) {
case _SummaryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PeriodSummaryModel> summary,  double specificPlannedAmountOthers,  double generalPlannedAmountOthers,  double actualAmountOthers,  double totalAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SummaryState() when $default != null:
return $default(_that.summary,_that.specificPlannedAmountOthers,_that.generalPlannedAmountOthers,_that.actualAmountOthers,_that.totalAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PeriodSummaryModel> summary,  double specificPlannedAmountOthers,  double generalPlannedAmountOthers,  double actualAmountOthers,  double totalAmount)  $default,) {final _that = this;
switch (_that) {
case _SummaryState():
return $default(_that.summary,_that.specificPlannedAmountOthers,_that.generalPlannedAmountOthers,_that.actualAmountOthers,_that.totalAmount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PeriodSummaryModel> summary,  double specificPlannedAmountOthers,  double generalPlannedAmountOthers,  double actualAmountOthers,  double totalAmount)?  $default,) {final _that = this;
switch (_that) {
case _SummaryState() when $default != null:
return $default(_that.summary,_that.specificPlannedAmountOthers,_that.generalPlannedAmountOthers,_that.actualAmountOthers,_that.totalAmount);case _:
  return null;

}
}

}

/// @nodoc


class _SummaryState implements SummaryState {
   _SummaryState({required final  List<PeriodSummaryModel> summary, required this.specificPlannedAmountOthers, required this.generalPlannedAmountOthers, required this.actualAmountOthers, required this.totalAmount}): _summary = summary;
  

 final  List<PeriodSummaryModel> _summary;
@override List<PeriodSummaryModel> get summary {
  if (_summary is EqualUnmodifiableListView) return _summary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_summary);
}

@override final  double specificPlannedAmountOthers;
@override final  double generalPlannedAmountOthers;
@override final  double actualAmountOthers;
@override final  double totalAmount;

/// Create a copy of SummaryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SummaryStateCopyWith<_SummaryState> get copyWith => __$SummaryStateCopyWithImpl<_SummaryState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SummaryState&&const DeepCollectionEquality().equals(other._summary, _summary)&&(identical(other.specificPlannedAmountOthers, specificPlannedAmountOthers) || other.specificPlannedAmountOthers == specificPlannedAmountOthers)&&(identical(other.generalPlannedAmountOthers, generalPlannedAmountOthers) || other.generalPlannedAmountOthers == generalPlannedAmountOthers)&&(identical(other.actualAmountOthers, actualAmountOthers) || other.actualAmountOthers == actualAmountOthers)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_summary),specificPlannedAmountOthers,generalPlannedAmountOthers,actualAmountOthers,totalAmount);

@override
String toString() {
  return 'SummaryState(summary: $summary, specificPlannedAmountOthers: $specificPlannedAmountOthers, generalPlannedAmountOthers: $generalPlannedAmountOthers, actualAmountOthers: $actualAmountOthers, totalAmount: $totalAmount)';
}


}

/// @nodoc
abstract mixin class _$SummaryStateCopyWith<$Res> implements $SummaryStateCopyWith<$Res> {
  factory _$SummaryStateCopyWith(_SummaryState value, $Res Function(_SummaryState) _then) = __$SummaryStateCopyWithImpl;
@override @useResult
$Res call({
 List<PeriodSummaryModel> summary, double specificPlannedAmountOthers, double generalPlannedAmountOthers, double actualAmountOthers, double totalAmount
});




}
/// @nodoc
class __$SummaryStateCopyWithImpl<$Res>
    implements _$SummaryStateCopyWith<$Res> {
  __$SummaryStateCopyWithImpl(this._self, this._then);

  final _SummaryState _self;
  final $Res Function(_SummaryState) _then;

/// Create a copy of SummaryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summary = null,Object? specificPlannedAmountOthers = null,Object? generalPlannedAmountOthers = null,Object? actualAmountOthers = null,Object? totalAmount = null,}) {
  return _then(_SummaryState(
summary: null == summary ? _self._summary : summary // ignore: cast_nullable_to_non_nullable
as List<PeriodSummaryModel>,specificPlannedAmountOthers: null == specificPlannedAmountOthers ? _self.specificPlannedAmountOthers : specificPlannedAmountOthers // ignore: cast_nullable_to_non_nullable
as double,generalPlannedAmountOthers: null == generalPlannedAmountOthers ? _self.generalPlannedAmountOthers : generalPlannedAmountOthers // ignore: cast_nullable_to_non_nullable
as double,actualAmountOthers: null == actualAmountOthers ? _self.actualAmountOthers : actualAmountOthers // ignore: cast_nullable_to_non_nullable
as double,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$BalanceState {

 double get totalPlanned; double get totalActual;
/// Create a copy of BalanceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BalanceStateCopyWith<BalanceState> get copyWith => _$BalanceStateCopyWithImpl<BalanceState>(this as BalanceState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BalanceState&&(identical(other.totalPlanned, totalPlanned) || other.totalPlanned == totalPlanned)&&(identical(other.totalActual, totalActual) || other.totalActual == totalActual));
}


@override
int get hashCode => Object.hash(runtimeType,totalPlanned,totalActual);

@override
String toString() {
  return 'BalanceState(totalPlanned: $totalPlanned, totalActual: $totalActual)';
}


}

/// @nodoc
abstract mixin class $BalanceStateCopyWith<$Res>  {
  factory $BalanceStateCopyWith(BalanceState value, $Res Function(BalanceState) _then) = _$BalanceStateCopyWithImpl;
@useResult
$Res call({
 double totalPlanned, double totalActual
});




}
/// @nodoc
class _$BalanceStateCopyWithImpl<$Res>
    implements $BalanceStateCopyWith<$Res> {
  _$BalanceStateCopyWithImpl(this._self, this._then);

  final BalanceState _self;
  final $Res Function(BalanceState) _then;

/// Create a copy of BalanceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalPlanned = null,Object? totalActual = null,}) {
  return _then(_self.copyWith(
totalPlanned: null == totalPlanned ? _self.totalPlanned : totalPlanned // ignore: cast_nullable_to_non_nullable
as double,totalActual: null == totalActual ? _self.totalActual : totalActual // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [BalanceState].
extension BalanceStatePatterns on BalanceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BalanceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BalanceState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BalanceState value)  $default,){
final _that = this;
switch (_that) {
case _BalanceState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BalanceState value)?  $default,){
final _that = this;
switch (_that) {
case _BalanceState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double totalPlanned,  double totalActual)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BalanceState() when $default != null:
return $default(_that.totalPlanned,_that.totalActual);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double totalPlanned,  double totalActual)  $default,) {final _that = this;
switch (_that) {
case _BalanceState():
return $default(_that.totalPlanned,_that.totalActual);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double totalPlanned,  double totalActual)?  $default,) {final _that = this;
switch (_that) {
case _BalanceState() when $default != null:
return $default(_that.totalPlanned,_that.totalActual);case _:
  return null;

}
}

}

/// @nodoc


class _BalanceState implements BalanceState {
   _BalanceState({required this.totalPlanned, required this.totalActual});
  

@override final  double totalPlanned;
@override final  double totalActual;

/// Create a copy of BalanceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BalanceStateCopyWith<_BalanceState> get copyWith => __$BalanceStateCopyWithImpl<_BalanceState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BalanceState&&(identical(other.totalPlanned, totalPlanned) || other.totalPlanned == totalPlanned)&&(identical(other.totalActual, totalActual) || other.totalActual == totalActual));
}


@override
int get hashCode => Object.hash(runtimeType,totalPlanned,totalActual);

@override
String toString() {
  return 'BalanceState(totalPlanned: $totalPlanned, totalActual: $totalActual)';
}


}

/// @nodoc
abstract mixin class _$BalanceStateCopyWith<$Res> implements $BalanceStateCopyWith<$Res> {
  factory _$BalanceStateCopyWith(_BalanceState value, $Res Function(_BalanceState) _then) = __$BalanceStateCopyWithImpl;
@override @useResult
$Res call({
 double totalPlanned, double totalActual
});




}
/// @nodoc
class __$BalanceStateCopyWithImpl<$Res>
    implements _$BalanceStateCopyWith<$Res> {
  __$BalanceStateCopyWithImpl(this._self, this._then);

  final _BalanceState _self;
  final $Res Function(_BalanceState) _then;

/// Create a copy of BalanceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalPlanned = null,Object? totalActual = null,}) {
  return _then(_BalanceState(
totalPlanned: null == totalPlanned ? _self.totalPlanned : totalPlanned // ignore: cast_nullable_to_non_nullable
as double,totalActual: null == totalActual ? _self.totalActual : totalActual // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
