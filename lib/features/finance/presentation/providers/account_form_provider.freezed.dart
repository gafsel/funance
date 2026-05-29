// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_form_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountFormState {

 String get id; String get name; double get initialBalance; DateTime get initialBalanceDate; AccountType get type; String get color; String get icon; double? get limit; int? get dueDay; int? get closingDay; double? get interestRate; File? get selectedFile; String? get fileName; AccountProcessingStatus get processingStatus; AccountRegistrationMethod get registrationMethod; List<OrderModel> get detectedOrders; List<PlanningModel> get detectedPlannings; bool get isLoading; bool get isSuccess; String? get errorMessage;
/// Create a copy of AccountFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountFormStateCopyWith<AccountFormState> get copyWith => _$AccountFormStateCopyWithImpl<AccountFormState>(this as AccountFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountFormState&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.initialBalance, initialBalance) || other.initialBalance == initialBalance)&&(identical(other.initialBalanceDate, initialBalanceDate) || other.initialBalanceDate == initialBalanceDate)&&(identical(other.type, type) || other.type == type)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.dueDay, dueDay) || other.dueDay == dueDay)&&(identical(other.closingDay, closingDay) || other.closingDay == closingDay)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate)&&(identical(other.selectedFile, selectedFile) || other.selectedFile == selectedFile)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.processingStatus, processingStatus) || other.processingStatus == processingStatus)&&(identical(other.registrationMethod, registrationMethod) || other.registrationMethod == registrationMethod)&&const DeepCollectionEquality().equals(other.detectedOrders, detectedOrders)&&const DeepCollectionEquality().equals(other.detectedPlannings, detectedPlannings)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,name,initialBalance,initialBalanceDate,type,color,icon,limit,dueDay,closingDay,interestRate,selectedFile,fileName,processingStatus,registrationMethod,const DeepCollectionEquality().hash(detectedOrders),const DeepCollectionEquality().hash(detectedPlannings),isLoading,isSuccess,errorMessage]);

@override
String toString() {
  return 'AccountFormState(id: $id, name: $name, initialBalance: $initialBalance, initialBalanceDate: $initialBalanceDate, type: $type, color: $color, icon: $icon, limit: $limit, dueDay: $dueDay, closingDay: $closingDay, interestRate: $interestRate, selectedFile: $selectedFile, fileName: $fileName, processingStatus: $processingStatus, registrationMethod: $registrationMethod, detectedOrders: $detectedOrders, detectedPlannings: $detectedPlannings, isLoading: $isLoading, isSuccess: $isSuccess, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $AccountFormStateCopyWith<$Res>  {
  factory $AccountFormStateCopyWith(AccountFormState value, $Res Function(AccountFormState) _then) = _$AccountFormStateCopyWithImpl;
@useResult
$Res call({
 String id, String name, double initialBalance, DateTime initialBalanceDate, AccountType type, String color, String icon, double? limit, int? dueDay, int? closingDay, double? interestRate, File? selectedFile, String? fileName, AccountProcessingStatus processingStatus, AccountRegistrationMethod registrationMethod, List<OrderModel> detectedOrders, List<PlanningModel> detectedPlannings, bool isLoading, bool isSuccess, String? errorMessage
});




}
/// @nodoc
class _$AccountFormStateCopyWithImpl<$Res>
    implements $AccountFormStateCopyWith<$Res> {
  _$AccountFormStateCopyWithImpl(this._self, this._then);

  final AccountFormState _self;
  final $Res Function(AccountFormState) _then;

/// Create a copy of AccountFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? initialBalance = null,Object? initialBalanceDate = null,Object? type = null,Object? color = null,Object? icon = null,Object? limit = freezed,Object? dueDay = freezed,Object? closingDay = freezed,Object? interestRate = freezed,Object? selectedFile = freezed,Object? fileName = freezed,Object? processingStatus = null,Object? registrationMethod = null,Object? detectedOrders = null,Object? detectedPlannings = null,Object? isLoading = null,Object? isSuccess = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,initialBalance: null == initialBalance ? _self.initialBalance : initialBalance // ignore: cast_nullable_to_non_nullable
as double,initialBalanceDate: null == initialBalanceDate ? _self.initialBalanceDate : initialBalanceDate // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AccountType,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as double?,dueDay: freezed == dueDay ? _self.dueDay : dueDay // ignore: cast_nullable_to_non_nullable
as int?,closingDay: freezed == closingDay ? _self.closingDay : closingDay // ignore: cast_nullable_to_non_nullable
as int?,interestRate: freezed == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double?,selectedFile: freezed == selectedFile ? _self.selectedFile : selectedFile // ignore: cast_nullable_to_non_nullable
as File?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,processingStatus: null == processingStatus ? _self.processingStatus : processingStatus // ignore: cast_nullable_to_non_nullable
as AccountProcessingStatus,registrationMethod: null == registrationMethod ? _self.registrationMethod : registrationMethod // ignore: cast_nullable_to_non_nullable
as AccountRegistrationMethod,detectedOrders: null == detectedOrders ? _self.detectedOrders : detectedOrders // ignore: cast_nullable_to_non_nullable
as List<OrderModel>,detectedPlannings: null == detectedPlannings ? _self.detectedPlannings : detectedPlannings // ignore: cast_nullable_to_non_nullable
as List<PlanningModel>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  double initialBalance,  DateTime initialBalanceDate,  AccountType type,  String color,  String icon,  double? limit,  int? dueDay,  int? closingDay,  double? interestRate,  File? selectedFile,  String? fileName,  AccountProcessingStatus processingStatus,  AccountRegistrationMethod registrationMethod,  List<OrderModel> detectedOrders,  List<PlanningModel> detectedPlannings,  bool isLoading,  bool isSuccess,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountFormState() when $default != null:
return $default(_that.id,_that.name,_that.initialBalance,_that.initialBalanceDate,_that.type,_that.color,_that.icon,_that.limit,_that.dueDay,_that.closingDay,_that.interestRate,_that.selectedFile,_that.fileName,_that.processingStatus,_that.registrationMethod,_that.detectedOrders,_that.detectedPlannings,_that.isLoading,_that.isSuccess,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  double initialBalance,  DateTime initialBalanceDate,  AccountType type,  String color,  String icon,  double? limit,  int? dueDay,  int? closingDay,  double? interestRate,  File? selectedFile,  String? fileName,  AccountProcessingStatus processingStatus,  AccountRegistrationMethod registrationMethod,  List<OrderModel> detectedOrders,  List<PlanningModel> detectedPlannings,  bool isLoading,  bool isSuccess,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _AccountFormState():
return $default(_that.id,_that.name,_that.initialBalance,_that.initialBalanceDate,_that.type,_that.color,_that.icon,_that.limit,_that.dueDay,_that.closingDay,_that.interestRate,_that.selectedFile,_that.fileName,_that.processingStatus,_that.registrationMethod,_that.detectedOrders,_that.detectedPlannings,_that.isLoading,_that.isSuccess,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  double initialBalance,  DateTime initialBalanceDate,  AccountType type,  String color,  String icon,  double? limit,  int? dueDay,  int? closingDay,  double? interestRate,  File? selectedFile,  String? fileName,  AccountProcessingStatus processingStatus,  AccountRegistrationMethod registrationMethod,  List<OrderModel> detectedOrders,  List<PlanningModel> detectedPlannings,  bool isLoading,  bool isSuccess,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _AccountFormState() when $default != null:
return $default(_that.id,_that.name,_that.initialBalance,_that.initialBalanceDate,_that.type,_that.color,_that.icon,_that.limit,_that.dueDay,_that.closingDay,_that.interestRate,_that.selectedFile,_that.fileName,_that.processingStatus,_that.registrationMethod,_that.detectedOrders,_that.detectedPlannings,_that.isLoading,_that.isSuccess,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _AccountFormState extends AccountFormState {
  const _AccountFormState({required this.id, required this.name, required this.initialBalance, required this.initialBalanceDate, required this.type, required this.color, required this.icon, this.limit, this.dueDay, this.closingDay, this.interestRate, this.selectedFile, this.fileName, this.processingStatus = AccountProcessingStatus.none, this.registrationMethod = AccountRegistrationMethod.document, final  List<OrderModel> detectedOrders = const [], final  List<PlanningModel> detectedPlannings = const [], this.isLoading = false, this.isSuccess = false, this.errorMessage}): _detectedOrders = detectedOrders,_detectedPlannings = detectedPlannings,super._();
  

@override final  String id;
@override final  String name;
@override final  double initialBalance;
@override final  DateTime initialBalanceDate;
@override final  AccountType type;
@override final  String color;
@override final  String icon;
@override final  double? limit;
@override final  int? dueDay;
@override final  int? closingDay;
@override final  double? interestRate;
@override final  File? selectedFile;
@override final  String? fileName;
@override@JsonKey() final  AccountProcessingStatus processingStatus;
@override@JsonKey() final  AccountRegistrationMethod registrationMethod;
 final  List<OrderModel> _detectedOrders;
@override@JsonKey() List<OrderModel> get detectedOrders {
  if (_detectedOrders is EqualUnmodifiableListView) return _detectedOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_detectedOrders);
}

 final  List<PlanningModel> _detectedPlannings;
@override@JsonKey() List<PlanningModel> get detectedPlannings {
  if (_detectedPlannings is EqualUnmodifiableListView) return _detectedPlannings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_detectedPlannings);
}

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isSuccess;
@override final  String? errorMessage;

/// Create a copy of AccountFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountFormStateCopyWith<_AccountFormState> get copyWith => __$AccountFormStateCopyWithImpl<_AccountFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountFormState&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.initialBalance, initialBalance) || other.initialBalance == initialBalance)&&(identical(other.initialBalanceDate, initialBalanceDate) || other.initialBalanceDate == initialBalanceDate)&&(identical(other.type, type) || other.type == type)&&(identical(other.color, color) || other.color == color)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.dueDay, dueDay) || other.dueDay == dueDay)&&(identical(other.closingDay, closingDay) || other.closingDay == closingDay)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate)&&(identical(other.selectedFile, selectedFile) || other.selectedFile == selectedFile)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.processingStatus, processingStatus) || other.processingStatus == processingStatus)&&(identical(other.registrationMethod, registrationMethod) || other.registrationMethod == registrationMethod)&&const DeepCollectionEquality().equals(other._detectedOrders, _detectedOrders)&&const DeepCollectionEquality().equals(other._detectedPlannings, _detectedPlannings)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,name,initialBalance,initialBalanceDate,type,color,icon,limit,dueDay,closingDay,interestRate,selectedFile,fileName,processingStatus,registrationMethod,const DeepCollectionEquality().hash(_detectedOrders),const DeepCollectionEquality().hash(_detectedPlannings),isLoading,isSuccess,errorMessage]);

@override
String toString() {
  return 'AccountFormState(id: $id, name: $name, initialBalance: $initialBalance, initialBalanceDate: $initialBalanceDate, type: $type, color: $color, icon: $icon, limit: $limit, dueDay: $dueDay, closingDay: $closingDay, interestRate: $interestRate, selectedFile: $selectedFile, fileName: $fileName, processingStatus: $processingStatus, registrationMethod: $registrationMethod, detectedOrders: $detectedOrders, detectedPlannings: $detectedPlannings, isLoading: $isLoading, isSuccess: $isSuccess, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$AccountFormStateCopyWith<$Res> implements $AccountFormStateCopyWith<$Res> {
  factory _$AccountFormStateCopyWith(_AccountFormState value, $Res Function(_AccountFormState) _then) = __$AccountFormStateCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double initialBalance, DateTime initialBalanceDate, AccountType type, String color, String icon, double? limit, int? dueDay, int? closingDay, double? interestRate, File? selectedFile, String? fileName, AccountProcessingStatus processingStatus, AccountRegistrationMethod registrationMethod, List<OrderModel> detectedOrders, List<PlanningModel> detectedPlannings, bool isLoading, bool isSuccess, String? errorMessage
});




}
/// @nodoc
class __$AccountFormStateCopyWithImpl<$Res>
    implements _$AccountFormStateCopyWith<$Res> {
  __$AccountFormStateCopyWithImpl(this._self, this._then);

  final _AccountFormState _self;
  final $Res Function(_AccountFormState) _then;

/// Create a copy of AccountFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? initialBalance = null,Object? initialBalanceDate = null,Object? type = null,Object? color = null,Object? icon = null,Object? limit = freezed,Object? dueDay = freezed,Object? closingDay = freezed,Object? interestRate = freezed,Object? selectedFile = freezed,Object? fileName = freezed,Object? processingStatus = null,Object? registrationMethod = null,Object? detectedOrders = null,Object? detectedPlannings = null,Object? isLoading = null,Object? isSuccess = null,Object? errorMessage = freezed,}) {
  return _then(_AccountFormState(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,initialBalance: null == initialBalance ? _self.initialBalance : initialBalance // ignore: cast_nullable_to_non_nullable
as double,initialBalanceDate: null == initialBalanceDate ? _self.initialBalanceDate : initialBalanceDate // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AccountType,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as double?,dueDay: freezed == dueDay ? _self.dueDay : dueDay // ignore: cast_nullable_to_non_nullable
as int?,closingDay: freezed == closingDay ? _self.closingDay : closingDay // ignore: cast_nullable_to_non_nullable
as int?,interestRate: freezed == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double?,selectedFile: freezed == selectedFile ? _self.selectedFile : selectedFile // ignore: cast_nullable_to_non_nullable
as File?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,processingStatus: null == processingStatus ? _self.processingStatus : processingStatus // ignore: cast_nullable_to_non_nullable
as AccountProcessingStatus,registrationMethod: null == registrationMethod ? _self.registrationMethod : registrationMethod // ignore: cast_nullable_to_non_nullable
as AccountRegistrationMethod,detectedOrders: null == detectedOrders ? _self._detectedOrders : detectedOrders // ignore: cast_nullable_to_non_nullable
as List<OrderModel>,detectedPlannings: null == detectedPlannings ? _self._detectedPlannings : detectedPlannings // ignore: cast_nullable_to_non_nullable
as List<PlanningModel>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
