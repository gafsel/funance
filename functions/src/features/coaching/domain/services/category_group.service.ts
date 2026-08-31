import { IFinanceRepository } from "../../../finance/domain/repositories/finance.repository";
import { IAIRepository } from "../../../../core/services/ai.service";
import { CategoryModel, CategoryType } from "../../../workspace/domain/models/category.model";
import {
    CategoryGroup,
    CategoryGroupCacheMap,
    isValidCategoryGroup,
} from "../models/category_group.model";

/**
 * Resolve o grupo macro de cada categoria do workspace, usando o cache em
 * workspaces/{wid}/coaching_meta/category_groups e chamando a IA APENAS para
 * categorias ainda não mapeadas ou cujo nome mudou desde a classificação.
 *
 * Regras determinísticas (sem IA):
 * - categorias de receita => income;
 * - categorias virtuais de dívida => debt_financial;
 * - categorias virtuais de investimento => savings_investments.
 */
export class CategoryGroupService {
    constructor(
        private financeRepository: IFinanceRepository,
        private aiRepository: IAIRepository
    ) {
    }

    /** Grupos fixos para as categorias virtuais usadas nos period_summaries. */
    static resolveVirtualCategoryGroup(categoryId: string): CategoryGroup | null {
        if (categoryId.startsWith("virtual_debt")) return CategoryGroup.debt_financial;
        if (categoryId.startsWith("virtual_investment")) return CategoryGroup.savings_investments;
        return null;
    }

    async resolveCategoryGroups(
        workspaceId: string,
        categories: CategoryModel[]
    ): Promise<Record<string, CategoryGroup>> {
        const result: Record<string, CategoryGroup> = {};
        const toClassify: { id: string; name: string; type: string }[] = [];

        let cached: CategoryGroupCacheMap = {};
        try {
            cached = (await this.financeRepository.getCoachingCategoryGroups(workspaceId)) || {};
        }
        catch (error) {
            console.error(`CategoryGroupService: falha ao ler cache de grupos (${workspaceId}):`, error);
        }

        for (const category of categories) {
            const virtualGroup = CategoryGroupService.resolveVirtualCategoryGroup(category.id);
            if (virtualGroup) {
                result[category.id] = virtualGroup;
                continue;
            }

            if (category.type === CategoryType.income) {
                result[category.id] = CategoryGroup.income;
                continue;
            }

            const cachedEntry = cached[category.id];
            if (cachedEntry && cachedEntry.name === category.name && isValidCategoryGroup(cachedEntry.group)) {
                result[category.id] = cachedEntry.group;
            }
            else {
                toClassify.push({ id: category.id, name: category.name, type: category.type });
            }
        }

        if (toClassify.length === 0) {
            return result;
        }

        try {
            const assignments = await this.aiRepository.classifyCategoryGroups(workspaceId, toClassify);
            const updates: CategoryGroupCacheMap = {};

            for (const category of toClassify) {
                const suggested = assignments?.[category.id];
                const group = isValidCategoryGroup(suggested) ? suggested : CategoryGroup.other;
                result[category.id] = group;
                updates[category.id] = { group, name: category.name };
            }

            await this.financeRepository.saveCoachingCategoryGroups(workspaceId, updates);
        }
        catch (error) {
            // Classificação é acessória: nunca derruba a geração do coaching.
            console.error(`CategoryGroupService: falha ao classificar categorias (${workspaceId}):`, error);
            for (const category of toClassify) {
                result[category.id] = CategoryGroup.other;
            }
        }

        return result;
    }
}
