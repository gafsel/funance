import { readFileSync } from "fs";
import { resolve } from "path";

import {
    assertFails,
    assertSucceeds,
    initializeTestEnvironment,
    RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
    doc,
    deleteDoc,
    getDoc,
    setDoc,
    updateDoc,
    setLogLevel,
    Timestamp,
} from "firebase/firestore";

/**
 * Testes das security rules do Firestore (firebase/firestore.rules) contra o
 * emulador. Rodam junto com os testes de integração via `npm run test:integration`.
 */

const RULES_PATH = resolve(__dirname, "../../../../firebase/firestore.rules");

const MEMBER_UID = "user-membro";
const GUEST_UID = "user-convidado";
const OUTSIDER_UID = "user-de-fora";
const WORKSPACE_ID = "ws-rules";
const INVITE_ID = "invite-rules";
const GUEST_EMAIL = "convidado@funances.test";
const ORDER_ID = "order-rules";
const INSTALLMENT_ID = "installment-rules";

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

const inviteDoc = (overrides: Record<string, unknown> = {}) => ({
    workspace: { id: WORKSPACE_ID, name: "Casa", type: "personal" },
    senderId: MEMBER_UID,
    senderName: "Dono",
    receiverEmail: GUEST_EMAIL,
    status: "pending",
    createdAt: Timestamp.fromDate(new Date(2026, 8, 10, 12)),
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
                // MEMBER_UID é members[0], ou seja, o dono.
                members: [MEMBER_UID, GUEST_UID],
            });
            await setDoc(doc(db, `invites/${INVITE_ID}`), inviteDoc());
            await setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/installments/${INSTALLMENT_ID}`),
                installmentDoc()
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

    it("nega que o cliente altere members do workspace", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(
            updateDoc(doc(db, `workspaces/${WORKSPACE_ID}`), {
                members: [MEMBER_UID],
            })
        );
    });

    describe("convites", () => {
        beforeEach(async () => {
            await testEnv.withSecurityRulesDisabled(async (context) => {
                await setDoc(
                    doc(context.firestore(), `invites/${INVITE_ID}`),
                    inviteDoc()
                );
            });
        });

        it("um membro do workspace lê os convites do próprio workspace", async () => {
            const db = testEnv.authenticatedContext(GUEST_UID).firestore();

            await assertSucceeds(getDoc(doc(db, `invites/${INVITE_ID}`)));
        });

        it("quem não é membro nem destinatário não lê o convite", async () => {
            const db = testEnv.authenticatedContext(OUTSIDER_UID).firestore();

            await assertFails(getDoc(doc(db, `invites/${INVITE_ID}`)));
        });

        it("o dono renova o convite pendente (só createdAt)", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            await assertSucceeds(
                updateDoc(doc(db, `invites/${INVITE_ID}`), {
                    createdAt: Timestamp.fromDate(new Date(2026, 8, 20, 12)),
                })
            );
        });

        it("renovar não pode mudar o destinatário", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            await assertFails(
                updateDoc(doc(db, `invites/${INVITE_ID}`), {
                    createdAt: Timestamp.fromDate(new Date(2026, 8, 20, 12)),
                    receiverEmail: "outro@funances.test",
                })
            );
        });

        it("o dono cancela o convite pendente", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            await assertSucceeds(deleteDoc(doc(db, `invites/${INVITE_ID}`)));
        });

        it("quem não é dono nem remetente não cancela", async () => {
            const db = testEnv.authenticatedContext(GUEST_UID).firestore();

            await assertFails(deleteDoc(doc(db, `invites/${INVITE_ID}`)));
        });

        it("convite já aceito não pode ser apagado", async () => {
            await testEnv.withSecurityRulesDisabled(async (context) => {
                await setDoc(
                    doc(context.firestore(), `invites/${INVITE_ID}`),
                    inviteDoc({ status: "accepted" })
                );
            });

            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            await assertFails(deleteDoc(doc(db, `invites/${INVITE_ID}`)));
        });
    });
});
