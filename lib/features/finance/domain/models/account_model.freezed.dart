// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NextInvoice {

/// Vencimento da fatura.
@TimestampOrIsoConverter() DateTime get dueDate;/// Fechamento que gerou esta fatura.
@TimestampOrIsoConverter() DateTime get closingDate;/// Primeira compra que pertence a esta fatura (inclusive).
@TimestampOrIsoConverter() DateTime get cycleStart;/// Última compra que pertence a esta fatura (inclusive).
@TimestampOrIsoConverter() DateTime get cycleEnd;/// Valor em aberto. Zero quando o ciclo ainda não tem compra nenhuma.
 double get amount;/// Id da order de fatura (`invoice-{accountId}-{YYYY-MM-DD}`).
 String get orderId;/// Parcela da fatura, ou `null` enquanto a fatura não existe de fato.
 String? get installmentId; InstallmentStatus get status;@TimestampOrIsoNullableConverter() DateTime? get updatedAt;
/// Create a copy of NextInvoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NextInvoiceCopyWith<NextInvoice> get copyWith => _$NextInvoiceCopyWithImpl<NextInvoice>(this as NextInvoice, _$identity);

  /// Serializes this NextInvoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NextInvoice&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.closingDate, closingDate) || other.closingDate == closingDate)&&(identical(other.cycleStart, cycleStart) || other.cycleStart == cycleStart)&&(identical(other.cycleEnd, cycleEnd) || other.cycleEnd == cycleEnd)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.installmentId, installmentId) || other.installmentId == installmentId)&&(identical(other.status, status) || other.status == status)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dueDate,closingDate,cycleStart,cycleEnd,amount,orderId,installmentId,status,updatedAt);

@override
String toString() {
  return 'NextInvoice(dueDate: $dueDate, closingDate: $closingDate, cycleStart: $cycleStart, cycleEnd: $cycleEnd, amount: $amount, orderId: $orderId, installmentId: $installmentId, status: $status, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $NextInvoiceCopyWith<$Res>  {
  factory $NextInvoiceCopyWith(NextInvoice value, $Res Function(NextInvoice) _then) = _$NextInvoiceCopyWithImpl;
@useResult
$Res call({
@TimestampOrIsoConverter() DateTime dueDate,@TimestampOrIsoConverter() DateTime closingDate,@TimestampOrIsoConverter() DateTime cycleStart,@TimestampOrIsoConverter() DateTime cycleEnd, double amount, String orderId, String? installmentId, InstallmentStatus status,@TimestampOrIsoNullableConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$NextInvoiceCopyWithImpl<$Res>
    implements $NextInvoiceCopyWith<$Res> {
  _$NextInvoiceCopyWithImpl(this._self, this._then);

  final NextInvoice _self;
  final $Res Function(NextInvoice) _then;

/// Create a copy of NextInvoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dueDate = null,Object? closingDate = null,Object? cycleStart = null,Object? cycleEnd = null,Object? amount = null,Object? orderId = null,Object? installmentId = freezed,Object? status = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,closingDate: null == closingDate ? _self.closingDate : closingDate // ignore: cast_nullable_to_non_nullable
as DateTime,cycleStart: null == cycleStart ? _self.cycleStart : cycleStart // ignore: cast_nullable_to_non_nullable
as DateTime,cycleEnd: null == cycleEnd ? _self.cycleEnd : cycleEnd // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,installmentId: freezed == installmentId ? _self.installmentId : installmentId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstallmentStatus,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [NextInvoice].
extension NextInvoicePatterns on NextInvoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NextInvoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NextInvoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NextInvoice value)  $default,){
final _that = this;
switch (_that) {
case _NextInvoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NextInvoice value)?  $default,){
final _that = this;
switch (_that) {
case _NextInvoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@TimestampOrIsoConverter()  DateTime dueDate, @TimestampOrIsoConverter()  DateTime closingDate, @TimestampOrIsoConverter()  DateTime cycleStart, @TimestampOrIsoConverter()  DateTime cycleEnd,  double amount,  String orderId,  String? installmentId,  InstallmentStatus status, @TimestampOrIsoNullableConverter()  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NextInvoice() when $default != null:
return $default(_that.dueDate,_that.closingDate,_that.cycleStart,_that.cycleEnd,_that.amount,_that.orderId,_that.installmentId,_that.status,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@TimestampOrIsoConverter()  DateTime dueDate, @TimestampOrIsoConverter()  DateTime closingDate, @TimestampOrIsoConverter()  DateTime cycleStart, @TimestampOrIsoConverter()  DateTime cycleEnd,  double amount,  String orderId,  String? installmentId,  InstallmentStatus status, @TimestampOrIsoNullableConverter()  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _NextInvoice():
return $default(_that.dueDate,_that.closingDate,_that.cycleStart,_that.cycleEnd,_that.amount,_that.orderId,_that.installmentId,_that.status,_that.updatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@TimestampOrIsoConverter()  DateTime dueDate, @TimestampOrIsoConverter()  DateTime closingDate, @TimestampOrIsoConverter()  DateTime cycleStart, @TimestampOrIsoConverter()  DateTime cycleEnd,  double amount,  String orderId,  String? installmentId,  InstallmentStatus status, @TimestampOrIsoNullableConverter()  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _NextInvoice() when $default != null:
return $default(_that.dueDate,_that.closingDate,_that.cycleStart,_that.cycleEnd,_that.amount,_that.orderId,_that.installmentId,_that.status,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NextInvoice extends NextInvoice {
  const _NextInvoice({@TimestampOrIsoConverter() required this.dueDate, @TimestampOrIsoConverter() required this.closingDate, @TimestampOrIsoConverter() required this.cycleStart, @TimestampOrIsoConverter() required this.cycleEnd, this.amount = 0.0, this.orderId = '', this.installmentId, this.status = InstallmentStatus.pending, @TimestampOrIsoNullableConverter() this.updatedAt}): super._();
  factory _NextInvoice.fromJson(Map<String, dynamic> json) => _$NextInvoiceFromJson(json);

/// Vencimento da fatura.
@override@TimestampOrIsoConverter() final  DateTime dueDate;
/// Fechamento que gerou esta fatura.
@override@TimestampOrIsoConverter() final  DateTime closingDate;
/// Primeira compra que pertence a esta fatura (inclusive).
@override@TimestampOrIsoConverter() final  DateTime cycleStart;
/// Última compra que pertence a esta fatura (inclusive).
@override@TimestampOrIsoConverter() final  DateTime cycleEnd;
/// Valor em aberto. Zero quando o ciclo ainda não tem compra nenhuma.
@override@JsonKey() final  double amount;
/// Id da order de fatura (`invoice-{accountId}-{YYYY-MM-DD}`).
@override@JsonKey() final  String orderId;
/// Parcela da fatura, ou `null` enquanto a fatura não existe de fato.
@override final  String? installmentId;
@override@JsonKey() final  InstallmentStatus status;
@override@TimestampOrIsoNullableConverter() final  DateTime? updatedAt;

/// Create a copy of NextInvoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NextInvoiceCopyWith<_NextInvoice> get copyWith => __$NextInvoiceCopyWithImpl<_NextInvoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NextInvoiceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NextInvoice&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.closingDate, closingDate) || other.closingDate == closingDate)&&(identical(other.cycleStart, cycleStart) || other.cycleStart == cycleStart)&&(identical(other.cycleEnd, cycleEnd) || other.cycleEnd == cycleEnd)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.installmentId, installmentId) || other.installmentId == installmentId)&&(identical(other.status, status) || other.status == status)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dueDate,closingDate,cycleStart,cycleEnd,amount,orderId,installmentId,status,updatedAt);

@override
String toString() {
  return 'NextInvoice(dueDate: $dueDate, closingDate: $closingDate, cycleStart: $cycleStart, cycleEnd: $cycleEnd, amount: $amount, orderId: $orderId, installmentId: $installmentId, status: $status, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$NextInvoiceCopyWith<$Res> implements $NextInvoiceCopyWith<$Res> {
  factory _$NextInvoiceCopyWith(_NextInvoice value, $Res Function(_NextInvoice) _then) = __$NextInvoiceCopyWithImpl;
@override @useResult
$Res call({
@TimestampOrIsoConverter() DateTime dueDate,@TimestampOrIsoConverter() DateTime closingDate,@TimestampOrIsoConverter() DateTime cycleStart,@TimestampOrIsoConverter() DateTime cycleEnd, double amount, String orderId, String? installmentId, InstallmentStatus status,@TimestampOrIsoNullableConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$NextInvoiceCopyWithImpl<$Res>
    implements _$NextInvoiceCopyWith<$Res> {
  __$NextInvoiceCopyWithImpl(this._self, this._then);

  final _NextInvoice _self;
  final $Res Function(_NextInvoice) _then;

/// Create a copy of NextInvoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dueDate = null,Object? closingDate = null,Object? cycleStart = null,Object? cycleEnd = null,Object? amount = null,Object? orderId = null,Object? installmentId = freezed,Object? status = null,Object? updatedAt = freezed,}) {
  return _then(_NextInvoice(
dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,closingDate: null == closingDate ? _self.closingDate : closingDate // ignore: cast_nullable_to_non_nullable
as DateTime,cycleStart: null == cycleStart ? _self.cycleStart : cycleStart // ignore: cast_nullable_to_non_nullable
as DateTime,cycleEnd: null == cycleEnd ? _self.cycleEnd : cycleEnd // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,installmentId: freezed == installmentId ? _self.installmentId : installmentId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstallmentStatus,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

AccountModel _$AccountModelFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'checking':
          return CheckingAccount.fromJson(
            json
          );
                case 'investment':
          return InvestmentAccount.fromJson(
            json
          );
                case 'creditCard':
          return CreditCardAccount.fromJson(
            json
          );
                case 'debt':
          return DebtAccount.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'AccountModel',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$AccountModel {

 String get id; String get name; String get icon; String get color; bool get isDeleted; double get initialBalance;@DateTimeTwelvePmConverter() DateTime get initialBalanceDate; BankLogo get bankLogo; List<String> get ownerIds;
/// Create a copy of AccountModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountModelCopyWith<AccountModel> get copyWith => _$AccountModelCopyWithImpl<AccountModel>(this as AccountModel, _$identity);

  /// Serializes this AccountModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.initialBalance, initialBalance) || other.initialBalance == initialBalance)&&(identical(other.initialBalanceDate, initialBalanceDate) || other.initialBalanceDate == initialBalanceDate)&&(identical(other.bankLogo, bankLogo) || other.bankLogo == bankLogo)&&const DeepCollectionEquality().equals(other.ownerIds, ownerIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,icon,color,isDeleted,initialBalance,initialBalanceDate,bankLogo,const DeepCollectionEquality().hash(ownerIds));

@override
String toString() {
  return 'AccountModel(id: $id, name: $name, icon: $icon, color: $color, isDeleted: $isDeleted, initialBalance: $initialBalance, initialBalanceDate: $initialBalanceDate, bankLogo: $bankLogo, ownerIds: $ownerIds)';
}


}

/// @nodoc
abstract mixin class $AccountModelCopyWith<$Res>  {
  factory $AccountModelCopyWith(AccountModel value, $Res Function(AccountModel) _then) = _$AccountModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String icon, String color, bool isDeleted, double initialBalance,@DateTimeTwelvePmConverter() DateTime initialBalanceDate, BankLogo bankLogo, List<String> ownerIds
});




}
/// @nodoc
class _$AccountModelCopyWithImpl<$Res>
    implements $AccountModelCopyWith<$Res> {
  _$AccountModelCopyWithImpl(this._self, this._then);

  final AccountModel _self;
  final $Res Function(AccountModel) _then;

/// Create a copy of AccountModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? color = null,Object? isDeleted = null,Object? initialBalance = null,Object? initialBalanceDate = null,Object? bankLogo = null,Object? ownerIds = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,initialBalance: null == initialBalance ? _self.initialBalance : initialBalance // ignore: cast_nullable_to_non_nullable
as double,initialBalanceDate: null == initialBalanceDate ? _self.initialBalanceDate : initialBalanceDate // ignore: cast_nullable_to_non_nullable
as DateTime,bankLogo: null == bankLogo ? _self.bankLogo : bankLogo // ignore: cast_nullable_to_non_nullable
as BankLogo,ownerIds: null == ownerIds ? _self.ownerIds : ownerIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountModel].
extension AccountModelPatterns on AccountModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CheckingAccount value)?  checking,TResult Function( InvestmentAccount value)?  investment,TResult Function( CreditCardAccount value)?  creditCard,TResult Function( DebtAccount value)?  debt,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CheckingAccount() when checking != null:
return checking(_that);case InvestmentAccount() when investment != null:
return investment(_that);case CreditCardAccount() when creditCard != null:
return creditCard(_that);case DebtAccount() when debt != null:
return debt(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CheckingAccount value)  checking,required TResult Function( InvestmentAccount value)  investment,required TResult Function( CreditCardAccount value)  creditCard,required TResult Function( DebtAccount value)  debt,}){
final _that = this;
switch (_that) {
case CheckingAccount():
return checking(_that);case InvestmentAccount():
return investment(_that);case CreditCardAccount():
return creditCard(_that);case DebtAccount():
return debt(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CheckingAccount value)?  checking,TResult? Function( InvestmentAccount value)?  investment,TResult? Function( CreditCardAccount value)?  creditCard,TResult? Function( DebtAccount value)?  debt,}){
final _that = this;
switch (_that) {
case CheckingAccount() when checking != null:
return checking(_that);case InvestmentAccount() when investment != null:
return investment(_that);case CreditCardAccount() when creditCard != null:
return creditCard(_that);case DebtAccount() when debt != null:
return debt(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance, @DateTimeTwelvePmConverter()  DateTime initialBalanceDate,  BankLogo bankLogo,  List<String> ownerIds)?  checking,TResult Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance, @DateTimeTwelvePmConverter()  DateTime initialBalanceDate,  double interestRate,  BankLogo bankLogo,  List<String> ownerIds)?  investment,TResult Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance, @DateTimeTwelvePmConverter()  DateTime initialBalanceDate,  double limit,  int dueDay,  int closingDay,  BankLogo bankLogo,  List<String> ownerIds, @JsonKey(includeToJson: false)  NextInvoice? nextInvoice)?  creditCard,TResult Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance, @DateTimeTwelvePmConverter()  DateTime initialBalanceDate,  double interestRate,  BankLogo bankLogo,  List<String> ownerIds)?  debt,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CheckingAccount() when checking != null:
return checking(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.bankLogo,_that.ownerIds);case InvestmentAccount() when investment != null:
return investment(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.interestRate,_that.bankLogo,_that.ownerIds);case CreditCardAccount() when creditCard != null:
return creditCard(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.limit,_that.dueDay,_that.closingDay,_that.bankLogo,_that.ownerIds,_that.nextInvoice);case DebtAccount() when debt != null:
return debt(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.interestRate,_that.bankLogo,_that.ownerIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance, @DateTimeTwelvePmConverter()  DateTime initialBalanceDate,  BankLogo bankLogo,  List<String> ownerIds)  checking,required TResult Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance, @DateTimeTwelvePmConverter()  DateTime initialBalanceDate,  double interestRate,  BankLogo bankLogo,  List<String> ownerIds)  investment,required TResult Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance, @DateTimeTwelvePmConverter()  DateTime initialBalanceDate,  double limit,  int dueDay,  int closingDay,  BankLogo bankLogo,  List<String> ownerIds, @JsonKey(includeToJson: false)  NextInvoice? nextInvoice)  creditCard,required TResult Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance, @DateTimeTwelvePmConverter()  DateTime initialBalanceDate,  double interestRate,  BankLogo bankLogo,  List<String> ownerIds)  debt,}) {final _that = this;
switch (_that) {
case CheckingAccount():
return checking(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.bankLogo,_that.ownerIds);case InvestmentAccount():
return investment(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.interestRate,_that.bankLogo,_that.ownerIds);case CreditCardAccount():
return creditCard(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.limit,_that.dueDay,_that.closingDay,_that.bankLogo,_that.ownerIds,_that.nextInvoice);case DebtAccount():
return debt(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.interestRate,_that.bankLogo,_that.ownerIds);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance, @DateTimeTwelvePmConverter()  DateTime initialBalanceDate,  BankLogo bankLogo,  List<String> ownerIds)?  checking,TResult? Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance, @DateTimeTwelvePmConverter()  DateTime initialBalanceDate,  double interestRate,  BankLogo bankLogo,  List<String> ownerIds)?  investment,TResult? Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance, @DateTimeTwelvePmConverter()  DateTime initialBalanceDate,  double limit,  int dueDay,  int closingDay,  BankLogo bankLogo,  List<String> ownerIds, @JsonKey(includeToJson: false)  NextInvoice? nextInvoice)?  creditCard,TResult? Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance, @DateTimeTwelvePmConverter()  DateTime initialBalanceDate,  double interestRate,  BankLogo bankLogo,  List<String> ownerIds)?  debt,}) {final _that = this;
switch (_that) {
case CheckingAccount() when checking != null:
return checking(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.bankLogo,_that.ownerIds);case InvestmentAccount() when investment != null:
return investment(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.interestRate,_that.bankLogo,_that.ownerIds);case CreditCardAccount() when creditCard != null:
return creditCard(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.limit,_that.dueDay,_that.closingDay,_that.bankLogo,_that.ownerIds,_that.nextInvoice);case DebtAccount() when debt != null:
return debt(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.interestRate,_that.bankLogo,_that.ownerIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class CheckingAccount extends AccountModel {
  const CheckingAccount({required this.id, required this.name, required this.icon, required this.color, this.isDeleted = false, this.initialBalance = 0.0, @DateTimeTwelvePmConverter() required this.initialBalanceDate, this.bankLogo = BankLogo.none, final  List<String> ownerIds = const [], final  String? $type}): _ownerIds = ownerIds,$type = $type ?? 'checking',super._();
  factory CheckingAccount.fromJson(Map<String, dynamic> json) => _$CheckingAccountFromJson(json);

@override final  String id;
@override final  String name;
@override final  String icon;
@override final  String color;
@override@JsonKey() final  bool isDeleted;
@override@JsonKey() final  double initialBalance;
@override@DateTimeTwelvePmConverter() final  DateTime initialBalanceDate;
@override@JsonKey() final  BankLogo bankLogo;
 final  List<String> _ownerIds;
@override@JsonKey() List<String> get ownerIds {
  if (_ownerIds is EqualUnmodifiableListView) return _ownerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ownerIds);
}


@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of AccountModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckingAccountCopyWith<CheckingAccount> get copyWith => _$CheckingAccountCopyWithImpl<CheckingAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckingAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckingAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.initialBalance, initialBalance) || other.initialBalance == initialBalance)&&(identical(other.initialBalanceDate, initialBalanceDate) || other.initialBalanceDate == initialBalanceDate)&&(identical(other.bankLogo, bankLogo) || other.bankLogo == bankLogo)&&const DeepCollectionEquality().equals(other._ownerIds, _ownerIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,icon,color,isDeleted,initialBalance,initialBalanceDate,bankLogo,const DeepCollectionEquality().hash(_ownerIds));

@override
String toString() {
  return 'AccountModel.checking(id: $id, name: $name, icon: $icon, color: $color, isDeleted: $isDeleted, initialBalance: $initialBalance, initialBalanceDate: $initialBalanceDate, bankLogo: $bankLogo, ownerIds: $ownerIds)';
}


}

/// @nodoc
abstract mixin class $CheckingAccountCopyWith<$Res> implements $AccountModelCopyWith<$Res> {
  factory $CheckingAccountCopyWith(CheckingAccount value, $Res Function(CheckingAccount) _then) = _$CheckingAccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String icon, String color, bool isDeleted, double initialBalance,@DateTimeTwelvePmConverter() DateTime initialBalanceDate, BankLogo bankLogo, List<String> ownerIds
});




}
/// @nodoc
class _$CheckingAccountCopyWithImpl<$Res>
    implements $CheckingAccountCopyWith<$Res> {
  _$CheckingAccountCopyWithImpl(this._self, this._then);

  final CheckingAccount _self;
  final $Res Function(CheckingAccount) _then;

/// Create a copy of AccountModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? color = null,Object? isDeleted = null,Object? initialBalance = null,Object? initialBalanceDate = null,Object? bankLogo = null,Object? ownerIds = null,}) {
  return _then(CheckingAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,initialBalance: null == initialBalance ? _self.initialBalance : initialBalance // ignore: cast_nullable_to_non_nullable
as double,initialBalanceDate: null == initialBalanceDate ? _self.initialBalanceDate : initialBalanceDate // ignore: cast_nullable_to_non_nullable
as DateTime,bankLogo: null == bankLogo ? _self.bankLogo : bankLogo // ignore: cast_nullable_to_non_nullable
as BankLogo,ownerIds: null == ownerIds ? _self._ownerIds : ownerIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class InvestmentAccount extends AccountModel {
  const InvestmentAccount({required this.id, required this.name, required this.icon, required this.color, this.isDeleted = false, this.initialBalance = 0.0, @DateTimeTwelvePmConverter() required this.initialBalanceDate, required this.interestRate, this.bankLogo = BankLogo.none, final  List<String> ownerIds = const [], final  String? $type}): _ownerIds = ownerIds,$type = $type ?? 'investment',super._();
  factory InvestmentAccount.fromJson(Map<String, dynamic> json) => _$InvestmentAccountFromJson(json);

@override final  String id;
@override final  String name;
@override final  String icon;
@override final  String color;
@override@JsonKey() final  bool isDeleted;
@override@JsonKey() final  double initialBalance;
@override@DateTimeTwelvePmConverter() final  DateTime initialBalanceDate;
 final  double interestRate;
@override@JsonKey() final  BankLogo bankLogo;
 final  List<String> _ownerIds;
@override@JsonKey() List<String> get ownerIds {
  if (_ownerIds is EqualUnmodifiableListView) return _ownerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ownerIds);
}


@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of AccountModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestmentAccountCopyWith<InvestmentAccount> get copyWith => _$InvestmentAccountCopyWithImpl<InvestmentAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvestmentAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.initialBalance, initialBalance) || other.initialBalance == initialBalance)&&(identical(other.initialBalanceDate, initialBalanceDate) || other.initialBalanceDate == initialBalanceDate)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate)&&(identical(other.bankLogo, bankLogo) || other.bankLogo == bankLogo)&&const DeepCollectionEquality().equals(other._ownerIds, _ownerIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,icon,color,isDeleted,initialBalance,initialBalanceDate,interestRate,bankLogo,const DeepCollectionEquality().hash(_ownerIds));

@override
String toString() {
  return 'AccountModel.investment(id: $id, name: $name, icon: $icon, color: $color, isDeleted: $isDeleted, initialBalance: $initialBalance, initialBalanceDate: $initialBalanceDate, interestRate: $interestRate, bankLogo: $bankLogo, ownerIds: $ownerIds)';
}


}

/// @nodoc
abstract mixin class $InvestmentAccountCopyWith<$Res> implements $AccountModelCopyWith<$Res> {
  factory $InvestmentAccountCopyWith(InvestmentAccount value, $Res Function(InvestmentAccount) _then) = _$InvestmentAccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String icon, String color, bool isDeleted, double initialBalance,@DateTimeTwelvePmConverter() DateTime initialBalanceDate, double interestRate, BankLogo bankLogo, List<String> ownerIds
});




}
/// @nodoc
class _$InvestmentAccountCopyWithImpl<$Res>
    implements $InvestmentAccountCopyWith<$Res> {
  _$InvestmentAccountCopyWithImpl(this._self, this._then);

  final InvestmentAccount _self;
  final $Res Function(InvestmentAccount) _then;

/// Create a copy of AccountModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? color = null,Object? isDeleted = null,Object? initialBalance = null,Object? initialBalanceDate = null,Object? interestRate = null,Object? bankLogo = null,Object? ownerIds = null,}) {
  return _then(InvestmentAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,initialBalance: null == initialBalance ? _self.initialBalance : initialBalance // ignore: cast_nullable_to_non_nullable
as double,initialBalanceDate: null == initialBalanceDate ? _self.initialBalanceDate : initialBalanceDate // ignore: cast_nullable_to_non_nullable
as DateTime,interestRate: null == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double,bankLogo: null == bankLogo ? _self.bankLogo : bankLogo // ignore: cast_nullable_to_non_nullable
as BankLogo,ownerIds: null == ownerIds ? _self._ownerIds : ownerIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CreditCardAccount extends AccountModel {
  const CreditCardAccount({required this.id, required this.name, required this.icon, required this.color, this.isDeleted = false, this.initialBalance = 0.0, @DateTimeTwelvePmConverter() required this.initialBalanceDate, required this.limit, required this.dueDay, required this.closingDay, this.bankLogo = BankLogo.none, final  List<String> ownerIds = const [], @JsonKey(includeToJson: false) this.nextInvoice, final  String? $type}): _ownerIds = ownerIds,$type = $type ?? 'creditCard',super._();
  factory CreditCardAccount.fromJson(Map<String, dynamic> json) => _$CreditCardAccountFromJson(json);

@override final  String id;
@override final  String name;
@override final  String icon;
@override final  String color;
@override@JsonKey() final  bool isDeleted;
@override@JsonKey() final  double initialBalance;
@override@DateTimeTwelvePmConverter() final  DateTime initialBalanceDate;
 final  double limit;
 final  int dueDay;
 final  int closingDay;
@override@JsonKey() final  BankLogo bankLogo;
 final  List<String> _ownerIds;
@override@JsonKey() List<String> get ownerIds {
  if (_ownerIds is EqualUnmodifiableListView) return _ownerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ownerIds);
}

// Somente leitura: escrito pelo servidor e negado ao cliente pelas rules.
@JsonKey(includeToJson: false) final  NextInvoice? nextInvoice;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of AccountModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreditCardAccountCopyWith<CreditCardAccount> get copyWith => _$CreditCardAccountCopyWithImpl<CreditCardAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreditCardAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreditCardAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.initialBalance, initialBalance) || other.initialBalance == initialBalance)&&(identical(other.initialBalanceDate, initialBalanceDate) || other.initialBalanceDate == initialBalanceDate)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.dueDay, dueDay) || other.dueDay == dueDay)&&(identical(other.closingDay, closingDay) || other.closingDay == closingDay)&&(identical(other.bankLogo, bankLogo) || other.bankLogo == bankLogo)&&const DeepCollectionEquality().equals(other._ownerIds, _ownerIds)&&(identical(other.nextInvoice, nextInvoice) || other.nextInvoice == nextInvoice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,icon,color,isDeleted,initialBalance,initialBalanceDate,limit,dueDay,closingDay,bankLogo,const DeepCollectionEquality().hash(_ownerIds),nextInvoice);

@override
String toString() {
  return 'AccountModel.creditCard(id: $id, name: $name, icon: $icon, color: $color, isDeleted: $isDeleted, initialBalance: $initialBalance, initialBalanceDate: $initialBalanceDate, limit: $limit, dueDay: $dueDay, closingDay: $closingDay, bankLogo: $bankLogo, ownerIds: $ownerIds, nextInvoice: $nextInvoice)';
}


}

/// @nodoc
abstract mixin class $CreditCardAccountCopyWith<$Res> implements $AccountModelCopyWith<$Res> {
  factory $CreditCardAccountCopyWith(CreditCardAccount value, $Res Function(CreditCardAccount) _then) = _$CreditCardAccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String icon, String color, bool isDeleted, double initialBalance,@DateTimeTwelvePmConverter() DateTime initialBalanceDate, double limit, int dueDay, int closingDay, BankLogo bankLogo, List<String> ownerIds,@JsonKey(includeToJson: false) NextInvoice? nextInvoice
});


$NextInvoiceCopyWith<$Res>? get nextInvoice;

}
/// @nodoc
class _$CreditCardAccountCopyWithImpl<$Res>
    implements $CreditCardAccountCopyWith<$Res> {
  _$CreditCardAccountCopyWithImpl(this._self, this._then);

  final CreditCardAccount _self;
  final $Res Function(CreditCardAccount) _then;

/// Create a copy of AccountModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? color = null,Object? isDeleted = null,Object? initialBalance = null,Object? initialBalanceDate = null,Object? limit = null,Object? dueDay = null,Object? closingDay = null,Object? bankLogo = null,Object? ownerIds = null,Object? nextInvoice = freezed,}) {
  return _then(CreditCardAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,initialBalance: null == initialBalance ? _self.initialBalance : initialBalance // ignore: cast_nullable_to_non_nullable
as double,initialBalanceDate: null == initialBalanceDate ? _self.initialBalanceDate : initialBalanceDate // ignore: cast_nullable_to_non_nullable
as DateTime,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as double,dueDay: null == dueDay ? _self.dueDay : dueDay // ignore: cast_nullable_to_non_nullable
as int,closingDay: null == closingDay ? _self.closingDay : closingDay // ignore: cast_nullable_to_non_nullable
as int,bankLogo: null == bankLogo ? _self.bankLogo : bankLogo // ignore: cast_nullable_to_non_nullable
as BankLogo,ownerIds: null == ownerIds ? _self._ownerIds : ownerIds // ignore: cast_nullable_to_non_nullable
as List<String>,nextInvoice: freezed == nextInvoice ? _self.nextInvoice : nextInvoice // ignore: cast_nullable_to_non_nullable
as NextInvoice?,
  ));
}

/// Create a copy of AccountModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NextInvoiceCopyWith<$Res>? get nextInvoice {
    if (_self.nextInvoice == null) {
    return null;
  }

  return $NextInvoiceCopyWith<$Res>(_self.nextInvoice!, (value) {
    return _then(_self.copyWith(nextInvoice: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class DebtAccount extends AccountModel {
  const DebtAccount({required this.id, required this.name, required this.icon, required this.color, this.isDeleted = false, this.initialBalance = 0.0, @DateTimeTwelvePmConverter() required this.initialBalanceDate, required this.interestRate, this.bankLogo = BankLogo.none, final  List<String> ownerIds = const [], final  String? $type}): _ownerIds = ownerIds,$type = $type ?? 'debt',super._();
  factory DebtAccount.fromJson(Map<String, dynamic> json) => _$DebtAccountFromJson(json);

@override final  String id;
@override final  String name;
@override final  String icon;
@override final  String color;
@override@JsonKey() final  bool isDeleted;
@override@JsonKey() final  double initialBalance;
@override@DateTimeTwelvePmConverter() final  DateTime initialBalanceDate;
 final  double interestRate;
@override@JsonKey() final  BankLogo bankLogo;
 final  List<String> _ownerIds;
@override@JsonKey() List<String> get ownerIds {
  if (_ownerIds is EqualUnmodifiableListView) return _ownerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ownerIds);
}


@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of AccountModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebtAccountCopyWith<DebtAccount> get copyWith => _$DebtAccountCopyWithImpl<DebtAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DebtAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DebtAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.initialBalance, initialBalance) || other.initialBalance == initialBalance)&&(identical(other.initialBalanceDate, initialBalanceDate) || other.initialBalanceDate == initialBalanceDate)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate)&&(identical(other.bankLogo, bankLogo) || other.bankLogo == bankLogo)&&const DeepCollectionEquality().equals(other._ownerIds, _ownerIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,icon,color,isDeleted,initialBalance,initialBalanceDate,interestRate,bankLogo,const DeepCollectionEquality().hash(_ownerIds));

@override
String toString() {
  return 'AccountModel.debt(id: $id, name: $name, icon: $icon, color: $color, isDeleted: $isDeleted, initialBalance: $initialBalance, initialBalanceDate: $initialBalanceDate, interestRate: $interestRate, bankLogo: $bankLogo, ownerIds: $ownerIds)';
}


}

/// @nodoc
abstract mixin class $DebtAccountCopyWith<$Res> implements $AccountModelCopyWith<$Res> {
  factory $DebtAccountCopyWith(DebtAccount value, $Res Function(DebtAccount) _then) = _$DebtAccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String icon, String color, bool isDeleted, double initialBalance,@DateTimeTwelvePmConverter() DateTime initialBalanceDate, double interestRate, BankLogo bankLogo, List<String> ownerIds
});




}
/// @nodoc
class _$DebtAccountCopyWithImpl<$Res>
    implements $DebtAccountCopyWith<$Res> {
  _$DebtAccountCopyWithImpl(this._self, this._then);

  final DebtAccount _self;
  final $Res Function(DebtAccount) _then;

/// Create a copy of AccountModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? color = null,Object? isDeleted = null,Object? initialBalance = null,Object? initialBalanceDate = null,Object? interestRate = null,Object? bankLogo = null,Object? ownerIds = null,}) {
  return _then(DebtAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,initialBalance: null == initialBalance ? _self.initialBalance : initialBalance // ignore: cast_nullable_to_non_nullable
as double,initialBalanceDate: null == initialBalanceDate ? _self.initialBalanceDate : initialBalanceDate // ignore: cast_nullable_to_non_nullable
as DateTime,interestRate: null == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double,bankLogo: null == bankLogo ? _self.bankLogo : bankLogo // ignore: cast_nullable_to_non_nullable
as BankLogo,ownerIds: null == ownerIds ? _self._ownerIds : ownerIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$AccountBalanceModel {

 String get id;// Date string YYYY-MM-DD
 double get balance; DateTime get updatedAt;
/// Create a copy of AccountBalanceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountBalanceModelCopyWith<AccountBalanceModel> get copyWith => _$AccountBalanceModelCopyWithImpl<AccountBalanceModel>(this as AccountBalanceModel, _$identity);

  /// Serializes this AccountBalanceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountBalanceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,balance,updatedAt);

@override
String toString() {
  return 'AccountBalanceModel(id: $id, balance: $balance, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AccountBalanceModelCopyWith<$Res>  {
  factory $AccountBalanceModelCopyWith(AccountBalanceModel value, $Res Function(AccountBalanceModel) _then) = _$AccountBalanceModelCopyWithImpl;
@useResult
$Res call({
 String id, double balance, DateTime updatedAt
});




}
/// @nodoc
class _$AccountBalanceModelCopyWithImpl<$Res>
    implements $AccountBalanceModelCopyWith<$Res> {
  _$AccountBalanceModelCopyWithImpl(this._self, this._then);

  final AccountBalanceModel _self;
  final $Res Function(AccountBalanceModel) _then;

/// Create a copy of AccountBalanceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? balance = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountBalanceModel].
extension AccountBalanceModelPatterns on AccountBalanceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountBalanceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountBalanceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountBalanceModel value)  $default,){
final _that = this;
switch (_that) {
case _AccountBalanceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountBalanceModel value)?  $default,){
final _that = this;
switch (_that) {
case _AccountBalanceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  double balance,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountBalanceModel() when $default != null:
return $default(_that.id,_that.balance,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  double balance,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _AccountBalanceModel():
return $default(_that.id,_that.balance,_that.updatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  double balance,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _AccountBalanceModel() when $default != null:
return $default(_that.id,_that.balance,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AccountBalanceModel extends AccountBalanceModel {
  const _AccountBalanceModel({required this.id, required this.balance, required this.updatedAt}): super._();
  factory _AccountBalanceModel.fromJson(Map<String, dynamic> json) => _$AccountBalanceModelFromJson(json);

@override final  String id;
// Date string YYYY-MM-DD
@override final  double balance;
@override final  DateTime updatedAt;

/// Create a copy of AccountBalanceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountBalanceModelCopyWith<_AccountBalanceModel> get copyWith => __$AccountBalanceModelCopyWithImpl<_AccountBalanceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccountBalanceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountBalanceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,balance,updatedAt);

@override
String toString() {
  return 'AccountBalanceModel(id: $id, balance: $balance, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AccountBalanceModelCopyWith<$Res> implements $AccountBalanceModelCopyWith<$Res> {
  factory _$AccountBalanceModelCopyWith(_AccountBalanceModel value, $Res Function(_AccountBalanceModel) _then) = __$AccountBalanceModelCopyWithImpl;
@override @useResult
$Res call({
 String id, double balance, DateTime updatedAt
});




}
/// @nodoc
class __$AccountBalanceModelCopyWithImpl<$Res>
    implements _$AccountBalanceModelCopyWith<$Res> {
  __$AccountBalanceModelCopyWithImpl(this._self, this._then);

  final _AccountBalanceModel _self;
  final $Res Function(_AccountBalanceModel) _then;

/// Create a copy of AccountBalanceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? balance = null,Object? updatedAt = null,}) {
  return _then(_AccountBalanceModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$AccountDocumentAnalysisResult {

 AccountModel get account; List<OrderModel> get orders;
/// Create a copy of AccountDocumentAnalysisResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountDocumentAnalysisResultCopyWith<AccountDocumentAnalysisResult> get copyWith => _$AccountDocumentAnalysisResultCopyWithImpl<AccountDocumentAnalysisResult>(this as AccountDocumentAnalysisResult, _$identity);

  /// Serializes this AccountDocumentAnalysisResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountDocumentAnalysisResult&&(identical(other.account, account) || other.account == account)&&const DeepCollectionEquality().equals(other.orders, orders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,account,const DeepCollectionEquality().hash(orders));

@override
String toString() {
  return 'AccountDocumentAnalysisResult(account: $account, orders: $orders)';
}


}

/// @nodoc
abstract mixin class $AccountDocumentAnalysisResultCopyWith<$Res>  {
  factory $AccountDocumentAnalysisResultCopyWith(AccountDocumentAnalysisResult value, $Res Function(AccountDocumentAnalysisResult) _then) = _$AccountDocumentAnalysisResultCopyWithImpl;
@useResult
$Res call({
 AccountModel account, List<OrderModel> orders
});


$AccountModelCopyWith<$Res> get account;

}
/// @nodoc
class _$AccountDocumentAnalysisResultCopyWithImpl<$Res>
    implements $AccountDocumentAnalysisResultCopyWith<$Res> {
  _$AccountDocumentAnalysisResultCopyWithImpl(this._self, this._then);

  final AccountDocumentAnalysisResult _self;
  final $Res Function(AccountDocumentAnalysisResult) _then;

/// Create a copy of AccountDocumentAnalysisResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? account = null,Object? orders = null,}) {
  return _then(_self.copyWith(
account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as AccountModel,orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as List<OrderModel>,
  ));
}
/// Create a copy of AccountDocumentAnalysisResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountModelCopyWith<$Res> get account {
  
  return $AccountModelCopyWith<$Res>(_self.account, (value) {
    return _then(_self.copyWith(account: value));
  });
}
}


/// Adds pattern-matching-related methods to [AccountDocumentAnalysisResult].
extension AccountDocumentAnalysisResultPatterns on AccountDocumentAnalysisResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountDocumentAnalysisResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountDocumentAnalysisResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountDocumentAnalysisResult value)  $default,){
final _that = this;
switch (_that) {
case _AccountDocumentAnalysisResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountDocumentAnalysisResult value)?  $default,){
final _that = this;
switch (_that) {
case _AccountDocumentAnalysisResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AccountModel account,  List<OrderModel> orders)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountDocumentAnalysisResult() when $default != null:
return $default(_that.account,_that.orders);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AccountModel account,  List<OrderModel> orders)  $default,) {final _that = this;
switch (_that) {
case _AccountDocumentAnalysisResult():
return $default(_that.account,_that.orders);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AccountModel account,  List<OrderModel> orders)?  $default,) {final _that = this;
switch (_that) {
case _AccountDocumentAnalysisResult() when $default != null:
return $default(_that.account,_that.orders);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AccountDocumentAnalysisResult extends AccountDocumentAnalysisResult {
   _AccountDocumentAnalysisResult({required this.account, final  List<OrderModel> orders = const []}): _orders = orders,super._();
  factory _AccountDocumentAnalysisResult.fromJson(Map<String, dynamic> json) => _$AccountDocumentAnalysisResultFromJson(json);

@override final  AccountModel account;
 final  List<OrderModel> _orders;
@override@JsonKey() List<OrderModel> get orders {
  if (_orders is EqualUnmodifiableListView) return _orders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orders);
}


/// Create a copy of AccountDocumentAnalysisResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountDocumentAnalysisResultCopyWith<_AccountDocumentAnalysisResult> get copyWith => __$AccountDocumentAnalysisResultCopyWithImpl<_AccountDocumentAnalysisResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccountDocumentAnalysisResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountDocumentAnalysisResult&&(identical(other.account, account) || other.account == account)&&const DeepCollectionEquality().equals(other._orders, _orders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,account,const DeepCollectionEquality().hash(_orders));

@override
String toString() {
  return 'AccountDocumentAnalysisResult(account: $account, orders: $orders)';
}


}

/// @nodoc
abstract mixin class _$AccountDocumentAnalysisResultCopyWith<$Res> implements $AccountDocumentAnalysisResultCopyWith<$Res> {
  factory _$AccountDocumentAnalysisResultCopyWith(_AccountDocumentAnalysisResult value, $Res Function(_AccountDocumentAnalysisResult) _then) = __$AccountDocumentAnalysisResultCopyWithImpl;
@override @useResult
$Res call({
 AccountModel account, List<OrderModel> orders
});


@override $AccountModelCopyWith<$Res> get account;

}
/// @nodoc
class __$AccountDocumentAnalysisResultCopyWithImpl<$Res>
    implements _$AccountDocumentAnalysisResultCopyWith<$Res> {
  __$AccountDocumentAnalysisResultCopyWithImpl(this._self, this._then);

  final _AccountDocumentAnalysisResult _self;
  final $Res Function(_AccountDocumentAnalysisResult) _then;

/// Create a copy of AccountDocumentAnalysisResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? account = null,Object? orders = null,}) {
  return _then(_AccountDocumentAnalysisResult(
account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as AccountModel,orders: null == orders ? _self._orders : orders // ignore: cast_nullable_to_non_nullable
as List<OrderModel>,
  ));
}

/// Create a copy of AccountDocumentAnalysisResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountModelCopyWith<$Res> get account {
  
  return $AccountModelCopyWith<$Res>(_self.account, (value) {
    return _then(_self.copyWith(account: value));
  });
}
}

// dart format on
