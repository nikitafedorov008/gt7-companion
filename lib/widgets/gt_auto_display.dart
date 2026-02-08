import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';

@RoutePage()
class GTAutoDisplay extends StatelessWidget {
  const GTAutoDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GT Auto'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.build_circle_outlined,
              size: 72,
              color: Colors.amber,
            ),
            const SizedBox(height: 12),
            Text('GT Auto', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Service & tuning — coming soon',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
