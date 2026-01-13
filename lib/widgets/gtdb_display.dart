import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/used_car.dart';
import '../models/legendary_car.dart';
import '../models/gt7info_data.dart'; // Needed for CarData compatibility
import '../services/gtdb_service.dart';
import '../widgets/car_grid_item.dart';

class GTDBDisplay extends StatefulWidget {
  const GTDBDisplay({super.key});

  @override
  State<GTDBDisplay> createState() => _GTDBDisplayState();
}

class _GTDBDisplayState extends State<GTDBDisplay> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch GTDB data when widget initializes
    Future.microtask(() {
      context.read<GTDBService>().fetchGTDBData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GTDBService>(
      builder: (context, service, child) {
        if (service.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (service.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error Loading GTDB Data',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  service.errorMessage!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => service.fetchGTDBData(forceRefresh: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (service.usedCars.isEmpty && service.legendaryCars.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No GTDB data available'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => service.fetchGTDBData(forceRefresh: true),
                  child: const Text('Load Data'),
                ),
              ],
            ),
          );
        }

        final lastUpdated = service.lastUpdated;

        return Column(
          children: [
            // Header with last updated info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GTDB Dealership Info',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (lastUpdated != null)
                              Text(
                                'Last refreshed: ${_formatDateTime(lastUpdated)}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh data',
                        onPressed: () => service.fetchGTDBData(forceRefresh: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Used Car Dealership'),
                Tab(text: 'Legendary Dealership'),
              ],
            ),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Used cars tab
                  _buildCarListView(service.usedCars, 'GTDB Used Cars'),

                  // Legendary cars tab
                  _buildCarListView(service.legendaryCars, 'GTDB Legendary Cars'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCarListView<T>(List<T> cars, String title) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount;
              double itemWidth = 300.0; // Approximate width for each item

              // For used car dealership, return 4-6 items per row depending on screen size
              if (title.contains('Used Cars')) {
                if (constraints.maxWidth < 600) {
                  crossAxisCount = 1; // 1 item per row on small screens
                } else if (constraints.maxWidth < 800) {
                  crossAxisCount = 2; // 2 items per row on medium screens
                } else if (constraints.maxWidth < 1200) {
                  crossAxisCount = 4; // 4 items per row on larger screens
                } else {
                  crossAxisCount = 6; // 6 items per row on very large screens
                }
              } else {
                // For legendary cars, use a consistent grid
                if (constraints.maxWidth < 600) {
                  crossAxisCount = 1; // 1 item per row on small screens
                } else if (constraints.maxWidth < 800) {
                  crossAxisCount = 2; // 2 items per row on medium screens
                } else {
                  crossAxisCount = 3; // 3 items per row on larger screens
                }
              }

              return GridView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5, // Adjust aspect ratio as needed
                ),
                itemCount: cars.length,
                itemBuilder: (context, index) {
                  if (cars[index] is UsedCar) {
                    return CarGridItem(car: _convertUsedCarToCarData(cars[index] as UsedCar));
                  } else if (cars[index] is LegendaryCar) {
                    return CarGridItem(car: _convertLegendaryCarToCarData(cars[index] as LegendaryCar));
                  } else {
                    // Fallback for unexpected types
                    return Container();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Convert UsedCar to CarData for compatibility with CarGridItem widget
  CarData _convertUsedCarToCarData(UsedCar usedCar) {
    return CarData(
      carId: 'car${usedCar.carIdFromDetails ?? usedCar.id}',
      manufacturer: usedCar.manufacturerName ?? 'Unknown',
      region: 'xx',
      name: usedCar.name ?? 'Unknown Car',
      credits: usedCar.price ?? 0,
      state: usedCar.state ?? 'normal',
      estimateDays: 0,
      maxEstimateDays: 0,
      isNew: usedCar.state == 'new',
      rewardCar: null,
      engineSwap: null,
      lotteryCar: null,
      trophyCar: null,
    );
  }

  // Convert LegendaryCar to CarData for compatibility with CarGridItem widget
  CarData _convertLegendaryCarToCarData(LegendaryCar legendaryCar) {
    return CarData(
      carId: 'car${legendaryCar.id}',
      manufacturer: legendaryCar.manufacturerName ?? 'Unknown',
      region: 'xx',
      name: legendaryCar.name ?? 'Unknown Car',
      credits: legendaryCar.price ?? 0,
      state: legendaryCar.state ?? 'normal',
      estimateDays: 0,
      maxEstimateDays: 0,
      isNew: legendaryCar.state == 'new',
      rewardCar: null,
      engineSwap: null,
      lotteryCar: null,
      trophyCar: null,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}