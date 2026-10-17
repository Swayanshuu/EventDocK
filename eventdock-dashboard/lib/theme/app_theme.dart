import 'package:flutter/material.dart';

class AppTheme {
  // Matte Black & Orange SaaS Palette
  static const Color background = Color(0xFF090A0D);     // Deep obsidian background
  static const Color sidebar = Color(0xFF0E0F14);        // Dedicated left sidebar surface
  static const Color shell = Color(0xFF101217);          // Main content container
  static const Color surface = Color(0xFF14161C);        // Primary surface
  static const Color card = Color(0xFF161820);           // Card background
  static const Color cardSecondary = Color(0xFF1D202A);  // Card interior / nested tiles
  static const Color cardBorder = Color(0xFF242733);     // Subtle 1px borders
  static const Color cardBorderLight = Color(0xFF2E3242);// Slightly elevated border

  // The Signature Hero Orange (Vibrant Orange Brand Accent)
  static const Color heroOrange = Color(0xFFFF5533);
  static const Color heroOrangeLight = Color(0xFFFF6D4D);
  static const Color heroOrangeDark = Color(0xFFE64220);
  static const Color heroOrangeGlow = Color(0x33FF5533);
  static const Color heroCoral = heroOrange;
  static const Color heroCoralLight = heroOrangeLight;
  static const Color heroCoralDark = heroOrangeDark;

  // Status & Brand Tokens
  static const Color primary = heroOrange;
  static const Color secondary = Color(0xFF1D202A);
  static const Color textPrimary = Color(0xFFF6F7FA);    // High contrast crisp off-white
  static const Color textMuted = Color(0xFF8B92A2);      // Muted slate gray
  static const Color textSubtle = Color(0xFF5A6172);     // Subtle caption gray
  static const Color codeBackground = Color(0xFF0C0D11); // Deep editor surface

  // Diagnostic Status Indicators
  static const Color status5xx = Color(0xFFEF4444);      // Server error crimson
  static const Color status4xx = Color(0xFFF59E0B);      // Client error amber
  static const Color status2xx = Color(0xFF22C55E);      // Healthy green
  static const Color accentYellow = Color(0xFFFACC15);   // Allocation yellow
  static const Color accentGreen = Color(0xFF10B981);    // Gauge green

  // Pill Navigation & Controls
  static const Color pillBackground = Color(0xFF1F1F27);
  static const Color pillBorder = Color(0xFF2D2D38);
  static const Color pillActive = Color(0xFFFFFFFF);
  static const Color pillActiveText = Color(0xFF0C0C0E);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: heroCoral,
        secondary: cardSecondary,
        surface: surface,
        error: status5xx,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      cardColor: card,
      cardTheme: const CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: cardBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: shell,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: cardBorderLight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: heroCoral, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: status5xx, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: status5xx, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: heroCoral,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: cardBorder),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
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
    );
  }
}
