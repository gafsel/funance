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
mixin _$CategoryPlanning503020Item {

 CategoryModel get category; double get generalAmount; double get specificAmount; double get actualAmount; String? get planningId; bool get isDirty;
/// Create a copy of CategoryPlanning503020Item
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryPlanning503020ItemCopyWith<CategoryPlanning503020Item> get copyWith => _$CategoryPlanning503020ItemCopyWithImpl<CategoryPlanning503020Item>(this as CategoryPlanning503020Item, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryPlanning503020Item&&(identical(other.category, category) || other.category == category)&&(identical(other.generalAmount, generalAmount) || other.generalAmount == generalAmount)&&(identical(other.specificAmount, specificAmount) || other.specificAmount == specificAmount)&&(identical(other.actualAmount, actualAmount) || other.actualAmount == actualAmount)&&(identical(other.planningId, planningId) || other.planningId == planningId)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty));
}


@override
int get hashCode => Object.hash(runtimeType,category,generalAmount,specificAmount,actualAmount,planningId,isDirty);

@override
String toString() {
  return 'CategoryPlanning503020Item(category: $category, generalAmount: $generalAmount, specificAmount: $specificAmount, actualAmount: $actualAmount, planningId: $planningId, isDirty: $isDirty)';
}


}

/// @nodoc
abstract mixin class $CategoryPlanning503020ItemCopyWith<$Res>  {
  factory $CategoryPlanning503020ItemCopyWith(CategoryPlanning503020Item value, $Res Function(CategoryPlanning503020Item) _then) = _$CategoryPlanning503020ItemCopyWithImpl;
@useResult
$Res call({
 CategoryModel category, double generalAmount, double specificAmount, double actualAmount, String? planningId, bool isDirty
});


$CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class _$CategoryPlanning503020ItemCopyWithImpl<$Res>
    implements $CategoryPlanning503020ItemCopyWith<$Res> {
  _$CategoryPlanning503020ItemCopyWithImpl(this._self, this._then);

  final CategoryPlanning503020Item _self;
  final $Res Function(CategoryPlanning503020Item) _then;

/// Create a copy of CategoryPlanning503020Item
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? generalAmount = null,Object? specificAmount = null,Object? actualAmount = null,Object? planningId = freezed,Object? isDirty = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,generalAmount: null == generalAmount ? _self.generalAmount : generalAmount // ignore: cast_nullable_to_non_nullable
as double,specificAmount: null == specificAmount ? _self.specificAmount : specificAmount // ignore: cast_nullable_to_non_nullable
as double,actualAmount: null == actualAmount ? _self.actualAmount : actualAmount // ignore: cast_nullable_to_non_nullable
as double,planningId: freezed == planningId ? _self.planningId : planningId // ignore: cast_nullable_to_non_nullable
as String?,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of CategoryPlanning503020Item
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [CategoryPlanning503020Item].
extension CategoryPlanning503020ItemPatterns on CategoryPlanning503020Item {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryPlanning503020Item value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryPlanning503020Item() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryPlanning503020Item value)  $default,){
final _that = this;
switch (_that) {
case _CategoryPlanning503020Item():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryPlanning503020Item value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryPlanning503020Item() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CategoryModel category,  double generalAmount,  double specificAmount,  double actualAmount,  String? planningId,  bool isDirty)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryPlanning503020Item() when $default != null:
return $default(_that.category,_that.generalAmount,_that.specificAmount,_that.actualAmount,_that.planningId,_that.isDirty);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CategoryModel category,  double generalAmount,  double specificAmount,  double actualAmount,  String? planningId,  bool isDirty)  $default,) {final _that = this;
switch (_that) {
case _CategoryPlanning503020Item():
return $default(_that.category,_that.generalAmount,_that.specificAmount,_that.actualAmount,_that.planningId,_that.isDirty);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CategoryModel category,  double generalAmount,  double specificAmount,  double actualAmount,  String? planningId,  bool isDirty)?  $default,) {final _that = this;
switch (_that) {
case _CategoryPlanning503020Item() when $default != null:
return $default(_that.category,_that.generalAmount,_that.specificAmount,_that.actualAmount,_that.planningId,_that.isDirty);case _:
  return null;

}
}

}

/// @nodoc


class _CategoryPlanning503020Item extends CategoryPlanning503020Item {
   _CategoryPlanning503020Item({required this.category, this.generalAmount = 0.0, this.specificAmount = 0.0, this.actualAmount = 0.0, this.planningId, this.isDirty = false}): super._();
  

@override final  CategoryModel category;
@override@JsonKey() final  double generalAmount;
@override@JsonKey() final  double specificAmount;
@override@JsonKey() final  double actualAmount;
@override final  String? planningId;
@override@JsonKey() final  bool isDirty;

/// Create a copy of CategoryPlanning503020Item
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryPlanning503020ItemCopyWith<_CategoryPlanning503020Item> get copyWith => __$CategoryPlanning503020ItemCopyWithImpl<_CategoryPlanning503020Item>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryPlanning503020Item&&(identical(other.category, category) || other.category == category)&&(identical(other.generalAmount, generalAmount) || other.generalAmount == generalAmount)&&(identical(other.specificAmount, specificAmount) || other.specificAmount == specificAmount)&&(identical(other.actualAmount, actualAmount) || other.actualAmount == actualAmount)&&(identical(other.planningId, planningId) || other.planningId == planningId)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty));
}


@override
int get hashCode => Object.hash(runtimeType,category,generalAmount,specificAmount,actualAmount,planningId,isDirty);

@override
String toString() {
  return 'CategoryPlanning503020Item(category: $category, generalAmount: $generalAmount, specificAmount: $specificAmount, actualAmount: $actualAmount, planningId: $planningId, isDirty: $isDirty)';
}


}

/// @nodoc
abstract mixin class _$CategoryPlanning503020ItemCopyWith<$Res> implements $CategoryPlanning503020ItemCopyWith<$Res> {
  factory _$CategoryPlanning503020ItemCopyWith(_CategoryPlanning503020Item value, $Res Function(_CategoryPlanning503020Item) _then) = __$CategoryPlanning503020ItemCopyWithImpl;
@override @useResult
$Res call({
 CategoryModel category, double generalAmount, double specificAmount, double actualAmount, String? planningId, bool isDirty
});


@override $CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class __$CategoryPlanning503020ItemCopyWithImpl<$Res>
    implements _$CategoryPlanning503020ItemCopyWith<$Res> {
  __$CategoryPlanning503020ItemCopyWithImpl(this._self, this._then);

  final _CategoryPlanning503020Item _self;
  final $Res Function(_CategoryPlanning503020Item) _then;

/// Create a copy of CategoryPlanning503020Item
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? generalAmount = null,Object? specificAmount = null,Object? actualAmount = null,Object? planningId = freezed,Object? isDirty = null,}) {
  return _then(_CategoryPlanning503020Item(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,generalAmount: null == generalAmount ? _self.generalAmount : generalAmount // ignore: cast_nullable_to_non_nullable
as double,specificAmount: null == specificAmount ? _self.specificAmount : specificAmount // ignore: cast_nullable_to_non_nullable
as double,actualAmount: null == actualAmount ? _self.actualAmount : actualAmount // ignore: cast_nullable_to_non_nullable
as double,planningId: freezed == planningId ? _self.planningId : planningId // ignore: cast_nullable_to_non_nullable
as String?,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of CategoryPlanning503020Item
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
mixin _$CategoryPlanning503020State {

 DateTime get date; List<CategoryPlanning503020Item> get items; double get totalIncomes; double get totalActualIncomes; bool get isLoading; bool get isSubmitting;
/// Create a copy of CategoryPlanning503020State
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryPlanning503020StateCopyWith<CategoryPlanning503020State> get copyWith => _$CategoryPlanning503020StateCopyWithImpl<CategoryPlanning503020State>(this as CategoryPlanning503020State, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryPlanning503020State&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalIncomes, totalIncomes) || other.totalIncomes == totalIncomes)&&(identical(other.totalActualIncomes, totalActualIncomes) || other.totalActualIncomes == totalActualIncomes)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting));
}


@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(items),totalIncomes,totalActualIncomes,isLoading,isSubmitting);

@override
String toString() {
  return 'CategoryPlanning503020State(date: $date, items: $items, totalIncomes: $totalIncomes, totalActualIncomes: $totalActualIncomes, isLoading: $isLoading, isSubmitting: $isSubmitting)';
}


}

/// @nodoc
abstract mixin class $CategoryPlanning503020StateCopyWith<$Res>  {
  factory $CategoryPlanning503020StateCopyWith(CategoryPlanning503020State value, $Res Function(CategoryPlanning503020State) _then) = _$CategoryPlanning503020StateCopyWithImpl;
@useResult
$Res call({
 DateTime date, List<CategoryPlanning503020Item> items, double totalIncomes, double totalActualIncomes, bool isLoading, bool isSubmitting
});




}
/// @nodoc
class _$CategoryPlanning503020StateCopyWithImpl<$Res>
    implements $CategoryPlanning503020StateCopyWith<$Res> {
  _$CategoryPlanning503020StateCopyWithImpl(this._self, this._then);

  final CategoryPlanning503020State _self;
  final $Res Function(CategoryPlanning503020State) _then;

/// Create a copy of CategoryPlanning503020State
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? items = null,Object? totalIncomes = null,Object? totalActualIncomes = null,Object? isLoading = null,Object? isSubmitting = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CategoryPlanning503020Item>,totalIncomes: null == totalIncomes ? _self.totalIncomes : totalIncomes // ignore: cast_nullable_to_non_nullable
as double,totalActualIncomes: null == totalActualIncomes ? _self.totalActualIncomes : totalActualIncomes // ignore: cast_nullable_to_non_nullable
as double,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryPlanning503020State].
extension CategoryPlanning503020StatePatterns on CategoryPlanning503020State {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryPlanning503020State value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryPlanning503020State() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryPlanning503020State value)  $default,){
final _that = this;
switch (_that) {
case _CategoryPlanning503020State():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryPlanning503020State value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryPlanning503020State() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  List<CategoryPlanning503020Item> items,  double totalIncomes,  double totalActualIncomes,  bool isLoading,  bool isSubmitting)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryPlanning503020State() when $default != null:
return $default(_that.date,_that.items,_that.totalIncomes,_that.totalActualIncomes,_that.isLoading,_that.isSubmitting);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  List<CategoryPlanning503020Item> items,  double totalIncomes,  double totalActualIncomes,  bool isLoading,  bool isSubmitting)  $default,) {final _that = this;
switch (_that) {
case _CategoryPlanning503020State():
return $default(_that.date,_that.items,_that.totalIncomes,_that.totalActualIncomes,_that.isLoading,_that.isSubmitting);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  List<CategoryPlanning503020Item> items,  double totalIncomes,  double totalActualIncomes,  bool isLoading,  bool isSubmitting)?  $default,) {final _that = this;
switch (_that) {
case _CategoryPlanning503020State() when $default != null:
return $default(_that.date,_that.items,_that.totalIncomes,_that.totalActualIncomes,_that.isLoading,_that.isSubmitting);case _:
  return null;

}
}

}

/// @nodoc


class _CategoryPlanning503020State implements CategoryPlanning503020State {
   _CategoryPlanning503020State({required this.date, final  List<CategoryPlanning503020Item> items = const [], this.totalIncomes = 0.0, this.totalActualIncomes = 0.0, this.isLoading = true, this.isSubmitting = false}): _items = items;
  

@override final  DateTime date;
 final  List<CategoryPlanning503020Item> _items;
@override@JsonKey() List<CategoryPlanning503020Item> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  double totalIncomes;
@override@JsonKey() final  double totalActualIncomes;
@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isSubmitting;

/// Create a copy of CategoryPlanning503020State
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryPlanning503020StateCopyWith<_CategoryPlanning503020State> get copyWith => __$CategoryPlanning503020StateCopyWithImpl<_CategoryPlanning503020State>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryPlanning503020State&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalIncomes, totalIncomes) || other.totalIncomes == totalIncomes)&&(identical(other.totalActualIncomes, totalActualIncomes) || other.totalActualIncomes == totalActualIncomes)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting));
}


@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(_items),totalIncomes,totalActualIncomes,isLoading,isSubmitting);

@override
String toString() {
  return 'CategoryPlanning503020State(date: $date, items: $items, totalIncomes: $totalIncomes, totalActualIncomes: $totalActualIncomes, isLoading: $isLoading, isSubmitting: $isSubmitting)';
}


}

/// @nodoc
abstract mixin class _$CategoryPlanning503020StateCopyWith<$Res> implements $CategoryPlanning503020StateCopyWith<$Res> {
  factory _$CategoryPlanning503020StateCopyWith(_CategoryPlanning503020State value, $Res Function(_CategoryPlanning503020State) _then) = __$CategoryPlanning503020StateCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, List<CategoryPlanning503020Item> items, double totalIncomes, double totalActualIncomes, bool isLoading, bool isSubmitting
});




}
/// @nodoc
class __$CategoryPlanning503020StateCopyWithImpl<$Res>
    implements _$CategoryPlanning503020StateCopyWith<$Res> {
  __$CategoryPlanning503020StateCopyWithImpl(this._self, this._then);

  final _CategoryPlanning503020State _self;
  final $Res Function(_CategoryPlanning503020State) _then;

/// Create a copy of CategoryPlanning503020State
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? items = null,Object? totalIncomes = null,Object? totalActualIncomes = null,Object? isLoading = null,Object? isSubmitting = null,}) {
  return _then(_CategoryPlanning503020State(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CategoryPlanning503020Item>,totalIncomes: null == totalIncomes ? _self.totalIncomes : totalIncomes // ignore: cast_nullable_to_non_nullable
as double,totalActualIncomes: null == totalActualIncomes ? _self.totalActualIncomes : totalActualIncomes // ignore: cast_nullable_to_non_nullable
as double,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$Planning503020DistributionGroup {

 double get plannedAmount; double get actualAmount; double get idealPercentage;
/// Create a copy of Planning503020DistributionGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Planning503020DistributionGroupCopyWith<Planning503020DistributionGroup> get copyWith => _$Planning503020DistributionGroupCopyWithImpl<Planning503020DistributionGroup>(this as Planning503020DistributionGroup, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Planning503020DistributionGroup&&(identical(other.plannedAmount, plannedAmount) || other.plannedAmount == plannedAmount)&&(identical(other.actualAmount, actualAmount) || other.actualAmount == actualAmount)&&(identical(other.idealPercentage, idealPercentage) || other.idealPercentage == idealPercentage));
}


@override
int get hashCode => Object.hash(runtimeType,plannedAmount,actualAmount,idealPercentage);

@override
String toString() {
  return 'Planning503020DistributionGroup(plannedAmount: $plannedAmount, actualAmount: $actualAmount, idealPercentage: $idealPercentage)';
}


}

/// @nodoc
abstract mixin class $Planning503020DistributionGroupCopyWith<$Res>  {
  factory $Planning503020DistributionGroupCopyWith(Planning503020DistributionGroup value, $Res Function(Planning503020DistributionGroup) _then) = _$Planning503020DistributionGroupCopyWithImpl;
@useResult
$Res call({
 double plannedAmount, double actualAmount, double idealPercentage
});




}
/// @nodoc
class _$Planning503020DistributionGroupCopyWithImpl<$Res>
    implements $Planning503020DistributionGroupCopyWith<$Res> {
  _$Planning503020DistributionGroupCopyWithImpl(this._self, this._then);

  final Planning503020DistributionGroup _self;
  final $Res Function(Planning503020DistributionGroup) _then;

/// Create a copy of Planning503020DistributionGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plannedAmount = null,Object? actualAmount = null,Object? idealPercentage = null,}) {
  return _then(_self.copyWith(
plannedAmount: null == plannedAmount ? _self.plannedAmount : plannedAmount // ignore: cast_nullable_to_non_nullable
as double,actualAmount: null == actualAmount ? _self.actualAmount : actualAmount // ignore: cast_nullable_to_non_nullable
as double,idealPercentage: null == idealPercentage ? _self.idealPercentage : idealPercentage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Planning503020DistributionGroup].
extension Planning503020DistributionGroupPatterns on Planning503020DistributionGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Planning503020DistributionGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Planning503020DistributionGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Planning503020DistributionGroup value)  $default,){
final _that = this;
switch (_that) {
case _Planning503020DistributionGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Planning503020DistributionGroup value)?  $default,){
final _that = this;
switch (_that) {
case _Planning503020DistributionGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double plannedAmount,  double actualAmount,  double idealPercentage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Planning503020DistributionGroup() when $default != null:
return $default(_that.plannedAmount,_that.actualAmount,_that.idealPercentage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double plannedAmount,  double actualAmount,  double idealPercentage)  $default,) {final _that = this;
switch (_that) {
case _Planning503020DistributionGroup():
return $default(_that.plannedAmount,_that.actualAmount,_that.idealPercentage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double plannedAmount,  double actualAmount,  double idealPercentage)?  $default,) {final _that = this;
switch (_that) {
case _Planning503020DistributionGroup() when $default != null:
return $default(_that.plannedAmount,_that.actualAmount,_that.idealPercentage);case _:
  return null;

}
}

}

/// @nodoc


class _Planning503020DistributionGroup implements Planning503020DistributionGroup {
  const _Planning503020DistributionGroup({this.plannedAmount = 0.0, this.actualAmount = 0.0, this.idealPercentage = 0.0});
  

@override@JsonKey() final  double plannedAmount;
@override@JsonKey() final  double actualAmount;
@override@JsonKey() final  double idealPercentage;

/// Create a copy of Planning503020DistributionGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Planning503020DistributionGroupCopyWith<_Planning503020DistributionGroup> get copyWith => __$Planning503020DistributionGroupCopyWithImpl<_Planning503020DistributionGroup>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Planning503020DistributionGroup&&(identical(other.plannedAmount, plannedAmount) || other.plannedAmount == plannedAmount)&&(identical(other.actualAmount, actualAmount) || other.actualAmount == actualAmount)&&(identical(other.idealPercentage, idealPercentage) || other.idealPercentage == idealPercentage));
}


@override
int get hashCode => Object.hash(runtimeType,plannedAmount,actualAmount,idealPercentage);

@override
String toString() {
  return 'Planning503020DistributionGroup(plannedAmount: $plannedAmount, actualAmount: $actualAmount, idealPercentage: $idealPercentage)';
}


}

/// @nodoc
abstract mixin class _$Planning503020DistributionGroupCopyWith<$Res> implements $Planning503020DistributionGroupCopyWith<$Res> {
  factory _$Planning503020DistributionGroupCopyWith(_Planning503020DistributionGroup value, $Res Function(_Planning503020DistributionGroup) _then) = __$Planning503020DistributionGroupCopyWithImpl;
@override @useResult
$Res call({
 double plannedAmount, double actualAmount, double idealPercentage
});




}
/// @nodoc
class __$Planning503020DistributionGroupCopyWithImpl<$Res>
    implements _$Planning503020DistributionGroupCopyWith<$Res> {
  __$Planning503020DistributionGroupCopyWithImpl(this._self, this._then);

  final _Planning503020DistributionGroup _self;
  final $Res Function(_Planning503020DistributionGroup) _then;

/// Create a copy of Planning503020DistributionGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plannedAmount = null,Object? actualAmount = null,Object? idealPercentage = null,}) {
  return _then(_Planning503020DistributionGroup(
plannedAmount: null == plannedAmount ? _self.plannedAmount : plannedAmount // ignore: cast_nullable_to_non_nullable
as double,actualAmount: null == actualAmount ? _self.actualAmount : actualAmount // ignore: cast_nullable_to_non_nullable
as double,idealPercentage: null == idealPercentage ? _self.idealPercentage : idealPercentage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$Planning503020Distribution {

 Planning503020DistributionGroup get essential; Planning503020DistributionGroup get comfort; Planning503020DistributionGroup get investment; double get totalIncome; double get totalActualIncome;
/// Create a copy of Planning503020Distribution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Planning503020DistributionCopyWith<Planning503020Distribution> get copyWith => _$Planning503020DistributionCopyWithImpl<Planning503020Distribution>(this as Planning503020Distribution, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Planning503020Distribution&&(identical(other.essential, essential) || other.essential == essential)&&(identical(other.comfort, comfort) || other.comfort == comfort)&&(identical(other.investment, investment) || other.investment == investment)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.totalActualIncome, totalActualIncome) || other.totalActualIncome == totalActualIncome));
}


@override
int get hashCode => Object.hash(runtimeType,essential,comfort,investment,totalIncome,totalActualIncome);

@override
String toString() {
  return 'Planning503020Distribution(essential: $essential, comfort: $comfort, investment: $investment, totalIncome: $totalIncome, totalActualIncome: $totalActualIncome)';
}


}

/// @nodoc
abstract mixin class $Planning503020DistributionCopyWith<$Res>  {
  factory $Planning503020DistributionCopyWith(Planning503020Distribution value, $Res Function(Planning503020Distribution) _then) = _$Planning503020DistributionCopyWithImpl;
@useResult
$Res call({
 Planning503020DistributionGroup essential, Planning503020DistributionGroup comfort, Planning503020DistributionGroup investment, double totalIncome, double totalActualIncome
});


$Planning503020DistributionGroupCopyWith<$Res> get essential;$Planning503020DistributionGroupCopyWith<$Res> get comfort;$Planning503020DistributionGroupCopyWith<$Res> get investment;

}
/// @nodoc
class _$Planning503020DistributionCopyWithImpl<$Res>
    implements $Planning503020DistributionCopyWith<$Res> {
  _$Planning503020DistributionCopyWithImpl(this._self, this._then);

  final Planning503020Distribution _self;
  final $Res Function(Planning503020Distribution) _then;

/// Create a copy of Planning503020Distribution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? essential = null,Object? comfort = null,Object? investment = null,Object? totalIncome = null,Object? totalActualIncome = null,}) {
  return _then(_self.copyWith(
essential: null == essential ? _self.essential : essential // ignore: cast_nullable_to_non_nullable
as Planning503020DistributionGroup,comfort: null == comfort ? _self.comfort : comfort // ignore: cast_nullable_to_non_nullable
as Planning503020DistributionGroup,investment: null == investment ? _self.investment : investment // ignore: cast_nullable_to_non_nullable
as Planning503020DistributionGroup,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as double,totalActualIncome: null == totalActualIncome ? _self.totalActualIncome : totalActualIncome // ignore: cast_nullable_to_non_nullable
as double,
  ));
}
/// Create a copy of Planning503020Distribution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Planning503020DistributionGroupCopyWith<$Res> get essential {
  
  return $Planning503020DistributionGroupCopyWith<$Res>(_self.essential, (value) {
    return _then(_self.copyWith(essential: value));
  });
}/// Create a copy of Planning503020Distribution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Planning503020DistributionGroupCopyWith<$Res> get comfort {
  
  return $Planning503020DistributionGroupCopyWith<$Res>(_self.comfort, (value) {
    return _then(_self.copyWith(comfort: value));
  });
}/// Create a copy of Planning503020Distribution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Planning503020DistributionGroupCopyWith<$Res> get investment {
  
  return $Planning503020DistributionGroupCopyWith<$Res>(_self.investment, (value) {
    return _then(_self.copyWith(investment: value));
  });
}
}


/// Adds pattern-matching-related methods to [Planning503020Distribution].
extension Planning503020DistributionPatterns on Planning503020Distribution {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Planning503020Distribution value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Planning503020Distribution() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Planning503020Distribution value)  $default,){
final _that = this;
switch (_that) {
case _Planning503020Distribution():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Planning503020Distribution value)?  $default,){
final _that = this;
switch (_that) {
case _Planning503020Distribution() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Planning503020DistributionGroup essential,  Planning503020DistributionGroup comfort,  Planning503020DistributionGroup investment,  double totalIncome,  double totalActualIncome)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Planning503020Distribution() when $default != null:
return $default(_that.essential,_that.comfort,_that.investment,_that.totalIncome,_that.totalActualIncome);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Planning503020DistributionGroup essential,  Planning503020DistributionGroup comfort,  Planning503020DistributionGroup investment,  double totalIncome,  double totalActualIncome)  $default,) {final _that = this;
switch (_that) {
case _Planning503020Distribution():
return $default(_that.essential,_that.comfort,_that.investment,_that.totalIncome,_that.totalActualIncome);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Planning503020DistributionGroup essential,  Planning503020DistributionGroup comfort,  Planning503020DistributionGroup investment,  double totalIncome,  double totalActualIncome)?  $default,) {final _that = this;
switch (_that) {
case _Planning503020Distribution() when $default != null:
return $default(_that.essential,_that.comfort,_that.investment,_that.totalIncome,_that.totalActualIncome);case _:
  return null;

}
}

}

/// @nodoc


class _Planning503020Distribution implements Planning503020Distribution {
  const _Planning503020Distribution({required this.essential, required this.comfort, required this.investment, this.totalIncome = 0.0, this.totalActualIncome = 0.0});
  

@override final  Planning503020DistributionGroup essential;
@override final  Planning503020DistributionGroup comfort;
@override final  Planning503020DistributionGroup investment;
@override@JsonKey() final  double totalIncome;
@override@JsonKey() final  double totalActualIncome;

/// Create a copy of Planning503020Distribution
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Planning503020DistributionCopyWith<_Planning503020Distribution> get copyWith => __$Planning503020DistributionCopyWithImpl<_Planning503020Distribution>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Planning503020Distribution&&(identical(other.essential, essential) || other.essential == essential)&&(identical(other.comfort, comfort) || other.comfort == comfort)&&(identical(other.investment, investment) || other.investment == investment)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.totalActualIncome, totalActualIncome) || other.totalActualIncome == totalActualIncome));
}


@override
int get hashCode => Object.hash(runtimeType,essential,comfort,investment,totalIncome,totalActualIncome);

@override
String toString() {
  return 'Planning503020Distribution(essential: $essential, comfort: $comfort, investment: $investment, totalIncome: $totalIncome, totalActualIncome: $totalActualIncome)';
}


}

/// @nodoc
abstract mixin class _$Planning503020DistributionCopyWith<$Res> implements $Planning503020DistributionCopyWith<$Res> {
  factory _$Planning503020DistributionCopyWith(_Planning503020Distribution value, $Res Function(_Planning503020Distribution) _then) = __$Planning503020DistributionCopyWithImpl;
@override @useResult
$Res call({
 Planning503020DistributionGroup essential, Planning503020DistributionGroup comfort, Planning503020DistributionGroup investment, double totalIncome, double totalActualIncome
});


@override $Planning503020DistributionGroupCopyWith<$Res> get essential;@override $Planning503020DistributionGroupCopyWith<$Res> get comfort;@override $Planning503020DistributionGroupCopyWith<$Res> get investment;

}
/// @nodoc
class __$Planning503020DistributionCopyWithImpl<$Res>
    implements _$Planning503020DistributionCopyWith<$Res> {
  __$Planning503020DistributionCopyWithImpl(this._self, this._then);

  final _Planning503020Distribution _self;
  final $Res Function(_Planning503020Distribution) _then;

/// Create a copy of Planning503020Distribution
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? essential = null,Object? comfort = null,Object? investment = null,Object? totalIncome = null,Object? totalActualIncome = null,}) {
  return _then(_Planning503020Distribution(
essential: null == essential ? _self.essential : essential // ignore: cast_nullable_to_non_nullable
as Planning503020DistributionGroup,comfort: null == comfort ? _self.comfort : comfort // ignore: cast_nullable_to_non_nullable
as Planning503020DistributionGroup,investment: null == investment ? _self.investment : investment // ignore: cast_nullable_to_non_nullable
as Planning503020DistributionGroup,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as double,totalActualIncome: null == totalActualIncome ? _self.totalActualIncome : totalActualIncome // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of Planning503020Distribution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Planning503020DistributionGroupCopyWith<$Res> get essential {
  
  return $Planning503020DistributionGroupCopyWith<$Res>(_self.essential, (value) {
    return _then(_self.copyWith(essential: value));
  });
}/// Create a copy of Planning503020Distribution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Planning503020DistributionGroupCopyWith<$Res> get comfort {
  
  return $Planning503020DistributionGroupCopyWith<$Res>(_self.comfort, (value) {
    return _then(_self.copyWith(comfort: value));
  });
}/// Create a copy of Planning503020Distribution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Planning503020DistributionGroupCopyWith<$Res> get investment {
  
  return $Planning503020DistributionGroupCopyWith<$Res>(_self.investment, (value) {
    return _then(_self.copyWith(investment: value));
  });
}
}

/// @nodoc
mixin _$TransactionWizardArgs {

 OrderType get type; bool get skipTransactions;
/// Create a copy of TransactionWizardArgs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionWizardArgsCopyWith<TransactionWizardArgs> get copyWith => _$TransactionWizardArgsCopyWithImpl<TransactionWizardArgs>(this as TransactionWizardArgs, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionWizardArgs&&(identical(other.type, type) || other.type == type)&&(identical(other.skipTransactions, skipTransactions) || other.skipTransactions == skipTransactions));
}


@override
int get hashCode => Object.hash(runtimeType,type,skipTransactions);

@override
String toString() {
  return 'TransactionWizardArgs(type: $type, skipTransactions: $skipTransactions)';
}


}

/// @nodoc
abstract mixin class $TransactionWizardArgsCopyWith<$Res>  {
  factory $TransactionWizardArgsCopyWith(TransactionWizardArgs value, $Res Function(TransactionWizardArgs) _then) = _$TransactionWizardArgsCopyWithImpl;
@useResult
$Res call({
 OrderType type, bool skipTransactions
});




}
/// @nodoc
class _$TransactionWizardArgsCopyWithImpl<$Res>
    implements $TransactionWizardArgsCopyWith<$Res> {
  _$TransactionWizardArgsCopyWithImpl(this._self, this._then);

  final TransactionWizardArgs _self;
  final $Res Function(TransactionWizardArgs) _then;

/// Create a copy of TransactionWizardArgs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? skipTransactions = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType,skipTransactions: null == skipTransactions ? _self.skipTransactions : skipTransactions // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionWizardArgs].
extension TransactionWizardArgsPatterns on TransactionWizardArgs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionWizardArgs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionWizardArgs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionWizardArgs value)  $default,){
final _that = this;
switch (_that) {
case _TransactionWizardArgs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionWizardArgs value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionWizardArgs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OrderType type,  bool skipTransactions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionWizardArgs() when $default != null:
return $default(_that.type,_that.skipTransactions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OrderType type,  bool skipTransactions)  $default,) {final _that = this;
switch (_that) {
case _TransactionWizardArgs():
return $default(_that.type,_that.skipTransactions);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OrderType type,  bool skipTransactions)?  $default,) {final _that = this;
switch (_that) {
case _TransactionWizardArgs() when $default != null:
return $default(_that.type,_that.skipTransactions);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionWizardArgs implements TransactionWizardArgs {
   _TransactionWizardArgs({required this.type, this.skipTransactions = false});
  

@override final  OrderType type;
@override@JsonKey() final  bool skipTransactions;

/// Create a copy of TransactionWizardArgs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionWizardArgsCopyWith<_TransactionWizardArgs> get copyWith => __$TransactionWizardArgsCopyWithImpl<_TransactionWizardArgs>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionWizardArgs&&(identical(other.type, type) || other.type == type)&&(identical(other.skipTransactions, skipTransactions) || other.skipTransactions == skipTransactions));
}


@override
int get hashCode => Object.hash(runtimeType,type,skipTransactions);

@override
String toString() {
  return 'TransactionWizardArgs(type: $type, skipTransactions: $skipTransactions)';
}


}

/// @nodoc
abstract mixin class _$TransactionWizardArgsCopyWith<$Res> implements $TransactionWizardArgsCopyWith<$Res> {
  factory _$TransactionWizardArgsCopyWith(_TransactionWizardArgs value, $Res Function(_TransactionWizardArgs) _then) = __$TransactionWizardArgsCopyWithImpl;
@override @useResult
$Res call({
 OrderType type, bool skipTransactions
});




}
/// @nodoc
class __$TransactionWizardArgsCopyWithImpl<$Res>
    implements _$TransactionWizardArgsCopyWith<$Res> {
  __$TransactionWizardArgsCopyWithImpl(this._self, this._then);

  final _TransactionWizardArgs _self;
  final $Res Function(_TransactionWizardArgs) _then;

/// Create a copy of TransactionWizardArgs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? skipTransactions = null,}) {
  return _then(_TransactionWizardArgs(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType,skipTransactions: null == skipTransactions ? _self.skipTransactions : skipTransactions // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$TransactionWizardState {

 OrderType get type; CategoryModel? get selectedCategory; InstallmentModel? get selectedInstallment; TransactionWizardStep get step; bool get skipTransactions;
/// Create a copy of TransactionWizardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionWizardStateCopyWith<TransactionWizardState> get copyWith => _$TransactionWizardStateCopyWithImpl<TransactionWizardState>(this as TransactionWizardState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionWizardState&&(identical(other.type, type) || other.type == type)&&(identical(other.selectedCategory, selectedCategory) || other.selectedCategory == selectedCategory)&&(identical(other.selectedInstallment, selectedInstallment) || other.selectedInstallment == selectedInstallment)&&(identical(other.step, step) || other.step == step)&&(identical(other.skipTransactions, skipTransactions) || other.skipTransactions == skipTransactions));
}


@override
int get hashCode => Object.hash(runtimeType,type,selectedCategory,selectedInstallment,step,skipTransactions);

@override
String toString() {
  return 'TransactionWizardState(type: $type, selectedCategory: $selectedCategory, selectedInstallment: $selectedInstallment, step: $step, skipTransactions: $skipTransactions)';
}


}

/// @nodoc
abstract mixin class $TransactionWizardStateCopyWith<$Res>  {
  factory $TransactionWizardStateCopyWith(TransactionWizardState value, $Res Function(TransactionWizardState) _then) = _$TransactionWizardStateCopyWithImpl;
@useResult
$Res call({
 OrderType type, CategoryModel? selectedCategory, InstallmentModel? selectedInstallment, TransactionWizardStep step, bool skipTransactions
});


$CategoryModelCopyWith<$Res>? get selectedCategory;$InstallmentModelCopyWith<$Res>? get selectedInstallment;

}
/// @nodoc
class _$TransactionWizardStateCopyWithImpl<$Res>
    implements $TransactionWizardStateCopyWith<$Res> {
  _$TransactionWizardStateCopyWithImpl(this._self, this._then);

  final TransactionWizardState _self;
  final $Res Function(TransactionWizardState) _then;

/// Create a copy of TransactionWizardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? selectedCategory = freezed,Object? selectedInstallment = freezed,Object? step = null,Object? skipTransactions = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType,selectedCategory: freezed == selectedCategory ? _self.selectedCategory : selectedCategory // ignore: cast_nullable_to_non_nullable
as CategoryModel?,selectedInstallment: freezed == selectedInstallment ? _self.selectedInstallment : selectedInstallment // ignore: cast_nullable_to_non_nullable
as InstallmentModel?,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as TransactionWizardStep,skipTransactions: null == skipTransactions ? _self.skipTransactions : skipTransactions // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of TransactionWizardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get selectedCategory {
    if (_self.selectedCategory == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.selectedCategory!, (value) {
    return _then(_self.copyWith(selectedCategory: value));
  });
}/// Create a copy of TransactionWizardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstallmentModelCopyWith<$Res>? get selectedInstallment {
    if (_self.selectedInstallment == null) {
    return null;
  }

  return $InstallmentModelCopyWith<$Res>(_self.selectedInstallment!, (value) {
    return _then(_self.copyWith(selectedInstallment: value));
  });
}
}


/// Adds pattern-matching-related methods to [TransactionWizardState].
extension TransactionWizardStatePatterns on TransactionWizardState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionWizardState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionWizardState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionWizardState value)  $default,){
final _that = this;
switch (_that) {
case _TransactionWizardState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionWizardState value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionWizardState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OrderType type,  CategoryModel? selectedCategory,  InstallmentModel? selectedInstallment,  TransactionWizardStep step,  bool skipTransactions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionWizardState() when $default != null:
return $default(_that.type,_that.selectedCategory,_that.selectedInstallment,_that.step,_that.skipTransactions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OrderType type,  CategoryModel? selectedCategory,  InstallmentModel? selectedInstallment,  TransactionWizardStep step,  bool skipTransactions)  $default,) {final _that = this;
switch (_that) {
case _TransactionWizardState():
return $default(_that.type,_that.selectedCategory,_that.selectedInstallment,_that.step,_that.skipTransactions);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OrderType type,  CategoryModel? selectedCategory,  InstallmentModel? selectedInstallment,  TransactionWizardStep step,  bool skipTransactions)?  $default,) {final _that = this;
switch (_that) {
case _TransactionWizardState() when $default != null:
return $default(_that.type,_that.selectedCategory,_that.selectedInstallment,_that.step,_that.skipTransactions);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionWizardState implements TransactionWizardState {
  const _TransactionWizardState({required this.type, this.selectedCategory, this.selectedInstallment, this.step = TransactionWizardStep.category, this.skipTransactions = false});
  

@override final  OrderType type;
@override final  CategoryModel? selectedCategory;
@override final  InstallmentModel? selectedInstallment;
@override@JsonKey() final  TransactionWizardStep step;
@override@JsonKey() final  bool skipTransactions;

/// Create a copy of TransactionWizardState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionWizardStateCopyWith<_TransactionWizardState> get copyWith => __$TransactionWizardStateCopyWithImpl<_TransactionWizardState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionWizardState&&(identical(other.type, type) || other.type == type)&&(identical(other.selectedCategory, selectedCategory) || other.selectedCategory == selectedCategory)&&(identical(other.selectedInstallment, selectedInstallment) || other.selectedInstallment == selectedInstallment)&&(identical(other.step, step) || other.step == step)&&(identical(other.skipTransactions, skipTransactions) || other.skipTransactions == skipTransactions));
}


@override
int get hashCode => Object.hash(runtimeType,type,selectedCategory,selectedInstallment,step,skipTransactions);

@override
String toString() {
  return 'TransactionWizardState(type: $type, selectedCategory: $selectedCategory, selectedInstallment: $selectedInstallment, step: $step, skipTransactions: $skipTransactions)';
}


}

/// @nodoc
abstract mixin class _$TransactionWizardStateCopyWith<$Res> implements $TransactionWizardStateCopyWith<$Res> {
  factory _$TransactionWizardStateCopyWith(_TransactionWizardState value, $Res Function(_TransactionWizardState) _then) = __$TransactionWizardStateCopyWithImpl;
@override @useResult
$Res call({
 OrderType type, CategoryModel? selectedCategory, InstallmentModel? selectedInstallment, TransactionWizardStep step, bool skipTransactions
});


@override $CategoryModelCopyWith<$Res>? get selectedCategory;@override $InstallmentModelCopyWith<$Res>? get selectedInstallment;

}
/// @nodoc
class __$TransactionWizardStateCopyWithImpl<$Res>
    implements _$TransactionWizardStateCopyWith<$Res> {
  __$TransactionWizardStateCopyWithImpl(this._self, this._then);

  final _TransactionWizardState _self;
  final $Res Function(_TransactionWizardState) _then;

/// Create a copy of TransactionWizardState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? selectedCategory = freezed,Object? selectedInstallment = freezed,Object? step = null,Object? skipTransactions = null,}) {
  return _then(_TransactionWizardState(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType,selectedCategory: freezed == selectedCategory ? _self.selectedCategory : selectedCategory // ignore: cast_nullable_to_non_nullable
as CategoryModel?,selectedInstallment: freezed == selectedInstallment ? _self.selectedInstallment : selectedInstallment // ignore: cast_nullable_to_non_nullable
as InstallmentModel?,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as TransactionWizardStep,skipTransactions: null == skipTransactions ? _self.skipTransactions : skipTransactions // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of TransactionWizardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res>? get selectedCategory {
    if (_self.selectedCategory == null) {
    return null;
  }

  return $CategoryModelCopyWith<$Res>(_self.selectedCategory!, (value) {
    return _then(_self.copyWith(selectedCategory: value));
  });
}/// Create a copy of TransactionWizardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstallmentModelCopyWith<$Res>? get selectedInstallment {
    if (_self.selectedInstallment == null) {
    return null;
  }

  return $InstallmentModelCopyWith<$Res>(_self.selectedInstallment!, (value) {
    return _then(_self.copyWith(selectedInstallment: value));
  });
}
}

/// @nodoc
mixin _$TransactionCreationArgs {

 OrderType get type; InstallmentStatus? get status; CategoryModel? get category; String? get accountIdSource; String? get accountIdTarget; String? get description; DateTime? get date; double? get amount;
/// Create a copy of TransactionCreationArgs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionCreationArgsCopyWith<TransactionCreationArgs> get copyWith => _$TransactionCreationArgsCopyWithImpl<TransactionCreationArgs>(this as TransactionCreationArgs, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionCreationArgs&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.category, category) || other.category == category)&&(identical(other.accountIdSource, accountIdSource) || other.accountIdSource == accountIdSource)&&(identical(other.accountIdTarget, accountIdTarget) || other.accountIdTarget == accountIdTarget)&&(identical(other.description, description) || other.description == description)&&(identical(other.date, date) || other.date == date)&&(identical(other.amount, amount) || other.amount == amount));
}


@override
int get hashCode => Object.hash(runtimeType,type,status,category,accountIdSource,accountIdTarget,description,date,amount);

@override
String toString() {
  return 'TransactionCreationArgs(type: $type, status: $status, category: $category, accountIdSource: $accountIdSource, accountIdTarget: $accountIdTarget, description: $description, date: $date, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $TransactionCreationArgsCopyWith<$Res>  {
  factory $TransactionCreationArgsCopyWith(TransactionCreationArgs value, $Res Function(TransactionCreationArgs) _then) = _$TransactionCreationArgsCopyWithImpl;
@useResult
$Res call({
 OrderType type, InstallmentStatus? status, CategoryModel? category, String? accountIdSource, String? accountIdTarget, String? description, DateTime? date, double? amount
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
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? status = freezed,Object? category = freezed,Object? accountIdSource = freezed,Object? accountIdTarget = freezed,Object? description = freezed,Object? date = freezed,Object? amount = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstallmentStatus?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,accountIdSource: freezed == accountIdSource ? _self.accountIdSource : accountIdSource // ignore: cast_nullable_to_non_nullable
as String?,accountIdTarget: freezed == accountIdTarget ? _self.accountIdTarget : accountIdTarget // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OrderType type,  InstallmentStatus? status,  CategoryModel? category,  String? accountIdSource,  String? accountIdTarget,  String? description,  DateTime? date,  double? amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionCreationArgs() when $default != null:
return $default(_that.type,_that.status,_that.category,_that.accountIdSource,_that.accountIdTarget,_that.description,_that.date,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OrderType type,  InstallmentStatus? status,  CategoryModel? category,  String? accountIdSource,  String? accountIdTarget,  String? description,  DateTime? date,  double? amount)  $default,) {final _that = this;
switch (_that) {
case _TransactionCreationArgs():
return $default(_that.type,_that.status,_that.category,_that.accountIdSource,_that.accountIdTarget,_that.description,_that.date,_that.amount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OrderType type,  InstallmentStatus? status,  CategoryModel? category,  String? accountIdSource,  String? accountIdTarget,  String? description,  DateTime? date,  double? amount)?  $default,) {final _that = this;
switch (_that) {
case _TransactionCreationArgs() when $default != null:
return $default(_that.type,_that.status,_that.category,_that.accountIdSource,_that.accountIdTarget,_that.description,_that.date,_that.amount);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionCreationArgs implements TransactionCreationArgs {
   _TransactionCreationArgs({required this.type, this.status, this.category, this.accountIdSource, this.accountIdTarget, this.description, this.date, this.amount});
  

@override final  OrderType type;
@override final  InstallmentStatus? status;
@override final  CategoryModel? category;
@override final  String? accountIdSource;
@override final  String? accountIdTarget;
@override final  String? description;
@override final  DateTime? date;
@override final  double? amount;

/// Create a copy of TransactionCreationArgs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionCreationArgsCopyWith<_TransactionCreationArgs> get copyWith => __$TransactionCreationArgsCopyWithImpl<_TransactionCreationArgs>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionCreationArgs&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.category, category) || other.category == category)&&(identical(other.accountIdSource, accountIdSource) || other.accountIdSource == accountIdSource)&&(identical(other.accountIdTarget, accountIdTarget) || other.accountIdTarget == accountIdTarget)&&(identical(other.description, description) || other.description == description)&&(identical(other.date, date) || other.date == date)&&(identical(other.amount, amount) || other.amount == amount));
}


@override
int get hashCode => Object.hash(runtimeType,type,status,category,accountIdSource,accountIdTarget,description,date,amount);

@override
String toString() {
  return 'TransactionCreationArgs(type: $type, status: $status, category: $category, accountIdSource: $accountIdSource, accountIdTarget: $accountIdTarget, description: $description, date: $date, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$TransactionCreationArgsCopyWith<$Res> implements $TransactionCreationArgsCopyWith<$Res> {
  factory _$TransactionCreationArgsCopyWith(_TransactionCreationArgs value, $Res Function(_TransactionCreationArgs) _then) = __$TransactionCreationArgsCopyWithImpl;
@override @useResult
$Res call({
 OrderType type, InstallmentStatus? status, CategoryModel? category, String? accountIdSource, String? accountIdTarget, String? description, DateTime? date, double? amount
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
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? status = freezed,Object? category = freezed,Object? accountIdSource = freezed,Object? accountIdTarget = freezed,Object? description = freezed,Object? date = freezed,Object? amount = freezed,}) {
  return _then(_TransactionCreationArgs(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderType,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstallmentStatus?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel?,accountIdSource: freezed == accountIdSource ? _self.accountIdSource : accountIdSource // ignore: cast_nullable_to_non_nullable
as String?,accountIdTarget: freezed == accountIdTarget ? _self.accountIdTarget : accountIdTarget // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,
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

 String? get installmentId; String? get orderId; TransactionFormType get formType; OrderType get type; InstallmentType get installmentType; TransactionAmountType get amountType; String get description; double get amount; int? get intallmentNumber; int? get installmentCount; DateTime get dueDate; InstallmentStatus get status; DateTime? get paidDate; double? get paidAmount; CategoryModel? get category; String? get accountIdSource; String? get accountIdTarget; ReplicationCascade? get replicateCascade; bool get isInvoice;
/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFormStateCopyWith<TransactionFormState> get copyWith => _$TransactionFormStateCopyWithImpl<TransactionFormState>(this as TransactionFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormState&&(identical(other.installmentId, installmentId) || other.installmentId == installmentId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.formType, formType) || other.formType == formType)&&(identical(other.type, type) || other.type == type)&&(identical(other.installmentType, installmentType) || other.installmentType == installmentType)&&(identical(other.amountType, amountType) || other.amountType == amountType)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.intallmentNumber, intallmentNumber) || other.intallmentNumber == intallmentNumber)&&(identical(other.installmentCount, installmentCount) || other.installmentCount == installmentCount)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.paidDate, paidDate) || other.paidDate == paidDate)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.category, category) || other.category == category)&&(identical(other.accountIdSource, accountIdSource) || other.accountIdSource == accountIdSource)&&(identical(other.accountIdTarget, accountIdTarget) || other.accountIdTarget == accountIdTarget)&&(identical(other.replicateCascade, replicateCascade) || other.replicateCascade == replicateCascade)&&(identical(other.isInvoice, isInvoice) || other.isInvoice == isInvoice));
}


@override
int get hashCode => Object.hashAll([runtimeType,installmentId,orderId,formType,type,installmentType,amountType,description,amount,intallmentNumber,installmentCount,dueDate,status,paidDate,paidAmount,category,accountIdSource,accountIdTarget,replicateCascade,isInvoice]);

@override
String toString() {
  return 'TransactionFormState(installmentId: $installmentId, orderId: $orderId, formType: $formType, type: $type, installmentType: $installmentType, amountType: $amountType, description: $description, amount: $amount, intallmentNumber: $intallmentNumber, installmentCount: $installmentCount, dueDate: $dueDate, status: $status, paidDate: $paidDate, paidAmount: $paidAmount, category: $category, accountIdSource: $accountIdSource, accountIdTarget: $accountIdTarget, replicateCascade: $replicateCascade, isInvoice: $isInvoice)';
}


}

/// @nodoc
abstract mixin class $TransactionFormStateCopyWith<$Res>  {
  factory $TransactionFormStateCopyWith(TransactionFormState value, $Res Function(TransactionFormState) _then) = _$TransactionFormStateCopyWithImpl;
@useResult
$Res call({
 String? installmentId, String? orderId, TransactionFormType formType, OrderType type, InstallmentType installmentType, TransactionAmountType amountType, String description, double amount, int? intallmentNumber, int? installmentCount, DateTime dueDate, InstallmentStatus status, DateTime? paidDate, double? paidAmount, CategoryModel? category, String? accountIdSource, String? accountIdTarget, ReplicationCascade? replicateCascade, bool isInvoice
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
@pragma('vm:prefer-inline') @override $Res call({Object? installmentId = freezed,Object? orderId = freezed,Object? formType = null,Object? type = null,Object? installmentType = null,Object? amountType = null,Object? description = null,Object? amount = null,Object? intallmentNumber = freezed,Object? installmentCount = freezed,Object? dueDate = null,Object? status = null,Object? paidDate = freezed,Object? paidAmount = freezed,Object? category = freezed,Object? accountIdSource = freezed,Object? accountIdTarget = freezed,Object? replicateCascade = freezed,Object? isInvoice = null,}) {
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
as ReplicationCascade?,isInvoice: null == isInvoice ? _self.isInvoice : isInvoice // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? installmentId,  String? orderId,  TransactionFormType formType,  OrderType type,  InstallmentType installmentType,  TransactionAmountType amountType,  String description,  double amount,  int? intallmentNumber,  int? installmentCount,  DateTime dueDate,  InstallmentStatus status,  DateTime? paidDate,  double? paidAmount,  CategoryModel? category,  String? accountIdSource,  String? accountIdTarget,  ReplicationCascade? replicateCascade,  bool isInvoice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionFormState() when $default != null:
return $default(_that.installmentId,_that.orderId,_that.formType,_that.type,_that.installmentType,_that.amountType,_that.description,_that.amount,_that.intallmentNumber,_that.installmentCount,_that.dueDate,_that.status,_that.paidDate,_that.paidAmount,_that.category,_that.accountIdSource,_that.accountIdTarget,_that.replicateCascade,_that.isInvoice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? installmentId,  String? orderId,  TransactionFormType formType,  OrderType type,  InstallmentType installmentType,  TransactionAmountType amountType,  String description,  double amount,  int? intallmentNumber,  int? installmentCount,  DateTime dueDate,  InstallmentStatus status,  DateTime? paidDate,  double? paidAmount,  CategoryModel? category,  String? accountIdSource,  String? accountIdTarget,  ReplicationCascade? replicateCascade,  bool isInvoice)  $default,) {final _that = this;
switch (_that) {
case _TransactionFormState():
return $default(_that.installmentId,_that.orderId,_that.formType,_that.type,_that.installmentType,_that.amountType,_that.description,_that.amount,_that.intallmentNumber,_that.installmentCount,_that.dueDate,_that.status,_that.paidDate,_that.paidAmount,_that.category,_that.accountIdSource,_that.accountIdTarget,_that.replicateCascade,_that.isInvoice);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? installmentId,  String? orderId,  TransactionFormType formType,  OrderType type,  InstallmentType installmentType,  TransactionAmountType amountType,  String description,  double amount,  int? intallmentNumber,  int? installmentCount,  DateTime dueDate,  InstallmentStatus status,  DateTime? paidDate,  double? paidAmount,  CategoryModel? category,  String? accountIdSource,  String? accountIdTarget,  ReplicationCascade? replicateCascade,  bool isInvoice)?  $default,) {final _that = this;
switch (_that) {
case _TransactionFormState() when $default != null:
return $default(_that.installmentId,_that.orderId,_that.formType,_that.type,_that.installmentType,_that.amountType,_that.description,_that.amount,_that.intallmentNumber,_that.installmentCount,_that.dueDate,_that.status,_that.paidDate,_that.paidAmount,_that.category,_that.accountIdSource,_that.accountIdTarget,_that.replicateCascade,_that.isInvoice);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionFormState extends TransactionFormState {
  const _TransactionFormState({this.installmentId, this.orderId, required this.formType, required this.type, required this.installmentType, this.amountType = TransactionAmountType.total, this.description = "", this.amount = 0.0, this.intallmentNumber, this.installmentCount, required this.dueDate, this.status = InstallmentStatus.pending, this.paidDate, this.paidAmount, this.category, this.accountIdSource, this.accountIdTarget, this.replicateCascade, this.isInvoice = false}): super._();
  

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
@override@JsonKey() final  bool isInvoice;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionFormStateCopyWith<_TransactionFormState> get copyWith => __$TransactionFormStateCopyWithImpl<_TransactionFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionFormState&&(identical(other.installmentId, installmentId) || other.installmentId == installmentId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.formType, formType) || other.formType == formType)&&(identical(other.type, type) || other.type == type)&&(identical(other.installmentType, installmentType) || other.installmentType == installmentType)&&(identical(other.amountType, amountType) || other.amountType == amountType)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.intallmentNumber, intallmentNumber) || other.intallmentNumber == intallmentNumber)&&(identical(other.installmentCount, installmentCount) || other.installmentCount == installmentCount)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.paidDate, paidDate) || other.paidDate == paidDate)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.category, category) || other.category == category)&&(identical(other.accountIdSource, accountIdSource) || other.accountIdSource == accountIdSource)&&(identical(other.accountIdTarget, accountIdTarget) || other.accountIdTarget == accountIdTarget)&&(identical(other.replicateCascade, replicateCascade) || other.replicateCascade == replicateCascade)&&(identical(other.isInvoice, isInvoice) || other.isInvoice == isInvoice));
}


@override
int get hashCode => Object.hashAll([runtimeType,installmentId,orderId,formType,type,installmentType,amountType,description,amount,intallmentNumber,installmentCount,dueDate,status,paidDate,paidAmount,category,accountIdSource,accountIdTarget,replicateCascade,isInvoice]);

@override
String toString() {
  return 'TransactionFormState(installmentId: $installmentId, orderId: $orderId, formType: $formType, type: $type, installmentType: $installmentType, amountType: $amountType, description: $description, amount: $amount, intallmentNumber: $intallmentNumber, installmentCount: $installmentCount, dueDate: $dueDate, status: $status, paidDate: $paidDate, paidAmount: $paidAmount, category: $category, accountIdSource: $accountIdSource, accountIdTarget: $accountIdTarget, replicateCascade: $replicateCascade, isInvoice: $isInvoice)';
}


}

/// @nodoc
abstract mixin class _$TransactionFormStateCopyWith<$Res> implements $TransactionFormStateCopyWith<$Res> {
  factory _$TransactionFormStateCopyWith(_TransactionFormState value, $Res Function(_TransactionFormState) _then) = __$TransactionFormStateCopyWithImpl;
@override @useResult
$Res call({
 String? installmentId, String? orderId, TransactionFormType formType, OrderType type, InstallmentType installmentType, TransactionAmountType amountType, String description, double amount, int? intallmentNumber, int? installmentCount, DateTime dueDate, InstallmentStatus status, DateTime? paidDate, double? paidAmount, CategoryModel? category, String? accountIdSource, String? accountIdTarget, ReplicationCascade? replicateCascade, bool isInvoice
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
@override @pragma('vm:prefer-inline') $Res call({Object? installmentId = freezed,Object? orderId = freezed,Object? formType = null,Object? type = null,Object? installmentType = null,Object? amountType = null,Object? description = null,Object? amount = null,Object? intallmentNumber = freezed,Object? installmentCount = freezed,Object? dueDate = null,Object? status = null,Object? paidDate = freezed,Object? paidAmount = freezed,Object? category = freezed,Object? accountIdSource = freezed,Object? accountIdTarget = freezed,Object? replicateCascade = freezed,Object? isInvoice = null,}) {
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
as ReplicationCascade?,isInvoice: null == isInvoice ? _self.isInvoice : isInvoice // ignore: cast_nullable_to_non_nullable
as bool,
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
mixin _$TransactionTotals {

 double get plannedIncomes; double get realizedIncomes; double get plannedExpenses; double get realizedExpenses; double get plannedTransfers; double get realizedTransfers; double get plannedInvoices; double get realizedInvoices; double get plannedVirtualDebtExpense; double get realizedVirtualDebtExpense; double get plannedVirtualDebtIncome; double get realizedVirtualDebtIncome; double get plannedVirtualInvestmentExpense; double get realizedVirtualInvestmentExpense; double get plannedVirtualInvestmentIncome; double get realizedVirtualInvestmentIncome;
/// Create a copy of TransactionTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionTotalsCopyWith<TransactionTotals> get copyWith => _$TransactionTotalsCopyWithImpl<TransactionTotals>(this as TransactionTotals, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionTotals&&(identical(other.plannedIncomes, plannedIncomes) || other.plannedIncomes == plannedIncomes)&&(identical(other.realizedIncomes, realizedIncomes) || other.realizedIncomes == realizedIncomes)&&(identical(other.plannedExpenses, plannedExpenses) || other.plannedExpenses == plannedExpenses)&&(identical(other.realizedExpenses, realizedExpenses) || other.realizedExpenses == realizedExpenses)&&(identical(other.plannedTransfers, plannedTransfers) || other.plannedTransfers == plannedTransfers)&&(identical(other.realizedTransfers, realizedTransfers) || other.realizedTransfers == realizedTransfers)&&(identical(other.plannedInvoices, plannedInvoices) || other.plannedInvoices == plannedInvoices)&&(identical(other.realizedInvoices, realizedInvoices) || other.realizedInvoices == realizedInvoices)&&(identical(other.plannedVirtualDebtExpense, plannedVirtualDebtExpense) || other.plannedVirtualDebtExpense == plannedVirtualDebtExpense)&&(identical(other.realizedVirtualDebtExpense, realizedVirtualDebtExpense) || other.realizedVirtualDebtExpense == realizedVirtualDebtExpense)&&(identical(other.plannedVirtualDebtIncome, plannedVirtualDebtIncome) || other.plannedVirtualDebtIncome == plannedVirtualDebtIncome)&&(identical(other.realizedVirtualDebtIncome, realizedVirtualDebtIncome) || other.realizedVirtualDebtIncome == realizedVirtualDebtIncome)&&(identical(other.plannedVirtualInvestmentExpense, plannedVirtualInvestmentExpense) || other.plannedVirtualInvestmentExpense == plannedVirtualInvestmentExpense)&&(identical(other.realizedVirtualInvestmentExpense, realizedVirtualInvestmentExpense) || other.realizedVirtualInvestmentExpense == realizedVirtualInvestmentExpense)&&(identical(other.plannedVirtualInvestmentIncome, plannedVirtualInvestmentIncome) || other.plannedVirtualInvestmentIncome == plannedVirtualInvestmentIncome)&&(identical(other.realizedVirtualInvestmentIncome, realizedVirtualInvestmentIncome) || other.realizedVirtualInvestmentIncome == realizedVirtualInvestmentIncome));
}


@override
int get hashCode => Object.hash(runtimeType,plannedIncomes,realizedIncomes,plannedExpenses,realizedExpenses,plannedTransfers,realizedTransfers,plannedInvoices,realizedInvoices,plannedVirtualDebtExpense,realizedVirtualDebtExpense,plannedVirtualDebtIncome,realizedVirtualDebtIncome,plannedVirtualInvestmentExpense,realizedVirtualInvestmentExpense,plannedVirtualInvestmentIncome,realizedVirtualInvestmentIncome);

@override
String toString() {
  return 'TransactionTotals(plannedIncomes: $plannedIncomes, realizedIncomes: $realizedIncomes, plannedExpenses: $plannedExpenses, realizedExpenses: $realizedExpenses, plannedTransfers: $plannedTransfers, realizedTransfers: $realizedTransfers, plannedInvoices: $plannedInvoices, realizedInvoices: $realizedInvoices, plannedVirtualDebtExpense: $plannedVirtualDebtExpense, realizedVirtualDebtExpense: $realizedVirtualDebtExpense, plannedVirtualDebtIncome: $plannedVirtualDebtIncome, realizedVirtualDebtIncome: $realizedVirtualDebtIncome, plannedVirtualInvestmentExpense: $plannedVirtualInvestmentExpense, realizedVirtualInvestmentExpense: $realizedVirtualInvestmentExpense, plannedVirtualInvestmentIncome: $plannedVirtualInvestmentIncome, realizedVirtualInvestmentIncome: $realizedVirtualInvestmentIncome)';
}


}

/// @nodoc
abstract mixin class $TransactionTotalsCopyWith<$Res>  {
  factory $TransactionTotalsCopyWith(TransactionTotals value, $Res Function(TransactionTotals) _then) = _$TransactionTotalsCopyWithImpl;
@useResult
$Res call({
 double plannedIncomes, double realizedIncomes, double plannedExpenses, double realizedExpenses, double plannedTransfers, double realizedTransfers, double plannedInvoices, double realizedInvoices, double plannedVirtualDebtExpense, double realizedVirtualDebtExpense, double plannedVirtualDebtIncome, double realizedVirtualDebtIncome, double plannedVirtualInvestmentExpense, double realizedVirtualInvestmentExpense, double plannedVirtualInvestmentIncome, double realizedVirtualInvestmentIncome
});




}
/// @nodoc
class _$TransactionTotalsCopyWithImpl<$Res>
    implements $TransactionTotalsCopyWith<$Res> {
  _$TransactionTotalsCopyWithImpl(this._self, this._then);

  final TransactionTotals _self;
  final $Res Function(TransactionTotals) _then;

/// Create a copy of TransactionTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plannedIncomes = null,Object? realizedIncomes = null,Object? plannedExpenses = null,Object? realizedExpenses = null,Object? plannedTransfers = null,Object? realizedTransfers = null,Object? plannedInvoices = null,Object? realizedInvoices = null,Object? plannedVirtualDebtExpense = null,Object? realizedVirtualDebtExpense = null,Object? plannedVirtualDebtIncome = null,Object? realizedVirtualDebtIncome = null,Object? plannedVirtualInvestmentExpense = null,Object? realizedVirtualInvestmentExpense = null,Object? plannedVirtualInvestmentIncome = null,Object? realizedVirtualInvestmentIncome = null,}) {
  return _then(_self.copyWith(
plannedIncomes: null == plannedIncomes ? _self.plannedIncomes : plannedIncomes // ignore: cast_nullable_to_non_nullable
as double,realizedIncomes: null == realizedIncomes ? _self.realizedIncomes : realizedIncomes // ignore: cast_nullable_to_non_nullable
as double,plannedExpenses: null == plannedExpenses ? _self.plannedExpenses : plannedExpenses // ignore: cast_nullable_to_non_nullable
as double,realizedExpenses: null == realizedExpenses ? _self.realizedExpenses : realizedExpenses // ignore: cast_nullable_to_non_nullable
as double,plannedTransfers: null == plannedTransfers ? _self.plannedTransfers : plannedTransfers // ignore: cast_nullable_to_non_nullable
as double,realizedTransfers: null == realizedTransfers ? _self.realizedTransfers : realizedTransfers // ignore: cast_nullable_to_non_nullable
as double,plannedInvoices: null == plannedInvoices ? _self.plannedInvoices : plannedInvoices // ignore: cast_nullable_to_non_nullable
as double,realizedInvoices: null == realizedInvoices ? _self.realizedInvoices : realizedInvoices // ignore: cast_nullable_to_non_nullable
as double,plannedVirtualDebtExpense: null == plannedVirtualDebtExpense ? _self.plannedVirtualDebtExpense : plannedVirtualDebtExpense // ignore: cast_nullable_to_non_nullable
as double,realizedVirtualDebtExpense: null == realizedVirtualDebtExpense ? _self.realizedVirtualDebtExpense : realizedVirtualDebtExpense // ignore: cast_nullable_to_non_nullable
as double,plannedVirtualDebtIncome: null == plannedVirtualDebtIncome ? _self.plannedVirtualDebtIncome : plannedVirtualDebtIncome // ignore: cast_nullable_to_non_nullable
as double,realizedVirtualDebtIncome: null == realizedVirtualDebtIncome ? _self.realizedVirtualDebtIncome : realizedVirtualDebtIncome // ignore: cast_nullable_to_non_nullable
as double,plannedVirtualInvestmentExpense: null == plannedVirtualInvestmentExpense ? _self.plannedVirtualInvestmentExpense : plannedVirtualInvestmentExpense // ignore: cast_nullable_to_non_nullable
as double,realizedVirtualInvestmentExpense: null == realizedVirtualInvestmentExpense ? _self.realizedVirtualInvestmentExpense : realizedVirtualInvestmentExpense // ignore: cast_nullable_to_non_nullable
as double,plannedVirtualInvestmentIncome: null == plannedVirtualInvestmentIncome ? _self.plannedVirtualInvestmentIncome : plannedVirtualInvestmentIncome // ignore: cast_nullable_to_non_nullable
as double,realizedVirtualInvestmentIncome: null == realizedVirtualInvestmentIncome ? _self.realizedVirtualInvestmentIncome : realizedVirtualInvestmentIncome // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionTotals].
extension TransactionTotalsPatterns on TransactionTotals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionTotals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionTotals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionTotals value)  $default,){
final _that = this;
switch (_that) {
case _TransactionTotals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionTotals value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionTotals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double plannedIncomes,  double realizedIncomes,  double plannedExpenses,  double realizedExpenses,  double plannedTransfers,  double realizedTransfers,  double plannedInvoices,  double realizedInvoices,  double plannedVirtualDebtExpense,  double realizedVirtualDebtExpense,  double plannedVirtualDebtIncome,  double realizedVirtualDebtIncome,  double plannedVirtualInvestmentExpense,  double realizedVirtualInvestmentExpense,  double plannedVirtualInvestmentIncome,  double realizedVirtualInvestmentIncome)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionTotals() when $default != null:
return $default(_that.plannedIncomes,_that.realizedIncomes,_that.plannedExpenses,_that.realizedExpenses,_that.plannedTransfers,_that.realizedTransfers,_that.plannedInvoices,_that.realizedInvoices,_that.plannedVirtualDebtExpense,_that.realizedVirtualDebtExpense,_that.plannedVirtualDebtIncome,_that.realizedVirtualDebtIncome,_that.plannedVirtualInvestmentExpense,_that.realizedVirtualInvestmentExpense,_that.plannedVirtualInvestmentIncome,_that.realizedVirtualInvestmentIncome);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double plannedIncomes,  double realizedIncomes,  double plannedExpenses,  double realizedExpenses,  double plannedTransfers,  double realizedTransfers,  double plannedInvoices,  double realizedInvoices,  double plannedVirtualDebtExpense,  double realizedVirtualDebtExpense,  double plannedVirtualDebtIncome,  double realizedVirtualDebtIncome,  double plannedVirtualInvestmentExpense,  double realizedVirtualInvestmentExpense,  double plannedVirtualInvestmentIncome,  double realizedVirtualInvestmentIncome)  $default,) {final _that = this;
switch (_that) {
case _TransactionTotals():
return $default(_that.plannedIncomes,_that.realizedIncomes,_that.plannedExpenses,_that.realizedExpenses,_that.plannedTransfers,_that.realizedTransfers,_that.plannedInvoices,_that.realizedInvoices,_that.plannedVirtualDebtExpense,_that.realizedVirtualDebtExpense,_that.plannedVirtualDebtIncome,_that.realizedVirtualDebtIncome,_that.plannedVirtualInvestmentExpense,_that.realizedVirtualInvestmentExpense,_that.plannedVirtualInvestmentIncome,_that.realizedVirtualInvestmentIncome);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double plannedIncomes,  double realizedIncomes,  double plannedExpenses,  double realizedExpenses,  double plannedTransfers,  double realizedTransfers,  double plannedInvoices,  double realizedInvoices,  double plannedVirtualDebtExpense,  double realizedVirtualDebtExpense,  double plannedVirtualDebtIncome,  double realizedVirtualDebtIncome,  double plannedVirtualInvestmentExpense,  double realizedVirtualInvestmentExpense,  double plannedVirtualInvestmentIncome,  double realizedVirtualInvestmentIncome)?  $default,) {final _that = this;
switch (_that) {
case _TransactionTotals() when $default != null:
return $default(_that.plannedIncomes,_that.realizedIncomes,_that.plannedExpenses,_that.realizedExpenses,_that.plannedTransfers,_that.realizedTransfers,_that.plannedInvoices,_that.realizedInvoices,_that.plannedVirtualDebtExpense,_that.realizedVirtualDebtExpense,_that.plannedVirtualDebtIncome,_that.realizedVirtualDebtIncome,_that.plannedVirtualInvestmentExpense,_that.realizedVirtualInvestmentExpense,_that.plannedVirtualInvestmentIncome,_that.realizedVirtualInvestmentIncome);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionTotals extends TransactionTotals {
  const _TransactionTotals({this.plannedIncomes = 0.0, this.realizedIncomes = 0.0, this.plannedExpenses = 0.0, this.realizedExpenses = 0.0, this.plannedTransfers = 0.0, this.realizedTransfers = 0.0, this.plannedInvoices = 0.0, this.realizedInvoices = 0.0, this.plannedVirtualDebtExpense = 0.0, this.realizedVirtualDebtExpense = 0.0, this.plannedVirtualDebtIncome = 0.0, this.realizedVirtualDebtIncome = 0.0, this.plannedVirtualInvestmentExpense = 0.0, this.realizedVirtualInvestmentExpense = 0.0, this.plannedVirtualInvestmentIncome = 0.0, this.realizedVirtualInvestmentIncome = 0.0}): super._();
  

@override@JsonKey() final  double plannedIncomes;
@override@JsonKey() final  double realizedIncomes;
@override@JsonKey() final  double plannedExpenses;
@override@JsonKey() final  double realizedExpenses;
@override@JsonKey() final  double plannedTransfers;
@override@JsonKey() final  double realizedTransfers;
@override@JsonKey() final  double plannedInvoices;
@override@JsonKey() final  double realizedInvoices;
@override@JsonKey() final  double plannedVirtualDebtExpense;
@override@JsonKey() final  double realizedVirtualDebtExpense;
@override@JsonKey() final  double plannedVirtualDebtIncome;
@override@JsonKey() final  double realizedVirtualDebtIncome;
@override@JsonKey() final  double plannedVirtualInvestmentExpense;
@override@JsonKey() final  double realizedVirtualInvestmentExpense;
@override@JsonKey() final  double plannedVirtualInvestmentIncome;
@override@JsonKey() final  double realizedVirtualInvestmentIncome;

/// Create a copy of TransactionTotals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionTotalsCopyWith<_TransactionTotals> get copyWith => __$TransactionTotalsCopyWithImpl<_TransactionTotals>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionTotals&&(identical(other.plannedIncomes, plannedIncomes) || other.plannedIncomes == plannedIncomes)&&(identical(other.realizedIncomes, realizedIncomes) || other.realizedIncomes == realizedIncomes)&&(identical(other.plannedExpenses, plannedExpenses) || other.plannedExpenses == plannedExpenses)&&(identical(other.realizedExpenses, realizedExpenses) || other.realizedExpenses == realizedExpenses)&&(identical(other.plannedTransfers, plannedTransfers) || other.plannedTransfers == plannedTransfers)&&(identical(other.realizedTransfers, realizedTransfers) || other.realizedTransfers == realizedTransfers)&&(identical(other.plannedInvoices, plannedInvoices) || other.plannedInvoices == plannedInvoices)&&(identical(other.realizedInvoices, realizedInvoices) || other.realizedInvoices == realizedInvoices)&&(identical(other.plannedVirtualDebtExpense, plannedVirtualDebtExpense) || other.plannedVirtualDebtExpense == plannedVirtualDebtExpense)&&(identical(other.realizedVirtualDebtExpense, realizedVirtualDebtExpense) || other.realizedVirtualDebtExpense == realizedVirtualDebtExpense)&&(identical(other.plannedVirtualDebtIncome, plannedVirtualDebtIncome) || other.plannedVirtualDebtIncome == plannedVirtualDebtIncome)&&(identical(other.realizedVirtualDebtIncome, realizedVirtualDebtIncome) || other.realizedVirtualDebtIncome == realizedVirtualDebtIncome)&&(identical(other.plannedVirtualInvestmentExpense, plannedVirtualInvestmentExpense) || other.plannedVirtualInvestmentExpense == plannedVirtualInvestmentExpense)&&(identical(other.realizedVirtualInvestmentExpense, realizedVirtualInvestmentExpense) || other.realizedVirtualInvestmentExpense == realizedVirtualInvestmentExpense)&&(identical(other.plannedVirtualInvestmentIncome, plannedVirtualInvestmentIncome) || other.plannedVirtualInvestmentIncome == plannedVirtualInvestmentIncome)&&(identical(other.realizedVirtualInvestmentIncome, realizedVirtualInvestmentIncome) || other.realizedVirtualInvestmentIncome == realizedVirtualInvestmentIncome));
}


@override
int get hashCode => Object.hash(runtimeType,plannedIncomes,realizedIncomes,plannedExpenses,realizedExpenses,plannedTransfers,realizedTransfers,plannedInvoices,realizedInvoices,plannedVirtualDebtExpense,realizedVirtualDebtExpense,plannedVirtualDebtIncome,realizedVirtualDebtIncome,plannedVirtualInvestmentExpense,realizedVirtualInvestmentExpense,plannedVirtualInvestmentIncome,realizedVirtualInvestmentIncome);

@override
String toString() {
  return 'TransactionTotals(plannedIncomes: $plannedIncomes, realizedIncomes: $realizedIncomes, plannedExpenses: $plannedExpenses, realizedExpenses: $realizedExpenses, plannedTransfers: $plannedTransfers, realizedTransfers: $realizedTransfers, plannedInvoices: $plannedInvoices, realizedInvoices: $realizedInvoices, plannedVirtualDebtExpense: $plannedVirtualDebtExpense, realizedVirtualDebtExpense: $realizedVirtualDebtExpense, plannedVirtualDebtIncome: $plannedVirtualDebtIncome, realizedVirtualDebtIncome: $realizedVirtualDebtIncome, plannedVirtualInvestmentExpense: $plannedVirtualInvestmentExpense, realizedVirtualInvestmentExpense: $realizedVirtualInvestmentExpense, plannedVirtualInvestmentIncome: $plannedVirtualInvestmentIncome, realizedVirtualInvestmentIncome: $realizedVirtualInvestmentIncome)';
}


}

/// @nodoc
abstract mixin class _$TransactionTotalsCopyWith<$Res> implements $TransactionTotalsCopyWith<$Res> {
  factory _$TransactionTotalsCopyWith(_TransactionTotals value, $Res Function(_TransactionTotals) _then) = __$TransactionTotalsCopyWithImpl;
@override @useResult
$Res call({
 double plannedIncomes, double realizedIncomes, double plannedExpenses, double realizedExpenses, double plannedTransfers, double realizedTransfers, double plannedInvoices, double realizedInvoices, double plannedVirtualDebtExpense, double realizedVirtualDebtExpense, double plannedVirtualDebtIncome, double realizedVirtualDebtIncome, double plannedVirtualInvestmentExpense, double realizedVirtualInvestmentExpense, double plannedVirtualInvestmentIncome, double realizedVirtualInvestmentIncome
});




}
/// @nodoc
class __$TransactionTotalsCopyWithImpl<$Res>
    implements _$TransactionTotalsCopyWith<$Res> {
  __$TransactionTotalsCopyWithImpl(this._self, this._then);

  final _TransactionTotals _self;
  final $Res Function(_TransactionTotals) _then;

/// Create a copy of TransactionTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plannedIncomes = null,Object? realizedIncomes = null,Object? plannedExpenses = null,Object? realizedExpenses = null,Object? plannedTransfers = null,Object? realizedTransfers = null,Object? plannedInvoices = null,Object? realizedInvoices = null,Object? plannedVirtualDebtExpense = null,Object? realizedVirtualDebtExpense = null,Object? plannedVirtualDebtIncome = null,Object? realizedVirtualDebtIncome = null,Object? plannedVirtualInvestmentExpense = null,Object? realizedVirtualInvestmentExpense = null,Object? plannedVirtualInvestmentIncome = null,Object? realizedVirtualInvestmentIncome = null,}) {
  return _then(_TransactionTotals(
plannedIncomes: null == plannedIncomes ? _self.plannedIncomes : plannedIncomes // ignore: cast_nullable_to_non_nullable
as double,realizedIncomes: null == realizedIncomes ? _self.realizedIncomes : realizedIncomes // ignore: cast_nullable_to_non_nullable
as double,plannedExpenses: null == plannedExpenses ? _self.plannedExpenses : plannedExpenses // ignore: cast_nullable_to_non_nullable
as double,realizedExpenses: null == realizedExpenses ? _self.realizedExpenses : realizedExpenses // ignore: cast_nullable_to_non_nullable
as double,plannedTransfers: null == plannedTransfers ? _self.plannedTransfers : plannedTransfers // ignore: cast_nullable_to_non_nullable
as double,realizedTransfers: null == realizedTransfers ? _self.realizedTransfers : realizedTransfers // ignore: cast_nullable_to_non_nullable
as double,plannedInvoices: null == plannedInvoices ? _self.plannedInvoices : plannedInvoices // ignore: cast_nullable_to_non_nullable
as double,realizedInvoices: null == realizedInvoices ? _self.realizedInvoices : realizedInvoices // ignore: cast_nullable_to_non_nullable
as double,plannedVirtualDebtExpense: null == plannedVirtualDebtExpense ? _self.plannedVirtualDebtExpense : plannedVirtualDebtExpense // ignore: cast_nullable_to_non_nullable
as double,realizedVirtualDebtExpense: null == realizedVirtualDebtExpense ? _self.realizedVirtualDebtExpense : realizedVirtualDebtExpense // ignore: cast_nullable_to_non_nullable
as double,plannedVirtualDebtIncome: null == plannedVirtualDebtIncome ? _self.plannedVirtualDebtIncome : plannedVirtualDebtIncome // ignore: cast_nullable_to_non_nullable
as double,realizedVirtualDebtIncome: null == realizedVirtualDebtIncome ? _self.realizedVirtualDebtIncome : realizedVirtualDebtIncome // ignore: cast_nullable_to_non_nullable
as double,plannedVirtualInvestmentExpense: null == plannedVirtualInvestmentExpense ? _self.plannedVirtualInvestmentExpense : plannedVirtualInvestmentExpense // ignore: cast_nullable_to_non_nullable
as double,realizedVirtualInvestmentExpense: null == realizedVirtualInvestmentExpense ? _self.realizedVirtualInvestmentExpense : realizedVirtualInvestmentExpense // ignore: cast_nullable_to_non_nullable
as double,plannedVirtualInvestmentIncome: null == plannedVirtualInvestmentIncome ? _self.plannedVirtualInvestmentIncome : plannedVirtualInvestmentIncome // ignore: cast_nullable_to_non_nullable
as double,realizedVirtualInvestmentIncome: null == realizedVirtualInvestmentIncome ? _self.realizedVirtualInvestmentIncome : realizedVirtualInvestmentIncome // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$TransactionQuery {

 String? get accountId; DateTime? get startDate; DateTime? get endDate; String? get categoryId; OrderType? get type; String? get description; double? get minAmount; double? get maxAmount; InstallmentStatus? get status; bool get descending;
/// Create a copy of TransactionQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionQueryCopyWith<TransactionQuery> get copyWith => _$TransactionQueryCopyWithImpl<TransactionQuery>(this as TransactionQuery, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionQuery&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.minAmount, minAmount) || other.minAmount == minAmount)&&(identical(other.maxAmount, maxAmount) || other.maxAmount == maxAmount)&&(identical(other.status, status) || other.status == status)&&(identical(other.descending, descending) || other.descending == descending));
}


@override
int get hashCode => Object.hash(runtimeType,accountId,startDate,endDate,categoryId,type,description,minAmount,maxAmount,status,descending);

@override
String toString() {
  return 'TransactionQuery(accountId: $accountId, startDate: $startDate, endDate: $endDate, categoryId: $categoryId, type: $type, description: $description, minAmount: $minAmount, maxAmount: $maxAmount, status: $status, descending: $descending)';
}


}

/// @nodoc
abstract mixin class $TransactionQueryCopyWith<$Res>  {
  factory $TransactionQueryCopyWith(TransactionQuery value, $Res Function(TransactionQuery) _then) = _$TransactionQueryCopyWithImpl;
@useResult
$Res call({
 String? accountId, DateTime? startDate, DateTime? endDate, String? categoryId, OrderType? type, String? description, double? minAmount, double? maxAmount, InstallmentStatus? status, bool descending
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
@pragma('vm:prefer-inline') @override $Res call({Object? accountId = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? categoryId = freezed,Object? type = freezed,Object? description = freezed,Object? minAmount = freezed,Object? maxAmount = freezed,Object? status = freezed,Object? descending = null,}) {
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
as InstallmentStatus?,descending: null == descending ? _self.descending : descending // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? accountId,  DateTime? startDate,  DateTime? endDate,  String? categoryId,  OrderType? type,  String? description,  double? minAmount,  double? maxAmount,  InstallmentStatus? status,  bool descending)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionQuery() when $default != null:
return $default(_that.accountId,_that.startDate,_that.endDate,_that.categoryId,_that.type,_that.description,_that.minAmount,_that.maxAmount,_that.status,_that.descending);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? accountId,  DateTime? startDate,  DateTime? endDate,  String? categoryId,  OrderType? type,  String? description,  double? minAmount,  double? maxAmount,  InstallmentStatus? status,  bool descending)  $default,) {final _that = this;
switch (_that) {
case _TransactionQuery():
return $default(_that.accountId,_that.startDate,_that.endDate,_that.categoryId,_that.type,_that.description,_that.minAmount,_that.maxAmount,_that.status,_that.descending);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? accountId,  DateTime? startDate,  DateTime? endDate,  String? categoryId,  OrderType? type,  String? description,  double? minAmount,  double? maxAmount,  InstallmentStatus? status,  bool descending)?  $default,) {final _that = this;
switch (_that) {
case _TransactionQuery() when $default != null:
return $default(_that.accountId,_that.startDate,_that.endDate,_that.categoryId,_that.type,_that.description,_that.minAmount,_that.maxAmount,_that.status,_that.descending);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionQuery implements TransactionQuery {
   _TransactionQuery({this.accountId, this.startDate, this.endDate, this.categoryId, this.type, this.description, this.minAmount, this.maxAmount, this.status, this.descending = true});
  

@override final  String? accountId;
@override final  DateTime? startDate;
@override final  DateTime? endDate;
@override final  String? categoryId;
@override final  OrderType? type;
@override final  String? description;
@override final  double? minAmount;
@override final  double? maxAmount;
@override final  InstallmentStatus? status;
@override@JsonKey() final  bool descending;

/// Create a copy of TransactionQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionQueryCopyWith<_TransactionQuery> get copyWith => __$TransactionQueryCopyWithImpl<_TransactionQuery>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionQuery&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.minAmount, minAmount) || other.minAmount == minAmount)&&(identical(other.maxAmount, maxAmount) || other.maxAmount == maxAmount)&&(identical(other.status, status) || other.status == status)&&(identical(other.descending, descending) || other.descending == descending));
}


@override
int get hashCode => Object.hash(runtimeType,accountId,startDate,endDate,categoryId,type,description,minAmount,maxAmount,status,descending);

@override
String toString() {
  return 'TransactionQuery(accountId: $accountId, startDate: $startDate, endDate: $endDate, categoryId: $categoryId, type: $type, description: $description, minAmount: $minAmount, maxAmount: $maxAmount, status: $status, descending: $descending)';
}


}

/// @nodoc
abstract mixin class _$TransactionQueryCopyWith<$Res> implements $TransactionQueryCopyWith<$Res> {
  factory _$TransactionQueryCopyWith(_TransactionQuery value, $Res Function(_TransactionQuery) _then) = __$TransactionQueryCopyWithImpl;
@override @useResult
$Res call({
 String? accountId, DateTime? startDate, DateTime? endDate, String? categoryId, OrderType? type, String? description, double? minAmount, double? maxAmount, InstallmentStatus? status, bool descending
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
@override @pragma('vm:prefer-inline') $Res call({Object? accountId = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? categoryId = freezed,Object? type = freezed,Object? description = freezed,Object? minAmount = freezed,Object? maxAmount = freezed,Object? status = freezed,Object? descending = null,}) {
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
as InstallmentStatus?,descending: null == descending ? _self.descending : descending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
