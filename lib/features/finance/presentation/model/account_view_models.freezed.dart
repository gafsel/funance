// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_view_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountFormArgs {

 AccountModel? get account; AccountType? get type;
/// Create a copy of AccountFormArgs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountFormArgsCopyWith<AccountFormArgs> get copyWith => _$AccountFormArgsCopyWithImpl<AccountFormArgs>(this as AccountFormArgs, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountFormArgs&&(identical(other.account, account) || other.account == account)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,account,type);

@override
String toString() {
  return 'AccountFormArgs(account: $account, type: $type)';
}


}

/// @nodoc
abstract mixin class $AccountFormArgsCopyWith<$Res>  {
  factory $AccountFormArgsCopyWith(AccountFormArgs value, $Res Function(AccountFormArgs) _then) = _$AccountFormArgsCopyWithImpl;
@useResult
$Res call({
 AccountModel? account, AccountType? type
});


$AccountModelCopyWith<$Res>? get account;

}
/// @nodoc
class _$AccountFormArgsCopyWithImpl<$Res>
    implements $AccountFormArgsCopyWith<$Res> {
  _$AccountFormArgsCopyWithImpl(this._self, this._then);

  final AccountFormArgs _self;
  final $Res Function(AccountFormArgs) _then;

/// Create a copy of AccountFormArgs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? account = freezed,Object? type = freezed,}) {
  return _then(_self.copyWith(
account: freezed == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as AccountModel?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AccountType?,
  ));
}
/// Create a copy of AccountFormArgs
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountModelCopyWith<$Res>? get account {
    if (_self.account == null) {
    return null;
  }

  return $AccountModelCopyWith<$Res>(_self.account!, (value) {
    return _then(_self.copyWith(account: value));
  });
}
}


/// Adds pattern-matching-related methods to [AccountFormArgs].
extension AccountFormArgsPatterns on AccountFormArgs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountFormArgs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountFormArgs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountFormArgs value)  $default,){
final _that = this;
switch (_that) {
case _AccountFormArgs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountFormArgs value)?  $default,){
final _that = this;
switch (_that) {
case _AccountFormArgs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AccountModel? account,  AccountType? type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountFormArgs() when $default != null:
return $default(_that.account,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AccountModel? account,  AccountType? type)  $default,) {final _that = this;
switch (_that) {
case _AccountFormArgs():
return $default(_that.account,_that.type);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AccountModel? account,  AccountType? type)?  $default,) {final _that = this;
switch (_that) {
case _AccountFormArgs() when $default != null:
return $default(_that.account,_that.type);case _:
  return null;

}
}

}

/// @nodoc


class _AccountFormArgs implements AccountFormArgs {
   _AccountFormArgs({this.account, this.type});
  

@override final  AccountModel? account;
@override final  AccountType? type;

/// Create a copy of AccountFormArgs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountFormArgsCopyWith<_AccountFormArgs> get copyWith => __$AccountFormArgsCopyWithImpl<_AccountFormArgs>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountFormArgs&&(identical(other.account, account) || other.account == account)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,account,type);

@override
String toString() {
  return 'AccountFormArgs(account: $account, type: $type)';
}


}

/// @nodoc
abstract mixin class _$AccountFormArgsCopyWith<$Res> implements $AccountFormArgsCopyWith<$Res> {
  factory _$AccountFormArgsCopyWith(_AccountFormArgs value, $Res Function(_AccountFormArgs) _then) = __$AccountFormArgsCopyWithImpl;
@override @useResult
$Res call({
 AccountModel? account, AccountType? type
});


@override $AccountModelCopyWith<$Res>? get account;

}
/// @nodoc
class __$AccountFormArgsCopyWithImpl<$Res>
    implements _$AccountFormArgsCopyWith<$Res> {
  __$AccountFormArgsCopyWithImpl(this._self, this._then);

  final _AccountFormArgs _self;
  final $Res Function(_AccountFormArgs) _then;

/// Create a copy of AccountFormArgs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? account = freezed,Object? type = freezed,}) {
  return _then(_AccountFormArgs(
account: freezed == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as AccountModel?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AccountType?,
  ));
}

/// Create a copy of AccountFormArgs
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountModelCopyWith<$Res>? get account {
    if (_self.account == null) {
    return null;
  }

  return $AccountModelCopyWith<$Res>(_self.account!, (value) {
    return _then(_self.copyWith(account: value));
  });
}
}

/// @nodoc
mixin _$AccountFormState {

 AccountModel? get originalAccount; String get name; double get initialBalance; DateTime get initialBalanceDate; String get color; String get icon; AccountType get type; double? get limit; int? get dueDay; int? get closingDay; double? get interestRate; File? get selectedFile; AccountProcessingStatus get processingStatus; String? get errorMessage; AccountRegistrationMethod get registrationMethod; List<OrderModel> get detectedOrders;
/// Create a copy of AccountFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountFormStateCopyWith<AccountFormState> get copyWith => _$AccountFormStateCopyWithImpl<AccountFormState>(this as AccountFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountFormState&&(identical(other.originalAccount, originalAccount) || other.originalAccount == originalAccount)&&(identical(other.name, name) || other.name == name)&&(identical(other.initialBalance, initialBalance) || other.initialBalance == initialBalance)&&(identical(other.initialBalanceDate, initialBalanceDate) || other.initialBalanceDate == initialBalanceDate)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.type, type) || other.type == type)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.dueDay, dueDay) || other.dueDay == dueDay)&&(identical(other.closingDay, closingDay) || other.closingDay == closingDay)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate)&&(identical(other.selectedFile, selectedFile) || other.selectedFile == selectedFile)&&(identical(other.processingStatus, processingStatus) || other.processingStatus == processingStatus)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.registrationMethod, registrationMethod) || other.registrationMethod == registrationMethod)&&const DeepCollectionEquality().equals(other.detectedOrders, detectedOrders));
}


@override
int get hashCode => Object.hash(runtimeType,originalAccount,name,initialBalance,initialBalanceDate,color,icon,type,limit,dueDay,closingDay,interestRate,selectedFile,processingStatus,errorMessage,registrationMethod,const DeepCollectionEquality().hash(detectedOrders));

@override
String toString() {
  return 'AccountFormState(originalAccount: $originalAccount, name: $name, initialBalance: $initialBalance, initialBalanceDate: $initialBalanceDate, color: $color, icon: $icon, type: $type, limit: $limit, dueDay: $dueDay, closingDay: $closingDay, interestRate: $interestRate, selectedFile: $selectedFile, processingStatus: $processingStatus, errorMessage: $errorMessage, registrationMethod: $registrationMethod, detectedOrders: $detectedOrders)';
}


}

/// @nodoc
abstract mixin class $AccountFormStateCopyWith<$Res>  {
  factory $AccountFormStateCopyWith(AccountFormState value, $Res Function(AccountFormState) _then) = _$AccountFormStateCopyWithImpl;
@useResult
$Res call({
 AccountModel? originalAccount, String name, double initialBalance, DateTime initialBalanceDate, String color, String icon, AccountType type, double? limit, int? dueDay, int? closingDay, double? interestRate, File? selectedFile, AccountProcessingStatus processingStatus, String? errorMessage, AccountRegistrationMethod registrationMethod, List<OrderModel> detectedOrders
});


$AccountModelCopyWith<$Res>? get originalAccount;

}
/// @nodoc
class _$AccountFormStateCopyWithImpl<$Res>
    implements $AccountFormStateCopyWith<$Res> {
  _$AccountFormStateCopyWithImpl(this._self, this._then);

  final AccountFormState _self;
  final $Res Function(AccountFormState) _then;

/// Create a copy of AccountFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? originalAccount = freezed,Object? name = null,Object? initialBalance = null,Object? initialBalanceDate = null,Object? color = null,Object? icon = null,Object? type = null,Object? limit = freezed,Object? dueDay = freezed,Object? closingDay = freezed,Object? interestRate = freezed,Object? selectedFile = freezed,Object? processingStatus = null,Object? errorMessage = freezed,Object? registrationMethod = null,Object? detectedOrders = null,}) {
  return _then(_self.copyWith(
originalAccount: freezed == originalAccount ? _self.originalAccount : originalAccount // ignore: cast_nullable_to_non_nullable
as AccountModel?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,initialBalance: null == initialBalance ? _self.initialBalance : initialBalance // ignore: cast_nullable_to_non_nullable
as double,initialBalanceDate: null == initialBalanceDate ? _self.initialBalanceDate : initialBalanceDate // ignore: cast_nullable_to_non_nullable
as DateTime,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AccountType,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as double?,dueDay: freezed == dueDay ? _self.dueDay : dueDay // ignore: cast_nullable_to_non_nullable
as int?,closingDay: freezed == closingDay ? _self.closingDay : closingDay // ignore: cast_nullable_to_non_nullable
as int?,interestRate: freezed == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double?,selectedFile: freezed == selectedFile ? _self.selectedFile : selectedFile // ignore: cast_nullable_to_non_nullable
as File?,processingStatus: null == processingStatus ? _self.processingStatus : processingStatus // ignore: cast_nullable_to_non_nullable
as AccountProcessingStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,registrationMethod: null == registrationMethod ? _self.registrationMethod : registrationMethod // ignore: cast_nullable_to_non_nullable
as AccountRegistrationMethod,detectedOrders: null == detectedOrders ? _self.detectedOrders : detectedOrders // ignore: cast_nullable_to_non_nullable
as List<OrderModel>,
  ));
}
/// Create a copy of AccountFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountModelCopyWith<$Res>? get originalAccount {
    if (_self.originalAccount == null) {
    return null;
  }

  return $AccountModelCopyWith<$Res>(_self.originalAccount!, (value) {
    return _then(_self.copyWith(originalAccount: value));
  });
}
}


/// Adds pattern-matching-related methods to [AccountFormState].
extension AccountFormStatePatterns on AccountFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountFormState value)  $default,){
final _that = this;
switch (_that) {
case _AccountFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountFormState value)?  $default,){
final _that = this;
switch (_that) {
case _AccountFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AccountModel? originalAccount,  String name,  double initialBalance,  DateTime initialBalanceDate,  String color,  String icon,  AccountType type,  double? limit,  int? dueDay,  int? closingDay,  double? interestRate,  File? selectedFile,  AccountProcessingStatus processingStatus,  String? errorMessage,  AccountRegistrationMethod registrationMethod,  List<OrderModel> detectedOrders)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountFormState() when $default != null:
return $default(_that.originalAccount,_that.name,_that.initialBalance,_that.initialBalanceDate,_that.color,_that.icon,_that.type,_that.limit,_that.dueDay,_that.closingDay,_that.interestRate,_that.selectedFile,_that.processingStatus,_that.errorMessage,_that.registrationMethod,_that.detectedOrders);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AccountModel? originalAccount,  String name,  double initialBalance,  DateTime initialBalanceDate,  String color,  String icon,  AccountType type,  double? limit,  int? dueDay,  int? closingDay,  double? interestRate,  File? selectedFile,  AccountProcessingStatus processingStatus,  String? errorMessage,  AccountRegistrationMethod registrationMethod,  List<OrderModel> detectedOrders)  $default,) {final _that = this;
switch (_that) {
case _AccountFormState():
return $default(_that.originalAccount,_that.name,_that.initialBalance,_that.initialBalanceDate,_that.color,_that.icon,_that.type,_that.limit,_that.dueDay,_that.closingDay,_that.interestRate,_that.selectedFile,_that.processingStatus,_that.errorMessage,_that.registrationMethod,_that.detectedOrders);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AccountModel? originalAccount,  String name,  double initialBalance,  DateTime initialBalanceDate,  String color,  String icon,  AccountType type,  double? limit,  int? dueDay,  int? closingDay,  double? interestRate,  File? selectedFile,  AccountProcessingStatus processingStatus,  String? errorMessage,  AccountRegistrationMethod registrationMethod,  List<OrderModel> detectedOrders)?  $default,) {final _that = this;
switch (_that) {
case _AccountFormState() when $default != null:
return $default(_that.originalAccount,_that.name,_that.initialBalance,_that.initialBalanceDate,_that.color,_that.icon,_that.type,_that.limit,_that.dueDay,_that.closingDay,_that.interestRate,_that.selectedFile,_that.processingStatus,_that.errorMessage,_that.registrationMethod,_that.detectedOrders);case _:
  return null;

}
}

}

/// @nodoc


class _AccountFormState extends AccountFormState {
  const _AccountFormState({this.originalAccount, required this.name, required this.initialBalance, required this.initialBalanceDate, required this.color, required this.icon, required this.type, this.limit, this.dueDay, this.closingDay, this.interestRate, this.selectedFile, this.processingStatus = AccountProcessingStatus.none, this.errorMessage, this.registrationMethod = AccountRegistrationMethod.document, final  List<OrderModel> detectedOrders = const []}): _detectedOrders = detectedOrders,super._();
  

@override final  AccountModel? originalAccount;
@override final  String name;
@override final  double initialBalance;
@override final  DateTime initialBalanceDate;
@override final  String color;
@override final  String icon;
@override final  AccountType type;
@override final  double? limit;
@override final  int? dueDay;
@override final  int? closingDay;
@override final  double? interestRate;
@override final  File? selectedFile;
@override@JsonKey() final  AccountProcessingStatus processingStatus;
@override final  String? errorMessage;
@override@JsonKey() final  AccountRegistrationMethod registrationMethod;
 final  List<OrderModel> _detectedOrders;
@override@JsonKey() List<OrderModel> get detectedOrders {
  if (_detectedOrders is EqualUnmodifiableListView) return _detectedOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_detectedOrders);
}


/// Create a copy of AccountFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountFormStateCopyWith<_AccountFormState> get copyWith => __$AccountFormStateCopyWithImpl<_AccountFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountFormState&&(identical(other.originalAccount, originalAccount) || other.originalAccount == originalAccount)&&(identical(other.name, name) || other.name == name)&&(identical(other.initialBalance, initialBalance) || other.initialBalance == initialBalance)&&(identical(other.initialBalanceDate, initialBalanceDate) || other.initialBalanceDate == initialBalanceDate)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.type, type) || other.type == type)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.dueDay, dueDay) || other.dueDay == dueDay)&&(identical(other.closingDay, closingDay) || other.closingDay == closingDay)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate)&&(identical(other.selectedFile, selectedFile) || other.selectedFile == selectedFile)&&(identical(other.processingStatus, processingStatus) || other.processingStatus == processingStatus)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.registrationMethod, registrationMethod) || other.registrationMethod == registrationMethod)&&const DeepCollectionEquality().equals(other._detectedOrders, _detectedOrders));
}


@override
int get hashCode => Object.hash(runtimeType,originalAccount,name,initialBalance,initialBalanceDate,color,icon,type,limit,dueDay,closingDay,interestRate,selectedFile,processingStatus,errorMessage,registrationMethod,const DeepCollectionEquality().hash(_detectedOrders));

@override
String toString() {
  return 'AccountFormState(originalAccount: $originalAccount, name: $name, initialBalance: $initialBalance, initialBalanceDate: $initialBalanceDate, color: $color, icon: $icon, type: $type, limit: $limit, dueDay: $dueDay, closingDay: $closingDay, interestRate: $interestRate, selectedFile: $selectedFile, processingStatus: $processingStatus, errorMessage: $errorMessage, registrationMethod: $registrationMethod, detectedOrders: $detectedOrders)';
}


}

/// @nodoc
abstract mixin class _$AccountFormStateCopyWith<$Res> implements $AccountFormStateCopyWith<$Res> {
  factory _$AccountFormStateCopyWith(_AccountFormState value, $Res Function(_AccountFormState) _then) = __$AccountFormStateCopyWithImpl;
@override @useResult
$Res call({
 AccountModel? originalAccount, String name, double initialBalance, DateTime initialBalanceDate, String color, String icon, AccountType type, double? limit, int? dueDay, int? closingDay, double? interestRate, File? selectedFile, AccountProcessingStatus processingStatus, String? errorMessage, AccountRegistrationMethod registrationMethod, List<OrderModel> detectedOrders
});


@override $AccountModelCopyWith<$Res>? get originalAccount;

}
/// @nodoc
class __$AccountFormStateCopyWithImpl<$Res>
    implements _$AccountFormStateCopyWith<$Res> {
  __$AccountFormStateCopyWithImpl(this._self, this._then);

  final _AccountFormState _self;
  final $Res Function(_AccountFormState) _then;

/// Create a copy of AccountFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? originalAccount = freezed,Object? name = null,Object? initialBalance = null,Object? initialBalanceDate = null,Object? color = null,Object? icon = null,Object? type = null,Object? limit = freezed,Object? dueDay = freezed,Object? closingDay = freezed,Object? interestRate = freezed,Object? selectedFile = freezed,Object? processingStatus = null,Object? errorMessage = freezed,Object? registrationMethod = null,Object? detectedOrders = null,}) {
  return _then(_AccountFormState(
originalAccount: freezed == originalAccount ? _self.originalAccount : originalAccount // ignore: cast_nullable_to_non_nullable
as AccountModel?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,initialBalance: null == initialBalance ? _self.initialBalance : initialBalance // ignore: cast_nullable_to_non_nullable
as double,initialBalanceDate: null == initialBalanceDate ? _self.initialBalanceDate : initialBalanceDate // ignore: cast_nullable_to_non_nullable
as DateTime,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AccountType,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as double?,dueDay: freezed == dueDay ? _self.dueDay : dueDay // ignore: cast_nullable_to_non_nullable
as int?,closingDay: freezed == closingDay ? _self.closingDay : closingDay // ignore: cast_nullable_to_non_nullable
as int?,interestRate: freezed == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double?,selectedFile: freezed == selectedFile ? _self.selectedFile : selectedFile // ignore: cast_nullable_to_non_nullable
as File?,processingStatus: null == processingStatus ? _self.processingStatus : processingStatus // ignore: cast_nullable_to_non_nullable
as AccountProcessingStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,registrationMethod: null == registrationMethod ? _self.registrationMethod : registrationMethod // ignore: cast_nullable_to_non_nullable
as AccountRegistrationMethod,detectedOrders: null == detectedOrders ? _self._detectedOrders : detectedOrders // ignore: cast_nullable_to_non_nullable
as List<OrderModel>,
  ));
}

/// Create a copy of AccountFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountModelCopyWith<$Res>? get originalAccount {
    if (_self.originalAccount == null) {
    return null;
  }

  return $AccountModelCopyWith<$Res>(_self.originalAccount!, (value) {
    return _then(_self.copyWith(originalAccount: value));
  });
}
}

/// @nodoc
mixin _$CategoryAmountModel {

 CategoryModel get category; double get amount;
/// Create a copy of CategoryAmountModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryAmountModelCopyWith<CategoryAmountModel> get copyWith => _$CategoryAmountModelCopyWithImpl<CategoryAmountModel>(this as CategoryAmountModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryAmountModel&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount));
}


@override
int get hashCode => Object.hash(runtimeType,category,amount);

@override
String toString() {
  return 'CategoryAmountModel(category: $category, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $CategoryAmountModelCopyWith<$Res>  {
  factory $CategoryAmountModelCopyWith(CategoryAmountModel value, $Res Function(CategoryAmountModel) _then) = _$CategoryAmountModelCopyWithImpl;
@useResult
$Res call({
 CategoryModel category, double amount
});


$CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class _$CategoryAmountModelCopyWithImpl<$Res>
    implements $CategoryAmountModelCopyWith<$Res> {
  _$CategoryAmountModelCopyWithImpl(this._self, this._then);

  final CategoryAmountModel _self;
  final $Res Function(CategoryAmountModel) _then;

/// Create a copy of CategoryAmountModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? amount = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}
/// Create a copy of CategoryAmountModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [CategoryAmountModel].
extension CategoryAmountModelPatterns on CategoryAmountModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryAmountModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryAmountModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryAmountModel value)  $default,){
final _that = this;
switch (_that) {
case _CategoryAmountModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryAmountModel value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryAmountModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CategoryModel category,  double amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryAmountModel() when $default != null:
return $default(_that.category,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CategoryModel category,  double amount)  $default,) {final _that = this;
switch (_that) {
case _CategoryAmountModel():
return $default(_that.category,_that.amount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CategoryModel category,  double amount)?  $default,) {final _that = this;
switch (_that) {
case _CategoryAmountModel() when $default != null:
return $default(_that.category,_that.amount);case _:
  return null;

}
}

}

/// @nodoc


class _CategoryAmountModel implements CategoryAmountModel {
   _CategoryAmountModel({required this.category, required this.amount});
  

@override final  CategoryModel category;
@override final  double amount;

/// Create a copy of CategoryAmountModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryAmountModelCopyWith<_CategoryAmountModel> get copyWith => __$CategoryAmountModelCopyWithImpl<_CategoryAmountModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryAmountModel&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount));
}


@override
int get hashCode => Object.hash(runtimeType,category,amount);

@override
String toString() {
  return 'CategoryAmountModel(category: $category, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$CategoryAmountModelCopyWith<$Res> implements $CategoryAmountModelCopyWith<$Res> {
  factory _$CategoryAmountModelCopyWith(_CategoryAmountModel value, $Res Function(_CategoryAmountModel) _then) = __$CategoryAmountModelCopyWithImpl;
@override @useResult
$Res call({
 CategoryModel category, double amount
});


@override $CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class __$CategoryAmountModelCopyWithImpl<$Res>
    implements _$CategoryAmountModelCopyWith<$Res> {
  __$CategoryAmountModelCopyWithImpl(this._self, this._then);

  final _CategoryAmountModel _self;
  final $Res Function(_CategoryAmountModel) _then;

/// Create a copy of CategoryAmountModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? amount = null,}) {
  return _then(_CategoryAmountModel(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of CategoryAmountModel
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
