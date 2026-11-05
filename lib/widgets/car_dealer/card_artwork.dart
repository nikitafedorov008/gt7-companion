import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:provider/provider.dart';
import '../../services/card_artwork_service.dart';

/// Immediate bundled primary → bundled thumbnail → cached future artwork.
/// This widget never requests the network for a known bundled image.
class CardArtwork extends StatelessWidget {
  const CardArtwork({
    super.key,
    required this.url,
    this.fallbackUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.cacheWidth,
    this.thumbnailBackground,
    this.thumbnailOverlay,
    this.imageBuilder,
  });
  final String url;
  final String? fallbackUrl;
  final double? width, height;
  final BoxFit fit;
  final int? cacheWidth;

  /// Applied only to transparent official car thumbnails, including fallbacks.
  final Decoration? thumbnailBackground;
  final Widget? thumbnailOverlay;

  /// Receives the selected image, so overlays follow runtime fallback changes.
  final Widget Function(BuildContext, Widget, bool isThumbnail)? imageBuilder;

  @override
  Widget build(BuildContext context) {
    // The default supports isolated previews/tests; AppScope injects the same
    // immutable lookup in the full application.
    final source =
        context.read<CardArtworkService?>() ?? const CardArtworkService();
    Widget missing() => SizedBox(
      width: width,
      height: height,
      child: const Center(child: Icon(Icons.directions_car_outlined)),
    );
    Widget decorate(Widget child, String imageUrl) {
      final isThumbnail = Uri.parse(
        imageUrl,
      ).path.contains('/carlist/car_thumbnails/');
      if (thumbnailBackground == null || !isThumbnail) {
        return imageBuilder?.call(context, child, isThumbnail) ?? child;
      }
      final decorated = DecoratedBox(
        decoration: thumbnailBackground!,
        child: thumbnailOverlay == null
            ? child
            : Stack(
                fit: StackFit.passthrough,
                children: [
                  child,
                  Positioned.fill(
                    child: IgnorePointer(child: thumbnailOverlay!),
                  ),
                ],
              ),
      );
      return imageBuilder?.call(context, decorated, isThumbnail) ?? decorated;
    }

    Widget fallback() {
      final asset = fallbackUrl == null ? null : source.assetFor(fallbackUrl!);
      if (asset == null) return missing();
      return decorate(
        Image.asset(
          asset,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: cacheWidth,
          errorBuilder: (_, _, _) => missing(),
        ),
        fallbackUrl!,
      );
    }

    final asset = source.assetFor(url);
    if (asset != null) {
      if (asset.endsWith('.avif')) {
        return AvifImage.asset(
          asset,
          width: width,
          height: height,
          fit: fit,
          frameBuilder: (_, child, frame, loaded) =>
              frame == null ? fallback() : decorate(child, url),
          errorBuilder: (_, _, _) => fallback(),
        );
      }
      return Image.asset(
        asset,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        frameBuilder: (_, child, frame, loaded) => decorate(child, url),
        errorBuilder: (_, _, _) => fallback(),
      );
    }
    if (url.isEmpty) return fallback();
    if (url.contains('imagedelivery.net')) {
      return CachedNetworkAvifImage(
        url,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        frameBuilder: (_, child, frame, loaded) =>
            frame == null ? fallback() : decorate(child, url),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : fallback(),
        errorBuilder: (_, _, _) => fallback(),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      imageBuilder: (_, provider) => decorate(
        Image(image: provider, width: width, height: height, fit: fit),
        url,
      ),
      placeholder: (_, _) => fallback(),
      errorWidget: (_, _, _) => fallback(),
    );
  }
}
