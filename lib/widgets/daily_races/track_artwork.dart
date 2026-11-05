// START_MODULE_CONTRACT
// PURPOSE: Render bundled track artwork with a cached future-source fallback.
// SCOPE: Local track images only; profile images never use this widget/index.
// DEPENDS: M-MODEL-DAILY
// LINKS: M-TRACK-ARTWORK, V-M-TRACK-ARTWORK
// END_MODULE_CONTRACT
// START_MODULE_MAP
// TrackArtwork - local-first photo, logo or circuit layout.
// END_MODULE_MAP
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/daily_races/track_image_assets.dart';

class TrackArtwork extends StatelessWidget {
  const TrackArtwork({
    super.key,
    required this.url,
    this.fallbackUrl,
    this.trackId,
    this.role,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.cacheWidth = 1024,
  });
  final String url;
  final String? fallbackUrl;
  final String? trackId, role;
  final BoxFit fit;
  final double? width, height;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    Widget empty() => SizedBox(width: width, height: height);
    Widget fallback() {
      final fallback = fallbackUrl ?? bundledTrackArtworkUrls[trackId]?[role];
      final asset = bundledTrackImages[fallback];
      return asset == null
          ? empty()
          : Image.asset(
              asset,
              width: width,
              height: height,
              fit: fit,
              cacheWidth: cacheWidth,
              errorBuilder: (_, _, _) => empty(),
            );
    }

    final asset = bundledTrackImages[url];
    if (asset != null) {
      return Image.asset(
        asset,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        errorBuilder: (_, _, _) => fallback(),
      );
    }
    if (url.isEmpty) return fallback();
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      placeholder: (_, _) => fallback(),
      errorWidget: (_, _, _) => fallback(),
    );
  }
}
