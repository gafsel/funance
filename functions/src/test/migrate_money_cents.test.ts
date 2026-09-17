/**
 * F1.10, etapa B — a migração dos espelhos inteiros e o passo derivado dos
 * gatilhos.
 *
 * As duas coisas respondem à mesma pergunta ("que `*Cents` faltam neste
 * documento?") em momentos diferentes: o passo derivado a responde para o
 * documento que o app acabou de escrever; a migração, para o acervo. Por isso
 * elas compartilham o mapa `MONEY_CENTS_FIELDS` — e por isso os dois são
 * testados lado a lado.
 */

/** Sentinela de exclusão, o bastante para reconhecê-la no patch. */
const DELETE_SENTINEL = { __delete: true };

jest.mock("firebase-admin", () => {
    const firestore: any = () => ({});
    firestore.FieldValue = {
        delete: () => ({ __delete: true }),
        serverTimestamp: () => ({ __serverTimestamp: true }),
    };
    class FakeFieldPath {
        constructor(public segments: string[]) {}
        static documentId() {
            return "__name__";
        }
    }
    firestore.FieldPath = FakeFieldPath;
    return { firestore, apps: [] };
});

import {
    inspectFlatDoc,
    inspectSummaryDoc,
    parseArgs,
} from "../scripts/migrate_money_cents";
import { buildCentsPatch } from "../core/utils/money_cents";
import {
    BALANCE_CENTS_FIELDS,
    MONEY_CENTS_FIELDS,
} from "../features/finance/domain/models/finance.models";

describe("inspectFlatDoc — documento simples", () => {
    it("preenche o que falta e deixa o double intocado", () => {
        const result = inspectFlatDoc(
            { amount: 167.47, paidAmount: 167.47, referenceAmount: 167.47 },
            MONEY_CENTS_FIELDS.installments
        );

        expect(result.patch).toEqual({
            amountCents: 16747,
            paidAmountCents: 16747,
            referenceAmountCents: 16747,
        });
        // O `double` nunca entra no patch: o inteiro é derivado dele.
        expect(Object.keys(result.patch!)).not.toContain("amount");
    });

    it("documento já correto não gera escrita nenhuma (idempotência)", () => {
        const data = { amount: 167.47, amountCents: 16747, referenceAmount: 167.47, referenceAmountCents: 16747 };
        expect(inspectFlatDoc(data, MONEY_CENTS_FIELDS.installments).patch).toBeNull();
    });

    it("AUSENTE continua ausente: paidAmount que não existe não vira zero", () => {
        const result = inspectFlatDoc({ amount: 50 }, MONEY_CENTS_FIELDS.installments);

        expect(result.patch).toEqual({ amountCents: 5000 });
        // `paidAmountCents: 0` diria que a parcela foi paga com valor zero.
        expect(result.patch).not.toHaveProperty("paidAmountCents");
    });

    it("inteiro pendurado sem o double correspondente é APAGADO", () => {
        const result = inspectFlatDoc({ amount: 50, paidAmountCents: 999 }, MONEY_CENTS_FIELDS.installments);

        expect(result.patch!.paidAmountCents).toEqual(DELETE_SENTINEL);
        expect(result.divergent).toBe(true);
    });

    it("inteiro que DISCORDA do double é reescrito e contado como divergência", () => {
        const result = inspectFlatDoc({ amount: 100, amountCents: 1 }, MONEY_CENTS_FIELDS.orders);

        expect(result.patch).toEqual({ amountCents: 10000 });
        expect(result.divergent).toBe(true);
        // A soma pelo double e a soma pelos cents divergem — é o que o
        // `--verify` reporta por coleção.
        expect(result.doubleCents).toBe(10000);
        expect(result.storedCents).toBe(1);
    });

    it("1.005 vai para 101 centavos, e não para 100", () => {
        expect(inspectFlatDoc({ amount: 1.005 }, MONEY_CENTS_FIELDS.orders).patch)
            .toEqual({ amountCents: 101 });
    });

    it("valor sujo (string, NaN) não vira campo inteiro", () => {
        expect(inspectFlatDoc({ amount: "100" as any }, MONEY_CENTS_FIELDS.orders).patch).toBeNull();
        expect(inspectFlatDoc({ amount: NaN }, MONEY_CENTS_FIELDS.orders).patch).toBeNull();
    });

    it("cobre delta e balance do saldo diário, inclusive negativos", () => {
        const result = inspectFlatDoc({ delta: -167.47, balance: -19058.9 }, BALANCE_CENTS_FIELDS);
        expect(result.patch).toEqual({ deltaCents: -16747, balanceCents: -1905890 });
    });

    it("um inteiro FRACIONÁRIO é tratado como ausente e reescrito", () => {
        const result = inspectFlatDoc({ amount: 10, amountCents: 1000.5 }, MONEY_CENTS_FIELDS.orders);
        expect(result.patch).toEqual({ amountCents: 1000 });
    });
});

describe("inspectSummaryDoc — period_summaries", () => {
    it("preenche os três totais de cada categoria", () => {
        const result = inspectSummaryDoc({
            year: 2026,
            month: 3,
            categories: {
                mercado: { generalPlannedAmount: 1000, specificPlannedAmount: 250.5, actualAmount: 0.3 },
            },
        });

        // Mapa ANINHADO (e não caminho pontilhado): um id de categoria com
        // ponto viraria caminho e gravaria no lugar errado.
        expect(result.patch).toEqual({
            categories: {
                mercado: {
                    generalPlannedAmountCents: 100000,
                    specificPlannedAmountCents: 25050,
                    actualAmountCents: 30,
                },
            },
        });
        expect(result.merge).toBe(true);
    });

    it("total ausente não ganha espelho (ele já vale zero na leitura)", () => {
        const result = inspectSummaryDoc({
            categories: { mercado: { actualAmount: 10 } },
        });
        expect(result.patch).toEqual({ categories: { mercado: { actualAmountCents: 1000 } } });
    });

    it("documento já migrado não gera escrita", () => {
        const result = inspectSummaryDoc({
            categories: {
                mercado: {
                    generalPlannedAmount: 1000, generalPlannedAmountCents: 100000,
                    specificPlannedAmount: 250.5, specificPlannedAmountCents: 25050,
                    actualAmount: 0.3, actualAmountCents: 30,
                },
            },
        });
        expect(result.patch).toBeNull();
        expect(result.divergent).toBe(false);
    });

    it("soma os três totais de TODAS as categorias para o verificador", () => {
        const result = inspectSummaryDoc({
            categories: {
                a: { actualAmount: 0.1 },
                b: { actualAmount: 0.2 },
            },
        });
        // 0.1 + 0.2 = 30 centavos exatos.
        expect(result.doubleCents).toBe(30);
    });

    it("id de categoria com PONTO não vira caminho aninhado", () => {
        const result = inspectSummaryDoc({
            categories: { "cat.com.ponto": { actualAmount: 5 } },
        });
        expect(result.patch).toEqual({ categories: { "cat.com.ponto": { actualAmountCents: 500 } } });
    });

    it("documento sem categorias é inofensivo", () => {
        expect(inspectSummaryDoc({ year: 2026 }).patch).toBeNull();
        expect(inspectSummaryDoc({ categories: {} }).patch).toBeNull();
    });
});

describe("buildCentsPatch — o passo derivado do gatilho", () => {
    it("responde exatamente como a migração para o mesmo documento", () => {
        const data = { amount: 167.47, paidAmount: 100, referenceAmount: 100 };

        expect(buildCentsPatch(data, MONEY_CENTS_FIELDS.installments))
            .toEqual(inspectFlatDoc(data, MONEY_CENTS_FIELDS.installments).patch);
    });

    it("documento já correto devolve null — é o que impede o laço do gatilho", () => {
        expect(buildCentsPatch(
            { targetAmount: 1000, targetAmountCents: 100000, currentAmount: 0, currentAmountCents: 0 },
            MONEY_CENTS_FIELDS.goals
        )).toBeNull();
    });

    it("currentAmount ZERO ganha currentAmountCents: 0 (zero é um valor, não ausência)", () => {
        expect(buildCentsPatch({ targetAmount: 100, currentAmount: 0 }, MONEY_CENTS_FIELDS.goals))
            .toEqual({ targetAmountCents: 10000, currentAmountCents: 0 });
    });

    it("documento nulo não gera patch", () => {
        expect(buildCentsPatch(null, MONEY_CENTS_FIELDS.goals)).toBeNull();
        expect(buildCentsPatch(undefined, MONEY_CENTS_FIELDS.goals)).toBeNull();
    });
});

describe("parseArgs", () => {
    it("dry-run é o padrão", () => {
        expect(parseArgs([])).toMatchObject({ dryRun: true, verify: false });
    });

    it("--apply desliga o dry-run", () => {
        expect(parseArgs(["--apply"]).dryRun).toBe(false);
    });

    it("--verify não escreve, mesmo com --apply", () => {
        const options = parseArgs(["--apply", "--verify"]);
        expect(options.verify).toBe(true);
    });

    it("lê workspace, página, projeto e --restart", () => {
        expect(parseArgs(["--workspace=w1", "--page-size=50", "--project=p1", "--restart"]))
            .toMatchObject({ workspaceId: "w1", pageSize: 50, projectId: "p1", restart: true });
    });

    it("página inválida cai no padrão", () => {
        expect(parseArgs(["--page-size=0"]).pageSize).toBeUndefined();
        expect(parseArgs(["--page-size=abc"]).pageSize).toBeUndefined();
    });
});
