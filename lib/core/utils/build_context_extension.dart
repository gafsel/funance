import 'package:flutter/widgets.dart';
import 'package:funances/core/validation/validation.dart';
import 'package:funances/l10n/app_localizations.dart';

extension BuildContextExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  String get locale => Localizations.localeOf(this).toString();

  Validations get validations {
    final l10n = AppLocalizations.of(this)!;
    return Validations(
      emailMessage: l10n.validationEmailMessage,
      lengthMaxMessage: l10n.validationLengthMaxMessage,
      lengthMinMessage: l10n.validationLenghtMinMessage,
      notEmptyMessage: l10n.validationNotEmptyMessage,
      notNullMessage: l10n.validationNotNullMessage,
    );
  }
}
