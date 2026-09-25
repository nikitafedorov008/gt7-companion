import 'package:flutter/material.dart';

// GT7-inspired dark color palette (cyan highlights + warm yellow accents)
const Color _gt7Background = Color(0xFF0B0D0F);
const Color _gt7Surface = Color(0xFF141619);
const Color _gt7Primary = Color(0xFF00D1E8); // cyan/aqua
const Color _gt7PrimaryContainer = Color(0xFF07282B);
const Color _gt7Accent = Color(0xFF6BE3FF);
const Color _gt7Secondary = Color(0xFFFFC857); // warm yellow (badges)
const Color _gt7Muted = Color(0xFF9AA3AC);
const Color _gt7Error = Color(0xFFFF5C5C);

// Panel + hairline values measured off the GT7 reference screenshots:
// near-black translucent panels, 1 px light borders, no shadows, 6-10 px radii.
const Color gt7Panel = Color(0xFF16191E);
const Color gt7PanelTranslucent = Color(0xCC16191E);
const Color gt7Hairline = Color(0x24FFFFFF);
const Color gt7Plot = Color(0xFF0E1114);
const Color gt7Text = Color(0xFFE6EEF2);
const Color gt7TextMuted = _gt7Muted;

// Data-meaning colours, as used by the game itself.
const Color gt7SlotA = Color(0xFF4DC3F3); // cyan  - slot A / reference
const Color gt7SlotB = Color(0xFFE7CB3C); // yellow - slot B / active
const Color gt7Best = Color(0xFF8E4DB1); // purple - best / fastest lap
const Color gt7Warn = Color(0xFFFA0F0B); // red    - loss / brake / redline
const Color gt7Gain = Color(0xFF4DA3FF); // blue   - gain  / faster

final ColorScheme _gt7ColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: _gt7Primary,
  onPrimary: _gt7Background,
  primaryContainer: _gt7PrimaryContainer,
  onPrimaryContainer: _gt7Accent,
  secondary: _gt7Secondary,
  onSecondary: _gt7Surface,
  secondaryContainer: const Color(0xFF2A2E35),
  onSecondaryContainer: gt7Text,
  tertiary: gt7SlotA,
  onTertiary: _gt7Background,
  tertiaryContainer: const Color(0xFF23272E),
  onTertiaryContainer: gt7Text,
  error: _gt7Error,
  onError: Colors.white,
  surface: _gt7Surface,
  onSurface: gt7Text,
  surfaceContainerLowest: _gt7Background,
  surfaceContainerLow: const Color(0xFF101317),
  surfaceContainer: gt7Panel,
  surfaceContainerHigh: const Color(0xFF1B1F25),
  surfaceContainerHighest: const Color(0xFF23272E),
  onSurfaceVariant: _gt7Muted,
  outline: const Color(0xFF3A4048),
  outlineVariant: gt7Hairline,
  inverseSurface: gt7Text,
  onInverseSurface: _gt7Background,
  surfaceTint: Colors.transparent,
);

ThemeData gt7Theme() => ThemeData(
  colorScheme: _gt7ColorScheme,
  useMaterial3: true,
  scaffoldBackgroundColor: _gt7Background,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    foregroundColor: _gt7ColorScheme.onSurface,
    elevation: 0,
    centerTitle: false,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _gt7Surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.transparent),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: _gt7ColorScheme.onSurface.withOpacity(0.08),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: _gt7ColorScheme.primary.withOpacity(0.85)),
    ),
    labelStyle: TextStyle(color: _gt7ColorScheme.onSurface.withOpacity(0.7)),
    hintStyle: TextStyle(color: _gt7ColorScheme.onSurface.withOpacity(0.5)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _gt7Primary,
      foregroundColor: _gt7ColorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: _gt7ColorScheme.onSurface),
  ),
  cardColor: _gt7Surface,
  iconTheme: IconThemeData(color: _gt7ColorScheme.onSurface.withOpacity(0.9)),
  textTheme: TextTheme(
    displayLarge: TextStyle(color: _gt7ColorScheme.onSurface),
    displayMedium: TextStyle(
      color: _gt7ColorScheme.onSurface.withOpacity(0.95),
    ),
    displaySmall: TextStyle(color: _gt7ColorScheme.onSurface.withOpacity(0.9)),
    headlineSmall: TextStyle(
      color: _gt7ColorScheme.onSurface,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: TextStyle(
      color: _gt7ColorScheme.onSurface,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: TextStyle(color: _gt7ColorScheme.onSurface.withOpacity(0.9)),
    bodyLarge: TextStyle(color: _gt7ColorScheme.onSurface),
    bodyMedium: TextStyle(color: _gt7ColorScheme.onSurface.withOpacity(0.9)),
    bodySmall: TextStyle(color: _gt7ColorScheme.onSurface.withOpacity(0.75)),
  ),
  extensions: <ThemeExtension<dynamic>>[
    GT7GraphColors(
      // The game draws the throttle bar white and the brake bar white with a
      // red cap (the ABS-reduced part), so the traces follow that pairing.
      lineA: gt7Text,
      lineB: gt7Warn,
      marker: gt7SlotA,
      grid: const Color(0x14FFFFFF),
      highlight: gt7SlotA,
      track: gt7Plot,
      trackShadow: gt7Panel,
    ),
  ],
  dialogTheme: DialogThemeData(backgroundColor: _gt7Surface),
);

/// Small uppercase caption, the way the game labels everything.
TextStyle gt7Caption({
  Color color = gt7TextMuted,
  double size = 10,
  double letterSpacing = 1.3,
  FontWeight weight = FontWeight.w600,
}) {
  return TextStyle(
    color: color,
    fontSize: size,
    letterSpacing: letterSpacing,
    fontWeight: weight,
    height: 1.1,
  );
}

/// Squared, tabular numerals - the closest stand-in for the game's segmented
/// digit face without shipping a font.
TextStyle gt7Digital({
  required double size,
  Color color = gt7Text,
  FontWeight weight = FontWeight.w600,
  double letterSpacing = 1.4,
}) {
  return TextStyle(
    color: color,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: 1.0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Near-black translucent panel with a 1 px hairline - the game's only
/// container treatment. No shadows, no elevation.
BoxDecoration gt7PanelDecoration({double radius = 10, Color? borderColor}) {
  return BoxDecoration(
    color: gt7PanelTranslucent,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? gt7Hairline, width: 1),
  );
}

// ThemeExtension for telemetry/graph-specific colors
@immutable
class GT7GraphColors extends ThemeExtension<GT7GraphColors> {
  final Color? lineA;
  final Color? lineB;
  final Color? marker;
  final Color? grid;
  final Color? highlight;
  final Color? track;
  final Color? trackShadow;

  const GT7GraphColors({
    this.lineA,
    this.lineB,
    this.marker,
    this.grid,
    this.highlight,
    this.track,
    this.trackShadow,
  });

  @override
  GT7GraphColors copyWith({
    Color? lineA,
    Color? lineB,
    Color? marker,
    Color? grid,
    Color? highlight,
    Color? track,
    Color? trackShadow,
  }) {
    return GT7GraphColors(
      lineA: lineA ?? this.lineA,
      lineB: lineB ?? this.lineB,
      marker: marker ?? this.marker,
      grid: grid ?? this.grid,
      highlight: highlight ?? this.highlight,
      track: track ?? this.track,
      trackShadow: trackShadow ?? this.trackShadow,
    );
  }

  @override
  GT7GraphColors lerp(ThemeExtension<GT7GraphColors>? other, double t) {
    if (other is! GT7GraphColors) return this;
    return GT7GraphColors(
      lineA: Color.lerp(lineA, other.lineA, t),
      lineB: Color.lerp(lineB, other.lineB, t),
      marker: Color.lerp(marker, other.marker, t),
      grid: Color.lerp(grid, other.grid, t),
      highlight: Color.lerp(highlight, other.highlight, t),
      track: Color.lerp(track, other.track, t),
      trackShadow: Color.lerp(trackShadow, other.trackShadow, t),
    );
  }
}
