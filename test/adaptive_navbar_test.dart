import 'package:gt7_companion/l10n/ui_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gt7_companion/services/music_service.dart';
import 'package:gt7_companion/services/sound_service.dart';
import 'package:gt7_companion/theme/gt7_theme.dart';
import 'package:gt7_companion/widgets/adaptive_navbar.dart';

void main() {
  for (final locale in ['en', 'ru']) {
    for (final width in [320.0, 390.0, 600.0, 820.0, 1024.0, 1280.0, 1920.0]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets(
          'desktop header $locale fits $width / $scale with all actions',
          (tester) async {
            tester.view.physicalSize = Size(width, 700);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            // Playback stays idle: no load/play call, so no audio platform channel.
            final sound = SoundService(enabled: false);
            final music = MusicService(enabled: false);
            addTearDown(sound.dispose);
            addTearDown(music.dispose);
            await tester.pumpWidget(
              MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(value: sound),
                  ChangeNotifierProvider.value(value: music),
                ],
                child: MaterialApp(
                  locale: Locale(locale),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  theme: gt7Theme(),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: const Scaffold(
                    appBar: AdaptiveNavBar(),
                    body: SizedBox(),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final compact = width - 110 < 740 || scale > 1.2;
            if (compact) {
              expect(
                find.byTooltip(locale == 'ru' ? 'Избранное' : 'Wishlist'),
                findsOneWidget,
              );
              expect(
                find.byTooltip(locale == 'ru' ? 'Профиль' : 'Profile'),
                findsOneWidget,
              );
              for (final label in [
                if (locale == 'ru') ...[
                  'Избранное',
                  'Профиль',
                  'Звук',
                ] else ...[
                  'Wishlist',
                  'Profile',
                  'Sound',
                ],
              ]) {
                final bounds = tester.getRect(find.byTooltip(label));
                expect(bounds.left, greaterThanOrEqualTo(0));
                expect(bounds.right, lessThanOrEqualTo(width));
              }
            } else {
              expect(
                find.text(locale == 'ru' ? 'Избранное' : 'Wishlist'),
                findsOneWidget,
              );
              expect(
                find.text(locale == 'ru' ? 'Профиль' : 'Profile'),
                findsOneWidget,
              );
              expect(find.text('Gran Turismo 7 Companion'), findsOneWidget);
            }
            expect(
              find.byTooltip(locale == 'ru' ? 'Звук' : 'Sound'),
              findsOneWidget,
            );
            await tester.pumpWidget(const SizedBox());
          },
          variant: TargetPlatformVariant({TargetPlatform.macOS}),
        );
      }
    }
  }
}
