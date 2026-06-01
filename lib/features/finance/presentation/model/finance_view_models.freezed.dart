// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'finance_view_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CategoryPlanningArgs {

 CategoryType get type;
/// Create a copy of CategoryPlanningArgs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryPlanningArgsCopyWith<CategoryPlanningArgs> get copyWith => _$CategoryPlanningArgsCopyWithImpl<CategoryPlanningArgs>(this as CategoryPlanningArgs, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryPlanningArgs&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,type);

@override
String toString() {
  return 'CategoryPlanningArgs(type: $type)';
}


}

/// @nodoc
abstract mixin class $CategoryPlanningArgsCopyWith<$Res>  {
  factory $CategoryPlanningArgsCopyWith(CategoryPlanningArgs value, $Res Function(CategoryPlanningArgs) _then) = _$CategoryPlanningArgsCopyWithImpl;
@useResult
$Res call({
 CategoryType type
});




}
/// @nodoc
class _$CategoryPlanningArgsCopyWithImpl<$Res>
    implements $CategoryPlanningArgsCopyWith<$Res> {
  _$CategoryPlanningArgsCopyWithImpl(this._self, this._then);

  final CategoryPlanningArgs _self;
  final $Res Function(CategoryPlanningArgs) _then;

/// Create a copy of CategoryPlanningArgs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CategoryType,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryPlanningArgs].
extension CategoryPlanningArgsPatterns on CategoryPlanningArgs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryPlanningArgs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryPlanningArgs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryPlanningArgs value)  $default,){
final _that = this;
switch (_that) {
case _CategoryPlanningArgs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryPlanningArgs value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryPlanningArgs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CategoryType type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryPlanningArgs() when $default != null:
return $default(_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CategoryType type)  $default,) {final _that = this;
switch (_that) {
case _CategoryPlanningArgs():
return $default(_that.type);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CategoryType type)?  $default,) {final _that = this;
switch (_that) {
case _CategoryPlanningArgs() when $default != null:
return $default(_that.type);case _:
  return null;

}
}

}

/// @nodoc


class _CategoryPlanningArgs implements CategoryPlanningArgs {
   _CategoryPlanningArgs({required this.type});
  

@override final  CategoryType type;

/// Create a copy of CategoryPlanningArgs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryPlanningArgsCopyWith<_CategoryPlanningArgs> get copyWith => __$CategoryPlanningArgsCopyWithImpl<_CategoryPlanningArgs>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryPlanningArgs&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,type);

@override
String toString() {
  return 'CategoryPlanningArgs(type: $type)';
}


}

/// @nodoc
abstract mixin class _$CategoryPlanningArgsCopyWith<$Res> implements $CategoryPlanningArgsCopyWith<$Res> {
  factory _$CategoryPlanningArgsCopyWith(_CategoryPlanningArgs value, $Res Function(_CategoryPlanningArgs) _then) = __$CategoryPlanningArgsCopyWithImpl;
@override @useResult
$Res call({
 CategoryType type
});




}
/// @nodoc
class __$CategoryPlanningArgsCopyWithImpl<$Res>
    implements _$CategoryPlanningArgsCopyWith<$Res> {
  __$CategoryPlanningArgsCopyWithImpl(this._self, this._then);

  final _CategoryPlanningArgs _self;
  final $Res Function(_CategoryPlanningArgs) _then;

/// Create a copy of CategoryPlanningArgs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,}) {
  return _then(_CategoryPlanningArgs(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CategoryType,
  ));
}


}

/// @nodoc
mixin _$CategoryPlanningFormItem {

 CategoryModel get category; double get amount; String? get planningId; bool get isDirty;
/// Create a copy of CategoryPlanningFormItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryPlanningFormItemCopyWith<CategoryPlanningFormItem> get copyWith => _$CategoryPlanningFormItemCopyWithImpl<CategoryPlanningFormItem>(this as CategoryPlanningFormItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryPlanningFormItem&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.planningId, planningId) || other.planningId == planningId)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty));
}


@override
int get hashCode => Object.hash(runtimeType,category,amount,planningId,isDirty);

@override
String toString() {
  return 'CategoryPlanningFormItem(category: $category, amount: $amount, planningId: $planningId, isDirty: $isDirty)';
}


}

/// @nodoc
abstract mixin class $CategoryPlanningFormItemCopyWith<$Res>  {
  factory $CategoryPlanningFormItemCopyWith(CategoryPlanningFormItem value, $Res Function(CategoryPlanningFormItem) _then) = _$CategoryPlanningFormItemCopyWithImpl;
@useResult
$Res call({
 CategoryModel category, double amount, String? planningId, bool isDirty
});


$CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class _$CategoryPlanningFormItemCopyWithImpl<$Res>
    implements $CategoryPlanningFormItemCopyWith<$Res> {
  _$CategoryPlanningFormItemCopyWithImpl(this._self, this._then);

  final CategoryPlanningFormItem _self;
  final $Res Function(CategoryPlanningFormItem) _then;

/// Create a copy of CategoryPlanningFormItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? amount = null,Object? planningId = freezed,Object? isDirty = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,planningId: freezed == planningId ? _self.planningId : planningId // ignore: cast_nullable_to_non_nullable
as String?,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of CategoryPlanningFormItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [CategoryPlanningFormItem].
extension CategoryPlanningFormItemPatterns on CategoryPlanningFormItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryPlanningFormItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryPlanningFormItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryPlanningFormItem value)  $default,){
final _that = this;
switch (_that) {
case _CategoryPlanningFormItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryPlanningFormItem value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryPlanningFormItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CategoryModel category,  double amount,  String? planningId,  bool isDirty)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryPlanningFormItem() when $default != null:
return $default(_that.category,_that.amount,_that.planningId,_that.isDirty);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CategoryModel category,  double amount,  String? planningId,  bool isDirty)  $default,) {final _that = this;
switch (_that) {
case _CategoryPlanningFormItem():
return $default(_that.category,_that.amount,_that.planningId,_that.isDirty);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CategoryModel category,  double amount,  String? planningId,  bool isDirty)?  $default,) {final _that = this;
switch (_that) {
case _CategoryPlanningFormItem() when $default != null:
return $default(_that.category,_that.amount,_that.planningId,_that.isDirty);case _:
  return null;

}
}

}

/// @nodoc


class _CategoryPlanningFormItem implements CategoryPlanningFormItem {
   _CategoryPlanningFormItem({required this.category, this.amount = 0.0, this.planningId, this.isDirty = false});
  

@override final  CategoryModel category;
@override@JsonKey() final  double amount;
@override final  String? planningId;
@override@JsonKey() final  bool isDirty;

/// Create a copy of CategoryPlanningFormItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryPlanningFormItemCopyWith<_CategoryPlanningFormItem> get copyWith => __$CategoryPlanningFormItemCopyWithImpl<_CategoryPlanningFormItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryPlanningFormItem&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.planningId, planningId) || other.planningId == planningId)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty));
}


@override
int get hashCode => Object.hash(runtimeType,category,amount,planningId,isDirty);

@override
String toString() {
  return 'CategoryPlanningFormItem(category: $category, amount: $amount, planningId: $planningId, isDirty: $isDirty)';
}


}

/// @nodoc
abstract mixin class _$CategoryPlanningFormItemCopyWith<$Res> implements $CategoryPlanningFormItemCopyWith<$Res> {
  factory _$CategoryPlanningFormItemCopyWith(_CategoryPlanningFormItem value, $Res Function(_CategoryPlanningFormItem) _then) = __$CategoryPlanningFormItemCopyWithImpl;
@override @useResult
$Res call({
 CategoryModel category, double amount, String? planningId, bool isDirty
});


@override $CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class __$CategoryPlanningFormItemCopyWithImpl<$Res>
    implements _$CategoryPlanningFormItemCopyWith<$Res> {
  __$CategoryPlanningFormItemCopyWithImpl(this._self, this._then);

  final _CategoryPlanningFormItem _self;
  final $Res Function(_CategoryPlanningFormItem) _then;

/// Create a copy of CategoryPlanningFormItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? amount = null,Object? planningId = freezed,Object? isDirty = null,}) {
  return _then(_CategoryPlanningFormItem(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,planningId: freezed == planningId ? _self.planningId : planningId // ignore: cast_nullable_to_non_nullable
as String?,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of CategoryPlanningFormItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

/// @nodoc
mixin _$CategoryPlanningState {

 List<CategoryPlanningFormItem> get items; bool get isLoading;
/// Create a copy of CategoryPlanningState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryPlanningStateCopyWith<CategoryPlanningState> get copyWith => _$CategoryPlanningStateCopyWithImpl<CategoryPlanningState>(this as CategoryPlanningState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryPlanningState&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),isLoading);

@override
String toString() {
  return 'CategoryPlanningState(items: $items, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class $CategoryPlanningStateCopyWith<$Res>  {
  factory $CategoryPlanningStateCopyWith(CategoryPlanningState value, $Res Function(CategoryPlanningState) _then) = _$CategoryPlanningStateCopyWithImpl;
@useResult
$Res call({
 List<CategoryPlanningFormItem> items, bool isLoading
});




}
/// @nodoc
class _$CategoryPlanningStateCopyWithImpl<$Res>
    implements $CategoryPlanningStateCopyWith<$Res> {
  _$CategoryPlanningStateCopyWithImpl(this._self, this._then);

  final CategoryPlanningState _self;
  final $Res Function(CategoryPlanningState) _then;

/// Create a copy of CategoryPlanningState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? isLoading = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CategoryPlanningFormItem>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryPlanningState].
extension CategoryPlanningStatePatterns on CategoryPlanningState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryPlanningState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryPlanningState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryPlanningState value)  $default,){
final _that = this;
switch (_that) {
case _CategoryPlanningState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryPlanningState value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryPlanningState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CategoryPlanningFormItem> items,  bool isLoading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryPlanningState() when $default != null:
return $default(_that.items,_that.isLoading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CategoryPlanningFormItem> items,  bool isLoading)  $default,) {final _that = this;
switch (_that) {
case _CategoryPlanningState():
return $default(_that.items,_that.isLoading);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CategoryPlanningFormItem> items,  bool isLoading)?  $default,) {final _that = this;
switch (_that) {
case _CategoryPlanningState() when $default != null:
return $default(_that.items,_that.isLoading);case _:
  return null;

}
}

}

/// @nodoc


class _CategoryPlanningState implements CategoryPlanningState {
   _CategoryPlanningState({final  List<CategoryPlanningFormItem> items = const [], this.isLoading = true}): _items = items;
  

 final  List<CategoryPlanningFormItem> _items;
@override@JsonKey() List<CategoryPlanningFormItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  bool isLoading;

/// Create a copy of CategoryPlanningState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryPlanningStateCopyWith<_CategoryPlanningState> get copyWith => __$CategoryPlanningStateCopyWithImpl<_CategoryPlanningState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryPlanningState&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),isLoading);

@override
String toString() {
  return 'CategoryPlanningState(items: $items, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class _$CategoryPlanningStateCopyWith<$Res> implements $CategoryPlanningStateCopyWith<$Res> {
  factory _$CategoryPlanningStateCopyWith(_CategoryPlanningState value, $Res Function(_CategoryPlanningState) _then) = __$CategoryPlanningStateCopyWithImpl;
@override @useResult
$Res call({
 List<CategoryPlanningFormItem> items, bool isLoading
});




}
/// @nodoc
class __$CategoryPlanningStateCopyWithImpl<$Res>
    implements _$CategoryPlanningStateCopyWith<$Res> {
  __$CategoryPlanningStateCopyWithImpl(this._self, this._then);

  final _CategoryPlanningState _self;
  final $Res Function(_CategoryPlanningState) _then;

/// Create a copy of CategoryPlanningState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? isLoading = null,}) {
  return _then(_CategoryPlanningState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CategoryPlanningFormItem>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$TransactionCreationArgs {

 OrderType get type; InstallmentStatus? get status; CategoryModel? get category; String? get accountIdSource; String? get accountIdTarget;
/// Create a copy of TransactionCreationArgs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionCreationArgsCopyWith<TransactionCreationArgs> get copyWith => _$TransactionCreationArgsCopyWithImpl<TransactionCreationArgs>(this as TransactionCreationArgs, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionCreationArgs&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.category, category) || other.category == category)&&(identical(other.accountIdSource, accountIdSource) || other.accountIdSource == accountIdSource)&&(identical(other.accountIdTarget, accountIdTarget) || other.accountIdTarget == accountIdTarget));
}


@override
int get hashCode => Object.hash(runtimeType,type,status,category,accountIdSource,accountIdTarget);

@override
String toString() {
  return 'TransactionCreationArgs(type: $type, status: $status, category: $category, accountIdSource: $accountIdSource, accountIdTarget: $accountIdTarget)';
}


}

/// @nodoc
abstract mixin class $TransactionCreationArgsCopyWith<$Res>  {
  factory $TransactionCreationArgsCopyWith(TransactionCreationArgs value, $Res Function(TransactionCreationArgs) _then) = _$TransactionCreationArgsCopyWithImpl;
@useResult
$Res call({
 OrderType type, InstallmentStatus? status, CategoryModel? category, String? accountIdSource, String? accountIdTarget
});


$CategoryModelCopyWith<$Res>? get category;

}
/// @nodoc
class _$TransactionCreationArgsCopyWithImpl<$Res>
    implements $TransactionCreationArgsCopyWith<$Res> {
  _$TransactionCreationArgsCopyWithImpl(this._self, this._then);

  final TransactionCreationArgs _self;
  final $Res Function(TransactionCreationArgs) _then;

/// Create a copy of TransactionCreationArgs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? status = freezed,Object? category = freezed,Object? accountIdSource = freezed,Object? accountIdTarget = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstallmentStatus?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,accountIdSource: freezed == accountIdSource ? _self.accountIdSource : accountIdSource // ignore: cast_nullable_to_non_nullable
as String?,accountIdTarget: freezed == accountIdTarget ? _self.accountIdTarget : accountIdTarget // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of TransactionCreationArgs
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [TransactionCreationArgs].
extension TransactionCreationArgsPatterns on TransactionCreationArgs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionCreationArgs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionCreationArgs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionCreationArgs value)  $default,){
final _that = this;
switch (_that) {
case _TransactionCreationArgs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionCreationArgs value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionCreationArgs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OrderType type,  InstallmentStatus? status,  CategoryModel? category,  String? accountIdSource,  String? accountIdTarget)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionCreationArgs() when $default != null:
return $default(_that.type,_that.status,_that.category,_that.accountIdSource,_that.accountIdTarget);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OrderType type,  InstallmentStatus? status,  CategoryModel? category,  String? accountIdSource,  String? accountIdTarget)  $default,) {final _that = this;
switch (_that) {
case _TransactionCreationArgs():
return $default(_that.type,_that.status,_that.category,_that.accountIdSource,_that.accountIdTarget);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OrderType type,  InstallmentStatus? status,  CategoryModel? category,  String? accountIdSource,  String? accountIdTarget)?  $default,) {final _that = this;
switch (_that) {
case _TransactionCreationArgs() when $default != null:
return $default(_that.type,_that.status,_that.category,_that.accountIdSource,_that.accountIdTarget);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionCreationArgs implements TransactionCreationArgs {
   _TransactionCreationArgs({required this.type, this.status, this.category, this.accountIdSource, this.accountIdTarget});
  

@override final  OrderType type;
@override final  InstallmentStatus? status;
@override final  CategoryModel? category;
@override final  String? accountIdSource;
@override final  String? accountIdTarget;

/// Create a copy of TransactionCreationArgs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionCreationArgsCopyWith<_TransactionCreationArgs> get copyWith => __$TransactionCreationArgsCopyWithImpl<_TransactionCreationArgs>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionCreationArgs&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.category, category) || other.category == category)&&(identical(other.accountIdSource, accountIdSource) || other.accountIdSource == accountIdSource)&&(identical(other.accountIdTarget, accountIdTarget) || other.accountIdTarget == accountIdTarget));
}


@override
int get hashCode => Object.hash(runtimeType,type,status,category,accountIdSource,accountIdTarget);

@override
String toString() {
  return 'TransactionCreationArgs(type: $type, status: $status, category: $category, accountIdSource: $accountIdSource, accountIdTarget: $accountIdTarget)';
}


}

/// @nodoc
abstract mixin class _$TransactionCreationArgsCopyWith<$Res> implements $TransactionCreationArgsCopyWith<$Res> {
  factory _$TransactionCreationArgsCopyWith(_TransactionCreationArgs value, $Res Function(_TransactionCreationArgs) _then) = __$TransactionCreationArgsCopyWithImpl;
@override @useResult
$Res call({
 OrderType type, InstallmentStatus? status, CategoryModel? category, String? accountIdSource, String? accountIdTarget
});


@override $CategoryModelCopyWith<$Res>? get category;

}
/// @nodoc
class __$TransactionCreationArgsCopyWithImpl<$Res>
    implements _$TransactionCreationArgsCopyWith<$Res> {
  __$TransactionCreationArgsCopyWithImpl(this._self, this._then);

  final _TransactionCreationArgs _self;
  final $Res Function(_TransactionCreationArgs) _then;

/// Create a copy of TransactionCreationArgs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? status = freezed,Object? category = freezed,Object? accountIdSource = freezed,Object? accountIdTarget = freezed,}) {
  return _then(_TransactionCreationArgs(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstallmentStatus?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,accountIdSource: freezed == accountIdSource ? _self.accountIdSource : accountIdSource // ignore: cast_nullable_to_non_nullable
as String?,accountIdTarget: freezed == accountIdTarget ? _self.accountIdTarget : accountIdTarget // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of TransactionCreationArgs
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

/// @nodoc
mixin _$TransactionFormState {

 String? get installmentId; String? get orderId; TransactionFormType get formType; OrderType get type; InstallmentType get installmentType; TransactionAmountType get amountType; String get description; double get amount; int? get intallmentNumber; int? get installmentCount; DateTime get dueDate; InstallmentStatus get status; DateTime? get paidDate; double? get paidAmount; CategoryModel? get category; String? get accountIdSource; String? get accountIdTarget; ReplicationCascade? get replicateCascade;
/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFormStateCopyWith<TransactionFormState> get copyWith => _$TransactionFormStateCopyWithImpl<TransactionFormState>(this as TransactionFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormState&&(identical(other.installmentId, installmentId) || other.installmentId == installmentId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.formType, formType) || other.formType == formType)&&(identical(other.type, type) || other.type == type)&&(identical(other.installmentType, installmentType) || other.installmentType == installmentType)&&(identical(other.amountType, amountType) || other.amountType == amountType)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.intallmentNumber, intallmentNumber) || other.intallmentNumber == intallmentNumber)&&(identical(other.installmentCount, installmentCount) || other.installmentCount == installmentCount)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.paidDate, paidDate) || other.paidDate == paidDate)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.category, category) || other.category == category)&&(identical(other.accountIdSource, accountIdSource) || other.accountIdSource == accountIdSource)&&(identical(other.accountIdTarget, accountIdTarget) || other.accountIdTarget == accountIdTarget)&&(identical(other.replicateCascade, replicateCascade) || other.replicateCascade == replicateCascade));
}


@override
int get hashCode => Object.hash(runtimeType,installmentId,orderId,formType,type,installmentType,amountType,description,amount,intallmentNumber,installmentCount,dueDate,status,paidDate,paidAmount,category,accountIdSource,accountIdTarget,replicateCascade);

@override
String toString() {
  return 'TransactionFormState(installmentId: $installmentId, orderId: $orderId, formType: $formType, type: $type, installmentType: $installmentType, amountType: $amountType, description: $description, amount: $amount, intallmentNumber: $intallmentNumber, installmentCount: $installmentCount, dueDate: $dueDate, status: $status, paidDate: $paidDate, paidAmount: $paidAmount, category: $category, accountIdSource: $accountIdSource, accountIdTarget: $accountIdTarget, replicateCascade: $replicateCascade)';
}


}

/// @nodoc
abstract mixin class $TransactionFormStateCopyWith<$Res>  {
  factory $TransactionFormStateCopyWith(TransactionFormState value, $Res Function(TransactionFormState) _then) = _$TransactionFormStateCopyWithImpl;
@useResult
$Res call({
 String? installmentId, String? orderId, TransactionFormType formType, OrderType type, InstallmentType installmentType, TransactionAmountType amountType, String description, double amount, int? intallmentNumber, int? installmentCount, DateTime dueDate, InstallmentStatus status, DateTime? paidDate, double? paidAmount, CategoryModel? category, String? accountIdSource, String? accountIdTarget, ReplicationCascade? replicateCascade
});


$CategoryModelCopyWith<$Res>? get category;

}
/// @nodoc
class _$TransactionFormStateCopyWithImpl<$Res>
    implements $TransactionFormStateCopyWith<$Res> {
  _$TransactionFormStateCopyWithImpl(this._self, this._then);

  final TransactionFormState _self;
  final $Res Function(TransactionFormState) _then;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? installmentId = freezed,Object? orderId = freezed,Object? formType = null,Object? type = null,Object? installmentType = null,Object? amountType = null,Object? description = null,Object? amount = null,Object? intallmentNumber = freezed,Object? installmentCount = freezed,Object? dueDate = null,Object? status = null,Object? paidDate = freezed,Object? paidAmount = freezed,Object? category = freezed,Object? accountIdSource = freezed,Object? accountIdTarget = freezed,Object? replicateCascade = freezed,}) {
  return _then(_self.copyWith(
installmentId: freezed == installmentId ? _self.installmentId : installmentId // ignore: cast_nullable_to_non_nullable
as String?,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,formType: null == formType ? _self.formType : formType // ignore: cast_nullable_to_non_nullable
as TransactionFormType,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType,installmentType: null == installmentType ? _self.installmentType : installmentType // ignore: cast_nullable_to_non_nullable
as InstallmentType,amountType: null == amountType ? _self.amountType : amountType // ignore: cast_nullable_to_non_nullable
as TransactionAmountType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,intallmentNumber: freezed == intallmentNumber ? _self.intallmentNumber : intallmentNumber // ignore: cast_nullable_to_non_nullable
as int?,installmentCount: freezed == installmentCount ? _self.installmentCount : installmentCount // ignore: cast_nullable_to_non_nullable
as int?,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstallmentStatus,paidDate: freezed == paidDate ? _self.paidDate : paidDate // ignore: cast_nullable_to_non_nullable
as DateTime?,paidAmount: freezed == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as double?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,accountIdSource: freezed == accountIdSource ? _self.accountIdSource : accountIdSource // ignore: cast_nullable_to_non_nullable
as String?,accountIdTarget: freezed == accountIdTarget ? _self.accountIdTarget : accountIdTarget // ignore: cast_nullable_to_non_nullable
as String?,replicateCascade: freezed == replicateCascade ? _self.replicateCascade : replicateCascade // ignore: cast_nullable_to_non_nullable
as ReplicationCascade?,
  ));
}
/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [TransactionFormState].
extension TransactionFormStatePatterns on TransactionFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionFormState value)  $default,){
final _that = this;
switch (_that) {
case _TransactionFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionFormState value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? installmentId,  String? orderId,  TransactionFormType formType,  OrderType type,  InstallmentType installmentType,  TransactionAmountType amountType,  String description,  double amount,  int? intallmentNumber,  int? installmentCount,  DateTime dueDate,  InstallmentStatus status,  DateTime? paidDate,  double? paidAmount,  CategoryModel? category,  String? accountIdSource,  String? accountIdTarget,  ReplicationCascade? replicateCascade)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionFormState() when $default != null:
return $default(_that.installmentId,_that.orderId,_that.formType,_that.type,_that.installmentType,_that.amountType,_that.description,_that.amount,_that.intallmentNumber,_that.installmentCount,_that.dueDate,_that.status,_that.paidDate,_that.paidAmount,_that.category,_that.accountIdSource,_that.accountIdTarget,_that.replicateCascade);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? installmentId,  String? orderId,  TransactionFormType formType,  OrderType type,  InstallmentType installmentType,  TransactionAmountType amountType,  String description,  double amount,  int? intallmentNumber,  int? installmentCount,  DateTime dueDate,  InstallmentStatus status,  DateTime? paidDate,  double? paidAmount,  CategoryModel? category,  String? accountIdSource,  String? accountIdTarget,  ReplicationCascade? replicateCascade)  $default,) {final _that = this;
switch (_that) {
case _TransactionFormState():
return $default(_that.installmentId,_that.orderId,_that.formType,_that.type,_that.installmentType,_that.amountType,_that.description,_that.amount,_that.intallmentNumber,_that.installmentCount,_that.dueDate,_that.status,_that.paidDate,_that.paidAmount,_that.category,_that.accountIdSource,_that.accountIdTarget,_that.replicateCascade);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? installmentId,  String? orderId,  TransactionFormType formType,  OrderType type,  InstallmentType installmentType,  TransactionAmountType amountType,  String description,  double amount,  int? intallmentNumber,  int? installmentCount,  DateTime dueDate,  InstallmentStatus status,  DateTime? paidDate,  double? paidAmount,  CategoryModel? category,  String? accountIdSource,  String? accountIdTarget,  ReplicationCascade? replicateCascade)?  $default,) {final _that = this;
switch (_that) {
case _TransactionFormState() when $default != null:
return $default(_that.installmentId,_that.orderId,_that.formType,_that.type,_that.installmentType,_that.amountType,_that.description,_that.amount,_that.intallmentNumber,_that.installmentCount,_that.dueDate,_that.status,_that.paidDate,_that.paidAmount,_that.category,_that.accountIdSource,_that.accountIdTarget,_that.replicateCascade);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionFormState extends TransactionFormState {
  const _TransactionFormState({this.installmentId, this.orderId, required this.formType, required this.type, required this.installmentType, this.amountType = TransactionAmountType.total, this.description = "", this.amount = 0.0, this.intallmentNumber, this.installmentCount, required this.dueDate, this.status = InstallmentStatus.pending, this.paidDate, this.paidAmount, this.category, this.accountIdSource, this.accountIdTarget, this.replicateCascade}): super._();
  

@override final  String? installmentId;
@override final  String? orderId;
@override final  TransactionFormType formType;
@override final  OrderType type;
@override final  InstallmentType installmentType;
@override@JsonKey() final  TransactionAmountType amountType;
@override@JsonKey() final  String description;
@override@JsonKey() final  double amount;
@override final  int? intallmentNumber;
@override final  int? installmentCount;
@override final  DateTime dueDate;
@override@JsonKey() final  InstallmentStatus status;
@override final  DateTime? paidDate;
@override final  double? paidAmount;
@override final  CategoryModel? category;
@override final  String? accountIdSource;
@override final  String? accountIdTarget;
@override final  ReplicationCascade? replicateCascade;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionFormStateCopyWith<_TransactionFormState> get copyWith => __$TransactionFormStateCopyWithImpl<_TransactionFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionFormState&&(identical(other.installmentId, installmentId) || other.installmentId == installmentId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.formType, formType) || other.formType == formType)&&(identical(other.type, type) || other.type == type)&&(identical(other.installmentType, installmentType) || other.installmentType == installmentType)&&(identical(other.amountType, amountType) || other.amountType == amountType)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.intallmentNumber, intallmentNumber) || other.intallmentNumber == intallmentNumber)&&(identical(other.installmentCount, installmentCount) || other.installmentCount == installmentCount)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.paidDate, paidDate) || other.paidDate == paidDate)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.category, category) || other.category == category)&&(identical(other.accountIdSource, accountIdSource) || other.accountIdSource == accountIdSource)&&(identical(other.accountIdTarget, accountIdTarget) || other.accountIdTarget == accountIdTarget)&&(identical(other.replicateCascade, replicateCascade) || other.replicateCascade == replicateCascade));
}


@override
int get hashCode => Object.hash(runtimeType,installmentId,orderId,formType,type,installmentType,amountType,description,amount,intallmentNumber,installmentCount,dueDate,status,paidDate,paidAmount,category,accountIdSource,accountIdTarget,replicateCascade);

@override
String toString() {
  return 'TransactionFormState(installmentId: $installmentId, orderId: $orderId, formType: $formType, type: $type, installmentType: $installmentType, amountType: $amountType, description: $description, amount: $amount, intallmentNumber: $intallmentNumber, installmentCount: $installmentCount, dueDate: $dueDate, status: $status, paidDate: $paidDate, paidAmount: $paidAmount, category: $category, accountIdSource: $accountIdSource, accountIdTarget: $accountIdTarget, replicateCascade: $replicateCascade)';
}


}

/// @nodoc
abstract mixin class _$TransactionFormStateCopyWith<$Res> implements $TransactionFormStateCopyWith<$Res> {
  factory _$TransactionFormStateCopyWith(_TransactionFormState value, $Res Function(_TransactionFormState) _then) = __$TransactionFormStateCopyWithImpl;
@override @useResult
$Res call({
 String? installmentId, String? orderId, TransactionFormType formType, OrderType type, InstallmentType installmentType, TransactionAmountType amountType, String description, double amount, int? intallmentNumber, int? installmentCount, DateTime dueDate, InstallmentStatus status, DateTime? paidDate, double? paidAmount, CategoryModel? category, String? accountIdSource, String? accountIdTarget, ReplicationCascade? replicateCascade
});


@override $CategoryModelCopyWith<$Res>? get category;

}
/// @nodoc
class __$TransactionFormStateCopyWithImpl<$Res>
    implements _$TransactionFormStateCopyWith<$Res> {
  __$TransactionFormStateCopyWithImpl(this._self, this._then);

  final _TransactionFormState _self;
  final $Res Function(_TransactionFormState) _then;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? installmentId = freezed,Object? orderId = freezed,Object? formType = null,Object? type = null,Object? installmentType = null,Object? amountType = null,Object? description = null,Object? amount = null,Object? intallmentNumber = freezed,Object? installmentCount = freezed,Object? dueDate = null,Object? status = null,Object? paidDate = freezed,Object? paidAmount = freezed,Object? category = freezed,Object? accountIdSource = freezed,Object? accountIdTarget = freezed,Object? replicateCascade = freezed,}) {
  return _then(_TransactionFormState(
installmentId: freezed == installmentId ? _self.installmentId : installmentId // ignore: cast_nullable_to_non_nullable
as String?,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,formType: null == formType ? _self.formType : formType // ignore: cast_nullable_to_non_nullable
as TransactionFormType,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType,installmentType: null == installmentType ? _self.installmentType : installmentType // ignore: cast_nullable_to_non_nullable
as InstallmentType,amountType: null == amountType ? _self.amountType : amountType // ignore: cast_nullable_to_non_nullable
as TransactionAmountType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,intallmentNumber: freezed == intallmentNumber ? _self.intallmentNumber : intallmentNumber // ignore: cast_nullable_to_non_nullable
as int?,installmentCount: freezed == installmentCount ? _self.installmentCount : installmentCount // ignore: cast_nullable_to_non_nullable
as int?,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstallmentStatus,paidDate: freezed == paidDate ? _self.paidDate : paidDate // ignore: cast_nullable_to_non_nullable
as DateTime?,paidAmount: freezed == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as double?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,accountIdSource: freezed == accountIdSource ? _self.accountIdSource : accountIdSource // ignore: cast_nullable_to_non_nullable
as String?,accountIdTarget: freezed == accountIdTarget ? _self.accountIdTarget : accountIdTarget // ignore: cast_nullable_to_non_nullable
as String?,replicateCascade: freezed == replicateCascade ? _self.replicateCascade : replicateCascade // ignore: cast_nullable_to_non_nullable
as ReplicationCascade?,
  ));
}

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

/// @nodoc
mixin _$TransactionQuery {

 String? get accountId; DateTime? get startDate; DateTime? get endDate; String? get categoryId; OrderType? get type; String? get description; double? get minAmount; double? get maxAmount; InstallmentStatus? get status;
/// Create a copy of TransactionQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionQueryCopyWith<TransactionQuery> get copyWith => _$TransactionQueryCopyWithImpl<TransactionQuery>(this as TransactionQuery, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionQuery&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.minAmount, minAmount) || other.minAmount == minAmount)&&(identical(other.maxAmount, maxAmount) || other.maxAmount == maxAmount)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,accountId,startDate,endDate,categoryId,type,description,minAmount,maxAmount,status);

@override
String toString() {
  return 'TransactionQuery(accountId: $accountId, startDate: $startDate, endDate: $endDate, categoryId: $categoryId, type: $type, description: $description, minAmount: $minAmount, maxAmount: $maxAmount, status: $status)';
}


}

/// @nodoc
abstract mixin class $TransactionQueryCopyWith<$Res>  {
  factory $TransactionQueryCopyWith(TransactionQuery value, $Res Function(TransactionQuery) _then) = _$TransactionQueryCopyWithImpl;
@useResult
$Res call({
 String? accountId, DateTime? startDate, DateTime? endDate, String? categoryId, OrderType? type, String? description, double? minAmount, double? maxAmount, InstallmentStatus? status
});




}
/// @nodoc
class _$TransactionQueryCopyWithImpl<$Res>
    implements $TransactionQueryCopyWith<$Res> {
  _$TransactionQueryCopyWithImpl(this._self, this._then);

  final TransactionQuery _self;
  final $Res Function(TransactionQuery) _then;

/// Create a copy of TransactionQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountId = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? categoryId = freezed,Object? type = freezed,Object? description = freezed,Object? minAmount = freezed,Object? maxAmount = freezed,Object? status = freezed,}) {
  return _then(_self.copyWith(
accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,minAmount: freezed == minAmount ? _self.minAmount : minAmount // ignore: cast_nullable_to_non_nullable
as double?,maxAmount: freezed == maxAmount ? _self.maxAmount : maxAmount // ignore: cast_nullable_to_non_nullable
as double?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstallmentStatus?,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionQuery].
extension TransactionQueryPatterns on TransactionQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionQuery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionQuery value)  $default,){
final _that = this;
switch (_that) {
case _TransactionQuery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionQuery value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionQuery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? accountId,  DateTime? startDate,  DateTime? endDate,  String? categoryId,  OrderType? type,  String? description,  double? minAmount,  double? maxAmount,  InstallmentStatus? status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionQuery() when $default != null:
return $default(_that.accountId,_that.startDate,_that.endDate,_that.categoryId,_that.type,_that.description,_that.minAmount,_that.maxAmount,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? accountId,  DateTime? startDate,  DateTime? endDate,  String? categoryId,  OrderType? type,  String? description,  double? minAmount,  double? maxAmount,  InstallmentStatus? status)  $default,) {final _that = this;
switch (_that) {
case _TransactionQuery():
return $default(_that.accountId,_that.startDate,_that.endDate,_that.categoryId,_that.type,_that.description,_that.minAmount,_that.maxAmount,_that.status);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? accountId,  DateTime? startDate,  DateTime? endDate,  String? categoryId,  OrderType? type,  String? description,  double? minAmount,  double? maxAmount,  InstallmentStatus? status)?  $default,) {final _that = this;
switch (_that) {
case _TransactionQuery() when $default != null:
return $default(_that.accountId,_that.startDate,_that.endDate,_that.categoryId,_that.type,_that.description,_that.minAmount,_that.maxAmount,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionQuery implements TransactionQuery {
   _TransactionQuery({this.accountId, this.startDate, this.endDate, this.categoryId, this.type, this.description, this.minAmount, this.maxAmount, this.status});
  

@override final  String? accountId;
@override final  DateTime? startDate;
@override final  DateTime? endDate;
@override final  String? categoryId;
@override final  OrderType? type;
@override final  String? description;
@override final  double? minAmount;
@override final  double? maxAmount;
@override final  InstallmentStatus? status;

/// Create a copy of TransactionQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionQueryCopyWith<_TransactionQuery> get copyWith => __$TransactionQueryCopyWithImpl<_TransactionQuery>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionQuery&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.minAmount, minAmount) || other.minAmount == minAmount)&&(identical(other.maxAmount, maxAmount) || other.maxAmount == maxAmount)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,accountId,startDate,endDate,categoryId,type,description,minAmount,maxAmount,status);

@override
String toString() {
  return 'TransactionQuery(accountId: $accountId, startDate: $startDate, endDate: $endDate, categoryId: $categoryId, type: $type, description: $description, minAmount: $minAmount, maxAmount: $maxAmount, status: $status)';
}


}

/// @nodoc
abstract mixin class _$TransactionQueryCopyWith<$Res> implements $TransactionQueryCopyWith<$Res> {
  factory _$TransactionQueryCopyWith(_TransactionQuery value, $Res Function(_TransactionQuery) _then) = __$TransactionQueryCopyWithImpl;
@override @useResult
$Res call({
 String? accountId, DateTime? startDate, DateTime? endDate, String? categoryId, OrderType? type, String? description, double? minAmount, double? maxAmount, InstallmentStatus? status
});




}
/// @nodoc
class __$TransactionQueryCopyWithImpl<$Res>
    implements _$TransactionQueryCopyWith<$Res> {
  __$TransactionQueryCopyWithImpl(this._self, this._then);

  final _TransactionQuery _self;
  final $Res Function(_TransactionQuery) _then;

/// Create a copy of TransactionQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountId = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? categoryId = freezed,Object? type = freezed,Object? description = freezed,Object? minAmount = freezed,Object? maxAmount = freezed,Object? status = freezed,}) {
  return _then(_TransactionQuery(
accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,minAmount: freezed == minAmount ? _self.minAmount : minAmount // ignore: cast_nullable_to_non_nullable
as double?,maxAmount: freezed == maxAmount ? _self.maxAmount : maxAmount // ignore: cast_nullable_to_non_nullable
as double?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstallmentStatus?,
  ));
}


}

// dart format on
