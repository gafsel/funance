// ofx-js é ESM puro e não é transformado pelo ts-jest; não é usado aqui.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

const mockWorkspaceGet = jest.fn();

jest.mock("firebase-admin", () => ({
    firestore: Object.assign(
        () => ({
            collection: () => ({
                doc: () => ({ get: mockWorkspaceGet }),
            }),
        }),
        {
            FieldValue: { arrayRemove: (...values: string[]) => ({ arrayRemove: values }) },
        }
    ),
}));

import { HttpsError } from "firebase-functions/v2/https";
import { WorkspaceServiceImpl } from "../features/workspace/domain/services/workspace.service.impl";

const DONO = "uid-dono";
const CONVIDADO = "uid-convidado";

/**
 * `assertWorkspaceOwner` lê o workspace direto pelo Admin SDK; o repositório
 * injetado é uma segunda leitura. Os dois precisam ver a mesma lista.
 */
function comMembros(members: string[] | undefined, exists = true) {
    mockWorkspaceGet.mockResolvedValue({
        exists,
        data: () => (members === undefined ? {} : { members }),
    });

    const repository = {
        getWorkspaceById: jest.fn().mockResolvedValue(
            exists ? { id: "ws-1", members } : null
        ),
        removeMember: jest.fn().mockResolvedValue(undefined),
        addMember: jest.fn(),
        getMembersByIds: jest.fn(),
        getUserWorkspaces: jest.fn(),
        createWorkspace: jest.fn(),
        updateUploadProgress: jest.fn(),
    };

    return { repository, service: new WorkspaceServiceImpl(repository as any) };
}

async function codeOf(promise: Promise<unknown>): Promise<string> {
    try {
        await promise;
    }
    catch (error) {
        if (error instanceof HttpsError) {
            return error.code;
        }
        throw error;
    }

    throw new Error("esperava um HttpsError, mas a chamada passou");
}

describe("WorkspaceServiceImpl.removeWorkspaceMember", () => {
    it("o dono remove um membro", async () => {
        const { repository, service } = comMembros([DONO, CONVIDADO]);

        await service.removeWorkspaceMember("ws-1", CONVIDADO, DONO);

        expect(repository.removeMember).toHaveBeenCalledWith("ws-1", CONVIDADO);
    });

    it("um membro comum não remove ninguém", async () => {
        const { repository, service } = comMembros([DONO, CONVIDADO]);

        expect(
            await codeOf(service.removeWorkspaceMember("ws-1", DONO, CONVIDADO))
        ).toBe("permission-denied");

        expect(repository.removeMember).not.toHaveBeenCalled();
    });

    it("quem nem é membro não remove ninguém", async () => {
        const { repository, service } = comMembros([DONO, CONVIDADO]);

        expect(
            await codeOf(
                service.removeWorkspaceMember("ws-1", CONVIDADO, "uid-estranho")
            )
        ).toBe("permission-denied");

        expect(repository.removeMember).not.toHaveBeenCalled();
    });

    it("o dono não remove a si mesmo", async () => {
        const { repository, service } = comMembros([DONO, CONVIDADO]);

        expect(
            await codeOf(service.removeWorkspaceMember("ws-1", DONO, DONO))
        ).toBe("failed-precondition");

        expect(repository.removeMember).not.toHaveBeenCalled();
    });

    it("remover quem não é membro devolve not-found", async () => {
        const { repository, service } = comMembros([DONO, CONVIDADO]);

        expect(
            await codeOf(
                service.removeWorkspaceMember("ws-1", "uid-nunca-entrou", DONO)
            )
        ).toBe("not-found");

        expect(repository.removeMember).not.toHaveBeenCalled();
    });

    it("workspace inexistente devolve not-found", async () => {
        const { repository, service } = comMembros(undefined, false);

        expect(
            await codeOf(service.removeWorkspaceMember("ws-1", CONVIDADO, DONO))
        ).toBe("not-found");

        expect(repository.removeMember).not.toHaveBeenCalled();
    });
});

describe("WorkspaceServiceImpl.getWorkspaceMembers", () => {
    it("membro comum pode listar", async () => {
        const { repository, service } = comMembros([DONO, CONVIDADO]);
        repository.getMembersByIds.mockResolvedValue([{ id: DONO }]);

        await service.getWorkspaceMembers("ws-1", CONVIDADO);

        expect(repository.getMembersByIds).toHaveBeenCalledWith([DONO, CONVIDADO]);
    });

    it("quem não é membro não lista", async () => {
        const { service } = comMembros([DONO]);

        expect(
            await codeOf(service.getWorkspaceMembers("ws-1", "uid-estranho"))
        ).toBe("permission-denied");
    });
});
