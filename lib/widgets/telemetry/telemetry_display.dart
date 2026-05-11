import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/telemetry/telemetry_data.dart';
import 'throttle_brake_graph.dart';

class TelemetryDisplay extends StatelessWidget {
  final TelemetryData? telemetry;
  final String? errorMessage;

  const TelemetryDisplay({super.key, this.telemetry, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 700;

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: theme.colorScheme.surface,
          child: telemetry == null
              ? _buildStatusMessage(context)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),
                      _buildGauges(context, telemetry!, isDesktop),
                      const SizedBox(height: 18),
                      _buildStatusRow(context, telemetry!, isDesktop),
                      const SizedBox(height: 18),
                      _buildDetailPanel(context, telemetry!, isDesktop),
                      const SizedBox(height: 18),
                      _buildThrottleBrakeGraph(context),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatusMessage(BuildContext context) {
    final theme = Theme.of(context);
    if (errorMessage != null) {
      return Center(
        child: Text(
          'Error: $errorMessage',
          style: TextStyle(color: theme.colorScheme.error, fontSize: 16),
        ),
      );
    }

    return Center(
      child: Text(
        'Waiting for telemetry data...',
        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
      ),
    );
  }

  Widget _buildGauges(
    BuildContext context,
    TelemetryData telemetry,
    bool isDesktop,
  ) {
    return Flex(
      direction: isDesktop ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GaugeCard(
            label: 'Speed',
            value: telemetry.speed.clamp(0, 540),
            maxValue: 540,
            units: 'km/h',
            sections: [
              const GaugeSection(0, 180, Color(0xFF4CAF50)),
              const GaugeSection(180, 360, Color(0xFFFFC107)),
              const GaugeSection(360, 540, Color(0xFFF44336)),
            ],
            tickLabels: const [
              GaugeLabel(text: '0', ratio: 0 / 540),
              GaugeLabel(text: '40', ratio: 40 / 540),
              GaugeLabel(text: '80', ratio: 80 / 540),
              GaugeLabel(text: '120', ratio: 120 / 540),
              GaugeLabel(text: '160', ratio: 160 / 540),
              GaugeLabel(text: '200', ratio: 200 / 540),
              GaugeLabel(text: '240', ratio: 240 / 540),
              GaugeLabel(text: '280', ratio: 280 / 540),
              GaugeLabel(text: '320', ratio: 320 / 540),
              GaugeLabel(text: '360', ratio: 360 / 540),
              GaugeLabel(text: '400', ratio: 400 / 540),
              GaugeLabel(text: '440', ratio: 440 / 540),
              GaugeLabel(text: '480', ratio: 480 / 540),
              GaugeLabel(text: '520', ratio: 520 / 540),
              GaugeLabel(text: '540', ratio: 540 / 540),
            ],
            footnote: 'Top speed estimate: ${telemetry.estTopSpeed} km/h',
          ),
        ),
        SizedBox(width: isDesktop ? 16 : 0, height: isDesktop ? 0 : 16),
        Expanded(
          child: GaugeCard(
            label: 'RPM',
            value: telemetry.rpm.clamp(0, 9000),
            maxValue: 9000,
            units: 'rpm',
            sections: [
              const GaugeSection(0, 4500, Color(0xFF4CAF50)),
              const GaugeSection(4500, 7000, Color(0xFFFFC107)),
              const GaugeSection(7000, 9000, Color(0xFFF44336)),
            ],
            tickLabels: const [
              GaugeLabel(text: '0', ratio: 0.0),
              GaugeLabel(text: '1', ratio: 1 / 10),
              GaugeLabel(text: '2', ratio: 2 / 10),
              GaugeLabel(text: '3', ratio: 3 / 10),
              GaugeLabel(text: '4', ratio: 4 / 10),
              GaugeLabel(text: '5', ratio: 5 / 10),
              GaugeLabel(text: '6', ratio: 6 / 10),
              GaugeLabel(text: '7', ratio: 7 / 10),
              GaugeLabel(text: '8', ratio: 8 / 10),
              GaugeLabel(text: '9', ratio: 9 / 10),
              GaugeLabel(text: '10', ratio: 1.0),
            ],
            footnote: 'Limiter: ${telemetry.rpmLimiter} rpm',
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(
    BuildContext context,
    TelemetryData telemetry,
    bool isDesktop,
  ) {
    final theme = Theme.of(context);
    final fuelPercent = telemetry.maxFuel > 0
        ? (telemetry.fuel / telemetry.maxFuel).clamp(0.0, 1.0)
        : 0.0;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatTile(
          title: 'Gear',
          value: _formatGear(telemetry.currentGear),
          accent: theme.colorScheme.primary,
          subtitle: 'Suggested: ${_formatGear(telemetry.suggestedGear)}',
        ),
        _StatTile(
          title: telemetry.isEV ? 'Charge' : 'Fuel',
          value:
              '${telemetry.fuel.toStringAsFixed(0)} / ${telemetry.maxFuel.toStringAsFixed(0)}',
          accent: fuelPercent > 0.4
              ? const Color(0xFF4CAF50)
              : const Color(0xFFFFC107),
          subtitle: '${(fuelPercent * 100).toStringAsFixed(0)}%',
        ),
        _StatTile(
          title: 'Lap',
          value: '${telemetry.currentLap}/${telemetry.totalLaps}',
          accent: theme.colorScheme.secondary,
          subtitle: 'Best: ${telemetry.formatLapTime(telemetry.bestLapTime)}',
        ),
        _StatTile(
          title: 'Position',
          value: '${telemetry.currentPos}/${telemetry.totalPositions}',
          accent: theme.colorScheme.tertiaryContainer,
          subtitle: 'Last: ${telemetry.formatLapTime(telemetry.lastLapTime)}',
        ),
      ],
    );
  }

  Widget _buildDetailPanel(
    BuildContext context,
    TelemetryData telemetry,
    bool isDesktop,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tire & Vehicle Status',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _TireStatusBadge(
                  label: 'FL',
                  temperature: telemetry.tireTempFL,
                ),
                _TireStatusBadge(
                  label: 'FR',
                  temperature: telemetry.tireTempFR,
                ),
                _TireStatusBadge(
                  label: 'RL',
                  temperature: telemetry.tireTempRL,
                ),
                _TireStatusBadge(
                  label: 'RR',
                  temperature: telemetry.tireTempRR,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildAuxiliaryRow(context, telemetry),
          ],
        ),
      ),
    );
  }

  Widget _buildAuxiliaryRow(BuildContext context, TelemetryData telemetry) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Flex(
          direction: isWide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _DetailChip(
                label: 'Oil Temp',
                value: '${telemetry.oilTemp.toStringAsFixed(1)} °C',
                color: telemetry.oilTemp > 110
                    ? const Color(0xFFF44336)
                    : const Color(0xFF4CAF50),
              ),
            ),
            SizedBox(width: isWide ? 12 : 0, height: isWide ? 0 : 12),
            Expanded(
              child: _DetailChip(
                label: 'Water Temp',
                value: '${telemetry.waterTemp.toStringAsFixed(1)} °C',
                color: telemetry.waterTemp > 100
                    ? const Color(0xFFF44336)
                    : const Color(0xFF4CAF50),
              ),
            ),
            SizedBox(width: isWide ? 12 : 0, height: isWide ? 0 : 12),
            Expanded(
              child: _DetailChip(
                label: 'Brake',
                value: '${(telemetry.brake).toStringAsFixed(0)}%',
                color: telemetry.brake > 80
                    ? const Color(0xFFF44336)
                    : const Color(0xFF4CAF50),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatGear(int gear) {
    if (gear == -1) return 'R';
    if (gear == 0) return 'N';
    return gear.toString();
  }

  Widget _buildThrottleBrakeGraph(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: const ThrottleBrakeGraph(height: 200),
    );
  }
}

class GaugeCard extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final String units;
  final String footnote;
  final List<GaugeSection> sections;
  final List<GaugeLabel> tickLabels;

  const GaugeCard({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.units,
    required this.sections,
    required this.footnote,
    this.tickLabels = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                units,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, child) {
                return CustomPaint(
                  painter: _GaugePainter(
                    currentValue: animatedValue,
                    maxValue: maxValue,
                    sections: sections,
                    tickLabels: tickLabels,
                    isSpeedometer: label.toLowerCase() == 'speed',
                    backgroundColor: theme.colorScheme.onSurface.withOpacity(
                      0.08,
                    ),
                    needleColor: theme.colorScheme.primary,
                    tickColor: theme.colorScheme.onSurface.withOpacity(0.55),
                    dynamicRingColor: label.toLowerCase() == 'speed'
                        ? Colors.white.withOpacity(0.5)
                        : _calculateGaugeRingColor(animatedValue, maxValue),
                  ),
                  child: Align(
                    alignment: const Alignment(0, 0.6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          animatedValue.toStringAsFixed(0),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          units,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            footnote,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.74),
            ),
          ),
        ],
      ),
    );
  }
}

class GaugeSection {
  final double start;
  final double end;
  final Color color;

  const GaugeSection(this.start, this.end, this.color);
}

class GaugeLabel {
  final String text;
  final double ratio;

  const GaugeLabel({required this.text, required this.ratio});
}

class _GaugePainter extends CustomPainter {
  final double currentValue;
  final double maxValue;
  final List<GaugeSection> sections;
  final List<GaugeLabel> tickLabels;
  final bool isSpeedometer;
  final Color backgroundColor;
  final Color needleColor;
  final Color tickColor;
  final Color dynamicRingColor;

  const _GaugePainter({
    required this.currentValue,
    required this.maxValue,
    required this.sections,
    required this.tickLabels,
    required this.isSpeedometer,
    required this.backgroundColor,
    required this.needleColor,
    required this.tickColor,
    required this.dynamicRingColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.38;
    final strokeWidth = 18.0;
    final startAngle = math.pi * 0.75;
    final sweepAngle = math.pi * 1.5;

    final basePaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      basePaint,
    );

    for (final section in sections) {
      final sectionStart = (section.start / maxValue) * sweepAngle;
      final sectionSweep =
          ((section.end - section.start) / maxValue) * sweepAngle;
      final sectionPaint = Paint()
        ..color = Colors.grey.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + sectionStart,
        sectionSweep,
        false,
        sectionPaint,
      );
    }

    final fillRatio = (currentValue / maxValue).clamp(0.0, 1.0);
    if (fillRatio > 0.0) {
      final overlayPaint = Paint()
        ..color = dynamicRingColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * fillRatio,
        false,
        overlayPaint,
      );
    }

    const tickCount = 30;
    for (int tick = 0; tick <= tickCount; tick++) {
      final tickAngle = startAngle + sweepAngle * (tick / tickCount);
      final isMajor = tick % 5 == 0;
      final tickLength = isMajor ? 14.0 : 8.0;
      final tickStart = Offset(
        center.dx + (radius - tickLength - 4) * math.cos(tickAngle),
        center.dy + (radius - tickLength - 4) * math.sin(tickAngle),
      );
      final tickEnd = Offset(
        center.dx + (radius + 8) * math.cos(tickAngle),
        center.dy + (radius + 8) * math.sin(tickAngle),
      );
      canvas.drawLine(
        tickStart,
        tickEnd,
        Paint()
          ..color = tickColor
          ..strokeWidth = isMajor ? 2.5 : 1.2
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final label in tickLabels) {
      final labelAngle = startAngle + sweepAngle * label.ratio.clamp(0.0, 1.0);
      final labelRadius = radius - (isSpeedometer ? 34 : 22);
      final labelOffset = Offset(
        center.dx + labelRadius * math.cos(labelAngle),
        center.dy + labelRadius * math.sin(labelAngle),
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: label.text,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final textPos =
          labelOffset - Offset(textPainter.width / 2, textPainter.height / 2);
      textPainter.paint(canvas, textPos);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.currentValue != currentValue ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.dynamicRingColor != dynamicRingColor ||
        oldDelegate.isSpeedometer != isSpeedometer;
  }
}

Color _calculateGaugeRingColor(double currentValue, double maxValue) {
  final ratio = (currentValue / maxValue).clamp(0.0, 1.0);
  if (ratio <= 0.0) {
    return Colors.transparent;
  }

  if (ratio < 0.5) {
    return Color.lerp(Colors.green, Colors.yellow, ratio * 2)!.withOpacity(0.7);
  }

  return Color.lerp(
    Colors.yellow,
    Colors.red,
    (ratio - 0.5) * 2,
  )!.withOpacity(0.85);
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accent;

  const _StatTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.68),
            ),
          ),
        ],
      ),
    );
  }
}

class _TireStatusBadge extends StatelessWidget {
  final String label;
  final double temperature;

  const _TireStatusBadge({required this.label, required this.temperature});

  @override
  Widget build(BuildContext context) {
    final color = _temperatureColor(temperature);
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '${temperature.toStringAsFixed(1)} °C',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _temperatureLabel(temperature),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }

  Color _temperatureColor(double temperature) {
    if (temperature < 80) return const Color(0xFF42A5F5);
    if (temperature < 110) return const Color(0xFF66BB6A);
    if (temperature < 130) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  String _temperatureLabel(double temperature) {
    if (temperature < 80) return 'Cold';
    if (temperature < 110) return 'Optimal';
    if (temperature < 130) return 'Warm';
    return 'Hot';
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
