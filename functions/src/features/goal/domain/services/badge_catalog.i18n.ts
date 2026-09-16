/**
 * Nomes e descrições dos badges em INGLÊS.
 *
 * O catálogo publicado em `config/badges` carrega os textos por locale
 * (`{pt, en}`) e o app escolhe pelo idioma do usuário, com fallback para `pt`.
 * O português vive junto da definição do badge, em `BADGES`; o inglês vive
 * aqui porque é tradução, não regra — e é exatamente o conjunto de strings que
 * saiu dos ARB do app quando o catálogo virou responsabilidade do servidor.
 *
 * Um badge SEM entrada aqui é publicado só em português: o app cai no
 * fallback e mostra o texto em pt, em vez de mostrar vazio.
 */
export const BADGE_STRINGS_EN: Record<string, { name: string; description: string }> = {
    first_step: {
        name: "First Step",
        description: "The workspace is created and onboarding is successfully completed.",
    },
    first_account: {
        name: "First Account",
        description: "The first bank account or card is registered in the workspace.",
    },
    first_transaction: {
        name: "Starting Point",
        description: "The first real transaction (installment) is recorded with paid status.",
    },
    planner: {
        name: "Strategic Planner",
        description: "Planning limits are created for at least 5 categories.",
    },
    reconcile_junior: {
        name: "Junior Reconciler",
        description: "The first successful bank reconciliation is completed (at least 1 confirmed match).",
    },
    cash_detective: {
        name: "Cash Detective",
        description: "Full reconciliation of a statement containing at least 10 transactions.",
    },
    reconcile_master: {
        name: "Reconciliation Master",
        description: "The workspace accumulates 10 successfully completed statement reconciliations.",
    },
    zero_friction: {
        name: "Zero Friction",
        description: "Reconcile an entire monthly statement without needing to create extra manual transactions.",
    },
    savings_seed: {
        name: "Savings Seed",
        description: "The first goal registered in the workspace reaches 100% progress.",
    },
    goal_bronze: {
        name: "Goal Collector",
        description: "The workspace successfully completes 3 different financial goals.",
    },
    goal_silver: {
        name: "Unwavering Focus",
        description: "The workspace successfully completes 5 different financial goals.",
    },
    under_control: {
        name: "All Under Control",
        description: "Close the month without exceeding any planned category in the 50-30-20 rule.",
    },
    golden_rule: {
        name: "Golden Rule",
        description: "Allocate limits in all 3 pools (Essential, Comfort, Investment) in the same month.",
    },
    future_focus: {
        name: "Future Focus",
        description: "Effectively save and invest at least 20% of the total workspace revenues in the month.",
    },
    cost_cutter: {
        name: "Cost Cutter",
        description: "Reduce total expenses of the Comfort pool (discretionary) by 20% compared to the previous month.",
    },
    united_front: {
        name: "United Front",
        description: "Workspace with 3 or more active members added and accepted.",
    },
    iron_consistency: {
        name: "Iron Consistency",
        description: "Successfully complete weekly missions for 4 consecutive weeks.",
    },
    first_category: {
        name: "Organizer",
        description: "Create the first custom category in the workspace.",
    },
    first_planning: {
        name: "Rookie Planner",
        description: "Create the first category planning with a defined budget.",
    },
    first_goal: {
        name: "Dreamer",
        description: "Create the first financial goal in the workspace.",
    },
    first_invite: {
        name: "Host",
        description: "Invite the first member to the workspace.",
    },
    profile_complete: {
        name: "Complete Profile",
        description: "Set the workspace name and type.",
    },
    first_income: {
        name: "Income Recorded",
        description: "Record the first paid income in the workspace.",
    },
    first_expense: {
        name: "Expense Recorded",
        description: "Record the first paid expense in the workspace.",
    },
    first_transfer: {
        name: "Transferrer",
        description: "Record the first transfer between accounts.",
    },
    workspace_named: {
        name: "Own Identity",
        description: "Give a custom name to the workspace.",
    },
    first_month: {
        name: "First Month",
        description: "Have at least one transaction in a full calendar month.",
    },
    five_transactions: {
        name: "Active!",
        description: "Record 5 paid transactions in total.",
    },
    twenty_transactions: {
        name: "Committed",
        description: "Record 20 paid transactions in total.",
    },
    fifty_transactions: {
        name: "Veteran",
        description: "Record 50 paid transactions in total.",
    },
    hundred_transactions: {
        name: "Centurion",
        description: "Record 100 paid transactions in total.",
    },
    week_complete: {
        name: "Full Week",
        description: "Record at least one transaction on 7 consecutive days.",
    },
    two_accounts: {
        name: "Multi-Account",
        description: "Register 2 accounts in the workspace.",
    },
    three_accounts: {
        name: "Manager",
        description: "Register 3 accounts in the workspace.",
    },
    five_accounts: {
        name: "Portfolio",
        description: "Register 5 accounts in the workspace.",
    },
    five_categories: {
        name: "Categorized",
        description: "Create at least 5 categories.",
    },
    ten_categories: {
        name: "Category Master",
        description: "Create at least 10 categories.",
    },
    round_number: {
        name: "Round Number",
        description: "Record a transaction with an exact amount, no cents.",
    },
    big_transaction: {
        name: "Big Deal",
        description: "Record a single transaction above R$ 1,000.",
    },
    small_transactions_ten: {
        name: "Meticulous Detail",
        description: "Record 10 transactions each under R$ 10.",
    },
    income_registered: {
        name: "Well Documented",
        description: "Record at least one income in the workspace.",
    },
    expense_under_income: {
        name: "Positive Balance",
        description: "Close the month with expenses lower than income.",
    },
    three_categories_month: {
        name: "Diversified",
        description: "Have spending in 3 different categories in the same month.",
    },
    five_categories_month: {
        name: "Comprehensive",
        description: "Have spending in 5 different categories in the same month.",
    },
    savings_10pct: {
        name: "Rookie Saver",
        description: "Save at least 10% of total monthly income.",
    },
    savings_start: {
        name: "First Cent",
        description: "Make the first deposit in any financial goal.",
    },
    no_credit_debt: {
        name: "Interest Free",
        description: "Close the month without any open credit card invoices.",
    },
    goal_halfway: {
        name: "Halfway There",
        description: "A financial goal reaches 50% of its target amount.",
    },
    goal_75pct: {
        name: "Almost There",
        description: "A financial goal reaches 75% of its target amount.",
    },
    goal_under_deadline: {
        name: "On Time",
        description: "Complete a goal before its established deadline.",
    },
    two_active_goals: {
        name: "Ambitious",
        description: "Have 2 active goals at the same time.",
    },
    five_active_goals: {
        name: "Multitasker",
        description: "Have 5 active goals at the same time.",
    },
    long_term_goal: {
        name: "Long-Term Vision",
        description: "Create a goal with a deadline more than 12 months away.",
    },
    short_term_goal: {
        name: "Financial Sprint",
        description: "Complete a goal in less than 30 days.",
    },
    goal_deposit: {
        name: "First Deposit",
        description: "Make the first deposit into a financial goal.",
    },
    goal_debt_paid: {
        name: "Debt Free",
        description: "Complete a goal of type 'Pay Off Debt'.",
    },
    goal_linked_account: {
        name: "Linked Goal",
        description: "Create a goal linked to a bank account.",
    },
    second_member: {
        name: "Dynamic Duo!",
        description: "A second member accepts the invitation to the workspace.",
    },
    reconcile_second: {
        name: "Frequent Reconciler",
        description: "Complete the second bank reconciliation.",
    },
    reconcile_five: {
        name: "Skilled Reconciler",
        description: "Complete 5 bank reconciliations in total.",
    },
    mission_first: {
        name: "First Mission",
        description: "Complete the first weekly mission.",
    },
    mission_three: {
        name: "Financial Triathlete",
        description: "Complete 3 weekly missions in total.",
    },
    planning_month: {
        name: "Monthly Planner",
        description: "Create a budget for at least 5 categories in the month.",
    },
    two_months_active: {
        name: "Consistent",
        description: "Record transactions in 2 different months.",
    },
    workspace_one_year: {
        name: "Anniversary!",
        description: "The workspace completes 1 year of existence.",
    },
    invite_accepted: {
        name: "Welcome to the Team",
        description: "Accept an invitation to join a workspace.",
    },
    all_missions_week: {
        name: "Perfect Week",
        description: "Complete all available weekly missions in one week.",
    },
};
