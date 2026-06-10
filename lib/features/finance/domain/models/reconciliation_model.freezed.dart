// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reconciliation_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReconciliationTransaction {

 String get description; double get amount;@DateTimeTwelvePmConverter() DateTime get date; OrderType get type;// income or expense
 CategoryModel? get category;
/// Create a copy of ReconciliationTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReconciliationTransactionCopyWith<ReconciliationTransaction> get copyWith => _$ReconciliationTransactionCopyWithImpl<ReconciliationTransaction>(this as ReconciliationTransaction, _$identity);

  /// Serializes this ReconciliationTransaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReconciliationTransaction&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,amount,date,type,category);

@override
String toString() {
  return 'ReconciliationTransaction(description: $description, amount: $amount, date: $date, type: $type, category: $category)';
}


}

/// @nodoc
abstract mixin class $ReconciliationTransactionCopyWith<$Res>  {
  factory $ReconciliationTransactionCopyWith(ReconciliationTransaction value, $Res Function(ReconciliationTransaction) _then) = _$ReconciliationTransactionCopyWithImpl;
@useResult
$Res call({
 String description, double amount,@DateTimeTwelvePmConverter() DateTime date, OrderType type, CategoryModel? category
});


$CategoryModelCopyWith<$Res>? get category;

}
/// @nodoc
class _$ReconciliationTransactionCopyWithImpl<$Res>
    implements $ReconciliationTransactionCopyWith<$Res> {
  _$ReconciliationTransactionCopyWithImpl(this._self, this._then);

  final ReconciliationTransaction _self;
  final $Res Function(ReconciliationTransaction) _then;

/// Create a copy of ReconciliationTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? description = null,Object? amount = null,Object? date = null,Object? type = null,Object? category = freezed,}) {
  return _then(_self.copyWith(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,
  ));
}
/// Create a copy of ReconciliationTransaction
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


/// Adds pattern-matching-related methods to [ReconciliationTransaction].
extension ReconciliationTransactionPatterns on ReconciliationTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReconciliationTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReconciliationTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReconciliationTransaction value)  $default,){
final _that = this;
switch (_that) {
case _ReconciliationTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReconciliationTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _ReconciliationTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String description,  double amount, @DateTimeTwelvePmConverter()  DateTime date,  OrderType type,  CategoryModel? category)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReconciliationTransaction() when $default != null:
return $default(_that.description,_that.amount,_that.date,_that.type,_that.category);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String description,  double amount, @DateTimeTwelvePmConverter()  DateTime date,  OrderType type,  CategoryModel? category)  $default,) {final _that = this;
switch (_that) {
case _ReconciliationTransaction():
return $default(_that.description,_that.amount,_that.date,_that.type,_that.category);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String description,  double amount, @DateTimeTwelvePmConverter()  DateTime date,  OrderType type,  CategoryModel? category)?  $default,) {final _that = this;
switch (_that) {
case _ReconciliationTransaction() when $default != null:
return $default(_that.description,_that.amount,_that.date,_that.type,_that.category);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReconciliationTransaction implements ReconciliationTransaction {
  const _ReconciliationTransaction({required this.description, required this.amount, @DateTimeTwelvePmConverter() required this.date, required this.type, this.category});
  factory _ReconciliationTransaction.fromJson(Map<String, dynamic> json) => _$ReconciliationTransactionFromJson(json);

@override final  String description;
@override final  double amount;
@override@DateTimeTwelvePmConverter() final  DateTime date;
@override final  OrderType type;
// income or expense
@override final  CategoryModel? category;

/// Create a copy of ReconciliationTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReconciliationTransactionCopyWith<_ReconciliationTransaction> get copyWith => __$ReconciliationTransactionCopyWithImpl<_ReconciliationTransaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReconciliationTransactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReconciliationTransaction&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,amount,date,type,category);

@override
String toString() {
  return 'ReconciliationTransaction(description: $description, amount: $amount, date: $date, type: $type, category: $category)';
}


}

/// @nodoc
abstract mixin class _$ReconciliationTransactionCopyWith<$Res> implements $ReconciliationTransactionCopyWith<$Res> {
  factory _$ReconciliationTransactionCopyWith(_ReconciliationTransaction value, $Res Function(_ReconciliationTransaction) _then) = __$ReconciliationTransactionCopyWithImpl;
@override @useResult
$Res call({
 String description, double amount,@DateTimeTwelvePmConverter() DateTime date, OrderType type, CategoryModel? category
});


@override $CategoryModelCopyWith<$Res>? get category;

}
/// @nodoc
class __$ReconciliationTransactionCopyWithImpl<$Res>
    implements _$ReconciliationTransactionCopyWith<$Res> {
  __$ReconciliationTransactionCopyWithImpl(this._self, this._then);

  final _ReconciliationTransaction _self;
  final $Res Function(_ReconciliationTransaction) _then;

/// Create a copy of ReconciliationTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? description = null,Object? amount = null,Object? date = null,Object? type = null,Object? category = freezed,}) {
  return _then(_ReconciliationTransaction(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,
  ));
}

/// Create a copy of ReconciliationTransaction
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

/// @nodoc
mixin _$ReconciliationMatch {

 ReconciliationTransaction? get documentTransaction; InstallmentModel? get systemInstallment; OrderModel? get createdOrder; ReconciliationMatchStatus get status; String? get customDescription; CategoryModel? get customCategory; OrderType? get customType; String? get targetAccountId; int? get installmentCount;
/// Create a copy of ReconciliationMatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReconciliationMatchCopyWith<ReconciliationMatch> get copyWith => _$ReconciliationMatchCopyWithImpl<ReconciliationMatch>(this as ReconciliationMatch, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReconciliationMatch&&(identical(other.documentTransaction, documentTransaction) || other.documentTransaction == documentTransaction)&&(identical(other.systemInstallment, systemInstallment) || other.systemInstallment == systemInstallment)&&(identical(other.createdOrder, createdOrder) || other.createdOrder == createdOrder)&&(identical(other.status, status) || other.status == status)&&(identical(other.customDescription, customDescription) || other.customDescription == customDescription)&&(identical(other.customCategory, customCategory) || other.customCategory == customCategory)&&(identical(other.customType, customType) || other.customType == customType)&&(identical(other.targetAccountId, targetAccountId) || other.targetAccountId == targetAccountId)&&(identical(other.installmentCount, installmentCount) || other.installmentCount == installmentCount));
}


@override
int get hashCode => Object.hash(runtimeType,documentTransaction,systemInstallment,createdOrder,status,customDescription,customCategory,customType,targetAccountId,installmentCount);

@override
String toString() {
  return 'ReconciliationMatch(documentTransaction: $documentTransaction, systemInstallment: $systemInstallment, createdOrder: $createdOrder, status: $status, customDescription: $customDescription, customCategory: $customCategory, customType: $customType, targetAccountId: $targetAccountId, installmentCount: $installmentCount)';
}


}

/// @nodoc
abstract mixin class $ReconciliationMatchCopyWith<$Res>  {
  factory $ReconciliationMatchCopyWith(ReconciliationMatch value, $Res Function(ReconciliationMatch) _then) = _$ReconciliationMatchCopyWithImpl;
@useResult
$Res call({
 ReconciliationTransaction? documentTransaction, InstallmentModel? systemInstallment, OrderModel? createdOrder, ReconciliationMatchStatus status, String? customDescription, CategoryModel? customCategory, OrderType? customType, String? targetAccountId, int? installmentCount
});


$ReconciliationTransactionCopyWith<$Res>? get documentTransaction;$InstallmentModelCopyWith<$Res>? get systemInstallment;$OrderModelCopyWith<$Res>? get createdOrder;$CategoryModelCopyWith<$Res>? get customCategory;

}
/// @nodoc
class _$ReconciliationMatchCopyWithImpl<$Res>
    implements $ReconciliationMatchCopyWith<$Res> {
  _$ReconciliationMatchCopyWithImpl(this._self, this._then);

  final ReconciliationMatch _self;
  final $Res Function(ReconciliationMatch) _then;

/// Create a copy of ReconciliationMatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documentTransaction = freezed,Object? systemInstallment = freezed,Object? createdOrder = freezed,Object? status = null,Object? customDescription = freezed,Object? customCategory = freezed,Object? customType = freezed,Object? targetAccountId = freezed,Object? installmentCount = freezed,}) {
  return _then(_self.copyWith(
documentTransaction: freezed == documentTransaction ? _self.documentTransaction : documentTransaction // ignore: cast_nullable_to_non_nullable
as ReconciliationTransaction?,systemInstallment: freezed == systemInstallment ? _self.systemInstallment : systemInstallment // ignore: cast_nullable_to_non_nullable
as InstallmentModel?,createdOrder: freezed == createdOrder ? _self.createdOrder : createdOrder // ignore: cast_nullable_to_non_nullable
as OrderModel?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReconciliationMatchStatus,customDescription: freezed == customDescription ? _self.customDescription : customDescription // ignore: cast_nullable_to_non_nullable
as String?,customCategory: freezed == customCategory ? _self.customCategory : customCategory // ignore: cast_nullable_to_non_nullable
as CategoryModel?,customType: freezed == customType ? _self.customType : customType // ignore: cast_nullable_to_non_nullable
as OrderType?,targetAccountId: freezed == targetAccountId ? _self.targetAccountId : targetAccountId // ignore: cast_nullable_to_non_nullable
as String?,installmentCount: freezed == installmentCount ? _self.installmentCount : installmentCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of ReconciliationMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReconciliationTransactionCopyWith<$Res>? get documentTransaction {
    if (_self.documentTransaction == null) {
    return null;
  }

  return $ReconciliationTransactionCopyWith<$Res>(_self.documentTransaction!, (value) {
    return _then(_self.copyWith(documentTransaction: value));
  });
}/// Create a copy of ReconciliationMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstallmentModelCopyWith<$Res>? get systemInstallment {
    if (_self.systemInstallment == null) {
    return null;
  }

  return $InstallmentModelCopyWith<$Res>(_self.systemInstallment!, (value) {
    return _then(_self.copyWith(systemInstallment: value));
  });
}/// Create a copy of ReconciliationMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderModelCopyWith<$Res>? get createdOrder {
    if (_self.createdOrder == null) {
    return null;
  }

  return $OrderModelCopyWith<$Res>(_self.createdOrder!, (value) {
    return _then(_self.copyWith(createdOrder: value));
  });
}/// Create a copy of ReconciliationMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get customCategory {
    if (_self.customCategory == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.customCategory!, (value) {
    return _then(_self.copyWith(customCategory: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReconciliationMatch].
extension ReconciliationMatchPatterns on ReconciliationMatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReconciliationMatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReconciliationMatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReconciliationMatch value)  $default,){
final _that = this;
switch (_that) {
case _ReconciliationMatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReconciliationMatch value)?  $default,){
final _that = this;
switch (_that) {
case _ReconciliationMatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReconciliationTransaction? documentTransaction,  InstallmentModel? systemInstallment,  OrderModel? createdOrder,  ReconciliationMatchStatus status,  String? customDescription,  CategoryModel? customCategory,  OrderType? customType,  String? targetAccountId,  int? installmentCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReconciliationMatch() when $default != null:
return $default(_that.documentTransaction,_that.systemInstallment,_that.createdOrder,_that.status,_that.customDescription,_that.customCategory,_that.customType,_that.targetAccountId,_that.installmentCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReconciliationTransaction? documentTransaction,  InstallmentModel? systemInstallment,  OrderModel? createdOrder,  ReconciliationMatchStatus status,  String? customDescription,  CategoryModel? customCategory,  OrderType? customType,  String? targetAccountId,  int? installmentCount)  $default,) {final _that = this;
switch (_that) {
case _ReconciliationMatch():
return $default(_that.documentTransaction,_that.systemInstallment,_that.createdOrder,_that.status,_that.customDescription,_that.customCategory,_that.customType,_that.targetAccountId,_that.installmentCount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReconciliationTransaction? documentTransaction,  InstallmentModel? systemInstallment,  OrderModel? createdOrder,  ReconciliationMatchStatus status,  String? customDescription,  CategoryModel? customCategory,  OrderType? customType,  String? targetAccountId,  int? installmentCount)?  $default,) {final _that = this;
switch (_that) {
case _ReconciliationMatch() when $default != null:
return $default(_that.documentTransaction,_that.systemInstallment,_that.createdOrder,_that.status,_that.customDescription,_that.customCategory,_that.customType,_that.targetAccountId,_that.installmentCount);case _:
  return null;

}
}

}

/// @nodoc


class _ReconciliationMatch implements ReconciliationMatch {
  const _ReconciliationMatch({this.documentTransaction, this.systemInstallment, this.createdOrder, this.status = ReconciliationMatchStatus.unmatched, this.customDescription, this.customCategory, this.customType, this.targetAccountId, this.installmentCount});
  

@override final  ReconciliationTransaction? documentTransaction;
@override final  InstallmentModel? systemInstallment;
@override final  OrderModel? createdOrder;
@override@JsonKey() final  ReconciliationMatchStatus status;
@override final  String? customDescription;
@override final  CategoryModel? customCategory;
@override final  OrderType? customType;
@override final  String? targetAccountId;
@override final  int? installmentCount;

/// Create a copy of ReconciliationMatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReconciliationMatchCopyWith<_ReconciliationMatch> get copyWith => __$ReconciliationMatchCopyWithImpl<_ReconciliationMatch>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReconciliationMatch&&(identical(other.documentTransaction, documentTransaction) || other.documentTransaction == documentTransaction)&&(identical(other.systemInstallment, systemInstallment) || other.systemInstallment == systemInstallment)&&(identical(other.createdOrder, createdOrder) || other.createdOrder == createdOrder)&&(identical(other.status, status) || other.status == status)&&(identical(other.customDescription, customDescription) || other.customDescription == customDescription)&&(identical(other.customCategory, customCategory) || other.customCategory == customCategory)&&(identical(other.customType, customType) || other.customType == customType)&&(identical(other.targetAccountId, targetAccountId) || other.targetAccountId == targetAccountId)&&(identical(other.installmentCount, installmentCount) || other.installmentCount == installmentCount));
}


@override
int get hashCode => Object.hash(runtimeType,documentTransaction,systemInstallment,createdOrder,status,customDescription,customCategory,customType,targetAccountId,installmentCount);

@override
String toString() {
  return 'ReconciliationMatch(documentTransaction: $documentTransaction, systemInstallment: $systemInstallment, createdOrder: $createdOrder, status: $status, customDescription: $customDescription, customCategory: $customCategory, customType: $customType, targetAccountId: $targetAccountId, installmentCount: $installmentCount)';
}


}

/// @nodoc
abstract mixin class _$ReconciliationMatchCopyWith<$Res> implements $ReconciliationMatchCopyWith<$Res> {
  factory _$ReconciliationMatchCopyWith(_ReconciliationMatch value, $Res Function(_ReconciliationMatch) _then) = __$ReconciliationMatchCopyWithImpl;
@override @useResult
$Res call({
 ReconciliationTransaction? documentTransaction, InstallmentModel? systemInstallment, OrderModel? createdOrder, ReconciliationMatchStatus status, String? customDescription, CategoryModel? customCategory, OrderType? customType, String? targetAccountId, int? installmentCount
});


@override $ReconciliationTransactionCopyWith<$Res>? get documentTransaction;@override $InstallmentModelCopyWith<$Res>? get systemInstallment;@override $OrderModelCopyWith<$Res>? get createdOrder;@override $CategoryModelCopyWith<$Res>? get customCategory;

}
/// @nodoc
class __$ReconciliationMatchCopyWithImpl<$Res>
    implements _$ReconciliationMatchCopyWith<$Res> {
  __$ReconciliationMatchCopyWithImpl(this._self, this._then);

  final _ReconciliationMatch _self;
  final $Res Function(_ReconciliationMatch) _then;

/// Create a copy of ReconciliationMatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documentTransaction = freezed,Object? systemInstallment = freezed,Object? createdOrder = freezed,Object? status = null,Object? customDescription = freezed,Object? customCategory = freezed,Object? customType = freezed,Object? targetAccountId = freezed,Object? installmentCount = freezed,}) {
  return _then(_ReconciliationMatch(
documentTransaction: freezed == documentTransaction ? _self.documentTransaction : documentTransaction // ignore: cast_nullable_to_non_nullable
as ReconciliationTransaction?,systemInstallment: freezed == systemInstallment ? _self.systemInstallment : systemInstallment // ignore: cast_nullable_to_non_nullable
as InstallmentModel?,createdOrder: freezed == createdOrder ? _self.createdOrder : createdOrder // ignore: cast_nullable_to_non_nullable
as OrderModel?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReconciliationMatchStatus,customDescription: freezed == customDescription ? _self.customDescription : customDescription // ignore: cast_nullable_to_non_nullable
as String?,customCategory: freezed == customCategory ? _self.customCategory : customCategory // ignore: cast_nullable_to_non_nullable
as CategoryModel?,customType: freezed == customType ? _self.customType : customType // ignore: cast_nullable_to_non_nullable
as OrderType?,targetAccountId: freezed == targetAccountId ? _self.targetAccountId : targetAccountId // ignore: cast_nullable_to_non_nullable
as String?,installmentCount: freezed == installmentCount ? _self.installmentCount : installmentCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of ReconciliationMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReconciliationTransactionCopyWith<$Res>? get documentTransaction {
    if (_self.documentTransaction == null) {
    return null;
  }

  return $ReconciliationTransactionCopyWith<$Res>(_self.documentTransaction!, (value) {
    return _then(_self.copyWith(documentTransaction: value));
  });
}/// Create a copy of ReconciliationMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstallmentModelCopyWith<$Res>? get systemInstallment {
    if (_self.systemInstallment == null) {
    return null;
  }

  return $InstallmentModelCopyWith<$Res>(_self.systemInstallment!, (value) {
    return _then(_self.copyWith(systemInstallment: value));
  });
}/// Create a copy of ReconciliationMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderModelCopyWith<$Res>? get createdOrder {
    if (_self.createdOrder == null) {
    return null;
  }

  return $OrderModelCopyWith<$Res>(_self.createdOrder!, (value) {
    return _then(_self.copyWith(createdOrder: value));
  });
}/// Create a copy of ReconciliationMatch
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get customCategory {
    if (_self.customCategory == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.customCategory!, (value) {
    return _then(_self.copyWith(customCategory: value));
  });
}
}

// dart format on
