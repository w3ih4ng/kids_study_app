import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand colors (unchanged) ───────────────────────────────
  static const Color primary = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color accent = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);

  // ── These keep the SAME names — no existing code breaks ───
  // Dark navy values (default/dark mode)
  static const Color background = Color(0xFF080C20);
  static const Color surface = Color(0xFF0F1535);
  static const Color border = Color(0xFF1E2A4A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B9CC8);

  // ── Light mode equivalents (only used inside lightTheme) ──
  static const Color _lightBackground = Color(0xFFF9FAFB);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightBorder = Color(0xFFE5E7EB);
  static const Color _lightTextPrimary = Color(0xFF111827);
  static const Color _lightTextSecondary = Color(0xFF6B7280);

  // Tab colors (unchanged)
  static const Color lessonsColor = Color(0xFF3B82F6);
  static const Color quizzesColor = Color(0xFF8B5CF6);
  static const Color booksColor = Color(0xFFEC4899);
  static const Color petsColor = Color(0xFF10B981);

  // ── Shared AppBar & Button (same in both modes) ────────────
  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    toolbarHeight: 70,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  );

  static ElevatedButtonThemeData get _buttonTheme => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  // ── Dark Theme (default — uses AppTheme.X colors) ─────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      onSurface: textPrimary,
      outline: border,
    ),
    scaffoldBackgroundColor: background,
    fontFamily: 'Roboto',
    appBarTheme: _appBarTheme,
    elevatedButtonTheme: _buttonTheme,
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textPrimary),
      displayMedium: TextStyle(color: textPrimary),
      displaySmall: TextStyle(color: textPrimary),
      headlineLarge: TextStyle(color: textPrimary),
      headlineMedium: TextStyle(color: textPrimary),
      headlineSmall: TextStyle(color: textPrimary),
      titleLarge: TextStyle(color: textPrimary),
      titleMedium: TextStyle(color: textPrimary),
      titleSmall: TextStyle(color: textPrimary),
      bodyLarge: TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textPrimary),
      bodySmall: TextStyle(color: textSecondary),
      labelLarge: TextStyle(color: textPrimary),
      labelMedium: TextStyle(color: textSecondary),
      labelSmall: TextStyle(color: textSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: textPrimary,
      iconColor: textSecondary,
    ),
    dividerColor: border,
    iconTheme: const IconThemeData(color: textSecondary),
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white60,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textSecondary,
    ),
  );

  // ── Light Theme ────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: _lightSurface,
      onSurface: _lightTextPrimary,
      outline: _lightBorder,
    ),
    scaffoldBackgroundColor: _lightBackground,
    fontFamily: 'Roboto',
    appBarTheme: _appBarTheme,
    elevatedButtonTheme: _buttonTheme,
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: _lightTextPrimary),
      displayMedium: TextStyle(color: _lightTextPrimary),
      displaySmall: TextStyle(color: _lightTextPrimary),
      headlineLarge: TextStyle(color: _lightTextPrimary),
      headlineMedium: TextStyle(color: _lightTextPrimary),
      headlineSmall: TextStyle(color: _lightTextPrimary),
      titleLarge: TextStyle(color: _lightTextPrimary),
      titleMedium: TextStyle(color: _lightTextPrimary),
      titleSmall: TextStyle(color: _lightTextPrimary),
      bodyLarge: TextStyle(color: _lightTextPrimary),
      bodyMedium: TextStyle(color: _lightTextPrimary),
      bodySmall: TextStyle(color: _lightTextSecondary),
      labelLarge: TextStyle(color: _lightTextPrimary),
      labelMedium: TextStyle(color: _lightTextSecondary),
      labelSmall: TextStyle(color: _lightTextSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(color: _lightTextSecondary),
      hintStyle: const TextStyle(color: _lightTextSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      filled: true,
      fillColor: _lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: _lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: _lightTextPrimary,
      iconColor: _lightTextSecondary,
    ),
    dividerColor: _lightBorder,
    iconTheme: const IconThemeData(color: _lightTextSecondary),
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white60,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _lightSurface,
      selectedItemColor: primary,
      unselectedItemColor: _lightTextSecondary,
    ),
  );

  // ── Keep old 'theme' getter pointing to dark ───────────────
  // So any file still using AppTheme.theme won't break
  static ThemeData get theme => darkTheme;
}
