// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'core_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QueryChunk<T> {

 List<T> get items; dynamic get nextChunckRef;
/// Create a copy of QueryChunk
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueryChunkCopyWith<T, QueryChunk<T>> get copyWith => _$QueryChunkCopyWithImpl<T, QueryChunk<T>>(this as QueryChunk<T>, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueryChunk<T>&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.nextChunckRef, nextChunckRef));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(nextChunckRef));

@override
String toString() {
  return 'QueryChunk<$T>(items: $items, nextChunckRef: $nextChunckRef)';
}


}

/// @nodoc
abstract mixin class $QueryChunkCopyWith<T,$Res>  {
  factory $QueryChunkCopyWith(QueryChunk<T> value, $Res Function(QueryChunk<T>) _then) = _$QueryChunkCopyWithImpl;
@useResult
$Res call({
 List<T> items, dynamic nextChunckRef
});




}
/// @nodoc
class _$QueryChunkCopyWithImpl<T,$Res>
    implements $QueryChunkCopyWith<T, $Res> {
  _$QueryChunkCopyWithImpl(this._self, this._then);

  final QueryChunk<T> _self;
  final $Res Function(QueryChunk<T>) _then;

/// Create a copy of QueryChunk
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextChunckRef = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<T>,nextChunckRef: freezed == nextChunckRef ? _self.nextChunckRef : nextChunckRef // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}

}


/// Adds pattern-matching-related methods to [QueryChunk].
extension QueryChunkPatterns<T> on QueryChunk<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueryChunk<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueryChunk() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueryChunk<T> value)  $default,){
final _that = this;
switch (_that) {
case _QueryChunk():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueryChunk<T> value)?  $default,){
final _that = this;
switch (_that) {
case _QueryChunk() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<T> items,  dynamic nextChunckRef)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueryChunk() when $default != null:
return $default(_that.items,_that.nextChunckRef);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<T> items,  dynamic nextChunckRef)  $default,) {final _that = this;
switch (_that) {
case _QueryChunk():
return $default(_that.items,_that.nextChunckRef);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<T> items,  dynamic nextChunckRef)?  $default,) {final _that = this;
switch (_that) {
case _QueryChunk() when $default != null:
return $default(_that.items,_that.nextChunckRef);case _:
  return null;

}
}

}

/// @nodoc


class _QueryChunk<T> extends QueryChunk<T> {
   _QueryChunk({required final  List<T> items, this.nextChunckRef}): _items = items,super._();
  

 final  List<T> _items;
@override List<T> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  dynamic nextChunckRef;

/// Create a copy of QueryChunk
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueryChunkCopyWith<T, _QueryChunk<T>> get copyWith => __$QueryChunkCopyWithImpl<T, _QueryChunk<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueryChunk<T>&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other.nextChunckRef, nextChunckRef));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(nextChunckRef));

@override
String toString() {
  return 'QueryChunk<$T>(items: $items, nextChunckRef: $nextChunckRef)';
}


}

/// @nodoc
abstract mixin class _$QueryChunkCopyWith<T,$Res> implements $QueryChunkCopyWith<T, $Res> {
  factory _$QueryChunkCopyWith(_QueryChunk<T> value, $Res Function(_QueryChunk<T>) _then) = __$QueryChunkCopyWithImpl;
@override @useResult
$Res call({
 List<T> items, dynamic nextChunckRef
});




}
/// @nodoc
class __$QueryChunkCopyWithImpl<T,$Res>
    implements _$QueryChunkCopyWith<T, $Res> {
  __$QueryChunkCopyWithImpl(this._self, this._then);

  final _QueryChunk<T> _self;
  final $Res Function(_QueryChunk<T>) _then;

/// Create a copy of QueryChunk
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextChunckRef = freezed,}) {
  return _then(_QueryChunk<T>(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<T>,nextChunckRef: freezed == nextChunckRef ? _self.nextChunckRef : nextChunckRef // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}


}

/// @nodoc
mixin _$InfiniteListState<Q,E> {

 List<E> get items; Q get query; InfiniteListStatus get status; dynamic get nextChunkRef; dynamic get error;
/// Create a copy of InfiniteListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InfiniteListStateCopyWith<Q, E, InfiniteListState<Q, E>> get copyWith => _$InfiniteListStateCopyWithImpl<Q, E, InfiniteListState<Q, E>>(this as InfiniteListState<Q, E>, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InfiniteListState<Q, E>&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.query, query)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.nextChunkRef, nextChunkRef)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(query),status,const DeepCollectionEquality().hash(nextChunkRef),const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'InfiniteListState<$Q, $E>(items: $items, query: $query, status: $status, nextChunkRef: $nextChunkRef, error: $error)';
}


}

/// @nodoc
abstract mixin class $InfiniteListStateCopyWith<Q,E,$Res>  {
  factory $InfiniteListStateCopyWith(InfiniteListState<Q, E> value, $Res Function(InfiniteListState<Q, E>) _then) = _$InfiniteListStateCopyWithImpl;
@useResult
$Res call({
 List<E> items, Q query, InfiniteListStatus status, dynamic nextChunkRef, dynamic error
});




}
/// @nodoc
class _$InfiniteListStateCopyWithImpl<Q,E,$Res>
    implements $InfiniteListStateCopyWith<Q, E, $Res> {
  _$InfiniteListStateCopyWithImpl(this._self, this._then);

  final InfiniteListState<Q, E> _self;
  final $Res Function(InfiniteListState<Q, E>) _then;

/// Create a copy of InfiniteListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? query = freezed,Object? status = null,Object? nextChunkRef = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<E>,query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as Q,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InfiniteListStatus,nextChunkRef: freezed == nextChunkRef ? _self.nextChunkRef : nextChunkRef // ignore: cast_nullable_to_non_nullable
as dynamic,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}

}


/// Adds pattern-matching-related methods to [InfiniteListState].
extension InfiniteListStatePatterns<Q,E> on InfiniteListState<Q, E> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InfiniteListState<Q, E> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InfiniteListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InfiniteListState<Q, E> value)  $default,){
final _that = this;
switch (_that) {
case _InfiniteListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InfiniteListState<Q, E> value)?  $default,){
final _that = this;
switch (_that) {
case _InfiniteListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<E> items,  Q query,  InfiniteListStatus status,  dynamic nextChunkRef,  dynamic error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InfiniteListState() when $default != null:
return $default(_that.items,_that.query,_that.status,_that.nextChunkRef,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<E> items,  Q query,  InfiniteListStatus status,  dynamic nextChunkRef,  dynamic error)  $default,) {final _that = this;
switch (_that) {
case _InfiniteListState():
return $default(_that.items,_that.query,_that.status,_that.nextChunkRef,_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<E> items,  Q query,  InfiniteListStatus status,  dynamic nextChunkRef,  dynamic error)?  $default,) {final _that = this;
switch (_that) {
case _InfiniteListState() when $default != null:
return $default(_that.items,_that.query,_that.status,_that.nextChunkRef,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _InfiniteListState<Q,E> extends InfiniteListState<Q, E> {
   _InfiniteListState({required final  List<E> items, required this.query, required this.status, this.nextChunkRef, this.error}): _items = items,super._();
  

 final  List<E> _items;
@override List<E> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  Q query;
@override final  InfiniteListStatus status;
@override final  dynamic nextChunkRef;
@override final  dynamic error;

/// Create a copy of InfiniteListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InfiniteListStateCopyWith<Q, E, _InfiniteListState<Q, E>> get copyWith => __$InfiniteListStateCopyWithImpl<Q, E, _InfiniteListState<Q, E>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InfiniteListState<Q, E>&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other.query, query)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.nextChunkRef, nextChunkRef)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(query),status,const DeepCollectionEquality().hash(nextChunkRef),const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'InfiniteListState<$Q, $E>(items: $items, query: $query, status: $status, nextChunkRef: $nextChunkRef, error: $error)';
}


}

/// @nodoc
abstract mixin class _$InfiniteListStateCopyWith<Q,E,$Res> implements $InfiniteListStateCopyWith<Q, E, $Res> {
  factory _$InfiniteListStateCopyWith(_InfiniteListState<Q, E> value, $Res Function(_InfiniteListState<Q, E>) _then) = __$InfiniteListStateCopyWithImpl;
@override @useResult
$Res call({
 List<E> items, Q query, InfiniteListStatus status, dynamic nextChunkRef, dynamic error
});




}
/// @nodoc
class __$InfiniteListStateCopyWithImpl<Q,E,$Res>
    implements _$InfiniteListStateCopyWith<Q, E, $Res> {
  __$InfiniteListStateCopyWithImpl(this._self, this._then);

  final _InfiniteListState<Q, E> _self;
  final $Res Function(_InfiniteListState<Q, E>) _then;

/// Create a copy of InfiniteListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? query = freezed,Object? status = null,Object? nextChunkRef = freezed,Object? error = freezed,}) {
  return _then(_InfiniteListState<Q, E>(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<E>,query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as Q,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InfiniteListStatus,nextChunkRef: freezed == nextChunkRef ? _self.nextChunkRef : nextChunkRef // ignore: cast_nullable_to_non_nullable
as dynamic,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}


}

// dart format on
