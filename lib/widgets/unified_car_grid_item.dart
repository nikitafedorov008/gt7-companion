// unified_car_card_item.dart

import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter_avif/flutter_avif.dart';
import '../models/unified_car_data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UnifiedCarCardItem extends StatelessWidget {
  final UnifiedCarData car;

  const UnifiedCarCardItem({
    super.key,
    required this.car,
  });

  @override
  Widget build(BuildContext context) {
    String carImageUrl = _getCarImageUrl();

    return GestureDetector(
      onTap: () => _launchPriceHistory(car.id),
      child: Container(
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Car Image (Left)
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  child: _buildImageWidget(
                    carImageUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),


            // Info Section (Right)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FractionallySizedBox(
                  widthFactor: 0.9,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Manufacturer + Flag
                        Row(
                          children: [
                            if (car.region.isNotEmpty)
                              Image.network(
                                car.flagUrl,
                                width: 20,
                                height: 14,
                                fit: BoxFit.contain,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              car.manufacturer.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Car Name
                        Text(
                          car.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),

                        const SizedBox(height: 4),

                        // Status: SOLD OUT / LIMITED STOCK
                        if (car.isSoldOut)
                          _buildStatusBadge('SOLD OUT', Colors.red[100]!, Colors.red[800]!)
                        else if (car.isLimitedStock)
                          _buildStatusBadge('LIMITED STOCK', Colors.orange[100]!, Colors.orange[800]!),

                        const SizedBox(height: 8),

                        // PP + Miles
                        Row(
                          children: [
                            const Icon(Icons.speed, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatMiles(car.estimateDays)} mi',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.trending_up, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'PP ${car.sort ?? 0}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Stars
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              Icons.star,
                              size: 14,
                              color: index < 3 ? Colors.yellow : Colors.grey[300],
                            );
                          }),
                        ),

                        const SizedBox(height: 8),

                        // Price
                        Text(
                          car.displayPrice,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  String _getCarImageUrl() => car.carImageUrl;

  Widget _buildImageWidget(String imageUrl, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    Widget placeholder = Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.car_repair, size: 16, color: Colors.grey),
    );

    if (imageUrl.contains('imagedelivery.net')) {
      return AvifImage.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : placeholder,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else {
      return ExtendedImage.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        cache: true,
        loadStateChanged: (ExtendedImageState state) {
          if (state.extendedImageLoadState == LoadState.loading ||
              state.extendedImageLoadState == LoadState.failed) {
            return placeholder;
          }
          return null;
        },
      );
    }
  }

  Future<void> _launchPriceHistory(String carId) async {
    final url = 'https://ddm999.github.io/gt7info/cars/prices_$carId.png';
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  String _formatMiles(int days) {
    return (days * 1000).toString();
  }
}