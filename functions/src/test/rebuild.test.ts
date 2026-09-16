// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// finance.service -> container -> ai.service, mas não é usado aqui.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";
import {
    ExistingDoc,
    IRebuildRepository,
    RebuildWrite,
} from "../features/finance/domain/repositories/rebuild.repository";
import {
    AccountModel,
    AccountType,
    CategoryPlanningModel,
    InstallmentModel,
    InstallmentStatus,
    InstallmentType,
    OrderType,
} from "../features/finance/domain/models/finance.models";
import { CategoryModel, CategoryType } from "../features/workspace/domain/models/category.model";
import { FinanceService } from "../features/finance/domain/services/finance.service";
import { SummaryService } from "../features/finance/domain/services/summary.service";
import { RebuildService } from "../features/finance/domain/services/rebuild.service";
import { parseRebuildRequest } from "../features/finance/presentation/functions/rebuild_handler";

const WORKSPACE = "ws-1";

const CATEGORY: CategoryModel = {
    id: "cat-mercado",
    name: "Mercado",
    icon: "shopping_cart",
    color: "#42A5F5",
    type: CategoryType.expense,
    isDeleted: false,
};

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

const INVESTMENT: AccountModel = {
    ...CHECKING,
    id: "acc-invest",
    name: "Tesouro",
    runtimeType: AccountType.investment,
};

/**
 * Parcela no formato REAL do Firestore (Timestamps), decodificada pelo fake do
 * mesmo jeito que `RebuildRepositoryImpl.forEachInstallment` decodifica.
 */
function rawInstallment(id: string, overrides: Record<string, any>): { id: string, data: Record<string, any> } {
    return {
        id,
        data: {
            orderId: `order-${id}`,
            amount: 0,
            description: "Parcela",
            installmentType: InstallmentType.single,
            status: InstallmentStatus.pending,
            type: OrderType.expense,
            accounts: { [CHECKING.id]: "debt" },
            accountIds: [CHECKING.id],
            category: CATEGORY,
            paidDate: null,
            ...overrides,
            dueDate: overrides.dueDate,
        },
    };
}

const ts = (year: number, month: number, day: number) =>
    admin.firestore.Timestamp.fromDate(new Date(year, month - 1, day, 12));

class FakeRebuildRepository implements IRebuildRepository {
    installments: { id: string, data: Record<string, any> }[] = [];
    accounts: AccountModel[] = [];
    plannings: CategoryPlanningModel[] = [];
    balances = new Map<string, Map<string, Record<string, any>>>();
    summaries = new Map<string, Record<string, any>>();
    weeklyXp = new Map<string, Record<string, any>>();
    /** Páginas efetivamente lidas — usado para provar que a leitura pagina. */
    pagesRead = 0;

    async forEachInstallment(_: string, pageSize: number, visit: (i: InstallmentModel) => void): Promise<void> {
        const sorted = [...this.installments].sort((a, b) => a.id.localeCompare(b.id));
        for (let i = 0; i < sorted.length; i += pageSize) {
            this.pagesRead++;
            for (const doc of sorted.slice(i, i + pageSize)) {
                visit({
                    ...doc.data,
                    id: doc.id,
                    dueDate: doc.data.dueDate?.toDate(),
                    paidDate: doc.data.paidDate ? doc.data.paidDate.toDate() : undefined,
                } as InstallmentModel);
            }
        }
    }

    async getAccounts(): Promise<AccountModel[]> {
        return this.accounts;
    }

    async listAccountIds(): Promise<string[]> {
        return [...new Set([...this.accounts.map((a) => a.id), ...this.balances.keys()])];
    }

    async getCategoryPlannings(): Promise<CategoryPlanningModel[]> {
        return this.plannings;
    }

    async getExistingBalances(_: string, accountId: string): Promise<ExistingDoc[]> {
        const perAccount = this.balances.get(accountId);
        if (!perAccount) return [];
        return [...perAccount.entries()].map(([id, data]) => ({ id, data }));
    }

    async getExistingPeriodSummaries(): Promise<ExistingDoc[]> {
        return [...this.summaries.entries()].map(([id, data]) => ({ id, data }));
    }

    async getExistingWeeklyXp(): Promise<ExistingDoc[]> {
        return [...this.weeklyXp.entries()].map(([id, data]) => ({ id, data }));
    }

    async applyWrites(_: string, writes: RebuildWrite[], chunkSize: number): Promise<number> {
        expect(chunkSize).toBeLessThanOrEqual(400);

        for (const write of writes) {
            if (write.kind === "balance") {
                let perAccount = this.balances.get(write.accountId);
                if (!perAccount) {
                    perAccount = new Map();
                    this.balances.set(write.accountId, perAccount);
                }
                if (write.op === "delete") perAccount.delete(write.docId);
                else perAccount.set(write.docId, { ...write.data, updatedAt: "serverTimestamp" });
            }
            else if (write.kind === "summary") {
                if (write.op === "delete") this.summaries.delete(write.docId);
                else this.summaries.set(write.docId, { ...write.data, lastUpdate: "serverTimestamp" });
            }
            else {
                if (write.op === "delete") this.weeklyXp.delete(write.docId);
                else this.weeklyXp.set(write.docId, { ...write.data, lastUpdate: "serverTimestamp" });
            }
        }

        return writes.length;
    }
}

function buildService(repository: FakeRebuildRepository): RebuildService {
    const financeRepository = {} as any;
    return new RebuildService(
        repository,
        new SummaryService(financeRepository),
        new FinanceService(financeRepository)
    );
}

describe("RebuildService", () => {
    let repository: FakeRebuildRepository;
    let service: RebuildService;

    beforeEach(() => {
        repository = new FakeRebuildRepository();
        repository.accounts = [CHECKING, INVESTMENT];
        service = buildService(repository);
    });

    const NOW = new Date(2026, 2, 15, 12);
    const apply = () => service.rebuildWorkspace(WORKSPACE, { dryRun: false, now: NOW });
    const dryRun = () => service.rebuildWorkspace(WORKSPACE, { now: NOW });
    const applyRebuildingPlanning = () =>
        service.rebuildWorkspace(WORKSPACE, { dryRun: false, now: NOW, rebuildPlanning: true });

    describe("saldos diários", () => {
        it("acumula o saldo dia a dia a partir do saldo inicial e das parcelas pagas", async () => {
            repository.installments = [
                // Saldo inicial: nasce liquidado, amount 0 e valor em paidAmount.
                rawInstallment("a-inicial", {
                    orderId: `initial-balance-${CHECKING.id}`,
                    amount: 0,
                    paidAmount: 1000,
                    status: InstallmentStatus.settled,
                    type: OrderType.income,
                    accounts: { [CHECKING.id]: "credit" },
                    dueDate: ts(2026, 3, 1),
                    paidDate: ts(2026, 3, 1),
                }),
                rawInstallment("b-mercado", {
                    amount: 167.47,
                    paidAmount: 167.47,
                    status: InstallmentStatus.paid,
                    dueDate: ts(2026, 3, 10),
                    paidDate: ts(2026, 3, 10),
                }),
                rawInstallment("c-mercado", {
                    amount: 50,
                    paidAmount: 50,
                    status: InstallmentStatus.paid,
                    dueDate: ts(2026, 3, 20),
                    paidDate: ts(2026, 3, 20),
                }),
            ];

            await apply();

            const balances = repository.balances.get(CHECKING.id)!;
            expect([...balances.keys()].sort()).toEqual(["2026-03-01", "2026-03-10", "2026-03-20"]);
            expect(balances.get("2026-03-01")!.balance).toBeCloseTo(1000, 2);
            expect(balances.get("2026-03-10")!.balance).toBeCloseTo(832.53, 2);
            expect(balances.get("2026-03-20")!.balance).toBeCloseTo(782.53, 2);
        });

        it("soma todas as parcelas do mesmo dia num único documento", async () => {
            repository.installments = [
                rawInstallment("a", {
                    amount: 10, paidAmount: 10, status: InstallmentStatus.paid,
                    dueDate: ts(2026, 3, 10), paidDate: ts(2026, 3, 10),
                }),
                rawInstallment("b", {
                    amount: 25, paidAmount: 25, status: InstallmentStatus.paid,
                    dueDate: ts(2026, 3, 10), paidDate: ts(2026, 3, 10),
                }),
            ];

            await apply();

            const balances = repository.balances.get(CHECKING.id)!;
            expect(balances.size).toBe(1);
            expect(balances.get("2026-03-10")!.balance).toBeCloseTo(-35, 2);
        });

        it("ignora parcelas removed, pendentes e sem paidAmount (igual ao applyInstallmentBalance)", async () => {
            repository.installments = [
                rawInstallment("a-removida", {
                    amount: 100, paidAmount: 100, status: InstallmentStatus.removed,
                    dueDate: ts(2026, 3, 10), paidDate: ts(2026, 3, 10),
                }),
                rawInstallment("b-pendente", {
                    amount: 100, status: InstallmentStatus.pending, dueDate: ts(2026, 3, 11),
                }),
                // paidAmount ausente: o gatilho sai cedo (`!installment.paidAmount`).
                rawInstallment("c-sem-valor", {
                    amount: 100, status: InstallmentStatus.paid,
                    dueDate: ts(2026, 3, 12), paidDate: ts(2026, 3, 12),
                }),
                // paidAmount zero: idem.
                rawInstallment("d-zero", {
                    amount: 0, paidAmount: 0, status: InstallmentStatus.paid,
                    dueDate: ts(2026, 3, 13), paidDate: ts(2026, 3, 13),
                }),
            ];

            const report = await apply();

            expect(repository.balances.get(CHECKING.id)).toBeUndefined();
            expect(report.scanned.installmentsRemoved).toBe(1);
            expect(report.scanned.installments).toBe(3);
        });

        it("apaga documentos de saldo de contas que não têm mais parcelas pagas", async () => {
            repository.balances.set(CHECKING.id, new Map([["2026-03-10", { balance: -50 }]]));

            const report = await dryRun();

            expect(report.diff.balances.toDelete).toBe(1);
            expect(report.diff.balances.samples).toContain("apagar accounts/acc-checking/balance/2026-03-10");
            // dry-run não escreve.
            expect(repository.balances.get(CHECKING.id)!.size).toBe(1);
        });

        it("trata como residual (não divergência) o dia sem movimento que repete o saldo acumulado", async () => {
            repository.installments = [
                rawInstallment("a", {
                    amount: 100, paidAmount: 100, status: InstallmentStatus.paid,
                    dueDate: ts(2026, 3, 10), paidDate: ts(2026, 3, 10),
                }),
            ];
            // 12/03 é sobra de um pagamento estornado: carrega o mesmo saldo de 10/03.
            repository.balances.set(CHECKING.id, new Map([
                ["2026-03-10", { balance: -100 }],
                ["2026-03-12", { balance: -100 }],
            ]));

            // Sumários/XP inexistentes seriam criados; aqui só interessa o saldo.
            await apply();

            const report = await dryRun();

            expect(report.diff.balances.toDelete).toBe(0);
            expect(report.diff.balances.residual).toBe(1);
            // O residual não conta como divergência.
            expect(report.totalChanges).toBe(0);

            // Com pruneResidual o documento é apagado.
            const pruned = await service.rebuildWorkspace(WORKSPACE, {
                dryRun: false, now: new Date(2026, 2, 15, 12), pruneResidual: true,
            });
            expect(pruned.writesCommitted).toBe(1);
            expect([...repository.balances.get(CHECKING.id)!.keys()]).toEqual(["2026-03-10"]);
        });
    });

    describe("period_summaries", () => {
        beforeEach(() => {
            repository.installments = [
                // Pendente: entra só como planejado específico no dueDate.
                rawInstallment("a-pendente", {
                    amount: 200, status: InstallmentStatus.pending, dueDate: ts(2026, 3, 10),
                }),
                // Paga com valor diferente: planejado no dueDate, realizado no paidDate.
                rawInstallment("b-paga", {
                    amount: 100, paidAmount: 90, status: InstallmentStatus.paid,
                    dueDate: ts(2026, 3, 12), paidDate: ts(2026, 3, 13),
                }),
            ];
        });

        it("grava mês, ano e semana com os ids do getPeriodSummaryDocRef", async () => {
            await apply();

            const month = repository.summaries.get("2026-03")!;
            expect(month.year).toBe(2026);
            expect(month.month).toBe(3);
            expect(month.week).toBeNull();
            expect(month.runtimeType).toBe("month");
            expect(month.categories[CATEGORY.id].specificPlannedAmount).toBeCloseTo(300, 2);
            expect(month.categories[CATEGORY.id].actualAmount).toBeCloseTo(90, 2);
            expect(month.categories[CATEGORY.id].generalPlannedAmount).toBeCloseTo(0, 2);

            const year = repository.summaries.get("2026")!;
            expect(year.runtimeType).toBe("year");
            expect(year.month).toBeNull();
            expect(year.categories[CATEGORY.id].specificPlannedAmount).toBeCloseTo(300, 2);

            // 2026-03-10 e 2026-03-12 caem na semana que começa no domingo 08/03
            // (a 10ª semana contada a partir de 01/01, como em week.utils).
            const week = repository.summaries.get("2026-W10")!;
            expect(week.runtimeType).toBe("week");
            expect(week.week).toBe(10);
            expect(week.categories[CATEGORY.id].specificPlannedAmount).toBeCloseTo(300, 2);
            expect(week.categories[CATEGORY.id].actualAmount).toBeCloseTo(90, 2);
        });

        it("usa a categoria virtual de investimento nas transferências", async () => {
            repository.installments = [
                rawInstallment("t-aporte", {
                    amount: 500,
                    paidAmount: 500,
                    status: InstallmentStatus.paid,
                    type: OrderType.transfer,
                    category: undefined,
                    accounts: { [CHECKING.id]: "debt", [INVESTMENT.id]: "credit" },
                    accountIds: [CHECKING.id, INVESTMENT.id],
                    dueDate: ts(2026, 3, 10),
                    paidDate: ts(2026, 3, 10),
                }),
            ];

            await apply();

            const month = repository.summaries.get("2026-03")!;
            expect(Object.keys(month.categories)).toEqual(["virtual_investment_expense"]);
            expect(month.categories.virtual_investment_expense.actualAmount).toBeCloseTo(500, 2);
        });

        it("soma o generalPlannedAmount do category_planning na janela de 12 meses (só com rebuildPlanning)", async () => {
            repository.installments = [];
            repository.plannings = [{
                id: "plan-mercado",
                category: CATEGORY,
                amount: 620,
                startMonth: "2026-03",
                endMonth: "2026-04",
            }];

            await applyRebuildingPlanning();

            // Março e abril entram; maio (fora do endMonth) não.
            expect(repository.summaries.get("2026-03")!.categories[CATEGORY.id].generalPlannedAmount).toBeCloseTo(620, 2);
            expect(repository.summaries.get("2026-04")!.categories[CATEGORY.id].generalPlannedAmount).toBeCloseTo(620, 2);
            expect(repository.summaries.get("2026-05")).toBeUndefined();

            // Semana: proporção diária * 7 (março tem 31 dias).
            const week = repository.summaries.get("2026-W10")!;
            expect(week.categories[CATEGORY.id].generalPlannedAmount).toBeCloseTo((620 / 31) * 7, 6);
        });
    });

    describe("generalPlannedAmount (planejamento)", () => {
        /** Sumários "de produção": planejado acumulado por meses de cron. */
        const seedAccumulatedPlanning = () => {
            repository.summaries.set("2025-12", {
                year: 2025, month: 12, week: null, runtimeType: "month",
                categories: { [CATEGORY.id]: { generalPlannedAmount: 3000, specificPlannedAmount: 0, actualAmount: 0 } },
            });
            repository.summaries.set("2026-03", {
                year: 2026, month: 3, week: null, runtimeType: "month",
                categories: { [CATEGORY.id]: { generalPlannedAmount: 4000, specificPlannedAmount: 0, actualAmount: 0 } },
            });
            repository.plannings = [{
                id: "plan-antigo",
                category: CATEGORY,
                amount: 1000,
                startMonth: "2025-10",
                endMonth: "2026-12",
            }];
        };

        it("por padrão preserva o planejado gravado, inclusive de meses passados", async () => {
            seedAccumulatedPlanning();

            const report = await dryRun();

            expect(report.rebuildPlanning).toBe(false);
            expect(report.totalChanges).toBe(0);
            expect(report.diff.periodSummaries.generalPlannedChanges).toBe(0);
            expect(report.diff.periodSummaries.toUpdate).toBe(0);
            expect(report.diff.periodSummaries.toDelete).toBe(0);
        });

        it("preserva o planejado mesmo quando há parcelas no mesmo documento", async () => {
            seedAccumulatedPlanning();
            repository.installments = [
                rawInstallment("a", {
                    amount: 100, paidAmount: 100, status: InstallmentStatus.paid,
                    dueDate: ts(2026, 3, 10), paidDate: ts(2026, 3, 10),
                }),
            ];

            await apply();

            const month = repository.summaries.get("2026-03")!;
            expect(month.categories[CATEGORY.id].generalPlannedAmount).toBeCloseTo(4000, 2);
            expect(month.categories[CATEGORY.id].actualAmount).toBeCloseTo(100, 2);
            expect(repository.summaries.get("2025-12")!.categories[CATEGORY.id].generalPlannedAmount).toBeCloseTo(3000, 2);

            expect((await dryRun()).totalChanges).toBe(0);
        });

        it("com rebuildPlanning recalcula e zera o passado — contado à parte no diff", async () => {
            seedAccumulatedPlanning();

            const report = await service.rebuildWorkspace(WORKSPACE, { now: NOW, rebuildPlanning: true });

            expect(report.rebuildPlanning).toBe(true);
            expect(report.totalChanges).toBeGreaterThan(0);
            expect(report.diff.periodSummaries.generalPlannedChanges).toBeGreaterThan(0);

            await applyRebuildingPlanning();
            // F1.5: o recálculo cobre o PERÍODO INTEIRO do planejamento até o
            // horizonte (2025-10 a 2026-12), então dezembro/2025 não some — ele
            // passa a valer o `amount` do mês, sem a acumulação do regime antigo.
            expect(repository.summaries.get("2025-12")!.categories[CATEGORY.id].generalPlannedAmount).toBeCloseTo(1000, 2);
            expect(repository.summaries.get("2026-03")!.categories[CATEGORY.id].generalPlannedAmount).toBeCloseTo(1000, 2);
            // E o ano recebe a soma dos meses aplicados (out/nov/dez de 2025).
            expect(repository.summaries.get("2025")!.categories[CATEGORY.id].generalPlannedAmount).toBeCloseTo(3000, 2);
        });

        it("com rebuildPlanning o resultado independe do dia em que o job roda", async () => {
            seedAccumulatedPlanning();

            const hoje = await service.rebuildWorkspace(WORKSPACE, { now: NOW, rebuildPlanning: true });
            const amanha = await service.rebuildWorkspace(WORKSPACE, {
                now: new Date(NOW.getTime() + 24 * 60 * 60 * 1000),
                rebuildPlanning: true,
            });

            expect(amanha.diff.periodSummaries.samples).toEqual(hoje.diff.periodSummaries.samples);
            expect(amanha.totalChanges).toBe(hoje.totalChanges);
        });

        it("não toca em documento com id fora do padrão", async () => {
            repository.summaries.set("planejamento-legado", { foo: "bar" });

            const report = await dryRun();

            expect(report.diff.periodSummaries.toDelete).toBe(0);
            expect(report.diff.periodSummaries.residual).toBe(0);
            expect(repository.summaries.has("planejamento-legado")).toBe(true);
        });

        it("conta como residual a categoria zerada que sairia do documento", async () => {
            repository.installments = [
                rawInstallment("a", {
                    amount: 100, paidAmount: 100, status: InstallmentStatus.paid,
                    dueDate: ts(2026, 3, 10), paidDate: ts(2026, 3, 10),
                }),
            ];
            await apply();

            const month = repository.summaries.get("2026-03")!;
            month.categories["cat-fantasma"] = { generalPlannedAmount: 0, specificPlannedAmount: 0, actualAmount: 0 };

            const report = await dryRun();
            expect(report.diff.periodSummaries.toUpdate).toBe(0);
            expect(report.diff.periodSummaries.residual).toBe(1);
            expect(report.totalChanges).toBe(0);

            await service.rebuildWorkspace(WORKSPACE, { dryRun: false, now: NOW, pruneResidual: true });
            expect(repository.summaries.get("2026-03")!.categories["cat-fantasma"]).toBeUndefined();
        });
    });

    describe("categoria sem id (hotfix)", () => {
        /** O documento encontrado em produção: nome preenchido, id vazio. */
        const BROKEN_CATEGORY = { ...CATEGORY, id: "" };

        let warn: jest.SpyInstance;

        beforeEach(() => {
            warn = jest.spyOn(console, "warn").mockImplementation(() => undefined);
        });

        afterEach(() => {
            warn.mockRestore();
        });

        const brokenInstallment = (id: string) => rawInstallment(id, {
            amount: 100,
            paidAmount: 100,
            status: InstallmentStatus.paid,
            category: BROKEN_CATEGORY,
            dueDate: ts(2026, 3, 10),
            paidDate: ts(2026, 3, 10),
        });

        it("não quebra o --apply e não cria a chave de categoria vazia", async () => {
            repository.installments = [brokenInstallment("a-quebrada")];

            const report = await apply();

            // Nenhum period_summaries: a única categoria da parcela não tem id.
            // Era aqui que o SDK explodia com "Element at index 0 should not be
            // an empty string" ao montar `categories.""`.
            expect([...repository.summaries.keys()]).toEqual([]);
            expect(report.diff.periodSummaries.toCreate).toBe(0);

            // Saldo e XP não dependem de categoria: continuam contando.
            expect(repository.balances.get(CHECKING.id)!.get("2026-03-10")!.balance).toBeCloseTo(-100, 2);
            expect(repository.weeklyXp.get("2026-W10")).toMatchObject({ xp: 15 });
        });

        it("conta a parcela em installmentsWithoutCategory e avisa uma vez", async () => {
            repository.installments = [brokenInstallment("a-quebrada"), brokenInstallment("b-quebrada")];

            const report = await apply();

            expect(report.scanned.installments).toBe(2);
            expect(report.scanned.installmentsWithoutCategory).toBe(2);
            expect(warn).toHaveBeenCalledTimes(2);
            expect(warn.mock.calls[0][0]).toContain(`workspace=${WORKSPACE}`);
            expect(warn.mock.calls[0][0]).toContain("parcela=a-quebrada");
        });

        it("as parcelas boas do mesmo workspace continuam sendo somadas", async () => {
            repository.installments = [
                brokenInstallment("a-quebrada"),
                rawInstallment("b-boa", {
                    amount: 50, paidAmount: 50, status: InstallmentStatus.paid,
                    dueDate: ts(2026, 3, 12), paidDate: ts(2026, 3, 12),
                }),
            ];

            const report = await apply();

            const month = repository.summaries.get("2026-03")!;
            expect(Object.keys(month.categories)).toEqual([CATEGORY.id]);
            expect(month.categories[CATEGORY.id].actualAmount).toBeCloseTo(50, 2);
            expect(report.scanned.installmentsWithoutCategory).toBe(1);

            // O saldo soma as duas (a quebrada também move dinheiro).
            expect(repository.balances.get(CHECKING.id)!.get("2026-03-12")!.balance).toBeCloseTo(-150, 2);
        });

        it("continua idempotente: o segundo dry-run não vê diferença", async () => {
            repository.installments = [brokenInstallment("a-quebrada")];

            await apply();

            expect((await dryRun()).totalChanges).toBe(0);
        });

        it("planejamento com categoria sem id também fica fora do generalPlannedAmount", async () => {
            repository.installments = [];
            repository.plannings = [{
                id: "plan-quebrado",
                category: BROKEN_CATEGORY,
                amount: 620,
                startMonth: "2026-03",
                endMonth: "2026-03",
            }];

            await applyRebuildingPlanning();

            expect([...repository.summaries.keys()]).toEqual([]);
        });
    });

    describe("weekly_xp", () => {
        it("soma o calculateXp das parcelas pagas por semana", async () => {
            repository.installments = [
                // Pagou o valor previsto: 15 XP.
                rawInstallment("a", {
                    amount: 100, paidAmount: 100, status: InstallmentStatus.paid,
                    dueDate: ts(2026, 3, 10), paidDate: ts(2026, 3, 10),
                }),
                // Despesa paga a MENOS: 15 + 1.5.
                rawInstallment("b", {
                    amount: 100, paidAmount: 80, status: InstallmentStatus.paid,
                    dueDate: ts(2026, 3, 11), paidDate: ts(2026, 3, 11),
                }),
                // Despesa paga a MAIS, semana seguinte: 15 - 1.5.
                rawInstallment("c", {
                    amount: 100, paidAmount: 120, status: InstallmentStatus.paid,
                    dueDate: ts(2026, 3, 17), paidDate: ts(2026, 3, 17),
                }),
                // amount 0 => calculateXp devolve 0 => nenhum documento (o gatilho
                // também sai cedo quando o delta é zero).
                rawInstallment("d", {
                    amount: 0, paidAmount: 700, status: InstallmentStatus.settled,
                    dueDate: ts(2026, 4, 5), paidDate: ts(2026, 4, 5),
                }),
            ];

            await apply();

            expect([...repository.weeklyXp.keys()].sort()).toEqual(["2026-W10", "2026-W11"]);
            expect(repository.weeklyXp.get("2026-W10")).toMatchObject({ year: 2026, week: 10, xp: 31.5 });
            expect(repository.weeklyXp.get("2026-W11")).toMatchObject({ year: 2026, week: 11, xp: 13.5 });
        });
    });

    describe("dry-run, idempotência e correção", () => {
        beforeEach(() => {
            repository.installments = [
                rawInstallment("a", {
                    amount: 100, paidAmount: 100, status: InstallmentStatus.paid,
                    dueDate: ts(2026, 3, 10), paidDate: ts(2026, 3, 10),
                }),
                rawInstallment("b", {
                    amount: 250, status: InstallmentStatus.pending, dueDate: ts(2026, 4, 10),
                }),
            ];
            repository.plannings = [{
                id: "plan-mercado",
                category: CATEGORY,
                amount: 300,
                startMonth: "2026-01",
                endMonth: "2026-12",
            }];
            // Planejado já gravado pelos gatilhos: o rebuild padrão preserva.
            repository.summaries.set("2026-03", {
                year: 2026, month: 3, week: null, runtimeType: "month",
                categories: { [CATEGORY.id]: { generalPlannedAmount: 300, specificPlannedAmount: 0, actualAmount: 0 } },
            });
        });

        it("dry-run não escreve nada e relata o que mudaria", async () => {
            const report = await dryRun();

            expect(report.mode).toBe("dryRun");
            expect(report.writesCommitted).toBe(0);
            expect(report.totalChanges).toBeGreaterThan(0);
            expect(report.diff.balances.toCreate).toBe(1);
            expect(report.diff.weeklyXp.toCreate).toBe(1);
            expect(report.diff.periodSummaries.generalPlannedChanges).toBe(0);
            expect(repository.summaries.size).toBe(1);
            expect(repository.balances.size).toBe(0);
        });

        it("aplicar duas vezes seguidas não muda nada (idempotente)", async () => {
            const first = await apply();
            expect(first.writesCommitted).toBe(first.totalChanges);
            expect(first.writesCommitted).toBeGreaterThan(0);

            const second = await apply();
            expect(second.totalChanges).toBe(0);
            expect(second.writesCommitted).toBe(0);

            const third = await dryRun();
            expect(third.totalChanges).toBe(0);
        });

        it("corrige saldo e sumário corrompidos à mão e converge na execução seguinte", async () => {
            await apply();

            repository.balances.get(CHECKING.id)!.set("2026-03-10", { balance: -999 });
            repository.summaries.get("2026-03")!.categories[CATEGORY.id].actualAmount = 4242;
            repository.summaries.set("2019-07", {
                year: 2019, month: 7, week: null, runtimeType: "month",
                categories: { [CATEGORY.id]: { generalPlannedAmount: 0, specificPlannedAmount: 0, actualAmount: 77 } },
            });
            // Documento zerado: residual, não é divergência e não é apagado sem --prune-residual.
            repository.summaries.set("2019-08", {
                year: 2019, month: 8, week: null, runtimeType: "month",
                categories: { [CATEGORY.id]: { generalPlannedAmount: 0, specificPlannedAmount: 0, actualAmount: 0 } },
            });

            const diff = await dryRun();
            expect(diff.diff.balances.toUpdate).toBe(1);
            expect(diff.diff.periodSummaries.toUpdate).toBe(1);
            expect(diff.diff.periodSummaries.toDelete).toBe(1);
            expect(diff.diff.periodSummaries.residual).toBe(1);

            const applied = await apply();
            expect(applied.writesCommitted).toBe(applied.totalChanges);

            expect(repository.balances.get(CHECKING.id)!.get("2026-03-10")!.balance).toBeCloseTo(-100, 2);
            expect(repository.summaries.get("2026-03")!.categories[CATEGORY.id].actualAmount).toBeCloseTo(100, 2);
            expect(repository.summaries.has("2019-07")).toBe(false);
            expect(repository.summaries.has("2019-08")).toBe(true);

            expect((await dryRun()).totalChanges).toBe(0);
        });

        it("pagina a leitura de parcelas", async () => {
            await service.rebuildWorkspace(WORKSPACE, { pageSize: 1, now: new Date(2026, 2, 15, 12) });
            expect(repository.pagesRead).toBe(2);
        });
    });
});

describe("callable rebuildWorkspace (validação do payload)", () => {
    it("aceita apenas o workspaceId e o rebuildPlanning (prévia)", () => {
        expect(parseRebuildRequest({ workspaceId: "ws-1" })).toEqual({ workspaceId: "ws-1", rebuildPlanning: false });
        expect(parseRebuildRequest({ workspaceId: "ws-1", rebuildPlanning: true }))
            .toEqual({ workspaceId: "ws-1", rebuildPlanning: true });
    });

    it("rejeita `apply`: escrever é exclusivo do script operacional", () => {
        expect(() => parseRebuildRequest({ workspaceId: "ws-1", apply: true }))
            .toThrow(expect.objectContaining({ code: "invalid-argument" }));
        // Mesmo `apply: false` é rejeitado: a callable não tem modo de escrita.
        expect(() => parseRebuildRequest({ workspaceId: "ws-1", apply: false }))
            .toThrow(expect.objectContaining({ code: "invalid-argument" }));
    });

    it("rejeita `pruneResidual` e payload sem workspaceId", () => {
        expect(() => parseRebuildRequest({ workspaceId: "ws-1", pruneResidual: true }))
            .toThrow(expect.objectContaining({ code: "invalid-argument" }));
        expect(() => parseRebuildRequest({}))
            .toThrow(expect.objectContaining({ code: "invalid-argument" }));
        expect(() => parseRebuildRequest({ workspaceId: "ws-1", rebuildPlanning: "sim" }))
            .toThrow(expect.objectContaining({ code: "invalid-argument" }));
    });
});
