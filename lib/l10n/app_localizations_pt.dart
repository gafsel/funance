// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Funances';

  @override
  String get loginTitle => 'Funances';

  @override
  String get loginSubtitle =>
      'Sua jornada para a liberdade financeira começa aqui.';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get editButton => 'Editar';

  @override
  String get deleteButton => 'Excluir';

  @override
  String get displayNameLabel => 'Nome Completo';

  @override
  String get loginButton => 'Entrar';

  @override
  String get registerButton => 'Criar Conta';

  @override
  String get registerLink => 'Não tem uma conta? Cadastre-se';

  @override
  String get loginLink => 'Já tem uma conta? Faça login';

  @override
  String get googleLoginButton => 'Entrar com Google';

  @override
  String get orDivider => 'OU';

  @override
  String get fieldRequired => 'Este campo é obrigatório';

  @override
  String get invalidEmail => 'E-mail inválido';

  @override
  String get appErrorWidgetTitle => 'Algo deu errado';

  @override
  String get appErrorWidgetMessage =>
      'Já fomos avisados e estamos trabalhando nisso. Tente voltar e abrir a tela de novo.';

  @override
  String get errorUnknown => 'Ocorreu um erro inesperado.';

  @override
  String get routeNotFound => 'Página não encontrada.';

  @override
  String get routeNotFoundGoHome => 'Voltar para o início';

  @override
  String get closeButton => 'Fechar';

  @override
  String get workspacePickerTitle => 'Workspaces';

  @override
  String get transactionMoreOptions => 'Mais Opções';

  @override
  String get transactionMatchTitle =>
      'Existe um agendamento nesta categoria. Quitar este?';

  @override
  String get transactionMatchSettle => 'Quitar';

  @override
  String get transactionMatchDismiss => 'É um gasto novo';

  @override
  String get transactionMatchDismissIncome => 'É uma receita nova';

  @override
  String get transactionMatchSearching => 'Procurando agendamentos…';

  @override
  String get transactionMatchUndo => 'Não era esse';

  @override
  String get transactionMatchSameAmount => 'mesmo valor';

  @override
  String get onboardingConceptXpTitle => 'Ganhe XP e suba de nível';

  @override
  String get onboardingConceptXpDesc =>
      'Cada lançamento vale XP — e gastar dentro do planejado vale ainda mais. Seu workspace evolui de nível como num jogo.';

  @override
  String get onboardingConceptMissionsTitle => 'Missões e conquistas';

  @override
  String get onboardingConceptMissionsDesc =>
      'Complete missões semanais, mantenha sua sequência de semanas perfeitas e desbloqueie insígnias na sua vitrine de conquistas.';

  @override
  String get onboardingConceptCoachTitle => 'Seu coach financeiro';

  @override
  String get onboardingConceptCoachDesc =>
      'Um coach com IA que conhece seus números e traz conselhos práticos e personalizados rumo à sua liberdade financeira.';

  @override
  String get onboardingNoSuggestions =>
      'Nenhuma sugestão por enquanto — você pode criar metas e planejamentos depois, na aba Jornada.';

  @override
  String journeyStreakWeeks(int count) {
    return '$count semanas perfeitas seguidas';
  }

  @override
  String get journeyAddGoalTooltip => 'Nova meta';

  @override
  String get errorKeychain =>
      'Sua sessão não pôde ser salva. Você poderá usar o app, mas precisará logar novamente ao reabrir.';

  @override
  String get errorUserNotFound => 'Usuário não encontrado.';

  @override
  String get errorWrongPassword => 'Senha incorreta.';

  @override
  String get errorEmailAlreadyInUse =>
      'Este e-mail já está sendo usado por outra conta.';

  @override
  String get errorWeakPassword => 'A senha fornecida é muito fraca.';

  @override
  String get errorInvalidEmail => 'O endereço de e-mail não é válido.';

  @override
  String get errorNetworkRequestFailed => 'Falha na conexão com a internet.';

  @override
  String get errorGoogleSignInConfig =>
      'Erro de configuração no login com Google. Verifique se a chave SHA-1 foi adicionada ao Firebase Console.';

  @override
  String get errorSignInPopupBlocked =>
      'Seu navegador bloqueou a janela do Google. Liberamos o login nesta mesma aba — se nada acontecer, permita pop-ups para este site e tente de novo.';

  @override
  String get errorSignInCancelled => 'Login cancelado.';

  @override
  String get errorSignInRedirecting => 'Redirecionando para o Google...';

  @override
  String get errorSignInUnauthorizedDomain =>
      'Este endereço não está autorizado a fazer login. Adicione o domínio em Authentication > Settings > Authorized domains no Firebase Console.';

  @override
  String get errorAccountExistsWithDifferentCredential =>
      'Já existe uma conta com este e-mail criada por outro método. Entre com e-mail e senha.';

  @override
  String get errorSignInProviderDisabled =>
      'Este método de login está desativado no projeto. Habilite-o em Authentication > Sign-in method.';

  @override
  String get offlineBannerOffline =>
      'Sem conexão. Você continua vendo e editando; sincronizamos quando a rede voltar.';

  @override
  String get offlineBannerPending =>
      'Salvo neste aparelho. Sincronizando com a nuvem...';

  @override
  String get errorOfflineCallable =>
      'Esta ação precisa de internet. Reconecte e tente de novo.';

  @override
  String get reconciliationChooseAccount => 'Qual conta você quer conciliar?';

  @override
  String get errorOffline =>
      'Sem conexão com a internet. Mostramos o que já estava no aparelho; toque em tentar de novo quando a rede voltar.';

  @override
  String get errorPermissionDenied =>
      'Você não tem acesso a estes dados. Se acabou de sair de um workspace, entre de novo.';

  @override
  String get errorQuotaExhausted =>
      'Limite de uso atingido. Tente de novo mais tarde.';

  @override
  String get errorNotAuthenticated =>
      'Sua sessão expirou. Entre de novo para continuar.';

  @override
  String get errorNotFound => 'Este item não existe mais.';

  @override
  String get errorTimeout =>
      'O servidor demorou demais para responder. Tente de novo.';

  @override
  String get onboardingWelcomeTitle => 'Boas-vindas ao Funances!';

  @override
  String get onboardingWelcomeDesc =>
      'O app que transforma sua gestão financeira em uma jornada de conquistas.';

  @override
  String get onboardingNext => 'Próximo';

  @override
  String get onboardingPersonalTitle => 'Workspace Pessoal';

  @override
  String get onboardingPersonalDesc =>
      'Ideal para suas contas individuais, gastos do dia a dia e metas pessoais.';

  @override
  String get onboardingBusinessTitle => 'Workspace de Negócio';

  @override
  String get onboardingBusinessDesc =>
      'Gerencie o fluxo de caixa da sua empresa ou projeto paralelo de forma profissional.';

  @override
  String get onboardingWorkspaceNameTitle => 'Dê um nome ao seu Workspace';

  @override
  String get onboardingWorkspaceNamePersonalHint =>
      'Ex: Minhas Finanças, Família Silva...';

  @override
  String get onboardingWorkspaceNameBusinessHint =>
      'Ex: Minha Empresa, Freelance...';

  @override
  String get onboardingWorkspaceNameLabel => 'Nome do Workspace';

  @override
  String get onboardingGoalsTitle => 'Trace suas primeiras metas';

  @override
  String get onboardingGoalsButton => 'ENTENDI, PRÓXIMO PASSO';

  @override
  String get onboardingMembersTitle => 'Convide membros';

  @override
  String get onboardingMembersDesc =>
      'Você pode compartilhar seu workspace com sócios ou familiares para gerirem as finanças juntos.';

  @override
  String get onboardingFinish => 'CONCLUIR ONBOARDING';

  @override
  String get onboardingAccountsTitle => 'DEFINIR CONTAS';

  @override
  String get onboardingAccountsDesc =>
      'Cadastre suas contas bancárias ou cartões de crédito. Você pode anexar extratos (PDF/OFX) para automatizar o processo.';

  @override
  String get onboardingAccountsEmpty => 'Nenhuma conta adicionada';

  @override
  String get onboardingAccountsAdd => 'ADICIONAR CONTA';

  @override
  String get onboardingAccountsAddAnother => 'ADICIONAR OUTRA CONTA';

  @override
  String get onboardingGoalsAnalysisTitle => 'SUGESTÕES DA IA';

  @override
  String get onboardingGoalsAnalysisDesc =>
      'Com base no seu perfil e contas, nossa IA sugere algumas metas e planejamentos para você.';

  @override
  String get onboardingSuggestedGoalsTitle => 'Metas Sugeridas';

  @override
  String get onboardingSuggestedPlanningsTitle => 'Planejamentos Sugeridos';

  @override
  String get onboardingMembersListTitle => 'Lista de convites';

  @override
  String get onboardingMembersEmpty => 'Nenhum e-mail adicionado';

  @override
  String get onboardingSuccessTitle => 'Tudo pronto!';

  @override
  String get onboardingSuccessDesc =>
      'Seu workspace foi configurado com sucesso. Agora você já pode começar a organizar sua vida financeira.';

  @override
  String get onboardingSuccessCTA => 'IR PARA A TELA PRINCIPAL';

  @override
  String get onboardingStepConceptsDesc =>
      'Para tirar o máximo proveito do Funances, vamos entender como organizamos as informações.';

  @override
  String get onboardingConceptLimitsTitle => 'Limites e Expectativas';

  @override
  String get onboardingConceptLimitsDesc =>
      'Defina quanto você espera ganhar e o limite máximo que deseja gastar por categoria. É o seu teto financeiro.';

  @override
  String get onboardingConceptPlanningTitle => 'Agendamentos';

  @override
  String get onboardingConceptPlanningDesc =>
      'Funciona como um lançamento agendado: contabiliza no teto da categoria mas não interfere no saldo da conta até ser efetivado. Ideal para pagamentos recorrentes ou parcelados.';

  @override
  String get onboardingConceptFeaturesTitle =>
      'Funcionalidades e Onde Encontrar';

  @override
  String get onboardingConceptFeaturesDesc =>
      'Explore o Dashboard para visão geral, Extratos para conciliação e Metas para acompanhar seus sonhos.';

  @override
  String get onboardingConceptTransactionsTitle => 'Lançamentos';

  @override
  String get onboardingConceptTransactionsDesc =>
      'O dia a dia! Registre suas entradas e saídas reais para acompanhar seu progresso em relação ao plano.';

  @override
  String goalTargetTarget(String amount) {
    return 'Alvo: $amount';
  }

  @override
  String get goalDetailsTitle => 'Detalhes da Meta';

  @override
  String get goalEditButton => 'Editar Meta';

  @override
  String get goalDeleteConfirmTitle => 'Excluir Meta?';

  @override
  String get goalDeleteConfirmMessage =>
      'Tem certeza que deseja excluir esta meta? Esta ação não pode ser desfeita.';

  @override
  String get goalStatusOnTrack => 'No Caminho';

  @override
  String get goalStatusAtRisk => 'Em Risco';

  @override
  String get goalStatusBehind => 'Atrasada';

  @override
  String get goalStatusLost => 'Perdida';

  @override
  String get goalProgressChartTitle => 'Progresso';

  @override
  String get goalChartIdealLine => 'Ideal';

  @override
  String get goalChartRealLine => 'Real';

  @override
  String get goalChartStartLabel => 'Início';

  @override
  String get goalChartEndLabel => 'Prazo';

  @override
  String get goalAnalyzeWithAi => 'Analisar com IA';

  @override
  String get goalAiError =>
      'Não foi possível analisar a meta. Tente novamente.';

  @override
  String get reconciliationError =>
      'Não foi possível analisar o extrato. Tente novamente.';

  @override
  String get goalAiAnalyzing => 'Analisando sua meta...';

  @override
  String get goalAiAnalyzingDesc =>
      'Nossa IA está examinando seu histórico financeiro para avaliar a viabilidade desta meta.';

  @override
  String get goalAiFeasible => 'Viável';

  @override
  String get goalAiChallenging => 'Desafiadora';

  @override
  String get goalAiUnrealistic => 'Irrealista';

  @override
  String get goalAiResultTitle => 'Análise da Meta';

  @override
  String get goalAiReason => 'Por quê:';

  @override
  String get goalAiSuggestion => 'Sugestão:';

  @override
  String get goalAiClose => 'Entendi';

  @override
  String goalMonthlyRequirementValue(String amount) {
    return '$amount/mês';
  }

  @override
  String get automaticTransactionTitle => 'Lançamentos Identificados';

  @override
  String get automaticTransactionSubtitle =>
      'Identificamos novas movimentações nas suas notificações. Deseja registrar?';

  @override
  String get automaticTransactionConsolidate => 'Cadastrar';

  @override
  String get automaticTransactionIgnore => 'Ignorar';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileEditTitle => 'Editar Perfil';

  @override
  String get profileNameLabel => 'Nome';

  @override
  String get profileEmailLabel => 'E-mail';

  @override
  String get profileUpdateSuccess => 'Perfil atualizado com sucesso!';

  @override
  String get profilePhotoCamera => 'Câmera';

  @override
  String get profilePhotoGallery => 'Galeria';

  @override
  String get planning503020Title => 'Planejamento 50-30-20';

  @override
  String get planning503020SummaryIncome => 'Receita Prevista';

  @override
  String get planning503020SummaryExpense => 'Despesa Prevista';

  @override
  String get planning503020Essential => 'Essencial';

  @override
  String get planning503020Comfort => 'Conforto';

  @override
  String get planning503020Investment => 'Investimento';

  @override
  String get planning503020EssentialDesc =>
      'Limites de gastos com necessidades básicas. Ideal: 50% da sua receita.';

  @override
  String get planning503020ComfortDesc =>
      'Gastos com seu estilo de vida e lazer. Ideal: 30% da sua receita.';

  @override
  String get planning503020InvestmentDesc =>
      'Futuro e segurança (investimentos e dívidas). Ideal: 20% da sua receita.';

  @override
  String planning503020ActualAmount(String amount) {
    return 'Real: $amount';
  }

  @override
  String get planning503020Subtitle => 'Acompanhe sua regra de ouro 50-30-20';

  @override
  String get planning503020DistributionTitle => 'Distribuição 50-30-20';

  @override
  String get planning503020Planned => 'Planejado';

  @override
  String get planning503020Actual => 'Executado';

  @override
  String get planning503020SummaryActual => 'Gasto Real';

  @override
  String get planning503020ActualLabel => 'Já gasto:';

  @override
  String planning503020Total(String amount) {
    return 'Total: $amount';
  }

  @override
  String get planning503020AlertSpecificGreater =>
      'Gastos previstos superiores ao estimado!';

  @override
  String get planning503020EmptyPool => 'Arraste categorias para cá';

  @override
  String get automaticTransactionSimulate => 'Simular Notificação';

  @override
  String get automaticTransactionRequestPermission => 'Ouvir Notificações';

  @override
  String get automaticTransactionPermissionRequired =>
      'Para detectar transações automaticamente, o app precisa de permissão para ler notificações.';

  @override
  String get automaticTransactionGrantPermission => 'Conceder Permissão';

  @override
  String goalRemainingValue(String amount) {
    return 'Faltam $amount';
  }

  @override
  String get goalEmptyMessage =>
      'Que tal começar a planejar o seu futuro? Crie a sua primeira meta agora!';

  @override
  String get goalEmptyExample => 'Ex.: Viagem pra Disney';

  @override
  String get addGoalButton => 'Nova Meta';

  @override
  String get goalNameLabel => 'Nome da Meta';

  @override
  String get goalTargetAmountLabel => 'Valor Alvo';

  @override
  String get goalDeadlineLabel => 'Prazo';

  @override
  String get goalTypeLabel => 'Tipo de Meta';

  @override
  String get goalTypeSaveMoney => 'Juntar Dinheiro';

  @override
  String get goalTypeReduceExpense => 'Economizar (Categoria)';

  @override
  String get goalTypeReduceCreditCard => 'Reduzir Cartão de Crédito';

  @override
  String get goalTypePayDebt => 'Pagar Dívida';

  @override
  String get goalCategoryLabel => 'Categoria';

  @override
  String get errorGoalNotFound => 'Meta não encontrada.';

  @override
  String get errorGoalTypeCannotBeChanged =>
      'O tipo da meta não pode ser alterado.';

  @override
  String get continueButton => 'CONTINUAR';

  @override
  String get invitesTitle => 'Convites Pendentes';

  @override
  String get uploadFileUnreadable => 'Não foi possível ler o arquivo.';

  @override
  String uploadUnsupportedFormat(String formats) {
    return 'Formato não suportado. Use apenas: $formats';
  }

  @override
  String uploadFileTooLarge(String size, int limit) {
    return 'Este arquivo tem $size e o limite da análise é $limit MB. Exporte o extrato em OFX, que é bem menor que o PDF, ou divida em períodos mais curtos.';
  }

  @override
  String get membersTitle => 'Membros';

  @override
  String get membersOwnerRole => 'Dono';

  @override
  String get membersMemberRole => 'Membro';

  @override
  String get membersYou => 'você';

  @override
  String get membersSectionActive => 'No workspace';

  @override
  String get membersSectionPending => 'Convites aguardando resposta';

  @override
  String get membersEmptyPending => 'Nenhum convite aguardando resposta.';

  @override
  String get membersLoadError => 'Não foi possível carregar os membros.';

  @override
  String get membersInvitesLoadError =>
      'Não foi possível carregar os convites.';

  @override
  String get membersRetry => 'Tentar de novo';

  @override
  String get membersRemoveAction => 'Remover do workspace';

  @override
  String membersRemoveTitle(String name) {
    return 'Remover $name?';
  }

  @override
  String get membersRemoveConfirm =>
      'Essa pessoa perde o acesso a este workspace. Os lançamentos, contas e categorias continuam onde estão — eles são do workspace, não de quem os criou.';

  @override
  String get membersRemoveSuccess => 'Membro removido.';

  @override
  String membersInviteSentAt(String date) {
    return 'Convidado em $date';
  }

  @override
  String get membersResendAction => 'Reenviar';

  @override
  String get membersResendSuccess => 'Convite renovado.';

  @override
  String get membersCancelInviteAction => 'Cancelar convite';

  @override
  String membersCancelInviteTitle(String email) {
    return 'Cancelar o convite de $email?';
  }

  @override
  String get membersCancelInviteConfirm =>
      'O convite deixa de aparecer para quem foi convidado.';

  @override
  String get membersCancelInviteSuccess => 'Convite cancelado.';

  @override
  String get invitesSubtitle =>
      'Você foi convidado para participar dos seguintes workspaces:';

  @override
  String inviteFrom(String sender) {
    return 'Enviado por: $sender';
  }

  @override
  String get acceptButton => 'Aceitar';

  @override
  String get declineButton => 'Recusar';

  @override
  String get homeJourneyTab => 'A Jornada';

  @override
  String get homeOverviewTab => 'Visão Geral';

  @override
  String get homeHistoryTab => 'Extrato';

  @override
  String get homeAccountsAndCards => 'Saldos e Faturas';

  @override
  String get weeklyMissions => 'Missões da Semana';

  @override
  String get weeklyMissionsNone => 'Nenhuma missão para esta semana';

  @override
  String get weeklyMissionsNoneDesc =>
      'Configure planejamentos ou adicione transações para começar.';

  @override
  String get pendingMissions => 'Pendentes';

  @override
  String get completedMissions => 'Concluídas';

  @override
  String get overdueMissions => 'Atrasadas';

  @override
  String weeklyMissionsProgress(String completed, String total) {
    return '$completed de $total completadas';
  }

  @override
  String xpValue(String xp) {
    return '$xp XP';
  }

  @override
  String percentage(String value) {
    return '$value%';
  }

  @override
  String dateRange(String start, String end) {
    return '$start - $end';
  }

  @override
  String get homeWhereIsMoney => 'Onde está o dinheiro?';

  @override
  String get homeTotalSpent => 'Total Gasto';

  @override
  String get homeNewTransaction => 'Novo Lançamento';

  @override
  String get noTransactionsInPeriod =>
      'Nenhuma transação encontrada para este período';

  @override
  String get historyFilterAccountLabel => 'Conta';

  @override
  String get all => 'Todos';

  @override
  String get historyFilterTitle => 'Filtros';

  @override
  String get historyFilterDescriptionLabel => 'Descrição';

  @override
  String get historyFilterTypeLabel => 'Tipo de Transação';

  @override
  String get historyFilterCategoryLabel => 'Categoria';

  @override
  String get historyFilterStatusLabel => 'Status';

  @override
  String get historyFilterMinAmountLabel => 'Valor Mínimo';

  @override
  String get historyFilterMaxAmountLabel => 'Valor Máximo';

  @override
  String get transactionWizardSelectCategory => 'Selecione a Categoria';

  @override
  String get historyFilterApply => 'Aplicar Filtros';

  @override
  String get historyFilterClear => 'Limpar';

  @override
  String get homeSettings => 'Configurações';

  @override
  String get homeNoWorkspaceSelected => 'Nenhum workspace selecionado';

  @override
  String get workspaceSettingsTitle => 'Configurações do Workspace';

  @override
  String get workspaceSettingsGeneralSection => 'Geral';

  @override
  String get workspaceSettingsEditName => 'Nome do Workspace';

  @override
  String get workspaceSettingsDataSection => 'Dados';

  @override
  String get workspaceSettingsCategories => 'Categorias';

  @override
  String get workspaceSettingsTeamSection => 'Equipe';

  @override
  String get workspaceSettingsMembers => 'Membros';

  @override
  String get workspaceSettingsEditNameDesc =>
      'Altere o nome do seu workspace para melhor identificação.';

  @override
  String get workspaceSettingsCategoriesDesc =>
      'Gerencie as categorias de receitas e despesas do seu workspace.';

  @override
  String get workspaceSettingsAccountsDesc =>
      'Configure suas contas bancárias, cartões de crédito e investimentos.';

  @override
  String get workspaceSettingsMembersDesc =>
      'Convide sócios ou familiares para gerirem as finanças juntos.';

  @override
  String get workspaceSettingsLogout => 'Sair';

  @override
  String get workspaceSettingsLogoutDesc =>
      'Encerre sua sessão atual de forma segura.';

  @override
  String get categoryManagementTitle => 'Gestão de Categorias';

  @override
  String get categoryManagementEmpty => 'Nenhuma categoria cadastrada.';

  @override
  String get categoryCreateTitle => 'Nova Categoria';

  @override
  String get categoryEditTitle => 'Editar Categoria';

  @override
  String get categoryNameLabel => 'Nome da Categoria';

  @override
  String get categoryTypeLabel => 'Tipo';

  @override
  String get categoryTypeIncome => 'Receita';

  @override
  String get categoryTypeExpense => 'Despesa';

  @override
  String get categoryDeleteTitle => 'Excluir Categoria';

  @override
  String categoryDeleteConfirm(String name) {
    return 'Deseja realmente excluir a categoria \"$name\"?';
  }

  @override
  String get categoryVirtualDebt => 'Empréstimo/Dívidas';

  @override
  String get categoryVirtualInvestment => 'Investimentos';

  @override
  String get categoryInitialBalance => 'Saldo Inicial';

  @override
  String get categoryOthers => 'Outros';

  @override
  String get saveButton => 'Salvar';

  @override
  String get reconciliationTitle => 'Conciliação Bancária';

  @override
  String get unnamedWorkspace => 'Workspace sem nome';

  @override
  String get accountManagementEmptyOfType =>
      'Você ainda não tem contas deste tipo.';

  @override
  String get bankLogoOther => 'Outros';

  @override
  String get accountsMine => 'Minhas contas';

  @override
  String accountsOfMember(String name) {
    return 'Contas de $name';
  }

  @override
  String get accountsShared => 'Contas compartilhadas';

  @override
  String planning503020TargetPercent(String percent) {
    return 'Meta: $percent';
  }

  @override
  String get noCategory => 'Sem categoria';

  @override
  String get noDescription => 'Sem descrição';

  @override
  String get unnamedAccount => 'Conta sem nome';

  @override
  String get unnamedGoal => 'Meta sem nome';

  @override
  String get automaticTransactionMoveWorkspace => 'Mover para outro workspace';

  @override
  String get accountOwnersLabel => 'Titulares da conta';

  @override
  String get reconciliationPickTransaction => 'Selecionar lançamento';

  @override
  String get transactionNewTitle => 'Novo lançamento';

  @override
  String get planning503020IdealLabel => 'Ideal';

  @override
  String get planning503020MonthlyLimitLabel => 'Limite Mensal';

  @override
  String get planning503020AlreadyPlanned => 'Já previsto:';

  @override
  String get loginTermsNotice =>
      'Ao entrar, você concorda com nossos Termos de Serviço e Política de Privacidade.';

  @override
  String get inviteEmailHint => 'exemplo@email.com';

  @override
  String get uploadStatusReading => 'Lendo o arquivo do extrato…';

  @override
  String get uploadStatusExtracting => 'Extraindo transações e valores…';

  @override
  String get uploadStatusSearching =>
      'Procurando os lançamentos correspondentes…';

  @override
  String get uploadStatusPreparing => 'Preparando as sugestões de conciliação…';

  @override
  String get uploadStatusCompleted => 'Conciliação pronta.';

  @override
  String get uploadStatusError => 'Não foi possível ler este extrato.';

  @override
  String get reconciliationAction => 'Conciliar extrato';

  @override
  String get reconciliationMissionCta => 'Conciliar extrato agora';

  @override
  String reconciliationTransactionsFound(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transações encontradas',
      one: '1 transação encontrada',
      zero: 'Nenhuma transação encontrada',
    );
    return '$_temp0';
  }

  @override
  String get reconciliationSelectAccount =>
      'Selecione o arquivo de extrato ou fatura';

  @override
  String get reconciliationSupportedFormats =>
      'Suporta PDF, OFX e Imagens (PNG, JPG)';

  @override
  String get reconciliationChooseFile => 'Escolher Arquivo';

  @override
  String get reconciliationAnalyzing => 'Analisando seu extrato';

  @override
  String get reconciliationAnalyzingDesc =>
      'A IA está processando as transações do seu documento para conciliação.';

  @override
  String get reconciliationConfirm => 'Confirmar';

  @override
  String get reconciliationBack => 'Voltar';

  @override
  String get reconciliationSuccess => 'Conciliação realizada com sucesso!';

  @override
  String get reconciliationStatusMatched => 'Encontrado';

  @override
  String get reconciliationStatusSuggested => 'Sugerido';

  @override
  String get reconciliationStatusUnmatched => 'Novo';

  @override
  String get reconciliationStatusIgnored => 'Ignorado';

  @override
  String get reconciliationActionConfirm => 'Confirmar';

  @override
  String get reconciliationActionModify => 'Modificar';

  @override
  String get reconciliationActionIgnore => 'Ignorar';

  @override
  String get reconciliationActionRestore => 'Restaurar';

  @override
  String get reconciliationActionLink => 'Vincular';

  @override
  String get reconciliationActionRegister => 'Cadastrar';

  @override
  String get reconciliationSystemLabel => 'SISTEMA';

  @override
  String get reconciliationExtratoLabel => 'EXTRATO';

  @override
  String get reconciliationNoMatchFound =>
      'Nenhuma transação correlata encontrada';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get categoryColorLabel => 'Cor da Categoria';

  @override
  String get categoryIconLabel => 'Ícone da Categoria';

  @override
  String get workspaceSettingsAccounts => 'Contas';

  @override
  String get accountManagementTitle => 'Gestão de Contas';

  @override
  String get accountManagementEmpty => 'Nenhuma conta cadastrada.';

  @override
  String get accountCreateTitle => 'Nova Conta';

  @override
  String get accountEditTitle => 'Editar Conta';

  @override
  String get accountNameLabel => 'Nome da Conta';

  @override
  String get accountTypeLabel => 'Tipo de Conta';

  @override
  String get accountTypeChecking => 'Conta Corrente';

  @override
  String get accountTypeInvestment => 'Investimento';

  @override
  String get accountTypeCreditCard => 'Cartão de Crédito';

  @override
  String get accountTypeDebt => 'Dívida';

  @override
  String get accountColorLabel => 'Cor da Conta';

  @override
  String get accountIconLabel => 'Ícone da Conta';

  @override
  String get accountLimitLabel => 'Limite';

  @override
  String get accountDueDayLabel => 'Dia do Vencimento';

  @override
  String get accountClosingDayLabel => 'Dia do Fechamento';

  @override
  String get accountInterestRateLabel => 'Taxa de Juros (%)';

  @override
  String get accountDeleteTitle => 'Excluir Conta';

  @override
  String accountDeleteConfirm(String name) {
    return 'Deseja realmente excluir a conta \"$name\"? (Os dados não serão perdidos fisicamente)';
  }

  @override
  String get addWorkspaceButton => 'Adicionar Workspace';

  @override
  String get goalAccountLabel => 'Conta associada';

  @override
  String get transactionAddExpense => 'Lançar Despesa';

  @override
  String get transactionAddIncome => 'Lançar Receita';

  @override
  String get transactionPlanExpense => 'Agendar Despesa';

  @override
  String get transactionPlanIncome => 'Agendar Receita';

  @override
  String get transactionPlanTransfer => 'Agendar Transferência';

  @override
  String get transactionActionTransfer => 'Transferência';

  @override
  String get transactionCategoriesSection => 'Categorias';

  @override
  String get transactionRealizedSection => 'Registrei';

  @override
  String get transactionRealizedSubtitle =>
      'Já aconteceu e já mexeu no seu saldo.';

  @override
  String get transactionPlannedSection => 'Agendar';

  @override
  String get transactionPlannedSubtitle =>
      'Ainda vai acontecer: contas a pagar e a receber.';

  @override
  String get planningSectionTitle => 'Estratégia';

  @override
  String get planningSectionSubtitle =>
      'Defina limites e acompanhe sua distribuição de gastos ideal.';

  @override
  String get transactionDescriptionLabel => 'Descrição';

  @override
  String get transactionAmountLabel => 'Valor';

  @override
  String get transactionAmountTotalLabel => 'Valor Total';

  @override
  String get transactionAmountInstallmentLabel => 'Valor da Parcela';

  @override
  String get transactionAmountRecurringLabel => 'Valor Recorrente';

  @override
  String get transactionDateLabel => 'Data';

  @override
  String get transactionAccountLabel => 'Conta';

  @override
  String get transactionInstallmentsLabel => 'Parcelas';

  @override
  String get transactionStatusSettled => 'Consolidado';

  @override
  String get transactionStatusPaid => 'Pago';

  @override
  String get transactionStatusPending => 'Pendente';

  @override
  String get transactionStatusLabel => 'Status';

  @override
  String get transactionSettledAlert =>
      'Este lançamento não pode ser modificado pois já foi consolidado.';

  @override
  String get transactionUnsettleAction => 'Desfazer conciliação';

  @override
  String get transactionTypeExpense => 'Despesa';

  @override
  String get transactionTypeIncome => 'Receita';

  @override
  String get transactionTypeTransfer => 'Transferência';

  @override
  String get transactionTypeInvoice => 'Fatura';

  @override
  String get transactionFromAccountLabel => 'Conta de Origem';

  @override
  String get transactionToAccountLabel => 'Conta de Destino';

  @override
  String get transactionSaveSuccess => 'Transação salva com sucesso!';

  @override
  String get transactionCascadeTitle => 'Aplicar alterações';

  @override
  String get transactionCascadeDescription =>
      'Deseja aplicar estas alterações apenas a esta parcela ou replicar para as demais?';

  @override
  String get transactionCascadeOnlyThis => 'Apenas esta';

  @override
  String get transactionCascadeThisAndNext => 'Esta e próximas';

  @override
  String get transactionCascadeAll => 'Todas';

  @override
  String get transactionDeleteCascadeTitle => 'Excluir parcelas';

  @override
  String get transactionDeleteCascadeDescription =>
      'Deseja excluir apenas esta parcela ou as demais também?';

  @override
  String get noAccountsFound => 'Nenhuma conta encontrada.';

  @override
  String get initialBalanceLabel => 'Saldo Inicial';

  @override
  String get initialBalanceCreditCardLabel => 'Valor da Próxima Fatura';

  @override
  String get initialBalanceInvestmentLabel => 'Valor Inicial do Investimento';

  @override
  String get initialBalanceDebtLabel => 'Valor Atual da Dívida';

  @override
  String get initialBalanceDateLabel => 'Data do Saldo Inicial';

  @override
  String get initialBalanceInvestmentDateLabel =>
      'Data do Investimento Inicial';

  @override
  String get initialBalanceDebtDateLabel => 'Data do Valor Atual';

  @override
  String get none => 'Nenhum';

  @override
  String get accountMethodDocument => 'Por Documento';

  @override
  String get accountMethodManual => 'Manual';

  @override
  String get accountDocumentDescription =>
      'Anexe seu extrato bancário (PDF) ou arquivo de transações (OFX). Nossa IA analisará os dados para configurar sua conta, saldo e transações automaticamente.';

  @override
  String get accountDocumentAcceptedTypes => 'Formatos aceitos: PDF, OFX';

  @override
  String get accountManualDescription =>
      'Preencha os dados da conta manualmente caso não possua um documento ou prefira configurar do seu jeito.';

  @override
  String get accountDetectedDataTitle => 'Dados detectados por IA';

  @override
  String accountDetectedTransactions(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transações encontradas',
      one: '1 transação encontrada',
    );
    return '$_temp0';
  }

  @override
  String get accountDetectedConfirmation =>
      'Confirme os dados abaixo para concluir o registro.';

  @override
  String get accountSelectFile => 'SELECIONAR ARQUIVO';

  @override
  String get accountDropFile =>
      'Arraste e solte o arquivo aqui ou clique para selecionar';

  @override
  String get accountAnalyzing => 'Analisando documento...';

  @override
  String get accountAnalysisDescription =>
      'Nossa IA está analisando seu documento para preparar os dados da sua conta e identificar transações automaticamente.';

  @override
  String get accountAnalysisProcessing => 'Processando dados...';

  @override
  String get onboardingPlanningAnalyzingTitle => 'Analisando padrões...';

  @override
  String get onboardingPlanningAnalyzingDesc =>
      'Nossa IA está analisando seus padrões de gastos para sugerir metas e planejamentos ideais para você.';

  @override
  String get accountViewTransactions => 'Ver Transações';

  @override
  String get accountDetectedTransactionsTitle => 'Transações Detectadas';

  @override
  String get historyEdit => 'Editar';

  @override
  String get historyDeleteTitle => 'Excluir Lançamento';

  @override
  String get historyDeleteConfirm =>
      'Deseja realmente excluir este lançamento?';

  @override
  String get today => 'Hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String get transactionTypeLabel => 'Tipo de Transação';

  @override
  String get transactionTypeSimple => 'Simples';

  @override
  String get transactionTypeInstallment => 'Parcelada';

  @override
  String get transactionTypeRecurrent => 'Recorrência';

  @override
  String get homeTotalPlanned => 'Total Planejado';

  @override
  String get overviewPlanning => 'Planejado';

  @override
  String get overviewEffective => 'Realizado';

  @override
  String get overviewComparison => 'Comparação';

  @override
  String get homeOverviewShowDetails => 'Ver Detalhes';

  @override
  String get categoryReportDetails => 'Detalhes por Categoria';

  @override
  String get transactionTransfer => 'Transferência';

  @override
  String get transactionTransferCountsAsInvestment =>
      'Vai contar como Investimentos';

  @override
  String get transactionTransferCountsAsDebt => 'Vai contar como Dívidas';

  @override
  String get transactionOrderTypeLabel => 'Tipo do Lançamento';

  @override
  String get clear => 'Limpar';

  @override
  String get validationEmailMessage => 'E-mail inválido';

  @override
  String validationLengthMaxMessage(Object min) {
    return 'Deve possuir no mínimo $min caracteres.';
  }

  @override
  String validationLenghtMinMessage(Object max) {
    return 'Deve possuir no máximo $max caracteres.';
  }

  @override
  String get validationNotEmptyMessage => 'Campo obrigatório.';

  @override
  String get validationNotNullMessage => 'Campo obrigatório.';

  @override
  String get noRecordsFound => 'Nenhum registro encontrado.';

  @override
  String get formatSimpleDate => 'dd/MM/yyyy';

  @override
  String get errorLoadingData => 'Falha ao carregar os dados.';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get planningExpenseLimits => 'Limites de Despesas';

  @override
  String get planningIncomeLimits => 'Expectativa de Receitas';

  @override
  String get planningLimitDefined => 'Limite definido';

  @override
  String get planningExpectationDefined => 'Expectativa definida';

  @override
  String get planningSave => 'SALVAR';

  @override
  String get expenses => 'Despesas';

  @override
  String get incomes => 'Receitas';

  @override
  String get balance => 'Saldo';

  @override
  String get securePasswordAtLeast8Characters => 'Ao menos 8 caracteres';

  @override
  String get securePasswordAtMost50Characters => 'No máximo 50 caracteres';

  @override
  String get securePasswordDontUseSpaces => 'Não use espaços';

  @override
  String get securePasswordAtLeast1Uppercase =>
      'Ao menos um caracter maiúsculo';

  @override
  String get securePasswordAtLeast1Lowercase =>
      'Ao menos um caracter minúsculo';

  @override
  String get securePasswordAtLeast1Number => 'Ao menos um número';

  @override
  String get signUpFailed =>
      'Falha ao tentar realizar o cadastro. Tente novamente ou contate nosso suporte.';

  @override
  String get signInFailed =>
      'Falha ao tentar realizar o acesso. Tente novamente ou contate nosso suporte.';

  @override
  String get dateInputPattern => 'dd/MM/yyyy';

  @override
  String installmentCountDescription(Object count, Object number) {
    return '$number de $count';
  }

  @override
  String get statusPending => 'Pendente';

  @override
  String get statusPaid => 'Pago';

  @override
  String get statusSettled => 'Conciliado';

  @override
  String get date => 'Data';

  @override
  String get historyAccountLabel => 'Conta';

  @override
  String get periodSummary => 'Resumo do Período';

  @override
  String get totalIncomes => 'Total de Receitas';

  @override
  String get totalExpenses => 'Total de Despesas';

  @override
  String get totalTransfers => 'Total de Transferências';

  @override
  String get totalInvoices => 'Total de Faturas';

  @override
  String get periodBalance => 'Saldo do Período';

  @override
  String get plannedLabel => 'Planejado';

  @override
  String get realizedLabel => 'Realizado';

  @override
  String get periodFilterDay => 'Dia';

  @override
  String get periodFilterMonth => 'Mês';

  @override
  String get periodFilterQuarter => 'Trimestre';

  @override
  String get periodFilterSemester => 'Semestre';

  @override
  String get periodFilterYear => 'Ano';

  @override
  String get periodFilterCustom => 'Customizado';

  @override
  String completedMissionsSummary(num count, Object xp) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'itens',
      one: 'item',
    );
    return '$count $_temp0 • $xp XP';
  }

  @override
  String get returnToPending => 'Retornar para Pendente';

  @override
  String get partyHpLabel => 'Saúde da Party';

  @override
  String get partyStatusHealthy => 'Party em segurança';

  @override
  String get partyStatusStrained => 'Party em perigo';

  @override
  String get partyStatusDefeated => 'Party derrotada';

  @override
  String get partyTitle => 'Sua Party';

  @override
  String get planned => 'Planejado';

  @override
  String get actual => 'Realizado';

  @override
  String get excess => 'Excesso';

  @override
  String get registerInvoicePayment => 'Registrar Pagamento de Fatura';

  @override
  String get coachingTitle => 'Coach Financeiro';

  @override
  String get coachingConsultAction => 'Consultar Coach';

  @override
  String get coachingViewLast => 'Ver última análise';

  @override
  String get coachingConsulting => 'Consultando Coach...';

  @override
  String get coachingConsultingDesc =>
      'Nossa IA está analisando sua saúde financeira para dar os melhores conselhos.';

  @override
  String get coachingError =>
      'Erro ao consultar coach. Tente novamente mais tarde.';

  @override
  String get coachingSlideNext => 'Próximo';

  @override
  String get coachingSlideBack => 'Voltar';

  @override
  String get coachingSlideFinish => 'Concluir';

  @override
  String get coachingNoData => 'Nenhum dado de coaching disponível.';

  @override
  String get coachingNoSlides => 'Nenhum slide foi gerado. Tente novamente.';

  @override
  String get coachingViewHistory => 'Ver histórico';

  @override
  String get coachingHistoryTitle => 'Histórico de Insights';

  @override
  String get coachingReviewTips => 'Rever Dicas';

  @override
  String get weeklyMissionsTitle => 'Missões Semanais';

  @override
  String get weeklyMissionsSuccessTitle => 'Missões Concluídas!';

  @override
  String get weeklyMissionsSuccessMessage =>
      'Parabéns! Você completou todas as atividades desta semana. Continue assim para manter sua saúde financeira em dia!';

  @override
  String get accountStatementCurrent => 'Atual';

  @override
  String get accountStatementFuture => 'Futuros';

  @override
  String get transactions => 'Lançamentos';

  @override
  String get challengeStatusStable => 'Estável';

  @override
  String get challengeStatusWarning => 'Alerta';

  @override
  String get challengeStatusCritical => 'Crítico';

  @override
  String get rest => 'Restante';

  @override
  String get category => 'Categoria';

  @override
  String get realization => 'Realização';

  @override
  String get difference => 'Diferença';

  @override
  String missingAmount(String amount) {
    return 'Faltam $amount';
  }

  @override
  String exceededAmount(String amount) {
    return 'Excederam $amount';
  }

  @override
  String get paymentInfo => 'Informações de pagamento';

  @override
  String get teamAchievementsTitle => 'Conquistas da Equipe';

  @override
  String workspaceLabel(String name) {
    return 'Workspace: $name';
  }

  @override
  String levelLabel(int level) {
    return 'Nível $level';
  }

  @override
  String totalXpLabel(String xp) {
    return 'Total: $xp XP';
  }

  @override
  String get weeklyStreaksLabelSingular => 'Sequência semanal: 1 semana';

  @override
  String weeklyStreaksLabelPlural(int streaks) {
    return 'Sequência semanal: $streaks semanas';
  }

  @override
  String get badgeUnlockedLabel => 'Desbloqueado';

  @override
  String get badgeLockedLabel => 'Bloqueado';

  @override
  String get badgeRewardLabel => 'Recompensa';

  @override
  String get badgeUnlockedAtLabel => 'Conquistado em';

  @override
  String levelIndicatorSemantics(int level, int count) {
    return 'Nível do Workspace: $level, Badges desbloqueados: $count';
  }

  @override
  String get statementDragOverTitle => 'Solte o arquivo do extrato aqui';

  @override
  String reconciliationBulkConfirmSuggestions(String amount) {
    return 'Confirmar todos os matches sugeridos ($amount)';
  }

  @override
  String get reconciliationWarningUnanswered =>
      'Responda a todas as transações antes de salvar';

  @override
  String get reconciliationActionUnlink => 'Desvincular';

  @override
  String get reconciliationAccountLabel => 'Conta de Conciliação';

  @override
  String get reconciliationNotInDocument => 'Não consta no documento';

  @override
  String get reconciliationActionKeep => 'Manter';

  @override
  String get reconciliationActionRemove => 'Remover';

  @override
  String get reconciliationStatusKeep => 'Manter no Sistema';

  @override
  String get reconciliationStatusRemove => 'Remover do Sistema';

  @override
  String get reconciliationStatusSystemOnly => 'Apenas no Sistema';

  @override
  String get goalDebtTotalLabel => 'Valor Total da Dívida';

  @override
  String get goalDebtTotalHint => 'Quanto você deve no total?';

  @override
  String get goalDebtAccountLabel => 'Vincular à Conta de Dívida';

  @override
  String get goalSpendingLimitHint => 'Ex: 500,00 (limite de gasto)';

  @override
  String get accountNotFound => 'Conta não encontrada.';

  @override
  String get savedSuccess => 'Salvo com sucesso!';

  @override
  String get planningAnalysisAction => 'Análise ideal (IA)';

  @override
  String get planningAnalysisLoadingTitle => 'Analisando seu planejamento';

  @override
  String get planningAnalysisLoadingDesc =>
      'A IA está calculando o gasto ideal de cada categoria com base na sua receita prevista e na regra 50-30-20.';

  @override
  String get planningAnalysisError =>
      'Não foi possível gerar a análise. Tente novamente.';

  @override
  String get planningAnalysisTitle => 'Análise Ideal 50-30-20';

  @override
  String planningAnalysisProjectedIncome(String amount) {
    return 'Receita prevista: $amount';
  }

  @override
  String planningAnalysisCurrentPct(String percent) {
    return 'Atual: $percent';
  }

  @override
  String planningAnalysisTargetPct(String percent) {
    return 'Alvo: $percent';
  }

  @override
  String planningAnalysisAboveBy(String amount) {
    return '$amount acima do alvo';
  }

  @override
  String planningAnalysisBelowBy(String amount) {
    return '$amount abaixo do alvo';
  }

  @override
  String get planningAnalysisCategoriesTitle => 'Ideal por categoria';

  @override
  String planningAnalysisIdealValue(String amount, String percent) {
    return 'Ideal: $amount ($percent da renda)';
  }

  @override
  String get planningAnalysisStatusOk => 'OK';

  @override
  String get planningAnalysisStatusAbove => 'Acima';

  @override
  String get planningAnalysisStatusBelow => 'Abaixo';

  @override
  String get planningAnalysisReclassTitle => 'Reclassificações sugeridas';

  @override
  String get planningAnalysisApply => 'Aplicar';

  @override
  String get planningAnalysisApplied => 'Categoria atualizada com sucesso!';

  @override
  String get planningAnalysisApplyError =>
      'Não foi possível atualizar a categoria.';

  @override
  String get planningAnalysisInsightsTitle => 'Insights';

  @override
  String planningAnalysisGeneratedAt(String date) {
    return 'Análise gerada em $date';
  }

  @override
  String planningAnalysisNextAvailable(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Nova análise disponível em $days dias',
      one: 'Nova análise disponível em $days dia',
    );
    return '$_temp0';
  }

  @override
  String get planningAnalysisGenerateNew => 'Gerar nova análise';

  @override
  String get goalSpendingLimitLabel => 'Teto de Gastos';

  @override
  String get goalAmountSavedLabel => 'Guardado';

  @override
  String get goalAmountPaidLabel => 'Quitado';

  @override
  String get goalAmountSpentLabel => 'Gasto';

  @override
  String goalCompletedAt(String date) {
    return 'Concluída em $date';
  }

  @override
  String goalSpentOfLimit(String amount, String limit) {
    return '$amount de $limit';
  }

  @override
  String goalRemainingLimit(String amount) {
    return 'Ainda cabem $amount';
  }

  @override
  String goalOverLimit(String amount) {
    return 'Estourou $amount';
  }

  @override
  String get partyEmptyTitle => 'Sua party ainda não tem desafios';

  @override
  String get partyEmptyMessage =>
      'Cada limite de gastos por categoria vira um desafio da party. Crie o primeiro e acompanhe aqui.';

  @override
  String get partyEmptyButton => 'Criar primeiro limite';

  @override
  String get partyErrorMessage =>
      'Não foi possível carregar o status da party.';

  @override
  String get badgeCatalogUnavailableTitle => 'Catálogo indisponível';

  @override
  String get badgeCatalogUnavailableMessage =>
      'Ainda não recebemos a lista de conquistas do servidor. Tente de novo em instantes.';

  @override
  String get badgeCategoryAdvanced => 'Conquistas Avançadas';

  @override
  String get badgeCategoryFirstSteps => 'Primeiros Passos';

  @override
  String get badgeCategoryConsistency => 'Registro Consistente';

  @override
  String get badgeCategorySavings => 'Gastos e Economias';

  @override
  String get badgeCategoryGoals => 'Metas';

  @override
  String get badgeCategoryTeam => 'Equipe e Consistência';

  @override
  String badgeCatalogTotal(int unlocked, int total) {
    return '$unlocked de $total';
  }

  @override
  String goalLimitBlownAt(String date) {
    return 'Limite estourado em $date';
  }

  @override
  String goalDeadlineMissedAt(String date) {
    return 'Prazo encerrado sem atingir em $date';
  }

  @override
  String get journeyClosedGoalsTitle => 'Metas encerradas';

  @override
  String get goalAwaitingOutcome => 'Aguardando apuração';

  @override
  String get invoiceCalculating => 'calculando…';

  @override
  String get invoiceCycleUnavailable =>
      'Estamos fechando esta fatura. As compras aparecem assim que o cálculo terminar.';

  @override
  String get journeyWeeklyXpEmpty => 'Sem XP ainda nesta semana';

  @override
  String get journeyMissionsSoonTitle => 'Suas missões estão a caminho';

  @override
  String get journeyMissionsSoonMessage =>
      'O Funances monta três missões novas no começo de cada semana.';

  @override
  String journeyMissionProgress(int progress, int target) {
    return '$progress de $target';
  }

  @override
  String get journeyMissionDone => 'Missão cumprida';

  @override
  String get journeyMissionConsistency => 'Consistência';

  @override
  String get journeyMissionDiscipline => 'Disciplina';

  @override
  String get journeyMissionOrganization => 'Organização';

  @override
  String get journeyMissionOther => 'Missão';

  @override
  String get journeyChecklistTitle => 'Checklist da semana';

  @override
  String get journeyAvailableTitle => 'Disponível até o fim do mês';

  @override
  String journeyAvailableSpent(String actual, String planned) {
    return 'Realizado $actual de $planned previstos';
  }

  @override
  String journeyAvailablePending(String pending) {
    return 'Ainda por pagar: $pending';
  }

  @override
  String get journeyAvailableNoIncome =>
      'Sem expectativa de receita não dá para dizer quanto sobra.';

  @override
  String get journeyAvailableNoIncomeAction =>
      'Defina sua expectativa de receita';

  @override
  String get journeyAvailableError =>
      'Não consegui calcular o disponível agora.';

  @override
  String get compassTitle => 'Bússola da Liberdade';

  @override
  String get compassCalibratingTitle => 'Sua bússola está sendo calibrada';

  @override
  String get compassCalibratingMessage =>
      'Assim que houver um mês fechado, seu índice aparece aqui.';

  @override
  String compassScoreOf(String score, String tier) {
    return '$score de 100 • $tier';
  }

  @override
  String get compassTierAprendiz => 'Aprendiz';

  @override
  String get compassTierGuardiao => 'Guardião';

  @override
  String get compassTierEstrategista => 'Estrategista';

  @override
  String get compassTierMestre => 'Mestre';

  @override
  String get compassTierLivre => 'Livre';

  @override
  String get compassTierUnknown => 'Em avaliação';

  @override
  String get compassFolego => 'Fôlego';

  @override
  String get compassFolegoDesc =>
      'Quanto tempo suas reservas seguram suas despesas se a renda parar.';

  @override
  String compassFolegoDetail(String months) {
    return '$months meses de despesas guardados';
  }

  @override
  String get compassPoupanca => 'Poupança';

  @override
  String get compassPoupancaDesc =>
      'Quanto da sua renda vira reserva ou investimento todo mês.';

  @override
  String compassPoupancaDetail(String rate) {
    return '$rate da renda guardada';
  }

  @override
  String get compassDisciplina => 'Disciplina';

  @override
  String get compassDisciplinaDesc =>
      'Quantas categorias terminaram o mês dentro do limite que você definiu.';

  @override
  String compassDisciplinaDetail(int within, int total) {
    return '$within de $total categorias dentro do limite';
  }

  @override
  String get compassAlivio => 'Alívio';

  @override
  String get compassAlivioDesc =>
      'Quanto suas dívidas diminuíram desde o mês passado.';

  @override
  String compassAlivioDetail(String delta) {
    return '$delta em dívidas no mês';
  }

  @override
  String get compassHistoryTitle => 'Últimos 6 meses';

  @override
  String get compassHistoryEmpty =>
      'Ainda não há meses fechados suficientes para comparar.';

  @override
  String get unplannedNudgeTitle => 'Esse gasto não estava no plano';

  @override
  String unplannedNudgeMessage(String category) {
    return '$category ainda não tem limite neste mês. Quer decidir agora o que fazer com ela?';
  }

  @override
  String get unplannedNudgeRecurring => 'Transformar em recorrência';

  @override
  String get unplannedNudgeRecurringDesc =>
      'Se acontece todo mês, o Funances passa a lançar sozinho.';

  @override
  String unplannedNudgeLimit(String category) {
    return 'Definir limite para $category';
  }

  @override
  String unplannedNudgeLimitDesc(String amount) {
    return 'Sugestão de $amount, pela sua média dos últimos meses.';
  }

  @override
  String get unplannedNudgeLimitDescNoHistory =>
      'Escolha quanto essa categoria pode custar por mês.';

  @override
  String get unplannedNudgeDismiss => 'Só desta vez';

  @override
  String get xpSourcesTitle => 'Como ganhar XP';

  @override
  String get journeyWeeklyXpCaption => 'XP ganho esta semana com lançamentos';

  @override
  String compassHistoryPoint(String month, String score) {
    return '$month: $score de 100';
  }

  @override
  String get writeFailedReasonPermission =>
      'você não tem permissão para essa mudança';

  @override
  String get writeFailedReasonNotFound => 'o item não existe mais';

  @override
  String get writeFailedReasonTimeout => 'o servidor não respondeu';

  @override
  String get writeFailedReasonUnknown => 'o servidor recusou a alteração';

  @override
  String get transactionSavePendingSync =>
      'Salvo neste dispositivo. As parcelas aparecem quando a conexão voltar.';

  @override
  String get uploadFolderNotSupported => 'Arraste um arquivo, não uma pasta.';

  @override
  String writeFailedEntity(String entity, String reason) {
    return 'Não foi possível salvar $entity: $reason';
  }

  @override
  String get writeEntityTransaction => 'o lançamento';

  @override
  String get writeEntityInstallment => 'a parcela';

  @override
  String get writeEntityPlanning => 'o planejamento';

  @override
  String get writeEntityAccount => 'a conta';

  @override
  String get writeEntityCategory => 'a categoria';

  @override
  String get writeEntityGoal => 'a meta';

  @override
  String get writeEntityInvite => 'o convite';

  @override
  String get writeEntityWorkspace => 'o workspace';

  @override
  String get writeEntityProfile => 'o perfil';

  @override
  String get writeEntityAutomaticTransaction => 'a transação automática';

  @override
  String get writeEntityReconciliation => 'a conciliação';

  @override
  String get savePendingSync =>
      'Salvo neste dispositivo. Sincroniza quando a conexão voltar.';

  @override
  String get accountSavePendingSync =>
      'Salva neste dispositivo. Saldo inicial e fatura aparecem quando a conexão voltar.';

  @override
  String get celebrationXpTitle => 'XP ganho';

  @override
  String get celebrationMissionTitle => 'Missão concluída';

  @override
  String get celebrationBadgeTitle => 'Conquista desbloqueada';

  @override
  String get celebrationBadgeFallback => 'Veja na vitrine';

  @override
  String celebrationLevelTitle(int level) {
    return 'Nível $level';
  }

  @override
  String get celebrationLevelSubtitle => 'O cofre subiu de nível';

  @override
  String get celebrationTierTitle => 'Nova patente';

  @override
  String get settingsAppearanceSection => 'Aparência';

  @override
  String get settingsThemeMode => 'Tema';

  @override
  String get settingsThemeModeDesc =>
      'Claro, escuro ou como o sistema estiver.';

  @override
  String get themeModeSystem => 'Sistema';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Escuro';

  @override
  String get settingsCelebrationSound => 'Som nas conquistas';

  @override
  String get settingsCelebrationSoundDesc =>
      'Desligado por padrão. A vibração continua.';

  @override
  String missionPersonalConsistencyPlanLimits(String target) {
    return 'Planejar limites para pelo menos $target categorias e organizar a semana.';
  }

  @override
  String missionPersonalDisciplineTopCategory(String category, String target) {
    return 'Manter a categoria $category dentro do orçamento planejado por $target dias.';
  }

  @override
  String missionPersonalOrganizationReconcileItems(String target) {
    return 'Fazer a conciliação completa de um extrato com pelo menos $target itens.';
  }

  @override
  String missionBusinessConsistencyCostCenters(String target) {
    return 'Planejar o limite de $target centros de custo para o mês.';
  }

  @override
  String missionBusinessConsistencyIncomeForecast(String target) {
    return 'Confirmar o recebimento de $target% da receita prevista para a semana.';
  }

  @override
  String missionBusinessDisciplineTopCostCenter(
    String category,
    String target,
  ) {
    return 'Manter o centro de custo $category dentro do plano por $target dias.';
  }

  @override
  String get missionBusinessDisciplineMargin =>
      'Fechar a semana com a margem (receita − despesa) acima da planejada.';

  @override
  String missionBusinessOrganizationReconcileStatements(String target) {
    return 'Conciliar $target extrato das contas da empresa nesta semana.';
  }

  @override
  String missionBusinessOrganizationCategorizeAuto(String target) {
    return 'Categorizar ou descartar $target lançamentos automáticos antes do fechamento.';
  }

  @override
  String missionBusinessOrganizationInvoiceOnTime(String target) {
    return 'Fechar $target fatura do cartão corporativo pagando até o vencimento.';
  }

  @override
  String get missionFallbackCategoryPersonal => 'de maior gasto';

  @override
  String get missionFallbackCategoryBusiness => 'de maior peso';

  @override
  String get missionCtaPlanning => 'Planejar agora';

  @override
  String get missionCtaPlanning503020 => 'Abrir o 50-30-20';

  @override
  String get missionCtaCategories => 'Ver a Party';

  @override
  String get missionCtaAccounts => 'Ver contas';

  @override
  String get missionCtaCategoryDetails => 'Ver categoria';

  @override
  String get missionCtaTransactionForm => 'Lançar agora';

  @override
  String get workspaceTypePersonalBadge => 'Pessoal';

  @override
  String get workspaceTypeBusinessBadge => 'Empresa';

  @override
  String levelBadgeShort(int level) {
    return 'Nv $level';
  }

  @override
  String levelBadgeSemantics(int level, int percent) {
    return 'Nível $level do cofre, $percent% para o próximo';
  }

  @override
  String get compassStripTitle => 'Bússola';

  @override
  String get compassStripOpen => 'Ver a Bússola completa';

  @override
  String compassStripDelta(String points) {
    return '$points desde o mês passado';
  }
}
