// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingState {

 int get currentStep; int get currentSubStep;// Para navegar dentro de passos complexos
 WorkspaceType? get workspaceType; String get workspaceName; bool get isSubmitting; String get createdWorkspaceId; bool get isFinalizing; List<String> get inviteEmails; List<AccountModel> get onboardingAccounts; List<GoalModel> get onboardingGoals; List<OrderModel> get onboardingOrders; List<PlanningModel> get onboardingPlannings; bool get isAnalyzing; String? get analysisError;
/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingStateCopyWith<OnboardingState> get copyWith => _$OnboardingStateCopyWithImpl<OnboardingState>(this as OnboardingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingState&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.currentSubStep, currentSubStep) || other.currentSubStep == currentSubStep)&&(identical(other.workspaceType, workspaceType) || other.workspaceType == workspaceType)&&(identical(other.workspaceName, workspaceName) || other.workspaceName == workspaceName)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.createdWorkspaceId, createdWorkspaceId) || other.createdWorkspaceId == createdWorkspaceId)&&(identical(other.isFinalizing, isFinalizing) || other.isFinalizing == isFinalizing)&&const DeepCollectionEquality().equals(other.inviteEmails, inviteEmails)&&const DeepCollectionEquality().equals(other.onboardingAccounts, onboardingAccounts)&&const DeepCollectionEquality().equals(other.onboardingGoals, onboardingGoals)&&const DeepCollectionEquality().equals(other.onboardingOrders, onboardingOrders)&&const DeepCollectionEquality().equals(other.onboardingPlannings, onboardingPlannings)&&(identical(other.isAnalyzing, isAnalyzing) || other.isAnalyzing == isAnalyzing)&&(identical(other.analysisError, analysisError) || other.analysisError == analysisError));
}


@override
int get hashCode => Object.hash(runtimeType,currentStep,currentSubStep,workspaceType,workspaceName,isSubmitting,createdWorkspaceId,isFinalizing,const DeepCollectionEquality().hash(inviteEmails),const DeepCollectionEquality().hash(onboardingAccounts),const DeepCollectionEquality().hash(onboardingGoals),const DeepCollectionEquality().hash(onboardingOrders),const DeepCollectionEquality().hash(onboardingPlannings),isAnalyzing,analysisError);

@override
String toString() {
  return 'OnboardingState(currentStep: $currentStep, currentSubStep: $currentSubStep, workspaceType: $workspaceType, workspaceName: $workspaceName, isSubmitting: $isSubmitting, createdWorkspaceId: $createdWorkspaceId, isFinalizing: $isFinalizing, inviteEmails: $inviteEmails, onboardingAccounts: $onboardingAccounts, onboardingGoals: $onboardingGoals, onboardingOrders: $onboardingOrders, onboardingPlannings: $onboardingPlannings, isAnalyzing: $isAnalyzing, analysisError: $analysisError)';
}


}

/// @nodoc
abstract mixin class $OnboardingStateCopyWith<$Res>  {
  factory $OnboardingStateCopyWith(OnboardingState value, $Res Function(OnboardingState) _then) = _$OnboardingStateCopyWithImpl;
@useResult
$Res call({
 int currentStep, int currentSubStep, WorkspaceType? workspaceType, String workspaceName, bool isSubmitting, String createdWorkspaceId, bool isFinalizing, List<String> inviteEmails, List<AccountModel> onboardingAccounts, List<GoalModel> onboardingGoals, List<OrderModel> onboardingOrders, List<PlanningModel> onboardingPlannings, bool isAnalyzing, String? analysisError
});




}
/// @nodoc
class _$OnboardingStateCopyWithImpl<$Res>
    implements $OnboardingStateCopyWith<$Res> {
  _$OnboardingStateCopyWithImpl(this._self, this._then);

  final OnboardingState _self;
  final $Res Function(OnboardingState) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentStep = null,Object? currentSubStep = null,Object? workspaceType = freezed,Object? workspaceName = null,Object? isSubmitting = null,Object? createdWorkspaceId = null,Object? isFinalizing = null,Object? inviteEmails = null,Object? onboardingAccounts = null,Object? onboardingGoals = null,Object? onboardingOrders = null,Object? onboardingPlannings = null,Object? isAnalyzing = null,Object? analysisError = freezed,}) {
  return _then(_self.copyWith(
currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,currentSubStep: null == currentSubStep ? _self.currentSubStep : currentSubStep // ignore: cast_nullable_to_non_nullable
as int,workspaceType: freezed == workspaceType ? _self.workspaceType : workspaceType // ignore: cast_nullable_to_non_nullable
as WorkspaceType?,workspaceName: null == workspaceName ? _self.workspaceName : workspaceName // ignore: cast_nullable_to_non_nullable
as String,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,createdWorkspaceId: null == createdWorkspaceId ? _self.createdWorkspaceId : createdWorkspaceId // ignore: cast_nullable_to_non_nullable
as String,isFinalizing: null == isFinalizing ? _self.isFinalizing : isFinalizing // ignore: cast_nullable_to_non_nullable
as bool,inviteEmails: null == inviteEmails ? _self.inviteEmails : inviteEmails // ignore: cast_nullable_to_non_nullable
as List<String>,onboardingAccounts: null == onboardingAccounts ? _self.onboardingAccounts : onboardingAccounts // ignore: cast_nullable_to_non_nullable
as List<AccountModel>,onboardingGoals: null == onboardingGoals ? _self.onboardingGoals : onboardingGoals // ignore: cast_nullable_to_non_nullable
as List<GoalModel>,onboardingOrders: null == onboardingOrders ? _self.onboardingOrders : onboardingOrders // ignore: cast_nullable_to_non_nullable
as List<OrderModel>,onboardingPlannings: null == onboardingPlannings ? _self.onboardingPlannings : onboardingPlannings // ignore: cast_nullable_to_non_nullable
as List<PlanningModel>,isAnalyzing: null == isAnalyzing ? _self.isAnalyzing : isAnalyzing // ignore: cast_nullable_to_non_nullable
as bool,analysisError: freezed == analysisError ? _self.analysisError : analysisError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OnboardingState].
extension OnboardingStatePatterns on OnboardingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingState value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingState value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentStep,  int currentSubStep,  WorkspaceType? workspaceType,  String workspaceName,  bool isSubmitting,  String createdWorkspaceId,  bool isFinalizing,  List<String> inviteEmails,  List<AccountModel> onboardingAccounts,  List<GoalModel> onboardingGoals,  List<OrderModel> onboardingOrders,  List<PlanningModel> onboardingPlannings,  bool isAnalyzing,  String? analysisError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
return $default(_that.currentStep,_that.currentSubStep,_that.workspaceType,_that.workspaceName,_that.isSubmitting,_that.createdWorkspaceId,_that.isFinalizing,_that.inviteEmails,_that.onboardingAccounts,_that.onboardingGoals,_that.onboardingOrders,_that.onboardingPlannings,_that.isAnalyzing,_that.analysisError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentStep,  int currentSubStep,  WorkspaceType? workspaceType,  String workspaceName,  bool isSubmitting,  String createdWorkspaceId,  bool isFinalizing,  List<String> inviteEmails,  List<AccountModel> onboardingAccounts,  List<GoalModel> onboardingGoals,  List<OrderModel> onboardingOrders,  List<PlanningModel> onboardingPlannings,  bool isAnalyzing,  String? analysisError)  $default,) {final _that = this;
switch (_that) {
case _OnboardingState():
return $default(_that.currentStep,_that.currentSubStep,_that.workspaceType,_that.workspaceName,_that.isSubmitting,_that.createdWorkspaceId,_that.isFinalizing,_that.inviteEmails,_that.onboardingAccounts,_that.onboardingGoals,_that.onboardingOrders,_that.onboardingPlannings,_that.isAnalyzing,_that.analysisError);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentStep,  int currentSubStep,  WorkspaceType? workspaceType,  String workspaceName,  bool isSubmitting,  String createdWorkspaceId,  bool isFinalizing,  List<String> inviteEmails,  List<AccountModel> onboardingAccounts,  List<GoalModel> onboardingGoals,  List<OrderModel> onboardingOrders,  List<PlanningModel> onboardingPlannings,  bool isAnalyzing,  String? analysisError)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
return $default(_that.currentStep,_that.currentSubStep,_that.workspaceType,_that.workspaceName,_that.isSubmitting,_that.createdWorkspaceId,_that.isFinalizing,_that.inviteEmails,_that.onboardingAccounts,_that.onboardingGoals,_that.onboardingOrders,_that.onboardingPlannings,_that.isAnalyzing,_that.analysisError);case _:
  return null;

}
}

}

/// @nodoc


class _OnboardingState extends OnboardingState {
  const _OnboardingState({this.currentStep = 0, this.currentSubStep = 0, this.workspaceType, this.workspaceName = '', this.isSubmitting = false, this.createdWorkspaceId = '', this.isFinalizing = false, final  List<String> inviteEmails = const [], final  List<AccountModel> onboardingAccounts = const [], final  List<GoalModel> onboardingGoals = const [], final  List<OrderModel> onboardingOrders = const [], final  List<PlanningModel> onboardingPlannings = const [], this.isAnalyzing = false, this.analysisError}): _inviteEmails = inviteEmails,_onboardingAccounts = onboardingAccounts,_onboardingGoals = onboardingGoals,_onboardingOrders = onboardingOrders,_onboardingPlannings = onboardingPlannings,super._();
  

@override@JsonKey() final  int currentStep;
@override@JsonKey() final  int currentSubStep;
// Para navegar dentro de passos complexos
@override final  WorkspaceType? workspaceType;
@override@JsonKey() final  String workspaceName;
@override@JsonKey() final  bool isSubmitting;
@override@JsonKey() final  String createdWorkspaceId;
@override@JsonKey() final  bool isFinalizing;
 final  List<String> _inviteEmails;
@override@JsonKey() List<String> get inviteEmails {
  if (_inviteEmails is EqualUnmodifiableListView) return _inviteEmails;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inviteEmails);
}

 final  List<AccountModel> _onboardingAccounts;
@override@JsonKey() List<AccountModel> get onboardingAccounts {
  if (_onboardingAccounts is EqualUnmodifiableListView) return _onboardingAccounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_onboardingAccounts);
}

 final  List<GoalModel> _onboardingGoals;
@override@JsonKey() List<GoalModel> get onboardingGoals {
  if (_onboardingGoals is EqualUnmodifiableListView) return _onboardingGoals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_onboardingGoals);
}

 final  List<OrderModel> _onboardingOrders;
@override@JsonKey() List<OrderModel> get onboardingOrders {
  if (_onboardingOrders is EqualUnmodifiableListView) return _onboardingOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_onboardingOrders);
}

 final  List<PlanningModel> _onboardingPlannings;
@override@JsonKey() List<PlanningModel> get onboardingPlannings {
  if (_onboardingPlannings is EqualUnmodifiableListView) return _onboardingPlannings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_onboardingPlannings);
}

@override@JsonKey() final  bool isAnalyzing;
@override final  String? analysisError;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingStateCopyWith<_OnboardingState> get copyWith => __$OnboardingStateCopyWithImpl<_OnboardingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingState&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.currentSubStep, currentSubStep) || other.currentSubStep == currentSubStep)&&(identical(other.workspaceType, workspaceType) || other.workspaceType == workspaceType)&&(identical(other.workspaceName, workspaceName) || other.workspaceName == workspaceName)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.createdWorkspaceId, createdWorkspaceId) || other.createdWorkspaceId == createdWorkspaceId)&&(identical(other.isFinalizing, isFinalizing) || other.isFinalizing == isFinalizing)&&const DeepCollectionEquality().equals(other._inviteEmails, _inviteEmails)&&const DeepCollectionEquality().equals(other._onboardingAccounts, _onboardingAccounts)&&const DeepCollectionEquality().equals(other._onboardingGoals, _onboardingGoals)&&const DeepCollectionEquality().equals(other._onboardingOrders, _onboardingOrders)&&const DeepCollectionEquality().equals(other._onboardingPlannings, _onboardingPlannings)&&(identical(other.isAnalyzing, isAnalyzing) || other.isAnalyzing == isAnalyzing)&&(identical(other.analysisError, analysisError) || other.analysisError == analysisError));
}


@override
int get hashCode => Object.hash(runtimeType,currentStep,currentSubStep,workspaceType,workspaceName,isSubmitting,createdWorkspaceId,isFinalizing,const DeepCollectionEquality().hash(_inviteEmails),const DeepCollectionEquality().hash(_onboardingAccounts),const DeepCollectionEquality().hash(_onboardingGoals),const DeepCollectionEquality().hash(_onboardingOrders),const DeepCollectionEquality().hash(_onboardingPlannings),isAnalyzing,analysisError);

@override
String toString() {
  return 'OnboardingState(currentStep: $currentStep, currentSubStep: $currentSubStep, workspaceType: $workspaceType, workspaceName: $workspaceName, isSubmitting: $isSubmitting, createdWorkspaceId: $createdWorkspaceId, isFinalizing: $isFinalizing, inviteEmails: $inviteEmails, onboardingAccounts: $onboardingAccounts, onboardingGoals: $onboardingGoals, onboardingOrders: $onboardingOrders, onboardingPlannings: $onboardingPlannings, isAnalyzing: $isAnalyzing, analysisError: $analysisError)';
}


}

/// @nodoc
abstract mixin class _$OnboardingStateCopyWith<$Res> implements $OnboardingStateCopyWith<$Res> {
  factory _$OnboardingStateCopyWith(_OnboardingState value, $Res Function(_OnboardingState) _then) = __$OnboardingStateCopyWithImpl;
@override @useResult
$Res call({
 int currentStep, int currentSubStep, WorkspaceType? workspaceType, String workspaceName, bool isSubmitting, String createdWorkspaceId, bool isFinalizing, List<String> inviteEmails, List<AccountModel> onboardingAccounts, List<GoalModel> onboardingGoals, List<OrderModel> onboardingOrders, List<PlanningModel> onboardingPlannings, bool isAnalyzing, String? analysisError
});




}
/// @nodoc
class __$OnboardingStateCopyWithImpl<$Res>
    implements _$OnboardingStateCopyWith<$Res> {
  __$OnboardingStateCopyWithImpl(this._self, this._then);

  final _OnboardingState _self;
  final $Res Function(_OnboardingState) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentStep = null,Object? currentSubStep = null,Object? workspaceType = freezed,Object? workspaceName = null,Object? isSubmitting = null,Object? createdWorkspaceId = null,Object? isFinalizing = null,Object? inviteEmails = null,Object? onboardingAccounts = null,Object? onboardingGoals = null,Object? onboardingOrders = null,Object? onboardingPlannings = null,Object? isAnalyzing = null,Object? analysisError = freezed,}) {
  return _then(_OnboardingState(
currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,currentSubStep: null == currentSubStep ? _self.currentSubStep : currentSubStep // ignore: cast_nullable_to_non_nullable
as int,workspaceType: freezed == workspaceType ? _self.workspaceType : workspaceType // ignore: cast_nullable_to_non_nullable
as WorkspaceType?,workspaceName: null == workspaceName ? _self.workspaceName : workspaceName // ignore: cast_nullable_to_non_nullable
as String,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,createdWorkspaceId: null == createdWorkspaceId ? _self.createdWorkspaceId : createdWorkspaceId // ignore: cast_nullable_to_non_nullable
as String,isFinalizing: null == isFinalizing ? _self.isFinalizing : isFinalizing // ignore: cast_nullable_to_non_nullable
as bool,inviteEmails: null == inviteEmails ? _self._inviteEmails : inviteEmails // ignore: cast_nullable_to_non_nullable
as List<String>,onboardingAccounts: null == onboardingAccounts ? _self._onboardingAccounts : onboardingAccounts // ignore: cast_nullable_to_non_nullable
as List<AccountModel>,onboardingGoals: null == onboardingGoals ? _self._onboardingGoals : onboardingGoals // ignore: cast_nullable_to_non_nullable
as List<GoalModel>,onboardingOrders: null == onboardingOrders ? _self._onboardingOrders : onboardingOrders // ignore: cast_nullable_to_non_nullable
as List<OrderModel>,onboardingPlannings: null == onboardingPlannings ? _self._onboardingPlannings : onboardingPlannings // ignore: cast_nullable_to_non_nullable
as List<PlanningModel>,isAnalyzing: null == isAnalyzing ? _self.isAnalyzing : isAnalyzing // ignore: cast_nullable_to_non_nullable
as bool,analysisError: freezed == analysisError ? _self.analysisError : analysisError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
