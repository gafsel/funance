/**
 * wp/missions-by-type — geração e progresso das missões semanais por TIPO de
 * workspace.
 *
 * O caso que originou o pacote: um workspace de EMPRESA recebeu "Reduzir
 * gastos com alimentação". Os testes aqui cobrem as duas metades da correção —
 * a geração (catálogo determinístico, IA só como tempero validado) e o avanço
 * do progresso por `progressRule`, inclusive as regras corporativas novas.
 */

import { GamificationService } from "../features/goal/domain/services/gamification.service";
import {
    AUDIENCE_FORBIDDEN_TERMS,
    buildMissionName,
    findMissionTemplate,
    normalizeTerm,
    selectMissionTemplate,
} from "../features/goal/domain/models/mission_catalog";
import { WeeklyMissionWrite } from "../features/goal/domain/repositories/gamification.repository";
import { CategoryType } from "../features/workspace/domain/models/category.model";

/** Terça 2026-08-11 12:00 em São Paulo — semana 2026-W32 (domingo 09/08). */
const TUESDAY = new Date("2026-08-11T15:00:00Z");
/** Sábado da mesma semana: 6 dias inteiros decorridos. */
const SATURDAY = new Date("2026-08-15T15:00:00Z");
const WEEK_ID = "2026-W32";

interface FakeRepoOptions {
    workspaceType?: string;
    plannings?: any[];
    paidInstallments?: any[];
    weeklySummary?: any[];
    reconciledStatements?: number;
    automaticTransactions?: any[];
    /** A peneira de CAPACIDADE (default: tudo presente). */
    capacity?: {
        hasCreditCardAccount: boolean;
        hasReconciledStatementEver: boolean;
        hasRecentAutomaticTransaction: boolean;
    };
    /** Missões pré-existentes, por tipo. */
    missions?: Record<string, any>;
}

function buildRepository(options: FakeRepoOptions = {}) {
    const missions: Record<string, any> = { ...(options.missions ?? {}) };
    const created: WeeklyMissionWrite[] = [];
    const updates: Array<{ type: string; data: any }> = [];
    const completions: Array<{ type: string; progress: number; rewardXp: number }> = [];

    const repository = {
        getWorkspaceById: jest.fn().mockResolvedValue({ id: "w1", type: options.workspaceType ?? "personal" }),
        addXp: jest.fn(),
        unlockBadge: jest.fn(),
        getAccountsCount: jest.fn(),
        hasPaidTransaction: jest.fn(),
        getCategoryPlannings: jest.fn().mockResolvedValue(options.plannings ?? []),
        getCompletedReconciliationsCount: jest.fn(),
        getGoals: jest.fn().mockResolvedValue([]),
        getPaidInstallmentsInPeriod: jest.fn().mockResolvedValue(options.paidInstallments ?? []),
        getWeeklyMission: jest.fn(async (_w: string, _week: string, type: string) => missions[type] ?? null),
        createWeeklyMission: jest.fn(async (_w: string, _week: string, type: string, data: WeeklyMissionWrite) => {
            created.push(data);
            missions[type] = { ...data };
        }),
        updateWeeklyMission: jest.fn(async (_w: string, _week: string, type: string, data: any) => {
            updates.push({ type, data });
            missions[type] = { ...missions[type], ...data };
        }),
        getWeeklyMissionsByWeek: jest.fn().mockResolvedValue([]),
        updateWorkspaceStreaks: jest.fn(),
        getPeriodSummaries: jest.fn().mockResolvedValue([]),
        getCategoriesCount: jest.fn(),
        getPaidInstallments: jest.fn().mockResolvedValue([]),
        getPaidInstallmentsSince: jest.fn().mockResolvedValue([]),
        completeMissionAndAwardXp: jest.fn(async (_w: string, _week: string, type: string, progress: number, rewardXp: number) => {
            completions.push({ type, progress, rewardXp });
            missions[type] = { ...missions[type], status: "completed", progress };
            return true;
        }),
        getPaidInstallmentsCount: jest.fn().mockResolvedValue(0),
        getCompletedMissionsCount: jest.fn().mockResolvedValue(0),
        getCreditCardAccountIds: jest.fn().mockResolvedValue([]),
        hasPendingInstallmentsForAccounts: jest.fn().mockResolvedValue(false),
        getWeeklySummaryRows: jest.fn().mockResolvedValue(options.weeklySummary ?? []),
        awardXpOnce: jest.fn(),
        getCompletedReconciliationsInPeriod: jest.fn().mockResolvedValue(options.reconciledStatements ?? 0),
        getAutomaticTransactions: jest.fn().mockResolvedValue(options.automaticTransactions ?? []),
        // Capacidade CHEIA por padrão: estes testes medem o catálogo e o
        // avanço, não a peneira (que tem os seus, em mission_catalog.test.ts).
        getMissionCapacity: jest.fn().mockResolvedValue(options.capacity ?? {
            hasCreditCardAccount: true,
            hasReconciledStatementEver: true,
            hasRecentAutomaticTransaction: true,
        }),
    };

    return { repository, created, updates, completions, missions };
}

/**
 * Uma linha do `period_summaries` semanal, nos DOIS formatos (double e
 * centavos), como o repositório a entrega.
 */
function summaryRow(
    categoryId: string,
    type: CategoryType,
    values: { general?: number; specific?: number; actual?: number; isSystem?: boolean }
) {
    const general = values.general ?? 0;
    const specific = values.specific ?? 0;
    const actual = values.actual ?? 0;
    return {
        categoryId,
        type,
        isSystem: values.isSystem ?? false,
        generalPlannedAmount: general,
        specificPlannedAmount: specific,
        actualAmount: actual,
        generalPlannedAmountCents: Math.round(general * 100),
        specificPlannedAmountCents: Math.round(specific * 100),
        actualAmountCents: Math.round(actual * 100),
    };
}

/**
 * O retrato REAL do workspace a70134c1 na semana 2026-W37, que é o que
 * reprovou a primeira versão: a receita prevista vive no `specific`
 * (R$ 15.850), o `general` da categoria de receita é zero, e só 24% entrou.
 */
const PRODUCAO_W37 = [
    summaryRow("servicos", CategoryType.income, { general: 0, specific: 15850, actual: 3850 }),
    summaryRow("custos", CategoryType.expense, { general: 4553.5, specific: 0, actual: 123.92 }),
];

/** Uma missão já gravada com o template indicado, pronta para avançar. */
function existingMission(templateKey: string, overrides: Record<string, unknown> = {}) {
    const template = findMissionTemplate(templateKey)!;
    return {
        id: template.type,
        type: template.type,
        name: buildMissionName(template, "pt", { target: template.target }),
        status: "pending",
        progress: 0,
        target: template.target,
        rewardXp: template.rewardXp,
        weekId: WEEK_ID,
        templateKey: template.key,
        workspaceType: template.audience,
        actionPath: template.actionPath,
        nameKey: template.nameKey,
        ...overrides,
    };
}

afterEach(() => {
    jest.useRealTimers();
});

describe("geração — o catálogo decide o objetivo, por tipo de workspace", () => {
    it("empresa recebe as missões corporativas da semana, com o contrato novo", async () => {
        jest.useFakeTimers({ now: TUESDAY });
        const { repository, created } = buildRepository({
            workspaceType: "business",
            plannings: [
                { amount: 9000, category: { name: "Marketing" }, startMonth: "2026-01", endMonth: "2026-12" },
                { amount: 1200, category: { name: "Software" }, startMonth: "2026-01", endMonth: "2026-12" },
            ],
        });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "planning", {});

        expect(created).toHaveLength(3);
        for (const mission of created) {
            const template = selectMissionTemplate("business", mission.type, WEEK_ID)!;
            expect(mission.templateKey).toBe(template.key);
            expect(mission.workspaceType).toBe("business");
            expect(mission.actionPath).toBe(template.actionPath);
            expect(mission.nameKey).toBe(template.nameKey);
            expect(mission.target).toBe(template.target);
            expect(mission.rewardXp).toBe(template.rewardXp);
        }
    });

    it("nenhuma missão de empresa fala de alimentação, lazer ou vida pessoal", async () => {
        jest.useFakeTimers({ now: TUESDAY });
        const { repository, created } = buildRepository({
            workspaceType: "business",
            plannings: [{ amount: 500, category: { name: "Marketing" }, startMonth: "2026-01", endMonth: "2026-12" }],
        });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "planning", {});

        for (const mission of created) {
            const text = normalizeTerm(mission.name);
            for (const term of AUDIENCE_FORBIDDEN_TERMS.business) {
                expect(text).not.toContain(term);
            }
        }
    });

    it("workspace sem tipo é tratado como pessoal (documento legado)", async () => {
        jest.useFakeTimers({ now: TUESDAY });
        const { repository, created } = buildRepository({ workspaceType: undefined, plannings: [] });
        // `getWorkspaceById` sem `type`.
        repository.getWorkspaceById.mockResolvedValue({ id: "w1" });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "planning", {});

        expect(created.every((m) => m.workspaceType === "personal")).toBe(true);
    });

    it("sem categoria planejada o nome cai no fallback, não num {category} vazio", async () => {
        jest.useFakeTimers({ now: TUESDAY });
        const { repository, created } = buildRepository({ workspaceType: "personal", plannings: [] });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "planning", {});

        const discipline = created.find((m) => m.type === "discipline")!;
        expect(discipline.name).not.toContain("{");
        expect(discipline.name).toContain("de maior gasto");
        // E, principalmente, não inventa "Alimentação" como o código antigo.
        expect(normalizeTerm(discipline.name)).not.toContain("alimentacao");
    });
});

describe("geração — a IA só tempera, e só se referenciar o template", () => {
    function aiRepository(response: Record<string, any>) {
        return {
            generateWeeklyMissions: jest.fn(async (_w: string, _t: string, _c: string[], _g: string[], expectations: any[]) => {
                const out: any = { consistency: null, discipline: null, organization: null };
                for (const e of expectations) {
                    const item = response[e.type];
                    if (item) out[e.type] = item;
                }
                return out;
            }),
        };
    }

    it("usa o texto da IA quando ele passa na validação", async () => {
        jest.useFakeTimers({ now: TUESDAY });
        const { repository, created } = buildRepository({ workspaceType: "personal", plannings: [] });
        const ai = aiRepository({ consistency: { name: "Dar um limite a 3 categorias nesta semana.", target: 3 } });
        const service = new GamificationService(repository as any, ai as any);

        await service.updateWeeklyMissionsProgress("w1", "planning", {});

        expect(created.find((m) => m.type === "consistency")!.name)
            .toBe("Dar um limite a 3 categorias nesta semana.");
    });

    it("cai no texto do catálogo quando a IA devolve null (validação recusou)", async () => {
        jest.useFakeTimers({ now: TUESDAY });
        const { repository, created } = buildRepository({ workspaceType: "business", plannings: [] });
        const ai = aiRepository({});
        const service = new GamificationService(repository as any, ai as any);

        await service.updateWeeklyMissionsProgress("w1", "planning", {});

        for (const mission of created) {
            const template = selectMissionTemplate("business", mission.type, WEEK_ID)!;
            expect(mission.name).toBe(buildMissionName(template, "pt", { target: template.target }));
        }
    });

    it("manda para a IA o template escolhido, a audiência e o vocabulário proibido", async () => {
        jest.useFakeTimers({ now: TUESDAY });
        const { repository } = buildRepository({ workspaceType: "business", plannings: [] });
        const ai = aiRepository({});
        const service = new GamificationService(repository as any, ai as any);

        await service.updateWeeklyMissionsProgress("w1", "planning", {});

        const [, workspaceType, , , expectations] = ai.generateWeeklyMissions.mock.calls[0];
        expect(workspaceType).toBe("business");
        expect(expectations).toHaveLength(3);
        for (const expectation of expectations as any[]) {
            const template = selectMissionTemplate("business", expectation.type, WEEK_ID)!;
            expect(expectation.templateKey).toBe(template.key);
            expect(expectation.target).toBe(template.target);
            expect(expectation.forbiddenTerms).toEqual(AUDIENCE_FORBIDDEN_TERMS.business);
        }
    });

    it("só a missão que recebeu a categoria ganha licença para citá-la", async () => {
        jest.useFakeTimers({ now: TUESDAY });
        const { repository } = buildRepository({
            workspaceType: "business",
            // Um centro de custo REAL chamado "Alimentação" (vale-refeição).
            plannings: [
                { amount: 9000, category: { name: "Alimentação" }, startMonth: "2026-01", endMonth: "2026-12" },
            ],
        });
        const ai = aiRepository({});
        const service = new GamificationService(repository as any, ai as any);

        await service.updateWeeklyMissionsProgress("w1", "planning", {});

        const expectations = ai.generateWeeklyMissions.mock.calls[0][4] as any[];
        for (const expectation of expectations) {
            const template = findMissionTemplate(expectation.templateKey)!;
            if (template.params.includes("category")) {
                expect(expectation.dataValues).toEqual(["Alimentação"]);
            }
            else {
                // Passar o nome às três abriria licença para a missão de
                // conciliação dizer "alimentação" só porque existe um centro
                // de custo com esse nome — que é o texto que o pacote barra.
                expect(expectation.dataValues).toEqual([]);
            }
        }
    });

    it("a falha da IA não impede a semana de ter missão", async () => {
        jest.useFakeTimers({ now: TUESDAY });
        const { repository, created } = buildRepository({ workspaceType: "business", plannings: [] });
        const ai = { generateWeeklyMissions: jest.fn().mockRejectedValue(new Error("503")) };
        const service = new GamificationService(repository as any, ai as any);

        await service.updateWeeklyMissionsProgress("w1", "planning", {});

        expect(created).toHaveLength(3);
    });
});

describe("progresso — regras corporativas", () => {
    it("reconciled_statements conta os extratos concluídos na semana", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const { repository, completions } = buildRepository({
            workspaceType: "business",
            reconciledStatements: 2,
            missions: {
                consistency: { status: "completed" },
                discipline: { status: "completed" },
                organization: existingMission("business_organization_reconcile_statements"),
            },
        });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "reconciliation", { status: "completed" });

        expect(completions).toEqual([
            { type: "organization", progress: 2, rewardXp: 200 },
        ]);
        const [, start, end] = repository.getCompletedReconciliationsInPeriod.mock.calls[0];
        expect(start.toISOString()).toBe("2026-08-09T03:00:00.000Z");
        expect(end.toISOString()).toBe("2026-08-16T02:59:59.999Z");
    });

    it("categorized_auto_transactions só conta o que a equipe RESOLVEU, na semana", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const { repository, updates } = buildRepository({
            workspaceType: "business",
            automaticTransactions: [
                // Resolvidos dentro da semana.
                { id: "a", date: "2026-08-10T15:00:00.000Z", isConsolidated: true, isIgnored: false },
                { id: "b", date: "2026-08-12T15:00:00.000Z", isConsolidated: false, isIgnored: true },
                // Ainda na caixa de entrada: a sugestão da IA não vale progresso.
                { id: "c", date: "2026-08-12T15:00:00.000Z", isConsolidated: false, isIgnored: false },
                // Resolvido, mas de outra semana.
                { id: "d", date: "2026-08-01T15:00:00.000Z", isConsolidated: true, isIgnored: false },
                // Sem data legível.
                { id: "e", date: null, isConsolidated: true, isIgnored: false },
            ],
            missions: {
                consistency: { status: "completed" },
                discipline: { status: "completed" },
                organization: existingMission("business_organization_categorize_auto"),
            },
        });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "transaction", {});

        expect(updates).toEqual([
            { type: "organization", data: { progress: 2, status: "pending" } },
        ]);
    });

    describe("categorized_week_installments — a missão que SEMPRE dá para cumprir", () => {
        function organizationWeekMissions(paidInstallments: any[]) {
            return buildRepository({
                workspaceType: "business",
                paidInstallments,
                missions: {
                    consistency: { status: "completed" },
                    discipline: { status: "completed" },
                    organization: existingMission("business_organization_categorize_week", { target: 100 }),
                },
            });
        }

        it("mede o PERCENTUAL das parcelas pagas da semana que têm categoria", async () => {
            jest.useFakeTimers({ now: SATURDAY });
            const { repository, updates } = organizationWeekMissions([
                { status: "paid", type: "expense", category: { id: "c1", name: "Custos" } },
                { status: "paid", type: "expense", category: { id: "c2", name: "Serviços" } },
                // Sem categoria utilizável — o defeito que o fix_empty_category repara.
                { status: "paid", type: "expense", category: { id: "", name: "Mercado" } },
                { status: "paid", type: "income", category: null },
            ]);
            const service = new GamificationService(repository as any);

            await service.updateWeeklyMissionsProgress("w1", "transaction", {});

            // 2 de 4 = 50%.
            expect(updates).toEqual([
                { type: "organization", data: { progress: 50, status: "pending" } },
            ]);
        });

        it("TRANSFERÊNCIA fica fora da conta: ela não tem categoria por desenho", async () => {
            jest.useFakeTimers({ now: SATURDAY });
            const { repository, completions } = organizationWeekMissions([
                { status: "paid", type: "expense", category: { id: "c1", name: "Custos" } },
                // Transferência e fatura (que é transferência): sem categoria,
                // e contá-las deixaria os 100% inalcançáveis.
                { status: "paid", type: "transfer", category: null },
                { status: "paid", type: "transfer", isInvoice: true, category: null },
                // Removida também não conta.
                { status: "removed", type: "expense", category: null },
            ]);
            const service = new GamificationService(repository as any);

            await service.updateWeeklyMissionsProgress("w1", "transaction", {});

            expect(completions).toEqual([
                { type: "organization", progress: 100, rewardXp: 200 },
            ]);
        });

        it("semana SEM parcela a categorizar não move nem conclui a missão", async () => {
            jest.useFakeTimers({ now: SATURDAY });
            const { repository, updates, completions } = organizationWeekMissions([
                { status: "paid", type: "transfer", category: null },
            ]);
            const service = new GamificationService(repository as any);

            await service.updateWeeklyMissionsProgress("w1", "transaction", {});

            // Nada a medir: o progresso gravado fica como está, em vez de um
            // 100% que ninguém conquistou.
            expect(updates).toEqual([]);
            expect(completions).toEqual([]);
        });

        /**
         * O CUSTO da regra depende da DISCIPLINA sorteada para a mesma semana,
         * porque `readPaidInstallments` é memoizado por AVALIAÇÃO:
         *
         *  - `days_within_category_limit` já lê as parcelas → custo zero;
         *  - `weekly_margin_above_plan` lê o sumário → custo de uma consulta.
         *
         * Os dois casos abaixo provam as duas situações. Em nenhuma delas
         * entra fonte de dados NOVA no caminho de avaliação.
         */
        function repositoryWith(disciplineTemplateKey: string) {
            return buildRepository({
                workspaceType: "business",
                plannings: [{
                    amount: 700,
                    startMonth: "2026-08",
                    category: { id: "custos", name: "Custos", type: "expense" },
                }],
                paidInstallments: [
                    { status: "paid", type: "expense", category: { id: "c1", name: "Custos" } },
                ],
                weeklySummary: [],
                missions: {
                    consistency: { status: "completed" },
                    discipline: existingMission(disciplineTemplateKey),
                    organization: existingMission("business_organization_categorize_week", { target: 100 }),
                },
            });
        }

        it("com a disciplina que JÁ lê as parcelas, não custa leitura nenhuma", async () => {
            jest.useFakeTimers({ now: SATURDAY });
            const { repository } = repositoryWith("business_discipline_top_cost_center");
            const service = new GamificationService(repository as any);

            await service.updateWeeklyMissionsProgress("w1", "transaction", {});

            // UMA consulta de parcelas para as DUAS missões (memoizada).
            expect(repository.getPaidInstallmentsInPeriod).toHaveBeenCalledTimes(1);
        });

        it("com a disciplina de MARGEM, custa UMA consulta de parcelas — e só", async () => {
            jest.useFakeTimers({ now: SATURDAY });
            const { repository } = repositoryWith("business_discipline_margin");
            const service = new GamificationService(repository as any);

            await service.updateWeeklyMissionsProgress("w1", "transaction", {});

            // A margem lê o sumário; as parcelas são a consulta que a
            // organização acrescenta. Uma, nunca duas.
            expect(repository.getWeeklySummaryRows).toHaveBeenCalledTimes(1);
            expect(repository.getPaidInstallmentsInPeriod).toHaveBeenCalledTimes(1);
        });

        it("não acrescenta fonte de dados nova ao caminho de avaliação", async () => {
            jest.useFakeTimers({ now: SATURDAY });
            const { repository } = organizationWeekMissions([
                { status: "paid", type: "expense", category: { id: "c1", name: "Custos" } },
            ]);
            const service = new GamificationService(repository as any);

            await service.updateWeeklyMissionsProgress("w1", "transaction", {});

            expect(repository.getPaidInstallmentsInPeriod).toHaveBeenCalledTimes(1);
            expect(repository.getAutomaticTransactions).not.toHaveBeenCalled();
            expect(repository.getCompletedReconciliationsInPeriod).not.toHaveBeenCalled();
        });
    });

    it("invoice_paid_on_time compara o DIA do pagamento com o do vencimento", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const { repository, completions } = buildRepository({
            workspaceType: "business",
            paidInstallments: [
                // Fatura paga às 18h do próprio dia do vencimento (que é gravado
                // ao meio-dia): CONTA.
                {
                    status: "paid", isInvoice: true,
                    dueDate: new Date("2026-08-12T15:00:00Z"),
                    paidDate: new Date("2026-08-12T21:00:00Z"),
                },
                // Fatura paga depois do vencimento: não conta.
                {
                    status: "paid", isInvoice: true,
                    dueDate: new Date("2026-08-10T15:00:00Z"),
                    paidDate: new Date("2026-08-13T15:00:00Z"),
                },
                // Compra comum paga no prazo: não é fatura.
                {
                    status: "paid", isInvoice: false,
                    dueDate: new Date("2026-08-12T15:00:00Z"),
                    paidDate: new Date("2026-08-11T15:00:00Z"),
                },
            ],
            missions: {
                consistency: { status: "completed" },
                discipline: { status: "completed" },
                organization: existingMission("business_organization_invoice_on_time"),
            },
        });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "transaction", {});

        expect(completions).toEqual([{ type: "organization", progress: 1, rewardXp: 200 }]);
    });

    it("weekly_margin_above_plan usa o sumário semanal e ignora categoria de sistema", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const summary = [
            summaryRow("i1", CategoryType.income, { specific: 12000, actual: 12000 }),
            summaryRow("e1", CategoryType.expense, { general: 8000, actual: 7000 }),
            // Saldo inicial: fora da conta, senão a margem seria fabricada.
            summaryRow("sys", CategoryType.income, { specific: 0, actual: 500000, isSystem: true }),
        ];
        const { repository, completions } = buildRepository({
            workspaceType: "business",
            weeklySummary: summary,
            missions: {
                consistency: { status: "completed" },
                discipline: existingMission("business_discipline_margin"),
                organization: { status: "completed" },
            },
        });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "transaction", {});

        // Planejado 12000-8000 = 4000; realizado 12000-7000 = 5000.
        expect(completions).toEqual([{ type: "discipline", progress: 1, rewardXp: 250 }]);
    });

    it("weekly_margin_above_plan NÃO conclui com os números reais de 2026-W37", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const { repository, completions, updates } = buildRepository({
            workspaceType: "business",
            weeklySummary: PRODUCAO_W37,
            missions: {
                consistency: { status: "completed" },
                discipline: existingMission("business_discipline_margin"),
                organization: { status: "completed" },
            },
        });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "transaction", {});

        // Margem planejada 15850 − 4553,50 = 11296,50; realizada
        // 3850 − 123,92 = 3726,08. A empresa recebeu 24% do que previa — a
        // versão anterior lia receita prevista ZERO, comparava com uma margem
        // planejada NEGATIVA (−4553,50) e pagava 250 XP por isso.
        expect(completions).toEqual([]);
        expect(updates).toEqual([]);
    });

    it("weekly_margin_above_plan exige os DOIS lados do plano", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        for (const summary of [
            // Só despesa planejada: era o caso que escapava da guarda antiga.
            [summaryRow("e1", CategoryType.expense, { general: 4553.5, actual: 123.92 })],
            // Só receita planejada.
            [summaryRow("i1", CategoryType.income, { specific: 15850, actual: 15850 })],
        ]) {
            const { repository, completions, updates } = buildRepository({
                workspaceType: "business",
                weeklySummary: summary,
                missions: {
                    consistency: { status: "completed" },
                    discipline: existingMission("business_discipline_margin"),
                    organization: { status: "completed" },
                },
            });
            const service = new GamificationService(repository as any);

            await service.updateWeeklyMissionsProgress("w1", "transaction", {});

            expect(completions).toEqual([]);
            expect(updates).toEqual([]);
        }
    });

    it("income_received_vs_planned lê a receita prevista do specificPlannedAmount", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const { repository, updates } = buildRepository({
            workspaceType: "business",
            weeklySummary: PRODUCAO_W37,
            missions: {
                consistency: existingMission("business_consistency_income_forecast"),
                discipline: { status: "completed" },
                organization: { status: "completed" },
            },
        });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "transaction", {});

        // 3850 / 15850 = 24%. A versão anterior somava o `generalPlannedAmount`
        // da categoria de receita — que é ZERO — e a regra devolvia null para
        // sempre: a missão ficava travada em 0% a semana inteira.
        expect(updates).toEqual([{ type: "consistency", data: { progress: 24, status: "pending" } }]);
    });

    it("income_received_vs_planned conclui quando a receita prevista de fato entra", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const { repository, completions } = buildRepository({
            workspaceType: "business",
            weeklySummary: [
                summaryRow("servicos", CategoryType.income, { general: 0, specific: 15850, actual: 14000 }),
            ],
            missions: {
                consistency: existingMission("business_consistency_income_forecast"),
                discipline: { status: "completed" },
                organization: { status: "completed" },
            },
        });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "transaction", {});

        // 14000 / 15850 = 88% >= 80%.
        expect(completions).toEqual([{ type: "consistency", progress: 88, rewardXp: 150 }]);
    });

    it("a despesa planejada soma o teto da categoria e o que já estava agendado", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const { repository, completions } = buildRepository({
            workspaceType: "business",
            weeklySummary: [
                summaryRow("i1", CategoryType.income, { specific: 10000, actual: 10000 }),
                // Teto de 3000 MAIS 4000 já agendados = 7000 planejados.
                summaryRow("e1", CategoryType.expense, { general: 3000, specific: 4000, actual: 6500 }),
            ],
            missions: {
                consistency: { status: "completed" },
                discipline: existingMission("business_discipline_margin"),
                organization: { status: "completed" },
            },
        });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "transaction", {});

        // Planejado 10000-7000 = 3000; realizado 10000-6500 = 3500.
        expect(completions).toEqual([{ type: "discipline", progress: 1, rewardXp: 250 }]);
    });
});

describe("progresso — regras pessoais e o que mudou", () => {
    it("days_within_category_limit não mede nada sem NENHUM limite (antes inventava R$ 250)", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const { repository, updates, completions } = buildRepository({
            workspaceType: "personal",
            plannings: [],
            missions: {
                consistency: { status: "completed" },
                discipline: existingMission("personal_discipline_top_category"),
                organization: { status: "completed" },
            },
        });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "transaction", {});

        expect(completions).toEqual([]);
        expect(updates).toEqual([]);
    });

    it("reconciled_statement_items continua lendo o EVENTO da conciliação", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const { repository, completions } = buildRepository({
            workspaceType: "personal",
            missions: {
                consistency: { status: "completed" },
                discipline: { status: "completed" },
                organization: existingMission("personal_organization_reconcile_items"),
            },
        });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "reconciliation", {
            status: "completed",
            totalTransactionsProcessed: 9,
        });

        expect(completions).toEqual([{ type: "organization", progress: 9, rewardXp: 200 }]);
    });

    it("missão legada (sem templateKey) continua avançando pela regra pessoal", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const { repository, completions } = buildRepository({
            workspaceType: "personal",
            plannings: [
                { amount: 100, category: { name: "Moradia" }, startMonth: "2026-01", endMonth: "2026-12" },
                { amount: 200, category: { name: "Mercado" }, startMonth: "2026-01", endMonth: "2026-12" },
                { amount: 300, category: { name: "Transporte" }, startMonth: "2026-01", endMonth: "2026-12" },
            ],
            missions: {
                // Documento do servidor ANTIGO: sem templateKey, sem workspaceType.
                consistency: { id: "consistency", type: "consistency", status: "pending", target: 3, rewardXp: 150, progress: 0 },
                discipline: { status: "completed" },
                organization: { status: "completed" },
            },
        });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "planning", {});

        expect(completions).toEqual([{ type: "consistency", progress: 3, rewardXp: 150 }]);
    });

    it("o evento que não toca na regra não gasta leitura nenhuma", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const { repository } = buildRepository({
            workspaceType: "business",
            missions: {
                consistency: { status: "completed" },
                discipline: { status: "completed" },
                organization: existingMission("business_organization_reconcile_statements"),
            },
        });
        const service = new GamificationService(repository as any);

        // Evento de PLANEJAMENTO: a regra de conciliação não pode ser lida.
        await service.updateWeeklyMissionsProgress("w1", "planning", {});

        expect(repository.getCompletedReconciliationsInPeriod).not.toHaveBeenCalled();
    });

    it("não reescreve o progresso que não mudou", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const { repository, updates } = buildRepository({
            workspaceType: "personal",
            plannings: [{ amount: 100, category: { name: "Moradia" }, startMonth: "2026-01", endMonth: "2026-12" }],
            missions: {
                consistency: existingMission("personal_consistency_plan_limits", { progress: 1 }),
                discipline: { status: "completed" },
                organization: { status: "completed" },
            },
        });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "planning", {});

        expect(updates).toEqual([]);
    });
});

describe("lançamentos automáticos — janela, fuso e gatilho", () => {
    function autoMissionRepo(rows: any[]) {
        return buildRepository({
            workspaceType: "business",
            automaticTransactions: rows,
            missions: {
                consistency: { status: "completed" },
                discipline: { status: "completed" },
                organization: existingMission("business_organization_categorize_auto"),
            },
        });
    }

    it("consulta pela JANELA da semana, não a coleção inteira", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const { repository } = autoMissionRepo([]);
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "transaction", {});

        const [, startIso, endIso, limit] = repository.getAutomaticTransactions.mock.calls[0];
        // Semana 2026-W32: domingo 09/08 a sábado 15/08, em São Paulo, com um
        // dia de folga em cada borda para o documento legado gravado em UTC.
        expect(startIso).toBe("2026-08-08T00:00:00.000");
        expect(endIso).toBe("2026-08-16T23:59:59.000");
        expect(limit).toBe(200);
        // Os limites são carimbos de RELÓGIO LOCAL, sem sufixo de fuso: é
        // assim que o app grava o campo, e um Timestamp aqui devolveria zero
        // documentos em silêncio.
        expect(startIso).not.toMatch(/Z$/);
    });

    it("uma caixa de entrada com 532 documentos não esconde os da semana", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        // A versão anterior lia `limit(500)` SEM `orderBy`: a página vinha
        // ordenada por id (UUID) e os 12 documentos da semana ficavam fora
        // dela — a missão marcava zero para sempre, a 500 leituras por evento.
        // Com a consulta por faixa, o repositório só devolve os da janela.
        const doSemana = Array.from({ length: 12 }, (_, i) => ({
            id: `w-${i}`,
            date: `2026-08-1${i % 5}T09:00:00.000`,
            isConsolidated: i < 5,
            isIgnored: false,
        }));
        const { repository, completions } = autoMissionRepo(doSemana);
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "transaction", {});

        // 5 consolidados >= alvo 3.
        expect(completions).toEqual([{ type: "organization", progress: 5, rewardXp: 200 }]);
    });

    it("interpreta a data como horário de São Paulo, não UTC", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        // Domingo 09/08 01:00 em São Paulo é o PRIMEIRO dia da semana. Lido
        // como UTC (o runtime das functions), viraria sábado 08/08 22:00 e
        // cairia na semana anterior.
        const { repository, updates } = autoMissionRepo([
            { id: "domingo-01h", date: "2026-08-09T01:00:00.000", isConsolidated: true, isIgnored: false },
            // Sábado 15/08 23:30 local ainda é a mesma semana; lido como UTC
            // viraria domingo 16/08 e pularia para a semana seguinte.
            { id: "sabado-2330", date: "2026-08-15T23:30:00.000", isIgnored: true, isConsolidated: false },
            // Sábado 08/08 23:00 local é a semana ANTERIOR — não conta.
            { id: "anterior", date: "2026-08-08T23:00:00.000", isConsolidated: true, isIgnored: false },
        ]);
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "transaction", {});

        expect(updates).toEqual([{ type: "organization", data: { progress: 2, status: "pending" } }]);
    });

    it("descartar um lançamento move a barra (origem auto_transaction)", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        // Descartar não cria transação nenhuma: sem a origem própria, metade
        // da missão ("ou descartar") não movia nada.
        const { repository, completions } = autoMissionRepo([
            { id: "a", date: "2026-08-10T09:00:00.000", isIgnored: true, isConsolidated: false },
            { id: "b", date: "2026-08-11T09:00:00.000", isIgnored: true, isConsolidated: false },
            { id: "c", date: "2026-08-12T09:00:00.000", isIgnored: true, isConsolidated: false },
        ]);
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "auto_transaction", null);

        expect(completions).toEqual([{ type: "organization", progress: 3, rewardXp: 200 }]);
    });
});

describe("custo por evento", () => {
    it("o evento de conciliação lê só a missão de organização", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const { repository } = buildRepository({
            workspaceType: "business",
            missions: {
                consistency: existingMission("business_consistency_cost_centers"),
                discipline: existingMission("business_discipline_top_cost_center"),
                organization: existingMission("business_organization_reconcile_statements"),
            },
        });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "reconciliation", { status: "completed" });

        // A leitura de existência (consistency) é inevitável; o LAÇO não pode
        // reler consistency nem tocar em discipline, porque nenhum template
        // desses tipos tem regra que a conciliação mova.
        const typesLidos = repository.getWeeklyMission.mock.calls.map((call: any[]) => call[2]);
        expect(typesLidos).toEqual(["consistency", "organization"]);
        expect(repository.getCategoryPlannings).not.toHaveBeenCalled();
        expect(repository.getPaidInstallmentsInPeriod).not.toHaveBeenCalled();
    });

    it("o evento de planejamento lê só a missão de consistência", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const { repository } = buildRepository({
            workspaceType: "business",
            plannings: [],
            missions: {
                consistency: existingMission("business_consistency_cost_centers"),
                discipline: existingMission("business_discipline_top_cost_center"),
                organization: existingMission("business_organization_reconcile_statements"),
            },
        });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "planning", {});

        const typesLidos = repository.getWeeklyMission.mock.calls.map((call: any[]) => call[2]);
        expect(typesLidos).toEqual(["consistency"]);
        expect(repository.getCompletedReconciliationsInPeriod).not.toHaveBeenCalled();
        expect(repository.getAutomaticTransactions).not.toHaveBeenCalled();
    });

    it("o evento de triagem lê só a missão de organização", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const { repository } = buildRepository({
            workspaceType: "business",
            missions: {
                consistency: existingMission("business_consistency_cost_centers"),
                discipline: existingMission("business_discipline_top_cost_center"),
                organization: existingMission("business_organization_categorize_auto"),
            },
        });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "auto_transaction", null);

        const typesLidos = repository.getWeeklyMission.mock.calls.map((call: any[]) => call[2]);
        expect(typesLidos).toEqual(["consistency", "organization"]);
    });
});

describe("fechamento da semana", () => {
    it("o cron dá uma última passada na semana fechada antes de decidir a streak", async () => {
        // Segunda 2026-08-17 03:00 SP: a semana a avaliar é a 2026-W32.
        jest.useFakeTimers({ now: new Date("2026-08-17T06:00:00Z") });
        const { repository, completions, missions } = buildRepository({
            workspaceType: "business",
            weeklySummary: [
                summaryRow("i1", CategoryType.income, { specific: 9000, actual: 9000 }),
                summaryRow("e1", CategoryType.expense, { general: 3000, actual: 1000 }),
            ],
            missions: {
                consistency: { type: "consistency", status: "completed" },
                discipline: existingMission("business_discipline_margin"),
                organization: { type: "organization", status: "completed" },
            },
        });
        repository.getWeeklyMissionsByWeek.mockImplementation(async () =>
            ["consistency", "discipline", "organization"].map((type) => missions[type])
        );
        const service = new GamificationService(repository as any);

        await service.evaluateWeeklyMissionsCron("w1");

        expect(completions).toEqual([{ type: "discipline", progress: 1, rewardXp: 250 }]);
        expect(repository.getWeeklySummaryRows).toHaveBeenCalledWith("w1", WEEK_ID);
        // A missão fechou NA passada final, então a streak sobe na mesma
        // execução em vez de esperar mais uma semana.
        expect(repository.updateWorkspaceStreaks).toHaveBeenCalledWith("w1", { missions: 1 });
    });

    it("semana já toda concluída não gasta leitura para ser reavaliada", async () => {
        jest.useFakeTimers({ now: new Date("2026-08-17T06:00:00Z") });
        const { repository } = buildRepository({ workspaceType: "business" });
        repository.getWeeklyMissionsByWeek.mockResolvedValue([
            { type: "consistency", status: "completed" },
            { type: "discipline", status: "completed" },
            { type: "organization", status: "completed" },
        ]);
        const service = new GamificationService(repository as any);

        await service.evaluateWeeklyMissionsCron("w1");

        expect(repository.getWeeklyMission).not.toHaveBeenCalled();
        expect(repository.getWeeklySummaryRows).not.toHaveBeenCalled();
        expect(repository.updateWorkspaceStreaks).toHaveBeenCalledWith("w1", { missions: 1 });
    });

    it("falha na passada final não derruba o resto do cron", async () => {
        jest.useFakeTimers({ now: new Date("2026-08-17T06:00:00Z") });
        const open = existingMission("business_consistency_cost_centers");
        const { repository } = buildRepository({
            workspaceType: "business",
            missions: { consistency: open },
        });
        repository.getCategoryPlannings.mockRejectedValue(new Error("indisponível"));
        repository.getWeeklyMissionsByWeek.mockResolvedValue([open]);
        const service = new GamificationService(repository as any);

        // Não lança: a streak e os badges são o trabalho principal do cron.
        await service.evaluateWeeklyMissionsCron("w1");

        // A missão continua aberta, então a semana não foi perfeita.
        expect(repository.updateWorkspaceStreaks).toHaveBeenCalledWith("w1", { missions: 0 });
        expect(repository.getCompletedMissionsCount).toHaveBeenCalled();
    });
});
