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
    };

    return { repository, created, updates, completions, missions };
}

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
            { categoryId: "i1", type: CategoryType.income, isSystem: false, actualAmount: 12000, generalPlannedAmount: 10000 },
            { categoryId: "e1", type: CategoryType.expense, isSystem: false, actualAmount: 7000, generalPlannedAmount: 8000 },
            // Saldo inicial: fora da conta, senão a margem seria fabricada.
            { categoryId: "sys", type: CategoryType.income, isSystem: true, actualAmount: 500000, generalPlannedAmount: 0 },
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

        // Planejado 10000-8000 = 2000; realizado 12000-7000 = 5000.
        expect(completions).toEqual([{ type: "discipline", progress: 1, rewardXp: 250 }]);
    });

    it("weekly_margin_above_plan não premia a AUSÊNCIA de plano", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const { repository, completions, updates } = buildRepository({
            workspaceType: "business",
            weeklySummary: [
                { categoryId: "i1", type: CategoryType.income, isSystem: false, actualAmount: 12000, generalPlannedAmount: 0 },
                { categoryId: "e1", type: CategoryType.expense, isSystem: false, actualAmount: 1, generalPlannedAmount: 0 },
            ],
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
    });

    it("income_received_vs_planned mede o PERCENTUAL recebido da receita prevista", async () => {
        jest.useFakeTimers({ now: SATURDAY });
        const { repository, updates } = buildRepository({
            workspaceType: "business",
            weeklySummary: [
                { categoryId: "i1", type: CategoryType.income, isSystem: false, actualAmount: 7000, generalPlannedAmount: 10000 },
            ],
            missions: {
                consistency: existingMission("business_consistency_income_forecast"),
                discipline: { status: "completed" },
                organization: { status: "completed" },
            },
        });
        const service = new GamificationService(repository as any);

        await service.updateWeeklyMissionsProgress("w1", "transaction", {});

        // 70% < alvo de 80%: progresso, sem conclusão.
        expect(updates).toEqual([{ type: "consistency", data: { progress: 70, status: "pending" } }]);
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

describe("fechamento da semana", () => {
    it("o cron dá uma última passada na semana fechada antes de decidir a streak", async () => {
        // Segunda 2026-08-17 03:00 SP: a semana a avaliar é a 2026-W32.
        jest.useFakeTimers({ now: new Date("2026-08-17T06:00:00Z") });
        const { repository, completions } = buildRepository({
            workspaceType: "business",
            weeklySummary: [
                { categoryId: "i1", type: CategoryType.income, isSystem: false, actualAmount: 9000, generalPlannedAmount: 9000 },
                { categoryId: "e1", type: CategoryType.expense, isSystem: false, actualAmount: 1000, generalPlannedAmount: 3000 },
            ],
            missions: {
                consistency: { status: "completed" },
                discipline: existingMission("business_discipline_margin"),
                organization: { status: "completed" },
            },
        });
        repository.getWeeklyMissionsByWeek.mockResolvedValue([{ status: "completed" }]);
        const service = new GamificationService(repository as any);

        await service.evaluateWeeklyMissionsCron("w1");

        expect(completions).toEqual([{ type: "discipline", progress: 1, rewardXp: 250 }]);
        expect(repository.getWeeklySummaryRows).toHaveBeenCalledWith("w1", WEEK_ID);
    });

    it("falha na passada final não derruba a streak nem os badges", async () => {
        jest.useFakeTimers({ now: new Date("2026-08-17T06:00:00Z") });
        const { repository } = buildRepository({
            workspaceType: "business",
            missions: { consistency: existingMission("business_consistency_cost_centers") },
        });
        repository.getCategoryPlannings.mockRejectedValue(new Error("indisponível"));
        repository.getWeeklyMissionsByWeek.mockResolvedValue([{ status: "completed" }]);
        const service = new GamificationService(repository as any);

        await service.evaluateWeeklyMissionsCron("w1");

        expect(repository.updateWorkspaceStreaks).toHaveBeenCalledWith("w1", { missions: 1 });
    });
});
