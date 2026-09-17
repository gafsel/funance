/**
 * Migração leve `retag_weekly_missions.ts`: dry-run, carimbo, substituição das
 * missões ABERTAS de empresa, preservação das concluídas e idempotência.
 */

import { parseArgs, retagWeeklyMissions } from "../scripts/retag_weekly_missions";
import { buildMissionName, selectMissionTemplate } from "../features/goal/domain/models/mission_catalog";
import { GamificationService } from "../features/goal/domain/services/gamification.service";
import { CategoryType } from "../features/workspace/domain/models/category.model";

/** Terça 2026-08-11 12:00 em São Paulo — semana 2026-W32. */
const NOW = new Date("2026-08-11T15:00:00Z");
const WEEK_ID = "2026-W32";

interface WorkspaceFixture {
    type?: string;
    missions: Record<string, Record<string, any>>;
    plannings?: Record<string, Record<string, any>>;
    categories?: Record<string, Record<string, any>>;
    /** Documentos de `period_summaries`, por id (`YYYY-Www`). */
    summaries?: Record<string, Record<string, any>>;
}

let written: Array<{ id: string; data: Record<string, any> }>;

/** Firestore falso: workspaces paginados + subcoleções por workspace. */
function buildFirestore(workspaces: Record<string, WorkspaceFixture>): any {
    const subcollection = (docs: Record<string, Record<string, any>>, workspaceId: string) => ({
        where() {
            return this;
        },
        doc(id: string) {
            return {
                async get() {
                    const data = docs[id];
                    return {
                        id,
                        exists: data !== undefined,
                        data: () => (data ? { ...data } : undefined),
                    };
                },
            };
        },
        async get() {
            const entries = Object.entries(docs);
            return {
                empty: entries.length === 0,
                size: entries.length,
                docs: entries.map(([id, data]) => ({
                    id,
                    data: () => ({ ...data }),
                    ref: { id, __workspaceId: workspaceId },
                })),
            };
        },
    });

    const workspaceDoc = (id: string) => {
        const fixture = workspaces[id];
        return {
            id,
            data: () => ({ type: fixture.type }),
            ref: {
                id,
                collection: (name: string) => {
                    if (name === "weekly_missions") return subcollection(fixture.missions, id);
                    if (name === "category_planning") return subcollection(fixture.plannings ?? {}, id);
                    if (name === "categories") return subcollection(fixture.categories ?? {}, id);
                    if (name === "period_summaries") return subcollection(fixture.summaries ?? {}, id);
                    throw new Error(`subcoleção inesperada: ${name}`);
                },
            },
        };
    };

    const makeQuery = () => {
        const query: any = {
            __only: null as string | null,
            __pageSize: null as number | null,
            __startAfter: null as string | null,
            where(_field: unknown, _op: string, value: string) {
                query.__only = value;
                return query;
            },
            orderBy() {
                return query;
            },
            limit(size: number) {
                query.__pageSize = size;
                return query;
            },
            startAfter(doc: any) {
                query.__startAfter = doc.id;
                return query;
            },
            async get() {
                let ids = Object.keys(workspaces).sort();
                if (query.__only) ids = ids.filter((id) => id === query.__only);
                if (query.__startAfter !== null) ids = ids.filter((id) => id > query.__startAfter);
                const page = query.__pageSize === null ? ids : ids.slice(0, query.__pageSize);
                return {
                    empty: page.length === 0,
                    size: page.length,
                    docs: page.map(workspaceDoc),
                };
            },
        };
        return query;
    };

    return {
        collection: (name: string) => {
            if (name !== "workspaces") throw new Error(`coleção inesperada: ${name}`);
            return makeQuery();
        },
        batch: () => ({
            __ops: 0,
            set(ref: any, data: Record<string, any>) {
                written.push({ id: `${ref.__workspaceId}/${ref.id}`, data });
                this.__ops++;
            },
            update() {
                throw new Error("o script só usa set(merge)");
            },
            delete() {
                throw new Error("o script não apaga nada");
            },
            async commit() {
                return [];
            },
        }),
    };
}

const silent = () => undefined;

beforeEach(() => {
    written = [];
});

function legacyMission(type: string, status = "pending") {
    return {
        id: type,
        type,
        name: "Equipe planeja limites para pelo menos 3 categorias para organizar a semana.",
        status,
        progress: status === "completed" ? 3 : 1,
        target: 3,
        rewardXp: 150,
        weekId: WEEK_ID,
    };
}

describe("retag_weekly_missions", () => {
    it("dry-run não escreve nada e conta o que faria", async () => {
        const firestore = buildFirestore({
            w1: { type: "business", missions: { [`${WEEK_ID}_consistency`]: legacyMission("consistency") } },
        });

        const summary = await retagWeeklyMissions(firestore, { dryRun: true, now: NOW }, silent);

        expect(written).toEqual([]);
        expect(summary.replaced).toBe(1);
        expect(summary.tagged).toBe(0);
    });

    it("substitui a missão ABERTA de empresa pelo template corporativo da semana", async () => {
        const firestore = buildFirestore({
            w1: {
                type: "business",
                missions: { [`${WEEK_ID}_consistency`]: legacyMission("consistency") },
                plannings: { p1: { amount: 900, category: { name: "Marketing" }, startMonth: "2026-01", endMonth: "2026-12" } },
            },
        });

        await retagWeeklyMissions(firestore, { dryRun: false, now: NOW }, silent);

        const template = selectMissionTemplate("business", "consistency", WEEK_ID)!;
        expect(written).toHaveLength(1);
        expect(written[0].id).toBe(`w1/${WEEK_ID}_consistency`);
        expect(written[0].data).toMatchObject({
            templateKey: template.key,
            workspaceType: "business",
            actionPath: template.actionPath,
            nameKey: template.nameKey,
            target: template.target,
            rewardXp: template.rewardXp,
            progress: 0,
            status: "pending",
        });
        // A régua mudou: o progresso da missão anterior não significa nada nela.
        expect(written[0].data.name).toBe(buildMissionName(template, "pt", { target: template.target }));
    });

    it("missão CONCLUÍDA é só carimbada — nome, XP e status ficam intocados", async () => {
        const firestore = buildFirestore({
            w1: { type: "business", missions: { [`${WEEK_ID}_consistency`]: legacyMission("consistency", "completed") } },
        });

        const summary = await retagWeeklyMissions(firestore, { dryRun: false, now: NOW }, silent);

        expect(summary.replaced).toBe(0);
        expect(summary.tagged).toBe(1);
        const patch = written[0].data;
        expect(Object.keys(patch).sort()).toEqual(["actionPath", "nameKey", "params", "templateKey", "workspaceType"]);
        // O carimbo descreve o que a missão FOI: o objetivo antigo era pessoal,
        // mesmo num workspace de empresa.
        expect(patch.templateKey).toBe("personal_consistency_plan_limits");
        expect(patch.workspaceType).toBe("personal");
    });

    it("workspace pessoal aberto é só carimbado (sem churn de texto)", async () => {
        const firestore = buildFirestore({
            w1: { type: "personal", missions: { [`${WEEK_ID}_organization`]: legacyMission("organization") } },
        });

        const summary = await retagWeeklyMissions(firestore, { dryRun: false, now: NOW }, silent);

        expect(summary.replaced).toBe(0);
        expect(written[0].data).not.toHaveProperty("name");
        expect(written[0].data.templateKey).toBe("personal_organization_reconcile_items");
    });

    it("ao CARIMBAR, params.target é o alvo do documento, não o do template", async () => {
        // A missão antiga pode ter nascido com um alvo escolhido pela IA. Se o
        // `params` disser "5 categorias" enquanto o `target` gravado é 4, a
        // frase e a barra se contradizem na tela do usuário.
        const legacy = { ...legacyMission("consistency", "completed"), target: 4 };
        const firestore = buildFirestore({
            w1: { type: "business", missions: { [`${WEEK_ID}_consistency`]: legacy } },
        });

        await retagWeeklyMissions(firestore, { dryRun: false, now: NOW }, silent);

        expect(written[0].data.params).toEqual({ target: 4 });
    });

    it("ao SUBSTITUIR, o alvo passa a ser o do template (a missão é outra)", async () => {
        const legacy = { ...legacyMission("organization"), target: 9 };
        const firestore = buildFirestore({
            w1: { type: "business", missions: { [`${WEEK_ID}_organization`]: legacy } },
        });

        await retagWeeklyMissions(firestore, { dryRun: false, now: NOW }, silent);

        const template = selectMissionTemplate("business", "organization", WEEK_ID)!;
        expect(written[0].data.target).toBe(template.target);
        expect(written[0].data.params).toEqual({ target: template.target });
    });

    it("é idempotente: missão já carimbada é pulada (e --force recarimba)", async () => {
        const tagged = { ...legacyMission("consistency"), templateKey: "personal_consistency_plan_limits" };
        const firestore = buildFirestore({
            w1: { type: "personal", missions: { [`${WEEK_ID}_consistency`]: tagged } },
        });

        const first = await retagWeeklyMissions(firestore, { dryRun: false, now: NOW }, silent);
        expect(first.skippedAlreadyTagged).toBe(1);
        expect(written).toEqual([]);

        const forced = await retagWeeklyMissions(firestore, { dryRun: false, force: true, now: NOW }, silent);
        expect(forced.skippedAlreadyTagged).toBe(0);
        expect(written).toHaveLength(1);
    });

    it("usa a categoria de maior limite do mês no {category} do template", async () => {
        const firestore = buildFirestore({
            w1: {
                type: "business",
                missions: { [`${WEEK_ID}_discipline`]: legacyMission("discipline") },
                plannings: {
                    p1: { amount: 900, category: { name: "Marketing" }, startMonth: "2026-01", endMonth: "2026-12" },
                    p2: { amount: 2500, category: { name: "Folha" }, startMonth: "2026-01", endMonth: "2026-12" },
                    // Fora do mês corrente: não pode vencer a disputa.
                    p3: { amount: 90000, category: { name: "Obra" }, startMonth: "2025-01", endMonth: "2025-12" },
                },
            },
        });

        await retagWeeklyMissions(firestore, { dryRun: false, now: NOW }, silent);

        const template = selectMissionTemplate("business", "discipline", WEEK_ID)!;
        const patch = written[0].data;
        if (template.params.includes("category")) {
            expect(patch.params).toEqual({ target: template.target, category: "Folha" });
            expect(patch.name).toContain("Folha");
        }
        else {
            // O template da semana é o de margem, que não tem placeholder.
            expect(patch.params).toBeUndefined();
        }
    });

    it("ignora missão com type fora do catálogo em vez de derrubar a varredura", async () => {
        const firestore = buildFirestore({
            w1: {
                type: "personal",
                missions: {
                    [`${WEEK_ID}_mystery`]: { ...legacyMission("consistency"), type: "mystery" },
                    [`${WEEK_ID}_consistency`]: legacyMission("consistency"),
                },
            },
        });

        const summary = await retagWeeklyMissions(firestore, { dryRun: false, now: NOW }, silent);

        expect(summary.skippedUnknownType).toBe(1);
        expect(summary.tagged).toBe(1);
    });

    it("limita a um workspace quando pedido", async () => {
        const firestore = buildFirestore({
            w1: { type: "business", missions: { [`${WEEK_ID}_consistency`]: legacyMission("consistency") } },
            w2: { type: "business", missions: { [`${WEEK_ID}_consistency`]: legacyMission("consistency") } },
        });

        const summary = await retagWeeklyMissions(firestore, { dryRun: false, workspaceId: "w2", now: NOW }, silent);

        expect(summary.workspaces).toBe(1);
        expect(written.map((w) => w.id)).toEqual([`w2/${WEEK_ID}_consistency`]);
    });
});

describe("retag_weekly_missions — parseArgs", () => {
    it("dry-run é o padrão e --apply é a única forma de escrever", () => {
        expect(parseArgs([]).dryRun).toBe(true);
        expect(parseArgs(["--apply"]).dryRun).toBe(false);
    });

    it("lê workspace, semana, página e force", () => {
        const options = parseArgs(["--workspace=w9", "--week=2026-W05", "--page-size=50", "--force"]);
        expect(options.workspaceId).toBe("w9");
        expect(options.weekId).toBe("2026-W05");
        expect(options.pageSize).toBe(50);
        expect(options.force).toBe(true);
    });

    it("ignora --page-size inválido", () => {
        expect(parseArgs(["--page-size=zero"]).pageSize).toBeUndefined();
        expect(parseArgs(["--page-size=-3"]).pageSize).toBeUndefined();
    });
});

/**
 * CONVERGÊNCIA gerador × retag.
 *
 * Os dois escolhem o template da semana pela MESMA função, mas com contextos
 * que podem divergir: o gerador lê o sumário semanal, e o retag — até a
 * reprovação do QA — não lia nada e sorteava entre TODOS os candidatos. O
 * resultado eram dois templates diferentes para a mesma semana, e um documento
 * descrevendo uma missão que não é a que está na tela.
 *
 * Este teste roda os DOIS caminhos de código de verdade, sobre os mesmos
 * dados, nos quatro contextos possíveis de elegibilidade.
 */
describe("convergência gerador × retag", () => {
    const CONTEXTOS = [
        { nome: "sem plano nenhum", income: 0, expense: 0 },
        { nome: "só receita prevista", income: 15850, expense: 0 },
        { nome: "só despesa planejada", income: 0, expense: 4553.5 },
        { nome: "plano completo", income: 15850, expense: 4553.5 },
    ];

    function summaryDoc(income: number, expense: number) {
        const cents = (v: number) => Math.round(v * 100);
        return {
            year: 2026,
            week: 32,
            month: null,
            runtimeType: "week",
            categories: {
                servicos: {
                    generalPlannedAmount: 0,
                    specificPlannedAmount: income,
                    actualAmount: 0,
                    generalPlannedAmountCents: 0,
                    specificPlannedAmountCents: cents(income),
                    actualAmountCents: 0,
                },
                custos: {
                    generalPlannedAmount: expense,
                    specificPlannedAmount: 0,
                    actualAmount: 0,
                    generalPlannedAmountCents: cents(expense),
                    specificPlannedAmountCents: 0,
                    actualAmountCents: 0,
                },
            },
        };
    }

    function summaryRows(income: number, expense: number) {
        const cents = (v: number) => Math.round(v * 100);
        return [
            {
                categoryId: "servicos", type: CategoryType.income, isSystem: false,
                generalPlannedAmount: 0, specificPlannedAmount: income, actualAmount: 0,
                generalPlannedAmountCents: 0, specificPlannedAmountCents: cents(income), actualAmountCents: 0,
            },
            {
                categoryId: "custos", type: CategoryType.expense, isSystem: false,
                generalPlannedAmount: expense, specificPlannedAmount: 0, actualAmount: 0,
                generalPlannedAmountCents: cents(expense), specificPlannedAmountCents: 0, actualAmountCents: 0,
            },
        ];
    }

    /** O que o GERADOR grava, rodando o serviço de verdade. */
    async function gerar(income: number, expense: number): Promise<Record<string, string>> {
        const created: Record<string, string> = {};
        const repository = {
            getWorkspaceById: jest.fn().mockResolvedValue({ id: "w1", type: "business" }),
            getCategoryPlannings: jest.fn().mockResolvedValue([]),
            getGoals: jest.fn().mockResolvedValue([]),
            getWeeklySummaryRows: jest.fn().mockResolvedValue(summaryRows(income, expense)),
            getWeeklyMission: jest.fn().mockResolvedValue(null),
            createWeeklyMission: jest.fn(async (_w: string, _week: string, type: string, data: any) => {
                created[type] = data.templateKey;
            }),
            updateWeeklyMission: jest.fn(),
            completeMissionAndAwardXp: jest.fn(),
            getPaidInstallmentsInPeriod: jest.fn().mockResolvedValue([]),
            getCompletedReconciliationsInPeriod: jest.fn().mockResolvedValue(0),
            getAutomaticTransactions: jest.fn().mockResolvedValue([]),
        };
        const service = new GamificationService(repository as any);
        await service.updateWeeklyMissionsProgress("w1", "planning", {});
        return created;
    }

    /** Uma semana em que a peneira MUDA a escolha nos dois tipos. */
    const SEMANA_SENSIVEL = { weekId: "2026-W02", now: new Date("2026-01-13T15:00:00Z") };

    /** O que o RETAG grava, rodando o script de verdade. */
    async function retagar(
        income: number,
        expense: number,
        weekId: string = WEEK_ID
    ): Promise<Record<string, string>> {
        written = [];
        const missions: Record<string, any> = {};
        for (const type of ["consistency", "discipline", "organization"]) {
            missions[`${weekId}_${type}`] = { ...legacyMission(type), weekId };
        }
        const firestore = buildFirestore({
            w1: {
                type: "business",
                missions,
                categories: {
                    servicos: { name: "Serviços", type: "income", isDeleted: false },
                    custos: { name: "Custos", type: "expense", isDeleted: false },
                },
                summaries: { [weekId]: summaryDoc(income, expense) },
            },
        });

        await retagWeeklyMissions(firestore, { dryRun: false, now: NOW, weekId }, silent);

        const out: Record<string, string> = {};
        for (const item of written) {
            const type = item.id.split("_").pop()!;
            out[type] = item.data.templateKey;
        }
        return out;
    }

    for (const contexto of CONTEXTOS) {
        it(`escolhe o MESMO template nos dois caminhos: ${contexto.nome}`, async () => {
            jest.useFakeTimers({ now: NOW });
            try {
                const doGerador = await gerar(contexto.income, contexto.expense);
                const doRetag = await retagar(contexto.income, contexto.expense);
                expect(doRetag).toEqual(doGerador);
            }
            finally {
                jest.useRealTimers();
            }
        });
    }

    it("numa semana em que a peneira MUDA a escolha, os dois continuam juntos", async () => {
        // Os quatro casos acima caem numa semana em que o hash escolheria o
        // mesmo template com ou sem contexto — passariam mesmo com o retag
        // ignorando o contexto. Esta semana é uma das 52 em que a peneira de
        // fato troca o template, e é ela que prova a correção.
        jest.useFakeTimers({ now: SEMANA_SENSIVEL.now });
        try {
            const doGerador = await gerar(15850, 4553.5);
            expect(doGerador.consistency).toBe("business_consistency_income_forecast");
            expect(doGerador.discipline).toBe("business_discipline_margin");

            const doRetag = await retagar(15850, 4553.5, SEMANA_SENSIVEL.weekId);
            expect(doRetag).toEqual(doGerador);
        }
        finally {
            jest.useRealTimers();
        }
    });

    it("sem plano, a mesma semana cai nos outros dois templates — nos dois caminhos", async () => {
        jest.useFakeTimers({ now: SEMANA_SENSIVEL.now });
        try {
            const doGerador = await gerar(0, 0);
            expect(doGerador.consistency).toBe("business_consistency_cost_centers");
            expect(doGerador.discipline).toBe("business_discipline_top_cost_center");

            const doRetag = await retagar(0, 0, SEMANA_SENSIVEL.weekId);
            expect(doRetag).toEqual(doGerador);
        }
        finally {
            jest.useRealTimers();
        }
    });
});
