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

final ColorScheme _gt7ColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: _gt7Primary,
  onPrimary: _gt7Background,
  primaryContainer: _gt7PrimaryContainer,
  onPrimaryContainer: _gt7Accent,
  secondary: _gt7Secondary,
  onSecondary: _gt7Surface,
  surface: _gt7Surface,
  onSurface: _gt7OnSurface,
  error: _gt7Error,
  onError: Colors.white,
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
      lineA: _gt7Primary,
      lineB: _gt7Primary.withOpacity(0.6),
      marker: _gt7Primary,
      grid: _gt7Surface.withOpacity(0.06),
      highlight: _gt7Primary.withOpacity(0.18),
      track: _gt7Surface.withOpacity(0.04),
      trackShadow: _gt7Surface.withOpacity(0.9),
    ),
  ],
  dialogTheme: DialogThemeData(backgroundColor: _gt7Surface),
);

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
