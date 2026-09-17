import { recomputeGoals } from "../scripts/recompute_goals";
import { AccountType } from "../features/finance/domain/models/finance.models";

function firestoreWithWorkspaces(ids: string[]) {
    return {
        collection: jest.fn().mockReturnValue({
            select: jest.fn().mockReturnValue({
                get: jest.fn().mockResolvedValue({ docs: ids.map((id) => ({ id })) }),
            }),
        }),
    } as any;
}

function makeRepository(goalsByWorkspace: Record<string, any[]>) {
    return {
        getGoals: jest.fn(async (workspaceId: string) => goalsByWorkspace[workspaceId] ?? []),
        getActiveGoalsByAccount: jest.fn().mockResolvedValue([]),
        getActiveGoalsByCategory: jest.fn().mockResolvedValue([]),
        getGoal: jest.fn(),
        updateGoal: jest.fn(),
        updateGoalProgress: jest.fn().mockResolvedValue(undefined),
        updateGoalOutcome: jest.fn().mockResolvedValue(undefined),
        getCategoryActualByMonths: jest.fn().mockResolvedValue(0),
        getBalancesForGoal: jest.fn().mockResolvedValue({ startBalance: null, currentBalance: null }),
        getCurrentBalance: jest.fn().mockResolvedValue(null),
        // Conta corrente por padrão: `saveMoney` segue no caminho dos aportes.
        getAccountType: jest.fn().mockResolvedValue(AccountType.checking),
        getPaidInstallmentsByAccountSince: jest.fn().mockResolvedValue([]),
    };
}

const silent = () => undefined;

function saveMoneyGoal(over: Partial<any> = {}) {
    return {
        id: "g1",
        name: "Reserva",
        runtimeType: "saveMoney",
        targetAmount: 1000,
        currentAmount: 0,
        accountId: "acc1",
        startDate: new Date("2026-01-01T00:00:00.000"),
        deadline: new Date("2026-12-31T00:00:00.000"),
        isDeleted: false,
        ...over,
    };
}

describe("recompute_goals (script)", () => {
    it("dry-run não escreve nada, mas relata o que mudaria", async () => {
        const repository = makeRepository({ w1: [saveMoneyGoal()] });
        repository.getPaidInstallmentsByAccountSince.mockResolvedValue([
            { amount: 400, paidAmount: 400, accounts: { acc1: "credit" } },
        ]);

        const summary = await recomputeGoals(
            firestoreWithWorkspaces(["w1"]),
            repository as any,
            { dryRun: true },
            silent
        );

        expect(repository.updateGoalProgress).not.toHaveBeenCalled();
        expect(summary).toMatchObject({ scanned: 1, goals: 1, updated: 1, skipped: 0, failed: 0 });
    });

    it("com --apply grava o valor recalculado", async () => {
        const repository = makeRepository({ w1: [saveMoneyGoal()] });
        repository.getPaidInstallmentsByAccountSince.mockResolvedValue([
            { amount: 400, paidAmount: 400, accounts: { acc1: "credit" } },
            { amount: 100, paidAmount: 100, accounts: { acc1: "debt" } },
        ]);

        const summary = await recomputeGoals(
            firestoreWithWorkspaces(["w1"]),
            repository as any,
            { dryRun: false },
            silent
        );

        expect(repository.updateGoalProgress).toHaveBeenCalledWith("w1", "g1", 300, null);
        expect(summary.updated).toBe(1);
        expect(summary.active).toBe(1);
    });

    it("é idempotente: meta já correta é pulada", async () => {
        const repository = makeRepository({ w1: [saveMoneyGoal({ currentAmount: 400 })] });
        repository.getPaidInstallmentsByAccountSince.mockResolvedValue([
            { amount: 400, paidAmount: 400, accounts: { acc1: "credit" } },
        ]);

        const summary = await recomputeGoals(
            firestoreWithWorkspaces(["w1"]),
            repository as any,
            { dryRun: false },
            silent
        );

        expect(repository.updateGoalProgress).not.toHaveBeenCalled();
        expect(summary).toMatchObject({ updated: 0, skipped: 1, active: 1 });
    });

    it("carimba outcome=success quando o recálculo alcança o alvo", async () => {
        const repository = makeRepository({ w1: [saveMoneyGoal()] });
        repository.getPaidInstallmentsByAccountSince.mockResolvedValue([
            { amount: 1000, paidAmount: 1000, accounts: { acc1: "credit" } },
        ]);

        const summary = await recomputeGoals(
            firestoreWithWorkspaces(["w1"]),
            repository as any,
            { dryRun: false },
            silent
        );

        const [, , amount, stamp] = repository.updateGoalProgress.mock.calls[0];
        expect(amount).toBe(1000);
        expect(stamp).toMatchObject({ outcome: "success" });
        expect(stamp.at).toBeInstanceOf(Date);
        expect(summary).toMatchObject({ completed: 1, lost: 0, active: 0 });
    });

    it("não reescreve o desfecho de uma meta que já desfechou", async () => {
        const repository = makeRepository({
            w1: [saveMoneyGoal({
                currentAmount: 0,
                outcome: "success",
                completedAt: new Date("2026-02-01T00:00:00.000"),
            })],
        });
        repository.getPaidInstallmentsByAccountSince.mockResolvedValue([
            { amount: 1000, paidAmount: 1000, accounts: { acc1: "credit" } },
        ]);

        const summary = await recomputeGoals(
            firestoreWithWorkspaces(["w1"]),
            repository as any,
            { dryRun: false },
            silent
        );

        expect(repository.updateGoalProgress.mock.calls[0][3]).toBeNull();
        expect(summary.completed).toBe(0);
    });

    it("limita a execução a um workspace quando --workspace é informado", async () => {
        const firestore = firestoreWithWorkspaces(["w1", "w2"]);
        const repository = makeRepository({ w2: [saveMoneyGoal()] });

        const summary = await recomputeGoals(
            firestore,
            repository as any,
            { dryRun: true, workspaceId: "w2" },
            silent
        );

        expect(firestore.collection).not.toHaveBeenCalled();
        expect(repository.getGoals).toHaveBeenCalledWith("w2");
        expect(summary.scanned).toBe(1);
    });

    it("uma meta quebrada não derruba as outras", async () => {
        const repository = makeRepository({
            w1: [saveMoneyGoal({ id: "ruim" }), saveMoneyGoal({ id: "boa", accountId: "acc2" })],
        });
        repository.getPaidInstallmentsByAccountSince.mockImplementation(async (_w: string, accountId: string) => {
            if (accountId === "acc1") throw new Error("boom");
            return [{ amount: 250, paidAmount: 250, accounts: { acc2: "credit" } }];
        });

        const summary = await recomputeGoals(
            firestoreWithWorkspaces(["w1"]),
            repository as any,
            { dryRun: false },
            silent
        );

        expect(summary).toMatchObject({ goals: 2, failed: 1, updated: 1 });
        expect(repository.updateGoalProgress).toHaveBeenCalledWith("w1", "boa", 250, null);
    });

    it("meta de tipo desconhecido é mantida, não zerada", async () => {
        const repository = makeRepository({ w1: [saveMoneyGoal({ runtimeType: "outroTipo" })] });

        const summary = await recomputeGoals(
            firestoreWithWorkspaces(["w1"]),
            repository as any,
            { dryRun: false },
            silent
        );

        expect(repository.updateGoalProgress).not.toHaveBeenCalled();
        expect(summary.skipped).toBe(1);
    });
});
