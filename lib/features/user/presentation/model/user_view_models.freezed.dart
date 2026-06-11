// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_view_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserProfileFormState {

 String get id; String get displayName; String get email; String? get photoUrl; File? get newPhotoFile; UserModel? get originalUser;
/// Create a copy of UserProfileFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileFormStateCopyWith<UserProfileFormState> get copyWith => _$UserProfileFormStateCopyWithImpl<UserProfileFormState>(this as UserProfileFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfileFormState&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.newPhotoFile, newPhotoFile) || other.newPhotoFile == newPhotoFile)&&(identical(other.originalUser, originalUser) || other.originalUser == originalUser));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,email,photoUrl,newPhotoFile,originalUser);

@override
String toString() {
  return 'UserProfileFormState(id: $id, displayName: $displayName, email: $email, photoUrl: $photoUrl, newPhotoFile: $newPhotoFile, originalUser: $originalUser)';
}


}

/// @nodoc
abstract mixin class $UserProfileFormStateCopyWith<$Res>  {
  factory $UserProfileFormStateCopyWith(UserProfileFormState value, $Res Function(UserProfileFormState) _then) = _$UserProfileFormStateCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String email, String? photoUrl, File? newPhotoFile, UserModel? originalUser
});


$UserModelCopyWith<$Res>? get originalUser;

}
/// @nodoc
class _$UserProfileFormStateCopyWithImpl<$Res>
    implements $UserProfileFormStateCopyWith<$Res> {
  _$UserProfileFormStateCopyWithImpl(this._self, this._then);

  final UserProfileFormState _self;
  final $Res Function(UserProfileFormState) _then;

/// Create a copy of UserProfileFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? email = null,Object? photoUrl = freezed,Object? newPhotoFile = freezed,Object? originalUser = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,newPhotoFile: freezed == newPhotoFile ? _self.newPhotoFile : newPhotoFile // ignore: cast_nullable_to_non_nullable
as File?,originalUser: freezed == originalUser ? _self.originalUser : originalUser // ignore: cast_nullable_to_non_nullable
as UserModel?,
  ));
}
/// Create a copy of UserProfileFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserModelCopyWith<$Res>? get originalUser {
    if (_self.originalUser == null) {
    return null;
  }

  return $UserModelCopyWith<$Res>(_self.originalUser!, (value) {
    return _then(_self.copyWith(originalUser: value));
  });
}
}


/// Adds pattern-matching-related methods to [UserProfileFormState].
extension UserProfileFormStatePatterns on UserProfileFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfileFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfileFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfileFormState value)  $default,){
final _that = this;
switch (_that) {
case _UserProfileFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfileFormState value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfileFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String email,  String? photoUrl,  File? newPhotoFile,  UserModel? originalUser)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfileFormState() when $default != null:
return $default(_that.id,_that.displayName,_that.email,_that.photoUrl,_that.newPhotoFile,_that.originalUser);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String email,  String? photoUrl,  File? newPhotoFile,  UserModel? originalUser)  $default,) {final _that = this;
switch (_that) {
case _UserProfileFormState():
return $default(_that.id,_that.displayName,_that.email,_that.photoUrl,_that.newPhotoFile,_that.originalUser);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String email,  String? photoUrl,  File? newPhotoFile,  UserModel? originalUser)?  $default,) {final _that = this;
switch (_that) {
case _UserProfileFormState() when $default != null:
return $default(_that.id,_that.displayName,_that.email,_that.photoUrl,_that.newPhotoFile,_that.originalUser);case _:
  return null;

}
}

}

/// @nodoc


class _UserProfileFormState implements UserProfileFormState {
  const _UserProfileFormState({required this.id, required this.displayName, required this.email, this.photoUrl, this.newPhotoFile, this.originalUser});
  

@override final  String id;
@override final  String displayName;
@override final  String email;
@override final  String? photoUrl;
@override final  File? newPhotoFile;
@override final  UserModel? originalUser;

/// Create a copy of UserProfileFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileFormStateCopyWith<_UserProfileFormState> get copyWith => __$UserProfileFormStateCopyWithImpl<_UserProfileFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfileFormState&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.newPhotoFile, newPhotoFile) || other.newPhotoFile == newPhotoFile)&&(identical(other.originalUser, originalUser) || other.originalUser == originalUser));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,email,photoUrl,newPhotoFile,originalUser);

@override
String toString() {
  return 'UserProfileFormState(id: $id, displayName: $displayName, email: $email, photoUrl: $photoUrl, newPhotoFile: $newPhotoFile, originalUser: $originalUser)';
}


}

/// @nodoc
abstract mixin class _$UserProfileFormStateCopyWith<$Res> implements $UserProfileFormStateCopyWith<$Res> {
  factory _$UserProfileFormStateCopyWith(_UserProfileFormState value, $Res Function(_UserProfileFormState) _then) = __$UserProfileFormStateCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String email, String? photoUrl, File? newPhotoFile, UserModel? originalUser
});


@override $UserModelCopyWith<$Res>? get originalUser;

}
/// @nodoc
class __$UserProfileFormStateCopyWithImpl<$Res>
    implements _$UserProfileFormStateCopyWith<$Res> {
  __$UserProfileFormStateCopyWithImpl(this._self, this._then);

  final _UserProfileFormState _self;
  final $Res Function(_UserProfileFormState) _then;

/// Create a copy of UserProfileFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? email = null,Object? photoUrl = freezed,Object? newPhotoFile = freezed,Object? originalUser = freezed,}) {
  return _then(_UserProfileFormState(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,newPhotoFile: freezed == newPhotoFile ? _self.newPhotoFile : newPhotoFile // ignore: cast_nullable_to_non_nullable
as File?,originalUser: freezed == originalUser ? _self.originalUser : originalUser // ignore: cast_nullable_to_non_nullable
as UserModel?,
  ));
}

/// Create a copy of UserProfileFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserModelCopyWith<$Res>? get originalUser {
    if (_self.originalUser == null) {
    return null;
  }

  return $UserModelCopyWith<$Res>(_self.originalUser!, (value) {
    return _then(_self.copyWith(originalUser: value));
  });
}
}

// dart format on
