import { IAIRepository, isTransientAiError } from "../../../../core/services/ai.service";
import { AI_CACHE_FUNCTIONS, IAiCacheService } from "../../../../core/services/ai_cache.service";
import { QuotaGuard } from "../../../../core/services/quota.service";
import { OrderModel, CategoryPlanningModel } from "../../../finance/domain/models/finance.models";
import { ICategoryRepository } from "../../../workspace/domain/repositories/category.repository";
import { IFinanceRepository } from "../../../finance/domain/repositories/finance.repository";
import { IWorkspaceRepository } from "../../../workspace/domain/repositories/workspace.repository";
import * as admin from "firebase-admin";

export interface IOnboardingService {
    /**
     * @param quota cota diária do chamador. Só é consumida em cache-miss,
     *              imediatamente antes da chamada à IA.
     */
    analyzePlanning(workspaceId: string, quota?: QuotaGuard): Promise<{
        goals: any[],
        plannings: CategoryPlanningModel[]
    }>;

    analyzeAccountDocument(workspaceId: string, storagePath: string): Promise<{
        account: any,
        orders: OrderModel[]
    }>;

    analyzeReconciliationDocument(workspaceId: string, storagePath: string, uploadId?: string): Promise<{
        transactions: any[]
    }>;
}

export class OnboardingServiceImpl implements IOnboardingService {
    constructor(
        private aiRepository: IAIRepository,
        private categoryRepository: ICategoryRepository,
        private financeRepository: IFinanceRepository,
        private workspaceRepository: IWorkspaceRepository,
        private aiCacheService: IAiCacheService
    ) {
    }

    async analyzePlanning(workspaceId: string, quota?: QuotaGuard): Promise<any> {
        const workspace = await this.workspaceRepository.getWorkspaceById(workspaceId);
        if (!workspace) throw new Error("Workspace não encontrado");

        const categories = await this.categoryRepository.getCategories(workspaceId);
        const orders = await this.financeRepository.getOrders(workspaceId, 100);

        const categoryNames = categories.map((c) => c.name);

        // Cache por hash da ENTRADA (F5.6): o usuário volta uma tela e avança
        // de novo com exatamente os mesmos dados. Cache-hit não gasta cota.
        const cacheInput = { workspaceType: workspace.type, categories: categoryNames, orders };
        const cached = await this.aiCacheService.get(
            workspaceId, AI_CACHE_FUNCTIONS.analysePlanning, cacheInput
        );
        if (cached) return cached;

        // A cota é consumida AQUI: é a chamada de IA que ela mede, e só
        // chegamos neste ponto em cache-miss.
        await quota?.consume();

        let result: any;
        try {
            result = await this.aiRepository.analyzePlanningAndSuggestGoals(
                workspaceId,
                workspace.type,
                categoryNames,
                orders,
            );
        }
        catch (error) {
            if (isTransientAiError(error)) {
                await quota?.refund();
            }
            throw error;
        }

        // Só a resposta já validada pelo ai.service entra no cache.
        await this.aiCacheService.set(
            workspaceId, AI_CACHE_FUNCTIONS.analysePlanning, cacheInput, result
        );
        return result;
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

    async analyzeReconciliationDocument(workspaceId: string, storagePath: string, uploadId?: string): Promise<{
        transactions: any[]
    }> {
        if (uploadId) {
            await this.workspaceRepository.updateUploadProgress(workspaceId, uploadId, {
                status: "extracting",
                progress: 0.50,
                message: "[Fase 2/4] 🔍 Extraindo transações e valores por IA..."
            });
        }
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
