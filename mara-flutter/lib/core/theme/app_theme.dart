import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const red = Color(0xFFB5103C);
  static const redDark = Color(0xFF8C0C2A);
  static const redLight = Color(0xFFFDF0F3);
  static const green = Color(0xFF2D6A4F);
  static const greenLight = Color(0xFFEAF5EE);
  static const navy = Color(0xFF1A2E4A);
  static const navyLight = Color(0xFFE8EFF8);
  static const amber = Color(0xFFB87A1A);
  static const amberLight = Color(0xFFFDF5E8);
  static const orange = Color(0xFFC85A18);
  static const orangeLight = Color(0xFFFDF0E6);
  static const purple = Color(0xFF7A3B8C);
  static const purpleLight = Color(0xFFF2EAF8);
  static const ink = Color(0xFF1A1A1A);
  static const sub = Color(0xFF5A5A5A);
  static const muted = Color(0xFF999999);
  static const border = Color(0xFFE8E8E3);
  static const bg = Color(0xFFFAFAF8);
  static const white = Colors.white;
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.red,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: GoogleFonts.sourceSerif4TextTheme(ThemeData.light().textTheme)
          .copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: AppColors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
