// ofx-js é ESM puro e não é transformado pelo ts-jest; não é usado aqui.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import {
    IdempotencyServiceImpl,
    IDEMPOTENCY_TTL_DAYS,
} from "../../core/services/idempotency.service";

/**
 * Idempotência contra o emulador do Firestore.
 *
 * O ponto do teste é o que o mock não consegue provar: que o `create()` do
 * Firestore real recusa a segunda reivindicação da mesma chave, e que o
 * marcador sobrevive com `status: done` e `expiresAt`.
 */
describe("Idempotência (integração com emulador do Firestore)", () => {
    let firestore: admin.firestore.Firestore;
    let service: IdempotencyServiceImpl;

    beforeAll(() => {
        if (admin.apps.length === 0) {
            admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
            admin.firestore().settings({ ignoreUndefinedProperties: false });
        }

        firestore = admin.firestore();
        service = new IdempotencyServiceImpl();
    });

    const markerFor = (eventId: string, action: string) =>
        firestore.collection("_idempotency").doc(`${eventId}_${action}`);

    it("executa a ação uma única vez para dois processamentos do mesmo eventId", async () => {
        const eventId = `evt-int-${Date.now()}`;
        const action = "acaoIntegrada";
        let executions = 0;

        const first = await service.runIdempotency(eventId, action, async () => {
            executions++;
            return "primeiro";
        });

        const second = await service.runIdempotency(eventId, action, async () => {
            executions++;
            return "segundo";
        });

        expect(executions).toBe(1);
        expect(first).toBe("primeiro");
        expect(second).toBeUndefined();

        const marker = await markerFor(eventId, action).get();
        expect(marker.exists).toBe(true);
        expect(marker.data()?.status).toBe("done");
        expect(marker.data()?.eventId).toBe(eventId);
        expect(marker.data()?.finishedAt).toBeDefined();
    });

    it("grava expiresAt 30 dias à frente de startedAt", async () => {
        const eventId = `evt-int-ttl-${Date.now()}`;
        await service.runIdempotency(eventId, "acaoTtl", async () => undefined);

        const data = (await markerFor(eventId, "acaoTtl").get()).data()!;
        const startedAt: admin.firestore.Timestamp = data.startedAt;
        const expiresAt: admin.firestore.Timestamp = data.expiresAt;

        expect(expiresAt.toMillis() - startedAt.toMillis())
            .toBe(IDEMPOTENCY_TTL_DAYS * 24 * 60 * 60 * 1000);
    });

    it("ações diferentes do mesmo evento são independentes", async () => {
        const eventId = `evt-int-multi-${Date.now()}`;
        const executed: string[] = [];

        await service.runIdempotency(eventId, "acaoA", async () => {
            executed.push("A");
        });
        await service.runIdempotency(eventId, "acaoB", async () => {
            executed.push("B");
        });
        await service.runIdempotency(eventId, "acaoA", async () => {
            executed.push("A de novo");
        });

        expect(executed).toEqual(["A", "B"]);
    });

    it("uma falha apaga o marcador e a tentativa seguinte reexecuta a ação", async () => {
        const eventId = `evt-int-falha-${Date.now()}`;
        const action = "acaoQueFalha";

        await expect(
            service.runIdempotency(eventId, action, async () => {
                throw new Error("falha simulada");
            })
        ).rejects.toThrow("falha simulada");

        const afterFailure = await markerFor(eventId, action).get();
        expect(afterFailure.exists).toBe(false);

        let executed = false;
        await service.runIdempotency(eventId, action, async () => {
            executed = true;
        });

        expect(executed).toBe(true);
        expect((await markerFor(eventId, action).get()).data()?.status).toBe("done");
    });

    it("duas execuções concorrentes do mesmo evento rodam a ação uma vez só", async () => {
        const eventId = `evt-int-corrida-${Date.now()}`;
        let executions = 0;

        const run = () => service.runIdempotency(eventId, "acaoConcorrente", async () => {
            executions++;
            // Segura o marcador `running` por um instante.
            await new Promise((resolve) => setTimeout(resolve, 50));
            return "ok";
        });

        await Promise.all([run(), run()]);

        expect(executions).toBe(1);
    });

    it("um marcador running ANTIGO é tratado como abandonado e libera a reexecução", async () => {
        const eventId = `evt-int-abandonado-${Date.now()}`;
        const action = "acaoAbandonada";

        // Simula a instância que morreu no meio: marcador running de 30 min atrás.
        const startedAt = new Date(Date.now() - 30 * 60 * 1000);
        await markerFor(eventId, action).create({
            eventId,
            actionName: action,
            status: "running",
            startedAt: admin.firestore.Timestamp.fromDate(startedAt),
            expiresAt: admin.firestore.Timestamp.fromDate(new Date(startedAt.getTime() + 86400000)),
        });

        let executed = false;
        await service.runIdempotency(eventId, action, async () => {
            executed = true;
        });

        expect(executed).toBe(true);

        const marker = (await markerFor(eventId, action).get()).data()!;
        expect(marker.status).toBe("done");
        expect(marker.startedAt.toMillis()).toBeGreaterThan(startedAt.getTime());
    });
});
