// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HistoryState {

 List<OrderModel> get orders; bool get isLoading; bool get hasMore; OrderModel? get lastOrder; String? get accountId; DateTime? get startDate; DateTime? get endDate;
/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryStateCopyWith<HistoryState> get copyWith => _$HistoryStateCopyWithImpl<HistoryState>(this as HistoryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryState&&const DeepCollectionEquality().equals(other.orders, orders)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.lastOrder, lastOrder) || other.lastOrder == lastOrder)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(orders),isLoading,hasMore,lastOrder,accountId,startDate,endDate);

@override
String toString() {
  return 'HistoryState(orders: $orders, isLoading: $isLoading, hasMore: $hasMore, lastOrder: $lastOrder, accountId: $accountId, startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class $HistoryStateCopyWith<$Res>  {
  factory $HistoryStateCopyWith(HistoryState value, $Res Function(HistoryState) _then) = _$HistoryStateCopyWithImpl;
@useResult
$Res call({
 List<OrderModel> orders, bool isLoading, bool hasMore, OrderModel? lastOrder, String? accountId, DateTime? startDate, DateTime? endDate
});


$OrderModelCopyWith<$Res>? get lastOrder;

}
/// @nodoc
class _$HistoryStateCopyWithImpl<$Res>
    implements $HistoryStateCopyWith<$Res> {
  _$HistoryStateCopyWithImpl(this._self, this._then);

  final HistoryState _self;
  final $Res Function(HistoryState) _then;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orders = null,Object? isLoading = null,Object? hasMore = null,Object? lastOrder = freezed,Object? accountId = freezed,Object? startDate = freezed,Object? endDate = freezed,}) {
  return _then(_self.copyWith(
orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as List<OrderModel>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,lastOrder: freezed == lastOrder ? _self.lastOrder : lastOrder // ignore: cast_nullable_to_non_nullable
as OrderModel?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderModelCopyWith<$Res>? get lastOrder {
    if (_self.lastOrder == null) {
    return null;
  }

  return $OrderModelCopyWith<$Res>(_self.lastOrder!, (value) {
    return _then(_self.copyWith(lastOrder: value));
  });
}
}


/// Adds pattern-matching-related methods to [HistoryState].
extension HistoryStatePatterns on HistoryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryState value)  $default,){
final _that = this;
switch (_that) {
case _HistoryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryState value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<OrderModel> orders,  bool isLoading,  bool hasMore,  OrderModel? lastOrder,  String? accountId,  DateTime? startDate,  DateTime? endDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
return $default(_that.orders,_that.isLoading,_that.hasMore,_that.lastOrder,_that.accountId,_that.startDate,_that.endDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<OrderModel> orders,  bool isLoading,  bool hasMore,  OrderModel? lastOrder,  String? accountId,  DateTime? startDate,  DateTime? endDate)  $default,) {final _that = this;
switch (_that) {
case _HistoryState():
return $default(_that.orders,_that.isLoading,_that.hasMore,_that.lastOrder,_that.accountId,_that.startDate,_that.endDate);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<OrderModel> orders,  bool isLoading,  bool hasMore,  OrderModel? lastOrder,  String? accountId,  DateTime? startDate,  DateTime? endDate)?  $default,) {final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
return $default(_that.orders,_that.isLoading,_that.hasMore,_that.lastOrder,_that.accountId,_that.startDate,_that.endDate);case _:
  return null;

}
}

}

/// @nodoc


class _HistoryState extends HistoryState {
  const _HistoryState({final  List<OrderModel> orders = const [], this.isLoading = false, this.hasMore = true, this.lastOrder, this.accountId, this.startDate, this.endDate}): _orders = orders,super._();
  

 final  List<OrderModel> _orders;
@override@JsonKey() List<OrderModel> get orders {
  if (_orders is EqualUnmodifiableListView) return _orders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orders);
}

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool hasMore;
@override final  OrderModel? lastOrder;
@override final  String? accountId;
@override final  DateTime? startDate;
@override final  DateTime? endDate;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryStateCopyWith<_HistoryState> get copyWith => __$HistoryStateCopyWithImpl<_HistoryState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryState&&const DeepCollectionEquality().equals(other._orders, _orders)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.lastOrder, lastOrder) || other.lastOrder == lastOrder)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_orders),isLoading,hasMore,lastOrder,accountId,startDate,endDate);

@override
String toString() {
  return 'HistoryState(orders: $orders, isLoading: $isLoading, hasMore: $hasMore, lastOrder: $lastOrder, accountId: $accountId, startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class _$HistoryStateCopyWith<$Res> implements $HistoryStateCopyWith<$Res> {
  factory _$HistoryStateCopyWith(_HistoryState value, $Res Function(_HistoryState) _then) = __$HistoryStateCopyWithImpl;
@override @useResult
$Res call({
 List<OrderModel> orders, bool isLoading, bool hasMore, OrderModel? lastOrder, String? accountId, DateTime? startDate, DateTime? endDate
});


@override $OrderModelCopyWith<$Res>? get lastOrder;

}
/// @nodoc
class __$HistoryStateCopyWithImpl<$Res>
    implements _$HistoryStateCopyWith<$Res> {
  __$HistoryStateCopyWithImpl(this._self, this._then);

  final _HistoryState _self;
  final $Res Function(_HistoryState) _then;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orders = null,Object? isLoading = null,Object? hasMore = null,Object? lastOrder = freezed,Object? accountId = freezed,Object? startDate = freezed,Object? endDate = freezed,}) {
  return _then(_HistoryState(
orders: null == orders ? _self._orders : orders // ignore: cast_nullable_to_non_nullable
as List<OrderModel>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,lastOrder: freezed == lastOrder ? _self.lastOrder : lastOrder // ignore: cast_nullable_to_non_nullable
as OrderModel?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderModelCopyWith<$Res>? get lastOrder {
    if (_self.lastOrder == null) {
    return null;
  }

  return $OrderModelCopyWith<$Res>(_self.lastOrder!, (value) {
    return _then(_self.copyWith(lastOrder: value));
  });
}
}

// dart format on
