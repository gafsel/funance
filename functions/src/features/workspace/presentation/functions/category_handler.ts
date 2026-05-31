import { onDocumentCreated, onDocumentDeleted, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { container } from "../../../../core/container";
import { CategoryModel } from "../../domain/models/category.model";
import { WorkspaceType } from "../../domain/models/workspace.model";

export const onWorkspaceCreated = onDocumentCreated("workspaces/{workspaceId}", async (event) => {
    const workspaceId = event.params.workspaceId;
    const data = event.data?.data();
    if (!data) return;

    const type = data.type as WorkspaceType;
    const categoryService = container.categoryService;

    await categoryService.createDefaultCategories(workspaceId, type);
});

export const onCategoryUpdated = onDocumentUpdated("workspaces/{workspaceId}/categories/{categoryId}", async (event) => {
    const workspaceId = event.params.workspaceId;
    const newData = event.data?.after.data() as CategoryModel;
    const oldData = event.data?.before.data() as CategoryModel;

    if (!newData || !oldData) return;

    const categoryService = container.categoryService;
    await categoryService.handleCategoryUpdate(workspaceId, oldData, newData);
});

export const onCategoryDeleted = onDocumentDeleted("workspaces/{workspaceId}/categories/{categoryId}", async (event) => {
    const workspaceId = event.params.workspaceId;
    const oldData = event.data?.data() as CategoryModel;
    if (!oldData) return;

    const categoryService = container.categoryService;
    await categoryService.handleCategoryDeletion(workspaceId, oldData);
});
