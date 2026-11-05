import 'package:flutter/material.dart';

/// The two GT7 dealerships deliberately have independent surface palettes.
ThemeData dealerTheme(ThemeData parent, {required bool legendary}) {
  final colors =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF2686A6),
        brightness: legendary ? Brightness.dark : Brightness.light,
        surface: legendary ? const Color(0xFF202226) : const Color(0xFFDEE0E1),
      ).copyWith(
        primary: legendary ? const Color(0xFF58ABCA) : const Color(0xFF27292C),
        onPrimary: legendary
            ? const Color(0xFF0C2028)
            : const Color(0xFFFFFFFF),
        surfaceContainerLow: legendary
            ? const Color(0xFF17191C)
            : const Color(0xFFE9EAEB),
        surfaceContainerHighest: legendary
            ? const Color(0xFF2D3137)
            : const Color(0xFFCDD0D2),
        onSurface: legendary
            ? const Color(0xFFE7EAEB)
            : const Color(0xFF191B1D),
        onSurfaceVariant: legendary
            ? const Color(0xFFA9B0B7)
            : const Color(0xFF5E6469),
        error: legendary ? const Color(0xFFFF8C85) : const Color(0xFFB3262A),
      );
  return parent.copyWith(
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surface,
    textTheme: parent.textTheme.apply(
      fontFamily: 'Arial',
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
    ),
    iconTheme: parent.iconTheme.copyWith(color: colors.onSurface),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: colors.primary),
    ),
    dialogTheme: DialogThemeData(backgroundColor: colors.surface),
  );
}

/// Reconstructed regional Used backplates; neutral studio for unknown countries.
/// The floor starts at the thumbnail wheel line rather than at the panel edge.
BoxDecoration dealerThumbnailBackground(String country) {
  final (sky, floor) = switch (country.toLowerCase()) {
    'jp' || 'kr' || 'cn' => (const Color(0xFFD6E8ED), const Color(0xFF6B8790)),
    'us' ||
    'ca' ||
    'mx' ||
    'br' => (const Color(0xFFF0DFC6), const Color(0xFF937955)),
    'it' ||
    'fr' ||
    'de' ||
    'gb' ||
    'at' ||
    'be' ||
    'es' ||
    'se' ||
    'cz' ||
    'hr' ||
    'nl' ||
    'ch' => (const Color(0xFFE8E1C9), const Color(0xFF817C60)),
    _ => (const Color(0xFFE7EAEB), const Color(0xFF81898D)),
  };
  final backdrop = switch (country.toLowerCase()) {
    'jp' || 'kr' || 'cn' || 'au' => 'asia',
    'us' || 'ca' || 'mx' || 'br' => 'america',
    'it' ||
    'fr' ||
    'de' ||
    'gb' ||
    'at' ||
    'be' ||
    'es' ||
    'se' ||
    'cz' ||
    'hr' ||
    'nl' ||
    'ch' => 'europe',
    _ => null,
  };
  return BoxDecoration(
    image: backdrop == null
        ? null
        : DecorationImage(
            image: AssetImage('assets/images/used-backdrop-$backdrop-v2.webp'),
            fit: BoxFit.cover,
          ),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [sky, Color.lerp(sky, floor, .22)!, floor, floor],
      stops: const [0, .36, .67, 1],
    ),
  );
}
