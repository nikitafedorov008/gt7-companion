// legendary_car_display.dart

import 'package:flutter/material.dart';
import 'package:auto_route/annotations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../../models/car_dealer/car.dart';
import '../../../repositories/car_repository.dart';
import 'legendary_car_grid_item.dart';

@RoutePage()
class LegendaryCarDisplay extends StatefulWidget {
  const LegendaryCarDisplay({super.key});

  @override
  State<LegendaryCarDisplay> createState() => _LegendaryCarDisplayState();
}

class _LegendaryCarDisplayState extends State<LegendaryCarDisplay> {
  late final ScrollController _ribbonController;

  @override
  void initState() {
    super.initState();
    _ribbonController = ScrollController();

    Future.microtask(() {
      context.read<CarRepository>().fetchAllCars();
    });
  }

  @override
  void dispose() {
    _ribbonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    return Scaffold(
      appBar: null,
      bottomNavigationBar: null,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withAlpha(4),
              Colors.white.withAlpha(8),
              Colors.black12,
              Colors.black,
            ],
          ),
        ),
        child: Consumer<CarRepository>(
          builder: (context, repository, child) {
            if (repository.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (repository.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Legend Car Data',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(repository.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () =>
                          repository.fetchAllCars(forceRefresh: true),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final legendCars = repository.getLegendCars();

            return Column(
              children: [
                // Header: AUTO-H | LEGENDARY CAR DEALERSHIP
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SvgPicture.asset(
                          'assets/images/legend-hagerty.svg',
                          width: 80,
                          height: 24,
                        ),
                        IconButton(
                          onPressed: Navigator.of(context).pop,
                          icon: const Icon(Icons.close_sharp),
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Legend cars list/grid
                Expanded(child: _buildCarListOrGrid(legendCars, 'Legend Cars')),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCarListOrGrid(List<Car> cars, String title) {
    // Use a horizontal, bounded ListView for both mobile and desktop.
    // Snapshot the list to avoid modifications during layout (this prevents
    // "_debugDoingThisLayout" assertions when the underlying provider updates).
    final items = List<Car>.from(cars);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        // Fixed item width keeps layout stable and prevents reflow during build.
        final itemWidth = isNarrow ? 260.0 : 360.0;
        final height = isNarrow ? 360.0 : 420.0;

        return SizedBox(
          height: height,
          child: Listener(
            onPointerSignal: (event) {
              // Access scrollDelta dynamically so the code passes older analyzers
              final dyn = event as dynamic;
              try {
                final sd = dyn.scrollDelta;
                if (sd == null) return;
                final rawDelta = (sd.dy != 0 ? sd.dy : sd.dx) as double;
                final sensitivity = 1.0;
                final delta = rawDelta * sensitivity;
                if (_ribbonController.hasClients) {
                  final max = _ribbonController.position.maxScrollExtent;
                  final newOffset = (_ribbonController.offset + delta).clamp(
                    0.0,
                    max,
                  );
                  _ribbonController.jumpTo(newOffset);
                }
              } catch (_) {
                // ignore: no-op on SDKs that don't expose scrollDelta
              }
            },
            child: ListView.builder(
              controller: _ribbonController,
              key: const PageStorageKey('legendary_car_ribbon'),
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 12.0,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final car = items[index];
                return AspectRatio(
                  aspectRatio: 3 / 5,
                  child: SizedBox(
                    width: itemWidth,
                    child: LegendaryCarCardItem(car: car),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
