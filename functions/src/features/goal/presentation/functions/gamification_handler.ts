import * as admin from "firebase-admin";
import { onDocumentWritten, onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import { container } from "../../../../core/container";
import {
    AI_SCHEDULE_OPTIONS,
    CRON_PAGE_SIZE,
    CRON_SCAN_DEADLINE_MS,
    CRON_WORKSPACE_CONCURRENCY,
} from "../../../../core/config/functions.config";
import { forEachWorkspacePaged } from "../../../../core/utils/cron_runner";
import { getChangedFields } from "../../../../core/utils/diff.utils";
import {
    GOAL_DERIVED_FIELDS,
    INSTALLMENT_DERIVED_FIELDS,
    MONEY_CENTS_FIELDS,
} from "../../../finance/domain/models/finance.models";
import { applyCentsPatch, withFreshCents } from "../../../../core/utils/money_cents";
import { GAMIFICATION_TIME_ZONE } from "../../domain/services/gamification_time.util";
import { GoalModel, resolveGoalOutcome, toGoalDate } from "../../domain/models/goal.model";

/**
 * Campos do doc do workspace escritos pelo próprio SERVIDOR
 * (addXp/unlockBadge/updateWorkspaceStreaks e, desde F2.2/F2.3, a Bússola da
 * Liberdade e os marcadores de XP único). Escritas que alteram APENAS estes
 * campos não devem redisparar as checagens de badge — sem este guard, cada
 * unlock/addXp reativa onWorkspaceUpdated em cascata.
 *
 * `healthDirtyAt` é o caso mais crítico da lista: ele é carimbado a CADA
 * escrita de parcela (ver `installment_handler`). Fora daqui, todo pagamento
 * do usuário dispararia, de graça, a bateria inteira de checagens de badge do
 * workspace.
 */
const GAMIFICATION_ONLY_FIELDS = new Set([
    "xp",
    "level",
    "unlockedBadges",
    "weeklyStreaks",
    "lastLevelUpAt",
    // F2.2 — Bússola da Liberdade.
    "financialHealth",
    "healthDirtyAt",
    // F2.3 — marcadores de XP concedido uma única vez por categoria e o mapa
    // de streaks semanais (escrito junto do `weeklyStreaks` numérico).
    "xpAwardedFor",
    "streaks",
]);

/**
 * Nomes de ação da idempotência — ESTÁVEIS: mudar um destes valores faz o
 * marcador antigo deixar de casar e a ação roda de novo para eventos em voo.
 *
 * A chave gravada é `${eventId}_${actionName}`. Estes handlers observam os
 * mesmos documentos que os handlers de finanças (ex.: installments), por isso
 * os nomes são prefixados: se a plataforma entregar o mesmo `event.id` para
 * dois triggers da mesma escrita, um não pode roubar a chave do outro.
 */
export const GAMIFICATION_ACTIONS = {
    workspaceUpdated: "gamification:workspaceUpdated",
    accountCreated: "gamification:accountCreated",
    installmentWritten: "gamification:installmentWritten",
    categoryPlanningWritten: "gamification:categoryPlanningWritten",
    orderWritten: "gamification:orderWritten",
    categoryWritten: "gamification:categoryWritten",
    reconciliationWritten: "gamification:reconciliationWritten",
    automaticTransactionTriaged: "gamification:automaticTransactionTriaged",
    goalWritten: "gamification:goalWritten",
    goalRecompute: "gamification:goalRecompute",
} as const;

function getChangedTopLevelFields(before: Record<string, any>, after: Record<string, any>): string[] {
    const keys = new Set([...Object.keys(before), ...Object.keys(after)]);
    const changed: string[] = [];
    for (const key of keys) {
        if (JSON.stringify(before[key]) !== JSON.stringify(after[key])) {
            changed.push(key);
        }
    }
    return changed;
}

export const onWorkspaceUpdated = onDocumentUpdated(
    "workspaces/{workspaceId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        const before = event.data?.before.data();
        const after = event.data?.after.data();

        if (!before || !after) return;

        const changedFields = getChangedTopLevelFields(before, after);
        if (changedFields.length === 0 ||
            changedFields.every((field) => GAMIFICATION_ONLY_FIELDS.has(field))) {
            // Escrita originada da própria gamificação (ou no-op): early return
            // para evitar o trigger recursivo.
            return;
        }

        logger.info(`[onWorkspaceUpdated] Triggered for workspaceId=${workspaceId}`);

        await container.idempotencyService.runIdempotency(event.id, GAMIFICATION_ACTIONS.workspaceUpdated, async () => {
            const gamificationService = container.gamificationService;

            // 1. Check first_step: onboardingCompleted transitions from false to true
            const beforeCompleted = before.onboardingCompleted || false;
            const afterCompleted = after.onboardingCompleted || false;
            if (!beforeCompleted && afterCompleted) {
                await gamificationService.checkFirstStep(workspaceId, true);
            }

            // 2. Check united_front: members list length >= 3
            const beforeMembers = before.members || [];
            const afterMembers = after.members || [];
            if (beforeMembers.length !== afterMembers.length && afterMembers.length >= 3) {
                await gamificationService.checkUnitedFront(workspaceId, afterMembers.length);
            }

            // 3. Simple badges: profile, naming, team size, anniversary
            await gamificationService.checkSimpleWorkspaceBadges(workspaceId, after);
        });
    }
);

export const onAccountCreatedGamification = onDocumentCreated(
    "workspaces/{workspaceId}/accounts/{accountId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        logger.info(`[onAccountCreatedGamification] Triggered for workspaceId=${workspaceId}`);

        await container.idempotencyService.runIdempotency(event.id, GAMIFICATION_ACTIONS.accountCreated, async () => {
            const gamificationService = container.gamificationService;
            await gamificationService.checkFirstAccount(workspaceId);
            // Simple: multi-account badges
            await gamificationService.checkSimpleAccountBadges(workspaceId);
        });
    }
);

/**
 * Verdadeiro quando a escrita só mexeu em campos derivados da parcela — o eco
 * da execução anterior do servidor (xp recalculado, cascata zerada).
 *
 * Mesma guarda do gatilho de finanças (`handleInstallmentWritten`): este
 * handler observa a MESMA coleção e, sem ela, cada escrita de xp reavaliava
 * badges e missões semanais de graça.
 */
export function isDerivedOnlyInstallmentWrite(
    before: Record<string, any> | null,
    after: Record<string, any> | null
): boolean {
    if (!before || !after) return false;

    return getChangedFields(before, after)
        .every((field) => INSTALLMENT_DERIVED_FIELDS.has(field));
}

export const onInstallmentWrittenGamification = onDocumentWritten(
    "workspaces/{workspaceId}/installments/{installmentId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        const before = event.data?.before.exists ? event.data.before.data()! : null;
        const after = event.data?.after.exists ? event.data.after.data()! : null;

        if (!after || after.status === "removed") return;

        if (isDerivedOnlyInstallmentWrite(before, after)) {
            logger.info(`[onInstallmentWrittenGamification] Saída antecipada: parcela mudou apenas campos derivados (workspaceId=${workspaceId}).`);
            return;
        }

        logger.info(`[onInstallmentWrittenGamification] Triggered for workspaceId=${workspaceId}`);

        await container.idempotencyService.runIdempotency(event.id, GAMIFICATION_ACTIONS.installmentWritten, async () => {
            const gamificationService = container.gamificationService;

            if (after.status === "paid" || after.status === "settled") {
                // 1. Check first_transaction
                await gamificationService.checkFirstTransaction(workspaceId);

                // 2. Simple transaction-count and type badges
                await gamificationService.checkSimpleTransactionBadges(workspaceId, after);
            }

            // 4. Update weekly mission progress
            await gamificationService.updateWeeklyMissionsProgress(workspaceId, "transaction", after);
        });
    }
);

// A coleção real é `category_planning` (singular): é o caminho usado pelo
// cliente, pelo category_planning_handler, pelas rules e pelos índices.
// Com o plural, este trigger nunca disparava.
export const onCategoryPlanningWrittenGamification = onDocumentWritten(
    "workspaces/{workspaceId}/category_planning/{planningId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        logger.info(`[onCategoryPlanningWrittenGamification] Triggered for workspaceId=${workspaceId}`);

        await container.idempotencyService.runIdempotency(event.id, GAMIFICATION_ACTIONS.categoryPlanningWritten, async () => {
            const gamificationService = container.gamificationService;
            await gamificationService.checkPlanner(workspaceId);
            await gamificationService.checkGoldenRule(workspaceId);

            // Simple: planning count badges
            await gamificationService.checkSimplePlanningBadges(workspaceId);

            const after = event.data?.after.exists ? event.data.after.data() : null;
            await gamificationService.updateWeeklyMissionsProgress(workspaceId, "planning", after);

            // F2.3 — +30 XP na PRIMEIRA vez que esta categoria ganha um limite.
            //
            // Entra aqui, e não no handler de finanças, porque XP é
            // gamificação: `onCategoryPlanningWritten` (finanças) existe para
            // estornar e reaplicar o planejado nos sumários, e misturar as duas
            // responsabilidades faria uma falha de XP derrubar o cálculo do
            // planejamento. A unicidade não depende deste gatilho: ela vive no
            // marcador `xpAwardedFor.planning.<categoryId>` do workspace, então
            // uma reentrega do evento (ou o eco da escrita dos marcadores de
            // F1.5) não concede nada de novo.
            await gamificationService.awardPlanningCreationXp(workspaceId, after);
        });
    }
);

/**
 * F2.3 — gatilho de gamificação sobre as ORDERS.
 *
 * Não existia: `onOrderWritten` (finanças) só sincroniza parcelas. Este observa
 * a mesma coleção com um nome de ação próprio (`gamification:orderWritten`),
 * para que os dois não disputem a mesma chave de idempotência quando a
 * plataforma entregar o mesmo `event.id` para ambos.
 *
 * Só faz uma coisa: premiar a primeira RECORRÊNCIA de cada categoria. Criar
 * uma recorrência é declarar que um gasto se repete — é planejamento, e o
 * jogo premia planejar.
 */
export const onOrderWrittenGamification = onDocumentWritten(
    "workspaces/{workspaceId}/orders/{orderId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        const after = event.data?.after.exists ? event.data.after.data() : null;

        // Saída antecipada ANTES da idempotência: a esmagadora maioria das
        // escritas de order não é recorrência, e nenhuma delas precisa custar
        // um documento em `_idempotency`.
        if (!after || after.installmentType !== "recurring") return;

        logger.info(`[onOrderWrittenGamification] Triggered for workspaceId=${workspaceId}`);

        await container.idempotencyService.runIdempotency(event.id, GAMIFICATION_ACTIONS.orderWritten, async () => {
            await container.gamificationService.awardRecurringCreationXp(workspaceId, after);
        });
    }
);

export const onCategoryWrittenGamification = onDocumentWritten(
    "workspaces/{workspaceId}/categories/{categoryId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;
        logger.info(`[onCategoryWrittenGamification] Triggered for workspaceId=${workspaceId}`);

        await container.idempotencyService.runIdempotency(event.id, GAMIFICATION_ACTIONS.categoryWritten, async () => {
            await container.gamificationService.checkSimpleCategoryBadges(workspaceId);
        });
    }
);

/** O que o gatilho de conciliação precisa saber sobre o evento. */
export interface ReconciliationEventContext {
    workspaceId: string;
    recId: string;
    eventId: string;
}

/**
 * Corpo do gatilho de conciliação, como função pura (sem `CloudEvent`): o
 * `onDocumentWritten` abaixo só desembrulha o evento e delega.
 *
 * Isolada assim ela pode ser chamada direto nos testes de integração — o
 * emulador do Firestore não dispara triggers, então a única forma de provar que
 * uma SOBRESCRITA do mesmo resumo não soma nada duas vezes é invocar o handler
 * com os dois pares (before, after) que o Eventarc entregaria.
 */
export async function handleReconciliationWritten(
    beforeData: Record<string, any> | null,
    afterData: Record<string, any> | null,
    ctx: ReconciliationEventContext
): Promise<void> {
    const { workspaceId, recId, eventId } = ctx;

    if (!afterData) return;

    // CREATE-ONLY: só a PRIMEIRA gravação do resumo vale para a gamificação.
    //
    // Desde que o app passou a derivar o id do resumo da linha do extrato
    // (idempotência no cliente), reconfirmar o MESMO extrato sobrescreve o
    // mesmo documento. O gatilho é `onDocumentWritten`, então a sobrescrita
    // dispara de novo — com um `event.id` NOVO, que a idempotência por eventId
    // não tem como reconhecer: ela protege contra a reentrega do mesmo evento,
    // não contra um evento novo sobre o mesmo fato.
    //
    // Hoje nenhum efeito dessa segunda passagem é aditivo (badge e XP de missão
    // vão em transação e só concedem uma vez; o progresso da missão é
    // RECALCULADO, não somado), mas essa segurança é INCIDENTAL — ela vem de
    // como cada consumidor foi escrito, não de uma decisão sobre este evento. O
    // primeiro efeito aditivo que alguém acrescentar aqui vazaria em silêncio.
    // Fechar na porta é o que torna a garantia estrutural.
    if (beforeData) {
        logger.info(
            `[onReconciliationWritten] Saída antecipada: o resumo ${recId} já existia ` +
            `(workspaceId=${workspaceId}). A gamificação da conciliação é create-only.`
        );
        return;
    }

    logger.info(`[onReconciliationWritten] Triggered for workspaceId=${workspaceId}`);

    if (afterData.status !== "completed") return;

    await container.idempotencyService.runIdempotency(eventId, GAMIFICATION_ACTIONS.reconciliationWritten, async () => {
        const gamificationService = container.gamificationService;

        const confirmedMatches = afterData.confirmedMatchesCount || 0;
        const totalProcessed = afterData.totalTransactionsProcessed || 0;
        const createdCount = afterData.createdTransactionsCount || 0;

        // 1. Advanced reconciliation badges
        await gamificationService.checkReconciliationBadges(
            workspaceId,
            confirmedMatches,
            totalProcessed,
            createdCount
        );

        // 2. Simple reconciliation frequency badges
        await gamificationService.checkSimpleReconciliationBadges(workspaceId);

        // 3. Update weekly mission progress
        await gamificationService.updateWeeklyMissionsProgress(workspaceId, "reconciliation", afterData);
    });
}

export const onReconciliationWritten = onDocumentWritten(
    "workspaces/{workspaceId}/reconciliations/{recId}",
    async (event) => {
        // `onDocumentWritten`, e não `onDocumentCreated`, mesmo o efeito sendo
        // create-only: a sobrescrita passa a ter um LOG dizendo por que nada
        // aconteceu. Com `onDocumentCreated` a função nem seria invocada, e o
        // "reconfirmei e não somou" do usuário não teria rastro nenhum para o
        // suporte seguir. O custo é uma invocação que sai em poucas linhas —
        // reconciliar é uma ação manual, não um evento de volume.
        await handleReconciliationWritten(
            event.data?.before.exists ? event.data.before.data()! : null,
            event.data?.after.exists ? event.data.after.data()! : null,
            {
                workspaceId: event.params.workspaceId,
                recId: event.params.recId,
                eventId: event.id,
            }
        );
    }
);

export interface GoalEventContext {
    workspaceId: string;
    goalId: string;
    eventId: string;
}

/**
 * Corpo do gatilho de meta, como função pura (sem `CloudEvent`).
 *
 * Isolada assim ela pode ser chamada direto nos testes de integração — o
 * emulador do Firestore não dispara triggers, então a única forma de verificar
 * o encadeamento evento -> escrita derivada -> evento é invocar o handler com o
 * par (before, after) que a escrita derivada produziria.
 */
export async function handleGoalWritten(
    beforeData: Record<string, any> | null,
    afterData: Record<string, any> | null,
    ctx: GoalEventContext
): Promise<void> {
    const { workspaceId, goalId, eventId } = ctx;

    if (!afterData) return;

    // GUARDA POR CONTEÚDO (F1.10) — ANTES do passo derivado. A escrita dos
    // espelhos inteiros gera um novo evento; sem esta saída ele recalcularia o
    // progresso e reavaliaria a bateria inteira de badges, para cada meta da
    // base, durante a migração.
    //
    // A guarda vem primeiro (e não depois, como na primeira versão) porque o
    // passo derivado não tem nada a fazer num evento que só mexeu em `*Cents`:
    // os espelhos já estão corretos, é essa escrita que os acabou de gravar.
    if (beforeData && afterData) {
        const changedFields = getChangedTopLevelFields(beforeData, afterData);
        if (changedFields.length > 0 && changedFields.every((field) => GOAL_DERIVED_FIELDS.has(field))) {
            logger.info(`[onGoalWritten] Saída antecipada: ${goalId} mudou apenas espelhos inteiros [${changedFields.join(", ")}].`);
            return;
        }
    }

    // F1.10 — passo derivado: completa `targetAmountCents`/`currentAmountCents`
    // a partir do `double` que o CLIENTE gravou.
    await applyCentsPatch(
        admin.firestore().collection(`workspaces/${workspaceId}/goals`).doc(goalId),
        afterData,
        MONEY_CENTS_FIELDS.goals,
        "onGoalWritten"
    );

    logger.info(`[onGoalWritten] Triggered for workspaceId=${workspaceId}`);

    // Progresso da meta recém-criada/editada.
    //
    // Sem isto, uma meta de categoria ou de dívida nasce em zero e só ganha
    // vida no próximo pagamento — o usuário vê a barra vazia mesmo tendo
    // histórico. O recálculo só escreve quando o valor MUDA, então a escrita
    // que ele provoca não reentra: a segunda passada calcula o mesmo número e
    // não grava nada.
    //
    // O modelo recalculado é GUARDADO: é ele, e não o documento cru do evento,
    // que vai para as checagens de badge logo abaixo. `recomputeGoal` muta o
    // objeto com o `currentAmount` novo e com o desfecho que acabou de
    // carimbar; avaliar os badges sobre o `after` cru os faria julgar o valor
    // ANTERIOR ao recálculo — e um badge de conclusão perdido nessa passagem só
    // reapareceria na próxima escrita da meta, se houver alguma.
    // HOTFIX — o payload do evento carrega o `*Cents` de ANTES do passo
    // derivado. `evaluateGoalOutcome` compara
    // `resolveCents(targetAmount, targetAmountCents)`, que prefere o inteiro:
    // baixar o alvo de R$ 1.000 para R$ 500 seria julgado contra 1000, e a meta
    // não desfecharia.
    //
    // A normalização vem DEPOIS da guarda por conteúdo e do passo derivado, de
    // propósito: a guarda compara os documentos CRUS, e é assim que ela
    // reconhece o eco da escrita do espelho — normalizar antes apagaria
    // justamente a diferença que ela procura. O `applyCentsPatch` também
    // precisa do documento cru, porque é ele quem decide o que gravar.
    const fresh = withFreshCents(afterData, MONEY_CENTS_FIELDS.goals);

    const goal: GoalModel = {
        ...fresh,
        id: goalId,
        startDate: toGoalDate(afterData.startDate) ?? new Date(),
        deadline: toGoalDate(afterData.deadline) ?? undefined,
        // O desfecho já gravado precisa vir junto: é ele que impede o recálculo
        // de carimbar um segundo desfecho por cima.
        outcome: resolveGoalOutcome(afterData),
        completedAt: toGoalDate(afterData.completedAt),
        failedAt: toGoalDate(afterData.failedAt),
    } as GoalModel;

    await container.idempotencyService.runIdempotency(eventId, GAMIFICATION_ACTIONS.goalRecompute, async () => {
        if (afterData.isDeleted === true) return;
        try {
            await container.goalService.recomputeGoal(workspaceId, goal);
        }
        catch (e) {
            // Recalcular é melhor-esforço: não pode impedir os badges.
            logger.error(`[onGoalWritten] Falha ao recalcular a meta ${goalId}:`, e);
        }
    });

    await container.idempotencyService.runIdempotency(eventId, GAMIFICATION_ACTIONS.goalWritten, async () => {
        const gamificationService = container.gamificationService;

        // O documento como ele ficou DEPOIS do recálculo: `goal` carrega o
        // `currentAmount`/`currentAmountCents` novos e o `outcome` carimbado.
        const evaluated = {
            ...fresh,
            currentAmount: goal.currentAmount,
            currentAmountCents: goal.currentAmountCents,
            outcome: goal.outcome ?? afterData.outcome ?? null,
            completedAt: goal.completedAt ?? afterData.completedAt ?? null,
            failedAt: goal.failedAt ?? afterData.failedAt ?? null,
        };

        // Advanced goal badges
        await gamificationService.checkGoalBadges(workspaceId, evaluated);

        // Simple goal badges
        await gamificationService.checkSimpleGoalBadges(workspaceId, evaluated);
    });
}

export const onGoalWritten = onDocumentWritten(
    "workspaces/{workspaceId}/goals/{goalId}",
    async (event) => {
        await handleGoalWritten(
            event.data?.before.exists ? event.data.before.data() ?? null : null,
            event.data?.after.exists ? event.data.after.data() ?? null : null,
            {
                workspaceId: event.params.workspaceId,
                goalId: event.params.goalId,
                eventId: event.id,
            }
        );
    }
);

// Crons agendados (firebase-functions v2 scheduler).
// Antes eram onCall ("cron simulation triggers") que nenhum código chamava —
// streaks e missões semanais/mensais nunca eram avaliadas.

export const weeklyGamificationCron = onSchedule(
    {
        // Toda segunda-feira às 03:00, horário de São Paulo — avalia a semana
        // anterior (domingo a sábado) já encerrada.
        schedule: "0 3 * * 1",
        timeZone: GAMIFICATION_TIME_ZONE,
        // Varre todos os workspaces e gera missões semanais via IA: precisa de
        // mais memória/timeout do que o padrão global de 256MiB/60s.
        ...AI_SCHEDULE_OPTIONS,
    },
    async () => {
        logger.info("[weeklyGamificationCron] Starting weekly gamification cron.");
        try {
            await container.gamificationService.runWeeklyCronForAllWorkspaces();
            logger.info("[weeklyGamificationCron] Weekly gamification cron finished.");
        }
        catch (e) {
            logger.error("[weeklyGamificationCron] Error processing weekly cron:", e);
        }
    }
);

export const monthlyGamificationCron = onSchedule(
    {
        // Todo dia 1 às 03:00, horário de São Paulo — avalia o mês anterior.
        schedule: "0 3 1 * *",
        timeZone: GAMIFICATION_TIME_ZONE,
        // Varre todos os workspaces igual ao semanal: herdar o padrão global
        // de 60s deixava a varredura morrer no meio do primeiro minuto.
        ...AI_SCHEDULE_OPTIONS,
    },
    async () => {
        logger.info("[monthlyGamificationCron] Starting monthly gamification cron.");
        try {
            await container.gamificationService.runMonthlyCronForAllWorkspaces();
            logger.info("[monthlyGamificationCron] Monthly gamification cron finished.");
        }
        catch (e) {
            logger.error("[monthlyGamificationCron] Error processing monthly cron:", e);
        }
    }
);

/**
 * Fecha, todo dia, as metas cujo prazo venceu.
 *
 * Sem este cron, uma meta de REDUÇÃO que atravessa o prazo dentro do teto
 * ficaria "em andamento" para sempre: o sucesso dela não é um evento — é a
 * AUSÊNCIA de estouro até o vencimento, e nada acontece no dia do vencimento
 * para disparar um gatilho. O mesmo vale para a meta de acúmulo que vence sem
 * alcançar o alvo: alguém precisa carimbar a derrota.
 *
 * 03:15 (America/Sao_Paulo), quinze minutos depois dos crons semanais/mensais,
 * para não disputar leitura com eles no mesmo minuto. A varredura é a paginada
 * com checkpoint (`forEachWorkspacePaged`), então um timeout retoma do ponto
 * exato na execução seguinte.
 *
 * Idempotente: só toca metas com `outcome == null` e prazo vencido — na segunda
 * passada elas já têm desfecho e são puladas.
 */
export const closeExpiredGoals = onSchedule(
    {
        schedule: "15 3 * * *",
        timeZone: GAMIFICATION_TIME_ZONE,
        ...AI_SCHEDULE_OPTIONS,
    },
    async () => {
        let closedTotal = 0;

        const result = await forEachWorkspacePaged(
            {
                checkpointKey: "close_expired_goals",
                pageSize: CRON_PAGE_SIZE,
                concurrency: CRON_WORKSPACE_CONCURRENCY,
                deadlineMs: CRON_SCAN_DEADLINE_MS,
            },
            async (workspaceId) => {
                const closed = await container.goalService.closeExpiredGoals(workspaceId);
                closedTotal += closed.length;

                for (const goal of closed) {
                    // Só o desfecho de SUCESSO concede alguma coisa; as
                    // checagens já sabem disso (`isGoalCompleted`). Passar a
                    // meta falhada por aqui é de propósito: é o que mantém o
                    // caminho do cron igual ao do gatilho.
                    await container.gamificationService.checkGoalBadges(workspaceId, goal);
                    await container.gamificationService.checkSimpleGoalBadges(workspaceId, goal);
                }
            }
        );

        logger.info(
            `[closeExpiredGoals] ${result.processed} workspaces, ${closedTotal} metas fechadas, ` +
            `${result.failed} com falha, varredura ${result.completed ? "completa" : `interrompida em ${result.lastWorkspaceId}`}.`
        );
    }
);

/**
 * Publica o catálogo de badges em `config/badges` (ver
 * `BadgeCatalogService.publishBadgeCatalog`).
 *
 * Por que um cron e não um gatilho: o catálogo é do PROJETO, não de um
 * workspace — não existe evento natural para publicá-lo, e amarrá-lo à criação
 * de workspace faria a publicação depender de um usuário novo aparecer. Um cron
 * diário barato (uma leitura; escreve só quando o hash do catálogo muda) faz o
 * deploy se propagar sozinho. `maxInstances: 1` porque duas execuções
 * simultâneas não têm nada a acrescentar uma à outra.
 *
 * O PRIMEIRO publish (antes do cron rodar) é feito pelo script
 * `scripts/publish_badge_catalog.ts`.
 */
export const publishBadgeCatalog = onSchedule(
    {
        schedule: "0 4 * * *",
        timeZone: GAMIFICATION_TIME_ZONE,
        maxInstances: 1,
    },
    async () => {
        try {
            const result = await container.badgeCatalogService.publishBadgeCatalog();
            logger.info(`[publishBadgeCatalog] versão=${result.version} publicado=${result.published} badges=${result.badgeCount}`);
        }
        catch (e) {
            logger.error("[publishBadgeCatalog] Erro ao publicar o catálogo de badges:", e);
        }
    }
);
