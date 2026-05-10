import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/throttle_brake_graph/throttle_brake_graph_bloc.dart';
import '../../blocs/throttle_brake_graph/throttle_brake_graph_event.dart';
import '../../blocs/throttle_brake_graph/throttle_brake_graph_state.dart';

/// Widget that displays throttle and brake input as a time-series graph
class ThrottleBrakeGraph extends StatefulWidget {
  final double height;

  const ThrottleBrakeGraph({
    super.key,
    this.height = 200.0,
  });

  @override
  State<ThrottleBrakeGraph> createState() => _ThrottleBrakeGraphState();
}

class _ThrottleBrakeGraphState extends State<ThrottleBrakeGraph> {
  @override
  void initState() {
    super.initState();
    // Initialize the BLoC when widget is created
    context.read<ThrottleBrakeGraphBloc>().add(
          const ThrottleBrakeGraphEvent.initialize(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThrottleBrakeGraphBloc, ThrottleBrakeGraphState>(
      builder: (context, state) {
        return Container(
          height: widget.height,
          padding: const EdgeInsets.all(8.0),
          child: state.when(
            initial: () => const _LoadingPlaceholder(),
            loading: () => const _LoadingPlaceholder(),
            success: (history) {
              if (history.isEmpty) {
                return const _NoDataPlaceholder();
              }
              return _buildGraphContent(history);
            },
            error: (message) => _ErrorPlaceholder(message: message),
          ),
        );
      },
    );
  }

  Widget _buildGraphContent(List<ThrottleBrakeDataPoint> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: const [
              _ColorLegend(
                color: Color(0xFF4CAF50),
                label: 'Throttle',
              ),
              SizedBox(width: 16.0),
              _ColorLegend(
                color: Color(0xFFF44336),
                label: 'Brake',
              ),
            ],
          ),
        ),
        // Graph canvas
        Expanded(
          child: CustomPaint(
            painter: _ThrottleBrakeGraphPainter(history),
            size: Size.infinite,
          ),
        ),
      ],
    );
  }
}

/// Custom painter that renders the throttle/brake graph
class _ThrottleBrakeGraphPainter extends CustomPainter {
  final List<ThrottleBrakeDataPoint> history;

  // Colors for the lines
  static const Color throttleColor = Color(0xFF4CAF50); // Green
  static const Color brakeColor = Color(0xFFF44336); // Red

  _ThrottleBrakeGraphPainter(this.history);

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) {
      return;
    }

    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFFAFAFA),
    );

    // Draw grid and axes
    _drawAxes(canvas, size);

    // Draw throttle line
    _drawLine(
      canvas,
      size,
      history.map((p) => p.throttle).toList(),
      throttleColor,
      strokeWidth: 2.0,
    );

    // Draw brake line
    _drawLine(
      canvas,
      size,
      history.map((p) => p.brake).toList(),
      brakeColor,
      strokeWidth: 2.0,
    );
  }

  /// Draw axes and grid
  void _drawAxes(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..strokeWidth = 0.5;

    final labelPaint = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Y-axis labels (0%, 50%, 100%)
    const yLabels = ['100%', '50%', '0%'];
    const yValues = [100.0, 50.0, 0.0];

    final padding = 40.0;

    for (int i = 0; i < yLabels.length; i++) {
      final y = _getYPosition(yValues[i], size);

      // Draw horizontal grid line
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - 10, y),
        axisPaint,
      );

      // Draw label
      labelPaint.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(
          color: Color(0xFF757575),
          fontSize: 12,
        ),
      );
      labelPaint.layout();
      labelPaint.paint(canvas, Offset(5, y - 8));
    }

    // X-axis
    canvas.drawLine(
      Offset(padding, size.height - 20),
      Offset(size.width - 10, size.height - 20),
      axisPaint,
    );

    // Y-axis
    canvas.drawLine(
      Offset(padding, 0),
      Offset(padding, size.height - 20),
      axisPaint,
    );
  }

  /// Draw a line for throttle or brake values
  void _drawLine(
    Canvas canvas,
    Size size,
    List<double> values,
    Color color, {
    double strokeWidth = 2.0,
  }) {
    if (values.isEmpty) return;

    final path = ui.Path();
    final padding = 40.0;

    for (int i = 0; i < values.length; i++) {
      final x = _getXPosition(i, values.length, size, padding);
      final y = _getYPosition(values[i], size);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Get X coordinate for a data point index
  double _getXPosition(
    int index,
    int total,
    Size size,
    double padding,
  ) {
    final graphWidth = size.width - padding - 10;
    return padding + (graphWidth * index / (total - 1).toDouble());
  }

  /// Get Y coordinate for a value (0-100)
  double _getYPosition(double value, Size size) {
    final graphHeight = size.height - 30;
    return size.height - 20 - (graphHeight * (value / 100.0));
  }

  @override
  bool shouldRepaint(_ThrottleBrakeGraphPainter oldDelegate) {
    return oldDelegate.history.length != history.length ||
        (history.isNotEmpty &&
            (oldDelegate.history.isEmpty ||
                oldDelegate.history.last != history.last));
  }
}

/// Legend item showing color and label
class _ColorLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ColorLegend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 2,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Placeholder when loading
class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

/// Placeholder when no data available
class _NoDataPlaceholder extends StatelessWidget {
  const _NoDataPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Waiting for telemetry data...',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey,
        ),
      ),
    );
  }
}

/// Placeholder when error occurs
class _ErrorPlaceholder extends StatelessWidget {
  final String message;

  const _ErrorPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Error: $message',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.red,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
