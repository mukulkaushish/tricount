import 'package:flutter/widgets.dart';

import 'package:tricount/l10n/app_localizations.dart';

extension LocalizationsContextExtensions on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
