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
  /// **'Funances'**
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

  /// No description provided for @transactionMatchSearching.
  ///
  /// In pt, this message translates to:
  /// **'Procurando agendamentos…'**
  String get transactionMatchSearching;

  /// No description provided for @transactionMatchUndo.
  ///
  /// In pt, this message translates to:
  /// **'Não era esse'**
  String get transactionMatchUndo;

  /// No description provided for @transactionMatchSameAmount.
  ///
  /// In pt, this message translates to:
  /// **'mesmo valor'**
  String get transactionMatchSameAmount;

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

  /// No description provided for @errorSignInPopupBlocked.
  ///
  /// In pt, this message translates to:
  /// **'Seu navegador bloqueou a janela do Google. Liberamos o login nesta mesma aba — se nada acontecer, permita pop-ups para este site e tente de novo.'**
  String get errorSignInPopupBlocked;

  /// No description provided for @errorSignInCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Login cancelado.'**
  String get errorSignInCancelled;

  /// No description provided for @errorSignInRedirecting.
  ///
  /// In pt, this message translates to:
  /// **'Redirecionando para o Google...'**
  String get errorSignInRedirecting;

  /// No description provided for @errorSignInUnauthorizedDomain.
  ///
  /// In pt, this message translates to:
  /// **'Este endereço não está autorizado a fazer login. Adicione o domínio em Authentication > Settings > Authorized domains no Firebase Console.'**
  String get errorSignInUnauthorizedDomain;

  /// No description provided for @errorAccountExistsWithDifferentCredential.
  ///
  /// In pt, this message translates to:
  /// **'Já existe uma conta com este e-mail criada por outro método. Entre com e-mail e senha.'**
  String get errorAccountExistsWithDifferentCredential;

  /// No description provided for @errorSignInProviderDisabled.
  ///
  /// In pt, this message translates to:
  /// **'Este método de login está desativado no projeto. Habilite-o em Authentication > Sign-in method.'**
  String get errorSignInProviderDisabled;

  /// No description provided for @offlineBannerOffline.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão. Você continua vendo e editando; sincronizamos quando a rede voltar.'**
  String get offlineBannerOffline;

  /// No description provided for @offlineBannerPending.
  ///
  /// In pt, this message translates to:
  /// **'Salvo neste aparelho. Sincronizando com a nuvem...'**
  String get offlineBannerPending;

  /// No description provided for @errorOfflineCallable.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação precisa de internet. Reconecte e tente de novo.'**
  String get errorOfflineCallable;

  /// No description provided for @reconciliationChooseAccount.
  ///
  /// In pt, this message translates to:
  /// **'Qual conta você quer conciliar?'**
  String get reconciliationChooseAccount;

  /// No description provided for @errorOffline.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão com a internet. Mostramos o que já estava no aparelho; toque em tentar de novo quando a rede voltar.'**
  String get errorOffline;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In pt, this message translates to:
  /// **'Você não tem acesso a estes dados. Se acabou de sair de um workspace, entre de novo.'**
  String get errorPermissionDenied;

  /// No description provided for @errorQuotaExhausted.
  ///
  /// In pt, this message translates to:
  /// **'Limite de uso atingido. Tente de novo mais tarde.'**
  String get errorQuotaExhausted;

  /// No description provided for @errorNotAuthenticated.
  ///
  /// In pt, this message translates to:
  /// **'Sua sessão expirou. Entre de novo para continuar.'**
  String get errorNotAuthenticated;

  /// No description provided for @errorNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Este item não existe mais.'**
  String get errorNotFound;

  /// No description provided for @errorTimeout.
  ///
  /// In pt, this message translates to:
  /// **'O servidor demorou demais para responder. Tente de novo.'**
  String get errorTimeout;

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

  /// No description provided for @goalTargetTarget.
  ///
  /// In pt, this message translates to:
  /// **'Alvo: {amount}'**
  String goalTargetTarget(String amount);

  /// No description provided for @goalDetailsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes da Meta'**
  String get goalDetailsTitle;

  /// No description provided for @goalEditButton.
  ///
  /// In pt, this message translates to:
  /// **'Editar Meta'**
  String get goalEditButton;

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

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Perfil atualizado com sucesso!'**
  String get profileUpdateSuccess;

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

  /// No description provided for @planning503020EmptyPool.
  ///
  /// In pt, this message translates to:
  /// **'Arraste categorias para cá'**
  String get planning503020EmptyPool;

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

  /// No description provided for @goalRemainingValue.
  ///
  /// In pt, this message translates to:
  /// **'Faltam {amount}'**
  String goalRemainingValue(String amount);

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

  /// No description provided for @homeAccountsAndCards.
  ///
  /// In pt, this message translates to:
  /// **'Saldos e Faturas'**
  String get homeAccountsAndCards;

  /// No description provided for @weeklyMissionsNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma missão para esta semana'**
  String get weeklyMissionsNone;

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

  /// No description provided for @xpValue.
  ///
  /// In pt, this message translates to:
  /// **'{xp} XP'**
  String xpValue(String xp);

  /// No description provided for @dateRange.
  ///
  /// In pt, this message translates to:
  /// **'{start} - {end}'**
  String dateRange(String start, String end);

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

  /// No description provided for @homeNewTransaction.
  ///
  /// In pt, this message translates to:
  /// **'Novo Lançamento'**
  String get homeNewTransaction;

  /// No description provided for @noTransactionsInPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma transação encontrada para este período'**
  String get noTransactionsInPeriod;

  /// No description provided for @historyFilterAccountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get historyFilterAccountLabel;

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

  /// No description provided for @categoryVirtualDebt.
  ///
  /// In pt, this message translates to:
  /// **'Empréstimo/Dívidas'**
  String get categoryVirtualDebt;

  /// No description provided for @categoryVirtualInvestment.
  ///
  /// In pt, this message translates to:
  /// **'Investimentos'**
  String get categoryVirtualInvestment;

  /// No description provided for @categoryInitialBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo Inicial'**
  String get categoryInitialBalance;

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

  /// No description provided for @unnamedWorkspace.
  ///
  /// In pt, this message translates to:
  /// **'Workspace sem nome'**
  String get unnamedWorkspace;

  /// No description provided for @accountManagementEmptyOfType.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não tem contas deste tipo.'**
  String get accountManagementEmptyOfType;

  /// No description provided for @bankLogoOther.
  ///
  /// In pt, this message translates to:
  /// **'Outros'**
  String get bankLogoOther;

  /// No description provided for @accountsMine.
  ///
  /// In pt, this message translates to:
  /// **'Minhas contas'**
  String get accountsMine;

  /// No description provided for @accountsOfMember.
  ///
  /// In pt, this message translates to:
  /// **'Contas de {name}'**
  String accountsOfMember(String name);

  /// No description provided for @accountsShared.
  ///
  /// In pt, this message translates to:
  /// **'Contas compartilhadas'**
  String get accountsShared;

  /// No description provided for @planning503020TargetPercent.
  ///
  /// In pt, this message translates to:
  /// **'Meta: {percent}'**
  String planning503020TargetPercent(String percent);

  /// No description provided for @noCategory.
  ///
  /// In pt, this message translates to:
  /// **'Sem categoria'**
  String get noCategory;

  /// No description provided for @noDescription.
  ///
  /// In pt, this message translates to:
  /// **'Sem descrição'**
  String get noDescription;

  /// No description provided for @unnamedAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta sem nome'**
  String get unnamedAccount;

  /// No description provided for @unnamedGoal.
  ///
  /// In pt, this message translates to:
  /// **'Meta sem nome'**
  String get unnamedGoal;

  /// No description provided for @automaticTransactionMoveWorkspace.
  ///
  /// In pt, this message translates to:
  /// **'Mover para outro workspace'**
  String get automaticTransactionMoveWorkspace;

  /// No description provided for @accountOwnersLabel.
  ///
  /// In pt, this message translates to:
  /// **'Titulares da conta'**
  String get accountOwnersLabel;

  /// No description provided for @reconciliationPickTransaction.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar lançamento'**
  String get reconciliationPickTransaction;

  /// No description provided for @transactionNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo lançamento'**
  String get transactionNewTitle;

  /// No description provided for @planning503020IdealLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ideal'**
  String get planning503020IdealLabel;

  /// No description provided for @planning503020MonthlyLimitLabel.
  ///
  /// In pt, this message translates to:
  /// **'Limite Mensal'**
  String get planning503020MonthlyLimitLabel;

  /// No description provided for @planning503020AlreadyPlanned.
  ///
  /// In pt, this message translates to:
  /// **'Já previsto:'**
  String get planning503020AlreadyPlanned;

  /// No description provided for @loginTermsNotice.
  ///
  /// In pt, this message translates to:
  /// **'Ao entrar, você concorda com nossos Termos de Serviço e Política de Privacidade.'**
  String get loginTermsNotice;

  /// No description provided for @inviteEmailHint.
  ///
  /// In pt, this message translates to:
  /// **'exemplo@email.com'**
  String get inviteEmailHint;

  /// No description provided for @uploadStatusReading.
  ///
  /// In pt, this message translates to:
  /// **'Lendo o arquivo do extrato…'**
  String get uploadStatusReading;

  /// No description provided for @uploadStatusExtracting.
  ///
  /// In pt, this message translates to:
  /// **'Extraindo transações e valores…'**
  String get uploadStatusExtracting;

  /// No description provided for @uploadStatusSearching.
  ///
  /// In pt, this message translates to:
  /// **'Procurando os lançamentos correspondentes…'**
  String get uploadStatusSearching;

  /// No description provided for @uploadStatusPreparing.
  ///
  /// In pt, this message translates to:
  /// **'Preparando as sugestões de conciliação…'**
  String get uploadStatusPreparing;

  /// No description provided for @uploadStatusCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Conciliação pronta.'**
  String get uploadStatusCompleted;

  /// No description provided for @uploadStatusError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível ler este extrato.'**
  String get uploadStatusError;

  /// No description provided for @reconciliationAction.
  ///
  /// In pt, this message translates to:
  /// **'Conciliar extrato'**
  String get reconciliationAction;

  /// No description provided for @reconciliationMissionCta.
  ///
  /// In pt, this message translates to:
  /// **'Conciliar extrato agora'**
  String get reconciliationMissionCta;

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
  String accountDetectedTransactions(int count);

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

  /// No description provided for @accountDetectedTransactionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Transações Detectadas'**
  String get accountDetectedTransactionsTitle;

  /// No description provided for @historyEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get historyEdit;

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
  /// **'Deve possuir no máximo {max} caracteres.'**
  String validationLengthMaxMessage(int max);

  /// No description provided for @validationLengthMinMessage.
  ///
  /// In pt, this message translates to:
  /// **'Deve possuir no mínimo {min} caracteres.'**
  String validationLengthMinMessage(int min);

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
  String installmentCountDescription(int number, int count);

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

  /// No description provided for @completedMissionsSummary.
  ///
  /// In pt, this message translates to:
  /// **'{count} {count, plural, =1{item} other{itens}} • {xp} XP'**
  String completedMissionsSummary(int count, String xp);

  /// No description provided for @returnToPending.
  ///
  /// In pt, this message translates to:
  /// **'Retornar para Pendente'**
  String get returnToPending;

  /// No description provided for @partyHpLabel.
  ///
  /// In pt, this message translates to:
  /// **'Saúde da Party'**
  String get partyHpLabel;

  /// No description provided for @partyStatusHealthy.
  ///
  /// In pt, this message translates to:
  /// **'Party em segurança'**
  String get partyStatusHealthy;

  /// No description provided for @partyStatusStrained.
  ///
  /// In pt, this message translates to:
  /// **'Party em perigo'**
  String get partyStatusStrained;

  /// No description provided for @partyStatusDefeated.
  ///
  /// In pt, this message translates to:
  /// **'Party derrotada'**
  String get partyStatusDefeated;

  /// No description provided for @partyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua Party'**
  String get partyTitle;

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

  /// No description provided for @coachingTypeWarning.
  ///
  /// In pt, this message translates to:
  /// **'Alerta'**
  String get coachingTypeWarning;

  /// No description provided for @coachingTypeTip.
  ///
  /// In pt, this message translates to:
  /// **'Dica'**
  String get coachingTypeTip;

  /// No description provided for @coachingTypeInsight.
  ///
  /// In pt, this message translates to:
  /// **'Insight'**
  String get coachingTypeInsight;

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

  /// No description provided for @goalSpendingLimitLabel.
  ///
  /// In pt, this message translates to:
  /// **'Teto de Gastos'**
  String get goalSpendingLimitLabel;

  /// No description provided for @goalAmountSavedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Guardado'**
  String get goalAmountSavedLabel;

  /// No description provided for @goalAmountPaidLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quitado'**
  String get goalAmountPaidLabel;

  /// No description provided for @goalAmountSpentLabel.
  ///
  /// In pt, this message translates to:
  /// **'Gasto'**
  String get goalAmountSpentLabel;

  /// No description provided for @goalCompletedAt.
  ///
  /// In pt, this message translates to:
  /// **'Concluída em {date}'**
  String goalCompletedAt(String date);

  /// No description provided for @goalSpentOfLimit.
  ///
  /// In pt, this message translates to:
  /// **'{amount} de {limit}'**
  String goalSpentOfLimit(String amount, String limit);

  /// No description provided for @goalRemainingLimit.
  ///
  /// In pt, this message translates to:
  /// **'Ainda cabem {amount}'**
  String goalRemainingLimit(String amount);

  /// No description provided for @goalOverLimit.
  ///
  /// In pt, this message translates to:
  /// **'Estourou {amount}'**
  String goalOverLimit(String amount);

  /// No description provided for @partyEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua party ainda não tem desafios'**
  String get partyEmptyTitle;

  /// No description provided for @partyEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Cada limite de gastos por categoria vira um desafio da party. Crie o primeiro e acompanhe aqui.'**
  String get partyEmptyMessage;

  /// No description provided for @partyEmptyButton.
  ///
  /// In pt, this message translates to:
  /// **'Criar primeiro limite'**
  String get partyEmptyButton;

  /// No description provided for @partyErrorMessage.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o status da party.'**
  String get partyErrorMessage;

  /// No description provided for @badgeCatalogUnavailableTitle.
  ///
  /// In pt, this message translates to:
  /// **'Catálogo indisponível'**
  String get badgeCatalogUnavailableTitle;

  /// No description provided for @badgeCatalogUnavailableMessage.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não recebemos a lista de conquistas do servidor. Tente de novo em instantes.'**
  String get badgeCatalogUnavailableMessage;

  /// No description provided for @badgeCategoryAdvanced.
  ///
  /// In pt, this message translates to:
  /// **'Conquistas Avançadas'**
  String get badgeCategoryAdvanced;

  /// No description provided for @badgeCategoryFirstSteps.
  ///
  /// In pt, this message translates to:
  /// **'Primeiros Passos'**
  String get badgeCategoryFirstSteps;

  /// No description provided for @badgeCategoryConsistency.
  ///
  /// In pt, this message translates to:
  /// **'Registro Consistente'**
  String get badgeCategoryConsistency;

  /// No description provided for @badgeCategorySavings.
  ///
  /// In pt, this message translates to:
  /// **'Gastos e Economias'**
  String get badgeCategorySavings;

  /// No description provided for @badgeCategoryGoals.
  ///
  /// In pt, this message translates to:
  /// **'Metas'**
  String get badgeCategoryGoals;

  /// No description provided for @badgeCategoryTeam.
  ///
  /// In pt, this message translates to:
  /// **'Equipe e Consistência'**
  String get badgeCategoryTeam;

  /// No description provided for @badgeCatalogTotal.
  ///
  /// In pt, this message translates to:
  /// **'{unlocked} de {total}'**
  String badgeCatalogTotal(int unlocked, int total);

  /// No description provided for @goalLimitBlownAt.
  ///
  /// In pt, this message translates to:
  /// **'Limite estourado em {date}'**
  String goalLimitBlownAt(String date);

  /// No description provided for @goalDeadlineMissedAt.
  ///
  /// In pt, this message translates to:
  /// **'Prazo encerrado sem atingir em {date}'**
  String goalDeadlineMissedAt(String date);

  /// No description provided for @journeyClosedGoalsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Metas encerradas'**
  String get journeyClosedGoalsTitle;

  /// No description provided for @goalAwaitingOutcome.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando apuração'**
  String get goalAwaitingOutcome;

  /// Mostrado no lugar do valor da fatura enquanto o servidor ainda não publicou o resumo da próxima fatura do cartão.
  ///
  /// In pt, this message translates to:
  /// **'calculando…'**
  String get invoiceCalculating;

  /// No description provided for @invoiceCycleUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Estamos fechando esta fatura. As compras aparecem assim que o cálculo terminar.'**
  String get invoiceCycleUnavailable;

  /// Mostrado no lugar do XP da semana quando o documento weekly_xp do servidor ainda não existe.
  ///
  /// In pt, this message translates to:
  /// **'Sem XP ainda nesta semana'**
  String get journeyWeeklyXpEmpty;

  /// No description provided for @journeyMissionsSoonTitle.
  ///
  /// In pt, this message translates to:
  /// **'Suas missões estão a caminho'**
  String get journeyMissionsSoonTitle;

  /// No description provided for @journeyMissionsSoonMessage.
  ///
  /// In pt, this message translates to:
  /// **'O Funances monta três missões novas no começo de cada semana.'**
  String get journeyMissionsSoonMessage;

  /// No description provided for @journeyMissionProgress.
  ///
  /// In pt, this message translates to:
  /// **'{progress} de {target}'**
  String journeyMissionProgress(int progress, int target);

  /// No description provided for @journeyMissionDone.
  ///
  /// In pt, this message translates to:
  /// **'Missão cumprida'**
  String get journeyMissionDone;

  /// No description provided for @journeyMissionConsistency.
  ///
  /// In pt, this message translates to:
  /// **'Consistência'**
  String get journeyMissionConsistency;

  /// No description provided for @journeyMissionDiscipline.
  ///
  /// In pt, this message translates to:
  /// **'Disciplina'**
  String get journeyMissionDiscipline;

  /// No description provided for @journeyMissionOrganization.
  ///
  /// In pt, this message translates to:
  /// **'Organização'**
  String get journeyMissionOrganization;

  /// No description provided for @journeyMissionOther.
  ///
  /// In pt, this message translates to:
  /// **'Missão'**
  String get journeyMissionOther;

  /// No description provided for @journeyChecklistTitle.
  ///
  /// In pt, this message translates to:
  /// **'Checklist da semana'**
  String get journeyChecklistTitle;

  /// No description provided for @journeyAvailableTitle.
  ///
  /// In pt, this message translates to:
  /// **'Disponível até o fim do mês'**
  String get journeyAvailableTitle;

  /// No description provided for @journeyAvailableSpent.
  ///
  /// In pt, this message translates to:
  /// **'Realizado {actual} de {planned} previstos'**
  String journeyAvailableSpent(String actual, String planned);

  /// No description provided for @journeyAvailablePending.
  ///
  /// In pt, this message translates to:
  /// **'Ainda por pagar: {pending}'**
  String journeyAvailablePending(String pending);

  /// No description provided for @journeyAvailableNoIncome.
  ///
  /// In pt, this message translates to:
  /// **'Sem expectativa de receita não dá para dizer quanto sobra.'**
  String get journeyAvailableNoIncome;

  /// No description provided for @journeyAvailableNoIncomeAction.
  ///
  /// In pt, this message translates to:
  /// **'Defina sua expectativa de receita'**
  String get journeyAvailableNoIncomeAction;

  /// No description provided for @journeyAvailableError.
  ///
  /// In pt, this message translates to:
  /// **'Não consegui calcular o disponível agora.'**
  String get journeyAvailableError;

  /// No description provided for @compassTitle.
  ///
  /// In pt, this message translates to:
  /// **'Bússola da Liberdade'**
  String get compassTitle;

  /// No description provided for @compassScoreOf.
  ///
  /// In pt, this message translates to:
  /// **'{score} de 100 • {tier}'**
  String compassScoreOf(String score, String tier);

  /// No description provided for @compassTierAprendiz.
  ///
  /// In pt, this message translates to:
  /// **'Aprendiz'**
  String get compassTierAprendiz;

  /// No description provided for @compassTierGuardiao.
  ///
  /// In pt, this message translates to:
  /// **'Guardião'**
  String get compassTierGuardiao;

  /// No description provided for @compassTierEstrategista.
  ///
  /// In pt, this message translates to:
  /// **'Estrategista'**
  String get compassTierEstrategista;

  /// No description provided for @compassTierMestre.
  ///
  /// In pt, this message translates to:
  /// **'Mestre'**
  String get compassTierMestre;

  /// No description provided for @compassTierLivre.
  ///
  /// In pt, this message translates to:
  /// **'Livre'**
  String get compassTierLivre;

  /// No description provided for @compassTierUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Em avaliação'**
  String get compassTierUnknown;

  /// No description provided for @compassFolego.
  ///
  /// In pt, this message translates to:
  /// **'Fôlego'**
  String get compassFolego;

  /// No description provided for @compassFolegoDesc.
  ///
  /// In pt, this message translates to:
  /// **'Quanto tempo suas reservas seguram suas despesas se a renda parar.'**
  String get compassFolegoDesc;

  /// No description provided for @compassFolegoDetail.
  ///
  /// In pt, this message translates to:
  /// **'{months} meses de despesas guardados'**
  String compassFolegoDetail(String months);

  /// No description provided for @compassPoupanca.
  ///
  /// In pt, this message translates to:
  /// **'Poupança'**
  String get compassPoupanca;

  /// No description provided for @compassPoupancaDesc.
  ///
  /// In pt, this message translates to:
  /// **'Quanto da sua renda vira reserva ou investimento todo mês.'**
  String get compassPoupancaDesc;

  /// No description provided for @compassPoupancaDetail.
  ///
  /// In pt, this message translates to:
  /// **'{rate} da renda guardada'**
  String compassPoupancaDetail(String rate);

  /// No description provided for @compassDisciplina.
  ///
  /// In pt, this message translates to:
  /// **'Disciplina'**
  String get compassDisciplina;

  /// No description provided for @compassDisciplinaDesc.
  ///
  /// In pt, this message translates to:
  /// **'Quantas categorias terminaram o mês dentro do limite que você definiu.'**
  String get compassDisciplinaDesc;

  /// No description provided for @compassDisciplinaDetail.
  ///
  /// In pt, this message translates to:
  /// **'{within} de {total} categorias dentro do limite'**
  String compassDisciplinaDetail(int within, int total);

  /// No description provided for @compassAlivio.
  ///
  /// In pt, this message translates to:
  /// **'Alívio'**
  String get compassAlivio;

  /// No description provided for @compassAlivioDesc.
  ///
  /// In pt, this message translates to:
  /// **'Quanto suas dívidas diminuíram desde o mês passado.'**
  String get compassAlivioDesc;

  /// No description provided for @compassAlivioDetail.
  ///
  /// In pt, this message translates to:
  /// **'{delta} em dívidas no mês'**
  String compassAlivioDetail(String delta);

  /// No description provided for @compassHistoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Últimos 6 meses'**
  String get compassHistoryTitle;

  /// No description provided for @compassHistoryEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há meses fechados suficientes para comparar.'**
  String get compassHistoryEmpty;

  /// No description provided for @unplannedNudgeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Esse gasto não estava no plano'**
  String get unplannedNudgeTitle;

  /// No description provided for @unplannedNudgeMessage.
  ///
  /// In pt, this message translates to:
  /// **'{category} ainda não tem limite neste mês. Quer decidir agora o que fazer com ela?'**
  String unplannedNudgeMessage(String category);

  /// No description provided for @unplannedNudgeRecurring.
  ///
  /// In pt, this message translates to:
  /// **'Transformar em recorrência'**
  String get unplannedNudgeRecurring;

  /// No description provided for @unplannedNudgeRecurringDesc.
  ///
  /// In pt, this message translates to:
  /// **'Se acontece todo mês, o Funances passa a lançar sozinho.'**
  String get unplannedNudgeRecurringDesc;

  /// No description provided for @unplannedNudgeLimit.
  ///
  /// In pt, this message translates to:
  /// **'Definir limite para {category}'**
  String unplannedNudgeLimit(String category);

  /// No description provided for @unplannedNudgeLimitDesc.
  ///
  /// In pt, this message translates to:
  /// **'Sugestão de {amount}, pela sua média dos últimos meses.'**
  String unplannedNudgeLimitDesc(String amount);

  /// No description provided for @unplannedNudgeLimitDescNoHistory.
  ///
  /// In pt, this message translates to:
  /// **'Escolha quanto essa categoria pode custar por mês.'**
  String get unplannedNudgeLimitDescNoHistory;

  /// No description provided for @unplannedNudgeDismiss.
  ///
  /// In pt, this message translates to:
  /// **'Só desta vez'**
  String get unplannedNudgeDismiss;

  /// No description provided for @xpSourcesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Como ganhar XP'**
  String get xpSourcesTitle;

  /// O weekly_xp do servidor só acumula XP de parcelas; o XP das missões vai para o total do workspace. O rótulo diz de onde vem o número para não sugerir uma soma que não existe.
  ///
  /// In pt, this message translates to:
  /// **'XP ganho esta semana com lançamentos'**
  String get journeyWeeklyXpCaption;

  /// No description provided for @compassHistoryPoint.
  ///
  /// In pt, this message translates to:
  /// **'{month}: {score} de 100'**
  String compassHistoryPoint(String month, String score);

  /// No description provided for @writeFailedReasonPermission.
  ///
  /// In pt, this message translates to:
  /// **'você não tem permissão para essa mudança'**
  String get writeFailedReasonPermission;

  /// No description provided for @writeFailedReasonNotFound.
  ///
  /// In pt, this message translates to:
  /// **'o item não existe mais'**
  String get writeFailedReasonNotFound;

  /// No description provided for @writeFailedReasonTimeout.
  ///
  /// In pt, this message translates to:
  /// **'o servidor não respondeu'**
  String get writeFailedReasonTimeout;

  /// No description provided for @writeFailedReasonUnknown.
  ///
  /// In pt, this message translates to:
  /// **'o servidor recusou a alteração'**
  String get writeFailedReasonUnknown;

  /// No description provided for @transactionSavePendingSync.
  ///
  /// In pt, this message translates to:
  /// **'Salvo neste dispositivo. As parcelas aparecem quando a conexão voltar.'**
  String get transactionSavePendingSync;

  /// No description provided for @uploadFolderNotSupported.
  ///
  /// In pt, this message translates to:
  /// **'Arraste um arquivo, não uma pasta.'**
  String get uploadFolderNotSupported;

  /// Aviso de escrita recusada pelo servidor depois de a tela ter seguido.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar {entity}: {reason}'**
  String writeFailedEntity(String entity, String reason);

  /// No description provided for @writeEntityTransaction.
  ///
  /// In pt, this message translates to:
  /// **'o lançamento'**
  String get writeEntityTransaction;

  /// No description provided for @writeEntityInstallment.
  ///
  /// In pt, this message translates to:
  /// **'a parcela'**
  String get writeEntityInstallment;

  /// No description provided for @writeEntityPlanning.
  ///
  /// In pt, this message translates to:
  /// **'o planejamento'**
  String get writeEntityPlanning;

  /// No description provided for @writeEntityAccount.
  ///
  /// In pt, this message translates to:
  /// **'a conta'**
  String get writeEntityAccount;

  /// No description provided for @writeEntityCategory.
  ///
  /// In pt, this message translates to:
  /// **'a categoria'**
  String get writeEntityCategory;

  /// No description provided for @writeEntityGoal.
  ///
  /// In pt, this message translates to:
  /// **'a meta'**
  String get writeEntityGoal;

  /// No description provided for @writeEntityInvite.
  ///
  /// In pt, this message translates to:
  /// **'o convite'**
  String get writeEntityInvite;

  /// No description provided for @writeEntityWorkspace.
  ///
  /// In pt, this message translates to:
  /// **'o workspace'**
  String get writeEntityWorkspace;

  /// No description provided for @writeEntityProfile.
  ///
  /// In pt, this message translates to:
  /// **'o perfil'**
  String get writeEntityProfile;

  /// No description provided for @writeEntityAutomaticTransaction.
  ///
  /// In pt, this message translates to:
  /// **'a transação automática'**
  String get writeEntityAutomaticTransaction;

  /// No description provided for @writeEntityReconciliation.
  ///
  /// In pt, this message translates to:
  /// **'a conciliação'**
  String get writeEntityReconciliation;

  /// No description provided for @savePendingSync.
  ///
  /// In pt, this message translates to:
  /// **'Salvo neste dispositivo. Sincroniza quando a conexão voltar.'**
  String get savePendingSync;

  /// No description provided for @accountSavePendingSync.
  ///
  /// In pt, this message translates to:
  /// **'Salva neste dispositivo. Saldo inicial e fatura aparecem quando a conexão voltar.'**
  String get accountSavePendingSync;

  /// No description provided for @celebrationXpTitle.
  ///
  /// In pt, this message translates to:
  /// **'XP ganho'**
  String get celebrationXpTitle;

  /// No description provided for @celebrationMissionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Missão concluída'**
  String get celebrationMissionTitle;

  /// No description provided for @celebrationBadgeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Conquista desbloqueada'**
  String get celebrationBadgeTitle;

  /// No description provided for @celebrationBadgeFallback.
  ///
  /// In pt, this message translates to:
  /// **'Veja na vitrine'**
  String get celebrationBadgeFallback;

  /// No description provided for @celebrationLevelTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nível {level}'**
  String celebrationLevelTitle(int level);

  /// No description provided for @celebrationLevelSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'O cofre subiu de nível'**
  String get celebrationLevelSubtitle;

  /// No description provided for @celebrationTierTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova patente'**
  String get celebrationTierTitle;

  /// No description provided for @settingsAppearanceSection.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get settingsAppearanceSection;

  /// No description provided for @settingsThemeMode.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get settingsThemeMode;

  /// No description provided for @settingsThemeModeDesc.
  ///
  /// In pt, this message translates to:
  /// **'Claro, escuro ou como o sistema estiver.'**
  String get settingsThemeModeDesc;

  /// No description provided for @themeModeSystem.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get themeModeDark;

  /// No description provided for @settingsCelebrationSound.
  ///
  /// In pt, this message translates to:
  /// **'Som nas conquistas'**
  String get settingsCelebrationSound;

  /// No description provided for @settingsCelebrationSoundDesc.
  ///
  /// In pt, this message translates to:
  /// **'Desligado por padrão. A vibração continua.'**
  String get settingsCelebrationSoundDesc;

  /// No description provided for @missionPersonalConsistencyPlanLimits.
  ///
  /// In pt, this message translates to:
  /// **'Planejar limites para pelo menos {target} categorias e organizar a semana.'**
  String missionPersonalConsistencyPlanLimits(String target);

  /// No description provided for @missionPersonalDisciplineTopCategory.
  ///
  /// In pt, this message translates to:
  /// **'Manter a categoria {category} dentro do orçamento planejado por {target} dias.'**
  String missionPersonalDisciplineTopCategory(String category, String target);

  /// No description provided for @missionPersonalOrganizationReconcileItems.
  ///
  /// In pt, this message translates to:
  /// **'Fazer a conciliação completa de um extrato com pelo menos {target} itens.'**
  String missionPersonalOrganizationReconcileItems(String target);

  /// No description provided for @missionBusinessConsistencyCostCenters.
  ///
  /// In pt, this message translates to:
  /// **'Planejar o limite de {target} centros de custo para o mês.'**
  String missionBusinessConsistencyCostCenters(String target);

  /// No description provided for @missionBusinessConsistencyIncomeForecast.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar o recebimento de {target}% da receita prevista para a semana.'**
  String missionBusinessConsistencyIncomeForecast(String target);

  /// No description provided for @missionBusinessDisciplineTopCostCenter.
  ///
  /// In pt, this message translates to:
  /// **'Manter o centro de custo {category} dentro do plano por {target} dias.'**
  String missionBusinessDisciplineTopCostCenter(String category, String target);

  /// No description provided for @missionBusinessDisciplineMargin.
  ///
  /// In pt, this message translates to:
  /// **'Fechar a semana com a margem (receita − despesa) acima da planejada.'**
  String get missionBusinessDisciplineMargin;

  /// No description provided for @missionBusinessOrganizationReconcileStatements.
  ///
  /// In pt, this message translates to:
  /// **'Conciliar {target} extrato das contas da empresa nesta semana.'**
  String missionBusinessOrganizationReconcileStatements(String target);

  /// No description provided for @missionBusinessOrganizationCategorizeAuto.
  ///
  /// In pt, this message translates to:
  /// **'Categorizar ou descartar {target} lançamentos automáticos antes do fechamento.'**
  String missionBusinessOrganizationCategorizeAuto(String target);

  /// No description provided for @missionBusinessOrganizationCategorizeWeek.
  ///
  /// In pt, this message translates to:
  /// **'Categorizar {target}% dos lançamentos pagos na semana.'**
  String missionBusinessOrganizationCategorizeWeek(String target);

  /// No description provided for @missionBusinessOrganizationInvoiceOnTime.
  ///
  /// In pt, this message translates to:
  /// **'Fechar {target} fatura do cartão corporativo pagando até o vencimento.'**
  String missionBusinessOrganizationInvoiceOnTime(String target);

  /// No description provided for @missionFallbackCategoryPersonal.
  ///
  /// In pt, this message translates to:
  /// **'de maior gasto'**
  String get missionFallbackCategoryPersonal;

  /// No description provided for @missionFallbackCategoryBusiness.
  ///
  /// In pt, this message translates to:
  /// **'de maior peso'**
  String get missionFallbackCategoryBusiness;

  /// No description provided for @missionCtaPlanning.
  ///
  /// In pt, this message translates to:
  /// **'Planejar agora'**
  String get missionCtaPlanning;

  /// No description provided for @missionCtaPlanning503020.
  ///
  /// In pt, this message translates to:
  /// **'Abrir o 50-30-20'**
  String get missionCtaPlanning503020;

  /// No description provided for @missionCtaCategories.
  ///
  /// In pt, this message translates to:
  /// **'Ver a Party'**
  String get missionCtaCategories;

  /// No description provided for @missionCtaAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Ver contas'**
  String get missionCtaAccounts;

  /// No description provided for @missionCtaCategoryDetails.
  ///
  /// In pt, this message translates to:
  /// **'Ver categoria'**
  String get missionCtaCategoryDetails;

  /// No description provided for @missionCtaTransactionForm.
  ///
  /// In pt, this message translates to:
  /// **'Lançar agora'**
  String get missionCtaTransactionForm;

  /// No description provided for @workspaceTypePersonalBadge.
  ///
  /// In pt, this message translates to:
  /// **'Pessoal'**
  String get workspaceTypePersonalBadge;

  /// No description provided for @workspaceTypeBusinessBadge.
  ///
  /// In pt, this message translates to:
  /// **'Empresa'**
  String get workspaceTypeBusinessBadge;

  /// No description provided for @levelBadgeShort.
  ///
  /// In pt, this message translates to:
  /// **'Nv {level}'**
  String levelBadgeShort(int level);

  /// No description provided for @levelBadgeSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Nível {level} do cofre, {percent}% para o próximo'**
  String levelBadgeSemantics(int level, int percent);

  /// No description provided for @compassStripTitle.
  ///
  /// In pt, this message translates to:
  /// **'Bússola'**
  String get compassStripTitle;

  /// No description provided for @compassStripOpen.
  ///
  /// In pt, this message translates to:
  /// **'Ver a Bússola completa'**
  String get compassStripOpen;

  /// No description provided for @compassStripDelta.
  ///
  /// In pt, this message translates to:
  /// **'{points} desde o mês passado'**
  String compassStripDelta(String points);

  /// No description provided for @dueSoonTitle.
  ///
  /// In pt, this message translates to:
  /// **'Vence hoje e amanhã'**
  String get dueSoonTitle;

  /// No description provided for @dueSoonToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get dueSoonToday;

  /// No description provided for @dueSoonTomorrow.
  ///
  /// In pt, this message translates to:
  /// **'Amanhã'**
  String get dueSoonTomorrow;

  /// No description provided for @dueSoonInvoiceClosing.
  ///
  /// In pt, this message translates to:
  /// **'Fatura de {card} fecha'**
  String dueSoonInvoiceClosing(String card);

  /// No description provided for @dueSoonSemantics.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 compromisso vencendo hoje ou amanhã} other{{count} compromissos vencendo hoje ou amanhã}}'**
  String dueSoonSemantics(int count);

  /// No description provided for @journeySeeAllGoals.
  ///
  /// In pt, this message translates to:
  /// **'Ver as {count} metas'**
  String journeySeeAllGoals(int count);

  /// No description provided for @journeyNoRunningGoals.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma meta em andamento'**
  String get journeyNoRunningGoals;

  /// No description provided for @journeySeeClosedGoals.
  ///
  /// In pt, this message translates to:
  /// **'Ver {count} encerradas'**
  String journeySeeClosedGoals(int count);

  /// No description provided for @planning503020PlannedPercent.
  ///
  /// In pt, this message translates to:
  /// **'Planejado: {percent}'**
  String planning503020PlannedPercent(String percent);

  /// No description provided for @planning503020ActualPercent.
  ///
  /// In pt, this message translates to:
  /// **'Real: {percent}'**
  String planning503020ActualPercent(String percent);

  /// No description provided for @automaticTransactionSeeAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver as {count} pendências'**
  String automaticTransactionSeeAll(int count);

  /// No description provided for @goalsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Metas'**
  String get goalsTitle;

  /// Contador compacto de progresso de missão, para uma linha.
  ///
  /// In pt, this message translates to:
  /// **'{progress}/{target}'**
  String missionProgressShort(String progress, String target);

  /// No description provided for @arenaTitle.
  ///
  /// In pt, this message translates to:
  /// **'Arena'**
  String get arenaTitle;

  /// No description provided for @arenaHeroLife.
  ///
  /// In pt, this message translates to:
  /// **'Vida'**
  String get arenaHeroLife;

  /// No description provided for @arenaCommitted.
  ///
  /// In pt, this message translates to:
  /// **'Comprometido'**
  String get arenaCommitted;

  /// No description provided for @arenaConfirmPaid.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar pago'**
  String get arenaConfirmPaid;

  /// No description provided for @arenaEnraged.
  ///
  /// In pt, this message translates to:
  /// **'Enfurecido: +{amount} atrasado'**
  String arenaEnraged(String amount);

  /// No description provided for @arenaEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Sem compromissos e sem saldo nesta semana — a arena está vazia. Agende uma conta a pagar e o monstro aparece.'**
  String get arenaEmpty;

  /// No description provided for @arenaTeamExtra.
  ///
  /// In pt, this message translates to:
  /// **'+{count} na equipe'**
  String arenaTeamExtra(int count);

  /// No description provided for @arenaExhausted.
  ///
  /// In pt, this message translates to:
  /// **'Exausto'**
  String get arenaExhausted;

  /// No description provided for @arenaHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque no monstro para confirmar um pagamento. Toque nos heróis para ver as contas.'**
  String get arenaHint;

  /// No description provided for @automaticTransactionSeeAllShort.
  ///
  /// In pt, this message translates to:
  /// **'Ver todas'**
  String get automaticTransactionSeeAllShort;

  /// No description provided for @arenaWeekChallenge.
  ///
  /// In pt, this message translates to:
  /// **'Desafio da semana'**
  String get arenaWeekChallenge;

  /// No description provided for @arenaFree.
  ///
  /// In pt, this message translates to:
  /// **'Livre'**
  String get arenaFree;

  /// No description provided for @arenaHealed.
  ///
  /// In pt, this message translates to:
  /// **'Recebido na semana'**
  String get arenaHealed;

  /// No description provided for @arenaRemainingPrefix.
  ///
  /// In pt, this message translates to:
  /// **'falta'**
  String get arenaRemainingPrefix;

  /// No description provided for @arenaMonsterDefeated.
  ///
  /// In pt, this message translates to:
  /// **'Derrotado'**
  String get arenaMonsterDefeated;

  /// No description provided for @arenaOverheal.
  ///
  /// In pt, this message translates to:
  /// **'+{amount} acima de domingo'**
  String arenaOverheal(String amount);

  /// No description provided for @arenaHeroesFallback.
  ///
  /// In pt, this message translates to:
  /// **'Você'**
  String get arenaHeroesFallback;

  /// No description provided for @arenaDayOfWeek.
  ///
  /// In pt, this message translates to:
  /// **'{day}/{total}'**
  String arenaDayOfWeek(int day, int total);

  /// No description provided for @arenaDaysLeft.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Último dia da semana} other{Faltam {count} dias na semana}}'**
  String arenaDaysLeft(int count);

  /// No description provided for @arenaHeroesSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Vida dos heróis: {balance}, sendo {committed} comprometido. Toque para ver as contas.'**
  String arenaHeroesSemantics(String balance, String committed);

  /// No description provided for @arenaMonsterSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Monstro da semana: falta {remaining} de {total}. Toque para ver os compromissos.'**
  String arenaMonsterSemantics(String remaining, String total);

  /// No description provided for @arenaMonsterSheetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Compromissos da semana'**
  String get arenaMonsterSheetTitle;

  /// No description provided for @arenaMonsterSheetTitleBusiness.
  ///
  /// In pt, this message translates to:
  /// **'Contas a pagar da semana'**
  String get arenaMonsterSheetTitleBusiness;

  /// No description provided for @arenaMonsterSheetSummary.
  ///
  /// In pt, this message translates to:
  /// **'{paid} pagos de {total} — falta {remaining}'**
  String arenaMonsterSheetSummary(String paid, String total, String remaining);

  /// No description provided for @arenaNextBlow.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Próximo golpe: 1 vence até amanhã} other{Próximo golpe: {count} vencem até amanhã}}'**
  String arenaNextBlow(int count);

  /// No description provided for @arenaNoCommitments.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum compromisso agendado nesta semana.'**
  String get arenaNoCommitments;

  /// No description provided for @arenaPaidOn.
  ///
  /// In pt, this message translates to:
  /// **'Pago · {date}'**
  String arenaPaidOn(String date);

  /// No description provided for @arenaOverdueSince.
  ///
  /// In pt, this message translates to:
  /// **'{days, plural, =1{Atrasado 1 dia · {date}} other{Atrasado {days} dias · {date}}}'**
  String arenaOverdueSince(String date, int days);

  /// No description provided for @arenaHeroesSheetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Suas contas nesta semana'**
  String get arenaHeroesSheetTitle;

  /// No description provided for @arenaHeroesSheetSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'A semana começou com {initial} em caixa.'**
  String arenaHeroesSheetSubtitle(String initial);

  /// No description provided for @arenaNoAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conta corrente ou de investimento cadastrada.'**
  String get arenaNoAccounts;

  /// No description provided for @arenaMonsterSpider.
  ///
  /// In pt, this message translates to:
  /// **'Aranha'**
  String get arenaMonsterSpider;

  /// No description provided for @arenaMonsterBat.
  ///
  /// In pt, this message translates to:
  /// **'Morcego'**
  String get arenaMonsterBat;

  /// No description provided for @arenaMonsterGhost.
  ///
  /// In pt, this message translates to:
  /// **'Fantasma'**
  String get arenaMonsterGhost;

  /// No description provided for @arenaMonsterSlime.
  ///
  /// In pt, this message translates to:
  /// **'Gosma'**
  String get arenaMonsterSlime;

  /// No description provided for @arenaMonsterDemon.
  ///
  /// In pt, this message translates to:
  /// **'Demônio'**
  String get arenaMonsterDemon;

  /// No description provided for @arenaError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível montar a arena desta semana.'**
  String get arenaError;

  /// No description provided for @arenaScheduledOn.
  ///
  /// In pt, this message translates to:
  /// **'Agendado · {date}'**
  String arenaScheduledOn(String date);
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
