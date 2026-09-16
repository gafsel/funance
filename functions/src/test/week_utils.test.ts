/**
 * F1.9 — a definição de semana é ÚNICA e passa no vetor compartilhado.
 *
 * O vetor (`src/test/fixtures/week_vectors.json`) foi gerado de forma
 * independente (fora do TypeScript) e é o mesmo contrato que o cliente Dart
 * precisa cumprir. Se este teste quebrar, os ids `YYYY-Www` do servidor e do
 * app deixaram de bater.
 */

import * as fs from "fs";
import * as path from "path";

import {
    formatWeekId,
    getWeekId,
    getWeekNumber,
    getWeekRef,
    getWeekRefBefore,
    getWeekStart,
    getWeekYear,
    weekStartFromRef,
} from "../core/utils/week.utils";
import { getWeekId as gamificationGetWeekId } from "../features/goal/domain/services/gamification_time.util";

interface WeekVectorCase {
    label: string;
    utc: string;
    saoPauloLocal: string;
    expectedYear: number;
    expectedWeek: number;
    expectedWeekId: string;
    expectedWeekStartUtc: string;
}

const VECTOR_PATH = path.join(__dirname, "fixtures", "week_vectors.json");
const vector = JSON.parse(fs.readFileSync(VECTOR_PATH, "utf8")) as {
    timeZone: string;
    cases: WeekVectorCase[];
};

describe("week.utils — vetor compartilhado com o cliente Dart", () => {
    it("o vetor está no fuso do produto e tem casos de borda suficientes", () => {
        expect(vector.timeZone).toBe("America/Sao_Paulo");
        expect(vector.cases.length).toBeGreaterThanOrEqual(10);
    });

    it.each(vector.cases.map((c) => [c.label, c] as [string, WeekVectorCase]))(
        "%s",
        (_label, testCase) => {
            const date = new Date(testCase.utc);

            expect(getWeekId(date)).toBe(testCase.expectedWeekId);
            expect(getWeekYear(date)).toBe(testCase.expectedYear);
            expect(getWeekNumber(date)).toBe(testCase.expectedWeek);
            expect(getWeekRef(date)).toEqual({ year: testCase.expectedYear, week: testCase.expectedWeek });
            expect(getWeekStart(date).toISOString()).toBe(testCase.expectedWeekStartUtc);

            // A volta: da referência para o domingo que inicia a semana.
            expect(weekStartFromRef({ year: testCase.expectedYear, week: testCase.expectedWeek }).toISOString())
                .toBe(testCase.expectedWeekStartUtc);
        }
    );

    it("o id da gamificação é a MESMA função (nenhuma cópia sobrou)", () => {
        expect(gamificationGetWeekId).toBe(getWeekId);

        for (const testCase of vector.cases) {
            const date = new Date(testCase.utc);
            // A gamificação sempre chamou com o weekStart; o resultado é o mesmo.
            expect(gamificationGetWeekId(getWeekStart(date))).toBe(testCase.expectedWeekId);
        }
    });

    it("o sábado 21h de São Paulo e o domingo 00h UTC caem em semanas diferentes", () => {
        // Mesmo instante, duas leituras: em UTC já é domingo (semana nova), em
        // São Paulo ainda é sábado (semana anterior). O bug de F1.9 era exatamente
        // esse: weekly_xp em UTC, missões em São Paulo.
        const saturdayNight = new Date("2026-09-13T00:30:00.000Z");
        const sundayMorning = new Date("2026-09-13T03:30:00.000Z");

        expect(getWeekId(saturdayNight)).toBe("2026-W36");
        expect(getWeekId(sundayMorning)).toBe("2026-W37");
        expect(saturdayNight.getUTCDay()).toBe(0); // domingo em UTC
    });

    it("formatWeekId preenche a semana com dois dígitos", () => {
        expect(formatWeekId({ year: 2026, week: 7 })).toBe("2026-W07");
        expect(formatWeekId({ year: 2026, week: 37 })).toBe("2026-W37");
    });

    it("getWeekRefBefore anda para trás atravessando a virada de ano", () => {
        const date = new Date("2026-01-15T15:00:00.000Z");

        // 15/01/2026 é quinta; o domingo que inicia a semana é 11/01 (semana 2).
        expect(getWeekRefBefore(date, 0)).toEqual(getWeekRef(date));
        expect(formatWeekId(getWeekRefBefore(date, 0))).toBe("2026-W02");
        expect(formatWeekId(getWeekRefBefore(date, 1))).toBe("2026-W01");
        expect(formatWeekId(getWeekRefBefore(date, 2))).toBe("2025-W52");
        expect(formatWeekId(getWeekRefBefore(date, 3))).toBe("2025-W51");
    });

    it("todo instante da semana devolve o mesmo id (168 horas seguidas)", () => {
        const weekStart = getWeekStart(new Date("2026-09-13T12:00:00.000Z"));
        const expected = getWeekId(weekStart);

        for (let hour = 0; hour < 168; hour++) {
            const instant = new Date(weekStart.getTime() + hour * 60 * 60 * 1000);
            expect(getWeekId(instant)).toBe(expected);
        }

        const nextWeek = new Date(weekStart.getTime() + 168 * 60 * 60 * 1000);
        expect(getWeekId(nextWeek)).not.toBe(expected);
    });
});
