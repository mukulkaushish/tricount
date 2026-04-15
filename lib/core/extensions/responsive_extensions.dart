import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tricount/core/theme/app_dimensions.dart';

/// Semantic breakpoint helpers on [BuildContext].
///
/// Prefer these over raw `MediaQuery.sizeOf(context).width` comparisons
/// to keep layout decisions consistent with [AppDimensions] breakpoints.
extension ResponsiveContext on BuildContext {
  /// `true` when width < 600dp — phones in portrait, folded foldables.
  bool get isCompact =>
      MediaQuery.sizeOf(this).width < AppDimensions.breakpointMedium;

  /// `true` when 600dp ≤ width < 840dp — phones landscape, foldables
  /// unfolded, small tablets.
  bool get isMedium {
    final width = MediaQuery.sizeOf(this).width;
    return width >= AppDimensions.breakpointMedium &&
        width < AppDimensions.breakpointExpanded;
  }

  /// `true` when width ≥ 840dp — iPads, large tablets, desktop.
  bool get isExpanded =>
      MediaQuery.sizeOf(this).width >= AppDimensions.breakpointExpanded;

  /// `true` for any non-phone screen (Medium or Expanded).
  bool get isLargeScreen =>
      MediaQuery.sizeOf(this).width >= AppDimensions.breakpointMedium;

  /// Hinge or fold display feature if the device is a foldable, else `null`.
  DisplayFeature? get hingeFeature => MediaQuery.of(this).displayFeatures
      .where(
        (f) =>
            f.type == DisplayFeatureType.hinge ||
            f.type == DisplayFeatureType.fold,
      )
      .firstOrNull;

  /// `true` when the device is in half-opened (tabletop / book) posture.
  bool get isHalfOpened =>
      hingeFeature?.state == DisplayFeatureState.postureHalfOpened;
}
