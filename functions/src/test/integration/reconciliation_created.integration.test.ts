/**
 * Gamificação da conciliação é CREATE-ONLY (wp/reconciliation-created).
 *
 * O app passou a derivar o id de `reconciliations/{id}` da linha do extrato,
 * para ser idempotente do lado do cliente. O efeito colateral: reconfirmar o
 * MESMO extrato sobrescreve o mesmo documento, e `onReconciliationWritten` —
 * um `onDocumentWritten` — dispara de novo, com um `event.id` NOVO. A
 * idempotência por eventId não reconhece esse segundo evento: ela protege
 * contra a REENTREGA do mesmo evento, não contra um evento novo sobre o mesmo
 * fato.
 *
 * O emulador não dispara triggers, então os dois eventos são simulados
 * chamando `handleReconciliationWritten` com os pares (before, after) que o
 * Eventarc entregaria — que é a única forma de provar o encadeamento.
 *
 * O que este teste prova, contra o Firestore de verdade:
 *
 *  - a sobrescrita NÃO soma XP, NÃO reconcede badge e NÃO mexe no progresso da
 *    missão, nem quando os números do resumo MUDAM entre as duas gravações;
 *  - a saída antecipada acontece ANTES da idempotência, então a sobrescrita não
 *    deixa nem lixo em `_idempotency`;
 *  - o caminho feliz continua inteiro: a PRIMEIRA gravação concede tudo.
 */

// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import {
    GAMIFICATION_ACTIONS,
    handleReconciliationWritten,
} from "../../features/goal/presentation/functions/gamification_handler";
import { BADGES } from "../../features/goal/domain/services/gamification.service";
import { buildMissionName, findMissionTemplate } from "../../features/goal/domain/models/mission_catalog";
import { getWeekId, startOfWeekInTz } from "../../core/utils/week.utils";

/** Quinta 2026-09-10 12:00 em São Paulo. */
const THURSDAY = new Date("2026-09-10T15:00:00.000Z");
const WEEK_ID = getWeekId(startOfWeekInTz(THURSDAY));

/** Id determinístico, como o app passou a derivá-lo da linha do extrato. */
const REC_ID = "stmt-2026-09-itau-0001";

let firestore: admin.firestore.Firestore;
const workspaces: string[] = [];
const idempotencyKeys: string[] = [];

function newWorkspace(label: string): string {
    const workspaceId = `ws-recon-${label}-${Date.now()}`;
    workspaces.push(workspaceId);
    return workspaceId;
}

async function seedWorkspace(workspaceId: string, type: "personal" | "business"): Promise<void> {
    await firestore.doc(`workspaces/${workspaceId}`).set({
        name: type === "business" ? "Benav Labs" : "Casa",
        type,
        members: ["uid"],
        xp: 0,
        level: 1,
    });
}

/** A missão da semana, já com o contrato completo. As outras duas, concluídas. */
async function seedMission(workspaceId: string, templateKey: string): Promise<void> {
    const template = findMissionTemplate(templateKey)!;
    await firestore.doc(`workspaces/${workspaceId}/weekly_missions/${WEEK_ID}_${template.type}`).set({
        id: template.type,
        type: template.type,
        name: buildMissionName(template, "pt", { target: template.target }),
        status: "pending",
        progress: 0,
        target: template.target,
        rewardXp: template.rewardXp,
        weekId: WEEK_ID,
        templateKey: template.key,
        workspaceType: template.audience,
        actionPath: template.actionPath,
        nameKey: template.nameKey,
    });
    for (const other of ["consistency", "discipline", "organization"]) {
        if (other === template.type) continue;
        await firestore.doc(`workspaces/${workspaceId}/weekly_missions/${WEEK_ID}_${other}`).set({
            id: other, type: other, name: "x", status: "completed", progress: 1, target: 1,
            rewardXp: 0, weekId: WEEK_ID, templateKey: "x", workspaceType: template.audience,
            actionPath: "/planning", nameKey: "x",
        });
    }
}

function summary(overrides: Record<string, unknown> = {}): Record<string, any> {
    return {
        id: REC_ID,
        status: "completed",
        confirmedMatchesCount: 12,
        totalTransactionsProcessed: 12,
        createdTransactionsCount: 0,
        // A regra corporativa `reconciled_statements` conta documentos pela
        // faixa de `createdAt` — sem o campo, o extrato não entra na semana.
        createdAt: admin.firestore.Timestamp.fromDate(THURSDAY),
        ...overrides,
    };
}

/** Grava o resumo e chama o handler com o par que o Eventarc entregaria. */
async function writeAndTrigger(
    workspaceId: string,
    data: Record<string, any>,
    before: Record<string, any> | null,
    eventId: string
): Promise<void> {
    await firestore.doc(`workspaces/${workspaceId}/reconciliations/${REC_ID}`).set(data);
    idempotencyKeys.push(`${eventId}_${GAMIFICATION_ACTIONS.reconciliationWritten}`);
    await handleReconciliationWritten(before, data, { workspaceId, recId: REC_ID, eventId });
}

async function readWorkspace(workspaceId: string): Promise<Record<string, any>> {
    return (await firestore.doc(`workspaces/${workspaceId}`).get()).data()!;
}

async function readMission(workspaceId: string, type: string): Promise<Record<string, any>> {
    return (await firestore.doc(`workspaces/${workspaceId}/weekly_missions/${WEEK_ID}_${type}`).get()).data()!;
}

describe("conciliação: gamificação create-only (integração com emulador)", () => {
    beforeAll(async () => {
        if (admin.apps.length === 0) {
            admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
            admin.firestore().settings({ ignoreUndefinedProperties: false });
        }
        firestore = admin.firestore();
    });

    afterAll(async () => {
        jest.useRealTimers();
        for (const workspaceId of workspaces) {
            await firestore.recursiveDelete(firestore.doc(`workspaces/${workspaceId}`));
        }
        for (const key of idempotencyKeys) {
            await firestore.doc(`_idempotency/${key}`).delete().catch(() => undefined);
        }
        await Promise.all(admin.apps.map((app) => app?.delete()));
    });

    afterEach(() => {
        jest.useRealTimers();
    });

    it("a PRIMEIRA gravação concede badges, XP e progresso da missão", async () => {
        jest.useFakeTimers({ now: THURSDAY, doNotFake: ["nextTick", "setImmediate"] });

        const workspaceId = newWorkspace("primeira");
        await seedWorkspace(workspaceId, "personal");
        await seedMission(workspaceId, "personal_organization_reconcile_items");

        await writeAndTrigger(workspaceId, summary(), null, "evt-create");

        const workspace = await readWorkspace(workspaceId);
        const unlocked = Object.keys(workspace.unlockedBadges ?? {}).sort();
        // 12 itens conciliados sem criar lançamento manual nenhum.
        expect(unlocked).toEqual(["cash_detective", "reconcile_junior", "zero_friction"]);

        const template = findMissionTemplate("personal_organization_reconcile_items")!;
        const mission = await readMission(workspaceId, "organization");
        expect(mission.status).toBe("completed");
        expect(mission.progress).toBe(12);

        const esperado =
            BADGES.reconcile_junior.xpReward +
            BADGES.cash_detective.xpReward +
            BADGES.zero_friction.xpReward +
            template.rewardXp;
        expect(workspace.xp).toBe(esperado);
    });

    it("a SOBRESCRITA do mesmo resumo não soma XP, badge nem progresso", async () => {
        jest.useFakeTimers({ now: THURSDAY, doNotFake: ["nextTick", "setImmediate"] });

        const workspaceId = newWorkspace("sobrescrita");
        await seedWorkspace(workspaceId, "personal");
        await seedMission(workspaceId, "personal_organization_reconcile_items");

        const primeira = summary();
        await writeAndTrigger(workspaceId, primeira, null, "evt-create");

        const depoisDaPrimeira = await readWorkspace(workspaceId);
        const missaoDepoisDaPrimeira = await readMission(workspaceId, "organization");

        // Reconfirmar o mesmo extrato: MESMO id de documento, `event.id` NOVO.
        // É exatamente o evento que a idempotência por eventId deixa passar.
        await writeAndTrigger(workspaceId, summary(), primeira, "evt-overwrite");

        const depoisDaSegunda = await readWorkspace(workspaceId);
        expect(depoisDaSegunda.xp).toBe(depoisDaPrimeira.xp);
        expect(depoisDaSegunda.level).toBe(depoisDaPrimeira.level);
        expect(depoisDaSegunda.unlockedBadges).toEqual(depoisDaPrimeira.unlockedBadges);
        expect(await readMission(workspaceId, "organization")).toEqual(missaoDepoisDaPrimeira);
    });

    it("a sobrescrita sai antes da idempotência — não deixa nem o marcador", async () => {
        jest.useFakeTimers({ now: THURSDAY, doNotFake: ["nextTick", "setImmediate"] });

        const workspaceId = newWorkspace("marcador");
        await seedWorkspace(workspaceId, "personal");
        await seedMission(workspaceId, "personal_organization_reconcile_items");

        const primeira = summary();
        await writeAndTrigger(workspaceId, primeira, null, "evt-marcador-create");
        await writeAndTrigger(workspaceId, summary(), primeira, "evt-marcador-overwrite");

        const criado = await firestore
            .doc(`_idempotency/evt-marcador-create_${GAMIFICATION_ACTIONS.reconciliationWritten}`)
            .get();
        const sobrescrita = await firestore
            .doc(`_idempotency/evt-marcador-overwrite_${GAMIFICATION_ACTIONS.reconciliationWritten}`)
            .get();

        expect(criado.exists).toBe(true);
        // Cada sobrescrita gravaria um marcador com TTL de 30 dias que nunca
        // serve para nada — lixo proporcional ao número de reconfirmações.
        expect(sobrescrita.exists).toBe(false);
    });

    it("nem quando os NÚMEROS do resumo mudam entre as duas gravações", async () => {
        jest.useFakeTimers({ now: THURSDAY, doNotFake: ["nextTick", "setImmediate"] });

        const workspaceId = newWorkspace("numeros");
        await seedWorkspace(workspaceId, "personal");
        await seedMission(workspaceId, "personal_organization_reconcile_items");

        // Primeira passada: 3 itens. Não chega ao `cash_detective` (>= 10).
        const primeira = summary({ confirmedMatchesCount: 3, totalTransactionsProcessed: 3 });
        await writeAndTrigger(workspaceId, primeira, null, "evt-num-create");

        const depoisDaPrimeira = await readWorkspace(workspaceId);
        expect(Object.keys(depoisDaPrimeira.unlockedBadges ?? {})).not.toContain("cash_detective");

        // O usuário volta ao mesmo extrato e casa mais 9 linhas.
        await writeAndTrigger(
            workspaceId,
            summary({ confirmedMatchesCount: 12, totalTransactionsProcessed: 12 }),
            primeira,
            "evt-num-overwrite"
        );

        const depoisDaSegunda = await readWorkspace(workspaceId);
        // CONSEQUÊNCIA ACEITA do contrato create-only: os 9 itens novos não
        // contam. O badge de 10 itens não é concedido e o progresso da missão
        // não anda. É o preço de o efeito ser inequivocamente uma vez só —
        // está documentado no README, em "Conciliação: create-only".
        expect(depoisDaSegunda.xp).toBe(depoisDaPrimeira.xp);
        expect(Object.keys(depoisDaSegunda.unlockedBadges ?? {})).not.toContain("cash_detective");
        expect((await readMission(workspaceId, "organization")).progress).toBe(3);
    });

    it("a missão CORPORATIVA de conciliação também não conta duas vezes", async () => {
        jest.useFakeTimers({ now: THURSDAY, doNotFake: ["nextTick", "setImmediate"] });

        const workspaceId = newWorkspace("empresa");
        await seedWorkspace(workspaceId, "business");
        await seedMission(workspaceId, "business_organization_reconcile_statements");

        const primeira = summary();
        await writeAndTrigger(workspaceId, primeira, null, "evt-biz-create");

        const template = findMissionTemplate("business_organization_reconcile_statements")!;
        const depoisDaPrimeira = await readWorkspace(workspaceId);
        // A regra corporativa conta DOCUMENTOS de conciliação na semana, e há
        // um só — o alvo é 1.
        expect((await readMission(workspaceId, "organization")).status).toBe("completed");
        // Os badges de conciliação são `both`: valem na empresa também.
        expect(depoisDaPrimeira.xp).toBe(
            BADGES.reconcile_junior.xpReward +
            BADGES.cash_detective.xpReward +
            BADGES.zero_friction.xpReward +
            template.rewardXp
        );

        await writeAndTrigger(workspaceId, summary(), primeira, "evt-biz-overwrite");

        expect((await readWorkspace(workspaceId)).xp).toBe(depoisDaPrimeira.xp);
    });

    it("o resumo criado ainda NÃO concluído não concede nada", async () => {
        jest.useFakeTimers({ now: THURSDAY, doNotFake: ["nextTick", "setImmediate"] });

        const workspaceId = newWorkspace("pendente");
        await seedWorkspace(workspaceId, "personal");
        await seedMission(workspaceId, "personal_organization_reconcile_items");

        await writeAndTrigger(workspaceId, summary({ status: "processing" }), null, "evt-pendente");

        const workspace = await readWorkspace(workspaceId);
        expect(workspace.xp).toBe(0);
        expect(workspace.unlockedBadges ?? {}).toEqual({});
    });
});
