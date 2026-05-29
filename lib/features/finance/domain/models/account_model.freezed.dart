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

 String get id; String get name; String get icon; String get color; bool get isDeleted; double get initialBalance; DateTime get initialBalanceDate; String? get filePath; String? get fileName; AccountProcessingStatus get processingStatus;
/// Create a copy of AccountModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountModelCopyWith<AccountModel> get copyWith => _$AccountModelCopyWithImpl<AccountModel>(this as AccountModel, _$identity);

  /// Serializes this AccountModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.initialBalance, initialBalance) || other.initialBalance == initialBalance)&&(identical(other.initialBalanceDate, initialBalanceDate) || other.initialBalanceDate == initialBalanceDate)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.processingStatus, processingStatus) || other.processingStatus == processingStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,icon,color,isDeleted,initialBalance,initialBalanceDate,filePath,fileName,processingStatus);

@override
String toString() {
  return 'AccountModel(id: $id, name: $name, icon: $icon, color: $color, isDeleted: $isDeleted, initialBalance: $initialBalance, initialBalanceDate: $initialBalanceDate, filePath: $filePath, fileName: $fileName, processingStatus: $processingStatus)';
}


}

/// @nodoc
abstract mixin class $AccountModelCopyWith<$Res>  {
  factory $AccountModelCopyWith(AccountModel value, $Res Function(AccountModel) _then) = _$AccountModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String icon, String color, bool isDeleted, double initialBalance, DateTime initialBalanceDate, String? filePath, String? fileName, AccountProcessingStatus processingStatus
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? color = null,Object? isDeleted = null,Object? initialBalance = null,Object? initialBalanceDate = null,Object? filePath = freezed,Object? fileName = freezed,Object? processingStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,initialBalance: null == initialBalance ? _self.initialBalance : initialBalance // ignore: cast_nullable_to_non_nullable
as double,initialBalanceDate: null == initialBalanceDate ? _self.initialBalanceDate : initialBalanceDate // ignore: cast_nullable_to_non_nullable
as DateTime,filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,processingStatus: null == processingStatus ? _self.processingStatus : processingStatus // ignore: cast_nullable_to_non_nullable
as AccountProcessingStatus,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance,  DateTime initialBalanceDate,  String? filePath,  String? fileName,  AccountProcessingStatus processingStatus)?  checking,TResult Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance,  DateTime initialBalanceDate,  String? filePath,  String? fileName,  AccountProcessingStatus processingStatus,  double? interestRate)?  investment,TResult Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance,  DateTime initialBalanceDate,  String? filePath,  String? fileName,  AccountProcessingStatus processingStatus,  double? limit,  int? dueDay,  int? closingDay)?  creditCard,TResult Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance,  DateTime initialBalanceDate,  String? filePath,  String? fileName,  AccountProcessingStatus processingStatus,  double? interestRate)?  debt,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CheckingAccount() when checking != null:
return checking(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.filePath,_that.fileName,_that.processingStatus);case InvestmentAccount() when investment != null:
return investment(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.filePath,_that.fileName,_that.processingStatus,_that.interestRate);case CreditCardAccount() when creditCard != null:
return creditCard(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.filePath,_that.fileName,_that.processingStatus,_that.limit,_that.dueDay,_that.closingDay);case DebtAccount() when debt != null:
return debt(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.filePath,_that.fileName,_that.processingStatus,_that.interestRate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance,  DateTime initialBalanceDate,  String? filePath,  String? fileName,  AccountProcessingStatus processingStatus)  checking,required TResult Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance,  DateTime initialBalanceDate,  String? filePath,  String? fileName,  AccountProcessingStatus processingStatus,  double? interestRate)  investment,required TResult Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance,  DateTime initialBalanceDate,  String? filePath,  String? fileName,  AccountProcessingStatus processingStatus,  double? limit,  int? dueDay,  int? closingDay)  creditCard,required TResult Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance,  DateTime initialBalanceDate,  String? filePath,  String? fileName,  AccountProcessingStatus processingStatus,  double? interestRate)  debt,}) {final _that = this;
switch (_that) {
case CheckingAccount():
return checking(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.filePath,_that.fileName,_that.processingStatus);case InvestmentAccount():
return investment(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.filePath,_that.fileName,_that.processingStatus,_that.interestRate);case CreditCardAccount():
return creditCard(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.filePath,_that.fileName,_that.processingStatus,_that.limit,_that.dueDay,_that.closingDay);case DebtAccount():
return debt(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.filePath,_that.fileName,_that.processingStatus,_that.interestRate);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance,  DateTime initialBalanceDate,  String? filePath,  String? fileName,  AccountProcessingStatus processingStatus)?  checking,TResult? Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance,  DateTime initialBalanceDate,  String? filePath,  String? fileName,  AccountProcessingStatus processingStatus,  double? interestRate)?  investment,TResult? Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance,  DateTime initialBalanceDate,  String? filePath,  String? fileName,  AccountProcessingStatus processingStatus,  double? limit,  int? dueDay,  int? closingDay)?  creditCard,TResult? Function( String id,  String name,  String icon,  String color,  bool isDeleted,  double initialBalance,  DateTime initialBalanceDate,  String? filePath,  String? fileName,  AccountProcessingStatus processingStatus,  double? interestRate)?  debt,}) {final _that = this;
switch (_that) {
case CheckingAccount() when checking != null:
return checking(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.filePath,_that.fileName,_that.processingStatus);case InvestmentAccount() when investment != null:
return investment(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.filePath,_that.fileName,_that.processingStatus,_that.interestRate);case CreditCardAccount() when creditCard != null:
return creditCard(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.filePath,_that.fileName,_that.processingStatus,_that.limit,_that.dueDay,_that.closingDay);case DebtAccount() when debt != null:
return debt(_that.id,_that.name,_that.icon,_that.color,_that.isDeleted,_that.initialBalance,_that.initialBalanceDate,_that.filePath,_that.fileName,_that.processingStatus,_that.interestRate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class CheckingAccount extends AccountModel {
  const CheckingAccount({required this.id, required this.name, required this.icon, required this.color, this.isDeleted = false, this.initialBalance = 0.0, required this.initialBalanceDate, this.filePath, this.fileName, this.processingStatus = AccountProcessingStatus.none, final  String? $type}): $type = $type ?? 'checking',super._();
  factory CheckingAccount.fromJson(Map<String, dynamic> json) => _$CheckingAccountFromJson(json);

@override final  String id;
@override final  String name;
@override final  String icon;
@override final  String color;
@override@JsonKey() final  bool isDeleted;
@override@JsonKey() final  double initialBalance;
@override final  DateTime initialBalanceDate;
@override final  String? filePath;
@override final  String? fileName;
@override@JsonKey() final  AccountProcessingStatus processingStatus;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckingAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.initialBalance, initialBalance) || other.initialBalance == initialBalance)&&(identical(other.initialBalanceDate, initialBalanceDate) || other.initialBalanceDate == initialBalanceDate)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.processingStatus, processingStatus) || other.processingStatus == processingStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,icon,color,isDeleted,initialBalance,initialBalanceDate,filePath,fileName,processingStatus);

@override
String toString() {
  return 'AccountModel.checking(id: $id, name: $name, icon: $icon, color: $color, isDeleted: $isDeleted, initialBalance: $initialBalance, initialBalanceDate: $initialBalanceDate, filePath: $filePath, fileName: $fileName, processingStatus: $processingStatus)';
}


}

/// @nodoc
abstract mixin class $CheckingAccountCopyWith<$Res> implements $AccountModelCopyWith<$Res> {
  factory $CheckingAccountCopyWith(CheckingAccount value, $Res Function(CheckingAccount) _then) = _$CheckingAccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String icon, String color, bool isDeleted, double initialBalance, DateTime initialBalanceDate, String? filePath, String? fileName, AccountProcessingStatus processingStatus
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? color = null,Object? isDeleted = null,Object? initialBalance = null,Object? initialBalanceDate = null,Object? filePath = freezed,Object? fileName = freezed,Object? processingStatus = null,}) {
  return _then(CheckingAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,initialBalance: null == initialBalance ? _self.initialBalance : initialBalance // ignore: cast_nullable_to_non_nullable
as double,initialBalanceDate: null == initialBalanceDate ? _self.initialBalanceDate : initialBalanceDate // ignore: cast_nullable_to_non_nullable
as DateTime,filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,processingStatus: null == processingStatus ? _self.processingStatus : processingStatus // ignore: cast_nullable_to_non_nullable
as AccountProcessingStatus,
  ));
}


}

/// @nodoc
@JsonSerializable()

class InvestmentAccount extends AccountModel {
  const InvestmentAccount({required this.id, required this.name, required this.icon, required this.color, this.isDeleted = false, this.initialBalance = 0.0, required this.initialBalanceDate, this.filePath, this.fileName, this.processingStatus = AccountProcessingStatus.none, this.interestRate, final  String? $type}): $type = $type ?? 'investment',super._();
  factory InvestmentAccount.fromJson(Map<String, dynamic> json) => _$InvestmentAccountFromJson(json);

@override final  String id;
@override final  String name;
@override final  String icon;
@override final  String color;
@override@JsonKey() final  bool isDeleted;
@override@JsonKey() final  double initialBalance;
@override final  DateTime initialBalanceDate;
@override final  String? filePath;
@override final  String? fileName;
@override@JsonKey() final  AccountProcessingStatus processingStatus;
 final  double? interestRate;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.initialBalance, initialBalance) || other.initialBalance == initialBalance)&&(identical(other.initialBalanceDate, initialBalanceDate) || other.initialBalanceDate == initialBalanceDate)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.processingStatus, processingStatus) || other.processingStatus == processingStatus)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,icon,color,isDeleted,initialBalance,initialBalanceDate,filePath,fileName,processingStatus,interestRate);

@override
String toString() {
  return 'AccountModel.investment(id: $id, name: $name, icon: $icon, color: $color, isDeleted: $isDeleted, initialBalance: $initialBalance, initialBalanceDate: $initialBalanceDate, filePath: $filePath, fileName: $fileName, processingStatus: $processingStatus, interestRate: $interestRate)';
}


}

/// @nodoc
abstract mixin class $InvestmentAccountCopyWith<$Res> implements $AccountModelCopyWith<$Res> {
  factory $InvestmentAccountCopyWith(InvestmentAccount value, $Res Function(InvestmentAccount) _then) = _$InvestmentAccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String icon, String color, bool isDeleted, double initialBalance, DateTime initialBalanceDate, String? filePath, String? fileName, AccountProcessingStatus processingStatus, double? interestRate
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? color = null,Object? isDeleted = null,Object? initialBalance = null,Object? initialBalanceDate = null,Object? filePath = freezed,Object? fileName = freezed,Object? processingStatus = null,Object? interestRate = freezed,}) {
  return _then(InvestmentAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,initialBalance: null == initialBalance ? _self.initialBalance : initialBalance // ignore: cast_nullable_to_non_nullable
as double,initialBalanceDate: null == initialBalanceDate ? _self.initialBalanceDate : initialBalanceDate // ignore: cast_nullable_to_non_nullable
as DateTime,filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,processingStatus: null == processingStatus ? _self.processingStatus : processingStatus // ignore: cast_nullable_to_non_nullable
as AccountProcessingStatus,interestRate: freezed == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CreditCardAccount extends AccountModel {
  const CreditCardAccount({required this.id, required this.name, required this.icon, required this.color, this.isDeleted = false, this.initialBalance = 0.0, required this.initialBalanceDate, this.filePath, this.fileName, this.processingStatus = AccountProcessingStatus.none, this.limit, this.dueDay, this.closingDay, final  String? $type}): $type = $type ?? 'creditCard',super._();
  factory CreditCardAccount.fromJson(Map<String, dynamic> json) => _$CreditCardAccountFromJson(json);

@override final  String id;
@override final  String name;
@override final  String icon;
@override final  String color;
@override@JsonKey() final  bool isDeleted;
@override@JsonKey() final  double initialBalance;
@override final  DateTime initialBalanceDate;
@override final  String? filePath;
@override final  String? fileName;
@override@JsonKey() final  AccountProcessingStatus processingStatus;
 final  double? limit;
 final  int? dueDay;
 final  int? closingDay;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreditCardAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.initialBalance, initialBalance) || other.initialBalance == initialBalance)&&(identical(other.initialBalanceDate, initialBalanceDate) || other.initialBalanceDate == initialBalanceDate)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.processingStatus, processingStatus) || other.processingStatus == processingStatus)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.dueDay, dueDay) || other.dueDay == dueDay)&&(identical(other.closingDay, closingDay) || other.closingDay == closingDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,icon,color,isDeleted,initialBalance,initialBalanceDate,filePath,fileName,processingStatus,limit,dueDay,closingDay);

@override
String toString() {
  return 'AccountModel.creditCard(id: $id, name: $name, icon: $icon, color: $color, isDeleted: $isDeleted, initialBalance: $initialBalance, initialBalanceDate: $initialBalanceDate, filePath: $filePath, fileName: $fileName, processingStatus: $processingStatus, limit: $limit, dueDay: $dueDay, closingDay: $closingDay)';
}


}

/// @nodoc
abstract mixin class $CreditCardAccountCopyWith<$Res> implements $AccountModelCopyWith<$Res> {
  factory $CreditCardAccountCopyWith(CreditCardAccount value, $Res Function(CreditCardAccount) _then) = _$CreditCardAccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String icon, String color, bool isDeleted, double initialBalance, DateTime initialBalanceDate, String? filePath, String? fileName, AccountProcessingStatus processingStatus, double? limit, int? dueDay, int? closingDay
});




}
/// @nodoc
class _$CreditCardAccountCopyWithImpl<$Res>
    implements $CreditCardAccountCopyWith<$Res> {
  _$CreditCardAccountCopyWithImpl(this._self, this._then);

  final CreditCardAccount _self;
  final $Res Function(CreditCardAccount) _then;

/// Create a copy of AccountModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? color = null,Object? isDeleted = null,Object? initialBalance = null,Object? initialBalanceDate = null,Object? filePath = freezed,Object? fileName = freezed,Object? processingStatus = null,Object? limit = freezed,Object? dueDay = freezed,Object? closingDay = freezed,}) {
  return _then(CreditCardAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,initialBalance: null == initialBalance ? _self.initialBalance : initialBalance // ignore: cast_nullable_to_non_nullable
as double,initialBalanceDate: null == initialBalanceDate ? _self.initialBalanceDate : initialBalanceDate // ignore: cast_nullable_to_non_nullable
as DateTime,filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,processingStatus: null == processingStatus ? _self.processingStatus : processingStatus // ignore: cast_nullable_to_non_nullable
as AccountProcessingStatus,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as double?,dueDay: freezed == dueDay ? _self.dueDay : dueDay // ignore: cast_nullable_to_non_nullable
as int?,closingDay: freezed == closingDay ? _self.closingDay : closingDay // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class DebtAccount extends AccountModel {
  const DebtAccount({required this.id, required this.name, required this.icon, required this.color, this.isDeleted = false, this.initialBalance = 0.0, required this.initialBalanceDate, this.filePath, this.fileName, this.processingStatus = AccountProcessingStatus.none, this.interestRate, final  String? $type}): $type = $type ?? 'debt',super._();
  factory DebtAccount.fromJson(Map<String, dynamic> json) => _$DebtAccountFromJson(json);

@override final  String id;
@override final  String name;
@override final  String icon;
@override final  String color;
@override@JsonKey() final  bool isDeleted;
@override@JsonKey() final  double initialBalance;
@override final  DateTime initialBalanceDate;
@override final  String? filePath;
@override final  String? fileName;
@override@JsonKey() final  AccountProcessingStatus processingStatus;
 final  double? interestRate;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DebtAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.initialBalance, initialBalance) || other.initialBalance == initialBalance)&&(identical(other.initialBalanceDate, initialBalanceDate) || other.initialBalanceDate == initialBalanceDate)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.processingStatus, processingStatus) || other.processingStatus == processingStatus)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,icon,color,isDeleted,initialBalance,initialBalanceDate,filePath,fileName,processingStatus,interestRate);

@override
String toString() {
  return 'AccountModel.debt(id: $id, name: $name, icon: $icon, color: $color, isDeleted: $isDeleted, initialBalance: $initialBalance, initialBalanceDate: $initialBalanceDate, filePath: $filePath, fileName: $fileName, processingStatus: $processingStatus, interestRate: $interestRate)';
}


}

/// @nodoc
abstract mixin class $DebtAccountCopyWith<$Res> implements $AccountModelCopyWith<$Res> {
  factory $DebtAccountCopyWith(DebtAccount value, $Res Function(DebtAccount) _then) = _$DebtAccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String icon, String color, bool isDeleted, double initialBalance, DateTime initialBalanceDate, String? filePath, String? fileName, AccountProcessingStatus processingStatus, double? interestRate
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? color = null,Object? isDeleted = null,Object? initialBalance = null,Object? initialBalanceDate = null,Object? filePath = freezed,Object? fileName = freezed,Object? processingStatus = null,Object? interestRate = freezed,}) {
  return _then(DebtAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,initialBalance: null == initialBalance ? _self.initialBalance : initialBalance // ignore: cast_nullable_to_non_nullable
as double,initialBalanceDate: null == initialBalanceDate ? _self.initialBalanceDate : initialBalanceDate // ignore: cast_nullable_to_non_nullable
as DateTime,filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,processingStatus: null == processingStatus ? _self.processingStatus : processingStatus // ignore: cast_nullable_to_non_nullable
as AccountProcessingStatus,interestRate: freezed == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double?,
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

// dart format on
