import '../models/car_dealer/card_image_assets.dart';

/// Pure lookup of verified, bundled card images. Runtime downloads belong to
/// CachedNetworkImage so unknown future URLs retain its bounded disk cache.
class CardArtworkService {
  const CardArtworkService();
  String? assetFor(String url) => bundledCardImages[url];
  String thumbnailUrl(String id) =>
      'https://www.gran-turismo.com/common/dist/gt7/carlist/car_thumbnails/car${id.replaceFirst(RegExp(r'^(?:car)+'), '')}.png';
}
