import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({
    required this.children,
    required this.subtitle,
    required this.title,
    super.key,
  });

  final List<Widget> children;
  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.breakpointCompact,
        ),
        child: Card(
          child: Padding(
            padding: context.responsiveContentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: context.textTheme.headlineSmall),
                const Gap(AppDimensions.s8),
                Text(subtitle, style: context.textTheme.bodyMedium),
                const Gap(AppDimensions.s24),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
