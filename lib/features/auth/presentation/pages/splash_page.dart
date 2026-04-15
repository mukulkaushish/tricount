import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/router/router.dart';

/// Entry-point screen shown while the app decides where to navigate.
///
/// Checks stored tokens synchronously — tokens are pre-loaded into memory
/// by [SecureTokenProvider.initialize] during app bootstrap.
@RoutePage()
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget; the splash page is transient.
    unawaited(_redirect());
  }

  Future<void> _redirect() async {
    // Brief delay to let the branded splash animate.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final hasToken = sl<TokenProvider>().accessToken != null;
    await context.router.replaceAll([
      if (hasToken) const HomeRoute() else const LoginRoute(),
    ]);
  }

  @override
  Widget build(final BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: AppDimensions.s64,
              color: scheme.onPrimary,
            ),
            const Gap(AppDimensions.s16),
            Text(
              'Tricount',
              style: context.textTheme.headlineLarge?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(AppDimensions.s8),
            Text(
              'Split bills, stay friends',
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimary.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
