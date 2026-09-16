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
  String get loginTitle => 'FUNANCE';

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
  String get shortPassword => 'A senha deve ter pelo menos 6 caracteres';

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
  String get badgeUnlockedToast => 'Nova conquista desbloqueada!';

  @override
  String get badgeUnlockedView => 'Ver';

  @override
  String get workspacePickerTitle => 'Workspaces';

  @override
  String get transactionMoreOptions => 'Mais Opções';

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
  String get onboardingWelcomeTitle => 'Boas-vindas ao Funances!';

  @override
  String get onboardingWelcomeDesc =>
      'O app que transforma sua gestão financeira em uma jornada de conquistas.';

  @override
  String get onboardingNext => 'Próximo';

  @override
  String get onboardingBack => 'Voltar';

  @override
  String get onboardingStart => 'Começar Jornada';

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
  String get onboardingWorkspaceCreateError => 'Erro ao criar workspace.';

  @override
  String get onboardingGoalsTitle => 'Trace suas primeiras metas';

  @override
  String get onboardingGoalsDesc =>
      'Economizar para uma viagem? Comprar um carro? Vamos configurar isso em breve.';

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
  String get onboardingAccountsManual => 'Cadastro manual';

  @override
  String onboardingAccountsAttachment(String fileName) {
    return 'Anexo: $fileName';
  }

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
  String get onboardingStepConceptsTitle => 'Entenda os Conceitos';

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
  String goalRemainingMonthly(String amount) {
    return '$amount/mês';
  }

  @override
  String goalTargetTarget(String amount) {
    return 'Alvo: $amount';
  }

  @override
  String get goalRemainingMonthlyDesc => 'Valor por mês';

  @override
  String goalRemainingMonthlyTarget(String amount, String date) {
    return '$amount/mês até $date';
  }

  @override
  String get goalDetailsTitle => 'Detalhes da Meta';

  @override
  String get goalTransactionsTitle => 'Transações Relacionadas';

  @override
  String get goalEditButton => 'Editar Meta';

  @override
  String get goalDeleteButton => 'Excluir Meta';

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
  String get goalMilestone25 => '25%';

  @override
  String get goalMilestone50 => '50%';

  @override
  String get goalMilestone75 => '75%';

  @override
  String get goalMilestone100 => '100%';

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
  String get goalMonthlyRequirementLabel => 'Valor por mês';

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
  String get profileSaveButton => 'Salvar Alterações';

  @override
  String get profileUpdateSuccess => 'Perfil atualizado com sucesso!';

  @override
  String get profileUpdateError => 'Erro ao atualizar perfil.';

  @override
  String get profilePhotoSourceTitle => 'Escolha a origem da foto';

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
  String planning503020Ideal(String amount) {
    return 'Meta: $amount';
  }

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
  String get planning503020Goal => 'Meta';

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
  String get planning503020Save => 'SALVAR';

  @override
  String get planning503020EmptyPool => 'Arraste categorias para cá';

  @override
  String get automaticTransactionFindExisting => 'Buscar Existente';

  @override
  String get automaticTransactionEmpty =>
      'Nenhum novo lançamento identificado.';

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
  String automaticTransactionSuggestedCategory(Object category) {
    return 'Categoria sugerida: $category';
  }

  @override
  String automaticTransactionSuggestedAccount(Object account) {
    return 'Conta sugerida: $account';
  }

  @override
  String goalRemainingValue(String amount) {
    return 'Faltam $amount';
  }

  @override
  String goalProgressValue(String percent) {
    return '$percent%';
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
  String get goalCurrentAmountLabel => 'Valor Atual';

  @override
  String get goalStartDateLabel => 'Data de Início';

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
  String get goalCreditCardLabel => 'Cartão de Crédito';

  @override
  String get goalAverageSpendingLabel => 'Média de Gastos Mensal';

  @override
  String get errorGoalNotFound => 'Meta não encontrada.';

  @override
  String get errorGoalTypeCannotBeChanged =>
      'O tipo da meta não pode ser alterado.';

  @override
  String get statusOnTrack => 'Em dia';

  @override
  String get statusAtRisk => 'Alerta';

  @override
  String get statusBehind => 'Atrasada';

  @override
  String get statusLost => 'Perdida';

  @override
  String goalProgressPercent(Object percent) {
    return '$percent% concluído';
  }

  @override
  String goalRemainingAmount(Object amount) {
    return 'Faltam $amount';
  }

  @override
  String get continueButton => 'CONTINUAR';

  @override
  String get invitesTitle => 'Convites Pendentes';

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
  String get membersRemoveError => 'Não foi possível remover o membro.';

  @override
  String membersInviteSentAt(String date) {
    return 'Convidado em $date';
  }

  @override
  String get membersResendAction => 'Reenviar';

  @override
  String get membersResendSuccess => 'Convite renovado.';

  @override
  String get membersResendError => 'Não foi possível renovar o convite.';

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
  String get membersCancelInviteError => 'Não foi possível cancelar o convite.';

  @override
  String get membersOnlyOwnerCanRemove =>
      'Apenas o dono do workspace pode remover membros.';

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
  String get homeMissionsTab => 'Missões';

  @override
  String get homeHistoryTab => 'Extrato';

  @override
  String homeTotalSavedMonth(Object amount) {
    return 'Você economizou $amount a mais que o planejado!';
  }

  @override
  String homePointsEarned(Object points) {
    return '+$points Pontos';
  }

  @override
  String homeRemainingAmount(Object amount, Object percent) {
    return 'Faltam $amount ($percent% concluído)';
  }

  @override
  String get homeAccountsAndCards => 'Saldos e Faturas';

  @override
  String get weeklyMissions => 'Missões da Semana';

  @override
  String get weeklyMissionsSuccess => 'Semana de Sucesso!';

  @override
  String get weeklyMissionsNone => 'Nenhuma missão para esta semana';

  @override
  String get weeklyMissionsSuccessDesc =>
      'Você cumpriu todas as suas metas. Parabéns!';

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
  String get weeklyGoal => 'Meta da Semana';

  @override
  String xpValue(String xp) {
    return '$xp XP';
  }

  @override
  String xpProgress(String current, String total) {
    return '$current / $total XP';
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
  String get remainingWeeklyPlanning => 'Disponível na semana';

  @override
  String spentOfWeeklyPlanning(String spent, String limit) {
    return '$spent de $limit';
  }

  @override
  String get hpLabel => 'HP';

  @override
  String overBudgetAmount(String amount) {
    return 'Excesso: $amount';
  }

  @override
  String get homeWhereIsMoney => 'Onde está o dinheiro?';

  @override
  String get homeTotalSpent => 'Total Gasto';

  @override
  String get homeTotalBalance => 'Saldo Total';

  @override
  String get accountCreateAction => 'Cadastrar Nova Conta';

  @override
  String accountCreateTypeAction(String type) {
    return 'Cadastrar Nova Conta de $type';
  }

  @override
  String get homeAllAccounts => 'Todas as Contas';

  @override
  String get homeThisMonth => 'Este Mês';

  @override
  String get homeLastMonth => 'Mês Passado';

  @override
  String get homeCustomPeriod => 'Customizado';

  @override
  String get homeNewTransaction => 'Novo Lançamento';

  @override
  String get homeConsolidate => 'Consolidar';

  @override
  String get noTransactionsInPeriod =>
      'Nenhuma transação encontrada para este período';

  @override
  String get historyFilterPeriod => 'Selecionar Período';

  @override
  String get historyFilterAccountLabel => 'Conta';

  @override
  String get historyFilterAllAccounts => 'Todas as Contas';

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
  String get historyFilterAmountRangeLabel => 'Faixa de Valor';

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
  String get categoryTypeBoth => 'Ambos';

  @override
  String get categoryDeleteTitle => 'Excluir Categoria';

  @override
  String categoryDeleteConfirm(String name) {
    return 'Deseja realmente excluir a categoria \"$name\"?';
  }

  @override
  String get categoryOthers => 'Outros';

  @override
  String get saveButton => 'Salvar';

  @override
  String get reconciliationTitle => 'Conciliação Bancária';

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
  String get reconciliationActionAnalyze => 'Analisar Extrato';

  @override
  String get reconciliationSystemLabel => 'SISTEMA';

  @override
  String get reconciliationExtratoLabel => 'EXTRATO';

  @override
  String get reconciliationNoMatchFound =>
      'Nenhuma transação correlata encontrada';

  @override
  String get reconciliationSectionTitle => 'Conciliação';

  @override
  String get reconciliationSectionDesc =>
      'Compare seus registros com o extrato bancário real.';

  @override
  String get reconciliationChangeAccount => 'Alterar';

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
  String get addAccountButton => 'Adicionar Conta';

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
  String get transactionDeleteCascadeOnlyThis => 'Apenas esta';

  @override
  String get transactionDeleteCascadeThisAndNext => 'Esta e próximas';

  @override
  String get transactionDeleteCascadeAll => 'Todas';

  @override
  String get transactionDueDateLabel => 'Vencimento';

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
  String get accountBankLogoLabel => 'Logo do Banco/Bandeira';

  @override
  String get accountOwnerIdsLabel => 'Titulares';

  @override
  String get customLabel => 'Personalizado';

  @override
  String get accountNextInvoiceValueLabel => 'Valor da próxima fatura';

  @override
  String get accountInitialInvestmentValueLabel =>
      'Saldo inicial do investimento';

  @override
  String get accountInitialDebtValueLabel => 'Valor da dívida';

  @override
  String get accountInitialInvestmentDateLabel =>
      'Data inicial do investimento';

  @override
  String get accountInitialDebtDateLabel => 'Data da dívida';

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
  String accountDetectedPlannings(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count planejamentos sugeridos',
      one: '1 planejamento sugerido',
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
  String get accountAnalysisFailed => 'Falha no processamento ';

  @override
  String get onboardingPlanningAnalyzingTitle => 'Analisando padrões...';

  @override
  String get onboardingPlanningAnalyzingDesc =>
      'Nossa IA está analisando seus padrões de gastos para sugerir metas e planejamentos ideais para você.';

  @override
  String get accountViewTransactions => 'Ver Transações';

  @override
  String get accountViewPlannings => 'Ver Planejamentos';

  @override
  String get accountDetectedTransactionsTitle => 'Transações Detectadas';

  @override
  String get accountDetectedPlanningsTitle => 'Planejamentos Sugeridos';

  @override
  String get historyEdit => 'Editar';

  @override
  String get historyDelete => 'Excluir';

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
  String get transactionSelectSourceAccount => 'Selecionar Conta de Origem';

  @override
  String get transactionSelectDestinationAccount =>
      'Selecione a Conta de Destino';

  @override
  String get transactionAddExpenseDesc =>
      'Registre uma despesa pontual que ocorreu hoje ou no passado.';

  @override
  String get transactionAddIncomeDesc =>
      'Registre uma receita pontual que ocorreu hoje ou no passado.';

  @override
  String get transactionPlanExpenseDesc =>
      'Agende uma despesa futura, recorrente ou parcelada.';

  @override
  String get transactionPlanIncomeDesc =>
      'Agende uma receita futura, recorrente ou parcelada.';

  @override
  String get transactionTransferDesc =>
      'Movimente saldo entre suas contas bancárias ou cartões.';

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
  String get periodFilterTitle => 'Selecionar Período';

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
  String get registerEffectivation => 'Marcar como realizado';

  @override
  String get returnToPending => 'Retornar para Pendente';

  @override
  String get partyHpLabel => 'Saúde da Equipe';

  @override
  String get partyStatusHealthy => 'Equipe em Segurança';

  @override
  String get partyStatusStrained => 'Equipe em Perigo';

  @override
  String get partyStatusDefeated => 'Equipe Derrotada';

  @override
  String get partyTeamTitle => 'Equipe';

  @override
  String get planned => 'Planejado';

  @override
  String get actual => 'Realizado';

  @override
  String get excess => 'Excesso';

  @override
  String get invoiceDetailTitle => 'Detalhe de Fatura';

  @override
  String get registerInvoicePayment => 'Registrar Pagamento de Fatura';

  @override
  String get coachingTitle => 'Coach Financeiro';

  @override
  String get coachingConsultAction => 'Consultar Coach';

  @override
  String get coachingViewLast => 'Ver última análise';

  @override
  String coachingLastAnalysisFrom(String date) {
    return 'Última análise de $date';
  }

  @override
  String coachingWaitSevenDays(int days) {
    return 'Você poderá consultar o coach novamente em $days dias.';
  }

  @override
  String get coachingWaitLessOneDay =>
      'Você poderá consultar o coach novamente amanhã.';

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
  String get currentBalance => 'Saldo Atual';

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
  String get accountOwnerLabel => 'Titularidade';

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
  String get yourBadgesLabel => 'Suas Insígnias';

  @override
  String get advancedBadgesLabel => 'Conquistas Avançadas';

  @override
  String get simpleBadgesLabel => 'Conquistas Simples';

  @override
  String get badgeUnlockedLabel => 'Desbloqueado';

  @override
  String get badgeLockedLabel => 'Bloqueado';

  @override
  String get badgeRewardLabel => 'Recompensa';

  @override
  String get badgeUnlockedAtLabel => 'Conquistado em';

  @override
  String get viewAchievementsButton => 'Ver Conquistas';

  @override
  String get badge_first_step_name => 'Primeiro Passo';

  @override
  String get badge_first_step_desc =>
      'O workspace é criado e o onboarding é concluído com sucesso.';

  @override
  String get badge_first_account_name => 'Primeira Conta';

  @override
  String get badge_first_account_desc =>
      'A primeira conta bancária ou cartão é cadastrado no workspace.';

  @override
  String get badge_first_transaction_name => 'Ponto de Partida';

  @override
  String get badge_first_transaction_desc =>
      'A primeira transação real (installment) é registrada com status paid.';

  @override
  String get badge_planner_name => 'Planejador Estrategista';

  @override
  String get badge_planner_desc =>
      'Limites de planejamento são criados para pelo menos 5 categorias.';

  @override
  String get badge_reconcile_junior_name => 'Conciliador Júnior';

  @override
  String get badge_reconcile_junior_desc =>
      'A primeira conciliação bancária bem-sucedida é concluída (pelo menos 1 match confirmado).';

  @override
  String get badge_cash_detective_name => 'Detetive de Caixa';

  @override
  String get badge_cash_detective_desc =>
      'Conciliação completa de um arquivo de extrato contendo pelo menos 10 transações.';

  @override
  String get badge_reconcile_master_name => 'Mestre da Conciliação';

  @override
  String get badge_reconcile_master_desc =>
      'O workspace acumula 10 conciliações de extratos concluídas com sucesso.';

  @override
  String get badge_zero_friction_name => 'Atrito Zero';

  @override
  String get badge_zero_friction_desc =>
      'Conciliar um extrato mensal inteiro sem necessitar criar lançamentos manuais extras.';

  @override
  String get badge_savings_seed_name => 'Semente de Poupança';

  @override
  String get badge_savings_seed_desc =>
      'A primeira meta (goal) cadastrada no workspace atinge 100% de progresso.';

  @override
  String get badge_goal_bronze_name => 'Colecionador de Metas';

  @override
  String get badge_goal_bronze_desc =>
      'O workspace conclui com sucesso 3 metas financeiras diferentes.';

  @override
  String get badge_goal_silver_name => 'Foco Inabalável';

  @override
  String get badge_goal_silver_desc =>
      'O workspace conclui com sucesso 5 metas financeiras diferentes.';

  @override
  String get badge_under_control_name => 'Tudo Sob Controle';

  @override
  String get badge_under_control_desc =>
      'Fechar o mês sem estourar nenhuma categoria planejada na regra 50-30-20.';

  @override
  String get badge_golden_rule_name => 'Regra de Ouro';

  @override
  String get badge_golden_rule_desc =>
      'Alocar limites em todos os 3 pools (Essencial, Conforto, Investimento) no mesmo mês.';

  @override
  String get badge_future_focus_name => 'Visão de Futuro';

  @override
  String get badge_future_focus_desc =>
      'Poupar e investir efetivamente pelo menos 20% das receitas totais do workspace no mês.';

  @override
  String get badge_cost_cutter_name => 'Tesoura de Gastos';

  @override
  String get badge_cost_cutter_desc =>
      'Reduzir os gastos totais do pool de Conforto (supérfluos) em 20% em relação ao mês anterior.';

  @override
  String get badge_united_front_name => 'Equipe Unida';

  @override
  String get badge_united_front_desc =>
      'Workspace com 3 ou mais membros ativos adicionados e aceitos.';

  @override
  String get badge_iron_consistency_name => 'Consistência de Aço';

  @override
  String get badge_iron_consistency_desc =>
      'Concluir com sucesso as missões semanais por 4 semanas consecutivas.';

  @override
  String levelIndicatorSemantics(int level, int count) {
    return 'Nível do Workspace: $level, Badges desbloqueados: $count';
  }

  @override
  String get levelUpTitle => 'LEVEL UP!';

  @override
  String get levelUpSubtitle => 'Parabéns para a equipe!';

  @override
  String levelUpContent(int level) {
    return 'Seu workspace subiu para o Nível $level!';
  }

  @override
  String get levelUpMessage =>
      'Continuem cooperando e planejando juntos para desbloquear novas conquistas e níveis!';

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
  String get badge_first_category_name => 'Organizador';

  @override
  String get badge_first_category_desc =>
      'Criar a primeira categoria personalizada no workspace.';

  @override
  String get badge_first_planning_name => 'Planejador Novato';

  @override
  String get badge_first_planning_desc =>
      'Criar o primeiro planejamento de categoria com valor definido.';

  @override
  String get badge_first_goal_name => 'Sonhador';

  @override
  String get badge_first_goal_desc =>
      'Criar a primeira meta financeira no workspace.';

  @override
  String get badge_first_invite_name => 'Anfitrião';

  @override
  String get badge_first_invite_desc =>
      'Convidar o primeiro membro para o workspace.';

  @override
  String get badge_profile_complete_name => 'Perfil Completo';

  @override
  String get badge_profile_complete_desc => 'Definir nome e tipo do workspace.';

  @override
  String get badge_first_income_name => 'Receita Registrada';

  @override
  String get badge_first_income_desc =>
      'Registrar a primeira receita paga no workspace.';

  @override
  String get badge_first_expense_name => 'Gasto Registrado';

  @override
  String get badge_first_expense_desc =>
      'Registrar o primeiro gasto pago no workspace.';

  @override
  String get badge_first_transfer_name => 'Transferidor';

  @override
  String get badge_first_transfer_desc =>
      'Registrar a primeira transferência entre contas.';

  @override
  String get badge_workspace_named_name => 'Identidade Própria';

  @override
  String get badge_workspace_named_desc =>
      'Dar um nome personalizado ao workspace.';

  @override
  String get badge_first_month_name => 'Primeiro Mês';

  @override
  String get badge_first_month_desc =>
      'Ter pelo menos uma transação registrada em um mês completo.';

  @override
  String get badge_five_transactions_name => 'Ativo!';

  @override
  String get badge_five_transactions_desc =>
      'Registrar 5 transações pagas no total.';

  @override
  String get badge_twenty_transactions_name => 'Comprometido';

  @override
  String get badge_twenty_transactions_desc =>
      'Registrar 20 transações pagas no total.';

  @override
  String get badge_fifty_transactions_name => 'Veterano';

  @override
  String get badge_fifty_transactions_desc =>
      'Registrar 50 transações pagas no total.';

  @override
  String get badge_hundred_transactions_name => 'Centenário';

  @override
  String get badge_hundred_transactions_desc =>
      'Registrar 100 transações pagas no total.';

  @override
  String get badge_week_complete_name => 'Semana Completa';

  @override
  String get badge_week_complete_desc =>
      'Registrar ao menos uma transação em 7 dias consecutivos.';

  @override
  String get badge_two_accounts_name => 'Multi-Conta';

  @override
  String get badge_two_accounts_desc => 'Cadastrar 2 contas no workspace.';

  @override
  String get badge_three_accounts_name => 'Gerenciador';

  @override
  String get badge_three_accounts_desc => 'Cadastrar 3 contas no workspace.';

  @override
  String get badge_five_accounts_name => 'Portfólio';

  @override
  String get badge_five_accounts_desc => 'Cadastrar 5 contas no workspace.';

  @override
  String get badge_five_categories_name => 'Categorizado';

  @override
  String get badge_five_categories_desc => 'Criar ao menos 5 categorias.';

  @override
  String get badge_ten_categories_name => 'Mestre Categorizador';

  @override
  String get badge_ten_categories_desc => 'Criar ao menos 10 categorias.';

  @override
  String get badge_round_number_name => 'Número Redondo';

  @override
  String get badge_round_number_desc =>
      'Registrar uma transação de valor exato sem centavos.';

  @override
  String get badge_big_transaction_name => 'Grande Negócio';

  @override
  String get badge_big_transaction_desc =>
      'Registrar uma transação individual acima de R\$ 1.000.';

  @override
  String get badge_small_transactions_ten_name => 'Detalhe Minucioso';

  @override
  String get badge_small_transactions_ten_desc =>
      'Registrar 10 transações de valor inferior a R\$ 10.';

  @override
  String get badge_income_registered_name => 'Bem Documentado';

  @override
  String get badge_income_registered_desc =>
      'Registrar ao menos uma receita no workspace.';

  @override
  String get badge_expense_under_income_name => 'Saldo Positivo';

  @override
  String get badge_expense_under_income_desc =>
      'Fechar o mês com despesas menores que as receitas.';

  @override
  String get badge_three_categories_month_name => 'Diversificado';

  @override
  String get badge_three_categories_month_desc =>
      'Ter gastos em 3 categorias diferentes no mesmo mês.';

  @override
  String get badge_five_categories_month_name => 'Abrangente';

  @override
  String get badge_five_categories_month_desc =>
      'Ter gastos em 5 categorias diferentes no mesmo mês.';

  @override
  String get badge_savings_10pct_name => 'Poupador Iniciante';

  @override
  String get badge_savings_10pct_desc =>
      'Poupar ao menos 10% da receita total no mês.';

  @override
  String get badge_savings_start_name => 'Primeiro Centavo';

  @override
  String get badge_savings_start_desc =>
      'Fazer o primeiro depósito em qualquer meta financeira.';

  @override
  String get badge_no_credit_debt_name => 'Livre de Juros';

  @override
  String get badge_no_credit_debt_desc =>
      'Fechar o mês sem nenhuma fatura de crédito em aberto.';

  @override
  String get badge_goal_halfway_name => 'Na Metade do Caminho';

  @override
  String get badge_goal_halfway_desc =>
      'Uma meta financeira atingir 50% do valor alvo.';

  @override
  String get badge_goal_75pct_name => 'Quase Lá';

  @override
  String get badge_goal_75pct_desc =>
      'Uma meta financeira atingir 75% do valor alvo.';

  @override
  String get badge_goal_under_deadline_name => 'No Prazo';

  @override
  String get badge_goal_under_deadline_desc =>
      'Concluir uma meta antes da data limite estabelecida.';

  @override
  String get badge_two_active_goals_name => 'Ambicioso';

  @override
  String get badge_two_active_goals_desc =>
      'Ter 2 metas ativas ao mesmo tempo.';

  @override
  String get badge_five_active_goals_name => 'Multitarefas';

  @override
  String get badge_five_active_goals_desc =>
      'Ter 5 metas ativas ao mesmo tempo.';

  @override
  String get badge_long_term_goal_name => 'Visão de Longo Prazo';

  @override
  String get badge_long_term_goal_desc =>
      'Criar uma meta com prazo superior a 12 meses.';

  @override
  String get badge_short_term_goal_name => 'Sprint Financeiro';

  @override
  String get badge_short_term_goal_desc =>
      'Concluir uma meta em menos de 30 dias.';

  @override
  String get badge_goal_deposit_name => 'Primeiro Depósito';

  @override
  String get badge_goal_deposit_desc =>
      'Fazer o primeiro depósito em uma meta financeira.';

  @override
  String get badge_goal_debt_paid_name => 'Livre de Dívidas';

  @override
  String get badge_goal_debt_paid_desc =>
      'Concluir uma meta do tipo \'Quitar Dívida\'.';

  @override
  String get badge_goal_linked_account_name => 'Meta Vinculada';

  @override
  String get badge_goal_linked_account_desc =>
      'Criar uma meta associada a uma conta bancária.';

  @override
  String get badge_second_member_name => 'Dupla!';

  @override
  String get badge_second_member_desc =>
      'Um segundo membro aceitar o convite para o workspace.';

  @override
  String get badge_reconcile_second_name => 'Conciliador Frequente';

  @override
  String get badge_reconcile_second_desc =>
      'Concluir a segunda conciliação bancária.';

  @override
  String get badge_reconcile_five_name => 'Conciliador Hábil';

  @override
  String get badge_reconcile_five_desc =>
      'Concluir 5 conciliações bancárias ao total.';

  @override
  String get badge_mission_first_name => 'Primeira Missão';

  @override
  String get badge_mission_first_desc => 'Completar a primeira missão semanal.';

  @override
  String get badge_mission_three_name => 'Triatleta Financeiro';

  @override
  String get badge_mission_three_desc =>
      'Completar 3 missões semanais ao total.';

  @override
  String get badge_planning_month_name => 'Planejamento do Mês';

  @override
  String get badge_planning_month_desc =>
      'Criar planejamento para ao menos 5 categorias no mês.';

  @override
  String get badge_two_months_active_name => 'Constante';

  @override
  String get badge_two_months_active_desc =>
      'Registrar transações em 2 meses diferentes.';

  @override
  String get badge_workspace_one_year_name => 'Aniversário!';

  @override
  String get badge_workspace_one_year_desc =>
      'O workspace completa 1 ano de existência.';

  @override
  String get badge_invite_accepted_name => 'Bem-vindo ao Time';

  @override
  String get badge_invite_accepted_desc =>
      'Aceitar o convite para entrar em um workspace.';

  @override
  String get badge_all_missions_week_name => 'Semana Perfeita';

  @override
  String get badge_all_missions_week_desc =>
      'Completar todas as missões semanais disponíveis em uma semana.';

  @override
  String get goalDebtTotalLabel => 'Valor Total da Dívida';

  @override
  String get goalDebtTotalHint => 'Quanto você deve no total?';

  @override
  String get goalDebtPaidLabel => 'Valor Já Pago';

  @override
  String get goalDebtPaidHint => 'Quanto você já amortizou?';

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
}
