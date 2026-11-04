import 'package:flutter/material.dart';

class AppTheme {
  // Theme Mode Controller
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);
  static bool get isDark => themeModeNotifier.value == ThemeMode.dark;

  static void toggleThemeMode() {
    themeModeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
  }

  static void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  // ==========================================
  // Signature Hero Orange (Vibrant Orange Brand Accent)
  // Shared across both Dark (Black & Orange) and Light (White & Orange)
  // ==========================================
  static const Color heroOrange = Color(0xFFFF5500);       // Pure vibrant SaaS orange
  static const Color heroOrangeLight = Color(0xFFFF7043);  // Hover & highlight
  static const Color heroOrangeDark = Color(0xFFE64220);   // Pressed & deep accent
  static const Color heroOrangeGlow = Color(0x33FF5500);   // Translucent glow
  static const Color heroCoral = heroOrange;
  static const Color heroCoralLight = heroOrangeLight;
  static const Color heroCoralDark = heroOrangeDark;
  static const Color primary = heroOrange;

  // Diagnostic Status Indicators
  static const Color status5xx = Color(0xFFEF4444);      // Server error crimson
  static const Color status4xx = Color(0xFFF59E0B);      // Client error amber
  static const Color status2xx = Color(0xFF22C55E);      // Healthy green
  static const Color accentYellow = Color(0xFFFACC15);   // Allocation yellow
  static const Color accentGreen = Color(0xFF10B981);    // Gauge green

  // ==========================================
  // Dynamic Surfaces & Typography Tokens
  // Automatically adapt to Dark Mode (Black) vs Light Mode (White)
  // ==========================================
  static Color get background => isDark ? const Color(0xFF090A0D) : const Color(0xFFFFFFFF);
  static Color get sidebar => isDark ? const Color(0xFF0C0D12) : const Color(0xFFF8F9FB);
  static Color get shell => isDark ? const Color(0xFF101117) : const Color(0xFFF3F4F7);
  static Color get surface => isDark ? const Color(0xFF13141A) : const Color(0xFFFFFFFF);
  static Color get card => isDark ? const Color(0xFF161820) : const Color(0xFFFFFFFF);
  static Color get cardBackground => card;
  static Color get cardSecondary => isDark ? const Color(0xFF1D202A) : const Color(0xFFF1F3F6);
  static Color get cardBorder => isDark ? const Color(0xFF262936) : const Color(0xFFE2E4E9);
  static Color get cardBorderLight => isDark ? const Color(0xFF2E3242) : const Color(0xFFD1D5DB);

  static Color get secondary => cardSecondary;
  static Color get textPrimary => isDark ? const Color(0xFFF6F7FA) : const Color(0xFF0F1115);
  static Color get textMuted => isDark ? const Color(0xFF8B92A2) : const Color(0xFF64748B);
  static Color get textSubtle => isDark ? const Color(0xFF5A6172) : const Color(0xFF94A3B8);
  static Color get codeBackground => isDark ? const Color(0xFF08090C) : const Color(0xFFF8F9FA);

  // Pill Navigation & Controls
  static Color get pillBackground => isDark ? const Color(0xFF1F1F27) : const Color(0xFFE9ECEF);
  static Color get pillBorder => isDark ? const Color(0xFF2D2D38) : const Color(0xFFDEE2E6);
  static Color get pillActive => isDark ? const Color(0xFF1D202A) : const Color(0xFFFFFFFF);
  static Color get pillActiveText => isDark ? const Color(0xFFF6F7FA) : const Color(0xFF0F1115);

  // Light Mode Tokens (White & Orange)
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSidebar = Color(0xFFF8F9FB);
  static const Color lightShell = Color(0xFFF3F4F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardSecondary = Color(0xFFF1F3F6);
  static const Color lightCardBorder = Color(0xFFE2E4E9);
  static const Color lightCardBorderLight = Color(0xFFD1D5DB);
  static const Color lightTextPrimary = Color(0xFF0F1115);
  static const Color lightTextMuted = Color(0xFF64748B);
  static const Color lightTextSubtle = Color(0xFF94A3B8);
  static const Color lightCodeBackground = Color(0xFFF8F9FA);

  // ==========================================
  // Dark Theme (Matte Black & Signature Orange)
  // ==========================================
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF090A0D),
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: const Color(0xFF1D202A).withValues(alpha: 0.5),
      colorScheme: const ColorScheme.dark(
        primary: heroOrange,
        secondary: Color(0xFF1D202A),
        surface: Color(0xFF13141A),
        error: status5xx,
        onPrimary: Colors.white,
        onSurface: Color(0xFFF6F7FA),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF1D202A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF262936), width: 1),
        ),
        textStyle: const TextStyle(
          color: Color(0xFFF6F7FA),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        waitDuration: const Duration(milliseconds: 300),
      ),
      cardColor: const Color(0xFF161820),
      cardTheme: const CardThemeData(
        color: Color(0xFF161820),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0xFF262936), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF101117),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Color(0xFFF6F7FA)),
        titleTextStyle: TextStyle(
          color: Color(0xFFF6F7FA),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF161820),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: Color(0xFF2E3242), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1D202A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF262936), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF262936), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: heroOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: status5xx, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: status5xx, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF8B92A2)),
        hintStyle: const TextStyle(color: Color(0xFF8B92A2)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: heroOrange,
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
          foregroundColor: const Color(0xFFF6F7FA),
          side: const BorderSide(color: Color(0xFF262936)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF8B92A2),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF262936),
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ==========================================
  // Light Theme (Pure White & Signature Orange)
  // ==========================================
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: const Color(0xFFF1F3F6).withValues(alpha: 0.7),
      colorScheme: const ColorScheme.light(
        primary: heroOrange,
        secondary: Color(0xFFF1F3F6),
        surface: Color(0xFFFFFFFF),
        error: status5xx,
        onPrimary: Colors.white,
        onSurface: Color(0xFF0F1115),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1115),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF262936), width: 1),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        waitDuration: const Duration(milliseconds: 300),
      ),
      cardColor: const Color(0xFFFFFFFF),
      cardTheme: const CardThemeData(
        color: Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0xFFE2E4E9), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF0F1115)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F1115),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: Color(0xFFE2E4E9), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E4E9), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E4E9), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: heroOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: status5xx, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: status5xx, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: heroOrange,
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
          foregroundColor: const Color(0xFF0F1115),
          side: const BorderSide(color: Color(0xFFE2E4E9)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF64748B),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E4E9),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
