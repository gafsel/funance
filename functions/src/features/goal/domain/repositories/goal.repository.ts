import { GoalModel } from "../models/goal.model";

export interface IGoalRepository {
  getGoals(workspaceId: string): Promise<GoalModel[]>;
  getActiveGoalsByAccount(workspaceId: string, accountId: string): Promise<GoalModel[]>;
  getGoal(workspaceId: string, goalId: string): Promise<GoalModel | null>;
  updateGoal(workspaceId: string, goal: GoalModel): Promise<void>;
}
