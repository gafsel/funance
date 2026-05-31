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
      securePasswordAtLeast1Lowercase: l10n.securePasswordAtLeast1Lowercase,
      securePasswordAtLeast8Characters: l10n.securePasswordAtLeast8Characters,
      securePasswordAtMost50Characters: l10n.securePasswordAtMost50Characters,
      securePasswordAtLeast1Number: l10n.securePasswordAtLeast1Number,
      securePasswordAtLeast1Uppercase: l10n.securePasswordAtLeast1Uppercase,
      securePasswordDontUseSpaces: l10n.securePasswordDontUseSpaces,
    );
  }
}
