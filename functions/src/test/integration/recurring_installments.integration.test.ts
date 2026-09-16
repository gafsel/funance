// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import { FinanceRepositoryImpl } from "../../features/finance/data/repositories/finance.repository.impl";
import { FinanceService } from "../../features/finance/domain/services/finance.service";
import {
    InstallmentType,
    OrderModel,
    OrderStatus,
    OrderType,
} from "../../features/finance/domain/models/finance.models";
import { CategoryModel, CategoryType } from "../../features/workspace/domain/models/category.model";

/**
 * F1.6 — as parcelas geradas pelo cron de recorrência têm de ser idênticas, em
 * schema, às criadas pelo fluxo normal: as duas passam por
 * `FinanceRepositoryImpl.createInstallments`.
 */
const WORKSPACE_ID = `ws-recurring-${Date.now()}`;
const ACCOUNT_ID = "acc-checking";
const ORDER_ID = "order-netflix";

const CATEGORY: CategoryModel = {
    id: "cat-assinaturas",
    name: "Assinaturas",
    icon: "subscriptions",
    color: "#E53935",
    type: CategoryType.expense,
    isDeleted: false,
    allocation: "comfort",
};

const toMonthId = (date: Date) =>
    `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;

describe("Recorrência (integração com emulador do Firestore)", () => {
    let firestore: admin.firestore.Firestore;
    let repository: FinanceRepositoryImpl;
    let financeService: FinanceService;

    const installmentsOfOrder = async () => {
        const snapshot = await firestore
            .collection(`workspaces/${WORKSPACE_ID}/installments`)
            .where("orderId", "==", ORDER_ID)
            .get();
        return snapshot.docs;
    };

    beforeAll(async () => {
        if (admin.apps.length === 0) {
            admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
            admin.firestore().settings({ ignoreUndefinedProperties: true });
        }

        firestore = admin.firestore();
        repository = new FinanceRepositoryImpl();
        financeService = new FinanceService(repository);
    });

    it("cron e fluxo normal criam parcelas com exatamente o mesmo schema", async () => {
        const order: Omit<OrderModel, "id"> = {
            amount: 55.9,
            dueDay: 10,
            description: "Netflix",
            startMonth: toMonthId(new Date()),
            installmentType: InstallmentType.recurring,
            status: OrderStatus.active,
            type: OrderType.expense,
            accounts: { [ACCOUNT_ID]: "debt" },
            accountIds: [ACCOUNT_ID],
            category: CATEGORY,
        };

        await repository.createOrder(WORKSPACE_ID, order, ORDER_ID);

        // 1) Fluxo normal: a criação da order gera o horizonte de parcelas.
        await financeService.syncInstallments(
            WORKSPACE_ID,
            ORDER_ID,
            null,
            { id: ORDER_ID, ...order } as OrderModel
        );

        const normalDocs = await installmentsOfOrder();
        expect(normalDocs.length).toBeGreaterThan(0);

        const normalIds = new Set(normalDocs.map((d) => d.id));
        const normalKeys = Object.keys(normalDocs[0].data()).sort();

        const orderAfterSync = await repository.getOrderById(WORKSPACE_ID, ORDER_ID);
        expect(orderAfterSync?.lastGeneratedDueDate).toBeInstanceOf(Date);

        // 2) Cron simulado: o mesmo código que roda no agendamento diário.
        await financeService.generateRecurringInstallments();

        const afterCronDocs = await installmentsOfOrder();
        const cronDocs = afterCronDocs.filter((d) => !normalIds.has(d.id));

        expect(cronDocs.length).toBeGreaterThan(0);

        for (const doc of cronDocs) {
            const data = doc.data();
            expect(Object.keys(data).sort()).toEqual(normalKeys);

            // Mesmos tipos, não só as mesmas chaves.
            expect(data.dueDate).toBeInstanceOf(admin.firestore.Timestamp);
            expect(data.referenceDate).toBeInstanceOf(admin.firestore.Timestamp);
            expect(data.paidDate).toBeNull();
            expect(data.referenceAmount).toBe(data.amount);
            expect(data.status).toBe("pending");
            expect(data.installmentType).toBe(InstallmentType.recurring);
        }

        // 3) O cron avançou a marca da order.
        const orderAfterCron = await repository.getOrderById(WORKSPACE_ID, ORDER_ID);
        expect(orderAfterCron!.lastGeneratedDueDate!.getTime())
            .toBeGreaterThan(orderAfterSync!.lastGeneratedDueDate!.getTime());

        // 4) Idempotente no mesmo dia: rodar de novo não duplica nada.
        await financeService.generateRecurringInstallments();
        const afterSecondRun = await installmentsOfOrder();
        expect(afterSecondRun.length).toBe(afterCronDocs.length);
    });

    it("order recorrente SEM lastGeneratedDueDate nunca é estendida", async () => {
        const orphanId = "order-sem-marca";
        const order: Omit<OrderModel, "id"> = {
            amount: 30,
            dueDay: 5,
            description: "Order legada sem marca",
            startMonth: toMonthId(new Date()),
            installmentType: InstallmentType.recurring,
            status: OrderStatus.active,
            type: OrderType.expense,
            accounts: { [ACCOUNT_ID]: "debt" },
            accountIds: [ACCOUNT_ID],
            category: CATEGORY,
        };

        // Gravada direto, sem passar por syncInstallments: nasce sem
        // `lastGeneratedDueDate`, como as orders legadas da base.
        await repository.createOrder(WORKSPACE_ID, order, orphanId);

        await financeService.generateRecurringInstallments();

        const snapshot = await firestore
            .collection(`workspaces/${WORKSPACE_ID}/installments`)
            .where("orderId", "==", orphanId)
            .get();

        expect(snapshot.empty).toBe(true);
    });
});
