import 'package:flutter/material.dart';

import '../../repositories/car_catalog.dart';

/// A searchable selector over the bundled official catalogue.
class GtAutoCarPicker extends StatefulWidget {
  const GtAutoCarPicker({
    super.key,
    required this.cars,
    required this.selectedId,
  });
  final List<CarInfo> cars;
  final String? selectedId;
  @override
  State<GtAutoCarPicker> createState() => _GtAutoCarPickerState();
}

class _GtAutoCarPickerState extends State<GtAutoCarPicker> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cars =
        widget.cars
            .where(
              (car) => car.name.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.sizeOf(context).height * .75,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose a car',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('gt-auto-search'),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Search the official catalogue',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              Text('${cars.length} cars', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Expanded(
                child: cars.isEmpty
                    ? const Center(child: Text('No cars match this search.'))
                    : ListView.separated(
                        itemCount: cars.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final car = cars[index];
                          final selected = car.id == widget.selectedId;
                          return Material(
                            color: selected
                                ? theme.colorScheme.secondaryContainer
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: ValueKey('gt-auto-car-${car.id}'),
                              onTap: () => Navigator.pop(context, car.id),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        car.name,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                    if (selected)
                                      Icon(
                                        Icons.check,
                                        color: theme.colorScheme.secondary,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
