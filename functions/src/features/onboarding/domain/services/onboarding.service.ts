import { IAIRepository } from "../../../../core/services/ai.service";
import { OrderModel, CategoryPlanningModel } from "../../../finance/domain/models/finance.models";
import { ICategoryRepository } from "../../../workspace/domain/repositories/category.repository";
import { IFinanceRepository } from "../../../finance/domain/repositories/finance.repository";
import { IWorkspaceRepository } from "../../../workspace/domain/repositories/workspace.repository";
import * as admin from "firebase-admin";

export interface IOnboardingService {
    analyzePlanning(workspaceId: string): Promise<{
        goals: any[],
        plannings: CategoryPlanningModel[]
    }>;

    analyzeAccountDocument(workspaceId: string, storagePath: string): Promise<{
        account: any,
        orders: OrderModel[]
    }>;

    analyzeReconciliationDocument(workspaceId: string, storagePath: string): Promise<{
        transactions: any[]
    }>;
}

export class OnboardingServiceImpl implements IOnboardingService {
    constructor(
        private aiRepository: IAIRepository,
        private categoryRepository: ICategoryRepository,
        private financeRepository: IFinanceRepository,
        private workspaceRepository: IWorkspaceRepository
    ) {
    }

    async analyzePlanning(workspaceId: string): Promise<any> {
        const workspace = await this.workspaceRepository.getWorkspaceById(workspaceId);
        if (!workspace) throw new Error("Workspace não encontrado");

        const categories = await this.categoryRepository.getCategories(workspaceId);
        const orders = await this.financeRepository.getOrders(workspaceId, 100);

        const categoryNames = categories.map((c) => c.name);

        return await this.aiRepository.analyzePlanningAndSuggestGoals(
            workspaceId,
            workspace.type,
            categoryNames,
            orders,
        );
    }

    async analyzeAccountDocument(workspaceId: string, storagePath: string): Promise<{
        account: any,
        orders: OrderModel[]
    }> {
        const bucket = admin.storage().bucket();
        const normalizedPath = storagePath.replace(/\/+/g, "/");
        const file = bucket.file(normalizedPath);

        const [exists] = await file.exists();
        if (!exists) {
            throw new Error(`Arquivo não encontrado no storage: ${storagePath}`);
        }

        const [content] = await file.download();
        const [metadata] = await file.getMetadata();
        let mimeType = metadata.contentType || "application/octet-stream";

        const fileName = normalizedPath.split("/").pop() || "";
        const lowerFileName = fileName.toLowerCase();
        if (lowerFileName.endsWith(".ofx") && mimeType === "application/octet-stream") {
            mimeType = "text/plain";
        }
        else if (lowerFileName.endsWith(".png") && mimeType === "application/octet-stream") {
            mimeType = "image/png";
        }
        else if ((lowerFileName.endsWith(".jpg") || lowerFileName.endsWith(".jpeg")) && mimeType === "application/octet-stream") {
            mimeType = "image/jpeg";
        }

        const existingCategories = await this.categoryRepository.getCategories(workspaceId);

        return await this.aiRepository.analyzeAccountDocument(
            workspaceId,
            content,
            mimeType,
            fileName,
            existingCategories.map(c => c.name),
            storagePath
        );
    }

    async analyzeReconciliationDocument(workspaceId: string, storagePath: string): Promise<{
        transactions: any[]
    }> {
        const bucket = admin.storage().bucket();
        const normalizedPath = storagePath.replace(/\/+/g, "/");
        const file = bucket.file(normalizedPath);

        const [exists] = await file.exists();
        if (!exists) {
            throw new Error(`Arquivo não encontrado no storage: ${storagePath}`);
        }

        const [content] = await file.download();
        const [metadata] = await file.getMetadata();
        let mimeType = metadata.contentType || "application/octet-stream";

        const fileName = normalizedPath.split("/").pop() || "";
        const lowerFileName = fileName.toLowerCase();
        if (lowerFileName.endsWith(".ofx") && mimeType === "application/octet-stream") {
            mimeType = "text/plain";
        }
        else if (lowerFileName.endsWith(".png") && mimeType === "application/octet-stream") {
            mimeType = "image/png";
        }
        else if ((lowerFileName.endsWith(".jpg") || lowerFileName.endsWith(".jpeg")) && mimeType === "application/octet-stream") {
            mimeType = "image/jpeg";
        }

        const existingCategories = await this.categoryRepository.getCategories(workspaceId);

        return await this.aiRepository.analyzeReconciliationDocument(
            workspaceId,
            content,
            mimeType,
            fileName,
            existingCategories.map(c => c.name)
        );
    }
}
