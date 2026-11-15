import { conferir, relatorio } from "../features/nucleo/migracao/conferir";
import { diaDe } from "../features/nucleo/migracao/dados_antigos";
import { documentos, transformar } from "../features/nucleo/migracao/transformar";
import { parseArgs } from "../scripts/migrar_funances2";
import { em, workspaceAntigo } from "./fixtures/nucleo_workspace_antigo";

const HOJE = "2026-01-25";

describe("transformar", () => {
    const novo = transformar(workspaceAntigo(), { hoje: HOJE });

    it("espaço e membros: o primeiro da lista vira dono", () => {
        expect(novo.espaco).toMatchObject({ nome: "Casa", tipo: "pessoal", migradoDe: { projeto: "demo-antigo", workspaceId: "w1" } });
        expect(novo.membros).toEqual({ u1: { papel: "dono", entrada: null }, u2: { papel: "convidado", entrada: null } });
    });

    it("saldo inicial vira campo da conta e a parcela sintética some", () => {
        expect(novo.contas.cc).toMatchObject({ tipo: "corrente", saldoInicialCentavos: 100000, saldoInicialData: "2026-01-01", banco: "nubank" });
        expect(novo.lancamentos.ib).toBeUndefined();
    });

    it("parcela vira lançamento com o mesmo id, previsto e realizado separados", () => {
        expect(novo.lancamentos.i1).toMatchObject({
            tipo: "entrada", previstoCentavos: 500000, realizadoCentavos: 500000, situacao: "efetivado",
            data: "2026-01-05", dataEfetiva: "2026-01-05", contaId: "cc", categoriaId: "salario",
        });
        expect(novo.lancamentos.i2).toMatchObject({ previstoCentavos: null, realizadoCentavos: 20000, contaId: "cartao" });
    });

    it("fatura em aberto vira a entidade fatura, com a janela gravada", () => {
        expect(novo.lancamentos.inv1).toBeUndefined();
        expect(novo.faturas["cartao_2026-02-10"]).toMatchObject({
            contaId: "cartao", vencimento: "2026-02-10", inicio: "2026-01-05", fim: "2026-02-04", fechamento: "2026-02-05",
        });
    });

    it("categoria sem id é criada e avisada; categoria de sistema não migra", () => {
        expect(novo.lancamentos.i3.categoriaId).toBe("mig-lazer-saida");
        expect(novo.categorias["mig-lazer-saida"]).toMatchObject({ nome: "Lazer", tipo: "saida" });
        expect(novo.categorias["initial-balance"]).toBeUndefined();
        expect(novo.avisos.map((a) => a.codigo)).toContain("categoria-sem-id");
    });

    it("limite mensal vem do planejamento que cobre o mês atual", () => {
        expect(novo.categorias.comida.limiteMensalCentavos).toBe(80000);
        expect(novo.categorias.salario.limiteMensalCentavos).toBeNull();
    });

    it("o que não cabe no modelo fica de fora e é listado, com o valor", () => {
        expect(novo.lancamentos.i4).toBeUndefined();
        expect(novo.problemas).toEqual([
            expect.objectContaining({ codigo: "lancamento-contas", origem: "installments/i4", centavos: 5000 }),
        ]);
    });

    it("só transações automáticas pendentes vão para a caixa de entrada", () => {
        expect(Object.keys(novo.entrada)).toEqual(["a1"]);
        expect(novo.entrada.a1).toMatchObject({ valorCentavos: 8000, data: "2026-01-15", tipo: "entrada", situacao: "pendente" });
    });

    it("conciliação antiga entra só como histórico", () => {
        expect(novo.fechamentos["antigo-r1"]).toMatchObject({ mes: "2026-01", situacao: "historico" });
    });

    it("nenhum documento novo tem campo undefined", () => {
        const temUndefined = (v: unknown): boolean =>
            v === undefined || (!!v && typeof v === "object" && !(v instanceof Date) && Object.values(v).some(temUndefined));
        expect(Object.values(documentos(novo)).some(temUndefined)).toBe(false);
    });

    it("pagamento de fatura vira transferência que paga a fatura", () => {
        const dados = workspaceAntigo();
        dados.installments.inv1 = {
            ...dados.installments.inv1, status: "paid", paidAmount: 200, paidDate: em("2026-02-09"),
            accounts: { cc: "debt", cartao: "credit" },
        };
        const pago = transformar(dados, { hoje: HOJE });
        expect(pago.lancamentos.inv1).toMatchObject({
            tipo: "transferencia", contaId: "cc", contaDestinoId: "cartao", pagaFaturaId: "cartao_2026-02-10",
            realizadoCentavos: 20000, dataEfetiva: "2026-02-09",
        });
    });

    it("compra parcelada vira série", () => {
        const dados = workspaceAntigo();
        dados.orders.o5 = { type: "expense", amount: 300, accounts: { cc: "debt" }, installmentType: "installment", installmentCount: 2, dueDay: 15, startMonth: "2026-02", status: "active", description: "Sofá" };
        for (const n of [1, 2]) {
            dados.installments[`s${n}`] = {
                orderId: "o5", type: "expense", amount: 150, status: "pending", dueDate: em(`2026-0${n + 1}-15`), paidDate: null,
                accounts: { cc: "debt" }, installmentNumber: n, installmentCount: 2, installmentType: "installment",
            };
        }
        const t = transformar(dados, { hoje: HOJE });
        expect(t.series.o5).toMatchObject({ forma: "parcelado", parcelas: 2, valorCentavos: 30000, diaVencimento: 15, inicioMes: "2026-02", contaId: "cc" });
        expect(t.lancamentos.s2).toMatchObject({ serieId: "o5", parcela: { numero: 2, total: 2 } });
    });
});

describe("diaDe", () => {
    it("lê o dia no fuso do produto, não em UTC", () => {
        expect(diaDe(new Date("2026-01-11T01:30:00Z"))).toBe("2026-01-10");
        expect(diaDe({ toDate: () => new Date("2026-01-10T15:00:00Z") })).toBe("2026-01-10");
    });
    it("texto sem fuso vale o dia escrito", () => {
        expect(diaDe("2026-09-04T23:30:00.000")).toBe("2026-09-04");
        expect(diaDe(null)).toBeNull();
    });
});

describe("conferir", () => {
    it("fecha sem diferença sem explicação quando o antigo é coerente", () => {
        const dados = workspaceAntigo();
        const novo = transformar(dados, { hoje: HOJE });
        const c = conferir(dados, novo, { hoje: HOJE });

        expect(c.secoes.flatMap((s) => s.semExplicacao)).toEqual([]);
        const causas = c.secoes.flatMap((s) => s.explicadas.map((d) => d.causa));
        expect(causas).toContain("saldo inicial deixa de ser lançamento e vira campo da conta");
        expect(causas).toContain("categoria sem id ficava fora do resumo antigo");
        expect(causas).toContain("lançamentos que ficaram de fora da migração (ver problemas)");

        const faturas = c.secoes.find((s) => s.nome === "Total de cada fatura");
        expect(faturas).toMatchObject({ comparados: 1, iguais: 1 });
        expect(relatorio(c, novo)).toContain("Diferenças sem explicação: **0**");
    });

    it("acusa saldo gravado que não bate", () => {
        const dados = workspaceAntigo();
        dados.saldos.cc["2026-01-05"] = { dateKey: "2026-01-05", delta: 5000.01, balanceCents: 600001 };
        const novo = transformar(dados, { hoje: HOJE });
        const c = conferir(dados, novo, { hoje: HOJE });
        expect(c.semExplicacao).toBe(1);
        expect(c.secoes[1].semExplicacao[0]).toMatchObject({ antigo: 600001, novo: 600000 });
    });

    it("explica o acumulado antigo que contradiz os movimentos do próprio app antigo", () => {
        const dados = workspaceAntigo();
        dados.saldos.cc["2026-01-05"].balanceCents = 590000;
        const c = conferir(dados, transformar(dados, { hoje: HOJE }), { hoje: HOJE });
        expect(c.semExplicacao).toBe(0);
        expect(c.secoes[1].explicadas[0].causa).toContain("acumulado antigo desatualizado");
    });

    it("explica o total de fatura antigo que não bate com as compras do ciclo, mas não um erro da migração", () => {
        const dados = workspaceAntigo();
        dados.orders["invoice-cartao-2026-02-10"].amountCents = 25000;
        const novo = transformar(dados, { hoje: HOJE });
        expect(conferir(dados, novo, { hoje: HOJE }).semExplicacao).toBe(0);

        // Se a migração perdesse a compra, a diferença ficaria sem explicação.
        delete novo.lancamentos.i2;
        const faturas = conferir(dados, novo, { hoje: HOJE }).secoes.find((s) => s.nome === "Total de cada fatura");
        expect(faturas?.semExplicacao).toHaveLength(1);
    });

    it("meta de reduzir gasto sem categoria fica em zero e é avisada", () => {
        const dados = workspaceAntigo();
        dados.goals.g1 = { runtimeType: "reduceExpense", name: "Gastar menos", targetAmount: 100, currentAmount: 0, startDate: em("2026-01-01"), deadline: em("2026-06-30"), category: { id: "" } };
        const novo = transformar(dados, { hoje: HOJE });
        expect(novo.avisos.map((a) => a.codigo)).toContain("meta-sem-categoria");
        expect(conferir(dados, novo, { hoje: HOJE }).semExplicacao).toBe(0);
    });

    it("acusa total de categoria que não bate", () => {
        const dados = workspaceAntigo();
        dados.resumos["2026-01"].categories.comida.actualAmount = 199;
        const c = conferir(dados, transformar(dados, { hoje: HOJE }), { hoje: HOJE });
        expect(c.semExplicacao).toBe(1);
    });

    it("explica a diferença de pagamento que o app antigo jogava na fatura seguinte", () => {
        const dados = workspaceAntigo();
        // Fatura de fevereiro paga com R$ 10 a menos: o antigo soma R$ 10 na de março.
        dados.installments.inv1 = {
            ...dados.installments.inv1, status: "paid", paidAmount: 190, paidDate: em("2026-02-09"),
            accounts: { cc: "debt", cartao: "credit" },
        };
        dados.orders["invoice-cartao-2026-03-10"] = { ...dados.orders["invoice-cartao-2026-02-10"], amount: 10, amountCents: 1000 };
        dados.installments.inv2 = {
            orderId: "invoice-cartao-2026-03-10", type: "transfer", amount: 10, status: "pending", isInvoice: true,
            dueDate: em("2026-03-10"), paidDate: null, accounts: { cartao: "credit" },
        };
        dados.saldos.cc["2026-02-09"] = { dateKey: "2026-02-09", balanceCents: 581000 };
        dados.saldos.cartao["2026-02-09"] = { dateKey: "2026-02-09", balanceCents: -1000 };

        const c = conferir(dados, transformar(dados, { hoje: HOJE }), { hoje: HOJE });
        expect(c.semExplicacao).toBe(0);
        const faturas = c.secoes.find((s) => s.nome === "Total de cada fatura");
        expect(faturas?.explicadas).toEqual([
            expect.objectContaining({ chave: "cartao_2026-03-10", antigo: 1000, novo: 0 }),
        ]);
    });
});

describe("parseArgs da migração", () => {
    it("simula por padrão e exige origem e alvo", () => {
        expect(parseArgs(["--origem=a", "--todos"])).toMatchObject({ aplicar: false, destino: null, todos: true });
        expect(() => parseArgs(["--todos"])).toThrow("--origem");
        expect(() => parseArgs(["--origem=a"])).toThrow("--workspace");
        expect(() => parseArgs(["--origem=a", "--todos", "--workspace=x"])).toThrow("--workspace");
    });

    it("recusa gravar no projeto antigo ou na própria origem", () => {
        expect(() => parseArgs(["--origem=a", "--todos", "--aplicar"])).toThrow("--destino");
        expect(() => parseArgs(["--origem=a", "--destino=a", "--todos", "--aplicar"])).toThrow("mesmo projeto");
        expect(() => parseArgs(["--origem=a", "--destino=funance-cef1b", "--todos", "--aplicar"])).toThrow("projeto antigo");
        expect(parseArgs(["--origem=funance-cef1b", "--destino=funances2-testes", "--workspace=w", "--aplicar"]).aplicar).toBe(true);
    });
});
