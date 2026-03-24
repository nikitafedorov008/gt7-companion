// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProfileState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProfileState()';
}


}

/// @nodoc
class $ProfileStateCopyWith<$Res>  {
$ProfileStateCopyWith(ProfileState _, $Res Function(ProfileState) __);
}


/// Adds pattern-matching-related methods to [ProfileState].
extension ProfileStatePatterns on ProfileState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _ProfileStateInitial value)?  initial,TResult Function( _ProfileStateLoading value)?  loading,TResult Function( _ProfileStateLoaded value)?  loaded,TResult Function( _ProfileStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileStateInitial() when initial != null:
return initial(_that);case _ProfileStateLoading() when loading != null:
return loading(_that);case _ProfileStateLoaded() when loaded != null:
return loaded(_that);case _ProfileStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _ProfileStateInitial value)  initial,required TResult Function( _ProfileStateLoading value)  loading,required TResult Function( _ProfileStateLoaded value)  loaded,required TResult Function( _ProfileStateError value)  error,}){
final _that = this;
switch (_that) {
case _ProfileStateInitial():
return initial(_that);case _ProfileStateLoading():
return loading(_that);case _ProfileStateLoaded():
return loaded(_that);case _ProfileStateError():
return error(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _ProfileStateInitial value)?  initial,TResult? Function( _ProfileStateLoading value)?  loading,TResult? Function( _ProfileStateLoaded value)?  loaded,TResult? Function( _ProfileStateError value)?  error,}){
final _that = this;
switch (_that) {
case _ProfileStateInitial() when initial != null:
return initial(_that);case _ProfileStateLoading() when loading != null:
return loading(_that);case _ProfileStateLoaded() when loaded != null:
return loaded(_that);case _ProfileStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( String onlineId,  List<DgEdgePlayerEvent> events,  DgEdgePlayerEventsPagination? pagination,  String? csrfToken)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileStateInitial() when initial != null:
return initial();case _ProfileStateLoading() when loading != null:
return loading();case _ProfileStateLoaded() when loaded != null:
return loaded(_that.onlineId,_that.events,_that.pagination,_that.csrfToken);case _ProfileStateError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( String onlineId,  List<DgEdgePlayerEvent> events,  DgEdgePlayerEventsPagination? pagination,  String? csrfToken)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _ProfileStateInitial():
return initial();case _ProfileStateLoading():
return loading();case _ProfileStateLoaded():
return loaded(_that.onlineId,_that.events,_that.pagination,_that.csrfToken);case _ProfileStateError():
return error(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( String onlineId,  List<DgEdgePlayerEvent> events,  DgEdgePlayerEventsPagination? pagination,  String? csrfToken)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _ProfileStateInitial() when initial != null:
return initial();case _ProfileStateLoading() when loading != null:
return loading();case _ProfileStateLoaded() when loaded != null:
return loaded(_that.onlineId,_that.events,_that.pagination,_that.csrfToken);case _ProfileStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _ProfileStateInitial implements ProfileState {
  const _ProfileStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProfileState.initial()';
}


}




/// @nodoc


class _ProfileStateLoading implements ProfileState {
  const _ProfileStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProfileState.loading()';
}


}




/// @nodoc


class _ProfileStateLoaded implements ProfileState {
  const _ProfileStateLoaded({required this.onlineId, final  List<DgEdgePlayerEvent> events = const <DgEdgePlayerEvent>[], this.pagination, this.csrfToken}): _events = events;
  

 final  String onlineId;
 final  List<DgEdgePlayerEvent> _events;
@JsonKey() List<DgEdgePlayerEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

 final  DgEdgePlayerEventsPagination? pagination;
 final  String? csrfToken;

/// Create a copy of ProfileState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileStateLoadedCopyWith<_ProfileStateLoaded> get copyWith => __$ProfileStateLoadedCopyWithImpl<_ProfileStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileStateLoaded&&(identical(other.onlineId, onlineId) || other.onlineId == onlineId)&&const DeepCollectionEquality().equals(other._events, _events)&&(identical(other.pagination, pagination) || other.pagination == pagination)&&(identical(other.csrfToken, csrfToken) || other.csrfToken == csrfToken));
}


@override
int get hashCode => Object.hash(runtimeType,onlineId,const DeepCollectionEquality().hash(_events),pagination,csrfToken);

@override
String toString() {
  return 'ProfileState.loaded(onlineId: $onlineId, events: $events, pagination: $pagination, csrfToken: $csrfToken)';
}


}

/// @nodoc
abstract mixin class _$ProfileStateLoadedCopyWith<$Res> implements $ProfileStateCopyWith<$Res> {
  factory _$ProfileStateLoadedCopyWith(_ProfileStateLoaded value, $Res Function(_ProfileStateLoaded) _then) = __$ProfileStateLoadedCopyWithImpl;
@useResult
$Res call({
 String onlineId, List<DgEdgePlayerEvent> events, DgEdgePlayerEventsPagination? pagination, String? csrfToken
});




}
/// @nodoc
class __$ProfileStateLoadedCopyWithImpl<$Res>
    implements _$ProfileStateLoadedCopyWith<$Res> {
  __$ProfileStateLoadedCopyWithImpl(this._self, this._then);

  final _ProfileStateLoaded _self;
  final $Res Function(_ProfileStateLoaded) _then;

/// Create a copy of ProfileState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? onlineId = null,Object? events = null,Object? pagination = freezed,Object? csrfToken = freezed,}) {
  return _then(_ProfileStateLoaded(
onlineId: null == onlineId ? _self.onlineId : onlineId // ignore: cast_nullable_to_non_nullable
as String,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<DgEdgePlayerEvent>,pagination: freezed == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as DgEdgePlayerEventsPagination?,csrfToken: freezed == csrfToken ? _self.csrfToken : csrfToken // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _ProfileStateError implements ProfileState {
  const _ProfileStateError(this.message);
  

 final  String message;

/// Create a copy of ProfileState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileStateErrorCopyWith<_ProfileStateError> get copyWith => __$ProfileStateErrorCopyWithImpl<_ProfileStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ProfileState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ProfileStateErrorCopyWith<$Res> implements $ProfileStateCopyWith<$Res> {
  factory _$ProfileStateErrorCopyWith(_ProfileStateError value, $Res Function(_ProfileStateError) _then) = __$ProfileStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$ProfileStateErrorCopyWithImpl<$Res>
    implements _$ProfileStateErrorCopyWith<$Res> {
  __$ProfileStateErrorCopyWithImpl(this._self, this._then);

  final _ProfileStateError _self;
  final $Res Function(_ProfileStateError) _then;

/// Create a copy of ProfileState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_ProfileStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
