import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:gt7_companion/models/daily_races/track_image_assets.dart';
import 'package:gt7_companion/models/daily_races/daily_race.dart';
import 'package:gt7_companion/models/dg_edge/dg_edge_daily_race.dart';
import 'package:gt7_companion/services/dg_edge_service.dart';
import 'package:gt7_companion/widgets/daily_races/daily_race_card.dart';
import 'package:gt7_companion/widgets/daily_races/daily_race_details_sheet.dart';
import 'package:gt7_companion/widgets/daily_races/track_artwork.dart';

void main() {
  test(
    'all published track configurations have all three local roles and no profiles',
    () {
      final data =
          jsonDecode(
                File('assets/tracks/artwork_catalogue.json').readAsStringSync(),
              )
              as Map;
      expect(bundledTrackArtworkUrls.length, (data['tracks'] as Map).length);
      for (final roles in bundledTrackArtworkUrls.values) {
        expect(roles.keys.toSet(), {'track', 'logo', 'background'});
        for (final url in roles.values) {
          expect(bundledTrackImages[url], startsWith('assets/track_images/'));
        }
      }
      for (final url in bundledTrackImages.keys) {
        expect(
          Uri.parse(url).path,
          anyOf(startsWith('/images/tracks/'), startsWith('/images/course/')),
        );
        expect(url.toLowerCase(), isNot(contains('avatar')));
        expect(url.toLowerCase(), isNot(contains('profile')));
      }
    },
  );
  test('new source URLs and JSON roundtrip preserve SUGO artwork', () {
    final body = File(
      'test/fixtures/dailies_page_2026_11.html',
    ).readAsStringSync();
    final races = DgEdgeService().parseListPage(
      html.parse(body),
      baseUrl: 'https://www.dg-edge.com',
    );
    for (final race in races) {
      expect(bundledTrackImages[race.trackImage], isNotNull);
      expect(bundledTrackImages[race.trackLogotype], isNotNull);
      expect(bundledTrackImages[race.trackBackgroundImage], isNotNull);
      final restored = DgEdgeDailyRace.fromJson(race.toJson());
      expect(restored.trackLogotype, race.trackLogotype);
      expect(restored.trackBackgroundImage, race.trackBackgroundImage);
    }
    final sugo = const DgEdgeDailyRace(
      id: 'sugo',
      title: 'SUGO',
      url: '',
      trackId: '392',
    );
    expect(sugo.trackLogotype, contains('logo1340-new.webp'));
    expect(sugo.trackBackgroundImage, contains('back1340-new.webp'));
  });
  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'real race card and details use assets at $width with test HTTP denied',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const source = DgEdgeDailyRace(
          id: 'sugo',
          title: 'Daily A',
          url: '',
          trackId: '392',
          trackName: 'SUGO',
          raceLetter: 'A',
          laps: 5,
        );
        final race = DailyRace.fromPair(source, null);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 350,
                  height: 420,
                  child: DailyRaceCard(race: race),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(TrackArtwork), findsNWidgets(2));
        expect(find.byType(CachedNetworkImage), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(DailyRaceCard));
        await tester.pumpAndSettle();
        expect(find.byType(DailyRaceDetailsSheet), findsOneWidget);
        expect(find.byType(TrackArtwork), findsAtLeastNWidgets(3));
        expect(find.byType(CachedNetworkImage), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('unknown future URL falls back to a local known track', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TrackArtwork(url: '', trackId: '392', role: 'background'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
