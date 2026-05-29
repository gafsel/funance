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

// dart format on
