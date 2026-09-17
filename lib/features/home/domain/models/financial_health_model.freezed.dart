// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'financial_health_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FreedomComponentScore {

 FreedomComponent get component; double get score; double? get months; double? get rate; int? get within; int? get total; double? get delta;
/// Create a copy of FreedomComponentScore
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FreedomComponentScoreCopyWith<FreedomComponentScore> get copyWith => _$FreedomComponentScoreCopyWithImpl<FreedomComponentScore>(this as FreedomComponentScore, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FreedomComponentScore&&(identical(other.component, component) || other.component == component)&&(identical(other.score, score) || other.score == score)&&(identical(other.months, months) || other.months == months)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.within, within) || other.within == within)&&(identical(other.total, total) || other.total == total)&&(identical(other.delta, delta) || other.delta == delta));
}


@override
int get hashCode => Object.hash(runtimeType,component,score,months,rate,within,total,delta);

@override
String toString() {
  return 'FreedomComponentScore(component: $component, score: $score, months: $months, rate: $rate, within: $within, total: $total, delta: $delta)';
}


}

/// @nodoc
abstract mixin class $FreedomComponentScoreCopyWith<$Res>  {
  factory $FreedomComponentScoreCopyWith(FreedomComponentScore value, $Res Function(FreedomComponentScore) _then) = _$FreedomComponentScoreCopyWithImpl;
@useResult
$Res call({
 FreedomComponent component, double score, double? months, double? rate, int? within, int? total, double? delta
});




}
/// @nodoc
class _$FreedomComponentScoreCopyWithImpl<$Res>
    implements $FreedomComponentScoreCopyWith<$Res> {
  _$FreedomComponentScoreCopyWithImpl(this._self, this._then);

  final FreedomComponentScore _self;
  final $Res Function(FreedomComponentScore) _then;

/// Create a copy of FreedomComponentScore
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? component = null,Object? score = null,Object? months = freezed,Object? rate = freezed,Object? within = freezed,Object? total = freezed,Object? delta = freezed,}) {
  return _then(_self.copyWith(
component: null == component ? _self.component : component // ignore: cast_nullable_to_non_nullable
as FreedomComponent,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,months: freezed == months ? _self.months : months // ignore: cast_nullable_to_non_nullable
as double?,rate: freezed == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double?,within: freezed == within ? _self.within : within // ignore: cast_nullable_to_non_nullable
as int?,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int?,delta: freezed == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [FreedomComponentScore].
extension FreedomComponentScorePatterns on FreedomComponentScore {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FreedomComponentScore value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FreedomComponentScore() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FreedomComponentScore value)  $default,){
final _that = this;
switch (_that) {
case _FreedomComponentScore():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FreedomComponentScore value)?  $default,){
final _that = this;
switch (_that) {
case _FreedomComponentScore() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FreedomComponent component,  double score,  double? months,  double? rate,  int? within,  int? total,  double? delta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FreedomComponentScore() when $default != null:
return $default(_that.component,_that.score,_that.months,_that.rate,_that.within,_that.total,_that.delta);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FreedomComponent component,  double score,  double? months,  double? rate,  int? within,  int? total,  double? delta)  $default,) {final _that = this;
switch (_that) {
case _FreedomComponentScore():
return $default(_that.component,_that.score,_that.months,_that.rate,_that.within,_that.total,_that.delta);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FreedomComponent component,  double score,  double? months,  double? rate,  int? within,  int? total,  double? delta)?  $default,) {final _that = this;
switch (_that) {
case _FreedomComponentScore() when $default != null:
return $default(_that.component,_that.score,_that.months,_that.rate,_that.within,_that.total,_that.delta);case _:
  return null;

}
}

}

/// @nodoc


class _FreedomComponentScore extends FreedomComponentScore {
  const _FreedomComponentScore({required this.component, required this.score, this.months, this.rate, this.within, this.total, this.delta}): super._();
  

@override final  FreedomComponent component;
@override final  double score;
@override final  double? months;
@override final  double? rate;
@override final  int? within;
@override final  int? total;
@override final  double? delta;

/// Create a copy of FreedomComponentScore
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FreedomComponentScoreCopyWith<_FreedomComponentScore> get copyWith => __$FreedomComponentScoreCopyWithImpl<_FreedomComponentScore>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FreedomComponentScore&&(identical(other.component, component) || other.component == component)&&(identical(other.score, score) || other.score == score)&&(identical(other.months, months) || other.months == months)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.within, within) || other.within == within)&&(identical(other.total, total) || other.total == total)&&(identical(other.delta, delta) || other.delta == delta));
}


@override
int get hashCode => Object.hash(runtimeType,component,score,months,rate,within,total,delta);

@override
String toString() {
  return 'FreedomComponentScore(component: $component, score: $score, months: $months, rate: $rate, within: $within, total: $total, delta: $delta)';
}


}

/// @nodoc
abstract mixin class _$FreedomComponentScoreCopyWith<$Res> implements $FreedomComponentScoreCopyWith<$Res> {
  factory _$FreedomComponentScoreCopyWith(_FreedomComponentScore value, $Res Function(_FreedomComponentScore) _then) = __$FreedomComponentScoreCopyWithImpl;
@override @useResult
$Res call({
 FreedomComponent component, double score, double? months, double? rate, int? within, int? total, double? delta
});




}
/// @nodoc
class __$FreedomComponentScoreCopyWithImpl<$Res>
    implements _$FreedomComponentScoreCopyWith<$Res> {
  __$FreedomComponentScoreCopyWithImpl(this._self, this._then);

  final _FreedomComponentScore _self;
  final $Res Function(_FreedomComponentScore) _then;

/// Create a copy of FreedomComponentScore
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? component = null,Object? score = null,Object? months = freezed,Object? rate = freezed,Object? within = freezed,Object? total = freezed,Object? delta = freezed,}) {
  return _then(_FreedomComponentScore(
component: null == component ? _self.component : component // ignore: cast_nullable_to_non_nullable
as FreedomComponent,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,months: freezed == months ? _self.months : months // ignore: cast_nullable_to_non_nullable
as double?,rate: freezed == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double?,within: freezed == within ? _self.within : within // ignore: cast_nullable_to_non_nullable
as int?,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int?,delta: freezed == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc
mixin _$FinancialHealth {

 double get score; FreedomTier get tier; List<FreedomComponentScore> get components; DateTime? get computedAt; String? get monthKey;
/// Create a copy of FinancialHealth
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinancialHealthCopyWith<FinancialHealth> get copyWith => _$FinancialHealthCopyWithImpl<FinancialHealth>(this as FinancialHealth, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinancialHealth&&(identical(other.score, score) || other.score == score)&&(identical(other.tier, tier) || other.tier == tier)&&const DeepCollectionEquality().equals(other.components, components)&&(identical(other.computedAt, computedAt) || other.computedAt == computedAt)&&(identical(other.monthKey, monthKey) || other.monthKey == monthKey));
}


@override
int get hashCode => Object.hash(runtimeType,score,tier,const DeepCollectionEquality().hash(components),computedAt,monthKey);

@override
String toString() {
  return 'FinancialHealth(score: $score, tier: $tier, components: $components, computedAt: $computedAt, monthKey: $monthKey)';
}


}

/// @nodoc
abstract mixin class $FinancialHealthCopyWith<$Res>  {
  factory $FinancialHealthCopyWith(FinancialHealth value, $Res Function(FinancialHealth) _then) = _$FinancialHealthCopyWithImpl;
@useResult
$Res call({
 double score, FreedomTier tier, List<FreedomComponentScore> components, DateTime? computedAt, String? monthKey
});




}
/// @nodoc
class _$FinancialHealthCopyWithImpl<$Res>
    implements $FinancialHealthCopyWith<$Res> {
  _$FinancialHealthCopyWithImpl(this._self, this._then);

  final FinancialHealth _self;
  final $Res Function(FinancialHealth) _then;

/// Create a copy of FinancialHealth
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? score = null,Object? tier = null,Object? components = null,Object? computedAt = freezed,Object? monthKey = freezed,}) {
  return _then(_self.copyWith(
score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as FreedomTier,components: null == components ? _self.components : components // ignore: cast_nullable_to_non_nullable
as List<FreedomComponentScore>,computedAt: freezed == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,monthKey: freezed == monthKey ? _self.monthKey : monthKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FinancialHealth].
extension FinancialHealthPatterns on FinancialHealth {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinancialHealth value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinancialHealth() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinancialHealth value)  $default,){
final _that = this;
switch (_that) {
case _FinancialHealth():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinancialHealth value)?  $default,){
final _that = this;
switch (_that) {
case _FinancialHealth() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double score,  FreedomTier tier,  List<FreedomComponentScore> components,  DateTime? computedAt,  String? monthKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinancialHealth() when $default != null:
return $default(_that.score,_that.tier,_that.components,_that.computedAt,_that.monthKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double score,  FreedomTier tier,  List<FreedomComponentScore> components,  DateTime? computedAt,  String? monthKey)  $default,) {final _that = this;
switch (_that) {
case _FinancialHealth():
return $default(_that.score,_that.tier,_that.components,_that.computedAt,_that.monthKey);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double score,  FreedomTier tier,  List<FreedomComponentScore> components,  DateTime? computedAt,  String? monthKey)?  $default,) {final _that = this;
switch (_that) {
case _FinancialHealth() when $default != null:
return $default(_that.score,_that.tier,_that.components,_that.computedAt,_that.monthKey);case _:
  return null;

}
}

}

/// @nodoc


class _FinancialHealth extends FinancialHealth {
  const _FinancialHealth({required this.score, required this.tier, final  List<FreedomComponentScore> components = const <FreedomComponentScore>[], this.computedAt, this.monthKey}): _components = components,super._();
  

@override final  double score;
@override final  FreedomTier tier;
 final  List<FreedomComponentScore> _components;
@override@JsonKey() List<FreedomComponentScore> get components {
  if (_components is EqualUnmodifiableListView) return _components;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_components);
}

@override final  DateTime? computedAt;
@override final  String? monthKey;

/// Create a copy of FinancialHealth
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinancialHealthCopyWith<_FinancialHealth> get copyWith => __$FinancialHealthCopyWithImpl<_FinancialHealth>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinancialHealth&&(identical(other.score, score) || other.score == score)&&(identical(other.tier, tier) || other.tier == tier)&&const DeepCollectionEquality().equals(other._components, _components)&&(identical(other.computedAt, computedAt) || other.computedAt == computedAt)&&(identical(other.monthKey, monthKey) || other.monthKey == monthKey));
}


@override
int get hashCode => Object.hash(runtimeType,score,tier,const DeepCollectionEquality().hash(_components),computedAt,monthKey);

@override
String toString() {
  return 'FinancialHealth(score: $score, tier: $tier, components: $components, computedAt: $computedAt, monthKey: $monthKey)';
}


}

/// @nodoc
abstract mixin class _$FinancialHealthCopyWith<$Res> implements $FinancialHealthCopyWith<$Res> {
  factory _$FinancialHealthCopyWith(_FinancialHealth value, $Res Function(_FinancialHealth) _then) = __$FinancialHealthCopyWithImpl;
@override @useResult
$Res call({
 double score, FreedomTier tier, List<FreedomComponentScore> components, DateTime? computedAt, String? monthKey
});




}
/// @nodoc
class __$FinancialHealthCopyWithImpl<$Res>
    implements _$FinancialHealthCopyWith<$Res> {
  __$FinancialHealthCopyWithImpl(this._self, this._then);

  final _FinancialHealth _self;
  final $Res Function(_FinancialHealth) _then;

/// Create a copy of FinancialHealth
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? score = null,Object? tier = null,Object? components = null,Object? computedAt = freezed,Object? monthKey = freezed,}) {
  return _then(_FinancialHealth(
score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as FreedomTier,components: null == components ? _self._components : components // ignore: cast_nullable_to_non_nullable
as List<FreedomComponentScore>,computedAt: freezed == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,monthKey: freezed == monthKey ? _self.monthKey : monthKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$FinancialHealthPoint {

 String get monthKey; double get score; FreedomTier get tier;
/// Create a copy of FinancialHealthPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinancialHealthPointCopyWith<FinancialHealthPoint> get copyWith => _$FinancialHealthPointCopyWithImpl<FinancialHealthPoint>(this as FinancialHealthPoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinancialHealthPoint&&(identical(other.monthKey, monthKey) || other.monthKey == monthKey)&&(identical(other.score, score) || other.score == score)&&(identical(other.tier, tier) || other.tier == tier));
}


@override
int get hashCode => Object.hash(runtimeType,monthKey,score,tier);

@override
String toString() {
  return 'FinancialHealthPoint(monthKey: $monthKey, score: $score, tier: $tier)';
}


}

/// @nodoc
abstract mixin class $FinancialHealthPointCopyWith<$Res>  {
  factory $FinancialHealthPointCopyWith(FinancialHealthPoint value, $Res Function(FinancialHealthPoint) _then) = _$FinancialHealthPointCopyWithImpl;
@useResult
$Res call({
 String monthKey, double score, FreedomTier tier
});




}
/// @nodoc
class _$FinancialHealthPointCopyWithImpl<$Res>
    implements $FinancialHealthPointCopyWith<$Res> {
  _$FinancialHealthPointCopyWithImpl(this._self, this._then);

  final FinancialHealthPoint _self;
  final $Res Function(FinancialHealthPoint) _then;

/// Create a copy of FinancialHealthPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? monthKey = null,Object? score = null,Object? tier = null,}) {
  return _then(_self.copyWith(
monthKey: null == monthKey ? _self.monthKey : monthKey // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as FreedomTier,
  ));
}

}


/// Adds pattern-matching-related methods to [FinancialHealthPoint].
extension FinancialHealthPointPatterns on FinancialHealthPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinancialHealthPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinancialHealthPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinancialHealthPoint value)  $default,){
final _that = this;
switch (_that) {
case _FinancialHealthPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinancialHealthPoint value)?  $default,){
final _that = this;
switch (_that) {
case _FinancialHealthPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String monthKey,  double score,  FreedomTier tier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinancialHealthPoint() when $default != null:
return $default(_that.monthKey,_that.score,_that.tier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String monthKey,  double score,  FreedomTier tier)  $default,) {final _that = this;
switch (_that) {
case _FinancialHealthPoint():
return $default(_that.monthKey,_that.score,_that.tier);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String monthKey,  double score,  FreedomTier tier)?  $default,) {final _that = this;
switch (_that) {
case _FinancialHealthPoint() when $default != null:
return $default(_that.monthKey,_that.score,_that.tier);case _:
  return null;

}
}

}

/// @nodoc


class _FinancialHealthPoint implements FinancialHealthPoint {
  const _FinancialHealthPoint({required this.monthKey, required this.score, this.tier = FreedomTier.unknown});
  

@override final  String monthKey;
@override final  double score;
@override@JsonKey() final  FreedomTier tier;

/// Create a copy of FinancialHealthPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinancialHealthPointCopyWith<_FinancialHealthPoint> get copyWith => __$FinancialHealthPointCopyWithImpl<_FinancialHealthPoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinancialHealthPoint&&(identical(other.monthKey, monthKey) || other.monthKey == monthKey)&&(identical(other.score, score) || other.score == score)&&(identical(other.tier, tier) || other.tier == tier));
}


@override
int get hashCode => Object.hash(runtimeType,monthKey,score,tier);

@override
String toString() {
  return 'FinancialHealthPoint(monthKey: $monthKey, score: $score, tier: $tier)';
}


}

/// @nodoc
abstract mixin class _$FinancialHealthPointCopyWith<$Res> implements $FinancialHealthPointCopyWith<$Res> {
  factory _$FinancialHealthPointCopyWith(_FinancialHealthPoint value, $Res Function(_FinancialHealthPoint) _then) = __$FinancialHealthPointCopyWithImpl;
@override @useResult
$Res call({
 String monthKey, double score, FreedomTier tier
});




}
/// @nodoc
class __$FinancialHealthPointCopyWithImpl<$Res>
    implements _$FinancialHealthPointCopyWith<$Res> {
  __$FinancialHealthPointCopyWithImpl(this._self, this._then);

  final _FinancialHealthPoint _self;
  final $Res Function(_FinancialHealthPoint) _then;

/// Create a copy of FinancialHealthPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? monthKey = null,Object? score = null,Object? tier = null,}) {
  return _then(_FinancialHealthPoint(
monthKey: null == monthKey ? _self.monthKey : monthKey // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as FreedomTier,
  ));
}


}

// dart format on
