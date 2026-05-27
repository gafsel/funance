import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Funances'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In pt, this message translates to:
  /// **'FUNANCE'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua jornada para a liberdade financeira começa aqui.'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get passwordLabel;

  /// No description provided for @displayNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome Completo'**
  String get displayNameLabel;

  /// No description provided for @loginButton.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In pt, this message translates to:
  /// **'Criar Conta'**
  String get registerButton;

  /// No description provided for @registerLink.
  ///
  /// In pt, this message translates to:
  /// **'Não tem uma conta? Cadastre-se'**
  String get registerLink;

  /// No description provided for @loginLink.
  ///
  /// In pt, this message translates to:
  /// **'Já tem uma conta? Faça login'**
  String get loginLink;

  /// No description provided for @googleLoginButton.
  ///
  /// In pt, this message translates to:
  /// **'Entrar com Google'**
  String get googleLoginButton;

  /// No description provided for @orDivider.
  ///
  /// In pt, this message translates to:
  /// **'OU'**
  String get orDivider;

  /// No description provided for @fieldRequired.
  ///
  /// In pt, this message translates to:
  /// **'Este campo é obrigatório'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In pt, this message translates to:
  /// **'E-mail inválido'**
  String get invalidEmail;

  /// No description provided for @shortPassword.
  ///
  /// In pt, this message translates to:
  /// **'A senha deve ter pelo menos 6 caracteres'**
  String get shortPassword;

  /// No description provided for @errorUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro inesperado.'**
  String get errorUnknown;

  /// No description provided for @errorKeychain.
  ///
  /// In pt, this message translates to:
  /// **'Sua sessão não pôde ser salva. Você poderá usar o app, mas precisará logar novamente ao reabrir.'**
  String get errorKeychain;

  /// No description provided for @errorUserNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Usuário não encontrado.'**
  String get errorUserNotFound;

  /// No description provided for @errorWrongPassword.
  ///
  /// In pt, this message translates to:
  /// **'Senha incorreta.'**
  String get errorWrongPassword;

  /// No description provided for @errorEmailAlreadyInUse.
  ///
  /// In pt, this message translates to:
  /// **'Este e-mail já está sendo usado por outra conta.'**
  String get errorEmailAlreadyInUse;

  /// No description provided for @errorWeakPassword.
  ///
  /// In pt, this message translates to:
  /// **'A senha fornecida é muito fraca.'**
  String get errorWeakPassword;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In pt, this message translates to:
  /// **'O endereço de e-mail não é válido.'**
  String get errorInvalidEmail;

  /// No description provided for @errorNetworkRequestFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falha na conexão com a internet.'**
  String get errorNetworkRequestFailed;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Boas-vindas ao Funances!'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeDesc.
  ///
  /// In pt, this message translates to:
  /// **'O app que transforma sua gestão financeira em uma jornada de conquistas.'**
  String get onboardingWelcomeDesc;

  /// No description provided for @onboardingNext.
  ///
  /// In pt, this message translates to:
  /// **'Próximo'**
  String get onboardingNext;

  /// No description provided for @onboardingBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get onboardingBack;

  /// No description provided for @onboardingStart.
  ///
  /// In pt, this message translates to:
  /// **'Começar Jornada'**
  String get onboardingStart;

  /// No description provided for @onboardingPersonalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Workspace Pessoal'**
  String get onboardingPersonalTitle;

  /// No description provided for @onboardingPersonalDesc.
  ///
  /// In pt, this message translates to:
  /// **'Ideal para suas contas individuais, gastos do dia a dia e metas pessoais.'**
  String get onboardingPersonalDesc;

  /// No description provided for @onboardingBusinessTitle.
  ///
  /// In pt, this message translates to:
  /// **'Workspace de Negócio'**
  String get onboardingBusinessTitle;

  /// No description provided for @onboardingBusinessDesc.
  ///
  /// In pt, this message translates to:
  /// **'Gerencie o fluxo de caixa da sua empresa ou projeto paralelo de forma profissional.'**
  String get onboardingBusinessDesc;

  /// No description provided for @onboardingWorkspaceNameTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dê um nome ao seu Workspace'**
  String get onboardingWorkspaceNameTitle;

  /// No description provided for @onboardingWorkspaceNamePersonalHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Minhas Finanças, Família Silva...'**
  String get onboardingWorkspaceNamePersonalHint;

  /// No description provided for @onboardingWorkspaceNameBusinessHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Minha Empresa, Freelance...'**
  String get onboardingWorkspaceNameBusinessHint;

  /// No description provided for @onboardingWorkspaceNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Workspace'**
  String get onboardingWorkspaceNameLabel;

  /// No description provided for @onboardingWorkspaceCreateError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao criar workspace.'**
  String get onboardingWorkspaceCreateError;

  /// No description provided for @onboardingGoalsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Trace suas primeiras metas'**
  String get onboardingGoalsTitle;

  /// No description provided for @onboardingGoalsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Economizar para uma viagem? Comprar um carro? Vamos configurar isso em breve.'**
  String get onboardingGoalsDesc;

  /// No description provided for @onboardingGoalsButton.
  ///
  /// In pt, this message translates to:
  /// **'ENTENDI, PRÓXIMO PASSO'**
  String get onboardingGoalsButton;

  /// No description provided for @onboardingMembersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Convide membros'**
  String get onboardingMembersTitle;

  /// No description provided for @onboardingMembersDesc.
  ///
  /// In pt, this message translates to:
  /// **'Você pode compartilhar seu workspace com sócios ou familiares para gerirem as finanças juntos.'**
  String get onboardingMembersDesc;

  /// No description provided for @onboardingFinish.
  ///
  /// In pt, this message translates to:
  /// **'CONCLUIR ONBOARDING'**
  String get onboardingFinish;

  /// No description provided for @goalEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Que tal começar a planejar o seu futuro? Crie a sua primeira meta agora!'**
  String get goalEmptyMessage;

  /// No description provided for @goalEmptyExample.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Viagem pra Disney'**
  String get goalEmptyExample;

  /// No description provided for @addGoalButton.
  ///
  /// In pt, this message translates to:
  /// **'Nova Meta'**
  String get addGoalButton;

  /// No description provided for @goalNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome da Meta'**
  String get goalNameLabel;

  /// No description provided for @goalTargetAmountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor Alvo'**
  String get goalTargetAmountLabel;

  /// No description provided for @goalCurrentAmountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor Atual'**
  String get goalCurrentAmountLabel;

  /// No description provided for @goalStartDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Data de Início'**
  String get goalStartDateLabel;

  /// No description provided for @goalDeadlineLabel.
  ///
  /// In pt, this message translates to:
  /// **'Prazo'**
  String get goalDeadlineLabel;

  /// No description provided for @goalTypeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Meta'**
  String get goalTypeLabel;

  /// No description provided for @goalTypeSaveMoney.
  ///
  /// In pt, this message translates to:
  /// **'Juntar Dinheiro'**
  String get goalTypeSaveMoney;

  /// No description provided for @goalTypeReduceExpense.
  ///
  /// In pt, this message translates to:
  /// **'Economizar (Categoria)'**
  String get goalTypeReduceExpense;

  /// No description provided for @goalTypeReduceCreditCard.
  ///
  /// In pt, this message translates to:
  /// **'Reduzir Cartão de Crédito'**
  String get goalTypeReduceCreditCard;

  /// No description provided for @goalCategoryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get goalCategoryLabel;

  /// No description provided for @goalCreditCardLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cartão de Crédito'**
  String get goalCreditCardLabel;

  /// No description provided for @goalAverageSpendingLabel.
  ///
  /// In pt, this message translates to:
  /// **'Média de Gastos Mensal'**
  String get goalAverageSpendingLabel;

  /// No description provided for @errorGoalNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Meta não encontrada.'**
  String get errorGoalNotFound;

  /// No description provided for @errorGoalTypeCannotBeChanged.
  ///
  /// In pt, this message translates to:
  /// **'O tipo da meta não pode ser alterado.'**
  String get errorGoalTypeCannotBeChanged;

  /// No description provided for @statusOnTrack.
  ///
  /// In pt, this message translates to:
  /// **'Em dia'**
  String get statusOnTrack;

  /// No description provided for @statusAtRisk.
  ///
  /// In pt, this message translates to:
  /// **'Alerta'**
  String get statusAtRisk;

  /// No description provided for @statusBehind.
  ///
  /// In pt, this message translates to:
  /// **'Atrasada'**
  String get statusBehind;

  /// No description provided for @statusLost.
  ///
  /// In pt, this message translates to:
  /// **'Perdida'**
  String get statusLost;

  /// No description provided for @goalProgressPercent.
  ///
  /// In pt, this message translates to:
  /// **'{percent}% concluído'**
  String goalProgressPercent(Object percent);

  /// No description provided for @goalRemainingAmount.
  ///
  /// In pt, this message translates to:
  /// **'Faltam {amount}'**
  String goalRemainingAmount(Object amount);

  /// No description provided for @continueButton.
  ///
  /// In pt, this message translates to:
  /// **'CONTINUAR'**
  String get continueButton;

  /// No description provided for @invitesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Convites Pendentes'**
  String get invitesTitle;

  /// No description provided for @invitesSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Você foi convidado para participar dos seguintes workspaces:'**
  String get invitesSubtitle;

  /// No description provided for @inviteFrom.
  ///
  /// In pt, this message translates to:
  /// **'Enviado por: {sender}'**
  String inviteFrom(String sender);

  /// No description provided for @acceptButton.
  ///
  /// In pt, this message translates to:
  /// **'Aceitar'**
  String get acceptButton;

  /// No description provided for @declineButton.
  ///
  /// In pt, this message translates to:
  /// **'Recusar'**
  String get declineButton;

  /// No description provided for @homeJourneyTab.
  ///
  /// In pt, this message translates to:
  /// **'A Jornada'**
  String get homeJourneyTab;

  /// No description provided for @homeOverviewTab.
  ///
  /// In pt, this message translates to:
  /// **'Visão Geral'**
  String get homeOverviewTab;

  /// No description provided for @homeHistoryTab.
  ///
  /// In pt, this message translates to:
  /// **'Extrato'**
  String get homeHistoryTab;

  /// No description provided for @homeTotalSavedMonth.
  ///
  /// In pt, this message translates to:
  /// **'Você economizou {amount} a mais que o planejado!'**
  String homeTotalSavedMonth(Object amount);

  /// No description provided for @homePointsEarned.
  ///
  /// In pt, this message translates to:
  /// **'+{points} Pontos'**
  String homePointsEarned(Object points);

  /// No description provided for @homeRemainingAmount.
  ///
  /// In pt, this message translates to:
  /// **'Faltam {amount} ({percent}% concluído)'**
  String homeRemainingAmount(Object amount, Object percent);

  /// No description provided for @homeAccountsAndCards.
  ///
  /// In pt, this message translates to:
  /// **'Saldos e Faturas'**
  String get homeAccountsAndCards;

  /// No description provided for @homeWhereIsMoney.
  ///
  /// In pt, this message translates to:
  /// **'Onde está o dinheiro?'**
  String get homeWhereIsMoney;

  /// No description provided for @homeTotalSpent.
  ///
  /// In pt, this message translates to:
  /// **'Total Gasto'**
  String get homeTotalSpent;

  /// No description provided for @homeTotalBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo Total'**
  String get homeTotalBalance;

  /// No description provided for @accountCreateAction.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar Nova Conta'**
  String get accountCreateAction;

  /// No description provided for @accountCreateTypeAction.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar Nova Conta de {type}'**
  String accountCreateTypeAction(String type);

  /// No description provided for @homeAllAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Todas as Contas'**
  String get homeAllAccounts;

  /// No description provided for @homeThisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Este Mês'**
  String get homeThisMonth;

  /// No description provided for @homeLastMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês Passado'**
  String get homeLastMonth;

  /// No description provided for @homeCustomPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Customizado'**
  String get homeCustomPeriod;

  /// No description provided for @homeNewTransaction.
  ///
  /// In pt, this message translates to:
  /// **'Novo Lançamento'**
  String get homeNewTransaction;

  /// No description provided for @homeConsolidate.
  ///
  /// In pt, this message translates to:
  /// **'Consolidar'**
  String get homeConsolidate;

  /// No description provided for @noTransactionsInPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma transação encontrada para este período'**
  String get noTransactionsInPeriod;

  /// No description provided for @homeSettings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get homeSettings;

  /// No description provided for @homeNoWorkspaceSelected.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum workspace selecionado'**
  String get homeNoWorkspaceSelected;

  /// No description provided for @workspaceSettingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurações do Workspace'**
  String get workspaceSettingsTitle;

  /// No description provided for @workspaceSettingsGeneralSection.
  ///
  /// In pt, this message translates to:
  /// **'Geral'**
  String get workspaceSettingsGeneralSection;

  /// No description provided for @workspaceSettingsEditName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Workspace'**
  String get workspaceSettingsEditName;

  /// No description provided for @workspaceSettingsDataSection.
  ///
  /// In pt, this message translates to:
  /// **'Dados'**
  String get workspaceSettingsDataSection;

  /// No description provided for @workspaceSettingsCategories.
  ///
  /// In pt, this message translates to:
  /// **'Categorias'**
  String get workspaceSettingsCategories;

  /// No description provided for @workspaceSettingsTeamSection.
  ///
  /// In pt, this message translates to:
  /// **'Equipe'**
  String get workspaceSettingsTeamSection;

  /// No description provided for @workspaceSettingsMembers.
  ///
  /// In pt, this message translates to:
  /// **'Membros'**
  String get workspaceSettingsMembers;

  /// No description provided for @categoryManagementTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gestão de Categorias'**
  String get categoryManagementTitle;

  /// No description provided for @categoryManagementEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma categoria cadastrada.'**
  String get categoryManagementEmpty;

  /// No description provided for @categoryCreateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova Categoria'**
  String get categoryCreateTitle;

  /// No description provided for @categoryEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Categoria'**
  String get categoryEditTitle;

  /// No description provided for @categoryNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome da Categoria'**
  String get categoryNameLabel;

  /// No description provided for @categoryTypeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get categoryTypeLabel;

  /// No description provided for @categoryTypeIncome.
  ///
  /// In pt, this message translates to:
  /// **'Receita'**
  String get categoryTypeIncome;

  /// No description provided for @categoryTypeExpense.
  ///
  /// In pt, this message translates to:
  /// **'Despesa'**
  String get categoryTypeExpense;

  /// No description provided for @categoryTypeBoth.
  ///
  /// In pt, this message translates to:
  /// **'Ambos'**
  String get categoryTypeBoth;

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Categoria'**
  String get categoryDeleteTitle;

  /// No description provided for @categoryDeleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Deseja realmente excluir a categoria \"{name}\"?'**
  String categoryDeleteConfirm(String name);

  /// No description provided for @categoryOthers.
  ///
  /// In pt, this message translates to:
  /// **'Outros'**
  String get categoryOthers;

  /// No description provided for @saveButton.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get saveButton;

  /// No description provided for @deleteButton.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get deleteButton;

  /// No description provided for @cancelButton.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancelButton;

  /// No description provided for @categoryColorLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cor da Categoria'**
  String get categoryColorLabel;

  /// No description provided for @categoryIconLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ícone da Categoria'**
  String get categoryIconLabel;

  /// No description provided for @workspaceSettingsAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Contas'**
  String get workspaceSettingsAccounts;

  /// No description provided for @accountManagementTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gestão de Contas'**
  String get accountManagementTitle;

  /// No description provided for @accountManagementEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conta cadastrada.'**
  String get accountManagementEmpty;

  /// No description provided for @accountCreateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova Conta'**
  String get accountCreateTitle;

  /// No description provided for @accountEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Conta'**
  String get accountEditTitle;

  /// No description provided for @accountNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome da Conta'**
  String get accountNameLabel;

  /// No description provided for @accountTypeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Conta'**
  String get accountTypeLabel;

  /// No description provided for @accountTypeChecking.
  ///
  /// In pt, this message translates to:
  /// **'Conta Corrente'**
  String get accountTypeChecking;

  /// No description provided for @accountTypeInvestment.
  ///
  /// In pt, this message translates to:
  /// **'Investimento'**
  String get accountTypeInvestment;

  /// No description provided for @accountTypeCreditCard.
  ///
  /// In pt, this message translates to:
  /// **'Cartão de Crédito'**
  String get accountTypeCreditCard;

  /// No description provided for @accountTypeDebt.
  ///
  /// In pt, this message translates to:
  /// **'Dívida'**
  String get accountTypeDebt;

  /// No description provided for @accountColorLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cor da Conta'**
  String get accountColorLabel;

  /// No description provided for @accountIconLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ícone da Conta'**
  String get accountIconLabel;

  /// No description provided for @accountLimitLabel.
  ///
  /// In pt, this message translates to:
  /// **'Limite'**
  String get accountLimitLabel;

  /// No description provided for @accountDueDayLabel.
  ///
  /// In pt, this message translates to:
  /// **'Dia do Vencimento'**
  String get accountDueDayLabel;

  /// No description provided for @accountClosingDayLabel.
  ///
  /// In pt, this message translates to:
  /// **'Dia do Fechamento'**
  String get accountClosingDayLabel;

  /// No description provided for @accountInterestRateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de Juros (%)'**
  String get accountInterestRateLabel;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Conta'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Deseja realmente excluir a conta \"{name}\"? (Os dados não serão perdidos fisicamente)'**
  String accountDeleteConfirm(String name);

  /// No description provided for @addAccountButton.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Conta'**
  String get addAccountButton;

  /// No description provided for @goalAccountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conta associada'**
  String get goalAccountLabel;

  /// No description provided for @transactionAddExpense.
  ///
  /// In pt, this message translates to:
  /// **'Lançar Despesa'**
  String get transactionAddExpense;

  /// No description provided for @transactionAddIncome.
  ///
  /// In pt, this message translates to:
  /// **'Lançar Receita'**
  String get transactionAddIncome;

  /// No description provided for @transactionPlanExpense.
  ///
  /// In pt, this message translates to:
  /// **'Planejar Despesa'**
  String get transactionPlanExpense;

  /// No description provided for @transactionPlanIncome.
  ///
  /// In pt, this message translates to:
  /// **'Planejar Receita'**
  String get transactionPlanIncome;

  /// No description provided for @transactionPlannedSection.
  ///
  /// In pt, this message translates to:
  /// **'Lançamentos Planejados'**
  String get transactionPlannedSection;

  /// No description provided for @transactionCategoriesSection.
  ///
  /// In pt, this message translates to:
  /// **'Categorias'**
  String get transactionCategoriesSection;

  /// No description provided for @transactionDescriptionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get transactionDescriptionLabel;

  /// No description provided for @transactionAmountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get transactionAmountLabel;

  /// No description provided for @transactionDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get transactionDateLabel;

  /// No description provided for @transactionAccountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get transactionAccountLabel;

  /// No description provided for @transactionInstallmentsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Parcelas'**
  String get transactionInstallmentsLabel;

  /// No description provided for @transactionTypeExpense.
  ///
  /// In pt, this message translates to:
  /// **'Despesa'**
  String get transactionTypeExpense;

  /// No description provided for @transactionTypeIncome.
  ///
  /// In pt, this message translates to:
  /// **'Receita'**
  String get transactionTypeIncome;

  /// No description provided for @transactionTypeTransfer.
  ///
  /// In pt, this message translates to:
  /// **'Transferência'**
  String get transactionTypeTransfer;

  /// No description provided for @transactionFromAccountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conta de Origem'**
  String get transactionFromAccountLabel;

  /// No description provided for @transactionToAccountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conta de Destino'**
  String get transactionToAccountLabel;

  /// No description provided for @transactionSaveSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Transação salva com sucesso!'**
  String get transactionSaveSuccess;

  /// No description provided for @noAccountsFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conta encontrada.'**
  String get noAccountsFound;

  /// No description provided for @initialBalanceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Saldo Inicial'**
  String get initialBalanceLabel;

  /// No description provided for @initialBalanceDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Data do Saldo Inicial'**
  String get initialBalanceDateLabel;

  /// No description provided for @historyEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get historyEdit;

  /// No description provided for @historyDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get historyDelete;

  /// No description provided for @historyDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Lançamento'**
  String get historyDeleteTitle;

  /// No description provided for @historyDeleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Deseja realmente excluir este lançamento?'**
  String get historyDeleteConfirm;

  /// No description provided for @today.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get yesterday;

  /// No description provided for @transactionTypeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Transação'**
  String get transactionTypeLabel;

  /// No description provided for @transactionTypeSimple.
  ///
  /// In pt, this message translates to:
  /// **'Simples'**
  String get transactionTypeSimple;

  /// No description provided for @transactionTypeInstallment.
  ///
  /// In pt, this message translates to:
  /// **'Parcelada'**
  String get transactionTypeInstallment;

  /// No description provided for @transactionTypeRecurrent.
  ///
  /// In pt, this message translates to:
  /// **'Recorrência'**
  String get transactionTypeRecurrent;

  /// No description provided for @homeTotalPlanned.
  ///
  /// In pt, this message translates to:
  /// **'Total Planejado'**
  String get homeTotalPlanned;

  /// No description provided for @overviewPlanning.
  ///
  /// In pt, this message translates to:
  /// **'Planejamento'**
  String get overviewPlanning;

  /// No description provided for @overviewEffective.
  ///
  /// In pt, this message translates to:
  /// **'Efetivo'**
  String get overviewEffective;

  /// No description provided for @overviewComparison.
  ///
  /// In pt, this message translates to:
  /// **'Comparação'**
  String get overviewComparison;

  /// No description provided for @transactionTransfer.
  ///
  /// In pt, this message translates to:
  /// **'Transferência'**
  String get transactionTransfer;

  /// No description provided for @transactionSelectSourceAccount.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Conta de Origem'**
  String get transactionSelectSourceAccount;

  /// No description provided for @transactionSelectDestinationAccount.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Conta de Destino'**
  String get transactionSelectDestinationAccount;
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
