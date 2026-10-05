import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/models/sfx.dart';
import 'package:gt7_companion/services/sfx_player.dart';
import 'package:gt7_companion/services/sound_service.dart';
import 'package:gt7_companion/widgets/tap_sound_area.dart';
import 'package:provider/provider.dart';

/// Records what the interface asked for, so the interceptor can be judged
/// without a device and without touching a platform channel.
class _FakeSfxPlayer implements SfxPlayer {
  final List<Sfx> played = [];

  @override
  Future<void> preload(Iterable<Sfx> sounds) async {}

  @override
  Future<void> play(Sfx sound, {required double volume}) async =>
      played.add(sound);

  @override
  Future<void> dispose() async {}
}

void main() {
  late _FakeSfxPlayer player;

  setUp(() => player = _FakeSfxPlayer());

  /// The interceptor over an empty surface, with sound switched on.
  Future<void> pumpArea(WidgetTester tester) async {
    final sound = SoundService(player: player, enabled: true);
    addTearDown(sound.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<SoundService>.value(
        value: sound,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: TapSoundArea(child: SizedBox.expand()),
        ),
      ),
    );
  }

  testWidgets('a genuine tap plays the press sound once', (tester) async {
    await pumpArea(tester);

    await tester.tapAt(const Offset(100, 100));
    await tester.pump();

    expect(player.played, [Sfx.tap]);
  });

  testWidgets('a drag stays silent', (tester) async {
    await pumpArea(tester);

    final gesture = await tester.startGesture(const Offset(100, 100));
    await gesture.moveBy(const Offset(0, kTouchSlop * 3));
    await gesture.up();
    await tester.pump();

    expect(
      player.played,
      isEmpty,
      reason: 'scrolling a list must not click',
    );
  });

  testWidgets('a drag that returns to where it started is still a drag', (
    tester,
  ) async {
    await pumpArea(tester);

    final gesture = await tester.startGesture(const Offset(100, 100));
    await gesture.moveBy(const Offset(0, kTouchSlop * 3));
    await gesture.moveBy(const Offset(0, -kTouchSlop * 3));
    await gesture.up();
    await tester.pump();

    expect(player.played, isEmpty);
  });

  testWidgets('sound switched off keeps even a genuine tap quiet', (
    tester,
  ) async {
    final sound = SoundService(player: player, enabled: false);
    addTearDown(sound.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<SoundService>.value(
        value: sound,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: TapSoundArea(child: SizedBox.expand()),
        ),
      ),
    );

    await tester.tapAt(const Offset(100, 100));
    await tester.pump();

    expect(player.played, isEmpty);
  });
}
