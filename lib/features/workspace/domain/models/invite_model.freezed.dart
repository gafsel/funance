// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InviteModel {

 String get id;@JsonKey(name: 'workspace') WorkspaceModel get workspace; String get senderId; String get senderName; String get receiverEmail; InviteStatus get status; DateTime get createdAt;
/// Create a copy of InviteModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteModelCopyWith<InviteModel> get copyWith => _$InviteModelCopyWithImpl<InviteModel>(this as InviteModel, _$identity);

  /// Serializes this InviteModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteModel&&(identical(other.id, id) || other.id == id)&&(identical(other.workspace, workspace) || other.workspace == workspace)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.receiverEmail, receiverEmail) || other.receiverEmail == receiverEmail)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workspace,senderId,senderName,receiverEmail,status,createdAt);

@override
String toString() {
  return 'InviteModel(id: $id, workspace: $workspace, senderId: $senderId, senderName: $senderName, receiverEmail: $receiverEmail, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $InviteModelCopyWith<$Res>  {
  factory $InviteModelCopyWith(InviteModel value, $Res Function(InviteModel) _then) = _$InviteModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'workspace') WorkspaceModel workspace, String senderId, String senderName, String receiverEmail, InviteStatus status, DateTime createdAt
});


$WorkspaceModelCopyWith<$Res> get workspace;

}
/// @nodoc
class _$InviteModelCopyWithImpl<$Res>
    implements $InviteModelCopyWith<$Res> {
  _$InviteModelCopyWithImpl(this._self, this._then);

  final InviteModel _self;
  final $Res Function(InviteModel) _then;

/// Create a copy of InviteModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? workspace = null,Object? senderId = null,Object? senderName = null,Object? receiverEmail = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspace: null == workspace ? _self.workspace : workspace // ignore: cast_nullable_to_non_nullable
as WorkspaceModel,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,receiverEmail: null == receiverEmail ? _self.receiverEmail : receiverEmail // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InviteStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of InviteModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkspaceModelCopyWith<$Res> get workspace {
  
  return $WorkspaceModelCopyWith<$Res>(_self.workspace, (value) {
    return _then(_self.copyWith(workspace: value));
  });
}
}


/// Adds pattern-matching-related methods to [InviteModel].
extension InviteModelPatterns on InviteModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InviteModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InviteModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InviteModel value)  $default,){
final _that = this;
switch (_that) {
case _InviteModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InviteModel value)?  $default,){
final _that = this;
switch (_that) {
case _InviteModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'workspace')  WorkspaceModel workspace,  String senderId,  String senderName,  String receiverEmail,  InviteStatus status,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InviteModel() when $default != null:
return $default(_that.id,_that.workspace,_that.senderId,_that.senderName,_that.receiverEmail,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'workspace')  WorkspaceModel workspace,  String senderId,  String senderName,  String receiverEmail,  InviteStatus status,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _InviteModel():
return $default(_that.id,_that.workspace,_that.senderId,_that.senderName,_that.receiverEmail,_that.status,_that.createdAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'workspace')  WorkspaceModel workspace,  String senderId,  String senderName,  String receiverEmail,  InviteStatus status,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _InviteModel() when $default != null:
return $default(_that.id,_that.workspace,_that.senderId,_that.senderName,_that.receiverEmail,_that.status,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _InviteModel extends InviteModel {
  const _InviteModel({required this.id, @JsonKey(name: 'workspace') required this.workspace, required this.senderId, required this.senderName, required this.receiverEmail, required this.status, required this.createdAt}): super._();
  factory _InviteModel.fromJson(Map<String, dynamic> json) => _$InviteModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'workspace') final  WorkspaceModel workspace;
@override final  String senderId;
@override final  String senderName;
@override final  String receiverEmail;
@override final  InviteStatus status;
@override final  DateTime createdAt;

/// Create a copy of InviteModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteModelCopyWith<_InviteModel> get copyWith => __$InviteModelCopyWithImpl<_InviteModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InviteModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteModel&&(identical(other.id, id) || other.id == id)&&(identical(other.workspace, workspace) || other.workspace == workspace)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.receiverEmail, receiverEmail) || other.receiverEmail == receiverEmail)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,workspace,senderId,senderName,receiverEmail,status,createdAt);

@override
String toString() {
  return 'InviteModel(id: $id, workspace: $workspace, senderId: $senderId, senderName: $senderName, receiverEmail: $receiverEmail, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$InviteModelCopyWith<$Res> implements $InviteModelCopyWith<$Res> {
  factory _$InviteModelCopyWith(_InviteModel value, $Res Function(_InviteModel) _then) = __$InviteModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'workspace') WorkspaceModel workspace, String senderId, String senderName, String receiverEmail, InviteStatus status, DateTime createdAt
});


@override $WorkspaceModelCopyWith<$Res> get workspace;

}
/// @nodoc
class __$InviteModelCopyWithImpl<$Res>
    implements _$InviteModelCopyWith<$Res> {
  __$InviteModelCopyWithImpl(this._self, this._then);

  final _InviteModel _self;
  final $Res Function(_InviteModel) _then;

/// Create a copy of InviteModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? workspace = null,Object? senderId = null,Object? senderName = null,Object? receiverEmail = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_InviteModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,workspace: null == workspace ? _self.workspace : workspace // ignore: cast_nullable_to_non_nullable
as WorkspaceModel,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,receiverEmail: null == receiverEmail ? _self.receiverEmail : receiverEmail // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InviteStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of InviteModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkspaceModelCopyWith<$Res> get workspace {
  
  return $WorkspaceModelCopyWith<$Res>(_self.workspace, (value) {
    return _then(_self.copyWith(workspace: value));
  });
}
}

// dart format on
