// START_MODULE_CONTRACT
// PURPOSE: Persist an independent local wishlist of canonical car identifiers.
// SCOPE: Restore, serialized toggles and explicit storage failures; no PSN sync.
// DEPENDS: none
// LINKS: M-REPO-WISHLIST, V-M-REPO-WISHLIST
// END_MODULE_CONTRACT
// START_MODULE_MAP
// WishlistRepository - durable local saved-car membership.
// END_MODULE_MAP
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistRepository extends ChangeNotifier {
  WishlistRepository({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;
  static const storageKey = 'dealer_wishlist_v1';
  final Future<SharedPreferences> Function() _preferences;
  SharedPreferences? _prefs;
  Future<void>? _ready;
  Future<void> _writes = Future.value();
  Set<String> _ids = {};
  bool _disposed = false, _loaded = false, _saving = false;
  String? error;
  List<String> get ids => List.unmodifiable(_ids);
  bool get isLoaded => _loaded;
  bool get isSaving => _saving;
  bool contains(String id) => _ids.contains(id);
  Future<void> load({bool force = false}) {
    if (force && !_loaded) _ready = null;
    return _ready ??= _load();
  }

  Future<void> _load() async {
    try {
      _prefs = await _preferences();
      _ids = (_prefs!.getStringList(storageKey) ?? []).where(_valid).toSet();
      _loaded = true;
      error = null;
    } catch (_) {
      error = 'storage';
    }
    _notify();
  }

  static bool _valid(String id) => RegExp(r'^car\d+$').hasMatch(id);
  Future<bool> toggle(String id) {
    if (!_valid(id)) return Future.value(false);
    final operation = _writes.then((_) async {
      if (!_loaded) {
        await load(force: error != null);
      }
      if (!_loaded || _disposed) return false;
      _saving = true;
      error = null;
      _notify();
      final next = {..._ids};
      next.contains(id) ? next.remove(id) : next.add(id);
      try {
        if (!await _prefs!.setStringList(storageKey, next.toList())) {
          throw StateError('Storage rejected write');
        }
        _ids = next;
        return true;
      } catch (_) {
        error = 'storage';
        return false;
      } finally {
        _saving = false;
        _notify();
      }
    });
    _writes = operation.then<void>((_) {});
    return operation;
  }

  Future<void> flush() => _writes;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
