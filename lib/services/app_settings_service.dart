// START_MODULE_CONTRACT
// PURPOSE: Own the persisted application language and follow OS locale changes.
// SCOPE: System/Russian/English choice, locale resolution and local persistence.
// DEPENDS: none
// LINKS: M-SETTINGS, V-M-SETTINGS
// END_MODULE_CONTRACT
// START_MODULE_MAP
// AppSettingsService - observable application preferences.
// AppLanguage - stable stored language choices.
// END_MODULE_MAP
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { system, russian, english }

class AppSettingsService extends ChangeNotifier with WidgetsBindingObserver {
  AppSettingsService({List<Locale>? systemLocales})
    : _systemLocales = systemLocales ?? PlatformDispatcher.instance.locales {
    WidgetsBinding.instance.addObserver(this);
  }
  static const languageKey = 'app_language_v1';
  static const autoTelemetryKey = 'telemetry_auto_connect_v1';
  static const confirmedConsoleKey = 'telemetry_confirmed_console_v1';
  bool autoTelemetry = true;
  String? confirmedConsole;
  List<Locale> _systemLocales;
  AppLanguage _language = AppLanguage.system;
  Future<void>? _loading;
  Future<void> _saving = Future.value();
  bool _loaded = false;
  bool _disposed = false;
  String? storageError;
  AppLanguage get language => _language;
  bool get isLoaded => _loaded;
  Locale? get locale => switch (_language) {
    AppLanguage.system => null,
    AppLanguage.russian => const Locale('ru'),
    AppLanguage.english => const Locale('en'),
  };
  Locale get effectiveLocale {
    if (locale != null) return locale!;
    for (final value in _systemLocales) {
      if (value.languageCode == 'ru' || value.languageCode == 'en') {
        return Locale(value.languageCode);
      }
    }
    return const Locale('en');
  }

  Future<void> load() => _loading ??= _restore();
  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      autoTelemetry = prefs.getBool(autoTelemetryKey) ?? true;
      confirmedConsole = prefs.getString(confirmedConsoleKey);
      final stored = prefs.getString(languageKey);
      _language =
          AppLanguage.values.where((v) => v.name == stored).firstOrNull ??
          AppLanguage.system;
    } catch (error) {
      storageError = 'Could not restore application preferences.';
      debugPrint('AppSettingsService: $error');
    } finally {
      if (!_disposed) {
        _loaded = true;
        Intl.defaultLocale = effectiveLocale.languageCode;
        notifyListeners();
      }
    }
  }

  Future<void> setLanguage(AppLanguage value) async {
    await load();
    if (_disposed || value == _language) return;
    _language = value;
    storageError = null;
    Intl.defaultLocale = effectiveLocale.languageCode;
    notifyListeners();
    // Preserve the order of rapid choices even when platform storage is slow.
    _saving = _saving.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (!await prefs.setString(languageKey, value.name)) {
          throw StateError('Preferences write failed');
        }
      } catch (error) {
        if (!_disposed) {
          storageError =
              'Could not save application preferences. Please retry.';
          notifyListeners();
        }
        debugPrint('AppSettingsService: $error');
      }
    });
    await _saving;
  }

  Future<void> setAutoTelemetry(bool value) async {
    await load();
    if (_disposed || value == autoTelemetry) return;
    autoTelemetry = value;
    notifyListeners();
    await _persistTelemetry(autoTelemetryKey, value);
  }

  Future<void> confirmConsole(String address) async {
    await load();
    if (_disposed || confirmedConsole == address) return;
    confirmedConsole = address;
    await _persistTelemetry(confirmedConsoleKey, address);
  }

  Future<void> _persistTelemetry(String key, Object value) async {
    _saving = _saving.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final success = value is bool
            ? await prefs.setBool(key, value)
            : await prefs.setString(key, value as String);
        if (!success) throw StateError('Preferences write failed');
      } catch (_) {
        if (!_disposed) {
          storageError =
              'Could not save application preferences. Please retry.';
          notifyListeners();
        }
      }
    });
    await _saving;
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    _systemLocales = locales ?? const [];
    if (_language == AppLanguage.system && !_disposed) {
      Intl.defaultLocale = effectiveLocale.languageCode;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
