import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Three independent layers: architectural plate, flat world map and live UI.
/// Portrait uses a separately composed plate rather than cropping the lobby.
class BrandCentralBackground extends StatefulWidget {
  const BrandCentralBackground({
    super.key,
    required this.child,
    this.showMap = true,
    this.region = 'All regions',
    this.mapOpacity = .42,
  });
  final Widget child;
  final bool showMap;
  final String region;
  final double mapOpacity;
  @override
  State<BrandCentralBackground> createState() => _BrandCentralBackgroundState();
}

class _BrandCentralBackgroundState extends State<BrandCentralBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _camera = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 36),
  );
  bool _reducedMotion = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _updateMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _updateMotion();
  void _updateMotion() {
    final state = WidgetsBinding.instance.lifecycleState;
    if (_reducedMotion ||
        (state != null && state != AppLifecycleState.resumed)) {
      _camera.stop();
    } else if (!_camera.isAnimating) {
      _camera.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final portrait =
            MediaQuery.orientationOf(context) == Orientation.portrait;
        final image = portrait ? 'portrait' : 'landscape';
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: ClipRect(
                      child: AnimatedBuilder(
                        animation: _camera,
                        child: ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: 2.8,
                            sigmaY: 2.8,
                          ),
                          child: Image.asset(
                            'assets/images/brand_central/atrium_$image.png',
                            key: ValueKey('brand-atrium-$image'),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                        builder: (context, child) {
                          final phase = _camera.value * math.pi * 2;
                          return Transform.translate(
                            offset: Offset(
                              math.sin(phase) * constraints.maxWidth * .006,
                              0,
                            ),
                            child: Transform.scale(
                              scale: 1.025 + math.sin(phase) * .008,
                              child: child,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.surface.withValues(
                          alpha: widget.showMap
                              ? (widget.mapOpacity < .3 ? .48 : .28)
                              : .76,
                        ),
                        colors.surface.withValues(
                          alpha: widget.showMap
                              ? (widget.mapOpacity < .3 ? .58 : .32)
                              : .82,
                        ),
                        colors.surface.withValues(alpha: .80),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showMap)
              Positioned.fill(
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: RepaintBoundary(
                      child: Align(
                        alignment: portrait
                            ? const Alignment(0, -.68)
                            : const Alignment(0, -.2),
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height:
                              constraints.maxHeight * (portrait ? .46 : .95),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              SvgPicture.asset(
                                'assets/images/brand_central/map_world.svg',
                                fit: BoxFit.contain,
                                colorFilter: ColorFilter.mode(
                                  colors.onSurface.withValues(
                                    alpha: widget.mapOpacity,
                                  ),
                                  BlendMode.srcIn,
                                ),
                              ),
                              if (widget.region != 'All regions' &&
                                  widget.region != 'Other')
                                SvgPicture.asset(
                                  'assets/images/brand_central/map_${switch (widget.region) {
                                    'North America' => 'america',
                                    'Europe' => 'europe',
                                    _ => 'asia_pacific',
                                  }}.svg',
                                  fit: BoxFit.contain,
                                  colorFilter: ColorFilter.mode(
                                    colors.onSurface.withValues(
                                      alpha: widget.mapOpacity * 1.3,
                                    ),
                                    BlendMode.srcIn,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            widget.child,
          ],
        );
      },
    );
  }
}
