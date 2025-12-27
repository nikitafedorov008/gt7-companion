import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/gt7info_data.dart';
import '../services/gt7info_service.dart';
import 'car_grid_item.dart';

class GT7InfoDisplay extends StatefulWidget {
  const GT7InfoDisplay({super.key});

  @override
  State<GT7InfoDisplay> createState() => _GT7InfoDisplayState();
}

class _GT7InfoDisplayState extends State<GT7InfoDisplay> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Fetch GT7Info data when widget initializes
    Future.microtask(() {
      context.read<GT7InfoService>().fetchGT7InfoData();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GT7InfoService>(
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
                  'Error Loading GT7Info Data',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  service.errorMessage!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => service.fetchGT7InfoData(forceRefresh: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (service.data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No GT7Info data available'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => service.fetchGT7InfoData(forceRefresh: true),
                  child: const Text('Load Data'),
                ),
              ],
            ),
          );
        }

        final data = service.data!;
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
                              'GT7 Dealership Info',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Game Update: ${data.updateTimestamp}',
                              style: const TextStyle(color: Colors.grey),
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
                        onPressed: () => service.fetchGT7InfoData(forceRefresh: true),
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
                  _buildCarListView(data.used.cars, 'Auto+: Used Cars'),
                  
                  // Legendary cars tab
                  _buildCarListView(data.legend.cars, 'Hagerty Collection: Legendary Cars'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCarListView(List<CarData> cars, String title) {
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
                  return CarGridItem(car: cars[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

}