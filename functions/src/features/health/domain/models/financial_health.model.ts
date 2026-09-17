/**
 * F2.2 — BÚSSOLA DA LIBERDADE: o placar que faltava.
 *
 * O jogo já premiava planejar (XP, badges, missões), mas nada media a
 * DISTÂNCIA até a liberdade financeira. XP diz "você jogou bem esta semana";
 * a Bússola diz "você está a tantos passos de não precisar mais do salário".
 *
 * O índice é um número de 0 a 100, composto por quatro componentes com pesos
 * fixos. Cada componente responde a uma pergunta que o usuário reconhece:
 *
 * | Componente   | Pergunta                                   | Peso |
 * |--------------|--------------------------------------------|------|
 * | **Fôlego**   | quantos meses eu aguento sem receita?      |  30  |
 * | **Poupança** | quanto do que entra eu consigo guardar?    |  25  |
 * | **Disciplina** | eu respeito os limites que eu mesmo pus? |  25  |
 * | **Alívio**   | minha dívida está encolhendo?              |  20  |
 *
 * Tudo aqui é FUNÇÃO PURA: nada lê o Firestore. O serviço
 * (`financial_health.service.ts`) reúne os insumos e chama estas funções, de
 * modo que a regra de pontuação seja testável sem emulador e idêntica entre o
 * gatilho, o cron e o script de recálculo.
 *
 * NÃO USA IA. O índice precisa ser determinístico e reprodutível: o mesmo
 * estado do workspace tem que dar sempre o mesmo número, senão a barra do app
 * oscila sozinha e o placar perde o sentido.
 */

/** Patente exibida no app, derivada da faixa do índice. */
export enum FinancialHealthTier {
    aprendiz = "aprendiz",
    guardiao = "guardiao",
    estrategista = "estrategista",
    mestre = "mestre",
    livre = "livre",
}

/**
 * Faixas das patentes, do topo para a base — a primeira cujo piso o score
 * alcança é a patente. Fechadas em `min` inclusive:
 * 0–19 Aprendiz, 20–39 Guardião, 40–59 Estrategista, 60–79 Mestre, 80–100 Livre.
 */
export const HEALTH_TIERS: ReadonlyArray<{ min: number, tier: FinancialHealthTier }> = [
    { min: 80, tier: FinancialHealthTier.livre },
    { min: 60, tier: FinancialHealthTier.mestre },
    { min: 40, tier: FinancialHealthTier.estrategista },
    { min: 20, tier: FinancialHealthTier.guardiao },
    { min: 0, tier: FinancialHealthTier.aprendiz },
];

/**
 * Pesos dos componentes. Somam 100 — o teste garante isso, porque um peso
 * esquecido faz o índice nunca chegar a 100 e ninguém percebe olhando o app.
 */
export const HEALTH_WEIGHTS = {
    folego: 30,
    poupanca: 25,
    disciplina: 25,
    alivio: 20,
} as const;

/** Meses de reserva que valem 100 em Fôlego. Acima disso não pontua mais. */
export const FOLEGO_TARGET_MONTHS = 6;

/** Taxa de poupança que vale 100 (30% da receita do mês). */
export const POUPANCA_TARGET_RATE = 0.30;

/**
 * Variação de dívida abaixo da qual a trajetória é considerada ESTÁVEL
 * (em reais). Sem esta faixa morta, um centavo de juros viraria "dívida
 * aumentou" e derrubaria o componente inteiro de 50 para 0.
 */
export const ALIVIO_STABLE_EPSILON = 1;

/** Um componente do índice: o valor bruto, a nota 0-100 e o dado que a explica. */
export interface HealthComponent {
    /**
     * Valor BRUTO da métrica, na unidade do componente (meses, taxa, razão,
     * variação em reais). É o que o app usa para escrever a frase explicativa;
     * o campo nomeado ao lado (`months`, `rate`, ...) é o mesmo número com o
     * nome do contrato.
     */
    value: number;
    /** Nota normalizada de 0 a 100. É ela que entra na média ponderada. */
    score: number;
}

export interface FolegoComponent extends HealthComponent {
    /** Meses de despesa que o saldo líquido cobre. */
    months: number;
}

export interface PoupancaComponent extends HealthComponent {
    /** `(receita − despesa) / receita` do mês. Negativa quando gastou mais do que ganhou. */
    rate: number;
}

export interface DisciplinaComponent extends HealthComponent {
    /** Categorias com limite que fecharam o mês DENTRO do limite. */
    within: number;
    /** Categorias com limite vigente no mês. */
    total: number;
}

export interface AlivioComponent extends HealthComponent {
    /**
     * Variação do saldo somado das contas de dívida/cartão contra o mês
     * anterior. Saldo de dívida é NEGATIVO, então amortizar aproxima de zero e
     * o delta é POSITIVO.
     */
    delta: number;
}

export interface FinancialHealthComponents {
    folego: FolegoComponent;
    poupanca: PoupancaComponent;
    disciplina: DisciplinaComponent;
    alivio: AlivioComponent;
}

/**
 * O documento gravado em `workspaces/{w}.financialHealth` e em
 * `workspaces/{w}/health_history/{YYYY-MM}`. O Flutter depende destes nomes.
 */
export interface FinancialHealthSnapshot {
    score: number;
    tier: FinancialHealthTier;
    components: FinancialHealthComponents;
    computedAt: Date;
    monthKey: string;
}

/** Garante um número finito; qualquer outra coisa vira o padrão. */
export function finiteOr(value: unknown, fallback: number): number {
    return typeof value === "number" && Number.isFinite(value) ? value : fallback;
}

/** Recorta para o intervalo `[min, max]`. */
export function clamp(value: number, min: number, max: number): number {
    if (!Number.isFinite(value)) return min;
    return Math.min(max, Math.max(min, value));
}

/** Nota inteira de 0 a 100 (arredondada). */
function toScore(ratio: number): number {
    return Math.round(clamp(ratio, 0, 1) * 100);
}

/**
 * FÔLEGO — meses de reserva.
 *
 * `saldo líquido das contas checking+investment ÷ média de despesas realizadas
 * dos últimos 3 meses`, mapeado de 0 a 6+ meses em 0 a 100.
 *
 * Sem histórico de despesa (média <= 0) o resultado é ZERO, não infinito: é o
 * caso do workspace recém-criado, e um Fôlego máximo ali seria uma mentira
 * confortável. Saldo negativo também vira zero — a reserva não é negativa, ela
 * simplesmente não existe.
 */
export function scoreFolego(liquidBalance: number, avgMonthlyExpense: number): FolegoComponent {
    const balance = finiteOr(liquidBalance, 0);
    const expense = finiteOr(avgMonthlyExpense, 0);

    if (expense <= 0 || balance <= 0) {
        return { value: 0, score: 0, months: 0 };
    }

    const months = balance / expense;
    return {
        value: months,
        score: toScore(months / FOLEGO_TARGET_MONTHS),
        months,
    };
}

/**
 * POUPANÇA — taxa do mês.
 *
 * `(receita − despesa) / receita`, de −∞..30%+ para 0..100. Receita zero
 * significa "nada a poupar ainda" e vale zero: dividir por zero não é opinião,
 * e tratar "não ganhei nada" como 100% de poupança premiaria o mês vazio.
 */
export function scorePoupanca(income: number, expense: number): PoupancaComponent {
    const totalIncome = finiteOr(income, 0);
    const totalExpense = finiteOr(expense, 0);

    if (totalIncome <= 0) {
        return { value: 0, score: 0, rate: 0 };
    }

    const rate = (totalIncome - totalExpense) / totalIncome;
    return {
        value: rate,
        score: toScore(rate / POUPANCA_TARGET_RATE),
        rate,
    };
}

/**
 * DISCIPLINA — aderência aos próprios limites.
 *
 * Percentual das categorias COM LIMITE que fecharam o mês anterior dentro do
 * limite. Sem nenhuma categoria com limite o componente vale zero: quem não
 * planejou não tem disciplina a medir — e é exatamente esse zero que o app usa
 * para convidar o usuário a criar o primeiro limite.
 */
export function scoreDisciplina(within: number, total: number): DisciplinaComponent {
    const safeTotal = Math.max(0, Math.trunc(finiteOr(total, 0)));
    const safeWithin = clamp(Math.trunc(finiteOr(within, 0)), 0, safeTotal);

    if (safeTotal === 0) {
        return { value: 0, score: 0, within: 0, total: 0 };
    }

    const ratio = safeWithin / safeTotal;
    return {
        value: ratio,
        score: toScore(ratio),
        within: safeWithin,
        total: safeTotal,
    };
}

/**
 * ALÍVIO — trajetória da dívida.
 *
 * Compara o saldo SOMADO das contas `debt` + `creditCard` com o do mês
 * anterior. Esses saldos são negativos, então amortizar aproxima de zero e o
 * delta é positivo:
 *
 *   delta > +ε  →  100 (a dívida encolheu)
 *   |delta| ≤ ε →   50 (estável)
 *   delta < −ε  →    0 (a dívida cresceu)
 *
 * `hasDebtAccounts == false` vale 100: quem não tem dívida nenhuma não pode
 * ser punido por não estar amortizando. O caso "workspace sem dado nenhum" não
 * chega aqui — o serviço devolve o retrato zerado antes (ver `emptySnapshot`).
 */
export function scoreAlivio(delta: number, hasDebtAccounts: boolean): AlivioComponent {
    if (!hasDebtAccounts) {
        return { value: 0, score: 100, delta: 0 };
    }

    const safeDelta = finiteOr(delta, 0);

    let score: number;
    if (Math.abs(safeDelta) <= ALIVIO_STABLE_EPSILON) {
        score = 50;
    }
    else {
        score = safeDelta > 0 ? 100 : 0;
    }

    return { value: safeDelta, score, delta: safeDelta };
}

/** Média ponderada dos quatro componentes, arredondada para inteiro 0-100. */
export function scoreFromComponents(components: FinancialHealthComponents): number {
    const total =
        components.folego.score * HEALTH_WEIGHTS.folego +
        components.poupanca.score * HEALTH_WEIGHTS.poupanca +
        components.disciplina.score * HEALTH_WEIGHTS.disciplina +
        components.alivio.score * HEALTH_WEIGHTS.alivio;

    const weightSum = HEALTH_WEIGHTS.folego + HEALTH_WEIGHTS.poupanca +
        HEALTH_WEIGHTS.disciplina + HEALTH_WEIGHTS.alivio;

    return clamp(Math.round(total / weightSum), 0, 100);
}

/** Patente da faixa em que o score cai. */
export function tierForScore(score: number): FinancialHealthTier {
    const safe = clamp(Math.round(finiteOr(score, 0)), 0, 100);
    for (const band of HEALTH_TIERS) {
        if (safe >= band.min) return band.tier;
    }
    return FinancialHealthTier.aprendiz;
}

/**
 * Retrato de um workspace SEM DADO NENHUM: score 0, patente Aprendiz e os
 * quatro componentes zerados. Não é erro — é o estado inicial, e o app precisa
 * de um documento para desenhar a bússola vazia em vez de um estado de falha.
 */
export function emptySnapshot(monthKey: string, computedAt: Date): FinancialHealthSnapshot {
    return {
        score: 0,
        tier: FinancialHealthTier.aprendiz,
        components: {
            folego: { value: 0, score: 0, months: 0 },
            poupanca: { value: 0, score: 0, rate: 0 },
            disciplina: { value: 0, score: 0, within: 0, total: 0 },
            alivio: { value: 0, score: 0, delta: 0 },
        },
        computedAt,
        monthKey,
    };
}

/** Monta o retrato final a partir dos quatro componentes já pontuados. */
export function buildSnapshot(
    components: FinancialHealthComponents,
    monthKey: string,
    computedAt: Date
): FinancialHealthSnapshot {
    const score = scoreFromComponents(components);
    return { score, tier: tierForScore(score), components, computedAt, monthKey };
}
