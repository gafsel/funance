import * as admin from "firebase-admin";
import { ICategoryRepository } from "../repositories/category.repository";
import { ICategoryService } from "./category.service";
import { CategoryModel, CategoryType } from "../models/category.model";
import { WorkspaceType } from "../models/workspace.model";
import { IFinanceRepository } from "../../../finance/domain/repositories/finance.repository";

export class CategoryServiceImpl implements ICategoryService {
    constructor(
        private categoryRepository: ICategoryRepository,
        private financeRepository: IFinanceRepository,
    ) {
    }

    async createDefaultCategories(workspaceId: string, type: WorkspaceType): Promise<void> {
        const personalCategories: Omit<CategoryModel, "id">[] = [
            // Receitas
            { name: "Salário", icon: "payments", color: "#9CDE7C", type: CategoryType.income, isDeleted: false },
            { name: "Investimentos", icon: "trending_up", color: "#25D3D0", type: CategoryType.income, isDeleted: false },
            { name: "Freelance/Extra", icon: "work", color: "#FAD02E", type: CategoryType.income, isDeleted: false },
            { name: "Presentes", icon: "celebration", color: "#E91E63", type: CategoryType.income, isDeleted: false },

            // Despesas Essenciais
            { name: "Moradia", icon: "home", color: "#14404C", type: CategoryType.expense, isDeleted: false },
            { name: "Alimentação", icon: "restaurant", color: "#FF6F61", type: CategoryType.expense, isDeleted: false },
            { name: "Supermercado", icon: "shopping_cart", color: "#4A8C9C", type: CategoryType.expense, isDeleted: false },
            { name: "Transporte", icon: "directions_car", color: "#009688", type: CategoryType.expense, isDeleted: false },
            { name: "Saúde", icon: "health_and_safety", color: "#BA1A1A", type: CategoryType.expense, isDeleted: false },
            { name: "Educação", icon: "school", color: "#3F51B5", type: CategoryType.expense, isDeleted: false },

            // Contas e Utilidades
            { name: "Energia", icon: "flash_on", color: "#FFEB3B", type: CategoryType.expense, isDeleted: false },
            { name: "Água", icon: "water_drop", color: "#2196F3", type: CategoryType.expense, isDeleted: false },
            { name: "Internet/TV", icon: "wifi", color: "#673AB7", type: CategoryType.expense, isDeleted: false },

            // Estilo de Vida
            { name: "Lazer", icon: "theater_comedy", color: "#FFFF98", type: CategoryType.expense, isDeleted: false },
            { name: "Compras", icon: "checkroom", color: "#9C27B0", type: CategoryType.expense, isDeleted: false },
            { name: "Viagens", icon: "flight", color: "#00BCD4", type: CategoryType.expense, isDeleted: false },
            { name: "Assinaturas", icon: "subscriptions", color: "#4CAF50", type: CategoryType.expense, isDeleted: false },
            { name: "Dívidas/Empréstimos", icon: "credit_card", color: "#795548", type: CategoryType.expense, isDeleted: false },
            { name: "Outros", icon: "category", color: "#607D8B", type: CategoryType.expense, isDeleted: false },
        ];

        const businessCategories: Omit<CategoryModel, "id">[] = [
            // Receitas
            { name: "Vendas", icon: "shopping_cart", color: "#9CDE7C", type: CategoryType.income, isDeleted: false },
            { name: "Serviços", icon: "handyman", color: "#25D3D0", type: CategoryType.income, isDeleted: false },
            { name: "Rendimentos", icon: "account_balance", color: "#FAD02E", type: CategoryType.income, isDeleted: false },

            // Despesas Operacionais
            { name: "Fornecedores", icon: "inventory", color: "#FF6F61", type: CategoryType.expense, isDeleted: false },
            { name: "Aluguel", icon: "home", color: "#14404C", type: CategoryType.expense, isDeleted: false },
            { name: "Marketing", icon: "show_chart", color: "#25D3D0", type: CategoryType.expense, isDeleted: false },
            { name: "Folha de Pagamento", icon: "payments", color: "#4A8C9C", type: CategoryType.expense, isDeleted: false },
            { name: "Impostos", icon: "account_balance_wallet", color: "#607D8B", type: CategoryType.expense, isDeleted: false },
            { name: "Ferramentas/Software", icon: "build", color: "#8E44AD", type: CategoryType.expense, isDeleted: false },
            { name: "Manutenção", icon: "handyman", color: "#D4A017", type: CategoryType.expense, isDeleted: false },
            { name: "Outros", icon: "category", color: "#795548", type: CategoryType.expense, isDeleted: false },
        ];

        const defaultCategories = type === WorkspaceType.business ? businessCategories : personalCategories;

        for (const category of defaultCategories) {
            await this.categoryRepository.createCategory(workspaceId, category);
        }
    }

    async handleCategoryUpdate(workspaceId: string, oldCategory: CategoryModel, newCategory: CategoryModel): Promise<void> {
        // Se mudou algo relevante para a apresentação
        const hasPresentationChanged =
            oldCategory.name !== newCategory.name ||
            oldCategory.icon !== newCategory.icon ||
            oldCategory.color !== newCategory.color;

        if (hasPresentationChanged) {
            await this.financeRepository.updateSummaryCategoryInfo(workspaceId, newCategory);
        }

        if (oldCategory.name === newCategory.name) return;

        const db = admin.firestore();
        const ordersSnapshot = await db.collection("workspaces").doc(workspaceId)
            .collection("orders").where("category.id", "==", oldCategory.id).get();

        if (ordersSnapshot.empty) return;

        const batch = db.batch();
        ordersSnapshot.docs.forEach((doc) => {
            batch.update(doc.ref, { category: newCategory });
        });
        await batch.commit();
    }

    async handleCategoryDeletion(workspaceId: string, category: CategoryModel): Promise<void> {
        // 1. Exclusão de planejamentos associados à categoria removida
        await this.financeRepository.deleteCategoryPlanningsByCategoryId(workspaceId, category.id);
    }
}
