import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/ui_messages.dart';
import '../gt_loading_indicator.dart';
import '../window_navigation_safe_area.dart';

/// The source publishes a PNG, so preserve its axes and labels and zoom the
/// supplied chart rather than deriving an invented time series from its pixels.
class DealerPriceHistoryDialog extends StatefulWidget {
  const DealerPriceHistoryDialog({
    super.key,
    required this.uri,
    required this.carName,
    this.imageProvider,
  });
  final Uri uri;
  final String carName;
  final ImageProvider? imageProvider;

  static Future<void> show(
    BuildContext context, {
    required Uri uri,
    required String carName,
    ImageProvider? imageProvider,
  }) => showDialog<void>(
    context: context,
    // Outside the tab PageView: horizontal chart panning must never switch tabs.
    useRootNavigator: true,
    builder: (_) => DealerPriceHistoryDialog(
      uri: uri,
      carName: carName,
      imageProvider: imageProvider,
    ),
  );

  @override
  State<DealerPriceHistoryDialog> createState() =>
      _DealerPriceHistoryDialogState();
}

class _DealerPriceHistoryDialogState extends State<DealerPriceHistoryDialog> {
  final _transform = TransformationController();
  bool _refreshing = false;
  int _generation = 0;
  ImageProvider get _provider =>
      widget.imageProvider ?? NetworkImage(widget.uri.toString());

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _zoom(double factor, Size viewport) {
    final scale = (_transform.value.getMaxScaleOnAxis() * factor).clamp(
      1.0,
      8.0,
    );
    final center = viewport.center(Offset.zero);
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        center.dx * (1 - scale),
        center.dy * (1 - scale),
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await _provider.evict();
    } finally {
      if (mounted) {
        setState(() {
          _generation++;
          _refreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = Theme.of(context).colorScheme;
    final mobile =
        theme.platform == TargetPlatform.iOS ||
        theme.platform == TargetPlatform.android;
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              Navigator.of(context).pop();
              return null;
            },
          ),
        },
        child: Dialog(
          insetPadding: EdgeInsets.fromLTRB(16, 16, 16, mobile ? 112 : 16),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280, maxHeight: 720),
            child: Column(
              children: [
                WindowNavigationSafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8, top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.dealerPriceHistory,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                widget.carName,
                                style: theme.textTheme.labelMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('dealer-chart-refresh'),
                          tooltip: context.l10n.dealerRetry,
                          onPressed: _refreshing ? null : _refresh,
                          icon: const Icon(Icons.refresh),
                        ),
                        IconButton(
                          key: const ValueKey('dealer-chart-close'),
                          tooltip: context.l10n.dealerClose,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, bounds) => Column(
                      children: [
                        Expanded(
                          child: InteractiveViewer(
                            key: const ValueKey('dealer-price-chart'),
                            transformationController: _transform,
                            minScale: 1,
                            maxScale: 8,
                            child: SizedBox.expand(
                              child: Image(
                                key: ValueKey(_generation),
                                image: _provider,
                                fit: BoxFit.contain,
                                frameBuilder: (_, child, frame, loaded) =>
                                    loaded || frame != null
                                    ? child
                                    : const Center(
                                        child: GtLoadingIndicator(
                                          withBackdrop: true,
                                        ),
                                      ),
                                errorBuilder: (_, _, _) => Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.broken_image_outlined,
                                          color: colors.onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          context.l10n.dealerPriceError,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        OutlinedButton(
                                          key: const ValueKey(
                                            'dealer-chart-retry',
                                          ),
                                          onPressed: _refreshing
                                              ? null
                                              : _refresh,
                                          child: Text(context.l10n.dealerRetry),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              IconButton(
                                key: const ValueKey('dealer-chart-zoom-out'),
                                tooltip: context.l10n.dealerChartZoomOut,
                                onPressed: () => _zoom(1 / 1.5, bounds.biggest),
                                icon: const Icon(Icons.remove),
                              ),
                              TextButton(
                                key: const ValueKey('dealer-chart-reset'),
                                onPressed: () =>
                                    _transform.value = Matrix4.identity(),
                                child: Text(context.l10n.dealerChartReset),
                              ),
                              IconButton(
                                key: const ValueKey('dealer-chart-zoom-in'),
                                tooltip: context.l10n.dealerChartZoomIn,
                                onPressed: () => _zoom(1.5, bounds.biggest),
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Text(
                    context.l10n.dealerChartSource,
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
