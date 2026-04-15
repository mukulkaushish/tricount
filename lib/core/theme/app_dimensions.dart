/// App-wide spacing, radius, elevation, and sizing constants.
///
/// Every widget that needs a numeric measurement reads from here.
/// No magic numbers in feature code.
abstract final class AppDimensions {
  // ── Spacing ────────────────────────────────────────────────────────────────
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s56 = 56;
  static const double s64 = 64;
  static const double s72 = 72;
  static const double s80 = 80;
  static const double s96 = 96;

  // ── Border radius ──────────────────────────────────────────────────────────
  static const double r4 = 4;
  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;
  static const double r28 = 28;
  static const double r32 = 32;

  /// Full pill / stadium shape.
  static const double rFull = 999;

  // ── Component heights ──────────────────────────────────────────────────────
  /// Primary CTA and social login button height.
  static const double buttonHeight = 52;

  /// Text field / input height.
  static const double inputHeight = 52;

  /// iOS AppBar toolbar height (matches UINavigationBar).
  static const double appBarHeightIOS = 44;

  /// Android AppBar toolbar height.
  static const double appBarHeightAndroid = 56;

  /// Material 3 NavigationBar height.
  static const double navBarHeight = 72;

  // ── Icon sizes ─────────────────────────────────────────────────────────────
  static const double iconSm = 18;
  static const double iconMd = 24;
  static const double iconLg = 32;

  // ── Logo / branding ────────────────────────────────────────────────────────
  /// App icon container size on the login screen.
  static const double logoContainerSize = 72;

  /// Corner radius of the app icon container.
  static const double logoContainerRadius = 20;

  // ── Elevation ──────────────────────────────────────────────────────────────
  static const double elevationNone = 0;
  static const double elevationLow = 1;
  static const double elevationMedium = 3;
  static const double elevationHigh = 6;

  // ── Divider thickness ──────────────────────────────────────────────────────
  /// iOS hairline divider (matches UIKit separator).
  static const double dividerIOS = 0.5;

  /// Android material divider.
  static const double dividerAndroid = 1;

  // ── Page padding ───────────────────────────────────────────────────────────
  static const double pagePaddingH = 24;
  static const double pagePaddingV = 16;

  // ── Responsive breakpoints ────────────────────────────────────────────────
  /// Compact → Medium breakpoint (foldables unfolded, small tablets).
  static const double breakpointMedium = 600;

  /// Medium → Expanded breakpoint (iPads, large tablets, desktop).
  static const double breakpointExpanded = 840;

  /// Maximum content width on Expanded screens (readable line length).
  static const double contentMaxWidth = 560;

  /// Minimum panel width in List-Detail layout.
  static const double panelMinWidth = 320;
}
