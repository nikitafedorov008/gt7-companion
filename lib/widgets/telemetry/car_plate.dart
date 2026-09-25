import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/telemetry/telemetry_data.dart';
import '../../repositories/car_catalog.dart';
import '../../theme/gt7_theme.dart';

/// The plate the HUD shows for the car being driven: its picture, the model
/// name and the class/power/weight line.
///
/// GT7's UDP packet names the car only by an opaque id, so the picture and the
/// names come from [CarCatalog], which is generated from the official car list
/// (see `tools/fetch_gt7_cars.py`). The plate hides itself until the catalogue
/// is in memory and the packet actually reports a car.
class CarPlate extends StatelessWidget {
  const CarPlate({super.key, required this.telemetry});

  final TelemetryData telemetry;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CarCatalog>();
    // Nothing to show until the catalogue is in memory and the packet carries
    // a car id at all (it is 0 while the game is not reporting a car).
    if (!catalog.isLoaded || telemetry.carId <= 0) {
      return const SizedBox.shrink();
    }

    final car = catalog.byPacketId(telemetry.carId);
    if (car == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          'CAR ID ${telemetry.carId} IS NOT IN THE CATALOGUE',
          style: gt7Caption(color: gt7TextMuted, size: 8),
        ),
      );
    }

    return Container(
      width: 380,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          _CarPhoto(catalog: catalog, carId: telemetry.carId),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  car.shortName.isEmpty ? car.name : car.shortName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gt7Digital(size: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  car.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gt7Caption(color: gt7TextMuted, size: 8),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (car.carClass.isNotEmpty) car.carClass,
                    if (car.driveTrain.isNotEmpty && car.driveTrain != '---')
                      car.driveTrain,
                    if (car.aspiration.isNotEmpty && car.aspiration != '---')
                      car.aspiration,
                    if (car.power.isNotEmpty) car.power,
                    if (car.weight.isNotEmpty) car.weight,
                  ].join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gt7Caption(
                    color: gt7TextMuted.withValues(alpha: 0.7),
                    size: 7,
                  ),
                ),
                if (car.performancePoints.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'PP ${car.performancePoints}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: gt7Caption(color: gt7SlotB, size: 7),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The car's picture: the official 320x180 thumbnail, falling back to the 4K
/// photo and then to a placeholder, so a missing asset never breaks the plate.
class _CarPhoto extends StatelessWidget {
  const _CarPhoto({required this.catalog, required this.carId});

  final CarCatalog catalog;
  final int carId;

  static const double _width = 130;
  static const double _height = 73;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Image.network(
        catalog.thumbnailUrl(carId),
        width: _width,
        height: _height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) {
          final fallback = catalog.photoUrl(carId);
          if (fallback == null) return const _NoCarPhoto();
          return Image.network(
            fallback,
            width: _width,
            height: _height,
            fit: BoxFit.cover,
            // The full photos are 3840x2160; decode them small.
            cacheWidth: 260,
            errorBuilder: (context, error, stack) => const _NoCarPhoto(),
          );
        },
      ),
    );
  }
}

class _NoCarPhoto extends StatelessWidget {
  const _NoCarPhoto();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _CarPhoto._width,
      height: _CarPhoto._height,
      alignment: Alignment.center,
      color: Colors.white.withValues(alpha: 0.05),
      child: Text('NO PHOTO', style: gt7Caption(size: 7)),
    );
  }
}
