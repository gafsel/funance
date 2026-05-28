import { IAIRepository } from "../../../../core/services/ai.service";
import { GoalModel } from "../../../goal/domain/models/goal.model";
import { OrderModel, PlanningModel } from "../../../finance/domain/models/finance.models";
import * as admin from "firebase-admin";

export interface IOnboardingService {
    analyzeAccounts(workspaceType: string, transactions: any[]): Promise<GoalModel[]>;
    analyzeAccountDocument(storagePath: string, fileName: string, existingCategories: string[]): Promise<{
        account: any,
        orders: OrderModel[],
        plannings: PlanningModel[]
    }>;
}

export class OnboardingServiceImpl implements IOnboardingService {
  constructor(private aiRepository: IAIRepository) {}

  async analyzeAccounts(workspaceType: string, transactions: any[]): Promise<GoalModel[]> {
    return await this.aiRepository.analyzeAccountsAndSuggestGoals(workspaceType, transactions);
  }

  async analyzeAccountDocument(storagePath: string, fileName: string, existingCategories: string[]): Promise<{
        account: any,
        orders: OrderModel[],
        plannings: PlanningModel[]
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

    // Tratar OFX que muitas vezes vem como octet-stream
    if (fileName.toLowerCase().endsWith(".ofx") && mimeType === "application/octet-stream") {
      mimeType = "text/plain";
    }

    return await this.aiRepository.analyzeAccountDocument(content, mimeType, fileName, existingCategories);
  }
}
