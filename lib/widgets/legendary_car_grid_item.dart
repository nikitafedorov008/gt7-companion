// legendary_car_grid_item.dart

import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter_avif/flutter_avif.dart';
import '../models/unified_car_data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LegendaryCarCardItem extends StatelessWidget {
  final UnifiedCarData car;

  const LegendaryCarCardItem({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    String carImageUrl = _getCarImageUrl();

    return GestureDetector(
      onTap: () => _launchPriceHistory(car.id),
      child: Container(
        margin: const EdgeInsets.all(8.0),
        // decoration: BoxDecoration(
        //   borderRadius: BorderRadius.circular(2.0),
        //   border: Border.all(color: Colors.grey[300]!, width: 1),
        // ),
        decoration: CustomDecoration(frameSFactor: .06, gap: 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topCenter.add(AlignmentDirectional(0.6, 0)),
              child: SvgPicture.asset(
                'assets/images/legend_hagerty_icon.svg',
                height: 32,
                width: 32,
              ),
            ),

            // Manufacturer logotype
            Padding(
              padding: const EdgeInsets.only(top: 18.0),
              child: FractionallySizedBox(
                widthFactor: 0.30,
                child: Image.network(
                  'https://vl.imgix.net/img/${car.manufacturer.toLowerCase().replaceAll(' ', '-')}-logo.png',
                ),
              ),
            ),

            // Manufacturer
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
                        const SizedBox(width: 6),
                        Align(
                          child: Text(
                            car.manufacturer,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Car Name
                        Text(
                          car.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            Divider(
              height: 30.0,
              thickness: 0.4,
              color: Colors.lightBlue,
              indent: 24.0,
              endIndent: 24.0,
              radius: BorderRadius.circular(24),
            ),

            // Car Image (Top)
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

            Divider(
              height: 30.0,
              thickness: 0.4,
              color: Colors.lightBlue,
              indent: 24.0,
              endIndent: 24.0,
              radius: BorderRadius.circular(24),
            ),

            // Info Section (Bottom)
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
                        // Price
                        Text(
                          car.displayPrice,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),

                        // Miles
                        Text(
                          '${_formatMiles(car.estimateDays)} miles',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Status: SOLD OUT / LIMITED STOCK
            if (car.isSoldOut)
              _buildStatusBadge('SOLD OUT', Colors.red[100]!, Colors.red[800]!)
            else if (car.isLimitedStock)
              _buildStatusBadge(
                'LIMITED STOCK',
                Colors.orange[100]!,
                Colors.orange[800]!,
              ),

            const SizedBox(height: 8),
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

  Widget _buildImageWidget(
    String imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    Widget placeholder = Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.car_repair, size: 16, color: Colors.grey),
    );

    // Standard fallback image in case of errors
    Widget fallbackImage = Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 24,
        color: Colors.grey,
      ),
    );

    if (imageUrl.contains('imagedelivery.net')) {
      // Для изображений из GTDB показываем стандартное изображение как placeholder,
      // а затем заменяем на изображение из GTDB если оно загрузится
      String gt7StandardUrl =
          'https://www.gran-turismo.com/common/dist/gt7/carlist/car_thumbnails/car${car.id}.png';

      // Сначала загружаем стандартное изображение
      return ExtendedImage.network(
        gt7StandardUrl, // Сначала показываем стандартное изображение
        // width: width,
        // height: height,
        fit: fit,
        cache: true,
        loadStateChanged: (ExtendedImageState standardState) {
          // Загружаем изображение из GTDB поверх стандартного
          Widget gtdbImage = AvifImage.network(
            imageUrl, // Это изображение из GTDB
            // width: width,
            // height: height,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) =>
                loadingProgress == null
                ? child
                : Container(), // Не показываем placeholder для GTDB
            errorBuilder: (context, error, stackTrace) =>
                Container(), // Не показываем ошибку GTDB
          );

          if (standardState.extendedImageLoadState == LoadState.loading) {
            // Если стандартное изображение еще грузится, показываем placeholder
            return Stack(
              alignment: Alignment.center,
              children: [
                placeholder, // placeholder пока грузится стандартное изображение
                gtdbImage, // попутно грузим изображение из GTDB
              ],
            );
          } else if (standardState.extendedImageLoadState ==
              LoadState.completed) {
            // Если стандартное изображение загрузилось, показываем его с возможностью замены на GTDB
            return Stack(
              alignment: Alignment.center,
              children: [
                standardState.completedWidget, // стандартное изображение
                gtdbImage, // поверх него изображение из GTDB, если оно загрузится
              ],
            );
          } else {
            // В случае ошибки стандартного изображения показываем fallback
            return Stack(
              alignment: Alignment.center,
              children: [
                fallbackImage, // fallback при ошибке
                gtdbImage, // попутно пробуем загрузить изображение из GTDB
              ],
            );
          }
        },
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
            return state.extendedImageLoadState == LoadState.loading
                ? placeholder
                : fallbackImage;
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

class CustomDecoration extends Decoration {
  final Color? backgroundColor;
  final double frameSFactor;
  //defalut padding _Need to check
  final double gap;

  const CustomDecoration({
    this.backgroundColor = Colors.transparent,
    required this.frameSFactor,
    required this.gap,
  });
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return CustomDecorationPainter(
      backgroundColor: backgroundColor!,
      frameSFactor: frameSFactor,
      padding: gap,
    );
  }
}

class CustomDecorationPainter extends BoxPainter {
  final Color backgroundColor;
  final double frameSFactor;
  final double padding;

  CustomDecorationPainter({
    this.backgroundColor = Colors.transparent,
    this.frameSFactor = .06,
    required this.padding,
  });

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    print(configuration.size!.height);

    final Rect bounds = offset & configuration.size!;
    final frameHWidth = configuration.size!.width * frameSFactor;

    Paint paint = Paint()
      ..color = backgroundColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;

    /// background
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, Radius.circular(0.8)),
      paint..color,
    );

    paint.color = Colors.grey;

    /// top left
    canvas.drawLine(
      bounds.topLeft + Offset(padding, padding),
      Offset(bounds.topLeft.dx + frameHWidth, bounds.topLeft.dy) +
          Offset(padding, padding),
      paint,
    );
    canvas.drawLine(
      bounds.topLeft + Offset(padding, padding),
      Offset(bounds.topLeft.dx, bounds.topLeft.dy + frameHWidth) +
          Offset(padding, padding),
      paint,
    );

    //top Right
    canvas.drawLine(
      Offset(bounds.topRight.dx - padding, bounds.topRight.dy + padding),
      Offset(
        bounds.topRight.dx - padding - frameHWidth,
        bounds.topRight.dy + padding,
      ),
      paint,
    );
    canvas.drawLine(
      Offset(bounds.topRight.dx - padding, bounds.topRight.dy + padding),
      Offset(
        bounds.topRight.dx - padding,
        bounds.topRight.dy + padding + frameHWidth,
      ),
      paint..color,
    );

    //bottom Right
    canvas.drawLine(
      Offset(bounds.bottomRight.dx - padding, bounds.bottomRight.dy - padding),
      Offset(
        bounds.bottomRight.dx - padding,
        bounds.bottomRight.dy - padding - frameHWidth,
      ),
      paint,
    );
    canvas.drawLine(
      Offset(bounds.bottomRight.dx - padding, bounds.bottomRight.dy - padding),
      Offset(
        bounds.bottomRight.dx - padding - frameHWidth,
        bounds.bottomRight.dy - padding,
      ),
      paint,
    );
    //bottom Left
    canvas.drawLine(
      Offset(bounds.bottomLeft.dx + padding, bounds.bottomLeft.dy - padding),
      Offset(
        bounds.bottomLeft.dx + padding,
        bounds.bottomLeft.dy - padding - frameHWidth,
      ),
      paint,
    );
    canvas.drawLine(
      Offset(bounds.bottomLeft.dx + padding, bounds.bottomLeft.dy - padding),
      Offset(
        bounds.bottomLeft.dx + padding + frameHWidth,
        bounds.bottomLeft.dy - padding,
      ),
      paint,
    );
  }
}
