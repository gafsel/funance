// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InviteState {

 List<InviteModel> get pendingInvites; bool get isLoading; bool get initialLoadDone;
/// Create a copy of InviteState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteStateCopyWith<InviteState> get copyWith => _$InviteStateCopyWithImpl<InviteState>(this as InviteState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteState&&const DeepCollectionEquality().equals(other.pendingInvites, pendingInvites)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.initialLoadDone, initialLoadDone) || other.initialLoadDone == initialLoadDone));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(pendingInvites),isLoading,initialLoadDone);

@override
String toString() {
  return 'InviteState(pendingInvites: $pendingInvites, isLoading: $isLoading, initialLoadDone: $initialLoadDone)';
}


}

/// @nodoc
abstract mixin class $InviteStateCopyWith<$Res>  {
  factory $InviteStateCopyWith(InviteState value, $Res Function(InviteState) _then) = _$InviteStateCopyWithImpl;
@useResult
$Res call({
 List<InviteModel> pendingInvites, bool isLoading, bool initialLoadDone
});




}
/// @nodoc
class _$InviteStateCopyWithImpl<$Res>
    implements $InviteStateCopyWith<$Res> {
  _$InviteStateCopyWithImpl(this._self, this._then);

  final InviteState _self;
  final $Res Function(InviteState) _then;

/// Create a copy of InviteState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pendingInvites = null,Object? isLoading = null,Object? initialLoadDone = null,}) {
  return _then(_self.copyWith(
pendingInvites: null == pendingInvites ? _self.pendingInvites : pendingInvites // ignore: cast_nullable_to_non_nullable
as List<InviteModel>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,initialLoadDone: null == initialLoadDone ? _self.initialLoadDone : initialLoadDone // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [InviteState].
extension InviteStatePatterns on InviteState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InviteState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InviteState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InviteState value)  $default,){
final _that = this;
switch (_that) {
case _InviteState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InviteState value)?  $default,){
final _that = this;
switch (_that) {
case _InviteState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<InviteModel> pendingInvites,  bool isLoading,  bool initialLoadDone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InviteState() when $default != null:
return $default(_that.pendingInvites,_that.isLoading,_that.initialLoadDone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<InviteModel> pendingInvites,  bool isLoading,  bool initialLoadDone)  $default,) {final _that = this;
switch (_that) {
case _InviteState():
return $default(_that.pendingInvites,_that.isLoading,_that.initialLoadDone);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<InviteModel> pendingInvites,  bool isLoading,  bool initialLoadDone)?  $default,) {final _that = this;
switch (_that) {
case _InviteState() when $default != null:
return $default(_that.pendingInvites,_that.isLoading,_that.initialLoadDone);case _:
  return null;

}
}

}

/// @nodoc


class _InviteState implements InviteState {
  const _InviteState({final  List<InviteModel> pendingInvites = const [], this.isLoading = false, this.initialLoadDone = false}): _pendingInvites = pendingInvites;
  

 final  List<InviteModel> _pendingInvites;
@override@JsonKey() List<InviteModel> get pendingInvites {
  if (_pendingInvites is EqualUnmodifiableListView) return _pendingInvites;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pendingInvites);
}

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool initialLoadDone;

/// Create a copy of InviteState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteStateCopyWith<_InviteState> get copyWith => __$InviteStateCopyWithImpl<_InviteState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteState&&const DeepCollectionEquality().equals(other._pendingInvites, _pendingInvites)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.initialLoadDone, initialLoadDone) || other.initialLoadDone == initialLoadDone));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_pendingInvites),isLoading,initialLoadDone);

@override
String toString() {
  return 'InviteState(pendingInvites: $pendingInvites, isLoading: $isLoading, initialLoadDone: $initialLoadDone)';
}


}

/// @nodoc
abstract mixin class _$InviteStateCopyWith<$Res> implements $InviteStateCopyWith<$Res> {
  factory _$InviteStateCopyWith(_InviteState value, $Res Function(_InviteState) _then) = __$InviteStateCopyWithImpl;
@override @useResult
$Res call({
 List<InviteModel> pendingInvites, bool isLoading, bool initialLoadDone
});




}
/// @nodoc
class __$InviteStateCopyWithImpl<$Res>
    implements _$InviteStateCopyWith<$Res> {
  __$InviteStateCopyWithImpl(this._self, this._then);

  final _InviteState _self;
  final $Res Function(_InviteState) _then;

/// Create a copy of InviteState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pendingInvites = null,Object? isLoading = null,Object? initialLoadDone = null,}) {
  return _then(_InviteState(
pendingInvites: null == pendingInvites ? _self._pendingInvites : pendingInvites // ignore: cast_nullable_to_non_nullable
as List<InviteModel>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,initialLoadDone: null == initialLoadDone ? _self.initialLoadDone : initialLoadDone // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
