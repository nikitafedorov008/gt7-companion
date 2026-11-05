import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../l10n/ui_messages.dart';

/// Shared GT-style loading mark. A dark plate keeps the white mark legible
/// inside light feature themes; compact controls can request a smaller size.
class GtLoadingIndicator extends StatelessWidget {
  const GtLoadingIndicator({
    super.key,
    this.size = 56,
    this.withBackdrop = false,
  });

  final double size;

  /// Legacy light canvases can inherit the dark app theme.
  final bool withBackdrop;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).colorScheme.brightness == Brightness.light;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: context.tr('Loading'),
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: light || withBackdrop
                  ? const Color(0xFF17191C)
                  : Colors.transparent,
            ),
            child: Padding(
              padding: EdgeInsets.all(size * .06),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: reducedMotion ? .75 : null,
                      strokeWidth: size >= 40 ? 1.5 : 1,
                      strokeCap: StrokeCap.round,
                      color: Colors.white,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/images/gran_turismo_logotype.svg',
                    width: size * .78,
                    height: size * .78,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
