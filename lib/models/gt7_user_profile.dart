/// GT7 user profile data from the official web API.
///
/// Fetched via `POST web-api.gt7.game.gran-turismo.com/user/get_user_profile`
/// using a Bearer token obtained from `/gt7/info/api/token/`.
class Gt7UserProfile {
  final String nickName;
  final String npOnlineId; // PSN online ID
  final String aboutMe;
  final String greeting;
  final String greetingPostRace;
  final String countryCode;
  final int avatarPhotoId;
  final int coverPhotoId;
  final int driverPhotoId;
  final String userId;

  /// Full image URLs (if scraped from the profile page HTML).
  /// These contain the opaque hash that cannot be derived from photo IDs alone.
  final String? avatarUrl;
  final String? coverUrl;
  final String? driverUrl;

  const Gt7UserProfile({
    required this.nickName,
    required this.npOnlineId,
    required this.aboutMe,
    required this.greeting,
    required this.greetingPostRace,
    required this.countryCode,
    required this.avatarPhotoId,
    required this.coverPhotoId,
    required this.driverPhotoId,
    required this.userId,
    this.avatarUrl,
    this.coverUrl,
    this.driverUrl,
  });

  factory Gt7UserProfile.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>? ?? json;
    return Gt7UserProfile(
      nickName: result['nick_name'] as String? ?? '',
      npOnlineId: result['np_online_id'] as String? ?? '',
      aboutMe: result['about_me'] as String? ?? '',
      greeting: result['greeting'] as String? ?? '',
      greetingPostRace: result['greeting_post_race'] as String? ?? '',
      countryCode: result['country_code'] as String? ?? '',
      avatarPhotoId: result['avatar_photo_id'] as int? ?? 0,
      coverPhotoId: result['cover_photo_id'] as int? ?? 0,
      driverPhotoId: result['driver_photo_id'] as int? ?? 0,
      userId: result['user_id'] as String? ?? '',
      avatarUrl: result['avatar_url'] as String?,
      coverUrl: result['cover_url'] as String?,
      driverUrl: result['driver_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'nick_name': nickName,
    'np_online_id': npOnlineId,
    'about_me': aboutMe,
    'greeting': greeting,
    'greeting_post_race': greetingPostRace,
    'country_code': countryCode,
    'avatar_photo_id': avatarPhotoId,
    'cover_photo_id': coverPhotoId,
    'driver_photo_id': driverPhotoId,
    'user_id': userId,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    if (coverUrl != null) 'cover_url': coverUrl,
    if (driverUrl != null) 'driver_url': driverUrl,
  };

  @override
  String toString() =>
      'Gt7UserProfile(nickName: $nickName, npOnlineId: $npOnlineId, country: $countryCode)';
}
