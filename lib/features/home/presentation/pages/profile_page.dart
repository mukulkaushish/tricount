import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/features/auth/auth.dart';
import 'package:tricount/router/router.dart';

@RoutePage()
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(final BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoggedOut) {
          unawaited(context.router.replaceAll([const LoginRoute()]));
        }
      },
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(final BuildContext context) {
    final scheme = context.colorScheme;
    final tokenProvider = sl<TokenProvider>();
    final displayName = tokenProvider.displayName ?? 'User';
    final email = tokenProvider.email ?? '';

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Profile'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
              vertical: AppDimensions.s8,
            ),
            sliver: SliverList.list(
              children: [
                _AvatarCard(
                  displayName: displayName,
                  email: email,
                  scheme: scheme,
                ),
                const Gap(AppDimensions.s24),
                _SectionLabel(label: 'Appearance', scheme: scheme),
                const Gap(AppDimensions.s12),
                _PalettePicker(scheme: scheme),
                const Gap(AppDimensions.s16),
                _ThemeModeTile(scheme: scheme),
                const Gap(AppDimensions.s16),
                _FontScaleTile(scheme: scheme),
                const Gap(AppDimensions.s32),
                _SectionLabel(label: 'Account', scheme: scheme),
                const Gap(AppDimensions.s12),
                _SignOutTile(scheme: scheme),
                const Gap(AppDimensions.s48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar card ──────────────────────────────────────────────────────────────

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({
    required this.displayName,
    required this.email,
    required this.scheme,
  });

  final String displayName;
  final String email;
  final ColorScheme scheme;

  @override
  Widget build(final BuildContext context) {
    final initials = _initials(displayName);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.s20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.r16),
      ),
      child: Row(
        children: [
          _AvatarCircle(initials: initials, scheme: scheme),
          const Gap(AppDimensions.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty) ...[
                  const Gap(AppDimensions.s2),
                  Text(
                    email,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(final String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.initials, required this.scheme});

  final String initials;
  final ColorScheme scheme;

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: AppDimensions.s64,
      height: AppDimensions.s64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: context.textTheme.titleLarge?.copyWith(
            color: scheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.scheme});

  final String label;
  final ColorScheme scheme;

  @override
  Widget build(final BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: context.textTheme.labelSmall?.copyWith(
        color: scheme.onSurfaceVariant,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ── Palette picker ───────────────────────────────────────────────────────────

class _PalettePicker extends StatelessWidget {
  const _PalettePicker({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(final BuildContext context) {
    final currentPaletteId = context.watch<ThemeBloc>().state.palette.id;
    final brightness = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.s16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_rounded,
                size: AppDimensions.iconMd,
                color: scheme.primary,
              ),
              const Gap(AppDimensions.s8),
              Text(
                'Color palette',
                style: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const Gap(AppDimensions.s16),
          Wrap(
            spacing: AppDimensions.s8,
            runSpacing: AppDimensions.s8,
            children: AppColors.all.map((palette) {
              final selected = palette.id == currentPaletteId;
              final tokens = palette.tokensFor(brightness);
              return _PaletteChip(
                palette: palette,
                tokens: tokens,
                selected: selected,
                onTap: () =>
                    context.read<ThemeBloc>().add(ThemePaletteChanged(palette)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PaletteChip extends StatelessWidget {
  const _PaletteChip({
    required this.palette,
    required this.tokens,
    required this.selected,
    required this.onTap,
  });

  final AppColorPalette palette;
  final AppColorTokens tokens;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final scheme = context.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.s12,
          vertical: AppDimensions.s8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? tokens.primary.withValues(alpha: 0.12)
              : scheme.surface,
          borderRadius: BorderRadius.circular(AppDimensions.rFull),
          border: Border.all(
            color: selected ? tokens.primary : scheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ColorDot(color: tokens.primary),
            const Gap(AppDimensions.s4),
            _ColorDot(color: tokens.secondary),
            const Gap(AppDimensions.s8),
            Text(
              palette.name,
              style: context.textTheme.labelMedium?.copyWith(
                color: selected ? tokens.primary : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: AppDimensions.s16,
      height: AppDimensions.s16,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Theme mode tile ──────────────────────────────────────────────────────────

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(final BuildContext context) {
    final current = context.watch<ThemeBloc>().state.themeMode;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.s16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.brightness_6_rounded,
                size: AppDimensions.iconMd,
                color: scheme.primary,
              ),
              const Gap(AppDimensions.s8),
              Text(
                'Theme mode',
                style: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const Gap(AppDimensions.s12),
          SegmentedButton<ThemeMode>(
            expandedInsets: EdgeInsets.zero,
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_rounded),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Auto'),
                icon: Icon(Icons.brightness_auto_rounded),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_rounded),
              ),
            ],
            selected: {current},
            onSelectionChanged: (selection) => context.read<ThemeBloc>().add(
              ThemeModeChanged(selection.first),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Font scale tile ──────────────────────────────────────────────────────────

class _FontScaleTile extends StatelessWidget {
  const _FontScaleTile({required this.scheme});

  final ColorScheme scheme;

  static const List<({String label, double value})> _scales = [
    (label: 'XS', value: AppTextStyles.scaleXS),
    (label: 'S', value: AppTextStyles.scaleS),
    (label: 'M', value: AppTextStyles.scaleM),
    (label: 'L', value: AppTextStyles.scaleL),
    (label: 'XL', value: AppTextStyles.scaleXL),
  ];

  @override
  Widget build(final BuildContext context) {
    final current = context.watch<ThemeBloc>().state.fontScale;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.s16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_fields_rounded,
                size: AppDimensions.iconMd,
                color: scheme.primary,
              ),
              const Gap(AppDimensions.s8),
              Text(
                'Font size',
                style: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const Gap(AppDimensions.s12),
          Row(
            children: _scales.map((s) {
              final selected = (current - s.value).abs() < 0.01;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppDimensions.s6),
                  child: _ScaleChip(
                    label: s.label,
                    selected: selected,
                    onTap: () => context.read<ThemeBloc>().add(
                      FontScaleChanged(s.value),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ScaleChip extends StatelessWidget {
  const _ScaleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final scheme = context.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s10),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.12)
              : scheme.surface,
          borderRadius: BorderRadius.circular(AppDimensions.r8),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sign out tile ────────────────────────────────────────────────────────────

class _SignOutTile extends StatelessWidget {
  const _SignOutTile({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(final BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) =>
          current is AuthLoading || previous is AuthLoading,
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Container(
          decoration: BoxDecoration(
            color: scheme.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppDimensions.r16),
            border: Border.all(
              color: scheme.error.withValues(alpha: 0.2),
            ),
          ),
          child: ListTile(
            leading: Icon(
              Icons.logout_rounded,
              color: scheme.error,
            ),
            title: Text(
              'Sign out',
              style: context.textTheme.bodyLarge?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: isLoading
                ? SizedBox.square(
                    dimension: AppDimensions.iconMd,
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.error),
                    ),
                  )
                : Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.error.withValues(alpha: 0.6),
                  ),
            onTap: isLoading ? null : () => _onSignOut(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.r16),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSignOut(final BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: context.colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const LogoutRequested());
    }
  }
}
