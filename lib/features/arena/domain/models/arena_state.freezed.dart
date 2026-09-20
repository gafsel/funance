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
mixin _$ArenaState {

/// `YYYY-Www` — a semana do servidor.
 String get weekId;// ── Herói ──────────────────────────────────────────────────────────────
/// Dinheiro nas contas líquidas: corrente + investimento (a "poupança"
/// deste modelo de dados). Cartão e dívida ficam de fora — o que está no
/// cartão ainda não saiu, e dívida não é caixa.
 double get liquidBalance;/// Receitas recebidas na semana. É a CURA.
 double get healedThisWeek;/// Gasto fora do plano, ou acima do limite da categoria. É o DANO.
 double get damageThisWeek;// ── Monstro ────────────────────────────────────────────────────────────
/// Parcelas de despesa da semana (pagas + pendentes) somadas ao atraso.
 double get installmentsInitial;/// O que dessas parcelas ainda não foi pago.
 double get installmentsRemaining;/// Rateio semanal dos limites planejados, como o servidor o agregou.
 double get budgetInitial;/// Quanto do orçamento da semana ainda não foi gasto.
 double get budgetRemaining;/// Parcelas pendentes vencidas ANTES desta semana. Deixam o monstro
/// enfurecido e viram a cicatriz "+R$ X atrasado".
 double get overdueAmount; MonsterSkin get monsterSkin;// ── Elenco e cenário ───────────────────────────────────────────────────
 List<ArenaHero> get heroes;/// Membros além dos dois que viram herói. Vira um contador na cena.
 int get extraMembers;/// XP da semana, do `weekly_xp` do servidor. Só alimenta as moedas.
 double get weeklyXp;/// Fatura aberta do cartão principal — o casulo. `null` = sem cartão, ou
/// resumo ainda não gravado pelo servidor.
 double? get invoiceAmount;/// Id da parcela da fatura, para o toque no casulo abrir `/invoices/{id}`.
 String? get invoiceInstallmentId;/// As parcelas de despesa da semana ainda PENDENTES, na ordem de
/// vencimento. É o que a folha do monstro lista.
 List<InstallmentModel> get pendingInstallments;
/// Create a copy of ArenaState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArenaStateCopyWith<ArenaState> get copyWith => _$ArenaStateCopyWithImpl<ArenaState>(this as ArenaState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArenaState&&(identical(other.weekId, weekId) || other.weekId == weekId)&&(identical(other.liquidBalance, liquidBalance) || other.liquidBalance == liquidBalance)&&(identical(other.healedThisWeek, healedThisWeek) || other.healedThisWeek == healedThisWeek)&&(identical(other.damageThisWeek, damageThisWeek) || other.damageThisWeek == damageThisWeek)&&(identical(other.installmentsInitial, installmentsInitial) || other.installmentsInitial == installmentsInitial)&&(identical(other.installmentsRemaining, installmentsRemaining) || other.installmentsRemaining == installmentsRemaining)&&(identical(other.budgetInitial, budgetInitial) || other.budgetInitial == budgetInitial)&&(identical(other.budgetRemaining, budgetRemaining) || other.budgetRemaining == budgetRemaining)&&(identical(other.overdueAmount, overdueAmount) || other.overdueAmount == overdueAmount)&&(identical(other.monsterSkin, monsterSkin) || other.monsterSkin == monsterSkin)&&const DeepCollectionEquality().equals(other.heroes, heroes)&&(identical(other.extraMembers, extraMembers) || other.extraMembers == extraMembers)&&(identical(other.weeklyXp, weeklyXp) || other.weeklyXp == weeklyXp)&&(identical(other.invoiceAmount, invoiceAmount) || other.invoiceAmount == invoiceAmount)&&(identical(other.invoiceInstallmentId, invoiceInstallmentId) || other.invoiceInstallmentId == invoiceInstallmentId)&&const DeepCollectionEquality().equals(other.pendingInstallments, pendingInstallments));
}


@override
int get hashCode => Object.hash(runtimeType,weekId,liquidBalance,healedThisWeek,damageThisWeek,installmentsInitial,installmentsRemaining,budgetInitial,budgetRemaining,overdueAmount,monsterSkin,const DeepCollectionEquality().hash(heroes),extraMembers,weeklyXp,invoiceAmount,invoiceInstallmentId,const DeepCollectionEquality().hash(pendingInstallments));

@override
String toString() {
  return 'ArenaState(weekId: $weekId, liquidBalance: $liquidBalance, healedThisWeek: $healedThisWeek, damageThisWeek: $damageThisWeek, installmentsInitial: $installmentsInitial, installmentsRemaining: $installmentsRemaining, budgetInitial: $budgetInitial, budgetRemaining: $budgetRemaining, overdueAmount: $overdueAmount, monsterSkin: $monsterSkin, heroes: $heroes, extraMembers: $extraMembers, weeklyXp: $weeklyXp, invoiceAmount: $invoiceAmount, invoiceInstallmentId: $invoiceInstallmentId, pendingInstallments: $pendingInstallments)';
}


}

/// @nodoc
abstract mixin class $ArenaStateCopyWith<$Res>  {
  factory $ArenaStateCopyWith(ArenaState value, $Res Function(ArenaState) _then) = _$ArenaStateCopyWithImpl;
@useResult
$Res call({
 String weekId, double liquidBalance, double healedThisWeek, double damageThisWeek, double installmentsInitial, double installmentsRemaining, double budgetInitial, double budgetRemaining, double overdueAmount, MonsterSkin monsterSkin, List<ArenaHero> heroes, int extraMembers, double weeklyXp, double? invoiceAmount, String? invoiceInstallmentId, List<InstallmentModel> pendingInstallments
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
@pragma('vm:prefer-inline') @override $Res call({Object? weekId = null,Object? liquidBalance = null,Object? healedThisWeek = null,Object? damageThisWeek = null,Object? installmentsInitial = null,Object? installmentsRemaining = null,Object? budgetInitial = null,Object? budgetRemaining = null,Object? overdueAmount = null,Object? monsterSkin = null,Object? heroes = null,Object? extraMembers = null,Object? weeklyXp = null,Object? invoiceAmount = freezed,Object? invoiceInstallmentId = freezed,Object? pendingInstallments = null,}) {
  return _then(_self.copyWith(
weekId: null == weekId ? _self.weekId : weekId // ignore: cast_nullable_to_non_nullable
as String,liquidBalance: null == liquidBalance ? _self.liquidBalance : liquidBalance // ignore: cast_nullable_to_non_nullable
as double,healedThisWeek: null == healedThisWeek ? _self.healedThisWeek : healedThisWeek // ignore: cast_nullable_to_non_nullable
as double,damageThisWeek: null == damageThisWeek ? _self.damageThisWeek : damageThisWeek // ignore: cast_nullable_to_non_nullable
as double,installmentsInitial: null == installmentsInitial ? _self.installmentsInitial : installmentsInitial // ignore: cast_nullable_to_non_nullable
as double,installmentsRemaining: null == installmentsRemaining ? _self.installmentsRemaining : installmentsRemaining // ignore: cast_nullable_to_non_nullable
as double,budgetInitial: null == budgetInitial ? _self.budgetInitial : budgetInitial // ignore: cast_nullable_to_non_nullable
as double,budgetRemaining: null == budgetRemaining ? _self.budgetRemaining : budgetRemaining // ignore: cast_nullable_to_non_nullable
as double,overdueAmount: null == overdueAmount ? _self.overdueAmount : overdueAmount // ignore: cast_nullable_to_non_nullable
as double,monsterSkin: null == monsterSkin ? _self.monsterSkin : monsterSkin // ignore: cast_nullable_to_non_nullable
as MonsterSkin,heroes: null == heroes ? _self.heroes : heroes // ignore: cast_nullable_to_non_nullable
as List<ArenaHero>,extraMembers: null == extraMembers ? _self.extraMembers : extraMembers // ignore: cast_nullable_to_non_nullable
as int,weeklyXp: null == weeklyXp ? _self.weeklyXp : weeklyXp // ignore: cast_nullable_to_non_nullable
as double,invoiceAmount: freezed == invoiceAmount ? _self.invoiceAmount : invoiceAmount // ignore: cast_nullable_to_non_nullable
as double?,invoiceInstallmentId: freezed == invoiceInstallmentId ? _self.invoiceInstallmentId : invoiceInstallmentId // ignore: cast_nullable_to_non_nullable
as String?,pendingInstallments: null == pendingInstallments ? _self.pendingInstallments : pendingInstallments // ignore: cast_nullable_to_non_nullable
as List<InstallmentModel>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String weekId,  double liquidBalance,  double healedThisWeek,  double damageThisWeek,  double installmentsInitial,  double installmentsRemaining,  double budgetInitial,  double budgetRemaining,  double overdueAmount,  MonsterSkin monsterSkin,  List<ArenaHero> heroes,  int extraMembers,  double weeklyXp,  double? invoiceAmount,  String? invoiceInstallmentId,  List<InstallmentModel> pendingInstallments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArenaState() when $default != null:
return $default(_that.weekId,_that.liquidBalance,_that.healedThisWeek,_that.damageThisWeek,_that.installmentsInitial,_that.installmentsRemaining,_that.budgetInitial,_that.budgetRemaining,_that.overdueAmount,_that.monsterSkin,_that.heroes,_that.extraMembers,_that.weeklyXp,_that.invoiceAmount,_that.invoiceInstallmentId,_that.pendingInstallments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String weekId,  double liquidBalance,  double healedThisWeek,  double damageThisWeek,  double installmentsInitial,  double installmentsRemaining,  double budgetInitial,  double budgetRemaining,  double overdueAmount,  MonsterSkin monsterSkin,  List<ArenaHero> heroes,  int extraMembers,  double weeklyXp,  double? invoiceAmount,  String? invoiceInstallmentId,  List<InstallmentModel> pendingInstallments)  $default,) {final _that = this;
switch (_that) {
case _ArenaState():
return $default(_that.weekId,_that.liquidBalance,_that.healedThisWeek,_that.damageThisWeek,_that.installmentsInitial,_that.installmentsRemaining,_that.budgetInitial,_that.budgetRemaining,_that.overdueAmount,_that.monsterSkin,_that.heroes,_that.extraMembers,_that.weeklyXp,_that.invoiceAmount,_that.invoiceInstallmentId,_that.pendingInstallments);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String weekId,  double liquidBalance,  double healedThisWeek,  double damageThisWeek,  double installmentsInitial,  double installmentsRemaining,  double budgetInitial,  double budgetRemaining,  double overdueAmount,  MonsterSkin monsterSkin,  List<ArenaHero> heroes,  int extraMembers,  double weeklyXp,  double? invoiceAmount,  String? invoiceInstallmentId,  List<InstallmentModel> pendingInstallments)?  $default,) {final _that = this;
switch (_that) {
case _ArenaState() when $default != null:
return $default(_that.weekId,_that.liquidBalance,_that.healedThisWeek,_that.damageThisWeek,_that.installmentsInitial,_that.installmentsRemaining,_that.budgetInitial,_that.budgetRemaining,_that.overdueAmount,_that.monsterSkin,_that.heroes,_that.extraMembers,_that.weeklyXp,_that.invoiceAmount,_that.invoiceInstallmentId,_that.pendingInstallments);case _:
  return null;

}
}

}

/// @nodoc


class _ArenaState extends ArenaState {
  const _ArenaState({required this.weekId, required this.liquidBalance, required this.healedThisWeek, required this.damageThisWeek, required this.installmentsInitial, required this.installmentsRemaining, required this.budgetInitial, required this.budgetRemaining, required this.overdueAmount, required this.monsterSkin, final  List<ArenaHero> heroes = const <ArenaHero>[], this.extraMembers = 0, this.weeklyXp = 0, this.invoiceAmount, this.invoiceInstallmentId, final  List<InstallmentModel> pendingInstallments = const <InstallmentModel>[]}): _heroes = heroes,_pendingInstallments = pendingInstallments,super._();
  

/// `YYYY-Www` — a semana do servidor.
@override final  String weekId;
// ── Herói ──────────────────────────────────────────────────────────────
/// Dinheiro nas contas líquidas: corrente + investimento (a "poupança"
/// deste modelo de dados). Cartão e dívida ficam de fora — o que está no
/// cartão ainda não saiu, e dívida não é caixa.
@override final  double liquidBalance;
/// Receitas recebidas na semana. É a CURA.
@override final  double healedThisWeek;
/// Gasto fora do plano, ou acima do limite da categoria. É o DANO.
@override final  double damageThisWeek;
// ── Monstro ────────────────────────────────────────────────────────────
/// Parcelas de despesa da semana (pagas + pendentes) somadas ao atraso.
@override final  double installmentsInitial;
/// O que dessas parcelas ainda não foi pago.
@override final  double installmentsRemaining;
/// Rateio semanal dos limites planejados, como o servidor o agregou.
@override final  double budgetInitial;
/// Quanto do orçamento da semana ainda não foi gasto.
@override final  double budgetRemaining;
/// Parcelas pendentes vencidas ANTES desta semana. Deixam o monstro
/// enfurecido e viram a cicatriz "+R$ X atrasado".
@override final  double overdueAmount;
@override final  MonsterSkin monsterSkin;
// ── Elenco e cenário ───────────────────────────────────────────────────
 final  List<ArenaHero> _heroes;
// ── Elenco e cenário ───────────────────────────────────────────────────
@override@JsonKey() List<ArenaHero> get heroes {
  if (_heroes is EqualUnmodifiableListView) return _heroes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_heroes);
}

/// Membros além dos dois que viram herói. Vira um contador na cena.
@override@JsonKey() final  int extraMembers;
/// XP da semana, do `weekly_xp` do servidor. Só alimenta as moedas.
@override@JsonKey() final  double weeklyXp;
/// Fatura aberta do cartão principal — o casulo. `null` = sem cartão, ou
/// resumo ainda não gravado pelo servidor.
@override final  double? invoiceAmount;
/// Id da parcela da fatura, para o toque no casulo abrir `/invoices/{id}`.
@override final  String? invoiceInstallmentId;
/// As parcelas de despesa da semana ainda PENDENTES, na ordem de
/// vencimento. É o que a folha do monstro lista.
 final  List<InstallmentModel> _pendingInstallments;
/// As parcelas de despesa da semana ainda PENDENTES, na ordem de
/// vencimento. É o que a folha do monstro lista.
@override@JsonKey() List<InstallmentModel> get pendingInstallments {
  if (_pendingInstallments is EqualUnmodifiableListView) return _pendingInstallments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pendingInstallments);
}


/// Create a copy of ArenaState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArenaStateCopyWith<_ArenaState> get copyWith => __$ArenaStateCopyWithImpl<_ArenaState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArenaState&&(identical(other.weekId, weekId) || other.weekId == weekId)&&(identical(other.liquidBalance, liquidBalance) || other.liquidBalance == liquidBalance)&&(identical(other.healedThisWeek, healedThisWeek) || other.healedThisWeek == healedThisWeek)&&(identical(other.damageThisWeek, damageThisWeek) || other.damageThisWeek == damageThisWeek)&&(identical(other.installmentsInitial, installmentsInitial) || other.installmentsInitial == installmentsInitial)&&(identical(other.installmentsRemaining, installmentsRemaining) || other.installmentsRemaining == installmentsRemaining)&&(identical(other.budgetInitial, budgetInitial) || other.budgetInitial == budgetInitial)&&(identical(other.budgetRemaining, budgetRemaining) || other.budgetRemaining == budgetRemaining)&&(identical(other.overdueAmount, overdueAmount) || other.overdueAmount == overdueAmount)&&(identical(other.monsterSkin, monsterSkin) || other.monsterSkin == monsterSkin)&&const DeepCollectionEquality().equals(other._heroes, _heroes)&&(identical(other.extraMembers, extraMembers) || other.extraMembers == extraMembers)&&(identical(other.weeklyXp, weeklyXp) || other.weeklyXp == weeklyXp)&&(identical(other.invoiceAmount, invoiceAmount) || other.invoiceAmount == invoiceAmount)&&(identical(other.invoiceInstallmentId, invoiceInstallmentId) || other.invoiceInstallmentId == invoiceInstallmentId)&&const DeepCollectionEquality().equals(other._pendingInstallments, _pendingInstallments));
}


@override
int get hashCode => Object.hash(runtimeType,weekId,liquidBalance,healedThisWeek,damageThisWeek,installmentsInitial,installmentsRemaining,budgetInitial,budgetRemaining,overdueAmount,monsterSkin,const DeepCollectionEquality().hash(_heroes),extraMembers,weeklyXp,invoiceAmount,invoiceInstallmentId,const DeepCollectionEquality().hash(_pendingInstallments));

@override
String toString() {
  return 'ArenaState(weekId: $weekId, liquidBalance: $liquidBalance, healedThisWeek: $healedThisWeek, damageThisWeek: $damageThisWeek, installmentsInitial: $installmentsInitial, installmentsRemaining: $installmentsRemaining, budgetInitial: $budgetInitial, budgetRemaining: $budgetRemaining, overdueAmount: $overdueAmount, monsterSkin: $monsterSkin, heroes: $heroes, extraMembers: $extraMembers, weeklyXp: $weeklyXp, invoiceAmount: $invoiceAmount, invoiceInstallmentId: $invoiceInstallmentId, pendingInstallments: $pendingInstallments)';
}


}

/// @nodoc
abstract mixin class _$ArenaStateCopyWith<$Res> implements $ArenaStateCopyWith<$Res> {
  factory _$ArenaStateCopyWith(_ArenaState value, $Res Function(_ArenaState) _then) = __$ArenaStateCopyWithImpl;
@override @useResult
$Res call({
 String weekId, double liquidBalance, double healedThisWeek, double damageThisWeek, double installmentsInitial, double installmentsRemaining, double budgetInitial, double budgetRemaining, double overdueAmount, MonsterSkin monsterSkin, List<ArenaHero> heroes, int extraMembers, double weeklyXp, double? invoiceAmount, String? invoiceInstallmentId, List<InstallmentModel> pendingInstallments
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
@override @pragma('vm:prefer-inline') $Res call({Object? weekId = null,Object? liquidBalance = null,Object? healedThisWeek = null,Object? damageThisWeek = null,Object? installmentsInitial = null,Object? installmentsRemaining = null,Object? budgetInitial = null,Object? budgetRemaining = null,Object? overdueAmount = null,Object? monsterSkin = null,Object? heroes = null,Object? extraMembers = null,Object? weeklyXp = null,Object? invoiceAmount = freezed,Object? invoiceInstallmentId = freezed,Object? pendingInstallments = null,}) {
  return _then(_ArenaState(
weekId: null == weekId ? _self.weekId : weekId // ignore: cast_nullable_to_non_nullable
as String,liquidBalance: null == liquidBalance ? _self.liquidBalance : liquidBalance // ignore: cast_nullable_to_non_nullable
as double,healedThisWeek: null == healedThisWeek ? _self.healedThisWeek : healedThisWeek // ignore: cast_nullable_to_non_nullable
as double,damageThisWeek: null == damageThisWeek ? _self.damageThisWeek : damageThisWeek // ignore: cast_nullable_to_non_nullable
as double,installmentsInitial: null == installmentsInitial ? _self.installmentsInitial : installmentsInitial // ignore: cast_nullable_to_non_nullable
as double,installmentsRemaining: null == installmentsRemaining ? _self.installmentsRemaining : installmentsRemaining // ignore: cast_nullable_to_non_nullable
as double,budgetInitial: null == budgetInitial ? _self.budgetInitial : budgetInitial // ignore: cast_nullable_to_non_nullable
as double,budgetRemaining: null == budgetRemaining ? _self.budgetRemaining : budgetRemaining // ignore: cast_nullable_to_non_nullable
as double,overdueAmount: null == overdueAmount ? _self.overdueAmount : overdueAmount // ignore: cast_nullable_to_non_nullable
as double,monsterSkin: null == monsterSkin ? _self.monsterSkin : monsterSkin // ignore: cast_nullable_to_non_nullable
as MonsterSkin,heroes: null == heroes ? _self._heroes : heroes // ignore: cast_nullable_to_non_nullable
as List<ArenaHero>,extraMembers: null == extraMembers ? _self.extraMembers : extraMembers // ignore: cast_nullable_to_non_nullable
as int,weeklyXp: null == weeklyXp ? _self.weeklyXp : weeklyXp // ignore: cast_nullable_to_non_nullable
as double,invoiceAmount: freezed == invoiceAmount ? _self.invoiceAmount : invoiceAmount // ignore: cast_nullable_to_non_nullable
as double?,invoiceInstallmentId: freezed == invoiceInstallmentId ? _self.invoiceInstallmentId : invoiceInstallmentId // ignore: cast_nullable_to_non_nullable
as String?,pendingInstallments: null == pendingInstallments ? _self._pendingInstallments : pendingInstallments // ignore: cast_nullable_to_non_nullable
as List<InstallmentModel>,
  ));
}


}

// dart format on
