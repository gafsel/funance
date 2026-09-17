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
  /**
   * LEGADO, mas vivo: a sequência de semanas com todas as missões concluídas,
   * como NÚMERO. O app instalado desserializa este campo como `num?`, então o
   * tipo não pode mudar. É sempre igual a `streaks.missions`.
   */
  weeklyStreaks?: number;
  /** F2.3 — os dois streaks semanais. Escrito junto de `weeklyStreaks`. */
  streaks?: { missions: number, plan: number };
  onboardingCompleted?: boolean;
}
