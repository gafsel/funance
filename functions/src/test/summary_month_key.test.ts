/**
 * O mês do sumário é o mês do FUSO DO PRODUTO.
 *
 * Dia (`toDateKey`) e semana (`week.utils`) já eram `America/Sao_Paulo`, mas o
 * mês e o ano dos `period_summaries` ainda vinham de `getFullYear()/getMonth()`
 * — UTC no servidor. Um pagamento às 23h30 de 31/10 em São Paulo é 01/11 em
 * UTC e ia parar no sumário de NOVEMBRO, enquanto o saldo do mesmo pagamento
 * ficava em outubro.
 */

// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service (FinanceService importa o container), mas não é
// exercitado aqui.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import { SummaryService } from "../features/finance/domain/services/summary.service";
import { RebuildAccumulator } from "../features/finance/domain/services/rebuild.service";
import { FinanceService } from "../features/finance/domain/services/finance.service";
import {
    InstallmentModel,
    InstallmentStatus,
    InstallmentType,
    OrderType,
} from "../features/finance/domain/models/finance.models";
import { CategoryModel, CategoryType } from "../features/workspace/domain/models/category.model";
import { toDateKey } from "../core/utils/date_key";
import { getWeekId } from "../core/utils/week.utils";

const CATEGORY: CategoryModel = {
    id: "cat-mercado",
    name: "Mercado",
    icon: "shopping_cart",
    color: "#42A5F5",
    type: CategoryType.expense,
    isDeleted: false,
    allocation: "essential",
};

/** 23h30 de 31/10/2026 em São Paulo = 01/11/2026 02h30 em UTC. */
const VIRADA_DO_MES = new Date("2026-11-01T02:30:00.000Z");

interface SummaryCall {
    year: number;
    month?: number;
    week?: number;
    data: Record<string, number | undefined>;
}

class FakeRepository {
    calls: SummaryCall[] = [];

    async updatePeriodSummary(
        _workspaceId: string,
        year: number,
        month: number | undefined,
        _category: CategoryModel,
        data: Record<string, number | undefined>,
        week?: number
    ): Promise<void> {
        this.calls.push({ year, month, week, data });
    }

    async getAccountById(): Promise<null> {
        return null;
    }
}

function installment(overrides: Partial<InstallmentModel> = {}): InstallmentModel {
    return {
        id: "inst-1",
        orderId: "order-1",
        amount: 100,
        dueDate: VIRADA_DO_MES,
        description: "Mercado",
        installmentType: InstallmentType.single,
        status: InstallmentStatus.pending,
        type: OrderType.expense,
        accounts: { "acc-checking": "debt" },
        accountIds: ["acc-checking"],
        category: CATEGORY,
        referenceDate: VIRADA_DO_MES,
        referenceAmount: 100,
        ...overrides,
    };
}

describe("mês do period_summaries no fuso do produto", () => {
    it("a data de referência é 01/11 em UTC e 31/10 em São Paulo", () => {
        expect(VIRADA_DO_MES.getUTCMonth() + 1).toBe(11);
        expect(toDateKey(VIRADA_DO_MES)).toBe("2026-10-31");
    });

    it("o realizado de um pagamento às 23h30 de 31/10 entra no sumário de outubro", async () => {
        const repository = new FakeRepository();
        const service = new SummaryService(repository as any);

        await service.processInstallmentChange("w1", null, installment({
            status: InstallmentStatus.paid,
            paidAmount: 100,
            paidDate: VIRADA_DO_MES,
        }));

        const realizado = repository.calls.filter((call) => call.data.actualDelta !== undefined);

        const mes = realizado.find((call) => call.month !== undefined)!;
        expect({ year: mes.year, month: mes.month }).toEqual({ year: 2026, month: 10 });

        const ano = realizado.find((call) => call.month === undefined && call.week === undefined)!;
        expect(ano.year).toBe(2026);

        // A semana continua vindo da definição única (F1.9) e concorda com o mês.
        const semana = realizado.find((call) => call.week !== undefined)!;
        expect(`${semana.year}-W${String(semana.week).padStart(2, "0")}`).toBe(getWeekId(VIRADA_DO_MES));
    });

    it("o projetado usa o mesmo mês (dueDate na virada)", async () => {
        const repository = new FakeRepository();
        const service = new SummaryService(repository as any);

        await service.processInstallmentChange("w1", null, installment());

        const projetado = repository.calls.filter((call) => call.data.specificPlannedDelta !== undefined);
        const mes = projetado.find((call) => call.month !== undefined)!;

        expect({ year: mes.year, month: mes.month }).toEqual({ year: 2026, month: 10 });
    });

    it("a virada de ANO também respeita o fuso (01/01 01h UTC ainda é 31/12 em SP)", async () => {
        const repository = new FakeRepository();
        const service = new SummaryService(repository as any);
        const viradaDoAno = new Date("2027-01-01T01:00:00.000Z");

        await service.processInstallmentChange("w1", null, installment({
            dueDate: viradaDoAno,
            referenceDate: viradaDoAno,
            status: InstallmentStatus.paid,
            paidAmount: 100,
            paidDate: viradaDoAno,
        }));

        const realizado = repository.calls.filter((call) => call.data.actualDelta !== undefined);
        const mes = realizado.find((call) => call.month !== undefined)!;

        expect({ year: mes.year, month: mes.month }).toEqual({ year: 2026, month: 12 });
    });

    it("o rebuild reproduz o mesmo mês (o oráculo não pode divergir do gatilho)", () => {
        const financeRepository = new FakeRepository();
        const accumulator = new RebuildAccumulator(
            [],
            new SummaryService(financeRepository as any),
            new FinanceService(financeRepository as any)
        );

        accumulator.addInstallment(installment({
            status: InstallmentStatus.paid,
            paidAmount: 100,
            paidDate: VIRADA_DO_MES,
        }));

        const target = accumulator.build();
        const ids = [...target.summaries.keys()].sort();

        expect(ids).toContain("2026-10");
        expect(ids).not.toContain("2026-11");
        expect(target.summaries.get("2026-10")!.categories[CATEGORY.id].actualAmount).toBeCloseTo(100, 2);
        // E o saldo do mesmo pagamento cai no mesmo dia (31/10).
        expect([...target.balances.get("acc-checking")!.keys()]).toEqual(["2026-10-31"]);
    });
});
