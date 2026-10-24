import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/gt_auto/gt_auto_data.dart';
import '../../repositories/gt_auto_repository.dart';
import '../../services/gt_auto_parts_service.dart';

class GtAutoSpecsPanel extends StatelessWidget {
  const GtAutoSpecsPanel({super.key, required this.repository});
  final GtAutoRepository repository;
  @override
  Widget build(BuildContext context) {
    final car = repository.selectedCar!;
    final specs = repository.specs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(title: 'Vehicle specifications', label: 'STOCK'),
        _StatGrid(
          values: [
            ('Power', car.power),
            ('Performance Points', car.performancePoints),
            ('Weight', car.weight),
            ('Drivetrain', car.driveTrain),
            ('Aspiration', car.aspiration),
            ('Class', car.carClass),
          ],
        ),
        const _SourceLink(
          name: 'Official Gran Turismo car catalogue',
          url: 'https://www.gran-turismo.com/us/gt7/carlist/',
        ),
        if (specs != null) ...[
          const SizedBox(height: 24),
          const _PanelTitle(
            title: 'Engine & dimensions',
            label: 'COMMUNITY DATA',
          ),
          _StatGrid(
            values: [
              ('Engine', specs.engine),
              ('Configuration', specs.engineType),
              ('Displacement', _value(specs.displacementCc, 'cc', decimals: 0)),
              (
                'Torque',
                _value(
                  specs.torqueKgfm == null ? null : specs.torqueKgfm! * 9.80665,
                  'Nm',
                ),
              ),
              ('Length', _value(specs.lengthMm, 'mm', decimals: 0)),
              ('Width', _value(specs.widthMm, 'mm', decimals: 0)),
              ('Height', _value(specs.heightMm, 'mm', decimals: 0)),
            ],
          ),
          if (repository.swapSource case final source?) _Source(source: source),
        ] else
          const _Note(
            'Additional engine and dimension data is not documented for this car.',
          ),
      ],
    );
  }
}

class GtAutoSwapsPanel extends StatefulWidget {
  const GtAutoSwapsPanel({super.key, required this.repository});
  final GtAutoRepository repository;
  @override
  State<GtAutoSwapsPanel> createState() => _GtAutoSwapsPanelState();
}

class _GtAutoSwapsPanelState extends State<GtAutoSwapsPanel> {
  String? _preview;
  @override
  Widget build(BuildContext context) {
    final repo = widget.repository;
    final swaps = repo.swaps;
    if (swaps.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(title: 'Engine swaps', label: 'COMPATIBILITY'),
          const _Note(
            'No confirmed swap records for this car in the current source. This does not establish incompatibility.',
          ),
          if (repo.swapSource case final source?) _Source(source: source),
        ],
      );
    }
    final selected =
        swaps
            .where((s) => s.id == (_preview ?? repo.build.swapId))
            .firstOrNull ??
        swaps.first;
    final specs = repo.specs;
    final theme = Theme.of(context);
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('gt-auto-engine-${selected.id}'),
          initialValue: selected.id,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Compatible engine'),
          items: [
            for (final swap in swaps)
              DropdownMenuItem(
                value: swap.id,
                child: Text(swap.engine, overflow: TextOverflow.ellipsis),
              ),
          ],
          selectedItemBuilder: (_) => [
            for (final swap in swaps)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  swap.engine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) => setState(() => _preview = value),
        ),
        const SizedBox(height: 12),
        Text('Donor: ${selected.donor}', style: theme.textTheme.bodyMedium),
        if (selected.version.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Added in update ${selected.version}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const ValueKey('gt-auto-save-swap'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
          ),
          onPressed: repo.build.swapId == selected.id
              ? null
              : () => repo.selectSwap(selected.id),
          icon: Icon(
            repo.build.swapId == selected.id ? Icons.check : Icons.add,
          ),
          label: Text(
            repo.build.swapId == selected.id
                ? 'In build plan'
                : 'Add to build plan',
          ),
        ),
      ],
    );
    final comparison = Column(
      children: [
        const _StatRow(label: 'GTPlus comparison', value: 'Stock → Swap'),
        _StatRow(
          label: 'Power · HP',
          value: '${_number(specs?.powerHp)} → ${_number(selected.powerHp)}',
        ),
        _StatRow(
          label: 'PP',
          value:
              '${_number(specs?.pp, decimals: 2)} → ${_number(selected.pp, decimals: 2)}',
        ),
        _StatRow(
          label: 'Weight · kg',
          value:
              '${_number(specs?.weightKg, decimals: 0)} → ${_number(selected.weightKg, decimals: 0)}',
        ),
        _StatRow(
          label: 'Torque · kgf·m',
          value:
              '${_number(specs?.torqueKgfm)} → ${_number(selected.torqueKgfm)}',
        ),
        _StatRow(
          label: 'In-game cost',
          value: selected.price == null
              ? 'Not documented'
              : 'Cr. ${NumberFormat.decimalPattern('en_US').format(selected.price)}',
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelTitle(title: 'Engine swaps', label: '${swaps.length} OPTIONS'),
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= 760
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: controls),
                    const SizedBox(width: 24),
                    Expanded(child: comparison),
                  ],
                )
              : Column(
                  children: [controls, const SizedBox(height: 20), comparison],
                ),
        ),
        const _Note(
          'GTPlus stock and swap figures are compared within the same source. Official catalogue values may differ. Plan here; install in GT7.',
        ),
        if (repo.swapSource case final source?) _Source(source: source),
      ],
    );
  }
}

class GtAutoPartsPanel extends StatelessWidget {
  const GtAutoPartsPanel({super.key, required this.repository});
  final GtAutoRepository repository;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = repository.parts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(title: 'Special parts', label: 'COMPATIBILITY'),
        if (parts == null)
          const _Note(
            'This car has no uniquely matched record in the special-parts source. Compatibility is unknown.',
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 2 : 1;
            final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final part in GtAutoPartsService.partNames)
                  SizedBox(
                    width: width,
                    child: Material(
                      color: theme.colorScheme.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: CheckboxListTile(
                        key: ValueKey('gt-auto-part-$part'),
                        activeColor: theme.colorScheme.secondary,
                        checkColor: theme.colorScheme.onSecondary,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(part, style: theme.textTheme.bodyMedium),
                        subtitle: Text(switch (parts?.compatibility[part]) {
                          true => 'Compatible · add to plan',
                          false => 'Not compatible',
                          null => 'Not documented',
                        }, style: theme.textTheme.bodySmall),
                        value: repository.build.parts.contains(part),
                        onChanged: parts?.compatibility[part] == true
                            ? (value) =>
                                  repository.setPart(part, value ?? false)
                            : null,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const _Note(
          'Compatibility refers to the stock car; engine swaps can change available upgrades. Regular tuning-shop parts and wide-body availability are not covered. Blank cells are unknown.',
        ),
        if (repository.partsSource case final source?) _Source(source: source),
      ],
    );
  }
}

class GtAutoBuildPanel extends StatelessWidget {
  const GtAutoBuildPanel({super.key, required this.repository});
  final GtAutoRepository repository;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = repository.build;
    final swap = repository.swaps.where((s) => s.id == plan.swapId).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(title: 'Build plan', label: 'SAVED ON THIS DEVICE'),
        Text(repository.selectedCar!.name, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        if (plan.swapId == null && plan.parts.isEmpty)
          const _Note(
            'Your plan is empty. Add an engine from Engine swaps or choose compatible special parts.',
          ),
        if (plan.swapId != null)
          _PlanRow(
            label:
                swap?.engine ?? 'Saved engine · source currently unavailable',
            onRemove: () => repository.selectSwap(null),
          ),
        for (final part in plan.parts)
          _PlanRow(
            label: part,
            onRemove: () => repository.setPart(part, false),
          ),
        const SizedBox(height: 16),
        TextFormField(
          key: ValueKey('gt-auto-notes-${repository.selectedCar!.id}'),
          initialValue: plan.notes,
          minLines: 2,
          maxLines: 5,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Build notes',
            hintText: 'Tyres, race requirements, settings…',
          ),
          onChanged: repository.setNotes,
        ),
        const _Note(
          'This is your preparation checklist, not the installed state of the game. PP and combined part effects must be checked in GT7.',
        ),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.check, size: 18),
      const SizedBox(width: 12),
      Expanded(child: Text(label)),
      IconButton(
        tooltip: 'Remove $label',
        onPressed: onRemove,
        icon: const Icon(Icons.close, size: 18),
      ),
    ],
  );
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.title, required this.label});
  final String title, label;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 20,
        runSpacing: 8,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.values});
  final List<(String, String)> values;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900
          ? 3
          : constraints.maxWidth >= 500
          ? 2
          : 1;
      final width = (constraints.maxWidth - 24 * (columns - 1)) / columns;
      return Wrap(
        spacing: 24,
        children: [
          for (final entry in values)
            SizedBox(
              width: width,
              child: _StatRow(label: entry.$1, value: entry.$2),
            ),
        ],
      );
    },
  );
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value.isEmpty || value == '---' ? 'Not documented' : value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _Source extends StatelessWidget {
  const _Source({required this.source});
  final GtAutoSource source;
  @override
  Widget build(BuildContext context) => _SourceLink(
    name:
        '${source.name} · fetched ${DateFormat('dd MMM yyyy, HH:mm').format(source.fetchedAt.toLocal())}',
    url: source.url,
  );
}

class _SourceLink extends StatelessWidget {
  const _SourceLink({required this.name, required this.url});
  final String name, url;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: () async {
        final opened = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open source.')),
          );
        }
      },
      icon: const Icon(Icons.open_in_new, size: 14),
      label: Text(name, style: Theme.of(context).textTheme.bodySmall),
    ),
  );
}

String _number(double? value, {int decimals = 1}) => value == null
    ? '—'
    : value.toStringAsFixed(value == value.roundToDouble() ? 0 : decimals);
String _value(double? value, String unit, {int decimals = 1}) => value == null
    ? 'Not documented'
    : '${_number(value, decimals: decimals)} $unit';
