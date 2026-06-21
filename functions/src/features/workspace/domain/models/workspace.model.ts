export enum WorkspaceType {
  personal = "personal",
  business = "business",
}

export interface WorkspaceModel {
  id: string;
  name: string;
  type: WorkspaceType;
  members: string[];
  createdAt: Date;
  xp?: number;
  level?: number;
  lastLevelUpAt?: Date;
  unlockedBadges?: Record<string, string>;
  weeklyStreaks?: number;
  onboardingCompleted?: boolean;
}
