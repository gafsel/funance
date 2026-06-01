// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'installment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InstallmentModel {

 String get id; String get orderId; double get amount; String get description;@DateTimeTwelvePmConverter() DateTime get dueDate; double? get paidAmount;@DateTimeTwelvePmNullableConverter() DateTime? get paidDate; int? get installmentNumber; int? get installmentCount; InstallmentStatus get status; OrderType get type; InstallmentType get installmentType; Map<String, AccountImpact> get accounts; CategoryModel? get category; ReplicationCascade? get replicationCascade;
/// Create a copy of InstallmentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstallmentModelCopyWith<InstallmentModel> get copyWith => _$InstallmentModelCopyWithImpl<InstallmentModel>(this as InstallmentModel, _$identity);

  /// Serializes this InstallmentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstallmentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.description, description) || other.description == description)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.paidDate, paidDate) || other.paidDate == paidDate)&&(identical(other.installmentNumber, installmentNumber) || other.installmentNumber == installmentNumber)&&(identical(other.installmentCount, installmentCount) || other.installmentCount == installmentCount)&&(identical(other.status, status) || other.status == status)&&(identical(other.type, type) || other.type == type)&&(identical(other.installmentType, installmentType) || other.installmentType == installmentType)&&const DeepCollectionEquality().equals(other.accounts, accounts)&&(identical(other.category, category) || other.category == category)&&(identical(other.replicationCascade, replicationCascade) || other.replicationCascade == replicationCascade));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,amount,description,dueDate,paidAmount,paidDate,installmentNumber,installmentCount,status,type,installmentType,const DeepCollectionEquality().hash(accounts),category,replicationCascade);

@override
String toString() {
  return 'InstallmentModel(id: $id, orderId: $orderId, amount: $amount, description: $description, dueDate: $dueDate, paidAmount: $paidAmount, paidDate: $paidDate, installmentNumber: $installmentNumber, installmentCount: $installmentCount, status: $status, type: $type, installmentType: $installmentType, accounts: $accounts, category: $category, replicationCascade: $replicationCascade)';
}


}

/// @nodoc
abstract mixin class $InstallmentModelCopyWith<$Res>  {
  factory $InstallmentModelCopyWith(InstallmentModel value, $Res Function(InstallmentModel) _then) = _$InstallmentModelCopyWithImpl;
@useResult
$Res call({
 String id, String orderId, double amount, String description,@DateTimeTwelvePmConverter() DateTime dueDate, double? paidAmount,@DateTimeTwelvePmNullableConverter() DateTime? paidDate, int? installmentNumber, int? installmentCount, InstallmentStatus status, OrderType type, InstallmentType installmentType, Map<String, AccountImpact> accounts, CategoryModel? category, ReplicationCascade? replicationCascade
});


$CategoryModelCopyWith<$Res>? get category;

}
/// @nodoc
class _$InstallmentModelCopyWithImpl<$Res>
    implements $InstallmentModelCopyWith<$Res> {
  _$InstallmentModelCopyWithImpl(this._self, this._then);

  final InstallmentModel _self;
  final $Res Function(InstallmentModel) _then;

/// Create a copy of InstallmentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderId = null,Object? amount = null,Object? description = null,Object? dueDate = null,Object? paidAmount = freezed,Object? paidDate = freezed,Object? installmentNumber = freezed,Object? installmentCount = freezed,Object? status = null,Object? type = null,Object? installmentType = null,Object? accounts = null,Object? category = freezed,Object? replicationCascade = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,paidAmount: freezed == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as double?,paidDate: freezed == paidDate ? _self.paidDate : paidDate // ignore: cast_nullable_to_non_nullable
as DateTime?,installmentNumber: freezed == installmentNumber ? _self.installmentNumber : installmentNumber // ignore: cast_nullable_to_non_nullable
as int?,installmentCount: freezed == installmentCount ? _self.installmentCount : installmentCount // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstallmentStatus,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType,installmentType: null == installmentType ? _self.installmentType : installmentType // ignore: cast_nullable_to_non_nullable
as InstallmentType,accounts: null == accounts ? _self.accounts : accounts // ignore: cast_nullable_to_non_nullable
as Map<String, AccountImpact>,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,replicationCascade: freezed == replicationCascade ? _self.replicationCascade : replicationCascade // ignore: cast_nullable_to_non_nullable
as ReplicationCascade?,
  ));
}
/// Create a copy of InstallmentModel
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


/// Adds pattern-matching-related methods to [InstallmentModel].
extension InstallmentModelPatterns on InstallmentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstallmentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstallmentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstallmentModel value)  $default,){
final _that = this;
switch (_that) {
case _InstallmentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstallmentModel value)?  $default,){
final _that = this;
switch (_that) {
case _InstallmentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String orderId,  double amount,  String description, @DateTimeTwelvePmConverter()  DateTime dueDate,  double? paidAmount, @DateTimeTwelvePmNullableConverter()  DateTime? paidDate,  int? installmentNumber,  int? installmentCount,  InstallmentStatus status,  OrderType type,  InstallmentType installmentType,  Map<String, AccountImpact> accounts,  CategoryModel? category,  ReplicationCascade? replicationCascade)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstallmentModel() when $default != null:
return $default(_that.id,_that.orderId,_that.amount,_that.description,_that.dueDate,_that.paidAmount,_that.paidDate,_that.installmentNumber,_that.installmentCount,_that.status,_that.type,_that.installmentType,_that.accounts,_that.category,_that.replicationCascade);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String orderId,  double amount,  String description, @DateTimeTwelvePmConverter()  DateTime dueDate,  double? paidAmount, @DateTimeTwelvePmNullableConverter()  DateTime? paidDate,  int? installmentNumber,  int? installmentCount,  InstallmentStatus status,  OrderType type,  InstallmentType installmentType,  Map<String, AccountImpact> accounts,  CategoryModel? category,  ReplicationCascade? replicationCascade)  $default,) {final _that = this;
switch (_that) {
case _InstallmentModel():
return $default(_that.id,_that.orderId,_that.amount,_that.description,_that.dueDate,_that.paidAmount,_that.paidDate,_that.installmentNumber,_that.installmentCount,_that.status,_that.type,_that.installmentType,_that.accounts,_that.category,_that.replicationCascade);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String orderId,  double amount,  String description, @DateTimeTwelvePmConverter()  DateTime dueDate,  double? paidAmount, @DateTimeTwelvePmNullableConverter()  DateTime? paidDate,  int? installmentNumber,  int? installmentCount,  InstallmentStatus status,  OrderType type,  InstallmentType installmentType,  Map<String, AccountImpact> accounts,  CategoryModel? category,  ReplicationCascade? replicationCascade)?  $default,) {final _that = this;
switch (_that) {
case _InstallmentModel() when $default != null:
return $default(_that.id,_that.orderId,_that.amount,_that.description,_that.dueDate,_that.paidAmount,_that.paidDate,_that.installmentNumber,_that.installmentCount,_that.status,_that.type,_that.installmentType,_that.accounts,_that.category,_that.replicationCascade);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _InstallmentModel extends InstallmentModel {
  const _InstallmentModel({required this.id, required this.orderId, required this.amount, required this.description, @DateTimeTwelvePmConverter() required this.dueDate, this.paidAmount, @DateTimeTwelvePmNullableConverter() this.paidDate, this.installmentNumber, this.installmentCount, required this.status, required this.type, required this.installmentType, final  Map<String, AccountImpact> accounts = const {}, this.category, this.replicationCascade}): _accounts = accounts,super._();
  factory _InstallmentModel.fromJson(Map<String, dynamic> json) => _$InstallmentModelFromJson(json);

@override final  String id;
@override final  String orderId;
@override final  double amount;
@override final  String description;
@override@DateTimeTwelvePmConverter() final  DateTime dueDate;
@override final  double? paidAmount;
@override@DateTimeTwelvePmNullableConverter() final  DateTime? paidDate;
@override final  int? installmentNumber;
@override final  int? installmentCount;
@override final  InstallmentStatus status;
@override final  OrderType type;
@override final  InstallmentType installmentType;
 final  Map<String, AccountImpact> _accounts;
@override@JsonKey() Map<String, AccountImpact> get accounts {
  if (_accounts is EqualUnmodifiableMapView) return _accounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_accounts);
}

@override final  CategoryModel? category;
@override final  ReplicationCascade? replicationCascade;

/// Create a copy of InstallmentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstallmentModelCopyWith<_InstallmentModel> get copyWith => __$InstallmentModelCopyWithImpl<_InstallmentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstallmentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstallmentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.description, description) || other.description == description)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.paidDate, paidDate) || other.paidDate == paidDate)&&(identical(other.installmentNumber, installmentNumber) || other.installmentNumber == installmentNumber)&&(identical(other.installmentCount, installmentCount) || other.installmentCount == installmentCount)&&(identical(other.status, status) || other.status == status)&&(identical(other.type, type) || other.type == type)&&(identical(other.installmentType, installmentType) || other.installmentType == installmentType)&&const DeepCollectionEquality().equals(other._accounts, _accounts)&&(identical(other.category, category) || other.category == category)&&(identical(other.replicationCascade, replicationCascade) || other.replicationCascade == replicationCascade));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,amount,description,dueDate,paidAmount,paidDate,installmentNumber,installmentCount,status,type,installmentType,const DeepCollectionEquality().hash(_accounts),category,replicationCascade);

@override
String toString() {
  return 'InstallmentModel(id: $id, orderId: $orderId, amount: $amount, description: $description, dueDate: $dueDate, paidAmount: $paidAmount, paidDate: $paidDate, installmentNumber: $installmentNumber, installmentCount: $installmentCount, status: $status, type: $type, installmentType: $installmentType, accounts: $accounts, category: $category, replicationCascade: $replicationCascade)';
}


}

/// @nodoc
abstract mixin class _$InstallmentModelCopyWith<$Res> implements $InstallmentModelCopyWith<$Res> {
  factory _$InstallmentModelCopyWith(_InstallmentModel value, $Res Function(_InstallmentModel) _then) = __$InstallmentModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String orderId, double amount, String description,@DateTimeTwelvePmConverter() DateTime dueDate, double? paidAmount,@DateTimeTwelvePmNullableConverter() DateTime? paidDate, int? installmentNumber, int? installmentCount, InstallmentStatus status, OrderType type, InstallmentType installmentType, Map<String, AccountImpact> accounts, CategoryModel? category, ReplicationCascade? replicationCascade
});


@override $CategoryModelCopyWith<$Res>? get category;

}
/// @nodoc
class __$InstallmentModelCopyWithImpl<$Res>
    implements _$InstallmentModelCopyWith<$Res> {
  __$InstallmentModelCopyWithImpl(this._self, this._then);

  final _InstallmentModel _self;
  final $Res Function(_InstallmentModel) _then;

/// Create a copy of InstallmentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderId = null,Object? amount = null,Object? description = null,Object? dueDate = null,Object? paidAmount = freezed,Object? paidDate = freezed,Object? installmentNumber = freezed,Object? installmentCount = freezed,Object? status = null,Object? type = null,Object? installmentType = null,Object? accounts = null,Object? category = freezed,Object? replicationCascade = freezed,}) {
  return _then(_InstallmentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,paidAmount: freezed == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as double?,paidDate: freezed == paidDate ? _self.paidDate : paidDate // ignore: cast_nullable_to_non_nullable
as DateTime?,installmentNumber: freezed == installmentNumber ? _self.installmentNumber : installmentNumber // ignore: cast_nullable_to_non_nullable
as int?,installmentCount: freezed == installmentCount ? _self.installmentCount : installmentCount // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstallmentStatus,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType,installmentType: null == installmentType ? _self.installmentType : installmentType // ignore: cast_nullable_to_non_nullable
as InstallmentType,accounts: null == accounts ? _self._accounts : accounts // ignore: cast_nullable_to_non_nullable
as Map<String, AccountImpact>,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,replicationCascade: freezed == replicationCascade ? _self.replicationCascade : replicationCascade // ignore: cast_nullable_to_non_nullable
as ReplicationCascade?,
  ));
}

/// Create a copy of InstallmentModel
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
