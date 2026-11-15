import { Conta, Lancamento } from "../features/nucleo/domain/models/modelo";
import {
    contribuicoes,
    contribuicoesDaConta,
    diferenca,
    faturaDoDia,
    saldoEm,
} from "../features/nucleo/domain/services/contribuicoes";

const conta = (tipo: Conta["tipo"], extra: Partial<Conta> = {}): Conta => ({
    nome: tipo, tipo, icone: null, cor: null, banco: null, saldoInicialCentavos: 0, saldoInicialData: null,
    arquivada: false, limiteCentavos: null, diaFechamento: null, diaVencimento: null, taxaJuros: null, donos: [],
    ...extra,
});

const contas = {
    cc: conta("corrente"),
    cartao: conta("cartao", { diaFechamento: 5, diaVencimento: 10 }),
};

const lancamento = (extra: Partial<Lancamento>): Lancamento => ({
    tipo: "saida", descricao: "", previstoCentavos: null, realizadoCentavos: 1000, data: "2026-03-12",
    dataEfetiva: "2026-03-12", situacao: "efetivado", contaId: "cc", contaDestinoId: null, categoriaId: "mercado",
    serieId: null, parcela: null, contraparteId: null, pagaFaturaId: null, origem: "manual", loteId: null, autorId: null,
    ...extra,
});

const mapa = (celulas: ReturnType<typeof contribuicoes>) =>
    Object.fromEntries(celulas.map((c) => [`${c.doc}#${c.campo.join("/")}`, c.centavos]));

describe("contribuicoes", () => {
    it("saída efetivada tira da conta e soma no realizado da categoria", () => {
        expect(mapa(contribuicoes(lancamento({}), contas))).toEqual({
            "resumos/2026-03#categorias/mercado/realizadoCentavos": 1000,
            "resumos/2026-03#saidas/realizadoCentavos": 1000,
            "contas/cc/dias/2026-03-12#deltaCentavos": -1000,
            "resumos/2026-03#contas/cc/deltaCentavos": -1000,
        });
    });

    it("previsto conta no mês do vencimento e o realizado no mês em que aconteceu", () => {
        const celulas = mapa(contribuicoes(lancamento({
            tipo: "entrada", previstoCentavos: 900, data: "2026-02-28", dataEfetiva: "2026-03-02", categoriaId: "salario",
        }), contas));
        expect(celulas["resumos/2026-02#categorias/salario/previstoCentavos"]).toBe(900);
        expect(celulas["resumos/2026-03#categorias/salario/realizadoCentavos"]).toBe(1000);
        expect(celulas["contas/cc/dias/2026-03-02#deltaCentavos"]).toBe(1000);
    });

    it("lançamento previsto não mexe em saldo", () => {
        const celulas = contribuicoes(lancamento({
            situacao: "previsto", previstoCentavos: 500, realizadoCentavos: null, dataEfetiva: null,
        }), contas);
        expect(celulas.every((c) => c.doc.startsWith("resumos/") && c.campo.includes("previstoCentavos"))).toBe(true);
    });

    it("cancelado não contribui com nada", () => {
        expect(contribuicoes(lancamento({ situacao: "cancelado" }), contas)).toEqual([]);
        expect(contribuicoes(null, contas)).toEqual([]);
    });

    it("transferência move entre contas e fica fora das categorias", () => {
        const celulas = mapa(contribuicoes(lancamento({
            tipo: "transferencia", contaId: "cc", contaDestinoId: "poupanca", categoriaId: null,
        }), contas));
        expect(celulas).toEqual({
            "contas/cc/dias/2026-03-12#deltaCentavos": -1000,
            "resumos/2026-03#contas/cc/deltaCentavos": -1000,
            "contas/poupanca/dias/2026-03-12#deltaCentavos": 1000,
            "resumos/2026-03#contas/poupanca/deltaCentavos": 1000,
        });
    });

    it("compra no cartão conta no mês da compra e entra na fatura do ciclo", () => {
        const celulas = contribuicoes(lancamento({ contaId: "cartao" }), contas);
        const m = mapa(celulas);
        expect(m["resumos/2026-03#categorias/mercado/realizadoCentavos"]).toBe(1000);
        expect(m["faturas/cartao_2026-04-10#totalCentavos"]).toBe(1000);
        expect(celulas.find((c) => c.doc.startsWith("faturas/"))?.base).toEqual({
            contaId: "cartao", vencimento: "2026-04-10", fechamento: "2026-04-05", inicio: "2026-03-05", fim: "2026-04-04",
        });
    });

    it("compra antes do fechamento entra na fatura deste mês", () => {
        expect(faturaDoDia("cartao", contas.cartao, "2026-03-03").id).toBe("cartao_2026-03-10");
    });

    it("pagar a fatura soma em pago e não abate o total; estorno abate", () => {
        const pagamento = mapa(contribuicoes(lancamento({
            tipo: "transferencia", contaId: "cc", contaDestinoId: "cartao", categoriaId: null,
            pagaFaturaId: "cartao_2026-03-10",
        }), contas));
        expect(pagamento["faturas/cartao_2026-03-10#pagoCentavos"]).toBe(1000);
        expect(Object.keys(pagamento).some((k) => k.endsWith("totalCentavos"))).toBe(false);

        const estorno = mapa(contribuicoes(lancamento({ tipo: "entrada", contaId: "cartao" }), contas));
        expect(estorno["faturas/cartao_2026-04-10#totalCentavos"]).toBe(-1000);
    });

    it("cartão que começa devendo põe a dívida na fatura do ciclo", () => {
        const cartao = conta("cartao", {
            diaFechamento: 5, diaVencimento: 10, saldoInicialCentavos: -30000, saldoInicialData: "2026-03-01",
        });
        expect(mapa(contribuicoesDaConta("cartao", cartao))).toEqual({ "faturas/cartao_2026-03-10#totalCentavos": 30000 });
        expect(contribuicoesDaConta("cc", conta("corrente", { saldoInicialCentavos: 500, saldoInicialData: "2026-03-01" }))).toEqual([]);
    });
});

describe("diferenca", () => {
    it("é vazia quando nada mudou", () => {
        const celulas = contribuicoes(lancamento({}), contas);
        expect(diferenca(celulas, celulas)).toEqual([]);
    });

    it("mudar a data desfaz o dia antigo e aplica no novo", () => {
        const antes = contribuicoes(lancamento({}), contas);
        const depois = contribuicoes(lancamento({ dataEfetiva: "2026-03-13" }), contas);
        expect(mapa(diferenca(depois, antes))).toEqual({
            "contas/cc/dias/2026-03-12#deltaCentavos": 1000,
            "contas/cc/dias/2026-03-13#deltaCentavos": -1000,
        });
    });

    it("apagar desfaz tudo o que estava aplicado", () => {
        const antes = contribuicoes(lancamento({}), contas);
        const desfaz = diferenca([], antes);
        expect(desfaz.map((c) => c.centavos).sort()).toEqual(antes.map((c) => -c.centavos).sort());
    });
});

describe("saldoEm", () => {
    it("soma o saldo inicial a partir da data dele e o movimento até o dia", () => {
        const c = conta("corrente", { saldoInicialCentavos: 10000, saldoInicialData: "2026-03-10" });
        const deltas = { "2026-03-05": 100, "2026-03-12": -300, "2026-04-01": 50 };
        expect(saldoEm(c, deltas, "2026-03-09")).toBe(100);
        expect(saldoEm(c, deltas, "2026-03-12")).toBe(9800);
        expect(saldoEm(c, deltas, "2026-12-31")).toBe(9850);
    });
});
