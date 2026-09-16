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
 * Cron de coaching: varre todos os workspaces com atividade recente e chama a
 * IA para cada um, por isso o timeout máximo do agendador e instância única.
 */
export const AI_SCHEDULE_OPTIONS: Omit<ScheduleOptions, "schedule"> = {
    memory: "512MiB",
    timeoutSeconds: 540,
    maxInstances: 1,
};
