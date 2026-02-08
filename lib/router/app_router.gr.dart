// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [EmptyPage]
class EmptyPageRoute extends PageRouteInfo<EmptyPageRouteArgs> {
  EmptyPageRoute({
    Key? key,
    required String title,
    List<PageRouteInfo>? children,
  }) : super(
         EmptyPageRoute.name,
         args: EmptyPageRouteArgs(key: key, title: title),
         initialChildren: children,
       );

  static const String name = 'EmptyPageRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EmptyPageRouteArgs>();
      return EmptyPage(key: args.key, title: args.title);
    },
  );
}

class EmptyPageRouteArgs {
  const EmptyPageRouteArgs({this.key, required this.title});

  final Key? key;

  final String title;

  @override
  String toString() {
    return 'EmptyPageRouteArgs{key: $key, title: $title}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EmptyPageRouteArgs) return false;
    return key == other.key && title == other.title;
  }

  @override
  int get hashCode => key.hashCode ^ title.hashCode;
}

/// generated route for
/// [GTAutoDisplay]
class GTAutoDisplayRoute extends PageRouteInfo<void> {
  const GTAutoDisplayRoute({List<PageRouteInfo>? children})
    : super(GTAutoDisplayRoute.name, initialChildren: children);

  static const String name = 'GTAutoDisplayRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const GTAutoDisplay();
    },
  );
}

/// generated route for
/// [HomePage]
class HomePageRoute extends PageRouteInfo<void> {
  const HomePageRoute({List<PageRouteInfo>? children})
    : super(HomePageRoute.name, initialChildren: children);

  static const String name = 'HomePageRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomePage();
    },
  );
}

/// generated route for
/// [HomeShell]
class HomeShellRoute extends PageRouteInfo<void> {
  const HomeShellRoute({List<PageRouteInfo>? children})
    : super(HomeShellRoute.name, initialChildren: children);

  static const String name = 'HomeShellRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomeShell();
    },
  );
}

/// generated route for
/// [LegendaryCarDisplay]
class LegendaryCarDisplayRoute extends PageRouteInfo<void> {
  const LegendaryCarDisplayRoute({List<PageRouteInfo>? children})
    : super(LegendaryCarDisplayRoute.name, initialChildren: children);

  static const String name = 'LegendaryCarDisplayRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LegendaryCarDisplay();
    },
  );
}

/// generated route for
/// [NestedWidget]
class NestedWidgetRoute extends PageRouteInfo<void> {
  const NestedWidgetRoute({List<PageRouteInfo>? children})
    : super(NestedWidgetRoute.name, initialChildren: children);

  static const String name = 'NestedWidgetRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const NestedWidget();
    },
  );
}

/// generated route for
/// [ProfilePage]
class ProfilePageRoute extends PageRouteInfo<void> {
  const ProfilePageRoute({List<PageRouteInfo>? children})
    : super(ProfilePageRoute.name, initialChildren: children);

  static const String name = 'ProfilePageRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfilePage();
    },
  );
}

/// generated route for
/// [ScreenA]
class ScreenARoute extends PageRouteInfo<void> {
  const ScreenARoute({List<PageRouteInfo>? children})
    : super(ScreenARoute.name, initialChildren: children);

  static const String name = 'ScreenARoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ScreenA();
    },
  );
}

/// generated route for
/// [ScreenB]
class ScreenBRoute extends PageRouteInfo<void> {
  const ScreenBRoute({List<PageRouteInfo>? children})
    : super(ScreenBRoute.name, initialChildren: children);

  static const String name = 'ScreenBRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ScreenB();
    },
  );
}

/// generated route for
/// [TelemetryDetailsScreen]
class TelemetryDetailsScreenRoute extends PageRouteInfo<void> {
  const TelemetryDetailsScreenRoute({List<PageRouteInfo>? children})
    : super(TelemetryDetailsScreenRoute.name, initialChildren: children);

  static const String name = 'TelemetryDetailsScreenRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TelemetryDetailsScreen();
    },
  );
}

/// generated route for
/// [UsedCarDisplay]
class UsedCarDisplayRoute extends PageRouteInfo<void> {
  const UsedCarDisplayRoute({List<PageRouteInfo>? children})
    : super(UsedCarDisplayRoute.name, initialChildren: children);

  static const String name = 'UsedCarDisplayRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const UsedCarDisplay();
    },
  );
}

/// generated route for
/// [WishlistPage]
class WishlistPageRoute extends PageRouteInfo<void> {
  const WishlistPageRoute({List<PageRouteInfo>? children})
    : super(WishlistPageRoute.name, initialChildren: children);

  static const String name = 'WishlistPageRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const WishlistPage();
    },
  );
}
