import 'package:flutter/material.dart';

class AppTheme {
  // Official EventDock Color Palette
  static const Color background = Color(0xFF000000);     // Pure Black
  static const Color surface = Color(0xFF171717);        // Dark Charcoal (Primary surface)
  static const Color card = Color(0xFF171717);           // Dark Charcoal
  static const Color cardSecondary = Color(0xFF262626);  // Charcoal (Secondary surface)
  static const Color cardBorder = Color(0xFF383838);     // Dark Gray

  static const Color primary = Color(0xFFFF7043);        // Signal Orange
  static const Color secondary = Color(0xFF262626);      // Charcoal
  static const Color textPrimary = Color(0xFFF5F5F5);    // Warm Off-White
  static const Color textMuted = Color(0xFFA3A3A3);      // Muted Gray
  static const Color codeBackground = Color(0xFF0D0D0D); // Deep Black for code/stack trace

  // Diagnostic Status Indicators
  static const Color status5xx = Color(0xFFEF4444);      // Error Red
  static const Color status4xx = Color(0xFFF59E0B);      // Warning Amber
  static const Color status2xx = Color(0xFF22C55E);      // Success Green

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: cardSecondary,
        surface: surface,
        error: status5xx,
        onPrimary: Colors.black,
        onSurface: textPrimary,
      ),
      cardColor: card,
      cardTheme: const CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          side: BorderSide(color: cardBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: cardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: cardBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: cardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: status5xx, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: status5xx, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: cardBorder),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textMuted,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: cardBorder,
        thickness: 1,
        space: 1,
      ),
      fontFamily: 'Inter',
    );
  }
}
