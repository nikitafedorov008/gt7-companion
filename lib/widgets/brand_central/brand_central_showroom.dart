import '../gt_loading_indicator.dart';
import 'package:gt7_companion/widgets/window_navigation_safe_area.dart';
import 'package:gt7_companion/l10n/ui_messages.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/brand_central/brand_central_data.dart';
import '../../repositories/brand_central_repository.dart';

/// A photograph-led showroom, with the proportions of the GT7 dealer view.
class BrandCentralShowroom extends StatefulWidget {
  const BrandCentralShowroom({super.key, required this.repository});
  final BrandCentralRepository repository;
  @override
  State<BrandCentralShowroom> createState() => _BrandCentralShowroomState();
}

class _BrandCentralShowroomState extends State<BrandCentralShowroom> {
  final _pages = PageController();
  int _page = 0;
  int _imageAttempt = 0;
  String _section = 'History';
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _move(int delta) {
    final count = widget.repository.photos.length;
    if (count == 0) return;
    _pages.animateToPage(
      (_page + delta) % count,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openGallery() async {
    final repo = widget.repository;
    final controller = PageController(initialPage: _page);
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog.fullscreen(
          child: Scaffold(
            appBar: WindowNavigationAppBar(
              child: AppBar(
                leading: IconButton(
                  key: const ValueKey('showroom-close-fullscreen'),
                  tooltip: context.tr('Back to showroom'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                title: Text(
                  context.tr(repo.selectedCar!.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            body: PageView.builder(
              controller: controller,
              itemCount: repo.photos.length,
              itemBuilder: (_, index) => InteractiveViewer(
                child: Center(
                  child: Image.network(
                    repo.photos[index],
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        Text(context.tr('Photo unavailable')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = widget.repository;
    final car = repo.selectedCar!;
    final brand = repo.data!.brands[car.brandId]!;
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        final hero = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 48,
                    child: Image.network(
                      brand.logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Text(context.tr(brand.name)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      context.tr(
                        '${brand.country.toUpperCase()} / ${brand.name.toUpperCase()}',
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 1,
                        colors: [
                          theme.colorScheme.surfaceContainerHighest,
                          theme.colorScheme.surface,
                        ],
                      ),
                    ),
                    child: repo.photos.isEmpty
                        ? _Photo(
                            url: car.thumbnail,
                            onRetry: () => setState(() => _imageAttempt++),
                            attempt: _imageAttempt,
                          )
                        : PageView.builder(
                            key: const ValueKey('showroom-gallery'),
                            controller: _pages,
                            itemCount: repo.photos.length,
                            onPageChanged: (index) =>
                                setState(() => _page = index),
                            itemBuilder: (_, index) => _Photo(
                              url: repo.photos[index],
                              onRetry: () => setState(() => _imageAttempt++),
                              attempt: _imageAttempt,
                            ),
                          ),
                  ),
                  if (repo.galleryLoading)
                    const Align(
                      alignment: Alignment.bottomCenter,
                      child: LinearProgressIndicator(),
                    ),
                  if (repo.photos.isNotEmpty)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: IconButton.filledTonal(
                        key: const ValueKey('showroom-fullscreen'),
                        tooltip: context.tr('View full image'),
                        icon: const Icon(Icons.fullscreen),
                        onPressed: _openGallery,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    context.tr(
                      repo.photos.isEmpty
                          ? 'Official catalogue preview'
                          : '${_page + 1} / ${repo.photos.length}',
                    ),
                    style: theme.textTheme.labelMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    key: const ValueKey('showroom-previous'),
                    tooltip: context.tr('Previous photo'),
                    onPressed: repo.photos.length > 1 ? () => _move(-1) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    key: const ValueKey('showroom-next'),
                    tooltip: context.tr('Next photo'),
                    onPressed: repo.photos.length > 1 ? () => _move(1) : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            if (repo.galleryError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr(repo.galleryError!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr('Retry gallery'),
                      onPressed: repo.retryGallery,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
          ],
        );
        final information = Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('GT7 SHOWROOM'),
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr(car.name),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr(car.tagline),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in [
                    car.text('performancePoint'),
                    car.text('power'),
                    car.text('weight'),
                    car.text('driveTrain'),
                  ])
                    if (value.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.tr(value),
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final section in [
                    'History',
                    'Specifications',
                    'Gallery',
                  ])
                    ChoiceChip(
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      key: ValueKey('showroom-tab-$section'),
                      label: Text(context.tr(section)),
                      selected: _section == section,
                      onSelected: (_) => setState(() => _section = section),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (_section == 'History')
                SelectableText(
                  context.tr(
                    car.history.isEmpty
                        ? 'No official description available.'
                        : car.history,
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.65),
                ),
              if (_section == 'Specifications') _Specifications(car: car),
              if (_section == 'Gallery') ...[
                Text(
                  context.tr('OFFICIAL PHOTOGRAPHY'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                if (repo.photos.isEmpty)
                  Text(
                    context.tr(
                      'The gallery is loading or unavailable. Use Retry gallery to try again.',
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < repo.photos.length; i++)
                      SizedBox(
                        width: 120,
                        height: 76,
                        child: Material(
                          clipBehavior: Clip.antiAlias,
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                            key: ValueKey('gallery-thumb-$i'),
                            onTap: () {
                              _pages.jumpToPage(i);
                              setState(() => _page = i);
                            },
                            child: Image.network(
                              repo.photos[i],
                              cacheWidth: 360,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.image_not_supported_outlined,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              const Divider(),
              Text(
                context.tr(
                  'Official GT7 Car List · ${repo.language == 'ru' ? 'Русский · метрические единицы' : 'English (US) · US units'}\nPolyphony Digital / Sony Interactive Entertainment',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () =>
                    launchUrl(Uri.parse(car.sourceUrl(repo.language))),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(context.tr('Open official source')),
              ),
            ],
          ),
        );
        return SingleChildScrollView(
          key: const ValueKey('showroom-scroll'),
          padding: const EdgeInsets.only(bottom: 120),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: hero),
                    Expanded(flex: 4, child: information),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [hero, information],
                ),
        );
      },
    );
  }
}

class _Specifications extends StatelessWidget {
  const _Specifications({required this.car});
  final ShowroomCar car;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final entry in car.specifications.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    context.tr(entry.key),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    context.tr(entry.value.isEmpty ? '—' : entry.value),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({
    required this.url,
    required this.onRetry,
    required this.attempt,
  });
  final String url;
  final VoidCallback onRetry;
  final int attempt;
  @override
  Widget build(BuildContext context) => Image.network(
    url,
    key: ValueKey('$url-$attempt'),
    fit: BoxFit.contain,
    loadingBuilder: (context, child, progress) =>
        progress == null ? child : const Center(child: GtLoadingIndicator()),
    errorBuilder: (_, _, _) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_not_supported_outlined),
          IconButton(
            onPressed: () {
              NetworkImage(url).evict();
              onRetry();
            },
            tooltip: context.tr('Retry photo'),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    ),
  );
}
