import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Brand Palette ─────────────────────────────────────────────────────────────
class AppColors {
  // Primary – MARA Red
  static const primary = Color(0xFFB5103C);
  static const primaryDark = Color(0xFF8C0C2A);
  static const primaryLight = Color(0xFFFDF0F3);
  static const primarySurface = Color(0xFFFAE5EC);

  // Accent – Trust Navy
  static const accent = Color(0xFF1A2E4A);
  static const accentLight = Color(0xFFE8EFF8);

  // Status
  static const success = Color(0xFF2D6A4F);
  static const successLight = Color(0xFFEAF5EE);
  static const warning = Color(0xFFB87A1A);
  static const warningLight = Color(0xFFFDF5E8);
  static const danger = Color(0xFFC85A18);
  static const dangerLight = Color(0xFFFDF0E6);
  static const info = Color(0xFF1D61B0);
  static const infoLight = Color(0xFFE3F0FF);

  // Extras
  static const purple = Color(0xFF7A3B8C);
  static const purpleLight = Color(0xFFF2EAF8);

  // Neutrals – ink scale
  static const ink = Color(0xFF0D1117);
  static const title = Color(0xFF1C2333);
  static const body = Color(0xFF3D4754);
  static const sub = Color(0xFF6B7685);
  static const muted = Color(0xFF9BA3AF);
  static const placeholder = Color(0xFFBEC5CF);
  static const border = Color(0xFFE4E7EC);
  static const borderLight = Color(0xFFF0F3F7);

  // Surfaces
  static const surface = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF6F8FC);
  static const bgAlt = Color(0xFFEFF2F7);
  static const white = Colors.white;

  // Dark surfaces
  static const darkBg = Color(0xFF0D1117);
  static const darkSurface = Color(0xFF161B22);
  static const darkBorder = Color(0xFF30363D);
  static const darkMuted = Color(0xFF8B949E);

  // Legacy aliases
  static const red = primary;
  static const redDark = primaryDark;
  static const redLight = primaryLight;
  static const green = success;
  static const greenLight = successLight;
  static const navy = accent;
  static const navyLight = accentLight;
  static const amber = warning;
  static const amberLight = warningLight;
  static const orange = danger;
  static const orangeLight = dangerLight;
}

// ── Shadows ───────────────────────────────────────────────────────────────────
class AppShadows {
  static const sm = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x05000000), blurRadius: 2),
  ];
  static const md = [
    BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
  ];
  static const lg = [
    BoxShadow(color: Color(0x18000000), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static const card = [
    BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x04000000), blurRadius: 4),
  ];
  static const nav = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, -4)),
    BoxShadow(color: Color(0x06000000), blurRadius: 8),
  ];
}

// ── Radius ────────────────────────────────────────────────────────────────────
class AppRadius {
  static const xs = BorderRadius.all(Radius.circular(6));
  static const sm = BorderRadius.all(Radius.circular(10));
  static const md = BorderRadius.all(Radius.circular(14));
  static const lg = BorderRadius.all(Radius.circular(20));
  static const xl = BorderRadius.all(Radius.circular(28));
  static const full = BorderRadius.all(Radius.circular(999));
}

// ── Theme ─────────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // System UI overlay
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          isDark ? AppColors.darkSurface : AppColors.surface,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      surface: isDark ? AppColors.darkSurface : AppColors.surface,
      onSurface: isDark ? Colors.white : AppColors.ink,
      error: AppColors.danger,
    );

    final inkColor = isDark ? Colors.white : AppColors.ink;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.darkBg : AppColors.bg,

      // ── Typography ──────────────────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 44,
          fontWeight: FontWeight.w800,
          color: inkColor,
          letterSpacing: -1.0,
          height: 1.1,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: inkColor,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: inkColor,
          letterSpacing: -0.3,
          height: 1.25,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: inkColor,
          letterSpacing: -0.4,
          height: 1.3,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: inkColor,
          letterSpacing: -0.3,
          height: 1.35,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: inkColor,
          letterSpacing: -0.2,
          height: 1.4,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: inkColor,
          height: 1.4,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: inkColor,
          height: 1.45,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.darkMuted : AppColors.body,
          height: 1.45,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: isDark ? Colors.white70 : AppColors.body,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDark ? Colors.white70 : AppColors.body,
          height: 1.55,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.darkMuted : AppColors.sub,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: inkColor,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkMuted : AppColors.sub,
          letterSpacing: 0.4,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkMuted : AppColors.muted,
          letterSpacing: 0.8,
        ),
      ),

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.title,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(
            color: isDark ? Colors.white : AppColors.title, size: 22),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),

      // ── Cards ───────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Buttons ─────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          textStyle: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1.5,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          textStyle:
              GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Inputs ──────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1C2333) : AppColors.bgAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: isDark ? AppColors.darkMuted : AppColors.placeholder,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: isDark ? AppColors.darkMuted : AppColors.sub,
        ),
      ),

      // ── Misc ────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkBorder : AppColors.border,
        thickness: 1,
        space: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF1C2333) : AppColors.bgAlt,
        selectedColor: AppColors.primarySurface,
        labelStyle:
            GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side:
            BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF2D333B) : AppColors.ink,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        selectedIconTheme:
            const IconThemeData(color: AppColors.primary, size: 24),
        unselectedIconTheme: IconThemeData(
            color: isDark ? AppColors.darkMuted : AppColors.muted, size: 22),
        selectedLabelTextStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primary),
        unselectedLabelTextStyle: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? AppColors.darkMuted : AppColors.muted),
        indicatorColor: AppColors.primarySurface,
        indicatorShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
