// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'planning_503020_analysis.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Planning503020AnalysisGroup {

 CategoryAllocation get allocation; double get currentPct; double get targetPct; double get deltaBRL;
/// Create a copy of Planning503020AnalysisGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Planning503020AnalysisGroupCopyWith<Planning503020AnalysisGroup> get copyWith => _$Planning503020AnalysisGroupCopyWithImpl<Planning503020AnalysisGroup>(this as Planning503020AnalysisGroup, _$identity);

  /// Serializes this Planning503020AnalysisGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Planning503020AnalysisGroup&&(identical(other.allocation, allocation) || other.allocation == allocation)&&(identical(other.currentPct, currentPct) || other.currentPct == currentPct)&&(identical(other.targetPct, targetPct) || other.targetPct == targetPct)&&(identical(other.deltaBRL, deltaBRL) || other.deltaBRL == deltaBRL));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,allocation,currentPct,targetPct,deltaBRL);

@override
String toString() {
  return 'Planning503020AnalysisGroup(allocation: $allocation, currentPct: $currentPct, targetPct: $targetPct, deltaBRL: $deltaBRL)';
}


}

/// @nodoc
abstract mixin class $Planning503020AnalysisGroupCopyWith<$Res>  {
  factory $Planning503020AnalysisGroupCopyWith(Planning503020AnalysisGroup value, $Res Function(Planning503020AnalysisGroup) _then) = _$Planning503020AnalysisGroupCopyWithImpl;
@useResult
$Res call({
 CategoryAllocation allocation, double currentPct, double targetPct, double deltaBRL
});




}
/// @nodoc
class _$Planning503020AnalysisGroupCopyWithImpl<$Res>
    implements $Planning503020AnalysisGroupCopyWith<$Res> {
  _$Planning503020AnalysisGroupCopyWithImpl(this._self, this._then);

  final Planning503020AnalysisGroup _self;
  final $Res Function(Planning503020AnalysisGroup) _then;

/// Create a copy of Planning503020AnalysisGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? allocation = null,Object? currentPct = null,Object? targetPct = null,Object? deltaBRL = null,}) {
  return _then(_self.copyWith(
allocation: null == allocation ? _self.allocation : allocation // ignore: cast_nullable_to_non_nullable
as CategoryAllocation,currentPct: null == currentPct ? _self.currentPct : currentPct // ignore: cast_nullable_to_non_nullable
as double,targetPct: null == targetPct ? _self.targetPct : targetPct // ignore: cast_nullable_to_non_nullable
as double,deltaBRL: null == deltaBRL ? _self.deltaBRL : deltaBRL // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Planning503020AnalysisGroup].
extension Planning503020AnalysisGroupPatterns on Planning503020AnalysisGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Planning503020AnalysisGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Planning503020AnalysisGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Planning503020AnalysisGroup value)  $default,){
final _that = this;
switch (_that) {
case _Planning503020AnalysisGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Planning503020AnalysisGroup value)?  $default,){
final _that = this;
switch (_that) {
case _Planning503020AnalysisGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CategoryAllocation allocation,  double currentPct,  double targetPct,  double deltaBRL)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Planning503020AnalysisGroup() when $default != null:
return $default(_that.allocation,_that.currentPct,_that.targetPct,_that.deltaBRL);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CategoryAllocation allocation,  double currentPct,  double targetPct,  double deltaBRL)  $default,) {final _that = this;
switch (_that) {
case _Planning503020AnalysisGroup():
return $default(_that.allocation,_that.currentPct,_that.targetPct,_that.deltaBRL);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CategoryAllocation allocation,  double currentPct,  double targetPct,  double deltaBRL)?  $default,) {final _that = this;
switch (_that) {
case _Planning503020AnalysisGroup() when $default != null:
return $default(_that.allocation,_that.currentPct,_that.targetPct,_that.deltaBRL);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Planning503020AnalysisGroup implements Planning503020AnalysisGroup {
  const _Planning503020AnalysisGroup({required this.allocation, this.currentPct = 0.0, this.targetPct = 0.0, this.deltaBRL = 0.0});
  factory _Planning503020AnalysisGroup.fromJson(Map<String, dynamic> json) => _$Planning503020AnalysisGroupFromJson(json);

@override final  CategoryAllocation allocation;
@override@JsonKey() final  double currentPct;
@override@JsonKey() final  double targetPct;
@override@JsonKey() final  double deltaBRL;

/// Create a copy of Planning503020AnalysisGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Planning503020AnalysisGroupCopyWith<_Planning503020AnalysisGroup> get copyWith => __$Planning503020AnalysisGroupCopyWithImpl<_Planning503020AnalysisGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Planning503020AnalysisGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Planning503020AnalysisGroup&&(identical(other.allocation, allocation) || other.allocation == allocation)&&(identical(other.currentPct, currentPct) || other.currentPct == currentPct)&&(identical(other.targetPct, targetPct) || other.targetPct == targetPct)&&(identical(other.deltaBRL, deltaBRL) || other.deltaBRL == deltaBRL));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,allocation,currentPct,targetPct,deltaBRL);

@override
String toString() {
  return 'Planning503020AnalysisGroup(allocation: $allocation, currentPct: $currentPct, targetPct: $targetPct, deltaBRL: $deltaBRL)';
}


}

/// @nodoc
abstract mixin class _$Planning503020AnalysisGroupCopyWith<$Res> implements $Planning503020AnalysisGroupCopyWith<$Res> {
  factory _$Planning503020AnalysisGroupCopyWith(_Planning503020AnalysisGroup value, $Res Function(_Planning503020AnalysisGroup) _then) = __$Planning503020AnalysisGroupCopyWithImpl;
@override @useResult
$Res call({
 CategoryAllocation allocation, double currentPct, double targetPct, double deltaBRL
});




}
/// @nodoc
class __$Planning503020AnalysisGroupCopyWithImpl<$Res>
    implements _$Planning503020AnalysisGroupCopyWith<$Res> {
  __$Planning503020AnalysisGroupCopyWithImpl(this._self, this._then);

  final _Planning503020AnalysisGroup _self;
  final $Res Function(_Planning503020AnalysisGroup) _then;

/// Create a copy of Planning503020AnalysisGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? allocation = null,Object? currentPct = null,Object? targetPct = null,Object? deltaBRL = null,}) {
  return _then(_Planning503020AnalysisGroup(
allocation: null == allocation ? _self.allocation : allocation // ignore: cast_nullable_to_non_nullable
as CategoryAllocation,currentPct: null == currentPct ? _self.currentPct : currentPct // ignore: cast_nullable_to_non_nullable
as double,targetPct: null == targetPct ? _self.targetPct : targetPct // ignore: cast_nullable_to_non_nullable
as double,deltaBRL: null == deltaBRL ? _self.deltaBRL : deltaBRL // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$Planning503020AnalysisCategory {

 String get categoryId; String get categoryName; double get idealMonthlyAmount; double get idealPctOfIncome; Planning503020AnalysisStatus get status; CategoryAllocation get currentAllocation; CategoryAllocation? get suggestedAllocation; bool get shouldReclassify; String get reason; String? get savingTip; double get plannedAmount; double get actualAmount;
/// Create a copy of Planning503020AnalysisCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Planning503020AnalysisCategoryCopyWith<Planning503020AnalysisCategory> get copyWith => _$Planning503020AnalysisCategoryCopyWithImpl<Planning503020AnalysisCategory>(this as Planning503020AnalysisCategory, _$identity);

  /// Serializes this Planning503020AnalysisCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Planning503020AnalysisCategory&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.idealMonthlyAmount, idealMonthlyAmount) || other.idealMonthlyAmount == idealMonthlyAmount)&&(identical(other.idealPctOfIncome, idealPctOfIncome) || other.idealPctOfIncome == idealPctOfIncome)&&(identical(other.status, status) || other.status == status)&&(identical(other.currentAllocation, currentAllocation) || other.currentAllocation == currentAllocation)&&(identical(other.suggestedAllocation, suggestedAllocation) || other.suggestedAllocation == suggestedAllocation)&&(identical(other.shouldReclassify, shouldReclassify) || other.shouldReclassify == shouldReclassify)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.savingTip, savingTip) || other.savingTip == savingTip)&&(identical(other.plannedAmount, plannedAmount) || other.plannedAmount == plannedAmount)&&(identical(other.actualAmount, actualAmount) || other.actualAmount == actualAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,categoryId,categoryName,idealMonthlyAmount,idealPctOfIncome,status,currentAllocation,suggestedAllocation,shouldReclassify,reason,savingTip,plannedAmount,actualAmount);

@override
String toString() {
  return 'Planning503020AnalysisCategory(categoryId: $categoryId, categoryName: $categoryName, idealMonthlyAmount: $idealMonthlyAmount, idealPctOfIncome: $idealPctOfIncome, status: $status, currentAllocation: $currentAllocation, suggestedAllocation: $suggestedAllocation, shouldReclassify: $shouldReclassify, reason: $reason, savingTip: $savingTip, plannedAmount: $plannedAmount, actualAmount: $actualAmount)';
}


}

/// @nodoc
abstract mixin class $Planning503020AnalysisCategoryCopyWith<$Res>  {
  factory $Planning503020AnalysisCategoryCopyWith(Planning503020AnalysisCategory value, $Res Function(Planning503020AnalysisCategory) _then) = _$Planning503020AnalysisCategoryCopyWithImpl;
@useResult
$Res call({
 String categoryId, String categoryName, double idealMonthlyAmount, double idealPctOfIncome, Planning503020AnalysisStatus status, CategoryAllocation currentAllocation, CategoryAllocation? suggestedAllocation, bool shouldReclassify, String reason, String? savingTip, double plannedAmount, double actualAmount
});




}
/// @nodoc
class _$Planning503020AnalysisCategoryCopyWithImpl<$Res>
    implements $Planning503020AnalysisCategoryCopyWith<$Res> {
  _$Planning503020AnalysisCategoryCopyWithImpl(this._self, this._then);

  final Planning503020AnalysisCategory _self;
  final $Res Function(Planning503020AnalysisCategory) _then;

/// Create a copy of Planning503020AnalysisCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryId = null,Object? categoryName = null,Object? idealMonthlyAmount = null,Object? idealPctOfIncome = null,Object? status = null,Object? currentAllocation = null,Object? suggestedAllocation = freezed,Object? shouldReclassify = null,Object? reason = null,Object? savingTip = freezed,Object? plannedAmount = null,Object? actualAmount = null,}) {
  return _then(_self.copyWith(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,idealMonthlyAmount: null == idealMonthlyAmount ? _self.idealMonthlyAmount : idealMonthlyAmount // ignore: cast_nullable_to_non_nullable
as double,idealPctOfIncome: null == idealPctOfIncome ? _self.idealPctOfIncome : idealPctOfIncome // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Planning503020AnalysisStatus,currentAllocation: null == currentAllocation ? _self.currentAllocation : currentAllocation // ignore: cast_nullable_to_non_nullable
as CategoryAllocation,suggestedAllocation: freezed == suggestedAllocation ? _self.suggestedAllocation : suggestedAllocation // ignore: cast_nullable_to_non_nullable
as CategoryAllocation?,shouldReclassify: null == shouldReclassify ? _self.shouldReclassify : shouldReclassify // ignore: cast_nullable_to_non_nullable
as bool,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,savingTip: freezed == savingTip ? _self.savingTip : savingTip // ignore: cast_nullable_to_non_nullable
as String?,plannedAmount: null == plannedAmount ? _self.plannedAmount : plannedAmount // ignore: cast_nullable_to_non_nullable
as double,actualAmount: null == actualAmount ? _self.actualAmount : actualAmount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Planning503020AnalysisCategory].
extension Planning503020AnalysisCategoryPatterns on Planning503020AnalysisCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Planning503020AnalysisCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Planning503020AnalysisCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Planning503020AnalysisCategory value)  $default,){
final _that = this;
switch (_that) {
case _Planning503020AnalysisCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Planning503020AnalysisCategory value)?  $default,){
final _that = this;
switch (_that) {
case _Planning503020AnalysisCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String categoryId,  String categoryName,  double idealMonthlyAmount,  double idealPctOfIncome,  Planning503020AnalysisStatus status,  CategoryAllocation currentAllocation,  CategoryAllocation? suggestedAllocation,  bool shouldReclassify,  String reason,  String? savingTip,  double plannedAmount,  double actualAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Planning503020AnalysisCategory() when $default != null:
return $default(_that.categoryId,_that.categoryName,_that.idealMonthlyAmount,_that.idealPctOfIncome,_that.status,_that.currentAllocation,_that.suggestedAllocation,_that.shouldReclassify,_that.reason,_that.savingTip,_that.plannedAmount,_that.actualAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String categoryId,  String categoryName,  double idealMonthlyAmount,  double idealPctOfIncome,  Planning503020AnalysisStatus status,  CategoryAllocation currentAllocation,  CategoryAllocation? suggestedAllocation,  bool shouldReclassify,  String reason,  String? savingTip,  double plannedAmount,  double actualAmount)  $default,) {final _that = this;
switch (_that) {
case _Planning503020AnalysisCategory():
return $default(_that.categoryId,_that.categoryName,_that.idealMonthlyAmount,_that.idealPctOfIncome,_that.status,_that.currentAllocation,_that.suggestedAllocation,_that.shouldReclassify,_that.reason,_that.savingTip,_that.plannedAmount,_that.actualAmount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String categoryId,  String categoryName,  double idealMonthlyAmount,  double idealPctOfIncome,  Planning503020AnalysisStatus status,  CategoryAllocation currentAllocation,  CategoryAllocation? suggestedAllocation,  bool shouldReclassify,  String reason,  String? savingTip,  double plannedAmount,  double actualAmount)?  $default,) {final _that = this;
switch (_that) {
case _Planning503020AnalysisCategory() when $default != null:
return $default(_that.categoryId,_that.categoryName,_that.idealMonthlyAmount,_that.idealPctOfIncome,_that.status,_that.currentAllocation,_that.suggestedAllocation,_that.shouldReclassify,_that.reason,_that.savingTip,_that.plannedAmount,_that.actualAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Planning503020AnalysisCategory extends Planning503020AnalysisCategory {
  const _Planning503020AnalysisCategory({required this.categoryId, this.categoryName = '', this.idealMonthlyAmount = 0.0, this.idealPctOfIncome = 0.0, this.status = Planning503020AnalysisStatus.ok, this.currentAllocation = CategoryAllocation.comfort, this.suggestedAllocation, this.shouldReclassify = false, this.reason = '', this.savingTip, this.plannedAmount = 0.0, this.actualAmount = 0.0}): super._();
  factory _Planning503020AnalysisCategory.fromJson(Map<String, dynamic> json) => _$Planning503020AnalysisCategoryFromJson(json);

@override final  String categoryId;
@override@JsonKey() final  String categoryName;
@override@JsonKey() final  double idealMonthlyAmount;
@override@JsonKey() final  double idealPctOfIncome;
@override@JsonKey() final  Planning503020AnalysisStatus status;
@override@JsonKey() final  CategoryAllocation currentAllocation;
@override final  CategoryAllocation? suggestedAllocation;
@override@JsonKey() final  bool shouldReclassify;
@override@JsonKey() final  String reason;
@override final  String? savingTip;
@override@JsonKey() final  double plannedAmount;
@override@JsonKey() final  double actualAmount;

/// Create a copy of Planning503020AnalysisCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Planning503020AnalysisCategoryCopyWith<_Planning503020AnalysisCategory> get copyWith => __$Planning503020AnalysisCategoryCopyWithImpl<_Planning503020AnalysisCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Planning503020AnalysisCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Planning503020AnalysisCategory&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.idealMonthlyAmount, idealMonthlyAmount) || other.idealMonthlyAmount == idealMonthlyAmount)&&(identical(other.idealPctOfIncome, idealPctOfIncome) || other.idealPctOfIncome == idealPctOfIncome)&&(identical(other.status, status) || other.status == status)&&(identical(other.currentAllocation, currentAllocation) || other.currentAllocation == currentAllocation)&&(identical(other.suggestedAllocation, suggestedAllocation) || other.suggestedAllocation == suggestedAllocation)&&(identical(other.shouldReclassify, shouldReclassify) || other.shouldReclassify == shouldReclassify)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.savingTip, savingTip) || other.savingTip == savingTip)&&(identical(other.plannedAmount, plannedAmount) || other.plannedAmount == plannedAmount)&&(identical(other.actualAmount, actualAmount) || other.actualAmount == actualAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,categoryId,categoryName,idealMonthlyAmount,idealPctOfIncome,status,currentAllocation,suggestedAllocation,shouldReclassify,reason,savingTip,plannedAmount,actualAmount);

@override
String toString() {
  return 'Planning503020AnalysisCategory(categoryId: $categoryId, categoryName: $categoryName, idealMonthlyAmount: $idealMonthlyAmount, idealPctOfIncome: $idealPctOfIncome, status: $status, currentAllocation: $currentAllocation, suggestedAllocation: $suggestedAllocation, shouldReclassify: $shouldReclassify, reason: $reason, savingTip: $savingTip, plannedAmount: $plannedAmount, actualAmount: $actualAmount)';
}


}

/// @nodoc
abstract mixin class _$Planning503020AnalysisCategoryCopyWith<$Res> implements $Planning503020AnalysisCategoryCopyWith<$Res> {
  factory _$Planning503020AnalysisCategoryCopyWith(_Planning503020AnalysisCategory value, $Res Function(_Planning503020AnalysisCategory) _then) = __$Planning503020AnalysisCategoryCopyWithImpl;
@override @useResult
$Res call({
 String categoryId, String categoryName, double idealMonthlyAmount, double idealPctOfIncome, Planning503020AnalysisStatus status, CategoryAllocation currentAllocation, CategoryAllocation? suggestedAllocation, bool shouldReclassify, String reason, String? savingTip, double plannedAmount, double actualAmount
});




}
/// @nodoc
class __$Planning503020AnalysisCategoryCopyWithImpl<$Res>
    implements _$Planning503020AnalysisCategoryCopyWith<$Res> {
  __$Planning503020AnalysisCategoryCopyWithImpl(this._self, this._then);

  final _Planning503020AnalysisCategory _self;
  final $Res Function(_Planning503020AnalysisCategory) _then;

/// Create a copy of Planning503020AnalysisCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryId = null,Object? categoryName = null,Object? idealMonthlyAmount = null,Object? idealPctOfIncome = null,Object? status = null,Object? currentAllocation = null,Object? suggestedAllocation = freezed,Object? shouldReclassify = null,Object? reason = null,Object? savingTip = freezed,Object? plannedAmount = null,Object? actualAmount = null,}) {
  return _then(_Planning503020AnalysisCategory(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,idealMonthlyAmount: null == idealMonthlyAmount ? _self.idealMonthlyAmount : idealMonthlyAmount // ignore: cast_nullable_to_non_nullable
as double,idealPctOfIncome: null == idealPctOfIncome ? _self.idealPctOfIncome : idealPctOfIncome // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Planning503020AnalysisStatus,currentAllocation: null == currentAllocation ? _self.currentAllocation : currentAllocation // ignore: cast_nullable_to_non_nullable
as CategoryAllocation,suggestedAllocation: freezed == suggestedAllocation ? _self.suggestedAllocation : suggestedAllocation // ignore: cast_nullable_to_non_nullable
as CategoryAllocation?,shouldReclassify: null == shouldReclassify ? _self.shouldReclassify : shouldReclassify // ignore: cast_nullable_to_non_nullable
as bool,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,savingTip: freezed == savingTip ? _self.savingTip : savingTip // ignore: cast_nullable_to_non_nullable
as String?,plannedAmount: null == plannedAmount ? _self.plannedAmount : plannedAmount // ignore: cast_nullable_to_non_nullable
as double,actualAmount: null == actualAmount ? _self.actualAmount : actualAmount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$Planning503020Analysis {

 String get id; String get month; String get summary; double get projectedIncome; List<Planning503020AnalysisGroup> get groups; List<Planning503020AnalysisCategory> get categories; List<String> get insights;// Quando o servidor gerou esta análise (ISO-8601). Análises antigas,
// persistidas antes deste campo existir, vêm nulas.
 DateTime? get createdAt;
/// Create a copy of Planning503020Analysis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Planning503020AnalysisCopyWith<Planning503020Analysis> get copyWith => _$Planning503020AnalysisCopyWithImpl<Planning503020Analysis>(this as Planning503020Analysis, _$identity);

  /// Serializes this Planning503020Analysis to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Planning503020Analysis&&(identical(other.id, id) || other.id == id)&&(identical(other.month, month) || other.month == month)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.projectedIncome, projectedIncome) || other.projectedIncome == projectedIncome)&&const DeepCollectionEquality().equals(other.groups, groups)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.insights, insights)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,month,summary,projectedIncome,const DeepCollectionEquality().hash(groups),const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(insights),createdAt);

@override
String toString() {
  return 'Planning503020Analysis(id: $id, month: $month, summary: $summary, projectedIncome: $projectedIncome, groups: $groups, categories: $categories, insights: $insights, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $Planning503020AnalysisCopyWith<$Res>  {
  factory $Planning503020AnalysisCopyWith(Planning503020Analysis value, $Res Function(Planning503020Analysis) _then) = _$Planning503020AnalysisCopyWithImpl;
@useResult
$Res call({
 String id, String month, String summary, double projectedIncome, List<Planning503020AnalysisGroup> groups, List<Planning503020AnalysisCategory> categories, List<String> insights, DateTime? createdAt
});




}
/// @nodoc
class _$Planning503020AnalysisCopyWithImpl<$Res>
    implements $Planning503020AnalysisCopyWith<$Res> {
  _$Planning503020AnalysisCopyWithImpl(this._self, this._then);

  final Planning503020Analysis _self;
  final $Res Function(Planning503020Analysis) _then;

/// Create a copy of Planning503020Analysis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? month = null,Object? summary = null,Object? projectedIncome = null,Object? groups = null,Object? categories = null,Object? insights = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,projectedIncome: null == projectedIncome ? _self.projectedIncome : projectedIncome // ignore: cast_nullable_to_non_nullable
as double,groups: null == groups ? _self.groups : groups // ignore: cast_nullable_to_non_nullable
as List<Planning503020AnalysisGroup>,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<Planning503020AnalysisCategory>,insights: null == insights ? _self.insights : insights // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Planning503020Analysis].
extension Planning503020AnalysisPatterns on Planning503020Analysis {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Planning503020Analysis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Planning503020Analysis() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Planning503020Analysis value)  $default,){
final _that = this;
switch (_that) {
case _Planning503020Analysis():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Planning503020Analysis value)?  $default,){
final _that = this;
switch (_that) {
case _Planning503020Analysis() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String month,  String summary,  double projectedIncome,  List<Planning503020AnalysisGroup> groups,  List<Planning503020AnalysisCategory> categories,  List<String> insights,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Planning503020Analysis() when $default != null:
return $default(_that.id,_that.month,_that.summary,_that.projectedIncome,_that.groups,_that.categories,_that.insights,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String month,  String summary,  double projectedIncome,  List<Planning503020AnalysisGroup> groups,  List<Planning503020AnalysisCategory> categories,  List<String> insights,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Planning503020Analysis():
return $default(_that.id,_that.month,_that.summary,_that.projectedIncome,_that.groups,_that.categories,_that.insights,_that.createdAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String month,  String summary,  double projectedIncome,  List<Planning503020AnalysisGroup> groups,  List<Planning503020AnalysisCategory> categories,  List<String> insights,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Planning503020Analysis() when $default != null:
return $default(_that.id,_that.month,_that.summary,_that.projectedIncome,_that.groups,_that.categories,_that.insights,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Planning503020Analysis extends Planning503020Analysis {
  const _Planning503020Analysis({required this.id, this.month = '', this.summary = '', this.projectedIncome = 0.0, final  List<Planning503020AnalysisGroup> groups = const [], final  List<Planning503020AnalysisCategory> categories = const [], final  List<String> insights = const [], this.createdAt}): _groups = groups,_categories = categories,_insights = insights,super._();
  factory _Planning503020Analysis.fromJson(Map<String, dynamic> json) => _$Planning503020AnalysisFromJson(json);

@override final  String id;
@override@JsonKey() final  String month;
@override@JsonKey() final  String summary;
@override@JsonKey() final  double projectedIncome;
 final  List<Planning503020AnalysisGroup> _groups;
@override@JsonKey() List<Planning503020AnalysisGroup> get groups {
  if (_groups is EqualUnmodifiableListView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_groups);
}

 final  List<Planning503020AnalysisCategory> _categories;
@override@JsonKey() List<Planning503020AnalysisCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<String> _insights;
@override@JsonKey() List<String> get insights {
  if (_insights is EqualUnmodifiableListView) return _insights;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_insights);
}

// Quando o servidor gerou esta análise (ISO-8601). Análises antigas,
// persistidas antes deste campo existir, vêm nulas.
@override final  DateTime? createdAt;

/// Create a copy of Planning503020Analysis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Planning503020AnalysisCopyWith<_Planning503020Analysis> get copyWith => __$Planning503020AnalysisCopyWithImpl<_Planning503020Analysis>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Planning503020AnalysisToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Planning503020Analysis&&(identical(other.id, id) || other.id == id)&&(identical(other.month, month) || other.month == month)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.projectedIncome, projectedIncome) || other.projectedIncome == projectedIncome)&&const DeepCollectionEquality().equals(other._groups, _groups)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._insights, _insights)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,month,summary,projectedIncome,const DeepCollectionEquality().hash(_groups),const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_insights),createdAt);

@override
String toString() {
  return 'Planning503020Analysis(id: $id, month: $month, summary: $summary, projectedIncome: $projectedIncome, groups: $groups, categories: $categories, insights: $insights, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$Planning503020AnalysisCopyWith<$Res> implements $Planning503020AnalysisCopyWith<$Res> {
  factory _$Planning503020AnalysisCopyWith(_Planning503020Analysis value, $Res Function(_Planning503020Analysis) _then) = __$Planning503020AnalysisCopyWithImpl;
@override @useResult
$Res call({
 String id, String month, String summary, double projectedIncome, List<Planning503020AnalysisGroup> groups, List<Planning503020AnalysisCategory> categories, List<String> insights, DateTime? createdAt
});




}
/// @nodoc
class __$Planning503020AnalysisCopyWithImpl<$Res>
    implements _$Planning503020AnalysisCopyWith<$Res> {
  __$Planning503020AnalysisCopyWithImpl(this._self, this._then);

  final _Planning503020Analysis _self;
  final $Res Function(_Planning503020Analysis) _then;

/// Create a copy of Planning503020Analysis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? month = null,Object? summary = null,Object? projectedIncome = null,Object? groups = null,Object? categories = null,Object? insights = null,Object? createdAt = freezed,}) {
  return _then(_Planning503020Analysis(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,projectedIncome: null == projectedIncome ? _self.projectedIncome : projectedIncome // ignore: cast_nullable_to_non_nullable
as double,groups: null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as List<Planning503020AnalysisGroup>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<Planning503020AnalysisCategory>,insights: null == insights ? _self._insights : insights // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
