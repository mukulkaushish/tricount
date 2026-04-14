import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/features/auth/presentation/pages/login_page.dart';

/// Entry-point screen shown while the app decides where to navigate.
///
/// Checks stored tokens and redirects to [LoginPage] (unauthenticated)
/// or the home screen (authenticated). Token persistence is a Phase 2 task —
/// for now the splash always lands on the login page.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_redirect());
  }

  Future<void> _redirect() async {
    final tokenProvider = sl<TokenProvider>();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    if (tokenProvider.accessToken != null) {
      // TODO(auth): navigate to home when token is valid
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: AppDimensions.s40 * 2,
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
          ],
        ),
      ),
    );
  }
}
