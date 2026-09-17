/**
 * F1.5 — sumário de planejamento com horizonte rolante.
 *
 * Cobre a aritmética (`calculatePlanningImpacts`), o gatilho (estorno exato +
 * reaplicação) e o cron mensal (só os meses novos, legados adotados sem
 * reaplicar).
 */

import {
    PLANNING_FULLY_SUMMARIZED,
    PLANNING_LEGACY_CURSOR_FIELD,
    SummaryService,
    intersectPlanningWindow,
    planningHorizon,
    resolveAppliedWindow,
    weeksStartingInMonth,
} from "../features/finance/domain/services/summary.service";
import {
    CategoryPlanningMarks,
    CategoryPlanningModel,
    PeriodSummaryUpdateModel,
} from "../features/finance/domain/models/finance.models";
import { CategoryModel, CategoryType } from "../features/workspace/domain/models/category.model";
import { formatWeekId } from "../core/utils/week.utils";
import { shiftMonthKey, toMonthKey } from "../core/utils/month_key";

const CATEGORY: CategoryModel = {
    id: "cat-moradia",
    name: "Moradia",
    icon: "home",
    color: "#42A5F5",
    type: CategoryType.expense,
    isDeleted: false,
    allocation: "essential",
};

interface AppliedCall {
    workspaceId: string;
    updates: PeriodSummaryUpdateModel[];
    marks?: CategoryPlanningMarks;
    planningId?: string;
}

/** Repositório falso com só o que o serviço de planejamento usa. */
class FakeRepository {
    calls: AppliedCall[] = [];
    pending: any[][] = [];
    /** Documentos da varredura completa, em ordem de caminho. */
    scanDocs: any[] = [];
    /** Cursor recebido em cada chamada da varredura (null = do início). */
    scanCalls: Array<string | null> = [];
    checkpoints = new Map<string, string | null>();

    getCategoryPlanningRef(workspaceId: string, planningId: string): any {
        return { __workspaceId: workspaceId, id: planningId };
    }

    async applyPlanningImpacts(workspaceId: string, updates: PeriodSummaryUpdateModel[], marks?: any): Promise<void> {
        this.calls.push({
            workspaceId,
            updates,
            marks: marks?.data,
            planningId: marks?.ref?.id,
        });
    }

    async getCategoryPlanningsPendingSummary(_horizon: string, _pageSize: number, cursor?: any): Promise<any> {
        const index = cursor ?? 0;
        const items = this.pending[index] ?? [];
        return { items, cursor: index + 1 < this.pending.length ? index + 1 : null };
    }

    async scanCategoryPlannings(pageSize: number, afterPath?: string | null): Promise<any> {
        this.scanCalls.push(afterPath ?? null);

        const start = afterPath
            ? this.scanDocs.findIndex((doc) => doc.ref.path === afterPath) + 1
            : 0;
        const items = this.scanDocs.slice(start, start + pageSize);

        return {
            items,
            nextPath: items.length < pageSize ? null : items[items.length - 1].ref.path,
        };
    }

    async getCronCheckpoint(field: string): Promise<string | null> {
        return this.checkpoints.get(field) ?? null;
    }

    async setCronCheckpoint(field: string, value: string | null): Promise<void> {
        this.checkpoints.set(field, value);
    }
}

/** Planejamento legado (sem marcadores) pronto para a varredura. */
function scanDoc(id: string, overrides: Record<string, any> = {}): any {
    return {
        ...planning({ id, amount: 1000, startMonth: "2026-01", endMonth: "2030-12" }),
        workspaceId: "w1",
        ref: { id, path: `workspaces/w1/category_planning/${id}` },
        ...overrides,
    };
}

function buildService(): { service: SummaryService, repository: FakeRepository } {
    const repository = new FakeRepository();
    return { service: new SummaryService(repository as any), repository };
}

function planning(overrides: Partial<CategoryPlanningModel> = {}): CategoryPlanningModel {
    return {
        id: "plan-1",
        category: CATEGORY,
        amount: 1200,
        startMonth: "2026-01",
        endMonth: "2026-12",
        ...overrides,
    };
}

/** Soma dos deltas do impacto, por documento (`YYYY-MM`, `YYYY` ou `YYYY-Www`). */
function byDocument(updates: PeriodSummaryUpdateModel[]): Map<string, number> {
    const totals = new Map<string, number>();

    for (const update of updates) {
        const id = update.week !== undefined
            ? formatWeekId({ year: update.year, week: update.week })
            : update.month !== undefined
                ? `${update.year}-${String(update.month).padStart(2, "0")}`
                : `${update.year}`;
        totals.set(id, (totals.get(id) ?? 0) + (update.generalPlannedDelta ?? 0));
    }

    return totals;
}

describe("calculatePlanningImpacts (F1.5)", () => {
    const { service } = buildService();

    it("respeita o intervalo do planejamento e a janela pedida", () => {
        const impacts = service.calculatePlanningImpacts(
            planning({ startMonth: "2026-03", endMonth: "2026-05" }),
            1,
            { from: "2026-01", until: "2026-12" }
        );

        const months = [...byDocument(impacts).keys()].filter((id) => /^\d{4}-\d{2}$/.test(id)).sort();
        expect(months).toEqual(["2026-03", "2026-04", "2026-05"]);
    });

    it("devolve vazio quando a janela não cruza o planejamento", () => {
        const impacts = service.calculatePlanningImpacts(
            planning({ startMonth: "2027-01", endMonth: "2027-06" }),
            1,
            { from: "2026-01", until: "2026-12" }
        );
        expect(impacts).toEqual([]);
    });

    it("o mês recebe o amount e o ano recebe a soma dos meses aplicados", () => {
        const impacts = service.calculatePlanningImpacts(
            planning({ amount: 1000, startMonth: "2026-01", endMonth: "2026-03" }),
            1,
            { from: "2026-01", until: "2026-12" }
        );

        const totals = byDocument(impacts);
        expect(totals.get("2026-01")).toBeCloseTo(1000, 6);
        expect(totals.get("2026-02")).toBeCloseTo(1000, 6);
        expect(totals.get("2026-03")).toBeCloseTo(1000, 6);
        // Três meses aplicados em 2026 => 3000 no documento do ano (a regra
        // antiga jogava amount * 12 de uma vez em janeiro).
        expect(totals.get("2026")).toBeCloseTo(3000, 6);
    });

    it("cada semana entra UMA vez, no mês do seu domingo inicial", () => {
        const impacts = service.calculatePlanningImpacts(
            planning({ amount: 3000, startMonth: "2026-04", endMonth: "2026-04" }),
            1,
            { from: "2026-04", until: "2026-04" }
        );

        const weeks = impacts.filter((impact) => impact.week !== undefined);
        const ids = weeks.map((impact) => formatWeekId({ year: impact.year, week: impact.week! }));

        // Nenhum id repetido: o bug antigo emitia a semana pelo dia 1 E pelo
        // domingo seguinte quando o mês começava no meio da semana.
        expect(new Set(ids).size).toBe(ids.length);
        // Abril de 2026 começa numa quarta: a semana do dia 1 pertence a março.
        expect(ids).not.toContain("2026-W13");
    });

    it("a soma das semanas fica próxima do valor do mês", () => {
        for (const monthKey of ["2026-01", "2026-02", "2026-04", "2026-11", "2024-02"]) {
            const impacts = service.calculatePlanningImpacts(
                planning({ amount: 3000, startMonth: monthKey, endMonth: monthKey }),
                1,
                { from: monthKey, until: monthKey }
            );

            const weekly = impacts
                .filter((impact) => impact.week !== undefined)
                .reduce((total, impact) => total + (impact.generalPlannedDelta ?? 0), 0);

            // 4 ou 5 semanas de amount/dias*7: entre ~93% e ~117% do mês.
            expect({ monthKey, ratio: weekly / 3000 }).toEqual({
                monthKey,
                ratio: expect.closeTo(1, 0),
            });
            expect(weekly).toBeGreaterThan(3000 * 0.9);
            expect(weekly).toBeLessThan(3000 * 1.2);
        }
    });

    it("multiplicador -1 devolve exatamente o oposto", () => {
        const window = { from: "2026-01", until: "2026-12" };
        const aplicado = byDocument(service.calculatePlanningImpacts(planning(), 1, window));
        const estornado = byDocument(service.calculatePlanningImpacts(planning(), -1, window));

        expect([...estornado.keys()].sort()).toEqual([...aplicado.keys()].sort());
        for (const [id, value] of aplicado) {
            expect({ id, value: estornado.get(id)! + value }).toEqual({ id, value: expect.closeTo(0, 9) });
        }
    });

    it("weeksStartingInMonth cobre todas as semanas sem sobreposição entre meses", () => {
        const janeiro = weeksStartingInMonth("2026-01").map(formatWeekId);
        const fevereiro = weeksStartingInMonth("2026-02").map(formatWeekId);

        expect(janeiro.length).toBeGreaterThanOrEqual(4);
        expect(janeiro.filter((id) => fevereiro.includes(id))).toEqual([]);
    });
});

describe("processCategoryPlanningChange (F1.5)", () => {
    const NOW = new Date("2026-09-15T15:00:00.000Z");
    const CURRENT = toMonthKey(NOW);
    const HORIZON = planningHorizon(NOW);

    it("horizonte é o mês corrente + 11", () => {
        expect(CURRENT).toBe("2026-09");
        expect(HORIZON).toBe("2027-08");
    });

    it("criação aplica de max(startMonth, mês corrente) até o horizonte e grava os marcadores", async () => {
        const { service, repository } = buildService();
        const novo = planning({ startMonth: "2026-01", endMonth: "2030-12", amount: 1000 });

        await service.processCategoryPlanningChange("w1", null, novo, NOW);

        expect(repository.calls).toHaveLength(1);
        const call = repository.calls[0];

        const months = [...byDocument(call.updates).keys()].filter((id) => /^\d{4}-\d{2}$/.test(id)).sort();
        expect(months[0]).toBe("2026-09");
        expect(months[months.length - 1]).toBe("2027-08");
        expect(months).toHaveLength(12);

        expect(call.marks).toEqual({
            summarizedUntil: "2027-08",
            appliedAmount: 1000,
            appliedAmountCents: 100000,
            appliedFrom: "2026-09",
            appliedUntil: "2027-08",
        });
        expect(call.planningId).toBe("plan-1");
    });

    it("planejamento que cabe no horizonte é marcado como concluído", async () => {
        const { service, repository } = buildService();
        const novo = planning({ startMonth: "2026-09", endMonth: "2026-11" });

        await service.processCategoryPlanningChange("w1", null, novo, NOW);

        expect(repository.calls[0].marks).toMatchObject({
            summarizedUntil: PLANNING_FULLY_SUMMARIZED,
            appliedFrom: "2026-09",
            appliedUntil: "2026-11",
        });
    });

    it("planejamento inteiramente no passado não aplica nada", async () => {
        const { service, repository } = buildService();
        const novo = planning({ startMonth: "2025-01", endMonth: "2025-12" });

        await service.processCategoryPlanningChange("w1", null, novo, NOW);

        expect(repository.calls[0].updates).toEqual([]);
        expect(repository.calls[0].marks).toEqual({
            summarizedUntil: PLANNING_FULLY_SUMMARIZED,
            appliedAmount: null,
            appliedAmountCents: null,
            appliedFrom: null,
            appliedUntil: null,
        });
    });

    it("alterar o valor estorna o aplicado e reaplica: o líquido é a diferença", async () => {
        const { service, repository } = buildService();

        const before = planning({
            amount: 1000,
            startMonth: "2026-01",
            endMonth: "2030-12",
            summarizedUntil: "2027-08",
            appliedAmount: 1000,
            appliedAmountCents: 100000,
            appliedFrom: "2026-09",
            appliedUntil: "2027-08",
        });
        const after = { ...before, amount: 1500 };

        await service.processCategoryPlanningChange("w1", before, after, NOW);

        const totals = byDocument(repository.calls[0].updates);
        expect(totals.get("2026-09")).toBeCloseTo(500, 6);
        expect(totals.get("2027-08")).toBeCloseTo(500, 6);
        // O ano recebe 500 por mês aplicado (4 meses de 2026, 8 de 2027).
        expect(totals.get("2026")).toBeCloseTo(4 * 500, 6);
        expect(totals.get("2027")).toBeCloseTo(8 * 500, 6);
    });

    it("encurtar o período zera os meses que saíram e não toca nos que ficaram", async () => {
        const { service, repository } = buildService();

        const before = planning({
            amount: 1000,
            startMonth: "2026-01",
            endMonth: "2030-12",
            summarizedUntil: "2027-08",
            appliedAmount: 1000,
            appliedAmountCents: 100000,
            appliedFrom: "2026-09",
            appliedUntil: "2027-08",
        });
        const after = { ...before, endMonth: "2026-12" };

        await service.processCategoryPlanningChange("w1", before, after, NOW);

        const totals = byDocument(repository.calls[0].updates);
        // Meses que continuam valendo: estorno + reaplicação se anulam.
        expect(totals.get("2026-09")).toBeCloseTo(0, 9);
        expect(totals.get("2026-12")).toBeCloseTo(0, 9);
        // Meses que saíram do período: só o estorno.
        expect(totals.get("2027-01")).toBeCloseTo(-1000, 6);
        expect(totals.get("2027-08")).toBeCloseTo(-1000, 6);

        expect(repository.calls[0].marks).toMatchObject({
            summarizedUntil: PLANNING_FULLY_SUMMARIZED,
            appliedUntil: "2026-12",
        });
    });

    it("apagar estorna exatamente o aplicado e não grava marcador", async () => {
        const { service, repository } = buildService();

        const before = planning({
            amount: 1000,
            summarizedUntil: "2027-08",
            appliedAmount: 1000,
            appliedAmountCents: 100000,
            appliedFrom: "2026-09",
            appliedUntil: "2027-08",
        });

        await service.processCategoryPlanningChange("w1", before, null, NOW);

        const totals = byDocument(repository.calls[0].updates);
        expect(totals.get("2026-09")).toBeCloseTo(-1000, 6);
        expect(totals.get("2027-08")).toBeCloseTo(-1000, 6);
        expect(repository.calls[0].marks).toBeUndefined();
    });

    it("estorna pelo valor APLICADO, mesmo que o amount atual seja outro", async () => {
        const { service, repository } = buildService();

        const before = planning({
            amount: 7777, // valor corrente, irrelevante para o estorno
            summarizedUntil: "2027-08",
            appliedAmount: 1000,
            appliedAmountCents: 100000,
            appliedFrom: "2026-09",
            appliedUntil: "2026-10",
        });

        await service.processCategoryPlanningChange("w1", before, null, NOW);

        const totals = byDocument(repository.calls[0].updates);
        expect(totals.get("2026-09")).toBeCloseTo(-1000, 6);
        expect(totals.get("2026-10")).toBeCloseTo(-1000, 6);
        expect(totals.has("2026-11")).toBe(false);
    });

    it("planejamento legado (sem marcadores) é estornado pela janela que o gatilho antigo aplicaria", async () => {
        const { service, repository } = buildService();

        const before = planning({ amount: 1000, startMonth: "2026-01", endMonth: "2030-12" });

        await service.processCategoryPlanningChange("w1", before, null, NOW);

        const totals = byDocument(repository.calls[0].updates);
        expect(totals.get("2026-09")).toBeCloseTo(-1000, 6);
        expect(totals.get("2027-08")).toBeCloseTo(-1000, 6);
        expect(totals.has("2026-08")).toBe(false);
    });

    it("não faz nada quando before e after são nulos", async () => {
        const { service, repository } = buildService();
        await service.processCategoryPlanningChange("w1", null, null, NOW);
        expect(repository.calls).toEqual([]);
    });

    it("resolveAppliedWindow prefere os campos persistidos", () => {
        const comMarcas = planning({
            summarizedUntil: "2027-08",
            appliedAmount: 500,
            appliedAmountCents: 50000,
            appliedFrom: "2026-09",
            appliedUntil: "2026-12",
        });
        expect(resolveAppliedWindow(comMarcas, CURRENT, HORIZON)).toEqual({
            from: "2026-09",
            until: "2026-12",
            amount: 500,
        });

        // Marcado como sumarizado, mas sem nada aplicado: nada a estornar.
        const semAplicacao = planning({ summarizedUntil: PLANNING_FULLY_SUMMARIZED, appliedFrom: null, appliedUntil: null });
        expect(resolveAppliedWindow(semAplicacao, CURRENT, HORIZON)).toBeNull();
    });

    it("intersectPlanningWindow devolve null para intervalo vazio", () => {
        expect(intersectPlanningWindow("2026-01", "2026-03", "2026-04", "2026-12")).toBeNull();
        expect(intersectPlanningWindow("2026-01", "2026-12", "2026-03", "2026-05"))
            .toEqual({ from: "2026-03", until: "2026-05" });
    });
});

describe("generateCategoryPlanningSummaries (cron mensal, F1.5)", () => {
    const NOW = new Date("2026-10-01T04:00:00.000Z"); // dia 1, 01h de Brasília
    const HORIZON = planningHorizon(NOW);

    it("horizonte do mês seguinte avança um mês", () => {
        expect(toMonthKey(NOW)).toBe("2026-10");
        expect(HORIZON).toBe("2027-09");
    });

    it("aplica SÓ o mês novo em quem já estava sumarizado", async () => {
        const { service, repository } = buildService();

        repository.pending = [[{
            ...planning({ amount: 1000, startMonth: "2026-01", endMonth: "2030-12" }),
            summarizedUntil: "2027-08",
            appliedAmount: 1000,
            appliedAmountCents: 100000,
            appliedFrom: "2026-09",
            appliedUntil: "2027-08",
            workspaceId: "w1",
            ref: { id: "plan-1" },
        }]];

        await service.generateCategoryPlanningSummaries(NOW);

        const call = repository.calls[0];
        const months = [...byDocument(call.updates).keys()].filter((id) => /^\d{4}-\d{2}$/.test(id));
        expect(months).toEqual(["2027-09"]);

        expect(call.marks).toEqual({
            summarizedUntil: "2027-09",
            appliedAmount: 1000,
            appliedAmountCents: 100000,
            appliedFrom: "2026-09",
            appliedUntil: "2027-09",
        });
    });

    it("pagina por cursor, sem limite global", async () => {
        const { service, repository } = buildService();

        const build = (id: string) => ({
            ...planning({ id, amount: 100, startMonth: "2026-01", endMonth: "2030-12" }),
            summarizedUntil: "2027-08",
            workspaceId: "w1",
            ref: { id },
        });

        repository.pending = [[build("p1"), build("p2")], [build("p3")]];

        await service.generateCategoryPlanningSummaries(NOW);

        expect(repository.calls.map((call) => call.planningId)).toEqual(["p1", "p2", "p3"]);
    });

    it("adota o legado (sem summarizedUntil) sem reaplicar impacto nenhum", async () => {
        const { service, repository } = buildService();

        repository.scanDocs = [scanDoc("plan-legado")];

        await service.generateCategoryPlanningSummaries(NOW);

        expect(repository.calls).toHaveLength(1);
        // Nenhum impacto: o gatilho antigo já aplicou esta janela. Reaplicar
        // aqui dobraria o planejado de toda a base legada.
        expect(repository.calls[0].updates).toEqual([]);
        expect(repository.calls[0].marks).toEqual({
            summarizedUntil: "2027-09",
            appliedAmount: 1000,
            appliedAmountCents: 100000,
            appliedFrom: "2026-10",
            appliedUntil: "2027-09",
        });
    });

    it("ignora na varredura quem já tem marcador", async () => {
        const { service, repository } = buildService();

        repository.scanDocs = [
            scanDoc("ok", { summarizedUntil: "2027-09" }),
            scanDoc("concluido", { summarizedUntil: PLANNING_FULLY_SUMMARIZED }),
        ];

        await service.generateCategoryPlanningSummaries(NOW);

        expect(repository.calls).toEqual([]);
    });

    it("um planejamento que acaba dentro do horizonte é concluído pelo cron", async () => {
        const { service, repository } = buildService();

        repository.pending = [[{
            ...planning({ amount: 100, startMonth: "2026-01", endMonth: "2027-02" }),
            summarizedUntil: "2027-08",
            appliedAmount: 100,
            appliedAmountCents: 10000,
            appliedFrom: "2026-09",
            appliedUntil: "2027-02",
            workspaceId: "w1",
            ref: { id: "plan-1" },
        }]];

        await service.generateCategoryPlanningSummaries(NOW);

        expect(repository.calls[0].updates).toEqual([]);
        expect(repository.calls[0].marks).toMatchObject({
            summarizedUntil: PLANNING_FULLY_SUMMARIZED,
            appliedUntil: "2027-02",
        });
    });

    it("varre mais de uma página e zera o checkpoint ao chegar ao fim", async () => {
        const { service, repository } = buildService();
        repository.scanDocs = Array.from({ length: 250 }, (_, i) => scanDoc(`p${String(i).padStart(4, "0")}`));

        await service.generateCategoryPlanningSummaries(NOW);

        expect(repository.calls).toHaveLength(250);
        // Três consultas: do início, depois do doc 200 e a página final vazia.
        expect(repository.scanCalls[0]).toBeNull();
        expect(repository.scanCalls[1]).toBe("workspaces/w1/category_planning/p0199");
        // Coleção acabou: o checkpoint volta a null e a próxima execução
        // recomeça do início.
        expect(repository.checkpoints.get(PLANNING_LEGACY_CURSOR_FIELD)).toBeNull();
    });

    it("retoma do checkpoint gravado na execução anterior", async () => {
        const { service, repository } = buildService();
        repository.scanDocs = Array.from({ length: 10 }, (_, i) => scanDoc(`p${String(i).padStart(4, "0")}`));
        repository.checkpoints.set(PLANNING_LEGACY_CURSOR_FIELD, "workspaces/w1/category_planning/p0006");

        await service.generateCategoryPlanningSummaries(NOW);

        expect(repository.scanCalls[0]).toBe("workspaces/w1/category_planning/p0006");
        // Só os três últimos foram adotados: os sete primeiros ficaram na
        // execução anterior.
        expect(repository.calls.map((call) => call.planningId)).toEqual(["p0007", "p0008", "p0009"]);
    });

    it("o teto por execução conta só as ADOÇÕES e a próxima execução continua dali", async () => {
        const { service, repository } = buildService();
        // 2000 legados: exatamente o teto de adoções por execução.
        repository.scanDocs = Array.from({ length: 2000 }, (_, i) => scanDoc(`p${String(i).padStart(4, "0")}`));

        await service.generateCategoryPlanningSummaries(NOW);

        expect(repository.calls).toHaveLength(2000);
        const checkpoint = repository.checkpoints.get(PLANNING_LEGACY_CURSOR_FIELD);
        expect(checkpoint).toBe("workspaces/w1/category_planning/p1999");

        // Segunda execução: retoma do checkpoint, não do começo.
        repository.calls = [];
        repository.scanCalls = [];
        await service.generateCategoryPlanningSummaries(NOW);

        expect(repository.scanCalls[0]).toBe(checkpoint);
        expect(repository.calls).toHaveLength(0);
        expect(repository.checkpoints.get(PLANNING_LEGACY_CURSOR_FIELD)).toBeNull();
    });

    it("documento já marcado não consome o teto de adoções", async () => {
        const { service, repository } = buildService();
        // 2000 já marcados + 5 legados no fim: sem o teto contar só as
        // adoções, os cinco do fim nunca seriam alcançados.
        repository.scanDocs = [
            ...Array.from({ length: 2000 }, (_, i) => scanDoc(`a${String(i).padStart(4, "0")}`, { summarizedUntil: "2027-09" })),
            ...Array.from({ length: 5 }, (_, i) => scanDoc(`b${i}`)),
        ];

        await service.generateCategoryPlanningSummaries(NOW);

        expect(repository.calls.map((call) => call.planningId)).toEqual(["b0", "b1", "b2", "b3", "b4"]);
        expect(repository.checkpoints.get(PLANNING_LEGACY_CURSOR_FIELD)).toBeNull();
    });

    it("mês a mês, doze execuções aplicam doze meses novos — nunca dois", async () => {
        const { service, repository } = buildService();

        const state = {
            ...planning({ amount: 600, startMonth: "2026-09", endMonth: "2040-12" }),
            summarizedUntil: "2027-08",
            appliedAmount: 600,
            appliedAmountCents: 60000,
            appliedFrom: "2026-09",
            appliedUntil: "2027-08",
            workspaceId: "w1",
            ref: { id: "plan-1" },
        };

        for (let i = 0; i < 12; i++) {
            repository.calls = [];
            const now = new Date(Date.UTC(2026, 9 + i, 1, 4));
            repository.pending = [[{ ...state }]];

            await service.generateCategoryPlanningSummaries(now);

            const call = repository.calls[0];
            const months = [...byDocument(call.updates).keys()].filter((id) => /^\d{4}-\d{2}$/.test(id));
            expect({ i, months }).toEqual({ i, months: [shiftMonthKey(toMonthKey(now), 11)] });

            Object.assign(state, call.marks);
        }

        expect(state.summarizedUntil).toBe("2028-08");
        expect(state.appliedUntil).toBe("2028-08");
    });
});
