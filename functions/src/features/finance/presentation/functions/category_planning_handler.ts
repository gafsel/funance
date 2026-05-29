import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { container } from "../../../../core/container";
import { CategoryPlanningModel } from "../../domain/models/finance.models";

export const onCategoryPlanningWritten = onDocumentWritten(
    "workspaces/{workspaceId}/category_planning/{planningId}",
    async (event) => {
        const workspaceId = event.params.workspaceId;

        const beforeData = event.data?.before.exists ? event.data.before.data() : null;
        const afterData = event.data?.after.exists ? event.data.after.data() : null;

        const before = beforeData ? {
            id: event.data?.before.id,
            ...beforeData,
        } as CategoryPlanningModel : null;

        const after = afterData ? {
            id: event.data?.after.id,
            ...afterData,
        } as CategoryPlanningModel : null;

        // Atualizar sumários mensais por categoria (Planejado)
        await container.summaryService.processCategoryPlanningChange(workspaceId, before, after);
    });
