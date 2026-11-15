/**
 * Leitura tolerante dos documentos que o app grava. O motor não pode quebrar
 * por causa de um documento malformado: o que não dá para ler devolve `null`
 * e deixa de contribuir, em vez de derrubar o gatilho.
 */

import { isDateKey } from "../../../../core/utils/date_key";
import { Conta, Lancamento, TipoConta, TipoLancamento, Situacao } from "../models/modelo";

type Bruto = Record<string, unknown>;

const TIPOS_LANCAMENTO: TipoLancamento[] = ["entrada", "saida", "transferencia"];
const SITUACOES: Situacao[] = ["previsto", "efetivado", "cancelado"];
const TIPOS_CONTA: TipoConta[] = ["corrente", "dinheiro", "cartao", "investimento", "divida"];

const inteiro = (v: unknown): number | null => (typeof v === "number" && Number.isSafeInteger(v) ? v : null);
const texto = (v: unknown): string | null => (typeof v === "string" && v.length > 0 ? v : null);
const dia = (v: unknown): string | null => (isDateKey(v) ? v : null);

export function lerLancamento(bruto: Bruto | undefined | null): Lancamento | null {
    if (!bruto) return null;

    const tipo = bruto.tipo as TipoLancamento;
    const situacao = bruto.situacao as Situacao;
    const data = dia(bruto.data);
    const contaId = texto(bruto.contaId);
    const previsto = inteiro(bruto.previstoCentavos);
    const realizado = inteiro(bruto.realizadoCentavos);

    if (!TIPOS_LANCAMENTO.includes(tipo) || !SITUACOES.includes(situacao) || !data || !contaId) {
        return null;
    }
    if ((previsto !== null && previsto < 0) || (realizado !== null && realizado < 0)) {
        return null;
    }

    const parcela = bruto.parcela as { numero?: unknown; total?: unknown } | null | undefined;

    return {
        tipo,
        descricao: typeof bruto.descricao === "string" ? bruto.descricao : "",
        previstoCentavos: previsto,
        realizadoCentavos: realizado,
        data,
        dataEfetiva: dia(bruto.dataEfetiva),
        situacao,
        contaId,
        contaDestinoId: texto(bruto.contaDestinoId),
        categoriaId: texto(bruto.categoriaId),
        serieId: texto(bruto.serieId),
        parcela: parcela && inteiro(parcela.numero) !== null && inteiro(parcela.total) !== null ?
            { numero: parcela.numero as number, total: parcela.total as number } :
            null,
        contraparteId: texto(bruto.contraparteId),
        pagaFaturaId: texto(bruto.pagaFaturaId),
        origem: (texto(bruto.origem) ?? "manual") as Lancamento["origem"],
        loteId: texto(bruto.loteId),
        autorId: texto(bruto.autorId),
    };
}

export function lerConta(bruto: Bruto | undefined | null): Conta | null {
    if (!bruto) return null;

    const tipo = bruto.tipo as TipoConta;
    if (!TIPOS_CONTA.includes(tipo)) return null;

    return {
        nome: typeof bruto.nome === "string" ? bruto.nome : "",
        tipo,
        icone: texto(bruto.icone),
        cor: texto(bruto.cor),
        banco: texto(bruto.banco),
        saldoInicialCentavos: inteiro(bruto.saldoInicialCentavos) ?? 0,
        saldoInicialData: dia(bruto.saldoInicialData),
        arquivada: bruto.arquivada === true,
        limiteCentavos: inteiro(bruto.limiteCentavos),
        diaFechamento: inteiro(bruto.diaFechamento),
        diaVencimento: inteiro(bruto.diaVencimento),
        taxaJuros: typeof bruto.taxaJuros === "number" ? bruto.taxaJuros : null,
        donos: Array.isArray(bruto.donos) ? bruto.donos.filter((d): d is string => typeof d === "string") : [],
    };
}
