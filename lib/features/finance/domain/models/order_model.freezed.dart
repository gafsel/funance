// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrderModel {

 String get id; double get amount; String get description; int get dueDay; String get startMonth; int? get installmentCount; InstallmentType get installmentType; OrderStatus get status; OrderType get type; InstallmentStatus? get installmentCreationStatus; Map<String, AccountImpact>? get accounts; CategoryModel? get category;
/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderModelCopyWith<OrderModel> get copyWith => _$OrderModelCopyWithImpl<OrderModel>(this as OrderModel, _$identity);

  /// Serializes this OrderModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderModel&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.description, description) || other.description == description)&&(identical(other.dueDay, dueDay) || other.dueDay == dueDay)&&(identical(other.startMonth, startMonth) || other.startMonth == startMonth)&&(identical(other.installmentCount, installmentCount) || other.installmentCount == installmentCount)&&(identical(other.installmentType, installmentType) || other.installmentType == installmentType)&&(identical(other.status, status) || other.status == status)&&(identical(other.type, type) || other.type == type)&&(identical(other.installmentCreationStatus, installmentCreationStatus) || other.installmentCreationStatus == installmentCreationStatus)&&const DeepCollectionEquality().equals(other.accounts, accounts)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,amount,description,dueDay,startMonth,installmentCount,installmentType,status,type,installmentCreationStatus,const DeepCollectionEquality().hash(accounts),category);

@override
String toString() {
  return 'OrderModel(id: $id, amount: $amount, description: $description, dueDay: $dueDay, startMonth: $startMonth, installmentCount: $installmentCount, installmentType: $installmentType, status: $status, type: $type, installmentCreationStatus: $installmentCreationStatus, accounts: $accounts, category: $category)';
}


}

/// @nodoc
abstract mixin class $OrderModelCopyWith<$Res>  {
  factory $OrderModelCopyWith(OrderModel value, $Res Function(OrderModel) _then) = _$OrderModelCopyWithImpl;
@useResult
$Res call({
 String id, double amount, String description, int dueDay, String startMonth, int? installmentCount, InstallmentType installmentType, OrderStatus status, OrderType type, InstallmentStatus? installmentCreationStatus, Map<String, AccountImpact>? accounts, CategoryModel? category
});


$CategoryModelCopyWith<$Res>? get category;

}
/// @nodoc
class _$OrderModelCopyWithImpl<$Res>
    implements $OrderModelCopyWith<$Res> {
  _$OrderModelCopyWithImpl(this._self, this._then);

  final OrderModel _self;
  final $Res Function(OrderModel) _then;

/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amount = null,Object? description = null,Object? dueDay = null,Object? startMonth = null,Object? installmentCount = freezed,Object? installmentType = null,Object? status = null,Object? type = null,Object? installmentCreationStatus = freezed,Object? accounts = freezed,Object? category = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,dueDay: null == dueDay ? _self.dueDay : dueDay // ignore: cast_nullable_to_non_nullable
as int,startMonth: null == startMonth ? _self.startMonth : startMonth // ignore: cast_nullable_to_non_nullable
as String,installmentCount: freezed == installmentCount ? _self.installmentCount : installmentCount // ignore: cast_nullable_to_non_nullable
as int?,installmentType: null == installmentType ? _self.installmentType : installmentType // ignore: cast_nullable_to_non_nullable
as InstallmentType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType,installmentCreationStatus: freezed == installmentCreationStatus ? _self.installmentCreationStatus : installmentCreationStatus // ignore: cast_nullable_to_non_nullable
as InstallmentStatus?,accounts: freezed == accounts ? _self.accounts : accounts // ignore: cast_nullable_to_non_nullable
as Map<String, AccountImpact>?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,
  ));
}
/// Create a copy of OrderModel
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


/// Adds pattern-matching-related methods to [OrderModel].
extension OrderModelPatterns on OrderModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderModel value)  $default,){
final _that = this;
switch (_that) {
case _OrderModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderModel value)?  $default,){
final _that = this;
switch (_that) {
case _OrderModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  double amount,  String description,  int dueDay,  String startMonth,  int? installmentCount,  InstallmentType installmentType,  OrderStatus status,  OrderType type,  InstallmentStatus? installmentCreationStatus,  Map<String, AccountImpact>? accounts,  CategoryModel? category)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderModel() when $default != null:
return $default(_that.id,_that.amount,_that.description,_that.dueDay,_that.startMonth,_that.installmentCount,_that.installmentType,_that.status,_that.type,_that.installmentCreationStatus,_that.accounts,_that.category);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  double amount,  String description,  int dueDay,  String startMonth,  int? installmentCount,  InstallmentType installmentType,  OrderStatus status,  OrderType type,  InstallmentStatus? installmentCreationStatus,  Map<String, AccountImpact>? accounts,  CategoryModel? category)  $default,) {final _that = this;
switch (_that) {
case _OrderModel():
return $default(_that.id,_that.amount,_that.description,_that.dueDay,_that.startMonth,_that.installmentCount,_that.installmentType,_that.status,_that.type,_that.installmentCreationStatus,_that.accounts,_that.category);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  double amount,  String description,  int dueDay,  String startMonth,  int? installmentCount,  InstallmentType installmentType,  OrderStatus status,  OrderType type,  InstallmentStatus? installmentCreationStatus,  Map<String, AccountImpact>? accounts,  CategoryModel? category)?  $default,) {final _that = this;
switch (_that) {
case _OrderModel() when $default != null:
return $default(_that.id,_that.amount,_that.description,_that.dueDay,_that.startMonth,_that.installmentCount,_that.installmentType,_that.status,_that.type,_that.installmentCreationStatus,_that.accounts,_that.category);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _OrderModel extends OrderModel {
  const _OrderModel({required this.id, required this.amount, required this.description, required this.dueDay, required this.startMonth, this.installmentCount, required this.installmentType, required this.status, required this.type, this.installmentCreationStatus, final  Map<String, AccountImpact>? accounts, this.category}): _accounts = accounts,super._();
  factory _OrderModel.fromJson(Map<String, dynamic> json) => _$OrderModelFromJson(json);

@override final  String id;
@override final  double amount;
@override final  String description;
@override final  int dueDay;
@override final  String startMonth;
@override final  int? installmentCount;
@override final  InstallmentType installmentType;
@override final  OrderStatus status;
@override final  OrderType type;
@override final  InstallmentStatus? installmentCreationStatus;
 final  Map<String, AccountImpact>? _accounts;
@override Map<String, AccountImpact>? get accounts {
  final value = _accounts;
  if (value == null) return null;
  if (_accounts is EqualUnmodifiableMapView) return _accounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  CategoryModel? category;

/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderModelCopyWith<_OrderModel> get copyWith => __$OrderModelCopyWithImpl<_OrderModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderModel&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.description, description) || other.description == description)&&(identical(other.dueDay, dueDay) || other.dueDay == dueDay)&&(identical(other.startMonth, startMonth) || other.startMonth == startMonth)&&(identical(other.installmentCount, installmentCount) || other.installmentCount == installmentCount)&&(identical(other.installmentType, installmentType) || other.installmentType == installmentType)&&(identical(other.status, status) || other.status == status)&&(identical(other.type, type) || other.type == type)&&(identical(other.installmentCreationStatus, installmentCreationStatus) || other.installmentCreationStatus == installmentCreationStatus)&&const DeepCollectionEquality().equals(other._accounts, _accounts)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,amount,description,dueDay,startMonth,installmentCount,installmentType,status,type,installmentCreationStatus,const DeepCollectionEquality().hash(_accounts),category);

@override
String toString() {
  return 'OrderModel(id: $id, amount: $amount, description: $description, dueDay: $dueDay, startMonth: $startMonth, installmentCount: $installmentCount, installmentType: $installmentType, status: $status, type: $type, installmentCreationStatus: $installmentCreationStatus, accounts: $accounts, category: $category)';
}


}

/// @nodoc
abstract mixin class _$OrderModelCopyWith<$Res> implements $OrderModelCopyWith<$Res> {
  factory _$OrderModelCopyWith(_OrderModel value, $Res Function(_OrderModel) _then) = __$OrderModelCopyWithImpl;
@override @useResult
$Res call({
 String id, double amount, String description, int dueDay, String startMonth, int? installmentCount, InstallmentType installmentType, OrderStatus status, OrderType type, InstallmentStatus? installmentCreationStatus, Map<String, AccountImpact>? accounts, CategoryModel? category
});


@override $CategoryModelCopyWith<$Res>? get category;

}
/// @nodoc
class __$OrderModelCopyWithImpl<$Res>
    implements _$OrderModelCopyWith<$Res> {
  __$OrderModelCopyWithImpl(this._self, this._then);

  final _OrderModel _self;
  final $Res Function(_OrderModel) _then;

/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amount = null,Object? description = null,Object? dueDay = null,Object? startMonth = null,Object? installmentCount = freezed,Object? installmentType = null,Object? status = null,Object? type = null,Object? installmentCreationStatus = freezed,Object? accounts = freezed,Object? category = freezed,}) {
  return _then(_OrderModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,dueDay: null == dueDay ? _self.dueDay : dueDay // ignore: cast_nullable_to_non_nullable
as int,startMonth: null == startMonth ? _self.startMonth : startMonth // ignore: cast_nullable_to_non_nullable
as String,installmentCount: freezed == installmentCount ? _self.installmentCount : installmentCount // ignore: cast_nullable_to_non_nullable
as int?,installmentType: null == installmentType ? _self.installmentType : installmentType // ignore: cast_nullable_to_non_nullable
as InstallmentType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType,installmentCreationStatus: freezed == installmentCreationStatus ? _self.installmentCreationStatus : installmentCreationStatus // ignore: cast_nullable_to_non_nullable
as InstallmentStatus?,accounts: freezed == accounts ? _self._accounts : accounts // ignore: cast_nullable_to_non_nullable
as Map<String, AccountImpact>?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,
  ));
}

/// Create a copy of OrderModel
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
