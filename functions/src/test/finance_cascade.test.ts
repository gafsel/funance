// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é usado nestes testes.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import {
    FinanceService,
    diffInstallmentForCascade,
    shiftDueDateByMonthDay,
} from "../features/finance/domain/services/finance.service";
import {
    InstallmentModel,
    InstallmentStatus,
    InstallmentType,
    OrderStatus,
    OrderType,
    ReplicationCascade,
} from "../features/finance/domain/models/finance.models";
import { CategoryModel, CategoryType } from "../features/workspace/domain/models/category.model";

const WORKSPACE_ID = "ws-1";
const ORDER_ID = "order-1";

const CATEGORY: CategoryModel = {
    id: "cat-casa",
    name: "Casa",
    icon: "home",
    color: "#000000",
    type: CategoryType.expense,
    isDeleted: false,
    allocation: "essential",
};

const OTHER_CATEGORY: CategoryModel = { ...CATEGORY, id: "cat-lazer", name: "Lazer" };

/** Parcela de vencimento `day/month/year` (meses 1-indexados para legibilidade). */
function makeInstallment(
    id: string,
    year: number,
    month: number,
    day: number,
    overrides: Partial<InstallmentModel> = {}
): InstallmentModel {
    const dueDate = new Date(year, month - 1, day, 12);
    const amount = overrides.amount ?? 100;

    return {
        id,
        orderId: ORDER_ID,
        amount,
        dueDate,
        description: "Aluguel",
        installmentType: InstallmentType.installment,
        status: InstallmentStatus.pending,
        type: OrderType.expense,
        accounts: { "acc-1": "debt" },
        accountIds: ["acc-1"],
        category: CATEGORY,
        referenceDate: dueDate,
        referenceAmount: amount,
        ...overrides,
    };
}

function makeRepository(installments: InstallmentModel[]) {
    return {
        getInstallmentsByOrderId: jest.fn(async () => installments.map((i) => ({ ...i }))),
        updateInstallment: jest.fn(async () => undefined),
        updateOrder: jest.fn(async () => undefined),
    } as any;
}

/** Ids das parcelas que receberam `updateInstallment`, na ordem das chamadas. */
function updatedIds(repository: any): string[] {
    return repository.updateInstallment.mock.calls.map((call: any[]) => call[1]);
}

function updateFor(repository: any, id: string): any {
    const call = repository.updateInstallment.mock.calls.find((c: any[]) => c[1] === id);
    return call ? call[2] : undefined;
}

/**
 * Ids das IRMÃS atualizadas. A parcela de origem sempre recebe uma escrita
 * própria no fim da cascata (o reset de `replicationCascade`), que não é
 * replicação e por isso fica de fora.
 */
function siblingUpdatedIds(repository: any, originId = "i3"): string[] {
    return updatedIds(repository).filter((id) => id !== originId);
}

/** A última escrita da cascata: o reset no documento de origem. */
function lastUpdate(repository: any): any[] {
    const calls = repository.updateInstallment.mock.calls;
    return calls[calls.length - 1];
}

describe("shiftDueDateByMonthDay", () => {
    it("aplica o novo DIA do mês, sem somar milissegundos (31 -> 28)", () => {
        const before = new Date(2025, 0, 31, 12); // 31/01
        const after = new Date(2025, 0, 28, 12); // 28/01
        const sibling = new Date(2025, 2, 31, 12); // 31/03

        const result = shiftDueDateByMonthDay(sibling, before, after);

        expect(result.getFullYear()).toBe(2025);
        expect(result.getMonth()).toBe(2); // continua em março
        expect(result.getDate()).toBe(28);
    });

    it("faz clamp no último dia do mês da irmã (dia 31 em fevereiro)", () => {
        const before = new Date(2025, 0, 15, 12);
        const after = new Date(2025, 0, 31, 12);
        const sibling = new Date(2025, 1, 15, 12); // fevereiro

        const result = shiftDueDateByMonthDay(sibling, before, after);

        expect(result.getMonth()).toBe(1);
        expect(result.getDate()).toBe(28); // 2025 não é bissexto
    });

    it("faz clamp para 29 em fevereiro de ano bissexto", () => {
        const result = shiftDueDateByMonthDay(
            new Date(2024, 1, 10, 12),
            new Date(2024, 0, 10, 12),
            new Date(2024, 0, 31, 12)
        );

        expect(result.getMonth()).toBe(1);
        expect(result.getDate()).toBe(29);
    });

    it("aplica o delta em MESES quando o vencimento muda de mês", () => {
        const before = new Date(2025, 0, 10, 12); // 10/01
        const after = new Date(2025, 1, 10, 12); // 10/02 (+1 mês)
        const sibling = new Date(2025, 5, 10, 12); // 10/06

        const result = shiftDueDateByMonthDay(sibling, before, after);

        expect(result.getFullYear()).toBe(2025);
        expect(result.getMonth()).toBe(6); // julho
        expect(result.getDate()).toBe(10);
    });

    it("atravessa a virada de ano ao aplicar o delta de meses", () => {
        const result = shiftDueDateByMonthDay(
            new Date(2025, 11, 5, 12), // 05/12/2025
            new Date(2025, 0, 5, 12),
            new Date(2025, 1, 5, 12) // +1 mês
        );

        expect(result.getFullYear()).toBe(2026);
        expect(result.getMonth()).toBe(0);
        expect(result.getDate()).toBe(5);
    });

    it("normaliza o horário para meio-dia (evita virada de dia por fuso)", () => {
        const result = shiftDueDateByMonthDay(
            new Date(2025, 2, 31, 23, 59),
            new Date(2025, 0, 31, 12),
            new Date(2025, 0, 28, 12)
        );
        expect(result.getHours()).toBe(12);
        expect(result.getMinutes()).toBe(0);
    });
});

describe("diffInstallmentForCascade", () => {
    it("não vê mudança replicável quando só o pagamento muda", () => {
        const before = makeInstallment("i1", 2025, 3, 10);
        const after = {
            ...before,
            status: InstallmentStatus.paid,
            paidAmount: 100,
            paidDate: new Date(2025, 2, 9, 12),
            xp: 15,
        };

        const changes = diffInstallmentForCascade(before, after);
        expect(changes.hasReplicableChange).toBe(false);
    });

    it("não vê mudança replicável quando só campos derivados mudam", () => {
        const before = makeInstallment("i1", 2025, 3, 10, { replicationCascade: ReplicationCascade.all });
        const after = { ...before, xp: 15, replicationCascade: ReplicationCascade.none };

        expect(diffInstallmentForCascade(before, after).hasReplicableChange).toBe(false);
    });

    it("detecta cada campo replicável", () => {
        const before = makeInstallment("i1", 2025, 3, 10);

        expect(diffInstallmentForCascade(before, { ...before, amount: 200 }).amount).toBe(true);
        expect(diffInstallmentForCascade(before, { ...before, dueDate: new Date(2025, 2, 20, 12) }).dueDate).toBe(true);
        expect(diffInstallmentForCascade(before, { ...before, description: "Outro" }).description).toBe(true);
        expect(diffInstallmentForCascade(before, { ...before, category: OTHER_CATEGORY }).category).toBe(true);
        expect(diffInstallmentForCascade(before, { ...before, accounts: { "acc-2": "debt" } }).accounts).toBe(true);
        expect(diffInstallmentForCascade(before, { ...before, type: OrderType.income }).type).toBe(true);
        expect(diffInstallmentForCascade(before, { ...before, status: InstallmentStatus.removed }).removed).toBe(true);
    });
});

describe("FinanceService.processInstallmentCascade (tabela none/all/future)", () => {
    /**
     * Série de 4 parcelas mensais de 100, vencendo dia 31 (com clamp em
     * fevereiro). A parcela de origem dos cenários é a de MARÇO (i3).
     */
    const buildSeries = (): InstallmentModel[] => [
        makeInstallment("i1", 2025, 1, 31),
        makeInstallment("i2", 2025, 2, 28),
        makeInstallment("i3", 2025, 3, 31),
        makeInstallment("i4", 2025, 4, 30),
    ];

    const origin = () => buildSeries()[2]; // i3, 31/03

    describe("cascade: none", () => {
        it("não lê parcelas nem toca a order numa mudança de valor", async () => {
            const repository = makeRepository(buildSeries());
            const service = new FinanceService(repository);

            const before = origin();
            const after = { ...before, amount: 250, replicationCascade: ReplicationCascade.none };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            expect(repository.getInstallmentsByOrderId).not.toHaveBeenCalled();
            expect(repository.updateInstallment).not.toHaveBeenCalled();
            expect(repository.updateOrder).not.toHaveBeenCalled();
        });

        it("não cancela a order quando ainda restam parcelas vivas", async () => {
            const series = buildSeries();
            series[2] = { ...series[2], status: InstallmentStatus.removed };
            const repository = makeRepository(series);
            const service = new FinanceService(repository);

            const before = origin();
            const after = { ...before, status: InstallmentStatus.removed };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            expect(repository.updateOrder).not.toHaveBeenCalled();
        });

        it("cancela a order quando a remoção esvazia a série (removidas uma a uma)", async () => {
            const series = buildSeries().map((i) => ({ ...i, status: InstallmentStatus.removed }));
            // i3 ainda não está removida no Firestore: é a escrita em curso.
            series[2] = { ...series[2], status: InstallmentStatus.pending };

            const repository = makeRepository(series);
            const service = new FinanceService(repository);

            const before = origin();
            const after = { ...before, status: InstallmentStatus.removed };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            expect(repository.updateInstallment).not.toHaveBeenCalled();
            expect(repository.updateOrder).toHaveBeenCalledWith(WORKSPACE_ID, ORDER_ID, {
                amount: 0,
                status: OrderStatus.cancelled,
            });
        });
    });

    describe("cascade: all", () => {
        it("replica valor para TODAS as irmãs e recalcula o total da order", async () => {
            const repository = makeRepository(buildSeries());
            const service = new FinanceService(repository);

            const before = origin();
            const after = { ...before, amount: 250, replicationCascade: ReplicationCascade.all };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            expect(siblingUpdatedIds(repository).sort()).toEqual(["i1", "i2", "i4"]);
            expect(updateFor(repository, "i1")).toMatchObject({
                amount: 250,
                referenceAmount: 250,
                replicationCascade: ReplicationCascade.none,
            });

            // 3 irmãs a 250 + a própria (250) = 1000
            expect(repository.updateOrder).toHaveBeenCalledWith(WORKSPACE_ID, ORDER_ID, { amount: 1000 });
        });

        it("replica categoria sem tocar em valor nem em dueDay da order", async () => {
            const repository = makeRepository(buildSeries());
            const service = new FinanceService(repository);

            const before = origin();
            const after = { ...before, category: OTHER_CATEGORY, replicationCascade: ReplicationCascade.all };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            expect(updateFor(repository, "i1")).toEqual({
                category: OTHER_CATEGORY,
                replicationCascade: ReplicationCascade.none,
            });
            expect(repository.updateOrder).toHaveBeenCalledWith(WORKSPACE_ID, ORDER_ID, {
                category: OTHER_CATEGORY,
            });
        });

        it("muda o dia de vencimento 31 -> 28 com clamp por mês, sem somar milissegundos", async () => {
            const repository = makeRepository(buildSeries());
            const service = new FinanceService(repository);

            const before = origin(); // 31/03
            const after = { ...before, dueDate: new Date(2025, 2, 28, 12), replicationCascade: ReplicationCascade.all };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            expect(updateFor(repository, "i1").dueDate).toEqual(new Date(2025, 0, 28, 12));
            expect(updateFor(repository, "i2").dueDate).toEqual(new Date(2025, 1, 28, 12));
            expect(updateFor(repository, "i4").dueDate).toEqual(new Date(2025, 3, 28, 12));
            // referenceDate acompanha em parcelas não pagas
            expect(updateFor(repository, "i4").referenceDate).toEqual(new Date(2025, 3, 28, 12));

            expect(repository.updateOrder).toHaveBeenCalledWith(WORKSPACE_ID, ORDER_ID, { dueDay: 28 });
        });

        it("remove todas as irmãs e cancela a order", async () => {
            const repository = makeRepository(buildSeries());
            const service = new FinanceService(repository);

            const before = origin();
            const after = { ...before, status: InstallmentStatus.removed, replicationCascade: ReplicationCascade.all };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            expect(siblingUpdatedIds(repository).sort()).toEqual(["i1", "i2", "i4"]);
            expect(updateFor(repository, "i1").status).toBe(InstallmentStatus.removed);
            expect(repository.updateOrder).toHaveBeenCalledWith(WORKSPACE_ID, ORDER_ID, {
                amount: 0,
                status: OrderStatus.cancelled,
            });
        });

        it("ignora a cascata quando nenhum campo replicável mudou (só xp/cascata)", async () => {
            const repository = makeRepository(buildSeries());
            const service = new FinanceService(repository);

            const before = { ...origin(), replicationCascade: ReplicationCascade.all };
            const after = { ...before, xp: 15 };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            expect(repository.getInstallmentsByOrderId).not.toHaveBeenCalled();
            expect(repository.updateOrder).not.toHaveBeenCalled();
        });

        it("não replica valor para parcelas pagas e soma o referenceAmount delas no total", async () => {
            const series = buildSeries();
            series[0] = {
                ...series[0],
                status: InstallmentStatus.paid,
                amount: 0,
                paidAmount: 100,
                referenceAmount: 100,
            };

            const repository = makeRepository(series);
            const service = new FinanceService(repository);

            const before = origin();
            const after = { ...before, amount: 250, replicationCascade: ReplicationCascade.all };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            // A paga não recebe o novo planejado...
            expect(updateFor(repository, "i1")).toBeUndefined();
            // ...e entra no total pelo que realmente custou (100 + 3x250).
            expect(repository.updateOrder).toHaveBeenCalledWith(WORKSPACE_ID, ORDER_ID, { amount: 850 });
        });
    });

    describe("cascade: future", () => {
        it("seleciona as irmãs por DATA (>= vencimento da origem), não por índice", async () => {
            // Série fora de ordem no Firestore: a ordenação é por data.
            const series = [
                makeInstallment("i4", 2025, 4, 30),
                makeInstallment("i2", 2025, 2, 28),
                makeInstallment("i3", 2025, 3, 31),
                makeInstallment("i1", 2025, 1, 31),
            ];
            const repository = makeRepository(series);
            const service = new FinanceService(repository);

            const before = makeInstallment("i3", 2025, 3, 31);
            const after = { ...before, amount: 250, replicationCascade: ReplicationCascade.future };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            expect(siblingUpdatedIds(repository)).toEqual(["i4"]);
            // i1 (100) + i2 (100) + i3 (250) + i4 (250)
            expect(repository.updateOrder).toHaveBeenCalledWith(WORKSPACE_ID, ORDER_ID, { amount: 700 });
        });

        it("inclui irmã que vence no MESMO dia da origem", async () => {
            const series = [
                makeInstallment("i1", 2025, 3, 31),
                makeInstallment("i2", 2025, 3, 31),
                makeInstallment("i3", 2025, 4, 30),
            ];
            const repository = makeRepository(series);
            const service = new FinanceService(repository);

            const before = series[0];
            const after = { ...before, description: "Novo nome", replicationCascade: ReplicationCascade.future };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            expect(siblingUpdatedIds(repository, "i1").sort()).toEqual(["i2", "i3"]);
        });

        it("remove só as futuras e NÃO cancela a order (restam parcelas vivas)", async () => {
            const repository = makeRepository(buildSeries());
            const service = new FinanceService(repository);

            const before = origin();
            const after = { ...before, status: InstallmentStatus.removed, replicationCascade: ReplicationCascade.future };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            expect(siblingUpdatedIds(repository)).toEqual(["i4"]);
            const orderUpdate = repository.updateOrder.mock.calls[0][2];
            expect(orderUpdate.status).toBeUndefined();
            expect(orderUpdate.amount).toBe(200); // i1 + i2
        });

        it("desloca o dia só das futuras, com clamp", async () => {
            const repository = makeRepository(buildSeries());
            const service = new FinanceService(repository);

            const before = origin(); // 31/03
            const after = { ...before, dueDate: new Date(2025, 2, 28, 12), replicationCascade: ReplicationCascade.future };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            expect(siblingUpdatedIds(repository)).toEqual(["i4"]);
            expect(updateFor(repository, "i4").dueDate).toEqual(new Date(2025, 3, 28, 12));
            expect(repository.updateOrder).toHaveBeenCalledWith(WORKSPACE_ID, ORDER_ID, { dueDay: 28 });
        });

        it("cancela a order quando a remoção das futuras esvazia a série", async () => {
            const series = buildSeries();
            series[0] = { ...series[0], status: InstallmentStatus.removed };
            series[1] = { ...series[1], status: InstallmentStatus.removed };

            const repository = makeRepository(series);
            const service = new FinanceService(repository);

            const before = origin();
            const after = { ...before, status: InstallmentStatus.removed, replicationCascade: ReplicationCascade.future };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            expect(repository.updateOrder).toHaveBeenCalledWith(WORKSPACE_ID, ORDER_ID, {
                amount: 0,
                status: OrderStatus.cancelled,
            });
        });

        it("não replica para irmã já removida", async () => {
            const series = buildSeries();
            series[3] = { ...series[3], status: InstallmentStatus.removed };

            const repository = makeRepository(series);
            const service = new FinanceService(repository);

            const before = origin();
            const after = { ...before, amount: 250, replicationCascade: ReplicationCascade.future };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            expect(siblingUpdatedIds(repository)).toEqual([]);
            // i1 + i2 + i3 (a removida i4 fica de fora)
            expect(repository.updateOrder).toHaveBeenCalledWith(WORKSPACE_ID, ORDER_ID, { amount: 450 });
        });
    });

    describe("reset da cascata no documento de origem", () => {
        it("zera a cascata na parcela de origem ao fim da cascata, numa escrita própria", async () => {
            const repository = makeRepository(buildSeries());
            const service = new FinanceService(repository);

            const before = origin();
            const after = { ...before, category: OTHER_CATEGORY, replicationCascade: ReplicationCascade.all };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            // Sem pagamento não há escrita de xp: é esta que tira a cascata do
            // documento de origem. Ela é a última, depois das irmãs e da order.
            expect(lastUpdate(repository)).toEqual([
                WORKSPACE_ID,
                "i3",
                { replicationCascade: ReplicationCascade.none },
            ]);
            expect(updateFor(repository, "i3")).toEqual({ replicationCascade: ReplicationCascade.none });
        });

        it("zera a cascata mesmo quando a order não precisa de update", async () => {
            // Uma irmã só, já removida: nada a replicar na order.
            const series = [
                makeInstallment("i3", 2025, 3, 31),
                makeInstallment("i4", 2025, 4, 30, { status: InstallmentStatus.removed }),
            ];
            const repository = makeRepository(series);
            const service = new FinanceService(repository);

            const before = series[0];
            const after = { ...before, description: "Outro nome", replicationCascade: ReplicationCascade.future };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            expect(siblingUpdatedIds(repository)).toEqual([]);
            expect(updateFor(repository, "i3")).toEqual({ replicationCascade: ReplicationCascade.none });
        });

        it("não escreve nada quando a cascata é none", async () => {
            const repository = makeRepository(buildSeries());
            const service = new FinanceService(repository);

            const before = origin();
            const after = { ...before, amount: 250, replicationCascade: ReplicationCascade.none };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            expect(repository.updateInstallment).not.toHaveBeenCalled();
        });

        it("não escreve nada quando nenhum campo replicável mudou", async () => {
            const repository = makeRepository(buildSeries());
            const service = new FinanceService(repository);

            const before = { ...origin(), replicationCascade: ReplicationCascade.all };
            const after = { ...before, xp: 15 };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            expect(repository.updateInstallment).not.toHaveBeenCalled();
        });
    });

    describe("mudança de vencimento em série longa (regra congelada)", () => {
        /** 12 parcelas mensais vencendo dia 31, de jan/2026 a dez/2026. */
        const buildYearSeries = (): InstallmentModel[] => {
            const series: InstallmentModel[] = [];
            for (let month = 1; month <= 12; month++) {
                const lastDay = new Date(2026, month, 0).getDate();
                series.push(makeInstallment(`p${month}`, 2026, month, Math.min(31, lastDay)));
            }
            return series;
        };

        it("31/01 -> 28/02 com future desloca a série inteira em 1 mês, dia 28", async () => {
            const series = buildYearSeries();
            const repository = makeRepository(series);
            const service = new FinanceService(repository);

            const before = series[0]; // 31/01/2026
            const after = {
                ...before,
                dueDate: new Date(2026, 1, 28, 12), // 28/02/2026
                replicationCascade: ReplicationCascade.future,
            };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            // Todas as 11 irmãs vencem depois de 28/02/2026, então entram.
            expect(siblingUpdatedIds(repository, "p1")).toEqual([
                "p2", "p3", "p4", "p5", "p6", "p7", "p8", "p9", "p10", "p11", "p12",
            ]);

            // Regra ATUAL congelada: mudar de 31/01 para 28/02 é lido como
            // "+1 mês, dia 28" — a série inteira anda um mês para a frente, e a
            // 12ª parcela sai de 31/12/2026 para 28/01/2027.
            expect(updateFor(repository, "p2").dueDate).toEqual(new Date(2026, 2, 28, 12));
            expect(updateFor(repository, "p3").dueDate).toEqual(new Date(2026, 3, 28, 12));
            expect(updateFor(repository, "p11").dueDate).toEqual(new Date(2026, 11, 28, 12));
            expect(updateFor(repository, "p12").dueDate).toEqual(new Date(2027, 0, 28, 12));

            expect(repository.updateOrder).toHaveBeenCalledWith(WORKSPACE_ID, ORDER_ID, { dueDay: 28 });
        });

        it("mover para TRÁS (31/03 -> 01/01) puxa as irmãs de jan e fev para o future", async () => {
            const series = buildYearSeries();
            const repository = makeRepository(series);
            const service = new FinanceService(repository);

            const before = series[2]; // 31/03/2026
            const after = {
                ...before,
                dueDate: new Date(2026, 0, 1, 12), // 01/01/2026
                replicationCascade: ReplicationCascade.future,
            };

            await service.processInstallmentCascade(WORKSPACE_ID, before, after);

            // `future` é por data: com o vencimento recuado para 01/01, as
            // irmãs de janeiro (31/01) e fevereiro (28/02) passam a ser
            // "futuras" e também são deslocadas.
            expect(siblingUpdatedIds(repository, "p3")).toEqual([
                "p1", "p2", "p4", "p5", "p6", "p7", "p8", "p9", "p10", "p11", "p12",
            ]);

            // Delta de -2 meses, dia 1: a série anda dois meses para trás e as
            // duas primeiras parcelas caem no ano anterior.
            expect(updateFor(repository, "p1").dueDate).toEqual(new Date(2025, 10, 1, 12));
            expect(updateFor(repository, "p2").dueDate).toEqual(new Date(2025, 11, 1, 12));
            expect(updateFor(repository, "p4").dueDate).toEqual(new Date(2026, 1, 1, 12));
            expect(updateFor(repository, "p12").dueDate).toEqual(new Date(2026, 9, 1, 12));

            expect(repository.updateOrder).toHaveBeenCalledWith(WORKSPACE_ID, ORDER_ID, { dueDay: 1 });
        });
    });

    it("um pagamento com cascata pendente não reescreve o dueDay da order", async () => {
        const repository = makeRepository(buildSeries());
        const service = new FinanceService(repository);

        const before = origin(); // vence 31/03
        const after = {
            ...before,
            status: InstallmentStatus.paid,
            paidAmount: 100,
            paidDate: new Date(2025, 2, 5, 12), // pago dia 5
            description: "Aluguel renegociado",
            replicationCascade: ReplicationCascade.all,
        };

        await service.processInstallmentCascade(WORKSPACE_ID, before, after);

        const orderUpdate = repository.updateOrder.mock.calls[0][2];
        expect(orderUpdate.dueDay).toBeUndefined();
        expect(orderUpdate.description).toBe("Aluguel renegociado");
    });
});
