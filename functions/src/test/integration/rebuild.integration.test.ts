// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import { FinanceRepositoryImpl } from "../../features/finance/data/repositories/finance.repository.impl";
import { RebuildRepositoryImpl } from "../../features/finance/data/repositories/rebuild.repository.impl";
import { FinanceService } from "../../features/finance/domain/services/finance.service";
import { SummaryService } from "../../features/finance/domain/services/summary.service";
import { RebuildService } from "../../features/finance/domain/services/rebuild.service";
import { assertWorkspaceOwner } from "../../core/services/workspace_access.service";
import { fromCents, toCents } from "../../core/utils/money";
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
 * Integração do job de reconstrução (F1.0) contra o emulador do Firestore.
 *
 * A ideia central: os GATILHOS são o oráculo. O estado é construído passando
 * pelos serviços reais que os gatilhos chamam (`FinanceService.syncInstallments`,
 * `SummaryService.processInstallmentChange`,
 * `FinanceService.updateAccountBalanceOnInstallmentChange` e
 * `FinanceService.updateXpOnInstallmentChange`) e o rebuild tem que chegar
 * exatamente no mesmo lugar.
 *
 * F1.4: até a reescrita do saldo diário, o documento do dia precisava ser
 * semeado à mão antes de cada pagamento — `getLastBalanceBefore` usava
 * `orderBy(documentId(), "desc")` e o emulador rejeita varredura descendente
 * por chave. Agora o caminho real (transação pequena + propagação em lotes)
 * roda direto, sem muleta.
 */

const OWNER_UID = "uid-dono";
const MEMBER_UID = "uid-convidado";

const CHECKING_ID = "acc-checking";
const INVEST_ID = "acc-invest";
const DEBT_ID = "acc-debt";

const MERCADO: CategoryModel = {
    id: "cat-mercado",
    name: "Mercado",
    icon: "shopping_cart",
    color: "#42A5F5",
    type: CategoryType.expense,
    isDeleted: false,
    allocation: "essential",
};

const SALARIO: CategoryModel = {
    id: "cat-salario",
    name: "Salário",
    icon: "payments",
    color: "#4CAF50",
    type: CategoryType.income,
    isDeleted: false,
};

const MORADIA: CategoryModel = {
    id: "cat-moradia",
    name: "Moradia",
    icon: "home",
    color: "#FF7043",
    type: CategoryType.expense,
    isDeleted: false,
    allocation: "essential",
};

let firestore: admin.firestore.Firestore;
let financeRepository: FinanceRepositoryImpl;
let financeService: FinanceService;
let summaryService: SummaryService;
let rebuildService: RebuildService;

const dateAt = (year: number, month: number, day: number) => new Date(year, month - 1, day, 12);

/** Decodifica a parcela como o gatilho `onInstallmentWritten` decodifica (Timestamp cru). */
function decodeInstallment(doc: admin.firestore.DocumentSnapshot): InstallmentModel {
    const data = doc.data()!;
    return {
        ...data,
        id: doc.id,
        dueDate: data.dueDate?.toDate ? data.dueDate.toDate() : new Date(data.dueDate),
        paidDate: data.paidDate?.toDate ? data.paidDate.toDate() : (data.paidDate ? new Date(data.paidDate) : null),
    } as InstallmentModel;
}

async function readInstallment(workspaceId: string, id: string): Promise<InstallmentModel> {
    const doc = await firestore.doc(`workspaces/${workspaceId}/installments/${id}`).get();
    return decodeInstallment(doc);
}

async function readInstallmentsOfOrder(workspaceId: string, orderId: string): Promise<InstallmentModel[]> {
    const snapshot = await firestore
        .collection(`workspaces/${workspaceId}/installments`)
        .where("orderId", "==", orderId)
        .get();

    return snapshot.docs
        .map(decodeInstallment)
        .sort((a, b) => a.dueDate.getTime() - b.dueDate.getTime());
}

/** Reproduz o que `onInstallmentWritten` executa (na mesma ordem). */
async function runInstallmentTriggers(
    workspaceId: string,
    before: InstallmentModel | null,
    after: InstallmentModel | null
): Promise<void> {
    await summaryService.processInstallmentChange(workspaceId, before, after);

    await financeService.updateAccountBalanceOnInstallmentChange(workspaceId, before, after);

    await financeService.updateXpOnInstallmentChange(workspaceId, before, after);
}

/** Cria a order, gera as parcelas e dispara o gatilho de criação de cada uma. */
async function createOrderWithInstallments(
    workspaceId: string,
    orderId: string,
    order: Omit<OrderModel, "id">,
    persistOrder = true
): Promise<InstallmentModel[]> {
    if (persistOrder) {
        await financeRepository.createOrder(workspaceId, order, orderId);
    }

    await financeService.syncInstallments(workspaceId, orderId, null, { ...order, id: orderId } as OrderModel);

    const created = await readInstallmentsOfOrder(workspaceId, orderId);
    for (const installment of created) {
        await runInstallmentTriggers(workspaceId, null, installment);
    }

    // Reler: `updateXpOnInstallmentChange` grava o campo `xp` na parcela paga.
    return readInstallmentsOfOrder(workspaceId, orderId);
}

/** Aplica uma alteração na parcela e dispara os gatilhos com before/after reais. */
async function updateInstallmentWithTriggers(
    workspaceId: string,
    installmentId: string,
    patch: Record<string, any>
): Promise<void> {
    const before = await readInstallment(workspaceId, installmentId);
    await financeRepository.updateInstallment(workspaceId, installmentId, patch as Partial<InstallmentModel>);
    const after = await readInstallment(workspaceId, installmentId);
    await runInstallmentTriggers(workspaceId, before, after);
}

async function createAccount(workspaceId: string, id: string, account: Omit<AccountModel, "id">): Promise<void> {
    await firestore.doc(`workspaces/${workspaceId}/accounts/${id}`).set(account);
}

interface WorkspaceSnapshot {
    balances: Record<string, { id: string, balance: number }[]>;
    summaries: Record<string, Record<string, { general: number, specific: number, actual: number }>>;
    weeklyXp: Record<string, number>;
}

async function snapshotWorkspace(workspaceId: string): Promise<WorkspaceSnapshot> {
    const snapshot: WorkspaceSnapshot = { balances: {}, summaries: {}, weeklyXp: {} };

    const accounts = await firestore.collection(`workspaces/${workspaceId}/accounts`).listDocuments();
    for (const account of accounts) {
        const balances = await account.collection("balance").orderBy(admin.firestore.FieldPath.documentId()).get();
        snapshot.balances[account.id] = balances.docs.map((doc) => ({ id: doc.id, balance: doc.data().balance }));
    }

    const summaries = await firestore.collection(`workspaces/${workspaceId}/period_summaries`).get();
    for (const doc of summaries.docs) {
        const categories = doc.data().categories || {};
        snapshot.summaries[doc.id] = {};
        for (const [categoryId, totals] of Object.entries<any>(categories)) {
            snapshot.summaries[doc.id][categoryId] = {
                general: totals.generalPlannedAmount ?? 0,
                specific: totals.specificPlannedAmount ?? 0,
                actual: totals.actualAmount ?? 0,
            };
        }
    }

    const weekly = await firestore.collection(`workspaces/${workspaceId}/weekly_xp`).get();
    for (const doc of weekly.docs) {
        snapshot.weeklyXp[doc.id] = doc.data().xp ?? 0;
    }

    return snapshot;
}

/** Saldo "enxergado" num dia: o do último documento com id <= dia (0 se não houver). */
function impliedBalance(docs: { id: string, balance: number }[], dayId: string): number {
    let value = 0;
    for (const doc of docs) {
        if (doc.id <= dayId) value = doc.balance;
    }
    return value;
}

/**
 * Compara dois estados SEMANTICAMENTE:
 *  - saldos: o valor lido em cada dia tem que ser o mesmo (um documento
 *    residual de dia sem movimento carrega o mesmo saldo do dia anterior, então
 *    não muda o que qualquer consulta enxerga);
 *  - sumários e XP: categoria/documento ausente vale 0.
 */
function expectSameSemantics(incremental: WorkspaceSnapshot, rebuilt: WorkspaceSnapshot, label: string): void {
    const accountIds = new Set([...Object.keys(incremental.balances), ...Object.keys(rebuilt.balances)]);
    for (const accountId of accountIds) {
        const before = incremental.balances[accountId] || [];
        const after = rebuilt.balances[accountId] || [];
        const days = [...new Set([...before.map((d) => d.id), ...after.map((d) => d.id)])].sort();

        for (const day of days) {
            expect({ label, accountId, day, balance: impliedBalance(after, day) })
                .toEqual({ label, accountId, day, balance: expect.closeTo(impliedBalance(before, day), 2) });
        }
    }

    const summaryIds = new Set([...Object.keys(incremental.summaries), ...Object.keys(rebuilt.summaries)]);
    for (const summaryId of summaryIds) {
        const before = incremental.summaries[summaryId] || {};
        const after = rebuilt.summaries[summaryId] || {};
        const categoryIds = new Set([...Object.keys(before), ...Object.keys(after)]);

        for (const categoryId of categoryIds) {
            const zero = { general: 0, specific: 0, actual: 0 };
            const expected = before[categoryId] || zero;
            const actual = after[categoryId] || zero;

            expect({ label, summaryId, categoryId, ...actual }).toEqual({
                label,
                summaryId,
                categoryId,
                general: expect.closeTo(expected.general, 2),
                specific: expect.closeTo(expected.specific, 2),
                actual: expect.closeTo(expected.actual, 2),
            });
        }
    }

    const weekIds = new Set([...Object.keys(incremental.weeklyXp), ...Object.keys(rebuilt.weeklyXp)]);
    for (const weekId of weekIds) {
        expect({ label, weekId, xp: rebuilt.weeklyXp[weekId] ?? 0 })
            .toEqual({ label, weekId, xp: expect.closeTo(incremental.weeklyXp[weekId] ?? 0, 2) });
    }
}

beforeAll(async () => {
    if (admin.apps.length === 0) {
        admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
        admin.firestore().settings({ ignoreUndefinedProperties: false });
    }

    firestore = admin.firestore();
    financeRepository = new FinanceRepositoryImpl();
    financeService = new FinanceService(financeRepository);
    summaryService = new SummaryService(financeRepository);
    rebuildService = new RebuildService(new RebuildRepositoryImpl(), summaryService, financeService);
});

afterAll(async () => {
    await Promise.all(admin.apps.map((app) => app?.delete()));
});

describe("rebuildWorkspace — cenário determinístico", () => {
    const WORKSPACE_ID = `ws-rebuild-${Date.now()}`;
    /** Congelado antes de criar os planejamentos: o gatilho usa `new Date()`. */
    const NOW = new Date();

    beforeAll(async () => {
        await firestore.doc(`workspaces/${WORKSPACE_ID}`).set({
            name: "Rebuild",
            type: "personal",
            members: [OWNER_UID, MEMBER_UID],
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await createAccount(WORKSPACE_ID, CHECKING_ID, {
            name: "Conta Corrente",
            icon: "account_balance",
            color: "#4CAF50",
            runtimeType: AccountType.checking,
            isDeleted: false,
            initialBalance: 1500,
            initialBalanceDate: dateAt(2026, 1, 5),
        });

        await createAccount(WORKSPACE_ID, INVEST_ID, {
            name: "Tesouro Direto",
            icon: "savings",
            color: "#7E57C2",
            runtimeType: AccountType.investment,
            isDeleted: false,
            initialBalance: 0,
            initialBalanceDate: dateAt(2026, 1, 5),
        });

        // 1. Saldo inicial: o gatilho onAccountCreated cria a order sintética,
        //    e onOrderWritten gera a parcela liquidada.
        await financeService.syncInitialBalance(WORKSPACE_ID, CHECKING_ID, {
            id: CHECKING_ID,
            initialBalance: 1500,
            initialBalanceDate: dateAt(2026, 1, 5),
            runtimeType: AccountType.checking,
        } as AccountModel);

        const initialOrder = await financeRepository.getOrderById(WORKSPACE_ID, `initial-balance-${CHECKING_ID}`);
        await financeService.syncInstallments(WORKSPACE_ID, `initial-balance-${CHECKING_ID}`, null, initialOrder!);
        for (const installment of await readInstallmentsOfOrder(WORKSPACE_ID, `initial-balance-${CHECKING_ID}`)) {
            await runInstallmentTriggers(WORKSPACE_ID, null, installment);
        }

        // 2. Despesa avulsa, paga depois com valor diferente do previsto.
        const mercado = await createOrderWithInstallments(WORKSPACE_ID, "order-mercado", {
            amount: 320.55,
            dueDay: 12,
            description: "Mercado",
            startMonth: "2026-03",
            installmentType: InstallmentType.single,
            status: OrderStatus.active,
            type: OrderType.expense,
            accounts: { [CHECKING_ID]: "debt" },
            accountIds: [CHECKING_ID],
            category: MERCADO,
        });

        await updateInstallmentWithTriggers(WORKSPACE_ID, mercado[0].id, {
            status: InstallmentStatus.paid,
            paidAmount: 298.4,
            paidDate: dateAt(2026, 3, 14),
        });

        // 3. Compra parcelada em 3x; a primeira é paga.
        const notebook = await createOrderWithInstallments(WORKSPACE_ID, "order-notebook", {
            amount: 502.4,
            dueDay: 10,
            description: "Notebook",
            startMonth: "2026-03",
            installmentCount: 3,
            installmentType: InstallmentType.installment,
            status: OrderStatus.active,
            type: OrderType.expense,
            accounts: { [CHECKING_ID]: "debt" },
            accountIds: [CHECKING_ID],
            category: MERCADO,
        });

        await updateInstallmentWithTriggers(WORKSPACE_ID, notebook[0].id, {
            status: InstallmentStatus.paid,
            paidAmount: notebook[0].amount,
            paidDate: dateAt(2026, 3, 10),
        });

        // 4. Receita recorrente (12 parcelas); as duas primeiras são recebidas.
        const salario = await createOrderWithInstallments(WORKSPACE_ID, "order-salario", {
            amount: 6200,
            dueDay: 5,
            description: "Salário",
            startMonth: "2026-03",
            installmentType: InstallmentType.recurring,
            status: OrderStatus.active,
            type: OrderType.income,
            accounts: { [CHECKING_ID]: "credit" },
            accountIds: [CHECKING_ID],
            category: SALARIO,
        });

        await updateInstallmentWithTriggers(WORKSPACE_ID, salario[0].id, {
            status: InstallmentStatus.paid,
            paidAmount: 6200,
            paidDate: dateAt(2026, 3, 5),
        });
        await updateInstallmentWithTriggers(WORKSPACE_ID, salario[1].id, {
            status: InstallmentStatus.paid,
            paidAmount: 6350.75,
            paidDate: dateAt(2026, 4, 6),
        });

        // 5. Transferência para investimento (categoria virtual no sumário).
        const aporte = await createOrderWithInstallments(WORKSPACE_ID, "order-aporte", {
            amount: 800,
            dueDay: 6,
            description: "Aporte",
            startMonth: "2026-03",
            installmentType: InstallmentType.single,
            status: OrderStatus.active,
            type: OrderType.transfer,
            accounts: { [CHECKING_ID]: "debt", [INVEST_ID]: "credit" },
            accountIds: [CHECKING_ID, INVEST_ID],
            category: undefined as any,
        });

        await updateInstallmentWithTriggers(WORKSPACE_ID, aporte[0].id, {
            status: InstallmentStatus.paid,
            paidAmount: 800,
            paidDate: dateAt(2026, 3, 6),
        });

        // 6. Parcela removida (exclusão lógica): não pode entrar em nada.
        const cancelada = await createOrderWithInstallments(WORKSPACE_ID, "order-cancelada", {
            amount: 99.9,
            dueDay: 20,
            description: "Assinatura cancelada",
            startMonth: "2026-03",
            installmentType: InstallmentType.single,
            status: OrderStatus.active,
            type: OrderType.expense,
            accounts: { [CHECKING_ID]: "debt" },
            accountIds: [CHECKING_ID],
            category: MERCADO,
        });

        await updateInstallmentWithTriggers(WORKSPACE_ID, cancelada[0].id, {
            status: InstallmentStatus.removed,
        });

        // 7. Planejamentos de categoria (gatilho onCategoryPlanningWritten).
        const monthKey = (offset: number) => {
            const date = new Date(NOW.getFullYear(), NOW.getMonth() + offset, 1);
            return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
        };

        for (const planning of [
            { id: "plan-mercado", category: MERCADO, amount: 900, startMonth: monthKey(0), endMonth: monthKey(3) },
            { id: "plan-moradia", category: MORADIA, amount: 2100, startMonth: monthKey(-2), endMonth: monthKey(6) },
        ]) {
            await firestore.doc(`workspaces/${WORKSPACE_ID}/category_planning/${planning.id}`).set({
                category: planning.category,
                amount: planning.amount,
                startMonth: planning.startMonth,
                endMonth: planning.endMonth,
                lastSummaryMonth: null,
            });
            await summaryService.processCategoryPlanningChange(WORKSPACE_ID, null, planning as any);
        }
    }, 120000);

    afterAll(async () => {
        await firestore.recursiveDelete(firestore.doc(`workspaces/${WORKSPACE_ID}`));
    });

    it("o estado escrito pelos gatilhos é o esperado (sanidade do cenário)", async () => {
        // Saldo do dia 10/03: 1500 (inicial) + 6200 (salário 05) - 800 (aporte 06)
        //                     - 167.47 (1ª do notebook, 10).
        const balance = await firestore
            .doc(`workspaces/${WORKSPACE_ID}/accounts/${CHECKING_ID}/balance/2026-03-10`)
            .get();
        expect(balance.data()!.balance).toBeCloseTo(6732.53, 2);

        const march = await firestore.doc(`workspaces/${WORKSPACE_ID}/period_summaries/2026-03`).get();
        const categories = march.data()!.categories;
        // Mercado: 320.55 (avulsa) + 167.47 (1ª parcela vira 0 ao ser paga? não:
        // o planejado da parcela paga continua sendo `amount`) + 99.90 removida NÃO entra.
        expect(categories[MERCADO.id].actualAmount).toBeCloseTo(298.4 + 167.47, 2);
        expect(categories.virtual_investment_expense.actualAmount).toBeCloseTo(800, 2);
        expect(categories[SALARIO.id].actualAmount).toBeCloseTo(6200, 2);
    });

    it("rebuildWorkspace em dry-run não encontra nenhuma diferença", async () => {
        const report = await rebuildService.rebuildWorkspace(WORKSPACE_ID, { now: NOW });

        expect(report.mode).toBe("dryRun");
        expect(report.writesCommitted).toBe(0);
        expect(report.diff).toEqual({
            balances: expect.objectContaining({ toCreate: 0, toUpdate: 0, toDelete: 0 }),
            periodSummaries: expect.objectContaining({ toCreate: 0, toUpdate: 0, toDelete: 0 }),
            weeklyXp: expect.objectContaining({ toCreate: 0, toUpdate: 0, toDelete: 0 }),
        });
        expect(report.totalChanges).toBe(0);
        expect(report.scanned.installmentsRemoved).toBe(1);
        expect(report.scanned.categoryPlannings).toBe(2);

        // A parcela removida (`order-cancelada`, vencimento 20/03) deixou para
        // trás o documento semanal 2026-W11 com a categoria zerada: o gatilho
        // subtraiu o projetado ao marcar `removed`, mas não apaga o documento.
        // O rebuild não gera esse documento e o classifica como RESIDUAL —
        // equivale à ausência dele, então não é divergência.
        expect(report.diff.periodSummaries.residual).toBe(1);
        expect(report.diff.periodSummaries.samples).toContain("residual period_summaries/2026-W11");

        // O planejado gravado pelos gatilhos é PRESERVADO (não é reconstruível).
        expect(report.rebuildPlanning).toBe(false);
        expect(report.diff.periodSummaries.generalPlannedChanges).toBe(0);
    }, 60000);

    it("apply restaura saldo e sumário corrompidos à mão e converge na execução seguinte", async () => {
        const balanceRef = firestore.doc(`workspaces/${WORKSPACE_ID}/accounts/${CHECKING_ID}/balance/2026-03-10`);
        const summaryRef = firestore.doc(`workspaces/${WORKSPACE_ID}/period_summaries/2026-03`);

        const goodBalance = (await balanceRef.get()).data()!.balance;
        const goodSummary = (await summaryRef.get()).data()!.categories[MERCADO.id];

        // F1.10 — a corrupção mexe nos DOIS lados do par. O inteiro é a fonte
        // da verdade: um `double` estragado sozinho seria ignorado pelo cálculo
        // (que leria o inteiro certo ao lado) e o teste não estaria
        // corrompendo coisa nenhuma.
        await balanceRef.set({
            balance: 42,
            balanceCents: 4200,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await summaryRef.set({
            categories: {
                [MERCADO.id]: {
                    actualAmount: 1, actualAmountCents: 100,
                    specificPlannedAmount: 2, specificPlannedAmountCents: 200,
                    generalPlannedAmount: 3, generalPlannedAmountCents: 300,
                },
            },
        }, { merge: true });

        const preview = await rebuildService.rebuildWorkspace(WORKSPACE_ID, { now: NOW });
        expect(preview.diff.balances.toUpdate).toBe(1);
        expect(preview.diff.periodSummaries.toUpdate).toBe(1);
        expect(preview.writesCommitted).toBe(0);

        const applied = await rebuildService.rebuildWorkspace(WORKSPACE_ID, { dryRun: false, now: NOW });
        expect(applied.mode).toBe("apply");
        expect(applied.writesCommitted).toBe(applied.totalChanges);

        const rebuiltBalance = (await balanceRef.get()).data()!;
        expect(rebuiltBalance.balance).toBeCloseTo(goodBalance, 2);
        // O par volta coerente: o inteiro é a verdade, o `double` é o espelho.
        expect(rebuiltBalance.balanceCents).toBe(toCents(goodBalance));
        expect(rebuiltBalance.balance).toBe(fromCents(rebuiltBalance.balanceCents));

        const restored = (await summaryRef.get()).data()!.categories[MERCADO.id];
        expect(restored.actualAmount).toBeCloseTo(goodSummary.actualAmount, 2);
        expect(restored.actualAmountCents).toBe(toCents(goodSummary.actualAmount));
        expect(restored.specificPlannedAmount).toBeCloseTo(goodSummary.specificPlannedAmount, 2);
        expect(restored.specificPlannedAmountCents).toBe(toCents(goodSummary.specificPlannedAmount));

        // CONTRATO: o `generalPlannedAmount` NÃO é reconstruível, então o
        // rebuild o preserva como está — inclusive quando está errado. Corrigir
        // esse campo exige o `--rebuild-planning` (destrutivo) ou reescrever o
        // planejamento pelo app, que dispara o gatilho.
        expect(restored.generalPlannedAmount).toBeCloseTo(3, 2);
        expect(restored.generalPlannedAmountCents).toBe(300);
        expect(goodSummary.generalPlannedAmount).toBeCloseTo(0, 2);

        const second = await rebuildService.rebuildWorkspace(WORKSPACE_ID, { now: NOW });
        expect(second.totalChanges).toBe(0);
    }, 120000);

    it("o callable só aceita o dono do workspace (members[0])", async () => {
        await expect(assertWorkspaceOwner(WORKSPACE_ID, OWNER_UID)).resolves.toBeUndefined();
        await expect(assertWorkspaceOwner(WORKSPACE_ID, MEMBER_UID)).rejects.toMatchObject({ code: "permission-denied" });
        await expect(assertWorkspaceOwner("ws-inexistente", OWNER_UID)).rejects.toMatchObject({ code: "not-found" });
    });
});

describe("rebuildWorkspace — generalPlannedAmount com histórico", () => {
    const WORKSPACE_ID = `ws-plan-${Date.now()}`;
    const NOW = new Date();

    const monthKey = (offset: number) => {
        const date = new Date(NOW.getFullYear(), NOW.getMonth() + offset, 1);
        return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
    };

    beforeAll(async () => {
        await firestore.doc(`workspaces/${WORKSPACE_ID}`).set({
            name: "Planejamento antigo",
            type: "personal",
            members: [OWNER_UID],
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await createAccount(WORKSPACE_ID, CHECKING_ID, {
            name: "Conta Corrente",
            icon: "account_balance",
            color: "#4CAF50",
            runtimeType: AccountType.checking,
            isDeleted: false,
            initialBalance: 0,
            initialBalanceDate: dateAt(2026, 1, 5),
        });

        const planning = {
            id: "plan-antigo",
            category: MERCADO,
            amount: 1000,
            startMonth: monthKey(-6),
            endMonth: monthKey(6),
        };

        await firestore.doc(`workspaces/${WORKSPACE_ID}/category_planning/${planning.id}`).set({
            category: planning.category,
            amount: planning.amount,
            startMonth: planning.startMonth,
            endMonth: planning.endMonth,
            lastSummaryMonth: monthKey(-1),
        });

        // O planejamento é antigo e vem do regime ANTERIOR a F1.5: o gatilho
        // reaplicava a janela de 12 meses a cada escrita, sem estornar, e o
        // cron fazia o mesmo. O resultado é um `generalPlannedAmount`
        // acumulado várias vezes — exatamente o que o rebuild PRESERVA por
        // padrão. Reproduzimos isso aplicando quatro janelas sobrepostas.
        for (const offset of [-3, -2, -1, 0]) {
            const window = { from: monthKey(offset), until: monthKey(offset + 11) };

            for (const impact of summaryService.calculatePlanningImpacts(planning as any, 1, window)) {
                await financeRepository.updatePeriodSummary(
                    WORKSPACE_ID, impact.year, impact.month, impact.category,
                    { generalPlannedDelta: impact.generalPlannedDelta }, impact.week
                );
            }
        }

        // Uma despesa paga no mês passado, para o documento ter também valores
        // reconstruíveis convivendo com o planejado.
        const passado = new Date(NOW.getFullYear(), NOW.getMonth() - 1, 15, 12);
        const mercado = await createOrderWithInstallments(WORKSPACE_ID, "order-mercado-passado", {
            amount: 210.9,
            dueDay: 15,
            description: "Mercado",
            startMonth: monthKey(-1),
            installmentType: InstallmentType.single,
            status: OrderStatus.active,
            type: OrderType.expense,
            accounts: { [CHECKING_ID]: "debt" },
            accountIds: [CHECKING_ID],
            category: MERCADO,
        });

        await updateInstallmentWithTriggers(WORKSPACE_ID, mercado[0].id, {
            status: InstallmentStatus.paid,
            paidAmount: 210.9,
            paidDate: passado,
        });
    }, 120000);

    afterAll(async () => {
        await firestore.recursiveDelete(firestore.doc(`workspaces/${WORKSPACE_ID}`));
    });

    it("dry-run padrão não muda a QUANTIA do generalPlannedAmount acumulado", async () => {
        const before = await snapshotWorkspace(WORKSPACE_ID);

        const report = await rebuildService.rebuildWorkspace(WORKSPACE_ID, { now: NOW });

        expect(report.rebuildPlanning).toBe(false);
        // Nenhuma QUANTIA de planejado muda: é o contrato de preservação.
        expect(report.diff.periodSummaries.generalPlannedChanges).toBe(0);

        // F1.10 — o que o rebuild passou a enxergar aqui é o ESPELHO SUJO. Este
        // cenário aplica quatro janelas sobrepostas com `FieldValue.increment`,
        // e três incrementos de 225,81 em `double` produzem 677.4300000000001
        // onde o inteiro diz 67743 centavos. O inteiro está certo; quem
        // escorregou foi o campo que o app lê. O rebuild reescreve o espelho a
        // partir do inteiro — sem mexer na quantia.
        const w31 = (await firestore.doc(`workspaces/${WORKSPACE_ID}/period_summaries/2026-W31`).get())
            .data()!.categories[MERCADO.id];
        expect(w31.generalPlannedAmountCents).toBe(67743);
        expect(w31.generalPlannedAmount).not.toBe(677.43);

        expect(report.totalChanges).toBe(report.diff.periodSummaries.toUpdate);
        expect(report.diff.periodSummaries.toUpdate).toBeGreaterThan(0);

        await rebuildService.rebuildWorkspace(WORKSPACE_ID, { dryRun: false, now: NOW });
        const after = await snapshotWorkspace(WORKSPACE_ID);

        // A quantia é a mesma de antes, ao centavo...
        for (const [summaryId, categories] of Object.entries(before.summaries)) {
            for (const [categoryId, totals] of Object.entries(categories)) {
                expect({ summaryId, categoryId, general: after.summaries[summaryId]?.[categoryId]?.general })
                    .toEqual({ summaryId, categoryId, general: expect.closeTo(totals.general, 2) });
            }
        }

        // ...e o espelho deixou de ser uma dízima.
        const fixed = (await firestore.doc(`workspaces/${WORKSPACE_ID}/period_summaries/2026-W31`).get())
            .data()!.categories[MERCADO.id];
        expect(fixed.generalPlannedAmountCents).toBe(67743);
        expect(fixed.generalPlannedAmount).toBe(677.43);

        // Convergiu: a segunda passada não tem mais nada a fazer.
        const second = await rebuildService.rebuildWorkspace(WORKSPACE_ID, { now: NOW });
        expect(second.totalChanges).toBe(0);
    }, 120000);

    it("rodar de novo um mês depois continua sem mexer no planejado", async () => {
        const umMesDepois = new Date(NOW.getFullYear(), NOW.getMonth() + 1, NOW.getDate(), 12);

        const report = await rebuildService.rebuildWorkspace(WORKSPACE_ID, { now: umMesDepois });

        expect(report.diff.periodSummaries.generalPlannedChanges).toBe(0);
        // O teste anterior já aplicou; agora não sobra nem o espelho sujo.
        expect(report.totalChanges).toBe(0);
    }, 60000);

    it("com rebuildPlanning as mudanças aparecem e são contadas à parte", async () => {
        const report = await rebuildService.rebuildWorkspace(WORKSPACE_ID, { now: NOW, rebuildPlanning: true });

        expect(report.rebuildPlanning).toBe(true);
        expect(report.totalChanges).toBeGreaterThan(0);
        expect(report.diff.periodSummaries.generalPlannedChanges).toBeGreaterThan(0);
        // Nada foi escrito: é dry-run.
        expect(report.writesCommitted).toBe(0);
    }, 60000);
});

/** PRNG determinístico (mulberry32) — a seed fixa mantém o teste reproduzível. */
function mulberry32(seed: number): () => number {
    let state = seed;
    return () => {
        state |= 0;
        state = (state + 0x6D2B79F5) | 0;
        let t = Math.imul(state ^ (state >>> 15), 1 | state);
        t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}

describe("rebuildWorkspace — propriedade: incremental == rebuild", () => {
    const SEQUENCES = 20;

    it("20 sequências aleatórias com seed fixa chegam ao mesmo estado", async () => {
        // Cobertura das operações sorteadas: garante que o teste não degenerou
        // em "só criar" se o gerador mudar.
        const executed: Record<string, number> = { criar: 0, pagar: 0, estornar: 0, remover: 0 };

        for (let sequence = 0; sequence < SEQUENCES; sequence++) {
            const workspaceId = `ws-prop-${Date.now()}-${sequence}`;
            const random = mulberry32(2026 + sequence);
            const pick = <T>(values: T[]): T => values[Math.floor(random() * values.length)];
            const cents = (min: number, max: number) => Math.round((min + random() * (max - min)) * 100) / 100;

            await firestore.doc(`workspaces/${workspaceId}`).set({
                name: `Propriedade ${sequence}`,
                type: "personal",
                members: [OWNER_UID],
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            await createAccount(workspaceId, CHECKING_ID, {
                name: "Conta Corrente",
                icon: "account_balance",
                color: "#4CAF50",
                runtimeType: AccountType.checking,
                isDeleted: false,
                initialBalance: 0,
                initialBalanceDate: dateAt(2026, 1, 5),
            });

            // Destinos de transferência: exercitam as categorias virtuais.
            await createAccount(workspaceId, INVEST_ID, {
                name: "Tesouro Direto",
                icon: "savings",
                color: "#7E57C2",
                runtimeType: AccountType.investment,
                isDeleted: false,
                initialBalance: 0,
                initialBalanceDate: dateAt(2026, 1, 5),
            });
            await createAccount(workspaceId, DEBT_ID, {
                name: "Empréstimo",
                icon: "handshake",
                color: "#E57373",
                runtimeType: AccountType.debt,
                isDeleted: false,
                initialBalance: 0,
                initialBalanceDate: dateAt(2026, 1, 5),
            });

            // Planejamentos: o rebuild padrão tem que PRESERVAR o que os
            // gatilhos gravaram em `generalPlannedAmount`.
            if (random() < 0.7) {
                const planning = {
                    id: `plan-${sequence}`,
                    category: pick([MERCADO, MORADIA]),
                    amount: cents(200, 3000),
                    startMonth: "2026-01",
                    endMonth: "2026-12",
                };
                await firestore.doc(`workspaces/${workspaceId}/category_planning/${planning.id}`).set({
                    category: planning.category,
                    amount: planning.amount,
                    startMonth: planning.startMonth,
                    endMonth: planning.endMonth,
                    lastSummaryMonth: null,
                });
                await summaryService.processCategoryPlanningChange(workspaceId, null, planning as any);
            }

            const installmentIds: string[] = [];
            const operations = 6 + Math.floor(random() * 5);

            for (let step = 0; step < operations; step++) {
                const current = await Promise.all(installmentIds.map((id) => readInstallment(workspaceId, id)));
                const pending = current.filter((i) => i.status === InstallmentStatus.pending);
                const paid = current.filter((i) => i.status === InstallmentStatus.paid);
                const alive = current.filter((i) => i.status !== InstallmentStatus.removed);

                const choices = ["criar"];
                if (pending.length > 0) choices.push("pagar", "pagar");
                if (paid.length > 0) choices.push("estornar");
                if (alive.length > 0) choices.push("remover");

                const operation = pick(choices);
                executed[operation]++;

                if (operation === "criar") {
                    const orderId = `order-${sequence}-${step}`;
                    const draw = random();
                    // 25% transferência (categoria virtual), 25% receita, resto despesa.
                    const kind = draw < 0.25 ? "transfer" : draw < 0.5 ? "income" : "expense";
                    const count = random() < 0.4 ? 2 : 1;

                    let accounts: Record<string, "debt" | "credit">;
                    let type: OrderType;
                    let category: CategoryModel | undefined;

                    if (kind === "transfer") {
                        type = OrderType.transfer;
                        category = undefined;
                        const other = pick([INVEST_ID, DEBT_ID]);
                        // Metade das vezes a conta especial é a ORIGEM
                        // (categoria virtual de receita), metade o DESTINO.
                        accounts = random() < 0.5
                            ? { [CHECKING_ID]: "debt", [other]: "credit" }
                            : { [other]: "debt", [CHECKING_ID]: "credit" };
                    }
                    else {
                        type = kind === "income" ? OrderType.income : OrderType.expense;
                        category = kind === "income" ? SALARIO : pick([MERCADO, MORADIA]);
                        accounts = { [CHECKING_ID]: kind === "income" ? "credit" : "debt" };
                    }

                    const created = await createOrderWithInstallments(workspaceId, orderId, {
                        amount: cents(50, 900),
                        dueDay: 1 + Math.floor(random() * 27),
                        description: `Lançamento ${step}`,
                        startMonth: pick(["2026-03", "2026-04", "2026-05"]),
                        installmentCount: count,
                        installmentType: count > 1 ? InstallmentType.installment : InstallmentType.single,
                        status: OrderStatus.active,
                        type,
                        accounts,
                        accountIds: Object.keys(accounts),
                        category: category as CategoryModel,
                    }, false);

                    installmentIds.push(...created.map((i) => i.id));
                }
                else if (operation === "pagar") {
                    const target = pick(pending);
                    const paidDate = new Date(target.dueDate);
                    paidDate.setDate(paidDate.getDate() + Math.floor(random() * 6) - 2);

                    // 15% dos pagamentos com paidAmount = 0: o saldo e o
                    // realizado ignoram, mas o XP ainda é creditado.
                    const paidAmount = random() < 0.15
                        ? 0
                        : Math.round(target.amount * (0.8 + random() * 0.4) * 100) / 100;

                    await updateInstallmentWithTriggers(workspaceId, target.id, {
                        status: random() < 0.2 ? InstallmentStatus.settled : InstallmentStatus.paid,
                        paidAmount,
                        paidDate,
                    });
                }
                else if (operation === "estornar") {
                    const target = pick(paid);
                    await updateInstallmentWithTriggers(workspaceId, target.id, {
                        status: InstallmentStatus.pending,
                        paidAmount: null,
                        paidDate: null,
                    });
                }
                else {
                    const target = pick(alive);
                    await updateInstallmentWithTriggers(workspaceId, target.id, {
                        status: InstallmentStatus.removed,
                    });
                }
            }

            const incremental = await snapshotWorkspace(workspaceId);

            const applied = await rebuildService.rebuildWorkspace(workspaceId, { dryRun: false });
            expect(applied.writesCommitted).toBe(applied.totalChanges);

            const rebuilt = await snapshotWorkspace(workspaceId);
            expectSameSemantics(incremental, rebuilt, `sequência ${sequence}`);

            // Reconstruir de novo não muda mais nada.
            const second = await rebuildService.rebuildWorkspace(workspaceId);
            expect({ sequence, changes: second.totalChanges }).toEqual({ sequence, changes: 0 });

            await firestore.recursiveDelete(firestore.doc(`workspaces/${workspaceId}`));
        }

        expect(executed.criar).toBeGreaterThan(0);
        expect(executed.pagar).toBeGreaterThan(0);
        expect(executed.estornar).toBeGreaterThan(0);
        expect(executed.remover).toBeGreaterThan(0);
    }, 600000);
});
