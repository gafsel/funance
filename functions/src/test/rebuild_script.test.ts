/**
 * `scripts/rebuild_workspace.ts`: flags e execução em lote (`--all-workspaces`).
 *
 * O núcleo do job é testado em `rebuild.test.ts` e na integração; aqui o que
 * importa é a camada de script — quais workspaces ele escolhe, se continua
 * depois de um workspace que falha e se o resumo final fecha.
 */

// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado aqui.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import {
    RebuildRunner,
    ScriptOptions,
    formatReport,
    formatTotals,
    parseArgs,
    runRebuild,
} from "../scripts/rebuild_workspace";
import { RebuildReport } from "../features/finance/domain/services/rebuild.service";

const silent = () => undefined;

function emptyDiff() {
    return { toCreate: 0, toUpdate: 0, toDelete: 0, unchanged: 0, residual: 0, generalPlannedChanges: 0, samples: [] };
}

function report(
    workspaceId: string,
    totalChanges: number,
    writesCommitted = 0,
    installmentsWithoutCategory = 0
): RebuildReport {
    return {
        workspaceId,
        mode: writesCommitted > 0 ? "apply" : "dryRun",
        rebuildPlanning: false,
        durationMs: 1,
        scanned: { installments: 0, installmentsRemoved: 0, installmentsWithoutCategory, accounts: 0, categoryPlannings: 0 },
        diff: { balances: emptyDiff(), periodSummaries: emptyDiff(), weeklyXp: emptyDiff() },
        totalChanges,
        writesCommitted,
    };
}

/** Firestore falso: só `collection("workspaces").listDocuments()`. */
function buildFirestore(ids: string[]): any {
    return {
        collection: (name: string) => {
            if (name !== "workspaces") throw new Error(`coleção inesperada: ${name}`);
            return {
                async listDocuments() {
                    return ids.map((id) => ({ id }));
                },
            };
        },
    };
}

function buildService(behaviour: (workspaceId: string) => RebuildReport): RebuildRunner & { calls: Array<{ id: string, options: any }> } {
    const calls: Array<{ id: string, options: any }> = [];
    return {
        calls,
        async rebuildWorkspace(workspaceId: string, options: Record<string, any>) {
            calls.push({ id: workspaceId, options });
            return behaviour(workspaceId);
        },
    };
}

const baseOptions: ScriptOptions = {
    allWorkspaces: false,
    dryRun: true,
    pruneResidual: false,
    rebuildPlanning: false,
};

describe("rebuild_workspace — parseArgs", () => {
    it("dry-run é o padrão e --all-workspaces é reconhecida", () => {
        expect(parseArgs([])).toMatchObject({ dryRun: true, allWorkspaces: false });
        expect(parseArgs(["--all-workspaces"])).toMatchObject({ dryRun: true, allWorkspaces: true });
        expect(parseArgs(["--all-workspaces", "--apply"])).toMatchObject({ dryRun: false, allWorkspaces: true });
    });

    it("mantém as demais flags", () => {
        expect(parseArgs([
            "--workspace=w1", "--project=p1", "--page-size=100",
            "--chunk-size=50", "--sample-limit=5", "--prune-residual", "--rebuild-planning",
        ])).toMatchObject({
            workspaceId: "w1",
            projectId: "p1",
            pageSize: 100,
            chunkSize: 50,
            sampleLimit: 5,
            pruneResidual: true,
            rebuildPlanning: true,
        });
    });
});

describe("rebuild_workspace — formatReport", () => {
    it("sempre imprime a linha das parcelas sem categoria", () => {
        const text = formatReport(report("w1", 0));

        expect(text).toContain("parcelas sem categoria (category.id vazio, fora dos period_summaries)=0");
        // Zero não pede ação nenhuma.
        expect(text).not.toContain("fix_empty_category");
    });

    it("com parcelas quebradas, aponta o script de correção", () => {
        const text = formatReport(report("w1", 0, 0, 7));

        expect(text).toContain("parcelas sem categoria (category.id vazio, fora dos period_summaries)=7");
        expect(text).toContain("rode fix_empty_category e refaça o rebuild");
    });
});

describe("rebuild_workspace — runRebuild", () => {
    it("sem --all-workspaces roda só o workspace pedido", async () => {
        const service = buildService((id) => report(id, 3));
        const firestore = buildFirestore(["w1", "w2", "w3"]);

        const summary = await runRebuild(firestore, service, { ...baseOptions, workspaceId: "w2" }, silent);

        expect(service.calls.map((call) => call.id)).toEqual(["w2"]);
        expect(summary.totalChanges).toBe(3);
        expect(summary.failures).toEqual([]);
    });

    it("com --all-workspaces percorre todos, em ordem, um de cada vez", async () => {
        const service = buildService((id) => report(id, 1, 2));
        const firestore = buildFirestore(["w3", "w1", "w2"]);

        const summary = await runRebuild(firestore, service, { ...baseOptions, allWorkspaces: true }, silent);

        expect(service.calls.map((call) => call.id)).toEqual(["w1", "w2", "w3"]);
        expect(summary.reports).toHaveLength(3);
        expect(summary.totalChanges).toBe(3);
        expect(summary.writesCommitted).toBe(6);
    });

    it("repassa as opções para cada workspace", async () => {
        const service = buildService((id) => report(id, 0));
        const firestore = buildFirestore(["w1"]);

        await runRebuild(firestore, service, {
            ...baseOptions,
            allWorkspaces: true,
            dryRun: false,
            pageSize: 100,
            chunkSize: 50,
            sampleLimit: 5,
            pruneResidual: true,
            rebuildPlanning: true,
        }, silent);

        expect(service.calls[0].options).toEqual({
            dryRun: false,
            pageSize: 100,
            chunkSize: 50,
            sampleLimit: 5,
            pruneResidual: true,
            rebuildPlanning: true,
        });
    });

    it("um workspace que falha não interrompe os demais", async () => {
        const service = buildService((id) => {
            if (id === "w2") throw new Error("boom");
            return report(id, 1);
        });
        const firestore = buildFirestore(["w1", "w2", "w3"]);

        const summary = await runRebuild(firestore, service, { ...baseOptions, allWorkspaces: true }, silent);

        expect(service.calls.map((call) => call.id)).toEqual(["w1", "w2", "w3"]);
        expect(summary.reports.map((r) => r.workspaceId)).toEqual(["w1", "w3"]);
        expect(summary.failures).toEqual(["w2"]);
        expect(summary.totalChanges).toBe(2);
    });

    it("formatTotals fecha a contagem e lista as falhas", () => {
        const summary = {
            reports: [report("w1", 1), report("w3", 1)],
            failures: ["w2"],
            totalChanges: 2,
            writesCommitted: 0,
        };

        const text = formatTotals(summary);
        expect(text).toContain("2 workspace(s) processado(s), 1 falha(s)");
        expect(text).toContain("total de mudanças=2");
        expect(text).toContain("falharam: w2");
    });
});
