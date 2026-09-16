// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import { FinanceRepositoryImpl } from "../../features/finance/data/repositories/finance.repository.impl";
import { FinanceService } from "../../features/finance/domain/services/finance.service";
import { SummaryService } from "../../features/finance/domain/services/summary.service";
import {
    AccountModel,
    AccountType,
    InstallmentModel,
    InstallmentStatus,
    InstallmentType,
    OrderModel,
    OrderStatus,
    OrderType,
} from "../../features/finance/domain/models/finance.models";
import { CategoryModel, CategoryType } from "../../features/workspace/domain/models/category.model";
import { toDateKey } from "../../core/utils/date_key";

/**
 * Teste de fumaça de integração contra o emulador do Firestore.
 *
 * Nada aqui é mockado além do `ofx-js`: os repositórios reais são
 * instanciados e escrevem/leem documentos no formato real usado em produção.
 *
 * Caminho exercitado:
 *   1. Order parcelada em 3x -> FinanceService.syncInstallments
 *   2. Gatilho de criação de cada parcela -> SummaryService.processInstallmentChange(null, inst)
 *   3. Pagamento da 1ª parcela -> FinanceService.updateAccountBalanceOnInstallmentChange
 *                              + SummaryService.processInstallmentChange(before, after)
 */

const WORKSPACE_ID = `ws-integration-${Date.now()}`;
const ACCOUNT_ID = "acc-checking";
const ORDER_ID = "order-notebook-3x";

const CATEGORY: CategoryModel = {
    id: "cat-eletronicos",
    name: "Eletrônicos",
    icon: "devices",
    color: "#42A5F5",
    type: CategoryType.expense,
    isDeleted: false,
    allocation: "comfort",
};

/** Total 502,40 em 3x => 16746 centavos base + 2 centavos de resto. */
const ORDER_AMOUNT = 502.40;
const EXPECTED_INSTALLMENT_AMOUNTS = [167.47, 167.47, 167.46];

// F1.4: o id do documento de saldo é o dia no fuso do produto, não em UTC.
const toDateId = (date: Date) => toDateKey(date);
const toMonthId = (date: Date) =>
    `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;

describe("Fluxo financeiro (integração com emulador do Firestore)", () => {
    let firestore: admin.firestore.Firestore;
    let repository: FinanceRepositoryImpl;
    let financeService: FinanceService;
    let summaryService: SummaryService;

    beforeAll(async () => {
        if (admin.apps.length === 0) {
            admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
            admin.firestore().settings({ ignoreUndefinedProperties: true });
        }

        firestore = admin.firestore();
        repository = new FinanceRepositoryImpl();
        financeService = new FinanceService(repository);
        summaryService = new SummaryService(repository);

        const account: Omit<AccountModel, "id"> = {
            name: "Conta Corrente",
            icon: "account_balance",
            color: "#4CAF50",
            runtimeType: AccountType.checking,
            isDeleted: false,
            initialBalance: 0,
            initialBalanceDate: new Date(2026, 0, 1, 12),
        };

        await firestore
            .doc(`workspaces/${WORKSPACE_ID}/accounts/${ACCOUNT_ID}`)
            .set(account);
    });

    afterAll(async () => {
        await firestore.recursiveDelete(firestore.doc(`workspaces/${WORKSPACE_ID}`));
        await Promise.all(admin.apps.map((app) => app?.delete()));
    });

    it("cria 3 parcelas com os valores em centavos corretos e atualiza saldo e period summary", async () => {
        // ------------------------------------------------------------------
        // 1. Order parcelada em 3x
        // ------------------------------------------------------------------
        const order: OrderModel = {
            id: ORDER_ID,
            amount: ORDER_AMOUNT,
            dueDay: 10,
            description: "Notebook",
            startMonth: "2026-03",
            installmentCount: 3,
            installmentType: InstallmentType.installment,
            status: OrderStatus.active,
            type: OrderType.expense,
            accounts: { [ACCOUNT_ID]: "debt" },
            accountIds: [ACCOUNT_ID],
            category: CATEGORY,
        };

        const orderData: Omit<OrderModel, "id"> = { ...order };
        delete (orderData as Partial<OrderModel>).id;
        await repository.createOrder(WORKSPACE_ID, orderData, ORDER_ID);

        await financeService.syncInstallments(WORKSPACE_ID, ORDER_ID, null, order);

        const created = (await repository.getInstallmentsByOrderId(WORKSPACE_ID, ORDER_ID))
            .sort((a, b) => a.dueDate.getTime() - b.dueDate.getTime());

        expect(created).toHaveLength(3);
        expect(created.map((i) => i.amount)).toEqual(EXPECTED_INSTALLMENT_AMOUNTS);
        expect(created.map((i) => i.installmentNumber)).toEqual([1, 2, 3]);
        expect(created.map((i) => i.installmentCount)).toEqual([3, 3, 3]);
        expect(created.map((i) => i.status)).toEqual([
            InstallmentStatus.pending,
            InstallmentStatus.pending,
            InstallmentStatus.pending,
        ]);
        expect(created.map((i) => toDateId(i.dueDate))).toEqual(
            [new Date(2026, 2, 10, 12), new Date(2026, 3, 10, 12), new Date(2026, 4, 10, 12)]
                .map(toDateId)
        );
        // A soma das parcelas tem que bater com o total da order, em centavos.
        const totalCents = created.reduce((acc, i) => acc + Math.round(i.amount * 100), 0);
        expect(totalCents).toBe(Math.round(ORDER_AMOUNT * 100));

        // ------------------------------------------------------------------
        // 2. Gatilho de criação: cada parcela entra como planejado (projetado)
        // ------------------------------------------------------------------
        for (const installment of created) {
            await summaryService.processInstallmentChange(WORKSPACE_ID, null, installment);
        }

        // ------------------------------------------------------------------
        // 3. Pagamento da 1ª parcela
        // ------------------------------------------------------------------
        const before = created[0];
        const paidDate = new Date(before.dueDate);
        paidDate.setHours(12, 0, 0, 0);

        const after: InstallmentModel = {
            ...before,
            status: InstallmentStatus.paid,
            paidAmount: before.amount,
            paidDate,
        };

        await repository.updateInstallment(WORKSPACE_ID, before.id, {
            status: InstallmentStatus.paid,
            paidAmount: after.paidAmount,
            paidDate: after.paidDate,
        });

        await financeService.updateAccountBalanceOnInstallmentChange(WORKSPACE_ID, before, after);
        await summaryService.processInstallmentChange(WORKSPACE_ID, before, after);

        // --- accounts/{id}/balance/{YYYY-MM-DD} ---------------------------
        const balanceId = toDateId(paidDate);
        const balanceSnap = await firestore
            .doc(`workspaces/${WORKSPACE_ID}/accounts/${ACCOUNT_ID}/balance/${balanceId}`)
            .get();

        expect(balanceSnap.exists).toBe(true);
        expect(balanceId).toMatch(/^\d{4}-\d{2}-\d{2}$/);
        // Conta com papel "debt" em uma despesa: o saldo é debitado.
        expect(balanceSnap.data()!.balance).toBeCloseTo(-EXPECTED_INSTALLMENT_AMOUNTS[0], 2);
        expect(balanceSnap.data()!.dateKey).toBe(balanceId);
        expect(balanceSnap.data()!.delta).toBeCloseTo(-EXPECTED_INSTALLMENT_AMOUNTS[0], 2);
        expect(balanceSnap.data()!.updatedAt).toBeInstanceOf(admin.firestore.Timestamp);

        // --- period_summaries/{YYYY-MM} -----------------------------------
        const monthId = toMonthId(before.dueDate);
        expect(monthId).toBe("2026-03");

        const summarySnap = await firestore
            .doc(`workspaces/${WORKSPACE_ID}/period_summaries/${monthId}`)
            .get();

        expect(summarySnap.exists).toBe(true);

        const summary = summarySnap.data()!;
        expect(summary.year).toBe(2026);
        expect(summary.month).toBe(3);
        expect(summary.categories).toBeDefined();

        const categorySummary = summary.categories[CATEGORY.id];
        expect(categorySummary).toBeDefined();
        expect(Object.keys(categorySummary).sort()).toEqual([
            "actualAmount",
            "generalPlannedAmount",
            "specificPlannedAmount",
        ]);
        // Nenhum CategoryPlanning foi criado, então o planejado geral é zero.
        expect(categorySummary.generalPlannedAmount).toBeCloseTo(0, 2);
        // A projeção da parcela de março permanece (estorno -167,47 + reaplicação +167,47).
        expect(categorySummary.specificPlannedAmount).toBeCloseTo(EXPECTED_INSTALLMENT_AMOUNTS[0], 2);
        // O realizado passa a valer o valor efetivamente pago.
        expect(categorySummary.actualAmount).toBeCloseTo(EXPECTED_INSTALLMENT_AMOUNTS[0], 2);

        // Os meses seguintes seguem apenas projetados, sem realizado.
        const aprilSnap = await firestore
            .doc(`workspaces/${WORKSPACE_ID}/period_summaries/${toMonthId(created[1].dueDate)}`)
            .get();
        const april = aprilSnap.data()!.categories[CATEGORY.id];
        expect(april.specificPlannedAmount).toBeCloseTo(EXPECTED_INSTALLMENT_AMOUNTS[1], 2);
        expect(april.actualAmount).toBeCloseTo(0, 2);
    });

    /**
     * F1.4 — este teste era `it.skip`.
     *
     * `FinanceRepositoryImpl.updateAccountBalance` chamava
     * `getLastBalanceBefore`, que montava
     * `.where(documentId(), "<", id).orderBy(documentId(), "desc")`. O emulador
     * responde `9 FAILED_PRECONDITION: Firestore does not support descending key
     * scans`, então o PRIMEIRO pagamento de um dia sem saldo prévio sempre
     * estourava — e em produção o caminho dependia de um índice `__name__ DESC`.
     *
     * Agora a busca do dia anterior usa o campo `dateKey` (descendente por
     * CAMPO, não por chave) e o teste voltou a rodar.
     */
    it("cria o documento de saldo do dia quando ainda não existe saldo anterior", async () => {
        const installments = await repository.getInstallmentsByOrderId(WORKSPACE_ID, ORDER_ID);
        const target = installments.sort((a, b) => a.dueDate.getTime() - b.dueDate.getTime())[1];

        const paidDate = new Date(target.dueDate);
        paidDate.setHours(12, 0, 0, 0);

        const after: InstallmentModel = {
            ...target,
            status: InstallmentStatus.paid,
            paidAmount: target.amount,
            paidDate,
        };

        await financeService.updateAccountBalanceOnInstallmentChange(WORKSPACE_ID, target, after);

        const snap = await firestore
            .doc(`workspaces/${WORKSPACE_ID}/accounts/${ACCOUNT_ID}/balance/${toDateId(paidDate)}`)
            .get();

        expect(snap.exists).toBe(true);
        // O dia herda o saldo acumulado do último dia anterior (o pagamento da
        // 1ª parcela) e desconta a 2ª.
        expect(snap.data()!.balance).toBeCloseTo(
            -(EXPECTED_INSTALLMENT_AMOUNTS[0] + EXPECTED_INSTALLMENT_AMOUNTS[1]),
            2
        );
        expect(snap.data()!.dateKey).toBe(toDateId(paidDate));
        expect(snap.data()!.delta).toBeCloseTo(-EXPECTED_INSTALLMENT_AMOUNTS[1], 2);
    });
});
