// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import { FinanceRepositoryImpl } from "../../features/finance/data/repositories/finance.repository.impl";
import { FinanceService } from "../../features/finance/domain/services/finance.service";
import { InvoiceSyncServiceImpl } from "../../features/finance/domain/services/invoice_sync.service";
import {
    AccountModel,
    AccountType,
    InstallmentModel,
    InstallmentStatus,
    InstallmentType,
    NextInvoiceModel,
    OrderType,
} from "../../features/finance/domain/models/finance.models";
import { CategoryModel, CategoryType } from "../../features/workspace/domain/models/category.model";
import { toDateKey } from "../../core/utils/date_key";
import { InvoiceService } from "../../features/finance/domain/services/invoice.service";

/**
 * F1.8 — fluxo completo da fatura contra o emulador:
 *
 *   compra paga no cartão -> order de fatura -> parcela da fatura
 *   -> `accounts/{id}.nextInvoice` -> pagamento da fatura -> resumo avança.
 *
 * O emulador NÃO dispara triggers, então o encadeamento
 * `order escrita -> onOrderWritten -> parcela escrita -> onInstallmentWritten`
 * é simulado chamando os serviços na mesma ordem em que os gatilhos rodariam.
 * É exatamente por causa desse encadeamento que a sincronização precisa ser
 * idempotente: ela roda mais de uma vez por compra.
 */

const WORKSPACE_ID = `ws-invoice-${Date.now()}`;
const CARD_ID = "acc-cartao";
const CHECKING_ID = "acc-corrente";
/** Cartão à parte, para os testes de id de order (legado vs canônico). */
const LEGACY_CARD_ID = "acc-cartao-legado";

/** Fechamento dia 5, vencimento dia 10. */
const CLOSING_DAY = 5;
const DUE_DAY = 10;

/** Compra em 03/03/2025 (segunda-feira, dia útil). */
const PURCHASE_DATE = new Date(Date.UTC(2025, 2, 3, 15, 0, 0));
const PURCHASE_AMOUNT = 420.75;

const CATEGORY: CategoryModel = {
    id: "cat-mercado",
    name: "Mercado",
    icon: "shopping_cart",
    color: "#66BB6A",
    type: CategoryType.expense,
    isDeleted: false,
    allocation: "essential",
};

describe("Fatura: nextInvoice do início ao pagamento (integração com emulador)", () => {
    let firestore: admin.firestore.Firestore;
    let repository: FinanceRepositoryImpl;
    let financeService: FinanceService;
    let invoiceSync: InvoiceSyncServiceImpl;

    const readNextInvoice = async (): Promise<NextInvoiceModel | undefined> => {
        const account = await repository.getAccountById(WORKSPACE_ID, CARD_ID);
        return account?.nextInvoice ?? undefined;
    };

    /**
     * Encadeamento que o Eventarc faria sozinho: a order de fatura foi escrita,
     * então `onOrderWritten` sincroniza a parcela e `onInstallmentWritten`
     * reprocessa a fatura (é essa última passagem que grava o valor certo em
     * `nextInvoice`).
     */
    const propagateInvoiceOrder = async (orderId: string, hadInstallmentBefore: boolean) => {
        const order = await repository.getOrderById(WORKSPACE_ID, orderId);
        expect(order).not.toBeNull();

        const before = hadInstallmentBefore
            ? (await repository.getInstallmentsByOrderId(WORKSPACE_ID, orderId))[0] ?? null
            : null;

        await financeService.syncInstallments(
            WORKSPACE_ID,
            orderId,
            hadInstallmentBefore ? order : null,
            order
        );

        const after = (await repository.getInstallmentsByOrderId(WORKSPACE_ID, orderId))[0] ?? null;
        await financeService.processInvoiceUpdate(WORKSPACE_ID, before, after);
        return after;
    };

    beforeAll(async () => {
        if (admin.apps.length === 0) {
            admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
            admin.firestore().settings({ ignoreUndefinedProperties: false });
        }

        firestore = admin.firestore();
        repository = new FinanceRepositoryImpl();
        financeService = new FinanceService(repository);
        invoiceSync = new InvoiceSyncServiceImpl(repository);

        const card: Omit<AccountModel, "id"> = {
            name: "Cartão",
            icon: "credit_card",
            color: "#8A05BE",
            runtimeType: AccountType.creditCard,
            isDeleted: false,
            initialBalance: 0,
            initialBalanceDate: new Date(Date.UTC(2025, 0, 1, 15, 0, 0)),
            limit: 5000,
            closingDay: CLOSING_DAY,
            dueDay: DUE_DAY,
        };

        const checking: Omit<AccountModel, "id"> = {
            name: "Conta Corrente",
            icon: "account_balance",
            color: "#4CAF50",
            runtimeType: AccountType.checking,
            isDeleted: false,
            initialBalance: 10000,
            initialBalanceDate: new Date(Date.UTC(2025, 0, 1, 15, 0, 0)),
        };

        await firestore.doc(`workspaces/${WORKSPACE_ID}/accounts/${CARD_ID}`).set(card);
        await firestore.doc(`workspaces/${WORKSPACE_ID}/accounts/${CHECKING_ID}`).set(checking);
        await firestore.doc(`workspaces/${WORKSPACE_ID}/accounts/${LEGACY_CARD_ID}`)
            .set({ ...card, name: "Cartão Legado" });
        await firestore.doc(`workspaces/${WORKSPACE_ID}/categories/${CATEGORY.id}`).set(CATEGORY);
    });

    afterAll(async () => {
        await firestore.recursiveDelete(firestore.doc(`workspaces/${WORKSPACE_ID}`));
    });

    it("cartão novo nasce com a janela do ciclo corrente e valor zero", async () => {
        // `now` explícito: 20/02/2025 — o vencimento de 10/02 já passou.
        const written = await invoiceSync.syncNextInvoice(
            WORKSPACE_ID,
            CARD_ID,
            null,
            new Date(Date.UTC(2025, 1, 20, 15, 0, 0))
        );
        expect(written).toBe(true);

        const next = await readNextInvoice();
        expect(next).toBeDefined();
        expect(next!.amount).toBe(0);
        expect(next!.installmentId).toBeNull();
        expect(toDateKey(next!.dueDate)).toBe("2025-03-10");
        expect(toDateKey(next!.cycleStart)).toBe("2025-02-05");
        expect(toDateKey(next!.cycleEnd)).toBe("2025-03-04");
        expect(next!.orderId).toBe(`invoice-${CARD_ID}-2025-03-10`);
    });

    it("não reescreve o resumo quando nada mudou", async () => {
        const written = await invoiceSync.syncNextInvoice(
            WORKSPACE_ID,
            CARD_ID,
            null,
            new Date(Date.UTC(2025, 1, 20, 15, 0, 0))
        );
        expect(written).toBe(false);
    });

    it("compra paga no cartão vira fatura e o resumo passa a mostrá-la", async () => {
        const purchase: Omit<InstallmentModel, "id"> = {
            orderId: "order-mercado",
            amount: 0,
            dueDate: PURCHASE_DATE,
            description: "Mercado",
            paidAmount: PURCHASE_AMOUNT,
            paidDate: PURCHASE_DATE,
            installmentType: InstallmentType.single,
            status: InstallmentStatus.paid,
            type: OrderType.expense,
            accounts: { [CARD_ID]: "debt" },
            accountIds: [CARD_ID],
            category: CATEGORY,
            referenceDate: PURCHASE_DATE,
            referenceAmount: PURCHASE_AMOUNT,
        };

        // Gatilho da parcela de compra: impacta a fatura do cartão.
        await financeService.processInvoiceUpdate(
            WORKSPACE_ID,
            null,
            { id: "inst-mercado", ...purchase }
        );

        const orderId = InvoiceService.invoiceOrderId(
            CARD_ID,
            InvoiceService.calculateInvoiceDueDate(PURCHASE_DATE, { closingDay: CLOSING_DAY, dueDay: DUE_DAY })
        );
        expect(orderId).toBe(`invoice-${CARD_ID}-2025-03-10`);

        const invoiceOrder = await repository.getOrderById(WORKSPACE_ID, orderId);
        expect(invoiceOrder?.amount).toBeCloseTo(PURCHASE_AMOUNT, 2);
        expect(invoiceOrder?.dueDay).toBe(DUE_DAY);
        expect(invoiceOrder?.startMonth).toBe("2025-03");

        const invoice = await propagateInvoiceOrder(orderId, false);
        expect(invoice).not.toBeNull();

        // A janela do ciclo fica GRAVADA na order e na parcela: é dela que a
        // tela de detalhe lista as compras, inclusive de uma fatura antiga.
        expect(toDateKey(invoiceOrder!.cycleStart!)).toBe("2025-02-05");
        expect(toDateKey(invoiceOrder!.cycleEnd!)).toBe("2025-03-04");
        expect(toDateKey(invoice!.cycleStart!)).toBe("2025-02-05");
        expect(toDateKey(invoice!.cycleEnd!)).toBe("2025-03-04");
        expect(toDateKey(invoice!.closingDate!)).toBe("2025-03-05");

        const next = await readNextInvoice();
        expect(next!.amount).toBeCloseTo(PURCHASE_AMOUNT, 2);
        expect(next!.installmentId).toBe(invoice!.id);
        expect(next!.orderId).toBe(orderId);
        expect(next!.status).toBe(InstallmentStatus.pending);
        expect(toDateKey(next!.dueDate)).toBe("2025-03-10");

        // A compra cai DENTRO da janela que o servidor publicou.
        expect(PURCHASE_DATE.getTime()).toBeGreaterThanOrEqual(next!.cycleStart.getTime());
        expect(PURCHASE_DATE.getTime()).toBeLessThanOrEqual(next!.cycleEnd.getTime());
    });

    it("uma segunda compra soma na mesma fatura e o resumo acompanha", async () => {
        const second: InstallmentModel = {
            id: "inst-farmacia",
            orderId: "order-farmacia",
            amount: 0,
            dueDate: PURCHASE_DATE,
            description: "Farmácia",
            paidAmount: 79.25,
            paidDate: PURCHASE_DATE,
            installmentType: InstallmentType.single,
            status: InstallmentStatus.paid,
            type: OrderType.expense,
            accounts: { [CARD_ID]: "debt" },
            accountIds: [CARD_ID],
            category: CATEGORY,
            referenceDate: PURCHASE_DATE,
            referenceAmount: 79.25,
        };

        await financeService.processInvoiceUpdate(WORKSPACE_ID, null, second);
        await propagateInvoiceOrder(`invoice-${CARD_ID}-2025-03-10`, true);

        const next = await readNextInvoice();
        expect(next!.amount).toBeCloseTo(PURCHASE_AMOUNT + 79.25, 2);
    });

    it("pagar a fatura faz o resumo avançar para o ciclo seguinte", async () => {
        const orderId = `invoice-${CARD_ID}-2025-03-10`;
        const before = (await repository.getInstallmentsByOrderId(WORKSPACE_ID, orderId))[0];
        expect(before).toBeDefined();

        const paidDate = new Date(Date.UTC(2025, 2, 10, 15, 0, 0));
        const after: InstallmentModel = {
            ...before,
            status: InstallmentStatus.paid,
            paidAmount: before.amount,
            paidDate,
            accounts: { [CARD_ID]: "credit", [CHECKING_ID]: "debt" },
            accountIds: [CARD_ID, CHECKING_ID],
        };

        await repository.updateInstallment(WORKSPACE_ID, before.id, {
            status: after.status,
            paidAmount: after.paidAmount,
            paidDate: after.paidDate,
            accounts: after.accounts,
            accountIds: after.accountIds,
        });

        await financeService.processInvoiceUpdate(WORKSPACE_ID, before, after);

        // Sem fatura em aberto, o resumo volta ao ciclo corrente com valor zero.
        const next = await readNextInvoice();
        expect(next!.installmentId).toBeNull();
        expect(next!.amount).toBe(0);
        expect(next!.status).toBe(InstallmentStatus.pending);

        // O caminho real (`processInvoiceUpdate`) usa o relógio de produção, e
        // sobre ele só dá para afirmar "avançou". A DATA exata é conferida
        // repetindo a sincronização com o relógio injetado: 11/03, um dia
        // depois do vencimento pago, tem de apontar para 10/04.
        await invoiceSync.syncNextInvoice(
            WORKSPACE_ID,
            CARD_ID,
            null,
            new Date(Date.UTC(2025, 2, 11, 15, 0, 0))
        );

        const exact = await readNextInvoice();
        expect(toDateKey(exact!.dueDate)).toBe("2025-04-10");
        expect(toDateKey(exact!.closingDate)).toBe("2025-04-05");
        expect(toDateKey(exact!.cycleStart)).toBe("2025-03-05");
        expect(toDateKey(exact!.cycleEnd)).toBe("2025-04-04");
        expect(exact!.orderId).toBe(`invoice-${CARD_ID}-2025-04-10`);
        expect(exact!.installmentId).toBeNull();
        expect(exact!.amount).toBe(0);
    });

    it("soma na order de fatura LEGADA quando os ids divergem", async () => {
        // O id canônico usa o dia no fuso do produto; o legado usava o dia em
        // UTC. Um vencimento às 23h de São Paulo já é o dia seguinte em UTC:
        // 10/03 canônico, 11/03 legado.
        const dueDate = new Date(Date.UTC(2025, 2, 11, 2, 0, 0));
        const legacyId = `invoice-${LEGACY_CARD_ID}-2025-03-11`;
        const canonicalId = `invoice-${LEGACY_CARD_ID}-2025-03-10`;

        expect(InvoiceService.invoiceOrderId(LEGACY_CARD_ID, dueDate)).toBe(canonicalId);
        expect(InvoiceService.legacyInvoiceOrderId(LEGACY_CARD_ID, dueDate)).toBe(legacyId);

        // Só a order LEGADA existe, como numa base gravada antes de F1.8.
        await firestore.doc(`workspaces/${WORKSPACE_ID}/orders/${legacyId}`).set({
            amount: 200,
            dueDay: 11,
            description: "Fatura Cartão Legado",
            startMonth: "2025-03",
            endMonth: "2025-03",
            installmentType: InstallmentType.single,
            status: "active",
            type: OrderType.transfer,
            accountIds: [LEGACY_CARD_ID],
            accounts: { [LEGACY_CARD_ID]: "credit" },
            isInvoice: true,
        });

        const legacyCard = await repository.getAccountById(WORKSPACE_ID, LEGACY_CARD_ID);
        await repository.updateInvoiceWithDelta(WORKSPACE_ID, legacyCard!, dueDate, 5000);

        // O delta foi para a order que já existia...
        const legacy = await firestore.doc(`workspaces/${WORKSPACE_ID}/orders/${legacyId}`).get();
        expect(legacy.data()?.amount).toBeCloseTo(250, 2);
        // ...e a canônica NÃO foi criada ao lado: seriam duas faturas do mesmo mês.
        const canonical = await firestore.doc(`workspaces/${WORKSPACE_ID}/orders/${canonicalId}`).get();
        expect(canonical.exists).toBe(false);

        // A janela do ciclo é gravada na order legada do mesmo jeito.
        expect(legacy.data()?.cycleStart).toBeDefined();
        expect(legacy.data()?.cycleEnd).toBeDefined();
    });

    it("usa o id canônico quando a order de fatura ainda não existe", async () => {
        const dueDate = new Date(Date.UTC(2025, 5, 11, 2, 0, 0));
        const canonicalId = `invoice-${LEGACY_CARD_ID}-2025-06-10`;

        const legacyCard = await repository.getAccountById(WORKSPACE_ID, LEGACY_CARD_ID);
        await repository.updateInvoiceWithDelta(WORKSPACE_ID, legacyCard!, dueDate, 7500);

        const canonical = await firestore.doc(`workspaces/${WORKSPACE_ID}/orders/${canonicalId}`).get();
        expect(canonical.data()?.amount).toBeCloseTo(75, 2);

        const legacy = await firestore
            .doc(`workspaces/${WORKSPACE_ID}/orders/invoice-${LEGACY_CARD_ID}-2025-06-11`)
            .get();
        expect(legacy.exists).toBe(false);
    });

    it("o cron avança o vencimento vencido e deixa o cartão em dia quieto", async () => {
        // Volta o resumo para um vencimento no passado, como se o ciclo
        // tivesse virado sem nenhuma escrita no workspace.
        await repository.setAccountNextInvoice(WORKSPACE_ID, CARD_ID, {
            dueDate: new Date(Date.UTC(2025, 2, 10, 15, 0, 0)),
            closingDate: new Date(Date.UTC(2025, 2, 5, 3, 0, 0)),
            cycleStart: new Date(Date.UTC(2025, 1, 5, 3, 0, 0)),
            cycleEnd: new Date(Date.UTC(2025, 2, 5, 2, 59, 59)),
            amount: 0,
            amountCents: 0,
            orderId: `invoice-${CARD_ID}-2025-03-10`,
            installmentId: null,
            status: InstallmentStatus.pending,
        });

        const now = new Date(Date.UTC(2025, 3, 15, 15, 0, 0)); // 15/04/2025
        const result = await invoiceSync.syncWorkspace(WORKSPACE_ID, now);

        // Dois cartões no workspace: o do fluxo e o dos testes de id de order.
        // Os dois entram desatualizados — um com o vencimento vencido, o outro
        // sem resumo nenhum (nenhum gatilho roda no emulador).
        expect(result.scanned).toBe(2);
        expect(result.updated).toBe(2);

        const next = await readNextInvoice();
        expect(toDateKey(next!.dueDate)).toBe("2025-05-10");
        expect(toDateKey(next!.cycleStart)).toBe("2025-04-05");
        expect(toDateKey(next!.cycleEnd)).toBe("2025-05-04");

        // Segunda passagem no mesmo instante: os dois estão em dia e o cron não
        // escreve nada — é essa quietude que impede o gatilho de se realimentar.
        expect(await invoiceSync.syncWorkspace(WORKSPACE_ID, now)).toEqual({ scanned: 2, updated: 0 });
    });

    it("cartão apagado logicamente perde o resumo", async () => {
        await firestore.doc(`workspaces/${WORKSPACE_ID}/accounts/${CARD_ID}`)
            .set({ isDeleted: true }, { merge: true });

        expect(await invoiceSync.syncNextInvoice(WORKSPACE_ID, CARD_ID)).toBe(true);

        const snapshot = await firestore.doc(`workspaces/${WORKSPACE_ID}/accounts/${CARD_ID}`).get();
        expect(snapshot.data()?.nextInvoice).toBeUndefined();
    });
});
