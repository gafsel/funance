/**
 * `actionPath` dos slides de coaching.
 *
 * O `actionPath` vira `context.push` no app. A allowlist antiga comparava a
 * string INTEIRA com as rotas, então qualquer query string era descartada junto
 * com a rota — e `/transactions/form` chegava ao cliente sem `status`. Desde
 * que o app passou a assumir `paid` por padrão, isso abre o formulário como
 * "Registrei": a IA propunha AGENDAR uma despesa e o usuário via o lançamento
 * dado como feito.
 *
 * Regra coberta aqui: a allowlist casa o CAMINHO, a query string sobrevive
 * FILTRADA, e `/transactions/form` nunca sai sem `status`.
 */

// ofx-js é ESM puro e não é transformado pelo ts-jest; chega aqui via
// ai.service, mas não é exercitado.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import { CoachingService, sanitizeActionPath } from "../features/coaching/domain/services/coaching.service";

describe("sanitizeActionPath — rotas", () => {
    it("aceita as rotas da allowlist sem query", () => {
        expect(sanitizeActionPath("/planning")).toBe("/planning");
        expect(sanitizeActionPath("/planning-50-30-20")).toBe("/planning-50-30-20");
        expect(sanitizeActionPath("/workspace/categories")).toBe("/workspace/categories");
        expect(sanitizeActionPath("/workspace/accounts")).toBe("/workspace/accounts");
        expect(sanitizeActionPath("/")).toBe("/");
    });

    it("recusa rota alucinada, com ou sem query", () => {
        expect(sanitizeActionPath("/goals/new")).toBeNull();
        expect(sanitizeActionPath("/transactions")).toBeNull();
        expect(sanitizeActionPath("https://exemplo.com/planning")).toBeNull();
        expect(sanitizeActionPath("/planning-50-30-20-turbo")).toBeNull();
        expect(sanitizeActionPath("")).toBeNull();
        expect(sanitizeActionPath("   ")).toBeNull();
    });

    it("tolera espaços em volta", () => {
        expect(sanitizeActionPath("  /planning  ")).toBe("/planning");
    });

    it("descarta query string em rota que não usa nenhuma", () => {
        expect(sanitizeActionPath("/planning?mes=3")).toBe("/planning");
    });
});

describe("sanitizeActionPath — /transactions/form e o `status`", () => {
    it("preserva `status=pending` (agendar/planejar)", () => {
        expect(sanitizeActionPath("/transactions/form?status=pending"))
            .toBe("/transactions/form?status=pending");
    });

    it("preserva `status=paid` (registrar o que já aconteceu)", () => {
        expect(sanitizeActionPath("/transactions/form?status=paid"))
            .toBe("/transactions/form?status=paid");
    });

    it("sem `status`, injeta `pending` — nunca deixa abrir como 'Registrei'", () => {
        // O BUG: antes isto saía como "/transactions/form" e o app assumia
        // `paid`, dando o lançamento como feito.
        expect(sanitizeActionPath("/transactions/form"))
            .toBe("/transactions/form?status=pending");
    });

    it("`status` inválido também vira `pending`", () => {
        expect(sanitizeActionPath("/transactions/form?status=settled"))
            .toBe("/transactions/form?status=pending");
        expect(sanitizeActionPath("/transactions/form?status="))
            .toBe("/transactions/form?status=pending");
    });

    it("preserva `type` junto do `status`, em ordem determinística", () => {
        expect(sanitizeActionPath("/transactions/form?type=expense&status=pending"))
            .toBe("/transactions/form?status=pending&type=expense");
        expect(sanitizeActionPath("/transactions/form?status=paid&type=income"))
            .toBe("/transactions/form?status=paid&type=income");
    });

    it("`type` inválido é descartado sem levar o `status` junto", () => {
        expect(sanitizeActionPath("/transactions/form?status=paid&type=boleto"))
            .toBe("/transactions/form?status=paid");
    });

    it("parâmetro desconhecido é descartado", () => {
        expect(sanitizeActionPath("/transactions/form?status=paid&amount=999&accountIdSource=x"))
            .toBe("/transactions/form?status=paid");
    });

    it("`type` sozinho ganha o `status` padrão", () => {
        expect(sanitizeActionPath("/transactions/form?type=expense"))
            .toBe("/transactions/form?status=pending&type=expense");
    });

    it("repetição do mesmo parâmetro: a primeira ocorrência vence", () => {
        expect(sanitizeActionPath("/transactions/form?status=paid&status=pending"))
            .toBe("/transactions/form?status=paid");
    });

    it("fragmento e percent-encoding malformado não derrubam a validação", () => {
        expect(sanitizeActionPath("/transactions/form?status=paid#topo"))
            .toBe("/transactions/form?status=paid");
        expect(sanitizeActionPath("/transactions/form?%zz=1&status=pending"))
            .toBe("/transactions/form?status=pending");
    });
});

describe("validateCoachingResponse — actionPath no slide", () => {
    /** Só o validador é exercitado: nenhuma dependência é tocada. */
    const service = new CoachingService(
        null as any, null as any, null as any, null as any, null as any
    );
    const validate = (response: any) =>
        (service as any).validateCoachingResponse(response);

    const slide = (over: Record<string, any>) => ({
        title: "Delivery",
        message: "Delivery custa R$ 620/mês; um teto de R$ 400 libera R$ 220/mês.",
        icon: "restaurant",
        ...over,
    });

    it("normaliza o path do slide e mantém o rótulo do botão", () => {
        const result = validate({ slides: [slide({
            actionPath: "/transactions/form",
            actionLabel: "Agendar",
        })] });

        expect(result.slides[0].actionPath).toBe("/transactions/form?status=pending");
        expect(result.slides[0].actionLabel).toBe("Agendar");
    });

    it("mantém a query válida que a IA mandou", () => {
        const result = validate({ slides: [slide({
            actionPath: "/transactions/form?status=paid&type=income",
            actionLabel: "Registrar receita",
        })] });

        expect(result.slides[0].actionPath).toBe("/transactions/form?status=paid&type=income");
    });

    it("rota fora da allowlist deixa o slide sem botão", () => {
        const result = validate({ slides: [slide({
            actionPath: "/relatorios/magico?status=paid",
            actionLabel: "Ver",
        })] });

        expect(result.slides[0].actionPath).toBeUndefined();
        expect(result.slides[0].actionLabel).toBeUndefined();
    });

    it("actionPath não-string continua sendo ignorado", () => {
        const result = validate({ slides: [slide({ actionPath: 42, actionLabel: "Ver" })] });

        expect(result.slides[0].actionPath).toBeUndefined();
    });
});
