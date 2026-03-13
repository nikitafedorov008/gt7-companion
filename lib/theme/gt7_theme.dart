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

final ColorScheme _gt7ColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: _gt7Primary,
  onPrimary: _gt7Background,
  primaryContainer: _gt7PrimaryContainer,
  onPrimaryContainer: _gt7Accent,
  secondary: _gt7Secondary,
  onSecondary: _gt7Surface,
  surface: _gt7Surface,
  onSurface: Color(0xFFE6EEF2),
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
