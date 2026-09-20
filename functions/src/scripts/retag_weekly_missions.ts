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
 *   JÁ CARIMBADA,
 *   ABERTA, com
 *   template hoje
 *   INELEGÍVEL  → REPARADA: trocada pelo template elegível da semana, mas
 *                **só com `progress == 0`**. Com progresso, a missão é
 *                MANTIDA e aparece no resumo como `mantidas_com_progresso` —
 *                progresso é trabalho do usuário, e um número que anda para
 *                trás é pior que uma missão difícil.
 *
 * O reparo existe para um RISCO conhecido: um workspace sem cartão (ou sem
 * nenhum extrato conciliado, ou sem captura por notificação) podia receber uma
 * missão de organização que nenhuma ação dentro do app conseguiria concluir. O
 * servidor novo já não as sorteia — a peneira de CAPACIDADE passou a olhar
 * cartão, hábito de conciliação e lançamento automático —, mas uma missão
 * gravada ANTES da peneira continuaria na tela até a virada da semana, e é ela
 * que este script conserta.
 *
 * A suspeita que originou o pacote (o workspace a70134c1 em 2026-W38) era
 * FALSO ALARME: aquele workspace tem cartão, 2 conciliações e 3 lançamentos
 * automáticos recentes — a checagem que levantou o alarme leu `type` em vez de
 * `runtimeType`, o discriminador da union de contas. O dry-run em produção
 * confirmou: `reparadas=0` nos cinco workspaces. O reparo segue no script
 * porque o risco é real; ele simplesmente não tinha vítima.
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
 *     node lib/scripts/retag_weekly_missions.js --project=<projectId> --all-workspaces --apply
 *
 * O ALCANCE É EXPLÍCITO: sem `--workspace=<id>` nem `--all-workspaces` o script
 * aborta, e um argumento desconhecido também — num script que escreve, uma
 * flag engolida calada faz o operador achar que limitou o alcance.
 *
 * Flags:
 *   --apply              executa as escritas (sem ela, dry-run)
 *   --all-workspaces     percorre TODOS os workspaces (exclusiva com --workspace)
 *   --project=<id>       projectId do Firebase (default: GOOGLE_CLOUD_PROJECT)
 *   --workspace=<id>     limita a migração a um único workspace
 *   --week=<YYYY-Www>    semana a tratar (default: a semana corrente). O mês
 *                        do planejamento e a janela de capacidade são os DESSA
 *                        semana, não os de hoje.
 *   --page-size=<n>      workspaces lidos por página (default 200)
 *   --force              recarimba missões que já têm `templateKey`
 */

import * as admin from "firebase-admin";
import { BatchOperation, commitInChunks } from "../core/utils/batch.utils";
import { getWeekId, startOfWeekInTz, weekStartFromRef } from "../core/utils/week.utils";
import { addCalendarDays, getMonthKeyInTz } from "../core/utils/timezone.utils";
import { resolveAudience } from "../features/goal/domain/models/audience.model";
import {
    MissionCapacity,
    MissionParams,
    MissionSelectionContext,
    MissionTemplate,
    NO_MISSION_CAPACITY,
    WEEKLY_MISSION_TYPES,
    WeeklyMissionType,
    buildMissionName,
    buildMissionSelectionContext,
    findMissionTemplate,
    missionTemplatesFor,
    selectMissionTemplate,
} from "../features/goal/domain/models/mission_catalog";
import {
    CAPACITY_WINDOW_DAYS,
    localWallClockIso,
    sumWeeklyTotals,
} from "../features/goal/domain/services/gamification.service";
import { WeeklySummaryRow } from "../features/goal/domain/repositories/gamification.repository";
import { CategoryModel, isSystemCategory } from "../features/workspace/domain/models/category.model";
import { CategoryPlanningModel, toPeriodSummaryDocument } from "../features/finance/domain/models/finance.models";

export interface RetagOptions {
    dryRun: boolean;
    /** Percorre TODOS os workspaces. Exclusiva com `workspaceId` no CLI. */
    allWorkspaces?: boolean;
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
    /** Missões abertas cujo template virou INELEGÍVEL e foram trocadas. */
    repaired: number;
    /** Missões inelegíveis MANTIDAS porque já tinham progresso. */
    keptWithProgress: number;
    failed: number;
}

const DEFAULT_PAGE_SIZE = 200;

/** Domingo 00:00 (fuso do produto) de um id `YYYY-Www`, ou `null` se malformado. */
export function weekStartFromWeekId(weekId: string): Date | null {
    const match = /^(\d{4})-W(\d{1,2})$/.exec(weekId);
    if (!match) return null;
    return weekStartFromRef({ year: Number(match[1]), week: Number(match[2]) });
}

/**
 * A CAPACIDADE do workspace, pelas MESMAS três perguntas do servidor
 * (`GamificationRepositoryImpl.getMissionCapacity`), com `limit(1)` cada.
 *
 * O script não usa o repositório: ele recebe uma instância de Firestore e
 * navega por referências, para poder rodar contra qualquer projeto sem montar
 * o container inteiro. O contrato que os dois compartilham é o do CONTEXTO —
 * `buildMissionSelectionContext` —, e é ele que garante que um campo novo de
 * peneira quebre a compilação dos dois lados.
 */
async function readCapacity(
    workspaceRef: admin.firestore.DocumentReference,
    automaticTransactionsSince: string
): Promise<MissionCapacity> {
    try {
        const [cards, reconciliations, automatics] = await Promise.all([
            workspaceRef.collection("accounts")
                .where("runtimeType", "==", "creditCard")
                .where("isDeleted", "==", false)
                .limit(1)
                .get(),
            workspaceRef.collection("reconciliations")
                .where("status", "==", "completed")
                .limit(1)
                .get(),
            workspaceRef.collection("automatic_transactions")
                .where("date", ">=", automaticTransactionsSince)
                .orderBy("date")
                .limit(1)
                .get(),
        ]);
        return {
            hasCreditCardAccount: !cards.empty,
            hasReconciledStatementEver: !reconciliations.empty,
            hasRecentAutomaticTransaction: !automatics.empty,
        };
    }
    catch (error) {
        // Sem capacidade conhecida o sorteio cai na missão que sempre dá para
        // cumprir — o lado seguro de errar.
        console.warn(`[retag_weekly_missions] ${workspaceRef.id}: falha ao ler a capacidade — ${error}`);
        return NO_MISSION_CAPACITY;
    }
}

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
        repaired: 0,
        keptWithProgress: 0,
        failed: 0,
    };

    const pageSize = Math.max(1, options.pageSize ?? DEFAULT_PAGE_SIZE);
    const now = options.now ?? new Date();
    const weekId = options.weekId ?? getWeekId(startOfWeekInTz(now));
    // O domingo da semana TRATADA, não o de hoje: com `--week=2026-W38` rodado
    // numa segunda-feira de outubro, o mês do planejamento e a janela de
    // capacidade têm de ser os daquela semana, senão o script reproduz um
    // sorteio diferente do que o servidor fez.
    const startOfWeek = weekStartFromWeekId(weekId) ?? startOfWeekInTz(now);
    const monthKey = getMonthKeyInTz(startOfWeek);
    const capacitySince = localWallClockIso(addCalendarDays(startOfWeek, -CAPACITY_WINDOW_DAYS));

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

                    // A CAPACIDADE é lida sempre — inclusive quando não há
                    // sumário da semana. Ela não depende do que foi planejado,
                    // e é ela que diz se a missão da fatura tinha como ser
                    // cumprida naquele workspace.
                    const capacity = await readCapacity(workspaceDoc.ref, capacitySince);

                    const summaryDoc = await workspaceDoc.ref
                        .collection("period_summaries")
                        .doc(weekId)
                        .get();
                    if (!summaryDoc.exists) {
                        selectionContext = buildMissionSelectionContext(
                            { plannedIncomeCents: 0, plannedExpenseCents: 0 },
                            capacity
                        );
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

                    selectionContext = buildMissionSelectionContext(sumWeeklyTotals(rows), capacity);
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

                    const type = WEEKLY_MISSION_TYPES.find((t) => t === data.type);
                    if (!type) {
                        summary.skippedUnknownType++;
                        log(`[retag_weekly_missions] ${workspaceId}/${missionDoc.id}: type "${data.type}" fora do catálogo — ignorado.`);
                        continue;
                    }

                    const isOpen = data.status !== "completed";
                    const alreadyTagged = typeof data.templateKey === "string" && data.templateKey.length > 0;

                    // REPARO DE MISSÃO IMPOSSÍVEL.
                    //
                    // A missão já carimbada normalmente é pulada — o carimbo é
                    // o trabalho deste script. Uma exceção: a missão ABERTA
                    // cujo template deixou de ser ELEGÍVEL para este
                    // workspace — `business_organization_invoice_on_time` num
                    // workspace sem nenhuma conta de cartão, por exemplo. O
                    // servidor novo já não a sortearia, mas a missão gravada
                    // continua na tela, incumprível, até a virada.
                    //
                    // Só com `progress == 0`. Progresso é trabalho do usuário:
                    // trocar a missão por baixo dele apagaria o que ele fez,
                    // e um número que anda para trás é pior que uma missão
                    // difícil. Com progresso, a missão FICA — e o relatório
                    // diz quais foram.
                    let repair = false;
                    if (alreadyTagged && !options.force) {
                        const recorded = findMissionTemplate(data.templateKey);
                        if (!isOpen || !recorded?.isEligible) {
                            summary.skippedAlreadyTagged++;
                            continue;
                        }
                        if (recorded.isEligible(await resolveSelectionContext())) {
                            summary.skippedAlreadyTagged++;
                            continue;
                        }
                        const progress = typeof data.progress === "number" ? data.progress : 0;
                        if (progress > 0) {
                            summary.keptWithProgress++;
                            log(
                                `[retag_weekly_missions] ${workspaceId}/${missionDoc.id}: ${recorded.key} é ` +
                                `INELEGÍVEL neste workspace, mas tem progresso ${progress} — MANTIDA.`
                            );
                            continue;
                        }
                        repair = true;
                    }

                    // `--force` mantém o comportamento antigo: a missão aberta
                    // de empresa é resorteada mesmo já carimbada.
                    const replace = repair ||
                        (isOpen && audience === "business" && (!alreadyTagged || options.force === true));

                    const template = replace
                        ? selectMissionTemplate(audience, type, weekId, await resolveSelectionContext())
                        : legacyTemplate(type);
                    if (!template) {
                        summary.skippedUnknownType++;
                        continue;
                    }

                    // O sorteio entre os elegíveis devolveu a MESMA missão
                    // impossível: só acontece se o catálogo perder a opção
                    // sempre possível daquele tipo (a peneira, sem ninguém de
                    // pé, volta a correr sobre todos). Trocar por ela mesma
                    // zeraria o documento à toa.
                    if (repair && template.key === data.templateKey) {
                        summary.skippedAlreadyTagged++;
                        log(
                            `[retag_weekly_missions] ${workspaceId}/${missionDoc.id}: ${template.key} ` +
                            "continua sendo o único candidato — nada a trocar."
                        );
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

                    if (repair) summary.repaired++;
                    else if (replace) summary.replaced++;
                    else summary.tagged++;

                    if (options.dryRun) {
                        const action = repair
                            ? `REPARARIA (${data.templateKey} é inelegível) com`
                            : replace ? "SUBSTITUIRIA com" : "CARIMBARIA com";
                        log(`[retag_weekly_missions] ${workspaceId}/${missionDoc.id}: ${action} ${template.key} (dry-run).`);
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
        `substituídas=${summary.replaced}, reparadas=${summary.repaired}, ` +
        `mantidas_com_progresso=${summary.keptWithProgress}, já_carimbadas=${summary.skippedAlreadyTagged}, ` +
        `tipo_desconhecido=${summary.skippedUnknownType}, falhas=${summary.failed}.`
    );
    return summary;
}

/**
 * Flags aceitas. Um argumento fora desta lista ABORTA a execução em vez de ser
 * ignorado: num script que ESCREVE, um `--all-workspaces` engolido calado (ou
 * um `--worskpace=` com erro de digitação) faz o operador achar que limitou o
 * alcance quando não limitou.
 */
const KNOWN_ARGS = [
    "--apply",
    "--force",
    "--all-workspaces",
    "--workspace=",
    "--week=",
    "--page-size=",
    "--project=",
];

export function parseArgs(argv: string[]): RetagOptions & { projectId?: string; unknownArgs: string[] } {
    const getValue = (prefix: string) => {
        const arg = argv.find((a) => a.startsWith(prefix));
        return arg ? arg.slice(prefix.length) : undefined;
    };

    const pageSize = Number(getValue("--page-size="));

    return {
        // Dry-run é o padrão: só escreve com --apply.
        dryRun: !argv.includes("--apply"),
        force: argv.includes("--force"),
        allWorkspaces: argv.includes("--all-workspaces"),
        workspaceId: getValue("--workspace="),
        weekId: getValue("--week="),
        pageSize: Number.isFinite(pageSize) && pageSize > 0 ? pageSize : undefined,
        projectId: getValue("--project=") || process.env.GOOGLE_CLOUD_PROJECT,
        unknownArgs: argv.filter((arg) => !KNOWN_ARGS.some((known) => arg === known || arg.startsWith(known))),
    };
}

async function main(): Promise<void> {
    const options = parseArgs(process.argv.slice(2));

    if (options.unknownArgs.length > 0) {
        console.error(`[retag_weekly_missions] argumento desconhecido: ${options.unknownArgs.join(", ")}.`);
        console.error(`[retag_weekly_missions] flags aceitas: ${KNOWN_ARGS.join(" ")}`);
        process.exit(1);
    }

    // O alcance é EXPLÍCITO, como em `rebuild_workspace.ts`: rodar a base
    // inteira por omissão de flag é fácil demais de fazer sem querer.
    if (!options.workspaceId && !options.allWorkspaces) {
        console.error("[retag_weekly_missions] informe --workspace=<id> ou --all-workspaces.");
        process.exit(1);
    }
    if (options.workspaceId && options.allWorkspaces) {
        console.error("[retag_weekly_missions] --workspace e --all-workspaces são mutuamente exclusivas.");
        process.exit(1);
    }

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
