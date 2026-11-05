import 'package:flutter/material.dart';

/// Palette measured on the official Beyond the Apex magazine, scoped to its
/// reader so the rest of the application keeps its own Gran Turismo styling.
const apexPaper = Color(0xFFFFFFFF);
const apexInk = Color(0xFF000000);
const apexChapterSurface = Color(0xFFF9FAFC);
const apexContentsSurface = Color(0xFFEDF2F4);
const apexRule = Color(0xFFC3C3C3);

ThemeData apexMagazineTheme(ThemeData parent) {
  final colors = const ColorScheme.light(
    primary: apexInk,
    onPrimary: apexPaper,
    secondary: apexInk,
    onSecondary: apexPaper,
    surface: apexPaper,
    onSurface: apexInk,
    onSurfaceVariant: Color(0xFF505050),
    surfaceContainerLow: apexChapterSurface,
    surfaceContainer: apexContentsSurface,
    surfaceContainerHigh: apexContentsSurface,
    surfaceContainerHighest: apexContentsSurface,
    outline: apexRule,
    outlineVariant: apexRule,
  );
  final text = parent.textTheme.apply(
    bodyColor: apexInk,
    displayColor: apexInk,
  );
  return parent.copyWith(
    colorScheme: colors,
    scaffoldBackgroundColor: apexPaper,
    canvasColor: apexPaper,
    dividerColor: apexRule,
    visualDensity: VisualDensity.standard,
    textTheme: text.copyWith(
      titleSmall: text.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: text.bodyLarge?.copyWith(
        height: 1.65,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: text.bodyMedium?.copyWith(
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: apexInk,
      foregroundColor: apexPaper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 52,
      iconTheme: const IconThemeData(color: apexPaper, size: 22),
      actionsIconTheme: const IconThemeData(color: apexPaper, size: 22),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: apexPaper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(),
    ),
    iconTheme: const IconThemeData(color: apexInk),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: apexInk,
        minimumSize: const Size(44, 44),
      ),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      backgroundColor: apexChapterSurface,
      collapsedBackgroundColor: apexChapterSurface,
      textColor: apexInk,
      collapsedTextColor: apexInk,
      iconColor: apexInk,
      collapsedIconColor: apexInk,
      shape: Border(),
      collapsedShape: Border(),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: apexInk),
  );
}
