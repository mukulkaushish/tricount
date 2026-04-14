import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tricount/core/theme/app_color_palette.dart';
import 'package:tricount/core/theme/theme_bloc/theme_bloc.dart';

/// Convenience extensions on [BuildContext] for theme access.
///
/// Use these instead of the verbose [Theme.of(context).xxx] pattern.
/// Three extensions only — see [docs/05_THEMING_SYSTEM.md].
extension ThemeContextExtensions on BuildContext {
  /// The active [ColorScheme] — shorthand for [Theme.of(context).colorScheme].
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// The active [TextTheme] — shorthand for [Theme.of(context).textTheme].
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// The active [AppColorPalette] tokens from [ThemeBloc].
  ///
  /// Returns semantic tokens for the current brightness directly.
  /// Use for palette-specific colors not mapped to [ColorScheme] roles.
  AppColorTokens get appColors {
    final state = read<ThemeBloc>().state;
    final brightness = Theme.of(this).brightness;
    return state.palette.tokensFor(brightness);
  }
}
