import { readFileSync } from "fs";
import { resolve } from "path";

import {
    assertFails,
    assertSucceeds,
    initializeTestEnvironment,
    RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { deleteField, doc, getDoc, setDoc, updateDoc, setLogLevel, Timestamp } from "firebase/firestore";

/**
 * Testes das security rules do Firestore (firebase/firestore.rules) contra o
 * emulador. Rodam junto com os testes de integração via `npm run test:integration`.
 */

const RULES_PATH = resolve(__dirname, "../../../../firebase/firestore.rules");

const MEMBER_UID = "user-membro";
const OUTSIDER_UID = "user-de-fora";
const WORKSPACE_ID = "ws-rules";
const ORDER_ID = "order-rules";
const INSTALLMENT_ID = "installment-rules";
const PLANNING_ID = "planning-rules";
const CARD_ID = "acc-card-rules";
const INVOICE_INSTALLMENT_ID = "installment-fatura-rules";

const planningDoc = (overrides: Record<string, unknown> = {}) => ({
    category: { id: "cat-moradia", name: "Moradia", icon: "home", color: "#42A5F5" },
    amount: 1200,
    startMonth: "2026-01",
    endMonth: "2026-12",
    ...overrides,
});

const cardDoc = (overrides: Record<string, unknown> = {}) => ({
    name: "Cartão",
    icon: "credit_card",
    color: "#8A05BE",
    runtimeType: "creditCard",
    isDeleted: false,
    initialBalance: 0,
    initialBalanceDate: "2026-01-01T12:00:00.000",
    limit: 5000,
    closingDay: 5,
    dueDay: 10,
    ...overrides,
});

/** Parcela de FATURA, com a janela do ciclo que só o servidor escreve (F1.8). */
const invoiceInstallmentDoc = (overrides: Record<string, unknown> = {}) => ({
    orderId: `invoice-${CARD_ID}-2026-03-10`,
    amount: 350.5,
    referenceAmount: 350.5,
    description: "Fatura Cartão",
    status: "pending",
    type: "transfer",
    installmentType: "single",
    dueDate: Timestamp.fromDate(new Date(2026, 2, 10, 12)),
    referenceDate: Timestamp.fromDate(new Date(2026, 2, 10, 12)),
    paidDate: null,
    accounts: { [CARD_ID]: "credit" },
    accountIds: [CARD_ID],
    isInvoice: true,
    cycleStart: Timestamp.fromDate(new Date(2026, 1, 5)),
    cycleEnd: Timestamp.fromDate(new Date(2026, 2, 4, 23, 59, 59)),
    closingDate: Timestamp.fromDate(new Date(2026, 2, 5)),
    ...overrides,
});

/** Resumo `nextInvoice` (F1.8) — só o servidor escreve. */
const nextInvoiceDoc = () => ({
    dueDate: Timestamp.fromDate(new Date(2026, 2, 10, 12)),
    closingDate: Timestamp.fromDate(new Date(2026, 2, 5)),
    cycleStart: Timestamp.fromDate(new Date(2026, 1, 5)),
    cycleEnd: Timestamp.fromDate(new Date(2026, 2, 4, 23, 59, 59)),
    amount: 350.5,
    orderId: `invoice-${CARD_ID}-2026-03-10`,
    installmentId: "inst-fatura",
    status: "pending",
});

const installmentDoc = (overrides: Record<string, unknown> = {}) => ({
    orderId: ORDER_ID,
    amount: 167.47,
    referenceAmount: 167.47,
    description: "Notebook",
    status: "pending",
    type: "expense",
    installmentType: "installment",
    dueDate: Timestamp.fromDate(new Date(2026, 2, 10, 12)),
    referenceDate: Timestamp.fromDate(new Date(2026, 2, 10, 12)),
    paidDate: null,
    installmentNumber: 1,
    installmentCount: 3,
    accounts: { "acc-checking": "debt" },
    accountIds: ["acc-checking"],
    ...overrides,
});

describe("firestore.rules", () => {
    let testEnv: RulesTestEnvironment;

    beforeAll(async () => {
        // As negativas esperadas geram PERMISSION_DENIED barulhento no stderr.
        setLogLevel("silent");

        const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST || "").split(":");

        testEnv = await initializeTestEnvironment({
            projectId: "demo-funances-rules",
            firestore: {
                rules: readFileSync(RULES_PATH, "utf8"),
                host,
                port: Number(port),
            },
        });

        await testEnv.withSecurityRulesDisabled(async (context) => {
            const db = context.firestore();
            await setDoc(doc(db, `workspaces/${WORKSPACE_ID}`), {
                name: "Casa",
                type: "personal",
                members: [MEMBER_UID],
            });
            await setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/installments/${INSTALLMENT_ID}`),
                installmentDoc()
            );
            await setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/category_planning/${PLANNING_ID}`),
                planningDoc({ summarizedUntil: "2026-12", appliedAmount: 1200, appliedFrom: "2026-09", appliedUntil: "2026-12" })
            );
            await setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/accounts/${CARD_ID}`),
                { ...cardDoc(), nextInvoice: nextInvoiceDoc() }
            );
            await setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/installments/${INVOICE_INSTALLMENT_ID}`),
                invoiceInstallmentDoc()
            );
        });
    });

    afterAll(async () => {
        await testEnv?.cleanup();
    });

    it("permite que um membro do workspace leia suas installments", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertSucceeds(
            getDoc(doc(db, `workspaces/${WORKSPACE_ID}/installments/${INSTALLMENT_ID}`))
        );
    });

    it("nega leitura de installments para quem não é membro do workspace", async () => {
        const db = testEnv.authenticatedContext(OUTSIDER_UID).firestore();

        await assertFails(
            getDoc(doc(db, `workspaces/${WORKSPACE_ID}/installments/${INSTALLMENT_ID}`))
        );
    });

    it("nega que o cliente escreva o campo xp de uma installment", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(
            updateDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/installments/${INSTALLMENT_ID}`),
                { xp: 100 }
            )
        );
    });

    it("permite que o membro marque a installment como paga (sem tocar em xp)", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertSucceeds(
            updateDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/installments/${INSTALLMENT_ID}`),
                {
                    status: "paid",
                    paidAmount: 167.47,
                    paidDate: Timestamp.fromDate(new Date(2026, 2, 10, 12)),
                }
            )
        );
    });

    it("nega que o cliente crie uma installment diretamente (addInstallment)", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(
            setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/installments/nova-installment`),
                installmentDoc()
            )
        );
    });

    // ---- F1.9: a semana corrente é escrita só pelo servidor -----------------

    it("nega que o cliente escreva currentWeekId/currentWeekStart no workspace", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(
            updateDoc(doc(db, `workspaces/${WORKSPACE_ID}`), { currentWeekId: "2026-W37" })
        );
        await assertFails(
            updateDoc(doc(db, `workspaces/${WORKSPACE_ID}`), {
                currentWeekStart: Timestamp.fromDate(new Date(2026, 8, 13)),
            })
        );
    });

    it("permite que o membro leia a semana corrente e continue editando o nome", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertSucceeds(getDoc(doc(db, `workspaces/${WORKSPACE_ID}`)));
        await assertSucceeds(updateDoc(doc(db, `workspaces/${WORKSPACE_ID}`), { name: "Casa nova" }));
    });

    // ---- F1.5: marcadores do planejamento são do servidor -------------------

    it("permite que o membro crie e edite um planejamento sem os marcadores", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertSucceeds(
            setDoc(doc(db, `workspaces/${WORKSPACE_ID}/category_planning/novo-plan`), planningDoc())
        );
        await assertSucceeds(
            updateDoc(doc(db, `workspaces/${WORKSPACE_ID}/category_planning/${PLANNING_ID}`), { amount: 1500 })
        );
    });

    it("nega que o cliente crie um planejamento já com os marcadores", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(
            setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/category_planning/plan-forjado`),
                planningDoc({ summarizedUntil: "9999-12", appliedAmount: 99999, appliedFrom: "2020-01", appliedUntil: "2030-12" })
            )
        );
    });

    it("nega que o cliente altere os marcadores de um planejamento existente", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        for (const patch of [
            { summarizedUntil: "2030-12" },
            { appliedAmount: 0 },
            { appliedFrom: "2020-01" },
            { appliedUntil: "2030-12" },
            { lastSummaryMonth: "2020-01" },
        ]) {
            await assertFails(
                updateDoc(doc(db, `workspaces/${WORKSPACE_ID}/category_planning/${PLANNING_ID}`), patch)
            );
        }
    });

    // ---- F1.8: nextInvoice da conta é do servidor ---------------------------

    it("permite que o membro leia o nextInvoice da conta", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        const snapshot = await assertSucceeds(
            getDoc(doc(db, `workspaces/${WORKSPACE_ID}/accounts/${CARD_ID}`))
        );
        expect(snapshot.data()?.nextInvoice?.amount).toBe(350.5);
    });

    it("permite criar e editar um cartão SEM o nextInvoice", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertSucceeds(
            setDoc(doc(db, `workspaces/${WORKSPACE_ID}/accounts/acc-card-novo`), cardDoc())
        );
        await assertSucceeds(
            updateDoc(doc(db, `workspaces/${WORKSPACE_ID}/accounts/${CARD_ID}`), { dueDay: 15 })
        );
    });

    it("nega que o cliente crie uma conta já com nextInvoice", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(
            setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/accounts/acc-card-forjado`),
                { ...cardDoc(), nextInvoice: nextInvoiceDoc() }
            )
        );
    });

    it("nega que o cliente altere ou apague o nextInvoice de uma conta existente", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(
            updateDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/accounts/${CARD_ID}`),
                { nextInvoice: { ...nextInvoiceDoc(), amount: 0 } }
            )
        );
        await assertFails(
            updateDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/accounts/${CARD_ID}`),
                { "nextInvoice.amount": 0 }
            )
        );
    });

    it("nega que um setDoc do cliente APAGUE o nextInvoice", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        // `setDoc` sem merge substitui o documento: omitir o campo equivale a
        // apagá-lo, e isso conta como chave afetada. É o caso de um formulário
        // que serialize a conta inteira e não conheça o campo do servidor.
        await assertFails(
            setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/accounts/${CARD_ID}`),
                cardDoc({ name: "Cartão renomeado" })
            )
        );
    });

    it("tolera o reenvio do MESMO nextInvoice (nada mudou, nada a negar)", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        // A regra é por DIFERENÇA de valor, não por presença da chave no
        // update: reescrever o campo com exatamente o que o servidor gravou é
        // um no-op e não precisa ser barrado.
        await assertSucceeds(
            setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/accounts/${CARD_ID}`),
                { ...cardDoc({ name: "Cartão renomeado" }), nextInvoice: nextInvoiceDoc() }
            )
        );
    });

    // ---- F1.8: a janela do ciclo da fatura é do servidor -------------------

    it("permite que o membro leia a janela do ciclo da fatura", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        const snapshot = await assertSucceeds(
            getDoc(doc(db, `workspaces/${WORKSPACE_ID}/installments/${INVOICE_INSTALLMENT_ID}`))
        );
        expect(snapshot.data()?.cycleStart).toBeDefined();
    });

    it("nega que o cliente altere a janela do ciclo de uma fatura", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        for (const patch of [
            { cycleStart: Timestamp.fromDate(new Date(2026, 0, 1)) },
            { cycleEnd: Timestamp.fromDate(new Date(2026, 5, 1)) },
            { closingDate: Timestamp.fromDate(new Date(2026, 5, 1)) },
        ]) {
            await assertFails(
                updateDoc(
                    doc(db, `workspaces/${WORKSPACE_ID}/installments/${INVOICE_INSTALLMENT_ID}`),
                    patch
                )
            );
        }
    });

    it("nega que o cliente APAGUE a janela do ciclo de uma fatura", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(
            updateDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/installments/${INVOICE_INSTALLMENT_ID}`),
                { cycleStart: deleteField() }
            )
        );
    });

    it("permite pagar a fatura sem tocar na janela", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertSucceeds(
            updateDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/installments/${INVOICE_INSTALLMENT_ID}`),
                {
                    status: "paid",
                    paidAmount: 350.5,
                    paidDate: Timestamp.fromDate(new Date(2026, 2, 10, 12)),
                }
            )
        );
    });

    it("tolera o null da build que grava o doc inteiro numa parcela comum", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        // Mesma exceção do xp: a parcela que NÃO é fatura não tem os campos, e
        // um `null` neles não é alteração de valor nenhuma.
        await assertSucceeds(
            updateDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/installments/${INSTALLMENT_ID}`),
                { cycleStart: null, cycleEnd: null, closingDate: null }
            )
        );
    });

    it("nega que o cliente crie uma parcela de fatura com a janela pronta", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        // `installments` não tem `allow create` nenhum: o create é negado
        // mesmo, e carregar a janela do ciclo não abre exceção.
        await assertFails(
            setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/installments/fatura-forjada`),
                invoiceInstallmentDoc()
            )
        );
    });
});
