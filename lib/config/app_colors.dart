import 'package:flutter/material.dart';

class AppColors {
  // ============ Primary Color Palette (Modern Teal-Cyan) ============
  static const Color primary50 = Color(0xFFE0F7FA);
  static const Color primary100 = Color(0xFFB2EBF2);
  static const Color primary200 = Color(0xFF80DEEA);
  static const Color primary300 = Color(0xFF4DD0E1);
  static const Color primary400 = Color(0xFF26C6DA);
  static const Color primary = Color(0xFF00ACC1); // أكثر حداثة وإشراقاً
  static const Color primary600 = Color(0xFF00ACC1);
  static const Color primary700 = Color(0xFF0097A7);
  static const Color primary800 = Color(0xFF00838F);
  static const Color primary900 = Color(0xFF006064);

  // ============ Secondary Color (Lighter Teal) ============
  static const Color secondary = Color(0xFF26C6DA);
  static const Color secondary100 = Color(0xFFB2EBF2);
  static const Color secondary700 = Color(0xFF0097A7);

  // ============ Accent Color (Deep Orange) ============
  static const Color accent = Color(0xFFFF6E40);
  static const Color accent100 = Color(0xFFFFCCBC);
  static const Color accent700 = Color(0xFFE64A19);

  // ============ Status Colors ============
  static const Color success = Color(0xFF10B981);
  static const Color success100 = Color(0xFFD1FAE5);
  static const Color success700 = Color(0xFF047857);

  static const Color danger = Color(0xFFEF4444);
  static const Color danger100 = Color(0xFFFEE2E2);
  static const Color danger700 = Color(0xFFB91C1C);

  static const Color warning = Color(0xFFFBBC04);
  static const Color warning100 = Color(0xFFFEF3C7);
  static const Color warning700 = Color(0xFFD97706);

  static const Color info = Color(0xFF3B82F6);
  static const Color info100 = Color(0xFFDBEAFE);
  static const Color info700 = Color(0xFF1D4ED8);

  // ============ Neutral Colors ============
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFFF1F5F9);
  static const Color surface = Colors.white;
  static const Color surfaceLight = Color(0xFFFAFAFA);

  // ============ Text Colors ============
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMedium = Color(0xFF475569);
  static const Color textLight = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);

  // ============ Border & Divider ============
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // ============ Chart Colors ============
  static const Color chartBar = Color(0xFF3B82F6);
  static const Color chartLine = Color(0xFF8B5CF6);
  static const Color chartPie1 = Color(0xFF06B6D4);
  static const Color chartPie2 = Color(0xFF10B981);
  static const Color chartPie3 = Color(0xFFF59E0B);

  // ============ Gradients ============
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accent700],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, success700],
  );

  // ============ Shadows ============
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get strongShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 30,
          offset: const Offset(0, 8),
        ),
      ];
}
