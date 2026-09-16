/**
 * F1.8 — regras de fatura (vencimento, fechamento e janela do ciclo).
 *
 * As asserções usam `toDateKey`, e não `getDate()/getMonth()`: o ponto do
 * pacote é justamente que o dia da fatura é o dia no FUSO DO PRODUTO. Comparar
 * com os getters locais validaria a implementação contra o fuso da máquina que
 * roda o teste.
 */

import { InvoiceService } from "../features/finance/domain/services/invoice.service";
import { toDateKey } from "../core/utils/date_key";
import { getZonedParts } from "../core/utils/timezone.utils";

/** Instante do meio-dia de São Paulo no dia informado (`YYYY-MM-DD`). */
function spNoon(dateKey: string): Date {
    const [year, month, day] = dateKey.split("-").map(Number);
    // São Paulo é UTC-3 o ano inteiro desde 2019.
    return new Date(Date.UTC(year, month - 1, day, 15, 0, 0));
}

const key = (date: Date) => toDateKey(date);

describe("InvoiceService — feriados", () => {
    it("calcula o Domingo de Páscoa de 2025 a 2027 (Meeus/Gauss)", () => {
        expect(InvoiceService.easterSunday(2025)).toEqual({ month: 4, day: 20 });
        expect(InvoiceService.easterSunday(2026)).toEqual({ month: 4, day: 5 });
        expect(InvoiceService.easterSunday(2027)).toEqual({ month: 3, day: 28 });
    });

    it("deriva Carnaval, Sexta-feira Santa e Corpus Christi da Páscoa", () => {
        // Datas conhecidas (verificáveis em qualquer calendário nacional).
        expect([...InvoiceService.movableHolidays(2025)].sort())
            .toEqual(["03-04", "04-18", "06-19"]);
        expect([...InvoiceService.movableHolidays(2026)].sort())
            .toEqual(["02-17", "04-03", "06-04"]);
        expect([...InvoiceService.movableHolidays(2027)].sort())
            .toEqual(["02-09", "03-26", "05-27"]);
    });

    it("reconhece feriados fixos e móveis", () => {
        expect(InvoiceService.isHoliday(spNoon("2025-12-25"))).toBe(true); // Natal
        expect(InvoiceService.isHoliday(spNoon("2025-04-21"))).toBe(true); // Tiradentes
        expect(InvoiceService.isHoliday(spNoon("2025-03-04"))).toBe(true); // Carnaval
        expect(InvoiceService.isHoliday(spNoon("2025-04-18"))).toBe(true); // Sexta-feira Santa
        expect(InvoiceService.isHoliday(spNoon("2025-06-19"))).toBe(true); // Corpus Christi
        expect(InvoiceService.isHoliday(spNoon("2026-06-19"))).toBe(false); // móvel: em 2026 é 04/06
        expect(InvoiceService.isHoliday(spNoon("2025-03-05"))).toBe(false); // Quarta-feira de Cinzas não é feriado nacional
    });

    it("usa o dia do fuso do produto, não o dia em UTC", () => {
        // 25/12 às 22h de São Paulo já é 26/12 em UTC.
        const natalTardeDaNoite = new Date(Date.UTC(2025, 11, 26, 1, 0, 0));
        expect(InvoiceService.isHoliday(natalTardeDaNoite)).toBe(true);
    });

    it("identifica fim de semana no fuso do produto", () => {
        expect(InvoiceService.isWeekend(spNoon("2025-03-08"))).toBe(true); // sábado
        expect(InvoiceService.isWeekend(spNoon("2025-03-09"))).toBe(true); // domingo
        expect(InvoiceService.isWeekend(spNoon("2025-03-10"))).toBe(false);
        // Sábado 21h em São Paulo é domingo em UTC — continua sendo sábado aqui.
        expect(InvoiceService.isWeekend(new Date(Date.UTC(2025, 2, 9, 0, 0, 0)))).toBe(true);
    });
});

describe("InvoiceService.getNextBusinessDay", () => {
    const next = (dateKey: string) => key(InvoiceService.getNextBusinessDay(spNoon(dateKey)));

    it("mantém o dia quando já é dia útil", () => {
        expect(next("2025-03-10")).toBe("2025-03-10");
    });

    it("pula o fim de semana", () => {
        expect(next("2025-03-08")).toBe("2025-03-10"); // sábado -> segunda
    });

    it("pula o Carnaval", () => {
        expect(next("2025-03-04")).toBe("2025-03-05");
    });

    it("pula Sexta-feira Santa, o fim de semana e Tiradentes de uma vez", () => {
        // 18/04 sexta santa, 19-20 fim de semana, 21 Tiradentes (segunda).
        expect(next("2025-04-18")).toBe("2025-04-22");
    });

    it("atravessa a virada de ano", () => {
        // 31/12/2025 é quarta e é dia útil; 01/01/2026 é feriado (quinta).
        expect(next("2025-12-31")).toBe("2025-12-31");
        expect(next("2026-01-01")).toBe("2026-01-02");
    });
});

describe("InvoiceService.calculateInvoiceDueDate", () => {
    it("clampa o dia de VENCIMENTO ao último dia do mês", () => {
        // Fechamento 25, vencimento 31: compra em 10/02 (antes do fechamento)
        // vence em fevereiro, clampado para 28.
        const account = { closingDay: 25, dueDay: 31 };
        expect(key(InvoiceService.calculateInvoiceDueDate(spNoon("2025-02-10"), account)))
            .toBe("2025-02-28");
    });

    it("clampa o dia de FECHAMENTO ao último dia do mês", () => {
        // Fechamento 31, vencimento 10: em fevereiro o cartão fecha no dia 28.
        const account = { closingDay: 31, dueDay: 10 };

        // 27/02 (quinta) ainda é antes do fechamento efetivo (28) -> fatura de março.
        expect(key(InvoiceService.calculateInvoiceDueDate(spNoon("2025-02-27"), account)))
            .toBe("2025-03-10");

        // 28/02 (sexta) é o próprio dia do fechamento -> já cai na fatura seguinte.
        expect(key(InvoiceService.calculateInvoiceDueDate(spNoon("2025-02-28"), account)))
            .toBe("2025-04-10");
    });

    it("não postecipa o vencimento que cai em feriado móvel", () => {
        // Corpus Christi de 2025 é 19/06 (quinta). O feriado adia o dia útil de
        // REFERÊNCIA da compra, nunca o vencimento: o id da order de fatura e a
        // janela do ciclo derivam do dia de calendário do vencimento, e mover a
        // data criaria uma fatura nova (e um ciclo de outro mês) a cada
        // recálculo.
        const account = { closingDay: 5, dueDay: 19 };
        const dueDate = InvoiceService.calculateInvoiceDueDate(spNoon("2025-06-02"), account);
        expect(key(dueDate)).toBe("2025-06-19");
        expect(InvoiceService.isHoliday(dueDate)).toBe(true);
    });

    it("leva a compra feita em feriado móvel para o próximo dia útil", () => {
        // Fechamento 5, vencimento 10. O Carnaval de 2025 é 04/03 (terça); o
        // próximo dia útil é 05/03, que JÁ é o dia do fechamento -> a compra vai
        // para a fatura de abril, não para a de março.
        const account = { closingDay: 5, dueDay: 10 };
        expect(key(InvoiceService.calculateInvoiceDueDate(spNoon("2025-03-04"), account)))
            .toBe("2025-04-10");
        expect(key(InvoiceService.calculateInvoiceDueDate(spNoon("2025-03-03"), account)))
            .toBe("2025-03-10");
    });

    it("atravessa a virada de ano com vencimento depois do fechamento", () => {
        const account = { closingDay: 5, dueDay: 10 };
        expect(key(InvoiceService.calculateInvoiceDueDate(spNoon("2025-12-20"), account)))
            .toBe("2026-01-10");
    });

    it("atravessa a virada de ano com vencimento ANTES do fechamento", () => {
        // Vencimento 10 < fechamento 25: o vencimento do fechamento de dezembro
        // é em janeiro; uma compra depois do fechamento de dezembro só vence em
        // fevereiro.
        const account = { closingDay: 25, dueDay: 10 };
        expect(key(InvoiceService.calculateInvoiceDueDate(spNoon("2025-12-24"), account)))
            .toBe("2026-01-10");
        expect(key(InvoiceService.calculateInvoiceDueDate(spNoon("2025-12-26"), account)))
            .toBe("2026-02-10");
    });

    it("usa os padrões quando a conta não tem os dias configurados", () => {
        // Sem closingDay/dueDay: 5 e 10.
        expect(key(InvoiceService.calculateInvoiceDueDate(spNoon("2025-07-02"), {})))
            .toBe("2025-07-10");
    });

    it("decide pelo dia de São Paulo, não pelo dia em UTC", () => {
        const account = { closingDay: 5, dueDay: 10 };
        // 04/03/2025 às 22h em SP = 05/03 às 01h em UTC. Em UTC a compra já
        // seria "no dia do fechamento"; no fuso do produto ainda é Carnaval.
        const compra = new Date(Date.UTC(2025, 2, 5, 1, 0, 0));
        expect(key(InvoiceService.calculateInvoiceDueDate(compra, account)))
            .toBe("2025-04-10");
    });
});

describe("InvoiceService.calculateInvoiceCycleRange", () => {
    it("vai do fechamento anterior até a véspera do fechamento atual", () => {
        const account = { closingDay: 5, dueDay: 10 };
        const range = InvoiceService.calculateInvoiceCycleRange(spNoon("2025-03-10"), account);

        expect(key(range.start)).toBe("2025-02-05");
        expect(key(range.end)).toBe("2025-03-04");
        expect(key(range.closingDate)).toBe("2025-03-05");

        // Bordas: 00:00 e 23:59:59.999 no fuso do produto.
        const startParts = getZonedParts(range.start);
        expect([startParts.hour, startParts.minute, startParts.second]).toEqual([0, 0, 0]);
        expect(range.closingDate.getTime() - range.end.getTime()).toBe(1);
    });

    it("clampa o fechamento 31 em fevereiro nas duas pontas", () => {
        const account = { closingDay: 31, dueDay: 10 };
        // Vencimento 10 < fechamento 31 -> o fechamento desta fatura é o do mês
        // ANTERIOR ao vencimento (março), e o anterior é fevereiro (clampado).
        const range = InvoiceService.calculateInvoiceCycleRange(spNoon("2025-04-10"), account);

        expect(key(range.start)).toBe("2025-02-28");
        expect(key(range.closingDate)).toBe("2025-03-31");
        expect(key(range.end)).toBe("2025-03-30");
    });

    it("atravessa a virada de ano", () => {
        const account = { closingDay: 5, dueDay: 10 };
        const range = InvoiceService.calculateInvoiceCycleRange(spNoon("2026-01-10"), account);

        expect(key(range.start)).toBe("2025-12-05");
        expect(key(range.closingDate)).toBe("2026-01-05");
        expect(key(range.end)).toBe("2026-01-04");
    });

    it("é o inverso de calculateInvoiceDueDate para toda compra em dia útil", () => {
        const accounts = [
            { closingDay: 5, dueDay: 10 },
            { closingDay: 25, dueDay: 10 },
            { closingDay: 31, dueDay: 10 },
            { closingDay: 15, dueDay: 31 },
        ];

        for (const account of accounts) {
            for (let offset = 0; offset < 400; offset += 7) {
                const compra = new Date(spNoon("2025-01-01").getTime() + offset * 24 * 3600 * 1000);
                // Só a data de referência (dia útil) precisa cair no ciclo.
                const referencia = InvoiceService.getNextBusinessDay(compra);
                const dueDate = InvoiceService.calculateInvoiceDueDate(compra, account);
                const range = InvoiceService.calculateInvoiceCycleRange(dueDate, account);

                expect(referencia.getTime()).toBeGreaterThanOrEqual(range.start.getTime());
                expect(referencia.getTime()).toBeLessThanOrEqual(range.end.getTime());
            }
        }
    });
});

describe("InvoiceService.resolveUpcomingDueDate", () => {
    const account = { closingDay: 5, dueDay: 10 };

    it("devolve o vencimento deste mês quando ele ainda não passou", () => {
        expect(key(InvoiceService.resolveUpcomingDueDate(spNoon("2025-03-01"), account)))
            .toBe("2025-03-10");
        expect(key(InvoiceService.resolveUpcomingDueDate(spNoon("2025-03-10"), account)))
            .toBe("2025-03-10");
    });

    it("avança para o mês seguinte quando o vencimento já passou", () => {
        expect(key(InvoiceService.resolveUpcomingDueDate(spNoon("2025-03-11"), account)))
            .toBe("2025-04-10");
    });

    it("atravessa a virada de ano e clampa o dia", () => {
        expect(key(InvoiceService.resolveUpcomingDueDate(spNoon("2025-12-20"), account)))
            .toBe("2026-01-10");
        expect(key(InvoiceService.resolveUpcomingDueDate(spNoon("2025-02-01"), { closingDay: 5, dueDay: 31 })))
            .toBe("2025-02-28");
    });
});

describe("InvoiceService — id da order de fatura", () => {
    it("usa o dia do fuso do produto no id canônico", () => {
        // 10/03 às 21h em SP = 11/03 em UTC.
        const dueDate = new Date(Date.UTC(2025, 2, 11, 0, 0, 0));
        expect(InvoiceService.invoiceOrderId("acc-1", dueDate)).toBe("invoice-acc-1-2025-03-10");
        expect(InvoiceService.legacyInvoiceOrderId("acc-1", dueDate)).toBe("invoice-acc-1-2025-03-11");
    });

    it("coincide com o id legado quando a data é meio-dia UTC (caso da base atual)", () => {
        const dueDate = new Date(Date.UTC(2025, 2, 10, 12, 0, 0));
        expect(InvoiceService.invoiceOrderId("acc-1", dueDate))
            .toBe(InvoiceService.legacyInvoiceOrderId("acc-1", dueDate));
    });
});

describe("InvoiceService.buildClampedDate", () => {
    it("clampa o dia 31 de fevereiro", () => {
        expect(key(InvoiceService.buildClampedDate(2025, 1, 31))).toBe("2025-02-28");
    });

    it("mantém 29 de fevereiro em ano bissexto", () => {
        expect(key(InvoiceService.buildClampedDate(2024, 1, 29))).toBe("2024-02-29");
    });

    it("clampa o dia 31 num mês de 30 dias", () => {
        expect(key(InvoiceService.buildClampedDate(2025, 3, 31))).toBe("2025-04-30");
    });

    it("mantém dias válidos", () => {
        expect(key(InvoiceService.buildClampedDate(2025, 0, 15))).toBe("2025-01-15");
    });

    it("normaliza o estouro de mês (13 = fevereiro do ano seguinte)", () => {
        expect(key(InvoiceService.buildClampedDate(2025, 13, 31))).toBe("2026-02-28");
    });
});
