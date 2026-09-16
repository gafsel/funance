// ofx-js é ESM puro e não é transformado pelo ts-jest; o container o alcança via ai.service
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import {
    onCategoryPlanningWrittenGamification,
    onInstallmentWrittenGamification,
} from "../features/goal/presentation/functions/gamification_handler";

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
