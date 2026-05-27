import { IWorkspaceRepository } from "../features/workspace/domain/repositories/workspace.repository";
import { IFinanceRepository } from "../features/finance/domain/repositories/finance.repository";
import { IUserRepository } from "../features/user/domain/repositories/user.repository";
import { IInviteRepository } from "../features/workspace/domain/repositories/invite.repository";
import { ICategoryRepository } from "../features/workspace/domain/repositories/category.repository";
import { ICategoryService } from "../features/workspace/domain/services/category.service";
import { IInviteService } from "../features/workspace/domain/services/invite.service";
import { IGoalRepository } from "../features/goal/domain/repositories/goal.repository";
import { IGoalService } from "../features/goal/domain/services/goal.service";
import { WorkspaceRepositoryImpl } from "../features/workspace/data/repositories/workspace.repository.impl";
import { FinanceRepositoryImpl } from "../features/finance/data/repositories/finance.repository.impl";
import { UserRepositoryImpl } from "../features/user/data/repositories/user.repository.impl";
import { InviteRepositoryImpl } from "../features/workspace/data/repositories/invite.repository.impl";
import { CategoryRepositoryImpl } from "../features/workspace/data/repositories/category.repository.impl";
import { GoalRepositoryImpl } from "../features/goal/data/repositories/goal.repository.impl";
import { CategoryServiceImpl } from "../features/workspace/domain/services/category.service.impl";
import { InviteServiceImpl } from "../features/workspace/domain/services/invite.service.impl";
import { GoalServiceImpl } from "../features/goal/domain/services/goal.service.impl";
import { FinanceService } from "../features/finance/domain/services/finance.service";
import { SummaryService } from "../features/finance/domain/services/summary.service";

class Container {
  private static _workspaceRepository: IWorkspaceRepository;
  private static _financeRepository: IFinanceRepository;
  private static _userRepository: IUserRepository;
  private static _inviteRepository: IInviteRepository;
  private static _categoryRepository: ICategoryRepository;
  private static _categoryService: ICategoryService;
  private static _inviteService: IInviteService;
  private static _goalRepository: IGoalRepository;
  private static _goalService: IGoalService;
  private static _financeService: FinanceService;
  private static _summaryService: SummaryService;

  static get workspaceRepository(): IWorkspaceRepository {
    if (!this._workspaceRepository) {
      this._workspaceRepository = new WorkspaceRepositoryImpl();
    }
    return this._workspaceRepository;
  }

  static get financeRepository(): IFinanceRepository {
    if (!this._financeRepository) {
      this._financeRepository = new FinanceRepositoryImpl();
    }
    return this._financeRepository;
  }

  static get userRepository(): IUserRepository {
    if (!this._userRepository) {
      this._userRepository = new UserRepositoryImpl();
    }
    return this._userRepository;
  }

  static get inviteRepository(): IInviteRepository {
    if (!this._inviteRepository) {
      this._inviteRepository = new InviteRepositoryImpl();
    }
    return this._inviteRepository;
  }

  static get inviteService(): IInviteService {
    if (!this._inviteService) {
      this._inviteService = new InviteServiceImpl(this.userRepository, this.workspaceRepository);
    }
    return this._inviteService;
  }

  static get categoryRepository(): ICategoryRepository {
    if (!this._categoryRepository) {
      this._categoryRepository = new CategoryRepositoryImpl();
    }
    return this._categoryRepository;
  }

  static get categoryService(): ICategoryService {
    if (!this._categoryService) {
      this._categoryService = new CategoryServiceImpl(this.categoryRepository, this.financeRepository);
    }
    return this._categoryService;
  }

  static get financeService(): FinanceService {
    if (!this._financeService) {
      this._financeService = new FinanceService(this.financeRepository);
    }
    return this._financeService;
  }

  static get summaryService(): SummaryService {
    if (!this._summaryService) {
      this._summaryService = new SummaryService(this.financeRepository);
    }
    return this._summaryService;
  }

  static get goalRepository(): IGoalRepository {
    if (!this._goalRepository) {
      this._goalRepository = new GoalRepositoryImpl();
    }
    return this._goalRepository;
  }

  static get goalService(): IGoalService {
    if (!this._goalService) {
      this._goalService = new GoalServiceImpl(this.goalRepository);
    }
    return this._goalService;
  }
}

export const container = Container;
