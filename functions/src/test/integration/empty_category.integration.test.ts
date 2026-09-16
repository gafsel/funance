// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import { FinanceRepositoryImpl } from "../../features/finance/data/repositories/finance.repository.impl";
import { RebuildRepositoryImpl } from "../../features/finance/data/repositories/rebuild.repository.impl";
import { FinanceService } from "../../features/finance/domain/services/finance.service";
import { SummaryService } from "../../features/finance/domain/services/summary.service";
import { RebuildService } from "../../features/finance/domain/services/rebuild.service";
import {
    AccountModel,
    AccountType,
    InstallmentModel,
    InstallmentStatus,
    InstallmentType,
    OrderType,
} from "../../features/finance/domain/models/finance.models";
import { CategoryModel, CategoryType } from "../../features/workspace/domain/models/category.model";

/**
 * HOTFIX — categoria sem id, contra o emulador do Firestore.
 *
 * Os testes unitários provam a REGRA; este prova o SINTOMA. A falha original só
 * aparece com o SDK de verdade: `period_summaries.categories.""` vira um
 * segmento vazio de `FieldPath` e o documento inteiro é rejeitado com
 * `Element at index 0 should not be an empty string`. Era assim que o gatilho
 * de sumário morria e o `rebuild_workspace --apply` falhava no commit — com o
 * dry-run limpo, porque ele nem chega a montar a referência.
 */

const MERCADO: CategoryModel = {
    id: "cat-mercado",
    name: "Supermercado",
    icon: "shopping_cart",
    color: "#42A5F5",
    type: CategoryType.expense,
    isDeleted: false,
    allocation: "essential",
};

/** O documento realmente encontrado em produção: nome preenchido, id vazio. */
const QUEBRADA = { ...MERCADO, id: "" };

const CHECKING: AccountModel = {
    id: "acc-checking",
    name: "Conta Corrente",
    icon: "account_balance",
    color: "#4CAF50",
    runtimeType: AccountType.checking,
    isDeleted: false,
    initialBalance: 0,
    initialBalanceDate: new Date(2026, 0, 1, 12),
};

const DATA = new Date(2026, 2, 10, 12);

let firestore: admin.firestore.Firestore;
let financeRepository: FinanceRepositoryImpl;
let summaryService: SummaryService;
let rebuildService: RebuildService;
let warn: jest.SpyInstance;

const workspaces: string[] = [];

function newWorkspace(label: string): string {
    const workspaceId = `ws-empty-category-${label}-${Date.now()}`;
    workspaces.push(workspaceId);
    return workspaceId;
}

function installment(category: CategoryModel | undefined): InstallmentModel {
    return {
        id: "inst-quebrada",
        orderId: "order-1",
        amount: 167.47,
        dueDate: DATA,
        description: "Compra no mercado",
        installmentType: InstallmentType.single,
        status: InstallmentStatus.paid,
        type: OrderType.expense,
        accounts: { [CHECKING.id]: "debt" },
        accountIds: [CHECKING.id],
        category,
        paidAmount: 167.47,
        paidDate: DATA,
        referenceDate: DATA,
        referenceAmount: 167.47,
    };
}

/** Grava a parcela como o app grava: Timestamps, sem normalizar a hora. */
async function writeInstallment(workspaceId: string, inst: InstallmentModel): Promise<void> {
    const { id, dueDate, paidDate, ...rest } = inst;
    await firestore.doc(`workspaces/${workspaceId}/installments/${id}`).set({
        ...rest,
        dueDate: admin.firestore.Timestamp.fromDate(dueDate),
        paidDate: paidDate ? admin.firestore.Timestamp.fromDate(paidDate) : null,
    });
    await firestore.doc(`workspaces/${workspaceId}/accounts/${CHECKING.id}`).set({
        ...CHECKING,
        initialBalanceDate: admin.firestore.Timestamp.fromDate(CHECKING.initialBalanceDate!),
    });
}

const summaryIds = async (workspaceId: string): Promise<string[]> => {
    const snapshot = await firestore.collection(`workspaces/${workspaceId}/period_summaries`).get();
    return snapshot.docs.map((doc) => doc.id).sort();
};

describe("Categoria sem id (integração com emulador do Firestore)", () => {
    beforeAll(async () => {
        if (admin.apps.length === 0) {
            admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
            admin.firestore().settings({ ignoreUndefinedProperties: true });
        }

        firestore = admin.firestore();
        financeRepository = new FinanceRepositoryImpl();
        summaryService = new SummaryService(financeRepository);
        rebuildService = new RebuildService(
            new RebuildRepositoryImpl(),
            summaryService,
            new FinanceService(financeRepository)
        );
    });

    beforeEach(() => {
        warn = jest.spyOn(console, "warn").mockImplementation(() => undefined);
    });

    afterEach(() => {
        warn.mockRestore();
    });

    afterAll(async () => {
        for (const workspaceId of workspaces) {
            await firestore.recursiveDelete(firestore.doc(`workspaces/${workspaceId}`));
        }
        await Promise.all(admin.apps.map((app) => app?.delete()));
    });

    it("o SDK realmente rejeita a chave de categoria vazia (a falha original)", async () => {
        const workspaceId = newWorkspace("sintoma");

        // Envolvido numa função: o SDK valida o field mask ANTES de devolver a
        // promessa, então a exceção pode ser síncrona.
        const write = async () => firestore
            .doc(`workspaces/${workspaceId}/period_summaries/2026-03`)
            .set({ categories: { "": { actualAmount: 1 } } }, { merge: true });

        await expect(write()).rejects.toThrow(/empty string/);
    });

    it("o gatilho de sumário não quebra e não cria documento nenhum", async () => {
        const workspaceId = newWorkspace("gatilho");
        const inst = installment(QUEBRADA);

        await writeInstallment(workspaceId, inst);
        await summaryService.processInstallmentChange(workspaceId, null, inst);

        expect(await summaryIds(workspaceId)).toEqual([]);
        expect(warn).toHaveBeenCalledTimes(1);
    });

    it("o rebuild --apply completa, conta a parcela e deixa os sumários vazios", async () => {
        const workspaceId = newWorkspace("rebuild");

        await writeInstallment(workspaceId, installment(QUEBRADA));

        const report = await rebuildService.rebuildWorkspace(workspaceId, {
            dryRun: false,
            now: new Date(2026, 2, 15, 12),
        });

        expect(report.scanned.installments).toBe(1);
        expect(report.scanned.installmentsWithoutCategory).toBe(1);
        expect(await summaryIds(workspaceId)).toEqual([]);

        // Saldo e XP não dependem de categoria: seguem reconstruídos.
        const balance = await firestore
            .doc(`workspaces/${workspaceId}/accounts/${CHECKING.id}/balance/2026-03-10`)
            .get();
        expect(balance.data()?.balance).toBeCloseTo(-167.47, 2);
        expect((await firestore.doc(`workspaces/${workspaceId}/weekly_xp/2026-W10`).get()).exists).toBe(true);
    });

    it("com a categoria corrigida, o mesmo fluxo volta a somar os sumários", async () => {
        const workspaceId = newWorkspace("corrigida");

        await writeInstallment(workspaceId, installment(MERCADO));

        const report = await rebuildService.rebuildWorkspace(workspaceId, {
            dryRun: false,
            now: new Date(2026, 2, 15, 12),
        });

        expect(report.scanned.installmentsWithoutCategory).toBe(0);
        expect(await summaryIds(workspaceId)).toEqual(["2026", "2026-03", "2026-W10"]);

        const month = await firestore.doc(`workspaces/${workspaceId}/period_summaries/2026-03`).get();
        expect(month.data()?.categories[MERCADO.id].actualAmount).toBeCloseTo(167.47, 2);
    });
});
