import 'package:flutter/gestures.dart' show PointerDeviceKind, kTouchSlop;
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

  testWidgets('a press whose release never arrives does not silence the next '
      'tap', (tester) async {
    await pumpArea(tester);

    // A press whose release never arrived: the window lost focus mid-press, or
    // the system cancelled the gesture without saying so. Before the recovery
    // this left the tracked pointer occupied and silenced every press that
    // followed, until the app restarted.
    tester.binding.handlePointerEvent(
      const PointerDownEvent(
        position: Offset(50, 50),
        kind: PointerDeviceKind.mouse,
        pointer: 41,
      ),
    );
    await tester.pump();

    final click = await tester.startGesture(
      const Offset(200, 200),
      kind: PointerDeviceKind.mouse,
    );
    await click.up();
    await tester.pump();

    expect(
      player.played,
      [Sfx.tap],
      reason: 'a lost release must cost one gesture, not every gesture',
    );
  });

  testWidgets('a touch that goes quiet is taken over too', (tester) async {
    await pumpArea(tester);

    tester.binding.handlePointerEvent(
      const PointerDownEvent(
        position: Offset(50, 50),
        kind: PointerDeviceKind.touch,
        pointer: 42,
      ),
    );
    await tester.pump();

    // Touch waits out the staleness window, because a second finger held down is
    // a real possibility; a mouse does not have to wait at all.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1100)),
    );

    final press = await tester.startGesture(
      const Offset(200, 200),
      kind: PointerDeviceKind.touch,
    );
    await press.up();
    await tester.pump();

    expect(player.played, [Sfx.tap]);
  });

  testWidgets('a mouse press that drifts is not a tap, as the buttons see it', (
    tester,
  ) async {
    await pumpArea(tester);

    // Six logical pixels: further than the precise pointer's one-pixel slop, far
    // short of the touch slop. Flutter's own buttons reject that press, so this
    // layer must not click for it either.
    final press = await tester.startGesture(
      const Offset(100, 100),
      kind: PointerDeviceKind.mouse,
    );
    await press.moveBy(const Offset(6, 0));
    await press.up();
    await tester.pump();

    expect(player.played, isEmpty);
  });
}
