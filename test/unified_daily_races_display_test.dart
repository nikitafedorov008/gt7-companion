import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:gt7_companion/widgets/unified_daily_races_display.dart';
import 'package:gt7_companion/repositories/sport_repository.dart';
import 'package:gt7_companion/models/unified_daily_race.dart';
import 'package:gt7_companion/models/daily_race.dart';

class FakeSportRepository extends ChangeNotifier implements SportRepository {
  final List<UnifiedDailyRace> items;
  bool _loading = false;
  String? _error;

  FakeSportRepository(this.items);

  @override
  List<UnifiedDailyRace> get dailyRaces => items;
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
  testWidgets('UnifiedDailyRacesDisplay shows up to 3 cards only', (
    tester,
  ) async {
    final combined = List.generate(5, (i) {
      if (i == 0) {
        final nullSummary = DailyRaceSummary(
          id: '0',
          title: 'Race ?0',
          url: 'https://example.com/race/0',
          trackName: null,
        );
        return UnifiedDailyRace.fromPair(nullSummary, null);
      }
      final summary = DailyRaceSummary(
        id: '${i + 1}',
        title: 'Race ${i + 1}',
        url: 'https://example.com/race/${i + 1}',
        trackName: 'Track${i + 1}',
        // no trackId to prevent network image fetch
      );
      return UnifiedDailyRace.fromPair(summary, null);
    });

    final fakeRepo = FakeSportRepository(combined);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<SportRepository>.value(
          value: fakeRepo,
          child: const Scaffold(body: UnifiedDailyRacesDisplay()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // first combined entry has no track and should be dropped
    expect(find.text('Track2'), findsOneWidget);
    expect(find.text('Track3'), findsOneWidget);
    expect(find.text('Track4'), findsOneWidget);
    expect(find.text('Track5'), findsNothing);
  });
}
