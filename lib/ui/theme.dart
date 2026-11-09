import 'package:flutter/material.dart';

class BrandPalette {
  const BrandPalette({
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.outline,
    required this.accent,
    required this.onAccent,
    required this.accentText,
    required this.info,
    required this.danger,
    required this.textHi,
    required this.textMid,
    required this.textLow,
  });

  final Color bg;
  final Color surface;
  final Color surfaceHigh;
  final Color outline;
  final Color accent;
  final Color onAccent;
  final Color accentText;
  final Color info;
  final Color danger;
  final Color textHi;
  final Color textMid;
  final Color textLow;
}

abstract final class FxSpace {
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
}

abstract final class FxRadius {
  static const button = 14.0;
  static const card = 18.0;
  static const sheet = 24.0;
}

ThemeData treasuryTheme(BrandPalette palette) {
  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: palette.accent,
    onPrimary: palette.onAccent,
    secondary: palette.info,
    onSecondary: palette.onAccent,
    error: palette.danger,
    onError: Colors.black,
    surface: palette.surface,
    onSurface: palette.textHi,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.bg,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: palette.bg,
      foregroundColor: palette.textHi,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FxRadius.card),
        side: BorderSide(color: palette.outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FxRadius.button)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.textHi,
        side: BorderSide(color: palette.outline),
        minimumSize: const Size(48, 48),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceHigh,
      isDense: false,
      contentPadding: const EdgeInsets.all(FxSpace.l),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(FxRadius.button)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.accent.withValues(alpha: 0.18),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(FxRadius.sheet)),
      ),
    ),
  );
}
