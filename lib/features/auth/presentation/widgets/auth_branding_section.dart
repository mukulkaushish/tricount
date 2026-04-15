import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';

/// Animated brand mark shown in the gradient panel of auth screens.
///
/// Displays the app icon, name, and tagline with entrance animations.
/// Used on both the login and register pages.
class AuthBrandingSection extends StatelessWidget {
  const AuthBrandingSection({super.key});

  @override
  Widget build(final BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
              width: AppDimensions.logoContainerSize,
              height: AppDimensions.logoContainerSize,
              decoration: BoxDecoration(
                color: scheme.onPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(
                  AppDimensions.logoContainerRadius,
                ),
                border: Border.all(
                  color: scheme.onPrimary.withValues(alpha: 0.25),
                  width: AppDimensions.borderThin,
                ),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: AppDimensions.s40,
                color: scheme.onPrimary,
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            ),
        const Gap(AppDimensions.s16),
        Text(
              'Tricount',
              style: context.textTheme.headlineLarge?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            )
            .animate()
            .fadeIn(delay: 100.ms, duration: 400.ms)
            .slideY(begin: 0.2, end: 0, delay: 100.ms, duration: 400.ms),
        const Gap(AppDimensions.s8),
        Text(
          'Split bills, stay friends',
          style: context.textTheme.bodyMedium?.copyWith(
            color: scheme.onPrimary.withValues(alpha: 0.75),
          ),
        ).animate().fadeIn(delay: 180.ms, duration: 400.ms),
      ],
    );
  }
}
