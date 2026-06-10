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

  /// No description provided for @errorGoogleSignInConfig.
  ///
  /// In pt, this message translates to:
  /// **'Erro de configuração no login com Google. Verifique se a chave SHA-1 foi adicionada ao Firebase Console.'**
  String get errorGoogleSignInConfig;

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

  /// No description provided for @onboardingAccountsTitle.
  ///
  /// In pt, this message translates to:
  /// **'DEFINIR CONTAS'**
  String get onboardingAccountsTitle;

  /// No description provided for @onboardingAccountsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre suas contas bancárias ou cartões de crédito. Você pode anexar extratos (PDF/OFX) para automatizar o processo.'**
  String get onboardingAccountsDesc;

  /// No description provided for @onboardingAccountsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conta adicionada'**
  String get onboardingAccountsEmpty;

  /// No description provided for @onboardingAccountsAdd.
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR CONTA'**
  String get onboardingAccountsAdd;

  /// No description provided for @onboardingAccountsAddAnother.
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR OUTRA CONTA'**
  String get onboardingAccountsAddAnother;

  /// No description provided for @onboardingAccountsManual.
  ///
  /// In pt, this message translates to:
  /// **'Cadastro manual'**
  String get onboardingAccountsManual;

  /// No description provided for @onboardingAccountsAttachment.
  ///
  /// In pt, this message translates to:
  /// **'Anexo: {fileName}'**
  String onboardingAccountsAttachment(String fileName);

  /// No description provided for @onboardingGoalsAnalysisTitle.
  ///
  /// In pt, this message translates to:
  /// **'SUGESTÕES DA IA'**
  String get onboardingGoalsAnalysisTitle;

  /// No description provided for @onboardingGoalsAnalysisDesc.
  ///
  /// In pt, this message translates to:
  /// **'Com base no seu perfil e contas, nossa IA sugere algumas metas e planejamentos para você.'**
  String get onboardingGoalsAnalysisDesc;

  /// No description provided for @onboardingSuggestedGoalsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Metas Sugeridas'**
  String get onboardingSuggestedGoalsTitle;

  /// No description provided for @onboardingSuggestedPlanningsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Planejamentos Sugeridos'**
  String get onboardingSuggestedPlanningsTitle;

  /// No description provided for @onboardingMembersListTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lista de convites'**
  String get onboardingMembersListTitle;

  /// No description provided for @onboardingMembersEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum e-mail adicionado'**
  String get onboardingMembersEmpty;

  /// No description provided for @onboardingSuccessTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tudo pronto!'**
  String get onboardingSuccessTitle;

  /// No description provided for @onboardingSuccessDesc.
  ///
  /// In pt, this message translates to:
  /// **'Seu workspace foi configurado com sucesso. Agora você já pode começar a organizar sua vida financeira.'**
  String get onboardingSuccessDesc;

  /// No description provided for @onboardingSuccessCTA.
  ///
  /// In pt, this message translates to:
  /// **'IR PARA A TELA PRINCIPAL'**
  String get onboardingSuccessCTA;

  /// No description provided for @onboardingStepConceptsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Entenda os Conceitos'**
  String get onboardingStepConceptsTitle;

  /// No description provided for @onboardingStepConceptsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Para tirar o máximo proveito do Funances, vamos entender como organizamos as informações.'**
  String get onboardingStepConceptsDesc;

  /// No description provided for @onboardingConceptLimitsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Limites e Expectativas'**
  String get onboardingConceptLimitsTitle;

  /// No description provided for @onboardingConceptLimitsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Defina quanto você espera ganhar e o limite máximo que deseja gastar por categoria. É o seu teto financeiro.'**
  String get onboardingConceptLimitsDesc;

  /// No description provided for @onboardingConceptPlanningTitle.
  ///
  /// In pt, this message translates to:
  /// **'Planejamentos'**
  String get onboardingConceptPlanningTitle;

  /// No description provided for @onboardingConceptPlanningDesc.
  ///
  /// In pt, this message translates to:
  /// **'Funciona como um lançamento agendado: contabiliza no teto da categoria mas não interfere no saldo da conta até ser efetivado. Ideal para pagamentos recorrentes ou parcelados.'**
  String get onboardingConceptPlanningDesc;

  /// No description provided for @onboardingConceptFeaturesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Funcionalidades e Onde Encontrar'**
  String get onboardingConceptFeaturesTitle;

  /// No description provided for @onboardingConceptFeaturesDesc.
  ///
  /// In pt, this message translates to:
  /// **'Explore o Dashboard para visão geral, Extratos para conciliação e Metas para acompanhar seus sonhos.'**
  String get onboardingConceptFeaturesDesc;

  /// No description provided for @onboardingConceptTransactionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lançamentos'**
  String get onboardingConceptTransactionsTitle;

  /// No description provided for @onboardingConceptTransactionsDesc.
  ///
  /// In pt, this message translates to:
  /// **'O dia a dia! Registre suas entradas e saídas reais para acompanhar seu progresso em relação ao plano.'**
  String get onboardingConceptTransactionsDesc;

  /// No description provided for @goalRemainingMonthly.
  ///
  /// In pt, this message translates to:
  /// **'{amount}/mês'**
  String goalRemainingMonthly(String amount);

  /// No description provided for @goalTargetTarget.
  ///
  /// In pt, this message translates to:
  /// **'Alvo: {amount}'**
  String goalTargetTarget(String amount);

  /// No description provided for @goalRemainingMonthlyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Valor por mês'**
  String get goalRemainingMonthlyDesc;

  /// No description provided for @goalRemainingMonthlyTarget.
  ///
  /// In pt, this message translates to:
  /// **'{amount}/mês até {date}'**
  String goalRemainingMonthlyTarget(String amount, String date);

  /// No description provided for @goalMonthlyRequirementLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor por mês'**
  String get goalMonthlyRequirementLabel;

  /// No description provided for @goalMonthlyRequirementValue.
  ///
  /// In pt, this message translates to:
  /// **'{amount}/mês'**
  String goalMonthlyRequirementValue(String amount);

  /// No description provided for @automaticTransactionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lançamentos Identificados'**
  String get automaticTransactionTitle;

  /// No description provided for @automaticTransactionSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Identificamos novas movimentações nas suas notificações. Deseja registrar?'**
  String get automaticTransactionSubtitle;

  /// No description provided for @automaticTransactionConsolidate.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar'**
  String get automaticTransactionConsolidate;

  /// No description provided for @automaticTransactionIgnore.
  ///
  /// In pt, this message translates to:
  /// **'Ignorar'**
  String get automaticTransactionIgnore;

  /// No description provided for @planning503020Title.
  ///
  /// In pt, this message translates to:
  /// **'Planejamento 50-30-20'**
  String get planning503020Title;

  /// No description provided for @planning503020SummaryIncome.
  ///
  /// In pt, this message translates to:
  /// **'Receita Prevista'**
  String get planning503020SummaryIncome;

  /// No description provided for @planning503020SummaryExpense.
  ///
  /// In pt, this message translates to:
  /// **'Despesa Prevista'**
  String get planning503020SummaryExpense;

  /// No description provided for @planning503020Essential.
  ///
  /// In pt, this message translates to:
  /// **'Essencial'**
  String get planning503020Essential;

  /// No description provided for @planning503020Comfort.
  ///
  /// In pt, this message translates to:
  /// **'Conforto'**
  String get planning503020Comfort;

  /// No description provided for @planning503020Investment.
  ///
  /// In pt, this message translates to:
  /// **'Investimento'**
  String get planning503020Investment;

  /// No description provided for @planning503020EssentialDesc.
  ///
  /// In pt, this message translates to:
  /// **'Limites de gastos com necessidades básicas. Ideal: 50% da sua receita.'**
  String get planning503020EssentialDesc;

  /// No description provided for @planning503020ComfortDesc.
  ///
  /// In pt, this message translates to:
  /// **'Gastos com seu estilo de vida e lazer. Ideal: 30% da sua receita.'**
  String get planning503020ComfortDesc;

  /// No description provided for @planning503020InvestmentDesc.
  ///
  /// In pt, this message translates to:
  /// **'Futuro e segurança (investimentos e dívidas). Ideal: 20% da sua receita.'**
  String get planning503020InvestmentDesc;

  /// No description provided for @planning503020Ideal.
  ///
  /// In pt, this message translates to:
  /// **'Meta: {amount}'**
  String planning503020Ideal(String amount);

  /// No description provided for @planning503020ActualAmount.
  ///
  /// In pt, this message translates to:
  /// **'Real: {amount}'**
  String planning503020ActualAmount(String amount);

  /// No description provided for @planning503020DistributionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Distribuição 50-30-20'**
  String get planning503020DistributionTitle;

  /// No description provided for @planning503020Planned.
  ///
  /// In pt, this message translates to:
  /// **'Planejado'**
  String get planning503020Planned;

  /// No description provided for @planning503020Actual.
  ///
  /// In pt, this message translates to:
  /// **'Executado'**
  String get planning503020Actual;

  /// No description provided for @planning503020Goal.
  ///
  /// In pt, this message translates to:
  /// **'Meta'**
  String get planning503020Goal;

  /// No description provided for @planning503020SummaryActual.
  ///
  /// In pt, this message translates to:
  /// **'Gasto Real'**
  String get planning503020SummaryActual;

  /// No description provided for @planning503020ActualLabel.
  ///
  /// In pt, this message translates to:
  /// **'Já gasto:'**
  String get planning503020ActualLabel;

  /// No description provided for @planning503020Total.
  ///
  /// In pt, this message translates to:
  /// **'Total: {amount}'**
  String planning503020Total(String amount);

  /// No description provided for @planning503020AlertSpecificGreater.
  ///
  /// In pt, this message translates to:
  /// **'Gastos previstos superiores ao estimado!'**
  String get planning503020AlertSpecificGreater;

  /// No description provided for @planning503020Save.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR'**
  String get planning503020Save;

  /// No description provided for @planning503020EmptyPool.
  ///
  /// In pt, this message translates to:
  /// **'Arraste categorias para cá'**
  String get planning503020EmptyPool;

  /// No description provided for @automaticTransactionFindExisting.
  ///
  /// In pt, this message translates to:
  /// **'Buscar Existente'**
  String get automaticTransactionFindExisting;

  /// No description provided for @automaticTransactionEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum novo lançamento identificado.'**
  String get automaticTransactionEmpty;

  /// No description provided for @automaticTransactionSimulate.
  ///
  /// In pt, this message translates to:
  /// **'Simular Notificação'**
  String get automaticTransactionSimulate;

  /// No description provided for @automaticTransactionRequestPermission.
  ///
  /// In pt, this message translates to:
  /// **'Ouvir Notificações'**
  String get automaticTransactionRequestPermission;

  /// No description provided for @automaticTransactionPermissionRequired.
  ///
  /// In pt, this message translates to:
  /// **'Para detectar transações automaticamente, o app precisa de permissão para ler notificações.'**
  String get automaticTransactionPermissionRequired;

  /// No description provided for @automaticTransactionGrantPermission.
  ///
  /// In pt, this message translates to:
  /// **'Conceder Permissão'**
  String get automaticTransactionGrantPermission;

  /// No description provided for @automaticTransactionSuggestedCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria sugerida: {category}'**
  String automaticTransactionSuggestedCategory(Object category);

  /// No description provided for @automaticTransactionSuggestedAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta sugerida: {account}'**
  String automaticTransactionSuggestedAccount(Object account);

  /// No description provided for @goalRemainingValue.
  ///
  /// In pt, this message translates to:
  /// **'Faltam {amount}'**
  String goalRemainingValue(String amount);

  /// No description provided for @goalProgressValue.
  ///
  /// In pt, this message translates to:
  /// **'{percent}%'**
  String goalProgressValue(String percent);

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

  /// No description provided for @goalTypePayDebt.
  ///
  /// In pt, this message translates to:
  /// **'Pagar Dívida'**
  String get goalTypePayDebt;

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

  /// No description provided for @homeMissionsTab.
  ///
  /// In pt, this message translates to:
  /// **'Missões'**
  String get homeMissionsTab;

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

  /// No description provided for @weeklyMissions.
  ///
  /// In pt, this message translates to:
  /// **'Missões da Semana'**
  String get weeklyMissions;

  /// No description provided for @weeklyMissionsSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Semana de Sucesso!'**
  String get weeklyMissionsSuccess;

  /// No description provided for @weeklyMissionsNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma missão para esta semana'**
  String get weeklyMissionsNone;

  /// No description provided for @weeklyMissionsSuccessDesc.
  ///
  /// In pt, this message translates to:
  /// **'Você cumpriu todas as suas metas. Parabéns!'**
  String get weeklyMissionsSuccessDesc;

  /// No description provided for @weeklyMissionsNoneDesc.
  ///
  /// In pt, this message translates to:
  /// **'Configure planejamentos ou adicione transações para começar.'**
  String get weeklyMissionsNoneDesc;

  /// No description provided for @pendingMissions.
  ///
  /// In pt, this message translates to:
  /// **'Pendentes'**
  String get pendingMissions;

  /// No description provided for @completedMissions.
  ///
  /// In pt, this message translates to:
  /// **'Concluídas'**
  String get completedMissions;

  /// No description provided for @overdueMissions.
  ///
  /// In pt, this message translates to:
  /// **'Atrasadas'**
  String get overdueMissions;

  /// No description provided for @weeklyMissionsProgress.
  ///
  /// In pt, this message translates to:
  /// **'{completed} de {total} completadas'**
  String weeklyMissionsProgress(String completed, String total);

  /// No description provided for @weeklyGoal.
  ///
  /// In pt, this message translates to:
  /// **'Meta da Semana'**
  String get weeklyGoal;

  /// No description provided for @xpValue.
  ///
  /// In pt, this message translates to:
  /// **'{xp} XP'**
  String xpValue(String xp);

  /// No description provided for @xpProgress.
  ///
  /// In pt, this message translates to:
  /// **'{current} / {total} XP'**
  String xpProgress(String current, String total);

  /// No description provided for @percentage.
  ///
  /// In pt, this message translates to:
  /// **'{value}%'**
  String percentage(String value);

  /// No description provided for @dateRange.
  ///
  /// In pt, this message translates to:
  /// **'{start} - {end}'**
  String dateRange(String start, String end);

  /// No description provided for @remainingWeeklyPlanning.
  ///
  /// In pt, this message translates to:
  /// **'Disponível na semana'**
  String get remainingWeeklyPlanning;

  /// No description provided for @spentOfWeeklyPlanning.
  ///
  /// In pt, this message translates to:
  /// **'{spent} de {limit}'**
  String spentOfWeeklyPlanning(String spent, String limit);

  /// No description provided for @hpLabel.
  ///
  /// In pt, this message translates to:
  /// **'HP'**
  String get hpLabel;

  /// No description provided for @overBudgetAmount.
  ///
  /// In pt, this message translates to:
  /// **'Excesso: {amount}'**
  String overBudgetAmount(String amount);

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

  /// No description provided for @historyFilterPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Período'**
  String get historyFilterPeriod;

  /// No description provided for @historyFilterAllAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Todas as Contas'**
  String get historyFilterAllAccounts;

  /// No description provided for @all.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get all;

  /// No description provided for @historyFilterTitle.
  ///
  /// In pt, this message translates to:
  /// **'Filtros'**
  String get historyFilterTitle;

  /// No description provided for @historyFilterDescriptionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get historyFilterDescriptionLabel;

  /// No description provided for @historyFilterTypeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Transação'**
  String get historyFilterTypeLabel;

  /// No description provided for @historyFilterCategoryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get historyFilterCategoryLabel;

  /// No description provided for @historyFilterStatusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get historyFilterStatusLabel;

  /// No description provided for @historyFilterAmountRangeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Faixa de Valor'**
  String get historyFilterAmountRangeLabel;

  /// No description provided for @historyFilterMinAmountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor Mínimo'**
  String get historyFilterMinAmountLabel;

  /// No description provided for @historyFilterMaxAmountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor Máximo'**
  String get historyFilterMaxAmountLabel;

  /// No description provided for @transactionWizardSelectCategory.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a Categoria'**
  String get transactionWizardSelectCategory;

  /// No description provided for @transactionWizardSelectPending.
  ///
  /// In pt, this message translates to:
  /// **'Lançamentos Pendentes'**
  String get transactionWizardSelectPending;

  /// No description provided for @transactionWizardNewTransaction.
  ///
  /// In pt, this message translates to:
  /// **'Novo lançamento'**
  String get transactionWizardNewTransaction;

  /// No description provided for @historyFilterApply.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar Filtros'**
  String get historyFilterApply;

  /// No description provided for @historyFilterClear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get historyFilterClear;

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

  /// No description provided for @workspaceSettingsEditNameDesc.
  ///
  /// In pt, this message translates to:
  /// **'Altere o nome do seu workspace para melhor identificação.'**
  String get workspaceSettingsEditNameDesc;

  /// No description provided for @workspaceSettingsCategoriesDesc.
  ///
  /// In pt, this message translates to:
  /// **'Gerencie as categorias de receitas e despesas do seu workspace.'**
  String get workspaceSettingsCategoriesDesc;

  /// No description provided for @workspaceSettingsAccountsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Configure suas contas bancárias, cartões de crédito e investimentos.'**
  String get workspaceSettingsAccountsDesc;

  /// No description provided for @workspaceSettingsMembersDesc.
  ///
  /// In pt, this message translates to:
  /// **'Convide sócios ou familiares para gerirem as finanças juntos.'**
  String get workspaceSettingsMembersDesc;

  /// No description provided for @workspaceSettingsLogout.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get workspaceSettingsLogout;

  /// No description provided for @workspaceSettingsLogoutDesc.
  ///
  /// In pt, this message translates to:
  /// **'Encerre sua sessão atual de forma segura.'**
  String get workspaceSettingsLogoutDesc;

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

  /// No description provided for @reconciliationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Conciliação Bancária'**
  String get reconciliationTitle;

  /// No description provided for @reconciliationTransactionsFound.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhuma transação encontrada} =1{1 transação encontrada} other{{count} transações encontradas}}'**
  String reconciliationTransactionsFound(num count);

  /// No description provided for @reconciliationSelectAccount.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o arquivo de extrato ou fatura'**
  String get reconciliationSelectAccount;

  /// No description provided for @reconciliationSupportedFormats.
  ///
  /// In pt, this message translates to:
  /// **'Suporta PDF, OFX e Imagens (PNG, JPG)'**
  String get reconciliationSupportedFormats;

  /// No description provided for @reconciliationChooseFile.
  ///
  /// In pt, this message translates to:
  /// **'Escolher Arquivo'**
  String get reconciliationChooseFile;

  /// No description provided for @reconciliationAnalyzing.
  ///
  /// In pt, this message translates to:
  /// **'Analisando seu extrato'**
  String get reconciliationAnalyzing;

  /// No description provided for @reconciliationAnalyzingDesc.
  ///
  /// In pt, this message translates to:
  /// **'A IA está processando as transações do seu documento para conciliação.'**
  String get reconciliationAnalyzingDesc;

  /// No description provided for @reconciliationConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get reconciliationConfirm;

  /// No description provided for @reconciliationBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get reconciliationBack;

  /// No description provided for @reconciliationSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Conciliação realizada com sucesso!'**
  String get reconciliationSuccess;

  /// No description provided for @reconciliationStatusMatched.
  ///
  /// In pt, this message translates to:
  /// **'Encontrado'**
  String get reconciliationStatusMatched;

  /// No description provided for @reconciliationStatusSuggested.
  ///
  /// In pt, this message translates to:
  /// **'Sugerido'**
  String get reconciliationStatusSuggested;

  /// No description provided for @reconciliationStatusUnmatched.
  ///
  /// In pt, this message translates to:
  /// **'Novo'**
  String get reconciliationStatusUnmatched;

  /// No description provided for @reconciliationStatusIgnored.
  ///
  /// In pt, this message translates to:
  /// **'Ignorado'**
  String get reconciliationStatusIgnored;

  /// No description provided for @reconciliationActionConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get reconciliationActionConfirm;

  /// No description provided for @reconciliationActionModify.
  ///
  /// In pt, this message translates to:
  /// **'Modificar'**
  String get reconciliationActionModify;

  /// No description provided for @reconciliationActionIgnore.
  ///
  /// In pt, this message translates to:
  /// **'Ignorar'**
  String get reconciliationActionIgnore;

  /// No description provided for @reconciliationActionRestore.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar'**
  String get reconciliationActionRestore;

  /// No description provided for @reconciliationActionLink.
  ///
  /// In pt, this message translates to:
  /// **'Vincular'**
  String get reconciliationActionLink;

  /// No description provided for @reconciliationActionRegister.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar'**
  String get reconciliationActionRegister;

  /// No description provided for @reconciliationActionAnalyze.
  ///
  /// In pt, this message translates to:
  /// **'Analisar Extrato'**
  String get reconciliationActionAnalyze;

  /// No description provided for @reconciliationSystemLabel.
  ///
  /// In pt, this message translates to:
  /// **'SISTEMA'**
  String get reconciliationSystemLabel;

  /// No description provided for @reconciliationExtratoLabel.
  ///
  /// In pt, this message translates to:
  /// **'EXTRATO'**
  String get reconciliationExtratoLabel;

  /// No description provided for @reconciliationNoMatchFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma transação correlata encontrada'**
  String get reconciliationNoMatchFound;

  /// No description provided for @reconciliationSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Conciliação'**
  String get reconciliationSectionTitle;

  /// No description provided for @reconciliationSectionDesc.
  ///
  /// In pt, this message translates to:
  /// **'Compare seus registros com o extrato bancário real.'**
  String get reconciliationSectionDesc;

  /// No description provided for @reconciliationChangeAccount.
  ///
  /// In pt, this message translates to:
  /// **'Alterar'**
  String get reconciliationChangeAccount;

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

  /// No description provided for @addWorkspaceButton.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Workspace'**
  String get addWorkspaceButton;

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

  /// No description provided for @transactionPlanTransfer.
  ///
  /// In pt, this message translates to:
  /// **'Planejar Transferência'**
  String get transactionPlanTransfer;

  /// No description provided for @transactionActionTransfer.
  ///
  /// In pt, this message translates to:
  /// **'Transferência'**
  String get transactionActionTransfer;

  /// No description provided for @transactionCategoriesSection.
  ///
  /// In pt, this message translates to:
  /// **'Categorias'**
  String get transactionCategoriesSection;

  /// No description provided for @transactionRealizedSection.
  ///
  /// In pt, this message translates to:
  /// **'Lançamentos Realizados'**
  String get transactionRealizedSection;

  /// No description provided for @transactionRealizedSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Transações que já aconteceram e impactaram seu saldo.'**
  String get transactionRealizedSubtitle;

  /// No description provided for @transactionPlannedSection.
  ///
  /// In pt, this message translates to:
  /// **'Agendamentos'**
  String get transactionPlannedSection;

  /// No description provided for @transactionPlannedSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Controle suas contas a pagar e a receber que estão por vir.'**
  String get transactionPlannedSubtitle;

  /// No description provided for @planningSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estratégia'**
  String get planningSectionTitle;

  /// No description provided for @planningSectionSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Defina limites e acompanhe sua distribuição de gastos ideal.'**
  String get planningSectionSubtitle;

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

  /// No description provided for @transactionAmountTotalLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor Total'**
  String get transactionAmountTotalLabel;

  /// No description provided for @transactionAmountInstallmentLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor da Parcela'**
  String get transactionAmountInstallmentLabel;

  /// No description provided for @transactionAmountRecurringLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor Recorrente'**
  String get transactionAmountRecurringLabel;

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

  /// No description provided for @transactionStatusSettled.
  ///
  /// In pt, this message translates to:
  /// **'Consolidado'**
  String get transactionStatusSettled;

  /// No description provided for @transactionStatusPaid.
  ///
  /// In pt, this message translates to:
  /// **'Pago'**
  String get transactionStatusPaid;

  /// No description provided for @transactionStatusPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get transactionStatusPending;

  /// No description provided for @transactionStatusPlanning.
  ///
  /// In pt, this message translates to:
  /// **'Planejamento'**
  String get transactionStatusPlanning;

  /// No description provided for @transactionStatusRealized.
  ///
  /// In pt, this message translates to:
  /// **'Realizado'**
  String get transactionStatusRealized;

  /// No description provided for @transactionStatusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get transactionStatusLabel;

  /// No description provided for @transactionStatusTypeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Cadastro'**
  String get transactionStatusTypeLabel;

  /// No description provided for @transactionSettledAlert.
  ///
  /// In pt, this message translates to:
  /// **'Este lançamento não pode ser modificado pois já foi consolidado.'**
  String get transactionSettledAlert;

  /// No description provided for @transactionUnsettleAction.
  ///
  /// In pt, this message translates to:
  /// **'Desfazer conciliação'**
  String get transactionUnsettleAction;

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

  /// No description provided for @transactionTypeInvoice.
  ///
  /// In pt, this message translates to:
  /// **'Fatura'**
  String get transactionTypeInvoice;

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

  /// No description provided for @transactionCascadeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar alterações'**
  String get transactionCascadeTitle;

  /// No description provided for @transactionCascadeDescription.
  ///
  /// In pt, this message translates to:
  /// **'Deseja aplicar estas alterações apenas a esta parcela ou replicar para as demais?'**
  String get transactionCascadeDescription;

  /// No description provided for @transactionCascadeOnlyThis.
  ///
  /// In pt, this message translates to:
  /// **'Apenas esta'**
  String get transactionCascadeOnlyThis;

  /// No description provided for @transactionCascadeThisAndNext.
  ///
  /// In pt, this message translates to:
  /// **'Esta e próximas'**
  String get transactionCascadeThisAndNext;

  /// No description provided for @transactionCascadeAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get transactionCascadeAll;

  /// No description provided for @transactionDeleteCascadeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir parcelas'**
  String get transactionDeleteCascadeTitle;

  /// No description provided for @transactionDeleteCascadeDescription.
  ///
  /// In pt, this message translates to:
  /// **'Deseja excluir apenas esta parcela ou as demais também?'**
  String get transactionDeleteCascadeDescription;

  /// No description provided for @transactionDeleteCascadeOnlyThis.
  ///
  /// In pt, this message translates to:
  /// **'Apenas esta'**
  String get transactionDeleteCascadeOnlyThis;

  /// No description provided for @transactionDeleteCascadeThisAndNext.
  ///
  /// In pt, this message translates to:
  /// **'Esta e próximas'**
  String get transactionDeleteCascadeThisAndNext;

  /// No description provided for @transactionDeleteCascadeAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get transactionDeleteCascadeAll;

  /// No description provided for @transactionDueDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Vencimento'**
  String get transactionDueDateLabel;

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

  /// No description provided for @accountMethodDocument.
  ///
  /// In pt, this message translates to:
  /// **'Por Documento'**
  String get accountMethodDocument;

  /// No description provided for @accountMethodManual.
  ///
  /// In pt, this message translates to:
  /// **'Manual'**
  String get accountMethodManual;

  /// No description provided for @accountDocumentDescription.
  ///
  /// In pt, this message translates to:
  /// **'Anexe seu extrato bancário (PDF) ou arquivo de transações (OFX). Nossa IA analisará os dados para configurar sua conta, saldo e transações automaticamente.'**
  String get accountDocumentDescription;

  /// No description provided for @accountDocumentAcceptedTypes.
  ///
  /// In pt, this message translates to:
  /// **'Formatos aceitos: PDF, OFX'**
  String get accountDocumentAcceptedTypes;

  /// No description provided for @accountManualDescription.
  ///
  /// In pt, this message translates to:
  /// **'Preencha os dados da conta manualmente caso não possua um documento ou prefira configurar do seu jeito.'**
  String get accountManualDescription;

  /// No description provided for @accountDetectedDataTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dados detectados por IA'**
  String get accountDetectedDataTitle;

  /// No description provided for @accountDetectedTransactions.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 transação encontrada} other{{count} transações encontradas}}'**
  String accountDetectedTransactions(num count);

  /// No description provided for @accountDetectedPlannings.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 planejamento sugerido} other{{count} planejamentos sugeridos}}'**
  String accountDetectedPlannings(num count);

  /// No description provided for @accountDetectedConfirmation.
  ///
  /// In pt, this message translates to:
  /// **'Confirme os dados abaixo para concluir o registro.'**
  String get accountDetectedConfirmation;

  /// No description provided for @accountSelectFile.
  ///
  /// In pt, this message translates to:
  /// **'SELECIONAR ARQUIVO'**
  String get accountSelectFile;

  /// No description provided for @accountDropFile.
  ///
  /// In pt, this message translates to:
  /// **'Arraste e solte o arquivo aqui ou clique para selecionar'**
  String get accountDropFile;

  /// No description provided for @accountAnalyzing.
  ///
  /// In pt, this message translates to:
  /// **'Analisando documento...'**
  String get accountAnalyzing;

  /// No description provided for @accountAnalysisDescription.
  ///
  /// In pt, this message translates to:
  /// **'Nossa IA está analisando seu documento para preparar os dados da sua conta e identificar transações automaticamente.'**
  String get accountAnalysisDescription;

  /// No description provided for @accountAnalysisProcessing.
  ///
  /// In pt, this message translates to:
  /// **'Processando dados...'**
  String get accountAnalysisProcessing;

  /// No description provided for @accountAnalysisFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falha no processamento '**
  String get accountAnalysisFailed;

  /// No description provided for @onboardingPlanningAnalyzingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Analisando padrões...'**
  String get onboardingPlanningAnalyzingTitle;

  /// No description provided for @onboardingPlanningAnalyzingDesc.
  ///
  /// In pt, this message translates to:
  /// **'Nossa IA está analisando seus padrões de gastos para sugerir metas e planejamentos ideais para você.'**
  String get onboardingPlanningAnalyzingDesc;

  /// No description provided for @accountViewTransactions.
  ///
  /// In pt, this message translates to:
  /// **'Ver Transações'**
  String get accountViewTransactions;

  /// No description provided for @accountViewPlannings.
  ///
  /// In pt, this message translates to:
  /// **'Ver Planejamentos'**
  String get accountViewPlannings;

  /// No description provided for @accountDetectedTransactionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Transações Detectadas'**
  String get accountDetectedTransactionsTitle;

  /// No description provided for @accountDetectedPlanningsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Planejamentos Sugeridos'**
  String get accountDetectedPlanningsTitle;

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
  /// **'Selecione a Conta de Destino'**
  String get transactionSelectDestinationAccount;

  /// No description provided for @transactionAddExpenseDesc.
  ///
  /// In pt, this message translates to:
  /// **'Registre uma despesa pontual que ocorreu hoje ou no passado.'**
  String get transactionAddExpenseDesc;

  /// No description provided for @transactionAddIncomeDesc.
  ///
  /// In pt, this message translates to:
  /// **'Registre uma receita pontual que ocorreu hoje ou no passado.'**
  String get transactionAddIncomeDesc;

  /// No description provided for @transactionPlanExpenseDesc.
  ///
  /// In pt, this message translates to:
  /// **'Agende uma despesa futura, recorrente ou parcelada.'**
  String get transactionPlanExpenseDesc;

  /// No description provided for @transactionPlanIncomeDesc.
  ///
  /// In pt, this message translates to:
  /// **'Agende uma receita futura, recorrente ou parcelada.'**
  String get transactionPlanIncomeDesc;

  /// No description provided for @transactionTransferDesc.
  ///
  /// In pt, this message translates to:
  /// **'Movimente saldo entre suas contas bancárias ou cartões.'**
  String get transactionTransferDesc;

  /// No description provided for @transactionOrderTypeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tipo do Lançamento'**
  String get transactionOrderTypeLabel;

  /// No description provided for @clear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get clear;

  /// No description provided for @validationEmailMessage.
  ///
  /// In pt, this message translates to:
  /// **'E-mail inválido'**
  String get validationEmailMessage;

  /// No description provided for @validationLengthMaxMessage.
  ///
  /// In pt, this message translates to:
  /// **'Deve possuir no mínimo {min} caracteres.'**
  String validationLengthMaxMessage(Object min);

  /// No description provided for @validationLenghtMinMessage.
  ///
  /// In pt, this message translates to:
  /// **'Deve possuir no máximo {max} caracteres.'**
  String validationLenghtMinMessage(Object max);

  /// No description provided for @validationNotEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Campo obrigatório.'**
  String get validationNotEmptyMessage;

  /// No description provided for @validationNotNullMessage.
  ///
  /// In pt, this message translates to:
  /// **'Campo obrigatório.'**
  String get validationNotNullMessage;

  /// No description provided for @noRecordsFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum registro encontrado.'**
  String get noRecordsFound;

  /// No description provided for @formatSimpleDate.
  ///
  /// In pt, this message translates to:
  /// **'dd/MM/yyyy'**
  String get formatSimpleDate;

  /// No description provided for @errorLoadingData.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao carregar os dados.'**
  String get errorLoadingData;

  /// No description provided for @retry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get retry;

  /// No description provided for @planningExpenseLimits.
  ///
  /// In pt, this message translates to:
  /// **'Limites de Despesas'**
  String get planningExpenseLimits;

  /// No description provided for @planningIncomeLimits.
  ///
  /// In pt, this message translates to:
  /// **'Expectativa de Receitas'**
  String get planningIncomeLimits;

  /// No description provided for @planningLimitDefined.
  ///
  /// In pt, this message translates to:
  /// **'Expectativa definida'**
  String get planningLimitDefined;

  /// No description provided for @planningSave.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR'**
  String get planningSave;

  /// No description provided for @expenses.
  ///
  /// In pt, this message translates to:
  /// **'Despesas'**
  String get expenses;

  /// No description provided for @incomes.
  ///
  /// In pt, this message translates to:
  /// **'Receitas'**
  String get incomes;

  /// No description provided for @balance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo'**
  String get balance;

  /// No description provided for @securePasswordAtLeast8Characters.
  ///
  /// In pt, this message translates to:
  /// **'Ao menos 8 caracteres'**
  String get securePasswordAtLeast8Characters;

  /// No description provided for @securePasswordAtMost50Characters.
  ///
  /// In pt, this message translates to:
  /// **'No máximo 50 caracteres'**
  String get securePasswordAtMost50Characters;

  /// No description provided for @securePasswordDontUseSpaces.
  ///
  /// In pt, this message translates to:
  /// **'Não use espaços'**
  String get securePasswordDontUseSpaces;

  /// No description provided for @securePasswordAtLeast1Uppercase.
  ///
  /// In pt, this message translates to:
  /// **'Ao menos um caracter maiúsculo'**
  String get securePasswordAtLeast1Uppercase;

  /// No description provided for @securePasswordAtLeast1Lowercase.
  ///
  /// In pt, this message translates to:
  /// **'Ao menos um caracter minúsculo'**
  String get securePasswordAtLeast1Lowercase;

  /// No description provided for @securePasswordAtLeast1Number.
  ///
  /// In pt, this message translates to:
  /// **'Ao menos um número'**
  String get securePasswordAtLeast1Number;

  /// No description provided for @signUpFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao tentar realizar o cadastro. Tente novamente ou contate nosso suporte.'**
  String get signUpFailed;

  /// No description provided for @signInFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao tentar realizar o acesso. Tente novamente ou contate nosso suporte.'**
  String get signInFailed;

  /// No description provided for @dateInputPattern.
  ///
  /// In pt, this message translates to:
  /// **'dd/MM/yyyy'**
  String get dateInputPattern;

  /// No description provided for @installmentCountDescription.
  ///
  /// In pt, this message translates to:
  /// **'{number} de {count}'**
  String installmentCountDescription(Object count, Object number);

  /// No description provided for @statusPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get statusPending;

  /// No description provided for @statusPaid.
  ///
  /// In pt, this message translates to:
  /// **'Pago'**
  String get statusPaid;

  /// No description provided for @statusSettled.
  ///
  /// In pt, this message translates to:
  /// **'Conciliado'**
  String get statusSettled;

  /// No description provided for @date.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get date;

  /// No description provided for @historyAccountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get historyAccountLabel;

  /// No description provided for @periodSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo do Período'**
  String get periodSummary;

  /// No description provided for @totalIncomes.
  ///
  /// In pt, this message translates to:
  /// **'Total de Receitas'**
  String get totalIncomes;

  /// No description provided for @totalExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Total de Despesas'**
  String get totalExpenses;

  /// No description provided for @totalTransfers.
  ///
  /// In pt, this message translates to:
  /// **'Total de Transferências'**
  String get totalTransfers;

  /// No description provided for @totalInvoices.
  ///
  /// In pt, this message translates to:
  /// **'Total de Faturas'**
  String get totalInvoices;

  /// No description provided for @periodBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo do Período'**
  String get periodBalance;

  /// No description provided for @plannedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Planejado'**
  String get plannedLabel;

  /// No description provided for @realizedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Realizado'**
  String get realizedLabel;

  /// No description provided for @periodFilterDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia'**
  String get periodFilterDay;

  /// No description provided for @periodFilterMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês'**
  String get periodFilterMonth;

  /// No description provided for @periodFilterQuarter.
  ///
  /// In pt, this message translates to:
  /// **'Trimestre'**
  String get periodFilterQuarter;

  /// No description provided for @periodFilterSemester.
  ///
  /// In pt, this message translates to:
  /// **'Semestre'**
  String get periodFilterSemester;

  /// No description provided for @periodFilterYear.
  ///
  /// In pt, this message translates to:
  /// **'Ano'**
  String get periodFilterYear;

  /// No description provided for @periodFilterCustom.
  ///
  /// In pt, this message translates to:
  /// **'Customizado'**
  String get periodFilterCustom;

  /// No description provided for @periodFilterTitle.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Período'**
  String get periodFilterTitle;

  /// No description provided for @completedMissionsSummary.
  ///
  /// In pt, this message translates to:
  /// **'{count} {count, plural, =1{item} other{itens}} • {xp} XP'**
  String completedMissionsSummary(num count, Object xp);

  /// No description provided for @registerEffectivation.
  ///
  /// In pt, this message translates to:
  /// **'Marcar como realizado'**
  String get registerEffectivation;

  /// No description provided for @returnToPending.
  ///
  /// In pt, this message translates to:
  /// **'Retornar para Pendente'**
  String get returnToPending;

  /// No description provided for @partyHpLabel.
  ///
  /// In pt, this message translates to:
  /// **'Saúde da Equipe'**
  String get partyHpLabel;

  /// No description provided for @partyStatusHealthy.
  ///
  /// In pt, this message translates to:
  /// **'Equipe em Segurança'**
  String get partyStatusHealthy;

  /// No description provided for @partyStatusStrained.
  ///
  /// In pt, this message translates to:
  /// **'Equipe em Perigo'**
  String get partyStatusStrained;

  /// No description provided for @partyStatusDefeated.
  ///
  /// In pt, this message translates to:
  /// **'Equipe Derrotada'**
  String get partyStatusDefeated;

  /// No description provided for @partyTeamTitle.
  ///
  /// In pt, this message translates to:
  /// **'Equipe'**
  String get partyTeamTitle;

  /// No description provided for @planned.
  ///
  /// In pt, this message translates to:
  /// **'Planejado'**
  String get planned;

  /// No description provided for @actual.
  ///
  /// In pt, this message translates to:
  /// **'Realizado'**
  String get actual;

  /// No description provided for @excess.
  ///
  /// In pt, this message translates to:
  /// **'Excesso'**
  String get excess;

  /// No description provided for @invoiceDetailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Detalhe de Fatura'**
  String get invoiceDetailTitle;

  /// No description provided for @registerInvoicePayment.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Pagamento de Fatura'**
  String get registerInvoicePayment;

  /// No description provided for @coachingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Coach Financeiro'**
  String get coachingTitle;

  /// No description provided for @coachingConsultAction.
  ///
  /// In pt, this message translates to:
  /// **'Consultar Coach'**
  String get coachingConsultAction;

  /// No description provided for @coachingViewLast.
  ///
  /// In pt, this message translates to:
  /// **'Ver última análise'**
  String get coachingViewLast;

  /// No description provided for @coachingLastAnalysisFrom.
  ///
  /// In pt, this message translates to:
  /// **'Última análise de {date}'**
  String coachingLastAnalysisFrom(String date);

  /// No description provided for @coachingWaitSevenDays.
  ///
  /// In pt, this message translates to:
  /// **'Você poderá consultar o coach novamente em {days} dias.'**
  String coachingWaitSevenDays(int days);

  /// No description provided for @coachingWaitLessOneDay.
  ///
  /// In pt, this message translates to:
  /// **'Você poderá consultar o coach novamente amanhã.'**
  String get coachingWaitLessOneDay;

  /// No description provided for @coachingConsulting.
  ///
  /// In pt, this message translates to:
  /// **'Consultando Coach...'**
  String get coachingConsulting;

  /// No description provided for @coachingConsultingDesc.
  ///
  /// In pt, this message translates to:
  /// **'Nossa IA está analisando sua saúde financeira para dar os melhores conselhos.'**
  String get coachingConsultingDesc;

  /// No description provided for @coachingError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao consultar coach. Tente novamente mais tarde.'**
  String get coachingError;

  /// No description provided for @coachingSlideNext.
  ///
  /// In pt, this message translates to:
  /// **'Próximo'**
  String get coachingSlideNext;

  /// No description provided for @coachingSlideBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get coachingSlideBack;

  /// No description provided for @coachingSlideFinish.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get coachingSlideFinish;

  /// No description provided for @coachingNoData.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum dado de coaching disponível.'**
  String get coachingNoData;

  /// No description provided for @coachingNoSlides.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum slide foi gerado. Tente novamente.'**
  String get coachingNoSlides;

  /// No description provided for @weeklyMissionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Missões Semanais'**
  String get weeklyMissionsTitle;

  /// No description provided for @accountStatementCurrent.
  ///
  /// In pt, this message translates to:
  /// **'Atual'**
  String get accountStatementCurrent;

  /// No description provided for @accountStatementFuture.
  ///
  /// In pt, this message translates to:
  /// **'Futuros'**
  String get accountStatementFuture;

  /// No description provided for @currentBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo Atual'**
  String get currentBalance;

  /// No description provided for @transactions.
  ///
  /// In pt, this message translates to:
  /// **'Lançamentos'**
  String get transactions;
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
