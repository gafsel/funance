/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import * as admin from "firebase-admin";

admin.initializeApp();
admin.firestore().settings({ ignoreUndefinedProperties: true });

export * from "./core/container";
export * from "./features/finance/presentation/functions/order_handler";
export * from "./features/finance/presentation/functions/recurring_handler";
export * from "./features/finance/presentation/functions/account_handler";
export * from "./features/finance/presentation/functions/automatic_transaction_handler";
export * from "./features/finance/presentation/functions/installment_handler";
export * from "./features/finance/presentation/functions/category_planning_handler";
export * from "./features/goal/presentation/functions/ai_handler";
export * from "./features/workspace/presentation/functions/invite_handler";
export * from "./features/workspace/presentation/functions/category_handler";
export * from "./features/workspace/presentation/functions/workspace_handler";
export * from "./features/coaching/presentation/functions/coaching_handler";
export * from "./features/coaching/presentation/functions/coaching_scheduler";
export * from "./features/goal/presentation/functions/gamification_handler";
