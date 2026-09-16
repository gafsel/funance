import { readFileSync } from "fs";
import { resolve } from "path";

import {
    assertFails,
    assertSucceeds,
    initializeTestEnvironment,
    RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc, updateDoc, setLogLevel, Timestamp } from "firebase/firestore";

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

const planningDoc = (overrides: Record<string, unknown> = {}) => ({
    category: { id: "cat-moradia", name: "Moradia", icon: "home", color: "#42A5F5" },
    amount: 1200,
    startMonth: "2026-01",
    endMonth: "2026-12",
    ...overrides,
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
});
