import * as admin from "firebase-admin";

export interface IIdempotencyService {
    runIdempotency<T>(
        eventId: string,
        actionName: string,
        action: () => Promise<T>
    ): Promise<T | void>;
}

export class IdempotencyServiceImpl implements IIdempotencyService {
    private db = admin.firestore();

    async runIdempotency<T>(
        eventId: string,
        actionName: string,
        action: () => Promise<T>
    ): Promise<T | void> {
        const idempotencyKey = `${eventId}_${actionName}`;
        const docRef = this.db.collection("_idempotency").doc(idempotencyKey);

        return await this.db.runTransaction(async (transaction) => {
            const doc = await transaction.get(docRef);

            if (doc.exists) {
                console.log(`[Idempotency] Action ${actionName} for event ${eventId} already processed.`);
                return;
            }

            const result = await action();

            transaction.set(docRef, {
                eventId,
                actionName,
                processedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            return result;
        });
    }
}
