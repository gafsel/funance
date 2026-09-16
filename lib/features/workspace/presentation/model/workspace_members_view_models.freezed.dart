// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workspace_members_view_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkspaceMembersState {

 List<UserModel> get members; List<InviteModel> get pendingInvites; bool get isLoading;// O stream de convites começa sem ter emitido nada; sem esta marca a tela
// mostraria "nenhum convite pendente" antes da primeira resposta.
 bool get invitesLoaded; bool get errorLoading; bool get errorInvites;// Id da linha com operação em curso, para desabilitar só ela.
 String? get busyMemberId; String? get busyInviteId;
/// Create a copy of WorkspaceMembersState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceMembersStateCopyWith<WorkspaceMembersState> get copyWith => _$WorkspaceMembersStateCopyWithImpl<WorkspaceMembersState>(this as WorkspaceMembersState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceMembersState&&const DeepCollectionEquality().equals(other.members, members)&&const DeepCollectionEquality().equals(other.pendingInvites, pendingInvites)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.invitesLoaded, invitesLoaded) || other.invitesLoaded == invitesLoaded)&&(identical(other.errorLoading, errorLoading) || other.errorLoading == errorLoading)&&(identical(other.errorInvites, errorInvites) || other.errorInvites == errorInvites)&&(identical(other.busyMemberId, busyMemberId) || other.busyMemberId == busyMemberId)&&(identical(other.busyInviteId, busyInviteId) || other.busyInviteId == busyInviteId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(members),const DeepCollectionEquality().hash(pendingInvites),isLoading,invitesLoaded,errorLoading,errorInvites,busyMemberId,busyInviteId);

@override
String toString() {
  return 'WorkspaceMembersState(members: $members, pendingInvites: $pendingInvites, isLoading: $isLoading, invitesLoaded: $invitesLoaded, errorLoading: $errorLoading, errorInvites: $errorInvites, busyMemberId: $busyMemberId, busyInviteId: $busyInviteId)';
}


}

/// @nodoc
abstract mixin class $WorkspaceMembersStateCopyWith<$Res>  {
  factory $WorkspaceMembersStateCopyWith(WorkspaceMembersState value, $Res Function(WorkspaceMembersState) _then) = _$WorkspaceMembersStateCopyWithImpl;
@useResult
$Res call({
 List<UserModel> members, List<InviteModel> pendingInvites, bool isLoading, bool invitesLoaded, bool errorLoading, bool errorInvites, String? busyMemberId, String? busyInviteId
});




}
/// @nodoc
class _$WorkspaceMembersStateCopyWithImpl<$Res>
    implements $WorkspaceMembersStateCopyWith<$Res> {
  _$WorkspaceMembersStateCopyWithImpl(this._self, this._then);

  final WorkspaceMembersState _self;
  final $Res Function(WorkspaceMembersState) _then;

/// Create a copy of WorkspaceMembersState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? members = null,Object? pendingInvites = null,Object? isLoading = null,Object? invitesLoaded = null,Object? errorLoading = null,Object? errorInvites = null,Object? busyMemberId = freezed,Object? busyInviteId = freezed,}) {
  return _then(_self.copyWith(
members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<UserModel>,pendingInvites: null == pendingInvites ? _self.pendingInvites : pendingInvites // ignore: cast_nullable_to_non_nullable
as List<InviteModel>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,invitesLoaded: null == invitesLoaded ? _self.invitesLoaded : invitesLoaded // ignore: cast_nullable_to_non_nullable
as bool,errorLoading: null == errorLoading ? _self.errorLoading : errorLoading // ignore: cast_nullable_to_non_nullable
as bool,errorInvites: null == errorInvites ? _self.errorInvites : errorInvites // ignore: cast_nullable_to_non_nullable
as bool,busyMemberId: freezed == busyMemberId ? _self.busyMemberId : busyMemberId // ignore: cast_nullable_to_non_nullable
as String?,busyInviteId: freezed == busyInviteId ? _self.busyInviteId : busyInviteId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkspaceMembersState].
extension WorkspaceMembersStatePatterns on WorkspaceMembersState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceMembersState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceMembersState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceMembersState value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceMembersState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceMembersState value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceMembersState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<UserModel> members,  List<InviteModel> pendingInvites,  bool isLoading,  bool invitesLoaded,  bool errorLoading,  bool errorInvites,  String? busyMemberId,  String? busyInviteId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceMembersState() when $default != null:
return $default(_that.members,_that.pendingInvites,_that.isLoading,_that.invitesLoaded,_that.errorLoading,_that.errorInvites,_that.busyMemberId,_that.busyInviteId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<UserModel> members,  List<InviteModel> pendingInvites,  bool isLoading,  bool invitesLoaded,  bool errorLoading,  bool errorInvites,  String? busyMemberId,  String? busyInviteId)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceMembersState():
return $default(_that.members,_that.pendingInvites,_that.isLoading,_that.invitesLoaded,_that.errorLoading,_that.errorInvites,_that.busyMemberId,_that.busyInviteId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<UserModel> members,  List<InviteModel> pendingInvites,  bool isLoading,  bool invitesLoaded,  bool errorLoading,  bool errorInvites,  String? busyMemberId,  String? busyInviteId)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceMembersState() when $default != null:
return $default(_that.members,_that.pendingInvites,_that.isLoading,_that.invitesLoaded,_that.errorLoading,_that.errorInvites,_that.busyMemberId,_that.busyInviteId);case _:
  return null;

}
}

}

/// @nodoc


class _WorkspaceMembersState implements WorkspaceMembersState {
  const _WorkspaceMembersState({final  List<UserModel> members = const [], final  List<InviteModel> pendingInvites = const [], this.isLoading = true, this.invitesLoaded = false, this.errorLoading = false, this.errorInvites = false, this.busyMemberId, this.busyInviteId}): _members = members,_pendingInvites = pendingInvites;
  

 final  List<UserModel> _members;
@override@JsonKey() List<UserModel> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

 final  List<InviteModel> _pendingInvites;
@override@JsonKey() List<InviteModel> get pendingInvites {
  if (_pendingInvites is EqualUnmodifiableListView) return _pendingInvites;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pendingInvites);
}

@override@JsonKey() final  bool isLoading;
// O stream de convites começa sem ter emitido nada; sem esta marca a tela
// mostraria "nenhum convite pendente" antes da primeira resposta.
@override@JsonKey() final  bool invitesLoaded;
@override@JsonKey() final  bool errorLoading;
@override@JsonKey() final  bool errorInvites;
// Id da linha com operação em curso, para desabilitar só ela.
@override final  String? busyMemberId;
@override final  String? busyInviteId;

/// Create a copy of WorkspaceMembersState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceMembersStateCopyWith<_WorkspaceMembersState> get copyWith => __$WorkspaceMembersStateCopyWithImpl<_WorkspaceMembersState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceMembersState&&const DeepCollectionEquality().equals(other._members, _members)&&const DeepCollectionEquality().equals(other._pendingInvites, _pendingInvites)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.invitesLoaded, invitesLoaded) || other.invitesLoaded == invitesLoaded)&&(identical(other.errorLoading, errorLoading) || other.errorLoading == errorLoading)&&(identical(other.errorInvites, errorInvites) || other.errorInvites == errorInvites)&&(identical(other.busyMemberId, busyMemberId) || other.busyMemberId == busyMemberId)&&(identical(other.busyInviteId, busyInviteId) || other.busyInviteId == busyInviteId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_members),const DeepCollectionEquality().hash(_pendingInvites),isLoading,invitesLoaded,errorLoading,errorInvites,busyMemberId,busyInviteId);

@override
String toString() {
  return 'WorkspaceMembersState(members: $members, pendingInvites: $pendingInvites, isLoading: $isLoading, invitesLoaded: $invitesLoaded, errorLoading: $errorLoading, errorInvites: $errorInvites, busyMemberId: $busyMemberId, busyInviteId: $busyInviteId)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceMembersStateCopyWith<$Res> implements $WorkspaceMembersStateCopyWith<$Res> {
  factory _$WorkspaceMembersStateCopyWith(_WorkspaceMembersState value, $Res Function(_WorkspaceMembersState) _then) = __$WorkspaceMembersStateCopyWithImpl;
@override @useResult
$Res call({
 List<UserModel> members, List<InviteModel> pendingInvites, bool isLoading, bool invitesLoaded, bool errorLoading, bool errorInvites, String? busyMemberId, String? busyInviteId
});




}
/// @nodoc
class __$WorkspaceMembersStateCopyWithImpl<$Res>
    implements _$WorkspaceMembersStateCopyWith<$Res> {
  __$WorkspaceMembersStateCopyWithImpl(this._self, this._then);

  final _WorkspaceMembersState _self;
  final $Res Function(_WorkspaceMembersState) _then;

/// Create a copy of WorkspaceMembersState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? members = null,Object? pendingInvites = null,Object? isLoading = null,Object? invitesLoaded = null,Object? errorLoading = null,Object? errorInvites = null,Object? busyMemberId = freezed,Object? busyInviteId = freezed,}) {
  return _then(_WorkspaceMembersState(
members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<UserModel>,pendingInvites: null == pendingInvites ? _self._pendingInvites : pendingInvites // ignore: cast_nullable_to_non_nullable
as List<InviteModel>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,invitesLoaded: null == invitesLoaded ? _self.invitesLoaded : invitesLoaded // ignore: cast_nullable_to_non_nullable
as bool,errorLoading: null == errorLoading ? _self.errorLoading : errorLoading // ignore: cast_nullable_to_non_nullable
as bool,errorInvites: null == errorInvites ? _self.errorInvites : errorInvites // ignore: cast_nullable_to_non_nullable
as bool,busyMemberId: freezed == busyMemberId ? _self.busyMemberId : busyMemberId // ignore: cast_nullable_to_non_nullable
as String?,busyInviteId: freezed == busyInviteId ? _self.busyInviteId : busyInviteId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
