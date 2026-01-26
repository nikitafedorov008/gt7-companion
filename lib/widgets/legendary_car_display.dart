// legendary_car_display.dart

import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../models/unified_car_data.dart';
import '../repositories/unified_car_repository.dart';
import '../widgets/legendary_car_grid_item.dart';

class LegendaryCarDisplay extends StatefulWidget {
  const LegendaryCarDisplay({super.key});

  @override
  State<LegendaryCarDisplay> createState() => _LegendaryCarDisplayState();
}

class _LegendaryCarDisplayState extends State<LegendaryCarDisplay> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<UnifiedCarRepository>().fetchAllCars();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedCarRepository>(
      builder: (context, repository, child) {
        if (repository.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (repository.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error Loading Legend Car Data', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(repository.errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => repository.fetchAllCars(forceRefresh: true),
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
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/ucd-auto.svg',
                      width: 80,
                      height: 24,
                    ),
                    VerticalDivider(
                      thickness: 2,
                      color: Colors.black87,
                    ),
                    const Text(
                      'LEGENDARY CAR DEALERSHIP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Legend cars list/grid
            Expanded(
              child: _buildCarListOrGrid(legendCars, 'Legend Cars'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCarListOrGrid(List<UnifiedCarData> cars, String title) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      // 📱 Мобильная версия: ListView — одна карточка в ряду
      return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: cars.length,
        itemBuilder: (context, index) => LegendaryCarCardItem(car: cars[index]),
      );
    } else {
      // 💻 Десктоп/планшет: GridView — сетка
      return LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 2;
          if (constraints.maxWidth > 800) crossAxisCount = 3;
          if (constraints.maxWidth > 1200) crossAxisCount = 4;

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.8, // подходит для горизонтальных карточек
            ),
            itemCount: cars.length,
            itemBuilder: (context, index) => LegendaryCarCardItem(car: cars[index]),
          );
        },
      );
    }
  }
}
