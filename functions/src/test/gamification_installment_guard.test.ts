// ofx-js é ESM puro e não é transformado pelo ts-jest; o container o alcança
// via ai.service (aqui o container é mockado, mas o import ainda é resolvido).
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

const runIdempotency = jest.fn();
const checkFirstTransaction = jest.fn();
const checkSimpleTransactionBadges = jest.fn();
const updateWeeklyMissionsProgress = jest.fn();

jest.mock("../core/container", () => ({
    container: {
        get idempotencyService() {
            return { runIdempotency };
        },
        get gamificationService() {
            return {
                checkFirstTransaction,
                checkSimpleTransactionBadges,
                updateWeeklyMissionsProgress,
            };
        },
    },
}));

import { onInstallmentWrittenGamification } from "../features/goal/presentation/functions/gamification_handler";

const snapshot = (data: any) => ({ exists: data !== null, data: () => data });

/** Evento de `onDocumentWritten` no formato que o handler consome. */
function installmentEvent(before: any, after: any) {
    return {
        id: `evt-${Date.now()}`,
        params: { workspaceId: "w1", installmentId: "i1" },
        data: { before: snapshot(before), after: snapshot(after) },
    } as any;
}

const PENDING = {
    orderId: "o1",
    amount: 100,
    dueDate: { toDate: () => new Date(2025, 2, 10, 12) },
    paidDate: null,
    description: "Curso",
    status: "pending",
    type: "expense",
};

/**
 * O gatilho de gamificação escuta a MESMA coleção `installments` que o de
 * finanças. Sem a guarda por conteúdo, a escrita de xp que o próprio servidor
 * faz ao processar um pagamento reabria todo o bloco: badges de transação e
 * progresso de missão semanal reavaliados de graça, a cada pagamento.
 */
describe("onInstallmentWrittenGamification — guarda por conteúdo", () => {
    beforeEach(() => {
        // jest.config.js usa resetMocks: true.
        runIdempotency.mockImplementation(async (_eventId: string, _action: string, action: any) => action());
        checkFirstTransaction.mockResolvedValue(undefined);
        checkSimpleTransactionBadges.mockResolvedValue(undefined);
        updateWeeklyMissionsProgress.mockResolvedValue(undefined);
    });

    it("sai cedo quando a escrita só mexeu em xp e na cascata", async () => {
        const before = { ...PENDING, status: "paid", paidAmount: 100, replicationCascade: "all" };
        const after = { ...before, xp: 15, replicationCascade: "none" };

        await (onInstallmentWrittenGamification as any).run(installmentEvent(before, after));

        expect(runIdempotency).not.toHaveBeenCalled();
        expect(checkFirstTransaction).not.toHaveBeenCalled();
        expect(updateWeeklyMissionsProgress).not.toHaveBeenCalled();
    });

    it("processa normalmente o pagamento feito pelo usuário", async () => {
        const after = { ...PENDING, status: "paid", paidAmount: 100 };

        await (onInstallmentWrittenGamification as any).run(installmentEvent(PENDING, after));

        expect(runIdempotency).toHaveBeenCalledTimes(1);
        expect(runIdempotency.mock.calls[0][1]).toBe("gamification:installmentWritten");
        expect(checkFirstTransaction).toHaveBeenCalledWith("w1");
        expect(updateWeeklyMissionsProgress).toHaveBeenCalledWith("w1", "transaction", after);
    });

    it("processa a criação de uma parcela (sem before)", async () => {
        await (onInstallmentWrittenGamification as any).run(installmentEvent(null, PENDING));

        expect(runIdempotency).toHaveBeenCalledTimes(1);
        expect(updateWeeklyMissionsProgress).toHaveBeenCalled();
    });

    it("continua ignorando parcela removida", async () => {
        const after = { ...PENDING, status: "removed" };

        await (onInstallmentWrittenGamification as any).run(installmentEvent(PENDING, after));

        expect(runIdempotency).not.toHaveBeenCalled();
    });
});
