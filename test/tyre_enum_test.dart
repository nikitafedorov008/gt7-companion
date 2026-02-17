import 'package:flutter/material.dart';
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

  test('TyreX.color mapping (hard/medium/soft + special types)', () {
    // Dirt -> beige (explicit hex)
    expect(Tyre.D.color.value, const Color(0xFFD2B48C).value);

    // Wet / Intermediate -> blue / green
    expect(Tyre.W.color, Colors.blue);
    expect(Tyre.IM.color, Colors.green);

    // Comfort/Sport/Racing -> H = white, M = amber, S = red
    expect(Tyre.CH.color, Colors.white);
    expect(Tyre.CM.color, Colors.amber);
    expect(Tyre.CS.color, Colors.red);
  });
}
