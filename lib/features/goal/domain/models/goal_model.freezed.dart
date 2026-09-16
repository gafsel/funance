// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'goal_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GoalProgress {

 double get percent; double get predictionPercent; GoalStatus get status; bool get isLost;
/// Create a copy of GoalProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GoalProgressCopyWith<GoalProgress> get copyWith => _$GoalProgressCopyWithImpl<GoalProgress>(this as GoalProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GoalProgress&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.predictionPercent, predictionPercent) || other.predictionPercent == predictionPercent)&&(identical(other.status, status) || other.status == status)&&(identical(other.isLost, isLost) || other.isLost == isLost));
}


@override
int get hashCode => Object.hash(runtimeType,percent,predictionPercent,status,isLost);

@override
String toString() {
  return 'GoalProgress(percent: $percent, predictionPercent: $predictionPercent, status: $status, isLost: $isLost)';
}


}

/// @nodoc
abstract mixin class $GoalProgressCopyWith<$Res>  {
  factory $GoalProgressCopyWith(GoalProgress value, $Res Function(GoalProgress) _then) = _$GoalProgressCopyWithImpl;
@useResult
$Res call({
 double percent, double predictionPercent, GoalStatus status, bool isLost
});




}
/// @nodoc
class _$GoalProgressCopyWithImpl<$Res>
    implements $GoalProgressCopyWith<$Res> {
  _$GoalProgressCopyWithImpl(this._self, this._then);

  final GoalProgress _self;
  final $Res Function(GoalProgress) _then;

/// Create a copy of GoalProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? percent = null,Object? predictionPercent = null,Object? status = null,Object? isLost = null,}) {
  return _then(_self.copyWith(
percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as double,predictionPercent: null == predictionPercent ? _self.predictionPercent : predictionPercent // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GoalStatus,isLost: null == isLost ? _self.isLost : isLost // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GoalProgress].
extension GoalProgressPatterns on GoalProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GoalProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GoalProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GoalProgress value)  $default,){
final _that = this;
switch (_that) {
case _GoalProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GoalProgress value)?  $default,){
final _that = this;
switch (_that) {
case _GoalProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double percent,  double predictionPercent,  GoalStatus status,  bool isLost)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GoalProgress() when $default != null:
return $default(_that.percent,_that.predictionPercent,_that.status,_that.isLost);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double percent,  double predictionPercent,  GoalStatus status,  bool isLost)  $default,) {final _that = this;
switch (_that) {
case _GoalProgress():
return $default(_that.percent,_that.predictionPercent,_that.status,_that.isLost);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double percent,  double predictionPercent,  GoalStatus status,  bool isLost)?  $default,) {final _that = this;
switch (_that) {
case _GoalProgress() when $default != null:
return $default(_that.percent,_that.predictionPercent,_that.status,_that.isLost);case _:
  return null;

}
}

}

/// @nodoc


class _GoalProgress implements GoalProgress {
  const _GoalProgress({required this.percent, required this.predictionPercent, required this.status, required this.isLost});
  

@override final  double percent;
@override final  double predictionPercent;
@override final  GoalStatus status;
@override final  bool isLost;

/// Create a copy of GoalProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoalProgressCopyWith<_GoalProgress> get copyWith => __$GoalProgressCopyWithImpl<_GoalProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GoalProgress&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.predictionPercent, predictionPercent) || other.predictionPercent == predictionPercent)&&(identical(other.status, status) || other.status == status)&&(identical(other.isLost, isLost) || other.isLost == isLost));
}


@override
int get hashCode => Object.hash(runtimeType,percent,predictionPercent,status,isLost);

@override
String toString() {
  return 'GoalProgress(percent: $percent, predictionPercent: $predictionPercent, status: $status, isLost: $isLost)';
}


}

/// @nodoc
abstract mixin class _$GoalProgressCopyWith<$Res> implements $GoalProgressCopyWith<$Res> {
  factory _$GoalProgressCopyWith(_GoalProgress value, $Res Function(_GoalProgress) _then) = __$GoalProgressCopyWithImpl;
@override @useResult
$Res call({
 double percent, double predictionPercent, GoalStatus status, bool isLost
});




}
/// @nodoc
class __$GoalProgressCopyWithImpl<$Res>
    implements _$GoalProgressCopyWith<$Res> {
  __$GoalProgressCopyWithImpl(this._self, this._then);

  final _GoalProgress _self;
  final $Res Function(_GoalProgress) _then;

/// Create a copy of GoalProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? percent = null,Object? predictionPercent = null,Object? status = null,Object? isLost = null,}) {
  return _then(_GoalProgress(
percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as double,predictionPercent: null == predictionPercent ? _self.predictionPercent : predictionPercent // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GoalStatus,isLost: null == isLost ? _self.isLost : isLost // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

GoalModel _$GoalModelFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'payDebt':
          return _GoalModelPayDebt.fromJson(
            json
          );
                case 'reduceCreditCard':
          return _GoalModelCreditCard.fromJson(
            json
          );
                case 'reduceExpense':
          return _GoalModelReduceExpense.fromJson(
            json
          );
                case 'saveMoney':
          return _GoalModelSaveMoney.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'GoalModel',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$GoalModel {

 String get id; String get name; double get targetAmount; double get currentAmount; DateTime get deadline; DateTime get startDate;/// Carimbo do SERVIDOR na primeira vez que a meta alcança o alvo.
/// O app só lê: as security rules negam a escrita pelo cliente e o
/// repositório remove o campo antes de salvar.
 DateTime? get completedAt; bool get isDeleted;
/// Create a copy of GoalModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GoalModelCopyWith<GoalModel> get copyWith => _$GoalModelCopyWithImpl<GoalModel>(this as GoalModel, _$identity);

  /// Serializes this GoalModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GoalModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.targetAmount, targetAmount) || other.targetAmount == targetAmount)&&(identical(other.currentAmount, currentAmount) || other.currentAmount == currentAmount)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,targetAmount,currentAmount,deadline,startDate,completedAt,isDeleted);

@override
String toString() {
  return 'GoalModel(id: $id, name: $name, targetAmount: $targetAmount, currentAmount: $currentAmount, deadline: $deadline, startDate: $startDate, completedAt: $completedAt, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class $GoalModelCopyWith<$Res>  {
  factory $GoalModelCopyWith(GoalModel value, $Res Function(GoalModel) _then) = _$GoalModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, double targetAmount, double currentAmount, DateTime deadline, DateTime startDate, DateTime? completedAt, bool isDeleted
});




}
/// @nodoc
class _$GoalModelCopyWithImpl<$Res>
    implements $GoalModelCopyWith<$Res> {
  _$GoalModelCopyWithImpl(this._self, this._then);

  final GoalModel _self;
  final $Res Function(GoalModel) _then;

/// Create a copy of GoalModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? targetAmount = null,Object? currentAmount = null,Object? deadline = null,Object? startDate = null,Object? completedAt = freezed,Object? isDeleted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,targetAmount: null == targetAmount ? _self.targetAmount : targetAmount // ignore: cast_nullable_to_non_nullable
as double,currentAmount: null == currentAmount ? _self.currentAmount : currentAmount // ignore: cast_nullable_to_non_nullable
as double,deadline: null == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GoalModel].
extension GoalModelPatterns on GoalModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _GoalModelPayDebt value)?  payDebt,TResult Function( _GoalModelCreditCard value)?  reduceCreditCard,TResult Function( _GoalModelReduceExpense value)?  reduceExpense,TResult Function( _GoalModelSaveMoney value)?  saveMoney,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GoalModelPayDebt() when payDebt != null:
return payDebt(_that);case _GoalModelCreditCard() when reduceCreditCard != null:
return reduceCreditCard(_that);case _GoalModelReduceExpense() when reduceExpense != null:
return reduceExpense(_that);case _GoalModelSaveMoney() when saveMoney != null:
return saveMoney(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _GoalModelPayDebt value)  payDebt,required TResult Function( _GoalModelCreditCard value)  reduceCreditCard,required TResult Function( _GoalModelReduceExpense value)  reduceExpense,required TResult Function( _GoalModelSaveMoney value)  saveMoney,}){
final _that = this;
switch (_that) {
case _GoalModelPayDebt():
return payDebt(_that);case _GoalModelCreditCard():
return reduceCreditCard(_that);case _GoalModelReduceExpense():
return reduceExpense(_that);case _GoalModelSaveMoney():
return saveMoney(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _GoalModelPayDebt value)?  payDebt,TResult? Function( _GoalModelCreditCard value)?  reduceCreditCard,TResult? Function( _GoalModelReduceExpense value)?  reduceExpense,TResult? Function( _GoalModelSaveMoney value)?  saveMoney,}){
final _that = this;
switch (_that) {
case _GoalModelPayDebt() when payDebt != null:
return payDebt(_that);case _GoalModelCreditCard() when reduceCreditCard != null:
return reduceCreditCard(_that);case _GoalModelReduceExpense() when reduceExpense != null:
return reduceExpense(_that);case _GoalModelSaveMoney() when saveMoney != null:
return saveMoney(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String name,  double targetAmount,  double currentAmount,  DateTime deadline,  String accountId,  DateTime startDate,  DateTime? completedAt,  bool isDeleted)?  payDebt,TResult Function( String id,  String name,  double targetAmount,  double currentAmount,  double averageSpending,  DateTime deadline,  String accountId,  DateTime startDate,  DateTime? completedAt,  bool isDeleted)?  reduceCreditCard,TResult Function( String id,  String name,  double targetAmount,  double currentAmount,  double averageSpending,  DateTime deadline,  CategoryModel category,  DateTime startDate,  DateTime? completedAt,  bool isDeleted)?  reduceExpense,TResult Function( String id,  String name,  double targetAmount,  double currentAmount,  DateTime deadline,  String accountId,  DateTime startDate,  DateTime? completedAt,  bool isDeleted)?  saveMoney,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GoalModelPayDebt() when payDebt != null:
return payDebt(_that.id,_that.name,_that.targetAmount,_that.currentAmount,_that.deadline,_that.accountId,_that.startDate,_that.completedAt,_that.isDeleted);case _GoalModelCreditCard() when reduceCreditCard != null:
return reduceCreditCard(_that.id,_that.name,_that.targetAmount,_that.currentAmount,_that.averageSpending,_that.deadline,_that.accountId,_that.startDate,_that.completedAt,_that.isDeleted);case _GoalModelReduceExpense() when reduceExpense != null:
return reduceExpense(_that.id,_that.name,_that.targetAmount,_that.currentAmount,_that.averageSpending,_that.deadline,_that.category,_that.startDate,_that.completedAt,_that.isDeleted);case _GoalModelSaveMoney() when saveMoney != null:
return saveMoney(_that.id,_that.name,_that.targetAmount,_that.currentAmount,_that.deadline,_that.accountId,_that.startDate,_that.completedAt,_that.isDeleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String name,  double targetAmount,  double currentAmount,  DateTime deadline,  String accountId,  DateTime startDate,  DateTime? completedAt,  bool isDeleted)  payDebt,required TResult Function( String id,  String name,  double targetAmount,  double currentAmount,  double averageSpending,  DateTime deadline,  String accountId,  DateTime startDate,  DateTime? completedAt,  bool isDeleted)  reduceCreditCard,required TResult Function( String id,  String name,  double targetAmount,  double currentAmount,  double averageSpending,  DateTime deadline,  CategoryModel category,  DateTime startDate,  DateTime? completedAt,  bool isDeleted)  reduceExpense,required TResult Function( String id,  String name,  double targetAmount,  double currentAmount,  DateTime deadline,  String accountId,  DateTime startDate,  DateTime? completedAt,  bool isDeleted)  saveMoney,}) {final _that = this;
switch (_that) {
case _GoalModelPayDebt():
return payDebt(_that.id,_that.name,_that.targetAmount,_that.currentAmount,_that.deadline,_that.accountId,_that.startDate,_that.completedAt,_that.isDeleted);case _GoalModelCreditCard():
return reduceCreditCard(_that.id,_that.name,_that.targetAmount,_that.currentAmount,_that.averageSpending,_that.deadline,_that.accountId,_that.startDate,_that.completedAt,_that.isDeleted);case _GoalModelReduceExpense():
return reduceExpense(_that.id,_that.name,_that.targetAmount,_that.currentAmount,_that.averageSpending,_that.deadline,_that.category,_that.startDate,_that.completedAt,_that.isDeleted);case _GoalModelSaveMoney():
return saveMoney(_that.id,_that.name,_that.targetAmount,_that.currentAmount,_that.deadline,_that.accountId,_that.startDate,_that.completedAt,_that.isDeleted);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String name,  double targetAmount,  double currentAmount,  DateTime deadline,  String accountId,  DateTime startDate,  DateTime? completedAt,  bool isDeleted)?  payDebt,TResult? Function( String id,  String name,  double targetAmount,  double currentAmount,  double averageSpending,  DateTime deadline,  String accountId,  DateTime startDate,  DateTime? completedAt,  bool isDeleted)?  reduceCreditCard,TResult? Function( String id,  String name,  double targetAmount,  double currentAmount,  double averageSpending,  DateTime deadline,  CategoryModel category,  DateTime startDate,  DateTime? completedAt,  bool isDeleted)?  reduceExpense,TResult? Function( String id,  String name,  double targetAmount,  double currentAmount,  DateTime deadline,  String accountId,  DateTime startDate,  DateTime? completedAt,  bool isDeleted)?  saveMoney,}) {final _that = this;
switch (_that) {
case _GoalModelPayDebt() when payDebt != null:
return payDebt(_that.id,_that.name,_that.targetAmount,_that.currentAmount,_that.deadline,_that.accountId,_that.startDate,_that.completedAt,_that.isDeleted);case _GoalModelCreditCard() when reduceCreditCard != null:
return reduceCreditCard(_that.id,_that.name,_that.targetAmount,_that.currentAmount,_that.averageSpending,_that.deadline,_that.accountId,_that.startDate,_that.completedAt,_that.isDeleted);case _GoalModelReduceExpense() when reduceExpense != null:
return reduceExpense(_that.id,_that.name,_that.targetAmount,_that.currentAmount,_that.averageSpending,_that.deadline,_that.category,_that.startDate,_that.completedAt,_that.isDeleted);case _GoalModelSaveMoney() when saveMoney != null:
return saveMoney(_that.id,_that.name,_that.targetAmount,_that.currentAmount,_that.deadline,_that.accountId,_that.startDate,_that.completedAt,_that.isDeleted);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _GoalModelPayDebt extends GoalModel {
  const _GoalModelPayDebt({required this.id, required this.name, required this.targetAmount, required this.currentAmount, required this.deadline, required this.accountId, required this.startDate, this.completedAt, this.isDeleted = false, final  String? $type}): $type = $type ?? 'payDebt',super._();
  factory _GoalModelPayDebt.fromJson(Map<String, dynamic> json) => _$GoalModelPayDebtFromJson(json);

@override final  String id;
@override final  String name;
@override final  double targetAmount;
@override final  double currentAmount;
@override final  DateTime deadline;
 final  String accountId;
@override final  DateTime startDate;
/// Carimbo do SERVIDOR na primeira vez que a meta alcança o alvo.
/// O app só lê: as security rules negam a escrita pelo cliente e o
/// repositório remove o campo antes de salvar.
@override final  DateTime? completedAt;
@override@JsonKey() final  bool isDeleted;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GoalModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoalModelPayDebtCopyWith<_GoalModelPayDebt> get copyWith => __$GoalModelPayDebtCopyWithImpl<_GoalModelPayDebt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GoalModelPayDebtToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GoalModelPayDebt&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.targetAmount, targetAmount) || other.targetAmount == targetAmount)&&(identical(other.currentAmount, currentAmount) || other.currentAmount == currentAmount)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,targetAmount,currentAmount,deadline,accountId,startDate,completedAt,isDeleted);

@override
String toString() {
  return 'GoalModel.payDebt(id: $id, name: $name, targetAmount: $targetAmount, currentAmount: $currentAmount, deadline: $deadline, accountId: $accountId, startDate: $startDate, completedAt: $completedAt, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class _$GoalModelPayDebtCopyWith<$Res> implements $GoalModelCopyWith<$Res> {
  factory _$GoalModelPayDebtCopyWith(_GoalModelPayDebt value, $Res Function(_GoalModelPayDebt) _then) = __$GoalModelPayDebtCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double targetAmount, double currentAmount, DateTime deadline, String accountId, DateTime startDate, DateTime? completedAt, bool isDeleted
});




}
/// @nodoc
class __$GoalModelPayDebtCopyWithImpl<$Res>
    implements _$GoalModelPayDebtCopyWith<$Res> {
  __$GoalModelPayDebtCopyWithImpl(this._self, this._then);

  final _GoalModelPayDebt _self;
  final $Res Function(_GoalModelPayDebt) _then;

/// Create a copy of GoalModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? targetAmount = null,Object? currentAmount = null,Object? deadline = null,Object? accountId = null,Object? startDate = null,Object? completedAt = freezed,Object? isDeleted = null,}) {
  return _then(_GoalModelPayDebt(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,targetAmount: null == targetAmount ? _self.targetAmount : targetAmount // ignore: cast_nullable_to_non_nullable
as double,currentAmount: null == currentAmount ? _self.currentAmount : currentAmount // ignore: cast_nullable_to_non_nullable
as double,deadline: null == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _GoalModelCreditCard extends GoalModel {
  const _GoalModelCreditCard({required this.id, required this.name, required this.targetAmount, required this.currentAmount, required this.averageSpending, required this.deadline, required this.accountId, required this.startDate, this.completedAt, this.isDeleted = false, final  String? $type}): $type = $type ?? 'reduceCreditCard',super._();
  factory _GoalModelCreditCard.fromJson(Map<String, dynamic> json) => _$GoalModelCreditCardFromJson(json);

@override final  String id;
@override final  String name;
@override final  double targetAmount;
@override final  double currentAmount;
 final  double averageSpending;
@override final  DateTime deadline;
 final  String accountId;
@override final  DateTime startDate;
/// Carimbo do SERVIDOR na primeira vez que a meta alcança o alvo.
/// O app só lê: as security rules negam a escrita pelo cliente e o
/// repositório remove o campo antes de salvar.
@override final  DateTime? completedAt;
@override@JsonKey() final  bool isDeleted;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GoalModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoalModelCreditCardCopyWith<_GoalModelCreditCard> get copyWith => __$GoalModelCreditCardCopyWithImpl<_GoalModelCreditCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GoalModelCreditCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GoalModelCreditCard&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.targetAmount, targetAmount) || other.targetAmount == targetAmount)&&(identical(other.currentAmount, currentAmount) || other.currentAmount == currentAmount)&&(identical(other.averageSpending, averageSpending) || other.averageSpending == averageSpending)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,targetAmount,currentAmount,averageSpending,deadline,accountId,startDate,completedAt,isDeleted);

@override
String toString() {
  return 'GoalModel.reduceCreditCard(id: $id, name: $name, targetAmount: $targetAmount, currentAmount: $currentAmount, averageSpending: $averageSpending, deadline: $deadline, accountId: $accountId, startDate: $startDate, completedAt: $completedAt, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class _$GoalModelCreditCardCopyWith<$Res> implements $GoalModelCopyWith<$Res> {
  factory _$GoalModelCreditCardCopyWith(_GoalModelCreditCard value, $Res Function(_GoalModelCreditCard) _then) = __$GoalModelCreditCardCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double targetAmount, double currentAmount, double averageSpending, DateTime deadline, String accountId, DateTime startDate, DateTime? completedAt, bool isDeleted
});




}
/// @nodoc
class __$GoalModelCreditCardCopyWithImpl<$Res>
    implements _$GoalModelCreditCardCopyWith<$Res> {
  __$GoalModelCreditCardCopyWithImpl(this._self, this._then);

  final _GoalModelCreditCard _self;
  final $Res Function(_GoalModelCreditCard) _then;

/// Create a copy of GoalModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? targetAmount = null,Object? currentAmount = null,Object? averageSpending = null,Object? deadline = null,Object? accountId = null,Object? startDate = null,Object? completedAt = freezed,Object? isDeleted = null,}) {
  return _then(_GoalModelCreditCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,targetAmount: null == targetAmount ? _self.targetAmount : targetAmount // ignore: cast_nullable_to_non_nullable
as double,currentAmount: null == currentAmount ? _self.currentAmount : currentAmount // ignore: cast_nullable_to_non_nullable
as double,averageSpending: null == averageSpending ? _self.averageSpending : averageSpending // ignore: cast_nullable_to_non_nullable
as double,deadline: null == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _GoalModelReduceExpense extends GoalModel {
  const _GoalModelReduceExpense({required this.id, required this.name, required this.targetAmount, required this.currentAmount, required this.averageSpending, required this.deadline, required this.category, required this.startDate, this.completedAt, this.isDeleted = false, final  String? $type}): $type = $type ?? 'reduceExpense',super._();
  factory _GoalModelReduceExpense.fromJson(Map<String, dynamic> json) => _$GoalModelReduceExpenseFromJson(json);

@override final  String id;
@override final  String name;
@override final  double targetAmount;
@override final  double currentAmount;
 final  double averageSpending;
@override final  DateTime deadline;
 final  CategoryModel category;
@override final  DateTime startDate;
/// Carimbo do SERVIDOR na primeira vez que a meta alcança o alvo.
/// O app só lê: as security rules negam a escrita pelo cliente e o
/// repositório remove o campo antes de salvar.
@override final  DateTime? completedAt;
@override@JsonKey() final  bool isDeleted;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GoalModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoalModelReduceExpenseCopyWith<_GoalModelReduceExpense> get copyWith => __$GoalModelReduceExpenseCopyWithImpl<_GoalModelReduceExpense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GoalModelReduceExpenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GoalModelReduceExpense&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.targetAmount, targetAmount) || other.targetAmount == targetAmount)&&(identical(other.currentAmount, currentAmount) || other.currentAmount == currentAmount)&&(identical(other.averageSpending, averageSpending) || other.averageSpending == averageSpending)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.category, category) || other.category == category)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,targetAmount,currentAmount,averageSpending,deadline,category,startDate,completedAt,isDeleted);

@override
String toString() {
  return 'GoalModel.reduceExpense(id: $id, name: $name, targetAmount: $targetAmount, currentAmount: $currentAmount, averageSpending: $averageSpending, deadline: $deadline, category: $category, startDate: $startDate, completedAt: $completedAt, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class _$GoalModelReduceExpenseCopyWith<$Res> implements $GoalModelCopyWith<$Res> {
  factory _$GoalModelReduceExpenseCopyWith(_GoalModelReduceExpense value, $Res Function(_GoalModelReduceExpense) _then) = __$GoalModelReduceExpenseCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double targetAmount, double currentAmount, double averageSpending, DateTime deadline, CategoryModel category, DateTime startDate, DateTime? completedAt, bool isDeleted
});


$CategoryModelCopyWith<$Res> get category;

}
/// @nodoc
class __$GoalModelReduceExpenseCopyWithImpl<$Res>
    implements _$GoalModelReduceExpenseCopyWith<$Res> {
  __$GoalModelReduceExpenseCopyWithImpl(this._self, this._then);

  final _GoalModelReduceExpense _self;
  final $Res Function(_GoalModelReduceExpense) _then;

/// Create a copy of GoalModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? targetAmount = null,Object? currentAmount = null,Object? averageSpending = null,Object? deadline = null,Object? category = null,Object? startDate = null,Object? completedAt = freezed,Object? isDeleted = null,}) {
  return _then(_GoalModelReduceExpense(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,targetAmount: null == targetAmount ? _self.targetAmount : targetAmount // ignore: cast_nullable_to_non_nullable
as double,currentAmount: null == currentAmount ? _self.currentAmount : currentAmount // ignore: cast_nullable_to_non_nullable
as double,averageSpending: null == averageSpending ? _self.averageSpending : averageSpending // ignore: cast_nullable_to_non_nullable
as double,deadline: null == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryModel,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of GoalModel
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
class _GoalModelSaveMoney extends GoalModel {
  const _GoalModelSaveMoney({required this.id, required this.name, required this.targetAmount, required this.currentAmount, required this.deadline, required this.accountId, required this.startDate, this.completedAt, this.isDeleted = false, final  String? $type}): $type = $type ?? 'saveMoney',super._();
  factory _GoalModelSaveMoney.fromJson(Map<String, dynamic> json) => _$GoalModelSaveMoneyFromJson(json);

@override final  String id;
@override final  String name;
@override final  double targetAmount;
@override final  double currentAmount;
@override final  DateTime deadline;
 final  String accountId;
@override final  DateTime startDate;
/// Carimbo do SERVIDOR na primeira vez que a meta alcança o alvo.
/// O app só lê: as security rules negam a escrita pelo cliente e o
/// repositório remove o campo antes de salvar.
@override final  DateTime? completedAt;
@override@JsonKey() final  bool isDeleted;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GoalModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoalModelSaveMoneyCopyWith<_GoalModelSaveMoney> get copyWith => __$GoalModelSaveMoneyCopyWithImpl<_GoalModelSaveMoney>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GoalModelSaveMoneyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GoalModelSaveMoney&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.targetAmount, targetAmount) || other.targetAmount == targetAmount)&&(identical(other.currentAmount, currentAmount) || other.currentAmount == currentAmount)&&(identical(other.deadline, deadline) || other.deadline == deadline)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,targetAmount,currentAmount,deadline,accountId,startDate,completedAt,isDeleted);

@override
String toString() {
  return 'GoalModel.saveMoney(id: $id, name: $name, targetAmount: $targetAmount, currentAmount: $currentAmount, deadline: $deadline, accountId: $accountId, startDate: $startDate, completedAt: $completedAt, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class _$GoalModelSaveMoneyCopyWith<$Res> implements $GoalModelCopyWith<$Res> {
  factory _$GoalModelSaveMoneyCopyWith(_GoalModelSaveMoney value, $Res Function(_GoalModelSaveMoney) _then) = __$GoalModelSaveMoneyCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, double targetAmount, double currentAmount, DateTime deadline, String accountId, DateTime startDate, DateTime? completedAt, bool isDeleted
});




}
/// @nodoc
class __$GoalModelSaveMoneyCopyWithImpl<$Res>
    implements _$GoalModelSaveMoneyCopyWith<$Res> {
  __$GoalModelSaveMoneyCopyWithImpl(this._self, this._then);

  final _GoalModelSaveMoney _self;
  final $Res Function(_GoalModelSaveMoney) _then;

/// Create a copy of GoalModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? targetAmount = null,Object? currentAmount = null,Object? deadline = null,Object? accountId = null,Object? startDate = null,Object? completedAt = freezed,Object? isDeleted = null,}) {
  return _then(_GoalModelSaveMoney(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,targetAmount: null == targetAmount ? _self.targetAmount : targetAmount // ignore: cast_nullable_to_non_nullable
as double,currentAmount: null == currentAmount ? _self.currentAmount : currentAmount // ignore: cast_nullable_to_non_nullable
as double,deadline: null == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as DateTime,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
