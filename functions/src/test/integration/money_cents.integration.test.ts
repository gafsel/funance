// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import {
    MONEY_CENTS_CHECKPOINT_FIELD,
    migrateMoneyCents,
    commitPatches, verdict } from "../../scripts/migrate_money_cents";
import { applyCentsPatch } from "../../core/utils/money_cents";
import { MONEY_CENTS_FIELDS } from "../../features/finance/domain/models/finance.models";
import { FinanceRepositoryImpl } from "../../features/finance/data/repositories/finance.repository.impl";
import { InvoiceService } from "../../features/finance/domain/services/invoice.service";
import { CategoryModel, CategoryType } from "../../features/workspace/domain/models/category.model";

const CATEGORY: CategoryModel = {
    id: "cat-mercado",
    name: "Mercado",
    icon: "shopping_cart",
    color: "#42A5F5",
    type: CategoryType.expense,
    isDeleted: false,
    allocation: "essential",
};

/** Workspace mínimo com UMA order — o bastante para o verificador ter o que dizer. */
async function seedSimple(workspaceId: string): Promise<void> {
    await firestore.collection("workspaces").doc(workspaceId)
        .set({ name: "Casa", type: "personal", members: ["u1"] });
    await firestore.collection(`workspaces/${workspaceId}/orders`).doc("o1")
        .set({ amount: 1000, description: "x" });
}

/**
 * F1.10, etapa B — a migração dos espelhos inteiros contra o emulador de
 * verdade.
 *
 * Os testes unitários provam a REGRA (que `*Cents` faltam num documento); este
 * prova o EFEITO: os campos aparecem no Firestore, o `double` não é tocado, uma
 * segunda passada não escreve nada, o `--verify` acusa a divergência que a
 * migração acabou de consertar e o checkpoint permite retomar.
 */

let firestore: admin.firestore.Firestore;

const workspaces: string[] = [];

function newWorkspace(label: string): string {
    const workspaceId = `ws-cents-${label}-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    workspaces.push(workspaceId);
    return workspaceId;
}

/** Silencia o log do script; os testes olham o Firestore, não o stdout. */
const quiet = () => undefined;

async function deleteCollection(path: string): Promise<void> {
    const snapshot = await firestore.collection(path).get();
    await Promise.all(snapshot.docs.map((doc) => doc.ref.delete()));
}

beforeAll(() => {
    if (!admin.apps.length) {
        admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
    }
    // Mesma configuração da produção: gravar `undefined` LANÇA (F1.11).
    admin.firestore().settings({ ignoreUndefinedProperties: false });
    firestore = admin.firestore();
});

afterAll(async () => {
    for (const workspaceId of workspaces) {
        for (const name of ["orders", "installments", "goals", "category_planning", "period_summaries"]) {
            await deleteCollection(`workspaces/${workspaceId}/${name}`);
        }
        const accounts = await firestore.collection(`workspaces/${workspaceId}/accounts`).listDocuments();
        for (const account of accounts) {
            await deleteCollection(`${account.path}/balance`);
            await account.delete();
        }
        await firestore.collection("workspaces").doc(workspaceId).delete();
    }
    await firestore.collection("config").doc("cron_checkpoints")
        .set({ [MONEY_CENTS_CHECKPOINT_FIELD]: null }, { merge: true });
});

describe("migrate_money_cents — contra o emulador", () => {
    async function seed(workspaceId: string): Promise<void> {
        const workspace = firestore.collection("workspaces").doc(workspaceId);
        await workspace.set({ name: "Casa", type: "personal", members: ["u1"] });

        // Tudo aqui é o formato ANTERIOR à etapa B: só o `double`.
        await workspace.collection("orders").doc("o1").set({
            amount: 502.4,
            description: "Notebook",
            dueDay: 10,
            startMonth: "2026-03",
            installmentType: "installment",
            status: "active",
            type: "expense",
        });

        await workspace.collection("installments").doc("i1").set({
            orderId: "o1",
            amount: 50.24,
            referenceAmount: 50.24,
            description: "Notebook 1/10",
            status: "pending",
            type: "expense",
            installmentType: "installment",
            dueDate: admin.firestore.Timestamp.fromDate(new Date("2026-03-10T15:00:00.000Z")),
            referenceDate: admin.firestore.Timestamp.fromDate(new Date("2026-03-10T15:00:00.000Z")),
            paidDate: null,
        });

        await workspace.collection("installments").doc("i2").set({
            orderId: "o1",
            amount: 0,
            paidAmount: 1.005,
            referenceAmount: 1.005,
            description: "Cafezinho",
            status: "paid",
            type: "expense",
            installmentType: "single",
            dueDate: admin.firestore.Timestamp.fromDate(new Date("2026-03-11T15:00:00.000Z")),
            referenceDate: admin.firestore.Timestamp.fromDate(new Date("2026-03-11T15:00:00.000Z")),
            paidDate: admin.firestore.Timestamp.fromDate(new Date("2026-03-11T15:00:00.000Z")),
        });

        await workspace.collection("accounts").doc("a1").set({
            name: "Conta",
            runtimeType: "creditCard",
            isDeleted: false,
            initialBalance: -19058.9,
            limit: 5000,
            nextInvoice: { amount: 350.5, orderId: "invoice-a1-2026-03-10", status: "pending" },
        });

        await workspace.collection("accounts").doc("a1").collection("balance").doc("2026-03-10").set({
            dateKey: "2026-03-10",
            delta: -167.47,
            balance: -19226.37,
        });

        await workspace.collection("goals").doc("g1").set({
            name: "Reserva",
            runtimeType: "saveMoney",
            targetAmount: 10000,
            currentAmount: 0.1 + 0.2,
            isDeleted: false,
        });

        await workspace.collection("category_planning").doc("p1").set({
            category: { id: "cat-1", name: "Mercado" },
            amount: 1200,
            startMonth: "2026-01",
            endMonth: "2026-12",
            appliedAmount: 1200,
        });

        await workspace.collection("period_summaries").doc("2026-03").set({
            year: 2026,
            month: 3,
            week: null,
            runtimeType: "month",
            categories: {
                "cat-1": { generalPlannedAmount: 1200, specificPlannedAmount: 50.24, actualAmount: 0.30000000000000004 },
            },
        });
    }

    it("preenche os *Cents de todas as coleções sem tocar no double", async () => {
        const workspaceId = newWorkspace("apply");
        await seed(workspaceId);

        const dryRun = await migrateMoneyCents(firestore, { dryRun: true, workspaceId }, quiet);
        expect(dryRun.writesCommitted).toBe(0);
        expect(dryRun.collections.installments.migrated).toBe(2);

        // O dry-run não escreveu nada.
        const beforeApply = await firestore.doc(`workspaces/${workspaceId}/orders/o1`).get();
        expect(beforeApply.data()?.amountCents).toBeUndefined();

        const applied = await migrateMoneyCents(firestore, { dryRun: false, workspaceId }, quiet);
        expect(applied.writesCommitted).toBeGreaterThan(0);
        expect(applied.failed).toBe(0);

        const workspace = firestore.collection("workspaces").doc(workspaceId);

        const order = (await workspace.collection("orders").doc("o1").get()).data()!;
        expect(order.amountCents).toBe(50240);
        expect(order.amount).toBe(502.4); // o double NÃO foi tocado

        const i1 = (await workspace.collection("installments").doc("i1").get()).data()!;
        expect(i1.amountCents).toBe(5024);
        expect(i1.referenceAmountCents).toBe(5024);
        // Parcela não paga: ausente continua ausente.
        expect(i1.paidAmountCents).toBeUndefined();

        const i2 = (await workspace.collection("installments").doc("i2").get()).data()!;
        // 1.005 -> 101 centavos. `Math.round(1.005 * 100)` daria 100.
        expect(i2.paidAmountCents).toBe(101);
        expect(i2.amountCents).toBe(0);

        const account = (await workspace.collection("accounts").doc("a1").get()).data()!;
        expect(account.initialBalanceCents).toBe(-1905890);
        expect(account.limitCents).toBe(500000);
        expect(account.nextInvoice.amountCents).toBe(35050);
        // O merge preservou o resto do resumo.
        expect(account.nextInvoice.orderId).toBe("invoice-a1-2026-03-10");
        expect(account.nextInvoice.status).toBe("pending");

        const balance = (await workspace.collection("accounts").doc("a1")
            .collection("balance").doc("2026-03-10").get()).data()!;
        expect(balance.deltaCents).toBe(-16747);
        expect(balance.balanceCents).toBe(-1922637);

        const goal = (await workspace.collection("goals").doc("g1").get()).data()!;
        expect(goal.targetAmountCents).toBe(1000000);
        // 0.1 + 0.2 = 0.30000000000000004 -> 30 centavos exatos.
        expect(goal.currentAmountCents).toBe(30);

        const planning = (await workspace.collection("category_planning").doc("p1").get()).data()!;
        expect(planning.amountCents).toBe(120000);
        expect(planning.appliedAmountCents).toBe(120000);

        const summary = (await workspace.collection("period_summaries").doc("2026-03").get()).data()!;
        expect(summary.categories["cat-1"]).toMatchObject({
            generalPlannedAmount: 1200,
            generalPlannedAmountCents: 120000,
            specificPlannedAmountCents: 5024,
            actualAmountCents: 30,
        });
        // O merge não apagou os metadados do documento.
        expect(summary.runtimeType).toBe("month");
        expect(summary.year).toBe(2026);
    });

    it("é IDEMPOTENTE: a segunda passada não escreve nada", async () => {
        const workspaceId = newWorkspace("idem");
        await seed(workspaceId);

        await migrateMoneyCents(firestore, { dryRun: false, workspaceId }, quiet);
        const second = await migrateMoneyCents(firestore, { dryRun: false, workspaceId }, quiet);

        expect(second.writesCommitted).toBe(0);
        for (const tally of Object.values(second.collections)) {
            expect(tally.migrated).toBe(0);
        }
    });

    it("--verify acusa a divergência e fica em silêncio depois do conserto", async () => {
        const workspaceId = newWorkspace("verify");
        await seed(workspaceId);

        // Um inteiro plantado errado: R$ 502,40 no double, 1 centavo no inteiro.
        await firestore.doc(`workspaces/${workspaceId}/orders/o1`).update({ amountCents: 1 });

        const before = await migrateMoneyCents(firestore, { dryRun: true, verify: true, workspaceId }, quiet);
        expect(before.collections.orders.divergent).toBe(1);
        expect(before.collections.orders.divergentSamples[0])
            .toBe(`workspaces/${workspaceId}/orders/o1`);
        // As duas somas discordam — é o sinal que o dono procura no relatório.
        expect(before.collections.orders.sumFromDoubleCents).toBe(50240);
        expect(before.collections.orders.sumFromCents).toBe(1);
        expect(before.writesCommitted).toBe(0);

        await migrateMoneyCents(firestore, { dryRun: false, workspaceId }, quiet);

        const after = await migrateMoneyCents(firestore, { dryRun: true, verify: true, workspaceId }, quiet);
        const totalDivergent = Object.values(after.collections).reduce((acc, t) => acc + t.divergent, 0);
        expect(totalDivergent).toBe(0);
        // Depois da migração as duas somas batem em toda coleção.
        for (const tally of Object.values(after.collections)) {
            expect(tally.sumFromCents).toBe(tally.sumFromDoubleCents);
        }
    });

    it("um inteiro pendurado sem o double correspondente é apagado", async () => {
        const workspaceId = newWorkspace("orfao");
        await seed(workspaceId);

        // `i1` não é paga: um `paidAmountCents` ali é resíduo.
        await firestore.doc(`workspaces/${workspaceId}/installments/i1`).update({ paidAmountCents: 999 });

        await migrateMoneyCents(firestore, { dryRun: false, workspaceId }, quiet);

        const i1 = (await firestore.doc(`workspaces/${workspaceId}/installments/i1`).get()).data()!;
        expect(i1.paidAmountCents).toBeUndefined();
    });

    it("grava o checkpoint na varredura da base e o zera ao terminar", async () => {
        const workspaceId = newWorkspace("checkpoint");
        await seed(workspaceId);

        await migrateMoneyCents(firestore, { dryRun: false, restart: true }, quiet);

        const checkpoint = (await firestore.doc("config/cron_checkpoints").get()).data();
        // Varredura completa: o campo é zerado para a próxima execução começar
        // do início, em vez de ficar presa no último workspace.
        expect(checkpoint?.[MONEY_CENTS_CHECKPOINT_FIELD]).toBeNull();
    });
});

describe("passo derivado do gatilho — contra o emulador", () => {
    it("completa os *Cents da parcela que o cliente gravou e não reescreve depois", async () => {
        const workspaceId = newWorkspace("derivado");
        const ref = firestore.collection(`workspaces/${workspaceId}/installments`).doc("i-derivada");

        await ref.set({
            orderId: "o1",
            amount: 0.1,
            referenceAmount: 0.1,
            description: "Do app",
            status: "pending",
            type: "expense",
            installmentType: "single",
            dueDate: admin.firestore.Timestamp.fromDate(new Date("2026-03-10T15:00:00.000Z")),
            referenceDate: admin.firestore.Timestamp.fromDate(new Date("2026-03-10T15:00:00.000Z")),
            paidDate: null,
        });

        const first = await applyCentsPatch(ref, (await ref.get()).data(), MONEY_CENTS_FIELDS.installments, "teste");
        expect(first).toBe(true);
        expect((await ref.get()).data()?.amountCents).toBe(10);

        // Segunda passada: nada a mudar. É esta resposta `false` que impede o
        // gatilho de se realimentar.
        const second = await applyCentsPatch(ref, (await ref.get()).data(), MONEY_CENTS_FIELDS.installments, "teste");
        expect(second).toBe(false);
    });

    it("não RESSUSCITA um documento apagado entre o evento e a escrita", async () => {
        const workspaceId = newWorkspace("fantasma");
        const ref = firestore.collection(`workspaces/${workspaceId}/installments`).doc("i-apagada");

        // O documento nunca existiu: `update` responde NOT_FOUND e o passo sai
        // calado, em vez de criar uma parcela com um único campo.
        const written = await applyCentsPatch(ref, { amount: 10 }, MONEY_CENTS_FIELDS.installments, "teste");

        expect(written).toBe(false);
        expect((await ref.get()).exists).toBe(false);
    });
});

describe("ALTO 1 — dinheiro nunca é incrementado sobre um *Cents ausente", () => {
    /**
     * O defeito: `FieldValue.increment` num campo que NÃO EXISTE começa do
     * zero. Num documento anterior à migração, com `actualAmount: 1000` e sem
     * `actualAmountCents`, um delta de +25 produzia `actualAmount: 1025`
     * (certo) e `actualAmountCents: 2500` (errado) — e é o inteiro que manda.
     */
    it("period_summaries: o total parte do DOUBLE gravado, não de zero", async () => {
        const workspaceId = newWorkspace("summary-seed");
        const repository = new FinanceRepositoryImpl();
        const ref = firestore.doc(`workspaces/${workspaceId}/period_summaries/2026-03`);

        // Documento no formato ANTERIOR à etapa B: só o `double`.
        await ref.set({
            year: 2026,
            month: 3,
            week: null,
            runtimeType: "month",
            categories: { [CATEGORY.id]: { actualAmount: 1000, specificPlannedAmount: 500 } },
        });

        await repository.updatePeriodSummary(workspaceId, 2026, 3, CATEGORY, { actualDelta: 25 });

        const totals = (await ref.get()).data()!.categories[CATEGORY.id];
        expect(totals.actualAmount).toBe(1025);
        // Sem a correção este número era 2500.
        expect(totals.actualAmountCents).toBe(102500);
        // Os totais que o delta não tocou também ficam coerentes.
        expect(totals.specificPlannedAmount).toBe(500);
        expect(totals.specificPlannedAmountCents).toBe(50000);
    });

    it("period_summaries: a segunda escrita soma sobre o inteiro, sem escorregar", async () => {
        const workspaceId = newWorkspace("summary-acc");
        const repository = new FinanceRepositoryImpl();
        const ref = firestore.doc(`workspaces/${workspaceId}/period_summaries/2026-03`);

        for (const delta of [0.1, 0.2]) {
            await repository.updatePeriodSummary(workspaceId, 2026, 3, CATEGORY, { actualDelta: delta });
        }

        const totals = (await ref.get()).data()!.categories[CATEGORY.id];
        expect(totals.actualAmountCents).toBe(30);
        expect(totals.actualAmount).toBe(0.3);
    });

    it("period_summaries: só a categoria do delta é tocada", async () => {
        const workspaceId = newWorkspace("summary-merge");
        const repository = new FinanceRepositoryImpl();
        const ref = firestore.doc(`workspaces/${workspaceId}/period_summaries/2026-03`);

        await ref.set({
            year: 2026, month: 3, week: null, runtimeType: "month",
            categories: {
                outra: { actualAmount: 77, actualAmountCents: 7700 },
                [CATEGORY.id]: { actualAmount: 10, actualAmountCents: 1000 },
            },
        });

        await repository.updatePeriodSummary(workspaceId, 2026, 3, CATEGORY, { actualDelta: 5 });

        const categories = (await ref.get()).data()!.categories;
        expect(categories[CATEGORY.id].actualAmountCents).toBe(1500);
        expect(categories.outra).toEqual({ actualAmount: 77, actualAmountCents: 7700 });
    });

    it("applyPlanningImpacts: idem, sobre um sumário pré-migração", async () => {
        const workspaceId = newWorkspace("planning-seed");
        const repository = new FinanceRepositoryImpl();
        const ref = firestore.doc(`workspaces/${workspaceId}/period_summaries/2026-03`);

        await ref.set({
            year: 2026, month: 3, week: null, runtimeType: "month",
            categories: { [CATEGORY.id]: { generalPlannedAmount: 1000 } },
        });

        await repository.applyPlanningImpacts(workspaceId, [
            { year: 2026, month: 3, category: CATEGORY, generalPlannedDelta: 25 },
        ]);

        const totals = (await ref.get()).data()!.categories[CATEGORY.id];
        expect(totals.generalPlannedAmount).toBe(1025);
        expect(totals.generalPlannedAmountCents).toBe(102500);
    });

    it("updateInvoiceWithDelta: a order de fatura pré-migração também", async () => {
        const workspaceId = newWorkspace("invoice-seed");
        const repository = new FinanceRepositoryImpl();

        const account = {
            id: "acc-card",
            name: "Cartão",
            runtimeType: "creditCard",
            isDeleted: false,
            initialBalance: 0,
            closingDay: 5,
            dueDay: 10,
        } as any;

        const dueDate = new Date("2026-03-10T15:00:00.000Z");
        const orderId = InvoiceService.invoiceOrderId(account.id, dueDate);
        const ref = firestore.doc(`workspaces/${workspaceId}/orders/${orderId}`);

        // Fatura antiga: só o `double`.
        await ref.set({ amount: 1000, description: "Fatura Cartão", isInvoice: true });

        await repository.updateInvoiceWithDelta(workspaceId, account, dueDate, 2500);

        const order = (await ref.get()).data()!;
        expect(order.amount).toBe(1025);
        expect(order.amountCents).toBe(102500);
    });

    it("propagateBalanceDelta: a semente do balanceCents vem da leitura", async () => {
        const workspaceId = newWorkspace("propaga-seed");
        const repository = new FinanceRepositoryImpl();
        const balances = firestore.collection(`workspaces/${workspaceId}/accounts/acc1/balance`);

        // Dia futuro no formato antigo: só `balance`.
        await balances.doc("2026-03-20").set({ balance: 1000 });

        await repository.updateAccountBalance(workspaceId, "acc1", new Date("2026-03-10T15:00:00.000Z"), -5000);

        const propagated = (await balances.doc("2026-03-20").get()).data()!;
        expect(propagated.balance).toBe(950);
        // Sem a semente, o incremento nasceria de zero: -5000.
        expect(propagated.balanceCents).toBe(95000);
        expect(propagated.dateKey).toBe("2026-03-20");
    });
});

describe("ALTO 3 — o checkpoint não pode esconder um workspace que falhou", () => {
    it("um workspace que falha CONTINUA pendente e é revisitado", async () => {
        const alpha = `ws-cents-alpha-${Date.now()}`;
        const beta = `ws-cents-beta-${Date.now()}`;
        workspaces.push(alpha, beta);

        for (const id of [alpha, beta]) {
            await firestore.collection("workspaces").doc(id).set({ name: id, type: "personal", members: ["u1"] });
            await firestore.collection(`workspaces/${id}/orders`).doc("o1").set({ amount: 10, description: "x" });
        }

        // Primeira execução: a leitura de uma coleção de `alpha` falha.
        const realCollection = firestore.collection.bind(firestore);
        const realWorkspaces = realCollection("workspaces");
        const spy = jest.spyOn(firestore, "collection").mockImplementation(((path: string) => {
            if (path !== "workspaces") return realCollection(path);
            return {
                listDocuments: () => realWorkspaces.listDocuments(),
                doc: (id: string) => {
                    const ref = realWorkspaces.doc(id);
                    if (id !== alpha) return ref;
                    return {
                        collection: (name: string) => {
                            if (name === "goals") throw new Error("falha simulada em ws-alpha");
                            return ref.collection(name);
                        },
                    };
                },
            };
        }) as any);

        const first = await migrateMoneyCents(firestore, { dryRun: false, restart: true }, quiet);
        spy.mockRestore();

        expect(first.failed).toBeGreaterThan(0);
        expect(first.failedWorkspaces).toContain(alpha);
        expect(first.pending).toContain(alpha);
        // `beta` passou e saiu da lista.
        expect(first.pending).not.toContain(beta);

        const checkpoint = (await firestore.doc("config/cron_checkpoints").get()).data();
        expect(checkpoint?.[MONEY_CENTS_CHECKPOINT_FIELD]).toContain(alpha);

        // Segunda execução: retoma a LISTA DE PENDENTES e migra `alpha`.
        // Com o marcador de avanço antigo (`id > último concluído`), `alpha`
        // ficava atrás do marcador, a varredura via 0 workspaces, zerava o
        // checkpoint e saía com código 0.
        const second = await migrateMoneyCents(firestore, { dryRun: false }, quiet);

        expect(second.workspaces).toBeGreaterThan(0);
        expect(second.failed).toBe(0);
        expect(second.pending).toEqual([]);
        expect((await firestore.doc(`workspaces/${alpha}/orders/o1`).get()).data()?.amountCents).toBe(1000);
    });

    it("--verify FALHA quando ainda há documento a migrar, não só quando diverge", async () => {
        const workspaceId = newWorkspace("verify-pendente");
        await seedSimple(workspaceId);

        const before = await migrateMoneyCents(firestore, { dryRun: true, verify: true, workspaceId }, quiet);
        const beforeVerdict = verdict(before);

        expect(beforeVerdict.divergent).toBe(0);
        expect(beforeVerdict.remaining).toBeGreaterThan(0);
        // É o ponto: "nenhuma divergência" numa base em que o inteiro sequer
        // existe seria um atestado de saúde para o silêncio.
        expect(beforeVerdict.ok).toBe(false);

        await migrateMoneyCents(firestore, { dryRun: false, workspaceId }, quiet);

        const after = verdict(await migrateMoneyCents(firestore, { dryRun: true, verify: true, workspaceId }, quiet));
        expect(after.ok).toBe(true);
        expect(after.remaining).toBe(0);
    });

    it("--verify FALHA quando há campo monetário presente e não numérico", async () => {
        const workspaceId = newWorkspace("verify-sujo");
        await seedSimple(workspaceId);
        await migrateMoneyCents(firestore, { dryRun: false, workspaceId }, quiet);

        await firestore.doc(`workspaces/${workspaceId}/orders/o1`).set({ amount: "1000", description: "sujo" });

        const result = verdict(await migrateMoneyCents(firestore, { dryRun: true, verify: true, workspaceId }, quiet));

        expect(result.invalid).toBeGreaterThan(0);
        expect(result.ok).toBe(false);
        expect(result.reasons.join(" ")).toContain("NÃO numéricos");
    });

    /**
     * MÉDIO 5 — `batch.update` é ATÔMICO: se um documento sumiu entre a leitura
     * e o commit, o lote inteiro é rejeitado com NOT_FOUND e os outros não são
     * gravados. `commitPatches` degrada para escrita por documento.
     *
     * Por que não `set(..., {merge: true})`, que não falharia: ele CRIARIA o
     * documento apagado — uma order fantasma com um único campo `amountCents`,
     * que o app listaria. Um patch de espelho não ressuscita nada.
     */
    it("um lote com documento apagado no meio não perde os outros", async () => {
        const workspaceId = newWorkspace("lote-parcial");
        const orders = firestore.collection(`workspaces/${workspaceId}/orders`);

        for (const id of ["o1", "o2", "o3"]) {
            await orders.doc(id).set({ amount: 10, description: id });
        }

        const patches = ["o1", "o2", "o3", "sumiu"].map((id) => ({
            op: "update" as const,
            ref: orders.doc(id),
            data: { amountCents: 1000 },
        }));

        const committed = await commitPatches(firestore, patches, quiet);

        // Três gravados; o quarto (inexistente) é descartado, não propagado.
        expect(committed).toBe(3);
        for (const id of ["o1", "o2", "o3"]) {
            expect((await orders.doc(id).get()).data()?.amountCents).toBe(1000);
        }
        // E o documento que não existia continua NÃO existindo.
        expect((await orders.doc("sumiu").get()).exists).toBe(false);
    });
});
