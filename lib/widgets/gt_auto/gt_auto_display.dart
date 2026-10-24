import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/gt_auto_repository.dart';
import 'gt_auto_car_picker.dart';
import 'gt_auto_workshop_header.dart';
import 'gt_auto_workshop_panels.dart';

// START_MODULE_CONTRACT
// PURPOSE: Present the selected Gran Turismo workshop design with real car data.
// SCOPE: Responsive service menu, car selection, specs, swaps, parts and plans.
// DEPENDS: M-REPO-GT-AUTO, M-MODEL-GT-AUTO
// LINKS: M-WIDGET-GT-AUTO, V-M-WIDGET-GT-AUTO
// END_MODULE_CONTRACT
// START_MODULE_MAP
// GTAutoDisplay - routed responsive workshop screen
// END_MODULE_MAP

@RoutePage()
class GTAutoDisplay extends StatefulWidget {
  const GTAutoDisplay({super.key});
  @override
  State<GTAutoDisplay> createState() => _GTAutoDisplayState();
}

class _GTAutoDisplayState extends State<GTAutoDisplay> {
  _Section _section = _Section.specs;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<GtAutoRepository>().load();
    });
  }

  Future<void> _chooseCar(GtAutoRepository repository) async {
    final id = await showDialog<String>(
      context: context,
      builder: (_) => GtAutoCarPicker(
        cars: repository.cars,
        selectedId: repository.selectedCar?.id,
      ),
    );
    if (id != null && mounted) repository.selectCar(id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('GT Auto'),
        actions: [
          Consumer<GtAutoRepository>(
            builder: (context, repository, _) => IconButton(
              key: const ValueKey('gt-auto-refresh'),
              tooltip: 'Refresh workshop data',
              onPressed: repository.isLoading
                  ? null
                  : () => repository.load(forceRefresh: true),
              icon: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Consumer<GtAutoRepository>(
          builder: (context, repository, _) {
            final car = repository.selectedCar;
            if (car == null) {
              if (repository.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Car catalogue could not be loaded.'),
                    IconButton(
                      tooltip: 'Retry',
                      onPressed: () => repository.load(forceRefresh: true),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              key: const ValueKey('gt-auto-scroll'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 64,
                              height: 56,
                              padding: const EdgeInsets.all(8),
                              color: theme.colorScheme.secondary,
                              child: Image.asset(
                                'assets/images/gt_auto.webp',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GARAGE / GT AUTO',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    letterSpacing: 2,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Workshop',
                                  style: theme.textTheme.headlineSmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (repository.isLoading) ...[
                        LinearProgressIndicator(
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(height: 16),
                      ],
                      for (final error in repository.errors.entries)
                        _SourceError(
                          source: error.key,
                          message: error.value,
                          loading: repository.isLoading,
                          onRetry: () => repository.load(forceRefresh: true),
                        ),
                      if (repository.storageError case final message?)
                        _SourceError(
                          source: 'Local storage',
                          message: message,
                          loading: false,
                          onRetry: () =>
                              repository.setNotes(repository.build.notes),
                        ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide =
                              constraints.maxWidth >= 900 &&
                              MediaQuery.textScalerOf(context).scale(14) <= 21;
                          final hero = GtAutoWorkshopHeader(
                            car: car,
                            catalog: repository.catalog,
                            onChoose: () => _chooseCar(repository),
                          );
                          final menu = _ServiceMenu(
                            selected: _section,
                            onSelect: (value) =>
                                setState(() => _section = value),
                            vertical: wide,
                          );
                          return wide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 7, child: hero),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 4, child: menu),
                                  ],
                                )
                              : Column(
                                  children: [
                                    hero,
                                    const SizedBox(height: 16),
                                    menu,
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 24),
                      Divider(color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      KeyedSubtree(
                        key: ValueKey('${car.id}-${_section.name}'),
                        child: switch (_section) {
                          _Section.specs => GtAutoSpecsPanel(
                            repository: repository,
                          ),
                          _Section.swaps => GtAutoSwapsPanel(
                            repository: repository,
                          ),
                          _Section.parts => GtAutoPartsPanel(
                            repository: repository,
                          ),
                          _Section.build => GtAutoBuildPanel(
                            repository: repository,
                          ),
                        },
                      ),
                      const SizedBox(height: 24),
                      Divider(color: theme.colorScheme.outlineVariant),
                      Text(
                        'GT AUTO / GT7 COMPANION · ${repository.cars.length} cars · ${repository.swapCount} confirmed swap records',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _Section { specs, swaps, parts, build }

const _sections = <_Section, (String, String, IconData)>{
  _Section.specs: ('Specifications', 'Vehicle passport', Icons.speed_outlined),
  _Section.swaps: (
    'Engine swaps',
    'Compatibility & comparison',
    Icons.swap_horiz,
  ),
  _Section.parts: ('Parts & body', 'Special upgrades', Icons.build_outlined),
  _Section.build: (
    'Build plan',
    'Your preparation checklist',
    Icons.assignment_outlined,
  ),
};

class _ServiceMenu extends StatelessWidget {
  const _ServiceMenu({
    required this.selected,
    required this.onSelect,
    required this.vertical,
  });
  final _Section selected;
  final ValueChanged<_Section> onSelect;
  final bool vertical;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = vertical || constraints.maxWidth < 360 ? 1 : 2;
      final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final entry in _sections.entries)
            SizedBox(
              width: width,
              child: _ServiceTile(
                section: entry.key,
                selected: selected == entry.key,
                onTap: () => onSelect(entry.key),
              ),
            ),
        ],
      );
    },
  );
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.section,
    required this.selected,
    required this.onTap,
  });
  final _Section section;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final entry = _sections[section]!;
    final foreground = selected ? colors.onSecondary : colors.onSurface;
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? colors.secondary : colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('gt-auto-section-${section.name}'),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? colors.secondary : colors.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Icon(entry.$3, size: 24, color: foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.$1,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: foreground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.$2,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: foreground.withValues(alpha: .75),
                        ),
                      ),
                    ],
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

class _SourceError extends StatelessWidget {
  const _SourceError({
    required this.source,
    required this.message,
    required this.loading,
    required this.onRetry,
  });
  final String source, message;
  final bool loading;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$source: $message',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Retry $source',
                onPressed: loading ? null : onRetry,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
