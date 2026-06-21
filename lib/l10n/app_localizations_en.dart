// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Funances';

  @override
  String get loginTitle => 'FUNANCE';

  @override
  String get loginSubtitle => 'Your journey to financial freedom starts here.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get editButton => 'Edit';

  @override
  String get deleteButton => 'Delete';

  @override
  String get displayNameLabel => 'Full Name';

  @override
  String get loginButton => 'Login';

  @override
  String get registerButton => 'Create Account';

  @override
  String get registerLink => 'Don\'t have an account? Sign up';

  @override
  String get loginLink => 'Already have an account? Login';

  @override
  String get googleLoginButton => 'Sign in with Google';

  @override
  String get orDivider => 'OR';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get shortPassword => 'Password must be at least 6 characters';

  @override
  String get errorUnknown => 'An unexpected error occurred.';

  @override
  String get errorKeychain =>
      'Your session could not be saved. You can use the app, but you will need to log in again upon reopening.';

  @override
  String get errorUserNotFound => 'User not found.';

  @override
  String get errorWrongPassword => 'Wrong password.';

  @override
  String get errorEmailAlreadyInUse =>
      'This email is already in use by another account.';

  @override
  String get errorWeakPassword => 'The provided password is too weak.';

  @override
  String get errorInvalidEmail => 'The email address is not valid.';

  @override
  String get errorNetworkRequestFailed => 'Internet connection failure.';

  @override
  String get errorGoogleSignInConfig =>
      'Google Sign-In configuration error. Please verify if the SHA-1 key has been added to the Firebase Console.';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Funances!';

  @override
  String get onboardingWelcomeDesc =>
      'The app that transforms your financial management into a journey of achievements.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingStart => 'Start Journey';

  @override
  String get onboardingPersonalTitle => 'Personal Workspace';

  @override
  String get onboardingPersonalDesc =>
      'Ideal for your individual accounts, daily expenses, and personal goals.';

  @override
  String get onboardingBusinessTitle => 'Business Workspace';

  @override
  String get onboardingBusinessDesc =>
      'Manage your company\'s or side project\'s cash flow professionally.';

  @override
  String get onboardingWorkspaceNameTitle => 'Name your Workspace';

  @override
  String get onboardingWorkspaceNamePersonalHint =>
      'Ex: My Finances, Silva Family...';

  @override
  String get onboardingWorkspaceNameBusinessHint =>
      'Ex: My Company, Freelance...';

  @override
  String get onboardingWorkspaceNameLabel => 'Workspace Name';

  @override
  String get onboardingWorkspaceCreateError => 'Error creating workspace.';

  @override
  String get onboardingGoalsTitle => 'Set your first goals';

  @override
  String get onboardingGoalsDesc =>
      'Save for a trip? Buy a car? Let\'s set that up soon.';

  @override
  String get onboardingGoalsButton => 'GOT IT, NEXT STEP';

  @override
  String get onboardingMembersTitle => 'Invite members';

  @override
  String get onboardingMembersDesc =>
      'You can share your workspace with partners or family members to manage finances together.';

  @override
  String get onboardingFinish => 'FINISH ONBOARDING';

  @override
  String get onboardingAccountsTitle => 'DEFINE ACCOUNTS';

  @override
  String get onboardingAccountsDesc =>
      'Register your bank accounts or credit cards. You can attach statements (PDF/OFX) to automate the process.';

  @override
  String get onboardingAccountsEmpty => 'No accounts added';

  @override
  String get onboardingAccountsAdd => 'ADD ACCOUNT';

  @override
  String get onboardingAccountsAddAnother => 'ADD ANOTHER ACCOUNT';

  @override
  String get onboardingAccountsManual => 'Manual registration';

  @override
  String onboardingAccountsAttachment(String fileName) {
    return 'Attachment: $fileName';
  }

  @override
  String get onboardingGoalsAnalysisTitle => 'AI SUGGESTIONS';

  @override
  String get onboardingGoalsAnalysisDesc =>
      'Based on your profile and accounts, our AI suggests some goals and plannings for you.';

  @override
  String get onboardingSuggestedGoalsTitle => 'Suggested Goals';

  @override
  String get onboardingSuggestedPlanningsTitle => 'Suggested Plannings';

  @override
  String get onboardingMembersListTitle => 'Invite list';

  @override
  String get onboardingMembersEmpty => 'No email added';

  @override
  String get onboardingSuccessTitle => 'All set!';

  @override
  String get onboardingSuccessDesc =>
      'Your workspace has been successfully configured. Now you can start organizing your financial life.';

  @override
  String get onboardingSuccessCTA => 'GO TO MAIN SCREEN';

  @override
  String get onboardingStepConceptsTitle => 'Understand the Concepts';

  @override
  String get onboardingStepConceptsDesc =>
      'To get the most out of Funances, let\'s understand how we organize information.';

  @override
  String get onboardingConceptLimitsTitle => 'Limits and Expectations';

  @override
  String get onboardingConceptLimitsDesc =>
      'Define how much you expect to earn and the maximum you want to spend per category. This is your financial ceiling.';

  @override
  String get onboardingConceptPlanningTitle => 'Planning';

  @override
  String get onboardingConceptPlanningDesc =>
      'Works as a scheduled transaction: counts towards the category ceiling but doesn\'t affect the account balance until cleared. Ideal for recurring or installment payments.';

  @override
  String get onboardingConceptFeaturesTitle => 'Features and Where to Find';

  @override
  String get onboardingConceptFeaturesDesc =>
      'Explore the Dashboard for an overview, Statements for reconciliation, and Goals to track your dreams.';

  @override
  String get onboardingConceptTransactionsTitle => 'Transactions';

  @override
  String get onboardingConceptTransactionsDesc =>
      'The day-to-day! Record your actual income and expenses to track your progress against the plan.';

  @override
  String goalRemainingMonthly(String amount) {
    return '$amount/mo';
  }

  @override
  String goalTargetTarget(String amount) {
    return 'Target: $amount';
  }

  @override
  String get goalRemainingMonthlyDesc => 'Monthly value';

  @override
  String goalRemainingMonthlyTarget(String amount, String date) {
    return '$amount/mo until $date';
  }

  @override
  String get goalDetailsTitle => 'Goal Details';

  @override
  String get goalTransactionsTitle => 'Transações Relacionadas';

  @override
  String get goalEditButton => 'Editar Meta';

  @override
  String get goalDeleteButton => 'Excluir Meta';

  @override
  String get goalDeleteConfirmTitle => 'Delete Goal?';

  @override
  String get goalDeleteConfirmMessage =>
      'Are you sure you want to delete this goal? This action cannot be undone.';

  @override
  String get goalStatusOnTrack => 'No Caminho';

  @override
  String get goalStatusAtRisk => 'Em Risco';

  @override
  String get goalStatusBehind => 'Atrasada';

  @override
  String get goalStatusLost => 'Perdida';

  @override
  String get goalProgressChartTitle => 'Progress';

  @override
  String get goalChartIdealLine => 'Ideal';

  @override
  String get goalChartRealLine => 'Actual';

  @override
  String get goalChartStartLabel => 'Start';

  @override
  String get goalChartEndLabel => 'Deadline';

  @override
  String get goalMilestone25 => '25%';

  @override
  String get goalMilestone50 => '50%';

  @override
  String get goalMilestone75 => '75%';

  @override
  String get goalMilestone100 => '100%';

  @override
  String get goalAnalyzeWithAi => 'Analyze with AI';

  @override
  String get goalAiAnalyzing => 'Analyzing your goal...';

  @override
  String get goalAiAnalyzingDesc =>
      'Our AI is examining your financial history to evaluate the feasibility of this goal.';

  @override
  String get goalAiFeasible => 'Feasible';

  @override
  String get goalAiChallenging => 'Challenging';

  @override
  String get goalAiUnrealistic => 'Unrealistic';

  @override
  String get goalAiResultTitle => 'Goal Analysis';

  @override
  String get goalAiReason => 'Why:';

  @override
  String get goalAiSuggestion => 'Suggestion:';

  @override
  String get goalAiClose => 'Got it';

  @override
  String get goalMonthlyRequirementLabel => 'Monthly value';

  @override
  String goalMonthlyRequirementValue(String amount) {
    return '$amount/mo';
  }

  @override
  String get automaticTransactionTitle => 'Identified Transactions';

  @override
  String get automaticTransactionSubtitle =>
      'We identified new movements in your notifications. Do you want to register them?';

  @override
  String get automaticTransactionConsolidate => 'Register';

  @override
  String get automaticTransactionIgnore => 'Ignore';

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
  String get planning503020Title => '50-30-20 Planning';

  @override
  String get planning503020SummaryIncome => 'Planned Income';

  @override
  String get planning503020SummaryExpense => 'Planned Expense';

  @override
  String get planning503020Essential => 'Essential';

  @override
  String get planning503020Comfort => 'Comfort';

  @override
  String get planning503020Investment => 'Investment';

  @override
  String get planning503020EssentialDesc =>
      'Spending limits for basic needs. Ideal: 50% of your income.';

  @override
  String get planning503020ComfortDesc =>
      'Spending on lifestyle and leisure. Ideal: 30% of your income.';

  @override
  String get planning503020InvestmentDesc =>
      'Future and security (investments and debts). Ideal: 20% of your income.';

  @override
  String planning503020Ideal(String amount) {
    return 'Goal: $amount';
  }

  @override
  String planning503020ActualAmount(String amount) {
    return 'Actual: $amount';
  }

  @override
  String get planning503020Subtitle => 'Track your golden rule 50-30-20';

  @override
  String get planning503020DistributionTitle => '50-30-20 Distribution';

  @override
  String get planning503020Planned => 'Planned';

  @override
  String get planning503020Actual => 'Actual';

  @override
  String get planning503020Goal => 'Goal';

  @override
  String get planning503020SummaryActual => 'Actual Spent';

  @override
  String get planning503020ActualLabel => 'Already spent:';

  @override
  String planning503020Total(String amount) {
    return 'Total: $amount';
  }

  @override
  String get planning503020AlertSpecificGreater =>
      'Planned spending higher than estimated!';

  @override
  String get planning503020Save => 'SAVE';

  @override
  String get planning503020EmptyPool => 'Drag categories here';

  @override
  String get automaticTransactionFindExisting => 'Find Existing';

  @override
  String get automaticTransactionEmpty => 'No new transactions identified.';

  @override
  String get automaticTransactionSimulate => 'Simulate Notification';

  @override
  String get automaticTransactionRequestPermission => 'Listen to Notifications';

  @override
  String get automaticTransactionPermissionRequired =>
      'To detect transactions automatically, the app needs permission to read notifications.';

  @override
  String get automaticTransactionGrantPermission => 'Grant Permission';

  @override
  String automaticTransactionSuggestedCategory(Object category) {
    return 'Suggested category: $category';
  }

  @override
  String automaticTransactionSuggestedAccount(Object account) {
    return 'Suggested account: $account';
  }

  @override
  String goalRemainingValue(String amount) {
    return '$amount left';
  }

  @override
  String goalProgressValue(String percent) {
    return '$percent%';
  }

  @override
  String get goalEmptyMessage =>
      'How about starting to plan your future? Create your first goal now!';

  @override
  String get goalEmptyExample => 'Ex.: Disney Trip';

  @override
  String get addGoalButton => 'New Goal';

  @override
  String get goalNameLabel => 'Goal Name';

  @override
  String get goalTargetAmountLabel => 'Target Amount';

  @override
  String get goalCurrentAmountLabel => 'Current Amount';

  @override
  String get goalStartDateLabel => 'Start Date';

  @override
  String get goalDeadlineLabel => 'Deadline';

  @override
  String get goalTypeLabel => 'Goal Type';

  @override
  String get goalTypeSaveMoney => 'Save Money';

  @override
  String get goalTypeReduceExpense => 'Reduce Spending (Category)';

  @override
  String get goalTypeReduceCreditCard => 'Reduce Credit Card Spending';

  @override
  String get goalTypePayDebt => 'Pay Debt';

  @override
  String get goalCategoryLabel => 'Category';

  @override
  String get goalCreditCardLabel => 'Credit Card';

  @override
  String get goalAverageSpendingLabel => 'Monthly Average Spending';

  @override
  String get errorGoalNotFound => 'Goal not found.';

  @override
  String get errorGoalTypeCannotBeChanged => 'Goal type cannot be changed.';

  @override
  String get statusOnTrack => 'On track';

  @override
  String get statusAtRisk => 'At risk';

  @override
  String get statusBehind => 'Behind';

  @override
  String get statusLost => 'Lost';

  @override
  String goalProgressPercent(Object percent) {
    return '$percent% completed';
  }

  @override
  String goalRemainingAmount(Object amount) {
    return '$amount remaining';
  }

  @override
  String get continueButton => 'CONTINUE';

  @override
  String get invitesTitle => 'Pending Invites';

  @override
  String get invitesSubtitle =>
      'You have been invited to participate in the following workspaces:';

  @override
  String inviteFrom(String sender) {
    return 'Sent by: $sender';
  }

  @override
  String get acceptButton => 'Accept';

  @override
  String get declineButton => 'Decline';

  @override
  String get homeJourneyTab => 'The Journey';

  @override
  String get homeOverviewTab => 'Overview';

  @override
  String get homeMissionsTab => 'Missions';

  @override
  String get homeHistoryTab => 'Statement';

  @override
  String homeTotalSavedMonth(Object amount) {
    return 'You saved $amount more than planned!';
  }

  @override
  String homePointsEarned(Object points) {
    return '+$points Points';
  }

  @override
  String homeRemainingAmount(Object amount, Object percent) {
    return '$amount left ($percent% completed)';
  }

  @override
  String get homeAccountsAndCards => 'Balances & Invoices';

  @override
  String get weeklyMissions => 'Weekly Missions';

  @override
  String get weeklyMissionsSuccess => 'Successful Week!';

  @override
  String get weeklyMissionsNone => 'No missions for this week';

  @override
  String get weeklyMissionsSuccessDesc =>
      'You have met all your goals. Congratulations!';

  @override
  String get weeklyMissionsNoneDesc =>
      'Set up plannings or add transactions to start.';

  @override
  String get pendingMissions => 'Pending';

  @override
  String get completedMissions => 'Completed';

  @override
  String get overdueMissions => 'Overdue';

  @override
  String weeklyMissionsProgress(String completed, String total) {
    return '$completed of $total completed';
  }

  @override
  String get weeklyGoal => 'Weekly Goal';

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
  String get remainingWeeklyPlanning => 'Available this week';

  @override
  String spentOfWeeklyPlanning(String spent, String limit) {
    return '$spent of $limit';
  }

  @override
  String get hpLabel => 'HP';

  @override
  String overBudgetAmount(String amount) {
    return 'Excess: $amount';
  }

  @override
  String get homeWhereIsMoney => 'Where is the money?';

  @override
  String get homeTotalSpent => 'Total Spent';

  @override
  String get homeTotalBalance => 'Total Balance';

  @override
  String get accountCreateAction => 'Create New Account';

  @override
  String accountCreateTypeAction(String type) {
    return 'Create New $type Account';
  }

  @override
  String get homeAllAccounts => 'All Accounts';

  @override
  String get homeThisMonth => 'This Month';

  @override
  String get homeLastMonth => 'Last Month';

  @override
  String get homeCustomPeriod => 'Custom';

  @override
  String get homeNewTransaction => 'New Transaction';

  @override
  String get homeConsolidate => 'Consolidate';

  @override
  String get noTransactionsInPeriod => 'No transactions found for this period';

  @override
  String get historyFilterPeriod => 'Select Period';

  @override
  String get historyFilterAccountLabel => 'Account';

  @override
  String get historyFilterAllAccounts => 'All Accounts';

  @override
  String get all => 'All';

  @override
  String get historyFilterTitle => 'Filters';

  @override
  String get historyFilterDescriptionLabel => 'Description';

  @override
  String get historyFilterTypeLabel => 'Transaction Type';

  @override
  String get historyFilterCategoryLabel => 'Category';

  @override
  String get historyFilterStatusLabel => 'Status';

  @override
  String get historyFilterAmountRangeLabel => 'Amount Range';

  @override
  String get historyFilterMinAmountLabel => 'Min Amount';

  @override
  String get historyFilterMaxAmountLabel => 'Max Amount';

  @override
  String get transactionWizardSelectCategory => 'Select Category';

  @override
  String get transactionWizardSelectPending => 'Pending Transactions';

  @override
  String get transactionWizardNewTransaction => 'New transaction';

  @override
  String get historyFilterApply => 'Apply Filters';

  @override
  String get historyFilterClear => 'Clear';

  @override
  String get homeSettings => 'Settings';

  @override
  String get homeNoWorkspaceSelected => 'No workspace selected';

  @override
  String get workspaceSettingsTitle => 'Workspace Settings';

  @override
  String get workspaceSettingsGeneralSection => 'General';

  @override
  String get workspaceSettingsEditName => 'Workspace Name';

  @override
  String get workspaceSettingsDataSection => 'Data';

  @override
  String get workspaceSettingsCategories => 'Categories';

  @override
  String get workspaceSettingsTeamSection => 'Team';

  @override
  String get workspaceSettingsMembers => 'Members';

  @override
  String get workspaceSettingsEditNameDesc =>
      'Change your workspace name for better identification.';

  @override
  String get workspaceSettingsCategoriesDesc =>
      'Manage income and expense categories for your workspace.';

  @override
  String get workspaceSettingsAccountsDesc =>
      'Set up your bank accounts, credit cards, and investments.';

  @override
  String get workspaceSettingsMembersDesc =>
      'Invite partners or family members to manage finances together.';

  @override
  String get workspaceSettingsLogout => 'Logout';

  @override
  String get workspaceSettingsLogoutDesc => 'Safely end your current session.';

  @override
  String get categoryManagementTitle => 'Category Management';

  @override
  String get categoryManagementEmpty => 'No categories registered.';

  @override
  String get categoryCreateTitle => 'New Category';

  @override
  String get categoryEditTitle => 'Edit Category';

  @override
  String get categoryNameLabel => 'Category Name';

  @override
  String get categoryTypeLabel => 'Type';

  @override
  String get categoryTypeIncome => 'Income';

  @override
  String get categoryTypeExpense => 'Expense';

  @override
  String get categoryTypeBoth => 'Both';

  @override
  String get categoryDeleteTitle => 'Delete Category';

  @override
  String categoryDeleteConfirm(String name) {
    return 'Are you sure you want to delete the category \"$name\"?';
  }

  @override
  String get categoryOthers => 'Others';

  @override
  String get saveButton => 'Save';

  @override
  String get reconciliationTitle => 'Bank Reconciliation';

  @override
  String reconciliationTransactionsFound(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions found',
      one: '1 transaction found',
      zero: 'No transactions found',
    );
    return '$_temp0';
  }

  @override
  String get reconciliationSelectAccount =>
      'Select the statement or invoice file';

  @override
  String get reconciliationSupportedFormats =>
      'Supports PDF, OFX, and Images (PNG, JPG)';

  @override
  String get reconciliationChooseFile => 'Choose File';

  @override
  String get reconciliationAnalyzing => 'Analyzing your statement';

  @override
  String get reconciliationAnalyzingDesc =>
      'AI is processing your document transactions for reconciliation.';

  @override
  String get reconciliationConfirm => 'Confirm';

  @override
  String get reconciliationBack => 'Back';

  @override
  String get reconciliationSuccess => 'Reconciliation completed successfully!';

  @override
  String get reconciliationStatusMatched => 'Found';

  @override
  String get reconciliationStatusSuggested => 'Suggested';

  @override
  String get reconciliationStatusUnmatched => 'New';

  @override
  String get reconciliationStatusIgnored => 'Ignored';

  @override
  String get reconciliationActionConfirm => 'Confirm';

  @override
  String get reconciliationActionModify => 'Modify';

  @override
  String get reconciliationActionIgnore => 'Ignore';

  @override
  String get reconciliationActionRestore => 'Restore';

  @override
  String get reconciliationActionLink => 'Link';

  @override
  String get reconciliationActionRegister => 'Register';

  @override
  String get reconciliationActionAnalyze => 'Analyze Statement';

  @override
  String get reconciliationSystemLabel => 'SYSTEM';

  @override
  String get reconciliationExtratoLabel => 'STATEMENT';

  @override
  String get reconciliationNoMatchFound => 'No matching transaction found';

  @override
  String get reconciliationSectionTitle => 'Reconciliation';

  @override
  String get reconciliationSectionDesc =>
      'Compare your records with the actual bank statement.';

  @override
  String get reconciliationChangeAccount => 'Change';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get categoryColorLabel => 'Category Color';

  @override
  String get categoryIconLabel => 'Category Icon';

  @override
  String get workspaceSettingsAccounts => 'Accounts';

  @override
  String get accountManagementTitle => 'Account Management';

  @override
  String get accountManagementEmpty => 'No accounts registered.';

  @override
  String get accountCreateTitle => 'New Account';

  @override
  String get accountEditTitle => 'Edit Account';

  @override
  String get accountNameLabel => 'Account Name';

  @override
  String get accountTypeLabel => 'Account Type';

  @override
  String get accountTypeChecking => 'Checking Account';

  @override
  String get accountTypeInvestment => 'Investment';

  @override
  String get accountTypeCreditCard => 'Credit Card';

  @override
  String get accountTypeDebt => 'Debt';

  @override
  String get accountColorLabel => 'Account Color';

  @override
  String get accountIconLabel => 'Account Icon';

  @override
  String get accountLimitLabel => 'Limit';

  @override
  String get accountDueDayLabel => 'Due Day';

  @override
  String get accountClosingDayLabel => 'Closing Day';

  @override
  String get accountInterestRateLabel => 'Interest Rate (%)';

  @override
  String get accountDeleteTitle => 'Delete Account';

  @override
  String accountDeleteConfirm(String name) {
    return 'Are you sure you want to delete the account \"$name\"? (Data will not be physically lost)';
  }

  @override
  String get addAccountButton => 'Add Account';

  @override
  String get addWorkspaceButton => 'Add Workspace';

  @override
  String get goalAccountLabel => 'Associated Account';

  @override
  String get transactionAddExpense => 'Log Expense';

  @override
  String get transactionAddIncome => 'Log Income';

  @override
  String get transactionPlanExpense => 'Plan Expense';

  @override
  String get transactionPlanIncome => 'Plan Income';

  @override
  String get transactionPlanTransfer => 'Plan Transfer';

  @override
  String get transactionActionTransfer => 'Transfer';

  @override
  String get transactionCategoriesSection => 'Categories';

  @override
  String get transactionRealizedSection => 'Realized Transactions';

  @override
  String get transactionRealizedSubtitle =>
      'Transactions that have already happened and impacted your balance.';

  @override
  String get transactionPlannedSection => 'Schedules';

  @override
  String get transactionPlannedSubtitle =>
      'Keep track of your upcoming bills and earnings.';

  @override
  String get planningSectionTitle => 'Strategy';

  @override
  String get planningSectionSubtitle =>
      'Set limits and track your ideal spending distribution.';

  @override
  String get transactionDescriptionLabel => 'Description';

  @override
  String get transactionAmountLabel => 'Amount';

  @override
  String get transactionAmountTotalLabel => 'Total Amount';

  @override
  String get transactionAmountInstallmentLabel => 'Installment Amount';

  @override
  String get transactionAmountRecurringLabel => 'Recurring Amount';

  @override
  String get transactionDateLabel => 'Date';

  @override
  String get transactionAccountLabel => 'Account';

  @override
  String get transactionInstallmentsLabel => 'Installments';

  @override
  String get transactionStatusSettled => 'Settled';

  @override
  String get transactionStatusPaid => 'Paid';

  @override
  String get transactionStatusPending => 'Pending';

  @override
  String get transactionStatusPlanning => 'Planning';

  @override
  String get transactionStatusRealized => 'Realized';

  @override
  String get transactionStatusLabel => 'Status';

  @override
  String get transactionStatusTypeLabel => 'Registration Type';

  @override
  String get transactionSettledAlert =>
      'This transaction cannot be modified because it has already been settled.';

  @override
  String get transactionUnsettleAction => 'Undo reconciliation';

  @override
  String get transactionTypeExpense => 'Expense';

  @override
  String get transactionTypeIncome => 'Income';

  @override
  String get transactionTypeTransfer => 'Transfer';

  @override
  String get transactionTypeInvoice => 'Invoice';

  @override
  String get transactionFromAccountLabel => 'From Account';

  @override
  String get transactionToAccountLabel => 'To Account';

  @override
  String get transactionSaveSuccess => 'Transaction saved successfully!';

  @override
  String get transactionCascadeTitle => 'Apply changes';

  @override
  String get transactionCascadeDescription =>
      'Do you want to apply these changes only to this installment or replicate to others?';

  @override
  String get transactionCascadeOnlyThis => 'Only this one';

  @override
  String get transactionCascadeThisAndNext => 'This and next ones';

  @override
  String get transactionCascadeAll => 'All of them';

  @override
  String get transactionDeleteCascadeTitle => 'Delete installments';

  @override
  String get transactionDeleteCascadeDescription =>
      'Do you want to delete only this installment or the others as well?';

  @override
  String get transactionDeleteCascadeOnlyThis => 'Only this one';

  @override
  String get transactionDeleteCascadeThisAndNext => 'This and next ones';

  @override
  String get transactionDeleteCascadeAll => 'All of them';

  @override
  String get transactionDueDateLabel => 'Due Date';

  @override
  String get noAccountsFound => 'No accounts found.';

  @override
  String get initialBalanceLabel => 'Initial Balance';

  @override
  String get initialBalanceCreditCardLabel => 'Next Invoice Amount';

  @override
  String get initialBalanceInvestmentLabel => 'Initial Investment Amount';

  @override
  String get initialBalanceDebtLabel => 'Current Debt Amount';

  @override
  String get initialBalanceDateLabel => 'Initial Balance Date';

  @override
  String get initialBalanceInvestmentDateLabel => 'Initial Investment Date';

  @override
  String get initialBalanceDebtDateLabel => 'Current Amount Date';

  @override
  String get accountBankLogoLabel => 'Bank/Brand Logo';

  @override
  String get accountOwnerIdsLabel => 'Owners';

  @override
  String get customLabel => 'Custom';

  @override
  String get accountNextInvoiceValueLabel => 'Next invoice amount';

  @override
  String get accountInitialInvestmentValueLabel => 'Initial investment balance';

  @override
  String get accountInitialDebtValueLabel => 'Debt amount';

  @override
  String get accountInitialInvestmentDateLabel => 'Initial investment date';

  @override
  String get accountInitialDebtDateLabel => 'Debt date';

  @override
  String get none => 'None';

  @override
  String get accountMethodDocument => 'By Document';

  @override
  String get accountMethodManual => 'Manual';

  @override
  String get accountDocumentDescription =>
      'Attach your bank statement (PDF) or transaction file (OFX). Our AI will analyze the data to automatically set up your account, balance, and transactions.';

  @override
  String get accountDocumentAcceptedTypes => 'Accepted formats: PDF, OFX';

  @override
  String get accountManualDescription =>
      'Fill in the account details manually if you don\'t have a document or prefer to set it up your way.';

  @override
  String get accountDetectedDataTitle => 'AI Detected Data';

  @override
  String accountDetectedTransactions(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions found',
      one: '1 transaction found',
    );
    return '$_temp0';
  }

  @override
  String accountDetectedPlannings(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count suggested plannings',
      one: '1 suggested planning',
    );
    return '$_temp0';
  }

  @override
  String get accountDetectedConfirmation =>
      'Confirm the details below to complete the registration.';

  @override
  String get accountSelectFile => 'SELECT FILE';

  @override
  String get accountDropFile =>
      'Drag and drop the file here or click to select';

  @override
  String get accountAnalyzing => 'Analyzing document...';

  @override
  String get accountAnalysisDescription =>
      'Our IA is analyzing your document to prepare your account data and identify transactions automatically.';

  @override
  String get accountAnalysisProcessing => 'Processing data...';

  @override
  String get accountAnalysisFailed => 'Processing failed';

  @override
  String get onboardingPlanningAnalyzingTitle => 'Analyzing patterns...';

  @override
  String get onboardingPlanningAnalyzingDesc =>
      'Our AI is analyzing your spending patterns to suggest ideal goals and plans for you.';

  @override
  String get accountViewTransactions => 'View Transactions';

  @override
  String get accountViewPlannings => 'View Plannings';

  @override
  String get accountDetectedTransactionsTitle => 'Detected Transactions';

  @override
  String get accountDetectedPlanningsTitle => 'Suggested Plannings';

  @override
  String get historyEdit => 'Edit';

  @override
  String get historyDelete => 'Delete';

  @override
  String get historyDeleteTitle => 'Delete Transaction';

  @override
  String get historyDeleteConfirm =>
      'Are you sure you want to delete this transaction?';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get transactionTypeLabel => 'Transaction Type';

  @override
  String get transactionTypeSimple => 'Simple';

  @override
  String get transactionTypeInstallment => 'Installment';

  @override
  String get transactionTypeRecurrent => 'Recurrence';

  @override
  String get homeTotalPlanned => 'Total Planned';

  @override
  String get overviewPlanning => 'Planned';

  @override
  String get overviewEffective => 'Actual';

  @override
  String get overviewComparison => 'Comparison';

  @override
  String get homeOverviewShowDetails => 'View Details';

  @override
  String get categoryReportDetails => 'Category Details';

  @override
  String get transactionTransfer => 'Transfer';

  @override
  String get transactionSelectSourceAccount => 'Select Source Account';

  @override
  String get transactionSelectDestinationAccount =>
      'Select Destination Account';

  @override
  String get transactionAddExpenseDesc =>
      'Record a single expense that happened today or in the past.';

  @override
  String get transactionAddIncomeDesc =>
      'Record a single income that happened today or in the past.';

  @override
  String get transactionPlanExpenseDesc =>
      'Schedule a future expense, recurring or installment-based.';

  @override
  String get transactionPlanIncomeDesc =>
      'Schedule a future income, recurring or installment-based.';

  @override
  String get transactionTransferDesc =>
      'Move money between your bank accounts or credit cards.';

  @override
  String get transactionOrderTypeLabel => 'Transaction Type';

  @override
  String get clear => 'Clear';

  @override
  String get validationEmailMessage => 'Invalid E-mail';

  @override
  String validationLengthMaxMessage(Object min) {
    return 'At least $min characters.';
  }

  @override
  String validationLenghtMinMessage(Object max) {
    return 'No more than $max characters.';
  }

  @override
  String get validationNotEmptyMessage => 'Required field.';

  @override
  String get validationNotNullMessage => 'Required field.';

  @override
  String get noRecordsFound => 'No records found.';

  @override
  String get formatSimpleDate => 'MM/dd/yyyy';

  @override
  String get errorLoadingData => 'Failed to load data.';

  @override
  String get retry => 'Try again';

  @override
  String get planningExpenseLimits => 'Expense Limits';

  @override
  String get planningIncomeLimits => 'Income Expectations';

  @override
  String get planningLimitDefined => 'Expectation defined';

  @override
  String get planningSave => 'SAVE';

  @override
  String get expenses => 'Expenses';

  @override
  String get incomes => 'Incomes';

  @override
  String get balance => 'Balance';

  @override
  String get securePasswordAtLeast8Characters => 'At least 8 characters';

  @override
  String get securePasswordAtMost50Characters => 'At most 50 characters';

  @override
  String get securePasswordDontUseSpaces => 'Don\'t use spaces';

  @override
  String get securePasswordAtLeast1Uppercase => 'At least one uppercase letter';

  @override
  String get securePasswordAtLeast1Lowercase => 'At least one lowercase letter';

  @override
  String get securePasswordAtLeast1Number => 'At least one number';

  @override
  String get signUpFailed =>
      'Failed to create account. Please try again or contact our support.';

  @override
  String get signInFailed =>
      'Failed to sign in. Please try again or contact our support.';

  @override
  String get dateInputPattern => 'MM/dd/yyyy';

  @override
  String installmentCountDescription(Object count, Object number) {
    return '$number of $count';
  }

  @override
  String get statusPending => 'Pending';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusSettled => 'Settled';

  @override
  String get date => 'Date';

  @override
  String get historyAccountLabel => 'Account';

  @override
  String get periodSummary => 'Period Summary';

  @override
  String get totalIncomes => 'Total Incomes';

  @override
  String get totalExpenses => 'Total Expenses';

  @override
  String get totalTransfers => 'Total Transfers';

  @override
  String get totalInvoices => 'Total Invoices';

  @override
  String get periodBalance => 'Period Balance';

  @override
  String get plannedLabel => 'Planned';

  @override
  String get realizedLabel => 'Realized';

  @override
  String get periodFilterDay => 'Dia';

  @override
  String get periodFilterMonth => 'Month';

  @override
  String get periodFilterQuarter => 'Quarter';

  @override
  String get periodFilterSemester => 'Semester';

  @override
  String get periodFilterYear => 'Year';

  @override
  String get periodFilterCustom => 'Custom';

  @override
  String get periodFilterTitle => 'Select Period';

  @override
  String completedMissionsSummary(num count, Object xp) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    return '$count $_temp0 • $xp XP';
  }

  @override
  String get registerEffectivation => 'Mark as realized';

  @override
  String get returnToPending => 'Return to Pending';

  @override
  String get partyHpLabel => 'Party Health';

  @override
  String get partyStatusHealthy => 'Party Safe';

  @override
  String get partyStatusStrained => 'Party in Danger';

  @override
  String get partyStatusDefeated => 'Party Defeated';

  @override
  String get partyTeamTitle => 'Team';

  @override
  String get planned => 'Planned';

  @override
  String get actual => 'Actual';

  @override
  String get excess => 'Excess';

  @override
  String get invoiceDetailTitle => 'Invoice Detail';

  @override
  String get registerInvoicePayment => 'Register Invoice Payment';

  @override
  String get coachingTitle => 'Financial Coach';

  @override
  String get coachingConsultAction => 'Consult Coach';

  @override
  String get coachingViewLast => 'View last analysis';

  @override
  String coachingLastAnalysisFrom(String date) {
    return 'Last analysis from $date';
  }

  @override
  String coachingWaitSevenDays(int days) {
    return 'You can consult the coach again in $days days.';
  }

  @override
  String get coachingWaitLessOneDay =>
      'You can consult the coach again tomorrow.';

  @override
  String get coachingConsulting => 'Consulting Coach...';

  @override
  String get coachingConsultingDesc =>
      'Our AI is analyzing your financial health to give you the best advice.';

  @override
  String get coachingError => 'Error consulting coach. Please try again later.';

  @override
  String get coachingSlideNext => 'Next';

  @override
  String get coachingSlideBack => 'Back';

  @override
  String get coachingSlideFinish => 'Finish';

  @override
  String get coachingNoData => 'No coaching data available.';

  @override
  String get coachingNoSlides => 'No slides were generated. Please try again.';

  @override
  String get coachingViewHistory => 'View history';

  @override
  String get coachingHistoryTitle => 'Insights History';

  @override
  String get coachingReviewTips => 'Review Tips';

  @override
  String get weeklyMissionsTitle => 'Weekly Missions';

  @override
  String get weeklyMissionsSuccessTitle => 'Missions Completed!';

  @override
  String get weeklyMissionsSuccessMessage =>
      'Congratulations! You completed all activities for this week. Keep it up to maintain your financial health!';

  @override
  String get accountStatementCurrent => 'Current';

  @override
  String get accountStatementFuture => 'Future';

  @override
  String get currentBalance => 'Current Balance';

  @override
  String get transactions => 'Transactions';

  @override
  String get challengeStatusStable => 'Stable';

  @override
  String get challengeStatusWarning => 'Warning';

  @override
  String get challengeStatusCritical => 'Critical';

  @override
  String get rest => 'Rest';

  @override
  String get category => 'Category';

  @override
  String get realization => 'Realization';

  @override
  String get difference => 'Difference';

  @override
  String missingAmount(String amount) {
    return 'Missing $amount';
  }

  @override
  String exceededAmount(String amount) {
    return 'Exceeded $amount';
  }

  @override
  String get paymentInfo => 'Payment Info';

  @override
  String get accountOwnerLabel => 'Ownership';

  @override
  String get teamAchievementsTitle => 'Team Achievements';

  @override
  String workspaceLabel(String name) {
    return 'Workspace: $name';
  }

  @override
  String levelLabel(int level) {
    return 'Level $level';
  }

  @override
  String totalXpLabel(String xp) {
    return 'Total: $xp XP';
  }

  @override
  String get weeklyStreaksLabelSingular => 'Weekly streak: 1 week';

  @override
  String weeklyStreaksLabelPlural(int streaks) {
    return 'Weekly streak: $streaks weeks';
  }

  @override
  String get yourBadgesLabel => 'Your Badges';

  @override
  String get badgeUnlockedLabel => 'Unlocked';

  @override
  String get badgeLockedLabel => 'Locked';

  @override
  String get badgeRewardLabel => 'Reward';

  @override
  String get badgeUnlockedAtLabel => 'Earned on';

  @override
  String get viewAchievementsButton => 'View Achievements';

  @override
  String get badge_first_step_name => 'First Step';

  @override
  String get badge_first_step_desc =>
      'The workspace is created and onboarding is successfully completed.';

  @override
  String get badge_first_account_name => 'First Account';

  @override
  String get badge_first_account_desc =>
      'The first bank account or card is registered in the workspace.';

  @override
  String get badge_first_transaction_name => 'Starting Point';

  @override
  String get badge_first_transaction_desc =>
      'The first real transaction (installment) is recorded with paid status.';

  @override
  String get badge_planner_name => 'Strategic Planner';

  @override
  String get badge_planner_desc =>
      'Planning limits are created for at least 5 categories.';

  @override
  String get badge_reconcile_junior_name => 'Junior Reconciler';

  @override
  String get badge_reconcile_junior_desc =>
      'The first successful bank reconciliation is completed (at least 1 confirmed match).';

  @override
  String get badge_cash_detective_name => 'Cash Detective';

  @override
  String get badge_cash_detective_desc =>
      'Full reconciliation of a statement containing at least 10 transactions.';

  @override
  String get badge_reconcile_master_name => 'Reconciliation Master';

  @override
  String get badge_reconcile_master_desc =>
      'The workspace accumulates 10 successfully completed statement reconciliations.';

  @override
  String get badge_zero_friction_name => 'Zero Friction';

  @override
  String get badge_zero_friction_desc =>
      'Reconcile an entire monthly statement without needing to create extra manual transactions.';

  @override
  String get badge_savings_seed_name => 'Savings Seed';

  @override
  String get badge_savings_seed_desc =>
      'The first goal registered in the workspace reaches 100% progress.';

  @override
  String get badge_goal_bronze_name => 'Goal Collector';

  @override
  String get badge_goal_bronze_desc =>
      'The workspace successfully completes 3 different financial goals.';

  @override
  String get badge_goal_silver_name => 'Unwavering Focus';

  @override
  String get badge_goal_silver_desc =>
      'The workspace successfully completes 5 different financial goals.';

  @override
  String get badge_emergency_shield_name => 'Emergency Shield';

  @override
  String get badge_emergency_shield_desc =>
      'Reach 100% progress on a goal created with the \"Emergency\" category/tag.';

  @override
  String get badge_under_control_name => 'All Under Control';

  @override
  String get badge_under_control_desc =>
      'Close the month without exceeding any planned category in the 50-30-20 rule.';

  @override
  String get badge_golden_rule_name => 'Golden Rule';

  @override
  String get badge_golden_rule_desc =>
      'Allocate limits in all 3 pools (Essential, Comfort, Investment) in the same month.';

  @override
  String get badge_future_focus_name => 'Future Focus';

  @override
  String get badge_future_focus_desc =>
      'Effectively save and invest at least 20% of the total workspace revenues in the month.';

  @override
  String get badge_cost_cutter_name => 'Cost Cutter';

  @override
  String get badge_cost_cutter_desc =>
      'Reduce total expenses of the Comfort pool (discretionary) by 20% compared to the previous month.';

  @override
  String get badge_dynamic_duo_name => 'Dynamic Duo';

  @override
  String get badge_dynamic_duo_desc =>
      'Workspace with 2 active members recording paid transactions in the same month.';

  @override
  String get badge_united_front_name => 'United Front';

  @override
  String get badge_united_front_desc =>
      'Workspace with 3 or more active members added and accepted.';

  @override
  String get badge_financial_synapsis_name => 'Financial Synergy';

  @override
  String get badge_financial_synapsis_desc =>
      'Complete a weekly mission where all active members recorded at least 1 transaction.';

  @override
  String get badge_iron_consistency_name => 'Iron Consistency';

  @override
  String get badge_iron_consistency_desc =>
      'Successfully complete weekly missions for 4 consecutive weeks.';

  @override
  String levelIndicatorSemantics(int level, int count) {
    return 'Workspace Level: $level, Badges unlocked: $count';
  }

  @override
  String get levelUpTitle => 'LEVEL UP!';

  @override
  String get levelUpSubtitle => 'Congratulations to the team!';

  @override
  String levelUpContent(int level) {
    return 'Your workspace rose to Level $level!';
  }

  @override
  String get levelUpMessage =>
      'Keep cooperating and planning together to unlock new achievements and levels!';

  @override
  String get statementDragOverTitle => 'Drop the statement file here';

  @override
  String reconciliationBulkConfirmSuggestions(String amount) {
    return 'Confirm all suggested matches ($amount)';
  }

  @override
  String get reconciliationWarningUnanswered =>
      'Please answer all transactions before saving';

  @override
  String get reconciliationActionUnlink => 'Unlink';

  @override
  String get reconciliationAccountLabel => 'Reconciliation Account';

  @override
  String get reconciliationNotInDocument => 'Not in document';

  @override
  String get reconciliationActionKeep => 'Keep';

  @override
  String get reconciliationActionRemove => 'Remove';

  @override
  String get reconciliationStatusKeep => 'Keep in System';

  @override
  String get reconciliationStatusRemove => 'Remove from System';

  @override
  String get reconciliationStatusSystemOnly => 'Only in System';
}
