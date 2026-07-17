/// نظام موحد للأبعاد (Dimensions) في التطبيق
/// يشمل Border Radius، Elevation، وأحجام الأيقونات
class AppDimensions {
  // ============ Border Radius ============
  static const double radiusXS = 8.0;
  static const double radiusSM = 12.0;
  static const double radiusMD = 16.0;
  static const double radiusLG = 24.0;
  static const double radiusXL = 32.0;
  static const double radiusRound = 999.0; // للأشكال الدائرية

  // ============ Elevation (Shadow) ============
  static const double elevationNone = 0.0;
  static const double elevationXS = 1.0;
  static const double elevationSM = 2.0;
  static const double elevationMD = 4.0;
  static const double elevationLG = 8.0;
  static const double elevationXL = 16.0;

  // ============ Icon Sizes ============
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;
  static const double iconXXL = 64.0;

  // ============ Component Heights ============
  static const double buttonHeight = 48.0;
  static const double buttonHeightSM = 40.0;
  static const double inputHeight = 56.0;
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 64.0;

  // ============ Card Dimensions ============
  static const double cardHeight = 200.0;
  static const double cardHeightSM = 150.0;
  static const double cardHeightLG = 250.0;

  // ============ Animation Durations (ms) ============
  static const int durationFast = 200;
  static const int durationNormal = 300;
  static const int durationMedium = 400;
  static const int durationSlow = 600;
  static const int durationVerySlow = 800;
}
