import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:gt7_companion/widgets/gtsh_rank_daily_races_display.dart';
import 'package:gt7_companion/models/gtsh_race.dart';
import 'package:gt7_companion/services/gtsh_rank_service.dart';

class FakeGtshRankService extends GtshRankService {
  final List<GtshRace> items;
  FakeGtshRankService(this.items);

  @override
  Future<List<GtshRace>> fetchRunningCards({bool forceRefresh = false}) async {
    return items;
  }
}

void main() {
  testWidgets('GtshRankDailyRacesDisplay shows up to 3 cards only',
      (tester) async {
    final races = List.generate(
      5,
      (i) => GtshRace(
        label: 'A${i + 1}',
        trackName: 'Track${i + 1}',
        tyreCode: 'T${i + 1}',
        pitStops: '-',
        bop: false,
        damage: '',
        startType: '',
        carSettings: false,
        wideFender: '',
      ),
    );

    final fake = FakeGtshRankService(races);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<GtshRankService>.value(
          value: fake,
          child: const Scaffold(body: GtshRankDailyRacesDisplay()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Track1'), findsOneWidget);
    expect(find.text('Track2'), findsOneWidget);
    expect(find.text('Track3'), findsOneWidget);
    expect(find.text('Track4'), findsNothing);
  });
}
