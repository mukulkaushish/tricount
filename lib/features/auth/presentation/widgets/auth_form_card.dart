import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';

/// Animated bottom-sheet-style card that wraps an auth form.
///
/// Used on LoginPage and RegisterPage in their compact (phone)
/// layouts. Slides up with a shadow to create a sheet-over-gradient effect.
class AuthFormCard extends StatelessWidget {
  const AuthFormCard({required this.title, required this.child, super.key});

  /// Header text displayed above [child] (e.g. "Sign in", "Create account").
  final String title;

  /// The form content (e.g. AuthForm or a custom register form).
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.r28),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.12),
                blurRadius: AppDimensions.s24,
                offset: const Offset(0, -AppDimensions.s4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.pagePaddingH,
              AppDimensions.s28,
              AppDimensions.pagePaddingH,
              AppDimensions.s32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag-pill indicator — mirrors the theme bottom sheet handle.
                Center(
                  child: Container(
                    width: AppDimensions.s32,
                    height: AppDimensions.s4,
                    decoration: BoxDecoration(
                      color: scheme.outline,
                      borderRadius: BorderRadius.circular(AppDimensions.r4),
                    ),
                  ),
                ),
                const Gap(AppDimensions.s20),
                Text(
                      title,
                      style: context.textTheme.headlineSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                    .animate()
                    .fadeIn(
                      delay: const Duration(
                        milliseconds: AppDimensions.delay1,
                      ),
                      duration: const Duration(
                        milliseconds: AppDimensions.animNormal,
                      ),
                    )
                    .slideY(
                      begin: 0.1,
                      end: 0,
                      delay: const Duration(
                        milliseconds: AppDimensions.delay1,
                      ),
                      duration: const Duration(
                        milliseconds: AppDimensions.animNormal,
                      ),
                    ),
                const Gap(AppDimensions.s24),
                child,
              ],
            ),
          ),
        )
        .animate()
        .slideY(
          begin: 0.15,
          end: 0,
          duration: const Duration(milliseconds: AppDimensions.animSlow),
          curve: Curves.easeOutCubic,
        )
        .fadeIn(
          duration: const Duration(milliseconds: AppDimensions.animNormal),
        );
  }
}
