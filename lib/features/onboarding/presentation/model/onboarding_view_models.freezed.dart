// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_view_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingState {

 OnboardingSteps get currentStep; WorkspaceModel get workspace; List<String> get inviteEmails; List<AccountModel> get accounts; PlanningSuggestions? get planningSuggestions;
/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingStateCopyWith<OnboardingState> get copyWith => _$OnboardingStateCopyWithImpl<OnboardingState>(this as OnboardingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingState&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.workspace, workspace) || other.workspace == workspace)&&const DeepCollectionEquality().equals(other.inviteEmails, inviteEmails)&&const DeepCollectionEquality().equals(other.accounts, accounts)&&(identical(other.planningSuggestions, planningSuggestions) || other.planningSuggestions == planningSuggestions));
}


@override
int get hashCode => Object.hash(runtimeType,currentStep,workspace,const DeepCollectionEquality().hash(inviteEmails),const DeepCollectionEquality().hash(accounts),planningSuggestions);

@override
String toString() {
  return 'OnboardingState(currentStep: $currentStep, workspace: $workspace, inviteEmails: $inviteEmails, accounts: $accounts, planningSuggestions: $planningSuggestions)';
}


}

/// @nodoc
abstract mixin class $OnboardingStateCopyWith<$Res>  {
  factory $OnboardingStateCopyWith(OnboardingState value, $Res Function(OnboardingState) _then) = _$OnboardingStateCopyWithImpl;
@useResult
$Res call({
 OnboardingSteps currentStep, WorkspaceModel workspace, List<String> inviteEmails, List<AccountModel> accounts, PlanningSuggestions? planningSuggestions
});


$WorkspaceModelCopyWith<$Res> get workspace;$PlanningSuggestionsCopyWith<$Res>? get planningSuggestions;

}
/// @nodoc
class _$OnboardingStateCopyWithImpl<$Res>
    implements $OnboardingStateCopyWith<$Res> {
  _$OnboardingStateCopyWithImpl(this._self, this._then);

  final OnboardingState _self;
  final $Res Function(OnboardingState) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentStep = null,Object? workspace = null,Object? inviteEmails = null,Object? accounts = null,Object? planningSuggestions = freezed,}) {
  return _then(_self.copyWith(
currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as OnboardingSteps,workspace: null == workspace ? _self.workspace : workspace // ignore: cast_nullable_to_non_nullable
as WorkspaceModel,inviteEmails: null == inviteEmails ? _self.inviteEmails : inviteEmails // ignore: cast_nullable_to_non_nullable
as List<String>,accounts: null == accounts ? _self.accounts : accounts // ignore: cast_nullable_to_non_nullable
as List<AccountModel>,planningSuggestions: freezed == planningSuggestions ? _self.planningSuggestions : planningSuggestions // ignore: cast_nullable_to_non_nullable
as PlanningSuggestions?,
  ));
}
/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkspaceModelCopyWith<$Res> get workspace {
  
  return $WorkspaceModelCopyWith<$Res>(_self.workspace, (value) {
    return _then(_self.copyWith(workspace: value));
  });
}/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanningSuggestionsCopyWith<$Res>? get planningSuggestions {
    if (_self.planningSuggestions == null) {
    return null;
  }

  return $PlanningSuggestionsCopyWith<$Res>(_self.planningSuggestions!, (value) {
    return _then(_self.copyWith(planningSuggestions: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OnboardingSteps currentStep,  WorkspaceModel workspace,  List<String> inviteEmails,  List<AccountModel> accounts,  PlanningSuggestions? planningSuggestions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
return $default(_that.currentStep,_that.workspace,_that.inviteEmails,_that.accounts,_that.planningSuggestions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OnboardingSteps currentStep,  WorkspaceModel workspace,  List<String> inviteEmails,  List<AccountModel> accounts,  PlanningSuggestions? planningSuggestions)  $default,) {final _that = this;
switch (_that) {
case _OnboardingState():
return $default(_that.currentStep,_that.workspace,_that.inviteEmails,_that.accounts,_that.planningSuggestions);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OnboardingSteps currentStep,  WorkspaceModel workspace,  List<String> inviteEmails,  List<AccountModel> accounts,  PlanningSuggestions? planningSuggestions)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
return $default(_that.currentStep,_that.workspace,_that.inviteEmails,_that.accounts,_that.planningSuggestions);case _:
  return null;

}
}

}

/// @nodoc


class _OnboardingState extends OnboardingState {
  const _OnboardingState({this.currentStep = OnboardingSteps.type, required this.workspace, final  List<String> inviteEmails = const [], final  List<AccountModel> accounts = const [], this.planningSuggestions}): _inviteEmails = inviteEmails,_accounts = accounts,super._();
  

@override@JsonKey() final  OnboardingSteps currentStep;
@override final  WorkspaceModel workspace;
 final  List<String> _inviteEmails;
@override@JsonKey() List<String> get inviteEmails {
  if (_inviteEmails is EqualUnmodifiableListView) return _inviteEmails;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inviteEmails);
}

 final  List<AccountModel> _accounts;
@override@JsonKey() List<AccountModel> get accounts {
  if (_accounts is EqualUnmodifiableListView) return _accounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_accounts);
}

@override final  PlanningSuggestions? planningSuggestions;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingStateCopyWith<_OnboardingState> get copyWith => __$OnboardingStateCopyWithImpl<_OnboardingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingState&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.workspace, workspace) || other.workspace == workspace)&&const DeepCollectionEquality().equals(other._inviteEmails, _inviteEmails)&&const DeepCollectionEquality().equals(other._accounts, _accounts)&&(identical(other.planningSuggestions, planningSuggestions) || other.planningSuggestions == planningSuggestions));
}


@override
int get hashCode => Object.hash(runtimeType,currentStep,workspace,const DeepCollectionEquality().hash(_inviteEmails),const DeepCollectionEquality().hash(_accounts),planningSuggestions);

@override
String toString() {
  return 'OnboardingState(currentStep: $currentStep, workspace: $workspace, inviteEmails: $inviteEmails, accounts: $accounts, planningSuggestions: $planningSuggestions)';
}


}

/// @nodoc
abstract mixin class _$OnboardingStateCopyWith<$Res> implements $OnboardingStateCopyWith<$Res> {
  factory _$OnboardingStateCopyWith(_OnboardingState value, $Res Function(_OnboardingState) _then) = __$OnboardingStateCopyWithImpl;
@override @useResult
$Res call({
 OnboardingSteps currentStep, WorkspaceModel workspace, List<String> inviteEmails, List<AccountModel> accounts, PlanningSuggestions? planningSuggestions
});


@override $WorkspaceModelCopyWith<$Res> get workspace;@override $PlanningSuggestionsCopyWith<$Res>? get planningSuggestions;

}
/// @nodoc
class __$OnboardingStateCopyWithImpl<$Res>
    implements _$OnboardingStateCopyWith<$Res> {
  __$OnboardingStateCopyWithImpl(this._self, this._then);

  final _OnboardingState _self;
  final $Res Function(_OnboardingState) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentStep = null,Object? workspace = null,Object? inviteEmails = null,Object? accounts = null,Object? planningSuggestions = freezed,}) {
  return _then(_OnboardingState(
currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as OnboardingSteps,workspace: null == workspace ? _self.workspace : workspace // ignore: cast_nullable_to_non_nullable
as WorkspaceModel,inviteEmails: null == inviteEmails ? _self._inviteEmails : inviteEmails // ignore: cast_nullable_to_non_nullable
as List<String>,accounts: null == accounts ? _self._accounts : accounts // ignore: cast_nullable_to_non_nullable
as List<AccountModel>,planningSuggestions: freezed == planningSuggestions ? _self.planningSuggestions : planningSuggestions // ignore: cast_nullable_to_non_nullable
as PlanningSuggestions?,
  ));
}

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkspaceModelCopyWith<$Res> get workspace {
  
  return $WorkspaceModelCopyWith<$Res>(_self.workspace, (value) {
    return _then(_self.copyWith(workspace: value));
  });
}/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanningSuggestionsCopyWith<$Res>? get planningSuggestions {
    if (_self.planningSuggestions == null) {
    return null;
  }

  return $PlanningSuggestionsCopyWith<$Res>(_self.planningSuggestions!, (value) {
    return _then(_self.copyWith(planningSuggestions: value));
  });
}
}

// dart format on
