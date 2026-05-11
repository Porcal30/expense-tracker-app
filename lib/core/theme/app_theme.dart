import 'package:flutter/material.dart';

class AppTheme {
  static const _bgStart = Color(0xFF050C1A);
  static const _bgEnd = Color(0xFF111B3B);
  static const _card = Color(0xFF13264A);
  static const _line = Color(0xFF31F0CE);
  static const _accent = Color(0xFF5EA8FF);
  static const _surfaceTint = Color(0xFF1F3668);

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.dark(
      primary: _line,
      secondary: _accent,
      surface: _card,
      onSurface: Color(0xFFEAF3FF),
      onSurfaceVariant: Color(0xFF9BB1CF),
      error: Color(0xFFFF6E8A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _bgStart,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface.withValues(alpha: 0.84),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.26)),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: Colors.white,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(color: Color(0xFFD5E2F6)),
        labelLarge: TextStyle(
          color: Color(0xFFE8F2FF),
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.24),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.16),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.62),
            width: 1.4,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: _surfaceTint.withValues(alpha: 0.88),
        indicatorColor: _line.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _line,
        foregroundColor: _bgStart,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: _line,
          foregroundColor: _bgStart,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: _surfaceTint.withValues(alpha: 0.35),
        iconColor: colorScheme.primary,
        textColor: colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.16),
        thickness: 1,
      ),
    );
  }
}
