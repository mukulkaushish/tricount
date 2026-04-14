import 'package:flutter/material.dart';

import 'package:tricount/core/theme/app_color_palette.dart';

/// All predefined [AppColorPalette] instances.
///
/// Each palette has a light and dark token set. Neutrals (backgrounds,
/// surfaces, text) follow a Slate-based scale on all palettes; only the
/// [AppColorTokens.primary] family changes per palette.
abstract final class AppColors {
  // ── Shared neutrals (light) ────────────────────────────────────────────────
  static const Color _lightBackground = Color(0xFFF8FAFC); // Slate-50
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightOnSurface = Color(0xFF0F172A); // Slate-900
  static const Color _lightSurfaceVariant = Color(0xFFF1F5F9); // Slate-100
  static const Color _lightOnSurfaceVariant = Color(0xFF64748B); // Slate-500
  static const Color _lightOutline = Color(0xFFE2E8F0); // Slate-200
  static const Color _lightShadow = Color(0x14000000); // 8 % black
  static const Color _lightError = Color(0xFFDC2626); // Red-600
  static const Color _lightOnError = Color(0xFFFFFFFF);

  // ── Shared neutrals (dark) ─────────────────────────────────────────────────
  static const Color _darkSurface = Color(0xFF141E28);
  static const Color _darkOnSurface = Color(0xFFF1F5F9); // Slate-100
  static const Color _darkSurfaceVariant = Color(0xFF1E2D3D);
  static const Color _darkOnSurfaceVariant = Color(0xFF94A3B8); // Slate-400
  static const Color _darkOutline = Color(0xFF1E2D3D);
  static const Color _darkShadow = Color(0x4D000000); // 30 % black
  static const Color _darkError = Color(0xFFEF4444); // Red-500
  static const Color _darkOnError = Color(0xFF7F1D1D);

  // ── Palette: Teal Flow ─────────────────────────────────────────────────────
  static const AppColorPalette tealFlow = AppColorPalette(
    id: 'teal',
    name: 'Teal Flow',
    light: AppColorTokens(
      primary: Color(0xFF0EA5E9), // Sky-500
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF0284C7), // Sky-600
      onSecondary: Color(0xFFFFFFFF),
      background: _lightBackground,
      onBackground: _lightOnSurface,
      surface: _lightSurface,
      onSurface: _lightOnSurface,
      surfaceVariant: _lightSurfaceVariant,
      onSurfaceVariant: _lightOnSurfaceVariant,
      error: _lightError,
      onError: _lightOnError,
      outline: _lightOutline,
      shadow: _lightShadow,
    ),
    dark: AppColorTokens(
      primary: Color(0xFF38BDF8), // Sky-400
      onPrimary: Color(0xFF0C4A6E), // Sky-950
      secondary: Color(0xFF7DD3FC), // Sky-300
      onSecondary: Color(0xFF082F49),
      background: Color(0xFF0C1117),
      onBackground: _darkOnSurface,
      surface: _darkSurface,
      onSurface: _darkOnSurface,
      surfaceVariant: _darkSurfaceVariant,
      onSurfaceVariant: _darkOnSurfaceVariant,
      error: _darkError,
      onError: _darkOnError,
      outline: _darkOutline,
      shadow: _darkShadow,
    ),
  );

  // ── Palette: Electric Indigo ───────────────────────────────────────────────
  static const AppColorPalette electricIndigo = AppColorPalette(
    id: 'indigo',
    name: 'Electric Indigo',
    light: AppColorTokens(
      primary: Color(0xFF6366F1), // Indigo-500
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF4F46E5), // Indigo-600
      onSecondary: Color(0xFFFFFFFF),
      background: Color(0xFFFAFAF9), // Stone-50
      onBackground: Color(0xFF1C1917), // Stone-900
      surface: _lightSurface,
      onSurface: Color(0xFF1C1917),
      surfaceVariant: Color(0xFFF5F3FF), // Violet-50 — slight purple tint
      onSurfaceVariant: Color(0xFF6B7280), // Gray-500
      error: _lightError,
      onError: _lightOnError,
      outline: Color(0xFFE5E7EB), // Gray-200
      shadow: _lightShadow,
    ),
    dark: AppColorTokens(
      primary: Color(0xFF818CF8), // Indigo-400
      onPrimary: Color(0xFF1E1B4B), // Indigo-950
      secondary: Color(0xFFA5B4FC), // Indigo-300
      onSecondary: Color(0xFF1E1B4B),
      background: Color(0xFF09090B), // Zinc-950
      onBackground: Color(0xFFF4F4F5),
      surface: Color(0xFF18181B), // Zinc-900
      onSurface: Color(0xFFF4F4F5),
      surfaceVariant: Color(0xFF27272A), // Zinc-800
      onSurfaceVariant: Color(0xFFA1A1AA), // Zinc-400
      error: _darkError,
      onError: _darkOnError,
      outline: Color(0xFF3F3F46), // Zinc-700
      shadow: _darkShadow,
    ),
  );

  // ── Palette: Slate Clean ───────────────────────────────────────────────────
  static const AppColorPalette slateClean = AppColorPalette(
    id: 'slate',
    name: 'Slate Clean',
    light: AppColorTokens(
      primary: Color(0xFF334155), // Slate-700
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF475569), // Slate-600
      onSecondary: Color(0xFFFFFFFF),
      background: Color(0xFFFFFFFF),
      onBackground: Color(0xFF020617), // Slate-950
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF020617),
      surfaceVariant: Color(0xFFF8FAFC), // Slate-50
      onSurfaceVariant: _lightOnSurfaceVariant,
      error: _lightError,
      onError: _lightOnError,
      outline: _lightOutline,
      shadow: _lightShadow,
    ),
    dark: AppColorTokens(
      primary: Color(0xFF94A3B8), // Slate-400
      onPrimary: Color(0xFF0F172A), // Slate-900
      secondary: Color(0xFFCBD5E1), // Slate-300
      onSecondary: Color(0xFF0F172A),
      background: Color(0xFF0F172A), // Slate-900
      onBackground: Color(0xFFF8FAFC),
      surface: Color(0xFF1E293B), // Slate-800
      onSurface: Color(0xFFF8FAFC),
      surfaceVariant: Color(0xFF283548),
      onSurfaceVariant: _darkOnSurfaceVariant,
      error: _darkError,
      onError: _darkOnError,
      outline: Color(0xFF334155), // Slate-700
      shadow: _darkShadow,
    ),
  );

  /// All palettes in display order (used by the theme picker).
  static const List<AppColorPalette> all = [
    tealFlow,
    electricIndigo,
    slateClean,
  ];

  /// Default palette used on first launch.
  static const AppColorPalette defaultPalette = tealFlow;

  /// Look up a palette by [id]. Falls back to [defaultPalette] if not found.
  static AppColorPalette fromId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => defaultPalette);
}
