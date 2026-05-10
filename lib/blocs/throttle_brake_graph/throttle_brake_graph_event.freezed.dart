// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'throttle_brake_graph_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ThrottleBrakeGraphEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ThrottleBrakeGraphEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ThrottleBrakeGraphEvent()';
}


}

/// @nodoc
class $ThrottleBrakeGraphEventCopyWith<$Res>  {
$ThrottleBrakeGraphEventCopyWith(ThrottleBrakeGraphEvent _, $Res Function(ThrottleBrakeGraphEvent) __);
}


/// Adds pattern-matching-related methods to [ThrottleBrakeGraphEvent].
extension ThrottleBrakeGraphEventPatterns on ThrottleBrakeGraphEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initialize value)?  initialize,TResult Function( _TelemetryUpdated value)?  telemetryUpdated,TResult Function( _Clear value)?  clear,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initialize() when initialize != null:
return initialize(_that);case _TelemetryUpdated() when telemetryUpdated != null:
return telemetryUpdated(_that);case _Clear() when clear != null:
return clear(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initialize value)  initialize,required TResult Function( _TelemetryUpdated value)  telemetryUpdated,required TResult Function( _Clear value)  clear,}){
final _that = this;
switch (_that) {
case _Initialize():
return initialize(_that);case _TelemetryUpdated():
return telemetryUpdated(_that);case _Clear():
return clear(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initialize value)?  initialize,TResult? Function( _TelemetryUpdated value)?  telemetryUpdated,TResult? Function( _Clear value)?  clear,}){
final _that = this;
switch (_that) {
case _Initialize() when initialize != null:
return initialize(_that);case _TelemetryUpdated() when telemetryUpdated != null:
return telemetryUpdated(_that);case _Clear() when clear != null:
return clear(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initialize,TResult Function( double throttle,  double brake,  DateTime timestamp)?  telemetryUpdated,TResult Function()?  clear,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initialize() when initialize != null:
return initialize();case _TelemetryUpdated() when telemetryUpdated != null:
return telemetryUpdated(_that.throttle,_that.brake,_that.timestamp);case _Clear() when clear != null:
return clear();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initialize,required TResult Function( double throttle,  double brake,  DateTime timestamp)  telemetryUpdated,required TResult Function()  clear,}) {final _that = this;
switch (_that) {
case _Initialize():
return initialize();case _TelemetryUpdated():
return telemetryUpdated(_that.throttle,_that.brake,_that.timestamp);case _Clear():
return clear();case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initialize,TResult? Function( double throttle,  double brake,  DateTime timestamp)?  telemetryUpdated,TResult? Function()?  clear,}) {final _that = this;
switch (_that) {
case _Initialize() when initialize != null:
return initialize();case _TelemetryUpdated() when telemetryUpdated != null:
return telemetryUpdated(_that.throttle,_that.brake,_that.timestamp);case _Clear() when clear != null:
return clear();case _:
  return null;

}
}

}

/// @nodoc


class _Initialize implements ThrottleBrakeGraphEvent {
  const _Initialize();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initialize);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ThrottleBrakeGraphEvent.initialize()';
}


}




/// @nodoc


class _TelemetryUpdated implements ThrottleBrakeGraphEvent {
  const _TelemetryUpdated({required this.throttle, required this.brake, required this.timestamp});
  

 final  double throttle;
 final  double brake;
 final  DateTime timestamp;

/// Create a copy of ThrottleBrakeGraphEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TelemetryUpdatedCopyWith<_TelemetryUpdated> get copyWith => __$TelemetryUpdatedCopyWithImpl<_TelemetryUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TelemetryUpdated&&(identical(other.throttle, throttle) || other.throttle == throttle)&&(identical(other.brake, brake) || other.brake == brake)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}


@override
int get hashCode => Object.hash(runtimeType,throttle,brake,timestamp);

@override
String toString() {
  return 'ThrottleBrakeGraphEvent.telemetryUpdated(throttle: $throttle, brake: $brake, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$TelemetryUpdatedCopyWith<$Res> implements $ThrottleBrakeGraphEventCopyWith<$Res> {
  factory _$TelemetryUpdatedCopyWith(_TelemetryUpdated value, $Res Function(_TelemetryUpdated) _then) = __$TelemetryUpdatedCopyWithImpl;
@useResult
$Res call({
 double throttle, double brake, DateTime timestamp
});




}
/// @nodoc
class __$TelemetryUpdatedCopyWithImpl<$Res>
    implements _$TelemetryUpdatedCopyWith<$Res> {
  __$TelemetryUpdatedCopyWithImpl(this._self, this._then);

  final _TelemetryUpdated _self;
  final $Res Function(_TelemetryUpdated) _then;

/// Create a copy of ThrottleBrakeGraphEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? throttle = null,Object? brake = null,Object? timestamp = null,}) {
  return _then(_TelemetryUpdated(
throttle: null == throttle ? _self.throttle : throttle // ignore: cast_nullable_to_non_nullable
as double,brake: null == brake ? _self.brake : brake // ignore: cast_nullable_to_non_nullable
as double,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class _Clear implements ThrottleBrakeGraphEvent {
  const _Clear();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Clear);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ThrottleBrakeGraphEvent.clear()';
}


}




// dart format on
