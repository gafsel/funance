/**
 * Base inicial do HUD MENSAL — a aldeia de um mês já encerrado.
 *
 * O XP dos aldeões nasce no `monthlyGamificationCron`, que roda no dia 1 e
 * fecha o mês anterior. Num deploy feito no MEIO do mês isso significa que o
 * mês recém-encerrado nunca foi avaliado: o usuário que manteve quatro
 * categorias em dia em agosto abriria o HUD e veria um histórico vazio, com o
 * detalhe do ícone da aldeia sem nada para mostrar. Este script faz essa
 * primeira passada.
 *
 * Ele também PUBLICA a receita prevista do mês corrente
 * (`workspaces/{w}.expectedIncome`). É o denominador das razões de poção, ovo
 * e gota: sem ele publicado, os três ícones ficam sem número até o workspace
 * receber uma parcela de receita ou até o cron do dia 1 — até quarenta dias de
 * HUD pela metade. Use `--villagers-only` para pular esse passo.
 *
 * Características:
 *  - DRY-RUN POR PADRÃO: só escreve com `--apply`. O dry-run CALCULA a aldeia
 *    e a receita prevista (é leitura pura) e imprime o que gravaria, incluindo
 *    o retrato já existente quando há um — é assim que se revisa o efeito
 *    antes de aplicar.
 *  - NÃO PAGA DUAS VEZES: a concessão passa pelo marcador durável
 *    `xpAwardedFor.monthlyVillagers.<monthKey>`, gravado na mesma transação do
 *    XP. Rodar depois do cron (ou rodar duas vezes) recalcula o retrato e não
 *    concede nada. É por isso que o script NÃO usa o embrulho de
 *    `_idempotency`: os marcadores dele têm TTL de 30 dias e não protegeriam
 *    um recálculo tardio.
 *  - ISOLA FALHA: um workspace que lança é contado e não derruba os demais.
 *
 * ATENÇÃO: este script NUNCA foi executado contra o projeto real
 * (`funance-cef1b`). Ele escreve com Admin SDK e ignora as security rules.
 *
 * Uso:
 *   cd functions
 *   npm run build
 *   # 1) Simulação (padrão, não escreve nada) — o mês anterior ao de hoje:
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/recompute_monthly_villagers.js --project=<projectId>
 *   # 2) Um workspace só, para conferir o efeito:
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/recompute_monthly_villagers.js --project=<projectId> \
 *       --workspace=<wid> --month=2026-08 --apply
 *   # 3) Base inteira (somente após revisar o dry-run):
 *   GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
 *     node lib/scripts/recompute_monthly_villagers.js --project=<projectId> \
 *       --month=2026-08 --apply
 *
 * Flags:
 *   --apply              executa as escritas (sem ela, dry-run)
 *   --project=<id>       projectId do Firebase (default: GOOGLE_CLOUD_PROJECT)
 *   --workspace=<id>     limita a execução a um único workspace
 *   --month=YYYY-MM      mês a recalcular (default: o mês ANTERIOR a hoje)
 *   --villagers-only     não publica `expectedIncome`
 */

import * as admin from "firebase-admin";

import { GamificationRepositoryImpl } from "../features/goal/data/repositories/gamification.repository.impl";
import { IGamificationRepository } from "../features/goal/domain/repositories/gamification.repository";
import { GamificationService, WeeklyXpWriter } from "../features/goal/domain/services/gamification.service";
import { ExpectedIncomeRepositoryImpl } from "../features/finance/data/repositories/expected_income.repository.impl";
import { IExpectedIncomeRepository } from "../features/finance/domain/repositories/expected_income.repository";
import { ExpectedIncomeService } from "../features/finance/domain/services/expected_income.service";
import { FinanceRepositoryImpl } from "../features/finance/data/repositories/finance.repository.impl";
import { FinanceService } from "../features/finance/domain/services/finance.service";
import { isMonthKey, shiftMonthKey, toMonthKey } from "../core/utils/month_key";

export interface RecomputeVillagersOptions {
    dryRun: boolean;
    workspaceId?: string;
    /** `YYYY-MM`. Sem ele, o mês ANTERIOR a `now`. */
    monthKey?: string;
    /** Não publica `workspaces/{w}.expectedIncome`. */
    villagersOnly?: boolean;
    /** Injeção de relógio (testes). */
    now?: Date;
    /**
     * Escrita da barra semanal (`weekly_xp`), INJETADA.
     *
     * O bootstrap passa `FinanceService.updateWeeklyTotalXp` — a única
     * implementação dessa escrita desde F1.9. Não é construída aqui porque
     * `FinanceRepositoryImpl` resolve `admin.firestore()` no construtor, e o
     * núcleo do script precisa rodar com mocks, sem app inicializado.
     */
    weeklyXpWriter?: WeeklyXpWriter;
}

export interface RecomputeVillagersSummary {
    /** O mês efetivamente recalculado. */
    monthKey: string;
    /** Workspaces inspecionados. */
    scanned: number;
    /** Workspaces com pelo menos um aldeão no mês (retrato gravado). */
    withVillagers: number;
    /** Workspaces sem nenhuma categoria orçada no mês. */
    withoutVillagers: number;
    /** Soma do XP que os meses renderam (o concedido pode ser menor — ver abaixo). */
    xpTotal: number;
    /** Workspaces que receberam (ou receberiam) `expectedIncome` novo. */
    incomePublished: number;
    /** Workspaces em que o recálculo lançou. */
    failed: number;
}

/**
 * Núcleo do recálculo, isolado do bootstrap para permitir teste com mocks
 * (recebe o Firestore e os repositórios por parâmetro).
 */
export async function recomputeMonthlyVillagers(
    firestore: admin.firestore.Firestore,
    gamificationRepository: IGamificationRepository,
    expectedIncomeRepository: IExpectedIncomeRepository,
    options: RecomputeVillagersOptions,
    log: (message: string) => void = console.log
): Promise<RecomputeVillagersSummary> {
    const now = options.now ?? new Date();
    const monthKey = options.monthKey ?? shiftMonthKey(toMonthKey(now), -1);

    if (!isMonthKey(monthKey)) {
        throw new Error(`[recompute_monthly_villagers] --month inválido: ${monthKey} (use YYYY-MM).`);
    }

    const summary: RecomputeVillagersSummary = {
        monthKey,
        scanned: 0,
        withVillagers: 0,
        withoutVillagers: 0,
        xpTotal: 0,
        incomePublished: 0,
        failed: 0,
    };

    const gamification = new GamificationService(
        gamificationRepository,
        undefined,
        // SEM serviço de idempotência: os marcadores de `_idempotency` têm TTL
        // de 30 dias e não protegem um recálculo tardio. Quem protege é o
        // marcador durável no documento do workspace.
        undefined,
        // A barra semanal é escrita pelo MESMO caminho do cron
        // (`FinanceService.updateWeeklyTotalXp`): duas implementações da mesma
        // escrita foi o defeito que F1.9 eliminou. No dry-run ninguém a
        // alcança, porque nada é concedido.
        options.weeklyXpWriter
    );
    const expectedIncome = new ExpectedIncomeService(expectedIncomeRepository);

    const workspaceIds: string[] = [];
    if (options.workspaceId) {
        workspaceIds.push(options.workspaceId);
    }
    else {
        const snapshot = await firestore.collection("workspaces").select().get();
        for (const doc of snapshot.docs) {
            workspaceIds.push(doc.id);
        }
    }

    log(
        `[recompute_monthly_villagers] ${options.dryRun ? "DRY-RUN" : "APPLY"} — mês ${monthKey}, ` +
        `${workspaceIds.length} workspace(s)` +
        `${options.villagersOnly ? " (sem publicar expectedIncome)" : ""}.`
    );

    for (const workspaceId of workspaceIds) {
        summary.scanned++;

        try {
            // O CÁLCULO é o mesmo nos dois modos — é o que torna a simulação
            // honesta. O que o `--apply` acrescenta é a escrita.
            const outcome = await gamification.computeMonthlyVillagers(workspaceId, monthKey);

            if (outcome.villagersPlanned === 0) {
                summary.withoutVillagers++;
                log(`[recompute_monthly_villagers] ${workspaceId}: nenhuma categoria orçada em ${monthKey} — sem aldeia.`);
            }
            else {
                summary.withVillagers++;
                summary.xpTotal += outcome.xpAwarded;

                const existing = await gamificationRepository.getMonthlyReport(workspaceId, monthKey);
                const from = existing
                    ? `retrato atual ${existing.villagersAlive}/${existing.villagersPlanned} (${existing.xpAwarded} XP)`
                    : "sem retrato";
                const verb = options.dryRun ? "GRAVARIA" : "gravado";

                log(
                    `[recompute_monthly_villagers] ${workspaceId}: ${from} -> ` +
                    `${outcome.villagersAlive}/${outcome.villagersPlanned} aldeões vivos, ` +
                    `vila ${outcome.villageAlive ? "protegida" : "caída"}, ${outcome.xpAwarded} XP ` +
                    `[planejado=${outcome.plannedCents} realizado=${outcome.actualCents} centavos] (${verb}).`
                );

                if (!options.dryRun) {
                    // O XP só sai se o marcador durável ainda não existir; o
                    // retrato é reescrito de qualquer jeito.
                    await gamification.closeMonthlyVillagers(workspaceId, monthKey, now);
                }
            }

            if (!options.villagersOnly) {
                const currentMonth = toMonthKey(now);
                const computed = await expectedIncome.expectedMonthlyIncomeCents(workspaceId, currentMonth, now);
                const published = await expectedIncomeRepository.getPublishedExpectedIncome(workspaceId);
                const changed = !published ||
                    published.monthKey !== computed.monthKey ||
                    published.cents !== computed.cents ||
                    published.source !== computed.source;

                if (changed) {
                    summary.incomePublished++;
                    const verb = options.dryRun ? "PUBLICARIA" : "publicado";
                    log(
                        `[recompute_monthly_villagers] ${workspaceId}: receita prevista de ${currentMonth} = ` +
                        `${computed.cents} centavos (${computed.source}) (${verb}).`
                    );

                    if (!options.dryRun) {
                        await expectedIncomeRepository.publishExpectedIncome(workspaceId, computed);
                    }
                }
            }
        }
        catch (e) {
            summary.failed++;
            log(`[recompute_monthly_villagers] ${workspaceId}: FALHA — ${String(e)}`);
        }
    }

    log(
        `[recompute_monthly_villagers] Fim (${monthKey}): workspaces=${summary.scanned} ` +
        `com aldeia=${summary.withVillagers} sem aldeia=${summary.withoutVillagers} ` +
        `XP do mês=${summary.xpTotal} receita publicada=${summary.incomePublished} ` +
        `falhas=${summary.failed}`
    );
    if (!options.dryRun) {
        log(
            "[recompute_monthly_villagers] O 'XP do mês' é o que o mês RENDE; " +
            "quem já tinha o marcador do mês não recebeu nada de novo."
        );
    }

    return summary;
}

/** Bootstrap: só roda quando o arquivo é executado direto por `node`. */
if (require.main === module) {
    const args = process.argv.slice(2);
    const dryRun = !args.includes("--apply");
    const villagersOnly = args.includes("--villagers-only");
    const projectId = args.find((a) => a.startsWith("--project="))?.split("=")[1]
        || process.env.GOOGLE_CLOUD_PROJECT;
    const workspaceId = args.find((a) => a.startsWith("--workspace="))?.split("=")[1];
    const monthKey = args.find((a) => a.startsWith("--month="))?.split("=")[1];

    if (!projectId) {
        console.error("[recompute_monthly_villagers] Informe --project=<projectId> (ou defina GOOGLE_CLOUD_PROJECT).");
        process.exit(1);
    }

    admin.initializeApp({ projectId });
    admin.firestore().settings({ ignoreUndefinedProperties: false });

    // Construído AQUI, e não no núcleo: `FinanceRepositoryImpl` resolve
    // `admin.firestore()` no construtor, e só agora o app existe.
    const financeService = new FinanceService(new FinanceRepositoryImpl());

    recomputeMonthlyVillagers(
        admin.firestore(),
        new GamificationRepositoryImpl(),
        new ExpectedIncomeRepositoryImpl(),
        {
            dryRun,
            workspaceId,
            monthKey,
            villagersOnly,
            weeklyXpWriter: (wid, date, deltaXp) => financeService.updateWeeklyTotalXp(wid, date, deltaXp),
        }
    )
        .then((summary) => process.exit(summary.failed > 0 ? 1 : 0))
        .catch((e) => {
            console.error("[recompute_monthly_villagers] Erro fatal:", e);
            process.exit(1);
        });
}
