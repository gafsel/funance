import 'package:flutter/material.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Os rótulos e ícones de conta que a seleção usa.
///
/// São três `switch` exaustivos — tipo de conta em ícone, tipo de conta em
/// palavra e logo de banco em nome de instituição — que ocupavam 60 das 800
/// linhas da tela. Aqui eles são o que sempre foram: tabelas.
///
/// Os nomes de banco NÃO passam pelo l10n de propósito: "Nubank" e "Itaú" são
/// marcas, e marca não se traduz. Só "Outro" é palavra, e essa vem do l10n.

IconData accountTypeIcon(AccountType type) {
  switch (type) {
    case AccountType.checking:
      return Icons.wallet_outlined;
    case AccountType.creditCard:
      return Icons.credit_card_outlined;
    case AccountType.investment:
      return Icons.trending_up_outlined;
    case AccountType.debt:
      return Icons.trending_down_outlined;
  }
}

String accountTypeName(AccountType type, AppLocalizations l10n) {
  switch (type) {
    case AccountType.checking:
      return l10n.accountTypeChecking;
    case AccountType.investment:
      return l10n.accountTypeInvestment;
    case AccountType.creditCard:
      return l10n.accountTypeCreditCard;
    case AccountType.debt:
      return l10n.accountTypeDebt;
  }
}

String institutionName(BankLogo logo, AppLocalizations l10n) {
  switch (logo) {
    case BankLogo.none:
      return l10n.bankLogoOther;
    case BankLogo.nubank:
      return "Nubank";
    case BankLogo.inter:
      return "Inter";
    case BankLogo.itau:
      return "Itaú";
    case BankLogo.bradesco:
      return "Bradesco";
    case BankLogo.santander:
      return "Santander";
    case BankLogo.bb:
      return "Banco do Brasil";
    case BankLogo.caixa:
      return "Caixa";
    case BankLogo.c6:
      return "C6 Bank";
    case BankLogo.xp:
      return "XP Investimentos";
    case BankLogo.btg:
      return "BTG Pactual";
    case BankLogo.visa:
      return "Visa";
    case BankLogo.mastercard:
      return "Mastercard";
    case BankLogo.elo:
      return "Elo";
    case BankLogo.amex:
      return "American Express";
  }
}
