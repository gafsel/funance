// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'automatic_transaction_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AutomaticTransactionModel {

 String get id; String get description; double get amount; DateTime get date; OrderType get type; String? get originNotificationId;// Para evitar duplicidade
 String? get packageName;// App que originou a notificação
 String? get accountId; String? get categoryId; CategoryModel? get suggestedCategory; AccountModel? get suggestedAccount; bool get isConsolidated; bool get isIgnored; Map<String, dynamic>? get metadata;
/// Create a copy of AutomaticTransactionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutomaticTransactionModelCopyWith<AutomaticTransactionModel> get copyWith => _$AutomaticTransactionModelCopyWithImpl<AutomaticTransactionModel>(this as AutomaticTransactionModel, _$identity);

  /// Serializes this AutomaticTransactionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutomaticTransactionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&(identical(other.originNotificationId, originNotificationId) || other.originNotificationId == originNotificationId)&&(identical(other.packageName, packageName) || other.packageName == packageName)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.suggestedCategory, suggestedCategory) || other.suggestedCategory == suggestedCategory)&&(identical(other.suggestedAccount, suggestedAccount) || other.suggestedAccount == suggestedAccount)&&(identical(other.isConsolidated, isConsolidated) || other.isConsolidated == isConsolidated)&&(identical(other.isIgnored, isIgnored) || other.isIgnored == isIgnored)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,description,amount,date,type,originNotificationId,packageName,accountId,categoryId,suggestedCategory,suggestedAccount,isConsolidated,isIgnored,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'AutomaticTransactionModel(id: $id, description: $description, amount: $amount, date: $date, type: $type, originNotificationId: $originNotificationId, packageName: $packageName, accountId: $accountId, categoryId: $categoryId, suggestedCategory: $suggestedCategory, suggestedAccount: $suggestedAccount, isConsolidated: $isConsolidated, isIgnored: $isIgnored, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $AutomaticTransactionModelCopyWith<$Res>  {
  factory $AutomaticTransactionModelCopyWith(AutomaticTransactionModel value, $Res Function(AutomaticTransactionModel) _then) = _$AutomaticTransactionModelCopyWithImpl;
@useResult
$Res call({
 String id, String description, double amount, DateTime date, OrderType type, String? originNotificationId, String? packageName, String? accountId, String? categoryId, CategoryModel? suggestedCategory, AccountModel? suggestedAccount, bool isConsolidated, bool isIgnored, Map<String, dynamic>? metadata
});


$CategoryModelCopyWith<$Res>? get suggestedCategory;$AccountModelCopyWith<$Res>? get suggestedAccount;

}
/// @nodoc
class _$AutomaticTransactionModelCopyWithImpl<$Res>
    implements $AutomaticTransactionModelCopyWith<$Res> {
  _$AutomaticTransactionModelCopyWithImpl(this._self, this._then);

  final AutomaticTransactionModel _self;
  final $Res Function(AutomaticTransactionModel) _then;

/// Create a copy of AutomaticTransactionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? description = null,Object? amount = null,Object? date = null,Object? type = null,Object? originNotificationId = freezed,Object? packageName = freezed,Object? accountId = freezed,Object? categoryId = freezed,Object? suggestedCategory = freezed,Object? suggestedAccount = freezed,Object? isConsolidated = null,Object? isIgnored = null,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType,originNotificationId: freezed == originNotificationId ? _self.originNotificationId : originNotificationId // ignore: cast_nullable_to_non_nullable
as String?,packageName: freezed == packageName ? _self.packageName : packageName // ignore: cast_nullable_to_non_nullable
as String?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,suggestedCategory: freezed == suggestedCategory ? _self.suggestedCategory : suggestedCategory // ignore: cast_nullable_to_non_nullable
as CategoryModel?,suggestedAccount: freezed == suggestedAccount ? _self.suggestedAccount : suggestedAccount // ignore: cast_nullable_to_non_nullable
as AccountModel?,isConsolidated: null == isConsolidated ? _self.isConsolidated : isConsolidated // ignore: cast_nullable_to_non_nullable
as bool,isIgnored: null == isIgnored ? _self.isIgnored : isIgnored // ignore: cast_nullable_to_non_nullable
as bool,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}
/// Create a copy of AutomaticTransactionModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get suggestedCategory {
    if (_self.suggestedCategory == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.suggestedCategory!, (value) {
    return _then(_self.copyWith(suggestedCategory: value));
  });
}/// Create a copy of AutomaticTransactionModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountModelCopyWith<$Res>? get suggestedAccount {
    if (_self.suggestedAccount == null) {
    return null;
  }

  return $AccountModelCopyWith<$Res>(_self.suggestedAccount!, (value) {
    return _then(_self.copyWith(suggestedAccount: value));
  });
}
}


/// Adds pattern-matching-related methods to [AutomaticTransactionModel].
extension AutomaticTransactionModelPatterns on AutomaticTransactionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutomaticTransactionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutomaticTransactionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutomaticTransactionModel value)  $default,){
final _that = this;
switch (_that) {
case _AutomaticTransactionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutomaticTransactionModel value)?  $default,){
final _that = this;
switch (_that) {
case _AutomaticTransactionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String description,  double amount,  DateTime date,  OrderType type,  String? originNotificationId,  String? packageName,  String? accountId,  String? categoryId,  CategoryModel? suggestedCategory,  AccountModel? suggestedAccount,  bool isConsolidated,  bool isIgnored,  Map<String, dynamic>? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AutomaticTransactionModel() when $default != null:
return $default(_that.id,_that.description,_that.amount,_that.date,_that.type,_that.originNotificationId,_that.packageName,_that.accountId,_that.categoryId,_that.suggestedCategory,_that.suggestedAccount,_that.isConsolidated,_that.isIgnored,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String description,  double amount,  DateTime date,  OrderType type,  String? originNotificationId,  String? packageName,  String? accountId,  String? categoryId,  CategoryModel? suggestedCategory,  AccountModel? suggestedAccount,  bool isConsolidated,  bool isIgnored,  Map<String, dynamic>? metadata)  $default,) {final _that = this;
switch (_that) {
case _AutomaticTransactionModel():
return $default(_that.id,_that.description,_that.amount,_that.date,_that.type,_that.originNotificationId,_that.packageName,_that.accountId,_that.categoryId,_that.suggestedCategory,_that.suggestedAccount,_that.isConsolidated,_that.isIgnored,_that.metadata);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String description,  double amount,  DateTime date,  OrderType type,  String? originNotificationId,  String? packageName,  String? accountId,  String? categoryId,  CategoryModel? suggestedCategory,  AccountModel? suggestedAccount,  bool isConsolidated,  bool isIgnored,  Map<String, dynamic>? metadata)?  $default,) {final _that = this;
switch (_that) {
case _AutomaticTransactionModel() when $default != null:
return $default(_that.id,_that.description,_that.amount,_that.date,_that.type,_that.originNotificationId,_that.packageName,_that.accountId,_that.categoryId,_that.suggestedCategory,_that.suggestedAccount,_that.isConsolidated,_that.isIgnored,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AutomaticTransactionModel implements AutomaticTransactionModel {
  const _AutomaticTransactionModel({required this.id, required this.description, required this.amount, required this.date, required this.type, this.originNotificationId, this.packageName, this.accountId, this.categoryId, this.suggestedCategory, this.suggestedAccount, this.isConsolidated = false, this.isIgnored = false, final  Map<String, dynamic>? metadata}): _metadata = metadata;
  factory _AutomaticTransactionModel.fromJson(Map<String, dynamic> json) => _$AutomaticTransactionModelFromJson(json);

@override final  String id;
@override final  String description;
@override final  double amount;
@override final  DateTime date;
@override final  OrderType type;
@override final  String? originNotificationId;
// Para evitar duplicidade
@override final  String? packageName;
// App que originou a notificação
@override final  String? accountId;
@override final  String? categoryId;
@override final  CategoryModel? suggestedCategory;
@override final  AccountModel? suggestedAccount;
@override@JsonKey() final  bool isConsolidated;
@override@JsonKey() final  bool isIgnored;
 final  Map<String, dynamic>? _metadata;
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of AutomaticTransactionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutomaticTransactionModelCopyWith<_AutomaticTransactionModel> get copyWith => __$AutomaticTransactionModelCopyWithImpl<_AutomaticTransactionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AutomaticTransactionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutomaticTransactionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&(identical(other.originNotificationId, originNotificationId) || other.originNotificationId == originNotificationId)&&(identical(other.packageName, packageName) || other.packageName == packageName)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.suggestedCategory, suggestedCategory) || other.suggestedCategory == suggestedCategory)&&(identical(other.suggestedAccount, suggestedAccount) || other.suggestedAccount == suggestedAccount)&&(identical(other.isConsolidated, isConsolidated) || other.isConsolidated == isConsolidated)&&(identical(other.isIgnored, isIgnored) || other.isIgnored == isIgnored)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,description,amount,date,type,originNotificationId,packageName,accountId,categoryId,suggestedCategory,suggestedAccount,isConsolidated,isIgnored,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'AutomaticTransactionModel(id: $id, description: $description, amount: $amount, date: $date, type: $type, originNotificationId: $originNotificationId, packageName: $packageName, accountId: $accountId, categoryId: $categoryId, suggestedCategory: $suggestedCategory, suggestedAccount: $suggestedAccount, isConsolidated: $isConsolidated, isIgnored: $isIgnored, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$AutomaticTransactionModelCopyWith<$Res> implements $AutomaticTransactionModelCopyWith<$Res> {
  factory _$AutomaticTransactionModelCopyWith(_AutomaticTransactionModel value, $Res Function(_AutomaticTransactionModel) _then) = __$AutomaticTransactionModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String description, double amount, DateTime date, OrderType type, String? originNotificationId, String? packageName, String? accountId, String? categoryId, CategoryModel? suggestedCategory, AccountModel? suggestedAccount, bool isConsolidated, bool isIgnored, Map<String, dynamic>? metadata
});


@override $CategoryModelCopyWith<$Res>? get suggestedCategory;@override $AccountModelCopyWith<$Res>? get suggestedAccount;

}
/// @nodoc
class __$AutomaticTransactionModelCopyWithImpl<$Res>
    implements _$AutomaticTransactionModelCopyWith<$Res> {
  __$AutomaticTransactionModelCopyWithImpl(this._self, this._then);

  final _AutomaticTransactionModel _self;
  final $Res Function(_AutomaticTransactionModel) _then;

/// Create a copy of AutomaticTransactionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? description = null,Object? amount = null,Object? date = null,Object? type = null,Object? originNotificationId = freezed,Object? packageName = freezed,Object? accountId = freezed,Object? categoryId = freezed,Object? suggestedCategory = freezed,Object? suggestedAccount = freezed,Object? isConsolidated = null,Object? isIgnored = null,Object? metadata = freezed,}) {
  return _then(_AutomaticTransactionModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType,originNotificationId: freezed == originNotificationId ? _self.originNotificationId : originNotificationId // ignore: cast_nullable_to_non_nullable
as String?,packageName: freezed == packageName ? _self.packageName : packageName // ignore: cast_nullable_to_non_nullable
as String?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,suggestedCategory: freezed == suggestedCategory ? _self.suggestedCategory : suggestedCategory // ignore: cast_nullable_to_non_nullable
as CategoryModel?,suggestedAccount: freezed == suggestedAccount ? _self.suggestedAccount : suggestedAccount // ignore: cast_nullable_to_non_nullable
as AccountModel?,isConsolidated: null == isConsolidated ? _self.isConsolidated : isConsolidated // ignore: cast_nullable_to_non_nullable
as bool,isIgnored: null == isIgnored ? _self.isIgnored : isIgnored // ignore: cast_nullable_to_non_nullable
as bool,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

/// Create a copy of AutomaticTransactionModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get suggestedCategory {
    if (_self.suggestedCategory == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.suggestedCategory!, (value) {
    return _then(_self.copyWith(suggestedCategory: value));
  });
}/// Create a copy of AutomaticTransactionModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountModelCopyWith<$Res>? get suggestedAccount {
    if (_self.suggestedAccount == null) {
    return null;
  }

  return $AccountModelCopyWith<$Res>(_self.suggestedAccount!, (value) {
    return _then(_self.copyWith(suggestedAccount: value));
  });
}
}

// dart format on
