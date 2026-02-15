import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/models/daily_race.dart';

void main() {
  test('CarType.parse recognizes GR groups and variants', () {
    expect(CarTypeX.parse('GR.4'), CarType.GR4);
    expect(CarTypeX.parse('gr4'), CarType.GR4);
    expect(CarTypeX.parse('Group 4'), CarType.GR4);
    expect(CarTypeX.parse('GR.3'), CarType.GR3);
  });

  test('CarType.parse recognizes common car-type names', () {
    expect(CarTypeX.parse('Road Car'), CarType.ROAD_CAR);
    expect(CarTypeX.parse('Racing Car'), CarType.RACING_CAR);
    expect(CarTypeX.parse('GT500'), CarType.GT500);
    expect(CarTypeX.parse('Le Mans'), CarType.LE_MANS);
    expect(CarTypeX.parse('Nürburgring 24 Hours'), CarType.NURBURGRING_24H);
    expect(CarTypeX.parse('Pikes Peak'), CarType.PIKES_PEAK);
    expect(CarTypeX.parse('Pickup Truck'), CarType.PICKUP_TRUCK);
    expect(CarTypeX.parse('Vision Gran Turismo'), CarType.VISION_GRAN_TURISMO);
  });

  test('CarType.code returns canonical strings', () {
    expect(CarType.GR4.code, 'GR.4');
    expect(CarType.ROAD_CAR.code, 'Road Car');
    expect(CarType.GT500.code, 'GT500');
  });
}
