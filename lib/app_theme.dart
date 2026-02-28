import 'package:flutter/material.dart';

/// Centralized theme and color definitions for the app.
///
/// This file makes it easy to adjust the look of all ElevatedButtons
/// (and other widgets) from a single location.  The custom theme is
/// constructed here and applied in `main.dart`.

class AppColors {
  AppColors._(); // prevent instantiation

  /// Primary brand color used throughout the app.
  ///
  /// Pick a value that matches your design language; all buttons will
  /// reference this color via the theme so changing it here will ripple
  /// through the UI.
  static const Color primary = Color(0xFF1E88E5);

  /// Accent color for elevated buttons and other UI elements.
  ///
  /// We simply reuse [primary] for now, but you can override it if
  /// you need a distinct button color in the future.
  static const Color button = primary;
}

/// Builds a [ThemeData] object preconfigured for the app.
ThemeData buildAppTheme() {
  // We use material3 because the app already opted in earlier.  The
  // color scheme is derived from a seed color so text/contrast
  // colors come for free, but we override the elevated button theme
  // to ensure the same shade is used everywhere.
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.button,
        foregroundColor: Colors.white,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.button,
      foregroundColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
