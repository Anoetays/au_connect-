import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand Colors ──────────────────────────────────────────────────────────
  static const Color primaryCrimson = Color(0xFFB91C1C);
  static const Color primary = primaryCrimson; // unified alias
  static const Color primaryDark = Color(0xFF7F1D1D);
  static const Color primaryLight = Color(0xFFFEF2F2);

  // ── Background / Surface ─────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundLight = background;
  static const Color backgroundDark = Color(0xFF201212);
  static const Color surface = Color(0xFFFFFFFF);

  // ── Border ───────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFF1F5F9);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textDark = textPrimary; // alias
  static const Color textSecondary = Color(0xFF475569);
  static const Color textLight = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF94A3B8);

  // ── Status / Semantic ────────────────────────────────────────────────────
  static const Color statusApproved = Color(0xFF22C55E);
  static const Color statusPending = Color(0xFFF97316);
  static const Color statusDenied = Color(0xFFEF4444);
  static const Color statusReview = Color(0xFF3B82F6);

  // ── Legacy semantic aliases (mapped to status colors) ────────────────────
  static const Color success = statusApproved;
  static const Color successSurface = Color(0xFFF0FDF4);
  static const Color warning = statusPending;
  static const Color warningSurface = Color(0xFFFFFBEB);
  static const Color info = statusReview;
  static const Color infoSurface = Color(0xFFEFF6FF);
  static const Color errorSurface = primaryLight;

  // ── UI Surface variants ──────────────────────────────────────────────────
  static const Color onSurface = Color(0xFF1F2937);
  static const Color onSurfaceVariant = Color(0xFF49454F);
  static const Color surfaceVariant = Color(0xFFE2E8F0);
  static const Color surfaceContainerHigh = Color(0xFFF0F4FF);
  static const Color surfaceContainerHighest = Color(0xFFE7E0EC);
  static const Color surfaceContainerLow = Color(0xFFF7F2FA);
  static const Color surfaceContainer = Color(0xFFF3EDF7);

  // ── Outline / Divider ────────────────────────────────────────────────────
  static const Color outline = textMuted;
  static const Color outlineVariant = Color(0xFFCBD5E1);
  static const Color divider = border;

  // ── Legacy compat ────────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF7C3AED);
  static const Color secondary = Color(0xFF625B71);
  static const Color primaryContainer = Color(0xFFFFDAD6);
  static const Color secondaryContainer = Color(0xFFE8DEF8);
  static const Color onSecondaryContainer = Color(0xFF1D192B);
  static const Color onTertiaryFixed = Color(0xFFFFFFFF);

  // ── Spacing ──────────────────────────────────────────────────────────────
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;

  // ── Radius ───────────────────────────────────────────────────────────────
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;

  // ── Shadows ──────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // ── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryCrimson,
        onPrimary: Colors.white,
        secondary: Color(0xFF625B71),
        surface: surface,
        error: statusDenied,
        outline: border,
      ),
      scaffoldBackgroundColor: background,
      textTheme: base.textTheme.copyWith(
        displayLarge: const TextStyle(
            fontSize: 32, fontWeight: FontWeight.w400, letterSpacing: -0.5,
            color: textPrimary),
        headlineLarge: const TextStyle(
            fontSize: 26, fontWeight: FontWeight.w400, letterSpacing: -0.5,
            color: textPrimary),
        headlineMedium: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w400, letterSpacing: -0.3,
            color: textPrimary),
        headlineSmall: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary),
        titleMedium: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
        titleSmall: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: const TextStyle(
            fontSize: 15, height: 1.5, color: textPrimary),
        bodyMedium: const TextStyle(
            fontSize: 14, height: 1.5, color: textPrimary),
        bodySmall: const TextStyle(
            fontSize: 12, height: 1.4, color: textMuted),
        labelLarge: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1,
            color: textPrimary),
        labelMedium: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5,
            color: textSecondary),
        labelSmall: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
            color: textMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Color(0x0F000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLG)),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return primaryCrimson.withValues(alpha: 0.5);
            }
            if (states.contains(WidgetState.pressed)) {
              return primaryDark;
            }
            return primaryCrimson;
          }),
          foregroundColor: WidgetStatePropertyAll(Colors.white),
          overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.12)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 9, horizontal: 18),
          ),
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0),
          ),
          elevation: WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: textSecondary,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 18),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryCrimson,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSM)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryCrimson, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: statusDenied),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: background,
        selectedColor: primaryLight,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: const StadiumBorder(),
        side: BorderSide(color: border),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: surface,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primaryCrimson : Colors.transparent),
        side: const BorderSide(color: outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryCrimson,
        unselectedItemColor: textMuted,
        selectedIconTheme: IconThemeData(size: 24),
        unselectedIconTheme: IconThemeData(size: 22),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMD)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryCrimson,
        onPrimary: Colors.white,
        surface: Color(0xFF0F172A),
        error: statusDenied,
      ),
      scaffoldBackgroundColor: backgroundDark,
      textTheme: ThemeData.dark().textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textLight),
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF0F172A),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryCrimson,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 18),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryCrimson,
          side: const BorderSide(color: primaryCrimson, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 18),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryCrimson,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryCrimson, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0F172A),
        selectedItemColor: primaryCrimson,
        unselectedItemColor: textMuted,
        selectedIconTheme: IconThemeData(size: 24),
        unselectedIconTheme: IconThemeData(size: 22),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
