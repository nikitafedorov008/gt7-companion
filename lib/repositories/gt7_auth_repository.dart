import 'package:flutter/foundation.dart';

import '../models/gt7_user_profile.dart';
import '../services/gt7_api_service.dart';
import '../services/gt7_auth_service.dart';

/// Repository that coordinates authentication and profile data from the
/// GT7 web API.
///
/// Wraps [Gt7AuthService] (token management) and [Gt7ApiService] (data
/// fetching) behind a single interface consumed by BLoCs and widgets.
abstract class Gt7AuthRepository extends ChangeNotifier {
  bool get isAuthenticated;
  bool get isLoading;
  String? get error;
  Gt7UserProfile? get profile;
  String? get accessToken;

  /// Initialize — load any saved token.
  Future<void> init();

  /// Fetch or refresh the user profile from the GT7 API.
  Future<Gt7UserProfile?> fetchProfile();

  /// Log out and clear all auth state.
  Future<void> logout();
}

class Gt7AuthRepositoryImpl extends Gt7AuthRepository {
  Gt7AuthRepositoryImpl(this._authService, this._apiService);

  final Gt7AuthService _authService;
  final Gt7ApiService _apiService;

  @override
  bool get isAuthenticated => _authService.isAuthenticated;

  @override
  bool get isLoading => _authService.isLoading || _apiService.isLoading;

  @override
  String? get error => _authService.error ?? _apiService.error;

  @override
  Gt7UserProfile? get profile => _apiService.profile;

  @override
  String? get accessToken => _authService.accessToken;

  /// The auth service — exposed so the login page can interact with the
  /// WebView and call [Gt7AuthService.extractTokenFromWebView].
  Gt7AuthService get authService => _authService;

  @override
  Future<void> init() async {
    await _authService.init();
    // If we have a valid token, try to load the profile immediately.
    if (_authService.isAuthenticated) {
      await fetchProfile();
    }
    notifyListeners();
  }

  @override
  Future<Gt7UserProfile?> fetchProfile() async {
    // Pulls the profile plus sport profile, race records and month history —
    // everything the profile screen renders.
    await _apiService.fetchAll();
    notifyListeners();
    return _apiService.profile;
  }

  @override
  Future<void> logout() async {
    await _authService.logout();
    _apiService.clear();
    notifyListeners();
  }

  /// Called after a successful WebView login to exchange the session cookie
  /// for an API token.
  ///
  /// Takes no WebView handle: the cookie jar is process-wide, so the exchange
  /// reads JSESSIONID without going through a controller.
  Future<bool> onLoginSuccess() async {
    final ok = await _authService.exchangeSessionForToken();
    if (ok) {
      await fetchProfile();
    }
    notifyListeners();
    return ok;
  }
}
