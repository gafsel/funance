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
  String get loginTitle => 'Funances';

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
  String get appErrorWidgetTitle => 'Something went wrong';

  @override
  String get appErrorWidgetMessage =>
      'We have been notified and are working on it. Try going back and opening the screen again.';

  @override
  String get errorUnknown => 'An unexpected error occurred.';

  @override
  String get routeNotFound => 'Page not found.';

  @override
  String get routeNotFoundGoHome => 'Back to home';

  @override
  String get closeButton => 'Close';

  @override
  String get workspacePickerTitle => 'Workspaces';

  @override
  String get transactionMoreOptions => 'More Options';

  @override
  String get transactionMatchTitle =>
      'There is a scheduled entry in this category. Settle it?';

  @override
  String get transactionMatchSettle => 'Settle';

  @override
  String get transactionMatchDismiss => 'It is a new expense';

  @override
  String get transactionMatchDismissIncome => 'It is new income';

  @override
  String get transactionMatchSearching => 'Looking for scheduled entries…';

  @override
  String get transactionMatchUndo => 'Not this one';

  @override
  String get transactionMatchSameAmount => 'same amount';

  @override
  String get onboardingConceptXpTitle => 'Earn XP and level up';

  @override
  String get onboardingConceptXpDesc =>
      'Every transaction earns XP — and spending within your plan earns even more. Your workspace levels up like in a game.';

  @override
  String get onboardingConceptMissionsTitle => 'Missions and achievements';

  @override
  String get onboardingConceptMissionsDesc =>
      'Complete weekly missions, keep your perfect-week streak and unlock badges in your achievements cabinet.';

  @override
  String get onboardingConceptCoachTitle => 'Your financial coach';

  @override
  String get onboardingConceptCoachDesc =>
      'An AI coach that knows your numbers and gives practical, personalized advice on your path to financial freedom.';

  @override
  String get onboardingNoSuggestions =>
      'No suggestions for now — you can create goals and plannings later, in the Journey tab.';

  @override
  String journeyStreakWeeks(int count) {
    return '$count perfect weeks in a row';
  }

  @override
  String get journeyAddGoalTooltip => 'New goal';

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
  String get errorSignInPopupBlocked =>
      'Your browser blocked the Google window. We\'re signing you in on this tab instead — if nothing happens, allow pop-ups for this site and try again.';

  @override
  String get errorSignInCancelled => 'Sign-in cancelled.';

  @override
  String get errorSignInRedirecting => 'Redirecting to Google...';

  @override
  String get errorSignInUnauthorizedDomain =>
      'This address is not authorized to sign in. Add the domain under Authentication > Settings > Authorized domains in the Firebase Console.';

  @override
  String get errorAccountExistsWithDifferentCredential =>
      'An account with this email already exists using another method. Sign in with email and password.';

  @override
  String get errorSignInProviderDisabled =>
      'This sign-in method is disabled for the project. Enable it under Authentication > Sign-in method.';

  @override
  String get offlineBannerOffline =>
      'You\'re offline. Keep browsing and editing; we\'ll sync when the network is back.';

  @override
  String get offlineBannerPending =>
      'Saved on this device. Syncing to the cloud...';

  @override
  String get errorOfflineCallable =>
      'This action needs an internet connection. Reconnect and try again.';

  @override
  String get reconciliationChooseAccount =>
      'Which account do you want to reconcile?';

  @override
  String get errorOffline =>
      'No internet connection. We\'re showing what was already on this device; tap retry when you\'re back online.';

  @override
  String get errorPermissionDenied =>
      'You don\'t have access to this data. If you just left a workspace, sign in again.';

  @override
  String get errorQuotaExhausted => 'Usage limit reached. Try again later.';

  @override
  String get errorNotAuthenticated =>
      'Your session expired. Sign in again to continue.';

  @override
  String get errorNotFound => 'This item no longer exists.';

  @override
  String get errorTimeout => 'The server took too long to respond. Try again.';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Funances!';

  @override
  String get onboardingWelcomeDesc =>
      'The app that transforms your financial management into a journey of achievements.';

  @override
  String get onboardingNext => 'Next';

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
  String get onboardingStepConceptsDesc =>
      'To get the most out of Funances, let\'s understand how we organize information.';

  @override
  String get onboardingConceptLimitsTitle => 'Limits and Expectations';

  @override
  String get onboardingConceptLimitsDesc =>
      'Define how much you expect to earn and the maximum you want to spend per category. This is your financial ceiling.';

  @override
  String get onboardingConceptPlanningTitle => 'Schedules';

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
  String goalTargetTarget(String amount) {
    return 'Target: $amount';
  }

  @override
  String get goalDetailsTitle => 'Goal Details';

  @override
  String get goalEditButton => 'Edit Goal';

  @override
  String get goalDeleteConfirmTitle => 'Delete Goal?';

  @override
  String get goalDeleteConfirmMessage =>
      'Are you sure you want to delete this goal? This action cannot be undone.';

  @override
  String get goalStatusOnTrack => 'On Track';

  @override
  String get goalStatusAtRisk => 'At Risk';

  @override
  String get goalStatusBehind => 'Behind';

  @override
  String get goalStatusLost => 'Lost';

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
  String get goalAnalyzeWithAi => 'Analyze with AI';

  @override
  String get goalAiError => 'We could not analyze the goal. Please try again.';

  @override
  String get reconciliationError =>
      'We could not analyze the statement. Please try again.';

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
  String get profileTitle => 'Profile';

  @override
  String get profileEditTitle => 'Edit Profile';

  @override
  String get profileNameLabel => 'Name';

  @override
  String get profileEmailLabel => 'Email';

  @override
  String get profileUpdateSuccess => 'Profile updated successfully!';

  @override
  String get profilePhotoCamera => 'Camera';

  @override
  String get profilePhotoGallery => 'Gallery';

  @override
  String get profileAvatarLabel => 'Your Arena hero';

  @override
  String get profileAvatarHint =>
      'This is the character who fights for you all week.';

  @override
  String get profileAvatarPreview => 'This is how you look in the Arena';

  @override
  String get profileAvatarUnknown =>
      'The hero you had saved is gone. Pick another one.';

  @override
  String get avatarKnight => 'Knight';

  @override
  String get avatarMage => 'Mage';

  @override
  String get avatarRanger => 'Ranger';

  @override
  String get avatarWarrior => 'Warrior';

  @override
  String get avatarHealer => 'Healer';

  @override
  String get avatarBarbarian => 'Barbarian';

  @override
  String get avatarMonk => 'Monk';

  @override
  String get avatarSmith => 'Blacksmith';

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
  String get planning503020EmptyPool => 'Drag categories here';

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
  String goalRemainingValue(String amount) {
    return '$amount left';
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
  String get errorGoalNotFound => 'Goal not found.';

  @override
  String get errorGoalTypeCannotBeChanged => 'Goal type cannot be changed.';

  @override
  String get continueButton => 'CONTINUE';

  @override
  String get invitesTitle => 'Pending Invites';

  @override
  String get uploadFileUnreadable => 'Could not read the file.';

  @override
  String uploadUnsupportedFormat(String formats) {
    return 'Unsupported format. Use only: $formats';
  }

  @override
  String uploadFileTooLarge(String size, int limit) {
    return 'This file is $size and the analysis limit is $limit MB. Export the statement as OFX, which is far smaller than a PDF, or split it into shorter periods.';
  }

  @override
  String get membersTitle => 'Members';

  @override
  String get membersOwnerRole => 'Owner';

  @override
  String get membersMemberRole => 'Member';

  @override
  String get membersYou => 'you';

  @override
  String get membersSectionActive => 'In this workspace';

  @override
  String get membersSectionPending => 'Invitations awaiting a reply';

  @override
  String get membersEmptyPending => 'No invitations awaiting a reply.';

  @override
  String get membersLoadError => 'Could not load the members.';

  @override
  String get membersInvitesLoadError => 'Could not load the invitations.';

  @override
  String get membersRetry => 'Try again';

  @override
  String get membersRemoveAction => 'Remove from workspace';

  @override
  String membersRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get membersRemoveConfirm =>
      'This person loses access to this workspace. Transactions, accounts and categories stay where they are — they belong to the workspace, not to whoever created them.';

  @override
  String get membersRemoveSuccess => 'Member removed.';

  @override
  String membersInviteSentAt(String date) {
    return 'Invited on $date';
  }

  @override
  String get membersResendAction => 'Resend';

  @override
  String get membersResendSuccess => 'Invitation renewed.';

  @override
  String get membersCancelInviteAction => 'Cancel invitation';

  @override
  String membersCancelInviteTitle(String email) {
    return 'Cancel the invitation to $email?';
  }

  @override
  String get membersCancelInviteConfirm =>
      'The invitation stops showing up for the person you invited.';

  @override
  String get membersCancelInviteSuccess => 'Invitation cancelled.';

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
  String get homeOverviewTab => 'Overview';

  @override
  String get homeHistoryTab => 'Statement';

  @override
  String get homeAccountsAndCards => 'Balances & Invoices';

  @override
  String get weeklyMissionsNone => 'No missions for this week';

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
  String xpValue(String xp) {
    return '$xp XP';
  }

  @override
  String dateRange(String start, String end) {
    return '$start - $end';
  }

  @override
  String get homeWhereIsMoney => 'Where is the money?';

  @override
  String get homeTotalSpent => 'Total Spent';

  @override
  String get homeNewTransaction => 'New Transaction';

  @override
  String get noTransactionsInPeriod => 'No transactions found for this period';

  @override
  String get historyFilterAccountLabel => 'Account';

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
  String get historyFilterMinAmountLabel => 'Min Amount';

  @override
  String get historyFilterMaxAmountLabel => 'Max Amount';

  @override
  String get transactionWizardSelectCategory => 'Select Category';

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
  String get categoryDeleteTitle => 'Delete Category';

  @override
  String categoryDeleteConfirm(String name) {
    return 'Are you sure you want to delete the category \"$name\"?';
  }

  @override
  String get categoryVirtualDebt => 'Loans & debt';

  @override
  String get categoryVirtualInvestment => 'Investments';

  @override
  String get categoryInitialBalance => 'Initial balance';

  @override
  String get categoryOthers => 'Others';

  @override
  String get saveButton => 'Save';

  @override
  String get reconciliationTitle => 'Bank Reconciliation';

  @override
  String get unnamedWorkspace => 'Unnamed workspace';

  @override
  String get accountManagementEmptyOfType =>
      'You don\'t have accounts of this type yet.';

  @override
  String get bankLogoOther => 'Other';

  @override
  String get accountsMine => 'My accounts';

  @override
  String accountsOfMember(String name) {
    return '$name\'s accounts';
  }

  @override
  String get accountsShared => 'Shared accounts';

  @override
  String planning503020TargetPercent(String percent) {
    return 'Target: $percent';
  }

  @override
  String get noCategory => 'No category';

  @override
  String get noDescription => 'No description';

  @override
  String get unnamedAccount => 'Unnamed account';

  @override
  String get unnamedGoal => 'Unnamed goal';

  @override
  String get automaticTransactionMoveWorkspace => 'Move to another workspace';

  @override
  String get accountOwnersLabel => 'Account owners';

  @override
  String get reconciliationPickTransaction => 'Pick a transaction';

  @override
  String get transactionNewTitle => 'New transaction';

  @override
  String get planning503020IdealLabel => 'Ideal';

  @override
  String get planning503020MonthlyLimitLabel => 'Monthly Limit';

  @override
  String get planning503020AlreadyPlanned => 'Already planned:';

  @override
  String get loginTermsNotice =>
      'By signing in, you agree to our Terms of Service and Privacy Policy.';

  @override
  String get inviteEmailHint => 'name@example.com';

  @override
  String get uploadStatusReading => 'Reading the statement file…';

  @override
  String get uploadStatusExtracting => 'Extracting transactions and amounts…';

  @override
  String get uploadStatusSearching => 'Looking for the matching entries…';

  @override
  String get uploadStatusPreparing => 'Preparing reconciliation suggestions…';

  @override
  String get uploadStatusCompleted => 'Reconciliation ready.';

  @override
  String get uploadStatusError => 'We couldn\'t read this statement.';

  @override
  String get reconciliationAction => 'Reconcile statement';

  @override
  String get reconciliationMissionCta => 'Reconcile a statement now';

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
  String get reconciliationSystemLabel => 'SYSTEM';

  @override
  String get reconciliationExtratoLabel => 'STATEMENT';

  @override
  String get reconciliationNoMatchFound => 'No matching transaction found';

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
  String get addWorkspaceButton => 'Add Workspace';

  @override
  String get goalAccountLabel => 'Associated Account';

  @override
  String get transactionAddExpense => 'Log Expense';

  @override
  String get transactionAddIncome => 'Log Income';

  @override
  String get transactionPlanExpense => 'Schedule Expense';

  @override
  String get transactionPlanIncome => 'Schedule Income';

  @override
  String get transactionPlanTransfer => 'Schedule Transfer';

  @override
  String get transactionActionTransfer => 'Transfer';

  @override
  String get transactionCategoriesSection => 'Categories';

  @override
  String get transactionRealizedSection => 'It happened';

  @override
  String get transactionRealizedSubtitle =>
      'Already happened and already moved your balance.';

  @override
  String get transactionPlannedSection => 'Schedule it';

  @override
  String get transactionPlannedSubtitle =>
      'Still to come: bills to pay and money to receive.';

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
  String get transactionStatusLabel => 'Status';

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
  String accountDetectedTransactions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions found',
      one: '1 transaction found',
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
  String get onboardingPlanningAnalyzingTitle => 'Analyzing patterns...';

  @override
  String get onboardingPlanningAnalyzingDesc =>
      'Our AI is analyzing your spending patterns to suggest ideal goals and plans for you.';

  @override
  String get accountViewTransactions => 'View Transactions';

  @override
  String get accountDetectedTransactionsTitle => 'Detected Transactions';

  @override
  String get historyEdit => 'Edit';

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
  String get transactionTransferCountsAsInvestment =>
      'Will count as Investments';

  @override
  String get transactionTransferCountsAsDebt => 'Will count as Debts';

  @override
  String get transactionOrderTypeLabel => 'Transaction Type';

  @override
  String get clear => 'Clear';

  @override
  String get validationEmailMessage => 'Invalid E-mail';

  @override
  String validationLengthMaxMessage(int max) {
    return 'No more than $max characters.';
  }

  @override
  String validationLengthMinMessage(int min) {
    return 'At least $min characters.';
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
  String get planningLimitDefined => 'Limit set';

  @override
  String get planningExpectationDefined => 'Expectation set';

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
  String installmentCountDescription(int number, int count) {
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
  String completedMissionsSummary(int count, String xp) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    return '$count $_temp0 • $xp XP';
  }

  @override
  String get returnToPending => 'Return to Pending';

  @override
  String get planned => 'Planned';

  @override
  String get actual => 'Actual';

  @override
  String get registerInvoicePayment => 'Register Invoice Payment';

  @override
  String get coachingTitle => 'Financial Coach';

  @override
  String get coachingConsultAction => 'Consult Coach';

  @override
  String get coachingViewLast => 'View last analysis';

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
  String get coachingHistoryTitle => 'Insights History';

  @override
  String get coachingReviewTips => 'Review Tips';

  @override
  String get coachingTypeWarning => 'Alert';

  @override
  String get coachingTypeTip => 'Tip';

  @override
  String get coachingTypeInsight => 'Insight';

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
  String get transactions => 'Transactions';

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
  String get badgeUnlockedLabel => 'Unlocked';

  @override
  String get badgeLockedLabel => 'Locked';

  @override
  String get badgeRewardLabel => 'Reward';

  @override
  String get badgeUnlockedAtLabel => 'Earned on';

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

  @override
  String get goalDebtTotalLabel => 'Total Debt Amount';

  @override
  String get goalDebtTotalHint => 'How much do you owe in total?';

  @override
  String get goalDebtAccountLabel => 'Link to Debt Account';

  @override
  String get goalSpendingLimitHint => 'E.g.: 500.00 (spending limit)';

  @override
  String get accountNotFound => 'Account not found.';

  @override
  String get savedSuccess => 'Saved successfully!';

  @override
  String get planningAnalysisAction => 'Ideal analysis (AI)';

  @override
  String get planningAnalysisLoadingTitle => 'Analyzing your plan';

  @override
  String get planningAnalysisLoadingDesc =>
      'The AI is calculating the ideal spend for each category based on your projected income and the 50-30-20 rule.';

  @override
  String get planningAnalysisError =>
      'Could not generate the analysis. Please try again.';

  @override
  String get planningAnalysisTitle => 'Ideal 50-30-20 Analysis';

  @override
  String planningAnalysisProjectedIncome(String amount) {
    return 'Projected income: $amount';
  }

  @override
  String planningAnalysisCurrentPct(String percent) {
    return 'Current: $percent';
  }

  @override
  String planningAnalysisTargetPct(String percent) {
    return 'Target: $percent';
  }

  @override
  String planningAnalysisAboveBy(String amount) {
    return '$amount above target';
  }

  @override
  String planningAnalysisBelowBy(String amount) {
    return '$amount below target';
  }

  @override
  String get planningAnalysisCategoriesTitle => 'Ideal per category';

  @override
  String planningAnalysisIdealValue(String amount, String percent) {
    return 'Ideal: $amount ($percent of income)';
  }

  @override
  String get planningAnalysisStatusOk => 'OK';

  @override
  String get planningAnalysisStatusAbove => 'Above';

  @override
  String get planningAnalysisStatusBelow => 'Below';

  @override
  String get planningAnalysisReclassTitle => 'Suggested reclassifications';

  @override
  String get planningAnalysisApply => 'Apply';

  @override
  String get planningAnalysisApplied => 'Category updated successfully!';

  @override
  String get planningAnalysisApplyError => 'Could not update the category.';

  @override
  String get planningAnalysisInsightsTitle => 'Insights';

  @override
  String planningAnalysisGeneratedAt(String date) {
    return 'Analysis generated on $date';
  }

  @override
  String planningAnalysisNextAvailable(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'New analysis available in $days days',
      one: 'New analysis available in $days day',
    );
    return '$_temp0';
  }

  @override
  String get planningAnalysisGenerateNew => 'Generate new analysis';

  @override
  String get goalSpendingLimitLabel => 'Spending Cap';

  @override
  String get goalAmountSavedLabel => 'Saved';

  @override
  String get goalAmountPaidLabel => 'Paid off';

  @override
  String get goalAmountSpentLabel => 'Spent';

  @override
  String goalCompletedAt(String date) {
    return 'Completed on $date';
  }

  @override
  String goalSpentOfLimit(String amount, String limit) {
    return '$amount of $limit';
  }

  @override
  String goalRemainingLimit(String amount) {
    return '$amount still fits';
  }

  @override
  String goalOverLimit(String amount) {
    return '$amount over';
  }

  @override
  String get badgeCatalogUnavailableTitle => 'Catalog unavailable';

  @override
  String get badgeCatalogUnavailableMessage =>
      'We have not received the achievement list from the server yet. Try again in a moment.';

  @override
  String get badgeCategoryAdvanced => 'Advanced Achievements';

  @override
  String get badgeCategoryFirstSteps => 'First Steps';

  @override
  String get badgeCategoryConsistency => 'Consistent Tracking';

  @override
  String get badgeCategorySavings => 'Spending and Savings';

  @override
  String get badgeCategoryGoals => 'Goals';

  @override
  String get badgeCategoryTeam => 'Team and Consistency';

  @override
  String badgeCatalogTotal(int unlocked, int total) {
    return '$unlocked of $total';
  }

  @override
  String goalLimitBlownAt(String date) {
    return 'Cap blown on $date';
  }

  @override
  String goalDeadlineMissedAt(String date) {
    return 'Deadline passed without reaching it on $date';
  }

  @override
  String get journeyClosedGoalsTitle => 'Closed goals';

  @override
  String get goalAwaitingOutcome => 'Awaiting assessment';

  @override
  String get invoiceCalculating => 'calculating…';

  @override
  String get invoiceCycleUnavailable =>
      'We are closing this invoice. Purchases show up as soon as the calculation finishes.';

  @override
  String get journeyWeeklyXpEmpty => 'No XP yet this week';

  @override
  String get journeyMissionsSoonTitle => 'Your missions are on the way';

  @override
  String get journeyMissionsSoonMessage =>
      'Funances sets three new missions at the start of every week.';

  @override
  String journeyMissionProgress(int progress, int target) {
    return '$progress of $target';
  }

  @override
  String get journeyMissionDone => 'Mission complete';

  @override
  String get journeyMissionConsistency => 'Consistency';

  @override
  String get journeyMissionDiscipline => 'Discipline';

  @override
  String get journeyMissionOrganization => 'Organization';

  @override
  String get journeyMissionOther => 'Mission';

  @override
  String get journeyChecklistTitle => 'This week\'s checklist';

  @override
  String get compassTitle => 'Freedom Compass';

  @override
  String compassScoreOf(String score, String tier) {
    return '$score of 100 • $tier';
  }

  @override
  String get compassTierAprendiz => 'Apprentice';

  @override
  String get compassTierGuardiao => 'Guardian';

  @override
  String get compassTierEstrategista => 'Strategist';

  @override
  String get compassTierMestre => 'Master';

  @override
  String get compassTierLivre => 'Free';

  @override
  String get compassTierUnknown => 'Being assessed';

  @override
  String get compassFolego => 'Breath';

  @override
  String get compassFolegoDesc =>
      'How long your savings cover your expenses if income stops.';

  @override
  String compassFolegoDetail(String months) {
    return '$months months of expenses saved';
  }

  @override
  String get compassPoupanca => 'Savings';

  @override
  String get compassPoupancaDesc =>
      'How much of your income becomes savings or investment each month.';

  @override
  String compassPoupancaDetail(String rate) {
    return '$rate of income saved';
  }

  @override
  String get compassDisciplina => 'Discipline';

  @override
  String get compassDisciplinaDesc =>
      'How many categories ended the month within the limit you set.';

  @override
  String compassDisciplinaDetail(int within, int total) {
    return '$within of $total categories within the limit';
  }

  @override
  String get compassAlivio => 'Relief';

  @override
  String get compassAlivioDesc =>
      'How much your debts have shrunk since last month.';

  @override
  String compassAlivioDetail(String delta) {
    return '$delta in debt this month';
  }

  @override
  String get compassHistoryTitle => 'Last 6 months';

  @override
  String get compassHistoryEmpty =>
      'There are not enough closed months to compare yet.';

  @override
  String get unplannedNudgeTitle => 'That spend was not in the plan';

  @override
  String unplannedNudgeMessage(String category) {
    return '$category has no limit this month. Want to decide what to do about it now?';
  }

  @override
  String get unplannedNudgeRecurring => 'Turn into a recurring entry';

  @override
  String get unplannedNudgeRecurringDesc =>
      'If it happens every month, Funances starts logging it for you.';

  @override
  String unplannedNudgeLimit(String category) {
    return 'Set a limit for $category';
  }

  @override
  String unplannedNudgeLimitDesc(String amount) {
    return 'Suggested $amount, from your average of recent months.';
  }

  @override
  String get unplannedNudgeLimitDescNoHistory =>
      'Choose how much this category may cost per month.';

  @override
  String get unplannedNudgeDismiss => 'Just this once';

  @override
  String get xpSourcesTitle => 'How to earn XP';

  @override
  String get journeyWeeklyXpCaption => 'XP earned this week from entries';

  @override
  String compassHistoryPoint(String month, String score) {
    return '$month: $score of 100';
  }

  @override
  String get writeFailedReasonPermission =>
      'you do not have permission for this change';

  @override
  String get writeFailedReasonNotFound => 'the item no longer exists';

  @override
  String get writeFailedReasonTimeout => 'the server did not respond';

  @override
  String get writeFailedReasonUnknown => 'the server rejected the change';

  @override
  String get writeFailedReasonSerialization =>
      'the app could not prepare the data; try again';

  @override
  String get transactionSavePendingSync =>
      'Saved on this device. Instalments appear when the connection is back.';

  @override
  String get uploadFolderNotSupported => 'Drop a file, not a folder.';

  @override
  String writeFailedEntity(String entity, String reason) {
    return 'Could not save $entity: $reason';
  }

  @override
  String get writeEntityTransaction => 'the transaction';

  @override
  String get writeEntityInstallment => 'the instalment';

  @override
  String get writeEntityPlanning => 'the plan';

  @override
  String get writeEntityAccount => 'the account';

  @override
  String get writeEntityCategory => 'the category';

  @override
  String get writeEntityGoal => 'the goal';

  @override
  String get writeEntityInvite => 'the invite';

  @override
  String get writeEntityWorkspace => 'the workspace';

  @override
  String get writeEntityProfile => 'the profile';

  @override
  String get writeEntityAutomaticTransaction => 'the automatic transaction';

  @override
  String get writeEntityReconciliation => 'the reconciliation';

  @override
  String get savePendingSync =>
      'Saved on this device. It syncs when the connection is back.';

  @override
  String get accountSavePendingSync =>
      'Saved on this device. Opening balance and invoice appear when the connection is back.';

  @override
  String get celebrationXpTitle => 'XP earned';

  @override
  String get celebrationMissionTitle => 'Mission complete';

  @override
  String get celebrationBadgeTitle => 'Achievement unlocked';

  @override
  String get celebrationBadgeFallback => 'See it in the cabinet';

  @override
  String celebrationLevelTitle(int level) {
    return 'Level $level';
  }

  @override
  String get celebrationLevelSubtitle => 'The vault levelled up';

  @override
  String get celebrationTierTitle => 'New rank';

  @override
  String get settingsAppearanceSection => 'Appearance';

  @override
  String get settingsThemeMode => 'Theme';

  @override
  String get settingsThemeModeDesc =>
      'Light, dark, or whatever the system is using.';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get settingsCelebrationSound => 'Sound on achievements';

  @override
  String get settingsCelebrationSoundDesc => 'Off by default. Haptics stay on.';

  @override
  String missionPersonalConsistencyPlanLimits(String target) {
    return 'Set limits for at least $target categories to organise the week.';
  }

  @override
  String missionPersonalDisciplineTopCategory(String category, String target) {
    return 'Keep the $category category within its planned budget for $target days.';
  }

  @override
  String missionPersonalOrganizationReconcileItems(String target) {
    return 'Fully reconcile a statement with at least $target items.';
  }

  @override
  String missionBusinessConsistencyCostCenters(String target) {
    return 'Plan the limit for $target cost centres this month.';
  }

  @override
  String missionBusinessConsistencyIncomeForecast(String target) {
    return 'Confirm $target% of the revenue forecast for the week.';
  }

  @override
  String missionBusinessDisciplineTopCostCenter(
    String category,
    String target,
  ) {
    return 'Keep the $category cost centre within plan for $target days.';
  }

  @override
  String get missionBusinessDisciplineMargin =>
      'Close the week with margin (revenue − expense) above plan.';

  @override
  String missionBusinessOrganizationReconcileStatements(String target) {
    return 'Reconcile $target company account statement this week.';
  }

  @override
  String missionBusinessOrganizationCategorizeAuto(String target) {
    return 'Categorise or dismiss $target automatic entries before closing.';
  }

  @override
  String missionBusinessOrganizationCategorizeWeek(String target) {
    return 'Categorise $target% of the entries paid this week.';
  }

  @override
  String missionBusinessOrganizationInvoiceOnTime(String target) {
    return 'Close $target corporate card invoice by paying before the due date.';
  }

  @override
  String get missionFallbackCategoryPersonal => 'highest-spending';

  @override
  String get missionFallbackCategoryBusiness => 'heaviest';

  @override
  String get missionCtaPlanning => 'Plan now';

  @override
  String get missionCtaPlanning503020 => 'Open the 50-30-20';

  @override
  String get missionCtaCategories => 'See categories';

  @override
  String get missionCtaAccounts => 'See accounts';

  @override
  String get missionCtaCategoryDetails => 'See category';

  @override
  String get missionCtaTransactionForm => 'Add an entry';

  @override
  String get workspaceTypePersonalBadge => 'Personal';

  @override
  String get workspaceTypeBusinessBadge => 'Business';

  @override
  String levelBadgeShort(int level) {
    return 'Lv $level';
  }

  @override
  String levelBadgeSemantics(int level, int percent) {
    return 'Vault level $level, $percent% to the next one';
  }

  @override
  String get dueSoonToday => 'Today';

  @override
  String get dueSoonTomorrow => 'Tomorrow';

  @override
  String journeySeeAllGoals(int count) {
    return 'See all $count goals';
  }

  @override
  String get journeyNoRunningGoals => 'No goals in progress';

  @override
  String journeySeeClosedGoals(int count) {
    return 'See $count closed';
  }

  @override
  String planning503020PlannedPercent(String percent) {
    return 'Planned: $percent';
  }

  @override
  String planning503020ActualPercent(String percent) {
    return 'Actual: $percent';
  }

  @override
  String automaticTransactionSeeAll(int count) {
    return 'See all $count pending';
  }

  @override
  String automaticTransactionPendingCount(int count) {
    return '$count pending';
  }

  @override
  String get goalsTitle => 'Goals';

  @override
  String missionProgressShort(String progress, String target) {
    return '$progress/$target';
  }

  @override
  String get arenaTitle => 'Arena';

  @override
  String get arenaHeroLife => 'Life';

  @override
  String get arenaCommitted => 'Committed';

  @override
  String get arenaConfirmPaid => 'Confirm paid';

  @override
  String arenaEnraged(String amount) {
    return '+$amount overdue';
  }

  @override
  String get arenaEmpty =>
      'No commitments and no balance this week — the arena is empty. Schedule a bill and the monster shows up.';

  @override
  String arenaTeamExtra(int count) {
    return '+$count on the team';
  }

  @override
  String get automaticTransactionSeeAllShort => 'See all';

  @override
  String get arenaFree => 'Free';

  @override
  String get arenaHealed => 'Received this week';

  @override
  String get arenaRemainingPrefix => 'left';

  @override
  String get arenaMonsterDefeated => 'Defeated';

  @override
  String arenaOverheal(String amount) {
    return '+$amount above Sunday';
  }

  @override
  String get arenaHeroesFallback => 'You';

  @override
  String arenaDayOfWeek(int day, int total) {
    return '$day/$total';
  }

  @override
  String arenaDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left this week',
      one: 'Last day of the week',
    );
    return '$_temp0';
  }

  @override
  String arenaHeroesSemantics(String balance, String committed) {
    return 'Heroes\' life: $balance, of which $committed is committed. Tap to see the accounts.';
  }

  @override
  String arenaMonsterSemantics(String remaining, String total) {
    return 'Monster of the week: $remaining left of $total. Tap to see the commitments.';
  }

  @override
  String get arenaMonsterSheetTitle => 'This week\'s commitments';

  @override
  String get arenaMonsterSheetTitleBusiness => 'This week\'s payables';

  @override
  String arenaMonsterSheetSummary(String paid, String total, String remaining) {
    return '$paid paid of $total — $remaining left';
  }

  @override
  String arenaNextBlow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Next blow: $count due by tomorrow',
      one: 'Next blow: 1 due by tomorrow',
    );
    return '$_temp0';
  }

  @override
  String get arenaNoCommitments => 'No commitments scheduled for this week.';

  @override
  String arenaPaidOn(String date) {
    return 'Paid · $date';
  }

  @override
  String arenaOverdueSince(String date, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days overdue · $date',
      one: '1 day overdue · $date',
    );
    return '$_temp0';
  }

  @override
  String get arenaHeroesSheetTitle => 'Your accounts this week';

  @override
  String arenaHeroesSheetSubtitle(String initial) {
    return 'The week started with $initial in cash.';
  }

  @override
  String get arenaNoAccounts => 'No checking account registered.';

  @override
  String get arenaMonsterSpider => 'Spider';

  @override
  String get arenaMonsterBat => 'Bat';

  @override
  String get arenaMonsterGhost => 'Ghost';

  @override
  String get arenaMonsterSlime => 'Slime';

  @override
  String get arenaMonsterDemon => 'Demon';

  @override
  String get arenaError => 'We could not set up this week\'s arena.';

  @override
  String arenaScheduledOn(String date) {
    return 'Scheduled · $date';
  }

  @override
  String arenaSceneSemantics(String monster, String remaining) {
    return 'This week\'s fight: the heroes against $monster, still at $remaining of life.';
  }

  @override
  String get arenaClosingWon => 'Last week: monster defeated';

  @override
  String arenaClosingLost(String amount) {
    return 'Last week: the monster escaped with $amount';
  }

  @override
  String arenaClosingScore(int paid, int total, String balance) {
    return '$paid of $total commitments paid · cash on Saturday: $balance';
  }

  @override
  String arenaPartiallyPaid(String paid, String total, String remaining) {
    return '$paid of $total — $remaining left';
  }

  @override
  String arenaOverpaid(String amount) {
    return '+$amount above plan';
  }

  @override
  String arenaShortfall(String amount) {
    return '$amount short';
  }

  @override
  String get arenaShortfallLabel => 'Short in cash';

  @override
  String arenaShortfallCause(String name, String amount) {
    return 'Cash does not cover this week\'s commitments. The largest is $name, $amount.';
  }

  @override
  String arenaShortfallCauseOverdue(String name, String amount, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Cash does not cover this week\'s commitments. The largest is $name, $amount, $days days overdue.',
      one:
          'Cash does not cover this week\'s commitments. The largest is $name, $amount, 1 day overdue.',
    );
    return '$_temp0';
  }

  @override
  String arenaResidue(String amount) {
    return '$amount residue';
  }

  @override
  String get arenaAdjustPayment => 'Adjust payment';

  @override
  String get hudPotionTitle => 'Potion';

  @override
  String get hudVillageTitle => 'Village';

  @override
  String get hudEggTitle => 'Incubating';

  @override
  String get hudEggSheetTitle => 'Incubating monsters';

  @override
  String get hudDropTitle => 'Poison';

  @override
  String get hudTierSemi => 'semi';

  @override
  String get hudTierRegular => 'regular';

  @override
  String get hudTierSuper => 'super';

  @override
  String get hudTierHyper => 'hyper';

  @override
  String get hudUnknown => '—';

  @override
  String get hudNoIncome =>
      'Expected income not calculated yet: schedule your income to see this month\'s ratios.';

  @override
  String hudRatioTimes(String value) {
    return '$value×';
  }

  @override
  String hudRatioOfIncome(String value, String income) {
    return '$value× this month\'s expected income ($income)';
  }

  @override
  String hudIncomeSourcePlanned(String income) {
    return 'Expected income this month: $income, from what you scheduled.';
  }

  @override
  String hudIncomeSourceAverage(String income) {
    return 'Expected income this month: $income, from the last three months\' average.';
  }

  @override
  String hudSlotSemantics(String name, String value, String state) {
    return '$name: $value, $state. Tap for details; long press to open the screen.';
  }

  @override
  String hudSemanticsRatio(String value) {
    return '$value× of income';
  }

  @override
  String hudSemanticsVillagers(int alive, int planned) {
    return '$alive of $planned villagers alive';
  }

  @override
  String get hudSemanticsVillageAlive => 'village standing';

  @override
  String get hudSemanticsVillageFallen => 'village fallen';

  @override
  String get hudSemanticsVillageNone => 'no village';

  @override
  String get hudSemanticsVillageNeedsThree =>
      'village incomplete, fewer than three villagers';

  @override
  String get hudSemanticsEggDanger => 'invoices above income, danger';

  @override
  String get hudSemanticsEggWarning =>
      'invoices at half a month of income, caution';

  @override
  String get hudSemanticsEggCalm => 'invoices within income';

  @override
  String get hudSemanticsEggEmpty => 'no monster incubating';

  @override
  String get hudSemanticsDropActive => 'poison active, open debt';

  @override
  String get hudSemanticsDropClear => 'no poison, no debt';

  @override
  String get hudSemanticsPotionEmpty => 'empty potion';

  @override
  String get hudSemanticsNoIncome => 'expected income not calculated yet';

  @override
  String get hudPotionGame =>
      'The potion is everything you invested, together: capital that works for you and yields with no effort of yours. From half a month of income stored on it earns a class — semi, regular, super and hyper — one more for every extra half month.';

  @override
  String get hudPotionFinance =>
      'Finance: it\'s your invested balance divided by this month\'s expected income — how many months of bills it already covers. Emergency money and goal money add up together: one is for what you did not see coming, the other for what you already planned (a trip, a purchase), and both do the same job — keeping the day-to-day bills untouched.';

  @override
  String get hudPotionXp =>
      'XP: none; the potion follows from what you saved — and it only really grows once the poison is gone, because debt interest runs faster than any yield. When the income it generates pays your expenses, the battle is over: that is financial independence.';

  @override
  String hudPotionMonths(int count, String months) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$months months standing',
      one: '$months month standing',
    );
    return '$_temp0';
  }

  @override
  String get hudPotionEmpty =>
      'No investment account with a balance. The potion is empty, and without it every month starts from zero.';

  @override
  String get hudVillageGame =>
      'Every budgeted category is a villager, and its HP is what\'s left of the month. Spend past the budget and the villager falls. An INVESTMENT category works the other way around: there the villager only stands if you invest what you planned, and stays at risk while anything is missing.';

  @override
  String get hudVillageFinance =>
      'Finance: it\'s your per-category limit against what you actually spent this month.';

  @override
  String get hudVillageXp =>
      'XP: +15 per villager standing at month end, up to 10 categories, plus 100 if the whole village holds. An investment villager counts as standing once its goal is met.';

  @override
  String get hudVillageGameBusiness =>
      'Every budgeted cost center is a villager, and its HP is what\'s left of the month. Spend past the budget and the villager falls. An INVESTMENT cost center works the other way around: there the villager only stands if the company invests what it planned, and stays at risk while anything is missing.';

  @override
  String get hudVillageFinanceBusiness =>
      'Finance: it\'s your per-cost-center limit against what the company actually spent this month.';

  @override
  String get hudVillageEmpty =>
      'No category has a budget this month. Set a limit and the village is born.';

  @override
  String get hudVillageEmptyBusiness =>
      'No cost center has a budget this month. Set a limit and the village is born.';

  @override
  String hudVillageAliveCount(int alive, int planned) {
    return '$alive of $planned standing';
  }

  @override
  String hudVillageEnvelopeExpense(String actual, String planned) {
    return 'Expenses: $actual of $planned';
  }

  @override
  String hudVillageEnvelopeInvestment(String actual, String planned) {
    return 'Investments: $actual of $planned';
  }

  @override
  String get hudVillageAtRisk =>
      'The village is at risk: expenses fit, but the investment is short.';

  @override
  String get hudSemanticsVillageAtRisk => 'village at risk, investment short';

  @override
  String get hudVillageAlive => 'The village holds: the total fits the plan.';

  @override
  String get hudVillageFallen =>
      'The village fell: spending went past the plan.';

  @override
  String get hudVillageNeedsThree =>
      'The village only counts with three villagers or more.';

  @override
  String hudProjectedXp(int xp) {
    return 'If the month closed now: +$xp XP';
  }

  @override
  String hudVillagerGoal(String actual, String planned) {
    return '$actual of $planned invested';
  }

  @override
  String hudVillagerMissing(String actual, String planned, String missing) {
    return '$actual of $planned invested — $missing short of standing up';
  }

  @override
  String hudVillageAtRiskGroup(int count) {
    return 'At risk ($count)';
  }

  @override
  String hudVillagerHp(String hp, String planned) {
    return '$hp of $planned';
  }

  @override
  String hudVillagerOver(String amount) {
    return '$amount past the budget';
  }

  @override
  String hudVillageAliveGroup(int count) {
    return 'Standing ($count)';
  }

  @override
  String hudVillageFallenGroup(int count) {
    return 'Fallen ($count)';
  }

  @override
  String hudVillagerSemantics(String name, String state) {
    return '$name: $state';
  }

  @override
  String get hudUnprotectedTitle => 'Unprotected';

  @override
  String get hudUnprotectedHint =>
      'Spending with no budget. It loses nothing, and it earns no XP either.';

  @override
  String get hudHistoryTitle => 'Closed months';

  @override
  String get hudHistoryMonthPattern => 'MMM yyyy';

  @override
  String hudHistoryLine(int alive, int planned, int xp) {
    return '$alive of $planned villagers · +$xp XP';
  }

  @override
  String get hudHistoryEmpty => 'No month closed yet.';

  @override
  String get hudEggGame =>
      'Every credit card expense strengthens a monster that hatches next month. The more you incubate, the bigger the creature that comes to collect.';

  @override
  String get hudEggFinance =>
      'Finance: it\'s the sum of your upcoming card bills divided by this month\'s expected income. A bill you expect is an expense; a bill you forget is a nasty surprise.';

  @override
  String get hudEggXp =>
      'XP: none; the monster takes no XP, but unplanned card spending eats the money that would have become a potion — and the potion is what leads to independence.';

  @override
  String get hudEggEmpty => 'No upcoming bill. There is no monster incubating.';

  @override
  String hudCardLimitLabel(String name) {
    return '$name limit';
  }

  @override
  String hudCardLimitUsage(int percent) {
    return '$percent% of the limit used';
  }

  @override
  String hudCardLimitFree(String amount) {
    return '$amount until the limit';
  }

  @override
  String hudCardLimitOver(String amount) {
    return '$amount over the limit';
  }

  @override
  String get hudCardLimitUnknown => 'No credit limit set for this card.';

  @override
  String hudInvoiceOverdue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Overdue by $days days',
      one: 'Overdue by 1 day',
    );
    return '$_temp0';
  }

  @override
  String hudInvoiceClosed(String closing, String due) {
    return 'Closed $closing · due $due';
  }

  @override
  String hudInvoiceOpen(String closing, String due) {
    return 'Open cycle · closes $closing · due $due';
  }

  @override
  String get hudDropGame =>
      'Debt is poison: interest corrodes your capital without pause and drags the hero\'s HP down every month.';

  @override
  String get hudDropFinance =>
      'Finance: it\'s your outstanding debt divided by this month\'s expected income. Untreated, interest eats first what would have been your wealth.';

  @override
  String get hudDropXp =>
      'XP: none directly; paying it off earns XP through planned entries paid and through payoff goals. Neutralizing the poison is the first step to financial independence.';

  @override
  String get hudDropEmpty =>
      'No open debt. The poison is neutralized, and what you earn is yours.';

  @override
  String hudDebtInstallment(String amount, String date) {
    return 'Installment $amount · due $date';
  }

  @override
  String get hudDebtNoInstallment =>
      'No installment scheduled in the next 60 days.';
}
