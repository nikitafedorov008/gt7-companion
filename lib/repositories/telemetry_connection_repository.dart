import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/telemetry/console_candidate.dart';
import '../services/app_settings_service.dart';
import '../services/console_discovery_service.dart';
import '../services/telemetry_service.dart';

enum ConnectionPhase {
  manual,
  searching,
  waiting,
  live,
  lost,
  choose,
  notFound,
  unavailable,
  demo,
}

/// Owns automatic attempts and packet freshness; the dashboard's socket remains
/// in TelemetryService. Generation checks prevent cancelled work reconnecting.
class TelemetryConnectionRepository extends ChangeNotifier
    with WidgetsBindingObserver {
  TelemetryConnectionRepository(
    this.settings,
    this.telemetry,
    this.discovery, {
    this.waitBudget = const Duration(seconds: 6),
    this.retryDelay = const Duration(seconds: 30),
    this.staleAfter = const Duration(seconds: 5),
  }) {
    WidgetsBinding.instance.addObserver(this);
    settings.addListener(_settingsChanged);
    telemetry.addListener(_telemetryChanged);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _freshness = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _telemetryChanged(),
    );
    unawaited(_initialize());
  }
  final AppSettingsService settings;
  final TelemetryService telemetry;
  final ConsoleDiscoveryService discovery;
  final Duration waitBudget, retryDelay, staleAfter;
  ConnectionPhase phase = ConnectionPhase.manual;
  List<ConsoleCandidate> candidates = [];
  String? address;
  String? consoleName;
  bool _foreground = true, _disposed = false, _suppressed = false;
  bool _autoAttempt = false, _manualBusy = false;
  int _generation = 0;
  Timer? _retry, _freshness, _waitTimer;
  Completer<bool>? _waiter;
  bool? _previousAuto;
  bool get hasFreshData =>
      telemetry.isConnected &&
      !telemetry.isDemo &&
      telemetry.receivedAt != null &&
      DateTime.now().difference(telemetry.receivedAt!) < staleAfter &&
      telemetry.telemetry != null;

  Future<void> _initialize() async {
    await settings.load();
    if (_disposed) return;
    _settingsChanged();
  }

  void _set(ConnectionPhase value) {
    if (_disposed || phase == value) return;
    phase = value;
    notifyListeners();
  }

  void _settingsChanged() {
    if (!settings.isLoaded || _disposed) return;
    final enabled = settings.autoTelemetry;
    if (_previousAuto == enabled) return;
    _previousAuto = enabled;
    if (!enabled) {
      _cancel();
      if (!hasFreshData && !telemetry.isDemo) _set(ConnectionPhase.manual);
    } else {
      _suppressed = false;
      unawaited(search());
    }
  }

  void _telemetryChanged() {
    if (_disposed) return;
    if (telemetry.isDemo) {
      if (_autoAttempt) _cancel();
      _set(ConnectionPhase.demo);
      return;
    }
    if (!telemetry.isConnected &&
        !_autoAttempt &&
        !_manualBusy &&
        (phase == ConnectionPhase.live || phase == ConnectionPhase.waiting)) {
      _cancel();
      if (telemetry.errorMessage != null) {
        // Socket failures permit recovery; only user disconnects suppress it.
        _set(ConnectionPhase.lost);
        _scheduleRetry();
      } else {
        _suppressed = true;
        _set(ConnectionPhase.manual);
      }
      return;
    }
    if (hasFreshData) {
      address = telemetry.connectedAddress ?? address;
      if (address != null) unawaited(settings.confirmConsole(address!));
      final waiter = _waiter;
      if (waiter != null && !waiter.isCompleted) waiter.complete(true);
      _set(ConnectionPhase.live);
    } else if (phase == ConnectionPhase.live) {
      _set(ConnectionPhase.lost);
      _scheduleRetry();
    } else if (phase == ConnectionPhase.demo && !telemetry.isDemo) {
      _suppressed = true;
      _set(ConnectionPhase.manual);
    }
  }

  void _cancel() {
    _generation++;
    discovery.cancel();
    _retry?.cancel();
    _waitTimer?.cancel();
    final waiter = _waiter;
    _waiter = null;
    if (waiter != null && !waiter.isCompleted) waiter.complete(false);
    // Only cancel sockets belonging to an unfinished automatic attempt.
    if (_autoAttempt && !hasFreshData && !telemetry.isDemo)
      unawaited(telemetry.disconnect());
    _autoAttempt = false;
  }

  bool _valid(int generation) =>
      !_disposed && _foreground && generation == _generation;

  Future<bool> _tryAddress(String target, int generation) async {
    address = target;
    _set(ConnectionPhase.waiting);
    final waiter = Completer<bool>();
    _waiter = waiter;
    _waitTimer = Timer(waitBudget, () {
      if (!waiter.isCompleted) waiter.complete(false);
    });
    await telemetry.connectToGT7(target);
    if (!_valid(generation)) return false;
    _telemetryChanged();
    final result = await waiter.future;
    if (_waiter == waiter) {
      _waiter = null;
      _waitTimer?.cancel();
    }
    return _valid(generation) && result;
  }

  Future<void> search({bool explicit = false}) async {
    if (_disposed ||
        !_foreground ||
        _manualBusy ||
        telemetry.isDemo ||
        hasFreshData ||
        _autoAttempt)
      return;
    if (!explicit && (!settings.autoTelemetry || _suppressed)) return;
    _cancel();
    _suppressed = false;
    final generation = _generation;
    _autoAttempt = true;
    candidates = [];
    consoleName = null;
    final saved = settings.confirmedConsole;
    try {
      if (saved != null && await _tryAddress(saved, generation)) return;
      if (!_valid(generation)) return;
      await telemetry.disconnect();
      if (!_valid(generation)) return;
      if (!discovery.broadcastAvailable) {
        // A known address remains retryable even when DDP broadcast is absent.
        _set(
          saved == null ? ConnectionPhase.unavailable : ConnectionPhase.lost,
        );
        return;
      }
      _set(ConnectionPhase.searching);
      final found = await discovery.discover();
      if (!_valid(generation)) return;
      candidates = found.where((c) => c.active).toList();
      if (candidates.isEmpty) {
        _set(ConnectionPhase.notFound);
        return;
      }
      ConsoleCandidate? chosen;
      if (candidates.length == 1) {
        chosen = candidates.single;
      } else {
        chosen = candidates.where((c) => c.address == saved).firstOrNull;
      }
      if (chosen == null) {
        _set(ConnectionPhase.choose);
        return;
      }
      consoleName = chosen.name;
      if (!await _tryAddress(chosen.address, generation) &&
          _valid(generation)) {
        await telemetry.disconnect();
        if (_valid(generation)) _set(ConnectionPhase.lost);
      }
    } catch (_) {
      if (_valid(generation)) _set(ConnectionPhase.notFound);
    } finally {
      if (_valid(generation)) {
        _autoAttempt = false;
        _scheduleRetry();
      }
    }
  }

  void _scheduleRetry() {
    _retry?.cancel();
    if (_disposed ||
        !_foreground ||
        !settings.autoTelemetry ||
        _suppressed ||
        phase == ConnectionPhase.choose ||
        phase == ConnectionPhase.unavailable ||
        telemetry.isDemo)
      return;
    _retry = Timer(retryDelay, () => unawaited(search()));
  }

  Future<void> connectManual(String target, {String? name}) async {
    _cancel();
    _suppressed = true;
    _manualBusy = true;
    consoleName = name;
    address = target;
    _set(ConnectionPhase.waiting);
    try {
      await telemetry.connectToGT7(target);
    } finally {
      _manualBusy = false;
    }
    if (!_disposed && telemetry.errorMessage != null)
      _set(ConnectionPhase.notFound);
  }

  Future<void> disconnect() async {
    _suppressed = true;
    _cancel();
    await telemetry.disconnect();
    _set(ConnectionPhase.manual);
  }

  Future<void> startDemo() async {
    _cancel();
    _suppressed = true;
    await telemetry.startDemoTelemetry();
    _set(ConnectionPhase.demo);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      final unfinished = _autoAttempt;
      _cancel();
      if (unfinished && !hasFreshData) _set(ConnectionPhase.manual);
    } else if (settings.autoTelemetry && !_suppressed) {
      unawaited(search());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cancel();
    _freshness?.cancel();
    settings.removeListener(_settingsChanged);
    telemetry.removeListener(_telemetryChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
