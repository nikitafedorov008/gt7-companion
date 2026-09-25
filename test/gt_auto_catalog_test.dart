import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/models/gt_auto/gt_auto_catalog.dart';

void main() {
  group('GtAutoOption.priceLabel', () {
    test('prints a flat price for the fixed services', () {
      const carWash = GtAutoOption(
        name: 'Car Wash',
        description: '',
        icon: Icons.abc,
        credits: 50,
      );
      expect(carWash.priceLabel, 'Cr. 50');
    });

    test('groups thousands the way the game does', () {
      const overhaul = GtAutoOption(
        name: 'Engine Overhaul',
        description: '',
        icon: Icons.abc,
        credits: 15000,
        variesByCar: true,
      );
      expect(overhaul.priceLabel, 'from Cr. 15,000');

      const swap = GtAutoOption(
        name: 'Engine Swap',
        description: '',
        icon: Icons.abc,
        credits: 167000,
        variesByCar: true,
      );
      expect(swap.priceLabel, 'from Cr. 167,000');
    });

    test('says nothing when the manual quotes no figure', () {
      const wheels = GtAutoOption(
        name: 'Wheels',
        description: '',
        icon: Icons.abc,
      );
      expect(wheels.priceLabel, isNull);
    });
  });

  group('catalogue', () {
    test('carries the three counters GT Auto has, in the game\'s order', () {
      expect(
        kGtAutoCounters.map((c) => c.id),
        ['maintenance', 'customise', 'gear'],
      );
    });

    test('splits the service counter the way the game splits it', () {
      final maintenance = kGtAutoCounters.first;
      expect(maintenance.layout, GtAutoLayout.list);
      expect(
        maintenance.groups.map((g) => g.title),
        ['Maintenance', 'Modification'],
      );
      expect(
        maintenance.allOptions.map((o) => o.name),
        [
          'Car Wash',
          'Oil Change',
          'Engine Overhaul',
          'Restore Rigidity',
          'Wide Body',
          'Engine Swap',
        ],
      );
    });

    test('lists the eight customisation options the manual names', () {
      final customise = kGtAutoCounters[1];
      expect(customise.layout, GtAutoLayout.tiles);
      expect(customise.allOptions.length, 8);
      expect(
        customise.allOptions.map((o) => o.name),
        containsAll(<String>['Wheels', 'Paint Colour', 'Livery Editor']),
      );
    });

    test('every option carries a description', () {
      for (final counter in kGtAutoCounters) {
        for (final option in counter.allOptions) {
          expect(
            option.description,
            isNotEmpty,
            reason: '${counter.id}/${option.name} has no description',
          );
        }
      }
    });

    test('only the two flat-priced services print without "from"', () {
      final flat = kGtAutoCounters
          .expand((c) => c.allOptions)
          .where((o) => o.credits != null && !o.variesByCar)
          .map((o) => o.name);
      expect(flat, ['Car Wash', 'Oil Change']);
    });

    test('each condition points at the service that restores it', () {
      final serviceNames = kGtAutoCounters.first.allOptions
          .map((o) => o.name)
          .toSet();
      for (final condition in kGtAutoConditions) {
        expect(serviceNames, contains(condition.restoredBy));
      }
    });
  });
}
