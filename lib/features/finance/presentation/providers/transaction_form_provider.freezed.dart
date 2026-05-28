// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_form_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransactionFormState {

 TransactionType get currentType; TransactionFormType get formType; String get description; double get amount; int get installments; DateTime get selectedDate; CategoryModel? get selectedCategory; String? get selectedAccountId; String? get toAccountId; String? get existingOrderId; String? get planningId; bool get isTransfer; bool get isLoading; String? get errorMessage; bool get isSuccess;
/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFormStateCopyWith<TransactionFormState> get copyWith => _$TransactionFormStateCopyWithImpl<TransactionFormState>(this as TransactionFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormState&&(identical(other.currentType, currentType) || other.currentType == currentType)&&(identical(other.formType, formType) || other.formType == formType)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.installments, installments) || other.installments == installments)&&(identical(other.selectedDate, selectedDate) || other.selectedDate == selectedDate)&&(identical(other.selectedCategory, selectedCategory) || other.selectedCategory == selectedCategory)&&(identical(other.selectedAccountId, selectedAccountId) || other.selectedAccountId == selectedAccountId)&&(identical(other.toAccountId, toAccountId) || other.toAccountId == toAccountId)&&(identical(other.existingOrderId, existingOrderId) || other.existingOrderId == existingOrderId)&&(identical(other.planningId, planningId) || other.planningId == planningId)&&(identical(other.isTransfer, isTransfer) || other.isTransfer == isTransfer)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess));
}


@override
int get hashCode => Object.hash(runtimeType,currentType,formType,description,amount,installments,selectedDate,selectedCategory,selectedAccountId,toAccountId,existingOrderId,planningId,isTransfer,isLoading,errorMessage,isSuccess);

@override
String toString() {
  return 'TransactionFormState(currentType: $currentType, formType: $formType, description: $description, amount: $amount, installments: $installments, selectedDate: $selectedDate, selectedCategory: $selectedCategory, selectedAccountId: $selectedAccountId, toAccountId: $toAccountId, existingOrderId: $existingOrderId, planningId: $planningId, isTransfer: $isTransfer, isLoading: $isLoading, errorMessage: $errorMessage, isSuccess: $isSuccess)';
}


}

/// @nodoc
abstract mixin class $TransactionFormStateCopyWith<$Res>  {
  factory $TransactionFormStateCopyWith(TransactionFormState value, $Res Function(TransactionFormState) _then) = _$TransactionFormStateCopyWithImpl;
@useResult
$Res call({
 TransactionType currentType, TransactionFormType formType, String description, double amount, int installments, DateTime selectedDate, CategoryModel? selectedCategory, String? selectedAccountId, String? toAccountId, String? existingOrderId, String? planningId, bool isTransfer, bool isLoading, String? errorMessage, bool isSuccess
});


$CategoryModelCopyWith<$Res>? get selectedCategory;

}
/// @nodoc
class _$TransactionFormStateCopyWithImpl<$Res>
    implements $TransactionFormStateCopyWith<$Res> {
  _$TransactionFormStateCopyWithImpl(this._self, this._then);

  final TransactionFormState _self;
  final $Res Function(TransactionFormState) _then;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentType = null,Object? formType = null,Object? description = null,Object? amount = null,Object? installments = null,Object? selectedDate = null,Object? selectedCategory = freezed,Object? selectedAccountId = freezed,Object? toAccountId = freezed,Object? existingOrderId = freezed,Object? planningId = freezed,Object? isTransfer = null,Object? isLoading = null,Object? errorMessage = freezed,Object? isSuccess = null,}) {
  return _then(_self.copyWith(
currentType: null == currentType ? _self.currentType : currentType // ignore: cast_nullable_to_non_nullable
as TransactionType,formType: null == formType ? _self.formType : formType // ignore: cast_nullable_to_non_nullable
as TransactionFormType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,installments: null == installments ? _self.installments : installments // ignore: cast_nullable_to_non_nullable
as int,selectedDate: null == selectedDate ? _self.selectedDate : selectedDate // ignore: cast_nullable_to_non_nullable
as DateTime,selectedCategory: freezed == selectedCategory ? _self.selectedCategory : selectedCategory // ignore: cast_nullable_to_non_nullable
as CategoryModel?,selectedAccountId: freezed == selectedAccountId ? _self.selectedAccountId : selectedAccountId // ignore: cast_nullable_to_non_nullable
as String?,toAccountId: freezed == toAccountId ? _self.toAccountId : toAccountId // ignore: cast_nullable_to_non_nullable
as String?,existingOrderId: freezed == existingOrderId ? _self.existingOrderId : existingOrderId // ignore: cast_nullable_to_non_nullable
as String?,planningId: freezed == planningId ? _self.planningId : planningId // ignore: cast_nullable_to_non_nullable
as String?,isTransfer: null == isTransfer ? _self.isTransfer : isTransfer // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get selectedCategory {
    if (_self.selectedCategory == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.selectedCategory!, (value) {
    return _then(_self.copyWith(selectedCategory: value));
  });
}
}


/// Adds pattern-matching-related methods to [TransactionFormState].
extension TransactionFormStatePatterns on TransactionFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionFormState value)  $default,){
final _that = this;
switch (_that) {
case _TransactionFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionFormState value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TransactionType currentType,  TransactionFormType formType,  String description,  double amount,  int installments,  DateTime selectedDate,  CategoryModel? selectedCategory,  String? selectedAccountId,  String? toAccountId,  String? existingOrderId,  String? planningId,  bool isTransfer,  bool isLoading,  String? errorMessage,  bool isSuccess)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionFormState() when $default != null:
return $default(_that.currentType,_that.formType,_that.description,_that.amount,_that.installments,_that.selectedDate,_that.selectedCategory,_that.selectedAccountId,_that.toAccountId,_that.existingOrderId,_that.planningId,_that.isTransfer,_that.isLoading,_that.errorMessage,_that.isSuccess);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TransactionType currentType,  TransactionFormType formType,  String description,  double amount,  int installments,  DateTime selectedDate,  CategoryModel? selectedCategory,  String? selectedAccountId,  String? toAccountId,  String? existingOrderId,  String? planningId,  bool isTransfer,  bool isLoading,  String? errorMessage,  bool isSuccess)  $default,) {final _that = this;
switch (_that) {
case _TransactionFormState():
return $default(_that.currentType,_that.formType,_that.description,_that.amount,_that.installments,_that.selectedDate,_that.selectedCategory,_that.selectedAccountId,_that.toAccountId,_that.existingOrderId,_that.planningId,_that.isTransfer,_that.isLoading,_that.errorMessage,_that.isSuccess);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TransactionType currentType,  TransactionFormType formType,  String description,  double amount,  int installments,  DateTime selectedDate,  CategoryModel? selectedCategory,  String? selectedAccountId,  String? toAccountId,  String? existingOrderId,  String? planningId,  bool isTransfer,  bool isLoading,  String? errorMessage,  bool isSuccess)?  $default,) {final _that = this;
switch (_that) {
case _TransactionFormState() when $default != null:
return $default(_that.currentType,_that.formType,_that.description,_that.amount,_that.installments,_that.selectedDate,_that.selectedCategory,_that.selectedAccountId,_that.toAccountId,_that.existingOrderId,_that.planningId,_that.isTransfer,_that.isLoading,_that.errorMessage,_that.isSuccess);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionFormState extends TransactionFormState {
  const _TransactionFormState({required this.currentType, required this.formType, required this.description, required this.amount, required this.installments, required this.selectedDate, this.selectedCategory, this.selectedAccountId, this.toAccountId, this.existingOrderId, this.planningId, required this.isTransfer, this.isLoading = false, this.errorMessage, this.isSuccess = false}): super._();
  

@override final  TransactionType currentType;
@override final  TransactionFormType formType;
@override final  String description;
@override final  double amount;
@override final  int installments;
@override final  DateTime selectedDate;
@override final  CategoryModel? selectedCategory;
@override final  String? selectedAccountId;
@override final  String? toAccountId;
@override final  String? existingOrderId;
@override final  String? planningId;
@override final  bool isTransfer;
@override@JsonKey() final  bool isLoading;
@override final  String? errorMessage;
@override@JsonKey() final  bool isSuccess;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionFormStateCopyWith<_TransactionFormState> get copyWith => __$TransactionFormStateCopyWithImpl<_TransactionFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionFormState&&(identical(other.currentType, currentType) || other.currentType == currentType)&&(identical(other.formType, formType) || other.formType == formType)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.installments, installments) || other.installments == installments)&&(identical(other.selectedDate, selectedDate) || other.selectedDate == selectedDate)&&(identical(other.selectedCategory, selectedCategory) || other.selectedCategory == selectedCategory)&&(identical(other.selectedAccountId, selectedAccountId) || other.selectedAccountId == selectedAccountId)&&(identical(other.toAccountId, toAccountId) || other.toAccountId == toAccountId)&&(identical(other.existingOrderId, existingOrderId) || other.existingOrderId == existingOrderId)&&(identical(other.planningId, planningId) || other.planningId == planningId)&&(identical(other.isTransfer, isTransfer) || other.isTransfer == isTransfer)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess));
}


@override
int get hashCode => Object.hash(runtimeType,currentType,formType,description,amount,installments,selectedDate,selectedCategory,selectedAccountId,toAccountId,existingOrderId,planningId,isTransfer,isLoading,errorMessage,isSuccess);

@override
String toString() {
  return 'TransactionFormState(currentType: $currentType, formType: $formType, description: $description, amount: $amount, installments: $installments, selectedDate: $selectedDate, selectedCategory: $selectedCategory, selectedAccountId: $selectedAccountId, toAccountId: $toAccountId, existingOrderId: $existingOrderId, planningId: $planningId, isTransfer: $isTransfer, isLoading: $isLoading, errorMessage: $errorMessage, isSuccess: $isSuccess)';
}


}

/// @nodoc
abstract mixin class _$TransactionFormStateCopyWith<$Res> implements $TransactionFormStateCopyWith<$Res> {
  factory _$TransactionFormStateCopyWith(_TransactionFormState value, $Res Function(_TransactionFormState) _then) = __$TransactionFormStateCopyWithImpl;
@override @useResult
$Res call({
 TransactionType currentType, TransactionFormType formType, String description, double amount, int installments, DateTime selectedDate, CategoryModel? selectedCategory, String? selectedAccountId, String? toAccountId, String? existingOrderId, String? planningId, bool isTransfer, bool isLoading, String? errorMessage, bool isSuccess
});


@override $CategoryModelCopyWith<$Res>? get selectedCategory;

}
/// @nodoc
class __$TransactionFormStateCopyWithImpl<$Res>
    implements _$TransactionFormStateCopyWith<$Res> {
  __$TransactionFormStateCopyWithImpl(this._self, this._then);

  final _TransactionFormState _self;
  final $Res Function(_TransactionFormState) _then;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentType = null,Object? formType = null,Object? description = null,Object? amount = null,Object? installments = null,Object? selectedDate = null,Object? selectedCategory = freezed,Object? selectedAccountId = freezed,Object? toAccountId = freezed,Object? existingOrderId = freezed,Object? planningId = freezed,Object? isTransfer = null,Object? isLoading = null,Object? errorMessage = freezed,Object? isSuccess = null,}) {
  return _then(_TransactionFormState(
currentType: null == currentType ? _self.currentType : currentType // ignore: cast_nullable_to_non_nullable
as TransactionType,formType: null == formType ? _self.formType : formType // ignore: cast_nullable_to_non_nullable
as TransactionFormType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,installments: null == installments ? _self.installments : installments // ignore: cast_nullable_to_non_nullable
as int,selectedDate: null == selectedDate ? _self.selectedDate : selectedDate // ignore: cast_nullable_to_non_nullable
as DateTime,selectedCategory: freezed == selectedCategory ? _self.selectedCategory : selectedCategory // ignore: cast_nullable_to_non_nullable
as CategoryModel?,selectedAccountId: freezed == selectedAccountId ? _self.selectedAccountId : selectedAccountId // ignore: cast_nullable_to_non_nullable
as String?,toAccountId: freezed == toAccountId ? _self.toAccountId : toAccountId // ignore: cast_nullable_to_non_nullable
as String?,existingOrderId: freezed == existingOrderId ? _self.existingOrderId : existingOrderId // ignore: cast_nullable_to_non_nullable
as String?,planningId: freezed == planningId ? _self.planningId : planningId // ignore: cast_nullable_to_non_nullable
as String?,isTransfer: null == isTransfer ? _self.isTransfer : isTransfer // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get selectedCategory {
    if (_self.selectedCategory == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.selectedCategory!, (value) {
    return _then(_self.copyWith(selectedCategory: value));
  });
}
}

// dart format on
