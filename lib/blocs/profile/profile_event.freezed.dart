// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProfileEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProfileEvent()';
}


}

/// @nodoc
class $ProfileEventCopyWith<$Res>  {
$ProfileEventCopyWith(ProfileEvent _, $Res Function(ProfileEvent) __);
}


/// Adds pattern-matching-related methods to [ProfileEvent].
extension ProfileEventPatterns on ProfileEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _LoadPlayer value)?  loadPlayer,TResult Function( _SendBannerImpressions value)?  sendBannerImpressions,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoadPlayer() when loadPlayer != null:
return loadPlayer(_that);case _SendBannerImpressions() when sendBannerImpressions != null:
return sendBannerImpressions(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _LoadPlayer value)  loadPlayer,required TResult Function( _SendBannerImpressions value)  sendBannerImpressions,}){
final _that = this;
switch (_that) {
case _LoadPlayer():
return loadPlayer(_that);case _SendBannerImpressions():
return sendBannerImpressions(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _LoadPlayer value)?  loadPlayer,TResult? Function( _SendBannerImpressions value)?  sendBannerImpressions,}){
final _that = this;
switch (_that) {
case _LoadPlayer() when loadPlayer != null:
return loadPlayer(_that);case _SendBannerImpressions() when sendBannerImpressions != null:
return sendBannerImpressions(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String onlineId,  int page)?  loadPlayer,TResult Function( List<int> impressions)?  sendBannerImpressions,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoadPlayer() when loadPlayer != null:
return loadPlayer(_that.onlineId,_that.page);case _SendBannerImpressions() when sendBannerImpressions != null:
return sendBannerImpressions(_that.impressions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String onlineId,  int page)  loadPlayer,required TResult Function( List<int> impressions)  sendBannerImpressions,}) {final _that = this;
switch (_that) {
case _LoadPlayer():
return loadPlayer(_that.onlineId,_that.page);case _SendBannerImpressions():
return sendBannerImpressions(_that.impressions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String onlineId,  int page)?  loadPlayer,TResult? Function( List<int> impressions)?  sendBannerImpressions,}) {final _that = this;
switch (_that) {
case _LoadPlayer() when loadPlayer != null:
return loadPlayer(_that.onlineId,_that.page);case _SendBannerImpressions() when sendBannerImpressions != null:
return sendBannerImpressions(_that.impressions);case _:
  return null;

}
}

}

/// @nodoc


class _LoadPlayer implements ProfileEvent {
  const _LoadPlayer({required this.onlineId, this.page = 1});
  

 final  String onlineId;
@JsonKey() final  int page;

/// Create a copy of ProfileEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadPlayerCopyWith<_LoadPlayer> get copyWith => __$LoadPlayerCopyWithImpl<_LoadPlayer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadPlayer&&(identical(other.onlineId, onlineId) || other.onlineId == onlineId)&&(identical(other.page, page) || other.page == page));
}


@override
int get hashCode => Object.hash(runtimeType,onlineId,page);

@override
String toString() {
  return 'ProfileEvent.loadPlayer(onlineId: $onlineId, page: $page)';
}


}

/// @nodoc
abstract mixin class _$LoadPlayerCopyWith<$Res> implements $ProfileEventCopyWith<$Res> {
  factory _$LoadPlayerCopyWith(_LoadPlayer value, $Res Function(_LoadPlayer) _then) = __$LoadPlayerCopyWithImpl;
@useResult
$Res call({
 String onlineId, int page
});




}
/// @nodoc
class __$LoadPlayerCopyWithImpl<$Res>
    implements _$LoadPlayerCopyWith<$Res> {
  __$LoadPlayerCopyWithImpl(this._self, this._then);

  final _LoadPlayer _self;
  final $Res Function(_LoadPlayer) _then;

/// Create a copy of ProfileEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? onlineId = null,Object? page = null,}) {
  return _then(_LoadPlayer(
onlineId: null == onlineId ? _self.onlineId : onlineId // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _SendBannerImpressions implements ProfileEvent {
  const _SendBannerImpressions({required final  List<int> impressions}): _impressions = impressions;
  

 final  List<int> _impressions;
 List<int> get impressions {
  if (_impressions is EqualUnmodifiableListView) return _impressions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_impressions);
}


/// Create a copy of ProfileEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SendBannerImpressionsCopyWith<_SendBannerImpressions> get copyWith => __$SendBannerImpressionsCopyWithImpl<_SendBannerImpressions>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SendBannerImpressions&&const DeepCollectionEquality().equals(other._impressions, _impressions));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_impressions));

@override
String toString() {
  return 'ProfileEvent.sendBannerImpressions(impressions: $impressions)';
}


}

/// @nodoc
abstract mixin class _$SendBannerImpressionsCopyWith<$Res> implements $ProfileEventCopyWith<$Res> {
  factory _$SendBannerImpressionsCopyWith(_SendBannerImpressions value, $Res Function(_SendBannerImpressions) _then) = __$SendBannerImpressionsCopyWithImpl;
@useResult
$Res call({
 List<int> impressions
});




}
/// @nodoc
class __$SendBannerImpressionsCopyWithImpl<$Res>
    implements _$SendBannerImpressionsCopyWith<$Res> {
  __$SendBannerImpressionsCopyWithImpl(this._self, this._then);

  final _SendBannerImpressions _self;
  final $Res Function(_SendBannerImpressions) _then;

/// Create a copy of ProfileEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? impressions = null,}) {
  return _then(_SendBannerImpressions(
impressions: null == impressions ? _self._impressions : impressions // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

// dart format on
