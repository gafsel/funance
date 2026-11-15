import { montarPromptDoDocumento, validarLinhas } from "../features/nucleo/domain/services/documento.service";

describe("validarLinhas", () => {
    it("aceita linhas completas e arruma a descrição", () => {
        expect(validarLinhas({ linhas: [
            { data: "2026-11-03", descricao: "  MERCADO   BOM ", valorCentavos: 4590, tipo: "saida" },
            { data: "2026-11-05", descricao: "Salário", valorCentavos: 650000, tipo: "entrada" },
        ] })).toEqual([
            { data: "2026-11-03", descricao: "MERCADO BOM", valorCentavos: 4590, tipo: "saida" },
            { data: "2026-11-05", descricao: "Salário", valorCentavos: 650000, tipo: "entrada" },
        ]);
    });

    it("descarta o que não é movimentação válida", () => {
        expect(validarLinhas({ linhas: [
            { data: "03/11/2026", descricao: "Data fora do formato", valorCentavos: 100, tipo: "saida" },
            { data: "2026-11-03", descricao: "Valor quebrado", valorCentavos: 45.9, tipo: "saida" },
            { data: "2026-11-03", descricao: "Valor negativo", valorCentavos: -100, tipo: "saida" },
            { data: "2026-11-03", descricao: "Tipo estranho", valorCentavos: 100, tipo: "transferencia" },
            { data: "2026-11-03", descricao: "   ", valorCentavos: 100, tipo: "saida" },
        ] })).toEqual([]);
        expect(validarLinhas(null)).toEqual([]);
        expect(validarLinhas({ linhas: "nada" })).toEqual([]);
    });
});

describe("montarPromptDoDocumento", () => {
    it("fatura de cartão não traz o pagamento da fatura anterior", () => {
        expect(montarPromptDoDocumento("2026-11-15", true)).toContain("NÃO inclua o pagamento da fatura anterior");
        expect(montarPromptDoDocumento("2026-11-15", false)).toContain("extrato de conta");
    });
});
