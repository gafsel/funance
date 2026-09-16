import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * Marcador de idempotência gravado em `_idempotency/{eventId}_{actionName}`.
 *
 * A chave continua sendo `eventId_action` (desenho intencional: ações
 * diferentes do mesmo evento são independentes, e handlers distintos que
 * observam a mesma escrita usam nomes de ação distintos).
 */
export interface IdempotencyMarker {
    eventId: string;
    actionName: string;
    status: "running" | "done";
    startedAt: admin.firestore.Timestamp;
    expiresAt: admin.firestore.Timestamp;
}

/**
 * TTL dos marcadores: 30 dias — mesma política documentada no README para
 * `ai_logs`/`quotas`. O campo só apaga documentos depois que a política de TTL
 * estiver ativa na coleção `_idempotency` (ver README).
 */
export const IDEMPOTENCY_TTL_DAYS = 30;

/**
 * Um marcador `running` mais antigo que isto é considerado abandonado: a
 * instância que o criou morreu antes de terminar (timeout máximo de uma
 * Function v2 é bem menor que 10 minutos nos triggers deste projeto), então a
 * próxima tentativa pode reexecutar a ação.
 */
export const IDEMPOTENCY_STALE_RUNNING_MS = 10 * 60 * 1000;

export interface IIdempotencyService {
    runIdempotency<T>(
        eventId: string,
        actionName: string,
        action: () => Promise<T>
    ): Promise<T | void>;
}

/** `create()` falha com ALREADY_EXISTS (gRPC 6) quando o documento já existe. */
function isAlreadyExistsError(error: any): boolean {
    if (!error) return false;
    if (error.code === 6 || error.code === "already-exists") return true;
    return typeof error.message === "string" && error.message.includes("ALREADY_EXISTS");
}

/** Normaliza `startedAt` (Timestamp do Firestore, Date ou número) para milissegundos. */
function toMillis(value: any): number | null {
    if (!value) return null;
    if (typeof value.toMillis === "function") return value.toMillis();
    if (typeof value.toDate === "function") return value.toDate().getTime();
    if (value instanceof Date) return value.getTime();
    if (typeof value === "number") return value;
    return null;
}

export class IdempotencyServiceImpl implements IIdempotencyService {
    /**
     * Lazy: o `admin.firestore()` só é resolvido no primeiro uso, para o
     * serviço poder ser construído antes do `initializeApp` (e nos testes).
     */
    private get db(): admin.firestore.Firestore {
        return admin.firestore();
    }

    private get collection(): admin.firestore.CollectionReference {
        return this.db.collection("_idempotency");
    }

    /**
     * Executa `action` no máximo uma vez por `eventId_actionName`.
     *
     * Diferente da versão anterior (que gravava o marcador DEPOIS da ação,
     * dentro de uma transação), o marcador é criado ANTES:
     *
     *  1. `create({status: "running"})` — falha com ALREADY_EXISTS se outra
     *     execução já reivindicou a chave; nesse caso saímos sem rodar nada.
     *  2. roda a ação;
     *  3. `update({status: "done"})`.
     *
     * Se a ação lançar, o marcador é APAGADO e o erro é repropagado. Isso NÃO
     * significa que a plataforma vai tentar de novo: nenhum trigger deste
     * projeto declara `retry: true`, então hoje uma falha só é reexecutada se o
     * evento for reentregue (a entrega é at-least-once) — ou se o retry for
     * ligado no futuro. Apagar o marcador é o que mantém essa porta aberta:
     * preso em `running`/`done`, a ação nunca mais rodaria para aquele evento.
     */
    async runIdempotency<T>(
        eventId: string,
        actionName: string,
        action: () => Promise<T>
    ): Promise<T | void> {
        const idempotencyKey = `${eventId}_${actionName}`;
        const docRef = this.collection.doc(idempotencyKey);

        const claimed = await this.claim(docRef, eventId, actionName);
        if (!claimed) {
            logger.debug(`[Idempotency] Ação ${actionName} do evento ${eventId} já processada (ou em andamento).`);
            return;
        }

        try {
            const result = await action();

            await docRef.update({
                status: "done",
                finishedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            return result;
        }
        catch (error) {
            // O marcador não pode sobreviver a uma falha: preso na coleção, ele
            // faria qualquer reentrega (ou um retry futuro, se ativado) pular a
            // ação que nunca chegou a completar.
            try {
                await docRef.delete();
            }
            catch (deleteError) {
                logger.error(`[Idempotency] Falha ao apagar o marcador ${idempotencyKey} após erro da ação:`, deleteError);
            }
            throw error;
        }
    }

    /**
     * Reivindica a chave. Retorna `true` quando esta execução é a dona da ação.
     */
    private async claim(
        docRef: admin.firestore.DocumentReference,
        eventId: string,
        actionName: string
    ): Promise<boolean> {
        const marker = this.buildMarker(eventId, actionName);

        try {
            await docRef.create(marker);
            return true;
        }
        catch (error) {
            if (!isAlreadyExistsError(error)) throw error;
        }

        const snapshot = await docRef.get();

        if (!snapshot.exists) {
            // Corrida: o dono anterior falhou e apagou o marcador entre o
            // create e o get. Tentamos reivindicar uma única vez.
            return await this.tryCreate(docRef, marker);
        }

        const data = snapshot.data() || {};

        if (data.status === "running") {
            const startedAtMs = toMillis(data.startedAt);
            const isStale = startedAtMs === null ||
                (Date.now() - startedAtMs) > IDEMPOTENCY_STALE_RUNNING_MS;

            if (!isStale) return false;

            logger.warn(`[Idempotency] Marcador 'running' abandonado em ${docRef.id} (iniciado há mais de ${IDEMPOTENCY_STALE_RUNNING_MS / 60000} min): reexecutando.`);
            try {
                await docRef.delete();
            }
            catch (deleteError) {
                logger.error(`[Idempotency] Falha ao apagar marcador abandonado ${docRef.id}:`, deleteError);
                return false;
            }
            return await this.tryCreate(docRef, marker);
        }

        // `done` — ou um marcador legado (gravado após a ação, sem `status`):
        // em ambos os casos a ação já rodou.
        return false;
    }

    private async tryCreate(
        docRef: admin.firestore.DocumentReference,
        marker: Record<string, any>
    ): Promise<boolean> {
        try {
            await docRef.create(marker);
            return true;
        }
        catch (error) {
            if (isAlreadyExistsError(error)) return false;
            throw error;
        }
    }

    private buildMarker(eventId: string, actionName: string): Record<string, any> {
        const now = new Date();
        const expiresAt = new Date(now.getTime() + IDEMPOTENCY_TTL_DAYS * 24 * 60 * 60 * 1000);

        return {
            eventId,
            actionName,
            status: "running",
            // Timestamp do cliente (e não serverTimestamp): o valor precisa
            // estar legível na mesma escrita para a checagem de marcador
            // abandonado, e serverTimestamp chega como null até o commit.
            startedAt: admin.firestore.Timestamp.fromDate(now),
            expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
        };
    }
}
