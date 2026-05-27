import { LedgerEntryModel } from "../../../finance/domain/models/finance.models";

export interface IGoalService {
  processLedgerEntryChange(workspaceId: string, before: LedgerEntryModel | null, after: LedgerEntryModel | null): Promise<void>;
}
