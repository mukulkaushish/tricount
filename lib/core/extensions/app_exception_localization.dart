import 'package:flutter/widgets.dart';

import 'package:tricount/core/network/network.dart';
import 'package:tricount/l10n/app_localizations.dart';

extension AppExceptionLocalization on AppException {
  String localizedMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return switch (this) {
      NetworkAppException _ => l10n.errorNetwork,
      TimeoutAppException _ => l10n.errorTimeout,
      UnauthorizedAppException(:final message?) when message.isNotEmpty =>
        message,
      UnauthorizedAppException _ => l10n.errorUnauthorized,
      NotFoundAppException(:final message?) when message.isNotEmpty => message,
      NotFoundAppException _ => l10n.errorNotFound,
      ConfigurationAppException _ => l10n.errorConfiguration,
      ValidationAppException(:final message?) when message.isNotEmpty =>
        message,
      ValidationAppException _ => l10n.errorValidation,
      ServerAppException(:final message?) when message.isNotEmpty => message,
      UnknownAppException(:final message?) when message.isNotEmpty => message,
      _ => l10n.errorGeneric,
    };
  }
}
