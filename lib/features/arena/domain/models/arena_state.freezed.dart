// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'arena_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ArenaHero {

 String get userId; String get name; HeroSkin get skin; String? get photoUrl;
/// Create a copy of ArenaHero
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArenaHeroCopyWith<ArenaHero> get copyWith => _$ArenaHeroCopyWithImpl<ArenaHero>(this as ArenaHero, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArenaHero&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.skin, skin) || other.skin == skin)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl));
}


@override
int get hashCode => Object.hash(runtimeType,userId,name,skin,photoUrl);

@override
String toString() {
  return 'ArenaHero(userId: $userId, name: $name, skin: $skin, photoUrl: $photoUrl)';
}


}

/// @nodoc
abstract mixin class $ArenaHeroCopyWith<$Res>  {
  factory $ArenaHeroCopyWith(ArenaHero value, $Res Function(ArenaHero) _then) = _$ArenaHeroCopyWithImpl;
@useResult
$Res call({
 String userId, String name, HeroSkin skin, String? photoUrl
});




}
/// @nodoc
class _$ArenaHeroCopyWithImpl<$Res>
    implements $ArenaHeroCopyWith<$Res> {
  _$ArenaHeroCopyWithImpl(this._self, this._then);

  final ArenaHero _self;
  final $Res Function(ArenaHero) _then;

/// Create a copy of ArenaHero
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? name = null,Object? skin = null,Object? photoUrl = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,skin: null == skin ? _self.skin : skin // ignore: cast_nullable_to_non_nullable
as HeroSkin,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ArenaHero].
extension ArenaHeroPatterns on ArenaHero {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArenaHero value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArenaHero() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArenaHero value)  $default,){
final _that = this;
switch (_that) {
case _ArenaHero():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArenaHero value)?  $default,){
final _that = this;
switch (_that) {
case _ArenaHero() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String name,  HeroSkin skin,  String? photoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArenaHero() when $default != null:
return $default(_that.userId,_that.name,_that.skin,_that.photoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String name,  HeroSkin skin,  String? photoUrl)  $default,) {final _that = this;
switch (_that) {
case _ArenaHero():
return $default(_that.userId,_that.name,_that.skin,_that.photoUrl);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String name,  HeroSkin skin,  String? photoUrl)?  $default,) {final _that = this;
switch (_that) {
case _ArenaHero() when $default != null:
return $default(_that.userId,_that.name,_that.skin,_that.photoUrl);case _:
  return null;

}
}

}

/// @nodoc


class _ArenaHero implements ArenaHero {
  const _ArenaHero({required this.userId, required this.name, required this.skin, this.photoUrl});
  

@override final  String userId;
@override final  String name;
@override final  HeroSkin skin;
@override final  String? photoUrl;

/// Create a copy of ArenaHero
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArenaHeroCopyWith<_ArenaHero> get copyWith => __$ArenaHeroCopyWithImpl<_ArenaHero>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArenaHero&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.skin, skin) || other.skin == skin)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl));
}


@override
int get hashCode => Object.hash(runtimeType,userId,name,skin,photoUrl);

@override
String toString() {
  return 'ArenaHero(userId: $userId, name: $name, skin: $skin, photoUrl: $photoUrl)';
}


}

/// @nodoc
abstract mixin class _$ArenaHeroCopyWith<$Res> implements $ArenaHeroCopyWith<$Res> {
  factory _$ArenaHeroCopyWith(_ArenaHero value, $Res Function(_ArenaHero) _then) = __$ArenaHeroCopyWithImpl;
@override @useResult
$Res call({
 String userId, String name, HeroSkin skin, String? photoUrl
});




}
/// @nodoc
class __$ArenaHeroCopyWithImpl<$Res>
    implements _$ArenaHeroCopyWith<$Res> {
  __$ArenaHeroCopyWithImpl(this._self, this._then);

  final _ArenaHero _self;
  final $Res Function(_ArenaHero) _then;

/// Create a copy of ArenaHero
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? name = null,Object? skin = null,Object? photoUrl = freezed,}) {
  return _then(_ArenaHero(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,skin: null == skin ? _self.skin : skin // ignore: cast_nullable_to_non_nullable
as HeroSkin,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ArenaCommitment {

 InstallmentModel get installment;/// Já quitado (`paid` ou `settled`).
 bool get isPaid;/// Pendente com vencimento ANTERIOR ao domingo desta semana.
 bool get isOverdue;/// Dias de calendário até o vencimento, a partir de hoje. Negativo =
/// venceu.
 int get daysUntilDue;
/// Create a copy of ArenaCommitment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArenaCommitmentCopyWith<ArenaCommitment> get copyWith => _$ArenaCommitmentCopyWithImpl<ArenaCommitment>(this as ArenaCommitment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArenaCommitment&&(identical(other.installment, installment) || other.installment == installment)&&(identical(other.isPaid, isPaid) || other.isPaid == isPaid)&&(identical(other.isOverdue, isOverdue) || other.isOverdue == isOverdue)&&(identical(other.daysUntilDue, daysUntilDue) || other.daysUntilDue == daysUntilDue));
}


@override
int get hashCode => Object.hash(runtimeType,installment,isPaid,isOverdue,daysUntilDue);

@override
String toString() {
  return 'ArenaCommitment(installment: $installment, isPaid: $isPaid, isOverdue: $isOverdue, daysUntilDue: $daysUntilDue)';
}


}

/// @nodoc
abstract mixin class $ArenaCommitmentCopyWith<$Res>  {
  factory $ArenaCommitmentCopyWith(ArenaCommitment value, $Res Function(ArenaCommitment) _then) = _$ArenaCommitmentCopyWithImpl;
@useResult
$Res call({
 InstallmentModel installment, bool isPaid, bool isOverdue, int daysUntilDue
});


$InstallmentModelCopyWith<$Res> get installment;

}
/// @nodoc
class _$ArenaCommitmentCopyWithImpl<$Res>
    implements $ArenaCommitmentCopyWith<$Res> {
  _$ArenaCommitmentCopyWithImpl(this._self, this._then);

  final ArenaCommitment _self;
  final $Res Function(ArenaCommitment) _then;

/// Create a copy of ArenaCommitment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? installment = null,Object? isPaid = null,Object? isOverdue = null,Object? daysUntilDue = null,}) {
  return _then(_self.copyWith(
installment: null == installment ? _self.installment : installment // ignore: cast_nullable_to_non_nullable
as InstallmentModel,isPaid: null == isPaid ? _self.isPaid : isPaid // ignore: cast_nullable_to_non_nullable
as bool,isOverdue: null == isOverdue ? _self.isOverdue : isOverdue // ignore: cast_nullable_to_non_nullable
as bool,daysUntilDue: null == daysUntilDue ? _self.daysUntilDue : daysUntilDue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ArenaCommitment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstallmentModelCopyWith<$Res> get installment {
  
  return $InstallmentModelCopyWith<$Res>(_self.installment, (value) {
    return _then(_self.copyWith(installment: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArenaCommitment].
extension ArenaCommitmentPatterns on ArenaCommitment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArenaCommitment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArenaCommitment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArenaCommitment value)  $default,){
final _that = this;
switch (_that) {
case _ArenaCommitment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArenaCommitment value)?  $default,){
final _that = this;
switch (_that) {
case _ArenaCommitment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( InstallmentModel installment,  bool isPaid,  bool isOverdue,  int daysUntilDue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArenaCommitment() when $default != null:
return $default(_that.installment,_that.isPaid,_that.isOverdue,_that.daysUntilDue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( InstallmentModel installment,  bool isPaid,  bool isOverdue,  int daysUntilDue)  $default,) {final _that = this;
switch (_that) {
case _ArenaCommitment():
return $default(_that.installment,_that.isPaid,_that.isOverdue,_that.daysUntilDue);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( InstallmentModel installment,  bool isPaid,  bool isOverdue,  int daysUntilDue)?  $default,) {final _that = this;
switch (_that) {
case _ArenaCommitment() when $default != null:
return $default(_that.installment,_that.isPaid,_that.isOverdue,_that.daysUntilDue);case _:
  return null;

}
}

}

/// @nodoc


class _ArenaCommitment extends ArenaCommitment {
  const _ArenaCommitment({required this.installment, required this.isPaid, required this.isOverdue, required this.daysUntilDue}): super._();
  

@override final  InstallmentModel installment;
/// Já quitado (`paid` ou `settled`).
@override final  bool isPaid;
/// Pendente com vencimento ANTERIOR ao domingo desta semana.
@override final  bool isOverdue;
/// Dias de calendário até o vencimento, a partir de hoje. Negativo =
/// venceu.
@override final  int daysUntilDue;

/// Create a copy of ArenaCommitment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArenaCommitmentCopyWith<_ArenaCommitment> get copyWith => __$ArenaCommitmentCopyWithImpl<_ArenaCommitment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArenaCommitment&&(identical(other.installment, installment) || other.installment == installment)&&(identical(other.isPaid, isPaid) || other.isPaid == isPaid)&&(identical(other.isOverdue, isOverdue) || other.isOverdue == isOverdue)&&(identical(other.daysUntilDue, daysUntilDue) || other.daysUntilDue == daysUntilDue));
}


@override
int get hashCode => Object.hash(runtimeType,installment,isPaid,isOverdue,daysUntilDue);

@override
String toString() {
  return 'ArenaCommitment(installment: $installment, isPaid: $isPaid, isOverdue: $isOverdue, daysUntilDue: $daysUntilDue)';
}


}

/// @nodoc
abstract mixin class _$ArenaCommitmentCopyWith<$Res> implements $ArenaCommitmentCopyWith<$Res> {
  factory _$ArenaCommitmentCopyWith(_ArenaCommitment value, $Res Function(_ArenaCommitment) _then) = __$ArenaCommitmentCopyWithImpl;
@override @useResult
$Res call({
 InstallmentModel installment, bool isPaid, bool isOverdue, int daysUntilDue
});


@override $InstallmentModelCopyWith<$Res> get installment;

}
/// @nodoc
class __$ArenaCommitmentCopyWithImpl<$Res>
    implements _$ArenaCommitmentCopyWith<$Res> {
  __$ArenaCommitmentCopyWithImpl(this._self, this._then);

  final _ArenaCommitment _self;
  final $Res Function(_ArenaCommitment) _then;

/// Create a copy of ArenaCommitment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? installment = null,Object? isPaid = null,Object? isOverdue = null,Object? daysUntilDue = null,}) {
  return _then(_ArenaCommitment(
installment: null == installment ? _self.installment : installment // ignore: cast_nullable_to_non_nullable
as InstallmentModel,isPaid: null == isPaid ? _self.isPaid : isPaid // ignore: cast_nullable_to_non_nullable
as bool,isOverdue: null == isOverdue ? _self.isOverdue : isOverdue // ignore: cast_nullable_to_non_nullable
as bool,daysUntilDue: null == daysUntilDue ? _self.daysUntilDue : daysUntilDue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ArenaCommitment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstallmentModelCopyWith<$Res> get installment {
  
  return $InstallmentModelCopyWith<$Res>(_self.installment, (value) {
    return _then(_self.copyWith(installment: value));
  });
}
}

/// @nodoc
mixin _$ArenaAccountLife {

 String get accountId; String get name;/// Saldo no início da semana: o último documento de `balance` com data
/// ANTERIOR ao domingo. Conta que não existia ainda vale zero.
 double get initial;/// Saldo agora: o último documento de `balance`.
 double get current;
/// Create a copy of ArenaAccountLife
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArenaAccountLifeCopyWith<ArenaAccountLife> get copyWith => _$ArenaAccountLifeCopyWithImpl<ArenaAccountLife>(this as ArenaAccountLife, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArenaAccountLife&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.name, name) || other.name == name)&&(identical(other.initial, initial) || other.initial == initial)&&(identical(other.current, current) || other.current == current));
}


@override
int get hashCode => Object.hash(runtimeType,accountId,name,initial,current);

@override
String toString() {
  return 'ArenaAccountLife(accountId: $accountId, name: $name, initial: $initial, current: $current)';
}


}

/// @nodoc
abstract mixin class $ArenaAccountLifeCopyWith<$Res>  {
  factory $ArenaAccountLifeCopyWith(ArenaAccountLife value, $Res Function(ArenaAccountLife) _then) = _$ArenaAccountLifeCopyWithImpl;
@useResult
$Res call({
 String accountId, String name, double initial, double current
});




}
/// @nodoc
class _$ArenaAccountLifeCopyWithImpl<$Res>
    implements $ArenaAccountLifeCopyWith<$Res> {
  _$ArenaAccountLifeCopyWithImpl(this._self, this._then);

  final ArenaAccountLife _self;
  final $Res Function(ArenaAccountLife) _then;

/// Create a copy of ArenaAccountLife
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountId = null,Object? name = null,Object? initial = null,Object? current = null,}) {
  return _then(_self.copyWith(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,initial: null == initial ? _self.initial : initial // ignore: cast_nullable_to_non_nullable
as double,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ArenaAccountLife].
extension ArenaAccountLifePatterns on ArenaAccountLife {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArenaAccountLife value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArenaAccountLife() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArenaAccountLife value)  $default,){
final _that = this;
switch (_that) {
case _ArenaAccountLife():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArenaAccountLife value)?  $default,){
final _that = this;
switch (_that) {
case _ArenaAccountLife() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accountId,  String name,  double initial,  double current)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArenaAccountLife() when $default != null:
return $default(_that.accountId,_that.name,_that.initial,_that.current);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accountId,  String name,  double initial,  double current)  $default,) {final _that = this;
switch (_that) {
case _ArenaAccountLife():
return $default(_that.accountId,_that.name,_that.initial,_that.current);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accountId,  String name,  double initial,  double current)?  $default,) {final _that = this;
switch (_that) {
case _ArenaAccountLife() when $default != null:
return $default(_that.accountId,_that.name,_that.initial,_that.current);case _:
  return null;

}
}

}

/// @nodoc


class _ArenaAccountLife extends ArenaAccountLife {
  const _ArenaAccountLife({required this.accountId, required this.name, required this.initial, required this.current}): super._();
  

@override final  String accountId;
@override final  String name;
/// Saldo no início da semana: o último documento de `balance` com data
/// ANTERIOR ao domingo. Conta que não existia ainda vale zero.
@override final  double initial;
/// Saldo agora: o último documento de `balance`.
@override final  double current;

/// Create a copy of ArenaAccountLife
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArenaAccountLifeCopyWith<_ArenaAccountLife> get copyWith => __$ArenaAccountLifeCopyWithImpl<_ArenaAccountLife>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArenaAccountLife&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.name, name) || other.name == name)&&(identical(other.initial, initial) || other.initial == initial)&&(identical(other.current, current) || other.current == current));
}


@override
int get hashCode => Object.hash(runtimeType,accountId,name,initial,current);

@override
String toString() {
  return 'ArenaAccountLife(accountId: $accountId, name: $name, initial: $initial, current: $current)';
}


}

/// @nodoc
abstract mixin class _$ArenaAccountLifeCopyWith<$Res> implements $ArenaAccountLifeCopyWith<$Res> {
  factory _$ArenaAccountLifeCopyWith(_ArenaAccountLife value, $Res Function(_ArenaAccountLife) _then) = __$ArenaAccountLifeCopyWithImpl;
@override @useResult
$Res call({
 String accountId, String name, double initial, double current
});




}
/// @nodoc
class __$ArenaAccountLifeCopyWithImpl<$Res>
    implements _$ArenaAccountLifeCopyWith<$Res> {
  __$ArenaAccountLifeCopyWithImpl(this._self, this._then);

  final _ArenaAccountLife _self;
  final $Res Function(_ArenaAccountLife) _then;

/// Create a copy of ArenaAccountLife
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountId = null,Object? name = null,Object? initial = null,Object? current = null,}) {
  return _then(_ArenaAccountLife(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,initial: null == initial ? _self.initial : initial // ignore: cast_nullable_to_non_nullable
as double,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$ArenaPendingEvent {

/// Despesa lançada: fere os heróis, porque o saldo é o HP.
 double get damage;/// Receita recebida: cura.
 double get healed;
/// Create a copy of ArenaPendingEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArenaPendingEventCopyWith<ArenaPendingEvent> get copyWith => _$ArenaPendingEventCopyWithImpl<ArenaPendingEvent>(this as ArenaPendingEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArenaPendingEvent&&(identical(other.damage, damage) || other.damage == damage)&&(identical(other.healed, healed) || other.healed == healed));
}


@override
int get hashCode => Object.hash(runtimeType,damage,healed);

@override
String toString() {
  return 'ArenaPendingEvent(damage: $damage, healed: $healed)';
}


}

/// @nodoc
abstract mixin class $ArenaPendingEventCopyWith<$Res>  {
  factory $ArenaPendingEventCopyWith(ArenaPendingEvent value, $Res Function(ArenaPendingEvent) _then) = _$ArenaPendingEventCopyWithImpl;
@useResult
$Res call({
 double damage, double healed
});




}
/// @nodoc
class _$ArenaPendingEventCopyWithImpl<$Res>
    implements $ArenaPendingEventCopyWith<$Res> {
  _$ArenaPendingEventCopyWithImpl(this._self, this._then);

  final ArenaPendingEvent _self;
  final $Res Function(ArenaPendingEvent) _then;

/// Create a copy of ArenaPendingEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? damage = null,Object? healed = null,}) {
  return _then(_self.copyWith(
damage: null == damage ? _self.damage : damage // ignore: cast_nullable_to_non_nullable
as double,healed: null == healed ? _self.healed : healed // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ArenaPendingEvent].
extension ArenaPendingEventPatterns on ArenaPendingEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArenaPendingEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArenaPendingEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArenaPendingEvent value)  $default,){
final _that = this;
switch (_that) {
case _ArenaPendingEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArenaPendingEvent value)?  $default,){
final _that = this;
switch (_that) {
case _ArenaPendingEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double damage,  double healed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArenaPendingEvent() when $default != null:
return $default(_that.damage,_that.healed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double damage,  double healed)  $default,) {final _that = this;
switch (_that) {
case _ArenaPendingEvent():
return $default(_that.damage,_that.healed);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double damage,  double healed)?  $default,) {final _that = this;
switch (_that) {
case _ArenaPendingEvent() when $default != null:
return $default(_that.damage,_that.healed);case _:
  return null;

}
}

}

/// @nodoc


class _ArenaPendingEvent implements ArenaPendingEvent {
  const _ArenaPendingEvent({this.damage = 0, this.healed = 0});
  

/// Despesa lançada: fere os heróis, porque o saldo é o HP.
@override@JsonKey() final  double damage;
/// Receita recebida: cura.
@override@JsonKey() final  double healed;

/// Create a copy of ArenaPendingEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArenaPendingEventCopyWith<_ArenaPendingEvent> get copyWith => __$ArenaPendingEventCopyWithImpl<_ArenaPendingEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArenaPendingEvent&&(identical(other.damage, damage) || other.damage == damage)&&(identical(other.healed, healed) || other.healed == healed));
}


@override
int get hashCode => Object.hash(runtimeType,damage,healed);

@override
String toString() {
  return 'ArenaPendingEvent(damage: $damage, healed: $healed)';
}


}

/// @nodoc
abstract mixin class _$ArenaPendingEventCopyWith<$Res> implements $ArenaPendingEventCopyWith<$Res> {
  factory _$ArenaPendingEventCopyWith(_ArenaPendingEvent value, $Res Function(_ArenaPendingEvent) _then) = __$ArenaPendingEventCopyWithImpl;
@override @useResult
$Res call({
 double damage, double healed
});




}
/// @nodoc
class __$ArenaPendingEventCopyWithImpl<$Res>
    implements _$ArenaPendingEventCopyWith<$Res> {
  __$ArenaPendingEventCopyWithImpl(this._self, this._then);

  final _ArenaPendingEvent _self;
  final $Res Function(_ArenaPendingEvent) _then;

/// Create a copy of ArenaPendingEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? damage = null,Object? healed = null,}) {
  return _then(_ArenaPendingEvent(
damage: null == damage ? _self.damage : damage // ignore: cast_nullable_to_non_nullable
as double,healed: null == healed ? _self.healed : healed // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$ArenaState {

/// `YYYY-Www` — a semana do servidor.
 String get weekId;/// Em que dia da semana estamos. O marcador central do HUD.
 ArenaDay get day;// ── Heróis ─────────────────────────────────────────────────────────────
/// Caixa no DOMINGO 00:00: soma dos últimos saldos anteriores ao domingo
/// das contas líquidas (corrente + investimento). É o HP MÁXIMO.
 double get initialBalance;/// Caixa AGORA: soma dos últimos saldos das mesmas contas. É o HP ATUAL.
 double get currentBalance;/// As contas que compõem os dois números, para o detalhe.
 List<ArenaAccountLife> get accounts;/// Receitas recebidas na semana. É a CURA — e é o que pode fazer o atual
/// passar do inicial.
 double get healedThisWeek;// ── Monstro ────────────────────────────────────────────────────────────
/// TODOS os compromissos agendados da semana (pagos e pendentes) mais o
/// atraso das semanas anteriores, já ordenados para a folha.
 List<ArenaCommitment> get commitments;/// Soma de tudo o que a semana tinha para pagar. HP INICIAL do monstro.
 double get commitmentsInitial;/// O que ainda falta pagar. HP ATUAL do monstro.
 double get commitmentsRemaining;/// O que está atrasado de semanas anteriores. Enfurece e vira cicatriz.
 double get overdueAmount; MonsterSkin get monsterSkin;// ── Elenco ─────────────────────────────────────────────────────────────
 List<ArenaHero> get heroes;/// Membros além dos dois que viram herói. Vira um contador na cena.
 int get extraMembers;/// XP da semana, do `weekly_xp` do servidor. Só alimenta as moedas.
 double get weeklyXp;
/// Create a copy of ArenaState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArenaStateCopyWith<ArenaState> get copyWith => _$ArenaStateCopyWithImpl<ArenaState>(this as ArenaState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArenaState&&(identical(other.weekId, weekId) || other.weekId == weekId)&&(identical(other.day, day) || other.day == day)&&(identical(other.initialBalance, initialBalance) || other.initialBalance == initialBalance)&&(identical(other.currentBalance, currentBalance) || other.currentBalance == currentBalance)&&const DeepCollectionEquality().equals(other.accounts, accounts)&&(identical(other.healedThisWeek, healedThisWeek) || other.healedThisWeek == healedThisWeek)&&const DeepCollectionEquality().equals(other.commitments, commitments)&&(identical(other.commitmentsInitial, commitmentsInitial) || other.commitmentsInitial == commitmentsInitial)&&(identical(other.commitmentsRemaining, commitmentsRemaining) || other.commitmentsRemaining == commitmentsRemaining)&&(identical(other.overdueAmount, overdueAmount) || other.overdueAmount == overdueAmount)&&(identical(other.monsterSkin, monsterSkin) || other.monsterSkin == monsterSkin)&&const DeepCollectionEquality().equals(other.heroes, heroes)&&(identical(other.extraMembers, extraMembers) || other.extraMembers == extraMembers)&&(identical(other.weeklyXp, weeklyXp) || other.weeklyXp == weeklyXp));
}


@override
int get hashCode => Object.hash(runtimeType,weekId,day,initialBalance,currentBalance,const DeepCollectionEquality().hash(accounts),healedThisWeek,const DeepCollectionEquality().hash(commitments),commitmentsInitial,commitmentsRemaining,overdueAmount,monsterSkin,const DeepCollectionEquality().hash(heroes),extraMembers,weeklyXp);

@override
String toString() {
  return 'ArenaState(weekId: $weekId, day: $day, initialBalance: $initialBalance, currentBalance: $currentBalance, accounts: $accounts, healedThisWeek: $healedThisWeek, commitments: $commitments, commitmentsInitial: $commitmentsInitial, commitmentsRemaining: $commitmentsRemaining, overdueAmount: $overdueAmount, monsterSkin: $monsterSkin, heroes: $heroes, extraMembers: $extraMembers, weeklyXp: $weeklyXp)';
}


}

/// @nodoc
abstract mixin class $ArenaStateCopyWith<$Res>  {
  factory $ArenaStateCopyWith(ArenaState value, $Res Function(ArenaState) _then) = _$ArenaStateCopyWithImpl;
@useResult
$Res call({
 String weekId, ArenaDay day, double initialBalance, double currentBalance, List<ArenaAccountLife> accounts, double healedThisWeek, List<ArenaCommitment> commitments, double commitmentsInitial, double commitmentsRemaining, double overdueAmount, MonsterSkin monsterSkin, List<ArenaHero> heroes, int extraMembers, double weeklyXp
});




}
/// @nodoc
class _$ArenaStateCopyWithImpl<$Res>
    implements $ArenaStateCopyWith<$Res> {
  _$ArenaStateCopyWithImpl(this._self, this._then);

  final ArenaState _self;
  final $Res Function(ArenaState) _then;

/// Create a copy of ArenaState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekId = null,Object? day = null,Object? initialBalance = null,Object? currentBalance = null,Object? accounts = null,Object? healedThisWeek = null,Object? commitments = null,Object? commitmentsInitial = null,Object? commitmentsRemaining = null,Object? overdueAmount = null,Object? monsterSkin = null,Object? heroes = null,Object? extraMembers = null,Object? weeklyXp = null,}) {
  return _then(_self.copyWith(
weekId: null == weekId ? _self.weekId : weekId // ignore: cast_nullable_to_non_nullable
as String,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as ArenaDay,initialBalance: null == initialBalance ? _self.initialBalance : initialBalance // ignore: cast_nullable_to_non_nullable
as double,currentBalance: null == currentBalance ? _self.currentBalance : currentBalance // ignore: cast_nullable_to_non_nullable
as double,accounts: null == accounts ? _self.accounts : accounts // ignore: cast_nullable_to_non_nullable
as List<ArenaAccountLife>,healedThisWeek: null == healedThisWeek ? _self.healedThisWeek : healedThisWeek // ignore: cast_nullable_to_non_nullable
as double,commitments: null == commitments ? _self.commitments : commitments // ignore: cast_nullable_to_non_nullable
as List<ArenaCommitment>,commitmentsInitial: null == commitmentsInitial ? _self.commitmentsInitial : commitmentsInitial // ignore: cast_nullable_to_non_nullable
as double,commitmentsRemaining: null == commitmentsRemaining ? _self.commitmentsRemaining : commitmentsRemaining // ignore: cast_nullable_to_non_nullable
as double,overdueAmount: null == overdueAmount ? _self.overdueAmount : overdueAmount // ignore: cast_nullable_to_non_nullable
as double,monsterSkin: null == monsterSkin ? _self.monsterSkin : monsterSkin // ignore: cast_nullable_to_non_nullable
as MonsterSkin,heroes: null == heroes ? _self.heroes : heroes // ignore: cast_nullable_to_non_nullable
as List<ArenaHero>,extraMembers: null == extraMembers ? _self.extraMembers : extraMembers // ignore: cast_nullable_to_non_nullable
as int,weeklyXp: null == weeklyXp ? _self.weeklyXp : weeklyXp // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ArenaState].
extension ArenaStatePatterns on ArenaState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArenaState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArenaState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArenaState value)  $default,){
final _that = this;
switch (_that) {
case _ArenaState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArenaState value)?  $default,){
final _that = this;
switch (_that) {
case _ArenaState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String weekId,  ArenaDay day,  double initialBalance,  double currentBalance,  List<ArenaAccountLife> accounts,  double healedThisWeek,  List<ArenaCommitment> commitments,  double commitmentsInitial,  double commitmentsRemaining,  double overdueAmount,  MonsterSkin monsterSkin,  List<ArenaHero> heroes,  int extraMembers,  double weeklyXp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArenaState() when $default != null:
return $default(_that.weekId,_that.day,_that.initialBalance,_that.currentBalance,_that.accounts,_that.healedThisWeek,_that.commitments,_that.commitmentsInitial,_that.commitmentsRemaining,_that.overdueAmount,_that.monsterSkin,_that.heroes,_that.extraMembers,_that.weeklyXp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String weekId,  ArenaDay day,  double initialBalance,  double currentBalance,  List<ArenaAccountLife> accounts,  double healedThisWeek,  List<ArenaCommitment> commitments,  double commitmentsInitial,  double commitmentsRemaining,  double overdueAmount,  MonsterSkin monsterSkin,  List<ArenaHero> heroes,  int extraMembers,  double weeklyXp)  $default,) {final _that = this;
switch (_that) {
case _ArenaState():
return $default(_that.weekId,_that.day,_that.initialBalance,_that.currentBalance,_that.accounts,_that.healedThisWeek,_that.commitments,_that.commitmentsInitial,_that.commitmentsRemaining,_that.overdueAmount,_that.monsterSkin,_that.heroes,_that.extraMembers,_that.weeklyXp);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String weekId,  ArenaDay day,  double initialBalance,  double currentBalance,  List<ArenaAccountLife> accounts,  double healedThisWeek,  List<ArenaCommitment> commitments,  double commitmentsInitial,  double commitmentsRemaining,  double overdueAmount,  MonsterSkin monsterSkin,  List<ArenaHero> heroes,  int extraMembers,  double weeklyXp)?  $default,) {final _that = this;
switch (_that) {
case _ArenaState() when $default != null:
return $default(_that.weekId,_that.day,_that.initialBalance,_that.currentBalance,_that.accounts,_that.healedThisWeek,_that.commitments,_that.commitmentsInitial,_that.commitmentsRemaining,_that.overdueAmount,_that.monsterSkin,_that.heroes,_that.extraMembers,_that.weeklyXp);case _:
  return null;

}
}

}

/// @nodoc


class _ArenaState extends ArenaState {
  const _ArenaState({required this.weekId, required this.day, required this.initialBalance, required this.currentBalance, final  List<ArenaAccountLife> accounts = const <ArenaAccountLife>[], required this.healedThisWeek, final  List<ArenaCommitment> commitments = const <ArenaCommitment>[], required this.commitmentsInitial, required this.commitmentsRemaining, required this.overdueAmount, required this.monsterSkin, final  List<ArenaHero> heroes = const <ArenaHero>[], this.extraMembers = 0, this.weeklyXp = 0}): _accounts = accounts,_commitments = commitments,_heroes = heroes,super._();
  

/// `YYYY-Www` — a semana do servidor.
@override final  String weekId;
/// Em que dia da semana estamos. O marcador central do HUD.
@override final  ArenaDay day;
// ── Heróis ─────────────────────────────────────────────────────────────
/// Caixa no DOMINGO 00:00: soma dos últimos saldos anteriores ao domingo
/// das contas líquidas (corrente + investimento). É o HP MÁXIMO.
@override final  double initialBalance;
/// Caixa AGORA: soma dos últimos saldos das mesmas contas. É o HP ATUAL.
@override final  double currentBalance;
/// As contas que compõem os dois números, para o detalhe.
 final  List<ArenaAccountLife> _accounts;
/// As contas que compõem os dois números, para o detalhe.
@override@JsonKey() List<ArenaAccountLife> get accounts {
  if (_accounts is EqualUnmodifiableListView) return _accounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_accounts);
}

/// Receitas recebidas na semana. É a CURA — e é o que pode fazer o atual
/// passar do inicial.
@override final  double healedThisWeek;
// ── Monstro ────────────────────────────────────────────────────────────
/// TODOS os compromissos agendados da semana (pagos e pendentes) mais o
/// atraso das semanas anteriores, já ordenados para a folha.
 final  List<ArenaCommitment> _commitments;
// ── Monstro ────────────────────────────────────────────────────────────
/// TODOS os compromissos agendados da semana (pagos e pendentes) mais o
/// atraso das semanas anteriores, já ordenados para a folha.
@override@JsonKey() List<ArenaCommitment> get commitments {
  if (_commitments is EqualUnmodifiableListView) return _commitments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_commitments);
}

/// Soma de tudo o que a semana tinha para pagar. HP INICIAL do monstro.
@override final  double commitmentsInitial;
/// O que ainda falta pagar. HP ATUAL do monstro.
@override final  double commitmentsRemaining;
/// O que está atrasado de semanas anteriores. Enfurece e vira cicatriz.
@override final  double overdueAmount;
@override final  MonsterSkin monsterSkin;
// ── Elenco ─────────────────────────────────────────────────────────────
 final  List<ArenaHero> _heroes;
// ── Elenco ─────────────────────────────────────────────────────────────
@override@JsonKey() List<ArenaHero> get heroes {
  if (_heroes is EqualUnmodifiableListView) return _heroes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_heroes);
}

/// Membros além dos dois que viram herói. Vira um contador na cena.
@override@JsonKey() final  int extraMembers;
/// XP da semana, do `weekly_xp` do servidor. Só alimenta as moedas.
@override@JsonKey() final  double weeklyXp;

/// Create a copy of ArenaState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArenaStateCopyWith<_ArenaState> get copyWith => __$ArenaStateCopyWithImpl<_ArenaState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArenaState&&(identical(other.weekId, weekId) || other.weekId == weekId)&&(identical(other.day, day) || other.day == day)&&(identical(other.initialBalance, initialBalance) || other.initialBalance == initialBalance)&&(identical(other.currentBalance, currentBalance) || other.currentBalance == currentBalance)&&const DeepCollectionEquality().equals(other._accounts, _accounts)&&(identical(other.healedThisWeek, healedThisWeek) || other.healedThisWeek == healedThisWeek)&&const DeepCollectionEquality().equals(other._commitments, _commitments)&&(identical(other.commitmentsInitial, commitmentsInitial) || other.commitmentsInitial == commitmentsInitial)&&(identical(other.commitmentsRemaining, commitmentsRemaining) || other.commitmentsRemaining == commitmentsRemaining)&&(identical(other.overdueAmount, overdueAmount) || other.overdueAmount == overdueAmount)&&(identical(other.monsterSkin, monsterSkin) || other.monsterSkin == monsterSkin)&&const DeepCollectionEquality().equals(other._heroes, _heroes)&&(identical(other.extraMembers, extraMembers) || other.extraMembers == extraMembers)&&(identical(other.weeklyXp, weeklyXp) || other.weeklyXp == weeklyXp));
}


@override
int get hashCode => Object.hash(runtimeType,weekId,day,initialBalance,currentBalance,const DeepCollectionEquality().hash(_accounts),healedThisWeek,const DeepCollectionEquality().hash(_commitments),commitmentsInitial,commitmentsRemaining,overdueAmount,monsterSkin,const DeepCollectionEquality().hash(_heroes),extraMembers,weeklyXp);

@override
String toString() {
  return 'ArenaState(weekId: $weekId, day: $day, initialBalance: $initialBalance, currentBalance: $currentBalance, accounts: $accounts, healedThisWeek: $healedThisWeek, commitments: $commitments, commitmentsInitial: $commitmentsInitial, commitmentsRemaining: $commitmentsRemaining, overdueAmount: $overdueAmount, monsterSkin: $monsterSkin, heroes: $heroes, extraMembers: $extraMembers, weeklyXp: $weeklyXp)';
}


}

/// @nodoc
abstract mixin class _$ArenaStateCopyWith<$Res> implements $ArenaStateCopyWith<$Res> {
  factory _$ArenaStateCopyWith(_ArenaState value, $Res Function(_ArenaState) _then) = __$ArenaStateCopyWithImpl;
@override @useResult
$Res call({
 String weekId, ArenaDay day, double initialBalance, double currentBalance, List<ArenaAccountLife> accounts, double healedThisWeek, List<ArenaCommitment> commitments, double commitmentsInitial, double commitmentsRemaining, double overdueAmount, MonsterSkin monsterSkin, List<ArenaHero> heroes, int extraMembers, double weeklyXp
});




}
/// @nodoc
class __$ArenaStateCopyWithImpl<$Res>
    implements _$ArenaStateCopyWith<$Res> {
  __$ArenaStateCopyWithImpl(this._self, this._then);

  final _ArenaState _self;
  final $Res Function(_ArenaState) _then;

/// Create a copy of ArenaState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekId = null,Object? day = null,Object? initialBalance = null,Object? currentBalance = null,Object? accounts = null,Object? healedThisWeek = null,Object? commitments = null,Object? commitmentsInitial = null,Object? commitmentsRemaining = null,Object? overdueAmount = null,Object? monsterSkin = null,Object? heroes = null,Object? extraMembers = null,Object? weeklyXp = null,}) {
  return _then(_ArenaState(
weekId: null == weekId ? _self.weekId : weekId // ignore: cast_nullable_to_non_nullable
as String,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as ArenaDay,initialBalance: null == initialBalance ? _self.initialBalance : initialBalance // ignore: cast_nullable_to_non_nullable
as double,currentBalance: null == currentBalance ? _self.currentBalance : currentBalance // ignore: cast_nullable_to_non_nullable
as double,accounts: null == accounts ? _self._accounts : accounts // ignore: cast_nullable_to_non_nullable
as List<ArenaAccountLife>,healedThisWeek: null == healedThisWeek ? _self.healedThisWeek : healedThisWeek // ignore: cast_nullable_to_non_nullable
as double,commitments: null == commitments ? _self._commitments : commitments // ignore: cast_nullable_to_non_nullable
as List<ArenaCommitment>,commitmentsInitial: null == commitmentsInitial ? _self.commitmentsInitial : commitmentsInitial // ignore: cast_nullable_to_non_nullable
as double,commitmentsRemaining: null == commitmentsRemaining ? _self.commitmentsRemaining : commitmentsRemaining // ignore: cast_nullable_to_non_nullable
as double,overdueAmount: null == overdueAmount ? _self.overdueAmount : overdueAmount // ignore: cast_nullable_to_non_nullable
as double,monsterSkin: null == monsterSkin ? _self.monsterSkin : monsterSkin // ignore: cast_nullable_to_non_nullable
as MonsterSkin,heroes: null == heroes ? _self._heroes : heroes // ignore: cast_nullable_to_non_nullable
as List<ArenaHero>,extraMembers: null == extraMembers ? _self.extraMembers : extraMembers // ignore: cast_nullable_to_non_nullable
as int,weeklyXp: null == weeklyXp ? _self.weeklyXp : weeklyXp // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
