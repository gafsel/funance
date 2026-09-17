// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import {
    MONEY_CENTS_CHECKPOINT_FIELD,
    migrateMoneyCents,
} from "../../scripts/migrate_money_cents";
import { applyCentsPatch } from "../../core/utils/money_cents";
import { MONEY_CENTS_FIELDS } from "../../features/finance/domain/models/finance.models";

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
