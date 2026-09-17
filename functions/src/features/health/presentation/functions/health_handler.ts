import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";

import { container } from "../../../../core/container";
import {
    CRON_PAGE_SIZE,
    CRON_SCAN_DEADLINE_MS,
    CRON_WORKSPACE_CONCURRENCY,
    HEALTH_SCHEDULE_OPTIONS,
} from "../../../../core/config/functions.config";
import { forEachWorkspacePaged } from "../../../../core/utils/cron_runner";
import { PRODUCT_TIME_ZONE } from "../../../../core/utils/timezone.utils";
import { HEALTH_DIRTY_FIELD } from "../../data/repositories/health.repository.impl";

/**
 * Piso da consulta de workspaces sujos. O Firestore NÃO consulta "campo que
 * existe", mas `> epoch` só casa documentos que têm o campo — e é exatamente
 * isso que queremos: a varredura custa o número de workspaces SUJOS, não o
 * tamanho da base.
 */
const DIRTY_FLOOR = admin.firestore.Timestamp.fromMillis(0);

export interface DirtyScanResult {
    /** Workspaces em que o retrato foi recalculado e gravado. */
    refreshed: number;
    /** Workspaces adiados pelo intervalo mínimo (continuam sujos). */
    debounced: number;
    /** Workspaces em que o recálculo lançou (o erro foi logado e isolado). */
    failed: number;
    /** `true` quando a fila de sujos acabou dentro do orçamento de tempo. */
    completed: boolean;
}

/**
 * Percorre os workspaces marcados com `healthDirtyAt`, do mais antigo para o
 * mais novo, e recalcula os que já podem ser recalculados.
 *
 * O cursor é o PRÓPRIO `healthDirtyAt` (a consulta ordena por ele), e não um
 * checkpoint persistido: a fila se esvazia sozinha, porque recalcular apaga o
 * marcador. Um workspace adiado pelo debounce continua sujo e é pego no ciclo
 * seguinte — sem ele, o cursor ficaria preso no mesmo documento para sempre.
 *
 * Isolada do `onSchedule` para poder ser exercitada no emulador (que não
 * dispara schedulers).
 */
export async function refreshDirtyWorkspaces(
    now: () => Date = () => new Date(),
    deadlineMs: number = CRON_SCAN_DEADLINE_MS,
    pageSize: number = CRON_PAGE_SIZE,
    concurrency: number = CRON_WORKSPACE_CONCURRENCY
): Promise<DirtyScanResult> {
    const result: DirtyScanResult = { refreshed: 0, debounced: 0, failed: 0, completed: false };
    const service = container.financialHealthService;
    const deadlineAt = now().getTime() + deadlineMs;

    let cursor: admin.firestore.Timestamp | null = null;

    while (now().getTime() < deadlineAt) {
        let query = admin.firestore()
            .collection("workspaces")
            .where(HEALTH_DIRTY_FIELD, ">", DIRTY_FLOOR)
            .orderBy(HEALTH_DIRTY_FIELD)
            .limit(pageSize);

        if (cursor) {
            query = query.startAfter(cursor);
        }

        const snapshot = await query.get();
        if (snapshot.empty) {
            result.completed = true;
            break;
        }

        const ids = snapshot.docs.map((doc) => doc.id);
        let consumed = 0;

        for (let start = 0; start < ids.length; start += concurrency) {
            if (now().getTime() >= deadlineAt) break;

            const batch = ids.slice(start, start + concurrency);
            const settled = await Promise.allSettled(
                batch.map((workspaceId) => service.refreshIfDue(workspaceId, now()))
            );

            settled.forEach((outcome, index) => {
                if (outcome.status === "rejected") {
                    result.failed++;
                    logger.error(
                        `[refreshFinancialHealth] falha no workspace ${batch[index]}:`,
                        outcome.reason
                    );
                    return;
                }
                if (outcome.value.computed) result.refreshed++;
                else if (outcome.value.debounced) result.debounced++;
            });

            consumed += batch.length;
        }

        // O cursor avança pelo valor do marcador, não pelo id: assim um
        // workspace adiado pelo debounce (que continua sujo) não é relido nesta
        // mesma execução.
        cursor = snapshot.docs[snapshot.size - 1].get(HEALTH_DIRTY_FIELD);

        if (consumed < ids.length) break;
        if (ids.length < pageSize) {
            result.completed = true;
            break;
        }
    }

    return result;
}

/**
 * F2.2 — recálculo da Bússola da Liberdade, a cada 15 minutos, só dos
 * workspaces sujos.
 *
 * Por que um cron e não o recálculo dentro do gatilho: o índice lê saldos de
 * TODAS as contas, três meses de sumário e os planejamentos vigentes. Fazer
 * isso a cada parcela paga transformaria um pagamento em dezenas de leituras —
 * e uma conciliação de extrato, com 80 lançamentos, em 80 recálculos do mesmo
 * número. O gatilho só carimba `healthDirtyAt` (UMA escrita, zero leituras) e
 * este cron faz o trabalho, no máximo uma vez a cada 10 minutos por workspace.
 */
export const refreshFinancialHealth = onSchedule(
    {
        schedule: "*/15 * * * *",
        timeZone: PRODUCT_TIME_ZONE,
        ...HEALTH_SCHEDULE_OPTIONS,
    },
    async () => {
        try {
            const result = await refreshDirtyWorkspaces();
            logger.info(
                `[refreshFinancialHealth] ${result.refreshed} recalculados, ${result.debounced} adiados, ` +
                `${result.failed} com falha, fila ${result.completed ? "esvaziada" : "interrompida pelo deadline"}.`
            );
        }
        catch (e) {
            logger.error("[refreshFinancialHealth] erro na varredura:", e);
        }
    }
);

/**
 * Fecha o histórico do mês anterior, todo dia 1.
 *
 * A Bússola de um mês só está completa quando o mês acaba — e nenhum evento
 * acontece no dia 1 para provocar essa última passada num workspace parado.
 * Sem este cron, o `health_history` de quem não mexeu no app na virada ficaria
 * congelado no retrato do dia 20, e o gráfico de evolução do app mostraria um
 * degrau que nunca existiu.
 *
 * 04:30: depois do cron mensal de gamificação (03:00) e do de metas (03:15),
 * que são os que fecham o mês anterior nas outras coleções.
 */
export const closeFinancialHealthMonth = onSchedule(
    {
        schedule: "30 4 1 * *",
        timeZone: PRODUCT_TIME_ZONE,
        ...HEALTH_SCHEDULE_OPTIONS,
    },
    async () => {
        const service = container.financialHealthService;

        const result = await forEachWorkspacePaged(
            {
                checkpointKey: "financial_health_monthly",
                pageSize: CRON_PAGE_SIZE,
                concurrency: CRON_WORKSPACE_CONCURRENCY,
                deadlineMs: CRON_SCAN_DEADLINE_MS,
            },
            async (workspaceId) => {
                await service.closeMonth(workspaceId);
            }
        );

        logger.info(
            `[closeFinancialHealthMonth] ${result.processed} workspaces, ${result.failed} com falha, ` +
            `varredura ${result.completed ? "completa" : `interrompida em ${result.lastWorkspaceId}`}.`
        );
    }
);
