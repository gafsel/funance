import { CategoryModel } from "../models/category.model";

export interface ICategoryRepository {
  createCategory(workspaceId: string, category: Omit<CategoryModel, "id">): Promise<string>;
  updateCategory(workspaceId: string, category: CategoryModel): Promise<void>;
  deleteCategory(workspaceId: string, categoryId: string): Promise<void>;
  getCategories(workspaceId: string): Promise<CategoryModel[]>;
}
