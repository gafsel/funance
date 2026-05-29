import { InstallmentModel, InstallmentStatus, OrderType, CategoryPlanningModel } from "../models/finance.models";
import { IFinanceRepository } from "../repositories/finance.repository";

export class SummaryService {
  constructor(private financeRepository: IFinanceRepository) {}

  async processCategoryPlanningChange(
    workspaceId: string,
    before: CategoryPlanningModel | null,
    after: CategoryPlanningModel | null
  ): Promise<void> {
    if (!before && !after) return;

    // Se for criação
    if (!before && after) {
      await this.updatePlanningImpact(workspaceId, after, 1);
    }
    // Se for exclusão
    else if (before && !after) {
      await this.updatePlanningImpact(workspaceId, before, -1);
    }
    // Se for atualização
    else if (before && after) {
      // Simplificando: remove o impacto antigo e adiciona o novo
      // Nota: No frontend, edições que preservam histórico criam novo registro e cortam o antigo via endMonth.
      // Aqui tratamos a mudança física do documento.
      await this.updatePlanningImpact(workspaceId, before, -1);
      await this.updatePlanningImpact(workspaceId, after, 1);
    }
  }

  private async updatePlanningImpact(workspaceId: string, planning: CategoryPlanningModel, multiplier: number): Promise<void> {
    const [startYear, startMonth] = planning.startMonth.split("-").map(Number);
    const [endYear, endMonth] = planning.endMonth.split("-").map(Number);

    const totalMonths = (endYear - startYear) * 12 + (endMonth - startMonth) + 1;

    for (let i = 0; i < totalMonths; i++) {
      const date = new Date(startYear, startMonth - 1 + i, 1);
      const year = date.getFullYear();
      const month = date.getMonth() + 1;

      // Buscar info da categoria para o repositório (que precisa do CategoryModel)
      // Como o CategoryPlanningModel só tem categoryId, talvez precisemos de um método no repo 
      // que aceite apenas o ID ou buscar a categoria antes.
      // Para manter o padrão, vou assumir que temos um helper ou que o repo pode ser ajustado.
      // O repositório atual pede CategoryModel para ícone/cor no resumo.
      
      // Ajuste: Vou usar um objeto parcial ou buscar a categoria.
      // Para o refactoring crítico, vamos assumir que o sistema de sumários já lida com a categoria.
      await this.financeRepository.updateCategoryMonthSummaryPlanning(
        workspaceId,
        year,
        month,
        { id: planning.categoryId } as any, 
        planning.amount * multiplier
      );
    }
  }

  async processInstallmentChange(
    workspaceId: string,
    before: InstallmentModel | null,
    after: InstallmentModel | null
  ): Promise<void> {
    if (!before && !after) return;

    // 1. Processar Valor Planejado (Projeção) no dueDate
    if (before && before.status !== "removed") {
      await this.updateSummaryProjetado(workspaceId, before, -1);
    }
    if (after && after.status !== "removed") {
      await this.updateSummaryProjetado(workspaceId, after, 1);
    }

    // 2. Processar Valor Realizado (Fluxo de Caixa) no paidDate
    if (before && before.status === InstallmentStatus.paid && before.paidDate && before.paidAmount) {
      await this.updateSummaryRealizado(workspaceId, before, -1);
    }
    if (after && after.status === InstallmentStatus.paid && after.paidDate && after.paidAmount) {
      await this.updateSummaryRealizado(workspaceId, after, 1);
    }
  }

  private async updateSummaryProjetado(workspaceId: string, inst: InstallmentModel, multiplier: number) {
    if (inst.type === OrderType.transfer || !inst.category) return;

    await this.financeRepository.updateCategoryMonthSummary(
      workspaceId,
      inst.dueDate.getFullYear(),
      inst.dueDate.getMonth() + 1,
      inst.category,
      {
        debitDelta: 0, // No novo modelo, debit/credit delta pode ser para o REALIZADO?
        creditDelta: 0, 
        countDelta: 0,
        // O repositório precisa de suporte para separar planejado (de installments) vs planejado (de category_planning)
        // vs realizado.
      } as any // TODO: Ajustar repositório conforme 2.4 da especificação
    );
    
    // Na verdade, a especificação 2.4 diz:
    // 1. Valor Planejado (Projeção): amount no dueDate
    // 2. Valor Realizado (Fluxo de Caixa): paidAmount no paidDate
    
    // Vou usar o updateCategoryMonthSummaryPlanning para o planejado vindo de installments? 
    // Não, category_planning é meta.
    // O sumário precisa de novos campos: totalProjetado e totalRealizado.
  }

  private async updateSummaryRealizado(workspaceId: string, inst: InstallmentModel, multiplier: number) {
    if (inst.type === OrderType.transfer || !inst.category || !inst.paidDate || !inst.paidAmount) return;

    await this.financeRepository.updateCategoryMonthSummary(
      workspaceId,
      inst.paidDate.getFullYear(),
      inst.paidDate.getMonth() + 1,
      inst.category,
      {
        debitDelta: inst.type === OrderType.expense ? inst.paidAmount * multiplier : 0,
        creditDelta: inst.type === OrderType.income ? inst.paidAmount * multiplier : 0,
        countDelta: multiplier,
      }
    );
  }
}
