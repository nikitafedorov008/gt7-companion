import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:gt7_companion/widgets/daily_races_display.dart';
import 'package:gt7_companion/repositories/sport_repository.dart';
import 'package:gt7_companion/models/daily_race.dart';
import 'package:gt7_companion/models/combined_daily_race.dart';

class FakeSportRepository extends ChangeNotifier implements SportRepository {
  final List<CombinedDailyRace> items;
  bool _loading = false;
  String? _error;

  FakeSportRepository(this.items);

  @override
  List<CombinedDailyRace> get dailyRaces => items;
  @override
  bool get isLoading => _loading;
  @override
  String? get error => _error;

  @override
  Future<void> fetchDailyRaces({bool forceRefresh = false}) async {
    _loading = true;
    notifyListeners();
    // simulate small delay
    await Future.delayed(Duration(milliseconds: 10));
    _loading = false;
    notifyListeners();
  }
}

void main() {
  testWidgets('DailyRacesDisplay shows up to 3 cards only', (tester) async {
    // create combined items: we just produce summaries and null gtsh
    final fakeItems = List.generate(5, (i) {
      final summary = DailyRaceSummary(
        id: '${i + 1}',
        title: 'Race ${i + 1}',
        url: 'https://www.dg-edge.com/events/dailies/${i + 1}',
        trackName: 'Track${i + 1}',
        trackId: '${i + 1}',
        pitStops: (i % 3) + 1,
        tyresAvailable: ((i + 1) % 3) + 1,
        tyreCode: i % 2 == 0 ? 'RM' : 'RS',
        tyre: Tyre.values.firstWhere(
          (t) => t.name == (i % 2 == 0 ? 'RM' : 'RS'),
        ),
        className: i == 0 ? 'Gr.3' : null,
        laps: i == 0 ? 5 : null,
        tyreCompound: i == 0 ? 'Hard' : null,
        reward: i == 0 ? '30000 CR' : null,
      );
      return CombinedDailyRace(dgEdge: summary, gtsh: null);
    });

    final fakeRepo = FakeSportRepository(fakeItems);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<SportRepository>.value(
          value: fakeRepo,
          child: const Scaffold(body: DailyRacesDisplay()),
        ),
      ),
    );

    // Allow async fetch to complete
    await tester.pumpAndSettle();

    // Only first three races should be visible
    expect(find.text('Race 1'), findsOneWidget);
    expect(find.text('Race 2'), findsOneWidget);
    expect(find.text('Race 3'), findsOneWidget);

    // Summary info from the model should be rendered on the card (pit/tyre)
    expect(find.textContaining('Pits: x1'), findsWidgets);
    expect(find.textContaining('Tyres: x2'), findsWidgets);
    expect(find.byKey(const ValueKey('track-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('bg-1')), findsOneWidget);
    expect(find.textContaining('RM'), findsWidgets);

    // New summary fields should be visible on the card for item 1 (compact)
    expect(find.textContaining('Gr.3'), findsOneWidget);
    expect(find.textContaining('30000'), findsOneWidget);

    // if carType model string is supplied when enum is null, it should display
    // correctly; simulate via manual creation
    expect(find.textContaining('Gr.3'), findsOneWidget);
    expect(find.text('Race 5'), findsNothing);
  });
}
