/**
 * O que um lançamento soma em cada documento derivado.
 *
 * Esta é a única implementação das regras de saldo, fatura e resumo. O motor
 * (incremental) e a reconstrução (do zero) chamam a mesma função, então os
 * dois não têm como divergir.
 *
 * Uma contribuição é uma célula: documento + campo + centavos. O motor guarda
 * as células já aplicadas de cada lançamento e, a cada mudança, aplica só a
 * diferença entre as novas e as guardadas.
 */

import { shiftDateKey } from "../../../../core/utils/date_key";
import {
    COLECOES,
    Conta,
    DiaChave,
    Fatura,
    Lancamento,
    SEM_CATEGORIA,
    idDaFatura,
} from "../models/modelo";

export interface Celula {
    /** Caminho relativo ao espaço, ex.: `resumos/2026-11`. */
    doc: string;
    /** Caminho do campo dentro do documento. */
    campo: string[];
    centavos: number;
    /** Campos fixos gravados junto (identidade de uma fatura, por exemplo). */
    base?: Record<string, unknown>;
}

export type ContasPorId = Record<string, Pick<Conta, "tipo" | "diaFechamento" | "diaVencimento"> | undefined>;

const FECHAMENTO_PADRAO = 5;
const VENCIMENTO_PADRAO = 10;

const doisDigitos = (n: number): string => String(n).padStart(2, "0");
const ultimoDiaDoMes = (ano: number, mes: number): number => new Date(Date.UTC(ano, mes, 0)).getUTCDate();

/** `dia` do mês `mes` (1 a 12; pode passar de 12 ou ser menor que 1), limitado ao último dia dele. */
function diaNoMes(ano: number, mes: number, dia: number): DiaChave {
    const data = new Date(Date.UTC(ano, mes - 1, 1));
    const a = data.getUTCFullYear();
    const m = data.getUTCMonth() + 1;
    return `${a}-${doisDigitos(m)}-${doisDigitos(Math.min(dia, ultimoDiaDoMes(a, m)))}`;
}

/**
 * Dados fixos da fatura que recebe um movimento feito em `dia` no cartão.
 *
 * Vale a data do calendário: a compra até a véspera do fechamento entra na
 * fatura que fecha neste mês; do dia do fechamento em diante, na seguinte. A
 * janela devolvida (`inicio` a `fim`) sempre contém `dia`, e é por ela que o
 * app lista as compras de uma fatura. Uma versão anterior empurrava a compra
 * de fim de semana ou feriado para o próximo dia útil antes de decidir a
 * fatura; quando o fechamento caía nesses dias, a compra da véspera era
 * somada numa fatura e listada em outra.
 */
export function faturaDoDia(contaId: string, conta: Pick<Conta, "diaFechamento" | "diaVencimento">, dia: DiaChave):
    { id: string; base: Omit<Fatura, "totalCentavos" | "pagoCentavos"> } {
    const diaFechamento = conta.diaFechamento || FECHAMENTO_PADRAO;
    const diaVencimento = conta.diaVencimento || VENCIMENTO_PADRAO;
    const [ano, mes, d] = dia.split("-").map(Number);

    // Com fechamento 31, fevereiro fecha no dia 28 (ou 29).
    const fechaNesteMes = d < Math.min(diaFechamento, ultimoDiaDoMes(ano, mes));
    const mesDoFechamento = fechaNesteMes ? mes : mes + 1;
    const fechamento = diaNoMes(ano, mesDoFechamento, diaFechamento);
    // Vencimento menor que o fechamento cai no mês seguinte ao do fechamento.
    const vencimento = diaNoMes(ano, mesDoFechamento + (diaVencimento < diaFechamento ? 1 : 0), diaVencimento);
    return {
        id: idDaFatura(contaId, vencimento),
        base: {
            contaId,
            vencimento,
            fechamento,
            inicio: diaNoMes(ano, mesDoFechamento - 1, diaFechamento),
            fim: shiftDateKey(fechamento, -1),
        },
    };
}

/**
 * Células de um lançamento. `contas` precisa trazer as contas citadas nele;
 * conta ausente é tratada como conta comum (sem fatura).
 */
export function contribuicoes(lancamento: Lancamento | null, contas: ContasPorId): Celula[] {
    if (!lancamento || lancamento.situacao === "cancelado") {
        return [];
    }

    const celulas: Celula[] = [];
    const l = lancamento;
    const semCategoria = l.tipo === "transferencia";
    const categoria = l.categoriaId || SEM_CATEGORIA;
    const lado = l.tipo === "entrada" ? "entradas" : "saidas";

    if (l.previstoCentavos !== null && !semCategoria) {
        const doc = `${COLECOES.resumos}/${l.data.slice(0, 7)}`;
        celulas.push({ doc, campo: ["categorias", categoria, "previstoCentavos"], centavos: l.previstoCentavos });
        celulas.push({ doc, campo: [lado, "previstoCentavos"], centavos: l.previstoCentavos });
    }

    const efetivado = l.situacao === "efetivado" && l.realizadoCentavos !== null && l.dataEfetiva !== null;
    if (!efetivado) {
        return semZeros(celulas);
    }

    const valor = l.realizadoCentavos as number;
    const dia = l.dataEfetiva as DiaChave;
    const resumo = `${COLECOES.resumos}/${dia.slice(0, 7)}`;

    if (!semCategoria) {
        celulas.push({ doc: resumo, campo: ["categorias", categoria, "realizadoCentavos"], centavos: valor });
        celulas.push({ doc: resumo, campo: [lado, "realizadoCentavos"], centavos: valor });
    }

    const mover = (contaId: string, centavos: number) => {
        celulas.push({
            doc: `${COLECOES.contas}/${contaId}/${COLECOES.dias}/${dia}`,
            campo: ["deltaCentavos"],
            centavos,
        });
        celulas.push({ doc: resumo, campo: ["contas", contaId, "deltaCentavos"], centavos });

        const conta = contas[contaId];
        if (conta?.tipo !== "cartao") return;

        // Quem paga a fatura não reduz o que foi comprado nela: soma em "pago".
        if (centavos > 0 && l.pagaFaturaId) {
            celulas.push({
                doc: `${COLECOES.faturas}/${l.pagaFaturaId}`,
                campo: ["pagoCentavos"],
                centavos,
            });
            return;
        }

        // Saída do cartão é compra (soma); entrada sem fatura indicada é
        // estorno (abate).
        const fatura = faturaDoDia(contaId, conta, dia);
        celulas.push({
            doc: `${COLECOES.faturas}/${fatura.id}`,
            campo: ["totalCentavos"],
            centavos: -centavos,
            base: fatura.base,
        });
    };

    if (l.tipo === "entrada") {
        mover(l.contaId, valor);
    }
    else {
        mover(l.contaId, -valor);
        if (l.tipo === "transferencia" && l.contaDestinoId) {
            mover(l.contaDestinoId, valor);
        }
    }

    return semZeros(celulas);
}

/**
 * Células de uma conta. Só o cartão que começa devendo contribui: a dívida
 * inicial entra na fatura do ciclo em que o saldo foi informado. O saldo
 * inicial em si não vira movimento; ele é somado na leitura (`saldoEm`).
 */
export function contribuicoesDaConta(contaId: string, conta: Conta | null): Celula[] {
    if (!conta || conta.tipo !== "cartao" || !conta.saldoInicialData || conta.saldoInicialCentavos === 0) {
        return [];
    }
    const fatura = faturaDoDia(contaId, conta, conta.saldoInicialData);
    return [{
        doc: `${COLECOES.faturas}/${fatura.id}`,
        campo: ["totalCentavos"],
        centavos: -conta.saldoInicialCentavos,
        base: fatura.base,
    }];
}

const semZeros = (celulas: Celula[]): Celula[] => celulas.filter((c) => c.centavos !== 0);

export const chaveDaCelula = (c: Pick<Celula, "doc" | "campo">): string => `${c.doc}#${c.campo.join("/")}`;

/** Soma células de mesma chave. A `base` de qualquer uma delas é mantida. */
export function somar(celulas: Celula[]): Map<string, Celula> {
    const mapa = new Map<string, Celula>();
    for (const c of celulas) {
        const chave = chaveDaCelula(c);
        const atual = mapa.get(chave);
        if (atual) {
            atual.centavos += c.centavos;
            atual.base = atual.base ?? c.base;
        }
        else {
            mapa.set(chave, { ...c, campo: [...c.campo] });
        }
    }
    return mapa;
}

/** O que falta aplicar para sair de `aplicadas` e chegar em `novas`. */
export function diferenca(novas: Celula[], aplicadas: Celula[]): Celula[] {
    const alvo = somar(novas);
    for (const c of aplicadas) {
        const chave = chaveDaCelula(c);
        const atual = alvo.get(chave);
        if (atual) {
            atual.centavos -= c.centavos;
        }
        else {
            alvo.set(chave, { doc: c.doc, campo: [...c.campo], centavos: -c.centavos });
        }
    }
    return [...alvo.values()].filter((c) => c.centavos !== 0);
}

/** Objeto aninhado `{a: {b: valor}}` a partir de `["a", "b"]`. */
export function aninhar(campo: string[], valor: unknown): Record<string, unknown> {
    return campo.reduceRight<unknown>((dentro, chave) => ({ [chave]: dentro }), valor) as Record<string, unknown>;
}

/**
 * Saldo de uma conta no fim de `dia`, a partir do saldo inicial e do
 * movimento por dia.
 */
export function saldoEm(
    conta: Pick<Conta, "saldoInicialCentavos" | "saldoInicialData">,
    deltasPorDia: Record<DiaChave, number>,
    dia: DiaChave
): number {
    const inicial = !conta.saldoInicialData || conta.saldoInicialData <= dia ? conta.saldoInicialCentavos : 0;
    return Object.entries(deltasPorDia)
        .filter(([d]) => d <= dia)
        .reduce((soma, [, delta]) => soma + delta, inicial);
}
