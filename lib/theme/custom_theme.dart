import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTheme {
  // HSL-based gradient brand colors: teal (174°, 72%, 42%) ↔ indigo (231°, 48%, 48%).
  static final Color primaryStart =
      HSLColor.fromAHSL(1.0, 174, 0.72, 0.42).toColor(); // teal
  static final Color primaryEnd =
      HSLColor.fromAHSL(1.0, 231, 0.48, 0.48).toColor(); // indigo

  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryStart, primaryEnd],
      );

  static LinearGradient gradientForBrightness(bool isDark) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [primaryEnd.withValues(alpha: 0.85), primaryStart.withValues(alpha: 0.65)]
            : [primaryStart, primaryEnd],
      );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: GoogleFonts.inter().fontFamily,
    scaffoldBackgroundColor: const Color(0xFFF4F7FB),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryStart,
      secondary: primaryEnd,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData(brightness: Brightness.light).textTheme,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.inter().fontFamily,
    scaffoldBackgroundColor: const Color(0xFF0E1116),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryStart,
      secondary: primaryEnd,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
    ),
  );

  static BoxDecoration gradientBackground({bool isDark = false}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [primaryEnd.withValues(alpha: 0.6), Colors.black87]
            : [primaryStart.withValues(alpha: 0.18), primaryEnd.withValues(alpha: 0.18)],
      ),
    );
  }

  static BoxDecoration glassCard({bool isDark = false}) {
    return BoxDecoration(
      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.3),
        width: 1,
      ),
    );
  }
}
