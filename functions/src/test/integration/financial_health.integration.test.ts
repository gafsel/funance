/**
 * F2.2 — Bússola da Liberdade contra o Firestore de verdade.
 *
 * Os unitários provam a REGRA de pontuação; aqui provamos a LEITURA: que os
 * saldos saem das contas certas (e do documento de saldo certo, inclusive no
 * formato legado sem `dateKey`), que o realizado sai do `period_summaries`
 * mensal com o join em `categories`, e que os limites vêm do
 * `category_planning` vigente. Mais as três garantias operacionais: número
 * determinístico, segunda execução sem efeito e virada de mês fechando o
 * histórico.
 */

// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import { HealthRepositoryImpl } from "../../features/health/data/repositories/health.repository.impl";
import { FinancialHealthService } from "../../features/health/domain/services/financial_health.service";
import { FinancialHealthTier } from "../../features/health/domain/models/financial_health.model";
import { refreshDirtyWorkspaces } from "../../features/health/presentation/functions/health_handler";

/** 10/09/2026 12:00 em São Paulo. */
const NOW = new Date("2026-09-10T15:00:00.000Z");
/** 01/10/2026 04:30 em São Paulo — o horário do cron mensal. */
const DAY_ONE_OCTOBER = new Date("2026-10-01T07:30:00.000Z");

let firestore: admin.firestore.Firestore;
const workspaces: string[] = [];

function newWorkspace(label: string): string {
    const workspaceId = `ws-health-${label}-${Date.now()}`;
    workspaces.push(workspaceId);
    return workspaceId;
}

async function seedWorkspace(workspaceId: string): Promise<void> {
    await firestore.doc(`workspaces/${workspaceId}`).set({
        name: "Casa", type: "personal", members: ["uid"],
    });
}

async function seedAccount(
    workspaceId: string,
    accountId: string,
    runtimeType: string,
    balances: Array<{ dateKey: string, balance: number, legacy?: boolean }>
): Promise<void> {
    await firestore.doc(`workspaces/${workspaceId}/accounts/${accountId}`).set({
        name: accountId, runtimeType, isDeleted: false, initialBalance: 0,
    });
    for (const entry of balances) {
        await firestore
            .doc(`workspaces/${workspaceId}/accounts/${accountId}/balance/${entry.dateKey}`)
            // `legacy` reproduz o documento anterior a F1.4: id certo, SEM o
            // campo `dateKey`. A consulta indexada não casa com ele; quem o
            // encontra é a varredura ascendente por id.
            .set(entry.legacy
                ? { balance: entry.balance }
                : { dateKey: entry.dateKey, balance: entry.balance, delta: 0 });
    }
}

async function seedCategory(
    workspaceId: string,
    categoryId: string,
    type: "income" | "expense",
    extra: Record<string, any> = {}
): Promise<void> {
    await firestore.doc(`workspaces/${workspaceId}/categories/${categoryId}`).set({
        name: categoryId, icon: "label", color: "#000", type, isDeleted: false, ...extra,
    });
}

async function seedMonthlySummary(
    workspaceId: string,
    monthKey: string,
    categories: Record<string, { actualAmount?: number, generalPlannedAmount?: number }>
): Promise<void> {
    const [year, month] = monthKey.split("-").map(Number);
    const payload: Record<string, any> = {};
    for (const [categoryId, values] of Object.entries(categories)) {
        payload[categoryId] = {
            actualAmount: values.actualAmount ?? 0,
            generalPlannedAmount: values.generalPlannedAmount ?? 0,
            specificPlannedAmount: 0,
        };
    }
    await firestore.doc(`workspaces/${workspaceId}/period_summaries/${monthKey}`).set({
        year, month, week: null, runtimeType: "month", categories: payload,
    });
}

async function seedPlanning(
    workspaceId: string,
    planningId: string,
    categoryId: string,
    amount: number,
    startMonth: string,
    endMonth: string
): Promise<void> {
    await firestore.doc(`workspaces/${workspaceId}/category_planning/${planningId}`).set({
        amount, startMonth, endMonth, category: { id: categoryId, name: categoryId },
    });
}

describe("Bússola da Liberdade (integração com emulador do Firestore)", () => {
    beforeAll(async () => {
        if (admin.apps.length === 0) {
            admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
            admin.firestore().settings({ ignoreUndefinedProperties: true });
        }
        firestore = admin.firestore();
    });

    afterAll(async () => {
        for (const workspaceId of workspaces) {
            await firestore.recursiveDelete(firestore.doc(`workspaces/${workspaceId}`));
        }
        await Promise.all(admin.apps.map((app) => app?.delete()));
    });

    it("calcula um score determinístico a partir de saldos e sumários reais", async () => {
        const workspaceId = newWorkspace("real");
        await seedWorkspace(workspaceId);

        // Reserva: 12.000 em conta corrente + investimento.
        await seedAccount(workspaceId, "cc", "checking", [
            { dateKey: "2026-08-20", balance: 3000 },
            { dateKey: "2026-09-05", balance: 4000 },
        ]);
        // Conta legada, SEM `dateKey`: precisa ser encontrada assim mesmo.
        await seedAccount(workspaceId, "inv", "investment", [
            { dateKey: "2026-09-01", balance: 8000, legacy: true },
        ]);
        // Dívida ESTÁVEL entre o fim de agosto e hoje => Alívio 50.
        await seedAccount(workspaceId, "cartao", "creditCard", [
            { dateKey: "2026-08-31", balance: -2000 },
            { dateKey: "2026-09-08", balance: -2000 },
        ]);
        // Conta APAGADA logicamente: o saldo dela é resíduo e não pode contar.
        await firestore.doc(`workspaces/${workspaceId}/accounts/velha`).set({
            name: "velha", runtimeType: "checking", isDeleted: true, initialBalance: 0,
        });
        await firestore.doc(`workspaces/${workspaceId}/accounts/velha/balance/2026-09-09`)
            .set({ dateKey: "2026-09-09", balance: 999999, delta: 0 });

        await seedCategory(workspaceId, "salario", "income");
        await seedCategory(workspaceId, "mercado", "expense");
        await seedCategory(workspaceId, "lazer", "expense");
        // Categoria de SISTEMA: fica fora de receita, despesa e disciplina.
        await seedCategory(workspaceId, "initial-balance", "income", { isSystem: true });

        // Três meses de despesa de 4.000 => Fôlego = 12.000 / 4.000 = 3 => 50.
        for (const monthKey of ["2026-08", "2026-07", "2026-06"]) {
            await seedMonthlySummary(workspaceId, monthKey, {
                salario: { actualAmount: 8000 },
                mercado: { actualAmount: 3000 },
                lazer: { actualAmount: 1000 },
                "initial-balance": { actualAmount: 50000 },
            });
        }
        // Mês corrente: (8000 − 6800) / 8000 = 15% => Poupança 50.
        await seedMonthlySummary(workspaceId, "2026-09", {
            salario: { actualAmount: 8000 },
            mercado: { actualAmount: 5800 },
            lazer: { actualAmount: 1000 },
        });

        // Agosto: mercado dentro (3000 <= 3200), lazer estourado (1000 > 800).
        await seedPlanning(workspaceId, "p-mercado", "mercado", 3200, "2026-01", "2026-12");
        await seedPlanning(workspaceId, "p-lazer", "lazer", 800, "2026-01", "2026-12");
        // Planejamento FORA do período avaliado: não conta.
        await seedPlanning(workspaceId, "p-antigo", "salario", 1, "2025-01", "2025-12");

        const repository = new HealthRepositoryImpl(firestore);
        const snapshot = await new FinancialHealthService(repository).computeHealth(workspaceId, NOW);

        expect(snapshot.components.folego).toMatchObject({ months: 3, score: 50 });
        expect(snapshot.components.poupanca.score).toBe(50);
        expect(snapshot.components.disciplina).toMatchObject({ within: 1, total: 2, score: 50 });
        expect(snapshot.components.alivio).toMatchObject({ delta: 0, score: 50 });
        // 50 em tudo, com pesos que somam 100.
        expect(snapshot.score).toBe(50);
        expect(snapshot.tier).toBe(FinancialHealthTier.estrategista);
        expect(snapshot.monthKey).toBe("2026-09");
    });

    it("a segunda execução não altera nada (idempotente)", async () => {
        const workspaceId = newWorkspace("idem");
        await seedWorkspace(workspaceId);
        await seedAccount(workspaceId, "cc", "checking", [{ dateKey: "2026-09-01", balance: 9000 }]);
        await seedCategory(workspaceId, "salario", "income");
        await seedCategory(workspaceId, "mercado", "expense");
        for (const monthKey of ["2026-08", "2026-07", "2026-06"]) {
            await seedMonthlySummary(workspaceId, monthKey, {
                salario: { actualAmount: 5000 }, mercado: { actualAmount: 3000 },
            });
        }
        await seedMonthlySummary(workspaceId, "2026-09", {
            salario: { actualAmount: 5000 }, mercado: { actualAmount: 4000 },
        });

        const repository = new HealthRepositoryImpl(firestore);
        const service = new FinancialHealthService(repository);

        const first = await service.refreshHealth(workspaceId, NOW);
        const firstDoc = (await firestore.doc(`workspaces/${workspaceId}`).get()).data()!.financialHealth;

        const second = await service.refreshHealth(workspaceId, NOW);
        const secondDoc = (await firestore.doc(`workspaces/${workspaceId}`).get()).data()!.financialHealth;

        expect(second.score).toBe(first.score);
        expect(second.tier).toBe(first.tier);
        expect(secondDoc).toEqual(firstDoc);

        // E o histórico continua com UM documento do mês, não dois.
        const history = await firestore.collection(`workspaces/${workspaceId}/health_history`).get();
        expect(history.docs.map((d) => d.id)).toEqual(["2026-09"]);
    });

    it("a virada de mês CONGELA o histórico do mês que acabou e reabre o novo", async () => {
        const workspaceId = newWorkspace("virada");
        await seedWorkspace(workspaceId);
        await seedAccount(workspaceId, "cc", "checking", [{ dateKey: "2026-09-20", balance: 18000 }]);
        await seedCategory(workspaceId, "salario", "income");
        await seedCategory(workspaceId, "mercado", "expense");
        for (const monthKey of ["2026-09", "2026-08", "2026-07", "2026-06"]) {
            await seedMonthlySummary(workspaceId, monthKey, {
                salario: { actualAmount: 10000 }, mercado: { actualAmount: 6000 },
            });
        }

        const repository = new HealthRepositoryImpl(firestore);
        const service = new FinancialHealthService(repository);

        // Durante setembro o retrato é escrito no histórico do mês corrente.
        const during = await service.refreshHealth(workspaceId, NOW);
        expect(during.monthKey).toBe("2026-09");

        // Dia 1 de outubro, o cron fecha setembro e abre outubro.
        await service.closeMonth(workspaceId, DAY_ONE_OCTOBER);

        const history = await firestore.collection(`workspaces/${workspaceId}/health_history`).get();
        expect(history.docs.map((d) => d.id).sort()).toEqual(["2026-09", "2026-10"]);

        // O documento de setembro carimba o ÚLTIMO instante de setembro, e não
        // "agora": é ele que congela o mês fechado.
        const september = history.docs.find((d) => d.id === "2026-09")!.data();
        expect((september.computedAt as admin.firestore.Timestamp).toDate().toISOString())
            .toBe("2026-10-01T02:59:59.999Z");

        // O retrato CORRENTE aponta para outubro, nunca para o mês que acabou.
        const workspace = (await firestore.doc(`workspaces/${workspaceId}`).get()).data()!;
        expect(workspace.financialHealth.monthKey).toBe("2026-10");
        // E o marcador de sujo some depois do fechamento.
        expect(workspace.healthDirtyAt).toBeUndefined();
    });

    it("workspace sem conta nenhuma: score 0, Aprendiz, sem erro", async () => {
        const workspaceId = newWorkspace("vazio");
        await seedWorkspace(workspaceId);

        const repository = new HealthRepositoryImpl(firestore);
        const snapshot = await new FinancialHealthService(repository).refreshHealth(workspaceId, NOW);

        expect(snapshot.score).toBe(0);
        expect(snapshot.tier).toBe(FinancialHealthTier.aprendiz);

        const stored = (await firestore.doc(`workspaces/${workspaceId}`).get()).data()!.financialHealth;
        expect(stored.score).toBe(0);
        expect(stored.tier).toBe("aprendiz");
        expect(stored.components.folego).toEqual({ value: 0, score: 0, months: 0 });
    });

    it("o marcador de sujo é uma escrita só e o retrato é lido de volta intacto", async () => {
        const workspaceId = newWorkspace("dirty");
        await seedWorkspace(workspaceId);
        await seedAccount(workspaceId, "cc", "checking", [{ dateKey: "2026-09-01", balance: 100 }]);

        const repository = new HealthRepositoryImpl(firestore);
        const service = new FinancialHealthService(repository);

        await service.markHealthDirty(workspaceId);
        expect((await firestore.doc(`workspaces/${workspaceId}`).get()).data()!.healthDirtyAt).toBeDefined();

        // Primeiro recálculo: não há retrato anterior, então nada a adiar.
        const first = await service.refreshIfDue(workspaceId, NOW);
        expect(first.computed).toBe(true);
        expect((await firestore.doc(`workspaces/${workspaceId}`).get()).data()!.healthDirtyAt).toBeUndefined();

        // Debounce: cinco minutos depois o recálculo é adiado.
        await service.markHealthDirty(workspaceId);
        const soon = await service.refreshIfDue(workspaceId, new Date(NOW.getTime() + 5 * 60 * 1000));
        expect(soon).toMatchObject({ computed: false, debounced: true });
        // O marcador CONTINUA lá: o workspace entra no ciclo seguinte.
        expect((await firestore.doc(`workspaces/${workspaceId}`).get()).data()!.healthDirtyAt).toBeDefined();

        // Onze minutos depois, recalcula e limpa.
        const later = await service.refreshIfDue(workspaceId, new Date(NOW.getTime() + 11 * 60 * 1000));
        expect(later.computed).toBe(true);
        expect((await firestore.doc(`workspaces/${workspaceId}`).get()).data()!.healthDirtyAt).toBeUndefined();

        // O retrato lido de volta é igual ao calculado (ida e volta do mapa).
        const roundTrip = await repository.getCurrent(workspaceId);
        expect(roundTrip!.score).toBe(later.snapshot!.score);
        expect(roundTrip!.monthKey).toBe(later.snapshot!.monthKey);
    });

    it("o cron de 15 min varre SÓ os sujos e esvazia a fila", async () => {
        // A consulta é `healthDirtyAt > epoch`: o Firestore não casa documentos
        // que não têm o campo, então o custo da varredura é o número de
        // workspaces SUJOS, não o tamanho da base. É isso que torna um cron de
        // 15 minutos viável.
        const sujo = newWorkspace("cron-sujo");
        const limpo = newWorkspace("cron-limpo");
        for (const workspaceId of [sujo, limpo]) {
            await seedWorkspace(workspaceId);
            await seedAccount(workspaceId, "cc", "checking", [{ dateKey: "2026-09-01", balance: 500 }]);
        }

        const repository = new HealthRepositoryImpl(firestore);
        await new FinancialHealthService(repository).markHealthDirty(sujo);

        const dirty = await firestore
            .collection("workspaces")
            .where("healthDirtyAt", ">", admin.firestore.Timestamp.fromMillis(0))
            .orderBy("healthDirtyAt")
            .get();

        const ids = dirty.docs.map((d) => d.id);
        expect(ids).toContain(sujo);
        expect(ids).not.toContain(limpo);

        const result = await refreshDirtyWorkspaces(() => NOW);

        expect(result.failed).toBe(0);
        expect(result.refreshed).toBeGreaterThanOrEqual(1);
        expect(result.completed).toBe(true);

        // A fila esvaziou e só o sujo ganhou retrato.
        const stillDirty = await firestore
            .collection("workspaces")
            .where("healthDirtyAt", ">", admin.firestore.Timestamp.fromMillis(0))
            .orderBy("healthDirtyAt")
            .get();
        expect(stillDirty.docs.map((d) => d.id)).not.toContain(sujo);

        expect((await firestore.doc(`workspaces/${sujo}`).get()).data()!.financialHealth).toBeDefined();
        expect((await firestore.doc(`workspaces/${limpo}`).get()).data()!.financialHealth).toBeUndefined();
    });

    it("um workspace que não existe não é criado pelo retrato", async () => {
        // `saveCurrent` usa `update`, não `set(merge)`: um workspace apagado
        // entre a leitura e a escrita não pode voltar à vida como fantasma.
        const repository = new HealthRepositoryImpl(firestore);
        const service = new FinancialHealthService(repository);

        await expect(service.refreshHealth("ws-health-inexistente", NOW)).resolves.toBeDefined();

        const doc = await firestore.doc("workspaces/ws-health-inexistente").get();
        expect(doc.exists).toBe(false);

        // O histórico, esse, é uma subcoleção e pode existir sob um documento
        // ausente — limpamos para não deixar lixo no emulador.
        await firestore.recursiveDelete(firestore.doc("workspaces/ws-health-inexistente"));
    });
});
