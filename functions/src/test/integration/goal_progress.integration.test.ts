// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import { GoalRepositoryImpl } from "../../features/goal/data/repositories/goal.repository.impl";
import { GoalServiceImpl } from "../../features/goal/domain/services/goal.service.impl";
import {
    InstallmentModel,
    InstallmentStatus,
    InstallmentType,
    OrderType,
} from "../../features/finance/domain/models/finance.models";
import { CategoryModel, CategoryType } from "../../features/workspace/domain/models/category.model";

/**
 * F2.5 — progresso automático das metas `reduceExpense` e `payDebt`, contra o
 * emulador, com documentos no formato de produção:
 *
 *  - meta com o discriminador em `runtimeType` e a categoria como MAPA;
 *  - `period_summaries/{YYYY-MM}` com o mapa `categories`;
 *  - `accounts/{id}/balance/{YYYY-MM-DD}` com o saldo acumulado do dia.
 *
 * Aqui o repositório é o real (sem mocks): o que está sendo verificado é
 * justamente a consulta ao Firestore — a máscara de campo do sumário mensal e a
 * busca do saldo mais próximo antes da data, que é o ponto onde
 * `orderBy(documentId(), "desc")` seria traiçoeiro.
 */
const WORKSPACE_ID = `ws-goals-${Date.now()}`;
const CATEGORY_ID = "cat-mercado";
const DEBT_ACCOUNT_ID = "acc-emprestimo";

const CATEGORY: CategoryModel = {
    id: CATEGORY_ID,
    name: "Mercado",
    icon: "shopping_cart",
    color: "#EF5350",
    type: CategoryType.expense,
    isDeleted: false,
    allocation: "essential",
};

function installment(over: Partial<InstallmentModel> = {}): InstallmentModel {
    return {
        id: "i-teste",
        orderId: "o-teste",
        amount: 100,
        dueDate: new Date("2026-02-10T12:00:00.000Z"),
        description: "Compra",
        paidAmount: 100,
        paidDate: new Date("2026-02-10T12:00:00.000Z"),
        installmentType: InstallmentType.single,
        status: InstallmentStatus.paid,
        type: OrderType.expense,
        accountIds: [],
        referenceDate: new Date("2026-02-10T12:00:00.000Z"),
        referenceAmount: 100,
        ...over,
    } as InstallmentModel;
}

describe("Progresso automático das metas (integração com emulador)", () => {
    let firestore: admin.firestore.Firestore;
    let repository: GoalRepositoryImpl;
    let service: GoalServiceImpl;

    const goalRef = (goalId: string) =>
        firestore.collection(`workspaces/${WORKSPACE_ID}/goals`).doc(goalId);

    beforeAll(async () => {
        if (admin.apps.length === 0) {
            admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
            admin.firestore().settings({ ignoreUndefinedProperties: true });
        }

        firestore = admin.firestore();
        repository = new GoalRepositoryImpl();
        service = new GoalServiceImpl(repository);

        // Sumários mensais da categoria: jan/2026 = 300, fev/2026 = 450,
        // mar/2026 = 200 (fora do período da meta, que termina em fevereiro).
        const summaries = firestore.collection(`workspaces/${WORKSPACE_ID}/period_summaries`);
        await summaries.doc("2026-01").set({
            year: 2026,
            month: 1,
            runtimeType: "month",
            categories: {
                [CATEGORY_ID]: { generalPlannedAmount: 500, specificPlannedAmount: 0, actualAmount: 300 },
                "cat-outra": { generalPlannedAmount: 0, specificPlannedAmount: 0, actualAmount: 999 },
            },
        });
        await summaries.doc("2026-02").set({
            year: 2026,
            month: 2,
            runtimeType: "month",
            categories: {
                [CATEGORY_ID]: { generalPlannedAmount: 500, specificPlannedAmount: 0, actualAmount: 450 },
            },
        });
        await summaries.doc("2026-03").set({
            year: 2026,
            month: 3,
            runtimeType: "month",
            categories: {
                [CATEGORY_ID]: { generalPlannedAmount: 500, specificPlannedAmount: 0, actualAmount: 200 },
            },
        });

        // Saldos da conta de dívida: devedor (negativo) que vai encolhendo.
        const balances = firestore
            .collection(`workspaces/${WORKSPACE_ID}/accounts/${DEBT_ACCOUNT_ID}/balance`);
        await balances.doc("2025-12-20").set({ balance: -5000, updatedAt: new Date() });
        await balances.doc("2026-01-05").set({ balance: -4500, updatedAt: new Date() });
        await balances.doc("2026-02-10").set({ balance: -3800, updatedAt: new Date() });
    });

    afterAll(async () => {
        await firestore.recursiveDelete(firestore.collection("workspaces").doc(WORKSPACE_ID));
        await Promise.all(admin.apps.map((app) => app?.delete()));
    });

    it("reduceExpense: soma o realizado da categoria nos meses do período", async () => {
        const goalId = "goal-reduce-expense";
        await goalRef(goalId).set({
            name: "Segurar o mercado",
            runtimeType: "reduceExpense",
            targetAmount: 1000,
            currentAmount: 0,
            averageSpending: 600,
            category: CATEGORY,
            startDate: admin.firestore.Timestamp.fromDate(new Date("2026-01-01T00:00:00.000Z")),
            deadline: admin.firestore.Timestamp.fromDate(new Date("2026-02-28T00:00:00.000Z")),
            isDeleted: false,
        });

        await service.processInstallmentChange(
            WORKSPACE_ID,
            null,
            installment({ category: CATEGORY })
        );

        const saved = (await goalRef(goalId).get()).data()!;
        // 300 (jan) + 450 (fev); março está fora do prazo da meta e a outra
        // categoria do mesmo documento não entra.
        expect(saved.currentAmount).toBe(750);
        expect(saved.completedAt).toBeUndefined();
    });

    it("reduceExpense: carimba completedAt quando o gasto atinge o teto", async () => {
        const goalId = "goal-reduce-expense-estourada";
        await goalRef(goalId).set({
            name: "Teto apertado",
            runtimeType: "reduceExpense",
            targetAmount: 500,
            currentAmount: 0,
            averageSpending: 600,
            category: CATEGORY,
            startDate: admin.firestore.Timestamp.fromDate(new Date("2026-01-01T00:00:00.000Z")),
            deadline: admin.firestore.Timestamp.fromDate(new Date("2026-02-28T00:00:00.000Z")),
            isDeleted: false,
        });

        await service.processInstallmentChange(
            WORKSPACE_ID,
            null,
            installment({ category: CATEGORY })
        );

        const saved = (await goalRef(goalId).get()).data()!;
        expect(saved.currentAmount).toBe(750);
        expect(saved.completedAt).toBeDefined();
    });

    it("payDebt: mede o quanto a dívida encolheu desde o início da meta", async () => {
        const goalId = "goal-pay-debt";
        await goalRef(goalId).set({
            name: "Quitar empréstimo",
            runtimeType: "payDebt",
            targetAmount: 5000,
            currentAmount: 0,
            accountId: DEBT_ACCOUNT_ID,
            startDate: admin.firestore.Timestamp.fromDate(new Date("2026-01-01T00:00:00.000Z")),
            deadline: admin.firestore.Timestamp.fromDate(new Date("2026-12-31T00:00:00.000Z")),
            isDeleted: false,
        });

        await service.processInstallmentChange(
            WORKSPACE_ID,
            null,
            installment({
                accounts: { [DEBT_ACCOUNT_ID]: "credit" },
                accountIds: [DEBT_ACCOUNT_ID],
                type: OrderType.income,
            })
        );

        const saved = (await goalRef(goalId).get()).data()!;
        // Saldo em 2026-01-01 é o de 2025-12-20 (-5000, o mais próximo ANTES do
        // início); o atual é -3800. Amortizados: 1200.
        expect(saved.currentAmount).toBe(1200);
    });

    it("getBalancesForGoal usa o saldo do dia exato quando ele existe", async () => {
        const balances = await repository.getBalancesForGoal(
            WORKSPACE_ID,
            DEBT_ACCOUNT_ID,
            new Date("2026-01-05T00:00:00.000Z")
        );
        expect(balances.startBalance).toBe(-4500);
        expect(balances.currentBalance).toBe(-3800);
    });

    it("getBalancesForGoal devolve startBalance nulo antes do primeiro saldo gravado", async () => {
        const balances = await repository.getBalancesForGoal(
            WORKSPACE_ID,
            DEBT_ACCOUNT_ID,
            new Date("2025-01-01T00:00:00.000Z")
        );
        expect(balances.startBalance).toBeNull();
        expect(balances.currentBalance).toBe(-3800);
    });

    it("getBalancesForGoal devolve os dois saldos nulos numa conta sem saldo", async () => {
        const balances = await repository.getBalancesForGoal(
            WORKSPACE_ID,
            "acc-sem-saldo",
            new Date("2026-01-01T00:00:00.000Z")
        );
        expect(balances).toEqual({ startBalance: null, currentBalance: null });
    });

    it("getActiveGoalsByCategory encontra a meta pelo mapa `category`", async () => {
        const goals = await repository.getActiveGoalsByCategory(WORKSPACE_ID, CATEGORY_ID);
        expect(goals.map((g) => g.id).sort()).toEqual([
            "goal-reduce-expense",
            "goal-reduce-expense-estourada",
        ]);
    });
});
