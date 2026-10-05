import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/models/sfx.dart';
import 'package:gt7_companion/router/sound_navigator_observer.dart';
import 'package:gt7_companion/services/sfx_player.dart';
import 'package:gt7_companion/services/sound_service.dart';

/// Records what the observer asked for.
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
  late SoundService sound;

  setUp(() {
    player = _FakeSfxPlayer();
    sound = SoundService(player: player, enabled: true);
  });

  tearDown(() => sound.dispose());

  /// A navigator carrying the observer, with a page to push and a dialog to open.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [SoundNavigatorObserver(sound)],
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: Text('second')),
                    ),
                  ),
                  child: const Text('push'),
                ),
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const AlertDialog(title: Text('hi')),
                  ),
                  child: const Text('dialog'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('opening and closing a popup sounds open and close', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(
      player.played,
      isEmpty,
      reason: 'the first route is the app opening, not something the user did',
    );

    await tester.tap(find.text('dialog'));
    await tester.pumpAndSettle();
    expect(player.played, [Sfx.open]);

    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(player.played, [Sfx.open, Sfx.close]);
  });

  testWidgets('a page push and pop sound navigate and back', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(player.played, [Sfx.navigate]);

    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(player.played, [Sfx.navigate, Sfx.back]);
  });
}
