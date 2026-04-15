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

  // ── Palette: Rose Glow ────────────────────────────────────────────────────
  static const AppColorPalette roseGlow = AppColorPalette(
    id: 'rose',
    name: 'Rose Glow',
    light: AppColorTokens(
      primary: Color(0xFFF43F5E), // Rose-500
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFFE11D48), // Rose-600
      onSecondary: Color(0xFFFFFFFF),
      background: Color(0xFFFFF1F2), // Rose-50
      onBackground: Color(0xFF1C0B0E),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1C0B0E),
      surfaceVariant: Color(0xFFFFE4E6), // Rose-100
      onSurfaceVariant: Color(0xFF9F1239), // Rose-800
      error: _lightError,
      onError: _lightOnError,
      outline: Color(0xFFFECDD3), // Rose-200
      shadow: _lightShadow,
    ),
    dark: AppColorTokens(
      primary: Color(0xFFFB7185), // Rose-400
      onPrimary: Color(0xFF4C0519), // Rose-950
      secondary: Color(0xFFFDA4AF), // Rose-300
      onSecondary: Color(0xFF4C0519),
      background: Color(0xFF0E0406),
      onBackground: Color(0xFFFFF1F2),
      surface: Color(0xFF1A0810),
      onSurface: Color(0xFFFFF1F2),
      surfaceVariant: Color(0xFF2D0F1B),
      onSurfaceVariant: Color(0xFFFDA4AF),
      error: _darkError,
      onError: _darkOnError,
      outline: Color(0xFF3D1223),
      shadow: _darkShadow,
    ),
  );

  // ── Palette: Emerald Grove ────────────────────────────────────────────────
  static const AppColorPalette emeraldGrove = AppColorPalette(
    id: 'emerald',
    name: 'Emerald Grove',
    light: AppColorTokens(
      primary: Color(0xFF10B981), // Emerald-500
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF059669), // Emerald-600
      onSecondary: Color(0xFFFFFFFF),
      background: Color(0xFFF0FDF4), // Green-50
      onBackground: Color(0xFF052E16), // Green-950
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF052E16),
      surfaceVariant: Color(0xFFDCFCE7), // Green-100
      onSurfaceVariant: Color(0xFF166534), // Green-800
      error: _lightError,
      onError: _lightOnError,
      outline: Color(0xFFBBF7D0), // Green-200
      shadow: _lightShadow,
    ),
    dark: AppColorTokens(
      primary: Color(0xFF34D399), // Emerald-400
      onPrimary: Color(0xFF022C22), // Emerald-950
      secondary: Color(0xFF6EE7B7), // Emerald-300
      onSecondary: Color(0xFF022C22),
      background: Color(0xFF020C06),
      onBackground: Color(0xFFF0FDF4),
      surface: Color(0xFF06180F),
      onSurface: Color(0xFFF0FDF4),
      surfaceVariant: Color(0xFF0A2818),
      onSurfaceVariant: Color(0xFF6EE7B7),
      error: _darkError,
      onError: _darkOnError,
      outline: Color(0xFF103D22),
      shadow: _darkShadow,
    ),
  );

  // ── Palette: Amber Glow ───────────────────────────────────────────────────
  static const AppColorPalette amberGlow = AppColorPalette(
    id: 'amber',
    name: 'Amber Glow',
    light: AppColorTokens(
      primary: Color(0xFFF59E0B), // Amber-500
      onPrimary: Color(0xFF000000),
      secondary: Color(0xFFD97706), // Amber-600
      onSecondary: Color(0xFFFFFFFF),
      background: Color(0xFFFFFBEB), // Amber-50
      onBackground: Color(0xFF1C1100),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1C1100),
      surfaceVariant: Color(0xFFFEF3C7), // Amber-100
      onSurfaceVariant: Color(0xFF92400E), // Amber-800
      error: _lightError,
      onError: _lightOnError,
      outline: Color(0xFFFDE68A), // Amber-200
      shadow: _lightShadow,
    ),
    dark: AppColorTokens(
      primary: Color(0xFFFBBF24), // Amber-400
      onPrimary: Color(0xFF1C1100),
      secondary: Color(0xFFFCD34D), // Amber-300
      onSecondary: Color(0xFF1C1100),
      background: Color(0xFF0D0900),
      onBackground: Color(0xFFFFFBEB),
      surface: Color(0xFF1A1200),
      onSurface: Color(0xFFFFFBEB),
      surfaceVariant: Color(0xFF2A1E00),
      onSurfaceVariant: Color(0xFFFCD34D),
      error: _darkError,
      onError: _darkOnError,
      outline: Color(0xFF3D2C00),
      shadow: _darkShadow,
    ),
  );

  // ── Palette: Purple Dusk ──────────────────────────────────────────────────
  static const AppColorPalette purpleDusk = AppColorPalette(
    id: 'purple',
    name: 'Purple Dusk',
    light: AppColorTokens(
      primary: Color(0xFFA855F7), // Purple-500
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF9333EA), // Purple-600
      onSecondary: Color(0xFFFFFFFF),
      background: Color(0xFFFAF5FF), // Purple-50
      onBackground: Color(0xFF1A0533),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1A0533),
      surfaceVariant: Color(0xFFF3E8FF), // Purple-100
      onSurfaceVariant: Color(0xFF6B21A8), // Purple-800
      error: _lightError,
      onError: _lightOnError,
      outline: Color(0xFFE9D5FF), // Purple-200
      shadow: _lightShadow,
    ),
    dark: AppColorTokens(
      primary: Color(0xFFC084FC), // Purple-400
      onPrimary: Color(0xFF1A0533),
      secondary: Color(0xFFD8B4FE), // Purple-300
      onSecondary: Color(0xFF1A0533),
      background: Color(0xFF0A0114),
      onBackground: Color(0xFFFAF5FF),
      surface: Color(0xFF130222),
      onSurface: Color(0xFFFAF5FF),
      surfaceVariant: Color(0xFF1E0535),
      onSurfaceVariant: Color(0xFFD8B4FE),
      error: _darkError,
      onError: _darkOnError,
      outline: Color(0xFF300A55),
      shadow: _darkShadow,
    ),
  );

  // ── Palette: Cyan Wave ────────────────────────────────────────────────────
  static const AppColorPalette cyanWave = AppColorPalette(
    id: 'cyan',
    name: 'Cyan Wave',
    light: AppColorTokens(
      primary: Color(0xFF06B6D4), // Cyan-500
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF0891B2), // Cyan-600
      onSecondary: Color(0xFFFFFFFF),
      background: Color(0xFFECFEFF), // Cyan-50
      onBackground: Color(0xFF00151C),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF00151C),
      surfaceVariant: Color(0xFFCFFAFE), // Cyan-100
      onSurfaceVariant: Color(0xFF155E75), // Cyan-800
      error: _lightError,
      onError: _lightOnError,
      outline: Color(0xFFA5F3FC), // Cyan-200
      shadow: _lightShadow,
    ),
    dark: AppColorTokens(
      primary: Color(0xFF22D3EE), // Cyan-400
      onPrimary: Color(0xFF00151C),
      secondary: Color(0xFF67E8F9), // Cyan-300
      onSecondary: Color(0xFF00151C),
      background: Color(0xFF000C10),
      onBackground: Color(0xFFECFEFF),
      surface: Color(0xFF001820),
      onSurface: Color(0xFFECFEFF),
      surfaceVariant: Color(0xFF002633),
      onSurfaceVariant: Color(0xFF67E8F9),
      error: _darkError,
      onError: _darkOnError,
      outline: Color(0xFF003B4D),
      shadow: _darkShadow,
    ),
  );

  /// All palettes in display order (used by the theme picker).
  static const List<AppColorPalette> all = [
    tealFlow,
    electricIndigo,
    slateClean,
    roseGlow,
    emeraldGrove,
    amberGlow,
    purpleDusk,
    cyanWave,
  ];

  /// Default palette used on first launch.
  static const AppColorPalette defaultPalette = tealFlow;

  /// Look up a palette by [id]. Falls back to [defaultPalette] if not found.
  static AppColorPalette fromId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => defaultPalette);
}
