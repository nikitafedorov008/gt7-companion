import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/models/daily_race.dart';

void main() {
  test('TyreX.parse recognizes short codes', () {
    expect(TyreX.parse('RM'), Tyre.RM);
    expect(TyreX.parse('rs'), Tyre.RS);
    expect(TyreX.parse('ch'), Tyre.CH);
  });

  test('TyreX.parse recognizes wet/intermediate/offroad names', () {
    expect(TyreX.parse('Intermediate'), Tyre.IM);
    expect(TyreX.parse('Intermediate Tires (IM)'), Tyre.IM);
    expect(TyreX.parse('Heavy-wet'), Tyre.W);
    expect(TyreX.parse('Wet'), Tyre.W);
    expect(TyreX.parse('Dirt Tires'), Tyre.D);
  });

  test('Tyre.code returns correct short code', () {
    expect(Tyre.IM.code, 'IM');
    expect(Tyre.W.code, 'W');
    expect(Tyre.D.code, 'D');
    expect(Tyre.RM.code, 'RM');
  });
}
