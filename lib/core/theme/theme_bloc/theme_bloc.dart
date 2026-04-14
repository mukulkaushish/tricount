import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tricount/core/theme/app_color_palette.dart';
import 'package:tricount/core/theme/app_colors.dart';
import 'package:tricount/core/theme/app_text_styles.dart';
import 'package:tricount/core/theme/app_theme.dart';
import 'package:tricount/core/theme/theme_bloc/theme_event.dart';
import 'package:tricount/core/theme/theme_bloc/theme_state.dart';

export 'package:tricount/core/theme/theme_bloc/theme_event.dart';
export 'package:tricount/core/theme/theme_bloc/theme_state.dart';

// ── SharedPreferences keys ───────────────────────────────────────────────────
const _kPaletteId = 'theme_palette_id';
const _kThemeMode = 'theme_mode';
const _kFontScale = 'font_scale';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc({
    required SharedPreferences prefs,
    required TargetPlatform platform,
  })  : _prefs = prefs,
        _platform = platform,
        super(ThemeState.initial()) {
    on<ThemeRestored>(_onRestored);
    on<ThemePaletteChanged>(_onPaletteChanged);
    on<ThemeModeChanged>(_onModeChanged);
    on<FontScaleChanged>(_onFontScaleChanged);
  }

  final SharedPreferences _prefs;
  final TargetPlatform _platform;

  // ── Handlers ─────────────────────────────────────────────────────────────

  void _onRestored(ThemeRestored event, Emitter<ThemeState> emit) {
    final paletteId = _prefs.getString(_kPaletteId);
    final themeModeStr = _prefs.getString(_kThemeMode);
    final fontScale =
        _prefs.getDouble(_kFontScale) ?? AppTextStyles.scaleM;

    final palette = paletteId != null
        ? AppColors.fromId(paletteId)
        : AppColors.defaultPalette;
    final themeMode = _themeModeFromString(themeModeStr);

    emit(_buildState(
      palette: palette,
      themeMode: themeMode,
      fontScale: fontScale,
    ));
  }

  void _onPaletteChanged(
    ThemePaletteChanged event,
    Emitter<ThemeState> emit,
  ) {
    unawaited(_prefs.setString(_kPaletteId, event.palette.id));
    emit(
      _buildState(
        palette: event.palette,
        themeMode: state.themeMode,
        fontScale: state.fontScale,
      ),
    );
  }

  void _onModeChanged(
    ThemeModeChanged event,
    Emitter<ThemeState> emit,
  ) {
    unawaited(_prefs.setString(_kThemeMode, event.mode.name));
    emit(
      _buildState(
        palette: state.palette,
        themeMode: event.mode,
        fontScale: state.fontScale,
      ),
    );
  }

  void _onFontScaleChanged(
    FontScaleChanged event,
    Emitter<ThemeState> emit,
  ) {
    unawaited(_prefs.setDouble(_kFontScale, event.scale));
    emit(
      _buildState(
        palette: state.palette,
        themeMode: state.themeMode,
        fontScale: event.scale,
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  ThemeState _buildState({
    required AppColorPalette palette,
    required ThemeMode themeMode,
    required double fontScale,
  }) =>
      ThemeState(
        palette: palette,
        themeMode: themeMode,
        fontScale: fontScale,
        lightTheme: AppTheme.build(
          palette: palette,
          brightness: Brightness.light,
          fontScale: fontScale,
          platform: _platform,
        ),
        darkTheme: AppTheme.build(
          palette: palette,
          brightness: Brightness.dark,
          fontScale: fontScale,
          platform: _platform,
        ),
      );

  static ThemeMode _themeModeFromString(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
