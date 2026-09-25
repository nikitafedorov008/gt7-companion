import 'package:flutter/material.dart';

import '../../models/telemetry/telemetry_data.dart';
import '../../theme/gt7_theme.dart';
import '../../models/telemetry/track_trace.dart';
import 'attitude_card.dart';
import 'motion_workspace.dart' show kMotionColumnWidth;
import 'surface_codes.dart';
import 'telemetry_display.dart' show Gt7Readout, gt7Count, gt7Gear, gt7LapTime;

/// What state the car is in: its own card, in the column the dial stands in.
///
/// The session's numbers - lap, position, the lap in progress - used to sit
/// beside it and have moved onto the map, where a racing HUD puts them. What is
/// left is the car: gear, fuel, steering and drift, the tyres, the fluids, the
/// aids.
class MotionSideCards extends StatelessWidget {
  const MotionSideCards({super.key, required this.telemetry, this.trace});

  final TelemetryData telemetry;

  /// The driven route, which is where the drift angle comes from: the steering
  /// instrument in the car's card draws it.
  final TrackTrace? trace;

  /// The width at which the cards can lie in a row instead of a column.
  static const double wide = 900;

  /// The car's card is exactly as wide as the motion column above it: the dial
  /// and the car's own card then line up, which is what makes the page read as
  /// two columns rather than as five panels that happen to be near each other.
  /// Wide enough, too, for the four tyres in one line - two by two needs 320 px
  /// and is 200 px taller.
  static const double carCardWidth = kMotionColumnWidth;

  @override
  Widget build(BuildContext context) {
    final card = _TyresPanel(telemetry: telemetry, trace: trace);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < wide) {
          return SizedBox(width: double.infinity, child: card);
        }
        // In the column the dial stands in, not stretched across the page: the
        // two are the same box, one above the other.
        return Align(
          alignment: Alignment.topRight,
          child: SizedBox(width: carCardWidth, child: card),
        );
      },
    );
  }
}

/// Two equal tiles side by side.
///
/// `IntrinsicHeight` and not `CrossAxisAlignment.stretch`: these cards live in a
/// scrolling column, where the height is unbounded, and stretching a row to an
/// infinite height throws before anything is drawn. Intrinsic height costs a
/// second layout pass on two small subtrees and gives the pair one height.
Widget _pair(Widget left, Widget right) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 10),
          Expanded(child: right),
        ],
      ),
    );

/// Where the driver is in the race: which lap, which place. The car's own state
/// - gear, fuel, tyres, aids - is in the card below this one.
class _SessionTiles extends StatelessWidget {
  const _SessionTiles({required this.telemetry});

  final TelemetryData telemetry;

  @override
  Widget build(BuildContext context) {
    return _pair(
      Gt7Readout(
        label: 'Lap',
        value: gt7Count(telemetry.currentLap, telemetry.totalLaps),
        sub: 'BEST ${gt7LapTime(telemetry.bestLapTime)}',
        width: double.infinity,
      ),
      Gt7Readout(
        label: 'Position',
        value: gt7Count(telemetry.currentPos, telemetry.totalPositions),
        sub: 'LAST ${gt7LapTime(telemetry.lastLapTime)}',
        width: double.infinity,
      ),
    );
  }
}


class _TyresPanel extends StatelessWidget {
  const _TyresPanel({required this.telemetry, this.trace});

  final TelemetryData telemetry;

  /// For the steering instrument: the drift angle is measured from the drive,
  /// not reported by the packet.
  final TrackTrace? trace;

  /// The gearbox and the tank, which are the car's state as much as its tyres
  /// are - they used to be two tiles above this card, and moving them in is what
  /// makes this the one place the car itself is described.
  Widget _gearAndFuel() {
    final fuelRatio = telemetry.maxFuel > 0
        ? (telemetry.fuel / telemetry.maxFuel).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final fuelLow = !telemetry.isEV && fuelRatio <= 0.2;

    return _pair(
      Gt7Readout(
        label: 'Gear',
        value: gt7Gear(telemetry.currentGear),
        sub: 'SUGGESTED ${gt7Gear(telemetry.suggestedGear)}',
        width: double.infinity,
      ),
      Gt7Readout(
        label: telemetry.isEV ? 'Charge' : 'Fuel',
        value: telemetry.isEV
            ? '--'
            : '${telemetry.fuel.toStringAsFixed(0)} / ${telemetry.maxFuel.toStringAsFixed(0)}',
        sub: telemetry.isEV
            ? 'ELECTRIC DRIVETRAIN'
            : '${(fuelRatio * 100).toStringAsFixed(0)}% REMAINING',
        valueColor: fuelLow ? gt7Warn : gt7Text,
        width: double.infinity,
      ),
    );
  }

  /// One tyre tile: its heat, and the surface the packet says it is standing on.
  Widget _tyre(int wheel) {
    return _TyreBlock(
      label: gt7WheelNames[wheel],
      temperature: switch (wheel) {
        0 => telemetry.tireTempFL,
        1 => telemetry.tireTempFR,
        2 => telemetry.tireTempRL,
        _ => telemetry.tireTempRR,
      },
      surface: gt7SurfaceAt(telemetry.surfaceTypes, wheel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brake = telemetry.brake;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: gt7PanelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('TYRES & VEHICLE', style: gt7Caption(color: gt7TextMuted)),
              if (telemetry.carCategory.replaceAll('\u0000', '').isNotEmpty) ...[
                const SizedBox(width: 10),
                Text(
                  telemetry.carCategory.replaceAll('\u0000', ''),
                  style: gt7Caption(color: gt7Text, size: 9),
                ),
              ],
              const Spacer(),
              // The summary the per-wheel surfaces add up to. The wheels say
              // *which* one is off the racing surface, this says that any is.
              if (telemetry.offTrack)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: gt7Warn.withValues(alpha: 0.18),
                    border: Border.all(color: gt7Warn.withValues(alpha: 0.6)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'OFF TRACK',
                    style: gt7Caption(color: gt7Warn, size: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _gearAndFuel(),
          const SizedBox(height: 10),
          // Steering and drift, with the rest of the car's state: what the
          // driver does with the wheel and what the car does with it belongs
          // beside the tyres that have to make it happen.
          AttitudeCard(
            steering: telemetry.steeringRadians ?? double.nan,
            rate: telemetry.steeringRate,
            source: telemetry.steeringSource,
            trace: trace,
          ),
          const SizedBox(height: 10),
          // The four corners, in the packet's order - which is also the order
          // the car on the dial builds them, and the order they sit on a car.
          // Across the card in one line when there is width for it, two by two
          // when there is not.
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _pair(_tyre(0), _tyre(1)),
                    const SizedBox(height: 10),
                    _pair(_tyre(2), _tyre(3)),
                  ],
                );
              }
              // `start`, not `stretch`: the page is a scrolling column, so the
              // cross axis is unbounded and stretching asks for an infinite
              // height. Four equal tiles do not need stretching anyway.
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var wheel = 0; wheel < 4; wheel++) ...[
                    if (wheel > 0) const SizedBox(width: 8),
                    Expanded(child: _tyre(wheel)),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _pair(
            Gt7Readout(
              label: 'Oil Temp',
              value: '${telemetry.oilTemp.toStringAsFixed(1)} °C',
              valueColor: telemetry.oilTemp > 110 ? gt7Warn : gt7Text,
              width: double.infinity,
            ),
            Gt7Readout(
              label: 'Water Temp',
              value: '${telemetry.waterTemp.toStringAsFixed(1)} °C',
              valueColor: telemetry.waterTemp > 100 ? gt7Warn : gt7Text,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 10),
          Gt7Readout(
            label: 'Brake',
            value: '${brake.toStringAsFixed(0)}%',
            valueColor: brake > 80 ? gt7Warn : gt7Text,
            width: double.infinity,
          ),
          const SizedBox(height: 14),
          // The car's electronics, which are part of its state like the tyres:
          // how hard each aid is working, what the pedals asked for before the
          // aids took their cut, and what is going back into the battery.
          _AidsRow(telemetry: telemetry),
        ],
      ),
    );
  }
}

/// How the driver aids are intervening, in the car's own card.
///
/// Only the "~" packet and up carries the pre-aid inputs (`0x13C` / `0x13D`),
/// so a session on heartbeat `A` sees only the energy recovery - and a session
/// on `B` sees nothing here at all, which is the honest answer.
class _AidsRow extends StatelessWidget {
  const _AidsRow({required this.telemetry});

  final TelemetryData telemetry;

  @override
  Widget build(BuildContext context) {
    final tcs = telemetry.tcsCut ?? 0;
    final abs = telemetry.absCut ?? 0;
    final regen = telemetry.energyRecovery;

    final children = <Widget>[
      if (tcs > 0.05) _aidChip('TCS', tcs),
      if (abs > 0.05) _aidChip('ABS', abs),
      if (!regen.isNaN && regen > 0)
        _fact('ENERGY RECOVERY', regen.toStringAsFixed(1)),
      if (telemetry.hasExtendedData)
        _fact(
          'PRE-AID INPUT',
          '${telemetry.throttleFiltered.round()}/255 · '
              '${telemetry.brakeFiltered.round()}/255',
        ),
    ];

    if (children.isEmpty) {
      return Text(
        'NO AID DATA IN PACKET ${telemetry.packetType}',
        style: gt7Caption(color: gt7TextMuted.withValues(alpha: 0.5), size: 8),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('AIDS', style: gt7Caption(color: gt7TextMuted, size: 8)),
        ...children,
      ],
    );
  }

  /// How hard an aid is working right now, from the raw-versus-assisted
  /// difference the "~" packet makes visible.
  Widget _aidChip(String label, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: gt7SlotB.withValues(alpha: 0.18),
        border: Border.all(color: gt7SlotB.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        '$label ${(amount * 100).round()}%',
        style: gt7Caption(color: gt7SlotB, size: 8),
      ),
    );
  }

  /// A label and its number, in a card that is 320 px wide at most.
  ///
  /// The value is [Flexible] because a Wrap child is given the row's width, not
  /// the space it would like: "PRE-AID INPUT 190/255 · 65/255" is wider than the
  /// card's inner width, and a fixed row overflowed by 51 px when it was.
  Widget _fact(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: gt7Caption(color: gt7TextMuted, size: 8)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: gt7Digital(size: 12),
          ),
        ),
      ],
    );
  }
}

class _TyreBlock extends StatelessWidget {
  const _TyreBlock({
    required this.label,
    required this.temperature,
    this.surface = '',
  });

  final String label;
  final double temperature;

  /// The packet's surface code for this wheel: `T`, `C`, `D`, `G`, `S`, `s`, or
  /// empty when the console is answering packet `A` or `B`, which carry none.
  final String surface;

  bool get _offTrack => surface.isNotEmpty && gt7SurfaceIsOffTrack(surface);

  /// Cold = blue, optimal = white, warm = yellow, hot = red. The game shows
  /// tyre heat as colour, not as text.
  Color get _color {
    if (temperature < 60) return gt7Gain;
    if (temperature < 100) return gt7Text;
    if (temperature < 120) return gt7SlotB;
    return gt7Warn;
  }

  @override
  Widget build(BuildContext context) {
    final fill = ((temperature - 20) / 130).clamp(0.04, 1.0);

    final surfaceColour =
        surface.isEmpty ? gt7TextMuted : gt7SurfaceColour(surface);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      // A tyre off the racing surface takes that colour on its own tile: the
      // surface belongs to the wheel, so it is written on the wheel rather than
      // in a row of chips beside it.
      decoration: gt7PanelDecoration(
        radius: 8,
        borderColor: _offTrack ? gt7Warn.withValues(alpha: 0.75) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: gt7Caption(
                  color: gt7Text,
                  size: 11,
                  letterSpacing: 1.6,
                  weight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${temperature.toStringAsFixed(1)}°',
                    style: gt7Digital(size: 15, color: _color),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              children: [
                Container(height: 4, color: Colors.white.withValues(alpha: 0.08)),
                FractionallySizedBox(
                  widthFactor: fill,
                  child: Container(height: 4, color: _color),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              if (surface.isNotEmpty)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: surfaceColour,
                    shape: BoxShape.circle,
                  ),
                ),
              if (surface.isNotEmpty) const SizedBox(width: 6),
              Flexible(
                child: Text(
                  surface.isEmpty ? 'NO SURFACE DATA' : gt7SurfaceLabel(surface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gt7Caption(
                    color: surface.isEmpty ? gt7TextMuted : surfaceColour,
                    size: 8,
                    weight: _offTrack ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

