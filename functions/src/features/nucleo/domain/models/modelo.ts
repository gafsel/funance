/**
 * Modelo de dados do Funances 2.
 *
 * Tudo vive em `espacos/{espacoId}` — uma raiz separada de `workspaces/`, para
 * que o modelo novo e o antigo convivam no mesmo banco sem que os gatilhos de
 * um reajam às gravações do outro.
 *
 * Convenções:
 * - dinheiro é sempre inteiro, em centavos (`*Centavos`);
 * - datas de calendário são texto `YYYY-MM-DD` no fuso do produto; meses são
 *   `YYYY-MM`;
 * - o que o servidor calcula (dias de saldo, resumos, totais de fatura) fica
 *   em documentos próprios, nunca dentro de um documento que o app grava.
 *   Assim o motor não precisa de guarda contra o próprio eco.
 */

export type DiaChave = string;
export type MesChave = string;

export const RAIZ = "espacos";

/** Caminhos relativos a `espacos/{espacoId}`. */
export const COLECOES = {
    membros: "membros",
    contas: "contas",
    lancamentos: "lancamentos",
    series: "series",
    faturas: "faturas",
    categorias: "categorias",
    metas: "metas",
    caminho: "caminho",
    contrapartes: "contrapartes",
    entrada: "entrada",
    lotes: "lotes",
    regras: "regras",
    fechamentos: "fechamentos",
    resumos: "resumos",
    /** Só do servidor: o que o motor já aplicou de cada lançamento. */
    aplicados: "aplicados",
    /** Subcoleção de `contas/{id}`: movimento do dia. */
    dias: "dias",
} as const;

export type TipoEspaco = "pessoal" | "empresa";

export interface Espaco {
    nome: string;
    tipo: TipoEspaco;
    criadoEm: Date;
    /** Presente quando o espaço veio do app antigo. */
    migradoDe?: { projeto: string; workspaceId: string };
}

export type Papel = "dono" | "convidado";

export interface Membro {
    /** Repete o id do documento, para a consulta "meus espaços". */
    uid: string;
    papel: Papel;
    entrada: Date | null;
}

export type TipoConta = "corrente" | "dinheiro" | "cartao" | "investimento" | "divida";

export interface Conta {
    nome: string;
    tipo: TipoConta;
    icone: string | null;
    cor: string | null;
    banco: string | null;
    /** Com sinal: negativo em cartão e dívida que começam devendo. */
    saldoInicialCentavos: number;
    saldoInicialData: DiaChave | null;
    arquivada: boolean;
    /** Só cartão. */
    limiteCentavos: number | null;
    diaFechamento: number | null;
    diaVencimento: number | null;
    /** Só investimento e dívida: taxa ao mês, em pontos percentuais. */
    taxaJuros: number | null;
    donos: string[];
}

export type TipoLancamento = "entrada" | "saida" | "transferencia";
export type Situacao = "previsto" | "efetivado" | "cancelado";
export type Origem = "manual" | "texto" | "extrato" | "planilha" | "notificacao" | "serie";

export interface Lancamento {
    tipo: TipoLancamento;
    descricao: string;
    /** `null` = não foi planejado (nasceu já efetivado). */
    previstoCentavos: number | null;
    /** `null` enquanto não efetivado. Sempre positivo; o sinal vem do tipo. */
    realizadoCentavos: number | null;
    /** Data prevista (vencimento). */
    data: DiaChave;
    /** Dia em que o dinheiro se moveu. */
    dataEfetiva: DiaChave | null;
    situacao: Situacao;
    /** Entrada: conta que recebe. Saída e transferência: conta de onde sai. */
    contaId: string;
    /** Só transferência. */
    contaDestinoId: string | null;
    categoriaId: string | null;
    serieId: string | null;
    parcela: { numero: number; total: number } | null;
    contraparteId: string | null;
    /** Transferência para um cartão que paga esta fatura. */
    pagaFaturaId: string | null;
    origem: Origem;
    loteId: string | null;
    autorId: string | null;
}

export interface Serie {
    forma: "parcelado" | "recorrente";
    frequencia: "mensal";
    tipo: TipoLancamento;
    descricao: string;
    valorCentavos: number;
    parcelas: number | null;
    diaVencimento: number;
    inicioMes: MesChave;
    /** Último vencimento já gerado (recorrente). */
    geradoAte: DiaChave | null;
    contaId: string;
    contaDestinoId: string | null;
    categoriaId: string | null;
    ativa: boolean;
}

export interface Fatura {
    contaId: string;
    vencimento: DiaChave;
    fechamento: DiaChave;
    /** Janela de compras, inclusive nas duas pontas. */
    inicio: DiaChave;
    fim: DiaChave;
    /** Calculados pelo motor. */
    totalCentavos: number;
    pagoCentavos: number;
}

export interface Categoria {
    nome: string;
    tipo: "entrada" | "saida";
    icone: string | null;
    cor: string | null;
    grupo: "essencial" | "conforto" | "investimento" | null;
    limiteMensalCentavos: number | null;
    arquivada: boolean;
}

export type TipoMeta = "juntar" | "quitar" | "reduzirCartao" | "reduzirGasto";

export interface Meta {
    nome: string;
    tipo: TipoMeta;
    alvoCentavos: number;
    inicio: DiaChave;
    prazo: DiaChave;
    parcelaMensalCentavos: number | null;
    contaId: string | null;
    categoriaId: string | null;
    adiamentos: number;
    arquivada: boolean;
    resultado: "atingida" | "nao_atingida" | null;
    encerradaEm: DiaChave | null;
}

export interface ItemEntrada {
    descricao: string;
    valorCentavos: number;
    data: DiaChave;
    tipo: TipoLancamento;
    origem: Origem;
    situacao: "pendente" | "confirmado" | "ignorado";
    sugestao: { contaId: string | null; categoriaId: string | null };
    loteId: string | null;
    bruto: Record<string, unknown> | null;
}

export interface Fechamento {
    mes: MesChave;
    situacao: "aberto" | "fechado" | "historico";
    /** Saldo de extrato informado, por conta. */
    extratoCentavos: Record<string, number>;
    fechadoPor: string | null;
    fechadoEm: Date | null;
    /** Só em registros trazidos do app antigo. */
    historico?: Record<string, unknown>;
}

/** Derivado: `resumos/{YYYY-MM}`. */
export interface ResumoMes {
    categorias: Record<string, { previstoCentavos?: number; realizadoCentavos?: number }>;
    entradas: { previstoCentavos?: number; realizadoCentavos?: number };
    saidas: { previstoCentavos?: number; realizadoCentavos?: number };
    /** Movimento do mês em cada conta. */
    contas: Record<string, { deltaCentavos?: number }>;
}

/** Chave usada em `ResumoMes.categorias` para lançamento sem categoria. */
export const SEM_CATEGORIA = "_sem";

export const idDaFatura = (contaId: string, vencimento: DiaChave): string => `${contaId}_${vencimento}`;
