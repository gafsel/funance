import { Categoria, Conta, Fatura, Lancamento, ResumoMes } from "../features/nucleo/domain/models/modelo";
import {
    avisoDeFimDeSemana, avisoDeVencimentos, avisoSemLancar, reais, tetoDoEstiloDeVida,
} from "../features/nucleo/domain/services/avisos";

const hoje = "2026-11-20";
const conta = (tipo: Conta["tipo"], nome = "Conta"): Conta => ({ nome, tipo } as Conta);
const contas = { cc: conta("corrente", "Nubank"), cartao: conta("cartao", "Cartão Nubank") };
const previsto = (descricao: string, centavos: number, extra: Partial<Lancamento> = {}): Lancamento => ({
    tipo: "saida", descricao, previstoCentavos: centavos, data: hoje, situacao: "previsto", contaId: "cc", ...extra,
} as Lancamento);
const fatura = (total: number, pago = 0, vencimento = hoje): Fatura =>
    ({ contaId: "cartao", vencimento, fechamento: "2026-11-15", inicio: "", fim: "", totalCentavos: total, pagoCentavos: pago });
const categoria = (nome: string, grupo: Categoria["grupo"], limite: number | null = null): Categoria =>
    ({ nome, tipo: "saida", grupo, limiteMensalCentavos: limite, arquivada: false, icone: null, cor: null });
const resumo = (gastos: Record<string, number>): ResumoMes => ({
    categorias: Object.fromEntries(Object.entries(gastos).map(([id, v]) => [id, { realizadoCentavos: v }])),
    entradas: {}, saidas: {}, contas: {},
});

describe("reais", () => {
    it("formata centavos", () => {
        expect(reais(123456)).toBe("R$ 1.234,56");
        expect(reais(5)).toBe("R$ 0,05");
        expect(reais(-9900)).toBe("-R$ 99,00");
    });
});

describe("avisoSemLancar", () => {
    it("avisa a partir de sete dias, com id do dia", () => {
        expect(avisoSemLancar("2026-11-14", hoje)).toBeNull();
        const aviso = avisoSemLancar("2026-11-13", hoje);
        expect(aviso?.id).toBe("semLancar-2026-11-20");
        expect(aviso?.texto).toContain("há 7 dias");
    });

    it("espaço sem nenhum lançamento não é cobrado", () => {
        expect(avisoSemLancar(null, hoje)).toBeNull();
    });
});

describe("avisoDeVencimentos", () => {
    it("conta a pagar em conta corrente avisa; agendado no cartão não", () => {
        const aviso = avisoDeVencimentos(
            [previsto("Internet", 11990), previsto("Assinatura", 2190, { contaId: "cartao" })], [], contas, hoje);
        expect(aviso?.titulo).toBe("Vence hoje");
        expect(aviso?.texto).toBe("A pagar: Internet (R$ 119,90). Ao pagar, marque no app.");
    });

    it("fatura sem pagamento avisa; paga, mesmo em parte, não", () => {
        expect(avisoDeVencimentos([], [fatura(41200)], contas, hoje)?.texto).toContain("Fatura Cartão Nubank (R$ 412,00)");
        expect(avisoDeVencimentos([], [fatura(41200, 10000)], contas, hoje)).toBeNull();
        expect(avisoDeVencimentos([], [fatura(0)], contas, hoje)).toBeNull();
    });

    it("separa o que é a pagar do que é a receber e resume quando são muitos", () => {
        const aviso = avisoDeVencimentos([
            previsto("Luz", 18900), previsto("Internet", 11990), previsto("Escola", 150000),
            previsto("Freela", 120000, { tipo: "entrada" }),
        ], [], contas, hoje);
        expect(aviso?.titulo).toBe("4 vencimentos hoje");
        expect(aviso?.texto).toBe("A pagar: 3 contas, R$ 1.808,90. A receber: Freela (R$ 1.200,00). Ao pagar, marque no app.");
    });

    it("ignora o que não vence hoje, o que já foi pago e transferência", () => {
        expect(avisoDeVencimentos([
            previsto("Amanhã", 100, { data: "2026-11-21" }),
            previsto("Pago", 100, { situacao: "efetivado" }),
            previsto("Guardar", 100, { tipo: "transferencia" }),
        ], [fatura(100, 0, "2026-11-21")], contas, hoje)).toBeNull();
    });
});

describe("avisoDeFimDeSemana", () => {
    const categorias = {
        restaurantes: categoria("Restaurantes", "conforto", 50000),
        lazer: categoria("Lazer", "conforto", 40000),
        compras: categoria("Compras", null, 30000),
        mercado: categoria("Mercado", "essencial", 80000),
    };

    it("aponta quem passou e quem está perto, só do estilo de vida", () => {
        const aviso = avisoDeFimDeSemana(
            resumo({ restaurantes: 62000, lazer: 34000, compras: 10000, mercado: 90000 }), categorias, null, hoje);
        expect(aviso?.titulo).toBe("Fim de semana com limite estourado");
        expect(aviso?.texto).toBe("Já passou do limite: Restaurantes (R$ 620,00 de R$ 500,00). Perto do limite: Lazer (85%).");
    });

    it("sem nada perto do limite não avisa", () => {
        expect(avisoDeFimDeSemana(resumo({ restaurantes: 10000, mercado: 90000 }), categorias, 500000, hoje)).toBeNull();
        expect(avisoDeFimDeSemana(null, categorias, null, hoje)).toBeNull();
    });

    it("o teto do grupo vale mesmo sem limite por categoria", () => {
        const semLimites = { restaurantes: categoria("Restaurantes", "conforto"), lazer: categoria("Lazer", null) };
        expect(avisoDeFimDeSemana(resumo({ restaurantes: 100000, lazer: 80000 }), semLimites, 200000, hoje)?.texto)
            .toBe("O estilo de vida usou 90% do teto do mês: restam R$ 200,00.");
        expect(avisoDeFimDeSemana(resumo({ restaurantes: 150000, lazer: 80000 }), semLimites, 200000, hoje)?.texto)
            .toBe("O estilo de vida inteiro passou do teto do mês em R$ 300,00.");
    });
});

describe("tetoDoEstiloDeVida", () => {
    it("usa a média dos meses com renda e a referência escolhida", () => {
        expect(tetoDoEstiloDeVida([1000000, 0, 800000], "equilibrio")).toBe(270000);
        expect(tetoDoEstiloDeVida([1000000], "acelerar")).toBe(200000);
        expect(tetoDoEstiloDeVida([1000000], undefined)).toBe(300000);
        expect(tetoDoEstiloDeVida([0, 0], "equilibrio")).toBeNull();
    });
});
