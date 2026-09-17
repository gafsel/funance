// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import { handleInstallmentWritten } from "../../features/finance/presentation/functions/installment_handler";
import { handleOrderWritten } from "../../features/finance/presentation/functions/order_handler";
import { handleAccountUpdated } from "../../features/finance/presentation/functions/account_handler";
import { handleCategoryPlanningWritten } from "../../features/finance/presentation/functions/category_planning_handler";
import { handleGoalWritten } from "../../features/goal/presentation/functions/gamification_handler";
import { CategoryModel, CategoryType } from "../../features/workspace/domain/models/category.model";
import { shiftMonthKey, toMonthKey } from "../../core/utils/month_key";
import { container } from "../../core/container";

/**
 * HOTFIX — O ESPELHO DEFASADO NO PAYLOAD DO EVENTO.
 *
 * O payload de um evento do Firestore é o documento como ele estava naquele
 * instante. Quando o app edita um valor sem tocar no espelho inteiro — que é o
 * que ele faz, porque os `*Cents` são server-only —, o `afterData` chega com o
 * `double` NOVO e o `*Cents` VELHO.
 *
 * O passo derivado (`applyCentsPatch`) conserta o BANCO, mas o objeto em
 * memória continua mentindo. E toda a regra de negócio abaixo dele resolve
 * dinheiro por `resolveCents`, que **prefere o inteiro**. Resultado: o gatilho
 * processa o valor ANTIGO, e o segundo evento — o eco da escrita do espelho —
 * sai pela guarda por conteúdo sem corrigir nada.
 *
 * Cada teste aqui monta exatamente esse par (double novo + cents velho) e
 * verifica que o efeito gravado corresponde ao valor NOVO. Todos falham sem a
 * normalização (`withFreshCents`) nos handlers.
 */

let firestore: admin.firestore.Firestore;

const workspaces: string[] = [];
const eventId = () => `evt-stale-${Date.now()}-${Math.floor(Math.random() * 100000)}`;

function newWorkspace(label: string): string {
    const workspaceId = `ws-stale-${label}-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
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

const ACCOUNT_ID = "acc-checking";
const ts = (iso: string) => admin.firestore.Timestamp.fromDate(new Date(iso));

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

/** Conta corrente, para o saldo ter onde cair. */
async function createAccount(workspaceId: string): Promise<void> {
    await firestore.doc(`workspaces/${workspaceId}/accounts/${ACCOUNT_ID}`).set({
        name: "Conta",
        icon: "account_balance",
        color: "#4CAF50",
        runtimeType: "checking",
        isDeleted: false,
        initialBalance: 0,
        initialBalanceCents: 0,
        initialBalanceDate: "2026-01-01T12:00:00.000",
    });
}

describe("1. category_planning — o valor editado é o que vai para os sumários", () => {
    const CURRENT_MONTH = toMonthKey(new Date());

    const planningDoc = (over: Record<string, unknown> = {}) => ({
        category: CATEGORY,
        amount: 500,
        amountCents: 50000,
        startMonth: CURRENT_MONTH,
        endMonth: shiftMonthKey(CURRENT_MONTH, 6),
        ...over,
    });

    it("amount 500 -> 1000 com amountCents DEFASADO aplica 1000, não 500", async () => {
        const workspaceId = newWorkspace("planning");
        const before = planningDoc();
        await firestore.doc(`workspaces/${workspaceId}/category_planning/p1`).set(before);

        // Primeiro evento: a criação, já coerente.
        await handleCategoryPlanningWritten(null, before, {
            workspaceId, planningId: "p1", eventId: eventId(),
        });

        // O app edita o valor. Ele NÃO grava `amountCents` — as rules negam —,
        // então o payload do evento traz o double novo e o inteiro velho.
        const after = { ...planningDoc(), amount: 1000, amountCents: 50000 };
        await firestore.doc(`workspaces/${workspaceId}/category_planning/p1`)
            .set({ amount: 1000 }, { merge: true });

        await handleCategoryPlanningWritten(before, after, {
            workspaceId, planningId: "p1", eventId: eventId(),
        });

        const summary = (await firestore.doc(`workspaces/${workspaceId}/period_summaries/${CURRENT_MONTH}`).get())
            .data()!.categories[CATEGORY.id];
        // Sem a normalização: 50000 (o estorno cancelava 500 e reaplicava 500).
        expect(summary.generalPlannedAmountCents).toBe(100000);
        expect(summary.generalPlannedAmount).toBe(1000);

        const planning = (await firestore.doc(`workspaces/${workspaceId}/category_planning/p1`).get()).data()!;
        expect(planning.appliedAmount).toBe(1000);
        expect(planning.appliedAmountCents).toBe(100000);
        expect(planning.amountCents).toBe(100000);
    });
});

describe("2. installment — o delta é o do valor NOVO", () => {
    const installmentDoc = (over: Record<string, unknown> = {}) => ({
        orderId: "o1",
        amount: 100,
        amountCents: 10000,
        referenceAmount: 100,
        referenceAmountCents: 10000,
        description: "Aluguel",
        status: "pending",
        type: "expense",
        installmentType: "single",
        dueDate: ts("2026-03-10T15:00:00.000Z"),
        referenceDate: ts("2026-03-10T15:00:00.000Z"),
        paidDate: null,
        accounts: { [ACCOUNT_ID]: "debt" },
        accountIds: [ACCOUNT_ID],
        category: CATEGORY,
        ...over,
    });

    const summaryCents = async (workspaceId: string, field: string) => {
        const doc = await firestore.doc(`workspaces/${workspaceId}/period_summaries/2026-03`).get();
        return doc.data()?.categories?.[CATEGORY.id]?.[field] ?? 0;
    };

    it("amount 100 -> 250 com amountCents defasado move o projetado em 150", async () => {
        const workspaceId = newWorkspace("inst-amount");
        await createAccount(workspaceId);
        const before = installmentDoc();
        await firestore.doc(`workspaces/${workspaceId}/installments/i1`).set(before);

        await handleInstallmentWritten(null, before, {
            workspaceId, installmentId: "i1", eventId: eventId(),
        });
        expect(await summaryCents(workspaceId, "specificPlannedAmountCents")).toBe(10000);

        // O app edita o valor; o espelho fica para trás.
        const after = { ...installmentDoc(), amount: 250, referenceAmount: 250, amountCents: 10000, referenceAmountCents: 10000 };
        await firestore.doc(`workspaces/${workspaceId}/installments/i1`)
            .set({ amount: 250, referenceAmount: 250 }, { merge: true });

        await handleInstallmentWritten(before, after, {
            workspaceId, installmentId: "i1", eventId: eventId(),
        });

        // Sem a normalização: estorno de -100 e reaplicação de +100 = delta 0,
        // e o projetado ficava preso em 10000.
        expect(await summaryCents(workspaceId, "specificPlannedAmountCents")).toBe(25000);
    });

    it("paidAmount 100 -> 250 com paidAmountCents defasado move saldo e realizado", async () => {
        const workspaceId = newWorkspace("inst-paid");
        await createAccount(workspaceId);

        const pago = installmentDoc({
            status: "paid",
            paidAmount: 100,
            paidAmountCents: 10000,
            paidDate: ts("2026-03-10T15:00:00.000Z"),
        });
        await firestore.doc(`workspaces/${workspaceId}/installments/i1`).set(pago);

        await handleInstallmentWritten(installmentDoc(), pago, {
            workspaceId, installmentId: "i1", eventId: eventId(),
        });

        const balanceRef = firestore.doc(`workspaces/${workspaceId}/accounts/${ACCOUNT_ID}/balance/2026-03-10`);
        expect((await balanceRef.get()).data()!.balanceCents).toBe(-10000);
        expect(await summaryCents(workspaceId, "actualAmountCents")).toBe(-0 + 10000);

        // O usuário corrige o valor pago; o espelho fica para trás.
        const corrigido = { ...pago, paidAmount: 250, referenceAmount: 250, paidAmountCents: 10000 };
        await firestore.doc(`workspaces/${workspaceId}/installments/i1`)
            .set({ paidAmount: 250, referenceAmount: 250 }, { merge: true });

        await handleInstallmentWritten(pago, corrigido, {
            workspaceId, installmentId: "i1", eventId: eventId(),
        });

        // Sem a normalização: estorno de -100 e reaplicação de +100 = zero.
        expect((await balanceRef.get()).data()!.balanceCents).toBe(-25000);
        expect(await summaryCents(workspaceId, "actualAmountCents")).toBe(25000);
    });
});

/**
 * ORDER e CONTA: aqui a normalização é PROFILAXIA, não conserto.
 *
 * Hoje nenhum consumidor lê o `amountCents` da order nem o
 * `initialBalanceCents`/`limitCents` da conta a partir do payload do evento —
 * `syncInstallments` reparte o `double` e `syncInitialBalance` monta a order
 * sintética a partir dele. Por isso estes dois casos NÃO produzem número errado
 * em produção hoje.
 *
 * O que estes testes travam é o CONTRATO do handler: o modelo entregue ao
 * serviço carrega um par coerente. No dia em que alguém trocar um `amount` por
 * `resolveCents(amount, amountCents)` lá dentro — que é exatamente o que os
 * outros três caminhos já fazem —, o defeito não volta calado.
 */
describe("3. order — o modelo entregue ao serviço tem o par coerente", () => {
    const orderDoc = (over: Record<string, unknown> = {}) => ({
        amount: 300,
        amountCents: 30000,
        description: "Curso",
        dueDay: 10,
        startMonth: "2026-03",
        installmentType: "installment",
        installmentCount: 3,
        status: "active",
        type: "expense",
        accounts: { [ACCOUNT_ID]: "debt" },
        accountIds: [ACCOUNT_ID],
        category: CATEGORY,
        ...over,
    });

    it("uma order com amountCents defasado chega ao serviço já normalizada", async () => {
        const workspaceId = newWorkspace("order");
        await createAccount(workspaceId);

        const after = orderDoc({ amount: 600, amountCents: 30000 });
        await firestore.doc(`workspaces/${workspaceId}/orders/o1`).set(after);

        const sync = jest.spyOn(container.financeService, "syncInstallments");

        await handleOrderWritten(null, after, { workspaceId, orderId: "o1", eventId: eventId() });

        expect(sync).toHaveBeenCalledTimes(1);
        const recebido = sync.mock.calls[0][3]!;
        // Sem a normalização: 30000, o espelho velho de R$ 300.
        expect(recebido.amountCents).toBe(60000);
        expect(recebido.amount).toBe(600);

        sync.mockRestore();

        // E as parcelas — que já saíam do `double` — continuam certas.
        const installments = await firestore.collection(`workspaces/${workspaceId}/installments`).get();
        expect(installments.docs.map((d) => d.data().amountCents).sort((a, b) => a - b))
            .toEqual([20000, 20000, 20000]);
    });
});

describe("4. goal — o alvo editado é o que decide o desfecho", () => {
    const goalDoc = (over: Record<string, unknown> = {}) => ({
        name: "Reserva",
        runtimeType: "saveMoney",
        targetAmount: 1000,
        targetAmountCents: 100000,
        currentAmount: 600,
        currentAmountCents: 60000,
        accountId: "acc-cofre",
        startDate: ts("2026-01-01T15:00:00.000Z"),
        deadline: ts("2099-12-31T15:00:00.000Z"),
        isDeleted: false,
        ...over,
    });

    it("baixar o alvo de 1000 para 500 com targetAmountCents defasado DESFECHA a meta", async () => {
        const workspaceId = newWorkspace("goal");
        // Cofrinho com R$ 600: o recálculo vai achar esse saldo.
        await firestore.doc(`workspaces/${workspaceId}/accounts/acc-cofre`).set({
            name: "Cofrinho", runtimeType: "investment", isDeleted: false, initialBalance: 0,
        });
        await firestore.doc(`workspaces/${workspaceId}/accounts/acc-cofre/balance/2026-02-01`).set({
            dateKey: "2026-02-01", delta: 600, balance: 600, deltaCents: 60000, balanceCents: 60000,
        });

        const before = goalDoc();
        // O app baixa o alvo; o espelho fica para trás.
        const after = goalDoc({ targetAmount: 500, targetAmountCents: 100000 });
        await firestore.doc(`workspaces/${workspaceId}/goals/g1`).set(after);

        await handleGoalWritten(before, after, { workspaceId, goalId: "g1", eventId: eventId() });

        const goal = (await firestore.doc(`workspaces/${workspaceId}/goals/g1`).get()).data()!;
        expect(goal.targetAmountCents).toBe(50000);
        // Sem a normalização: o veredito comparava 60000 com 100000 e a meta
        // continuava em andamento, embora já tivesse passado do alvo novo.
        expect(goal.outcome).toBe("success");
    });
});

describe("5. account — o modelo entregue ao serviço tem o par coerente", () => {
    const accountDoc = (over: Record<string, unknown> = {}) => ({
        name: "Conta",
        icon: "account_balance",
        color: "#4CAF50",
        runtimeType: "checking",
        isDeleted: false,
        initialBalance: 1000,
        initialBalanceCents: 100000,
        limit: 5000,
        limitCents: 500000,
        initialBalanceDate: "2026-01-05T12:00:00.000",
        ...over,
    });

    it("initialBalance 1000 -> 2500 com initialBalanceCents defasado grava 2500", async () => {
        const workspaceId = newWorkspace("account");
        const before = accountDoc();
        await firestore.doc(`workspaces/${workspaceId}/accounts/${ACCOUNT_ID}`).set(before);

        // O app edita o saldo inicial; o espelho fica para trás.
        const after = accountDoc({ initialBalance: 2500, initialBalanceCents: 100000, limit: 7000, limitCents: 500000 });
        await firestore.doc(`workspaces/${workspaceId}/accounts/${ACCOUNT_ID}`)
            .set({ initialBalance: 2500, limit: 7000 }, { merge: true });

        const sync = jest.spyOn(container.financeService, "syncInitialBalance");

        await handleAccountUpdated(before, after, {
            workspaceId, accountId: ACCOUNT_ID, eventId: eventId(),
        });

        expect(sync).toHaveBeenCalledTimes(1);
        const recebida = sync.mock.calls[0][2]!;
        // Sem a normalização: 100000/500000, os espelhos velhos.
        expect(recebida.initialBalanceCents).toBe(250000);
        expect(recebida.limitCents).toBe(700000);
        sync.mockRestore();

        // A order sintética — que já saía do `double` — continua certa.
        const order = (await firestore.doc(`workspaces/${workspaceId}/orders/initial-balance-${ACCOUNT_ID}`).get()).data()!;
        expect(order.amountCents).toBe(250000);
        expect(order.amount).toBe(2500);

        // E o passo derivado consertou o banco.
        const account = (await firestore.doc(`workspaces/${workspaceId}/accounts/${ACCOUNT_ID}`).get()).data()!;
        expect(account.initialBalanceCents).toBe(250000);
        expect(account.limitCents).toBe(700000);
    });
});
