import { LedgerEntryModel, LedgerEntryType, OrderType, PlanningModel, PlanningType } from "../models/finance.models";
import { IFinanceRepository } from "../repositories/finance.repository";

export class SummaryService {
  constructor(private financeRepository: IFinanceRepository) {}

  async processPlanningChange(
    workspaceId: string,
    before: PlanningModel | null,
    after: PlanningModel | null
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
      // Simplificando: remove o antigo e adiciona o novo para garantir consistência
      await this.updatePlanningImpact(workspaceId, before, -1);
      await this.updatePlanningImpact(workspaceId, after, 1);
    }
  }

  private async updatePlanningImpact(workspaceId: string, planning: PlanningModel, multiplier: number): Promise<void> {
    const startYear = planning.startDate.getFullYear();
    const startMonth = planning.startDate.getMonth();
    const endYear = planning.endDate.getFullYear();
    const endMonth = planning.endDate.getMonth();

    const totalMonths = (endYear - startYear) * 12 + (endMonth - startMonth) + 1;

    for (let i = 0; i < totalMonths; i++) {
      const date = new Date(startYear, startMonth + i, 1);
      const year = date.getFullYear();
      const month = date.getMonth() + 1;

      let monthAmount = 0;
      if (planning.type === PlanningType.unique) {
        if (i === 0) {
          monthAmount = planning.amount;
        }
      }
      else if (planning.type === PlanningType.parcelado) {
        monthAmount = planning.amount / (planning.installmentsCount || 1);
      }
      else {
        monthAmount = planning.amount;
      }

      if (monthAmount !== 0) {
        await this.financeRepository.updateCategoryMonthSummaryPlanning(
          workspaceId,
          year,
          month,
          planning.category,
          monthAmount * multiplier
        );

        await this.financeRepository.updatePlanningMonthSummary(
          workspaceId,
          planning.id,
          year,
          month,
          { plannedDelta: monthAmount * multiplier, actualDelta: 0 }
        );
      }
    }
  }

  async processLedgerEntryChange(
    workspaceId: string,
    before: LedgerEntryModel | null,
    after: LedgerEntryModel | null
  ): Promise<void> {
    if (!before && !after) return;

    // Ignorar transferências
    if (before?.orderType === OrderType.transfer) before = null;
    if (after?.orderType === OrderType.transfer) after = null;

    if (!before && !after) return;

    // Se for criação
    if (!before && after) {
      await this.financeRepository.updateCategoryMonthSummary(
        workspaceId,
        after.dueDate.getFullYear(),
        after.dueDate.getMonth() + 1,
        after.category,
        {
          debitDelta: after.type === LedgerEntryType.debit ? after.amount : 0,
          creditDelta: after.type === LedgerEntryType.credit ? after.amount : 0,
          countDelta: 1,
        }
      );

      if (after.planningId) {
        await this.financeRepository.updatePlanningMonthSummary(
          workspaceId,
          after.planningId,
          after.dueDate.getFullYear(),
          after.dueDate.getMonth() + 1,
          { plannedDelta: 0, actualDelta: after.amount }
        );
      }
    }
    // Se for exclusão
    else if (before && !after) {
      await this.financeRepository.updateCategoryMonthSummary(
        workspaceId,
        before.dueDate.getFullYear(),
        before.dueDate.getMonth() + 1,
        before.category,
        {
          debitDelta: before.type === LedgerEntryType.debit ? -before.amount : 0,
          creditDelta: before.type === LedgerEntryType.credit ? -before.amount : 0,
          countDelta: -1,
        }
      );

      if (before.planningId) {
        await this.financeRepository.updatePlanningMonthSummary(
          workspaceId,
          before.planningId,
          before.dueDate.getFullYear(),
          before.dueDate.getMonth() + 1,
          { plannedDelta: 0, actualDelta: -before.amount }
        );
      }
    }
    // Se for atualização
    else if (before && after) {
      const beforeYear = before.dueDate.getFullYear();
      const beforeMonth = before.dueDate.getMonth() + 1;
      const afterYear = after.dueDate.getFullYear();
      const afterMonth = after.dueDate.getMonth() + 1;

      if (beforeYear !== afterYear || beforeMonth !== afterMonth || before.category.id !== after.category.id || before.planningId !== after.planningId) {
        // Remover do antigo
        await this.financeRepository.updateCategoryMonthSummary(
          workspaceId,
          beforeYear,
          beforeMonth,
          before.category,
          {
            debitDelta: before.type === LedgerEntryType.debit ? -before.amount : 0,
            creditDelta: before.type === LedgerEntryType.credit ? -before.amount : 0,
            countDelta: -1,
          }
        );

        if (before.planningId) {
          await this.financeRepository.updatePlanningMonthSummary(
            workspaceId,
            before.planningId,
            beforeYear,
            beforeMonth,
            { plannedDelta: 0, actualDelta: -before.amount }
          );
        }

        // Adicionar no novo
        await this.financeRepository.updateCategoryMonthSummary(
          workspaceId,
          afterYear,
          afterMonth,
          after.category,
          {
            debitDelta: after.type === LedgerEntryType.debit ? after.amount : 0,
            creditDelta: after.type === LedgerEntryType.credit ? after.amount : 0,
            countDelta: 1,
          }
        );

        if (after.planningId) {
          await this.financeRepository.updatePlanningMonthSummary(
            workspaceId,
            after.planningId,
            afterYear,
            afterMonth,
            { plannedDelta: 0, actualDelta: after.amount }
          );
        }
      }
      else {
        // Apenas mudou o valor ou tipo no mesmo mês/ano e categoria
        const debitDelta = (after.type === LedgerEntryType.debit ? after.amount : 0) - (before.type === LedgerEntryType.debit ? before.amount : 0);
        const creditDelta = (after.type === LedgerEntryType.credit ? after.amount : 0) - (before.type === LedgerEntryType.credit ? before.amount : 0);

        if (debitDelta !== 0 || creditDelta !== 0) {
          await this.financeRepository.updateCategoryMonthSummary(
            workspaceId,
            afterYear,
            afterMonth,
            after.category,
            {
              debitDelta,
              creditDelta,
              countDelta: 0,
            }
          );
        }

        if (after.planningId) {
          const actualDelta = after.amount - before.amount;
          if (actualDelta !== 0) {
            await this.financeRepository.updatePlanningMonthSummary(
              workspaceId,
              after.planningId,
              afterYear,
              afterMonth,
              { plannedDelta: 0, actualDelta }
            );
          }
        }
      }
    }
  }
}
