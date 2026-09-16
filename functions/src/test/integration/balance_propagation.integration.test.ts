// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import { FinanceRepositoryImpl } from "../../features/finance/data/repositories/finance.repository.impl";
import { RebuildRepositoryImpl } from "../../features/finance/data/repositories/rebuild.repository.impl";
import { FinanceService } from "../../features/finance/domain/services/finance.service";
import { SummaryService } from "../../features/finance/domain/services/summary.service";
import { RebuildService } from "../../features/finance/domain/services/rebuild.service";
import { toDateKey } from "../../core/utils/date_key";
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

/**
 * F1.4 — saldo diário no emulador do Firestore.
 *
 * Três coisas que o modelo antigo não conseguia fazer:
 *  1. pagamento retroativo com MUITOS dias de saldo futuro (a transação única
 *     estourava o limite de 500 escritas);
 *  2. dois pagamentos em dias diferentes convergindo para o mesmo estado que o
 *     job de reconstrução calcula do zero;
 *  3. pagamento perto da meia-noite de Brasília caindo no dia certo (o id vinha
 *     de `toISOString()`, ou seja, UTC).
 */

const CATEGORY: CategoryModel = {
    id: "cat-mercado",
    name: "Mercado",
    icon: "shopping_cart",
    color: "#42A5F5",
    type: CategoryType.expense,
    isDeleted: false,
    allocation: "essential",
};

const ACCOUNT_ID = "acc-checking";

let firestore: admin.firestore.Firestore;
let financeRepository: FinanceRepositoryImpl;
let financeService: FinanceService;
let summaryService: SummaryService;
let rebuildService: RebuildService;

async function createAccount(workspaceId: string): Promise<void> {
    const account: Omit<AccountModel, "id"> = {
        name: "Conta Corrente",
        icon: "account_balance",
        color: "#4CAF50",
        runtimeType: AccountType.checking,
        isDeleted: false,
        initialBalance: 0,
        initialBalanceDate: new Date(2023, 0, 1, 12),
    };
    await firestore.doc(`workspaces/${workspaceId}/accounts/${ACCOUNT_ID}`).set(account);
}

function balanceCollection(workspaceId: string) {
    return firestore.collection(`workspaces/${workspaceId}/accounts/${ACCOUNT_ID}/balance`);
}

async function readBalance(workspaceId: string, dateKey: string): Promise<Record<string, any> | undefined> {
    const doc = await balanceCollection(workspaceId).doc(dateKey).get();
    return doc.exists ? doc.data() : undefined;
}

describe("Saldo diário (integração com emulador do Firestore)", () => {
    const workspaces: string[] = [];

    beforeAll(async () => {
        if (admin.apps.length === 0) {
            admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
            admin.firestore().settings({ ignoreUndefinedProperties: true });
        }

        firestore = admin.firestore();
        financeRepository = new FinanceRepositoryImpl();
        financeService = new FinanceService(financeRepository);
        summaryService = new SummaryService(financeRepository);
        rebuildService = new RebuildService(new RebuildRepositoryImpl(), summaryService, financeService);
    });

    afterAll(async () => {
        for (const workspaceId of workspaces) {
            await firestore.recursiveDelete(firestore.doc(`workspaces/${workspaceId}`));
        }
        await Promise.all(admin.apps.map((app) => app?.delete()));
    });

    function newWorkspace(label: string): string {
        const workspaceId = `ws-balance-${label}-${Date.now()}`;
        workspaces.push(workspaceId);
        return workspaceId;
    }

    it("pagamento retroativo de 3 anos propaga 1000 dias de saldo em lotes", async () => {
        const workspaceId = newWorkspace("retroativo");
        await createAccount(workspaceId);

        // Ancoragem: o dia do pagamento retroativo já existe com saldo 5000.
        const anchorKey = "2023-01-01";
        await balanceCollection(workspaceId).doc(anchorKey).set({
            dateKey: anchorKey,
            delta: 5000,
            balance: 5000,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 1000 dias seguintes, sem movimento (saldo repetido).
        const days: string[] = [];
        let writer = firestore.batch();
        let pending = 0;
        for (let i = 1; i <= 1000; i++) {
            const day = new Date(Date.UTC(2023, 0, 1 + i));
            const key = day.toISOString().split("T")[0];
            days.push(key);
            writer.set(balanceCollection(workspaceId).doc(key), {
                dateKey: key,
                delta: 0,
                balance: 5000,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            pending++;
            if (pending === 400) {
                await writer.commit();
                writer = firestore.batch();
                pending = 0;
            }
        }
        if (pending > 0) await writer.commit();

        const total = await balanceCollection(workspaceId).count().get();
        expect(total.data().count).toBe(1001);

        // Pagamento retroativo no dia âncora: no modelo antigo, os 1000
        // documentos seguintes entravam todos na mesma transação.
        await financeRepository.updateAccountBalance(
            workspaceId,
            ACCOUNT_ID,
            new Date("2023-01-01T15:00:00.000Z"),
            -250.75
        );

        expect(await readBalance(workspaceId, anchorKey)).toMatchObject({
            dateKey: anchorKey,
            delta: 4749.25,
            balance: 4749.25,
        });

        for (const key of [days[0], days[399], days[400], days[999]]) {
            const doc = await readBalance(workspaceId, key);
            expect({ key, balance: doc!.balance }).toEqual({ key, balance: expect.closeTo(4749.25, 2) });
        }

        // Nenhum documento a mais, nenhum a menos.
        const after = await balanceCollection(workspaceId).count().get();
        expect(after.data().count).toBe(1001);
    }, 120000);

    it("dois pagamentos em dias diferentes convergem com o rebuild (zero diferenças)", async () => {
        const workspaceId = newWorkspace("concorrente");
        await createAccount(workspaceId);

        const order: OrderModel = {
            id: "order-2x",
            amount: 400,
            dueDay: 10,
            description: "Compra 2x",
            startMonth: "2026-03",
            installmentCount: 2,
            installmentType: InstallmentType.installment,
            status: OrderStatus.active,
            type: OrderType.expense,
            accounts: { [ACCOUNT_ID]: "debt" },
            accountIds: [ACCOUNT_ID],
            category: CATEGORY,
        };

        const orderData: Omit<OrderModel, "id"> = { ...order };
        delete (orderData as Partial<OrderModel>).id;
        await financeRepository.createOrder(workspaceId, orderData, order.id);
        await financeService.syncInstallments(workspaceId, order.id, null, order);

        const created = (await financeRepository.getInstallmentsByOrderId(workspaceId, order.id))
            .sort((a, b) => a.dueDate.getTime() - b.dueDate.getTime());
        expect(created).toHaveLength(2);

        for (const installment of created) {
            await summaryService.processInstallmentChange(workspaceId, null, installment);
        }

        const pay = async (installment: InstallmentModel) => {
            const paidDate = new Date(installment.dueDate);
            paidDate.setHours(12, 0, 0, 0);

            const after: InstallmentModel = {
                ...installment,
                status: InstallmentStatus.paid,
                paidAmount: installment.amount,
                paidDate,
            };

            await financeRepository.updateInstallment(workspaceId, installment.id, {
                status: InstallmentStatus.paid,
                paidAmount: after.paidAmount,
                paidDate: after.paidDate,
            });
            await financeService.updateAccountBalanceOnInstallmentChange(workspaceId, installment, after);
            await summaryService.processInstallmentChange(workspaceId, installment, after);
        };

        // Os dois gatilhos rodando ao mesmo tempo, como acontece quando o app
        // marca duas parcelas como pagas em sequência rápida.
        await Promise.all([pay(created[0]), pay(created[1])]);

        const firstKey = toDateKey(new Date(new Date(created[0].dueDate).setHours(12, 0, 0, 0)));
        const secondKey = toDateKey(new Date(new Date(created[1].dueDate).setHours(12, 0, 0, 0)));

        expect((await readBalance(workspaceId, firstKey))!.balance).toBeCloseTo(-200, 2);
        expect((await readBalance(workspaceId, secondKey))!.balance).toBeCloseTo(-400, 2);

        // O oráculo: o rebuild recalcula do zero e não encontra divergência.
        const report = await rebuildService.rebuildWorkspace(workspaceId, { dryRun: true });
        expect(report.diff.balances).toMatchObject({ toCreate: 0, toUpdate: 0, toDelete: 0 });
    });

    it("pagamento às 23h30 de São Paulo cai no dia de São Paulo, não no de UTC", async () => {
        const workspaceId = newWorkspace("fuso");
        await createAccount(workspaceId);

        // 23h30 de 10/03/2026 em São Paulo = 02h30 de 11/03/2026 em UTC.
        const lateNight = new Date("2026-03-11T02:30:00.000Z");
        expect(lateNight.toISOString().split("T")[0]).toBe("2026-03-11");

        await financeRepository.updateAccountBalance(workspaceId, ACCOUNT_ID, lateNight, -42.5);

        expect(await readBalance(workspaceId, "2026-03-10")).toMatchObject({
            dateKey: "2026-03-10",
            delta: -42.5,
            balance: -42.5,
        });
        expect(await readBalance(workspaceId, "2026-03-11")).toBeUndefined();
    });

    it("o primeiro pagamento do dia parte do saldo do último dia anterior", async () => {
        const workspaceId = newWorkspace("anterior");
        await createAccount(workspaceId);

        await financeRepository.updateAccountBalance(workspaceId, ACCOUNT_ID, new Date("2026-03-01T15:00:00.000Z"), 1000);
        await financeRepository.updateAccountBalance(workspaceId, ACCOUNT_ID, new Date("2026-03-10T15:00:00.000Z"), -167.47);
        await financeRepository.updateAccountBalance(workspaceId, ACCOUNT_ID, new Date("2026-03-20T15:00:00.000Z"), -50);

        expect((await readBalance(workspaceId, "2026-03-01"))!.balance).toBeCloseTo(1000, 2);
        expect((await readBalance(workspaceId, "2026-03-10"))!.balance).toBeCloseTo(832.53, 2);
        expect((await readBalance(workspaceId, "2026-03-20"))!.balance).toBeCloseTo(782.53, 2);

        // E um lançamento retroativo reposiciona toda a série.
        await financeRepository.updateAccountBalance(workspaceId, ACCOUNT_ID, new Date("2026-03-05T15:00:00.000Z"), -100);

        expect((await readBalance(workspaceId, "2026-03-05"))!.balance).toBeCloseTo(900, 2);
        expect((await readBalance(workspaceId, "2026-03-10"))!.balance).toBeCloseTo(732.53, 2);
        expect((await readBalance(workspaceId, "2026-03-20"))!.balance).toBeCloseTo(682.53, 2);
    });

    it("convive com documentos legados (sem dateKey) e os migra ao passar", async () => {
        const workspaceId = newWorkspace("legado");
        await createAccount(workspaceId);

        // Formato anterior a F1.4: só `balance`.
        await balanceCollection(workspaceId).doc("2026-03-01").set({ balance: 1000 });
        await balanceCollection(workspaceId).doc("2026-03-20").set({ balance: 800 });

        await financeRepository.updateAccountBalance(workspaceId, ACCOUNT_ID, new Date("2026-03-10T15:00:00.000Z"), -50);

        // O dia novo achou o legado mais recente ANTES dele (2026-03-01).
        expect(await readBalance(workspaceId, "2026-03-10")).toMatchObject({
            dateKey: "2026-03-10",
            delta: -50,
            balance: 950,
        });
        // E o legado POSTERIOR foi propagado e ganhou o dateKey.
        expect(await readBalance(workspaceId, "2026-03-20")).toMatchObject({
            dateKey: "2026-03-20",
            balance: 750,
        });
    });
});
