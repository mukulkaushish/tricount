import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Tricount'**
  String get appName;

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authTitle;

  /// No description provided for @authSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep your group expenses in sync.'**
  String get authSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get displayNameHint;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Repeat your password'**
  String get confirmPasswordHint;

  /// No description provided for @loginCta.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginCta;

  /// No description provided for @registerCta.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerCta;

  /// No description provided for @forgotPasswordCta.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordCta;

  /// No description provided for @sendOtpCta.
  ///
  /// In en, this message translates to:
  /// **'Send email OTP'**
  String get sendOtpCta;

  /// No description provided for @resetPasswordCta.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordCta;

  /// No description provided for @passkeyCta.
  ///
  /// In en, this message translates to:
  /// **'Use passkey'**
  String get passkeyCta;

  /// No description provided for @googleLoginCta.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get googleLoginCta;

  /// No description provided for @appleLoginCta.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get appleLoginCta;

  /// No description provided for @switchToRegister.
  ///
  /// In en, this message translates to:
  /// **'Create a new account'**
  String get switchToRegister;

  /// No description provided for @switchToLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get switchToLogin;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start tracking shared expenses with your group.'**
  String get registerSubtitle;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Request an email OTP and use it to set a new password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @otpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'OTP code'**
  String get otpCodeLabel;

  /// No description provided for @otpCodeHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get otpCodeHint;

  /// No description provided for @passwordResetOtpSent.
  ///
  /// In en, this message translates to:
  /// **'We sent an OTP to your email.'**
  String get passwordResetOtpSent;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your password has been reset.'**
  String get passwordResetSuccess;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your session'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This screen is driven by the authenticated `me` response.'**
  String get homeSubtitle;

  /// No description provided for @accountSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSectionTitle;

  /// No description provided for @sessionSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get sessionSectionTitle;

  /// No description provided for @appearanceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSectionTitle;

  /// No description provided for @accountIdValue.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String accountIdValue(Object id);

  /// No description provided for @emailVerifiedValue.
  ///
  /// In en, this message translates to:
  /// **'Email verified: {value}'**
  String emailVerifiedValue(Object value);

  /// No description provided for @passkeyEnabledValue.
  ///
  /// In en, this message translates to:
  /// **'Passkey enabled: {value}'**
  String passkeyEnabledValue(Object value);

  /// No description provided for @logoutCta.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutCta;

  /// No description provided for @refreshMeCta.
  ///
  /// In en, this message translates to:
  /// **'Refresh details'**
  String get refreshMeCta;

  /// No description provided for @themeModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeModeLabel;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @paletteLabel.
  ///
  /// In en, this message translates to:
  /// **'Palette'**
  String get paletteLabel;

  /// No description provided for @fontScaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontScaleLabel;

  /// No description provided for @emailValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get emailValidationRequired;

  /// No description provided for @emailValidationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get emailValidationInvalid;

  /// No description provided for @passwordValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get passwordValidationRequired;

  /// No description provided for @passwordValidationShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get passwordValidationShort;

  /// No description provided for @displayNameValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your display name.'**
  String get displayNameValidationRequired;

  /// No description provided for @confirmPasswordValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password.'**
  String get confirmPasswordValidationRequired;

  /// No description provided for @confirmPasswordValidationMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get confirmPasswordValidationMismatch;

  /// No description provided for @otpValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the email OTP code.'**
  String get otpValidationRequired;

  /// No description provided for @genericTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get genericTryAgain;

  /// No description provided for @loadingSession.
  ///
  /// In en, this message translates to:
  /// **'Loading your session…'**
  String get loadingSession;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session is no longer valid. Please sign in again.'**
  String get errorUnauthorized;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'We could not find what you were looking for.'**
  String get errorNotFound;

  /// No description provided for @errorConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Authentication is not configured for this build.'**
  String get errorConfiguration;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please review the entered information.'**
  String get errorValidation;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
