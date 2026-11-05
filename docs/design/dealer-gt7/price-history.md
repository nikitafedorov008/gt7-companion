# In-app price history — 2026-11-05

Bounded direct follow-up requested by the user: replace the external-image price action with a viewer in the application. No source/pricing changes and no gallery scrape.

GT7Info publishes a PNG at https://ddm999.github.io/gt7info/cars/prices_1523.png (live verified HTTP 200, image/png, 1600x600). DealerCarDetails now owns canonical chart URI construction. Both dealership detail surfaces open the shared image viewer, with GT loader, zoom/pan (1–8x), fit/reset, explicit refresh, localized retry/error and close/Escape returning to the same vehicle.

The chart is mounted on the root modal navigator, above the swipeable app tabs. Native iPhone inspection caught a conflict where a horizontal pan moved to Wishlist; the root-modal change fixes it. A permanent regression exercises a nested Navigator inside PageView and verifies the chart moves while page remains 0. This does not replace the car screen or open another app/browser.

76 tests passed (/tmp/price-final-tests.log); analyzer clean (/tmp/price-analyze.log); GRACE 0 errors/56 warnings (/tmp/price-grace.log). Actual source chart is retained as a test-only fixture, not a production bundled history snapshot. Tests cover real vehicle button, loading success, invalid image/retry, zoom/reset/Escape, nested-tab pan isolation, RU/EN, 390/820/1280 and enlarged text.

Native iPhone was visibly mirrored in IAB during checks. Real PNG loaded, zoom/pan/reset/return verified after the gesture fix. Simulator app and scoped mirror helper stopped. Ordinary Mac lib/main.dart checked through CUA and left open on the loaded FIAT price chart. No persistent preference changes, commit or push.
