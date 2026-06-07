// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reconciliation_view_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReconciliationState {

 ReconciliationStep get step; AccountModel? get selectedAccount; File? get selectedFile; List<ReconciliationMatch> get matches;
/// Create a copy of ReconciliationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReconciliationStateCopyWith<ReconciliationState> get copyWith => _$ReconciliationStateCopyWithImpl<ReconciliationState>(this as ReconciliationState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReconciliationState&&(identical(other.step, step) || other.step == step)&&(identical(other.selectedAccount, selectedAccount) || other.selectedAccount == selectedAccount)&&(identical(other.selectedFile, selectedFile) || other.selectedFile == selectedFile)&&const DeepCollectionEquality().equals(other.matches, matches));
}


@override
int get hashCode => Object.hash(runtimeType,step,selectedAccount,selectedFile,const DeepCollectionEquality().hash(matches));

@override
String toString() {
  return 'ReconciliationState(step: $step, selectedAccount: $selectedAccount, selectedFile: $selectedFile, matches: $matches)';
}


}

/// @nodoc
abstract mixin class $ReconciliationStateCopyWith<$Res>  {
  factory $ReconciliationStateCopyWith(ReconciliationState value, $Res Function(ReconciliationState) _then) = _$ReconciliationStateCopyWithImpl;
@useResult
$Res call({
 ReconciliationStep step, AccountModel? selectedAccount, File? selectedFile, List<ReconciliationMatch> matches
});


$AccountModelCopyWith<$Res>? get selectedAccount;

}
/// @nodoc
class _$ReconciliationStateCopyWithImpl<$Res>
    implements $ReconciliationStateCopyWith<$Res> {
  _$ReconciliationStateCopyWithImpl(this._self, this._then);

  final ReconciliationState _self;
  final $Res Function(ReconciliationState) _then;

/// Create a copy of ReconciliationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? selectedAccount = freezed,Object? selectedFile = freezed,Object? matches = null,}) {
  return _then(_self.copyWith(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as ReconciliationStep,selectedAccount: freezed == selectedAccount ? _self.selectedAccount : selectedAccount // ignore: cast_nullable_to_non_nullable
as AccountModel?,selectedFile: freezed == selectedFile ? _self.selectedFile : selectedFile // ignore: cast_nullable_to_non_nullable
as File?,matches: null == matches ? _self.matches : matches // ignore: cast_nullable_to_non_nullable
as List<ReconciliationMatch>,
  ));
}
/// Create a copy of ReconciliationState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountModelCopyWith<$Res>? get selectedAccount {
    if (_self.selectedAccount == null) {
    return null;
  }

  return $AccountModelCopyWith<$Res>(_self.selectedAccount!, (value) {
    return _then(_self.copyWith(selectedAccount: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReconciliationState].
extension ReconciliationStatePatterns on ReconciliationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReconciliationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReconciliationState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReconciliationState value)  $default,){
final _that = this;
switch (_that) {
case _ReconciliationState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReconciliationState value)?  $default,){
final _that = this;
switch (_that) {
case _ReconciliationState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReconciliationStep step,  AccountModel? selectedAccount,  File? selectedFile,  List<ReconciliationMatch> matches)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReconciliationState() when $default != null:
return $default(_that.step,_that.selectedAccount,_that.selectedFile,_that.matches);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReconciliationStep step,  AccountModel? selectedAccount,  File? selectedFile,  List<ReconciliationMatch> matches)  $default,) {final _that = this;
switch (_that) {
case _ReconciliationState():
return $default(_that.step,_that.selectedAccount,_that.selectedFile,_that.matches);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReconciliationStep step,  AccountModel? selectedAccount,  File? selectedFile,  List<ReconciliationMatch> matches)?  $default,) {final _that = this;
switch (_that) {
case _ReconciliationState() when $default != null:
return $default(_that.step,_that.selectedAccount,_that.selectedFile,_that.matches);case _:
  return null;

}
}

}

/// @nodoc


class _ReconciliationState implements ReconciliationState {
  const _ReconciliationState({this.step = ReconciliationStep.selectAccount, this.selectedAccount, this.selectedFile, final  List<ReconciliationMatch> matches = const []}): _matches = matches;
  

@override@JsonKey() final  ReconciliationStep step;
@override final  AccountModel? selectedAccount;
@override final  File? selectedFile;
 final  List<ReconciliationMatch> _matches;
@override@JsonKey() List<ReconciliationMatch> get matches {
  if (_matches is EqualUnmodifiableListView) return _matches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_matches);
}


/// Create a copy of ReconciliationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReconciliationStateCopyWith<_ReconciliationState> get copyWith => __$ReconciliationStateCopyWithImpl<_ReconciliationState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReconciliationState&&(identical(other.step, step) || other.step == step)&&(identical(other.selectedAccount, selectedAccount) || other.selectedAccount == selectedAccount)&&(identical(other.selectedFile, selectedFile) || other.selectedFile == selectedFile)&&const DeepCollectionEquality().equals(other._matches, _matches));
}


@override
int get hashCode => Object.hash(runtimeType,step,selectedAccount,selectedFile,const DeepCollectionEquality().hash(_matches));

@override
String toString() {
  return 'ReconciliationState(step: $step, selectedAccount: $selectedAccount, selectedFile: $selectedFile, matches: $matches)';
}


}

/// @nodoc
abstract mixin class _$ReconciliationStateCopyWith<$Res> implements $ReconciliationStateCopyWith<$Res> {
  factory _$ReconciliationStateCopyWith(_ReconciliationState value, $Res Function(_ReconciliationState) _then) = __$ReconciliationStateCopyWithImpl;
@override @useResult
$Res call({
 ReconciliationStep step, AccountModel? selectedAccount, File? selectedFile, List<ReconciliationMatch> matches
});


@override $AccountModelCopyWith<$Res>? get selectedAccount;

}
/// @nodoc
class __$ReconciliationStateCopyWithImpl<$Res>
    implements _$ReconciliationStateCopyWith<$Res> {
  __$ReconciliationStateCopyWithImpl(this._self, this._then);

  final _ReconciliationState _self;
  final $Res Function(_ReconciliationState) _then;

/// Create a copy of ReconciliationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? selectedAccount = freezed,Object? selectedFile = freezed,Object? matches = null,}) {
  return _then(_ReconciliationState(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as ReconciliationStep,selectedAccount: freezed == selectedAccount ? _self.selectedAccount : selectedAccount // ignore: cast_nullable_to_non_nullable
as AccountModel?,selectedFile: freezed == selectedFile ? _self.selectedFile : selectedFile // ignore: cast_nullable_to_non_nullable
as File?,matches: null == matches ? _self._matches : matches // ignore: cast_nullable_to_non_nullable
as List<ReconciliationMatch>,
  ));
}

/// Create a copy of ReconciliationState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountModelCopyWith<$Res>? get selectedAccount {
    if (_self.selectedAccount == null) {
    return null;
  }

  return $AccountModelCopyWith<$Res>(_self.selectedAccount!, (value) {
    return _then(_self.copyWith(selectedAccount: value));
  });
}
}

// dart format on
