import 'package:flutter/material.dart';

/// Centralized typography system.
///
/// Call [AppTextStyles.build] to get a [TextTheme] bound to specific colors,
/// or [AppTextStyles.scaled] to apply a font-scale multiplier.
///
/// Font family: Montserrat (bundled in assets/fonts/).
/// All sizes follow the Material 3 type scale.
abstract final class AppTextStyles {
  static const String _family = 'Montserrat';

  // ── Font scale labels ──────────────────────────────────────────────────────
  static const double scaleXS = 0.80;
  static const double scaleS = 0.90;
  static const double scaleM = 1; // default
  static const double scaleL = 1.15;
  static const double scaleXL = 1.30;
  static const double scaleXXL = 1.40;

  /// Builds a [TextTheme] with [primaryColor] for most styles and
  /// [mutedColor] for secondary / caption styles.
  ///
  /// Sizes match the Material 3 scale; weights are tuned for Montserrat.
  static TextTheme build({
    required Color primaryColor,
    required Color mutedColor,
    double scale = scaleM,
  }) {
    double s(double base) => base * scale;

    return TextTheme(
      // Display
      displayLarge: TextStyle(
        fontFamily: _family,
        fontSize: s(32),
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: _family,
        fontSize: s(28),
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.2,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontFamily: _family,
        fontSize: s(24),
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.25,
      ),
      // Headline
      headlineLarge: TextStyle(
        fontFamily: _family,
        fontSize: s(22),
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontFamily: _family,
        fontSize: s(20),
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontFamily: _family,
        fontSize: s(18),
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.35,
      ),
      // Title
      titleLarge: TextStyle(
        fontFamily: _family,
        fontSize: s(17),
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.35,
      ),
      titleMedium: TextStyle(
        fontFamily: _family,
        fontSize: s(16),
        fontWeight: FontWeight.w500,
        color: primaryColor,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontFamily: _family,
        fontSize: s(14),
        fontWeight: FontWeight.w500,
        color: primaryColor,
        height: 1.4,
      ),
      // Body
      bodyLarge: TextStyle(
        fontFamily: _family,
        fontSize: s(16),
        fontWeight: FontWeight.w400,
        color: primaryColor,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: _family,
        fontSize: s(14),
        fontWeight: FontWeight.w400,
        color: primaryColor,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: _family,
        fontSize: s(12),
        fontWeight: FontWeight.w400,
        color: mutedColor,
        height: 1.4,
      ),
      // Label
      labelLarge: TextStyle(
        fontFamily: _family,
        fontSize: s(15),
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.4,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontFamily: _family,
        fontSize: s(13),
        fontWeight: FontWeight.w500,
        color: primaryColor,
        height: 1.4,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontFamily: _family,
        fontSize: s(11),
        fontWeight: FontWeight.w500,
        color: mutedColor,
        height: 1.3,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Convenience wrapper — builds with [scale] applied.
  static TextTheme scaled({
    required Color primaryColor,
    required Color mutedColor,
    required double scale,
  }) => build(primaryColor: primaryColor, mutedColor: mutedColor, scale: scale);
}
