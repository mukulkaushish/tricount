import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/features/auth/presentation/widgets/auth_branding_section.dart';

/// Compact (phone) auth layout: gradient fills the top half of the screen,
/// branding sits in the upper 30%, and [formCard] slides up from the bottom.
///
/// Used by LoginPage and RegisterPage.
class AuthCompactLayout extends StatelessWidget {
  const AuthCompactLayout({required this.formCard, super.key});

  /// The form card widget positioned at the bottom (e.g. AuthFormCard).
  final Widget formCard;

  @override
  Widget build(final BuildContext context) {
    final scheme = context.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: size.height * AppDimensions.authGradientFraction,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primary, scheme.secondary],
              ),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height - topPadding,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: size.height * AppDimensions.authBrandingFraction,
                    child: const Center(child: AuthBrandingSection()),
                  ),
                  formCard,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Expanded (tablet / desktop) auth layout: left panel shows the gradient +
/// branding; right panel shows a scrollable form with title, subtitle,
/// and formContent.
///
/// Used by LoginPage and RegisterPage.
class AuthExpandedLayout extends StatelessWidget {
  const AuthExpandedLayout({
    required this.title,
    required this.subtitle,
    required this.formContent,
    super.key,
  });

  /// Form panel heading (e.g. "Sign in", "Create account").
  final String title;

  /// Form panel sub-heading (e.g. "Split bills, stay friends.").
  final String subtitle;

  /// The actual form widget placed below the title/subtitle.
  final Widget formContent;

  @override
  Widget build(final BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      children: [
        // Left panel — gradient + branding
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primary, scheme.secondary],
              ),
            ),
            child: const SafeArea(
              child: Center(child: AuthBrandingSection()),
            ),
          ),
        ),
        // Right panel — scrollable form
        Expanded(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.s32,
                  vertical: AppDimensions.s32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppDimensions.contentMaxWidth,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Gap(AppDimensions.s8),
                      Text(
                        subtitle,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const Gap(AppDimensions.s32),
                      formContent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
