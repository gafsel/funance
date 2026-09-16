import { CallableOptions } from "firebase-functions/v2/https";
import { ScheduleOptions } from "firebase-functions/v2/scheduler";

/**
 * Opções das funções que chamam o Gemini. As chamadas de IA são lentas
 * (documentos grandes, prompts longos) e consomem mais memória do que os
 * triggers comuns, então sobrescrevem o padrão global definido em index.ts.
 *
 * `maxInstances` baixo é proposital: cada instância simultânea é uma chamada
 * paga ao Gemini. Preferimos enfileirar/negar a escalar sem limite.
 * A região continua sendo a padrão (não definir aqui).
 */
export const AI_CALLABLE_OPTIONS: CallableOptions = {
    memory: "512MiB",
    timeoutSeconds: 300,
    maxInstances: 3,
};

/**
 * Callables que analisam DOCUMENTO (extrato/fatura em PDF ou imagem).
 *
 * 1GiB porque o pior caso legítimo é um arquivo de 10 MB (o teto de F5.4)
 * dentro do processo ao mesmo tempo que o buffer baixado do Storage, o base64
 * do caminho inline e a resposta do modelo. Com 512MiB o OOM não era teórico.
 */
export const AI_DOCUMENT_CALLABLE_OPTIONS: CallableOptions = {
    memory: "1GiB",
    timeoutSeconds: 300,
    maxInstances: 3,
};

/**
 * Callables de IA mais rápidas (payload já pré-calculado pelo servidor,
 * sem upload de documento): mesmo teto de instâncias, timeout menor.
 */
export const AI_CALLABLE_OPTIONS_SHORT: CallableOptions = {
    memory: "512MiB",
    timeoutSeconds: 120,
    maxInstances: 3,
};

/**
 * Job de reconstrução de saldos/sumários (`rebuildWorkspace`).
 *
 * Mesma forma de `AI_CALLABLE_OPTIONS_SHORT` (mais memória e timeout que o
 * padrão global), mas NÃO é uma função de IA: não consome cota. O custo aqui é
 * Firestore — a varredura do workspace inteiro e a reescrita em lotes.
 * `maxInstances: 1` é proposital: duas reconstruções simultâneas do mesmo
 * workspace escreveriam uma por cima da outra.
 */
export const REBUILD_CALLABLE_OPTIONS: CallableOptions = {
    memory: "512MiB",
    timeoutSeconds: 300,
    maxInstances: 1,
};

/**
 * Orçamento de tempo de uma varredura de workspaces num cron (F5.5).
 *
 * `AI_SCHEDULE_OPTIONS.timeoutSeconds` é 540s; a margem de 90s precisa caber o
 * último lote em voo (um workspace com chamada de IA leva dezenas de segundos)
 * mais a gravação do checkpoint. O que não couber retoma na execução seguinte.
 */
export const CRON_SCAN_TIMEOUT_SECONDS = 540;
export const CRON_SCAN_MARGIN_SECONDS = 90;
export const CRON_SCAN_DEADLINE_MS = (CRON_SCAN_TIMEOUT_SECONDS - CRON_SCAN_MARGIN_SECONDS) * 1000;

/** Workspaces por página de varredura (uma query do Firestore). */
export const CRON_PAGE_SIZE = 50;

/**
 * Workspaces processados em paralelo. Os crons de gamificação só leem/escrevem
 * no Firestore; o de coaching chama o Gemini por workspace e usa um valor
 * menor, para não empilhar chamadas pagas nem tomar 429.
 */
export const CRON_WORKSPACE_CONCURRENCY = 5;
export const CRON_AI_WORKSPACE_CONCURRENCY = 3;

/**
 * Cron de coaching: varre todos os workspaces com atividade recente e chama a
 * IA para cada um, por isso o timeout máximo do agendador e instância única.
 */
export const AI_SCHEDULE_OPTIONS: Omit<ScheduleOptions, "schedule"> = {
    memory: "512MiB",
    timeoutSeconds: CRON_SCAN_TIMEOUT_SECONDS,
    maxInstances: 1,
};
