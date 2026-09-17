/**
 * F1.8 — `accounts/{id}.nextInvoice`: o servidor resolve, o cliente lê.
 */

import {
    AccountModel,
    AccountType,
    InstallmentModel,
    InstallmentStatus,
    InstallmentType,
    NextInvoiceModel,
    OrderType,
} from "../features/finance/domain/models/finance.models";
import { IFinanceRepository } from "../features/finance/domain/repositories/finance.repository";
import { InvoiceSyncServiceImpl, isSameNextInvoice } from "../features/finance/domain/services/invoice_sync.service";
import { toDateKey } from "../core/utils/date_key";

const ACCOUNT_ID = "acc-card";
const WORKSPACE_ID = "ws-1";

/** Instante do meio-dia de São Paulo (UTC-3 o ano inteiro desde 2019). */
function spNoon(dateKey: string): Date {
    const [year, month, day] = dateKey.split("-").map(Number);
    return new Date(Date.UTC(year, month - 1, day, 15, 0, 0));
}

function card(overrides: Partial<AccountModel> = {}): AccountModel {
    return {
        id: ACCOUNT_ID,
        name: "Cartão",
        icon: "credit_card",
        color: "#000000",
        runtimeType: AccountType.creditCard,
        isDeleted: false,
        initialBalance: 0,
        initialBalanceDate: spNoon("2025-01-01"),
        closingDay: 5,
        dueDay: 10,
        limit: 5000,
        ...overrides,
    };
}

function invoice(overrides: Partial<InstallmentModel> = {}): InstallmentModel {
    return {
        id: "inst-invoice",
        orderId: `invoice-${ACCOUNT_ID}-2025-03-10`,
        amount: 350.5,
        dueDate: spNoon("2025-03-10"),
        description: "Fatura Cartão",
        installmentType: InstallmentType.single,
        status: InstallmentStatus.pending,
        type: OrderType.transfer,
        accounts: { [ACCOUNT_ID]: "credit" },
        accountIds: [ACCOUNT_ID],
        referenceDate: spNoon("2025-03-10"),
        referenceAmount: 350.5,
        isInvoice: true,
        ...overrides,
    };
}

interface Harness {
    service: InvoiceSyncServiceImpl;
    repository: jest.Mocked<Pick<IFinanceRepository,
        "getAccountById" | "getAccounts" | "getNextPendingInvoice" | "setAccountNextInvoice">>;
}

function makeHarness(options: {
    account?: AccountModel | null;
    accounts?: AccountModel[];
    pending?: InstallmentModel | null;
} = {}): Harness {
    const repository = {
        getAccountById: jest.fn().mockResolvedValue(
            options.account === undefined ? card() : options.account
        ),
        getAccounts: jest.fn().mockResolvedValue(options.accounts ?? []),
        getNextPendingInvoice: jest.fn().mockResolvedValue(options.pending ?? null),
        setAccountNextInvoice: jest.fn().mockResolvedValue(undefined),
    };

    return {
        service: new InvoiceSyncServiceImpl(repository as unknown as IFinanceRepository),
        repository: repository as any,
    };
}

/** Último `nextInvoice` gravado. */
function written(h: Harness): NextInvoiceModel {
    const calls = h.repository.setAccountNextInvoice.mock.calls;
    return calls[calls.length - 1][2] as NextInvoiceModel;
}

describe("InvoiceSyncService.syncNextInvoice", () => {
    it("usa a fatura em aberto como fonte do valor, do status e do id", async () => {
        const h = makeHarness({ pending: invoice() });

        expect(await h.service.syncNextInvoice(WORKSPACE_ID, ACCOUNT_ID, null, spNoon("2025-02-20"))).toBe(true);

        const next = written(h);
        expect(toDateKey(next.dueDate)).toBe("2025-03-10");
        expect(next.amount).toBe(350.5);
        expect(next.installmentId).toBe("inst-invoice");
        expect(next.orderId).toBe(`invoice-${ACCOUNT_ID}-2025-03-10`);
        expect(next.status).toBe(InstallmentStatus.pending);
        // Janela do ciclo vinda do servidor: fechamento 05/03, ciclo 05/02..04/03.
        expect(toDateKey(next.cycleStart)).toBe("2025-02-05");
        expect(toDateKey(next.cycleEnd)).toBe("2025-03-04");
        expect(toDateKey(next.closingDate)).toBe("2025-03-05");
    });

    it("mantém a fatura VENCIDA e não paga como a próxima", async () => {
        const h = makeHarness({ pending: invoice({ dueDate: spNoon("2025-02-10") }) });

        await h.service.syncNextInvoice(WORKSPACE_ID, ACCOUNT_ID, null, spNoon("2025-03-20"));

        expect(toDateKey(written(h).dueDate)).toBe("2025-02-10");
    });

    it("sem fatura em aberto, devolve o ciclo corrente com valor zero", async () => {
        const h = makeHarness({ pending: null });

        expect(await h.service.syncNextInvoice(WORKSPACE_ID, ACCOUNT_ID, null, spNoon("2025-03-20"))).toBe(true);

        const next = written(h);
        expect(next.amount).toBe(0);
        expect(next.installmentId).toBeNull();
        expect(next.status).toBe(InstallmentStatus.pending);
        // 10/03 já passou -> o próximo vencimento é 10/04.
        expect(toDateKey(next.dueDate)).toBe("2025-04-10");
        expect(next.orderId).toBe(`invoice-${ACCOUNT_ID}-2025-04-10`);
    });

    it("avança a fatura quando o vencimento passa (sem nada em aberto)", async () => {
        const h = makeHarness({ pending: null });

        await h.service.syncNextInvoice(WORKSPACE_ID, ACCOUNT_ID, null, spNoon("2025-03-09"));
        expect(toDateKey(written(h).dueDate)).toBe("2025-03-10");

        await h.service.syncNextInvoice(WORKSPACE_ID, ACCOUNT_ID, null, spNoon("2025-03-11"));
        expect(toDateKey(written(h).dueDate)).toBe("2025-04-10");
    });

    it("NÃO escreve quando o resumo já está correto (o gatilho se realimentaria)", async () => {
        const first = makeHarness({ pending: invoice() });
        await first.service.syncNextInvoice(WORKSPACE_ID, ACCOUNT_ID, null, spNoon("2025-02-20"));
        const current = written(first);

        const h = makeHarness({
            account: card({ nextInvoice: current }),
            pending: invoice(),
        });

        expect(await h.service.syncNextInvoice(WORKSPACE_ID, ACCOUNT_ID, null, spNoon("2025-02-20"))).toBe(false);
        expect(h.repository.setAccountNextInvoice).not.toHaveBeenCalled();
    });

    it("apaga o resumo de conta que deixou de ser cartão", async () => {
        const h = makeHarness({
            account: card({
                runtimeType: AccountType.checking,
                nextInvoice: { amount: 10 } as NextInvoiceModel,
            }),
        });

        expect(await h.service.syncNextInvoice(WORKSPACE_ID, ACCOUNT_ID)).toBe(true);
        expect(h.repository.setAccountNextInvoice).toHaveBeenCalledWith(WORKSPACE_ID, ACCOUNT_ID, null);
    });

    it("apaga o resumo de cartão apagado logicamente", async () => {
        const h = makeHarness({
            account: card({ isDeleted: true, nextInvoice: { amount: 10 } as NextInvoiceModel }),
        });

        expect(await h.service.syncNextInvoice(WORKSPACE_ID, ACCOUNT_ID)).toBe(true);
        expect(h.repository.setAccountNextInvoice).toHaveBeenCalledWith(WORKSPACE_ID, ACCOUNT_ID, null);
    });

    it("não escreve nada numa conta comum que nunca teve resumo", async () => {
        const h = makeHarness({ account: card({ runtimeType: AccountType.checking }) });

        expect(await h.service.syncNextInvoice(WORKSPACE_ID, ACCOUNT_ID)).toBe(false);
        expect(h.repository.setAccountNextInvoice).not.toHaveBeenCalled();
    });

    it("ignora conta inexistente", async () => {
        const h = makeHarness({ account: null });

        expect(await h.service.syncNextInvoice(WORKSPACE_ID, "sumiu")).toBe(false);
        expect(h.repository.setAccountNextInvoice).not.toHaveBeenCalled();
    });

    it("aproveita a conta recebida e não relê o documento", async () => {
        const h = makeHarness({ pending: null });

        await h.service.syncNextInvoice(WORKSPACE_ID, ACCOUNT_ID, card(), spNoon("2025-03-01"));

        expect(h.repository.getAccountById).not.toHaveBeenCalled();
    });

    it("respeita o clamp: fechamento 31 em fevereiro", async () => {
        const h = makeHarness({
            account: card({ closingDay: 31, dueDay: 10 }),
            pending: invoice({ dueDate: spNoon("2025-04-10") }),
        });

        await h.service.syncNextInvoice(WORKSPACE_ID, ACCOUNT_ID, null, spNoon("2025-03-15"));

        const next = written(h);
        expect(toDateKey(next.cycleStart)).toBe("2025-02-28");
        expect(toDateKey(next.closingDate)).toBe("2025-03-31");
        expect(toDateKey(next.cycleEnd)).toBe("2025-03-30");
    });
});

describe("InvoiceSyncService.syncWorkspace", () => {
    it("pula o cartão cujo vencimento ainda não chegou", async () => {
        const emAberto = card({
            id: "acc-em-dia",
            nextInvoice: { dueDate: spNoon("2025-03-10") } as NextInvoiceModel,
        });

        const h = makeHarness({ accounts: [emAberto] });

        const result = await h.service.syncWorkspace(WORKSPACE_ID, spNoon("2025-03-01"));

        expect(result).toEqual({ scanned: 1, updated: 0 });
        expect(h.repository.getNextPendingInvoice).not.toHaveBeenCalled();
    });

    it("sincroniza o cartão com vencimento vencido e o que nunca teve resumo", async () => {
        const vencido = card({
            id: "acc-vencido",
            nextInvoice: { dueDate: spNoon("2025-02-10") } as NextInvoiceModel,
        });
        const novo = card({ id: "acc-novo" });
        const corrente = card({
            id: "acc-corrente",
            nextInvoice: { dueDate: spNoon("2025-04-10") } as NextInvoiceModel,
        });

        const h = makeHarness({ accounts: [vencido, novo, corrente] });

        const result = await h.service.syncWorkspace(WORKSPACE_ID, spNoon("2025-03-15"));

        expect(result).toEqual({ scanned: 3, updated: 2 });
        const alvos = h.repository.setAccountNextInvoice.mock.calls.map((c) => c[1]);
        expect(alvos.sort()).toEqual(["acc-novo", "acc-vencido"]);
    });

    it("ignora contas que não são cartão", async () => {
        const h = makeHarness({
            accounts: [card({ id: "cc", runtimeType: AccountType.checking })],
        });

        expect(await h.service.syncWorkspace(WORKSPACE_ID, spNoon("2025-03-15")))
            .toEqual({ scanned: 0, updated: 0 });
    });

    it("o vencimento do PRÓPRIO dia ainda conta como em aberto", async () => {
        const hoje = card({
            id: "acc-hoje",
            nextInvoice: { dueDate: spNoon("2025-03-15") } as NextInvoiceModel,
        });

        const h = makeHarness({ accounts: [hoje] });

        // O corte é a meia-noite do dia no fuso do produto, não o instante.
        expect(await h.service.syncWorkspace(WORKSPACE_ID, spNoon("2025-03-15")))
            .toEqual({ scanned: 1, updated: 0 });
    });
});

describe("isSameNextInvoice", () => {
    const base: NextInvoiceModel = {
        dueDate: spNoon("2025-03-10"),
        closingDate: spNoon("2025-03-05"),
        cycleStart: spNoon("2025-02-05"),
        cycleEnd: spNoon("2025-03-04"),
        amount: 100,
        orderId: "invoice-acc-2025-03-10",
        installmentId: "inst-1",
        status: InstallmentStatus.pending,
    };

    it("ignora updatedAt", () => {
        expect(isSameNextInvoice({ ...base, updatedAt: new Date(0) }, base)).toBe(true);
    });

    it("detecta mudança de valor, de status e de parcela", () => {
        expect(isSameNextInvoice({ ...base, amount: 101 }, base)).toBe(false);
        expect(isSameNextInvoice({ ...base, status: InstallmentStatus.paid }, base)).toBe(false);
        expect(isSameNextInvoice({ ...base, installmentId: null }, base)).toBe(false);
    });

    it("detecta mudança de janela", () => {
        expect(isSameNextInvoice({ ...base, cycleStart: spNoon("2025-02-06") }, base)).toBe(false);
    });

    it("resumo ausente nunca é igual", () => {
        expect(isSameNextInvoice(null, base)).toBe(false);
        expect(isSameNextInvoice(undefined, base)).toBe(false);
    });
});
