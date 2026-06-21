import { GeminiAIRepositoryImpl, IAIRepository } from "../core/services/ai.service";
import { IIdempotencyService, IdempotencyServiceImpl } from "../core/services/idempotency.service";
import { IOnboardingService, OnboardingServiceImpl } from "../features/onboarding/domain/services/onboarding.service";
import { IWorkspaceRepository } from "../features/workspace/domain/repositories/workspace.repository";
import { IFinanceRepository } from "../features/finance/domain/repositories/finance.repository";
import { IUserRepository } from "../features/user/domain/repositories/user.repository";
import { IInviteRepository } from "../features/workspace/domain/repositories/invite.repository";
import { ICategoryRepository } from "../features/workspace/domain/repositories/category.repository";
import { ICategoryService } from "../features/workspace/domain/services/category.service";
import { IInviteService } from "../features/workspace/domain/services/invite.service";
import { IWorkspaceService } from "../features/workspace/domain/services/workspace.service";
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
import { WorkspaceServiceImpl } from "../features/workspace/domain/services/workspace.service.impl";
import { GoalServiceImpl } from "../features/goal/domain/services/goal.service.impl";
import { FinanceService } from "../features/finance/domain/services/finance.service";
import { SummaryService } from "../features/finance/domain/services/summary.service";
import { CoachingService } from "../features/coaching/domain/services/coaching.service";
import { GamificationService } from "../features/goal/domain/services/gamification.service";
import { GoalFeasibilityService } from "../features/goal/domain/services/goal_feasibility.service";

class Container {
    private static _workspaceRepository: IWorkspaceRepository;
    private static _financeRepository: IFinanceRepository;
    private static _userRepository: IUserRepository;
    private static _inviteRepository: IInviteRepository;
    private static _categoryRepository: ICategoryRepository;
    private static _categoryService: ICategoryService;
    private static _workspaceService: IWorkspaceService;
    private static _inviteService: IInviteService;
    private static _goalRepository: IGoalRepository;
    private static _goalService: IGoalService;
    private static _financeService: FinanceService;
    private static _summaryService: SummaryService;
    private static _coachingService: CoachingService;
    private static _aiRepository: IAIRepository;
    private static _onboardingService: IOnboardingService;
    private static _idempotencyService: IIdempotencyService;
    private static _gamificationService: GamificationService;
    private static _goalFeasibilityService: GoalFeasibilityService;

    static get idempotencyService(): IIdempotencyService {
        if (!this._idempotencyService) {
            this._idempotencyService = new IdempotencyServiceImpl();
        }
        return this._idempotencyService;
    }

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

    static get workspaceService(): IWorkspaceService {
        if (!this._workspaceService) {
            this._workspaceService = new WorkspaceServiceImpl(this.workspaceRepository);
        }
        return this._workspaceService;
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

    static get coachingService(): CoachingService {
        if (!this._coachingService) {
            this._coachingService = new CoachingService(
                this.financeRepository,
                this.goalRepository,
                this.categoryRepository,
                this.workspaceRepository,
                this.aiRepository,
            );
        }
        return this._coachingService;
    }

    static get aiRepository(): IAIRepository {
        if (!this._aiRepository) {
            this._aiRepository = new GeminiAIRepositoryImpl();
        }
        return this._aiRepository;
    }

    static get onboardingService(): IOnboardingService {
        if (!this._onboardingService) {
            this._onboardingService = new OnboardingServiceImpl(
                this.aiRepository,
                this.categoryRepository,
                this.financeRepository,
                this.workspaceRepository
            );
        }
        return this._onboardingService;
    }

    static get gamificationService(): GamificationService {
        if (!this._gamificationService) {
            this._gamificationService = new GamificationService(this.aiRepository);
        }
        return this._gamificationService;
    }

    static get goalFeasibilityService(): GoalFeasibilityService {
        if (!this._goalFeasibilityService) {
            this._goalFeasibilityService = new GoalFeasibilityService(
                this.financeRepository,
                this.categoryRepository,
                this.aiRepository,
            );
        }
        return this._goalFeasibilityService;
    }
}

export const container = Container;
