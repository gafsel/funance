import * as admin from "firebase-admin";
import { CategoryModel } from "../../domain/models/category.model";
import { ICategoryRepository } from "../../domain/repositories/category.repository";

export class CategoryRepositoryImpl implements ICategoryRepository {
    private getCollection(workspaceId: string) {
        return admin.firestore().collection("workspaces").doc(workspaceId).collection("categories");
    }

    async createCategory(workspaceId: string, category: CategoryModel | Omit<CategoryModel, "id">): Promise<string> {
        if ("id" in category) {
            const { id, ...data } = category;
            await this.getCollection(workspaceId).doc(id).set(data);
            return id;
        }
        const docRef = await this.getCollection(workspaceId).add(category);
        return docRef.id;
    }

    async updateCategory(workspaceId: string, category: CategoryModel): Promise<void> {
        const { id, ...data } = category;
        await this.getCollection(workspaceId).doc(id).update(data);
    }

    async deleteCategory(workspaceId: string, categoryId: string): Promise<void> {
        await this.getCollection(workspaceId).doc(categoryId).delete();
    }

    async getCategories(workspaceId: string): Promise<CategoryModel[]> {
        const snapshot = await this.getCollection(workspaceId).get();
        return snapshot.docs.map((doc) => {
            const data = doc.data();
            return {
                id: doc.id,
                ...data,
            } as CategoryModel;
        });
    }
}
