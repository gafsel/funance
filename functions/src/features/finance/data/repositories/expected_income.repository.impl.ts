import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

import {
    IExpectedIncomeRepository,
    MonthlyIncomeTotals,
} from "../../domain/repositories/expected_income.repository";
import { ExpectedIncome, ExpectedIncomeSource } from "../../domain/models/expected_income.model";
import { toPeriodSummaryDocument } from "../../domain/models/finance.models";
import { CategoryModel, CategoryType, isSystemCategory } from "../../../workspace/domain/models/category.model";

/** O campo publicado no documento do workspace. */
export const EXPECTED_INCOME_FIELD = "expectedIncome";

/** Reconstrói o valor publicado, recusando documento sujo/legado. */
function fromFirestore(raw: unknown): ExpectedIncome | null {
    if (!raw || typeof raw !== "object") return null;

    const data = raw as Record<string, unknown>;
    const monthKey = data.monthKey;
    const cents = data.cents;
    const source = data.source;

    if (typeof monthKey !== "string") return null;
    if (typeof cents !== "number" || !Number.isFinite(cents)) return null;
    if (source !== "planned" && source !== "average") return null;

    return {
        monthKey,
        cents: Math.trunc(cents),
        source: source as ExpectedIncomeSource,
        updatedAt: typeof data.updatedAt === "string" ? data.updatedAt : "",
    };
}

export class ExpectedIncomeRepositoryImpl implements IExpectedIncomeRepository {
    private workspaceRef(workspaceId: string): admin.firestore.DocumentReference {
        return admin.firestore().collection("workspaces").doc(workspaceId);
    }

    /**
     * Mapa `categoryId -> categoria` sem as deletadas — o mesmo join que a
     * gamificação e a Bússola fazem: `period_summaries` guarda só o id, e sem
     * o documento da categoria não há como saber se a linha é receita.
     */
    private async categoriesById(workspaceId: string): Promise<Map<string, CategoryModel>> {
        const snapshot = await this.workspaceRef(workspaceId).collection("categories").get();
        const map = new Map<string, CategoryModel>();
        for (const doc of snapshot.docs) {
            const data = doc.data() as CategoryModel;
            if (data.isDeleted === true) continue;
            map.set(doc.id, data);
        }
        return map;
    }

    async getMonthlyIncomeTotals(workspaceId: string, monthKeys: string[]): Promise<MonthlyIncomeTotals[]> {
        if (monthKeys.length === 0) return [];

        const summariesRef = this.workspaceRef(workspaceId).collection("period_summaries");

        // O join de categorias é feito UMA vez para todos os meses; os
        // documentos mensais vêm por `getAll` (id direto, sem índice).
        const [categories, summaryDocs] = await Promise.all([
            this.categoriesById(workspaceId),
            admin.firestore().getAll(...monthKeys.map((monthKey) => summariesRef.doc(monthKey))),
        ]);

        return monthKeys.map((monthKey, index) => {
            const doc = summaryDocs[index];
            if (!doc?.exists) {
                return { monthKey, exists: false, plannedCents: 0, actualCents: 0 };
            }

            const { categories: rows } = toPeriodSummaryDocument(doc.id, doc.data());

            let plannedCents = 0;
            let actualCents = 0;

            for (const [categoryId, totals] of Object.entries(rows)) {
                const category = categories.get(categoryId);
                // Sem o documento da categoria não dá para saber se a linha é
                // receita. Somar às cegas somaria a despesa do mês à previsão.
                if (!category) continue;
                // O SALDO INICIAL é uma categoria de sistema do tipo `income`:
                // sem este filtro, abrir uma conta com R$ 20.000 viraria uma
                // "receita prevista" de R$ 20.000 e todas as razões do HUD
                // mentiriam no primeiro mês do workspace.
                if (isSystemCategory(categoryId, category)) continue;
                if (category.type !== CategoryType.income) continue;

                plannedCents += totals.specificPlannedAmountCents ?? 0;
                actualCents += totals.actualAmountCents ?? 0;
            }

            return { monthKey, exists: true, plannedCents, actualCents };
        });
    }

    async getPublishedExpectedIncome(workspaceId: string): Promise<ExpectedIncome | null> {
        const doc = await this.workspaceRef(workspaceId).get();
        return fromFirestore(doc.data()?.[EXPECTED_INCOME_FIELD]);
    }

    async publishExpectedIncome(workspaceId: string, value: ExpectedIncome): Promise<void> {
        await this.writeField(workspaceId, { ...value });
    }

    async clearExpectedIncome(workspaceId: string): Promise<void> {
        await this.writeField(workspaceId, admin.firestore.FieldValue.delete());
    }

    /**
     * `update` (e não `set(..., {merge: true})`): a previsão nunca pode CRIAR
     * um documento de workspace. Um workspace apagado entre a leitura e a
     * escrita voltaria à vida com um único campo — a mesma postura de
     * `HealthRepository.saveCurrent`.
     */
    private async writeField(workspaceId: string, value: unknown): Promise<void> {
        try {
            await this.workspaceRef(workspaceId).update({ [EXPECTED_INCOME_FIELD]: value });
        }
        catch (error: unknown) {
            // gRPC 5 = NOT_FOUND
            if ((error as { code?: number } | null)?.code === 5) {
                logger.warn(`[ExpectedIncomeRepository] workspace ${workspaceId} não existe; previsão descartada.`);
                return;
            }
            throw error;
        }
    }
}
