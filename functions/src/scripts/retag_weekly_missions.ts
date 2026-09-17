/**
 * Migração leve (wp/missions-by-type): carimba `workspaceType`/`templateKey`
 * nas missões da SEMANA CORRENTE e troca as missões ABERTAS de workspaces
 * `business` pelas do catálogo corporativo.
 *
 * Contexto: até este pacote a missão semanal era escrita pela IA sobre um
 * prompt que só MENCIONAVA o tipo do workspace. O resultado apareceu em
 * produção — "Reduzir gastos com alimentação" numa empresa. O servidor novo já
 * gera pelo catálogo, mas as missões da semana em curso foram criadas pelo
 * servidor antigo e ficariam erradas na tela até domingo.
 *
 * O que o script faz, por missão da semana corrente:
 *
 *   CONCLUÍDA  → só CARIMBA (templateKey/workspaceType/actionPath/nameKey do
 *                template PESSOAL daquele tipo, que é o objetivo que aquela
 *                missão de fato teve). `name`, `target`, `progress`, `status`,
 *                `rewardXp` e `completedAt` ficam INTOCADOS.
 *   ABERTA em
 *   workspace
 *   `business` → SUBSTITUÍDA pelo template corporativo da semana: nome, alvo,
 *                XP, rota e chaves do catálogo, `progress` de volta a 0.
 *   ABERTA em
 *   workspace
 *   `personal` → só CARIMBA. O objetivo já era o certo; reescrever o texto
 *                só produziria churn na tela de quem não tem problema nenhum.
 *
 * **Por que a missão concluída NÃO é estornada.** O XP dela já entrou no
 * workspace, já subiu nível e já pode ter desbloqueado badge. Estornar
 * exigiria desfazer uma cadeia inteira de efeitos por causa de um texto — e
 * puniria o usuário por um defeito do servidor. A missão concluída fica como
 * troféu; o que muda daqui para a frente é o que se gera.
 *
 * **Por que a missão concluída é carimbada como PESSOAL mesmo numa empresa.**
 * O carimbo descreve o que aquela missão FOI, não o que geraríamos hoje: os
 * fallbacks e o prompt antigos eram todos de linguagem pessoal, qualquer que
 * fosse o tipo do workspace. Marcar `workspaceType: business` numa missão de
 * texto pessoal seria gravar uma mentira no documento.
 *
 * Características:
 *   - IDEMPOTENTE: pula a missão que já tem `templateKey` (a não ser com
 *     `--force`).
 *   - DRY-RUN POR PADRÃO: só escreve com `--apply`.
 *   - Paginado por cursor e escrito em lotes de no máximo 400 operações.
 *
 * ATENÇÃO: este script NUNCA foi executado contra o projeto real
 * (`funance-cef1b`). Ele escreve com Admin SDK e ignora as security rules.
 *
 * Uso:
 *   cd functions
 *   npm run build
 *   # 1) Simulação (padrão, não escreve nada):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/retag_weekly_missions.js --project=<projectId>
 *   # 2) Um workspace só:
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/retag_weekly_missions.js --project=<projectId> --workspace=<wid> --apply
 *   # 3) Base inteira (somente após revisar o dry-run):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/retag_weekly_missions.js --project=<projectId> --apply
 *
 * Flags:
 *   --apply              executa as escritas (sem ela, dry-run)
 *   --project=<id>       projectId do Firebase (default: GOOGLE_CLOUD_PROJECT)
 *   --workspace=<id>     limita a migração a um único workspace
 *   --week=<YYYY-Www>    semana a tratar (default: a semana corrente)
 *   --page-size=<n>      workspaces lidos por página (default 200)
 *   --force              recarimba missões que já têm `templateKey`
 */

import * as admin from "firebase-admin";
import { BatchOperation, commitInChunks } from "../core/utils/batch.utils";
import { getWeekId, startOfWeekInTz } from "../core/utils/week.utils";
import { getMonthKeyInTz } from "../core/utils/timezone.utils";
import { resolveAudience } from "../features/goal/domain/models/audience.model";
import {
    EMPTY_MISSION_CONTEXT,
    MissionParams,
    MissionSelectionContext,
    MissionTemplate,
    WEEKLY_MISSION_TYPES,
    WeeklyMissionType,
    buildMissionName,
    missionTemplatesFor,
    selectMissionTemplate,
} from "../features/goal/domain/models/mission_catalog";
import { sumWeeklyTotals } from "../features/goal/domain/services/gamification.service";
import { WeeklySummaryRow } from "../features/goal/domain/repositories/gamification.repository";
import { CategoryModel, isSystemCategory } from "../features/workspace/domain/models/category.model";
import { CategoryPlanningModel, toPeriodSummaryDocument } from "../features/finance/domain/models/finance.models";

export interface RetagOptions {
    dryRun: boolean;
    workspaceId?: string;
    weekId?: string;
    pageSize?: number;
    force?: boolean;
    /** Data-base da semana (default: agora). Existe para os testes. */
    now?: Date;
}

export interface RetagSummary {
    /** Workspaces inspecionados. */
    workspaces: number;
    /** Documentos de missão inspecionados. */
    scanned: number;
    /** Missões que só receberam o carimbo. */
    tagged: number;
    /** Missões abertas de empresa trocadas pelo template corporativo. */
    replaced: number;
    /** Missões que já tinham `templateKey`. */
    skippedAlreadyTagged: number;
    /** Missões cujo `type` não está no catálogo. */
    skippedUnknownType: number;
    failed: number;
}

const DEFAULT_PAGE_SIZE = 200;

/** O template PESSOAL daquele tipo — o objetivo que a missão antiga teve. */
function legacyTemplate(type: WeeklyMissionType): MissionTemplate | null {
    return missionTemplatesFor("personal", type)[0] ?? null;
}

/**
 * Só os campos de CONTRATO. Nada de `name`, `target`, `progress`, `status` ou
 * `rewardXp`: carimbar é dizer o que a missão é, não mexer no que ela vale.
 */
export function buildTagPatch(template: MissionTemplate, params: MissionParams): Record<string, unknown> {
    const patch: Record<string, unknown> = {
        templateKey: template.key,
        workspaceType: template.audience,
        actionPath: template.actionPath,
        nameKey: template.nameKey,
    };
    if (template.params.length > 0) {
        patch.params = params;
    }
    return patch;
}

/** A missão corporativa inteira, como o servidor novo a criaria nesta semana. */
export function buildReplacementPatch(
    template: MissionTemplate,
    params: MissionParams
): Record<string, unknown> {
    return {
        ...buildTagPatch(template, params),
        name: buildMissionName(template, "pt", params),
        target: template.target,
        rewardXp: template.rewardXp,
        // A missão é outra: o progresso da anterior não significa nada nesta
        // régua ("3 categorias planejadas" não é "2 extratos conciliados").
        progress: 0,
        status: "pending",
    };
}

/**
 * Núcleo da migração, isolado do bootstrap para permitir teste com mocks
 * (recebe a instância do Firestore por parâmetro).
 */
export async function retagWeeklyMissions(
    firestore: admin.firestore.Firestore,
    options: RetagOptions,
    log: (message: string) => void = console.log
): Promise<RetagSummary> {
    const summary: RetagSummary = {
        workspaces: 0,
        scanned: 0,
        tagged: 0,
        replaced: 0,
        skippedAlreadyTagged: 0,
        skippedUnknownType: 0,
        failed: 0,
    };

    const pageSize = Math.max(1, options.pageSize ?? DEFAULT_PAGE_SIZE);
    const now = options.now ?? new Date();
    const startOfWeek = startOfWeekInTz(now);
    const weekId = options.weekId ?? getWeekId(startOfWeek);
    const monthKey = getMonthKeyInTz(startOfWeek);

    log(`[retag_weekly_missions] ${options.dryRun ? "DRY-RUN" : "APPLY"} — semana ${weekId}.`);

    let cursor: admin.firestore.QueryDocumentSnapshot | null = null;

    for (;;) {
        let query: admin.firestore.Query = firestore.collection("workspaces");
        if (options.workspaceId) {
            query = query.where(admin.firestore.FieldPath.documentId(), "==", options.workspaceId);
        }
        query = query.orderBy(admin.firestore.FieldPath.documentId()).limit(pageSize);
        if (cursor) query = query.startAfter(cursor);

        const snapshot = await query.get();
        if (snapshot.empty) break;

        const operations: BatchOperation[] = [];

        for (const workspaceDoc of snapshot.docs) {
            summary.workspaces++;
            const workspaceId = workspaceDoc.id;
            const audience = resolveAudience(workspaceDoc.data()?.type);

            try {
                const missions = await workspaceDoc.ref
                    .collection("weekly_missions")
                    .where("weekId", "==", weekId)
                    .get();
                if (missions.empty) continue;

                // A categoria de maior limite só é lida quando algum template
                // escolhido de fato usa o placeholder `{category}` — numa base
                // grande isso poupa uma consulta por workspace.
                // Contexto de ELEGIBILIDADE, lido do MESMO lugar que o gerador
                // lê (`period_summaries/{weekId}` + `categories`) e somado pela
                // MESMA função (`sumWeeklyTotals`).
                //
                // Sem ele, o retag sorteava entre TODOS os candidatos e o
                // gerador entre os elegíveis — dois resultados diferentes para
                // a mesma semana. Em produção, o retag carimbaria
                // `top_cost_center` numa semana em que o gerador tinha
                // escolhido `margin`, e o documento passaria a descrever uma
                // missão que não é a que está na tela.
                //
                // A leitura é preguiçosa e só acontece em workspace `business`
                // com missão a SUBSTITUIR: é o único caso em que o contexto
                // muda alguma coisa (o carimbo usa o template pessoal, que é
                // único por tipo).
                let selectionContext: MissionSelectionContext | undefined;
                const resolveSelectionContext = async (): Promise<MissionSelectionContext> => {
                    if (selectionContext !== undefined) return selectionContext;

                    const summaryDoc = await workspaceDoc.ref
                        .collection("period_summaries")
                        .doc(weekId)
                        .get();
                    if (!summaryDoc.exists) {
                        selectionContext = EMPTY_MISSION_CONTEXT;
                        return selectionContext;
                    }

                    // O script lê a coleção INTEIRA de categorias, enquanto o
                    // repositório faz `getAll` nos ids do sumário. O resultado é
                    // o mesmo; a diferença é de custo, e um script manual que
                    // roda uma vez por semana pode pagá-la.
                    const categoriesSnapshot = await workspaceDoc.ref.collection("categories").get();
                    const categoriesById = new Map<string, CategoryModel>();
                    for (const doc of categoriesSnapshot.docs) {
                        const data = doc.data() as CategoryModel;
                        if (data.isDeleted === true) continue;
                        categoriesById.set(doc.id, data);
                    }

                    const rows: WeeklySummaryRow[] = [];
                    const { categories } = toPeriodSummaryDocument(summaryDoc.id, summaryDoc.data());
                    for (const [categoryId, raw] of Object.entries(categories)) {
                        const category = categoriesById.get(categoryId);
                        if (!category) continue;
                        rows.push({
                            categoryId,
                            type: category.type,
                            isSystem: isSystemCategory(categoryId, category),
                            actualAmount: raw.actualAmount,
                            generalPlannedAmount: raw.generalPlannedAmount,
                            specificPlannedAmount: raw.specificPlannedAmount,
                            actualAmountCents: raw.actualAmountCents ?? 0,
                            generalPlannedAmountCents: raw.generalPlannedAmountCents ?? 0,
                            specificPlannedAmountCents: raw.specificPlannedAmountCents ?? 0,
                        });
                    }

                    selectionContext = sumWeeklyTotals(rows);
                    return selectionContext;
                };

                let topCategory: string | null | undefined;
                const resolveTopCategory = async (): Promise<string | null> => {
                    if (topCategory !== undefined) return topCategory;
                    const plannings = await workspaceDoc.ref.collection("category_planning").get();
                    let best: string | null = null;
                    let bestAmount = 0;
                    for (const doc of plannings.docs) {
                        const planning = doc.data() as CategoryPlanningModel;
                        const start = planning.startMonth || "0000-00";
                        const end = planning.endMonth || "9999-12";
                        if (!(start <= monthKey && monthKey <= end)) continue;
                        const name = planning.category?.name;
                        if (!name || !(planning.amount > bestAmount)) continue;
                        bestAmount = planning.amount;
                        best = name;
                    }
                    topCategory = best;
                    return best;
                };

                for (const missionDoc of missions.docs) {
                    summary.scanned++;
                    const data = missionDoc.data() ?? {};

                    if (typeof data.templateKey === "string" && data.templateKey.length > 0 && !options.force) {
                        summary.skippedAlreadyTagged++;
                        continue;
                    }

                    const type = WEEKLY_MISSION_TYPES.find((t) => t === data.type);
                    if (!type) {
                        summary.skippedUnknownType++;
                        log(`[retag_weekly_missions] ${workspaceId}/${missionDoc.id}: type "${data.type}" fora do catálogo — ignorado.`);
                        continue;
                    }

                    const isOpen = data.status !== "completed";
                    const replace = isOpen && audience === "business";

                    const template = replace
                        ? selectMissionTemplate("business", type, weekId, await resolveSelectionContext())
                        : legacyTemplate(type);
                    if (!template) {
                        summary.skippedUnknownType++;
                        continue;
                    }

                    // Ao CARIMBAR, o alvo que vale é o do DOCUMENTO: a missão
                    // antiga pode ter nascido com um alvo da IA diferente do
                    // do template, e `params` existe para o app montar o texto
                    // daquela missão — se ele disser "5 categorias" enquanto o
                    // `target` gravado é 3, a barra e a frase se contradizem na
                    // tela. Na SUBSTITUIÇÃO o alvo passa a ser o do template,
                    // porque a missão inteira passa a ser a do template.
                    const effectiveTarget = replace
                        ? template.target
                        : (typeof data.target === "number" && Number.isFinite(data.target)
                            ? data.target
                            : template.target);

                    const params: MissionParams = { target: effectiveTarget };
                    if (template.params.includes("category")) {
                        const category = await resolveTopCategory();
                        if (category) params.category = category;
                    }

                    const patch = replace
                        ? buildReplacementPatch(template, params)
                        : buildTagPatch(template, params);

                    if (replace) summary.replaced++;
                    else summary.tagged++;

                    if (options.dryRun) {
                        log(
                            `[retag_weekly_missions] ${workspaceId}/${missionDoc.id}: ` +
                            `${replace ? "SUBSTITUIRIA" : "CARIMBARIA"} com ${template.key} (dry-run).`
                        );
                        continue;
                    }

                    operations.push({ op: "set", ref: missionDoc.ref, data: patch, options: { merge: true } });
                }
            }
            catch (error) {
                summary.failed++;
                log(`[retag_weekly_missions] ${workspaceId}: FALHOU — ${error}`);
            }
        }

        if (operations.length > 0) {
            await commitInChunks(firestore, operations);
        }

        if (snapshot.size < pageSize) break;
        cursor = snapshot.docs[snapshot.size - 1];
    }

    log(
        "[retag_weekly_missions] Resumo: " +
        `workspaces=${summary.workspaces}, missões=${summary.scanned}, carimbadas=${summary.tagged}, ` +
        `substituídas=${summary.replaced}, já_carimbadas=${summary.skippedAlreadyTagged}, ` +
        `tipo_desconhecido=${summary.skippedUnknownType}, falhas=${summary.failed}.`
    );
    return summary;
}

export function parseArgs(argv: string[]): RetagOptions & { projectId?: string } {
    const getValue = (prefix: string) => {
        const arg = argv.find((a) => a.startsWith(prefix));
        return arg ? arg.slice(prefix.length) : undefined;
    };

    const pageSize = Number(getValue("--page-size="));

    return {
        // Dry-run é o padrão: só escreve com --apply.
        dryRun: !argv.includes("--apply"),
        force: argv.includes("--force"),
        workspaceId: getValue("--workspace="),
        weekId: getValue("--week="),
        pageSize: Number.isFinite(pageSize) && pageSize > 0 ? pageSize : undefined,
        projectId: getValue("--project=") || process.env.GOOGLE_CLOUD_PROJECT,
    };
}

async function main(): Promise<void> {
    const options = parseArgs(process.argv.slice(2));

    if (!admin.apps.length) {
        admin.initializeApp({
            credential: admin.credential.applicationDefault(),
            projectId: options.projectId,
        });
    }

    const summary = await retagWeeklyMissions(admin.firestore(), options);

    if (options.dryRun) {
        console.log("[retag_weekly_missions] Nada foi escrito (dry-run). Rode novamente com --apply para aplicar.");
    }

    process.exit(summary.failed > 0 ? 1 : 0);
}

// Só executa quando invocado diretamente (`node lib/scripts/...`), nunca ao ser importado.
if (require.main === module) {
    main().catch((error) => {
        console.error("[retag_weekly_missions] Erro fatal:", error);
        process.exit(1);
    });
}
