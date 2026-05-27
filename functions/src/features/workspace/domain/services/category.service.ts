import { CategoryModel } from "../models/category.model";
import { WorkspaceType } from "../models/workspace.model";

export interface ICategoryService {
    createDefaultCategories(workspaceId: string, type: WorkspaceType): Promise<void>;
    handleCategoryUpdate(workspaceId: string, oldCategory: CategoryModel, newCategory: CategoryModel): Promise<void>;
    handleCategoryDeletion(workspaceId: string, category: CategoryModel): Promise<void>;
}
