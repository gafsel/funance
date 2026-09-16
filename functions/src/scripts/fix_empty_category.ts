/**
 * Correção pontual: parcelas e orders com `category.id` VAZIO.
 *
 * Contexto: a conciliação/transação automática chegou a gravar
 * `category = {id: "", name: "Supermercado", ...}` — o nome veio da IA, mas o
 * documento da categoria nunca foi resolvido. Um id vazio vira um segmento
 * vazio de `FieldPath` na escrita de `period_summaries.categories.<id>`, e o
 * SDK rejeita o documento inteiro ("Element at index 0 should not be an empty
 * string"): o gatilho de sumário quebra e o `rebuild_workspace --apply` morre
 * no commit (o dry-run não acusa, porque não chega a montar a referência).
 *
 * O código já foi endurecido: categoria sem id é tratada como SEM CATEGORIA
 * para efeito de sumário (gatilho e rebuild), então nada mais quebra — mas
 * essas parcelas ficam fora dos `period_summaries` até serem consertadas. É o
 * que este script faz.
 *
 * O que ele NÃO faz: adivinhar categoria. A escrita só acontece quando o
 * `category.name` do documento quebrado BATE (ignorando maiúsculas/minúsculas e
 * espaços nas pontas) com o `name` da categoria de destino, lida de
 * `workspaces/{workspaceId}/categories/{categoryId}`. Quando não bate, o
 * documento é apenas LISTADO, para decisão humana. Por isso a correção é feita
 * uma categoria de cada vez (`--category-id`).
 *
 * Características:
 *  - DRY-RUN POR PADRÃO: só escreve com `--apply` explícito.
 *  - `--category-id` é OBRIGATÓRIO com `--apply` (sem ele o script só lista).
 *  - IDEMPOTENTE: depois da correção o `category.id` deixa de ser vazio e o
 *    documento não é mais encontrado pela consulta. Pode rodar N vezes.
 *  - PRESERVA os demais campos da categoria embutida (nome, ícone, cor, tipo):
 *    a escrita é um `set({category: {...atual, id}}, {merge: true})`.
 *  - Log por documento, com resumo final.
 *
 * DEPOIS DE APLICAR: rode `rebuild_workspace` (dry-run e depois `--apply`) no
 * workspace afetado — é ele quem recoloca essas parcelas nos
 * `period_summaries`; o gatilho só reage a escritas novas.
 *
 * ATENÇÃO: este script NUNCA foi executado contra o projeto real
 * (`funance-cef1b`). Ele escreve com Admin SDK e ignora as security rules.
 * Rode o dry-run, revise a saída e só então aplique.
 *
 * Uso:
 *   cd functions
 *   npm run build
 *   # 1) Levantamento (padrão, não escreve nada): lista tudo que está quebrado
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/fix_empty_category.js --project=<projectId>
 *   # 2) Simulação da correção de UMA categoria num workspace
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/fix_empty_category.js --project=<projectId> \
 *       --workspace=<workspaceId> --category-id=<categoryId>
 *   # 3) Execução real (somente após revisar a saída do dry-run)
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/fix_empty_category.js --project=<projectId> \
 *       --workspace=<workspaceId> --category-id=<categoryId> --apply
 *
 * Flags:
 *   --apply              executa as escritas (sem ela, dry-run)
 *   --project=<id>       projectId do Firebase (default: GOOGLE_CLOUD_PROJECT)
 *   --workspace=<id>     limita a varredura a um workspace (sem ela, base inteira)
 *   --category-id=<id>   categoria de destino, lida de
 *                        `workspaces/{wid}/categories/{id}`; obrigatória com --apply
 */

import * as admin from "firebase-admin";

export interface FixOptions {
    dryRun: boolean;
    workspaceId?: string;
    categoryId?: string;
}

export interface FixSummary {
    /** Documentos encontrados com `category.id` vazio. */
    scanned: number;
    /** Destes, quantos são parcelas. */
    installments: number;
    /** Destes, quantos são orders. */
    orders: number;
    /** Corrigidos (ou que seriam corrigidos, em dry-run). */
    fixed: number;
    /** Só listados: o nome embutido não bate com o da categoria de destino. */
    skippedNameMismatch: number;
    /** Só listados: nenhuma categoria de destino informada/encontrada. */
    skippedNoTarget: number;
    /** Documentos que falharam. */
    failed: number;
}

/** Comparação de nome: ignora maiúsculas/minúsculas e espaços nas pontas. */
export function sameCategoryName(a?: unknown, b?: unknown): boolean {
    if (typeof a !== "string" || typeof b !== "string") return false;

    const left = a.trim().toLocaleLowerCase("pt-BR");
    const right = b.trim().toLocaleLowerCase("pt-BR");
    return left.length > 0 && left === right;
}

/** Mensagem de erro das combinações de flags inválidas (null = tudo certo). */
export function validateOptions(options: FixOptions): string | null {
    if (!options.dryRun && !options.categoryId) {
        return "--apply exige --category-id=<id>: o script não adivinha categoria.";
    }
    return null;
}

/**
 * Núcleo do script, isolado do bootstrap para permitir teste com mocks
 * (recebe a instância do Firestore por parâmetro).
 */
export async function fixEmptyCategory(
    firestore: admin.firestore.Firestore,
    options: FixOptions,
    log: (message: string) => void = console.log
): Promise<FixSummary> {
    const summary: FixSummary = {
        scanned: 0,
        installments: 0,
        orders: 0,
        fixed: 0,
        skippedNameMismatch: 0,
        skippedNoTarget: 0,
        failed: 0,
    };

    // Cache do nome da categoria de destino por workspace: numa varredura da
    // base inteira o mesmo id é consultado uma vez por workspace, não por
    // documento. `null` = o documento não existe naquele workspace.
    const targetNames = new Map<string, string | null>();

    const targetName = async (workspaceId: string): Promise<string | null> => {
        if (!options.categoryId) return null;
        if (targetNames.has(workspaceId)) return targetNames.get(workspaceId)!;

        const doc = await firestore
            .collection("workspaces").doc(workspaceId)
            .collection("categories").doc(options.categoryId)
            .get();

        const name = doc.exists ? (doc.data()?.name ?? null) : null;
        targetNames.set(workspaceId, typeof name === "string" ? name : null);
        return targetNames.get(workspaceId)!;
    };

    log(`[fix_empty_category] ${options.dryRun ? "DRY-RUN" : "APPLY"} — escopo=${options.workspaceId ?? "base inteira"}, categoria de destino=${options.categoryId ?? "(nenhuma: apenas listagem)"}.`);

    for (const collection of ["installments", "orders"] as const) {
        // Com --workspace a busca é na subcoleção; sem ela, no grupo de
        // coleções (todos os workspaces). `category.id` é caminho de campo:
        // o ponto navega para dentro do mapa embutido.
        const query = options.workspaceId
            ? firestore.collection("workspaces").doc(options.workspaceId).collection(collection)
                .where("category.id", "==", "")
            : firestore.collectionGroup(collection)
                .where("category.id", "==", "");

        const snapshot = await query.get();
        log(`[fix_empty_category] ${collection}: ${snapshot.docs.length} documento(s) com category.id vazio.`);

        for (const doc of snapshot.docs) {
            summary.scanned++;
            if (collection === "installments") summary.installments++;
            else summary.orders++;

            const workspaceId = options.workspaceId ?? doc.ref.parent.parent?.id;
            const label = `${workspaceId ?? "?"}/${collection}/${doc.id}`;

            try {
                if (!workspaceId) {
                    summary.failed++;
                    log(`[fix_empty_category] ${label}: FALHOU — não foi possível resolver o workspace do documento.`);
                    continue;
                }

                const category = doc.data()?.category ?? {};
                const name = category.name;
                log(`[fix_empty_category] ${label}: category.id vazio, category.name="${name ?? ""}".`);

                const expected = await targetName(workspaceId);

                if (!expected) {
                    summary.skippedNoTarget++;
                    log(`[fix_empty_category] ${label}: apenas listado — ${options.categoryId ? `a categoria '${options.categoryId}' não existe em ${workspaceId}` : "nenhuma categoria de destino informada (--category-id)"}.`);
                    continue;
                }

                if (!sameCategoryName(name, expected)) {
                    summary.skippedNameMismatch++;
                    log(`[fix_empty_category] ${label}: apenas listado — o nome não bate com a categoria de destino ("${name ?? ""}" ≠ "${expected}").`);
                    continue;
                }

                if (options.dryRun) {
                    summary.fixed++;
                    log(`[fix_empty_category] ${label}: GRAVARIA category.id='${options.categoryId}' (dry-run).`);
                    continue;
                }

                // Merge preservando os demais campos embutidos (nome, ícone,
                // cor, tipo): só o `id` muda.
                await doc.ref.set(
                    { category: { ...category, id: options.categoryId } },
                    { merge: true }
                );
                summary.fixed++;
                log(`[fix_empty_category] ${label}: category.id='${options.categoryId}' gravado.`);
            }
            catch (error) {
                summary.failed++;
                log(`[fix_empty_category] ${label}: FALHOU — ${error}`);
            }
        }
    }

    log(`[fix_empty_category] Resumo: encontrados=${summary.scanned} (parcelas=${summary.installments}, orders=${summary.orders}), corrigidos=${summary.fixed}, nome_divergente=${summary.skippedNameMismatch}, sem_destino=${summary.skippedNoTarget}, falhas=${summary.failed}.`);
    return summary;
}

export function parseArgs(argv: string[]): FixOptions & { projectId?: string } {
    const getValue = (prefix: string) => {
        const arg = argv.find((a) => a.startsWith(prefix));
        return arg ? arg.slice(prefix.length) : undefined;
    };

    return {
        // Dry-run é o padrão: só escreve com --apply explícito.
        dryRun: !argv.includes("--apply"),
        workspaceId: getValue("--workspace="),
        categoryId: getValue("--category-id="),
        projectId: getValue("--project=") || process.env.GOOGLE_CLOUD_PROJECT,
    };
}

async function main(): Promise<void> {
    const options = parseArgs(process.argv.slice(2));

    const invalid = validateOptions(options);
    if (invalid) {
        console.error(`[fix_empty_category] ${invalid}`);
        process.exit(1);
    }

    if (!admin.apps.length) {
        admin.initializeApp({
            credential: admin.credential.applicationDefault(),
            projectId: options.projectId,
        });
    }

    const summary = await fixEmptyCategory(admin.firestore(), options);

    if (options.dryRun) {
        console.log("[fix_empty_category] Nada foi escrito (dry-run). Rode novamente com --apply para aplicar.");
    }
    else if (summary.fixed > 0) {
        console.log("[fix_empty_category] Rode agora o rebuild_workspace (dry-run e depois --apply) no workspace afetado: é ele quem recoloca essas parcelas nos period_summaries.");
    }

    process.exit(summary.failed > 0 ? 1 : 0);
}

// Só executa quando invocado diretamente (`node lib/scripts/...`), nunca ao ser importado.
if (require.main === module) {
    main().catch((error) => {
        console.error("[fix_empty_category] Erro fatal:", error);
        process.exit(1);
    });
}
