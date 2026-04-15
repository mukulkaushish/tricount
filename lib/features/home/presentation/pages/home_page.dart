import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import 'package:tricount/core/core.dart';
import 'package:tricount/features/auth/presentation/pages/login_page.dart';

/// Temporary home screen — shown immediately after login.
///
/// Lets the user switch between color palettes, theme modes,
/// and font scale. All settings persist to SharedPreferences
/// via [ThemeBloc].
class HomePage extends StatelessWidget {
  const HomePage({required this.displayName, super.key});
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tricount'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: const _HomeBody(),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      unawaited(
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const LoginPage()),
          (_) => false,
        ),
      );
    }
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePaddingH,
        vertical: AppDimensions.s24,
      ),
      children: [
        // ── Welcome card ───────────────────────────────────────────────────
        Container(
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
                padding: const EdgeInsets.all(AppDimensions.s10),
                decoration: BoxDecoration(
                  color: scheme.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.r12),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: scheme.onPrimary,
                  size: AppDimensions.s32,
                ),
              ),
              const Gap(AppDimensions.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      'Tricount',
                      style: context.textTheme.titleLarge?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Gap(AppDimensions.s32),

        // ── Theme section ──────────────────────────────────────────────────
        Text(
          'Appearance',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(AppDimensions.s16),

        const _PalettePicker(),
        const Gap(AppDimensions.s16),
        const _ThemeModePicker(),
        const Gap(AppDimensions.s16),
        const _FontScalePicker(),
      ],
    );
  }
}

// ── Palette picker ───────────────────────────────────────────────────────────

class _PalettePicker extends StatelessWidget {
  const _PalettePicker();

  @override
  Widget build(BuildContext context) {
    final currentPaletteId = context.watch<ThemeBloc>().state.palette.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color palette',
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const Gap(AppDimensions.s10),
        Row(
          children: AppColors.all.map((palette) {
            final selected = palette.id == currentPaletteId;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppDimensions.s8),
                child: _PaletteCard(
                  palette: palette,
                  selected: selected,
                  onTap: () => context.read<ThemeBloc>().add(
                    ThemePaletteChanged(palette),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PaletteCard extends StatelessWidget {
  const _PaletteCard({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppColorPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final tokens = palette.tokensFor(brightness);
    final scheme = context.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.s12,
          horizontal: AppDimensions.s8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? tokens.primary.withValues(alpha: 0.12)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          border: Border.all(
            color: selected ? tokens.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Color swatch row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Swatch(color: tokens.primary),
                const Gap(AppDimensions.s4),
                _Swatch(color: tokens.secondary),
              ],
            ),
            const Gap(AppDimensions.s8),
            Text(
              palette.name,
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall?.copyWith(
                color: selected ? tokens.primary : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.s20,
      height: AppDimensions.s20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Theme mode picker ────────────────────────────────────────────────────────

class _ThemeModePicker extends StatelessWidget {
  const _ThemeModePicker();

  @override
  Widget build(BuildContext context) {
    final current = context.watch<ThemeBloc>().state.themeMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme mode',
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const Gap(AppDimensions.s10),
        SegmentedButton<ThemeMode>(
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
          onSelectionChanged: (selection) =>
              context.read<ThemeBloc>().add(ThemeModeChanged(selection.first)),
        ),
      ],
    );
  }
}

// ── Font scale picker ────────────────────────────────────────────────────────

class _FontScalePicker extends StatelessWidget {
  const _FontScalePicker();

  static const List<({String label, double value})> _scales = [
    (label: 'XS', value: AppTextStyles.scaleXS),
    (label: 'S', value: AppTextStyles.scaleS),
    (label: 'M', value: AppTextStyles.scaleM),
    (label: 'L', value: AppTextStyles.scaleL),
    (label: 'XL', value: AppTextStyles.scaleXL),
  ];

  @override
  Widget build(BuildContext context) {
    final current = context.watch<ThemeBloc>().state.fontScale;
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Font size',
          style: context.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const Gap(AppDimensions.s10),
        Row(
          children: _scales.map((s) {
            final selected = (current - s.value).abs() < 0.01;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppDimensions.s6),
                child: _ScaleChip(
                  label: s.label,
                  selected: selected,
                  onTap: () =>
                      context.read<ThemeBloc>().add(FontScaleChanged(s.value)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s10),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.12)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppDimensions.r8),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
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
