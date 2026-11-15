/**
 * Geração dos lançamentos de uma série (parcelado ou recorrente).
 *
 * Pura: devolve os lançamentos que faltam, com ids determinísticos
 * (`<serieId>_<YYYY-MM>`), para que gerar duas vezes dê o mesmo resultado.
 */

import { daysInMonthKey, shiftMonthKey } from "../../../../core/utils/month_key";
import { DiaChave, Lancamento, MesChave, Serie } from "../models/modelo";

/** Dia de vencimento da série num mês, limitado ao último dia do mês. */
export function vencimentoNoMes(mes: MesChave, dia: number): DiaChave {
    return `${mes}-${String(Math.min(dia, daysInMonthKey(mes))).padStart(2, "0")}`;
}

/**
 * Lançamentos previstos de uma série recorrente depois de `geradoAte` e até
 * `horizonte` (inclusive), um por mês.
 */
export function proximosDaSerie(serieId: string, serie: Serie, horizonte: MesChave): Record<string, Lancamento> {
    if (!serie.ativa || serie.forma !== "recorrente") return {};

    const novos: Record<string, Lancamento> = {};
    let mes = serie.geradoAte ? shiftMonthKey(serie.geradoAte.slice(0, 7), 1) : serie.inicioMes;
    while (mes <= horizonte) {
        novos[`${serieId}_${mes}`] = {
            tipo: serie.tipo,
            descricao: serie.descricao,
            previstoCentavos: serie.valorCentavos,
            realizadoCentavos: null,
            data: vencimentoNoMes(mes, serie.diaVencimento),
            dataEfetiva: null,
            situacao: "previsto",
            contaId: serie.contaId,
            contaDestinoId: serie.contaDestinoId,
            categoriaId: serie.categoriaId,
            serieId,
            parcela: null,
            contraparteId: null,
            pagaFaturaId: null,
            origem: "serie",
            loteId: null,
            autorId: null,
        };
        mes = shiftMonthKey(mes, 1);
    }
    return novos;
}
