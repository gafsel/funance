import { InstallmentModel } from "../../../finance/domain/models/finance.models";

export interface IGoalService {
  processInstallmentChange(workspaceId: string, before: InstallmentModel | null, after: InstallmentModel | null): Promise<void>;
}
