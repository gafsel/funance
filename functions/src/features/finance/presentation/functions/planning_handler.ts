import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { container } from "../../../../core/container";
import { PlanningModel } from "../../domain/models/finance.models";

export const onPlanningWritten = onDocumentWritten(
  "workspaces/{workspaceId}/planning/{planningId}",
  async (event) => {
    const workspaceId = event.params.workspaceId;

    const beforeData = event.data?.before.exists ? event.data.before.data() : null;
    const afterData = event.data?.after.exists ? event.data.after.data() : null;

    const before = beforeData ? {
      ...beforeData,
      id: event.data?.before.id,
      startDate: (beforeData.start_date || beforeData.startDate).toDate(),
      endDate: (beforeData.end_date || beforeData.endDate).toDate(),
      installmentsCount: beforeData.installments_count || beforeData.installmentsCount,
    } as PlanningModel : null;

    const after = afterData ? {
      ...afterData,
      id: event.data?.after.id,
      startDate: (afterData.start_date || afterData.startDate).toDate(),
      endDate: (afterData.end_date || afterData.endDate).toDate(),
      installmentsCount: afterData.installments_count || afterData.installmentsCount,
    } as PlanningModel : null;

    // Atualizar sumários mensais por categoria (Planejado)
    await container.summaryService.processPlanningChange(workspaceId, before, after);
  });
