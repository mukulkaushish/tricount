import 'package:flutter/widgets.dart';
import 'package:tricount/core/theme/app_dimensions.dart';

/// Builds different widget trees based on the current screen width.
///
/// Uses the project's standard breakpoints from [AppDimensions]:
/// - **Compact** (< 600dp): phones in portrait, folded foldables
/// - **Medium** (600–840dp): foldables unfolded, small tablets
/// - **Expanded** (≥ 840dp): iPads, large tablets
///
/// Falls back to [compact] when a more-specific builder is not provided.
///
/// Example:
/// ```dart
/// AdaptiveLayout(
///   compact: const _PhoneLayout(),
///   expanded: const _TabletLayout(),
/// )
/// ```
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    required this.compact,
    super.key,
    this.medium,
    this.expanded,
  });

  /// Layout for phones in portrait and folded foldables (< 600dp).
  final Widget compact;

  /// Layout for foldables unfolded and small tablets (600–840dp).
  /// Falls back to [compact] when omitted.
  final Widget? medium;

  /// Layout for iPads and large tablets (≥ 840dp).
  /// Falls back to [medium] then [compact] when omitted.
  final Widget? expanded;

  @override
  Widget build(final BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= AppDimensions.breakpointExpanded) {
          return expanded ?? medium ?? compact;
        }
        if (width >= AppDimensions.breakpointMedium) {
          return medium ?? compact;
        }
        return compact;
      },
    );
  }
}
