import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

import { isSystemCategory } from "../../../workspace/domain/models/category.model";
import { AccountType } from "../../../finance/domain/models/finance.models";
import {
    AccountBalanceTotals,
    CategoryLimitOutcome,
    IHealthRepository,
    MonthlyTotals,
} from "../../domain/repositories/health.repository";
import {
    FinancialHealthSnapshot,
    FinancialHealthTier,
    finiteOr,
} from "../../domain/models/financial_health.model";

/** Contas cujo saldo é reserva: é delas que sai o Fôlego. */
const LIQUID_ACCOUNT_TYPES = new Set<string>([AccountType.checking, AccountType.investment]);

/** Contas cujo saldo é dívida: é delas que sai o Alívio. */
const DEBT_ACCOUNT_TYPES = new Set<string>([AccountType.debt, AccountType.creditCard]);

/** Página da varredura de saldos legados (sem `dateKey`). */
const BALANCE_PAGE_SIZE = 300;

/** Campo do workspace com o marcador de "precisa recalcular". */
export const HEALTH_DIRTY_FIELD = "healthDirtyAt";

/** Campo do workspace com o retrato corrente. */
export const HEALTH_FIELD = "financialHealth";

/** Subcoleção do histórico mensal. */
export const HEALTH_HISTORY_COLLECTION = "health_history";

export class HealthRepositoryImpl implements IHealthRepository {
    constructor(private firestore: admin.firestore.Firestore = admin.firestore()) {}

    private workspaceRef(workspaceId: string): admin.firestore.DocumentReference {
        return this.firestore.collection("workspaces").doc(workspaceId);
    }

    async getAccountBalanceTotals(workspaceId: string, asOfDateKey: string): Promise<AccountBalanceTotals> {
        const accounts = await this.workspaceRef(workspaceId)
            .collection("accounts")
            .get();

        const totals: AccountBalanceTotals = {
            liquid: 0,
            debt: 0,
            hasDebtAccounts: false,
            hasAnyAccount: false,
        };

        const pending: Array<{ type: string, promise: Promise<number | null> }> = [];

        for (const doc of accounts.docs) {
            const data = doc.data();
            // Conta apagada logicamente não entra: o saldo dela é resíduo de um
            // histórico que ninguém mais mantém (ver o aviso do rebuild).
            if (data.isDeleted === true) continue;

            const type = String(data.runtimeType ?? "");
            const isLiquid = LIQUID_ACCOUNT_TYPES.has(type);
            const isDebt = DEBT_ACCOUNT_TYPES.has(type);

            totals.hasAnyAccount = true;
            if (isDebt) totals.hasDebtAccounts = true;
            if (!isLiquid && !isDebt) continue;

            pending.push({
                type,
                promise: this.lastBalanceUpTo(doc.ref.collection("balance"), asOfDateKey),
            });
        }

        const resolved = await Promise.all(pending.map((entry) => entry.promise));

        resolved.forEach((balance, index) => {
            if (balance === null) return;
            if (LIQUID_ACCOUNT_TYPES.has(pending[index].type)) {
                totals.liquid += balance;
            }
            else {
                totals.debt += balance;
            }
        });

        return totals;
    }

    /**
     * Saldo do último documento com id/`dateKey` <= `limitKey`.
     *
     * Mesmo caminho DUPLO do repositório de metas e do de finanças, e pelo
     * mesmo motivo: `orderBy(documentId(), "desc")` é recusado pelo Firestore
     * (`does not support descending key scans`) e o campo `dateKey` é recente —
     * a consulta indexada simplesmente não casa com os documentos legados. A
     * query por `dateKey` responde em uma leitura numa base migrada; a
     * varredura ASCENDENTE por id no intervalo `(candidato, limite]` recupera
     * o que ficou para trás (intervalo vazio numa base migrada).
     */
    private async lastBalanceUpTo(
        collection: admin.firestore.CollectionReference,
        limitKey: string
    ): Promise<number | null> {
        const indexed = await collection
            .where("dateKey", "<=", limitKey)
            .orderBy("dateKey", "desc")
            .limit(1)
            .get();

        const candidate = indexed.empty ? null : indexed.docs[0];
        const legacy = await this.lastLegacyBalanceDoc(collection, candidate?.id ?? null, limitKey);

        const chosen = legacy ?? candidate;
        if (!chosen) return null;

        const value = Number(chosen.data()?.balance ?? 0);
        return Number.isFinite(value) ? value : null;
    }

    /** Último documento por id no intervalo `(after, upTo]`, varrendo ascendente. */
    private async lastLegacyBalanceDoc(
        collection: admin.firestore.CollectionReference,
        after: string | null,
        upTo: string
    ): Promise<admin.firestore.QueryDocumentSnapshot | null> {
        const id = admin.firestore.FieldPath.documentId();
        let last: admin.firestore.QueryDocumentSnapshot | null = null;
        let cursor: admin.firestore.QueryDocumentSnapshot | null = null;

        for (;;) {
            let query: admin.firestore.Query = collection.where(id, "<=", upTo);
            if (after !== null) {
                query = query.where(id, ">", after);
            }
            query = query.orderBy(id).select("balance").limit(BALANCE_PAGE_SIZE);
            if (cursor) {
                query = query.startAfter(cursor);
            }

            const snapshot = await query.get();
            if (snapshot.empty) return last;

            last = snapshot.docs[snapshot.size - 1];
            if (snapshot.size < BALANCE_PAGE_SIZE) return last;
            cursor = last;
        }
    }

    /**
     * Mapa `categoryId -> documento da categoria`, sem as deletadas. É o mesmo
     * join que a gamificação faz para classificar as linhas do sumário: o
     * `period_summaries` guarda só o id da categoria.
     */
    private async categoriesById(workspaceId: string): Promise<Map<string, any>> {
        const snapshot = await this.workspaceRef(workspaceId).collection("categories").get();
        const map = new Map<string, any>();
        for (const doc of snapshot.docs) {
            const data = doc.data();
            if (data.isDeleted === true) continue;
            map.set(doc.id, data);
        }
        return map;
    }

    /** Mapa `categoryId -> actualAmount` do documento mensal de sumário. */
    private async monthlyActuals(workspaceId: string, monthKey: string): Promise<Map<string, number>> {
        const doc = await this.workspaceRef(workspaceId)
            .collection("period_summaries")
            .doc(monthKey)
            .get();

        const actuals = new Map<string, number>();
        if (!doc.exists) return actuals;

        const categories = doc.data()?.categories ?? {};
        for (const [categoryId, raw] of Object.entries<any>(categories)) {
            actuals.set(categoryId, finiteOr(raw?.actualAmount, 0));
        }
        return actuals;
    }

    async getMonthlyTotals(workspaceId: string, monthKey: string): Promise<MonthlyTotals> {
        const [categories, actuals] = await Promise.all([
            this.categoriesById(workspaceId),
            this.monthlyActuals(workspaceId, monthKey),
        ]);

        const totals: MonthlyTotals = { income: 0, expense: 0 };

        for (const [categoryId, actual] of actuals) {
            const category = categories.get(categoryId);
            // Sem o documento da categoria não dá para saber se é receita ou
            // despesa. Somar às cegas inverteria o sinal do índice inteiro.
            if (!category) continue;
            // Saldo inicial e as virtuais de transferência não são escolha de
            // consumo: com elas, um aporte para a poupança contaria como gasto.
            if (isSystemCategory(categoryId, category)) continue;

            if (category.type === "income") {
                totals.income += actual;
            }
            else if (category.type === "expense") {
                totals.expense += actual;
            }
        }

        return totals;
    }

    async getCategoryLimitOutcomes(workspaceId: string, monthKey: string): Promise<CategoryLimitOutcome[]> {
        const [plannings, categories, actuals] = await Promise.all([
            this.workspaceRef(workspaceId).collection("category_planning").get(),
            this.categoriesById(workspaceId),
            this.monthlyActuals(workspaceId, monthKey),
        ]);

        // Um planejamento por categoria é o caso normal, mas a coleção não
        // impede dois. Quando houver, o limite da categoria é a SOMA deles —
        // é isso que o usuário enxerga como "quanto posso gastar aqui".
        const limits = new Map<string, number>();

        for (const doc of plannings.docs) {
            const data = doc.data();
            const amount = finiteOr(data.amount, 0);
            if (amount <= 0) continue;

            const start = typeof data.startMonth === "string" ? data.startMonth : "0000-00";
            const end = typeof data.endMonth === "string" ? data.endMonth : "9999-12";
            if (monthKey < start || monthKey > end) continue;

            const categoryId = data.category?.id;
            if (typeof categoryId !== "string" || categoryId.length === 0) continue;

            const category = categories.get(categoryId);
            // Categoria apagada, de sistema ou que não é despesa não participa
            // da Disciplina: limite de receita não é limite, é meta.
            if (!category || isSystemCategory(categoryId, category)) continue;
            if (category.type !== "expense") continue;

            limits.set(categoryId, (limits.get(categoryId) ?? 0) + amount);
        }

        const outcomes: CategoryLimitOutcome[] = [];
        for (const [categoryId, limit] of limits) {
            outcomes.push({ categoryId, limit, actual: actuals.get(categoryId) ?? 0 });
        }
        // Ordem estável: o mesmo estado sempre produz a mesma lista, o que
        // torna o teste e o diff do script legíveis.
        outcomes.sort((a, b) => a.categoryId.localeCompare(b.categoryId));
        return outcomes;
    }

    async saveCurrent(workspaceId: string, snapshot: FinancialHealthSnapshot): Promise<void> {
        // `update` (e não `set(..., {merge: true})`): o retrato nunca pode
        // CRIAR um documento de workspace. Um workspace apagado entre a leitura
        // e a escrita voltaria à vida com um único campo, e a lista de
        // workspaces do usuário passaria a mostrar um fantasma.
        try {
            await this.workspaceRef(workspaceId).update({
                [HEALTH_FIELD]: toFirestore(snapshot),
            });
        }
        catch (error: any) {
            // gRPC 5 = NOT_FOUND
            if (error?.code === 5) {
                logger.warn(`[HealthRepository] workspace ${workspaceId} não existe; retrato descartado.`);
                return;
            }
            throw error;
        }
    }

    async saveHistory(workspaceId: string, snapshot: FinancialHealthSnapshot): Promise<void> {
        await this.workspaceRef(workspaceId)
            .collection(HEALTH_HISTORY_COLLECTION)
            .doc(snapshot.monthKey)
            .set(toFirestore(snapshot));
    }

    async getCurrent(workspaceId: string): Promise<FinancialHealthSnapshot | null> {
        const doc = await this.workspaceRef(workspaceId).get();
        return fromFirestore(doc.data()?.[HEALTH_FIELD]);
    }

    async markDirty(workspaceId: string): Promise<void> {
        // Uma escrita, ZERO leituras: este método é chamado de dentro de
        // gatilhos quentes (toda parcela paga, todo saldo movido). Se ele
        // custasse uma leitura, a Bússola encareceria o caminho crítico do
        // pagamento — que é justamente o que o debounce existe para evitar.
        try {
            await this.workspaceRef(workspaceId).update({
                [HEALTH_DIRTY_FIELD]: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        catch (error: any) {
            if (error?.code === 5) return; // workspace inexistente: nada a sujar
            throw error;
        }
    }

    async clearDirty(workspaceId: string): Promise<void> {
        try {
            await this.workspaceRef(workspaceId).update({
                [HEALTH_DIRTY_FIELD]: admin.firestore.FieldValue.delete(),
            });
        }
        catch (error: any) {
            if (error?.code === 5) return;
            throw error;
        }
    }
}

/** Retrato -> documento (o `computedAt` vira Timestamp). */
export function toFirestore(snapshot: FinancialHealthSnapshot): Record<string, any> {
    return {
        score: snapshot.score,
        tier: snapshot.tier,
        components: {
            folego: { ...snapshot.components.folego },
            poupanca: { ...snapshot.components.poupanca },
            disciplina: { ...snapshot.components.disciplina },
            alivio: { ...snapshot.components.alivio },
        },
        computedAt: admin.firestore.Timestamp.fromDate(snapshot.computedAt),
        monthKey: snapshot.monthKey,
    };
}

/** Documento -> retrato. Devolve `null` para qualquer coisa fora do contrato. */
export function fromFirestore(raw: any): FinancialHealthSnapshot | null {
    if (!raw || typeof raw !== "object") return null;
    if (typeof raw.monthKey !== "string") return null;

    const computedAt = raw.computedAt?.toDate ? raw.computedAt.toDate() : null;
    if (!computedAt) return null;

    return {
        score: finiteOr(raw.score, 0),
        tier: raw.tier as FinancialHealthTier,
        components: raw.components,
        computedAt,
        monthKey: raw.monthKey,
    };
}
