import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/router/router.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<SessionBloc>().state;
    if (sessionState case final SessionAuthenticated authenticatedState) {
      return _HomeScaffold(session: authenticatedState.session);
    }

    if (sessionState is SessionLoading || sessionState is SessionInitial) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => context.router.replace(const LoginRoute()),
          child: Text(context.l10n.loginCta),
        ),
      ),
    );
  }
}

class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold({required this.session});

  final AppSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeState = context.watch<ThemeBloc>().state;
    final sections = <Widget>[
      _InfoCard(
        title: l10n.accountSectionTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(session.user.displayName, style: context.textTheme.titleLarge),
            const Gap(AppDimensions.s8),
            Text(session.user.email),
            const Gap(AppDimensions.s8),
            Text(
              l10n.accountIdValue(session.user.id),
              style: context.textTheme.bodySmall,
            ),
            const Gap(AppDimensions.s8),
            Text(
              l10n.emailVerifiedValue(session.user.emailVerified.toString()),
              style: context.textTheme.bodySmall,
            ),
            const Gap(AppDimensions.s8),
            Text(
              l10n.passkeyEnabledValue(session.user.passkeyEnabled.toString()),
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      _InfoCard(
        title: l10n.sessionSectionTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.homeSubtitle, style: context.textTheme.bodyMedium),
            const Gap(AppDimensions.s16),
            FilledButton(
              onPressed: () => context.read<SessionBloc>().add(
                const SessionReloadRequested(),
              ),
              child: Text(l10n.refreshMeCta),
            ),
          ],
        ),
      ),
      _InfoCard(
        title: l10n.appearanceSectionTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.themeModeLabel),
            const Gap(AppDimensions.s12),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l10n.themeModeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l10n.themeModeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l10n.themeModeDark),
                ),
              ],
              selected: {themeState.themeMode},
              onSelectionChanged: (selection) => context.read<ThemeBloc>().add(
                ThemeModeChanged(selection.first),
              ),
            ),
            const Gap(AppDimensions.s16),
            Text(l10n.paletteLabel),
            const Gap(AppDimensions.s12),
            DropdownMenu<AppColorPalette>(
              initialSelection: themeState.palette,
              dropdownMenuEntries: AppColors.all
                  .map(
                    (palette) => DropdownMenuEntry(
                      value: palette,
                      label: palette.name,
                    ),
                  )
                  .toList(growable: false),
              onSelected: (palette) {
                if (palette != null) {
                  context.read<ThemeBloc>().add(ThemePaletteChanged(palette));
                }
              },
            ),
            const Gap(AppDimensions.s16),
            Text(l10n.fontScaleLabel),
            Slider(
              value: themeState.fontScale,
              min: AppTextStyles.scaleXS,
              max: AppTextStyles.scaleXL,
              divisions: 5,
              label: themeState.fontScale.toStringAsFixed(2),
              onChanged: (value) =>
                  context.read<ThemeBloc>().add(FontScaleChanged(value)),
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            onPressed: () =>
                context.read<SessionBloc>().add(const SessionReloadRequested()),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refreshMeCta,
          ),
          IconButton(
            onPressed: () async {
              context.read<SessionBloc>().add(
                const SessionSignedOutRequested(),
              );
              await context.router.replaceAll([const LoginRoute()]);
            },
            icon: const Icon(Icons.logout_rounded),
            tooltip: l10n.logoutCta,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= AppDimensions.breakpointMedium
              ? 3
              : 1;

          return GridView.builder(
            padding: context.responsiveContentPadding,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppDimensions.s16,
              mainAxisSpacing: AppDimensions.s16,
              mainAxisExtent: 280,
            ),
            itemCount: sections.length,
            itemBuilder: (context, index) => sections[index],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.child,
    required this.title,
  });

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: context.responsiveContentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: context.textTheme.titleLarge),
            const Gap(AppDimensions.s16),
            child,
          ],
        ),
      ),
    );
  }
}
