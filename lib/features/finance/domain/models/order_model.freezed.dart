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
OrderModel _$OrderModelFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'expense':
          return ExpenseOrder.fromJson(
            json
          );
                case 'income':
          return IncomeOrder.fromJson(
            json
          );
                case 'transfer':
          return TransferOrder.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'OrderModel',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$OrderModel {

 String get id; String get description; double get totalAmount; CategoryModel get category; int get installmentsCount; DateTime get date; OrderStatus get status; String? get planningId; bool? get isDeleted;
/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderModelCopyWith<OrderModel> get copyWith => _$OrderModelCopyWithImpl<OrderModel>(this as OrderModel, _$identity);

  /// Serializes this OrderModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderModel&&(identical(other.id, id) || other.id == id)&&(identical(other.description, description) || other.description == description)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.category, category) || other.category == category)&&(identical(other.installmentsCount, installmentsCount) || other.installmentsCount == installmentsCount)&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status)&&(identical(other.planningId, planningId) || other.planningId == planningId)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,description,totalAmount,category,installmentsCount,date,status,planningId,isDeleted);

@override
String toString() {
  return 'OrderModel(id: $id, description: $description, totalAmount: $totalAmount, category: $category, installmentsCount: $installmentsCount, date: $date, status: $status, planningId: $planningId, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class $OrderModelCopyWith<$Res>  {
  factory $OrderModelCopyWith(OrderModel value, $Res Function(OrderModel) _then) = _$OrderModelCopyWithImpl;
@useResult
$Res call({
 String id, String description, double totalAmount, CategoryModel category, int installmentsCount, DateTime date, OrderStatus status, String? planningId, bool isDeleted
});


$CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class _$OrderModelCopyWithImpl<$Res>
    implements $OrderModelCopyWith<$Res> {
  _$OrderModelCopyWithImpl(this._self, this._then);

  final OrderModel _self;
  final $Res Function(OrderModel) _then;

/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? description = null,Object? totalAmount = null,Object? category = null,Object? installmentsCount = null,Object? date = null,Object? status = null,Object? planningId = freezed,Object? isDeleted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,installmentsCount: null == installmentsCount ? _self.installmentsCount : installmentsCount // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,planningId: freezed == planningId ? _self.planningId : planningId // ignore: cast_nullable_to_non_nullable
as String?,isDeleted: null == isDeleted ? _self.isDeleted! : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ExpenseOrder value)?  expense,TResult Function( IncomeOrder value)?  income,TResult Function( TransferOrder value)?  transfer,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ExpenseOrder() when expense != null:
return expense(_that);case IncomeOrder() when income != null:
return income(_that);case TransferOrder() when transfer != null:
return transfer(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ExpenseOrder value)  expense,required TResult Function( IncomeOrder value)  income,required TResult Function( TransferOrder value)  transfer,}){
final _that = this;
switch (_that) {
case ExpenseOrder():
return expense(_that);case IncomeOrder():
return income(_that);case TransferOrder():
return transfer(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ExpenseOrder value)?  expense,TResult? Function( IncomeOrder value)?  income,TResult? Function( TransferOrder value)?  transfer,}){
final _that = this;
switch (_that) {
case ExpenseOrder() when expense != null:
return expense(_that);case IncomeOrder() when income != null:
return income(_that);case TransferOrder() when transfer != null:
return transfer(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String description,  double totalAmount,  CategoryModel category,  int installmentsCount,  DateTime date,  OrderStatus status,  String? planningId,  String? accountId,  bool? isDeleted)?  expense,TResult Function( String id,  String description,  double totalAmount,  CategoryModel category,  int installmentsCount,  DateTime date,  OrderStatus status,  String? planningId,  String? accountId,  bool? isDeleted)?  income,TResult Function( String id,  String description,  double totalAmount,  CategoryModel category,  int installmentsCount,  DateTime date,  OrderStatus status,  String? planningId,  String? fromAccountId,  String? toAccountId,  bool isDeleted)?  transfer,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ExpenseOrder() when expense != null:
return expense(_that.id,_that.description,_that.totalAmount,_that.category,_that.installmentsCount,_that.date,_that.status,_that.planningId,_that.accountId,_that.isDeleted);case IncomeOrder() when income != null:
return income(_that.id,_that.description,_that.totalAmount,_that.category,_that.installmentsCount,_that.date,_that.status,_that.planningId,_that.accountId,_that.isDeleted);case TransferOrder() when transfer != null:
return transfer(_that.id,_that.description,_that.totalAmount,_that.category,_that.installmentsCount,_that.date,_that.status,_that.planningId,_that.fromAccountId,_that.toAccountId,_that.isDeleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String description,  double totalAmount,  CategoryModel category,  int installmentsCount,  DateTime date,  OrderStatus status,  String? planningId,  String? accountId,  bool? isDeleted)  expense,required TResult Function( String id,  String description,  double totalAmount,  CategoryModel category,  int installmentsCount,  DateTime date,  OrderStatus status,  String? planningId,  String? accountId,  bool? isDeleted)  income,required TResult Function( String id,  String description,  double totalAmount,  CategoryModel category,  int installmentsCount,  DateTime date,  OrderStatus status,  String? planningId,  String? fromAccountId,  String? toAccountId,  bool isDeleted)  transfer,}) {final _that = this;
switch (_that) {
case ExpenseOrder():
return expense(_that.id,_that.description,_that.totalAmount,_that.category,_that.installmentsCount,_that.date,_that.status,_that.planningId,_that.accountId,_that.isDeleted);case IncomeOrder():
return income(_that.id,_that.description,_that.totalAmount,_that.category,_that.installmentsCount,_that.date,_that.status,_that.planningId,_that.accountId,_that.isDeleted);case TransferOrder():
return transfer(_that.id,_that.description,_that.totalAmount,_that.category,_that.installmentsCount,_that.date,_that.status,_that.planningId,_that.fromAccountId,_that.toAccountId,_that.isDeleted);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String description,  double totalAmount,  CategoryModel category,  int installmentsCount,  DateTime date,  OrderStatus status,  String? planningId,  String? accountId,  bool? isDeleted)?  expense,TResult? Function( String id,  String description,  double totalAmount,  CategoryModel category,  int installmentsCount,  DateTime date,  OrderStatus status,  String? planningId,  String? accountId,  bool? isDeleted)?  income,TResult? Function( String id,  String description,  double totalAmount,  CategoryModel category,  int installmentsCount,  DateTime date,  OrderStatus status,  String? planningId,  String? fromAccountId,  String? toAccountId,  bool isDeleted)?  transfer,}) {final _that = this;
switch (_that) {
case ExpenseOrder() when expense != null:
return expense(_that.id,_that.description,_that.totalAmount,_that.category,_that.installmentsCount,_that.date,_that.status,_that.planningId,_that.accountId,_that.isDeleted);case IncomeOrder() when income != null:
return income(_that.id,_that.description,_that.totalAmount,_that.category,_that.installmentsCount,_that.date,_that.status,_that.planningId,_that.accountId,_that.isDeleted);case TransferOrder() when transfer != null:
return transfer(_that.id,_that.description,_that.totalAmount,_that.category,_that.installmentsCount,_that.date,_that.status,_that.planningId,_that.fromAccountId,_that.toAccountId,_that.isDeleted);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class ExpenseOrder extends OrderModel {
  const ExpenseOrder({required this.id, required this.description, required this.totalAmount, required this.category, required this.installmentsCount, required this.date, required this.status, this.planningId, this.accountId, this.isDeleted, final  String? $type}): $type = $type ?? 'expense',super._();
  factory ExpenseOrder.fromJson(Map<String, dynamic> json) => _$ExpenseOrderFromJson(json);

@override final  String id;
@override final  String description;
@override final  double totalAmount;
@override final  CategoryModel category;
@override final  int installmentsCount;
@override final  DateTime date;
@override final  OrderStatus status;
@override final  String? planningId;
 final  String? accountId;
@override final  bool? isDeleted;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseOrderCopyWith<ExpenseOrder> get copyWith => _$ExpenseOrderCopyWithImpl<ExpenseOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpenseOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.description, description) || other.description == description)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.category, category) || other.category == category)&&(identical(other.installmentsCount, installmentsCount) || other.installmentsCount == installmentsCount)&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status)&&(identical(other.planningId, planningId) || other.planningId == planningId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,description,totalAmount,category,installmentsCount,date,status,planningId,accountId,isDeleted);

@override
String toString() {
  return 'OrderModel.expense(id: $id, description: $description, totalAmount: $totalAmount, category: $category, installmentsCount: $installmentsCount, date: $date, status: $status, planningId: $planningId, accountId: $accountId, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class $ExpenseOrderCopyWith<$Res> implements $OrderModelCopyWith<$Res> {
  factory $ExpenseOrderCopyWith(ExpenseOrder value, $Res Function(ExpenseOrder) _then) = _$ExpenseOrderCopyWithImpl;
@override @useResult
$Res call({
 String id, String description, double totalAmount, CategoryModel category, int installmentsCount, DateTime date, OrderStatus status, String? planningId, String? accountId, bool? isDeleted
});


@override $CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class _$ExpenseOrderCopyWithImpl<$Res>
    implements $ExpenseOrderCopyWith<$Res> {
  _$ExpenseOrderCopyWithImpl(this._self, this._then);

  final ExpenseOrder _self;
  final $Res Function(ExpenseOrder) _then;

/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? description = null,Object? totalAmount = null,Object? category = null,Object? installmentsCount = null,Object? date = null,Object? status = null,Object? planningId = freezed,Object? accountId = freezed,Object? isDeleted = freezed,}) {
  return _then(ExpenseOrder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,installmentsCount: null == installmentsCount ? _self.installmentsCount : installmentsCount // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,planningId: freezed == planningId ? _self.planningId : planningId // ignore: cast_nullable_to_non_nullable
as String?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,isDeleted: freezed == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class IncomeOrder extends OrderModel {
  const IncomeOrder({required this.id, required this.description, required this.totalAmount, required this.category, required this.installmentsCount, required this.date, required this.status, this.planningId, this.accountId, this.isDeleted, final  String? $type}): $type = $type ?? 'income',super._();
  factory IncomeOrder.fromJson(Map<String, dynamic> json) => _$IncomeOrderFromJson(json);

@override final  String id;
@override final  String description;
@override final  double totalAmount;
@override final  CategoryModel category;
@override final  int installmentsCount;
@override final  DateTime date;
@override final  OrderStatus status;
@override final  String? planningId;
 final  String? accountId;
@override final  bool? isDeleted;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncomeOrderCopyWith<IncomeOrder> get copyWith => _$IncomeOrderCopyWithImpl<IncomeOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IncomeOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IncomeOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.description, description) || other.description == description)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.category, category) || other.category == category)&&(identical(other.installmentsCount, installmentsCount) || other.installmentsCount == installmentsCount)&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status)&&(identical(other.planningId, planningId) || other.planningId == planningId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,description,totalAmount,category,installmentsCount,date,status,planningId,accountId,isDeleted);

@override
String toString() {
  return 'OrderModel.income(id: $id, description: $description, totalAmount: $totalAmount, category: $category, installmentsCount: $installmentsCount, date: $date, status: $status, planningId: $planningId, accountId: $accountId, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class $IncomeOrderCopyWith<$Res> implements $OrderModelCopyWith<$Res> {
  factory $IncomeOrderCopyWith(IncomeOrder value, $Res Function(IncomeOrder) _then) = _$IncomeOrderCopyWithImpl;
@override @useResult
$Res call({
 String id, String description, double totalAmount, CategoryModel category, int installmentsCount, DateTime date, OrderStatus status, String? planningId, String? accountId, bool? isDeleted
});


@override $CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class _$IncomeOrderCopyWithImpl<$Res>
    implements $IncomeOrderCopyWith<$Res> {
  _$IncomeOrderCopyWithImpl(this._self, this._then);

  final IncomeOrder _self;
  final $Res Function(IncomeOrder) _then;

/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? description = null,Object? totalAmount = null,Object? category = null,Object? installmentsCount = null,Object? date = null,Object? status = null,Object? planningId = freezed,Object? accountId = freezed,Object? isDeleted = freezed,}) {
  return _then(IncomeOrder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,installmentsCount: null == installmentsCount ? _self.installmentsCount : installmentsCount // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,planningId: freezed == planningId ? _self.planningId : planningId // ignore: cast_nullable_to_non_nullable
as String?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,isDeleted: freezed == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class TransferOrder extends OrderModel {
  const TransferOrder({required this.id, required this.description, required this.totalAmount, required this.category, required this.installmentsCount, required this.date, required this.status, this.planningId, this.fromAccountId, this.toAccountId, this.isDeleted = false, final  String? $type}): $type = $type ?? 'transfer',super._();
  factory TransferOrder.fromJson(Map<String, dynamic> json) => _$TransferOrderFromJson(json);

@override final  String id;
@override final  String description;
@override final  double totalAmount;
@override final  CategoryModel category;
@override final  int installmentsCount;
@override final  DateTime date;
@override final  OrderStatus status;
@override final  String? planningId;
 final  String? fromAccountId;
 final  String? toAccountId;
@override@JsonKey() final  bool isDeleted;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferOrderCopyWith<TransferOrder> get copyWith => _$TransferOrderCopyWithImpl<TransferOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransferOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.description, description) || other.description == description)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.category, category) || other.category == category)&&(identical(other.installmentsCount, installmentsCount) || other.installmentsCount == installmentsCount)&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status)&&(identical(other.planningId, planningId) || other.planningId == planningId)&&(identical(other.fromAccountId, fromAccountId) || other.fromAccountId == fromAccountId)&&(identical(other.toAccountId, toAccountId) || other.toAccountId == toAccountId)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,description,totalAmount,category,installmentsCount,date,status,planningId,fromAccountId,toAccountId,isDeleted);

@override
String toString() {
  return 'OrderModel.transfer(id: $id, description: $description, totalAmount: $totalAmount, category: $category, installmentsCount: $installmentsCount, date: $date, status: $status, planningId: $planningId, fromAccountId: $fromAccountId, toAccountId: $toAccountId, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class $TransferOrderCopyWith<$Res> implements $OrderModelCopyWith<$Res> {
  factory $TransferOrderCopyWith(TransferOrder value, $Res Function(TransferOrder) _then) = _$TransferOrderCopyWithImpl;
@override @useResult
$Res call({
 String id, String description, double totalAmount, CategoryModel category, int installmentsCount, DateTime date, OrderStatus status, String? planningId, String? fromAccountId, String? toAccountId, bool isDeleted
});


@override $CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class _$TransferOrderCopyWithImpl<$Res>
    implements $TransferOrderCopyWith<$Res> {
  _$TransferOrderCopyWithImpl(this._self, this._then);

  final TransferOrder _self;
  final $Res Function(TransferOrder) _then;

/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? description = null,Object? totalAmount = null,Object? category = null,Object? installmentsCount = null,Object? date = null,Object? status = null,Object? planningId = freezed,Object? fromAccountId = freezed,Object? toAccountId = freezed,Object? isDeleted = null,}) {
  return _then(TransferOrder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,installmentsCount: null == installmentsCount ? _self.installmentsCount : installmentsCount // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,planningId: freezed == planningId ? _self.planningId : planningId // ignore: cast_nullable_to_non_nullable
as String?,fromAccountId: freezed == fromAccountId ? _self.fromAccountId : fromAccountId // ignore: cast_nullable_to_non_nullable
as String?,toAccountId: freezed == toAccountId ? _self.toAccountId : toAccountId // ignore: cast_nullable_to_non_nullable
as String?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

// dart format on
