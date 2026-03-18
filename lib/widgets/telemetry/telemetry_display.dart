import 'package:flutter/material.dart';
import '../../models/telemetry/telemetry_data.dart';
import 'package:gt7_companion/theme/gt7_theme.dart';

class TelemetryDisplay extends StatelessWidget {
  final TelemetryData? telemetry;
  final String? errorMessage;

  const TelemetryDisplay({super.key, this.telemetry, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(isDesktop ? 16.0 : 8.0),
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 1200 : double.infinity,
        ),
        child: errorMessage != null
            ? Center(
                child: Text(
                  'Error: $errorMessage',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 16,
                  ),
                ),
              )
            : telemetry == null
            ? Center(
                child: Text(
                  'Waiting for telemetry data...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: IntrinsicWidth(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                _buildHeader(context, isDesktop),

                                // Track Data
                                _buildSectionHeader(
                                  context,
                                  'Current Track Data',
                                ),
                                _buildCarData(context, isDesktop),

                                // Tire Data
                                _buildSectionHeader(context, 'Tyre Data'),
                                _buildTireData(context, isDesktop),

                                // Gearing and Positioning
                                isDesktop
                                    ? Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildSectionHeader(
                                                  context,
                                                  'Gearing',
                                                ),
                                                _buildGearingData(
                                                  context,
                                                  isDesktop,
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            flex: 1,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildSectionHeader(
                                                  context,
                                                  'Positioning (m)',
                                                ),
                                                _buildPositioningData(
                                                  context,
                                                  isDesktop,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildSectionHeader(
                                                context,
                                                'Gearing',
                                              ),
                                              _buildGearingData(
                                                context,
                                                isDesktop,
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildSectionHeader(
                                                context,
                                                'Positioning (m)',
                                              ),
                                              _buildPositioningData(
                                                context,
                                                isDesktop,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                // Velocity and Rotation
                                isDesktop
                                    ? Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildSectionHeader(
                                                  context,
                                                  'Velocity (m/s)',
                                                ),
                                                _buildVelocityData(
                                                  context,
                                                  isDesktop,
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            flex: 1,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildSectionHeader(
                                                  context,
                                                  'Rotation',
                                                ),
                                                _buildRotationData(
                                                  context,
                                                  isDesktop,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildSectionHeader(
                                            context,
                                            'Velocity (m/s)',
                                          ),
                                          _buildVelocityData(
                                            context,
                                            isDesktop,
                                          ),
                                          _buildSectionHeader(
                                            context,
                                            'Rotation',
                                          ),
                                          _buildRotationData(
                                            context,
                                            isDesktop,
                                          ),
                                        ],
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildMapPreview(BuildContext context, bool isDesktop) {
    final graph = Theme.of(context).extension<GT7GraphColors>();
    final markerColor = Theme.of(context).colorScheme.primary;
    final trackColor = graph?.track ?? Theme.of(context).colorScheme.surface;
    final trackShadow =
        graph?.trackShadow ??
        Theme.of(context).colorScheme.surface.withOpacity(0.9);

    if (telemetry == null) {
      return Container(
        height: isDesktop ? 220 : 140,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
          ),
        ),
        child: Center(
          child: Text(
            'Track preview — waiting for telemetry',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    return Container(
      height: isDesktop ? 240 : 160,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: StatefulBuilder(
        builder: (context, setState) {
          // ephemeral toggle for visual highlights (works until parent rebuild)
          final highlight = ValueNotifier<bool>(true);

          return Stack(
            children: [
              // base track + grid
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrackBasePainter(
                    trackColor: trackColor,
                    trackShadow: trackShadow,
                    gridColor:
                        graph?.grid ?? Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),

              // highlighted segments overlay (toggleable)
              ValueListenableBuilder<bool>(
                valueListenable: highlight,
                builder: (context, showHighlights, _) => showHighlights
                    ? Positioned.fill(
                        child: CustomPaint(
                          painter: _TrackHighlightPainter(
                            highlight: markerColor.withOpacity(0.18),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // center telemetry lines
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrackLinePainter(
                    lineA: graph?.lineA ?? markerColor.withOpacity(0.95),
                    lineB: graph?.lineB ?? markerColor.withOpacity(0.6),
                  ),
                ),
              ),

              // markers + callouts
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, bc) {
                    Widget marker(
                      String label,
                      double fx,
                      double fy, {
                      double size = 34,
                    }) {
                      return Positioned(
                        left: bc.maxWidth * fx - size / 2,
                        top:
                            (isDesktop ? 26 : 18) +
                            (bc.maxHeight - (isDesktop ? 140 : 96)) * fy,
                        child: Column(
                          children: [
                            // connector (visual)
                            Container(
                              width: 2,
                              height: 6,
                              color: Colors.transparent,
                            ),
                            Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                color: markerColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: markerColor.withOpacity(0.28),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.06),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    Widget ring(double fx, double fy, {double diameter = 48}) {
                      return Positioned(
                        left: bc.maxWidth * fx - diameter / 2,
                        top:
                            (isDesktop ? 20 : 12) +
                            (bc.maxHeight - (isDesktop ? 140 : 96)) * fy,
                        child: Container(
                          width: diameter,
                          height: diameter,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                              width: 6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.45),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Stack(
                      children: [
                        ring(0.45, 0.48, diameter: isDesktop ? 56 : 40),
                        ring(0.82, 0.62, diameter: isDesktop ? 52 : 38),
                        marker('A', 0.20, 0.36, size: isDesktop ? 36 : 28),
                        marker('B', 0.45, 0.48, size: isDesktop ? 44 : 34),
                        marker('C', 0.68, 0.42, size: isDesktop ? 36 : 28),
                        marker('D', 0.82, 0.62, size: isDesktop ? 40 : 30),
                      ],
                    );
                  },
                ),
              ),

              // toggle and legend (non-destructive, visual-only)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.scatter_plot,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Highlights',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(width: 8),
                      // ephemeral visual toggle (local only)
                      GestureDetector(
                        onTap: () => highlight.value = !highlight.value,
                        child: Container(
                          width: 34,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ValueListenableBuilder<bool>(
                            valueListenable: highlight,
                            builder: (context, v, _) => Align(
                              alignment: v
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: Container(
                                width: 14,
                                height: 14,
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // small footer legend
              Positioned(
                left: 12,
                bottom: 8,
                child: Row(
                  children: [
                    _miniLegendDot(
                      context,
                      graph?.lineA ?? Theme.of(context).colorScheme.primary,
                      'Live',
                    ),
                    const SizedBox(width: 8),
                    _miniLegendDot(
                      context,
                      graph?.lineB ??
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.6),
                      'Compare',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 12 : 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(isDesktop ? 8 : 4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'GT7 Telemetry Display (Flutter)',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            'Packet ID: ${telemetry?.packetId ?? 0}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
      margin: EdgeInsets.only(top: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTrackData(BuildContext context, bool isDesktop) {
    final isWide = MediaQuery.of(context).size.width > 500;
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 8 : 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isWide
              ? Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Time on track: ${telemetry != null ? (telemetry!.timeOfDay / 1000).toStringAsFixed(0) : '0'}s',
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Laps: ${telemetry?.currentLap ?? 0}/${telemetry?.totalLaps ?? 0}',
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Position: ${telemetry?.currentPos ?? 0}/${telemetry?.totalPositions ?? 0}',
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time on track: ${telemetry != null ? (telemetry!.timeOfDay / 1000).toStringAsFixed(0) : '0'}s',
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Laps: ${telemetry?.currentLap ?? 0}/${telemetry?.totalLaps ?? 0}',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Position: ${telemetry?.currentPos ?? 0}/${telemetry?.totalPositions ?? 0}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          SizedBox(height: 8),
          isWide
              ? Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Best Lap',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  telemetry != null
                                      ? telemetry!.formatLapTime(
                                          telemetry!.bestLapTime,
                                        )
                                      : '',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.emoji_events,
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            const TextSpan(text: 'Current Lap Time: '),
                            TextSpan(
                              text: telemetry != null
                                  ? telemetry!.formatCurLapTime(
                                      telemetry!.curLapTime,
                                    )
                                  : '',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            const TextSpan(text: 'Last Lap Time: '),
                            TextSpan(
                              text: telemetry != null
                                  ? telemetry!.formatLapTime(
                                      telemetry!.lastLapTime,
                                    )
                                  : '',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best Lap: ${telemetry != null ? telemetry!.formatLapTime(telemetry!.bestLapTime) : ''}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current Lap: ${telemetry != null ? telemetry!.formatCurLapTime(telemetry!.curLapTime) : ''}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last Lap: ${telemetry != null ? telemetry!.formatLapTime(telemetry!.lastLapTime) : ''}',
                    ),
                  ],
                ),
          const SizedBox(height: 12),
          // small map/track preview with cyan markers (visual-only)
          _buildMapPreview(context, isDesktop),
        ],
      ),
    );
  }

  Widget _buildCarData(BuildContext context, bool isDesktop) {
    final isWide = MediaQuery.of(context).size.width > 650;
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 8 : 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isWide
              ? Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text('Car ID: ${telemetry?.carId ?? 0}'),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Throttle: ${(telemetry?.throttle ?? 0).toStringAsFixed(1)}%',
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            const TextSpan(text: 'RPM: '),
                            TextSpan(
                              text: (telemetry?.rpm ?? 0).toStringAsFixed(0),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.9),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: ' rpm'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            const TextSpan(text: 'Speed: '),
                            TextSpan(
                              text: (telemetry?.speed ?? 0).toStringAsFixed(1),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text: ' kph',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Car ID: ${telemetry?.carId ?? 0}'),
                        ),
                        Expanded(
                          child: Text(
                            'Throttle: ${(telemetry?.throttle ?? 0).toStringAsFixed(1)}%',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                const TextSpan(text: 'RPM: '),
                                TextSpan(
                                  text: (telemetry?.rpm ?? 0).toStringAsFixed(
                                    0,
                                  ),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.9),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const TextSpan(text: ' rpm'),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                const TextSpan(text: 'Speed: '),
                                TextSpan(
                                  text: (telemetry?.speed ?? 0).toStringAsFixed(
                                    1,
                                  ),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: ' kph',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          SizedBox(height: 8),
          isWide
              ? Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Brake: ${(telemetry?.brake ?? 0).toStringAsFixed(1)}%',
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Gear: ${_formatGear(telemetry?.currentGear ?? 0)} (${telemetry?.suggestedGear ?? 0})',
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Boost: ${(telemetry?.boost ?? 0).toStringAsFixed(2)} kPa',
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Rev Warning: ${(telemetry?.rpmWarning ?? 0).toStringAsFixed(0)} rpm',
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Brake: ${(telemetry?.brake ?? 0).toStringAsFixed(1)}%',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Gear: ${_formatGear(telemetry?.currentGear ?? 0)} (${telemetry?.suggestedGear ?? 0})',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Boost: ${(telemetry?.boost ?? 0).toStringAsFixed(2)} kPa',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Rev Warning: ${(telemetry?.rpmWarning ?? 0).toStringAsFixed(0)} rpm',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  'Rev Limiter: ${(telemetry?.rpmLimiter ?? 0).toStringAsFixed(0)} rpm',
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  telemetry?.isEV == true
                      ? 'Charge: ${(telemetry?.fuel ?? 0).toStringAsFixed(0)} kWh'
                      : 'Fuel: ${(telemetry?.fuel ?? 0).toStringAsFixed(0)} lit',
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  telemetry?.isEV == true
                      ? 'Max: ${(telemetry?.maxFuel ?? 0).toStringAsFixed(0)} kWh'
                      : 'Max: ${(telemetry?.maxFuel ?? 0).toStringAsFixed(0)} lit',
                ),
              ),
              Expanded(
                flex: 1,
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      const TextSpan(text: 'Est. Speed: '),
                      TextSpan(
                        text: (telemetry?.estTopSpeed ?? 0).toStringAsFixed(0),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: ' kph',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  'Clutch: ${(telemetry?.clutch ?? 0).toStringAsFixed(3)}/${(telemetry?.clutchEngaged ?? 0).toStringAsFixed(3)}',
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'RPM After Clutch: ${(telemetry?.rpmAfterClutch ?? 0).toStringAsFixed(0)} rpm',
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Oil Temp: ${(telemetry?.oilTemp ?? 0).toStringAsFixed(1)} °C',
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Water Temp: ${(telemetry?.waterTemp ?? 0).toStringAsFixed(1)} °C',
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  'Oil Pressure: ${(telemetry?.oilPressure ?? 0).toStringAsFixed(2)} bar',
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Body/Ride Height: ${(telemetry?.rideHeight ?? 0).toStringAsFixed(0)} mm',
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(), // Empty for layout
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTireData(BuildContext context, bool isDesktop) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 8 : 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isWide
              ? Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        'FL: ${(telemetry?.tireTempFL ?? 0).toStringAsFixed(1)} °C',
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'FR: ${(telemetry?.tireTempFR ?? 0).toStringAsFixed(1)} °C',
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'ø: ${(telemetry?.tireDiamFL ?? 0).toStringAsFixed(1)}/${(telemetry?.tireDiamFR ?? 0).toStringAsFixed(1)} cm',
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${telemetry?.tireSpeedFL.toStringAsFixed(1) ?? '0'} kph',
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(telemetry?.tireSlipRatioFL ?? '0'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'FL: ${(telemetry?.tireTempFL ?? 0).toStringAsFixed(1)} °C',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'FR: ${(telemetry?.tireTempFR ?? 0).toStringAsFixed(1)} °C',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'ø: ${(telemetry?.tireDiamFL ?? 0).toStringAsFixed(1)}/${(telemetry?.tireDiamFR ?? 0).toStringAsFixed(1)} cm',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${telemetry?.tireSpeedFL.toStringAsFixed(1) ?? '0'} kph',
                          ),
                        ),
                      ],
                    ),
                    Text('Slip: ${telemetry?.tireSlipRatioFL ?? '0'}'),
                  ],
                ),
          SizedBox(height: 4),
          isWide
              ? Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${telemetry?.tireSpeedFL.toStringAsFixed(1) ?? '0'} kph',
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${telemetry?.tireSpeedFR.toStringAsFixed(1) ?? '0'} kph',
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${telemetry?.tireSlipRatioFL ?? '0'}/${telemetry?.tireSlipRatioFR ?? '0'}',
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(), // Empty for layout
                    ),
                  ],
                )
              : !isWide
              ? Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Slip FL/FR: ${telemetry?.tireSlipRatioFL ?? '0'}/${telemetry?.tireSlipRatioFR ?? '0'}',
                      ),
                    ),
                  ],
                )
              : Container(),
          SizedBox(height: 8),
          isWide
              ? Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        'RL: ${(telemetry?.tireTempRL ?? 0).toStringAsFixed(1)} °C',
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'RR: ${(telemetry?.tireTempRR ?? 0).toStringAsFixed(1)} °C',
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'ø: ${(telemetry?.tireDiamRL ?? 0).toStringAsFixed(1)}/${(telemetry?.tireDiamRR ?? 0).toStringAsFixed(1)} cm',
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${telemetry?.tireSpeedRL.toStringAsFixed(1) ?? '0'} kph',
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(telemetry?.tireSlipRatioRL ?? '0'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'RL: ${(telemetry?.tireTempRL ?? 0).toStringAsFixed(1)} °C',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'RR: ${(telemetry?.tireTempRR ?? 0).toStringAsFixed(1)} °C',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'ø: ${(telemetry?.tireDiamRL ?? 0).toStringAsFixed(1)}/${(telemetry?.tireDiamRR ?? 0).toStringAsFixed(1)} cm',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${telemetry?.tireSpeedRL.toStringAsFixed(1) ?? '0'} kph',
                          ),
                        ),
                      ],
                    ),
                    Text('Slip: ${telemetry?.tireSlipRatioRL ?? '0'}'),
                  ],
                ),
          SizedBox(height: 4),
          isWide
              ? Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${telemetry?.tireSpeedRL.toStringAsFixed(1) ?? '0'} kph',
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${telemetry?.tireSpeedRR.toStringAsFixed(1) ?? '0'} kph',
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${telemetry?.tireSlipRatioRL ?? '0'}/${telemetry?.tireSlipRatioRR ?? '0'}',
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(), // Empty for layout
                    ),
                  ],
                )
              : !isWide
              ? Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Slip RL/RR: ${telemetry?.tireSlipRatioRL ?? '0'}/${telemetry?.tireSlipRatioRR ?? '0'}',
                      ),
                    ),
                  ],
                )
              : Container(),
        ],
      ),
    );
  }

  Widget _buildGearingData(BuildContext context, bool isDesktop) {
    final isNarrow = MediaQuery.of(context).size.width < 500;
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 8 : 4),
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '1: ${(telemetry?.gear1 ?? 0).toStringAsFixed(3)}',
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '2: ${(telemetry?.gear2 ?? 0).toStringAsFixed(3)}',
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '3: ${(telemetry?.gear3 ?? 0).toStringAsFixed(3)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '4: ${(telemetry?.gear4 ?? 0).toStringAsFixed(3)}',
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '5: ${(telemetry?.gear5 ?? 0).toStringAsFixed(3)}',
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '6: ${(telemetry?.gear6 ?? 0).toStringAsFixed(3)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '7: ${(telemetry?.gear7 ?? 0).toStringAsFixed(3)}',
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '8: ${(telemetry?.gear8 ?? 0).toStringAsFixed(3)}',
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '?: ${(telemetry?.gearUnknown ?? 0).toStringAsFixed(3)}',
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1st: ${(telemetry?.gear1 ?? 0).toStringAsFixed(3)}'),
                Text('2nd: ${(telemetry?.gear2 ?? 0).toStringAsFixed(3)}'),
                Text('3rd: ${(telemetry?.gear3 ?? 0).toStringAsFixed(3)}'),
                Text('4th: ${(telemetry?.gear4 ?? 0).toStringAsFixed(3)}'),
                Text('5th: ${(telemetry?.gear5 ?? 0).toStringAsFixed(3)}'),
                Text('6th: ${(telemetry?.gear6 ?? 0).toStringAsFixed(3)}'),
                Text('7th: ${(telemetry?.gear7 ?? 0).toStringAsFixed(3)}'),
                Text('8th: ${(telemetry?.gear8 ?? 0).toStringAsFixed(3)}'),
                Text(
                  '???: ${(telemetry?.gearUnknown ?? 0).toStringAsFixed(3)}',
                ),
              ],
            ),
    );
  }

  Widget _buildPositioningData(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 8 : 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('X: ${(telemetry?.posX ?? 0).toStringAsFixed(4)}'),
          Text('Y: ${(telemetry?.posY ?? 0).toStringAsFixed(4)}'),
          Text('Z: ${(telemetry?.posZ ?? 0).toStringAsFixed(4)}'),
        ],
      ),
    );
  }

  Widget _buildVelocityData(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 8 : 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('X: ${(telemetry?.velX ?? 0).toStringAsFixed(4)}'),
          Text('Y: ${(telemetry?.velY ?? 0).toStringAsFixed(4)}'),
          Text('Z: ${(telemetry?.velZ ?? 0).toStringAsFixed(4)}'),
        ],
      ),
    );
  }

  Widget _buildRotationData(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 8 : 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('P: ${(telemetry?.rotPitch ?? 0).toStringAsFixed(4)}'),
          Text('Y: ${(telemetry?.rotYaw ?? 0).toStringAsFixed(4)}'),
          Text('R: ${(telemetry?.rotRoll ?? 0).toStringAsFixed(4)}'),
        ],
      ),
    );
  }

  String _formatGear(int gear) {
    if (gear == -1) return 'R'; // Reverse
    return gear.toString();
  }
}

// --- Track preview painters & small helpers (visual-only) ---
Widget _miniLegendDot(BuildContext context, Color color, String label) {
  return Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 6)],
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    ],
  );
}

class _TrackBasePainter extends CustomPainter {
  final Color trackColor;
  final Color trackShadow;
  final Color gridColor;
  const _TrackBasePainter({
    required this.trackColor,
    required this.trackShadow,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = gridColor.withOpacity(0.12);
    final stepX = size.width / 8;
    final stepY = size.height / 6;
    for (double x = 0; x <= size.width; x += stepX) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += stepY) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // track shadow (rounded rect)
    final shadowRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.9,
      height: size.height * 0.6,
    );
    final r = RRect.fromRectAndRadius(
      shadowRect,
      Radius.circular(size.height * 0.25),
    );
    final shadowPaint = Paint()..color = trackShadow;
    canvas.drawRRect(r, shadowPaint);

    // track base
    final trackRect = shadowRect.deflate(size.height * 0.06);
    final trackR = RRect.fromRectAndRadius(
      trackRect,
      Radius.circular(size.height * 0.22),
    );
    final trackPaint = Paint()
      ..shader = LinearGradient(
        colors: [trackColor.withOpacity(0.6), trackColor.withOpacity(0.9)],
      ).createShader(trackRect);
    canvas.drawRRect(trackR, trackPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrackLinePainter extends CustomPainter {
  final Color lineA;
  final Color lineB;
  const _TrackLinePainter({required this.lineA, required this.lineB});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // simple undulating path across the track area
    final path = Path();
    final left = size.width * 0.08;
    final right = size.width * 0.92;
    path.moveTo(left, center.dy + size.height * 0.08);
    path.cubicTo(
      size.width * 0.28,
      size.height * 0.06,
      size.width * 0.40,
      size.height * 0.18,
      size.width * 0.52,
      center.dy - size.height * 0.06,
    );
    path.cubicTo(
      size.width * 0.64,
      center.dy - size.height * 0.12,
      size.width * 0.76,
      center.dy - size.height * 0.04,
      right,
      center.dy - size.height * 0.02,
    );

    final pA = Paint()
      ..color = lineA
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final pB = Paint()
      ..color = lineB
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, pB);
    canvas.drawPath(path, pA);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrackHighlightPainter extends CustomPainter {
  final Color highlight;
  const _TrackHighlightPainter({required this.highlight});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = highlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

    // draw 2 highlighted segments as bezier subsections
    final seg1 = Path();
    seg1.moveTo(size.width * 0.30, center.dy + size.height * 0.05);
    seg1.quadraticBezierTo(
      size.width * 0.36,
      center.dy - size.height * 0.02,
      size.width * 0.44,
      center.dy - size.height * 0.03,
    );

    final seg2 = Path();
    seg2.moveTo(size.width * 0.66, center.dy - size.height * 0.01);
    seg2.quadraticBezierTo(
      size.width * 0.74,
      center.dy + size.height * 0.02,
      size.width * 0.82,
      center.dy + size.height * 0.04,
    );

    canvas.drawPath(seg1, paint);
    canvas.drawPath(seg2, paint);

    // small zig-zag accent on a segment (visual mimic)
    final zig = Path();
    double sx = size.width * 0.60;
    double sy = center.dy + size.height * 0.02;
    for (int i = 0; i < 8; i++) {
      zig.lineTo(sx + i * 6, sy + (i % 2 == 0 ? -4 : 4));
    }
    final zigPaint = Paint()
      ..color = highlight.withOpacity(0.95)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(zig, zigPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
