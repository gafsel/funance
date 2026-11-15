import { DadosAntigos } from "../../features/nucleo/migracao/dados_antigos";

/** Meio-dia de Brasília do dia informado. */
export const em = (dia: string): Date => new Date(`${dia}T15:00:00Z`);

const comida = { id: "comida", name: "Comida", icon: "x", color: "#fff", type: "expense", allocation: "essential" };
const salario = { id: "salario", name: "Salário", icon: "x", color: "#fff", type: "income", allocation: "essential" };

/**
 * Um workspace pequeno e coerente do app antigo: os saldos e resumos gravados
 * batem com as parcelas, como os gatilhos antigos deixariam.
 */
export function workspaceAntigo(): DadosAntigos {
    return {
        projeto: "demo-antigo",
        workspaceId: "w1",
        workspace: { name: "Casa", type: "personal", members: ["u1", "u2"], createdAt: em("2025-12-01") },
        accounts: {
            cc: { name: "Corrente", runtimeType: "checking", initialBalance: 1000, initialBalanceDate: "2026-01-01T12:00:00.000", bankLogo: "nubank", ownerIds: ["u1"] },
            cartao: { name: "Cartão", runtimeType: "creditCard", closingDay: 5, dueDay: 10, limit: 5000, bankLogo: "none" },
        },
        orders: {
            "initial-balance-cc": { type: "income", amount: 1000, accounts: { cc: "credit" }, installmentType: "single", status: "settled" },
            "o1": { type: "income", amount: 5000, accounts: { cc: "credit" }, installmentType: "single", status: "active" },
            "o2": { type: "expense", amount: 200, accounts: { cartao: "debt" }, installmentType: "single", status: "active" },
            "invoice-cartao-2026-02-10": {
                type: "transfer", amount: 200, amountCents: 20000, accounts: { cartao: "credit" }, isInvoice: true,
                installmentType: "single", status: "active",
                cycleStart: new Date("2026-01-05T03:00:00Z"), cycleEnd: new Date("2026-02-05T02:59:59.999Z"),
                closingDate: new Date("2026-02-05T03:00:00Z"),
            },
            "o3": { type: "expense", amount: 150, accounts: { cc: "debt" }, installmentType: "single", status: "active" },
            "o4": { type: "transfer", amount: 50, accounts: { cc: "debt" }, installmentType: "single", status: "active" },
        },
        installments: {
            ib: {
                orderId: "initial-balance-cc", type: "income", amount: 0, paidAmount: 1000, paidAmountCents: 100000,
                status: "settled", dueDate: em("2026-01-01"), paidDate: em("2026-01-01"), accounts: { cc: "credit" },
                category: { id: "initial-balance", name: "Saldo Inicial", type: "income" },
            },
            i1: {
                orderId: "o1", type: "income", description: "Salário", amount: 5000, paidAmount: 5000, status: "paid",
                dueDate: em("2026-01-05"), paidDate: em("2026-01-05"), accounts: { cc: "credit" }, category: salario,
            },
            i2: {
                orderId: "o2", type: "expense", description: "Mercado", amount: 0, paidAmount: 200, status: "paid",
                unplannedReason: "born_paid", dueDate: em("2026-01-10"), paidDate: em("2026-01-10"),
                accounts: { cartao: "debt" }, category: comida,
            },
            inv1: {
                orderId: "invoice-cartao-2026-02-10", type: "transfer", description: "Fatura Cartão", amount: 200,
                status: "pending", isInvoice: true, dueDate: em("2026-02-10"), paidDate: null, accounts: { cartao: "credit" },
            },
            i3: {
                orderId: "o3", type: "expense", description: "Cinema", amount: 150, status: "pending",
                dueDate: em("2026-01-20"), paidDate: null, accounts: { cc: "debt" },
                category: { id: "", name: "Lazer", type: "expense" },
            },
            i4: {
                orderId: "o4", type: "transfer", description: "Transferência torta", amount: 50, status: "pending",
                dueDate: em("2026-01-22"), paidDate: null, accounts: { cc: "debt" },
            },
        },
        categories: {
            "comida": { ...comida, id: undefined },
            "salario": { ...salario, id: undefined },
            "initial-balance": { name: "Saldo Inicial", type: "income", isSystem: true },
        },
        plannings: {
            p1: { category: comida, amount: 800, startMonth: "2026-01", endMonth: "9999-12" },
        },
        goals: {},
        automaticas: {
            a1: { id: "a1", description: "PIX recebido", amount: 80, date: "2026-01-15T10:30:00.000", type: "income", isConsolidated: false, isIgnored: false },
            a2: { id: "a2", description: "Já lançado", amount: 10, date: "2026-01-15T10:30:00.000", type: "expense", isConsolidated: true, isIgnored: false },
        },
        reconciliations: {
            r1: { id: "r1", status: "completed", confirmedMatchesCount: 3, totalTransactionsProcessed: 5, createdTransactionsCount: 2, createdAt: em("2026-01-31") },
        },
        saldos: {
            cc: {
                "2026-01-01": { dateKey: "2026-01-01", delta: 1000, balance: 1000, balanceCents: 100000 },
                "2026-01-05": { dateKey: "2026-01-05", delta: 5000, balance: 6000, balanceCents: 600000 },
            },
            cartao: {
                "2026-01-10": { dateKey: "2026-01-10", delta: -200, balance: -200, balanceCents: -20000 },
            },
        },
        resumos: {
            "2026-01": {
                runtimeType: "month", year: 2026, month: 1,
                categories: {
                    "initial-balance": { actualAmount: 1000, specificPlannedAmount: 0 },
                    "salario": { actualAmount: 5000, specificPlannedAmount: 5000 },
                    "comida": { actualAmount: 200, specificPlannedAmount: 0, generalPlannedAmount: 800 },
                },
            },
            "2026": { runtimeType: "year", year: 2026, categories: { salario: { actualAmount: 5000 } } },
        },
    };
}
