import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:tricount/core/theme/app_color_palette.dart';
import 'package:tricount/core/theme/app_colors.dart';
import 'package:tricount/core/theme/app_text_styles.dart';
import 'package:tricount/core/theme/app_theme.dart';

class ThemeState extends Equatable {
  const ThemeState({
    required this.palette,
    required this.themeMode,
    required this.fontScale,
    required this.lightTheme,
    required this.darkTheme,
  });

  /// Constructs the default state using [AppColors.defaultPalette].
  factory ThemeState.initial() {
    const palette = AppColors.defaultPalette;
    const platform = TargetPlatform.android; // overridden at runtime
    return ThemeState(
      palette: palette,
      themeMode: ThemeMode.system,
      fontScale: AppTextStyles.scaleM,
      lightTheme: AppTheme.build(
        palette: palette,
        brightness: Brightness.light,
        fontScale: AppTextStyles.scaleM,
        platform: platform,
      ),
      darkTheme: AppTheme.build(
        palette: palette,
        brightness: Brightness.dark,
        fontScale: AppTextStyles.scaleM,
        platform: platform,
      ),
    );
  }

  final AppColorPalette palette;
  final ThemeMode themeMode;
  final double fontScale;
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  ThemeState copyWith({
    AppColorPalette? palette,
    ThemeMode? themeMode,
    double? fontScale,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
  }) => ThemeState(
    palette: palette ?? this.palette,
    themeMode: themeMode ?? this.themeMode,
    fontScale: fontScale ?? this.fontScale,
    lightTheme: lightTheme ?? this.lightTheme,
    darkTheme: darkTheme ?? this.darkTheme,
  );

  @override
  List<Object?> get props => [
    palette,
    themeMode,
    fontScale,
    lightTheme,
    darkTheme,
  ];
}
