import 'dart:ui' show instantiateImageCodec;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gt7_companion/models/car_dealer/car.dart';
import 'package:gt7_companion/models/car_dealer/card_image_assets.dart';
import 'package:gt7_companion/services/card_artwork_service.dart';
import 'package:gt7_companion/widgets/car_dealer/card_artwork.dart';
import 'package:gt7_companion/widgets/car_dealer/dealer_theme.dart';
import 'package:gt7_companion/widgets/car_dealer/dealer_card_parts.dart';

class MissingPrimaryBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key.contains('missing-primary')) throw StateError('broken primary');
    return rootBundle.load(key);
  }
}

class MissingPrimaryLookup extends CardArtworkService {
  const MissingPrimaryLookup();
  @override
  String? assetFor(String url) =>
      url == 'broken-primary' ? 'missing-primary.png' : super.assetFor(url);
}

Car sampleCar(String id, {String region = 'xx'}) => Car(
  id: id,
  name: 'Car',
  shortName: 'Car',
  manufacturer: 'Toyota',
  region: region,
  credits: 1,
  state: 'normal',
  estimateDays: 0,
  maxEstimateDays: 0,
  isNew: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'regional studio backdrop only decorates silhouettes and fallback',
    (tester) async {
      const source = CardArtworkService();
      final thumbnail = source.thumbnailUrl('102');
      final backdrop = dealerThumbnailBackground('fr');
      Future<void> show(String url) async {
        await tester.pumpWidget(
          Provider<CardArtworkService>.value(
            value: const MissingPrimaryLookup(),
            child: MaterialApp(
              home: DefaultAssetBundle(
                bundle: MissingPrimaryBundle(),
                child: SizedBox(
                  width: 320,
                  height: 180,
                  child: CardArtwork(
                    url: url,
                    fallbackUrl: thumbnail,
                    thumbnailBackground: backdrop,
                    thumbnailOverlay: const UsedDealerWatermark(),
                    imageBuilder: (_, image, isThumbnail) => KeyedSubtree(
                      key: ValueKey(
                        isThumbnail ? 'thumbnail-overlay' : 'photo-overlay',
                      ),
                      child: image,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
      }

      Finder backgrounds() => find.byWidgetPredicate(
        (widget) => widget is DecoratedBox && widget.decoration == backdrop,
      );
      await show(thumbnail);
      expect(backgrounds(), findsOneWidget);
      expect(find.byKey(const ValueKey('thumbnail-overlay')), findsOneWidget);
      expect(find.byType(UsedDealerWatermark), findsOneWidget);
      await show('broken-primary');
      expect(backgrounds(), findsOneWidget);
      expect(find.byKey(const ValueKey('thumbnail-overlay')), findsOneWidget);
      expect(find.byType(UsedDealerWatermark), findsOneWidget);
      final photo = bundledCardImages.entries.firstWhere(
        (entry) =>
            !entry.key.contains('/car_thumbnails/') &&
            entry.value.endsWith('.png') &&
            !entry.key.contains('flagcdn'),
      );
      await show(photo.key);
      expect(backgrounds(), findsNothing);
      expect(find.byKey(const ValueKey('photo-overlay')), findsOneWidget);
      expect(find.byType(UsedDealerWatermark), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'regional backgrounds have a darker floor and neutral unknown fallback',
    () {
      final europe =
          dealerThumbnailBackground('fr').gradient! as LinearGradient;
      final asia = dealerThumbnailBackground('jp').gradient! as LinearGradient;
      final america =
          dealerThumbnailBackground('us').gradient! as LinearGradient;
      expect(europe.colors, isNot(asia.colors));
      expect(asia.colors, isNot(america.colors));
      expect(
        europe.colors.first.computeLuminance(),
        greaterThan(europe.colors.last.computeLuminance()),
      );
      expect(dealerThumbnailBackground('FR'), dealerThumbnailBackground('fr'));
      expect(dealerThumbnailBackground('xx'), dealerThumbnailBackground(''));
    },
  );

  test(
    'regional backplates are bundled, with neutral unknown-country fallback',
    () async {
      for (final (country, region) in [
        ('fr', 'europe'),
        ('jp', 'asia'),
        ('us', 'america'),
      ]) {
        final image = dealerThumbnailBackground(country).image!;
        expect(
          (image.image as AssetImage).assetName,
          'assets/images/used-backdrop-$region-v2.webp',
        );
        final bytes = await rootBundle.load(
          (image.image as AssetImage).assetName,
        );
        final codec = await instantiateImageCodec(bytes.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        expect(
          frame.image.width / frame.image.height,
          closeTo(1187 / 768, .01),
        );
        frame.image.dispose();
        codec.dispose();
      }
      expect(dealerThumbnailBackground('xx').image, isNull);
    },
  );

  test(
    'canonical thumbnails and unknown country never produce invalid requests',
    () {
      const service = CardArtworkService();
      for (final id in ['344', 'car344', 'carcar344']) {
        expect(sampleCar(id).thumbnailUrl, endsWith('/car344.png'));
        expect(service.thumbnailUrl(id), sampleCar(id).thumbnailUrl);
      }
      expect(sampleCar('344').flagUrl, isEmpty);
      expect(sampleCar('344', region: 'jp').flagUrl, endsWith('/jp.png'));
      expect(sampleCar('344', region: 'Japan').flagUrl, isEmpty);
    },
  );

  test(
    'every official catalogue thumbnail is bundled and galleries are excluded',
    () async {
      final catalogue = await rootBundle.loadString('assets/cars/cars.json');
      // All 580 numeric IDs in the canonical catalogue are represented, without
      // assuming that Brand Central and dealers have separate copies.
      final ids = RegExp(
        r'"(car\d+)"\s*:',
      ).allMatches(catalogue).map((m) => m[1]!).toSet();
      const service = CardArtworkService();
      expect(ids.length, greaterThanOrEqualTo(580));
      for (final id in ids) {
        expect(
          service.assetFor(service.thumbnailUrl(id)),
          isNotNull,
          reason: id,
        );
      }
      expect(
        bundledCardImages.keys.any((url) => url.contains('/carlist/assets/')),
        isFalse,
      );
      expect(bundledCardImages.length, greaterThanOrEqualTo(858));
    },
  );

  for (final width in [390.0, 1280.0]) {
    testWidgets('known card and future URL fallback load locally at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const source = CardArtworkService();
      final url = source.thumbnailUrl('102');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(child: CardArtwork(url: url, height: 160)),
                // Empty/unavailable new URL must render the known local thumbnail.
                Expanded(
                  child: CardArtwork(url: '', fallbackUrl: url, height: 160),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pump();
      final images = tester.widgetList<Image>(find.byType(Image));
      expect(images.length, 2);
      expect(images.every((i) => i.image is AssetImage), isTrue);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('a corrupt bundled primary recovers to the local thumbnail', (
    tester,
  ) async {
    const source = CardArtworkService();
    final fallback = source.thumbnailUrl('102');
    await tester.pumpWidget(
      Provider<CardArtworkService>(
        create: (_) => const MissingPrimaryLookup(),
        child: DefaultAssetBundle(
          bundle: MissingPrimaryBundle(),
          child: MaterialApp(
            home: Scaffold(
              body: CardArtwork(url: 'broken-primary', fallbackUrl: fallback),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == source.assetFor(fallback),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
