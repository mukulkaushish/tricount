import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tricount/features/auth/presentation/widgets/auth_form.dart';
import 'package:tricount/features/home/home.dart';
import 'package:tricount/shared/shared.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(final BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(final BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          unawaited(
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => const HomePage(displayName: 'there'),
              ),
            ),
          );
        }
      },
      child: KeyboardDismisser(
        gestures: const [
          GestureType.onTap,
          GestureType.onPanUpdateDownDirection,
          GestureType.onPanUpdateUpDirection,
        ],
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: context.colorScheme.surface,
          body: const AdaptiveLayout(
            compact: _CompactLoginLayout(),
            expanded: _ExpandedLoginLayout(),
          ),
        ),
      ),
    );
  }
}

// ── Compact layout ───────────────────────────────────────────────────────────

class _CompactLoginLayout extends StatelessWidget {
  const _CompactLoginLayout();

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
          height: size.height * 0.50,
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
              constraints: BoxConstraints(minHeight: size.height - topPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: size.height * 0.30,
                    child: const Center(child: _BrandingSection()),
                  ),
                  const _FormCard(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Expanded layout ──────────────────────────────────────────────────────────

class _ExpandedLoginLayout extends StatelessWidget {
  const _ExpandedLoginLayout();

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
              child: Center(child: _BrandingSection()),
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
                        'Sign in',
                        style: context.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Gap(AppDimensions.s8),
                      Text(
                        'Split bills, stay friends.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const Gap(AppDimensions.s32),
                      const AuthForm(),
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

// ── Branding ─────────────────────────────────────────────────────────────────

class _BrandingSection extends StatelessWidget {
  const _BrandingSection();

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
                  width: 1.5,
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

// ── Form card ────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard();

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
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, -4),
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
                      'Sign in',
                      style: context.textTheme.headlineSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 50.ms, duration: 350.ms)
                    .slideY(
                      begin: 0.1,
                      end: 0,
                      delay: 50.ms,
                      duration: 350.ms,
                    ),
                const Gap(AppDimensions.s24),
                const AuthForm(),
              ],
            ),
          ),
        )
        .animate()
        .slideY(
          begin: 0.15,
          end: 0,
          duration: 450.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 350.ms);
  }
}
