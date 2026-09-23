import 'package:flutter/material.dart';

abstract final class BttrColors {
  static const green = Color(0xFF14634C);
  static const ink = Color(0xFF213B32);
  static const muted = Color(0xFF616E66);
  static const background = Color(0xFFF7F9F6);
  static const line = Color(0xFFE5EAE5);
  static const lightGreen = Color(0xFFEAF0DF);
  static const forest = Color(0xFF124C3D);
}

ThemeData bttrTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: BttrColors.green,
    primary: BttrColors.green,
    surface: Colors.white,
    error: const Color(0xFFB63838),
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: BttrColors.line),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: BttrColors.background,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: BttrColors.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: BttrColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: BttrColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: BttrColors.ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: BttrColors.ink, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, color: BttrColors.muted, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, color: BttrColors.muted, height: 1.5),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: BttrColors.background,
      foregroundColor: BttrColors.ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: BttrColors.green, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      errorMaxLines: 3,
      helperMaxLines: 3,
      floatingLabelBehavior: FloatingLabelBehavior.always,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: BttrColors.lightGreen,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(color: BttrColors.line),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
