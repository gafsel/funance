import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { BatchOperation, commitInChunks } from "../utils/batch.utils";
import { getWeekId, getWeekStart } from "../utils/week.utils";

/**
 * F1.9 — marcador da semana corrente no documento do workspace.
 *
 * Enquanto o cliente Dart tiver a própria aritmética de semana, ele pode
 * divergir do servidor na virada (sábado 21h em São Paulo já é domingo em UTC).
 * Para tirar a decisão do cliente, o SERVIDOR grava no documento do workspace:
 *
 *  - `currentWeekId`    — `YYYY-Www` da semana corrente (mesma regra de `weekly_xp`);
 *  - `currentWeekStart` — `Timestamp` do domingo 00:00 no fuso do produto;
 *  - `currentWeekUpdatedAt` — quando o marcador foi reafirmado.
 *
 * O app deve LER esses campos em vez de calcular. Os dois são escritos apenas
 * pelo servidor (Admin SDK) — as security rules do workspace já restringem o
 * update do cliente a uma lista fechada de campos que não os inclui.
 *
 * Atualização em dois caminhos:
 *  1. o cron semanal (`syncWorkspaceCurrentWeek`, domingo de madrugada);
 *  2. sob demanda, quando um handler mexe em dado semanal e percebe que o id
 *     mudou (`ensureCurrentWeek`) — cobre o workspace que ficou inativo no
 *     horário do cron ou nasceu depois dele.
 */
export interface IWeekSyncService {
    /**
     * Garante `currentWeekId`/`currentWeekStart` no workspace. Devolve `true`
     * quando escreveu. Não cria o documento do workspace se ele não existir.
     */
    ensureCurrentWeek(workspaceId: string, now?: Date): Promise<boolean>;

    /** Reafirma o marcador em todos os workspaces (usado pelo cron semanal). */
    syncAllWorkspaces(now?: Date, pageSize?: number): Promise<{ scanned: number; updated: number }>;
}

const DEFAULT_PAGE_SIZE = 400;

export class WeekSyncServiceImpl implements IWeekSyncService {
    /**
     * Último id de semana já confirmado por workspace NESTA instância. Evita
     * uma leitura do documento do workspace a cada pagamento: dentro da mesma
     * semana e da mesma instância, a primeira confirmação basta.
     */
    private readonly confirmed = new Map<string, string>();

    private get firestore(): admin.firestore.Firestore {
        return admin.firestore();
    }

    async ensureCurrentWeek(workspaceId: string, now: Date = new Date()): Promise<boolean> {
        const weekId = getWeekId(now);
        if (this.confirmed.get(workspaceId) === weekId) return false;

        const docRef = this.firestore.collection("workspaces").doc(workspaceId);

        try {
            const snapshot = await docRef.get();
            if (!snapshot.exists) {
                // Workspace inexistente (ou já apagado): não inventar documento.
                return false;
            }

            if (snapshot.data()?.currentWeekId === weekId) {
                this.confirmed.set(workspaceId, weekId);
                return false;
            }

            await docRef.set(buildWeekMarker(now), { merge: true });
            this.confirmed.set(workspaceId, weekId);
            return true;
        }
        catch (error) {
            // O marcador é uma conveniência para o cliente: falhar aqui não
            // pode derrubar o pagamento que disparou o handler.
            logger.warn(`[WeekSyncService] Falha ao gravar a semana corrente de ${workspaceId}: ${error}`);
            return false;
        }
    }

    async syncAllWorkspaces(now: Date = new Date(), pageSize: number = DEFAULT_PAGE_SIZE): Promise<{ scanned: number; updated: number }> {
        const weekId = getWeekId(now);
        const marker = buildWeekMarker(now);
        const size = Math.max(1, Math.min(pageSize, DEFAULT_PAGE_SIZE));

        let scanned = 0;
        let updated = 0;
        let cursor: admin.firestore.QueryDocumentSnapshot | null = null;

        for (;;) {
            let query: admin.firestore.Query = this.firestore
                .collection("workspaces")
                .orderBy(admin.firestore.FieldPath.documentId())
                .limit(size);

            if (cursor) query = query.startAfter(cursor);

            const snapshot = await query.get();
            if (snapshot.empty) break;

            const operations: BatchOperation[] = [];
            for (const doc of snapshot.docs) {
                scanned++;
                if (doc.data()?.currentWeekId === weekId) continue;
                operations.push({ op: "set", ref: doc.ref, data: marker, options: { merge: true } });
            }

            updated += await commitInChunks(this.firestore, operations);

            if (snapshot.size < size) break;
            cursor = snapshot.docs[snapshot.size - 1];
        }

        this.confirmed.clear();
        return { scanned, updated };
    }
}

/** Payload do marcador de semana (a mesma forma nos dois caminhos de escrita). */
function buildWeekMarker(now: Date): Record<string, any> {
    return {
        currentWeekId: getWeekId(now),
        currentWeekStart: admin.firestore.Timestamp.fromDate(getWeekStart(now)),
        currentWeekUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
}
