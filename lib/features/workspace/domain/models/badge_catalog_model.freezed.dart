// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'badge_catalog_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BadgeCatalogItem {

 String get id;/// Nome por idioma (`{pt: ..., en: ...}`). Use [nameIn].
@JsonKey(fromJson: localizedText) Map<String, String> get name;/// Nome do ícone Material (ver `badgeIconFor`).
 String get icon; int get xpReward;@JsonKey(unknownEnumValue: BadgeCategory.unknown) BadgeCategory get category;/// Descrição por idioma. Use [descriptionIn].
@JsonKey(fromJson: localizedText) Map<String, String> get description;/// Para qual tipo de cofre a conquista existe: `personal`, `business` ou
/// `both`. O servidor materializa o campo em toda badge publicada, mas um
/// catálogo mais antigo pode não trazê-lo — e aí a badge vale para os
/// dois, que é o padrão do servidor.
@JsonKey(unknownEnumValue: BadgeAudience.both) BadgeAudience get audience;
/// Create a copy of BadgeCatalogItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BadgeCatalogItemCopyWith<BadgeCatalogItem> get copyWith => _$BadgeCatalogItemCopyWithImpl<BadgeCatalogItem>(this as BadgeCatalogItem, _$identity);

  /// Serializes this BadgeCatalogItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BadgeCatalogItem&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.name, name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.xpReward, xpReward) || other.xpReward == xpReward)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.description, description)&&(identical(other.audience, audience) || other.audience == audience));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(name),icon,xpReward,category,const DeepCollectionEquality().hash(description),audience);

@override
String toString() {
  return 'BadgeCatalogItem(id: $id, name: $name, icon: $icon, xpReward: $xpReward, category: $category, description: $description, audience: $audience)';
}


}

/// @nodoc
abstract mixin class $BadgeCatalogItemCopyWith<$Res>  {
  factory $BadgeCatalogItemCopyWith(BadgeCatalogItem value, $Res Function(BadgeCatalogItem) _then) = _$BadgeCatalogItemCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(fromJson: localizedText) Map<String, String> name, String icon, int xpReward,@JsonKey(unknownEnumValue: BadgeCategory.unknown) BadgeCategory category,@JsonKey(fromJson: localizedText) Map<String, String> description,@JsonKey(unknownEnumValue: BadgeAudience.both) BadgeAudience audience
});




}
/// @nodoc
class _$BadgeCatalogItemCopyWithImpl<$Res>
    implements $BadgeCatalogItemCopyWith<$Res> {
  _$BadgeCatalogItemCopyWithImpl(this._self, this._then);

  final BadgeCatalogItem _self;
  final $Res Function(BadgeCatalogItem) _then;

/// Create a copy of BadgeCatalogItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? xpReward = null,Object? category = null,Object? description = null,Object? audience = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as Map<String, String>,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,xpReward: null == xpReward ? _self.xpReward : xpReward // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as BadgeCategory,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as Map<String, String>,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as BadgeAudience,
  ));
}

}


/// Adds pattern-matching-related methods to [BadgeCatalogItem].
extension BadgeCatalogItemPatterns on BadgeCatalogItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BadgeCatalogItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BadgeCatalogItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BadgeCatalogItem value)  $default,){
final _that = this;
switch (_that) {
case _BadgeCatalogItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BadgeCatalogItem value)?  $default,){
final _that = this;
switch (_that) {
case _BadgeCatalogItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(fromJson: localizedText)  Map<String, String> name,  String icon,  int xpReward, @JsonKey(unknownEnumValue: BadgeCategory.unknown)  BadgeCategory category, @JsonKey(fromJson: localizedText)  Map<String, String> description, @JsonKey(unknownEnumValue: BadgeAudience.both)  BadgeAudience audience)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BadgeCatalogItem() when $default != null:
return $default(_that.id,_that.name,_that.icon,_that.xpReward,_that.category,_that.description,_that.audience);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(fromJson: localizedText)  Map<String, String> name,  String icon,  int xpReward, @JsonKey(unknownEnumValue: BadgeCategory.unknown)  BadgeCategory category, @JsonKey(fromJson: localizedText)  Map<String, String> description, @JsonKey(unknownEnumValue: BadgeAudience.both)  BadgeAudience audience)  $default,) {final _that = this;
switch (_that) {
case _BadgeCatalogItem():
return $default(_that.id,_that.name,_that.icon,_that.xpReward,_that.category,_that.description,_that.audience);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(fromJson: localizedText)  Map<String, String> name,  String icon,  int xpReward, @JsonKey(unknownEnumValue: BadgeCategory.unknown)  BadgeCategory category, @JsonKey(fromJson: localizedText)  Map<String, String> description, @JsonKey(unknownEnumValue: BadgeAudience.both)  BadgeAudience audience)?  $default,) {final _that = this;
switch (_that) {
case _BadgeCatalogItem() when $default != null:
return $default(_that.id,_that.name,_that.icon,_that.xpReward,_that.category,_that.description,_that.audience);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BadgeCatalogItem extends BadgeCatalogItem {
  const _BadgeCatalogItem({required this.id, @JsonKey(fromJson: localizedText) final  Map<String, String> name = const <String, String>{}, this.icon = '', this.xpReward = 0, @JsonKey(unknownEnumValue: BadgeCategory.unknown) this.category = BadgeCategory.unknown, @JsonKey(fromJson: localizedText) final  Map<String, String> description = const <String, String>{}, @JsonKey(unknownEnumValue: BadgeAudience.both) this.audience = BadgeAudience.both}): _name = name,_description = description,super._();
  factory _BadgeCatalogItem.fromJson(Map<String, dynamic> json) => _$BadgeCatalogItemFromJson(json);

@override final  String id;
/// Nome por idioma (`{pt: ..., en: ...}`). Use [nameIn].
 final  Map<String, String> _name;
/// Nome por idioma (`{pt: ..., en: ...}`). Use [nameIn].
@override@JsonKey(fromJson: localizedText) Map<String, String> get name {
  if (_name is EqualUnmodifiableMapView) return _name;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_name);
}

/// Nome do ícone Material (ver `badgeIconFor`).
@override@JsonKey() final  String icon;
@override@JsonKey() final  int xpReward;
@override@JsonKey(unknownEnumValue: BadgeCategory.unknown) final  BadgeCategory category;
/// Descrição por idioma. Use [descriptionIn].
 final  Map<String, String> _description;
/// Descrição por idioma. Use [descriptionIn].
@override@JsonKey(fromJson: localizedText) Map<String, String> get description {
  if (_description is EqualUnmodifiableMapView) return _description;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_description);
}

/// Para qual tipo de cofre a conquista existe: `personal`, `business` ou
/// `both`. O servidor materializa o campo em toda badge publicada, mas um
/// catálogo mais antigo pode não trazê-lo — e aí a badge vale para os
/// dois, que é o padrão do servidor.
@override@JsonKey(unknownEnumValue: BadgeAudience.both) final  BadgeAudience audience;

/// Create a copy of BadgeCatalogItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BadgeCatalogItemCopyWith<_BadgeCatalogItem> get copyWith => __$BadgeCatalogItemCopyWithImpl<_BadgeCatalogItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BadgeCatalogItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BadgeCatalogItem&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._name, _name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.xpReward, xpReward) || other.xpReward == xpReward)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._description, _description)&&(identical(other.audience, audience) || other.audience == audience));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_name),icon,xpReward,category,const DeepCollectionEquality().hash(_description),audience);

@override
String toString() {
  return 'BadgeCatalogItem(id: $id, name: $name, icon: $icon, xpReward: $xpReward, category: $category, description: $description, audience: $audience)';
}


}

/// @nodoc
abstract mixin class _$BadgeCatalogItemCopyWith<$Res> implements $BadgeCatalogItemCopyWith<$Res> {
  factory _$BadgeCatalogItemCopyWith(_BadgeCatalogItem value, $Res Function(_BadgeCatalogItem) _then) = __$BadgeCatalogItemCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(fromJson: localizedText) Map<String, String> name, String icon, int xpReward,@JsonKey(unknownEnumValue: BadgeCategory.unknown) BadgeCategory category,@JsonKey(fromJson: localizedText) Map<String, String> description,@JsonKey(unknownEnumValue: BadgeAudience.both) BadgeAudience audience
});




}
/// @nodoc
class __$BadgeCatalogItemCopyWithImpl<$Res>
    implements _$BadgeCatalogItemCopyWith<$Res> {
  __$BadgeCatalogItemCopyWithImpl(this._self, this._then);

  final _BadgeCatalogItem _self;
  final $Res Function(_BadgeCatalogItem) _then;

/// Create a copy of BadgeCatalogItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? icon = null,Object? xpReward = null,Object? category = null,Object? description = null,Object? audience = null,}) {
  return _then(_BadgeCatalogItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self._name : name // ignore: cast_nullable_to_non_nullable
as Map<String, String>,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,xpReward: null == xpReward ? _self.xpReward : xpReward // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as BadgeCategory,description: null == description ? _self._description : description // ignore: cast_nullable_to_non_nullable
as Map<String, String>,audience: null == audience ? _self.audience : audience // ignore: cast_nullable_to_non_nullable
as BadgeAudience,
  ));
}


}


/// @nodoc
mixin _$XpSource {

 String get id;/// Nome por idioma (`{pt: ..., en: ...}`). Use [nameIn].
@JsonKey(fromJson: localizedText) Map<String, String> get name; int get xp;/// Descrição por idioma. Use [descriptionIn].
@JsonKey(fromJson: localizedText) Map<String, String> get description;
/// Create a copy of XpSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XpSourceCopyWith<XpSource> get copyWith => _$XpSourceCopyWithImpl<XpSource>(this as XpSource, _$identity);

  /// Serializes this XpSource to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XpSource&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.name, name)&&(identical(other.xp, xp) || other.xp == xp)&&const DeepCollectionEquality().equals(other.description, description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(name),xp,const DeepCollectionEquality().hash(description));

@override
String toString() {
  return 'XpSource(id: $id, name: $name, xp: $xp, description: $description)';
}


}

/// @nodoc
abstract mixin class $XpSourceCopyWith<$Res>  {
  factory $XpSourceCopyWith(XpSource value, $Res Function(XpSource) _then) = _$XpSourceCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(fromJson: localizedText) Map<String, String> name, int xp,@JsonKey(fromJson: localizedText) Map<String, String> description
});




}
/// @nodoc
class _$XpSourceCopyWithImpl<$Res>
    implements $XpSourceCopyWith<$Res> {
  _$XpSourceCopyWithImpl(this._self, this._then);

  final XpSource _self;
  final $Res Function(XpSource) _then;

/// Create a copy of XpSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? xp = null,Object? description = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as Map<String, String>,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [XpSource].
extension XpSourcePatterns on XpSource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _XpSource value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _XpSource() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _XpSource value)  $default,){
final _that = this;
switch (_that) {
case _XpSource():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _XpSource value)?  $default,){
final _that = this;
switch (_that) {
case _XpSource() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(fromJson: localizedText)  Map<String, String> name,  int xp, @JsonKey(fromJson: localizedText)  Map<String, String> description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _XpSource() when $default != null:
return $default(_that.id,_that.name,_that.xp,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(fromJson: localizedText)  Map<String, String> name,  int xp, @JsonKey(fromJson: localizedText)  Map<String, String> description)  $default,) {final _that = this;
switch (_that) {
case _XpSource():
return $default(_that.id,_that.name,_that.xp,_that.description);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(fromJson: localizedText)  Map<String, String> name,  int xp, @JsonKey(fromJson: localizedText)  Map<String, String> description)?  $default,) {final _that = this;
switch (_that) {
case _XpSource() when $default != null:
return $default(_that.id,_that.name,_that.xp,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _XpSource extends XpSource {
  const _XpSource({required this.id, @JsonKey(fromJson: localizedText) final  Map<String, String> name = const <String, String>{}, this.xp = 0, @JsonKey(fromJson: localizedText) final  Map<String, String> description = const <String, String>{}}): _name = name,_description = description,super._();
  factory _XpSource.fromJson(Map<String, dynamic> json) => _$XpSourceFromJson(json);

@override final  String id;
/// Nome por idioma (`{pt: ..., en: ...}`). Use [nameIn].
 final  Map<String, String> _name;
/// Nome por idioma (`{pt: ..., en: ...}`). Use [nameIn].
@override@JsonKey(fromJson: localizedText) Map<String, String> get name {
  if (_name is EqualUnmodifiableMapView) return _name;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_name);
}

@override@JsonKey() final  int xp;
/// Descrição por idioma. Use [descriptionIn].
 final  Map<String, String> _description;
/// Descrição por idioma. Use [descriptionIn].
@override@JsonKey(fromJson: localizedText) Map<String, String> get description {
  if (_description is EqualUnmodifiableMapView) return _description;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_description);
}


/// Create a copy of XpSource
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$XpSourceCopyWith<_XpSource> get copyWith => __$XpSourceCopyWithImpl<_XpSource>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$XpSourceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _XpSource&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._name, _name)&&(identical(other.xp, xp) || other.xp == xp)&&const DeepCollectionEquality().equals(other._description, _description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_name),xp,const DeepCollectionEquality().hash(_description));

@override
String toString() {
  return 'XpSource(id: $id, name: $name, xp: $xp, description: $description)';
}


}

/// @nodoc
abstract mixin class _$XpSourceCopyWith<$Res> implements $XpSourceCopyWith<$Res> {
  factory _$XpSourceCopyWith(_XpSource value, $Res Function(_XpSource) _then) = __$XpSourceCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(fromJson: localizedText) Map<String, String> name, int xp,@JsonKey(fromJson: localizedText) Map<String, String> description
});




}
/// @nodoc
class __$XpSourceCopyWithImpl<$Res>
    implements _$XpSourceCopyWith<$Res> {
  __$XpSourceCopyWithImpl(this._self, this._then);

  final _XpSource _self;
  final $Res Function(_XpSource) _then;

/// Create a copy of XpSource
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? xp = null,Object? description = null,}) {
  return _then(_XpSource(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self._name : name // ignore: cast_nullable_to_non_nullable
as Map<String, String>,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self._description : description // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}


/// @nodoc
mixin _$BadgeCatalog {

 String get version; List<BadgeCatalogItem> get badges;/// XP mínimo de cada nível: `levelThresholds[n - 1]` abre o nível `n`.
 List<int> get levelThresholds;/// Como ganhar XP. Vazio enquanto o servidor não publicar a lista — a
/// seção simplesmente não aparece, em vez de mostrar um título vazio.
 List<XpSource> get xpSources;
/// Create a copy of BadgeCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BadgeCatalogCopyWith<BadgeCatalog> get copyWith => _$BadgeCatalogCopyWithImpl<BadgeCatalog>(this as BadgeCatalog, _$identity);

  /// Serializes this BadgeCatalog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BadgeCatalog&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other.badges, badges)&&const DeepCollectionEquality().equals(other.levelThresholds, levelThresholds)&&const DeepCollectionEquality().equals(other.xpSources, xpSources));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,const DeepCollectionEquality().hash(badges),const DeepCollectionEquality().hash(levelThresholds),const DeepCollectionEquality().hash(xpSources));

@override
String toString() {
  return 'BadgeCatalog(version: $version, badges: $badges, levelThresholds: $levelThresholds, xpSources: $xpSources)';
}


}

/// @nodoc
abstract mixin class $BadgeCatalogCopyWith<$Res>  {
  factory $BadgeCatalogCopyWith(BadgeCatalog value, $Res Function(BadgeCatalog) _then) = _$BadgeCatalogCopyWithImpl;
@useResult
$Res call({
 String version, List<BadgeCatalogItem> badges, List<int> levelThresholds, List<XpSource> xpSources
});




}
/// @nodoc
class _$BadgeCatalogCopyWithImpl<$Res>
    implements $BadgeCatalogCopyWith<$Res> {
  _$BadgeCatalogCopyWithImpl(this._self, this._then);

  final BadgeCatalog _self;
  final $Res Function(BadgeCatalog) _then;

/// Create a copy of BadgeCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? badges = null,Object? levelThresholds = null,Object? xpSources = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,badges: null == badges ? _self.badges : badges // ignore: cast_nullable_to_non_nullable
as List<BadgeCatalogItem>,levelThresholds: null == levelThresholds ? _self.levelThresholds : levelThresholds // ignore: cast_nullable_to_non_nullable
as List<int>,xpSources: null == xpSources ? _self.xpSources : xpSources // ignore: cast_nullable_to_non_nullable
as List<XpSource>,
  ));
}

}


/// Adds pattern-matching-related methods to [BadgeCatalog].
extension BadgeCatalogPatterns on BadgeCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BadgeCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BadgeCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BadgeCatalog value)  $default,){
final _that = this;
switch (_that) {
case _BadgeCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BadgeCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _BadgeCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String version,  List<BadgeCatalogItem> badges,  List<int> levelThresholds,  List<XpSource> xpSources)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BadgeCatalog() when $default != null:
return $default(_that.version,_that.badges,_that.levelThresholds,_that.xpSources);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String version,  List<BadgeCatalogItem> badges,  List<int> levelThresholds,  List<XpSource> xpSources)  $default,) {final _that = this;
switch (_that) {
case _BadgeCatalog():
return $default(_that.version,_that.badges,_that.levelThresholds,_that.xpSources);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String version,  List<BadgeCatalogItem> badges,  List<int> levelThresholds,  List<XpSource> xpSources)?  $default,) {final _that = this;
switch (_that) {
case _BadgeCatalog() when $default != null:
return $default(_that.version,_that.badges,_that.levelThresholds,_that.xpSources);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BadgeCatalog extends BadgeCatalog {
  const _BadgeCatalog({this.version = '', final  List<BadgeCatalogItem> badges = const <BadgeCatalogItem>[], final  List<int> levelThresholds = const <int>[], final  List<XpSource> xpSources = const <XpSource>[]}): _badges = badges,_levelThresholds = levelThresholds,_xpSources = xpSources,super._();
  factory _BadgeCatalog.fromJson(Map<String, dynamic> json) => _$BadgeCatalogFromJson(json);

@override@JsonKey() final  String version;
 final  List<BadgeCatalogItem> _badges;
@override@JsonKey() List<BadgeCatalogItem> get badges {
  if (_badges is EqualUnmodifiableListView) return _badges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_badges);
}

/// XP mínimo de cada nível: `levelThresholds[n - 1]` abre o nível `n`.
 final  List<int> _levelThresholds;
/// XP mínimo de cada nível: `levelThresholds[n - 1]` abre o nível `n`.
@override@JsonKey() List<int> get levelThresholds {
  if (_levelThresholds is EqualUnmodifiableListView) return _levelThresholds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_levelThresholds);
}

/// Como ganhar XP. Vazio enquanto o servidor não publicar a lista — a
/// seção simplesmente não aparece, em vez de mostrar um título vazio.
 final  List<XpSource> _xpSources;
/// Como ganhar XP. Vazio enquanto o servidor não publicar a lista — a
/// seção simplesmente não aparece, em vez de mostrar um título vazio.
@override@JsonKey() List<XpSource> get xpSources {
  if (_xpSources is EqualUnmodifiableListView) return _xpSources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_xpSources);
}


/// Create a copy of BadgeCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BadgeCatalogCopyWith<_BadgeCatalog> get copyWith => __$BadgeCatalogCopyWithImpl<_BadgeCatalog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BadgeCatalogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BadgeCatalog&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other._badges, _badges)&&const DeepCollectionEquality().equals(other._levelThresholds, _levelThresholds)&&const DeepCollectionEquality().equals(other._xpSources, _xpSources));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,const DeepCollectionEquality().hash(_badges),const DeepCollectionEquality().hash(_levelThresholds),const DeepCollectionEquality().hash(_xpSources));

@override
String toString() {
  return 'BadgeCatalog(version: $version, badges: $badges, levelThresholds: $levelThresholds, xpSources: $xpSources)';
}


}

/// @nodoc
abstract mixin class _$BadgeCatalogCopyWith<$Res> implements $BadgeCatalogCopyWith<$Res> {
  factory _$BadgeCatalogCopyWith(_BadgeCatalog value, $Res Function(_BadgeCatalog) _then) = __$BadgeCatalogCopyWithImpl;
@override @useResult
$Res call({
 String version, List<BadgeCatalogItem> badges, List<int> levelThresholds, List<XpSource> xpSources
});




}
/// @nodoc
class __$BadgeCatalogCopyWithImpl<$Res>
    implements _$BadgeCatalogCopyWith<$Res> {
  __$BadgeCatalogCopyWithImpl(this._self, this._then);

  final _BadgeCatalog _self;
  final $Res Function(_BadgeCatalog) _then;

/// Create a copy of BadgeCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? badges = null,Object? levelThresholds = null,Object? xpSources = null,}) {
  return _then(_BadgeCatalog(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,badges: null == badges ? _self._badges : badges // ignore: cast_nullable_to_non_nullable
as List<BadgeCatalogItem>,levelThresholds: null == levelThresholds ? _self._levelThresholds : levelThresholds // ignore: cast_nullable_to_non_nullable
as List<int>,xpSources: null == xpSources ? _self._xpSources : xpSources // ignore: cast_nullable_to_non_nullable
as List<XpSource>,
  ));
}


}

// dart format on
