// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ledger_entry_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LedgerEntryModel {

 String get id;@JsonKey(name: 'order_id') String? get orderId; String get category; double get amount;@JsonKey(name: 'due_date') DateTime get dueDate; LedgerEntryStatus get status; LedgerEntryType get type;@JsonKey(name: 'account_id') String? get accountId;@JsonKey(name: 'is_deductible') bool get isDeductible;
/// Create a copy of LedgerEntryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LedgerEntryModelCopyWith<LedgerEntryModel> get copyWith => _$LedgerEntryModelCopyWithImpl<LedgerEntryModel>(this as LedgerEntryModel, _$identity);

  /// Serializes this LedgerEntryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LedgerEntryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.type, type) || other.type == type)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.isDeductible, isDeductible) || other.isDeductible == isDeductible));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,category,amount,dueDate,status,type,accountId,isDeductible);

@override
String toString() {
  return 'LedgerEntryModel(id: $id, orderId: $orderId, category: $category, amount: $amount, dueDate: $dueDate, status: $status, type: $type, accountId: $accountId, isDeductible: $isDeductible)';
}


}

/// @nodoc
abstract mixin class $LedgerEntryModelCopyWith<$Res>  {
  factory $LedgerEntryModelCopyWith(LedgerEntryModel value, $Res Function(LedgerEntryModel) _then) = _$LedgerEntryModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'order_id') String? orderId, String category, double amount,@JsonKey(name: 'due_date') DateTime dueDate, LedgerEntryStatus status, LedgerEntryType type,@JsonKey(name: 'account_id') String? accountId,@JsonKey(name: 'is_deductible') bool isDeductible
});




}
/// @nodoc
class _$LedgerEntryModelCopyWithImpl<$Res>
    implements $LedgerEntryModelCopyWith<$Res> {
  _$LedgerEntryModelCopyWithImpl(this._self, this._then);

  final LedgerEntryModel _self;
  final $Res Function(LedgerEntryModel) _then;

/// Create a copy of LedgerEntryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderId = freezed,Object? category = null,Object? amount = null,Object? dueDate = null,Object? status = null,Object? type = null,Object? accountId = freezed,Object? isDeductible = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LedgerEntryStatus,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LedgerEntryType,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,isDeductible: null == isDeductible ? _self.isDeductible : isDeductible // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LedgerEntryModel].
extension LedgerEntryModelPatterns on LedgerEntryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LedgerEntryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LedgerEntryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LedgerEntryModel value)  $default,){
final _that = this;
switch (_that) {
case _LedgerEntryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LedgerEntryModel value)?  $default,){
final _that = this;
switch (_that) {
case _LedgerEntryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'order_id')  String? orderId,  String category,  double amount, @JsonKey(name: 'due_date')  DateTime dueDate,  LedgerEntryStatus status,  LedgerEntryType type, @JsonKey(name: 'account_id')  String? accountId, @JsonKey(name: 'is_deductible')  bool isDeductible)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LedgerEntryModel() when $default != null:
return $default(_that.id,_that.orderId,_that.category,_that.amount,_that.dueDate,_that.status,_that.type,_that.accountId,_that.isDeductible);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'order_id')  String? orderId,  String category,  double amount, @JsonKey(name: 'due_date')  DateTime dueDate,  LedgerEntryStatus status,  LedgerEntryType type, @JsonKey(name: 'account_id')  String? accountId, @JsonKey(name: 'is_deductible')  bool isDeductible)  $default,) {final _that = this;
switch (_that) {
case _LedgerEntryModel():
return $default(_that.id,_that.orderId,_that.category,_that.amount,_that.dueDate,_that.status,_that.type,_that.accountId,_that.isDeductible);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'order_id')  String? orderId,  String category,  double amount, @JsonKey(name: 'due_date')  DateTime dueDate,  LedgerEntryStatus status,  LedgerEntryType type, @JsonKey(name: 'account_id')  String? accountId, @JsonKey(name: 'is_deductible')  bool isDeductible)?  $default,) {final _that = this;
switch (_that) {
case _LedgerEntryModel() when $default != null:
return $default(_that.id,_that.orderId,_that.category,_that.amount,_that.dueDate,_that.status,_that.type,_that.accountId,_that.isDeductible);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LedgerEntryModel implements LedgerEntryModel {
  const _LedgerEntryModel({required this.id, @JsonKey(name: 'order_id') this.orderId, required this.category, required this.amount, @JsonKey(name: 'due_date') required this.dueDate, required this.status, required this.type, @JsonKey(name: 'account_id') this.accountId, @JsonKey(name: 'is_deductible') this.isDeductible = false});
  factory _LedgerEntryModel.fromJson(Map<String, dynamic> json) => _$LedgerEntryModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'order_id') final  String? orderId;
@override final  String category;
@override final  double amount;
@override@JsonKey(name: 'due_date') final  DateTime dueDate;
@override final  LedgerEntryStatus status;
@override final  LedgerEntryType type;
@override@JsonKey(name: 'account_id') final  String? accountId;
@override@JsonKey(name: 'is_deductible') final  bool isDeductible;

/// Create a copy of LedgerEntryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LedgerEntryModelCopyWith<_LedgerEntryModel> get copyWith => __$LedgerEntryModelCopyWithImpl<_LedgerEntryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LedgerEntryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LedgerEntryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.type, type) || other.type == type)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.isDeductible, isDeductible) || other.isDeductible == isDeductible));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,category,amount,dueDate,status,type,accountId,isDeductible);

@override
String toString() {
  return 'LedgerEntryModel(id: $id, orderId: $orderId, category: $category, amount: $amount, dueDate: $dueDate, status: $status, type: $type, accountId: $accountId, isDeductible: $isDeductible)';
}


}

/// @nodoc
abstract mixin class _$LedgerEntryModelCopyWith<$Res> implements $LedgerEntryModelCopyWith<$Res> {
  factory _$LedgerEntryModelCopyWith(_LedgerEntryModel value, $Res Function(_LedgerEntryModel) _then) = __$LedgerEntryModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'order_id') String? orderId, String category, double amount,@JsonKey(name: 'due_date') DateTime dueDate, LedgerEntryStatus status, LedgerEntryType type,@JsonKey(name: 'account_id') String? accountId,@JsonKey(name: 'is_deductible') bool isDeductible
});




}
/// @nodoc
class __$LedgerEntryModelCopyWithImpl<$Res>
    implements _$LedgerEntryModelCopyWith<$Res> {
  __$LedgerEntryModelCopyWithImpl(this._self, this._then);

  final _LedgerEntryModel _self;
  final $Res Function(_LedgerEntryModel) _then;

/// Create a copy of LedgerEntryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderId = freezed,Object? category = null,Object? amount = null,Object? dueDate = null,Object? status = null,Object? type = null,Object? accountId = freezed,Object? isDeductible = null,}) {
  return _then(_LedgerEntryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LedgerEntryStatus,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as LedgerEntryType,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,isDeductible: null == isDeductible ? _self.isDeductible : isDeductible // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
