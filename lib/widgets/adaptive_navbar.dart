import 'package:gt7_companion/l10n/ui_messages.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'window_navigation_safe_area.dart';
import '../models/sfx.dart';
import '../router/app_router.dart';
import '../services/sound_service.dart';
import '../services/music_service.dart';

/// Adaptive navigation bar used across the app.
/// - Desktop / Web: renders a top navigation bar.
/// - Mobile (iOS/Android): renders a bottom navigation bar with a centered circular button.
class AdaptiveNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AdaptiveNavBar({super.key});

  static const double _kMobileBarHeight = 80.0;
  static const double _kDesktopBarHeight = 72.0;
  // Matches macos_ui toolbar height (keeps navbar visually aligned with Macos
  // toolbar). If macos_ui exposes a public constant in future, prefer that.
  static const double _kMacosToolbarHeight =
      56.0; // TODO: replace with macos_ui constant

  bool get _isMobile {
    if (kIsWeb) return false;
    final p = defaultTargetPlatform;
    return p == TargetPlatform.iOS || p == TargetPlatform.android;
  }

  double _effectiveHeightForPlatform() {
    if (kIsWeb) return _kDesktopBarHeight;
    final p = defaultTargetPlatform;
    if (p == TargetPlatform.macOS) return _kMacosToolbarHeight;
    if (p == TargetPlatform.iOS || p == TargetPlatform.android) {
      return _kMobileBarHeight;
    }
    return _kDesktopBarHeight;
  }

  void _goHome(BuildContext context) {
    // Prefer tab switching when we're inside a TabsRouter; fallback to push/pop.
    TabsRouter? tabs;
    try {
      tabs = AutoTabsRouter.of(context);
    } catch (_) {
      tabs = null;
    }
    if (tabs != null) {
      // Tab transitions are sounded centrally by SoundNavigatorObserver.
      tabs.setActiveIndex(0);
      return;
    }

    final router = context.router;
    bool foundHome = false;
    context.sfx(Sfx.back);
    router.popUntil((r) {
      if (r.settings.name == '/home') foundHome = true;
      return r.isFirst || foundHome;
    });
    if (!foundHome) router.push(const HomePageRoute());
  }

  void _openPlaceholder(BuildContext context, String title) {
    TabsRouter? tabs;
    try {
      tabs = AutoTabsRouter.of(context);
    } catch (_) {
      tabs = null;
    }

    // Map placeholder buttons to tab indexes when possible.
    if (tabs != null) {
      if (title == 'Wishlist') {
        tabs.setActiveIndex(1);
        return;
      }
      if (title == 'Profile') {
        tabs.setActiveIndex(2);
        return;
      }
      // fallback -> open home
      tabs.setActiveIndex(0);
      return;
    }

    // If no TabsRouter present, preserve previous push behavior (legacy).
    final router = context.router;
    if (title == 'Screen A') {
      router.push(const ScreenARoute());
    } else if (title == 'Screen B') {
      router.push(const ScreenBRoute());
    } else {
      router.push(const ScreenARoute());
    }
  }

  Future<void> _openGtMenu(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final theme = Theme.of(context);
    final choice = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .22),
      builder: (dialogContext) => Align(
        alignment: Alignment.topLeft,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            width: 330,
            child: Material(
              color: theme.colorScheme.surface.withValues(alpha: .95),
              elevation: 18,
              shadowColor: Colors.black.withValues(alpha: .35),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WindowNavigationSafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.tr('GT Menu'),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                          IconButton(
                            key: const ValueKey('gt-menu-close'),
                            tooltip: context.tr('Close'),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.menu, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.onSurface.withValues(alpha: .08),
                  ),
                  InkWell(
                    key: const ValueKey('gt-menu-settings'),
                    onTap: () => Navigator.of(dialogContext).pop('settings'),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: const Icon(Icons.settings, size: 24),
                      title: Text(
                        context.l10n.settings,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.onSurface.withValues(alpha: .08),
                  ),
                  InkWell(
                    key: const ValueKey('gt-menu-apex'),
                    onTap: () => Navigator.of(dialogContext).pop('apex'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.newspaper_outlined, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Beyond the Apex',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.onSurface.withValues(alpha: .08),
                  ),
                  InkWell(
                    key: const ValueKey('gt-menu-home'),
                    onTap: () => Navigator.of(dialogContext).pop('home'),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: const Icon(Icons.location_on_outlined, size: 24),
                      title: Text(
                        context.l10n.home,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (choice == 'home') _goHome(context);
    if (choice == 'apex') {
      final tabs = AutoTabsRouter.of(context);
      final previousTab = tabs.activeIndex;
      final home = tabs.stackRouterOfIndex(0)!;
      tabs.setActiveIndex(0);
      if (home.current.name == ApexDisplayRoute.name) return;
      await home.push(const ApexDisplayRoute());
      if (context.mounted && tabs.activeIndex == 0) {
        tabs.setActiveIndex(previousTab);
      }
    }
    if (choice == 'settings') {
      context.router.root.push(const SettingsDisplayRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isMobile) {
      // Bottom navigation with centered circular button. When inside a
      // TabsRouter, reflect and control the active index.
      TabsRouter? tabs;
      try {
        tabs = AutoTabsRouter.of(context);
      } catch (_) {
        tabs = null;
      }
      final active = tabs?.activeIndex ?? -1;

      return SafeArea(
        top: false,
        // Add a small extra bottom inset so the bar sits a couple pixels lower,
        // while still avoiding the system navigation bar.
        minimum: const EdgeInsets.only(bottom: 4),
        child: SizedBox(
          height: _kMobileBarHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // background bar
              Positioned.fill(
                bottom: 12,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // left button -> Wishlist tab (index 1)
                        IconButton(
                          onPressed: () =>
                              _openPlaceholder(context, 'Wishlist'),
                          icon: Icon(
                            Icons.flag,
                            color: active == 1
                                ? Colors.pinkAccent
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(width: 56), // spacer for central button
                        // right button -> Profile tab (index 2)
                        IconButton(
                          onPressed: () => _openPlaceholder(context, 'Profile'),
                          icon: Icon(
                            Icons.person_outline,
                            color: active == 2
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.9),
                          ),
                        ),
                        const _AudioMenu(),
                      ],
                    ),
                  ),
                ),
              ),

              // central circular button (overlaps bar)
              Positioned(
                // Reduce overlap with content above the bar.
                // Keep the button inside the nav bar bounds so it doesn't cover page content.
                bottom: 8,
                child: InkWell(
                  key: const ValueKey('gt-menu-button'),
                  onTap: () => _openGtMenu(context),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.all(3.2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomRight,
                        colors: [Colors.white70, Colors.grey],
                      ),
                      // color: active == 0
                      //     ? primary.withValues(alpha: 0.12)
                      //     : primary.withValues(alpha: 0.04),
                    ),
                    child: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [Colors.black38, Colors.black],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: SvgPicture.asset(
                        'assets/images/gran_turismo_logotype.svg',
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.6),
                          BlendMode.srcIn,
                        ),
                        // colorFilter: ColorFilter.mode(
                        //   active == 0 ? primary : Theme.of(context).iconTheme.color!,
                        //   BlendMode.srcIn,
                        // ),
                        height: 58,
                        width: 58,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Desktop / Web — top navigation bar
    TabsRouter? tabs;
    try {
      tabs = AutoTabsRouter.of(context);
    } catch (_) {
      tabs = null;
    }
    final active = tabs?.activeIndex ?? -1;

    final homeButton = InkWell(
      key: const ValueKey('gt-menu-button'),
      onTap: () => _openGtMenu(context),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.all(3.2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: [Colors.white70, Colors.grey],
          ),
          // color: active == 0
          //     ? primary.withValues(alpha: 0.12)
          //     : primary.withValues(alpha: 0.04),
        ),
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [Colors.black38, Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: SvgPicture.asset(
            'assets/images/gran_turismo_logotype.svg',
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.6),
              BlendMode.srcIn,
            ),
            // colorFilter: ColorFilter.mode(
            //   active == 0 ? primary : Theme.of(context).iconTheme.color!,
            //   BlendMode.srcIn,
            // ),
            height: 36,
            width: 36,
          ),
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: WindowNavigationSafeArea(
        child: Container(
          height: _effectiveHeightForPlatform(),
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.04),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.04),
              ),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 740 ||
                  MediaQuery.textScalerOf(context).scale(14) > 17;
              if (compact) {
                return Row(
                  children: [
                    homeButton,
                    if (constraints.maxWidth >= 260) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.tr(
                            constraints.maxWidth < 500
                                ? 'GT7 Companion'
                                : 'Gran Turismo 7 Companion',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    IconButton(
                      tooltip: context.tr('Wishlist'),
                      onPressed: () => _openPlaceholder(context, 'Wishlist'),
                      icon: Icon(
                        Icons.flag_outlined,
                        color: active == 1
                            ? Colors.pinkAccent
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr('Profile'),
                      onPressed: () => _openPlaceholder(context, 'Profile'),
                      icon: Icon(
                        Icons.person_outline,
                        color: active == 2
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const _AudioMenu(),
                  ],
                );
              }
              return Row(
                children: [
                  homeButton,

                  const SizedBox(width: 6),

                  VerticalDivider(indent: 12, endIndent: 12, thickness: 0.4),

                  const SizedBox(width: 6),
                  // app title / spacer
                  Expanded(
                    child: Text(
                      context.tr('Gran Turismo 7 Companion'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),

                  VerticalDivider(indent: 12, endIndent: 12, thickness: 0.4),

                  const SizedBox(width: 6),

                  // two action buttons on the right (map to tabs when available)
                  TextButton.icon(
                    onPressed: () => _openPlaceholder(context, 'Wishlist'),
                    icon: Icon(
                      Icons.flag_outlined,
                      color: active == 1
                          ? Colors.pinkAccent
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.9),
                    ),
                    label: Text(context.tr('Wishlist')),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),

                  VerticalDivider(indent: 12, endIndent: 12, thickness: 0.4),

                  const SizedBox(width: 6),

                  TextButton.icon(
                    onPressed: () => _openPlaceholder(context, 'Profile'),
                    icon: Icon(
                      Icons.person_outline,
                      color: active == 2
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.9),
                    ),
                    label: Text(context.tr('Profile')),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(width: 6),

                  VerticalDivider(indent: 12, endIndent: 12, thickness: 0.4),

                  const SizedBox(width: 6),

                  // Live clock: HH:mm on top, "D Mon" (Russian short month) below
                  StreamBuilder<DateTime>(
                    stream: Stream<DateTime>.periodic(
                      const Duration(minutes: 1),
                      (_) => DateTime.now(),
                    ),
                    initialData: DateTime.now(),
                    builder: (context, snapshot) {
                      final now = snapshot.data ?? DateTime.now();
                      final locale = Localizations.localeOf(context).toString();
                      final time = DateFormat.Hm(locale).format(now);
                      final date = DateFormat('d MMM', locale).format(now);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            context.tr(time),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            context.tr(date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      );
                    },
                  ),
                  // end StreamBuilder

                  const SizedBox(width: 6),
                  const _AudioMenu(),
                ],
              );
            },
          ), // LayoutBuilder
        ), // Container
      ),
    );
  }

  @override
  Size get preferredSize {
    if (kIsWeb) return const Size.fromHeight(_kDesktopBarHeight);
    final p = defaultTargetPlatform;
    if (p == TargetPlatform.macOS) {
      return const Size.fromHeight(_kMacosToolbarHeight);
    }
    if (p == TargetPlatform.iOS || p == TargetPlatform.android) {
      return const Size.fromHeight(_kMobileBarHeight);
    }
    return const Size.fromHeight(_kDesktopBarHeight);
  }
}

/// One control for both audio channels, in the header where a global setting belongs.
///
/// It reads both services, so each switch shows the stored state, and the icon
/// answers the only question worth a glance: is this app about to make a sound?
class _AudioMenu extends StatelessWidget {
  const _AudioMenu();

  @override
  Widget build(BuildContext context) {
    final sound = context.watch<SoundService>();
    final music = context.watch<MusicService>();
    final anyChannelOn = sound.enabled || music.enabled;

    return PopupMenuButton<String>(
      tooltip: context.tr('Sound'),
      icon: Icon(anyChannelOn ? Icons.volume_up : Icons.volume_off),
      onSelected: (channel) {
        if (channel == 'credits') {
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(context.tr('Music credits')),
              content: SingleChildScrollView(
                child: SelectableText(context.tr(MusicService.credits)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.tr('Close')),
                ),
              ],
            ),
          );
          return;
        }
        if (channel == 'sound') {
          final turnOn = !sound.enabled;
          sound.setEnabled(turnOn);
          if (turnOn) context.sfx(Sfx.toggle);
        } else {
          final turnOn = !music.enabled;
          music.setEnabled(turnOn);
          if (turnOn) context.sfx(Sfx.toggle);
        }
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: 'sound',
          checked: sound.enabled,
          child: Text(context.tr('Interface sounds')),
        ),
        CheckedPopupMenuItem(
          value: 'music',
          checked: music.enabled,
          child: Text(context.tr('Ambient music')),
        ),
        PopupMenuItem(
          value: 'credits',
          child: Text(context.tr('Music credits')),
        ),
      ],
    );
  }
}
