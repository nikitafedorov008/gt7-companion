import 'package:flutter/material.dart';

/// Collapsible breakdown of who is entered in a race.
///
/// DG-Edge publishes two histograms per card: entrants by `DR_SR` pair (about
/// 30 buckets) and by country (about 70). Neither fits inline on a race card,
/// so this stays folded until asked for, and shows only the leading buckets
/// with the remainder summarised rather than truncated silently.
class RaceFieldHistogram extends StatelessWidget {
  const RaceFieldHistogram({
    required this.title,
    required this.values,
    this.maxRows = 8,
    this.labelBuilder,
    super.key,
  });

  /// Bucket label to count, e.g. `{"D_S": 3323}` or `{"US": 3259}`.
  final Map<String, int> values;

  final String title;

  /// How many buckets to draw before folding the rest into an "others" row.
  final int maxRows;

  /// Optional prettifier for bucket keys — used to turn `D_S` into `DR D · SR S`.
  final String Function(String key)? labelBuilder;

  int get _total => values.values.fold<int>(0, (sum, v) => sum + v);

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final sorted = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = sorted.take(maxRows).toList();
    final hidden = sorted.skip(maxRows).toList();
    final total = _total;
    final peak = sorted.first.value;

    return Theme(
      // The default divider on an expansion tile fights the card's own
      // borders; drop it rather than restyle every usage.
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Text(
          '$title · ${_formatCount(total)}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        children: [
          for (final e in shown)
            _HistogramRow(
              label: labelBuilder?.call(e.key) ?? e.key,
              count: e.value,
              share: peak == 0 ? 0 : e.value / peak,
              total: total,
            ),
          if (hidden.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '+${hidden.length} more, '
                '${_formatCount(hidden.fold<int>(0, (s, e) => s + e.value))} entrants',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _formatCount(int value) {
    final digits = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}

class _HistogramRow extends StatelessWidget {
  const _HistogramRow({
    required this.label,
    required this.count,
    required this.share,
    required this.total,
  });

  final String label;
  final int count;

  /// Bar length relative to the largest bucket, so small buckets stay visible.
  final double share;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = total == 0 ? 0.0 : count / total * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: share.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.08,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 58,
            child: Text(
              '${percent.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Turn a DG-Edge `DR_SR` bucket key into something readable: `D_S` → `DR D · SR S`.
String formatRatingBucket(String key) {
  final parts = key.split('_');
  if (parts.length != 2) return key;
  return 'DR ${parts[0]} · SR ${parts[1]}';
}
