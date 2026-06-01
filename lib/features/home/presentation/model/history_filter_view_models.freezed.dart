// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_filter_view_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HistoryFilterState {

 String? get accountId; String? get description; CategoryModel? get category; OrderType? get type; InstallmentStatus? get status; double? get minAmount; double? get maxAmount; DateTime? get startDate; DateTime? get endDate;
/// Create a copy of HistoryFilterState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryFilterStateCopyWith<HistoryFilterState> get copyWith => _$HistoryFilterStateCopyWithImpl<HistoryFilterState>(this as HistoryFilterState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryFilterState&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.minAmount, minAmount) || other.minAmount == minAmount)&&(identical(other.maxAmount, maxAmount) || other.maxAmount == maxAmount)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}


@override
int get hashCode => Object.hash(runtimeType,accountId,description,category,type,status,minAmount,maxAmount,startDate,endDate);

@override
String toString() {
  return 'HistoryFilterState(accountId: $accountId, description: $description, category: $category, type: $type, status: $status, minAmount: $minAmount, maxAmount: $maxAmount, startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class $HistoryFilterStateCopyWith<$Res>  {
  factory $HistoryFilterStateCopyWith(HistoryFilterState value, $Res Function(HistoryFilterState) _then) = _$HistoryFilterStateCopyWithImpl;
@useResult
$Res call({
 String? accountId, String? description, CategoryModel? category, OrderType? type, InstallmentStatus? status, double? minAmount, double? maxAmount, DateTime? startDate, DateTime? endDate
});


$CategoryModelCopyWith<$Res>? get category;

}
/// @nodoc
class _$HistoryFilterStateCopyWithImpl<$Res>
    implements $HistoryFilterStateCopyWith<$Res> {
  _$HistoryFilterStateCopyWithImpl(this._self, this._then);

  final HistoryFilterState _self;
  final $Res Function(HistoryFilterState) _then;

/// Create a copy of HistoryFilterState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountId = freezed,Object? description = freezed,Object? category = freezed,Object? type = freezed,Object? status = freezed,Object? minAmount = freezed,Object? maxAmount = freezed,Object? startDate = freezed,Object? endDate = freezed,}) {
  return _then(_self.copyWith(
accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstallmentStatus?,minAmount: freezed == minAmount ? _self.minAmount : minAmount // ignore: cast_nullable_to_non_nullable
as double?,maxAmount: freezed == maxAmount ? _self.maxAmount : maxAmount // ignore: cast_nullable_to_non_nullable
as double?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of HistoryFilterState
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


/// Adds pattern-matching-related methods to [HistoryFilterState].
extension HistoryFilterStatePatterns on HistoryFilterState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryFilterState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryFilterState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryFilterState value)  $default,){
final _that = this;
switch (_that) {
case _HistoryFilterState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryFilterState value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryFilterState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? accountId,  String? description,  CategoryModel? category,  OrderType? type,  InstallmentStatus? status,  double? minAmount,  double? maxAmount,  DateTime? startDate,  DateTime? endDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryFilterState() when $default != null:
return $default(_that.accountId,_that.description,_that.category,_that.type,_that.status,_that.minAmount,_that.maxAmount,_that.startDate,_that.endDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? accountId,  String? description,  CategoryModel? category,  OrderType? type,  InstallmentStatus? status,  double? minAmount,  double? maxAmount,  DateTime? startDate,  DateTime? endDate)  $default,) {final _that = this;
switch (_that) {
case _HistoryFilterState():
return $default(_that.accountId,_that.description,_that.category,_that.type,_that.status,_that.minAmount,_that.maxAmount,_that.startDate,_that.endDate);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? accountId,  String? description,  CategoryModel? category,  OrderType? type,  InstallmentStatus? status,  double? minAmount,  double? maxAmount,  DateTime? startDate,  DateTime? endDate)?  $default,) {final _that = this;
switch (_that) {
case _HistoryFilterState() when $default != null:
return $default(_that.accountId,_that.description,_that.category,_that.type,_that.status,_that.minAmount,_that.maxAmount,_that.startDate,_that.endDate);case _:
  return null;

}
}

}

/// @nodoc


class _HistoryFilterState extends HistoryFilterState {
  const _HistoryFilterState({this.accountId, this.description, this.category, this.type, this.status, this.minAmount, this.maxAmount, this.startDate, this.endDate}): super._();
  

@override final  String? accountId;
@override final  String? description;
@override final  CategoryModel? category;
@override final  OrderType? type;
@override final  InstallmentStatus? status;
@override final  double? minAmount;
@override final  double? maxAmount;
@override final  DateTime? startDate;
@override final  DateTime? endDate;

/// Create a copy of HistoryFilterState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryFilterStateCopyWith<_HistoryFilterState> get copyWith => __$HistoryFilterStateCopyWithImpl<_HistoryFilterState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryFilterState&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.minAmount, minAmount) || other.minAmount == minAmount)&&(identical(other.maxAmount, maxAmount) || other.maxAmount == maxAmount)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}


@override
int get hashCode => Object.hash(runtimeType,accountId,description,category,type,status,minAmount,maxAmount,startDate,endDate);

@override
String toString() {
  return 'HistoryFilterState(accountId: $accountId, description: $description, category: $category, type: $type, status: $status, minAmount: $minAmount, maxAmount: $maxAmount, startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class _$HistoryFilterStateCopyWith<$Res> implements $HistoryFilterStateCopyWith<$Res> {
  factory _$HistoryFilterStateCopyWith(_HistoryFilterState value, $Res Function(_HistoryFilterState) _then) = __$HistoryFilterStateCopyWithImpl;
@override @useResult
$Res call({
 String? accountId, String? description, CategoryModel? category, OrderType? type, InstallmentStatus? status, double? minAmount, double? maxAmount, DateTime? startDate, DateTime? endDate
});


@override $CategoryModelCopyWith<$Res>? get category;

}
/// @nodoc
class __$HistoryFilterStateCopyWithImpl<$Res>
    implements _$HistoryFilterStateCopyWith<$Res> {
  __$HistoryFilterStateCopyWithImpl(this._self, this._then);

  final _HistoryFilterState _self;
  final $Res Function(_HistoryFilterState) _then;

/// Create a copy of HistoryFilterState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountId = freezed,Object? description = freezed,Object? category = freezed,Object? type = freezed,Object? status = freezed,Object? minAmount = freezed,Object? maxAmount = freezed,Object? startDate = freezed,Object? endDate = freezed,}) {
  return _then(_HistoryFilterState(
accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstallmentStatus?,minAmount: freezed == minAmount ? _self.minAmount : minAmount // ignore: cast_nullable_to_non_nullable
as double?,maxAmount: freezed == maxAmount ? _self.maxAmount : maxAmount // ignore: cast_nullable_to_non_nullable
as double?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of HistoryFilterState
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

// dart format on
