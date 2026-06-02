// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mission_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MissionModel {

 List<InstallmentMission> get pendingInstallments; List<InstallmentMission> get completedInstallments; List<InstallmentMission> get overdueInstallments; List<PlanningMission> get planningMissions; double get totalXp; double get currentXp; DateTime get startDate; DateTime get endDate;
/// Create a copy of MissionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MissionModelCopyWith<MissionModel> get copyWith => _$MissionModelCopyWithImpl<MissionModel>(this as MissionModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MissionModel&&const DeepCollectionEquality().equals(other.pendingInstallments, pendingInstallments)&&const DeepCollectionEquality().equals(other.completedInstallments, completedInstallments)&&const DeepCollectionEquality().equals(other.overdueInstallments, overdueInstallments)&&const DeepCollectionEquality().equals(other.planningMissions, planningMissions)&&(identical(other.totalXp, totalXp) || other.totalXp == totalXp)&&(identical(other.currentXp, currentXp) || other.currentXp == currentXp)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(pendingInstallments),const DeepCollectionEquality().hash(completedInstallments),const DeepCollectionEquality().hash(overdueInstallments),const DeepCollectionEquality().hash(planningMissions),totalXp,currentXp,startDate,endDate);

@override
String toString() {
  return 'MissionModel(pendingInstallments: $pendingInstallments, completedInstallments: $completedInstallments, overdueInstallments: $overdueInstallments, planningMissions: $planningMissions, totalXp: $totalXp, currentXp: $currentXp, startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class $MissionModelCopyWith<$Res>  {
  factory $MissionModelCopyWith(MissionModel value, $Res Function(MissionModel) _then) = _$MissionModelCopyWithImpl;
@useResult
$Res call({
 List<InstallmentMission> pendingInstallments, List<InstallmentMission> completedInstallments, List<InstallmentMission> overdueInstallments, List<PlanningMission> planningMissions, double totalXp, double currentXp, DateTime startDate, DateTime endDate
});




}
/// @nodoc
class _$MissionModelCopyWithImpl<$Res>
    implements $MissionModelCopyWith<$Res> {
  _$MissionModelCopyWithImpl(this._self, this._then);

  final MissionModel _self;
  final $Res Function(MissionModel) _then;

/// Create a copy of MissionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pendingInstallments = null,Object? completedInstallments = null,Object? overdueInstallments = null,Object? planningMissions = null,Object? totalXp = null,Object? currentXp = null,Object? startDate = null,Object? endDate = null,}) {
  return _then(_self.copyWith(
pendingInstallments: null == pendingInstallments ? _self.pendingInstallments : pendingInstallments // ignore: cast_nullable_to_non_nullable
as List<InstallmentMission>,completedInstallments: null == completedInstallments ? _self.completedInstallments : completedInstallments // ignore: cast_nullable_to_non_nullable
as List<InstallmentMission>,overdueInstallments: null == overdueInstallments ? _self.overdueInstallments : overdueInstallments // ignore: cast_nullable_to_non_nullable
as List<InstallmentMission>,planningMissions: null == planningMissions ? _self.planningMissions : planningMissions // ignore: cast_nullable_to_non_nullable
as List<PlanningMission>,totalXp: null == totalXp ? _self.totalXp : totalXp // ignore: cast_nullable_to_non_nullable
as double,currentXp: null == currentXp ? _self.currentXp : currentXp // ignore: cast_nullable_to_non_nullable
as double,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MissionModel].
extension MissionModelPatterns on MissionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MissionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MissionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MissionModel value)  $default,){
final _that = this;
switch (_that) {
case _MissionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MissionModel value)?  $default,){
final _that = this;
switch (_that) {
case _MissionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<InstallmentMission> pendingInstallments,  List<InstallmentMission> completedInstallments,  List<InstallmentMission> overdueInstallments,  List<PlanningMission> planningMissions,  double totalXp,  double currentXp,  DateTime startDate,  DateTime endDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MissionModel() when $default != null:
return $default(_that.pendingInstallments,_that.completedInstallments,_that.overdueInstallments,_that.planningMissions,_that.totalXp,_that.currentXp,_that.startDate,_that.endDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<InstallmentMission> pendingInstallments,  List<InstallmentMission> completedInstallments,  List<InstallmentMission> overdueInstallments,  List<PlanningMission> planningMissions,  double totalXp,  double currentXp,  DateTime startDate,  DateTime endDate)  $default,) {final _that = this;
switch (_that) {
case _MissionModel():
return $default(_that.pendingInstallments,_that.completedInstallments,_that.overdueInstallments,_that.planningMissions,_that.totalXp,_that.currentXp,_that.startDate,_that.endDate);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<InstallmentMission> pendingInstallments,  List<InstallmentMission> completedInstallments,  List<InstallmentMission> overdueInstallments,  List<PlanningMission> planningMissions,  double totalXp,  double currentXp,  DateTime startDate,  DateTime endDate)?  $default,) {final _that = this;
switch (_that) {
case _MissionModel() when $default != null:
return $default(_that.pendingInstallments,_that.completedInstallments,_that.overdueInstallments,_that.planningMissions,_that.totalXp,_that.currentXp,_that.startDate,_that.endDate);case _:
  return null;

}
}

}

/// @nodoc


class _MissionModel extends MissionModel {
  const _MissionModel({required final  List<InstallmentMission> pendingInstallments, required final  List<InstallmentMission> completedInstallments, required final  List<InstallmentMission> overdueInstallments, required final  List<PlanningMission> planningMissions, required this.totalXp, required this.currentXp, required this.startDate, required this.endDate}): _pendingInstallments = pendingInstallments,_completedInstallments = completedInstallments,_overdueInstallments = overdueInstallments,_planningMissions = planningMissions,super._();
  

 final  List<InstallmentMission> _pendingInstallments;
@override List<InstallmentMission> get pendingInstallments {
  if (_pendingInstallments is EqualUnmodifiableListView) return _pendingInstallments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pendingInstallments);
}

 final  List<InstallmentMission> _completedInstallments;
@override List<InstallmentMission> get completedInstallments {
  if (_completedInstallments is EqualUnmodifiableListView) return _completedInstallments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_completedInstallments);
}

 final  List<InstallmentMission> _overdueInstallments;
@override List<InstallmentMission> get overdueInstallments {
  if (_overdueInstallments is EqualUnmodifiableListView) return _overdueInstallments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_overdueInstallments);
}

 final  List<PlanningMission> _planningMissions;
@override List<PlanningMission> get planningMissions {
  if (_planningMissions is EqualUnmodifiableListView) return _planningMissions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_planningMissions);
}

@override final  double totalXp;
@override final  double currentXp;
@override final  DateTime startDate;
@override final  DateTime endDate;

/// Create a copy of MissionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MissionModelCopyWith<_MissionModel> get copyWith => __$MissionModelCopyWithImpl<_MissionModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MissionModel&&const DeepCollectionEquality().equals(other._pendingInstallments, _pendingInstallments)&&const DeepCollectionEquality().equals(other._completedInstallments, _completedInstallments)&&const DeepCollectionEquality().equals(other._overdueInstallments, _overdueInstallments)&&const DeepCollectionEquality().equals(other._planningMissions, _planningMissions)&&(identical(other.totalXp, totalXp) || other.totalXp == totalXp)&&(identical(other.currentXp, currentXp) || other.currentXp == currentXp)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_pendingInstallments),const DeepCollectionEquality().hash(_completedInstallments),const DeepCollectionEquality().hash(_overdueInstallments),const DeepCollectionEquality().hash(_planningMissions),totalXp,currentXp,startDate,endDate);

@override
String toString() {
  return 'MissionModel(pendingInstallments: $pendingInstallments, completedInstallments: $completedInstallments, overdueInstallments: $overdueInstallments, planningMissions: $planningMissions, totalXp: $totalXp, currentXp: $currentXp, startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class _$MissionModelCopyWith<$Res> implements $MissionModelCopyWith<$Res> {
  factory _$MissionModelCopyWith(_MissionModel value, $Res Function(_MissionModel) _then) = __$MissionModelCopyWithImpl;
@override @useResult
$Res call({
 List<InstallmentMission> pendingInstallments, List<InstallmentMission> completedInstallments, List<InstallmentMission> overdueInstallments, List<PlanningMission> planningMissions, double totalXp, double currentXp, DateTime startDate, DateTime endDate
});




}
/// @nodoc
class __$MissionModelCopyWithImpl<$Res>
    implements _$MissionModelCopyWith<$Res> {
  __$MissionModelCopyWithImpl(this._self, this._then);

  final _MissionModel _self;
  final $Res Function(_MissionModel) _then;

/// Create a copy of MissionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pendingInstallments = null,Object? completedInstallments = null,Object? overdueInstallments = null,Object? planningMissions = null,Object? totalXp = null,Object? currentXp = null,Object? startDate = null,Object? endDate = null,}) {
  return _then(_MissionModel(
pendingInstallments: null == pendingInstallments ? _self._pendingInstallments : pendingInstallments // ignore: cast_nullable_to_non_nullable
as List<InstallmentMission>,completedInstallments: null == completedInstallments ? _self._completedInstallments : completedInstallments // ignore: cast_nullable_to_non_nullable
as List<InstallmentMission>,overdueInstallments: null == overdueInstallments ? _self._overdueInstallments : overdueInstallments // ignore: cast_nullable_to_non_nullable
as List<InstallmentMission>,planningMissions: null == planningMissions ? _self._planningMissions : planningMissions // ignore: cast_nullable_to_non_nullable
as List<PlanningMission>,totalXp: null == totalXp ? _self.totalXp : totalXp // ignore: cast_nullable_to_non_nullable
as double,currentXp: null == currentXp ? _self.currentXp : currentXp // ignore: cast_nullable_to_non_nullable
as double,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$InstallmentMission {

 InstallmentModel get installment; double get xpValue; bool get isAdherent; double get earnedXp;
/// Create a copy of InstallmentMission
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstallmentMissionCopyWith<InstallmentMission> get copyWith => _$InstallmentMissionCopyWithImpl<InstallmentMission>(this as InstallmentMission, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstallmentMission&&(identical(other.installment, installment) || other.installment == installment)&&(identical(other.xpValue, xpValue) || other.xpValue == xpValue)&&(identical(other.isAdherent, isAdherent) || other.isAdherent == isAdherent)&&(identical(other.earnedXp, earnedXp) || other.earnedXp == earnedXp));
}


@override
int get hashCode => Object.hash(runtimeType,installment,xpValue,isAdherent,earnedXp);

@override
String toString() {
  return 'InstallmentMission(installment: $installment, xpValue: $xpValue, isAdherent: $isAdherent, earnedXp: $earnedXp)';
}


}

/// @nodoc
abstract mixin class $InstallmentMissionCopyWith<$Res>  {
  factory $InstallmentMissionCopyWith(InstallmentMission value, $Res Function(InstallmentMission) _then) = _$InstallmentMissionCopyWithImpl;
@useResult
$Res call({
 InstallmentModel installment, double xpValue, bool isAdherent, double earnedXp
});


$InstallmentModelCopyWith<$Res> get installment;

}
/// @nodoc
class _$InstallmentMissionCopyWithImpl<$Res>
    implements $InstallmentMissionCopyWith<$Res> {
  _$InstallmentMissionCopyWithImpl(this._self, this._then);

  final InstallmentMission _self;
  final $Res Function(InstallmentMission) _then;

/// Create a copy of InstallmentMission
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? installment = null,Object? xpValue = null,Object? isAdherent = null,Object? earnedXp = null,}) {
  return _then(_self.copyWith(
installment: null == installment ? _self.installment : installment // ignore: cast_nullable_to_non_nullable
as InstallmentModel,xpValue: null == xpValue ? _self.xpValue : xpValue // ignore: cast_nullable_to_non_nullable
as double,isAdherent: null == isAdherent ? _self.isAdherent : isAdherent // ignore: cast_nullable_to_non_nullable
as bool,earnedXp: null == earnedXp ? _self.earnedXp : earnedXp // ignore: cast_nullable_to_non_nullable
as double,
  ));
}
/// Create a copy of InstallmentMission
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstallmentModelCopyWith<$Res> get installment {
  
  return $InstallmentModelCopyWith<$Res>(_self.installment, (value) {
    return _then(_self.copyWith(installment: value));
  });
}
}


/// Adds pattern-matching-related methods to [InstallmentMission].
extension InstallmentMissionPatterns on InstallmentMission {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstallmentMission value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstallmentMission() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstallmentMission value)  $default,){
final _that = this;
switch (_that) {
case _InstallmentMission():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstallmentMission value)?  $default,){
final _that = this;
switch (_that) {
case _InstallmentMission() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( InstallmentModel installment,  double xpValue,  bool isAdherent,  double earnedXp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstallmentMission() when $default != null:
return $default(_that.installment,_that.xpValue,_that.isAdherent,_that.earnedXp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( InstallmentModel installment,  double xpValue,  bool isAdherent,  double earnedXp)  $default,) {final _that = this;
switch (_that) {
case _InstallmentMission():
return $default(_that.installment,_that.xpValue,_that.isAdherent,_that.earnedXp);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( InstallmentModel installment,  double xpValue,  bool isAdherent,  double earnedXp)?  $default,) {final _that = this;
switch (_that) {
case _InstallmentMission() when $default != null:
return $default(_that.installment,_that.xpValue,_that.isAdherent,_that.earnedXp);case _:
  return null;

}
}

}

/// @nodoc


class _InstallmentMission implements InstallmentMission {
  const _InstallmentMission({required this.installment, required this.xpValue, this.isAdherent = false, this.earnedXp = 0});
  

@override final  InstallmentModel installment;
@override final  double xpValue;
@override@JsonKey() final  bool isAdherent;
@override@JsonKey() final  double earnedXp;

/// Create a copy of InstallmentMission
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstallmentMissionCopyWith<_InstallmentMission> get copyWith => __$InstallmentMissionCopyWithImpl<_InstallmentMission>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstallmentMission&&(identical(other.installment, installment) || other.installment == installment)&&(identical(other.xpValue, xpValue) || other.xpValue == xpValue)&&(identical(other.isAdherent, isAdherent) || other.isAdherent == isAdherent)&&(identical(other.earnedXp, earnedXp) || other.earnedXp == earnedXp));
}


@override
int get hashCode => Object.hash(runtimeType,installment,xpValue,isAdherent,earnedXp);

@override
String toString() {
  return 'InstallmentMission(installment: $installment, xpValue: $xpValue, isAdherent: $isAdherent, earnedXp: $earnedXp)';
}


}

/// @nodoc
abstract mixin class _$InstallmentMissionCopyWith<$Res> implements $InstallmentMissionCopyWith<$Res> {
  factory _$InstallmentMissionCopyWith(_InstallmentMission value, $Res Function(_InstallmentMission) _then) = __$InstallmentMissionCopyWithImpl;
@override @useResult
$Res call({
 InstallmentModel installment, double xpValue, bool isAdherent, double earnedXp
});


@override $InstallmentModelCopyWith<$Res> get installment;

}
/// @nodoc
class __$InstallmentMissionCopyWithImpl<$Res>
    implements _$InstallmentMissionCopyWith<$Res> {
  __$InstallmentMissionCopyWithImpl(this._self, this._then);

  final _InstallmentMission _self;
  final $Res Function(_InstallmentMission) _then;

/// Create a copy of InstallmentMission
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? installment = null,Object? xpValue = null,Object? isAdherent = null,Object? earnedXp = null,}) {
  return _then(_InstallmentMission(
installment: null == installment ? _self.installment : installment // ignore: cast_nullable_to_non_nullable
as InstallmentModel,xpValue: null == xpValue ? _self.xpValue : xpValue // ignore: cast_nullable_to_non_nullable
as double,isAdherent: null == isAdherent ? _self.isAdherent : isAdherent // ignore: cast_nullable_to_non_nullable
as bool,earnedXp: null == earnedXp ? _self.earnedXp : earnedXp // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of InstallmentMission
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
mixin _$PlanningMission {

 PeriodSummaryModel get summary; double get weeklyPlannedAmount; double get weeklyActualAmount; double get xpValue; double get progress; bool get isAdherent; double get earnedXp;
/// Create a copy of PlanningMission
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanningMissionCopyWith<PlanningMission> get copyWith => _$PlanningMissionCopyWithImpl<PlanningMission>(this as PlanningMission, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanningMission&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.weeklyPlannedAmount, weeklyPlannedAmount) || other.weeklyPlannedAmount == weeklyPlannedAmount)&&(identical(other.weeklyActualAmount, weeklyActualAmount) || other.weeklyActualAmount == weeklyActualAmount)&&(identical(other.xpValue, xpValue) || other.xpValue == xpValue)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.isAdherent, isAdherent) || other.isAdherent == isAdherent)&&(identical(other.earnedXp, earnedXp) || other.earnedXp == earnedXp));
}


@override
int get hashCode => Object.hash(runtimeType,summary,weeklyPlannedAmount,weeklyActualAmount,xpValue,progress,isAdherent,earnedXp);

@override
String toString() {
  return 'PlanningMission(summary: $summary, weeklyPlannedAmount: $weeklyPlannedAmount, weeklyActualAmount: $weeklyActualAmount, xpValue: $xpValue, progress: $progress, isAdherent: $isAdherent, earnedXp: $earnedXp)';
}


}

/// @nodoc
abstract mixin class $PlanningMissionCopyWith<$Res>  {
  factory $PlanningMissionCopyWith(PlanningMission value, $Res Function(PlanningMission) _then) = _$PlanningMissionCopyWithImpl;
@useResult
$Res call({
 PeriodSummaryModel summary, double weeklyPlannedAmount, double weeklyActualAmount, double xpValue, double progress, bool isAdherent, double earnedXp
});


$PeriodSummaryModelCopyWith<$Res> get summary;

}
/// @nodoc
class _$PlanningMissionCopyWithImpl<$Res>
    implements $PlanningMissionCopyWith<$Res> {
  _$PlanningMissionCopyWithImpl(this._self, this._then);

  final PlanningMission _self;
  final $Res Function(PlanningMission) _then;

/// Create a copy of PlanningMission
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summary = null,Object? weeklyPlannedAmount = null,Object? weeklyActualAmount = null,Object? xpValue = null,Object? progress = null,Object? isAdherent = null,Object? earnedXp = null,}) {
  return _then(_self.copyWith(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as PeriodSummaryModel,weeklyPlannedAmount: null == weeklyPlannedAmount ? _self.weeklyPlannedAmount : weeklyPlannedAmount // ignore: cast_nullable_to_non_nullable
as double,weeklyActualAmount: null == weeklyActualAmount ? _self.weeklyActualAmount : weeklyActualAmount // ignore: cast_nullable_to_non_nullable
as double,xpValue: null == xpValue ? _self.xpValue : xpValue // ignore: cast_nullable_to_non_nullable
as double,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,isAdherent: null == isAdherent ? _self.isAdherent : isAdherent // ignore: cast_nullable_to_non_nullable
as bool,earnedXp: null == earnedXp ? _self.earnedXp : earnedXp // ignore: cast_nullable_to_non_nullable
as double,
  ));
}
/// Create a copy of PlanningMission
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodSummaryModelCopyWith<$Res> get summary {
  
  return $PeriodSummaryModelCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlanningMission].
extension PlanningMissionPatterns on PlanningMission {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanningMission value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanningMission() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanningMission value)  $default,){
final _that = this;
switch (_that) {
case _PlanningMission():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanningMission value)?  $default,){
final _that = this;
switch (_that) {
case _PlanningMission() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PeriodSummaryModel summary,  double weeklyPlannedAmount,  double weeklyActualAmount,  double xpValue,  double progress,  bool isAdherent,  double earnedXp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanningMission() when $default != null:
return $default(_that.summary,_that.weeklyPlannedAmount,_that.weeklyActualAmount,_that.xpValue,_that.progress,_that.isAdherent,_that.earnedXp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PeriodSummaryModel summary,  double weeklyPlannedAmount,  double weeklyActualAmount,  double xpValue,  double progress,  bool isAdherent,  double earnedXp)  $default,) {final _that = this;
switch (_that) {
case _PlanningMission():
return $default(_that.summary,_that.weeklyPlannedAmount,_that.weeklyActualAmount,_that.xpValue,_that.progress,_that.isAdherent,_that.earnedXp);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PeriodSummaryModel summary,  double weeklyPlannedAmount,  double weeklyActualAmount,  double xpValue,  double progress,  bool isAdherent,  double earnedXp)?  $default,) {final _that = this;
switch (_that) {
case _PlanningMission() when $default != null:
return $default(_that.summary,_that.weeklyPlannedAmount,_that.weeklyActualAmount,_that.xpValue,_that.progress,_that.isAdherent,_that.earnedXp);case _:
  return null;

}
}

}

/// @nodoc


class _PlanningMission implements PlanningMission {
  const _PlanningMission({required this.summary, required this.weeklyPlannedAmount, required this.weeklyActualAmount, required this.xpValue, required this.progress, required this.isAdherent, required this.earnedXp});
  

@override final  PeriodSummaryModel summary;
@override final  double weeklyPlannedAmount;
@override final  double weeklyActualAmount;
@override final  double xpValue;
@override final  double progress;
@override final  bool isAdherent;
@override final  double earnedXp;

/// Create a copy of PlanningMission
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanningMissionCopyWith<_PlanningMission> get copyWith => __$PlanningMissionCopyWithImpl<_PlanningMission>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanningMission&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.weeklyPlannedAmount, weeklyPlannedAmount) || other.weeklyPlannedAmount == weeklyPlannedAmount)&&(identical(other.weeklyActualAmount, weeklyActualAmount) || other.weeklyActualAmount == weeklyActualAmount)&&(identical(other.xpValue, xpValue) || other.xpValue == xpValue)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.isAdherent, isAdherent) || other.isAdherent == isAdherent)&&(identical(other.earnedXp, earnedXp) || other.earnedXp == earnedXp));
}


@override
int get hashCode => Object.hash(runtimeType,summary,weeklyPlannedAmount,weeklyActualAmount,xpValue,progress,isAdherent,earnedXp);

@override
String toString() {
  return 'PlanningMission(summary: $summary, weeklyPlannedAmount: $weeklyPlannedAmount, weeklyActualAmount: $weeklyActualAmount, xpValue: $xpValue, progress: $progress, isAdherent: $isAdherent, earnedXp: $earnedXp)';
}


}

/// @nodoc
abstract mixin class _$PlanningMissionCopyWith<$Res> implements $PlanningMissionCopyWith<$Res> {
  factory _$PlanningMissionCopyWith(_PlanningMission value, $Res Function(_PlanningMission) _then) = __$PlanningMissionCopyWithImpl;
@override @useResult
$Res call({
 PeriodSummaryModel summary, double weeklyPlannedAmount, double weeklyActualAmount, double xpValue, double progress, bool isAdherent, double earnedXp
});


@override $PeriodSummaryModelCopyWith<$Res> get summary;

}
/// @nodoc
class __$PlanningMissionCopyWithImpl<$Res>
    implements _$PlanningMissionCopyWith<$Res> {
  __$PlanningMissionCopyWithImpl(this._self, this._then);

  final _PlanningMission _self;
  final $Res Function(_PlanningMission) _then;

/// Create a copy of PlanningMission
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summary = null,Object? weeklyPlannedAmount = null,Object? weeklyActualAmount = null,Object? xpValue = null,Object? progress = null,Object? isAdherent = null,Object? earnedXp = null,}) {
  return _then(_PlanningMission(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as PeriodSummaryModel,weeklyPlannedAmount: null == weeklyPlannedAmount ? _self.weeklyPlannedAmount : weeklyPlannedAmount // ignore: cast_nullable_to_non_nullable
as double,weeklyActualAmount: null == weeklyActualAmount ? _self.weeklyActualAmount : weeklyActualAmount // ignore: cast_nullable_to_non_nullable
as double,xpValue: null == xpValue ? _self.xpValue : xpValue // ignore: cast_nullable_to_non_nullable
as double,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,isAdherent: null == isAdherent ? _self.isAdherent : isAdherent // ignore: cast_nullable_to_non_nullable
as bool,earnedXp: null == earnedXp ? _self.earnedXp : earnedXp // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of PlanningMission
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodSummaryModelCopyWith<$Res> get summary {
  
  return $PeriodSummaryModelCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}

// dart format on
