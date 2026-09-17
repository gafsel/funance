// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import { handleOrderWritten } from "../../features/finance/presentation/functions/order_handler";
import { handleAccountUpdated } from "../../features/finance/presentation/functions/account_handler";
import { handleCategoryPlanningWritten } from "../../features/finance/presentation/functions/category_planning_handler";
import { handleGoalWritten } from "../../features/goal/presentation/functions/gamification_handler";
import { container } from "../../core/container";
import { CategoryModel, CategoryType } from "../../features/workspace/domain/models/category.model";
import { shiftMonthKey, toMonthKey } from "../../core/utils/month_key";

/**
 * F1.10 — AS GUARDAS POR CONTEÚDO DOS ESPELHOS INTEIROS.
 *
 * A escrita do passo derivado (`amountCents` & cia.) produz um evento novo. Se
 * esse evento não sair cedo, a migração dos 4.540 documentos de produção
 * dispara o gatilho inteiro de cada um: `orders/{id}/history` do nada,
 * `syncInstallments` de graça, badges reavaliados, planejamento estornado e
 * reaplicado.
 *
 * O emulador NÃO dispara triggers, então o eco é simulado invocando o handler
 * com o par (before, after) que o Eventarc entregaria — before = documento sem
 * o espelho, after = documento com ele, nada mais mudando.
 */

let firestore: admin.firestore.Firestore;

const workspaces: string[] = [];
const eventId = () => `evt-cents-${Date.now()}-${Math.floor(Math.random() * 100000)}`;

function newWorkspace(label: string): string {
    const workspaceId = `ws-guard-${label}-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    workspaces.push(workspaceId);
    return workspaceId;
}

const CATEGORY: CategoryModel = {
    id: "cat-moradia",
    name: "Moradia",
    icon: "home",
    color: "#42A5F5",
    type: CategoryType.expense,
    isDeleted: false,
    allocation: "essential",
};

beforeAll(async () => {
    if (admin.apps.length === 0) {
        admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
        admin.firestore().settings({ ignoreUndefinedProperties: false });
    }
    firestore = admin.firestore();
});

afterAll(async () => {
    for (const workspaceId of workspaces) {
        await firestore.recursiveDelete(firestore.doc(`workspaces/${workspaceId}`));
    }
});

describe("ORDER_DERIVED_FIELDS — a escrita do amountCents não vira histórico", () => {
    async function seedOrder(workspaceId: string): Promise<Record<string, any>> {
        const data = {
            amount: 502.4,
            description: "Notebook",
            dueDay: 10,
            startMonth: "2026-03",
            installmentType: "single",
            status: "active",
            type: "expense",
            accounts: {},
            accountIds: [],
            category: CATEGORY,
        };
        await firestore.doc(`workspaces/${workspaceId}/orders/o1`).set(data);
        return data;
    }

    const historyCount = async (workspaceId: string) =>
        (await firestore.collection(`workspaces/${workspaceId}/orders/o1/history`).get()).size;

    const installmentCount = async (workspaceId: string) =>
        (await firestore.collection(`workspaces/${workspaceId}/installments`).get()).size;

    it("a criação completa o espelho e faz o trabalho normal", async () => {
        const workspaceId = newWorkspace("order-create");
        const data = await seedOrder(workspaceId);

        await handleOrderWritten(null, data, { workspaceId, orderId: "o1", eventId: eventId() });

        // Passo derivado rodou...
        expect((await firestore.doc(`workspaces/${workspaceId}/orders/o1`).get()).data()?.amountCents).toBe(50240);
        // ...e o gatilho fez o que faz: parcela criada e histórico gravado.
        expect(await installmentCount(workspaceId)).toBe(1);
        expect(await historyCount(workspaceId)).toBe(1);
    });

    it("o ECO da escrita do espelho não faz NADA", async () => {
        const workspaceId = newWorkspace("order-eco");
        const data = await seedOrder(workspaceId);

        await handleOrderWritten(null, data, { workspaceId, orderId: "o1", eventId: eventId() });
        const historyBefore = await historyCount(workspaceId);
        const installmentsBefore = await installmentCount(workspaceId);

        // O par que a escrita de `amountCents` produz: só o espelho mudou.
        await handleOrderWritten(
            data,
            { ...data, amountCents: 50240 },
            { workspaceId, orderId: "o1", eventId: eventId() }
        );

        expect(await historyCount(workspaceId)).toBe(historyBefore);
        expect(await installmentCount(workspaceId)).toBe(installmentsBefore);
    });

    it("uma mudança REAL ao lado do espelho não é engolida pela guarda", async () => {
        const workspaceId = newWorkspace("order-real");
        const data = await seedOrder(workspaceId);

        await handleOrderWritten(null, data, { workspaceId, orderId: "o1", eventId: eventId() });
        const historyBefore = await historyCount(workspaceId);

        await handleOrderWritten(
            data,
            { ...data, amountCents: 50240, description: "Notebook novo" },
            { workspaceId, orderId: "o1", eventId: eventId() }
        );

        expect(await historyCount(workspaceId)).toBe(historyBefore + 1);
    });
});

describe("GOAL_DERIVED_FIELDS — a escrita dos *Cents não reavalia a meta", () => {
    const goalDoc = (over: Record<string, unknown> = {}) => ({
        name: "Reserva",
        runtimeType: "saveMoney",
        targetAmount: 1000,
        currentAmount: 0,
        accountId: "acc-1",
        startDate: admin.firestore.Timestamp.fromDate(new Date("2026-01-01T15:00:00.000Z")),
        deadline: admin.firestore.Timestamp.fromDate(new Date("2026-12-31T15:00:00.000Z")),
        isDeleted: false,
        ...over,
    });

    it("a criação completa o espelho", async () => {
        const workspaceId = newWorkspace("goal-create");
        const data = goalDoc();
        await firestore.doc(`workspaces/${workspaceId}/goals/g1`).set(data);

        await handleGoalWritten(null, data, { workspaceId, goalId: "g1", eventId: eventId() });

        const goal = (await firestore.doc(`workspaces/${workspaceId}/goals/g1`).get()).data()!;
        expect(goal.targetAmountCents).toBe(100000);
        expect(goal.currentAmountCents).toBe(0);
    });

    it("o ECO não chama nem o recálculo nem os badges", async () => {
        const workspaceId = newWorkspace("goal-eco");
        const data = goalDoc();
        await firestore.doc(`workspaces/${workspaceId}/goals/g1`).set(data);

        const recompute = jest.spyOn(container.goalService, "recomputeGoal");
        const badges = jest.spyOn(container.gamificationService, "checkGoalBadges");

        await handleGoalWritten(
            data,
            { ...data, targetAmountCents: 100000, currentAmountCents: 0 },
            { workspaceId, goalId: "g1", eventId: eventId() }
        );

        expect(recompute).not.toHaveBeenCalled();
        expect(badges).not.toHaveBeenCalled();

        recompute.mockRestore();
        badges.mockRestore();
    });

    it("os badges recebem o valor RECALCULADO, não o documento cru do evento", async () => {
        const workspaceId = newWorkspace("goal-badges");
        // Meta de cofrinho: o progresso é o SALDO da conta, e o recálculo o
        // encontra sozinho. O documento do evento diz `currentAmount: 0`.
        const data = goalDoc({ accountId: "acc-cofre" });
        await firestore.doc(`workspaces/${workspaceId}/goals/g1`).set(data);
        await firestore.doc(`workspaces/${workspaceId}/accounts/acc-cofre`).set({
            name: "Cofrinho", runtimeType: "investment", isDeleted: false, initialBalance: 0,
        });
        await firestore.doc(`workspaces/${workspaceId}/accounts/acc-cofre/balance/2026-02-01`).set({
            dateKey: "2026-02-01", delta: 263.41, balance: 263.41, deltaCents: 26341, balanceCents: 26341,
        });

        const badges = jest.spyOn(container.gamificationService, "checkGoalBadges")
            .mockResolvedValue(undefined as never);
        jest.spyOn(container.gamificationService, "checkSimpleGoalBadges")
            .mockResolvedValue(undefined as never);

        await handleGoalWritten(null, data, { workspaceId, goalId: "g1", eventId: eventId() });

        expect(badges).toHaveBeenCalledTimes(1);
        const evaluated = badges.mock.calls[0][1] as Record<string, unknown>;
        // O documento cru dizia 0; o recálculo achou o saldo do cofrinho.
        expect(evaluated.currentAmount).toBe(263.41);
        expect(evaluated.currentAmountCents).toBe(26341);

        jest.restoreAllMocks();
    });
});

describe("CATEGORY_PLANNING_DERIVED_FIELDS — o espelho não estorna o planejamento", () => {
    // O gatilho aplica de `max(startMonth, mês corrente)` em diante, então o
    // mês conferido é o CORRENTE — o único que existe em qualquer data.
    const CURRENT_MONTH = toMonthKey(new Date());

    const planningDoc = (over: Record<string, unknown> = {}) => ({
        category: CATEGORY,
        amount: 1000,
        startMonth: CURRENT_MONTH,
        endMonth: shiftMonthKey(CURRENT_MONTH, 6),
        ...over,
    });

    const summaryTotal = async (workspaceId: string) => {
        const doc = await firestore.doc(`workspaces/${workspaceId}/period_summaries/${CURRENT_MONTH}`).get();
        return doc.data()?.categories?.[CATEGORY.id]?.generalPlannedAmountCents ?? 0;
    };

    it("a criação aplica o planejado e completa o espelho", async () => {
        const workspaceId = newWorkspace("plan-create");
        const data = planningDoc();
        await firestore.doc(`workspaces/${workspaceId}/category_planning/p1`).set(data);

        await handleCategoryPlanningWritten(null, data, {
            workspaceId, planningId: "p1", eventId: eventId(),
        });

        expect((await firestore.doc(`workspaces/${workspaceId}/category_planning/p1`).get()).data()?.amountCents)
            .toBe(100000);
        expect(await summaryTotal(workspaceId)).toBe(100000);
    });

    it("o ECO do espelho não estorna nem reaplica", async () => {
        const workspaceId = newWorkspace("plan-eco");
        const data = planningDoc();
        await firestore.doc(`workspaces/${workspaceId}/category_planning/p1`).set(data);

        await handleCategoryPlanningWritten(null, data, {
            workspaceId, planningId: "p1", eventId: eventId(),
        });
        const applied = await summaryTotal(workspaceId);
        expect(applied).toBe(100000);

        const stored = (await firestore.doc(`workspaces/${workspaceId}/category_planning/p1`).get()).data()!;

        // O par que a escrita dos marcadores + espelho produz.
        await handleCategoryPlanningWritten(data, stored, {
            workspaceId, planningId: "p1", eventId: eventId(),
        });

        expect(await summaryTotal(workspaceId)).toBe(applied);
    });
});

describe("conta — o espelho não redispara o nextInvoice", () => {
    const cardDoc = (over: Record<string, unknown> = {}) => ({
        name: "Cartão",
        runtimeType: "creditCard",
        isDeleted: false,
        initialBalance: 0,
        initialBalanceDate: "2026-01-01T12:00:00.000",
        limit: 5000,
        closingDay: 5,
        dueDay: 10,
        ...over,
    });

    it("completa initialBalanceCents/limitCents sem sincronizar a fatura", async () => {
        const workspaceId = newWorkspace("conta");
        const before = cardDoc();
        const after = cardDoc({ name: "Cartão renomeado" });
        await firestore.doc(`workspaces/${workspaceId}/accounts/acc-card`).set(after);

        const sync = jest.spyOn(container.invoiceSyncService, "syncNextInvoice");

        await handleAccountUpdated(before, after, {
            workspaceId, accountId: "acc-card", eventId: eventId(),
        });

        const account = (await firestore.doc(`workspaces/${workspaceId}/accounts/acc-card`).get()).data()!;
        expect(account.initialBalanceCents).toBe(0);
        expect(account.limitCents).toBe(500000);
        // Nem o fechamento nem o vencimento mudaram: a lista de permissão do
        // handler já exclui os `*Cents` por construção.
        expect(sync).not.toHaveBeenCalled();

        sync.mockRestore();
    });

    it("o ECO do espelho reentra uma vez e para (nada a mudar)", async () => {
        const workspaceId = newWorkspace("conta-eco");
        const before = cardDoc();
        const after = cardDoc({ initialBalanceCents: 0, limitCents: 500000 });
        await firestore.doc(`workspaces/${workspaceId}/accounts/acc-card`).set(after);

        const sync = jest.spyOn(container.invoiceSyncService, "syncNextInvoice");

        await handleAccountUpdated(before, after, {
            workspaceId, accountId: "acc-card", eventId: eventId(),
        });

        // Segunda passada: o passo derivado não encontra nada a completar.
        const updatedAtBefore = (await firestore.doc(`workspaces/${workspaceId}/accounts/acc-card`).get()).updateTime;
        await handleAccountUpdated(after, after, {
            workspaceId, accountId: "acc-card", eventId: eventId(),
        });
        const updatedAtAfter = (await firestore.doc(`workspaces/${workspaceId}/accounts/acc-card`).get()).updateTime;

        expect(updatedAtAfter?.isEqual(updatedAtBefore!)).toBe(true);
        expect(sync).not.toHaveBeenCalled();

        sync.mockRestore();
    });
});
