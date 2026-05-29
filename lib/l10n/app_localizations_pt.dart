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
  String get errorUnknown => 'Ocorreu um erro inesperado.';

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
  String get onboardingGoalsAnalysisTitle => 'TRAÇAR METAS';

  @override
  String get onboardingGoalsAnalysisDesc =>
      'Com base no seu perfil, nossa IA sugere algumas metas para você.';

  @override
  String get onboardingMembersListTitle => 'Lista de convites';

  @override
  String get onboardingMembersEmpty => 'Nenhum e-mail adicionado';

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
  String get goalMonthlyRequirementLabel => 'Valor por mês';

  @override
  String goalMonthlyRequirementValue(String amount) {
    return '$amount/mês';
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
  String get historyFilterAllAccounts => 'Todas as Contas';

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
  String get deleteButton => 'Excluir';

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
  String get transactionPlanExpense => 'Planejar Despesa';

  @override
  String get transactionPlanIncome => 'Planejar Receita';

  @override
  String get transactionActionTransfer => 'Transferência';

  @override
  String get transactionPlannedSection => 'Lançamentos Planejados';

  @override
  String get transactionCategoriesSection => 'Categorias';

  @override
  String get transactionDescriptionLabel => 'Descrição';

  @override
  String get transactionAmountLabel => 'Valor';

  @override
  String get transactionDateLabel => 'Data';

  @override
  String get transactionAccountLabel => 'Conta';

  @override
  String get transactionInstallmentsLabel => 'Parcelas';

  @override
  String get transactionTypeExpense => 'Despesa';

  @override
  String get transactionTypeIncome => 'Receita';

  @override
  String get transactionTypeTransfer => 'Transferência';

  @override
  String get transactionFromAccountLabel => 'Conta de Origem';

  @override
  String get transactionToAccountLabel => 'Conta de Destino';

  @override
  String get transactionSaveSuccess => 'Transação salva com sucesso!';

  @override
  String get noAccountsFound => 'Nenhuma conta encontrada.';

  @override
  String get initialBalanceLabel => 'Saldo Inicial';

  @override
  String get initialBalanceDateLabel => 'Data do Saldo Inicial';

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
  String get overviewPlanning => 'Planejamento';

  @override
  String get overviewEffective => 'Efetivo';

  @override
  String get overviewComparison => 'Comparação';

  @override
  String get transactionTransfer => 'Transferência';

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
}
