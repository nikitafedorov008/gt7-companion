import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/widgets/daily_races/daily_races_display.dart';
import 'package:provider/provider.dart';

import 'package:gt7_companion/repositories/sport_repository.dart';
import 'package:gt7_companion/models/dg_edge/dg_edge_daily_race.dart';
import 'package:gt7_companion/models/daily_races/daily_race.dart';

class FakeSportRepository extends ChangeNotifier implements SportRepository {
  final List<DailyRace> _items;
  bool _loading = false;
  String? _error;

  FakeSportRepository(this._items);

  @override
  List<DailyRace> get dailyRaces => _items;

  @override
  bool get isLoading => _loading;

  @override
  String? get error => _error;

  @override
  Future<void> fetchDailyRaces({bool forceRefresh = false}) async {
    _loading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 10));
    _loading = false;
    notifyListeners();
  }
}

void main() {
  testWidgets('DailyRacesDisplay shows up to 3 cards only', (tester) async {
    final races = List.generate(5, (i) {
      // make the very first element lack a track name
      final summary = i == 0
          ? DgEdgeDailyRace(
              id: '0',
              title: 'Race ?0',
              url: 'https://www.dg-edge.com/events/dailies/0',
              trackName: null,
              tyreCode: 'RM',
              tyre: Tyre.RM,
            )
          : DgEdgeDailyRace(
              id: '${i + 1}',
              title: 'Race ${i + 1}',
              url: 'https://www.dg-edge.com/events/dailies/${i + 1}',
              trackName: 'Track${i + 1}',
              // omit trackId to prevent network image fetch
              // no metrics to keep layout simple for tests
              tyreCode: i % 2 == 0 ? 'RM' : 'RS',
              tyre: Tyre.values.firstWhere(
                (t) => t.name == (i % 2 == 0 ? 'RM' : 'RS'),
              ), // assume exist
              className: i == 1 ? 'Gr.3' : null,
              laps: i == 1 ? 5 : null,
              tyreCompound: i == 1 ? 'Hard' : null,
              reward: i == 1 ? '30000 CR' : null,
              isActive: true,
              isEnded: false,
            );

      // Wrap DG‑Edge result into the unified model.
      return DailyRace.fromPair(summary, null);
    });

    final fake = FakeSportRepository(races);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<SportRepository>.value(
          value: fake,
          child: const Scaffold(body: DailyRacesDisplay()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // first race had no track name and should be dropped; remaining
    // tracks start with Track2
    expect(find.text('Track2'), findsOneWidget);
    expect(find.text('Track3'), findsOneWidget);
    expect(find.text('Track4'), findsOneWidget);
    expect(find.text('Track5'), findsNothing);
  });
}
