import 'package:flutter/material.dart';

/// What GT Auto contains, transcribed from the official GT7 online manual:
/// gran-turismo.com/gb/gt7/manual/gtauto/05 (the shop), /01 (maintenance),
/// /02 (customisation) and /03 (driving gear).
///
/// This is a reference table, not something fetched. No public API publishes
/// GT Auto's parts, prices or tuning — gt-gridstats, the closest thing, serves
/// a car catalogue and driver statistics and nothing else. Wording follows the
/// manual so the screen reads the way the game does.

/// One thing you can buy or have done at a counter.
@immutable
class GtAutoOption {
  const GtAutoOption({
    required this.name,
    required this.description,
    required this.icon,
    this.credits,
    this.variesByCar = false,
  });

  final String name;
  final String description;
  final IconData icon;

  /// Price in credits. Null when the manual quotes no figure.
  final int? credits;

  /// True when the price depends on the car and [credits] is only the figure
  /// the manual's own screenshot happens to show — printed as "from Cr. X"
  /// rather than as a flat price.
  final bool variesByCar;

  /// "Cr. 50", "from Cr. 15,000", or null when there is no figure to show.
  String? get priceLabel {
    final value = credits;
    if (value == null) return null;
    final formatted = value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
    return variesByCar ? 'from Cr. $formatted' : 'Cr. $formatted';
  }
}

/// A titled block of options. GT7 splits the maintenance counter into
/// MAINTENANCE and MODIFICATION; the other counters run as a single list.
@immutable
class GtAutoGroup {
  const GtAutoGroup({required this.options, this.title});

  final String? title;
  final List<GtAutoOption> options;
}

/// How a counter's options are drawn — the game uses two different shapes.
enum GtAutoLayout {
  /// Rows with an icon, a name and a price, as on the service counter.
  list,

  /// Square icon tiles along the bottom, as on the customisation counter.
  tiles,
}

/// One of the three counters the GT Auto forecourt sends you to.
@immutable
class GtAutoCounter {
  const GtAutoCounter({
    required this.id,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.layout,
    required this.groups,
  });

  final String id;
  final String name;
  final String tagline;
  final IconData icon;
  final GtAutoLayout layout;
  final List<GtAutoGroup> groups;

  Iterable<GtAutoOption> get allOptions => groups.expand((g) => g.options);
}

/// The three counters, in the order the game lists them.
const List<GtAutoCounter> kGtAutoCounters = [
  GtAutoCounter(
    id: 'maintenance',
    name: 'Maintenance & Servicing',
    tagline:
        'Check your car\'s cleanliness and body condition, and request a car '
        'wash, oil change, engine overhaul or body rigidity restoration work.',
    icon: Icons.build_circle_outlined,
    layout: GtAutoLayout.list,
    groups: [
      GtAutoGroup(
        title: 'Maintenance',
        options: [
          GtAutoOption(
            name: 'Car Wash',
            description:
                'Remove dirt and debris so that your car shines like new.',
            icon: Icons.local_car_wash_outlined,
            credits: 50,
          ),
          GtAutoOption(
            name: 'Oil Change',
            description:
                'The longer you drive a car, the more its oil degrades, which '
                'in turn will make its engine run slower.',
            icon: Icons.water_drop_outlined,
            credits: 250,
          ),
          GtAutoOption(
            name: 'Engine Overhaul',
            description:
                'When an oil change is not enough to restore an '
                'under-performing engine, an overhaul will bring it back.',
            icon: Icons.precision_manufacturing_outlined,
            credits: 15000,
            variesByCar: true,
          ),
          GtAutoOption(
            name: 'Restore Rigidity',
            description:
                'Constant driving deforms the body over time. Restore the '
                'rigidity of your car\'s chassis here.',
            icon: Icons.construction_outlined,
            credits: 15000,
            variesByCar: true,
          ),
        ],
      ),
      GtAutoGroup(
        title: 'Modification',
        options: [
          GtAutoOption(
            name: 'Wide Body',
            description: 'Install a wide body kit.',
            icon: Icons.open_in_full,
            credits: 10000,
            variesByCar: true,
          ),
          GtAutoOption(
            name: 'Engine Swap',
            description:
                'Unlocked at Collector Level 50. A car that has undergone an '
                'engine swap cannot undergo another.',
            icon: Icons.swap_horiz,
            credits: 167000,
            variesByCar: true,
          ),
        ],
      ),
    ],
  ),
  GtAutoCounter(
    id: 'customise',
    name: 'Customise Cars',
    tagline:
        'Personalise your cars with new wheels, a fresh coat of paint or '
        'custom external parts. Parts differ for each car.',
    icon: Icons.palette_outlined,
    layout: GtAutoLayout.tiles,
    groups: [
      GtAutoGroup(
        options: [
          GtAutoOption(
            name: 'Wheels',
            description:
                'Purchase wheels made by different brands from around the '
                'world.',
            icon: Icons.trip_origin,
          ),
          GtAutoOption(
            name: 'Paint Colour',
            description:
                'Purchase paint in a wide spectrum of colour and texture.',
            icon: Icons.format_paint_outlined,
          ),
          GtAutoOption(
            name: 'Custom Parts',
            description:
                'Purchase front spoilers, wings and other external parts.',
            icon: Icons.directions_car_outlined,
          ),
          GtAutoOption(
            name: 'Racing Items',
            description:
                'Purchase bonnet pins, roll cages and other racing items.',
            icon: Icons.flag_outlined,
          ),
          GtAutoOption(
            name: 'Other',
            description:
                'Purchase light bulbs, number plates, front grills and caliper '
                'colours.',
            icon: Icons.more_horiz,
          ),
          GtAutoOption(
            name: 'Livery Editor',
            description:
                'Change the colours of your cars and apply decals to create '
                'your own unique liveries.',
            icon: Icons.brush_outlined,
          ),
          GtAutoOption(
            name: 'Save Style',
            description: 'Save and share any piece of modified content.',
            icon: Icons.save_outlined,
          ),
          GtAutoOption(
            name: 'Load Style',
            description:
                'Apply styles you have downloaded from the Discover feature.',
            icon: Icons.folder_open_outlined,
          ),
        ],
      ),
    ],
  ),
  GtAutoCounter(
    id: 'gear',
    name: 'Driving Gear',
    tagline:
        'Change the colours of your helmets and racing suits, or apply decals, '
        'to create your own unique driving gear.',
    icon: Icons.sports_motorsports_outlined,
    layout: GtAutoLayout.tiles,
    groups: [
      GtAutoGroup(
        options: [
          GtAutoOption(
            name: 'Change',
            description:
                'Change your helmet or racing suit. Helmets are rewarded for '
                'increasing your Collector Level.',
            icon: Icons.checkroom_outlined,
          ),
          GtAutoOption(
            name: 'Livery Editor',
            description: 'Design your own helmet or racing suit.',
            icon: Icons.brush_outlined,
          ),
        ],
      ),
    ],
  ),
];

/// The three readings GT7 prints along the bottom of the service counter.
/// The app has no link to a save file, so these are described rather than
/// measured — each one names the service that restores it.
@immutable
class GtAutoCondition {
  const GtAutoCondition({
    required this.name,
    required this.restoredBy,
    required this.icon,
  });

  final String name;
  final String restoredBy;
  final IconData icon;
}

const List<GtAutoCondition> kGtAutoConditions = [
  GtAutoCondition(
    name: 'Dirt',
    restoredBy: 'Car Wash',
    icon: Icons.local_car_wash_outlined,
  ),
  GtAutoCondition(
    name: 'Oil',
    restoredBy: 'Oil Change',
    icon: Icons.water_drop_outlined,
  ),
  GtAutoCondition(
    name: 'Body Rigidity',
    restoredBy: 'Restore Rigidity',
    icon: Icons.construction_outlined,
  ),
];
