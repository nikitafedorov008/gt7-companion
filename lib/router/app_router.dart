import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../widgets/gt_auto_display.dart';
import '../pages/home_page.dart';
import '../widgets/nested_widget.dart';
import '../widgets/used_car_display.dart';
import '../widgets/legendary_car_display.dart';
import '../pages/home_shell.dart';
import '../pages/profile_page.dart';
import '../pages/wishlist_page.dart';
import '../pages/empty_page.dart';
import '../widgets/telemetry_display.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => RouteType.adaptive();

  @override
  List<AutoRouteGuard> get guards => [];

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: NestedWidgetRoute.page,
      initial: true,
      children: [
        AutoRoute(
          page: HomeShellRoute.page,
          initial: true,
          path: 'home',
          children: [
            AutoRoute(page: HomePageRoute.page, initial: true, path: ''),
            AutoRoute(page: UsedCarDisplayRoute.page, path: 'used'),
            AutoRoute(page: LegendaryCarDisplayRoute.page, path: 'legendary'),
            AutoRoute(page: GTAutoDisplayRoute.page, path: 'gtauto'),
          ],
        ),
        AutoRoute(page: WishlistPageRoute.page, path: 'wishlist'),
        AutoRoute(page: ProfilePageRoute.page, path: 'profile'),
        AutoRoute(page: TelemetryDetailsScreenRoute.page, path: 'telemetry'),

        AutoRoute(page: ScreenARoute.page, path: 'a'),
        AutoRoute(page: ScreenBRoute.page, path: 'b'),
      ],
    ),
  ];
}
