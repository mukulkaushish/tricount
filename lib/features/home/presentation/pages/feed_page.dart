import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';

@RoutePage()
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(final BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Tricount'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                tooltip: 'New group',
                onPressed: () {},
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
              vertical: AppDimensions.s16,
            ),
            sliver: SliverList.list(
              children: [
                _SummaryCard(scheme: scheme),
                const Gap(AppDimensions.s24),
                _SectionHeader(title: 'Recent groups', scheme: scheme),
                const Gap(AppDimensions.s12),
                _EmptyGroupsPlaceholder(scheme: scheme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.s20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.r16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.s12),
            decoration: BoxDecoration(
              color: scheme.onPrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppDimensions.r12),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: scheme.onPrimary,
              size: AppDimensions.iconLg,
            ),
          ),
          const Gap(AppDimensions.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are all settled up',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const Gap(AppDimensions.s4),
                Text(
                  r'$0.00',
                  style: context.textTheme.headlineMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.scheme});

  final String title;
  final ColorScheme scheme;

  @override
  Widget build(final BuildContext context) {
    return Text(
      title,
      style: context.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    );
  }
}

class _EmptyGroupsPlaceholder extends StatelessWidget {
  const _EmptyGroupsPlaceholder({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.s48,
        horizontal: AppDimensions.s24,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.r16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.groups_rounded,
            size: AppDimensions.s64,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const Gap(AppDimensions.s16),
          Text(
            'No groups yet',
            style: context.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(AppDimensions.s8),
          Text(
            'Create a group to start splitting expenses\n'
            'with friends and family.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const Gap(AppDimensions.s24),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create a group'),
          ),
        ],
      ),
    );
  }
}
