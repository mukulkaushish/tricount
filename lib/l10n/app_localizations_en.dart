// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Tricount';

  @override
  String get authTitle => 'Welcome back';

  @override
  String get authSubtitle => 'Sign in to keep your group expenses in sync.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get displayNameHint => 'Your name';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get confirmPasswordHint => 'Repeat your password';

  @override
  String get loginCta => 'Sign in';

  @override
  String get registerCta => 'Create account';

  @override
  String get forgotPasswordCta => 'Forgot password?';

  @override
  String get sendOtpCta => 'Send email OTP';

  @override
  String get resetPasswordCta => 'Reset password';

  @override
  String get passkeyCta => 'Use passkey';

  @override
  String get googleLoginCta => 'Continue with Google';

  @override
  String get appleLoginCta => 'Continue with Apple';

  @override
  String get switchToRegister => 'Create a new account';

  @override
  String get switchToLogin => 'Already have an account? Sign in';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle =>
      'Start tracking shared expenses with your group.';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordSubtitle =>
      'Request an email OTP and use it to set a new password.';

  @override
  String get otpCodeLabel => 'OTP code';

  @override
  String get otpCodeHint => '6-digit code';

  @override
  String get passwordResetOtpSent => 'We sent an OTP to your email.';

  @override
  String get passwordResetSuccess => 'Your password has been reset.';

  @override
  String get homeTitle => 'Your session';

  @override
  String get homeSubtitle =>
      'This screen is driven by the authenticated `me` response.';

  @override
  String get accountSectionTitle => 'Account';

  @override
  String get sessionSectionTitle => 'Session';

  @override
  String get appearanceSectionTitle => 'Appearance';

  @override
  String accountIdValue(Object id) {
    return 'ID: $id';
  }

  @override
  String emailVerifiedValue(Object value) {
    return 'Email verified: $value';
  }

  @override
  String passkeyEnabledValue(Object value) {
    return 'Passkey enabled: $value';
  }

  @override
  String get logoutCta => 'Log out';

  @override
  String get refreshMeCta => 'Refresh details';

  @override
  String get themeModeLabel => 'Theme mode';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get paletteLabel => 'Palette';

  @override
  String get fontScaleLabel => 'Font size';

  @override
  String get emailValidationRequired => 'Enter your email address.';

  @override
  String get emailValidationInvalid => 'Enter a valid email address.';

  @override
  String get passwordValidationRequired => 'Enter your password.';

  @override
  String get passwordValidationShort =>
      'Password must be at least 8 characters.';

  @override
  String get displayNameValidationRequired => 'Enter your display name.';

  @override
  String get confirmPasswordValidationRequired => 'Confirm your password.';

  @override
  String get confirmPasswordValidationMismatch => 'Passwords do not match.';

  @override
  String get otpValidationRequired => 'Enter the email OTP code.';

  @override
  String get genericTryAgain => 'Try again';

  @override
  String get loadingSession => 'Loading your session…';

  @override
  String get errorNetwork =>
      'No internet connection. Check your connection and try again.';

  @override
  String get errorTimeout => 'The request timed out. Please try again.';

  @override
  String get errorUnauthorized =>
      'Your session is no longer valid. Please sign in again.';

  @override
  String get errorNotFound => 'We could not find what you were looking for.';

  @override
  String get errorConfiguration =>
      'Authentication is not configured for this build.';

  @override
  String get errorValidation => 'Please review the entered information.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';
}
