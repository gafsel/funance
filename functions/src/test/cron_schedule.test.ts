// ofx-js é ESM puro e não é transformado pelo ts-jest; o container o alcança
// via ai.service, e o handler importa o container.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as fs from "fs";
import * as path from "path";

import {
    WEEKLY_CRON_MINUTES_AFTER_WEEK_START,
    WEEKLY_GAMIFICATION_CRON_SCHEDULE,
    weeklyGamificationCron,
} from "../features/goal/presentation/functions/gamification_handler";
import {
    PRODUCT_TIME_ZONE,
    addCalendarDays,
    getDayIndexInTz,
    getZonedParts,
} from "../core/utils/timezone.utils";
import { endOfWeekFromStart, getWeekId, getWeekStart } from "../core/utils/week.utils";

const MINUTE_MS = 60 * 1000;

interface WeekVectorCase {
    label: string;
    utc: string;
    saoPauloLocal: string;
    expectedWeekId: string;
    expectedWeekStartUtc: string;
}

const vector = JSON.parse(
    fs.readFileSync(path.join(__dirname, "fixtures", "week_vectors.json"), "utf8")
) as { timeZone: string; cases: WeekVectorCase[] };

/**
 * O dia em que a semana do produto COMEÇA, descoberto pela implementação em
 * vez de escrito à mão: para sete dias consecutivos, `getWeekStart` devolve o
 * mesmo instante, e o dia da semana desse instante é o dia de início.
 */
function productWeekStartWeekday(): number {
    const weekdays = new Set<number>();
    for (let i = 0; i < 7; i++) {
        // Meio-dia local, para nenhum dos sete cair numa borda de fuso.
        const day = new Date(Date.UTC(2026, 8, 14 + i, 15));
        weekdays.add(getDayIndexInTz(getWeekStart(day)));
    }
    expect(weekdays.size).toBe(1);
    return [...weekdays][0];
}

/**
 * O cron semanal precisa disparar na VIRADA da semana do produto.
 *
 * Este teste existe porque as duas coisas já se desalinharam: a semana passou
 * a começar no domingo (F1.9) e o cron continuou em `"0 3 * * 1"` — segunda,
 * 03:00. A passada de fechamento seguia correta, mas a semana nova ficava 27
 * horas sem nada do lado semanal, e a Home mostrava o bloco de missões vazio.
 *
 * A expressão esperada é DERIVADA do dia de início da semana; mudar
 * `week.utils.ts` para começar na segunda quebra este teste em vez de deixar
 * o cron para trás outra vez.
 */
describe("weeklyGamificationCron — o agendamento sai da definição de semana", () => {
    it("dispara no dia em que a semana do produto começa (domingo)", () => {
        const weekday = productWeekStartWeekday();
        expect(weekday).toBe(0);

        const hour = Math.floor(WEEKLY_CRON_MINUTES_AFTER_WEEK_START / 60);
        const minute = WEEKLY_CRON_MINUTES_AFTER_WEEK_START % 60;
        const expected = `${minute} ${hour} * * ${weekday}`;

        expect(WEEKLY_GAMIFICATION_CRON_SCHEDULE).toBe(expected);
    });

    it("a constante é a expressão que o scheduler recebe, no fuso do produto", () => {
        const trigger = (weeklyGamificationCron as any).__endpoint.scheduleTrigger;
        expect(trigger.schedule).toBe(WEEKLY_GAMIFICATION_CRON_SCHEDULE);
        expect(trigger.timeZone).toBe(PRODUCT_TIME_ZONE);
    });

    it("dispara DEPOIS da virada, com a folga declarada, e não antes", () => {
        for (const testCase of vector.cases) {
            const weekStart = getWeekStart(new Date(testCase.utc));
            const fireAt = new Date(weekStart.getTime() + WEEKLY_CRON_MINUTES_AFTER_WEEK_START * MINUTE_MS);

            // Dentro da semana nova: fechar a semana em curso zeraria a streak.
            expect(getWeekStart(fireAt).getTime()).toBe(weekStart.getTime());
            // E depois do último instante da semana que fechou.
            const closedWeekStart = addCalendarDays(weekStart, -7);
            expect(endOfWeekFromStart(closedWeekStart).getTime()).toBeLessThan(fireAt.getTime());

            // O horário local do disparo é exatamente o da expressão cron.
            const parts = getZonedParts(fireAt);
            expect(parts.weekday).toBe(productWeekStartWeekday());

            // ... exceto no domingo em que o relógio ADIANTAVA (00:00 -> 01:00
            // no antigo horário de verão): a meia-noite local não existe, a
            // semana começa às 01:00 e o agendador resolve o disparo por conta
            // própria. O Brasil não tem mais DST desde 2019; o vetor ainda
            // cobre esses domingos históricos.
            if (getZonedParts(weekStart).hour === 0) {
                expect(parts.hour).toBe(Math.floor(WEEKLY_CRON_MINUTES_AFTER_WEEK_START / 60));
                expect(parts.minute).toBe(WEEKLY_CRON_MINUTES_AFTER_WEEK_START % 60);
            }
        }
    });

    it("no instante do disparo, a semana FECHADA é a anterior e a corrente é a nova", () => {
        // Vetor compartilhado com o app: domingo 13/09/2026 00:00 em São Paulo
        // inicia a 2026-W37, e a semana que fecha ali é a 2026-W36.
        const turnover = vector.cases.find((c) => c.expectedWeekId === "2026-W37" && c.saoPauloLocal.endsWith("00:00:00"));
        expect(turnover).toBeDefined();

        const fireAt = new Date(
            new Date(turnover!.expectedWeekStartUtc).getTime() + WEEKLY_CRON_MINUTES_AFTER_WEEK_START * MINUTE_MS
        );

        // A mesma aritmética de `evaluateWeeklyMissionsCron`/`evaluateWeeklyPlanXp`.
        expect(getWeekId(fireAt)).toBe("2026-W37");
        expect(getWeekId(addCalendarDays(getWeekStart(fireAt), -7))).toBe("2026-W36");
    });
});
