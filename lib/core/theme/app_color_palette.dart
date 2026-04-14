import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Semantic color tokens for a single brightness mode.
///
/// Every property maps to a Material 3 role — feature widgets access colors
/// through [ColorScheme] on [BuildContext], never from this class directly.
class AppColorTokens extends Equatable {
  const AppColorTokens({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.error,
    required this.onError,
    required this.outline,
    required this.shadow,
  });

  /// Brand / accent color — buttons, links, active states.
  final Color primary;

  /// Content on [primary] backgrounds.
  final Color onPrimary;

  /// Secondary brand tone — less prominent accents.
  final Color secondary;

  /// Content on [secondary] backgrounds.
  final Color onSecondary;

  /// Page / scaffold background.
  final Color background;

  /// Primary text and icons on [background].
  final Color onBackground;

  /// Card and bottom-sheet backgrounds.
  final Color surface;

  /// Primary text and icons on [surface].
  final Color onSurface;

  /// Slightly elevated surfaces — input fills, chips, tags.
  final Color surfaceVariant;

  /// Muted text, secondary icons on [surfaceVariant] and [surface].
  final Color onSurfaceVariant;

  /// Error state color.
  final Color error;

  /// Content on [error] backgrounds.
  final Color onError;

  /// Borders, dividers, input outlines.
  final Color outline;

  /// Drop-shadow color.
  final Color shadow;

  @override
  List<Object?> get props => [
        primary,
        onPrimary,
        secondary,
        onSecondary,
        background,
        onBackground,
        surface,
        onSurface,
        surfaceVariant,
        onSurfaceVariant,
        error,
        onError,
        outline,
        shadow,
      ];
}

/// A named color palette that bundles light and dark [AppColorTokens].
///
/// Compared by [id] only — swapping two palettes with the same id is a no-op.
class AppColorPalette extends Equatable {
  const AppColorPalette({
    required this.id,
    required this.name,
    required this.light,
    required this.dark,
  });

  /// Stable identifier used for persistence (SharedPreferences key).
  final String id;

  /// Human-readable display name shown in settings.
  final String name;

  /// Tokens for [Brightness.light].
  final AppColorTokens light;

  /// Tokens for [Brightness.dark].
  final AppColorTokens dark;

  /// Returns the correct token set for [brightness].
  AppColorTokens tokensFor(Brightness brightness) =>
      brightness == Brightness.light ? light : dark;

  @override
  List<Object?> get props => [id];
}
