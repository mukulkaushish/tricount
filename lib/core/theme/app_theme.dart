import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tricount/core/theme/app_color_palette.dart';
import 'package:tricount/core/theme/app_dimensions.dart';
import 'package:tricount/core/theme/app_text_styles.dart';

/// Factory that builds a complete [ThemeData] from an [AppColorPalette].
///
/// Every visual property for every component lives here.
/// Feature code never sets color/padding/shape/textStyle inline.
abstract final class AppTheme {
  // ── Cache ──────────────────────────────────────────────────────────────────
  // Keyed by (paletteId, brightness, fontScale, platform).
  static final Map<String, ThemeData> _cache = {};

  static String _cacheKey(
    AppColorPalette palette,
    Brightness brightness,
    double fontScale,
    TargetPlatform platform,
  ) =>
      '${palette.id}_${brightness.name}_${fontScale}_${platform.name}';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Builds (or returns cached) [ThemeData] for the given configuration.
  static ThemeData build({
    required AppColorPalette palette,
    required Brightness brightness,
    required double fontScale,
    required TargetPlatform platform,
  }) {
    final key = _cacheKey(palette, brightness, fontScale, platform);
    if (_cache.containsKey(key)) return _cache[key]!;

    final tokens = palette.tokensFor(brightness);
    final isIOS = platform == TargetPlatform.iOS ||
        platform == TargetPlatform.macOS;

    final textTheme = AppTextStyles.scaled(
      primaryColor: tokens.onSurface,
      mutedColor: tokens.onSurfaceVariant,
      scale: fontScale,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: tokens.primary,
      brightness: brightness,
    ).copyWith(
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      secondary: tokens.secondary,
      onSecondary: tokens.onSecondary,
      surface: tokens.surface,
      onSurface: tokens.onSurface,
      surfaceContainerHighest: tokens.surfaceVariant,
      onSurfaceVariant: tokens.onSurfaceVariant,
      error: tokens.error,
      onError: tokens.onError,
      outline: tokens.outline,
      shadow: tokens.shadow,
    );

    final theme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: 'Montserrat',
      scaffoldBackgroundColor: tokens.background,
      canvasColor: tokens.surface,
      shadowColor: tokens.shadow,
      dividerColor: tokens.outline,
      disabledColor: tokens.onSurface.withValues(alpha: 0.38),
      hintColor: tokens.onSurfaceVariant,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      // ── Text ──────────────────────────────────────────────────────────────
      textTheme: textTheme,
      primaryTextTheme: textTheme.apply(
        bodyColor: tokens.onPrimary,
        displayColor: tokens.onPrimary,
      ),

      // ── Icons ─────────────────────────────────────────────────────────────
      iconTheme: IconThemeData(
        color: tokens.onSurface,
        size: AppDimensions.iconMd,
      ),
      primaryIconTheme: IconThemeData(
        color: tokens.onPrimary,
        size: AppDimensions.iconMd,
      ),

      // ── Tap feedback ──────────────────────────────────────────────────────
      splashFactory: isIOS ? NoSplash.splashFactory : InkSparkle.splashFactory,
      splashColor: isIOS
          ? Colors.transparent
          : tokens.primary.withValues(alpha: 0.12),
      highlightColor: tokens.onSurface.withValues(alpha: isIOS ? 0.08 : 0.10),

      // ── Page transitions ──────────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        },
      ),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.onSurface,
        elevation: 0,
        scrolledUnderElevation: isIOS ? 0 : 3,
        surfaceTintColor: Colors.transparent,
        centerTitle: isIOS,
        toolbarHeight: isIOS
            ? AppDimensions.appBarHeightIOS
            : AppDimensions.appBarHeightAndroid,
        titleTextStyle: textTheme.titleMedium,
        iconTheme: IconThemeData(color: tokens.primary),
        actionsIconTheme: IconThemeData(color: tokens.primary),
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        // iOS hairline separator
        shape: isIOS
            ? Border(
                bottom: BorderSide(
                  color: tokens.outline,
                  width: AppDimensions.dividerIOS,
                ),
              )
            : null,
      ),

      // ── Buttons ───────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
          minimumSize: const Size(64, AppDimensions.buttonHeight),
          textStyle: textTheme.labelLarge,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s24),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
          minimumSize: const Size(64, AppDimensions.buttonHeight),
          textStyle: textTheme.labelLarge,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.onSurface,
          side: BorderSide(color: tokens.outline, width: 1.5),
          minimumSize: const Size(64, AppDimensions.buttonHeight),
          textStyle: textTheme.labelLarge,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.primary,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(AppDimensions.s48, AppDimensions.s40),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: tokens.onSurface,
          iconSize: AppDimensions.iconMd,
          padding: const EdgeInsets.all(AppDimensions.s12),
          shape: const CircleBorder(),
        ),
      ),

      // ── Input ─────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceVariant,
        hoverColor: Colors.transparent,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: tokens.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: tokens.primary,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.s16,
          vertical: AppDimensions.s16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          borderSide: BorderSide(color: tokens.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          borderSide: BorderSide(color: tokens.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          borderSide: BorderSide(color: tokens.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          borderSide: BorderSide(color: tokens.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          borderSide: BorderSide(color: tokens.error, width: 2),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: tokens.error),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: isIOS
            ? AppDimensions.elevationNone
            : AppDimensions.elevationLow,
        shadowColor: tokens.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r12),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: tokens.outline,
        thickness:
            isIOS ? AppDimensions.dividerIOS : AppDimensions.dividerAndroid,
        space: 0,
        indent: AppDimensions.s16,
        endIndent: AppDimensions.s16,
      ),

      // ── Tab bar ───────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: tokens.primary,
        unselectedLabelColor: tokens.onSurfaceVariant,
        indicatorColor: tokens.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
      ),

      // ── Navigation bar (M3) ───────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.surface,
        indicatorColor: tokens.primary.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: tokens.primary,
              size: AppDimensions.iconMd,
            );
          }
          return IconThemeData(
            color: tokens.onSurfaceVariant,
            size: AppDimensions.iconMd,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(color: tokens.primary);
          }
          return textTheme.labelSmall?.copyWith(color: tokens.onSurfaceVariant);
        }),
        height: AppDimensions.navBarHeight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // ── Bottom navigation (legacy) ────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: tokens.surface,
        selectedItemColor: tokens.primary,
        unselectedItemColor: tokens.onSurfaceVariant,
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Drawer ────────────────────────────────────────────────────────────
      drawerTheme: DrawerThemeData(
        backgroundColor: tokens.surface,
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppDimensions.r16),
            bottomRight: Radius.circular(AppDimensions.r16),
          ),
        ),
      ),

      // ── List tile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: tokens.primary.withValues(alpha: 0.08),
        selectedColor: tokens.primary,
        iconColor: tokens.onSurfaceVariant,
        textColor: tokens.onSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.s16,
          vertical: AppDimensions.s8,
        ),
        minVerticalPadding: AppDimensions.s12,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodyMedium
            ?.copyWith(color: tokens.onSurfaceVariant),
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceVariant,
        selectedColor: tokens.primary.withValues(alpha: 0.12),
        labelStyle: textTheme.labelMedium,
        shape: const StadiumBorder(),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.s12,
          vertical: AppDimensions.s6,
        ),
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.onPrimary;
          return tokens.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.primary;
          return tokens.outline;
        }),
      ),

      // ── Checkbox ──────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(tokens.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r4),
        ),
        side: BorderSide(color: tokens.onSurfaceVariant, width: 1.5),
      ),

      // ── Radio ─────────────────────────────────────────────────────────────
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.primary;
          return tokens.onSurfaceVariant;
        }),
      ),

      // ── Slider ────────────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor: tokens.primary,
        inactiveTrackColor: tokens.primary.withValues(alpha: 0.24),
        thumbColor: tokens.primary,
        overlayColor: tokens.primary.withValues(alpha: 0.12),
        trackHeight: 4,
        valueIndicatorColor: tokens.primary,
        valueIndicatorTextStyle: textTheme.labelMedium
            ?.copyWith(color: tokens.onPrimary),
      ),

      // ── Segmented button ──────────────────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return tokens.primary.withValues(alpha: 0.12);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return tokens.primary;
            return tokens.onSurfaceVariant;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: tokens.outline),
          ),
        ),
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        elevation: isIOS ? 0 : 24,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r28),
        ),
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // ── Bottom sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        modalBackgroundColor: tokens.surface,
        elevation: 0,
        modalElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.r20),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: tokens.onSurfaceVariant.withValues(alpha: 0.3),
        dragHandleSize: const Size(AppDimensions.s32, AppDimensions.s4),
      ),

      // ── Snack bar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: tokens.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r12),
        ),
        elevation: 3,
      ),

      // ── Progress indicator ────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.primary,
        linearTrackColor: tokens.primary.withValues(alpha: 0.16),
        circularTrackColor: tokens.primary.withValues(alpha: 0.16),
        strokeWidth: 3,
      ),

      // ── Tooltip ───────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppDimensions.r8),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.s12,
          vertical: AppDimensions.s8,
        ),
        waitDuration: const Duration(milliseconds: 500),
      ),

      // ── Popup menu ────────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: tokens.surface,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r8),
        ),
        textStyle: textTheme.bodyMedium,
      ),

      // ── Dropdown menu ─────────────────────────────────────────────────────
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(tokens.surface),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.r8),
            ),
          ),
          elevation: WidgetStateProperty.all(2),
        ),
        textStyle: textTheme.bodyMedium,
      ),
    );

    _cache[key] = theme;
    return theme;
  }

  /// Clears the theme cache.
  ///
  /// Call when a setting change invalidates all cached themes.
  static void clearCache() => _cache.clear();
}
