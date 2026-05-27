import * as admin from "firebase-admin";
import { ICategoryRepository } from "../repositories/category.repository";
import { ICategoryService } from "./category.service";
import { CategoryModel, CategoryType } from "../models/category.model";
import { WorkspaceType } from "../models/workspace.model";
import { IFinanceRepository } from "../../../finance/domain/repositories/finance.repository";

export class CategoryServiceImpl implements ICategoryService {
  constructor(
        private categoryRepository: ICategoryRepository,
        private financeRepository: IFinanceRepository
  ) {}

  async createDefaultCategories(workspaceId: string, type: WorkspaceType): Promise<void> {
    const personalCategories: Omit<CategoryModel, "id">[] = [
      // Receitas
      { name: "Salário", icon: "payments", color: "#9CDE7C", type: CategoryType.income, isDeleted: false },
      { name: "Investimentos", icon: "trending_up", color: "#25D3D0", type: CategoryType.income, isDeleted: false },
      { name: "Freelance/Extra", icon: "add_task", color: "#FAD02E", type: CategoryType.income, isDeleted: false },
      { name: "Presentes", icon: "redeem", color: "#8E44AD", type: CategoryType.income, isDeleted: false },

      // Despesas Essenciais
      { name: "Moradia", icon: "home", color: "#14404C", type: CategoryType.expense, isDeleted: false },
      { name: "Alimentação", icon: "restaurant", color: "#FF6F61", type: CategoryType.expense, isDeleted: false },
      { name: "Supermercado", icon: "shopping_cart", color: "#4A8C9C", type: CategoryType.expense, isDeleted: false },
      { name: "Transporte", icon: "commute", color: "#25D3D0", type: CategoryType.expense, isDeleted: false },
      { name: "Saúde", icon: "medical_services", color: "#9CDE7C", type: CategoryType.expense, isDeleted: false },
      { name: "Educação", icon: "school", color: "#8E44AD", type: CategoryType.expense, isDeleted: false },

      // Despesas Variáveis/Estilo de Vida
      { name: "Lazer", icon: "celebration", color: "#FAD02E", type: CategoryType.expense, isDeleted: false },
      { name: "Compras", icon: "shopping_bag", color: "#FF6F61", type: CategoryType.expense, isDeleted: false },
      { name: "Assinaturas/Serviços", icon: "subscriptions", color: "#4A8C9C", type: CategoryType.expense, isDeleted: false },
      { name: "Dívidas/Empréstimos", icon: "credit_card", color: "#14404C", type: CategoryType.expense, isDeleted: false },
      { name: "Outros", icon: "more_horiz", color: "#D4A017", type: CategoryType.expense, isDeleted: false },
    ];

    const businessCategories: Omit<CategoryModel, "id">[] = [
      // Receitas
      { name: "Vendas", icon: "trending_up", color: "#9CDE7C", type: CategoryType.income, isDeleted: false },
      { name: "Serviços", icon: "engineering", color: "#25D3D0", type: CategoryType.income, isDeleted: false },
      { name: "Rendimentos", icon: "account_balance", color: "#FAD02E", type: CategoryType.income, isDeleted: false },

      // Despesas Operacionais
      { name: "Fornecedores", icon: "inventory", color: "#FF6F61", type: CategoryType.expense, isDeleted: false },
      { name: "Aluguel Escritório", icon: "business", color: "#14404C", type: CategoryType.expense, isDeleted: false },
      { name: "Marketing/Publicidade", icon: "campaign", color: "#25D3D0", type: CategoryType.expense, isDeleted: false },
      { name: "Folha de Pagamento", icon: "groups", color: "#4A8C9C", type: CategoryType.expense, isDeleted: false },
      { name: "Impostos/Taxas", icon: "gavel", color: "#14404C", type: CategoryType.expense, isDeleted: false },
      { name: "Software/Ferramentas", icon: "computer", color: "#8E44AD", type: CategoryType.expense, isDeleted: false },
      { name: "Logística/Frete", icon: "local_shipping", color: "#FF6F61", type: CategoryType.expense, isDeleted: false },

      // Outros
      { name: "Manutenção", icon: "build", color: "#D4A017", type: CategoryType.expense, isDeleted: false },
      { name: "Diversos", icon: "more_horiz", color: "#4A8C9C", type: CategoryType.expense, isDeleted: false },
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
    const db = admin.firestore();
    const ordersSnapshot = await db.collection("workspaces").doc(workspaceId)
      .collection("orders").where("category.id", "==", category.id).get();

    if (ordersSnapshot.empty) return;

    const batch = db.batch();
    ordersSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {
        category: {
          id: "no_category",
          name: "Sem Categoria",
          icon: "help_outline",
          color: "#999999",
          type: CategoryType.both,
          isDeleted: false,
        },
      });
    });
    await batch.commit();
  }
}
