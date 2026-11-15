/**
 * Progresso de uma meta, calculado a partir dos lançamentos. Não é guardado:
 * quem precisa do número chama esta função.
 */

import { Conta, DiaChave, Lancamento, Meta, SEM_CATEGORIA } from "../models/modelo";
import { saldoEm } from "./contribuicoes";

export interface BaseDasMetas {
    contas: Record<string, Conta>;
    lancamentos: Lancamento[];
    /** Movimento por dia de cada conta. */
    deltas: Record<string, Record<DiaChave, number>>;
}

/** Movimento por dia de cada conta, direto dos lançamentos efetivados. */
export function deltasPorConta(lancamentos: Lancamento[]): Record<string, Record<DiaChave, number>> {
    const deltas: Record<string, Record<DiaChave, number>> = {};
    const somar = (contaId: string, dia: DiaChave, centavos: number) => {
        deltas[contaId] = deltas[contaId] ?? {};
        deltas[contaId][dia] = (deltas[contaId][dia] ?? 0) + centavos;
    };
    for (const l of lancamentos) {
        if (l.situacao !== "efetivado" || l.realizadoCentavos === null || !l.dataEfetiva) continue;
        if (l.tipo === "entrada") {
            somar(l.contaId, l.dataEfetiva, l.realizadoCentavos);
        }
        else {
            somar(l.contaId, l.dataEfetiva, -l.realizadoCentavos);
            if (l.tipo === "transferencia" && l.contaDestinoId) somar(l.contaDestinoId, l.dataEfetiva, l.realizadoCentavos);
        }
    }
    return deltas;
}

export function progressoDaMeta(meta: Meta, base: BaseDasMetas, hoje: DiaChave): number {
    const efetivados = base.lancamentos.filter(
        (l) => l.situacao === "efetivado" && l.realizadoCentavos !== null && l.dataEfetiva !== null
    );

    if (meta.tipo === "reduzirGasto") {
        // Meta de reduzir gasto sem categoria não mede nada.
        if (!meta.categoriaId) return 0;
        const categoria = meta.categoriaId;
        const de = meta.inicio.slice(0, 7);
        const ate = meta.prazo.slice(0, 7);
        return efetivados
            .filter((l) => l.tipo !== "transferencia" && (l.categoriaId ?? SEM_CATEGORIA) === categoria)
            .filter((l) => (l.dataEfetiva as string).slice(0, 7) >= de && (l.dataEfetiva as string).slice(0, 7) <= ate)
            .reduce((soma, l) => soma + (l.realizadoCentavos as number), 0);
    }

    const conta = meta.contaId ? base.contas[meta.contaId] : undefined;
    if (!meta.contaId || !conta) return 0;
    const deltas = base.deltas[meta.contaId] ?? {};

    if (meta.tipo === "reduzirCartao") {
        return efetivados
            .filter((l) => l.tipo !== "entrada" && l.contaId === meta.contaId && (l.dataEfetiva as string) >= meta.inicio)
            .reduce((soma, l) => soma + (l.realizadoCentavos as number), 0);
    }

    if (meta.tipo === "quitar") {
        return Math.max(0, saldoEm(conta, deltas, hoje) - saldoEm(conta, deltas, meta.inicio));
    }

    // juntar
    if (conta.tipo === "investimento") {
        return Math.max(0, saldoEm(conta, deltas, hoje));
    }
    return Object.entries(deltas)
        .filter(([dia]) => dia >= meta.inicio)
        .reduce((soma, [, delta]) => soma + delta, 0);
}
