// ofx-js é ESM puro e não é transformado pelo ts-jest; o container o alcança via ai.service
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import {
    isDerivedOnlyInstallmentWrite,
    onCategoryPlanningWrittenGamification,
    onInstallmentWrittenGamification,
} from "../features/goal/presentation/functions/gamification_handler";
import { INSTALLMENT_DERIVED_FIELDS } from "../features/finance/domain/models/finance.models";

/** Timestamp do Firestore, reduzido ao que a comparação usa. */
function timestamp(date: Date) {
    return { toDate: () => new Date(date.getTime()) };
}

const PENDING_INSTALLMENT = {
    orderId: "o1",
    amount: 100,
    dueDate: timestamp(new Date(2025, 2, 10, 12)),
    paidDate: null,
    description: "Curso",
    status: "pending",
    type: "expense",
    category: { id: "c1", name: "Educação" },
};

function triggerDocument(cloudFunction: any): string {
    return cloudFunction.__endpoint.eventTrigger.eventFilterPathPatterns.document;
}

/**
 * Cobre o bug F2.1 #1: o trigger escutava `category_plannings` (plural), uma
 * coleção que não existe. Com isso os badges planner, golden_rule,
 * first_planning e planning_month nunca disparavam.
 */
describe("gamification_handler — caminhos dos triggers", () => {
    it("escuta a coleção real de planejamentos: category_planning (singular)", () => {
        expect(triggerDocument(onCategoryPlanningWrittenGamification))
            .toBe("workspaces/{workspaceId}/category_planning/{planningId}");
    });

    it("escuta a coleção de parcelas", () => {
        expect(triggerDocument(onInstallmentWrittenGamification))
            .toBe("workspaces/{workspaceId}/installments/{installmentId}");
    });
});

/**
 * O gatilho de gamificação observa a MESMA coleção `installments` que o de
 * finanças. Sem a guarda por conteúdo, cada escrita de xp feita pelo servidor
 * reavaliava badges e missões semanais de graça.
 */
describe("gamification_handler — guarda por conteúdo na parcela", () => {
    it("usa exatamente o mesmo conjunto de campos derivados do handler de finanças", () => {
        expect([...INSTALLMENT_DERIVED_FIELDS].sort())
            .toEqual([
                // F1.10: os espelhos inteiros do valor da parcela.
                "amountCents",
                // F1.8: a janela do ciclo da fatura é escrita pelo servidor.
                "closingDate", "cycleEnd", "cycleStart",
                "lastUpdate", "paidAmountCents", "referenceAmountCents", "replicationCascade",
                // F2.3: gravado na mesma escrita do xp.
                "unplannedReason",
                "updatedAt", "xp",
            ]);
    });

    it("trata o preenchimento da janela do ciclo como escrita derivada", () => {
        // O backfill de F1.8 grava cycleStart/cycleEnd nas faturas antigas.
        // Sem a guarda, cada fatura da base reavaliaria badges e missões.
        const before = { ...PENDING_INSTALLMENT, isInvoice: true };
        const after = {
            ...before,
            cycleStart: "2025-02-05",
            cycleEnd: "2025-03-04",
            closingDate: "2025-03-05",
        };

        expect(isDerivedOnlyInstallmentWrite(before, after)).toBe(true);
    });

    it("reconhece a escrita derivada de xp + cascata", () => {
        const before = { ...PENDING_INSTALLMENT, status: "paid", paidAmount: 100, replicationCascade: "all" };
        const after = { ...before, xp: 15, replicationCascade: "none" };

        expect(isDerivedOnlyInstallmentWrite(before, after)).toBe(true);
    });

    it("reconhece uma escrita que não mudou nada", () => {
        expect(isDerivedOnlyInstallmentWrite(PENDING_INSTALLMENT, { ...PENDING_INSTALLMENT })).toBe(true);
    });

    it("não trata uma mudança de conteúdo como derivada", () => {
        const before = PENDING_INSTALLMENT;

        expect(isDerivedOnlyInstallmentWrite(before, { ...before, status: "paid", paidAmount: 100 })).toBe(false);
        expect(isDerivedOnlyInstallmentWrite(before, { ...before, amount: 200 })).toBe(false);
        expect(isDerivedOnlyInstallmentWrite(before, { ...before, description: "Outro" })).toBe(false);
        expect(isDerivedOnlyInstallmentWrite(before, { ...before, dueDate: timestamp(new Date(2025, 2, 28, 12)) })).toBe(false);
    });

    it("uma criação (sem before) nunca é derivada", () => {
        expect(isDerivedOnlyInstallmentWrite(null, PENDING_INSTALLMENT)).toBe(false);
    });

    it("uma exclusão (sem after) nunca é derivada", () => {
        expect(isDerivedOnlyInstallmentWrite(PENDING_INSTALLMENT, null)).toBe(false);
    });

    it("ignora diferença de representação entre Timestamp e Date", () => {
        const before = { ...PENDING_INSTALLMENT, dueDate: timestamp(new Date(2025, 2, 10, 12)) };
        const after = { ...before, dueDate: new Date(2025, 2, 10, 12), xp: 15 };

        expect(isDerivedOnlyInstallmentWrite(before, after)).toBe(true);
    });
});
