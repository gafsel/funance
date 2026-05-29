// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'planning_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
PlanningModel _$PlanningModelFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'unique':
          return UniquePlanning.fromJson(
            json
          );
                case 'recurrent':
          return RecurrentPlanning.fromJson(
            json
          );
                case 'parcelado':
          return ParceladoPlanning.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'PlanningModel',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$PlanningModel {

 String get id; CategoryModel get category; double get amount; int? get installmentsCount; DateTime get startDate; DateTime get endDate; String? get accountId;
/// Create a copy of PlanningModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanningModelCopyWith<PlanningModel> get copyWith => _$PlanningModelCopyWithImpl<PlanningModel>(this as PlanningModel, _$identity);

  /// Serializes this PlanningModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanningModel&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.installmentsCount, installmentsCount) || other.installmentsCount == installmentsCount)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.accountId, accountId) || other.accountId == accountId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,category,amount,installmentsCount,startDate,endDate,accountId);

@override
String toString() {
  return 'PlanningModel(id: $id, category: $category, amount: $amount, installmentsCount: $installmentsCount, startDate: $startDate, endDate: $endDate, accountId: $accountId)';
}


}

/// @nodoc
abstract mixin class $PlanningModelCopyWith<$Res>  {
  factory $PlanningModelCopyWith(PlanningModel value, $Res Function(PlanningModel) _then) = _$PlanningModelCopyWithImpl;
@useResult
$Res call({
 String id, CategoryModel category, double amount, int? installmentsCount, DateTime startDate, DateTime endDate, String? accountId
});


$CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class _$PlanningModelCopyWithImpl<$Res>
    implements $PlanningModelCopyWith<$Res> {
  _$PlanningModelCopyWithImpl(this._self, this._then);

  final PlanningModel _self;
  final $Res Function(PlanningModel) _then;

/// Create a copy of PlanningModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? category = null,Object? amount = null,Object? installmentsCount = freezed,Object? startDate = null,Object? endDate = null,Object? accountId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,installmentsCount: freezed == installmentsCount ? _self.installmentsCount : installmentsCount // ignore: cast_nullable_to_non_nullable
as int?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PlanningModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlanningModel].
extension PlanningModelPatterns on PlanningModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UniquePlanning value)?  unique,TResult Function( RecurrentPlanning value)?  recurrent,TResult Function( ParceladoPlanning value)?  parcelado,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UniquePlanning() when unique != null:
return unique(_that);case RecurrentPlanning() when recurrent != null:
return recurrent(_that);case ParceladoPlanning() when parcelado != null:
return parcelado(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UniquePlanning value)  unique,required TResult Function( RecurrentPlanning value)  recurrent,required TResult Function( ParceladoPlanning value)  parcelado,}){
final _that = this;
switch (_that) {
case UniquePlanning():
return unique(_that);case RecurrentPlanning():
return recurrent(_that);case ParceladoPlanning():
return parcelado(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UniquePlanning value)?  unique,TResult? Function( RecurrentPlanning value)?  recurrent,TResult? Function( ParceladoPlanning value)?  parcelado,}){
final _that = this;
switch (_that) {
case UniquePlanning() when unique != null:
return unique(_that);case RecurrentPlanning() when recurrent != null:
return recurrent(_that);case ParceladoPlanning() when parcelado != null:
return parcelado(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  CategoryModel category,  double amount,  int? installmentsCount,  DateTime startDate,  DateTime endDate,  String? accountId)?  unique,TResult Function( String id,  CategoryModel category,  double amount,  int? installmentsCount,  DateTime startDate,  DateTime endDate,  String? accountId)?  recurrent,TResult Function( String id,  CategoryModel category,  double amount,  int? installmentsCount,  DateTime startDate,  DateTime endDate,  String? accountId)?  parcelado,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UniquePlanning() when unique != null:
return unique(_that.id,_that.category,_that.amount,_that.installmentsCount,_that.startDate,_that.endDate,_that.accountId);case RecurrentPlanning() when recurrent != null:
return recurrent(_that.id,_that.category,_that.amount,_that.installmentsCount,_that.startDate,_that.endDate,_that.accountId);case ParceladoPlanning() when parcelado != null:
return parcelado(_that.id,_that.category,_that.amount,_that.installmentsCount,_that.startDate,_that.endDate,_that.accountId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  CategoryModel category,  double amount,  int? installmentsCount,  DateTime startDate,  DateTime endDate,  String? accountId)  unique,required TResult Function( String id,  CategoryModel category,  double amount,  int? installmentsCount,  DateTime startDate,  DateTime endDate,  String? accountId)  recurrent,required TResult Function( String id,  CategoryModel category,  double amount,  int? installmentsCount,  DateTime startDate,  DateTime endDate,  String? accountId)  parcelado,}) {final _that = this;
switch (_that) {
case UniquePlanning():
return unique(_that.id,_that.category,_that.amount,_that.installmentsCount,_that.startDate,_that.endDate,_that.accountId);case RecurrentPlanning():
return recurrent(_that.id,_that.category,_that.amount,_that.installmentsCount,_that.startDate,_that.endDate,_that.accountId);case ParceladoPlanning():
return parcelado(_that.id,_that.category,_that.amount,_that.installmentsCount,_that.startDate,_that.endDate,_that.accountId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  CategoryModel category,  double amount,  int? installmentsCount,  DateTime startDate,  DateTime endDate,  String? accountId)?  unique,TResult? Function( String id,  CategoryModel category,  double amount,  int? installmentsCount,  DateTime startDate,  DateTime endDate,  String? accountId)?  recurrent,TResult? Function( String id,  CategoryModel category,  double amount,  int? installmentsCount,  DateTime startDate,  DateTime endDate,  String? accountId)?  parcelado,}) {final _that = this;
switch (_that) {
case UniquePlanning() when unique != null:
return unique(_that.id,_that.category,_that.amount,_that.installmentsCount,_that.startDate,_that.endDate,_that.accountId);case RecurrentPlanning() when recurrent != null:
return recurrent(_that.id,_that.category,_that.amount,_that.installmentsCount,_that.startDate,_that.endDate,_that.accountId);case ParceladoPlanning() when parcelado != null:
return parcelado(_that.id,_that.category,_that.amount,_that.installmentsCount,_that.startDate,_that.endDate,_that.accountId);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class UniquePlanning extends PlanningModel {
  const UniquePlanning({required this.id, required this.category, required this.amount, this.installmentsCount, required this.startDate, required this.endDate, this.accountId, final  String? $type}): $type = $type ?? 'unique',super._();
  factory UniquePlanning.fromJson(Map<String, dynamic> json) => _$UniquePlanningFromJson(json);

@override final  String id;
@override final  CategoryModel category;
@override final  double amount;
@override final  int? installmentsCount;
@override final  DateTime startDate;
@override final  DateTime endDate;
@override final  String? accountId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of PlanningModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UniquePlanningCopyWith<UniquePlanning> get copyWith => _$UniquePlanningCopyWithImpl<UniquePlanning>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UniquePlanningToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UniquePlanning&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.installmentsCount, installmentsCount) || other.installmentsCount == installmentsCount)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.accountId, accountId) || other.accountId == accountId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,category,amount,installmentsCount,startDate,endDate,accountId);

@override
String toString() {
  return 'PlanningModel.unique(id: $id, category: $category, amount: $amount, installmentsCount: $installmentsCount, startDate: $startDate, endDate: $endDate, accountId: $accountId)';
}


}

/// @nodoc
abstract mixin class $UniquePlanningCopyWith<$Res> implements $PlanningModelCopyWith<$Res> {
  factory $UniquePlanningCopyWith(UniquePlanning value, $Res Function(UniquePlanning) _then) = _$UniquePlanningCopyWithImpl;
@override @useResult
$Res call({
 String id, CategoryModel category, double amount, int? installmentsCount, DateTime startDate, DateTime endDate, String? accountId
});


@override $CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class _$UniquePlanningCopyWithImpl<$Res>
    implements $UniquePlanningCopyWith<$Res> {
  _$UniquePlanningCopyWithImpl(this._self, this._then);

  final UniquePlanning _self;
  final $Res Function(UniquePlanning) _then;

/// Create a copy of PlanningModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? amount = null,Object? installmentsCount = freezed,Object? startDate = null,Object? endDate = null,Object? accountId = freezed,}) {
  return _then(UniquePlanning(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,installmentsCount: freezed == installmentsCount ? _self.installmentsCount : installmentsCount // ignore: cast_nullable_to_non_nullable
as int?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PlanningModel
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

@JsonSerializable(explicitToJson: true)
class RecurrentPlanning extends PlanningModel {
  const RecurrentPlanning({required this.id, required this.category, required this.amount, this.installmentsCount, required this.startDate, required this.endDate, this.accountId, final  String? $type}): $type = $type ?? 'recurrent',super._();
  factory RecurrentPlanning.fromJson(Map<String, dynamic> json) => _$RecurrentPlanningFromJson(json);

@override final  String id;
@override final  CategoryModel category;
@override final  double amount;
@override final  int? installmentsCount;
@override final  DateTime startDate;
@override final  DateTime endDate;
@override final  String? accountId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of PlanningModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurrentPlanningCopyWith<RecurrentPlanning> get copyWith => _$RecurrentPlanningCopyWithImpl<RecurrentPlanning>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecurrentPlanningToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurrentPlanning&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.installmentsCount, installmentsCount) || other.installmentsCount == installmentsCount)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.accountId, accountId) || other.accountId == accountId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,category,amount,installmentsCount,startDate,endDate,accountId);

@override
String toString() {
  return 'PlanningModel.recurrent(id: $id, category: $category, amount: $amount, installmentsCount: $installmentsCount, startDate: $startDate, endDate: $endDate, accountId: $accountId)';
}


}

/// @nodoc
abstract mixin class $RecurrentPlanningCopyWith<$Res> implements $PlanningModelCopyWith<$Res> {
  factory $RecurrentPlanningCopyWith(RecurrentPlanning value, $Res Function(RecurrentPlanning) _then) = _$RecurrentPlanningCopyWithImpl;
@override @useResult
$Res call({
 String id, CategoryModel category, double amount, int? installmentsCount, DateTime startDate, DateTime endDate, String? accountId
});


@override $CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class _$RecurrentPlanningCopyWithImpl<$Res>
    implements $RecurrentPlanningCopyWith<$Res> {
  _$RecurrentPlanningCopyWithImpl(this._self, this._then);

  final RecurrentPlanning _self;
  final $Res Function(RecurrentPlanning) _then;

/// Create a copy of PlanningModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? amount = null,Object? installmentsCount = freezed,Object? startDate = null,Object? endDate = null,Object? accountId = freezed,}) {
  return _then(RecurrentPlanning(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,installmentsCount: freezed == installmentsCount ? _self.installmentsCount : installmentsCount // ignore: cast_nullable_to_non_nullable
as int?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PlanningModel
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

@JsonSerializable(explicitToJson: true)
class ParceladoPlanning extends PlanningModel {
  const ParceladoPlanning({required this.id, required this.category, required this.amount, this.installmentsCount, required this.startDate, required this.endDate, this.accountId, final  String? $type}): $type = $type ?? 'parcelado',super._();
  factory ParceladoPlanning.fromJson(Map<String, dynamic> json) => _$ParceladoPlanningFromJson(json);

@override final  String id;
@override final  CategoryModel category;
@override final  double amount;
@override final  int? installmentsCount;
@override final  DateTime startDate;
@override final  DateTime endDate;
@override final  String? accountId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of PlanningModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParceladoPlanningCopyWith<ParceladoPlanning> get copyWith => _$ParceladoPlanningCopyWithImpl<ParceladoPlanning>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParceladoPlanningToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParceladoPlanning&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.installmentsCount, installmentsCount) || other.installmentsCount == installmentsCount)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.accountId, accountId) || other.accountId == accountId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,category,amount,installmentsCount,startDate,endDate,accountId);

@override
String toString() {
  return 'PlanningModel.parcelado(id: $id, category: $category, amount: $amount, installmentsCount: $installmentsCount, startDate: $startDate, endDate: $endDate, accountId: $accountId)';
}


}

/// @nodoc
abstract mixin class $ParceladoPlanningCopyWith<$Res> implements $PlanningModelCopyWith<$Res> {
  factory $ParceladoPlanningCopyWith(ParceladoPlanning value, $Res Function(ParceladoPlanning) _then) = _$ParceladoPlanningCopyWithImpl;
@override @useResult
$Res call({
 String id, CategoryModel category, double amount, int? installmentsCount, DateTime startDate, DateTime endDate, String? accountId
});


@override $CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class _$ParceladoPlanningCopyWithImpl<$Res>
    implements $ParceladoPlanningCopyWith<$Res> {
  _$ParceladoPlanningCopyWithImpl(this._self, this._then);

  final ParceladoPlanning _self;
  final $Res Function(ParceladoPlanning) _then;

/// Create a copy of PlanningModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? amount = null,Object? installmentsCount = freezed,Object? startDate = null,Object? endDate = null,Object? accountId = freezed,}) {
  return _then(ParceladoPlanning(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,installmentsCount: freezed == installmentsCount ? _self.installmentsCount : installmentsCount // ignore: cast_nullable_to_non_nullable
as int?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PlanningModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryModelCopyWith<$Res> get category {
  
  return $CategoryModelCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

// dart format on
