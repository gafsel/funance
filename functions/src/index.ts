/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import * as admin from "firebase-admin";
import { setGlobalOptions } from "firebase-functions/v2";

// Padrão para os triggers leves (gatilhos de Firestore, crons de manutenção e
// callables simples): pouca memória, timeout curto e teto de instâncias baixo
// para limitar custo em caso de loop de escrita ou pico inesperado.
// As funções de IA sobrescrevem estes valores individualmente (memória e
// timeout maiores, maxInstances ainda mais baixo) — ver AI_CALLABLE_OPTIONS.
// A REGIÃO NÃO É DEFINIDA AQUI de propósito: Firestore e Functions já estão na
// mesma região padrão e mudá-la exigiria recriar todas as funções.
setGlobalOptions({
    maxInstances: 10,
    memory: "256MiB",
    timeoutSeconds: 60,
});

admin.initializeApp();

// `ignoreUndefinedProperties` fica DESLIGADO (F1.11).
//
// Ligada, a opção fazia o SDK descartar em silêncio toda chave com valor
// `undefined`. Um campo que o servidor deveria escrever e que chegou
// `undefined` por um erro de tipagem simplesmente não ia para o documento —
// sem erro, sem log, sem teste vermelho. O defeito só aparecia depois, no app,
// como um campo que "sumiu".
//
// Desligada, gravar `undefined` LANÇA. Onde o descarte é legítimo (um
// `Partial<Model>`, um campo que só existe em fatura), ele é explícito:
// `stripUndefined` (`core/utils/firestore.utils.ts`), aplicado na camada de
// repositório, onde o documento é montado.
admin.firestore().settings({ ignoreUndefinedProperties: false });

export * from "./features/finance/presentation/functions/order_handler";
export * from "./features/finance/presentation/functions/recurring_handler";
export * from "./features/finance/presentation/functions/account_handler";
export * from "./features/finance/presentation/functions/automatic_transaction_handler";
export * from "./features/finance/presentation/functions/installment_handler";
export * from "./features/finance/presentation/functions/category_planning_handler";
export * from "./features/finance/presentation/functions/planning_analysis_handler";
export * from "./features/finance/presentation/functions/rebuild_handler";
export * from "./features/goal/presentation/functions/ai_handler";
export * from "./features/workspace/presentation/functions/invite_handler";
export * from "./features/workspace/presentation/functions/category_handler";
export * from "./features/workspace/presentation/functions/workspace_handler";
export * from "./features/coaching/presentation/functions/coaching_handler";
export * from "./features/coaching/presentation/functions/coaching_scheduler";
export * from "./features/goal/presentation/functions/gamification_handler";
export * from "./features/health/presentation/functions/health_handler";
