/**
 * HOTFIX — categoria sem id (`{id: "", name: "Supermercado"}`).
 *
 * Conciliação/transação automática gravaram parcelas e orders com o nome da
 * categoria mas sem id. A chave `period_summaries.categories.<id>` com id vazio
 * vira um segmento vazio de `FieldPath` e o SDK rejeita o documento inteiro
 * ("Element at index 0 should not be an empty string"), derrubando o gatilho de
 * sumário.
 *
 * REGRA ÚNICA coberta aqui: categoria sem id é SEM CATEGORIA para efeito de
 * sumário — não entra em `period_summaries`, nem projetado nem realizado, com
 * um aviso por parcela. Saldo e XP não dependem de categoria e seguem contando
 * (ver `rebuild.test.ts` e `finance_repository.test.ts` para as outras pontas).
 */

import { SummaryService } from "../features/finance/domain/services/summary.service";
import {
    AccountModel,
    AccountType,
    InstallmentModel,
    InstallmentStatus,
    InstallmentType,
    OrderType,
} from "../features/finance/domain/models/finance.models";
import {
    CategoryModel,
    CategoryType,
    hasCategoryId,
    isCategoryRefBroken,
} from "../features/workspace/domain/models/category.model";

const WORKSPACE = "ws-1";

const CATEGORY: CategoryModel = {
    id: "cat-mercado",
    name: "Supermercado",
    icon: "shopping_cart",
    color: "#42A5F5",
    type: CategoryType.expense,
    isDeleted: false,
};

/** O documento realmente encontrado em produção: nome sem id. */
const BROKEN_CATEGORY = { ...CATEGORY, id: "" };

interface SummaryCall {
    year: number;
    month?: number;
    week?: number;
    category: CategoryModel;
    data: Record<string, number | undefined>;
}

class FakeRepository {
    calls: SummaryCall[] = [];

    async updatePeriodSummary(
        _workspaceId: string,
        year: number,
        month: number | undefined,
        category: CategoryModel,
        data: Record<string, number | undefined>,
        week?: number
    ): Promise<void> {
        this.calls.push({ year, month, week, category, data });
    }

    /** Conta devolvida a QUALQUER `getAccountById` — `null` desliga a virtual. */
    account: AccountModel | null = null;

    async getAccountById(): Promise<AccountModel | null> {
        return this.account;
    }
}

function installment(overrides: Partial<InstallmentModel> = {}): InstallmentModel {
    const date = new Date(2026, 2, 10, 12);
    return {
        id: "inst-1",
        orderId: "order-1",
        amount: 167.47,
        dueDate: date,
        description: "Compra no mercado",
        installmentType: InstallmentType.single,
        status: InstallmentStatus.paid,
        type: OrderType.expense,
        accounts: { "acc-checking": "debt" },
        accountIds: ["acc-checking"],
        category: BROKEN_CATEGORY,
        paidAmount: 167.47,
        paidDate: date,
        referenceDate: date,
        referenceAmount: 167.47,
        ...overrides,
    };
}

describe("hasCategoryId", () => {
    it("só aceita id string não vazio", () => {
        expect(hasCategoryId(CATEGORY)).toBe(true);
        expect(hasCategoryId(BROKEN_CATEGORY)).toBe(false);
        expect(hasCategoryId(undefined)).toBe(false);
        expect(hasCategoryId(null)).toBe(false);
        expect(hasCategoryId({ id: null })).toBe(false);
        expect(hasCategoryId({} as CategoryModel)).toBe(false);
    });
});

describe("isCategoryRefBroken — só a categoria QUEBRADA merece aviso", () => {
    it("id vazio é defeito em qualquer tipo, transferência inclusive", () => {
        expect(isCategoryRefBroken({ type: OrderType.expense, category: BROKEN_CATEGORY })).toBe(true);
        expect(isCategoryRefBroken({ type: OrderType.income, category: BROKEN_CATEGORY })).toBe(true);
        expect(isCategoryRefBroken({ type: OrderType.transfer, category: BROKEN_CATEGORY })).toBe(true);
    });

    it("categoria AUSENTE é defeito fora de transferência", () => {
        expect(isCategoryRefBroken({ type: OrderType.expense })).toBe(true);
        expect(isCategoryRefBroken({ type: OrderType.expense, category: null })).toBe(true);
        expect(isCategoryRefBroken({ type: OrderType.income, category: undefined })).toBe(true);
        // Sem `type` nenhum também é defeito: só transferência tem passe livre.
        expect(isCategoryRefBroken({})).toBe(true);
    });

    it("transferência sem categoria é o desenho NORMAL: silêncio", () => {
        // Fatura também é `type: transfer` — entra na mesma isenção. Era daqui
        // que vinham as 98 falsas "parcelas sem categoria" de um rebuild de
        // produção.
        expect(isCategoryRefBroken({ type: OrderType.transfer })).toBe(false);
        expect(isCategoryRefBroken({ type: OrderType.transfer, category: null })).toBe(false);
        expect(isCategoryRefBroken({ type: OrderType.transfer, category: undefined })).toBe(false);
    });

    it("o literal usado no modelo casa com OrderType.transfer", () => {
        expect(OrderType.transfer).toBe("transfer");
    });

    it("categoria boa nunca é defeito", () => {
        expect(isCategoryRefBroken({ type: OrderType.expense, category: CATEGORY })).toBe(false);
        expect(isCategoryRefBroken({ type: OrderType.transfer, category: CATEGORY })).toBe(false);
    });
});

describe("SummaryService com categoria de id vazio", () => {
    let repository: FakeRepository;
    let service: SummaryService;
    let warn: jest.SpyInstance;

    beforeEach(() => {
        repository = new FakeRepository();
        service = new SummaryService(repository as any);
        warn = jest.spyOn(console, "warn").mockImplementation(() => undefined);
    });

    afterEach(() => {
        warn.mockRestore();
    });

    it("não escreve NENHUM sumário — nem projetado nem realizado", async () => {
        await service.processInstallmentChange(WORKSPACE, null, installment());

        expect(repository.calls).toHaveLength(0);
    });

    it("também não escreve no estorno (a parcela sai do sumário que nunca entrou)", async () => {
        await service.processInstallmentChange(WORKSPACE, installment(), null);

        expect(repository.calls).toHaveLength(0);
    });

    it("avisa UMA VEZ por parcela, citando workspace e parcela", async () => {
        // Antes e depois pagos: são quatro chamadas internas (projetado e
        // realizado, estorno e aplicação) para a mesma parcela.
        await service.processInstallmentChange(
            WORKSPACE,
            installment({ amount: 100, paidAmount: 100 }),
            installment()
        );

        expect(warn).toHaveBeenCalledTimes(1);
        const message = warn.mock.calls[0][0] as string;
        expect(message).toContain(`workspace=${WORKSPACE}`);
        expect(message).toContain("parcela=inst-1");
        expect(message).toContain("Supermercado");
    });

    it("a categoria válida continua escrevendo mês, ano e semana nas duas frentes", async () => {
        await service.processInstallmentChange(WORKSPACE, null, installment({ category: CATEGORY }));

        // 3 documentos (mês, ano, semana) × projetado + realizado.
        expect(repository.calls).toHaveLength(6);
        expect(repository.calls.every((call) => call.category.id === CATEGORY.id)).toBe(true);
        expect(warn).not.toHaveBeenCalled();
    });

    it("categoria ausente cai na mesma regra: fora do sumário, com um aviso", async () => {
        await service.processInstallmentChange(WORKSPACE, null, installment({ category: undefined }));

        expect(repository.calls).toHaveLength(0);
        expect(warn).toHaveBeenCalledTimes(1);
    });

    it("transferência sem categoria fica fora do sumário EM SILÊNCIO", async () => {
        // `getAccountById` do fake devolve null: nenhuma contrapartida virtual,
        // que é o caso da esmagadora maioria das transferências. Antes isso
        // enchia o log de falso positivo.
        await service.processInstallmentChange(WORKSPACE, null, installment({
            type: OrderType.transfer,
            category: undefined,
            accounts: { "acc-origem": "debt", "acc-destino": "credit" },
            accountIds: ["acc-origem", "acc-destino"],
        }));

        expect(repository.calls).toHaveLength(0);
        expect(warn).not.toHaveBeenCalled();
    });

    /**
     * O aviso julga a categoria EFETIVA — a mesma que a guarda acabou de
     * recusar —, e não `inst.category`.
     *
     * Numa transferência sem contrapartida virtual o serviço saía ANTES da
     * guarda, então uma transferência com categoria quebrada (`{id: ""}`)
     * ficava fora do sumário sem uma palavra, embora `isCategoryRefBroken`
     * diga que id vazio é defeito em QUALQUER tipo.
     */
    it("transferência com categoria QUEBRADA avisa (id vazio é defeito em qualquer tipo)", async () => {
        await service.processInstallmentChange(WORKSPACE, null, installment({
            type: OrderType.transfer,
            category: BROKEN_CATEGORY,
            accounts: { "acc-origem": "debt", "acc-destino": "credit" },
            accountIds: ["acc-origem", "acc-destino"],
        }));

        expect(repository.calls).toHaveLength(0);
        expect(warn).toHaveBeenCalledTimes(1);
        expect(warn.mock.calls[0][0] as string).toContain("parcela=inst-1");
    });

    /**
     * Com contrapartida virtual, a categoria efetiva é a VIRTUAL — que sempre
     * tem id. A original quebrada não importa mais: ela foi SUBSTITUÍDA, o
     * sumário é escrito normalmente e não há defeito a denunciar.
     */
    it("transferência com contrapartida virtual escreve pela virtual, sem aviso", async () => {
        repository.account = {
            id: "acc-destino",
            runtimeType: AccountType.investment,
        } as AccountModel;

        await service.processInstallmentChange(WORKSPACE, null, installment({
            type: OrderType.transfer,
            category: BROKEN_CATEGORY,
            accounts: { "acc-origem": "debt", "acc-destino": "credit" },
            accountIds: ["acc-origem", "acc-destino"],
        }));

        expect(repository.calls).toHaveLength(6);
        expect(repository.calls.every((call) => call.category.id === "virtual_investment_expense")).toBe(true);
        expect(warn).not.toHaveBeenCalled();
    });
});
