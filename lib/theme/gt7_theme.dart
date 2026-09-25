import 'package:flutter/material.dart';

// GT7-inspired dark color palette
// Based on design tokens from gran-turismo.com (dark theme)
// See DESIGN.md for full token reference
const Color _gt7Background = Color(0xFF000000);      // pure black (from GT7 site)
const Color _gt7Surface = Color(0xFF141619);          // dark surface (cards, panels)
const Color _gt7Primary = Color(0xFF00D1E8);          // cyan/aqua (telemetry accent)
const Color _gt7PrimaryContainer = Color(0xFF07282B); // subtle cyan tint
const Color _gt7Accent = Color(0xFF6BE3FF);           // light cyan highlight
const Color _gt7Secondary = Color(0xFFFFC857);        // warm yellow (badges, race data)
const Color _gt7Muted = Color(0xFFA2A4AC);            // muted gray (from GT7 site)
const Color _gt7OnSurface = Color(0xFFFFFFFF);        // white text (from GT7 site)
const Color _gt7Error = Color(0xFFFF5C5C);            // error red

// Design tokens: rounded corners (from DESIGN.md)
const double gt7RadiusSm = 7.0;
const double gt7RadiusMd = 8.0;
const double gt7RadiusLg = 12.0;
const double gt7RadiusXl = 50.0;

// Design tokens: spacing (from DESIGN.md)
const double gt7SpacingXs = 5.0;
const double gt7SpacingSm = 7.0;
const double gt7SpacingMd = 8.0;
const double gt7SpacingLg = 9.0;
const double gt7SpacingXl = 10.0;
const double gt7SpacingXxl = 12.0;

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
      borderRadius: BorderRadius.circular(gt7RadiusLg),
      borderSide: BorderSide(color: Colors.transparent),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(gt7RadiusLg),
      borderSide: BorderSide(
        color: _gt7ColorScheme.onSurface.withOpacity(0.08),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(gt7RadiusLg),
      borderSide: BorderSide(color: _gt7ColorScheme.primary.withOpacity(0.85)),
    ),
    labelStyle: TextStyle(color: _gt7Muted),
    hintStyle: TextStyle(color: _gt7Muted.withOpacity(0.6)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _gt7Primary,
      foregroundColor: _gt7ColorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(gt7RadiusMd)),
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: _gt7ColorScheme.onSurface),
  ),
  cardColor: _gt7Surface,
  iconTheme: IconThemeData(color: _gt7ColorScheme.onSurface.withOpacity(0.9)),
  textTheme: TextTheme(
    // Headings — Roboto Condensed (from DESIGN.md: text-1, 29dp, light)
    displayLarge: TextStyle(
      fontFamily: 'Roboto Condensed',
      fontSize: 29,
      fontWeight: FontWeight.w300,
      height: 1.45,
      color: _gt7ColorScheme.onSurface,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Roboto Condensed',
      fontSize: 24,
      fontWeight: FontWeight.w400,
      height: 1.3,
      color: _gt7ColorScheme.onSurface,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Roboto Condensed',
      fontSize: 20,
      fontWeight: FontWeight.w400,
      height: 1.2,
      color: _gt7ColorScheme.onSurface.withOpacity(0.9),
    ),
    // Section headers — Helvetica Neue (from DESIGN.md: text-2, 21dp, bold)
    headlineSmall: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      height: 1.15,
      color: _gt7ColorScheme.onSurface,
    ),
    // Titles
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w400,
      height: 1.2,
      color: _gt7ColorScheme.onSurface,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 1.2,
      color: _gt7ColorScheme.onSurface.withOpacity(0.9),
    ),
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.0,
      color: _gt7ColorScheme.onSurface.withOpacity(0.9),
    ),
    // Body
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: _gt7ColorScheme.onSurface,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.3,
      color: _gt7ColorScheme.onSurface.withOpacity(0.9),
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: _gt7Muted,
    ),
    // Labels
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.0,
      color: _gt7ColorScheme.onSurface,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: _gt7Muted,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: _gt7Muted,
    ),
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
