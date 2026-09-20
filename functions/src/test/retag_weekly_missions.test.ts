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
    /** Contas do workspace — a capacidade "tem cartão de crédito". */
    accounts?: Record<string, Record<string, any>>;
    /** Conciliações — a capacidade "já conciliou alguma vez". */
    reconciliations?: Record<string, Record<string, any>>;
    /** Lançamentos automáticos — a capacidade "recebe notificação". */
    automaticTransactions?: Record<string, Record<string, any>>;
}

let written: Array<{ id: string; data: Record<string, any> }>;
/** Filtros aplicados às subcoleções de CAPACIDADE, para inspeção nos testes. */
let capacityFilters: Array<{ collection: string; field: string; op: string; value: any }>;

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

    /**
     * Subcoleção que FILTRA de verdade (`where`/`orderBy`/`limit`).
     *
     * As consultas de capacidade dependem do filtro: um fixture com uma conta
     * corrente não pode responder "tem cartão de crédito" só porque a coleção
     * não está vazia. A de `weekly_missions` continua permissiva de propósito
     * — os fixtures dela são montados já recortados pela semana.
     */
    const filteredSubcollection = (name: string, docs: Record<string, Record<string, any>>) => {
        const filters: Array<{ field: string; op: string; value: any }> = [];
        let max: number | null = null;
        const api: any = {
            where(field: string, op: string, value: any) {
                filters.push({ field, op, value });
                capacityFilters.push({ collection: name, field, op, value });
                return api;
            },
            orderBy() {
                return api;
            },
            limit(size: number) {
                max = size;
                return api;
            },
            async get() {
                let entries = Object.entries(docs).filter(([, data]) =>
                    filters.every(({ field, op, value }) => {
                        const actual = (data as Record<string, any>)[field];
                        if (op === "==") return actual === value;
                        if (op === ">=") return actual !== undefined && actual >= value;
                        if (op === "<") return actual !== undefined && actual < value;
                        throw new Error(`operador inesperado no fake: ${op}`);
                    })
                );
                if (max !== null) entries = entries.slice(0, max);
                return {
                    empty: entries.length === 0,
                    size: entries.length,
                    docs: entries.map(([id, data]) => ({ id, data: () => ({ ...data }) })),
                };
            },
        };
        return api;
    };

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
                    if (name === "accounts") return filteredSubcollection(name, fixture.accounts ?? {});
                    if (name === "reconciliations") {
                        return filteredSubcollection(name, fixture.reconciliations ?? {});
                    }
                    if (name === "automatic_transactions") {
                        return filteredSubcollection(name, fixture.automaticTransactions ?? {});
                    }
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
    capacityFilters = [];
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

    it("--all-workspaces é reconhecida, e o desconhecido é DENUNCIADO", () => {
        // A flag existia nas instruções e não no parser: passá-la rodava a
        // base inteira por omissão, com o operador achando que a tinha
        // limitado. Agora ela existe — e o que não existe aborta.
        expect(parseArgs(["--all-workspaces"])).toMatchObject({ allWorkspaces: true, unknownArgs: [] });
        expect(parseArgs(["--workspace=w1"])).toMatchObject({ allWorkspaces: false, unknownArgs: [] });
        expect(parseArgs(["--worskpace=w1"]).unknownArgs).toEqual(["--worskpace=w1"]);
        expect(parseArgs(["--all-workspaces", "--apply", "--week=2026-W38"]).unknownArgs).toEqual([]);
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
            // O firestore falso do script não tem contas, reconciliações nem
            // lançamentos automáticos: para os dois caminhos convergirem, o
            // gerador também roda SEM capacidade nenhuma.
            getMissionCapacity: jest.fn().mockResolvedValue({
                hasCreditCardAccount: false,
                hasReconciledStatementEver: false,
                hasRecentAutomaticTransaction: false,
            }),
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

/**
 * REPARO DA MISSÃO IMPOSSÍVEL.
 *
 * Uma missão de organização gravada ANTES da peneira de capacidade pode ser
 * incumprível — `business_organization_invoice_on_time` num workspace sem
 * cartão. O servidor novo já não a sorteia; estas são as que JÁ ESTÃO
 * gravadas, e é este script que as conserta.
 *
 * O workspace do fixture é FICTÍCIO. A suspeita que originou o pacote
 * (a70134c1 em 2026-W38) foi falso alarme: aquele workspace tem cartão, e o
 * dry-run em produção deu `reparadas=0`. O cenário abaixo é o do risco, não o
 * de um caso real.
 */
describe("retag — reparo de missão inelegível", () => {
    const WEEK = "2026-W38";
    /** Domingo 20/09/2026 00:05 em São Paulo — a semana 2026-W38. */
    const NOW_W38 = new Date("2026-09-20T03:05:00.000Z");

    /** A missão impossível, exatamente como o cron a gravou. */
    function invoiceMission(overrides: Record<string, any> = {}) {
        return {
            id: "organization",
            type: "organization",
            name: "Fechar 1 fatura do cartão corporativo pagando até o vencimento.",
            status: "pending",
            progress: 0,
            target: 1,
            rewardXp: 200,
            weekId: WEEK,
            templateKey: "business_organization_invoice_on_time",
            workspaceType: "business",
            actionPath: "/workspace/accounts",
            nameKey: "missionBusinessOrganizationInvoiceOnTime",
            ...overrides,
        };
    }

    function workspaceSemCartao(mission: Record<string, any>) {
        return {
            empresaSemCartao: {
                type: "business",
                missions: { [`${WEEK}_organization`]: mission },
                // Só conta corrente: nenhum cartão de crédito.
                accounts: { conta1: { runtimeType: "checking", isDeleted: false } },
            },
        };
    }

    it("dry-run ANUNCIA a troca e não escreve nada", async () => {
        const lines: string[] = [];
        const firestore = buildFirestore(workspaceSemCartao(invoiceMission()));

        const summary = await retagWeeklyMissions(
            firestore,
            { dryRun: true, now: NOW_W38, weekId: WEEK, workspaceId: "empresaSemCartao" },
            (line) => lines.push(line)
        );

        expect(summary.repaired).toBe(1);
        expect(summary.keptWithProgress).toBe(0);
        expect(written).toHaveLength(0);
        expect(lines.join("\n")).toContain("REPARARIA (business_organization_invoice_on_time é inelegível)");
        expect(lines.join("\n")).toContain("business_organization_categorize_week");
    });

    it("com --apply, substitui pela missão que SEMPRE dá para cumprir", async () => {
        const firestore = buildFirestore(workspaceSemCartao(invoiceMission()));

        const summary = await retagWeeklyMissions(
            firestore,
            { dryRun: false, now: NOW_W38, weekId: WEEK, workspaceId: "empresaSemCartao" },
            silent
        );

        expect(summary.repaired).toBe(1);
        expect(written).toHaveLength(1);

        const patch = written[0].data;
        expect(written[0].id).toBe(`empresaSemCartao/${WEEK}_organization`);
        expect(patch.templateKey).toBe("business_organization_categorize_week");
        expect(patch.nameKey).toBe("missionBusinessOrganizationCategorizeWeek");
        expect(patch.actionPath).toBe("/workspace/categories");
        expect(patch.workspaceType).toBe("business");
        expect(patch.target).toBe(100);
        expect(patch.rewardXp).toBe(200);
        expect(patch.progress).toBe(0);
        expect(patch.status).toBe("pending");
        expect(patch.name).toContain("100%");
        // E é exatamente o que o servidor geraria hoje para esta semana.
        expect(patch.templateKey).toBe(
            selectMissionTemplate("business", "organization", WEEK, {
                plannedIncomeCents: 0,
                plannedExpenseCents: 0,
                hasCreditCardAccount: false,
                hasReconciledStatementEver: false,
                hasRecentAutomaticTransaction: false,
            })!.key
        );
    });

    it("com PROGRESSO, a missão é MANTIDA — progresso é trabalho do usuário", async () => {
        const lines: string[] = [];
        const firestore = buildFirestore(workspaceSemCartao(invoiceMission({ progress: 1 })));

        const summary = await retagWeeklyMissions(
            firestore,
            { dryRun: false, now: NOW_W38, weekId: WEEK, workspaceId: "empresaSemCartao" },
            (line) => lines.push(line)
        );

        expect(summary.keptWithProgress).toBe(1);
        expect(summary.repaired).toBe(0);
        expect(written).toHaveLength(0);
        expect(lines.join("\n")).toContain("MANTIDA");
    });

    it("a missão CONCLUÍDA não é tocada, mesmo com o template inelegível", async () => {
        const firestore = buildFirestore(
            workspaceSemCartao(invoiceMission({ status: "completed", progress: 1 }))
        );

        const summary = await retagWeeklyMissions(
            firestore,
            { dryRun: false, now: NOW_W38, weekId: WEEK, workspaceId: "empresaSemCartao" },
            silent
        );

        expect(summary.repaired).toBe(0);
        expect(summary.keptWithProgress).toBe(0);
        expect(summary.skippedAlreadyTagged).toBe(1);
        expect(written).toHaveLength(0);
    });

    it("COM cartão, a mesma missão é legítima e fica onde está", async () => {
        const firestore = buildFirestore({
            comCartao: {
                type: "business",
                missions: { [`${WEEK}_organization`]: invoiceMission() },
                accounts: { cartao1: { runtimeType: "creditCard", isDeleted: false } },
            },
        });

        const summary = await retagWeeklyMissions(
            firestore,
            { dryRun: false, now: NOW_W38, weekId: WEEK, workspaceId: "comCartao" },
            silent
        );

        expect(summary.repaired).toBe(0);
        expect(summary.skippedAlreadyTagged).toBe(1);
        expect(written).toHaveLength(0);
    });

    it("o cartão EXCLUÍDO não conta como capacidade", async () => {
        const firestore = buildFirestore({
            empresaSemCartao: {
                type: "business",
                missions: { [`${WEEK}_organization`]: invoiceMission() },
                accounts: { cartao1: { runtimeType: "creditCard", isDeleted: true } },
            },
        });

        const summary = await retagWeeklyMissions(
            firestore,
            { dryRun: false, now: NOW_W38, weekId: WEEK, workspaceId: "empresaSemCartao" },
            silent
        );

        expect(summary.repaired).toBe(1);
        expect(written[0].data.templateKey).toBe("business_organization_categorize_week");
    });

    it("rodado SEMANAS depois, ancora a janela no domingo da semana tratada", async () => {
        // O operador roda o reparo em 17/11, pedindo a semana 2026-W38. O mês
        // do planejamento e a janela de capacidade têm de ser os DAQUELA
        // semana: ancorar em `now` faria o script reproduzir um sorteio que o
        // servidor nunca fez.
        const NOVEMBRO = new Date("2026-11-17T15:00:00.000Z");
        const firestore = buildFirestore(workspaceSemCartao(invoiceMission()));

        await retagWeeklyMissions(
            firestore,
            { dryRun: true, now: NOVEMBRO, weekId: WEEK, workspaceId: "empresaSemCartao" },
            silent
        );

        const janela = capacityFilters.find(
            (f) => f.collection === "automatic_transactions" && f.op === ">="
        )!;
        // Domingo 20/09/2026 00:00 (SP) menos 30 dias, em relógio local — o
        // formato em que `automatic_transactions.date` é gravado.
        expect(janela.value).toBe("2026-08-21T00:00:00.000");

        // E não a janela de HOJE, que seria 18/10.
        expect(janela.value.startsWith("2026-10")).toBe(false);
    });

    it("a consulta de capacidade filtra pelo discriminador certo da conta", async () => {
        // `runtimeType` é o discriminador da union de contas — ler `type`
        // devolve outra coisa, e foi assim que um workspace COM cartão passou
        // por "sem cartão" na apuração que originou este pacote.
        const firestore = buildFirestore(workspaceSemCartao(invoiceMission()));
        await retagWeeklyMissions(
            firestore,
            { dryRun: true, now: NOW_W38, weekId: WEEK, workspaceId: "empresaSemCartao" },
            silent
        );

        const cartao = capacityFilters.find(
            (f) => f.collection === "accounts" && f.op === "==" && f.value === "creditCard"
        );
        expect(cartao?.field).toBe("runtimeType");
        // E a conta excluída continua fora da conta.
        expect(capacityFilters).toContainEqual(
            { collection: "accounts", field: "isDeleted", op: "==", value: false }
        );
    });

    it("a missão de conciliação também é reparada em quem nunca conciliou", async () => {
        const firestore = buildFirestore({
            empresaSemCartao: {
                type: "business",
                missions: {
                    [`${WEEK}_organization`]: invoiceMission({
                        templateKey: "business_organization_reconcile_statements",
                        name: "Conciliar 1 extrato das contas da empresa nesta semana.",
                        actionPath: "/reconciliation",
                    }),
                },
                reconciliations: {},
            },
        });

        const summary = await retagWeeklyMissions(
            firestore,
            { dryRun: false, now: NOW_W38, weekId: WEEK, workspaceId: "empresaSemCartao" },
            silent
        );

        expect(summary.repaired).toBe(1);
        expect(written[0].data.templateKey).toBe("business_organization_categorize_week");
    });
});
