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

  /// No description provided for @editButton.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get editButton;

  /// No description provided for @deleteButton.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get deleteButton;

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

  /// No description provided for @appErrorWidgetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Algo deu errado'**
  String get appErrorWidgetTitle;

  /// No description provided for @appErrorWidgetMessage.
  ///
  /// In pt, this message translates to:
  /// **'Já fomos avisados e estamos trabalhando nisso. Tente voltar e abrir a tela de novo.'**
  String get appErrorWidgetMessage;

  /// No description provided for @errorUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro inesperado.'**
  String get errorUnknown;

  /// No description provided for @routeNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Página não encontrada.'**
  String get routeNotFound;

  /// No description provided for @routeNotFoundGoHome.
  ///
  /// In pt, this message translates to:
  /// **'Voltar para o início'**
  String get routeNotFoundGoHome;

  /// No description provided for @closeButton.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get closeButton;

  /// No description provided for @badgeUnlockedToast.
  ///
  /// In pt, this message translates to:
  /// **'Nova conquista desbloqueada!'**
  String get badgeUnlockedToast;

  /// No description provided for @badgeUnlockedView.
  ///
  /// In pt, this message translates to:
  /// **'Ver'**
  String get badgeUnlockedView;

  /// No description provided for @workspacePickerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Workspaces'**
  String get workspacePickerTitle;

  /// No description provided for @transactionMoreOptions.
  ///
  /// In pt, this message translates to:
  /// **'Mais Opções'**
  String get transactionMoreOptions;

  /// No description provided for @transactionMatchTitle.
  ///
  /// In pt, this message translates to:
  /// **'Existe um agendamento nesta categoria. Quitar este?'**
  String get transactionMatchTitle;

  /// No description provided for @transactionMatchSettle.
  ///
  /// In pt, this message translates to:
  /// **'Quitar'**
  String get transactionMatchSettle;

  /// No description provided for @transactionMatchDismiss.
  ///
  /// In pt, this message translates to:
  /// **'É um gasto novo'**
  String get transactionMatchDismiss;

  /// No description provided for @transactionMatchDismissIncome.
  ///
  /// In pt, this message translates to:
  /// **'É uma receita nova'**
  String get transactionMatchDismissIncome;

  /// No description provided for @onboardingConceptXpTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ganhe XP e suba de nível'**
  String get onboardingConceptXpTitle;

  /// No description provided for @onboardingConceptXpDesc.
  ///
  /// In pt, this message translates to:
  /// **'Cada lançamento vale XP — e gastar dentro do planejado vale ainda mais. Seu workspace evolui de nível como num jogo.'**
  String get onboardingConceptXpDesc;

  /// No description provided for @onboardingConceptMissionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Missões e conquistas'**
  String get onboardingConceptMissionsTitle;

  /// No description provided for @onboardingConceptMissionsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Complete missões semanais, mantenha sua sequência de semanas perfeitas e desbloqueie insígnias na sua vitrine de conquistas.'**
  String get onboardingConceptMissionsDesc;

  /// No description provided for @onboardingConceptCoachTitle.
  ///
  /// In pt, this message translates to:
  /// **'Seu coach financeiro'**
  String get onboardingConceptCoachTitle;

  /// No description provided for @onboardingConceptCoachDesc.
  ///
  /// In pt, this message translates to:
  /// **'Um coach com IA que conhece seus números e traz conselhos práticos e personalizados rumo à sua liberdade financeira.'**
  String get onboardingConceptCoachDesc;

  /// No description provided for @onboardingNoSuggestions.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma sugestão por enquanto — você pode criar metas e planejamentos depois, na aba Jornada.'**
  String get onboardingNoSuggestions;

  /// No description provided for @journeyStreakWeeks.
  ///
  /// In pt, this message translates to:
  /// **'{count} semanas perfeitas seguidas'**
  String journeyStreakWeeks(int count);

  /// No description provided for @journeyAddGoalTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Nova meta'**
  String get journeyAddGoalTooltip;

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
  /// **'Agendamentos'**
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

  /// No description provided for @goalDetailsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes da Meta'**
  String get goalDetailsTitle;

  /// No description provided for @goalTransactionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Transações Relacionadas'**
  String get goalTransactionsTitle;

  /// No description provided for @goalEditButton.
  ///
  /// In pt, this message translates to:
  /// **'Editar Meta'**
  String get goalEditButton;

  /// No description provided for @goalDeleteButton.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Meta'**
  String get goalDeleteButton;

  /// No description provided for @goalDeleteConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Meta?'**
  String get goalDeleteConfirmTitle;

  /// No description provided for @goalDeleteConfirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir esta meta? Esta ação não pode ser desfeita.'**
  String get goalDeleteConfirmMessage;

  /// No description provided for @goalStatusOnTrack.
  ///
  /// In pt, this message translates to:
  /// **'No Caminho'**
  String get goalStatusOnTrack;

  /// No description provided for @goalStatusAtRisk.
  ///
  /// In pt, this message translates to:
  /// **'Em Risco'**
  String get goalStatusAtRisk;

  /// No description provided for @goalStatusBehind.
  ///
  /// In pt, this message translates to:
  /// **'Atrasada'**
  String get goalStatusBehind;

  /// No description provided for @goalStatusLost.
  ///
  /// In pt, this message translates to:
  /// **'Perdida'**
  String get goalStatusLost;

  /// No description provided for @goalProgressChartTitle.
  ///
  /// In pt, this message translates to:
  /// **'Progresso'**
  String get goalProgressChartTitle;

  /// No description provided for @goalChartIdealLine.
  ///
  /// In pt, this message translates to:
  /// **'Ideal'**
  String get goalChartIdealLine;

  /// No description provided for @goalChartRealLine.
  ///
  /// In pt, this message translates to:
  /// **'Real'**
  String get goalChartRealLine;

  /// No description provided for @goalChartStartLabel.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get goalChartStartLabel;

  /// No description provided for @goalChartEndLabel.
  ///
  /// In pt, this message translates to:
  /// **'Prazo'**
  String get goalChartEndLabel;

  /// No description provided for @goalMilestone25.
  ///
  /// In pt, this message translates to:
  /// **'25%'**
  String get goalMilestone25;

  /// No description provided for @goalMilestone50.
  ///
  /// In pt, this message translates to:
  /// **'50%'**
  String get goalMilestone50;

  /// No description provided for @goalMilestone75.
  ///
  /// In pt, this message translates to:
  /// **'75%'**
  String get goalMilestone75;

  /// No description provided for @goalMilestone100.
  ///
  /// In pt, this message translates to:
  /// **'100%'**
  String get goalMilestone100;

  /// No description provided for @goalAnalyzeWithAi.
  ///
  /// In pt, this message translates to:
  /// **'Analisar com IA'**
  String get goalAnalyzeWithAi;

  /// No description provided for @goalAiError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível analisar a meta. Tente novamente.'**
  String get goalAiError;

  /// No description provided for @reconciliationError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível analisar o extrato. Tente novamente.'**
  String get reconciliationError;

  /// No description provided for @goalAiAnalyzing.
  ///
  /// In pt, this message translates to:
  /// **'Analisando sua meta...'**
  String get goalAiAnalyzing;

  /// No description provided for @goalAiAnalyzingDesc.
  ///
  /// In pt, this message translates to:
  /// **'Nossa IA está examinando seu histórico financeiro para avaliar a viabilidade desta meta.'**
  String get goalAiAnalyzingDesc;

  /// No description provided for @goalAiFeasible.
  ///
  /// In pt, this message translates to:
  /// **'Viável'**
  String get goalAiFeasible;

  /// No description provided for @goalAiChallenging.
  ///
  /// In pt, this message translates to:
  /// **'Desafiadora'**
  String get goalAiChallenging;

  /// No description provided for @goalAiUnrealistic.
  ///
  /// In pt, this message translates to:
  /// **'Irrealista'**
  String get goalAiUnrealistic;

  /// No description provided for @goalAiResultTitle.
  ///
  /// In pt, this message translates to:
  /// **'Análise da Meta'**
  String get goalAiResultTitle;

  /// No description provided for @goalAiReason.
  ///
  /// In pt, this message translates to:
  /// **'Por quê:'**
  String get goalAiReason;

  /// No description provided for @goalAiSuggestion.
  ///
  /// In pt, this message translates to:
  /// **'Sugestão:'**
  String get goalAiSuggestion;

  /// No description provided for @goalAiClose.
  ///
  /// In pt, this message translates to:
  /// **'Entendi'**
  String get goalAiClose;

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

  /// No description provided for @profileTitle.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @profileEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Perfil'**
  String get profileEditTitle;

  /// No description provided for @profileNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get profileNameLabel;

  /// No description provided for @profileEmailLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get profileEmailLabel;

  /// No description provided for @profileSaveButton.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Alterações'**
  String get profileSaveButton;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Perfil atualizado com sucesso!'**
  String get profileUpdateSuccess;

  /// No description provided for @profileUpdateError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar perfil.'**
  String get profileUpdateError;

  /// No description provided for @profilePhotoSourceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha a origem da foto'**
  String get profilePhotoSourceTitle;

  /// No description provided for @profilePhotoCamera.
  ///
  /// In pt, this message translates to:
  /// **'Câmera'**
  String get profilePhotoCamera;

  /// No description provided for @profilePhotoGallery.
  ///
  /// In pt, this message translates to:
  /// **'Galeria'**
  String get profilePhotoGallery;

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

  /// No description provided for @planning503020Subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhe sua regra de ouro 50-30-20'**
  String get planning503020Subtitle;

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

  /// No description provided for @uploadFileUnreadable.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível ler o arquivo.'**
  String get uploadFileUnreadable;

  /// No description provided for @uploadUnsupportedFormat.
  ///
  /// In pt, this message translates to:
  /// **'Formato não suportado. Use apenas: {formats}'**
  String uploadUnsupportedFormat(String formats);

  /// No description provided for @uploadFileTooLarge.
  ///
  /// In pt, this message translates to:
  /// **'Este arquivo tem {size} e o limite da análise é {limit} MB. Exporte o extrato em OFX, que é bem menor que o PDF, ou divida em períodos mais curtos.'**
  String uploadFileTooLarge(String size, int limit);

  /// No description provided for @membersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Membros'**
  String get membersTitle;

  /// No description provided for @membersOwnerRole.
  ///
  /// In pt, this message translates to:
  /// **'Dono'**
  String get membersOwnerRole;

  /// No description provided for @membersMemberRole.
  ///
  /// In pt, this message translates to:
  /// **'Membro'**
  String get membersMemberRole;

  /// No description provided for @membersYou.
  ///
  /// In pt, this message translates to:
  /// **'você'**
  String get membersYou;

  /// No description provided for @membersSectionActive.
  ///
  /// In pt, this message translates to:
  /// **'No workspace'**
  String get membersSectionActive;

  /// No description provided for @membersSectionPending.
  ///
  /// In pt, this message translates to:
  /// **'Convites aguardando resposta'**
  String get membersSectionPending;

  /// No description provided for @membersEmptyPending.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum convite aguardando resposta.'**
  String get membersEmptyPending;

  /// No description provided for @membersLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os membros.'**
  String get membersLoadError;

  /// No description provided for @membersInvitesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os convites.'**
  String get membersInvitesLoadError;

  /// No description provided for @membersRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get membersRetry;

  /// No description provided for @membersRemoveAction.
  ///
  /// In pt, this message translates to:
  /// **'Remover do workspace'**
  String get membersRemoveAction;

  /// No description provided for @membersRemoveTitle.
  ///
  /// In pt, this message translates to:
  /// **'Remover {name}?'**
  String membersRemoveTitle(String name);

  /// No description provided for @membersRemoveConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Essa pessoa perde o acesso a este workspace. Os lançamentos, contas e categorias continuam onde estão — eles são do workspace, não de quem os criou.'**
  String get membersRemoveConfirm;

  /// No description provided for @membersRemoveSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Membro removido.'**
  String get membersRemoveSuccess;

  /// No description provided for @membersRemoveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível remover o membro.'**
  String get membersRemoveError;

  /// No description provided for @membersInviteSentAt.
  ///
  /// In pt, this message translates to:
  /// **'Convidado em {date}'**
  String membersInviteSentAt(String date);

  /// No description provided for @membersResendAction.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar'**
  String get membersResendAction;

  /// No description provided for @membersResendSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Convite renovado.'**
  String get membersResendSuccess;

  /// No description provided for @membersResendError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível renovar o convite.'**
  String get membersResendError;

  /// No description provided for @membersCancelInviteAction.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar convite'**
  String get membersCancelInviteAction;

  /// No description provided for @membersCancelInviteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar o convite de {email}?'**
  String membersCancelInviteTitle(String email);

  /// No description provided for @membersCancelInviteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'O convite deixa de aparecer para quem foi convidado.'**
  String get membersCancelInviteConfirm;

  /// No description provided for @membersCancelInviteSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Convite cancelado.'**
  String get membersCancelInviteSuccess;

  /// No description provided for @membersCancelInviteError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível cancelar o convite.'**
  String get membersCancelInviteError;

  /// No description provided for @membersOnlyOwnerCanRemove.
  ///
  /// In pt, this message translates to:
  /// **'Apenas o dono do workspace pode remover membros.'**
  String get membersOnlyOwnerCanRemove;

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

  /// No description provided for @historyFilterAccountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get historyFilterAccountLabel;

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
  /// **'Agendar Despesa'**
  String get transactionPlanExpense;

  /// No description provided for @transactionPlanIncome.
  ///
  /// In pt, this message translates to:
  /// **'Agendar Receita'**
  String get transactionPlanIncome;

  /// No description provided for @transactionPlanTransfer.
  ///
  /// In pt, this message translates to:
  /// **'Agendar Transferência'**
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
  /// **'Registrei'**
  String get transactionRealizedSection;

  /// No description provided for @transactionRealizedSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Já aconteceu e já mexeu no seu saldo.'**
  String get transactionRealizedSubtitle;

  /// No description provided for @transactionPlannedSection.
  ///
  /// In pt, this message translates to:
  /// **'Agendar'**
  String get transactionPlannedSection;

  /// No description provided for @transactionPlannedSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Ainda vai acontecer: contas a pagar e a receber.'**
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

  /// No description provided for @transactionStatusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get transactionStatusLabel;

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

  /// No description provided for @initialBalanceCreditCardLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor da Próxima Fatura'**
  String get initialBalanceCreditCardLabel;

  /// No description provided for @initialBalanceInvestmentLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor Inicial do Investimento'**
  String get initialBalanceInvestmentLabel;

  /// No description provided for @initialBalanceDebtLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor Atual da Dívida'**
  String get initialBalanceDebtLabel;

  /// No description provided for @initialBalanceDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Data do Saldo Inicial'**
  String get initialBalanceDateLabel;

  /// No description provided for @initialBalanceInvestmentDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Data do Investimento Inicial'**
  String get initialBalanceInvestmentDateLabel;

  /// No description provided for @initialBalanceDebtDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Data do Valor Atual'**
  String get initialBalanceDebtDateLabel;

  /// No description provided for @accountBankLogoLabel.
  ///
  /// In pt, this message translates to:
  /// **'Logo do Banco/Bandeira'**
  String get accountBankLogoLabel;

  /// No description provided for @accountOwnerIdsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Titulares'**
  String get accountOwnerIdsLabel;

  /// No description provided for @customLabel.
  ///
  /// In pt, this message translates to:
  /// **'Personalizado'**
  String get customLabel;

  /// No description provided for @accountNextInvoiceValueLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor da próxima fatura'**
  String get accountNextInvoiceValueLabel;

  /// No description provided for @accountInitialInvestmentValueLabel.
  ///
  /// In pt, this message translates to:
  /// **'Saldo inicial do investimento'**
  String get accountInitialInvestmentValueLabel;

  /// No description provided for @accountInitialDebtValueLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor da dívida'**
  String get accountInitialDebtValueLabel;

  /// No description provided for @accountInitialInvestmentDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Data inicial do investimento'**
  String get accountInitialInvestmentDateLabel;

  /// No description provided for @accountInitialDebtDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Data da dívida'**
  String get accountInitialDebtDateLabel;

  /// No description provided for @none.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum'**
  String get none;

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
  /// **'Planejado'**
  String get overviewPlanning;

  /// No description provided for @overviewEffective.
  ///
  /// In pt, this message translates to:
  /// **'Realizado'**
  String get overviewEffective;

  /// No description provided for @overviewComparison.
  ///
  /// In pt, this message translates to:
  /// **'Comparação'**
  String get overviewComparison;

  /// No description provided for @homeOverviewShowDetails.
  ///
  /// In pt, this message translates to:
  /// **'Ver Detalhes'**
  String get homeOverviewShowDetails;

  /// No description provided for @categoryReportDetails.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes por Categoria'**
  String get categoryReportDetails;

  /// No description provided for @transactionTransfer.
  ///
  /// In pt, this message translates to:
  /// **'Transferência'**
  String get transactionTransfer;

  /// No description provided for @transactionTransferCountsAsInvestment.
  ///
  /// In pt, this message translates to:
  /// **'Vai contar como Investimentos'**
  String get transactionTransferCountsAsInvestment;

  /// No description provided for @transactionTransferCountsAsDebt.
  ///
  /// In pt, this message translates to:
  /// **'Vai contar como Dívidas'**
  String get transactionTransferCountsAsDebt;

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
  /// **'Limite definido'**
  String get planningLimitDefined;

  /// No description provided for @planningExpectationDefined.
  ///
  /// In pt, this message translates to:
  /// **'Expectativa definida'**
  String get planningExpectationDefined;

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

  /// No description provided for @coachingViewHistory.
  ///
  /// In pt, this message translates to:
  /// **'Ver histórico'**
  String get coachingViewHistory;

  /// No description provided for @coachingHistoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Insights'**
  String get coachingHistoryTitle;

  /// No description provided for @coachingReviewTips.
  ///
  /// In pt, this message translates to:
  /// **'Rever Dicas'**
  String get coachingReviewTips;

  /// No description provided for @weeklyMissionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Missões Semanais'**
  String get weeklyMissionsTitle;

  /// No description provided for @weeklyMissionsSuccessTitle.
  ///
  /// In pt, this message translates to:
  /// **'Missões Concluídas!'**
  String get weeklyMissionsSuccessTitle;

  /// No description provided for @weeklyMissionsSuccessMessage.
  ///
  /// In pt, this message translates to:
  /// **'Parabéns! Você completou todas as atividades desta semana. Continue assim para manter sua saúde financeira em dia!'**
  String get weeklyMissionsSuccessMessage;

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

  /// No description provided for @challengeStatusStable.
  ///
  /// In pt, this message translates to:
  /// **'Estável'**
  String get challengeStatusStable;

  /// No description provided for @challengeStatusWarning.
  ///
  /// In pt, this message translates to:
  /// **'Alerta'**
  String get challengeStatusWarning;

  /// No description provided for @challengeStatusCritical.
  ///
  /// In pt, this message translates to:
  /// **'Crítico'**
  String get challengeStatusCritical;

  /// No description provided for @rest.
  ///
  /// In pt, this message translates to:
  /// **'Restante'**
  String get rest;

  /// No description provided for @category.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get category;

  /// No description provided for @realization.
  ///
  /// In pt, this message translates to:
  /// **'Realização'**
  String get realization;

  /// No description provided for @difference.
  ///
  /// In pt, this message translates to:
  /// **'Diferença'**
  String get difference;

  /// No description provided for @missingAmount.
  ///
  /// In pt, this message translates to:
  /// **'Faltam {amount}'**
  String missingAmount(String amount);

  /// No description provided for @exceededAmount.
  ///
  /// In pt, this message translates to:
  /// **'Excederam {amount}'**
  String exceededAmount(String amount);

  /// No description provided for @paymentInfo.
  ///
  /// In pt, this message translates to:
  /// **'Informações de pagamento'**
  String get paymentInfo;

  /// No description provided for @accountOwnerLabel.
  ///
  /// In pt, this message translates to:
  /// **'Titularidade'**
  String get accountOwnerLabel;

  /// No description provided for @teamAchievementsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Conquistas da Equipe'**
  String get teamAchievementsTitle;

  /// No description provided for @workspaceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Workspace: {name}'**
  String workspaceLabel(String name);

  /// No description provided for @levelLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nível {level}'**
  String levelLabel(int level);

  /// No description provided for @totalXpLabel.
  ///
  /// In pt, this message translates to:
  /// **'Total: {xp} XP'**
  String totalXpLabel(String xp);

  /// No description provided for @weeklyStreaksLabelSingular.
  ///
  /// In pt, this message translates to:
  /// **'Sequência semanal: 1 semana'**
  String get weeklyStreaksLabelSingular;

  /// No description provided for @weeklyStreaksLabelPlural.
  ///
  /// In pt, this message translates to:
  /// **'Sequência semanal: {streaks} semanas'**
  String weeklyStreaksLabelPlural(int streaks);

  /// No description provided for @yourBadgesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Suas Insígnias'**
  String get yourBadgesLabel;

  /// No description provided for @advancedBadgesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conquistas Avançadas'**
  String get advancedBadgesLabel;

  /// No description provided for @simpleBadgesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conquistas Simples'**
  String get simpleBadgesLabel;

  /// No description provided for @badgeUnlockedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Desbloqueado'**
  String get badgeUnlockedLabel;

  /// No description provided for @badgeLockedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Bloqueado'**
  String get badgeLockedLabel;

  /// No description provided for @badgeRewardLabel.
  ///
  /// In pt, this message translates to:
  /// **'Recompensa'**
  String get badgeRewardLabel;

  /// No description provided for @badgeUnlockedAtLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conquistado em'**
  String get badgeUnlockedAtLabel;

  /// No description provided for @viewAchievementsButton.
  ///
  /// In pt, this message translates to:
  /// **'Ver Conquistas'**
  String get viewAchievementsButton;

  /// No description provided for @badge_first_step_name.
  ///
  /// In pt, this message translates to:
  /// **'Primeiro Passo'**
  String get badge_first_step_name;

  /// No description provided for @badge_first_step_desc.
  ///
  /// In pt, this message translates to:
  /// **'O workspace é criado e o onboarding é concluído com sucesso.'**
  String get badge_first_step_desc;

  /// No description provided for @badge_first_account_name.
  ///
  /// In pt, this message translates to:
  /// **'Primeira Conta'**
  String get badge_first_account_name;

  /// No description provided for @badge_first_account_desc.
  ///
  /// In pt, this message translates to:
  /// **'A primeira conta bancária ou cartão é cadastrado no workspace.'**
  String get badge_first_account_desc;

  /// No description provided for @badge_first_transaction_name.
  ///
  /// In pt, this message translates to:
  /// **'Ponto de Partida'**
  String get badge_first_transaction_name;

  /// No description provided for @badge_first_transaction_desc.
  ///
  /// In pt, this message translates to:
  /// **'A primeira transação real (installment) é registrada com status paid.'**
  String get badge_first_transaction_desc;

  /// No description provided for @badge_planner_name.
  ///
  /// In pt, this message translates to:
  /// **'Planejador Estrategista'**
  String get badge_planner_name;

  /// No description provided for @badge_planner_desc.
  ///
  /// In pt, this message translates to:
  /// **'Limites de planejamento são criados para pelo menos 5 categorias.'**
  String get badge_planner_desc;

  /// No description provided for @badge_reconcile_junior_name.
  ///
  /// In pt, this message translates to:
  /// **'Conciliador Júnior'**
  String get badge_reconcile_junior_name;

  /// No description provided for @badge_reconcile_junior_desc.
  ///
  /// In pt, this message translates to:
  /// **'A primeira conciliação bancária bem-sucedida é concluída (pelo menos 1 match confirmado).'**
  String get badge_reconcile_junior_desc;

  /// No description provided for @badge_cash_detective_name.
  ///
  /// In pt, this message translates to:
  /// **'Detetive de Caixa'**
  String get badge_cash_detective_name;

  /// No description provided for @badge_cash_detective_desc.
  ///
  /// In pt, this message translates to:
  /// **'Conciliação completa de um arquivo de extrato contendo pelo menos 10 transações.'**
  String get badge_cash_detective_desc;

  /// No description provided for @badge_reconcile_master_name.
  ///
  /// In pt, this message translates to:
  /// **'Mestre da Conciliação'**
  String get badge_reconcile_master_name;

  /// No description provided for @badge_reconcile_master_desc.
  ///
  /// In pt, this message translates to:
  /// **'O workspace acumula 10 conciliações de extratos concluídas com sucesso.'**
  String get badge_reconcile_master_desc;

  /// No description provided for @badge_zero_friction_name.
  ///
  /// In pt, this message translates to:
  /// **'Atrito Zero'**
  String get badge_zero_friction_name;

  /// No description provided for @badge_zero_friction_desc.
  ///
  /// In pt, this message translates to:
  /// **'Conciliar um extrato mensal inteiro sem necessitar criar lançamentos manuais extras.'**
  String get badge_zero_friction_desc;

  /// No description provided for @badge_savings_seed_name.
  ///
  /// In pt, this message translates to:
  /// **'Semente de Poupança'**
  String get badge_savings_seed_name;

  /// No description provided for @badge_savings_seed_desc.
  ///
  /// In pt, this message translates to:
  /// **'A primeira meta (goal) cadastrada no workspace atinge 100% de progresso.'**
  String get badge_savings_seed_desc;

  /// No description provided for @badge_goal_bronze_name.
  ///
  /// In pt, this message translates to:
  /// **'Colecionador de Metas'**
  String get badge_goal_bronze_name;

  /// No description provided for @badge_goal_bronze_desc.
  ///
  /// In pt, this message translates to:
  /// **'O workspace conclui com sucesso 3 metas financeiras diferentes.'**
  String get badge_goal_bronze_desc;

  /// No description provided for @badge_goal_silver_name.
  ///
  /// In pt, this message translates to:
  /// **'Foco Inabalável'**
  String get badge_goal_silver_name;

  /// No description provided for @badge_goal_silver_desc.
  ///
  /// In pt, this message translates to:
  /// **'O workspace conclui com sucesso 5 metas financeiras diferentes.'**
  String get badge_goal_silver_desc;

  /// No description provided for @badge_under_control_name.
  ///
  /// In pt, this message translates to:
  /// **'Tudo Sob Controle'**
  String get badge_under_control_name;

  /// No description provided for @badge_under_control_desc.
  ///
  /// In pt, this message translates to:
  /// **'Fechar o mês sem estourar nenhuma categoria planejada na regra 50-30-20.'**
  String get badge_under_control_desc;

  /// No description provided for @badge_golden_rule_name.
  ///
  /// In pt, this message translates to:
  /// **'Regra de Ouro'**
  String get badge_golden_rule_name;

  /// No description provided for @badge_golden_rule_desc.
  ///
  /// In pt, this message translates to:
  /// **'Alocar limites em todos os 3 pools (Essencial, Conforto, Investimento) no mesmo mês.'**
  String get badge_golden_rule_desc;

  /// No description provided for @badge_future_focus_name.
  ///
  /// In pt, this message translates to:
  /// **'Visão de Futuro'**
  String get badge_future_focus_name;

  /// No description provided for @badge_future_focus_desc.
  ///
  /// In pt, this message translates to:
  /// **'Poupar e investir efetivamente pelo menos 20% das receitas totais do workspace no mês.'**
  String get badge_future_focus_desc;

  /// No description provided for @badge_cost_cutter_name.
  ///
  /// In pt, this message translates to:
  /// **'Tesoura de Gastos'**
  String get badge_cost_cutter_name;

  /// No description provided for @badge_cost_cutter_desc.
  ///
  /// In pt, this message translates to:
  /// **'Reduzir os gastos totais do pool de Conforto (supérfluos) em 20% em relação ao mês anterior.'**
  String get badge_cost_cutter_desc;

  /// No description provided for @badge_united_front_name.
  ///
  /// In pt, this message translates to:
  /// **'Equipe Unida'**
  String get badge_united_front_name;

  /// No description provided for @badge_united_front_desc.
  ///
  /// In pt, this message translates to:
  /// **'Workspace com 3 ou mais membros ativos adicionados e aceitos.'**
  String get badge_united_front_desc;

  /// No description provided for @badge_iron_consistency_name.
  ///
  /// In pt, this message translates to:
  /// **'Consistência de Aço'**
  String get badge_iron_consistency_name;

  /// No description provided for @badge_iron_consistency_desc.
  ///
  /// In pt, this message translates to:
  /// **'Concluir com sucesso as missões semanais por 4 semanas consecutivas.'**
  String get badge_iron_consistency_desc;

  /// No description provided for @levelIndicatorSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Nível do Workspace: {level}, Badges desbloqueados: {count}'**
  String levelIndicatorSemantics(int level, int count);

  /// No description provided for @levelUpTitle.
  ///
  /// In pt, this message translates to:
  /// **'LEVEL UP!'**
  String get levelUpTitle;

  /// No description provided for @levelUpSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Parabéns para a equipe!'**
  String get levelUpSubtitle;

  /// No description provided for @levelUpContent.
  ///
  /// In pt, this message translates to:
  /// **'Seu workspace subiu para o Nível {level}!'**
  String levelUpContent(int level);

  /// No description provided for @levelUpMessage.
  ///
  /// In pt, this message translates to:
  /// **'Continuem cooperando e planejando juntos para desbloquear novas conquistas e níveis!'**
  String get levelUpMessage;

  /// No description provided for @statementDragOverTitle.
  ///
  /// In pt, this message translates to:
  /// **'Solte o arquivo do extrato aqui'**
  String get statementDragOverTitle;

  /// No description provided for @reconciliationBulkConfirmSuggestions.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar todos os matches sugeridos ({amount})'**
  String reconciliationBulkConfirmSuggestions(String amount);

  /// No description provided for @reconciliationWarningUnanswered.
  ///
  /// In pt, this message translates to:
  /// **'Responda a todas as transações antes de salvar'**
  String get reconciliationWarningUnanswered;

  /// No description provided for @reconciliationActionUnlink.
  ///
  /// In pt, this message translates to:
  /// **'Desvincular'**
  String get reconciliationActionUnlink;

  /// No description provided for @reconciliationAccountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conta de Conciliação'**
  String get reconciliationAccountLabel;

  /// No description provided for @reconciliationNotInDocument.
  ///
  /// In pt, this message translates to:
  /// **'Não consta no documento'**
  String get reconciliationNotInDocument;

  /// No description provided for @reconciliationActionKeep.
  ///
  /// In pt, this message translates to:
  /// **'Manter'**
  String get reconciliationActionKeep;

  /// No description provided for @reconciliationActionRemove.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get reconciliationActionRemove;

  /// No description provided for @reconciliationStatusKeep.
  ///
  /// In pt, this message translates to:
  /// **'Manter no Sistema'**
  String get reconciliationStatusKeep;

  /// No description provided for @reconciliationStatusRemove.
  ///
  /// In pt, this message translates to:
  /// **'Remover do Sistema'**
  String get reconciliationStatusRemove;

  /// No description provided for @reconciliationStatusSystemOnly.
  ///
  /// In pt, this message translates to:
  /// **'Apenas no Sistema'**
  String get reconciliationStatusSystemOnly;

  /// No description provided for @badge_first_category_name.
  ///
  /// In pt, this message translates to:
  /// **'Organizador'**
  String get badge_first_category_name;

  /// No description provided for @badge_first_category_desc.
  ///
  /// In pt, this message translates to:
  /// **'Criar a primeira categoria personalizada no workspace.'**
  String get badge_first_category_desc;

  /// No description provided for @badge_first_planning_name.
  ///
  /// In pt, this message translates to:
  /// **'Planejador Novato'**
  String get badge_first_planning_name;

  /// No description provided for @badge_first_planning_desc.
  ///
  /// In pt, this message translates to:
  /// **'Criar o primeiro planejamento de categoria com valor definido.'**
  String get badge_first_planning_desc;

  /// No description provided for @badge_first_goal_name.
  ///
  /// In pt, this message translates to:
  /// **'Sonhador'**
  String get badge_first_goal_name;

  /// No description provided for @badge_first_goal_desc.
  ///
  /// In pt, this message translates to:
  /// **'Criar a primeira meta financeira no workspace.'**
  String get badge_first_goal_desc;

  /// No description provided for @badge_first_invite_name.
  ///
  /// In pt, this message translates to:
  /// **'Anfitrião'**
  String get badge_first_invite_name;

  /// No description provided for @badge_first_invite_desc.
  ///
  /// In pt, this message translates to:
  /// **'Convidar o primeiro membro para o workspace.'**
  String get badge_first_invite_desc;

  /// No description provided for @badge_profile_complete_name.
  ///
  /// In pt, this message translates to:
  /// **'Perfil Completo'**
  String get badge_profile_complete_name;

  /// No description provided for @badge_profile_complete_desc.
  ///
  /// In pt, this message translates to:
  /// **'Definir nome e tipo do workspace.'**
  String get badge_profile_complete_desc;

  /// No description provided for @badge_first_income_name.
  ///
  /// In pt, this message translates to:
  /// **'Receita Registrada'**
  String get badge_first_income_name;

  /// No description provided for @badge_first_income_desc.
  ///
  /// In pt, this message translates to:
  /// **'Registrar a primeira receita paga no workspace.'**
  String get badge_first_income_desc;

  /// No description provided for @badge_first_expense_name.
  ///
  /// In pt, this message translates to:
  /// **'Gasto Registrado'**
  String get badge_first_expense_name;

  /// No description provided for @badge_first_expense_desc.
  ///
  /// In pt, this message translates to:
  /// **'Registrar o primeiro gasto pago no workspace.'**
  String get badge_first_expense_desc;

  /// No description provided for @badge_first_transfer_name.
  ///
  /// In pt, this message translates to:
  /// **'Transferidor'**
  String get badge_first_transfer_name;

  /// No description provided for @badge_first_transfer_desc.
  ///
  /// In pt, this message translates to:
  /// **'Registrar a primeira transferência entre contas.'**
  String get badge_first_transfer_desc;

  /// No description provided for @badge_workspace_named_name.
  ///
  /// In pt, this message translates to:
  /// **'Identidade Própria'**
  String get badge_workspace_named_name;

  /// No description provided for @badge_workspace_named_desc.
  ///
  /// In pt, this message translates to:
  /// **'Dar um nome personalizado ao workspace.'**
  String get badge_workspace_named_desc;

  /// No description provided for @badge_first_month_name.
  ///
  /// In pt, this message translates to:
  /// **'Primeiro Mês'**
  String get badge_first_month_name;

  /// No description provided for @badge_first_month_desc.
  ///
  /// In pt, this message translates to:
  /// **'Ter pelo menos uma transação registrada em um mês completo.'**
  String get badge_first_month_desc;

  /// No description provided for @badge_five_transactions_name.
  ///
  /// In pt, this message translates to:
  /// **'Ativo!'**
  String get badge_five_transactions_name;

  /// No description provided for @badge_five_transactions_desc.
  ///
  /// In pt, this message translates to:
  /// **'Registrar 5 transações pagas no total.'**
  String get badge_five_transactions_desc;

  /// No description provided for @badge_twenty_transactions_name.
  ///
  /// In pt, this message translates to:
  /// **'Comprometido'**
  String get badge_twenty_transactions_name;

  /// No description provided for @badge_twenty_transactions_desc.
  ///
  /// In pt, this message translates to:
  /// **'Registrar 20 transações pagas no total.'**
  String get badge_twenty_transactions_desc;

  /// No description provided for @badge_fifty_transactions_name.
  ///
  /// In pt, this message translates to:
  /// **'Veterano'**
  String get badge_fifty_transactions_name;

  /// No description provided for @badge_fifty_transactions_desc.
  ///
  /// In pt, this message translates to:
  /// **'Registrar 50 transações pagas no total.'**
  String get badge_fifty_transactions_desc;

  /// No description provided for @badge_hundred_transactions_name.
  ///
  /// In pt, this message translates to:
  /// **'Centenário'**
  String get badge_hundred_transactions_name;

  /// No description provided for @badge_hundred_transactions_desc.
  ///
  /// In pt, this message translates to:
  /// **'Registrar 100 transações pagas no total.'**
  String get badge_hundred_transactions_desc;

  /// No description provided for @badge_week_complete_name.
  ///
  /// In pt, this message translates to:
  /// **'Semana Completa'**
  String get badge_week_complete_name;

  /// No description provided for @badge_week_complete_desc.
  ///
  /// In pt, this message translates to:
  /// **'Registrar ao menos uma transação em 7 dias consecutivos.'**
  String get badge_week_complete_desc;

  /// No description provided for @badge_two_accounts_name.
  ///
  /// In pt, this message translates to:
  /// **'Multi-Conta'**
  String get badge_two_accounts_name;

  /// No description provided for @badge_two_accounts_desc.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar 2 contas no workspace.'**
  String get badge_two_accounts_desc;

  /// No description provided for @badge_three_accounts_name.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciador'**
  String get badge_three_accounts_name;

  /// No description provided for @badge_three_accounts_desc.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar 3 contas no workspace.'**
  String get badge_three_accounts_desc;

  /// No description provided for @badge_five_accounts_name.
  ///
  /// In pt, this message translates to:
  /// **'Portfólio'**
  String get badge_five_accounts_name;

  /// No description provided for @badge_five_accounts_desc.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar 5 contas no workspace.'**
  String get badge_five_accounts_desc;

  /// No description provided for @badge_five_categories_name.
  ///
  /// In pt, this message translates to:
  /// **'Categorizado'**
  String get badge_five_categories_name;

  /// No description provided for @badge_five_categories_desc.
  ///
  /// In pt, this message translates to:
  /// **'Criar ao menos 5 categorias.'**
  String get badge_five_categories_desc;

  /// No description provided for @badge_ten_categories_name.
  ///
  /// In pt, this message translates to:
  /// **'Mestre Categorizador'**
  String get badge_ten_categories_name;

  /// No description provided for @badge_ten_categories_desc.
  ///
  /// In pt, this message translates to:
  /// **'Criar ao menos 10 categorias.'**
  String get badge_ten_categories_desc;

  /// No description provided for @badge_round_number_name.
  ///
  /// In pt, this message translates to:
  /// **'Número Redondo'**
  String get badge_round_number_name;

  /// No description provided for @badge_round_number_desc.
  ///
  /// In pt, this message translates to:
  /// **'Registrar uma transação de valor exato sem centavos.'**
  String get badge_round_number_desc;

  /// No description provided for @badge_big_transaction_name.
  ///
  /// In pt, this message translates to:
  /// **'Grande Negócio'**
  String get badge_big_transaction_name;

  /// No description provided for @badge_big_transaction_desc.
  ///
  /// In pt, this message translates to:
  /// **'Registrar uma transação individual acima de R\$ 1.000.'**
  String get badge_big_transaction_desc;

  /// No description provided for @badge_small_transactions_ten_name.
  ///
  /// In pt, this message translates to:
  /// **'Detalhe Minucioso'**
  String get badge_small_transactions_ten_name;

  /// No description provided for @badge_small_transactions_ten_desc.
  ///
  /// In pt, this message translates to:
  /// **'Registrar 10 transações de valor inferior a R\$ 10.'**
  String get badge_small_transactions_ten_desc;

  /// No description provided for @badge_income_registered_name.
  ///
  /// In pt, this message translates to:
  /// **'Bem Documentado'**
  String get badge_income_registered_name;

  /// No description provided for @badge_income_registered_desc.
  ///
  /// In pt, this message translates to:
  /// **'Registrar ao menos uma receita no workspace.'**
  String get badge_income_registered_desc;

  /// No description provided for @badge_expense_under_income_name.
  ///
  /// In pt, this message translates to:
  /// **'Saldo Positivo'**
  String get badge_expense_under_income_name;

  /// No description provided for @badge_expense_under_income_desc.
  ///
  /// In pt, this message translates to:
  /// **'Fechar o mês com despesas menores que as receitas.'**
  String get badge_expense_under_income_desc;

  /// No description provided for @badge_three_categories_month_name.
  ///
  /// In pt, this message translates to:
  /// **'Diversificado'**
  String get badge_three_categories_month_name;

  /// No description provided for @badge_three_categories_month_desc.
  ///
  /// In pt, this message translates to:
  /// **'Ter gastos em 3 categorias diferentes no mesmo mês.'**
  String get badge_three_categories_month_desc;

  /// No description provided for @badge_five_categories_month_name.
  ///
  /// In pt, this message translates to:
  /// **'Abrangente'**
  String get badge_five_categories_month_name;

  /// No description provided for @badge_five_categories_month_desc.
  ///
  /// In pt, this message translates to:
  /// **'Ter gastos em 5 categorias diferentes no mesmo mês.'**
  String get badge_five_categories_month_desc;

  /// No description provided for @badge_savings_10pct_name.
  ///
  /// In pt, this message translates to:
  /// **'Poupador Iniciante'**
  String get badge_savings_10pct_name;

  /// No description provided for @badge_savings_10pct_desc.
  ///
  /// In pt, this message translates to:
  /// **'Poupar ao menos 10% da receita total no mês.'**
  String get badge_savings_10pct_desc;

  /// No description provided for @badge_savings_start_name.
  ///
  /// In pt, this message translates to:
  /// **'Primeiro Centavo'**
  String get badge_savings_start_name;

  /// No description provided for @badge_savings_start_desc.
  ///
  /// In pt, this message translates to:
  /// **'Fazer o primeiro depósito em qualquer meta financeira.'**
  String get badge_savings_start_desc;

  /// No description provided for @badge_no_credit_debt_name.
  ///
  /// In pt, this message translates to:
  /// **'Livre de Juros'**
  String get badge_no_credit_debt_name;

  /// No description provided for @badge_no_credit_debt_desc.
  ///
  /// In pt, this message translates to:
  /// **'Fechar o mês sem nenhuma fatura de crédito em aberto.'**
  String get badge_no_credit_debt_desc;

  /// No description provided for @badge_goal_halfway_name.
  ///
  /// In pt, this message translates to:
  /// **'Na Metade do Caminho'**
  String get badge_goal_halfway_name;

  /// No description provided for @badge_goal_halfway_desc.
  ///
  /// In pt, this message translates to:
  /// **'Uma meta financeira atingir 50% do valor alvo.'**
  String get badge_goal_halfway_desc;

  /// No description provided for @badge_goal_75pct_name.
  ///
  /// In pt, this message translates to:
  /// **'Quase Lá'**
  String get badge_goal_75pct_name;

  /// No description provided for @badge_goal_75pct_desc.
  ///
  /// In pt, this message translates to:
  /// **'Uma meta financeira atingir 75% do valor alvo.'**
  String get badge_goal_75pct_desc;

  /// No description provided for @badge_goal_under_deadline_name.
  ///
  /// In pt, this message translates to:
  /// **'No Prazo'**
  String get badge_goal_under_deadline_name;

  /// No description provided for @badge_goal_under_deadline_desc.
  ///
  /// In pt, this message translates to:
  /// **'Concluir uma meta antes da data limite estabelecida.'**
  String get badge_goal_under_deadline_desc;

  /// No description provided for @badge_two_active_goals_name.
  ///
  /// In pt, this message translates to:
  /// **'Ambicioso'**
  String get badge_two_active_goals_name;

  /// No description provided for @badge_two_active_goals_desc.
  ///
  /// In pt, this message translates to:
  /// **'Ter 2 metas ativas ao mesmo tempo.'**
  String get badge_two_active_goals_desc;

  /// No description provided for @badge_five_active_goals_name.
  ///
  /// In pt, this message translates to:
  /// **'Multitarefas'**
  String get badge_five_active_goals_name;

  /// No description provided for @badge_five_active_goals_desc.
  ///
  /// In pt, this message translates to:
  /// **'Ter 5 metas ativas ao mesmo tempo.'**
  String get badge_five_active_goals_desc;

  /// No description provided for @badge_long_term_goal_name.
  ///
  /// In pt, this message translates to:
  /// **'Visão de Longo Prazo'**
  String get badge_long_term_goal_name;

  /// No description provided for @badge_long_term_goal_desc.
  ///
  /// In pt, this message translates to:
  /// **'Criar uma meta com prazo superior a 12 meses.'**
  String get badge_long_term_goal_desc;

  /// No description provided for @badge_short_term_goal_name.
  ///
  /// In pt, this message translates to:
  /// **'Sprint Financeiro'**
  String get badge_short_term_goal_name;

  /// No description provided for @badge_short_term_goal_desc.
  ///
  /// In pt, this message translates to:
  /// **'Concluir uma meta em menos de 30 dias.'**
  String get badge_short_term_goal_desc;

  /// No description provided for @badge_goal_deposit_name.
  ///
  /// In pt, this message translates to:
  /// **'Primeiro Depósito'**
  String get badge_goal_deposit_name;

  /// No description provided for @badge_goal_deposit_desc.
  ///
  /// In pt, this message translates to:
  /// **'Fazer o primeiro depósito em uma meta financeira.'**
  String get badge_goal_deposit_desc;

  /// No description provided for @badge_goal_debt_paid_name.
  ///
  /// In pt, this message translates to:
  /// **'Livre de Dívidas'**
  String get badge_goal_debt_paid_name;

  /// No description provided for @badge_goal_debt_paid_desc.
  ///
  /// In pt, this message translates to:
  /// **'Concluir uma meta do tipo \'Quitar Dívida\'.'**
  String get badge_goal_debt_paid_desc;

  /// No description provided for @badge_goal_linked_account_name.
  ///
  /// In pt, this message translates to:
  /// **'Meta Vinculada'**
  String get badge_goal_linked_account_name;

  /// No description provided for @badge_goal_linked_account_desc.
  ///
  /// In pt, this message translates to:
  /// **'Criar uma meta associada a uma conta bancária.'**
  String get badge_goal_linked_account_desc;

  /// No description provided for @badge_second_member_name.
  ///
  /// In pt, this message translates to:
  /// **'Dupla!'**
  String get badge_second_member_name;

  /// No description provided for @badge_second_member_desc.
  ///
  /// In pt, this message translates to:
  /// **'Um segundo membro aceitar o convite para o workspace.'**
  String get badge_second_member_desc;

  /// No description provided for @badge_reconcile_second_name.
  ///
  /// In pt, this message translates to:
  /// **'Conciliador Frequente'**
  String get badge_reconcile_second_name;

  /// No description provided for @badge_reconcile_second_desc.
  ///
  /// In pt, this message translates to:
  /// **'Concluir a segunda conciliação bancária.'**
  String get badge_reconcile_second_desc;

  /// No description provided for @badge_reconcile_five_name.
  ///
  /// In pt, this message translates to:
  /// **'Conciliador Hábil'**
  String get badge_reconcile_five_name;

  /// No description provided for @badge_reconcile_five_desc.
  ///
  /// In pt, this message translates to:
  /// **'Concluir 5 conciliações bancárias ao total.'**
  String get badge_reconcile_five_desc;

  /// No description provided for @badge_mission_first_name.
  ///
  /// In pt, this message translates to:
  /// **'Primeira Missão'**
  String get badge_mission_first_name;

  /// No description provided for @badge_mission_first_desc.
  ///
  /// In pt, this message translates to:
  /// **'Completar a primeira missão semanal.'**
  String get badge_mission_first_desc;

  /// No description provided for @badge_mission_three_name.
  ///
  /// In pt, this message translates to:
  /// **'Triatleta Financeiro'**
  String get badge_mission_three_name;

  /// No description provided for @badge_mission_three_desc.
  ///
  /// In pt, this message translates to:
  /// **'Completar 3 missões semanais ao total.'**
  String get badge_mission_three_desc;

  /// No description provided for @badge_planning_month_name.
  ///
  /// In pt, this message translates to:
  /// **'Planejamento do Mês'**
  String get badge_planning_month_name;

  /// No description provided for @badge_planning_month_desc.
  ///
  /// In pt, this message translates to:
  /// **'Criar planejamento para ao menos 5 categorias no mês.'**
  String get badge_planning_month_desc;

  /// No description provided for @badge_two_months_active_name.
  ///
  /// In pt, this message translates to:
  /// **'Constante'**
  String get badge_two_months_active_name;

  /// No description provided for @badge_two_months_active_desc.
  ///
  /// In pt, this message translates to:
  /// **'Registrar transações em 2 meses diferentes.'**
  String get badge_two_months_active_desc;

  /// No description provided for @badge_workspace_one_year_name.
  ///
  /// In pt, this message translates to:
  /// **'Aniversário!'**
  String get badge_workspace_one_year_name;

  /// No description provided for @badge_workspace_one_year_desc.
  ///
  /// In pt, this message translates to:
  /// **'O workspace completa 1 ano de existência.'**
  String get badge_workspace_one_year_desc;

  /// No description provided for @badge_invite_accepted_name.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo ao Time'**
  String get badge_invite_accepted_name;

  /// No description provided for @badge_invite_accepted_desc.
  ///
  /// In pt, this message translates to:
  /// **'Aceitar o convite para entrar em um workspace.'**
  String get badge_invite_accepted_desc;

  /// No description provided for @badge_all_missions_week_name.
  ///
  /// In pt, this message translates to:
  /// **'Semana Perfeita'**
  String get badge_all_missions_week_name;

  /// No description provided for @badge_all_missions_week_desc.
  ///
  /// In pt, this message translates to:
  /// **'Completar todas as missões semanais disponíveis em uma semana.'**
  String get badge_all_missions_week_desc;

  /// No description provided for @goalDebtTotalLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor Total da Dívida'**
  String get goalDebtTotalLabel;

  /// No description provided for @goalDebtTotalHint.
  ///
  /// In pt, this message translates to:
  /// **'Quanto você deve no total?'**
  String get goalDebtTotalHint;

  /// No description provided for @goalDebtPaidLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor Já Pago'**
  String get goalDebtPaidLabel;

  /// No description provided for @goalDebtPaidHint.
  ///
  /// In pt, this message translates to:
  /// **'Quanto você já amortizou?'**
  String get goalDebtPaidHint;

  /// No description provided for @goalDebtAccountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Vincular à Conta de Dívida'**
  String get goalDebtAccountLabel;

  /// No description provided for @goalSpendingLimitHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: 500,00 (limite de gasto)'**
  String get goalSpendingLimitHint;

  /// No description provided for @accountNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Conta não encontrada.'**
  String get accountNotFound;

  /// No description provided for @savedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Salvo com sucesso!'**
  String get savedSuccess;

  /// No description provided for @planningAnalysisAction.
  ///
  /// In pt, this message translates to:
  /// **'Análise ideal (IA)'**
  String get planningAnalysisAction;

  /// No description provided for @planningAnalysisLoadingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Analisando seu planejamento'**
  String get planningAnalysisLoadingTitle;

  /// No description provided for @planningAnalysisLoadingDesc.
  ///
  /// In pt, this message translates to:
  /// **'A IA está calculando o gasto ideal de cada categoria com base na sua receita prevista e na regra 50-30-20.'**
  String get planningAnalysisLoadingDesc;

  /// No description provided for @planningAnalysisError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível gerar a análise. Tente novamente.'**
  String get planningAnalysisError;

  /// No description provided for @planningAnalysisTitle.
  ///
  /// In pt, this message translates to:
  /// **'Análise Ideal 50-30-20'**
  String get planningAnalysisTitle;

  /// No description provided for @planningAnalysisProjectedIncome.
  ///
  /// In pt, this message translates to:
  /// **'Receita prevista: {amount}'**
  String planningAnalysisProjectedIncome(String amount);

  /// No description provided for @planningAnalysisCurrentPct.
  ///
  /// In pt, this message translates to:
  /// **'Atual: {percent}'**
  String planningAnalysisCurrentPct(String percent);

  /// No description provided for @planningAnalysisTargetPct.
  ///
  /// In pt, this message translates to:
  /// **'Alvo: {percent}'**
  String planningAnalysisTargetPct(String percent);

  /// No description provided for @planningAnalysisAboveBy.
  ///
  /// In pt, this message translates to:
  /// **'{amount} acima do alvo'**
  String planningAnalysisAboveBy(String amount);

  /// No description provided for @planningAnalysisBelowBy.
  ///
  /// In pt, this message translates to:
  /// **'{amount} abaixo do alvo'**
  String planningAnalysisBelowBy(String amount);

  /// No description provided for @planningAnalysisCategoriesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ideal por categoria'**
  String get planningAnalysisCategoriesTitle;

  /// No description provided for @planningAnalysisIdealValue.
  ///
  /// In pt, this message translates to:
  /// **'Ideal: {amount} ({percent} da renda)'**
  String planningAnalysisIdealValue(String amount, String percent);

  /// No description provided for @planningAnalysisStatusOk.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get planningAnalysisStatusOk;

  /// No description provided for @planningAnalysisStatusAbove.
  ///
  /// In pt, this message translates to:
  /// **'Acima'**
  String get planningAnalysisStatusAbove;

  /// No description provided for @planningAnalysisStatusBelow.
  ///
  /// In pt, this message translates to:
  /// **'Abaixo'**
  String get planningAnalysisStatusBelow;

  /// No description provided for @planningAnalysisReclassTitle.
  ///
  /// In pt, this message translates to:
  /// **'Reclassificações sugeridas'**
  String get planningAnalysisReclassTitle;

  /// No description provided for @planningAnalysisApply.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar'**
  String get planningAnalysisApply;

  /// No description provided for @planningAnalysisApplied.
  ///
  /// In pt, this message translates to:
  /// **'Categoria atualizada com sucesso!'**
  String get planningAnalysisApplied;

  /// No description provided for @planningAnalysisApplyError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atualizar a categoria.'**
  String get planningAnalysisApplyError;

  /// No description provided for @planningAnalysisInsightsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Insights'**
  String get planningAnalysisInsightsTitle;

  /// No description provided for @planningAnalysisGeneratedAt.
  ///
  /// In pt, this message translates to:
  /// **'Análise gerada em {date}'**
  String planningAnalysisGeneratedAt(String date);

  /// No description provided for @planningAnalysisNextAvailable.
  ///
  /// In pt, this message translates to:
  /// **'{days, plural, one{Nova análise disponível em {days} dia} other{Nova análise disponível em {days} dias}}'**
  String planningAnalysisNextAvailable(int days);

  /// No description provided for @planningAnalysisGenerateNew.
  ///
  /// In pt, this message translates to:
  /// **'Gerar nova análise'**
  String get planningAnalysisGenerateNew;
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
