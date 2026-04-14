import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tricount/core/theme/app_color_palette.dart';
import 'package:tricount/core/theme/app_dimensions.dart';
import 'package:tricount/core/theme/theme_bloc/theme_bloc.dart';

/// Convenience extensions on [BuildContext] for theme access.
///
/// Use these instead of the verbose [Theme.of(context).xxx] pattern.
extension ThemeContextExtensions on BuildContext {
  /// The active [ColorScheme] — shorthand for [Theme.of(context).colorScheme].
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// The active [TextTheme] — shorthand for [Theme.of(context).textTheme].
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// The active [AppColorPalette] tokens from [ThemeBloc].
  ///
  /// Returns semantic tokens for the current brightness directly.
  /// Use for palette-specific colors not mapped to [ColorScheme] roles.
  AppColorTokens get appColors {
    final state = read<ThemeBloc>().state;
    final brightness = Theme.of(this).brightness;
    return state.palette.tokensFor(brightness);
  }
}

/// Responsive design helpers on [BuildContext].
///
/// Use to adapt layout and padding based on screen size and device posture.
extension ResponsiveContextExtensions on BuildContext {
  /// The current screen width in logical pixels.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// The current screen height in logical pixels.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// True if screen width < 600dp (Compact: phones in portrait).
  bool get isCompact => screenWidth < AppDimensions.breakpointCompact;

  /// True if 600dp ≤ width < 840dp (Medium: tablets, large phones landscape).
  bool get isMedium =>
      screenWidth >= AppDimensions.breakpointCompact &&
      screenWidth < AppDimensions.breakpointMedium;

  /// True if width ≥ 840dp (Expanded: large tablets, desktop).
  bool get isExpanded => screenWidth >= AppDimensions.breakpointMedium;

  /// True if width ≥ 1200dp (Large: very wide displays).
  bool get isLarge => screenWidth >= AppDimensions.breakpointExpanded;

  /// Responsive horizontal padding based on breakpoint.
  double get responsivePaddingH {
    if (isCompact) return AppDimensions.paddingCompactH;
    if (isMedium) return AppDimensions.paddingMediumH;
    return AppDimensions.paddingExpandedH;
  }

  /// Responsive vertical padding based on breakpoint.
  double get responsivePaddingV {
    if (isCompact) return AppDimensions.s12;
    if (isMedium) return AppDimensions.s16;
    return AppDimensions.s24;
  }

  /// Responsive EdgeInsets combining horizontal and vertical padding.
  EdgeInsets get responsiveContentPadding => EdgeInsets.symmetric(
    horizontal: responsivePaddingH,
    vertical: responsivePaddingV,
  );

  /// Checks for foldable device with hinge/fold in half-opened state.
  ///
  /// Returns true if the device has a display feature (hinge or fold)
  /// and is in a half-opened posture (tabletop or book mode).
  bool get hasActiveFold {
    final features = MediaQuery.displayFeaturesOf(this);
    return features.any(
      (f) =>
          (f.type == DisplayFeatureType.hinge ||
              f.type == DisplayFeatureType.fold) &&
          f.state == DisplayFeatureState.postureHalfOpened,
    );
  }

  /// Gets the bounding box of the hinge/fold if present.
  ///
  /// Used to avoid placing critical UI elements directly on the crease.
  Rect? get foldBounds {
    final features = MediaQuery.displayFeaturesOf(this);
    for (final feature in features) {
      if (feature.type == DisplayFeatureType.hinge ||
          feature.type == DisplayFeatureType.fold) {
        return feature.bounds;
      }
    }
    return null;
  }

  /// Safe padding below the hinge (for content that should be below it).
  EdgeInsets get hingeAwarePadding {
    final bounds = foldBounds;
    if (bounds == null) return EdgeInsets.zero;
    return EdgeInsets.only(top: bounds.bottom);
  }
}
