import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/gt7info_data.dart';
import 'package:url_launcher/url_launcher.dart';

class CarGridItem extends StatelessWidget {
  final CarData car;

  const CarGridItem({
    super.key,
    required this.car,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => _launchPriceHistory(car.carId),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Flag and manufacturer
              Row(
                children: [
                  CachedNetworkImage(
                    imageUrl: car.flagUrl,
                    width: 20,
                    height: 14,
                    errorWidget: (context, url, error) => const Icon(Icons.flag, size: 20),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      car.manufacturer.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Car name
              Expanded(
                child: Text(
                  car.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Price
              Text(
                'Cr. ${_formatCredits(car.credits)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: car.isSoldOut ? Colors.red : Colors.green[700],
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Status
              if (car.isSoldOut || car.isLimitedStock)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: car.isSoldOut ? Colors.red[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: car.isSoldOut ? Colors.red[300]! : Colors.orange[300]!,
                    ),
                  ),
                  child: Text(
                    car.isSoldOut ? 'SOLD OUT' : 'LIMITED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: car.isSoldOut ? Colors.red[700] : Colors.orange[800],
                    ),
                  ),
                ),
              
              // NEW indicator
              if (car.isNew)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCredits(int credits) {
    final formatted = credits.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},'
    );
    return formatted;
  }

  Future<void> _launchPriceHistory(String carId) async {
    final url = 'https://ddm999.github.io/gt7info/cars/prices_$carId.png';

    try {
      if (!await launchUrl(Uri.parse(url))) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}