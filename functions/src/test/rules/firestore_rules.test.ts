import { readFileSync } from "fs";
import { resolve } from "path";

import {
    assertFails,
    assertSucceeds,
    initializeTestEnvironment,
    RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
    deleteDoc,
    deleteField,
    doc,
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
const PLANNING_ID = "planning-rules";
const CARD_ID = "acc-card-rules";
const INVOICE_INSTALLMENT_ID = "installment-fatura-rules";
const WEEK_ID = "2026-W37";
const MISSION_ID = `${WEEK_ID}_consistency`;
const HEALTH_MONTH_ID = "2026-08";

const planningDoc = (overrides: Record<string, unknown> = {}) => ({
    category: { id: "cat-moradia", name: "Moradia", icon: "home", color: "#42A5F5" },
    amount: 1200,
    startMonth: "2026-01",
    endMonth: "2026-12",
    ...overrides,
});

const GOAL_ID = "goal-rules";

const goalDoc = (overrides: Record<string, unknown> = {}) => ({
    name: "Reserva de emergência",
    runtimeType: "saveMoney",
    targetAmount: 10000,
    currentAmount: 0,
    accountId: "acc-checking",
    deadline: Timestamp.fromDate(new Date(2026, 11, 31, 12)),
    startDate: Timestamp.fromDate(new Date(2026, 0, 1, 12)),
    isDeleted: false,
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

const orderDoc = (overrides: Record<string, unknown> = {}) => ({
    amount: 502.4,
    description: "Notebook",
    dueDay: 10,
    startMonth: "2026-03",
    installmentType: "installment",
    installmentCount: 3,
    status: "active",
    type: "expense",
    accounts: { "acc-checking": "debt" },
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
                // F2.2/F2.3: campos do servidor já presentes, para que apagá-los
                // seja uma alteração DE VERDADE nos testes abaixo (um
                // `deleteField()` num campo inexistente é um no-op e passaria).
                financialHealth: { score: 55, tier: "estrategista", monthKey: "2026-08" },
                xpAwardedFor: { planning: { mercado: "2026-08-01T00:00:00.000Z" } },
                // `weeklyStreaks` continua NÚMERO; o mapa vive em `streaks`.
                weeklyStreaks: 2,
                streaks: { missions: 2, plan: 3 },
            });
            await setDoc(doc(db, `invites/${INVITE_ID}`), inviteDoc());
            await setDoc(doc(db, `workspaces/${WORKSPACE_ID}/orders/${ORDER_ID}`), {
                ...orderDoc(),
                // F1.10: o espelho inteiro já gravado pelo servidor.
                amountCents: 50240,
            });
            await setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/installments/${INSTALLMENT_ID}`),
                installmentDoc({ amountCents: 16747, referenceAmountCents: 16747 })
            );
            await setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/category_planning/${PLANNING_ID}`),
                planningDoc({ summarizedUntil: "2026-12", appliedAmount: 1200, appliedFrom: "2026-09", appliedUntil: "2026-12" })
            );
            await setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/goals/${GOAL_ID}`),
                goalDoc({
                    outcome: "success",
                    completedAt: Timestamp.fromDate(new Date(2026, 5, 1, 12)),
                })
            );
            // Catálogo público de badges (F2.7): publicado pelo servidor.
            await setDoc(doc(db, "config/badges"), {
                version: "v-teste",
                badges: [{ id: "first_step", name: "Primeiro Passo", icon: "rocket_launch", xpReward: 100, category: "advanced", description: "..." }],
                levelThresholds: [0, 300, 900],
            });
            await setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/accounts/${CARD_ID}`),
                { ...cardDoc(), nextInvoice: nextInvoiceDoc() }
            );
            await setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/installments/${INVOICE_INSTALLMENT_ID}`),
                invoiceInstallmentDoc()
            );
            // F2.4/F3.1: missões semanais e histórico da Bússola da Liberdade.
            // Os dois são escritos só pelo Admin SDK; o app precisa LER.
            await setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/weekly_missions/${MISSION_ID}`),
                {
                    id: "consistency",
                    name: "Equipe planeja limites para pelo menos 3 categorias.",
                    type: "consistency",
                    status: "pending",
                    rewardXp: 150,
                    progress: 0,
                    target: 3,
                    weekId: WEEK_ID,
                    createdAt: new Date().toISOString(),
                }
            );
            await setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/health_history/${HEALTH_MONTH_ID}`),
                { score: 62, tier: "estrategista", monthKey: HEALTH_MONTH_ID, computedAt: Timestamp.fromDate(new Date(2026, 8, 1, 0)) }
            );
            await setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/weekly_xp/${WEEK_ID}`),
                { year: 2026, week: 37, xp: 175 }
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

    it("nega que o cliente altere members do workspace", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(
            updateDoc(doc(db, `workspaces/${WORKSPACE_ID}`), {
                members: [MEMBER_UID],
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

    // ── Metas: o DESFECHO é do servidor (F2.5) ────────────────────────────

    it("permite que o membro edite a meta sem tocar no desfecho", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertSucceeds(
            updateDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/goals/${GOAL_ID}`),
                { name: "Reserva maior", targetAmount: 12000 }
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

    it("nega que o cliente escreva completedAt numa meta", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(
            updateDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/goals/${GOAL_ID}`),
                { completedAt: Timestamp.fromDate(new Date(2026, 0, 2, 12)) }
            )
        );
    });

    it("nega que o cliente crie uma meta já com completedAt", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(
            setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/goals/goal-nova`),
                goalDoc({ completedAt: Timestamp.fromDate(new Date(2026, 0, 2, 12)) })
            )
        );
    });

    it("nega que o cliente escreva outcome numa meta", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        // A meta semeada já tem `outcome: "success"`; escrever o MESMO valor
        // não muda chave nenhuma e as rules nem veriam a tentativa. O que
        // precisa ser negado é a troca do veredito.
        await assertFails(
            updateDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/goals/${GOAL_ID}`),
                { outcome: "failed" }
            )
        );
    });

    it("nega que o cliente escreva failedAt numa meta", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(
            updateDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/goals/${GOAL_ID}`),
                { failedAt: Timestamp.fromDate(new Date(2026, 0, 2, 12)) }
            )
        );
    });

    it("nega que o cliente crie uma meta já com outcome", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(
            setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/goals/goal-nova-outcome`),
                goalDoc({ outcome: "failed" })
            )
        );
    });

    it("nega meta com targetAmount zero", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(
            setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/goals/goal-alvo-zero`),
                goalDoc({ targetAmount: 0 })
            )
        );
    });

    it("nega meta com targetAmount negativo", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(
            setDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/goals/goal-alvo-negativo`),
                goalDoc({ targetAmount: -100 })
            )
        );
    });

    it("nega EDIÇÃO que zera o targetAmount de uma meta existente", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(
            updateDoc(
                doc(db, `workspaces/${WORKSPACE_ID}/goals/${GOAL_ID}`),
                { targetAmount: 0 }
            )
        );
    });

    it("permite que o cliente crie uma meta normal", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertSucceeds(
            setDoc(doc(db, `workspaces/${WORKSPACE_ID}/goals/goal-nova-ok`), goalDoc())
        );
    });

    // ── Catálogo de badges (F2.7) ─────────────────────────────────────────

    it("permite que qualquer usuário autenticado leia config/badges", async () => {
        const db = testEnv.authenticatedContext(OUTSIDER_UID).firestore();

        await assertSucceeds(getDoc(doc(db, "config/badges")));
    });

    it("nega leitura de config/badges para quem não está autenticado", async () => {
        const db = testEnv.unauthenticatedContext().firestore();

        await assertFails(getDoc(doc(db, "config/badges")));
    });

    it("nega escrita em config/badges mesmo para usuário autenticado", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(updateDoc(doc(db, "config/badges"), { version: "hackeada" }));
    });

    it("mantém os demais documentos de config fechados", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(getDoc(doc(db, "config/ai")));
        await assertFails(getDoc(doc(db, "config/cron_checkpoints")));
    });

    // ---- F2.4/F3.1: missões semanais e histórico do índice ------------------
    //
    // Sem estas regras as duas coleções caíam no `match /{document=**}` do fim
    // do arquivo, que nega tudo: a Jornada não conseguia ler nem as missões que
    // o GamificationService já vinha gerando havia meses.

    describe("weekly_missions", () => {
        const missionPath = `workspaces/${WORKSPACE_ID}/weekly_missions/${MISSION_ID}`;

        it("permite que um membro leia as missões da semana", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            const snapshot = await assertSucceeds(getDoc(doc(db, missionPath)));
            expect(snapshot.data()?.rewardXp).toBe(150);
            expect(snapshot.data()?.weekId).toBe(WEEK_ID);
        });

        it("nega leitura para quem não é membro do workspace", async () => {
            const db = testEnv.authenticatedContext(OUTSIDER_UID).firestore();

            await assertFails(getDoc(doc(db, missionPath)));
        });

        it("nega leitura para quem não está autenticado", async () => {
            const db = testEnv.unauthenticatedContext().firestore();

            await assertFails(getDoc(doc(db, missionPath)));
        });

        it("nega que o membro conclua a própria missão", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            await assertFails(
                updateDoc(doc(db, missionPath), { status: "completed", progress: 3 })
            );
        });

        it("nega que o membro crie uma missão", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            await assertFails(
                setDoc(
                    doc(db, `workspaces/${WORKSPACE_ID}/weekly_missions/${WEEK_ID}_inventada`),
                    { type: "consistency", status: "completed", rewardXp: 99999, weekId: WEEK_ID }
                )
            );
        });

        it("nega que o membro apague uma missão", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            await assertFails(deleteDoc(doc(db, missionPath)));
        });
    });

    describe("health_history", () => {
        const historyPath = `workspaces/${WORKSPACE_ID}/health_history/${HEALTH_MONTH_ID}`;

        it("permite que um membro leia o histórico do índice", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            const snapshot = await assertSucceeds(getDoc(doc(db, historyPath)));
            expect(snapshot.data()?.score).toBe(62);
        });

        it("nega leitura para quem não é membro do workspace", async () => {
            const db = testEnv.authenticatedContext(OUTSIDER_UID).firestore();

            await assertFails(getDoc(doc(db, historyPath)));
        });

        it("nega leitura para quem não está autenticado", async () => {
            const db = testEnv.unauthenticatedContext().firestore();

            await assertFails(getDoc(doc(db, historyPath)));
        });

        it("nega que o membro reescreva o próprio score", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            await assertFails(updateDoc(doc(db, historyPath), { score: 100 }));
        });

        it("nega que o membro crie um mês de histórico", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            await assertFails(
                setDoc(
                    doc(db, `workspaces/${WORKSPACE_ID}/health_history/2026-09`),
                    { score: 100, tier: "livre" }
                )
            );
        });

        it("nega que o membro apague um mês de histórico", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            await assertFails(deleteDoc(doc(db, historyPath)));
        });
    });

    it("nega que o membro escreva o weekly_xp da semana", async () => {
        const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

        await assertFails(
            updateDoc(doc(db, `workspaces/${WORKSPACE_ID}/weekly_xp/${WEEK_ID}`), { xp: 99999 })
        );
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

    describe("F2.2 — Bússola da Liberdade", () => {
        it("permite que o membro LEIA o histórico mensal do índice", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            await assertSucceeds(
                getDoc(doc(db, `workspaces/${WORKSPACE_ID}/health_history/2026-08`))
            );
        });

        it("nega a leitura do histórico a quem não é membro", async () => {
            const db = testEnv.authenticatedContext(OUTSIDER_UID).firestore();

            await assertFails(
                getDoc(doc(db, `workspaces/${WORKSPACE_ID}/health_history/2026-08`))
            );
        });

        it("nega que o membro ESCREVA no histórico — é placar, não diário", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            await assertFails(
                setDoc(
                    doc(db, `workspaces/${WORKSPACE_ID}/health_history/2026-09`),
                    { score: 100, tier: "livre", monthKey: "2026-09" }
                )
            );
            await assertFails(
                updateDoc(
                    doc(db, `workspaces/${WORKSPACE_ID}/health_history/2026-08`),
                    { score: 100, tier: "livre" }
                )
            );
            await assertFails(
                deleteDoc(doc(db, `workspaces/${WORKSPACE_ID}/health_history/2026-08`))
            );
        });

        it("nega que o cliente escreva financialHealth ou healthDirtyAt no workspace", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            for (const patch of [
                { financialHealth: { score: 100, tier: "livre", monthKey: "2026-09" } },
                { healthDirtyAt: Timestamp.fromDate(new Date()) },
                { financialHealth: deleteField() },
            ]) {
                await assertFails(updateDoc(doc(db, `workspaces/${WORKSPACE_ID}`), patch));
            }
        });

        it("nega a criação de um workspace já com bússola ou marcadores de XP", async () => {
            const db = testEnv.authenticatedContext(OUTSIDER_UID).firestore();

            for (const extra of [
                { financialHealth: { score: 100, tier: "livre", monthKey: "2026-09" } },
                { healthDirtyAt: Timestamp.fromDate(new Date()) },
                { xpAwardedFor: { planning: { mercado: "2026-01-01" } } },
                { streaks: { missions: 40, plan: 40 } },
            ]) {
                await assertFails(
                    setDoc(doc(db, "workspaces/ws-forjado"), {
                        name: "Forjado", type: "personal", members: [OUTSIDER_UID], ...extra,
                    })
                );
            }
        });

        it("`weeklyStreaks` continua sendo um NÚMERO na criação", async () => {
            // O app instalado desserializa este campo como `num?`. Aceitar um
            // mapa aqui abriria a porta para o tipo que quebra toda build em
            // campo — e é exatamente por isso que o mapa novo vive em
            // `streaks`, negado ao cliente.
            const dbAntigo = testEnv.authenticatedContext("user-antigo").firestore();
            await assertSucceeds(
                setDoc(doc(dbAntigo, "workspaces/ws-streak-antigo"), {
                    name: "Antigo", type: "personal", members: ["user-antigo"], weeklyStreaks: 0,
                })
            );

            const dbMapa = testEnv.authenticatedContext("user-mapa").firestore();
            await assertFails(
                setDoc(doc(dbMapa, "workspaces/ws-streak-mapa"), {
                    name: "Mapa", type: "personal", members: ["user-mapa"], weeklyStreaks: {},
                })
            );

            // E nunca com uma sequência já pronta.
            const dbForja = testEnv.authenticatedContext("user-forja").firestore();
            await assertFails(
                setDoc(doc(dbForja, "workspaces/ws-streak-forjado"), {
                    name: "Forjado", type: "personal", members: ["user-forja"], weeklyStreaks: 40,
                })
            );
        });

        it("nega que o cliente escreva o mapa `streaks`", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            await assertFails(
                updateDoc(doc(db, `workspaces/${WORKSPACE_ID}`), { streaks: { missions: 99, plan: 99 } })
            );
        });
    });

    describe("F2.3 — unplannedReason", () => {
        it("nega que o cliente grave ou apague o motivo do XP zero", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            await assertFails(
                updateDoc(
                    doc(db, `workspaces/${WORKSPACE_ID}/installments/${INSTALLMENT_ID}`),
                    { unplannedReason: "born_paid" }
                )
            );
        });

        it("tolera o null da build que grava o doc inteiro numa parcela sem o campo", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            await assertSucceeds(
                updateDoc(
                    doc(db, `workspaces/${WORKSPACE_ID}/installments/${INSTALLMENT_ID}`),
                    { unplannedReason: null }
                )
            );
        });
    });
    describe("F1.10 — os espelhos inteiros (*Cents) são do SERVIDOR", () => {
        // Nesta etapa o app não conhece os campos `*Cents`: ele lê e escreve o
        // `double`, e o servidor completa o inteiro no passo derivado do
        // gatilho. Se o cliente pudesse gravá-los, bastaria um `amount: 10` com
        // `amountCents: 1` para que saldo, sumário e XP — que somam o INTEIRO —
        // acreditassem em um centavo.

        it("nega que o cliente crie uma order já com amountCents", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            await assertFails(
                setDoc(
                    doc(db, `workspaces/${WORKSPACE_ID}/orders/order-cents-forjada`),
                    { ...orderDoc(), amountCents: 1 }
                )
            );
        });

        it("nega que o cliente altere o amountCents de uma order existente", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            await assertFails(
                updateDoc(doc(db, `workspaces/${WORKSPACE_ID}/orders/${ORDER_ID}`), { amountCents: 1 })
            );
        });

        it("nega que o cliente grave os *Cents de uma parcela", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();
            const ref = doc(db, `workspaces/${WORKSPACE_ID}/installments/${INSTALLMENT_ID}`);

            await assertFails(updateDoc(ref, { amountCents: 1 }));
            await assertFails(updateDoc(ref, { paidAmountCents: 1 }));
            await assertFails(updateDoc(ref, { referenceAmountCents: 1 }));
        });

        it("tolera o reenvio do MESMO amountCents numa parcela (nada mudou)", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            // A negação é por DIFERENÇA de valor: uma build futura que releia e
            // reenvie o documento inteiro não é barrada por reenviar o que o
            // servidor gravou.
            await assertSucceeds(
                updateDoc(
                    doc(db, `workspaces/${WORKSPACE_ID}/installments/${INSTALLMENT_ID}`),
                    { amountCents: 16747, description: "Notebook novo" }
                )
            );
        });

        it("nega que o cliente grave os *Cents de uma meta", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();
            const ref = doc(db, `workspaces/${WORKSPACE_ID}/goals/${GOAL_ID}`);

            await assertFails(updateDoc(ref, { targetAmountCents: 1 }));
            await assertFails(updateDoc(ref, { currentAmountCents: 999999 }));
            await assertFails(
                setDoc(
                    doc(db, `workspaces/${WORKSPACE_ID}/goals/goal-cents-forjada`),
                    { ...goalDoc(), targetAmountCents: 1 }
                )
            );
        });

        it("nega que o cliente grave os *Cents de um planejamento", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();
            const ref = doc(db, `workspaces/${WORKSPACE_ID}/category_planning/${PLANNING_ID}`);

            await assertFails(updateDoc(ref, { amountCents: 1 }));
            await assertFails(updateDoc(ref, { appliedAmountCents: 1 }));
            await assertFails(
                setDoc(
                    doc(db, `workspaces/${WORKSPACE_ID}/category_planning/planning-cents-forjado`),
                    { ...planningDoc(), amountCents: 1 }
                )
            );
        });

        it("nega que o cliente grave os *Cents de uma conta", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();
            const ref = doc(db, `workspaces/${WORKSPACE_ID}/accounts/${CARD_ID}`);

            await assertFails(updateDoc(ref, { initialBalanceCents: 1 }));
            await assertFails(updateDoc(ref, { limitCents: 1 }));
            await assertFails(
                setDoc(
                    doc(db, `workspaces/${WORKSPACE_ID}/accounts/acc-card-cents-forjado`),
                    { ...cardDoc(), limitCents: 1 }
                )
            );
        });

        it("o membro LÊ os espelhos inteiros normalmente", async () => {
            const db = testEnv.authenticatedContext(MEMBER_UID).firestore();

            const snapshot = await assertSucceeds(
                getDoc(doc(db, `workspaces/${WORKSPACE_ID}/installments/${INSTALLMENT_ID}`))
            );
            expect(snapshot.data()?.amountCents).toBe(16747);
        });
    });
});
