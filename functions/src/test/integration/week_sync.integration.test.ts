// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import { WeekSyncServiceImpl } from "../../core/services/week_sync.service";
import { getWeekId, getWeekStart } from "../../core/utils/week.utils";

/**
 * F1.9 — marcador da semana corrente no documento do workspace.
 *
 * O cliente lê `currentWeekId`/`currentWeekStart` em vez de calcular a semana
 * por conta própria (é no sábado à noite que as duas contas divergiam).
 */

const SABADO_NOITE = new Date("2026-09-13T00:30:00.000Z"); // sábado 21h30 em SP
const DOMINGO = new Date("2026-09-13T03:30:00.000Z"); // domingo 00h30 em SP

let firestore: admin.firestore.Firestore;
const workspaces: string[] = [];

function newWorkspace(label: string): string {
    const workspaceId = `ws-week-${label}-${Date.now()}`;
    workspaces.push(workspaceId);
    return workspaceId;
}

async function readWorkspace(workspaceId: string): Promise<Record<string, any> | undefined> {
    const doc = await firestore.doc(`workspaces/${workspaceId}`).get();
    return doc.exists ? doc.data() : undefined;
}

describe("Semana corrente do workspace (integração com emulador do Firestore)", () => {
    beforeAll(async () => {
        if (admin.apps.length === 0) {
            admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
            admin.firestore().settings({ ignoreUndefinedProperties: false });
        }
        firestore = admin.firestore();
    });

    afterAll(async () => {
        for (const workspaceId of workspaces) {
            await firestore.recursiveDelete(firestore.doc(`workspaces/${workspaceId}`));
        }
        await Promise.all(admin.apps.map((app) => app?.delete()));
    });

    it("grava o id e o início da semana, e não reescreve quando já está certo", async () => {
        const workspaceId = newWorkspace("demanda");
        await firestore.doc(`workspaces/${workspaceId}`).set({ name: "Casa", type: "personal", members: ["uid"] });

        const service = new WeekSyncServiceImpl();

        expect(await service.ensureCurrentWeek(workspaceId, SABADO_NOITE)).toBe(true);

        const marker = await readWorkspace(workspaceId);
        expect(marker).toMatchObject({ currentWeekId: "2026-W36" });
        expect((marker!.currentWeekStart as admin.firestore.Timestamp).toDate().toISOString())
            .toBe(getWeekStart(SABADO_NOITE).toISOString());

        // Mesma semana: nada a fazer (e a memória da instância evita a leitura).
        expect(await service.ensureCurrentWeek(workspaceId, SABADO_NOITE)).toBe(false);

        // Três horas depois já é domingo em São Paulo: a semana virou.
        expect(await service.ensureCurrentWeek(workspaceId, DOMINGO)).toBe(true);
        expect((await readWorkspace(workspaceId))!.currentWeekId).toBe("2026-W37");
    });

    it("não cria o documento de um workspace inexistente", async () => {
        const service = new WeekSyncServiceImpl();
        const workspaceId = `ws-week-fantasma-${Date.now()}`;

        expect(await service.ensureCurrentWeek(workspaceId, DOMINGO)).toBe(false);
        expect(await readWorkspace(workspaceId)).toBeUndefined();
    });

    it("o cron semanal atualiza só quem está atrasado", async () => {
        const atrasado = newWorkspace("atrasado");
        const emDia = newWorkspace("em-dia");

        await firestore.doc(`workspaces/${atrasado}`).set({
            name: "Atrasado",
            type: "personal",
            members: ["uid"],
            currentWeekId: "2020-W01",
        });
        await firestore.doc(`workspaces/${emDia}`).set({
            name: "Em dia",
            type: "personal",
            members: ["uid"],
            currentWeekId: getWeekId(DOMINGO),
        });

        const service = new WeekSyncServiceImpl();
        const result = await service.syncAllWorkspaces(DOMINGO);

        expect(result.scanned).toBeGreaterThanOrEqual(2);
        expect(result.updated).toBeGreaterThanOrEqual(1);

        expect((await readWorkspace(atrasado))!.currentWeekId).toBe("2026-W37");
        expect((await readWorkspace(emDia))!.currentWeekId).toBe("2026-W37");
        // O que já estava em dia não recebeu carimbo novo.
        expect((await readWorkspace(emDia))!.currentWeekUpdatedAt).toBeUndefined();
    });
});
