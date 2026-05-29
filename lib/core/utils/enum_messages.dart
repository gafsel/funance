import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/l10n/app_localizations.dart';

extension AccountTypeExtension on AppLocalizations {
  String fromAccountType(AccountType type) {
    switch (type) {
      case AccountType.checking:
        return accountTypeChecking;
      case AccountType.investment:
        return accountTypeInvestment;
      case AccountType.creditCard:
        return accountTypeCreditCard;
      case AccountType.debt:
        return accountTypeDebt;
    }
  }

  String fromSummaryViewType(SummaryViewType type) {
    switch (type) {
      case SummaryViewType.planning:
        return overviewPlanning;
      case SummaryViewType.effective:
        return overviewEffective;
    }
  }
}
