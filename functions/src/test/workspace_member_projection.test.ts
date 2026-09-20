// ofx-js é ESM puro e não é transformado pelo ts-jest; não é usado aqui.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

const mockUsersGet = jest.fn();

jest.mock("firebase-admin", () => ({
    firestore: Object.assign(
        () => ({
            collection: () => ({
                where: () => ({ get: mockUsersGet }),
                doc: () => ({}),
            }),
        }),
        {
            FieldPath: { documentId: () => "__name__" },
            FieldValue: {
                arrayUnion: (...values: string[]) => ({ arrayUnion: values }),
                arrayRemove: (...values: string[]) => ({ arrayRemove: values }),
                serverTimestamp: () => "now",
            },
        }
    ),
}));

import { WorkspaceRepositoryImpl } from "../features/workspace/data/repositories/workspace.repository.impl";

/**
 * A projeção de `getWorkspaceMembers`.
 *
 * O app lê `users/{uid}` só do PRÓPRIO usuário — as rules não deixam ler o do
 * parceiro —, então tudo o que um membro sabe do outro passa por esta lista.
 * Quando o avatar entrou no perfil, ele precisou entrar aqui também: sem isso
 * a escolha do parceiro ficaria gravada no Firestore e a Arena nunca a veria.
 */
function comUsuarios(docs: Array<{ id: string; data: Record<string, unknown> }>) {
    mockUsersGet.mockResolvedValue({
        forEach: (fn: (doc: { id: string; data: () => Record<string, unknown> }) => void) =>
            docs.forEach((d) => fn({ id: d.id, data: () => d.data })),
    });
}

describe("WorkspaceRepositoryImpl.getMembersByIds", () => {
    beforeEach(() => mockUsersGet.mockReset());

    it("entrega o avatar escolhido pelo membro", async () => {
        comUsuarios([
            {
                id: "u1",
                data: { email: "a@b.c", displayName: "Gabriel", avatar: "smith" },
            },
        ]);

        const membros = await new WorkspaceRepositoryImpl().getMembersByIds(["u1"]);

        expect(membros).toHaveLength(1);
        expect(membros[0].avatar).toBe("smith");
        expect(membros[0].displayName).toBe("Gabriel");
    });

    it("quem nunca escolheu vem sem o campo, e não com um padrão do servidor", async () => {
        comUsuarios([{ id: "u1", data: { email: "a@b.c" } }]);

        const membros = await new WorkspaceRepositoryImpl().getMembersByIds(["u1"]);

        // Quem decide o boneco de quem não escolheu é o APP: ele tem a ordem
        // de entrada no workspace, que o servidor não tem por que replicar.
        expect(membros[0].avatar).toBeUndefined();
    });

    it("lista vazia não consulta o Firestore", async () => {
        expect(await new WorkspaceRepositoryImpl().getMembersByIds([])).toEqual([]);
        expect(mockUsersGet).not.toHaveBeenCalled();
    });
});
