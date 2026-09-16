// ofx-js é ESM puro e não é transformado pelo ts-jest; não é usado aqui.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

const mockDoc = jest.fn();
const mockCollection = jest.fn();

jest.mock("firebase-admin", () => {
    class FakeTimestamp {
        constructor(private readonly ms: number) {
        }
        static fromDate(date: Date) {
            return new FakeTimestamp(date.getTime());
        }
        toMillis() {
            return this.ms;
        }
        toDate() {
            return new Date(this.ms);
        }
    }

    return {
        firestore: Object.assign(
            () => ({ collection: mockCollection }),
            {
                Timestamp: FakeTimestamp,
                FieldValue: { serverTimestamp: () => "SERVER_TIMESTAMP" },
            }
        ),
    };
});

import {
    IdempotencyServiceImpl,
    IDEMPOTENCY_STALE_RUNNING_MS,
    IDEMPOTENCY_TTL_DAYS,
} from "../core/services/idempotency.service";

/** Erro equivalente ao ALREADY_EXISTS (gRPC 6) devolvido por `create()`. */
function alreadyExistsError() {
    const error: any = new Error("6 ALREADY_EXISTS: entity already exists");
    error.code = 6;
    return error;
}

type DocState = {
    exists: boolean;
    data: any;
};

/**
 * DocumentReference falso com o mesmo contrato usado pelo serviço:
 * `create` falha com ALREADY_EXISTS quando o doc existe.
 */
function makeDocRef(initial: DocState = { exists: false, data: null }) {
    const state = { ...initial };

    const ref = {
        id: "evt-1_acao",
        state,
        create: jest.fn(async (data: any) => {
            if (state.exists) throw alreadyExistsError();
            state.exists = true;
            state.data = { ...data };
        }),
        get: jest.fn(async () => ({
            exists: state.exists,
            data: () => state.data,
        })),
        update: jest.fn(async (data: any) => {
            if (!state.exists) throw new Error("NOT_FOUND");
            state.data = { ...state.data, ...data };
        }),
        delete: jest.fn(async () => {
            state.exists = false;
            state.data = null;
        }),
    };

    return ref;
}

describe("IdempotencyServiceImpl.runIdempotency", () => {
    let service: IdempotencyServiceImpl;

    beforeEach(() => {
        // jest.config.js usa resetMocks: true — as implementações precisam ser
        // reinstaladas a cada teste.
        mockCollection.mockImplementation(() => ({ doc: mockDoc }));
        service = new IdempotencyServiceImpl();
    });

    it("cria o marcador ANTES da ação e o fecha com status done", async () => {
        const docRef = makeDocRef();
        mockDoc.mockReturnValue(docRef);

        const order: string[] = [];
        docRef.create.mockImplementation(async () => {
            order.push("create");
            docRef.state.exists = true;
            docRef.state.data = { status: "running" };
        });

        const result = await service.runIdempotency("evt-1", "acao", async () => {
            order.push("action");
            return "resultado";
        });

        expect(result).toBe("resultado");
        expect(order).toEqual(["create", "action"]);
        expect(mockCollection).toHaveBeenCalledWith("_idempotency");
        expect(mockDoc).toHaveBeenCalledWith("evt-1_acao");

        const created = docRef.create.mock.calls[0][0];
        expect(created.status).toBe("running");
        expect(created.eventId).toBe("evt-1");
        expect(created.actionName).toBe("acao");

        expect(docRef.update).toHaveBeenCalledWith(
            expect.objectContaining({ status: "done" })
        );
    });

    it("grava expiresAt = startedAt + 30 dias", async () => {
        const docRef = makeDocRef();
        mockDoc.mockReturnValue(docRef);

        await service.runIdempotency("evt-ttl", "acao", async () => undefined);

        const created: any = docRef.create.mock.calls[0][0];
        const deltaMs = created.expiresAt.toMillis() - created.startedAt.toMillis();
        expect(deltaMs).toBe(IDEMPOTENCY_TTL_DAYS * 24 * 60 * 60 * 1000);
    });

    it("não executa a ação quando o create falha com ALREADY_EXISTS (marcador done)", async () => {
        const docRef = makeDocRef({
            exists: true,
            data: { status: "done", startedAt: null },
        });
        mockDoc.mockReturnValue(docRef);

        const action = jest.fn(async () => "nunca");
        const result = await service.runIdempotency("evt-2", "acao", action);

        expect(action).not.toHaveBeenCalled();
        expect(result).toBeUndefined();
        expect(docRef.update).not.toHaveBeenCalled();
    });

    it("trata marcador legado (sem status) como já processado", async () => {
        const docRef = makeDocRef({
            exists: true,
            data: { eventId: "evt-3", actionName: "acao", processedAt: "x" },
        });
        mockDoc.mockReturnValue(docRef);

        const action = jest.fn(async () => "nunca");
        await service.runIdempotency("evt-3", "acao", action);

        expect(action).not.toHaveBeenCalled();
        expect(docRef.delete).not.toHaveBeenCalled();
    });

    it("não executa a ação quando há um marcador running recente", async () => {
        const startedAt = { toMillis: () => Date.now() - 1000 };
        const docRef = makeDocRef({ exists: true, data: { status: "running", startedAt } });
        mockDoc.mockReturnValue(docRef);

        const action = jest.fn(async () => "nunca");
        await service.runIdempotency("evt-4", "acao", action);

        expect(action).not.toHaveBeenCalled();
        expect(docRef.delete).not.toHaveBeenCalled();
    });

    it("reexecuta quando o marcador running está abandonado (mais de 10 min)", async () => {
        const startedAt = { toMillis: () => Date.now() - (IDEMPOTENCY_STALE_RUNNING_MS + 60_000) };
        const docRef = makeDocRef({ exists: true, data: { status: "running", startedAt } });
        mockDoc.mockReturnValue(docRef);

        const action = jest.fn(async () => "rodou");
        const result = await service.runIdempotency("evt-5", "acao", action);

        expect(action).toHaveBeenCalledTimes(1);
        expect(result).toBe("rodou");
        // apagou o abandonado e recriou o marcador
        expect(docRef.delete).toHaveBeenCalledTimes(1);
        expect(docRef.create).toHaveBeenCalledTimes(2);
        expect(docRef.update).toHaveBeenCalledWith(
            expect.objectContaining({ status: "done" })
        );
    });

    it("reexecuta quando o marcador running não tem startedAt legível", async () => {
        const docRef = makeDocRef({ exists: true, data: { status: "running" } });
        mockDoc.mockReturnValue(docRef);

        const action = jest.fn(async () => "rodou");
        await service.runIdempotency("evt-6", "acao", action);

        expect(action).toHaveBeenCalledTimes(1);
    });

    it("apaga o marcador e repropaga o erro quando a ação falha", async () => {
        const docRef = makeDocRef();
        mockDoc.mockReturnValue(docRef);

        const boom = new Error("falha da ação");
        await expect(
            service.runIdempotency("evt-7", "acao", async () => {
                throw boom;
            })
        ).rejects.toBe(boom);

        expect(docRef.delete).toHaveBeenCalledTimes(1);
        expect(docRef.update).not.toHaveBeenCalled();
        expect(docRef.state.exists).toBe(false);
    });

    it("após uma falha, a próxima tentativa do mesmo evento reexecuta a ação", async () => {
        const docRef = makeDocRef();
        mockDoc.mockReturnValue(docRef);

        await expect(
            service.runIdempotency("evt-8", "acao", async () => {
                throw new Error("falha");
            })
        ).rejects.toThrow("falha");

        const action = jest.fn(async () => "ok no retry");
        const result = await service.runIdempotency("evt-8", "acao", action);

        expect(action).toHaveBeenCalledTimes(1);
        expect(result).toBe("ok no retry");
    });

    it("sai sem rodar a ação quando outro processo reivindica a chave na corrida", async () => {
        // Doc some entre o create (ALREADY_EXISTS) e o get, e o segundo create
        // também falha: outro processo ficou com a chave.
        const docRef = makeDocRef({ exists: true, data: { status: "running", startedAt: { toMillis: () => Date.now() } } });
        mockDoc.mockReturnValue(docRef);
        docRef.get.mockResolvedValueOnce({ exists: false, data: () => null } as any);

        const action = jest.fn(async () => "nunca");
        await service.runIdempotency("evt-9", "acao", action);

        expect(action).not.toHaveBeenCalled();
    });

    it("propaga erros do create que não sejam ALREADY_EXISTS", async () => {
        const docRef = makeDocRef();
        mockDoc.mockReturnValue(docRef);
        docRef.create.mockRejectedValueOnce(new Error("PERMISSION_DENIED"));

        const action = jest.fn(async () => "nunca");
        await expect(service.runIdempotency("evt-10", "acao", action)).rejects.toThrow("PERMISSION_DENIED");
        expect(action).not.toHaveBeenCalled();
    });
});
