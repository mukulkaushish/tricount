import 'package:flutter/material.dart';

import 'package:tricount/core/theme/app_color_palette.dart';

sealed class ThemeEvent {
  const ThemeEvent();
}

/// Fired at app startup — reads saved preferences and restores last state.
final class ThemeRestored extends ThemeEvent {
  const ThemeRestored();
}

/// User selected a new color palette.
final class ThemePaletteChanged extends ThemeEvent {
  const ThemePaletteChanged(this.palette);
  final AppColorPalette palette;
}

/// User toggled light / dark / system mode.
final class ThemeModeChanged extends ThemeEvent {
  const ThemeModeChanged(this.mode);
  final ThemeMode mode;
}

/// User adjusted the global font scale slider.
final class FontScaleChanged extends ThemeEvent {
  const FontScaleChanged(this.scale);
  final double scale;
}
