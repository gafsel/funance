// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import {
    handleInstallmentWritten,
    INSTALLMENT_DERIVED_FIELDS,
} from "../../features/finance/presentation/functions/installment_handler";
import { getChangedFields } from "../../core/utils/diff.utils";
import { FinanceRepositoryImpl } from "../../features/finance/data/repositories/finance.repository.impl";
import {
    AccountModel,
    AccountType,
    InstallmentStatus,
    InstallmentType,
    OrderModel,
    OrderStatus,
    OrderType,
    ReplicationCascade,
} from "../../features/finance/domain/models/finance.models";
import { CategoryModel, CategoryType } from "../../features/workspace/domain/models/category.model";

/**
 * F1.1 — guarda por conteúdo no gatilho de parcela.
 *
 * O emulador do Firestore NÃO dispara triggers nos testes, então o segundo
 * evento (o eco da escrita de xp feita pelo próprio handler) é simulado
 * chamando `handleInstallmentWritten` com before = documento antes do xp e
 * after = documento depois do xp — exatamente o par que o Eventarc entregaria.
 */
const WORKSPACE_ID = `ws-handler-${Date.now()}`;
const ACCOUNT_ID = "acc-checking";
const ORDER_ID = "order-curso-2x";

const CATEGORY: CategoryModel = {
    id: "cat-educacao",
    name: "Educação",
    icon: "school",
    color: "#7E57C2",
    type: CategoryType.expense,
    isDeleted: false,
    allocation: "essential",
};

describe("Gatilho de parcela: guarda por conteúdo (integração com emulador)", () => {
    let firestore: admin.firestore.Firestore;
    let repository: FinanceRepositoryImpl;
    let installmentId: string;

    const installmentRef = () =>
        firestore.collection(`workspaces/${WORKSPACE_ID}/installments`).doc(installmentId);

    beforeAll(async () => {
        if (admin.apps.length === 0) {
            admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
            admin.firestore().settings({ ignoreUndefinedProperties: true });
        }

        firestore = admin.firestore();
        repository = new FinanceRepositoryImpl();

        const account: Omit<AccountModel, "id"> = {
            name: "Conta Corrente",
            icon: "account_balance",
            color: "#4CAF50",
            runtimeType: AccountType.checking,
            isDeleted: false,
            initialBalance: 0,
            initialBalanceDate: new Date(2025, 0, 1, 12),
        };
        await firestore.doc(`workspaces/${WORKSPACE_ID}/accounts/${ACCOUNT_ID}`).set(account);
        await firestore.doc(`workspaces/${WORKSPACE_ID}/categories/${CATEGORY.id}`).set(CATEGORY);

        const order: Omit<OrderModel, "id"> = {
            amount: 200,
            dueDay: 10,
            description: "Curso de inglês",
            startMonth: "2025-03",
            installmentCount: 2,
            installmentType: InstallmentType.installment,
            status: OrderStatus.active,
            type: OrderType.expense,
            accounts: { [ACCOUNT_ID]: "debt" },
            accountIds: [ACCOUNT_ID],
            category: CATEGORY,
        };
        await repository.createOrder(WORKSPACE_ID, order, ORDER_ID);

        await repository.createInstallments(WORKSPACE_ID, [
            {
                orderId: ORDER_ID,
                amount: 100,
                dueDate: new Date(2025, 2, 10, 12),
                description: "Curso de inglês",
                status: InstallmentStatus.pending,
                type: OrderType.expense,
                installmentType: InstallmentType.installment,
                installmentNumber: 1,
                installmentCount: 2,
                accounts: { [ACCOUNT_ID]: "debt" },
                accountIds: [ACCOUNT_ID],
                category: CATEGORY,
            },
            {
                orderId: ORDER_ID,
                amount: 100,
                dueDate: new Date(2025, 3, 10, 12),
                description: "Curso de inglês",
                status: InstallmentStatus.pending,
                type: OrderType.expense,
                installmentType: InstallmentType.installment,
                installmentNumber: 2,
                installmentCount: 2,
                accounts: { [ACCOUNT_ID]: "debt" },
                accountIds: [ACCOUNT_ID],
                category: CATEGORY,
            },
        ]);

        const created = await firestore
            .collection(`workspaces/${WORKSPACE_ID}/installments`)
            .where("orderId", "==", ORDER_ID)
            .where("installmentNumber", "==", 1)
            .get();

        installmentId = created.docs[0].id;
    });

    it("pagar uma parcela gera exatamente 1 evento derivado, e ele sai cedo", async () => {
        const beforePay = (await installmentRef().get()).data()!;
        const paidDate = new Date(2025, 2, 9, 12);

        // 1) O cliente paga a parcela (mesma escrita que o app faz).
        await installmentRef().update({
            status: InstallmentStatus.paid,
            paidAmount: 100,
            paidDate: admin.firestore.Timestamp.fromDate(paidDate),
        });
        const afterPay = (await installmentRef().get()).data()!;

        const updateInstallmentSpy = jest.spyOn(FinanceRepositoryImpl.prototype, "updateInstallment");
        const updateOrderSpy = jest.spyOn(FinanceRepositoryImpl.prototype, "updateOrder");

        // 2) Primeiro evento: a escrita do usuário.
        await handleInstallmentWritten(beforePay, afterPay, {
            workspaceId: WORKSPACE_ID,
            installmentId,
            eventId: `evt-pagamento-${Date.now()}`,
        });

        // A ÚNICA escrita derivada na parcela é o xp (com a cascata zerada
        // junto, na mesma escrita).
        expect(updateInstallmentSpy).toHaveBeenCalledTimes(1);
        expect(updateInstallmentSpy).toHaveBeenCalledWith(WORKSPACE_ID, installmentId, {
            xp: 15,
            replicationCascade: ReplicationCascade.none,
        });
        // Pagar não cascateia: a order não é tocada (e portanto não nasce
        // documento em orders/{id}/history).
        expect(updateOrderSpy).not.toHaveBeenCalled();

        const afterXp = (await installmentRef().get()).data()!;
        expect(afterXp.xp).toBe(15);
        expect(afterXp.replicationCascade).toBe(ReplicationCascade.none);

        // 3) O evento derivado: só campos derivados mudaram.
        const derivedChange = getChangedFields(afterPay, afterXp);
        expect(derivedChange.length).toBeGreaterThan(0);
        expect(derivedChange.every((field) => INSTALLMENT_DERIVED_FIELDS.has(field))).toBe(true);

        updateInstallmentSpy.mockClear();
        updateOrderSpy.mockClear();

        await handleInstallmentWritten(afterPay, afterXp, {
            workspaceId: WORKSPACE_ID,
            installmentId,
            eventId: `evt-derivado-${Date.now()}`,
        });

        // Saída antecipada: nenhum bloco rodou.
        expect(updateInstallmentSpy).not.toHaveBeenCalled();
        expect(updateOrderSpy).not.toHaveBeenCalled();

        const history = await firestore
            .collection(`workspaces/${WORKSPACE_ID}/orders/${ORDER_ID}/history`)
            .get();
        expect(history.empty).toBe(true);

        // O documento não foi tocado de novo (o eco não gerou terceiro evento).
        const afterEcho = (await installmentRef().get()).data()!;
        expect(getChangedFields(afterXp, afterEcho)).toEqual([]);

        updateInstallmentSpy.mockRestore();
        updateOrderSpy.mockRestore();
    });

    it("uma escrita com mudança real de conteúdo NÃO sai cedo", async () => {
        const before = (await installmentRef().get()).data()!;
        const after = { ...before, description: "Curso de inglês avançado" };

        const updateOrderSpy = jest.spyOn(FinanceRepositoryImpl.prototype, "updateOrder");
        const updateInstallmentSpy = jest.spyOn(FinanceRepositoryImpl.prototype, "updateInstallment");

        await handleInstallmentWritten(before, { ...after, replicationCascade: ReplicationCascade.all }, {
            workspaceId: WORKSPACE_ID,
            installmentId,
            eventId: `evt-descricao-${Date.now()}`,
        });

        // Com cascata `all` e descrição alterada, a order é atualizada.
        expect(updateOrderSpy).toHaveBeenCalledWith(
            WORKSPACE_ID,
            ORDER_ID,
            expect.objectContaining({ description: "Curso de inglês avançado" })
        );

        // E a cascata é zerada no documento de ORIGEM: sem pagamento não há
        // escrita de xp, então é esta que impede a cascata de ficar grudada.
        expect(updateInstallmentSpy).toHaveBeenCalledWith(WORKSPACE_ID, installmentId, {
            replicationCascade: ReplicationCascade.none,
        });
        expect((await installmentRef().get()).data()!.replicationCascade)
            .toBe(ReplicationCascade.none);

        updateOrderSpy.mockRestore();
        updateInstallmentSpy.mockRestore();
    });
});
