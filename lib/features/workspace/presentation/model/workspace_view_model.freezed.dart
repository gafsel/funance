// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workspace_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkspaceState {

 WorkspaceModel? get currentWorkspace; List<WorkspaceModel> get availableWorkspaces; bool get isLoading; bool get initialLoadDone;
/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceStateCopyWith<WorkspaceState> get copyWith => _$WorkspaceStateCopyWithImpl<WorkspaceState>(this as WorkspaceState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceState&&(identical(other.currentWorkspace, currentWorkspace) || other.currentWorkspace == currentWorkspace)&&const DeepCollectionEquality().equals(other.availableWorkspaces, availableWorkspaces)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.initialLoadDone, initialLoadDone) || other.initialLoadDone == initialLoadDone));
}


@override
int get hashCode => Object.hash(runtimeType,currentWorkspace,const DeepCollectionEquality().hash(availableWorkspaces),isLoading,initialLoadDone);

@override
String toString() {
  return 'WorkspaceState(currentWorkspace: $currentWorkspace, availableWorkspaces: $availableWorkspaces, isLoading: $isLoading, initialLoadDone: $initialLoadDone)';
}


}

/// @nodoc
abstract mixin class $WorkspaceStateCopyWith<$Res>  {
  factory $WorkspaceStateCopyWith(WorkspaceState value, $Res Function(WorkspaceState) _then) = _$WorkspaceStateCopyWithImpl;
@useResult
$Res call({
 WorkspaceModel? currentWorkspace, List<WorkspaceModel> availableWorkspaces, bool isLoading, bool initialLoadDone
});


$WorkspaceModelCopyWith<$Res>? get currentWorkspace;

}
/// @nodoc
class _$WorkspaceStateCopyWithImpl<$Res>
    implements $WorkspaceStateCopyWith<$Res> {
  _$WorkspaceStateCopyWithImpl(this._self, this._then);

  final WorkspaceState _self;
  final $Res Function(WorkspaceState) _then;

/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentWorkspace = freezed,Object? availableWorkspaces = null,Object? isLoading = null,Object? initialLoadDone = null,}) {
  return _then(_self.copyWith(
currentWorkspace: freezed == currentWorkspace ? _self.currentWorkspace : currentWorkspace // ignore: cast_nullable_to_non_nullable
as WorkspaceModel?,availableWorkspaces: null == availableWorkspaces ? _self.availableWorkspaces : availableWorkspaces // ignore: cast_nullable_to_non_nullable
as List<WorkspaceModel>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,initialLoadDone: null == initialLoadDone ? _self.initialLoadDone : initialLoadDone // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkspaceModelCopyWith<$Res>? get currentWorkspace {
    if (_self.currentWorkspace == null) {
    return null;
  }

  return $WorkspaceModelCopyWith<$Res>(_self.currentWorkspace!, (value) {
    return _then(_self.copyWith(currentWorkspace: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkspaceState].
extension WorkspaceStatePatterns on WorkspaceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceState value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceState value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkspaceModel? currentWorkspace,  List<WorkspaceModel> availableWorkspaces,  bool isLoading,  bool initialLoadDone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceState() when $default != null:
return $default(_that.currentWorkspace,_that.availableWorkspaces,_that.isLoading,_that.initialLoadDone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkspaceModel? currentWorkspace,  List<WorkspaceModel> availableWorkspaces,  bool isLoading,  bool initialLoadDone)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceState():
return $default(_that.currentWorkspace,_that.availableWorkspaces,_that.isLoading,_that.initialLoadDone);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkspaceModel? currentWorkspace,  List<WorkspaceModel> availableWorkspaces,  bool isLoading,  bool initialLoadDone)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceState() when $default != null:
return $default(_that.currentWorkspace,_that.availableWorkspaces,_that.isLoading,_that.initialLoadDone);case _:
  return null;

}
}

}

/// @nodoc


class _WorkspaceState implements WorkspaceState {
  const _WorkspaceState({this.currentWorkspace, final  List<WorkspaceModel> availableWorkspaces = const [], this.isLoading = false, this.initialLoadDone = false}): _availableWorkspaces = availableWorkspaces;
  

@override final  WorkspaceModel? currentWorkspace;
 final  List<WorkspaceModel> _availableWorkspaces;
@override@JsonKey() List<WorkspaceModel> get availableWorkspaces {
  if (_availableWorkspaces is EqualUnmodifiableListView) return _availableWorkspaces;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableWorkspaces);
}

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool initialLoadDone;

/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceStateCopyWith<_WorkspaceState> get copyWith => __$WorkspaceStateCopyWithImpl<_WorkspaceState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceState&&(identical(other.currentWorkspace, currentWorkspace) || other.currentWorkspace == currentWorkspace)&&const DeepCollectionEquality().equals(other._availableWorkspaces, _availableWorkspaces)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.initialLoadDone, initialLoadDone) || other.initialLoadDone == initialLoadDone));
}


@override
int get hashCode => Object.hash(runtimeType,currentWorkspace,const DeepCollectionEquality().hash(_availableWorkspaces),isLoading,initialLoadDone);

@override
String toString() {
  return 'WorkspaceState(currentWorkspace: $currentWorkspace, availableWorkspaces: $availableWorkspaces, isLoading: $isLoading, initialLoadDone: $initialLoadDone)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceStateCopyWith<$Res> implements $WorkspaceStateCopyWith<$Res> {
  factory _$WorkspaceStateCopyWith(_WorkspaceState value, $Res Function(_WorkspaceState) _then) = __$WorkspaceStateCopyWithImpl;
@override @useResult
$Res call({
 WorkspaceModel? currentWorkspace, List<WorkspaceModel> availableWorkspaces, bool isLoading, bool initialLoadDone
});


@override $WorkspaceModelCopyWith<$Res>? get currentWorkspace;

}
/// @nodoc
class __$WorkspaceStateCopyWithImpl<$Res>
    implements _$WorkspaceStateCopyWith<$Res> {
  __$WorkspaceStateCopyWithImpl(this._self, this._then);

  final _WorkspaceState _self;
  final $Res Function(_WorkspaceState) _then;

/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentWorkspace = freezed,Object? availableWorkspaces = null,Object? isLoading = null,Object? initialLoadDone = null,}) {
  return _then(_WorkspaceState(
currentWorkspace: freezed == currentWorkspace ? _self.currentWorkspace : currentWorkspace // ignore: cast_nullable_to_non_nullable
as WorkspaceModel?,availableWorkspaces: null == availableWorkspaces ? _self._availableWorkspaces : availableWorkspaces // ignore: cast_nullable_to_non_nullable
as List<WorkspaceModel>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,initialLoadDone: null == initialLoadDone ? _self.initialLoadDone : initialLoadDone // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkspaceModelCopyWith<$Res>? get currentWorkspace {
    if (_self.currentWorkspace == null) {
    return null;
  }

  return $WorkspaceModelCopyWith<$Res>(_self.currentWorkspace!, (value) {
    return _then(_self.copyWith(currentWorkspace: value));
  });
}
}

// dart format on
