/**
 * Conferência da migração: compara os números do app antigo com os do modelo
 * novo, ao centavo.
 *
 * É pura: recebe os dados antigos e o resultado da transformação. Os números
 * novos saem de `calcularDerivados`, a mesma função que o motor e a
 * reconstrução usam, então o que é conferido aqui é o que o banco novo terá.
 *
 * Toda diferença cai num de dois grupos: explicada (com a causa) ou sem
 * explicação. A migração só está pronta quando o segundo grupo está vazio.
 */

import { toDateKey } from "../../../core/utils/date_key";
import { InvoiceService } from "../../finance/domain/services/invoice.service";
import { COLECOES, Lancamento, SEM_CATEGORIA, idDaFatura } from "../domain/models/modelo";
import { saldoEm } from "../domain/services/contribuicoes";
import { deltasPorConta, progressoDaMeta } from "../domain/services/metas";
import { calcularDerivados } from "../domain/services/reconstrucao.service";
import {
    Bruto,
    DadosAntigos,
    centavos,
    diaDe,
    ehCategoriaDeSistema,
    ehSaldoInicial,
    estaPaga,
    instante,
    lados,
    temValor,
} from "./dados_antigos";
import { Transformado } from "./transformar";

export interface Diferenca {
    chave: string;
    antigo: number;
    novo: number;
    /** Ausente = sem explicação. */
    causa?: string;
}

export interface Secao {
    nome: string;
    comparados: number;
    iguais: number;
    explicadas: Diferenca[];
    semExplicacao: Diferenca[];
}

export interface Conferencia {
    secoes: Secao[];
    semExplicacao: number;
}

class Coletor {
    readonly secao: Secao;
    constructor(nome: string) {
        this.secao = { nome, comparados: 0, iguais: 0, explicadas: [], semExplicacao: [] };
    }
    comparar(chave: string, antigo: number, novo: number, causa?: (diferenca: number) => string | undefined): void {
        this.secao.comparados++;
        if (antigo === novo) {
            this.secao.iguais++;
            return;
        }
        const explicacao = causa?.(novo - antigo);
        if (explicacao) this.secao.explicadas.push({ chave, antigo, novo, causa: explicacao });
        else this.secao.semExplicacao.push({ chave, antigo, novo });
    }
}

export function conferir(dados: DadosAntigos, novo: Transformado, opcoes: { hoje: string }): Conferencia {
    const derivados = calcularDerivados(novo.contas, novo.lancamentos);
    const celula = (doc: string, campo: string[]): number =>
        derivados.celulas.get(`${doc}#${campo.join("/")}`)?.centavos ?? 0;
    const lancamentos = Object.values(novo.lancamentos);
    const deltas = deltasPorConta(lancamentos);

    // Valor que ficou de fora, por parcela antiga.
    const recusadas = new Set(
        novo.problemas.filter((p) => p.origem.startsWith("installments/")).map((p) => p.origem.slice("installments/".length))
    );

    const secoes = [
        conferirSaldosRecalculados(dados, novo, deltas, recusadas),
        conferirSaldosGravados(dados, novo, deltas),
        conferirCategorias(dados, novo, celula),
        conferirFaturas(dados, novo, celula),
        conferirQuantidades(dados, novo, recusadas),
        conferirMetas(dados, novo, lancamentos, deltas, opcoes.hoje),
    ];

    return { secoes, semExplicacao: secoes.reduce((soma, s) => soma + s.semExplicacao.length, 0) };
}

type Deltas = Record<string, Record<string, number>>;

/**
 * Saldo final de cada conta, refeito a partir das parcelas antigas pela regra
 * do app antigo, contra o saldo final do modelo novo. Não depende dos saldos
 * gravados, então separa erro de migração de saldo antigo desatualizado.
 */
function conferirSaldosRecalculados(dados: DadosAntigos, novo: Transformado, deltas: Deltas, recusadas: Set<string>): Secao {
    const coletor = new Coletor("Saldo final por conta (refeito das parcelas antigas)");
    const antigo: Record<string, number> = {};
    const fora: Record<string, number> = {};

    for (const [id, inst] of Object.entries(dados.installments)) {
        if (!estaPaga(inst) || !inst.paidAmount || !inst.paidDate) continue;
        const valor = centavos(inst, "paidAmount");
        const { debito, credito } = lados(inst);
        for (const conta of credito) antigo[conta] = (antigo[conta] ?? 0) + valor;
        for (const conta of debito) antigo[conta] = (antigo[conta] ?? 0) - valor;
        if (recusadas.has(id)) {
            for (const conta of credito) fora[conta] = (fora[conta] ?? 0) + valor;
            for (const conta of debito) fora[conta] = (fora[conta] ?? 0) - valor;
        }
    }

    for (const [id, conta] of Object.entries(novo.contas)) {
        const total = conta.saldoInicialCentavos + Object.values(deltas[id] ?? {}).reduce((a, b) => a + b, 0);
        coletor.comparar(`${conta.nome} (${id})`, antigo[id] ?? 0, total, (dif) =>
            (fora[id] && dif === -fora[id] ? "lançamentos que ficaram de fora da migração (ver problemas)" : undefined));
    }
    return coletor.secao;
}

/** Saldo gravado em cada dia no app antigo contra o saldo novo no mesmo dia. */
function conferirSaldosGravados(dados: DadosAntigos, novo: Transformado, deltas: Deltas): Secao {
    const coletor = new Coletor("Saldo por conta e por dia (gravado no app antigo)");
    for (const [contaId, dias] of Object.entries(dados.saldos)) {
        const conta = novo.contas[contaId];
        if (!conta) continue;
        // Soma dos movimentos que o próprio app antigo gravou, dia a dia. Se
        // ela dá o valor novo e o acumulado gravado não, o errado é o acumulado.
        const ordenados = Object.entries(dias)
            .map(([docId, doc]) => ({ dia: typeof doc.dateKey === "string" ? doc.dateKey as string : docId, doc }))
            .sort((a, b) => a.dia.localeCompare(b.dia));
        let somaDosMovimentos = 0;
        let movimentosCompletos = true;
        for (const { dia, doc } of ordenados) {
            const semChave = typeof doc.dateKey !== "string";
            movimentosCompletos = movimentosCompletos && temValor(doc, "delta");
            somaDosMovimentos += centavos(doc, "delta");
            const somaAteAqui = somaDosMovimentos;
            const completo = movimentosCompletos;
            const novoSaldo = saldoEm(conta, deltas[contaId] ?? {}, dia);
            coletor.comparar(`${conta.nome} (${contaId}) em ${dia}`, centavos(doc, "balance"), novoSaldo, () => {
                if (completo && somaAteAqui === novoSaldo) {
                    return "acumulado antigo desatualizado: a soma dos movimentos gravados pelo próprio app antigo dá o valor novo";
                }
                return semChave ? "saldo antigo gravado com o dia em UTC (formato anterior à correção de fuso)" : undefined;
            });
        }
    }
    return coletor.secao;
}

/** Realizado e previsto por categoria e mês. */
function conferirCategorias(
    dados: DadosAntigos,
    novo: Transformado,
    celula: (doc: string, campo: string[]) => number
): Secao {
    const coletor = new Coletor("Total por categoria e mês");
    const vistos = new Set<string>();

    for (const [chave, resumo] of Object.entries(dados.resumos)) {
        if (resumo.runtimeType !== "month" && !/^\d{4}-\d{2}$/.test(chave)) continue;
        for (const [categoriaId, valores] of Object.entries((resumo.categories ?? {}) as Record<string, Bruto>)) {
            const doc = `${COLECOES.resumos}/${chave}`;
            const sistema = ehCategoriaDeSistema(categoriaId);
            const causaSistema = () => (categoriaId === "initial-balance" ?
                "saldo inicial deixa de ser lançamento e vira campo da conta" :
                "transferência para investimento ou dívida deixa de contar como categoria");

            vistos.add(`${chave}|${categoriaId}`);
            coletor.comparar(
                `${chave} · ${nomeDaCategoria(novo, categoriaId)} · realizado`,
                centavos(valores, "actualAmount"),
                celula(doc, ["categorias", categoriaId, "realizadoCentavos"]),
                sistema ? causaSistema : undefined
            );
            coletor.comparar(
                `${chave} · ${nomeDaCategoria(novo, categoriaId)} · previsto`,
                centavos(valores, "specificPlannedAmount"),
                celula(doc, ["categorias", categoriaId, "previstoCentavos"]),
                sistema ? causaSistema : undefined
            );
        }
    }

    // O que existe no novo e não existia no resumo antigo.
    const novos = new Map<string, number>();
    for (const l of Object.values(novo.lancamentos)) {
        if (l.tipo === "transferencia" || l.situacao === "cancelado") continue;
        const categoriaId = l.categoriaId ?? SEM_CATEGORIA;
        if (l.previstoCentavos !== null) {
            const k = `${l.data.slice(0, 7)}|${categoriaId}|previsto`;
            novos.set(k, (novos.get(k) ?? 0) + l.previstoCentavos);
        }
        if (l.situacao === "efetivado" && l.realizadoCentavos !== null && l.dataEfetiva) {
            const k = `${l.dataEfetiva.slice(0, 7)}|${categoriaId}|realizado`;
            novos.set(k, (novos.get(k) ?? 0) + l.realizadoCentavos);
        }
    }
    for (const [k, valor] of novos) {
        const [mes, categoriaId, lado] = k.split("|");
        if (vistos.has(`${mes}|${categoriaId}`) || valor === 0) continue;
        coletor.comparar(`${mes} · ${nomeDaCategoria(novo, categoriaId)} · ${lado}`, 0, valor, () => {
            if (categoriaId === SEM_CATEGORIA) return "lançamento sem categoria ficava fora do resumo antigo";
            if (categoriaId.startsWith("mig-")) return "categoria sem id ficava fora do resumo antigo";
            return undefined;
        });
    }
    return coletor.secao;
}

const nomeDaCategoria = (novo: Transformado, id: string): string =>
    (novo.categorias[id] ? `${novo.categorias[id].nome} (${id})` : id);

/** Total de cada fatura. */
function conferirFaturas(
    dados: DadosAntigos,
    novo: Transformado,
    celula: (doc: string, campo: string[]) => number
): Secao {
    const coletor = new Coletor("Total de cada fatura");

    // No app antigo, pagar a fatura com valor diferente do total joga a
    // diferença na fatura seguinte. No novo, cada fatura guarda total e pago.
    const transportado: Record<string, number> = {};
    for (const inst of Object.values(dados.installments)) {
        if (inst.isInvoice !== true || !estaPaga(inst) || !inst.paidAmount) continue;
        const cartaoId = lados(inst).credito[0];
        const pagoEm = instante(inst.paidDate);
        const conta = cartaoId ? dados.accounts[cartaoId] : undefined;
        if (!conta || !pagoEm) continue;
        const diferenca = centavos(inst, "paidAmount") - centavos(inst, "amount");
        if (diferenca === 0) continue;
        const destino = idDaFatura(cartaoId, toDateKey(InvoiceService.calculateInvoiceDueDate(pagoEm, conta)));
        transportado[destino] = (transportado[destino] ?? 0) - diferenca;
    }

    const antigas = new Map<string, number>();
    const duplicadas = new Set<string>();
    for (const [orderId, order] of Object.entries(dados.orders)) {
        if (order.isInvoice !== true) continue;
        const cartaoId = lados(order).credito[0];
        const vivas = Object.values(dados.installments).filter((i) => i.orderId === orderId && i.status !== "removed");
        const vencimento = diaDe(vivas[0]?.dueDate);
        if (!cartaoId || !vencimento) continue;
        const id = idDaFatura(cartaoId, vencimento);
        antigas.set(id, (antigas.get(id) ?? 0) + centavos(order, "amount"));
        if (vivas.length > 1) duplicadas.add(id);
    }

    // As compras de cada ciclo, somadas direto das parcelas antigas pela regra
    // do app antigo, sem passar pela transformação.
    const refeito: Record<string, number> = {};
    for (const inst of Object.values(dados.installments)) {
        if (inst.isInvoice === true || !estaPaga(inst) || !inst.paidAmount) continue;
        const pagoEm = instante(inst.paidDate);
        if (!pagoEm) continue;
        for (const [contaId, lado] of Object.entries(inst.accounts ?? {})) {
            const conta = dados.accounts[contaId];
            if (conta?.runtimeType !== "creditCard") continue;
            const id = idDaFatura(contaId, toDateKey(InvoiceService.calculateInvoiceDueDate(pagoEm, conta)));
            refeito[id] = (refeito[id] ?? 0) + centavos(inst, "paidAmount") * (lado === "debt" ? 1 : -1);
        }
    }

    const ids = new Set<string>([...antigas.keys()]);
    for (const c of calcularFaturasNovas(novo)) ids.add(c);

    for (const id of [...ids].sort()) {
        const total = celula(`${COLECOES.faturas}/${id}`, ["totalCentavos"]);
        const antigo = antigas.get(id);
        coletor.comparar(id, antigo ?? 0, total, (dif) => {
            const resto = dif + (transportado[id] ?? 0);
            if (transportado[id] && resto === 0) {
                return "diferença de pagamento da fatura anterior, que o app antigo somava nesta";
            }
            if (duplicadas.has(id)) {
                return "fatura antiga com mais de uma parcela para a mesma order (dado incoerente no app antigo)";
            }
            if (Math.abs(resto) <= 2) {
                return "até 2 centavos de arredondamento no total antigo, acumulado quando os valores eram guardados com casas decimais";
            }
            if ((refeito[id] ?? 0) === total) {
                return "total antigo desatualizado: as compras pagas do ciclo, somadas direto das parcelas antigas, dão o valor novo";
            }
            return undefined;
        });
    }
    return coletor.secao;
}

function calcularFaturasNovas(novo: Transformado): string[] {
    const { celulas } = calcularDerivados(novo.contas, novo.lancamentos);
    const prefixo = `${COLECOES.faturas}/`;
    return [...celulas.values()]
        .filter((c) => c.doc.startsWith(prefixo) && c.campo[0] === "totalCentavos")
        .map((c) => c.doc.slice(prefixo.length));
}

/** Quantidade de lançamentos por conta e por mês. */
function conferirQuantidades(dados: DadosAntigos, novo: Transformado, recusadas: Set<string>): Secao {
    const coletor = new Coletor("Quantidade de lançamentos por conta e mês");
    const antigo = new Map<string, number>();
    const fora = new Map<string, number>();
    const contar = (mapa: Map<string, number>, chave: string) => mapa.set(chave, (mapa.get(chave) ?? 0) + 1);

    for (const [id, inst] of Object.entries(dados.installments)) {
        if (inst.status === "removed" || ehSaldoInicial(inst)) continue;
        if (inst.isInvoice === true && !estaPaga(inst)) continue;
        const mes = (diaDe(inst.paidDate) ?? diaDe(inst.dueDate) ?? "0000-00-00").slice(0, 7);
        for (const contaId of Object.keys(inst.accounts ?? {})) {
            contar(antigo, `${contaId}|${mes}`);
            if (recusadas.has(id)) contar(fora, `${contaId}|${mes}`);
        }
    }

    const novoPorChave = new Map<string, number>();
    for (const l of Object.values(novo.lancamentos) as Lancamento[]) {
        if (l.situacao === "cancelado") continue;
        const mes = (l.dataEfetiva ?? l.data).slice(0, 7);
        contar(novoPorChave, `${l.contaId}|${mes}`);
        if (l.contaDestinoId) contar(novoPorChave, `${l.contaDestinoId}|${mes}`);
    }

    for (const chave of new Set([...antigo.keys(), ...novoPorChave.keys()])) {
        const [contaId, mes] = chave.split("|");
        const nome = novo.contas[contaId]?.nome ?? contaId;
        coletor.comparar(`${nome} · ${mes}`, antigo.get(chave) ?? 0, novoPorChave.get(chave) ?? 0, (dif) =>
            (fora.get(chave) && dif === -(fora.get(chave) as number) ?
                "lançamentos que ficaram de fora da migração (ver problemas)" : undefined));
    }
    return coletor.secao;
}

/** Progresso das metas em aberto. */
function conferirMetas(dados: DadosAntigos, novo: Transformado, lancamentos: Lancamento[], deltas: Deltas, hoje: string): Secao {
    const coletor = new Coletor("Progresso das metas em aberto");
    for (const [id, meta] of Object.entries(novo.metas)) {
        const antiga = dados.goals[id];
        if (!antiga || meta.arquivada || meta.resultado !== null) continue;
        coletor.comparar(
            `${meta.nome} (${id})`,
            centavos(antiga, "currentAmount"),
            progressoDaMeta(meta, { contas: novo.contas, lancamentos, deltas }, hoje),
            () => (meta.tipo === "reduzirGasto" && !antiga.category?.id && meta.categoriaId ?
                "a meta apontava para uma categoria sem id e não media nada; agora está ligada à categoria de mesmo nome" :
                undefined)
        );
    }
    return coletor.secao;
}

const reais = (c: number): string => (c / 100).toLocaleString("pt-BR", { style: "currency", currency: "BRL" });

/** Relatório em Markdown, para leitura humana. */
export function relatorio(conferencia: Conferencia, novo: Transformado, limitePorSecao = 40): string {
    const linhas: string[] = ["# Conferência da migração", ""];
    linhas.push(`Diferenças sem explicação: **${conferencia.semExplicacao}**. Problemas (ficaram de fora): **${novo.problemas.length}**. Avisos: **${novo.avisos.length}**.`, "");

    linhas.push("| Comparação | Comparados | Iguais | Explicadas | Sem explicação |", "|---|---:|---:|---:|---:|");
    for (const s of conferencia.secoes) {
        linhas.push(`| ${s.nome} | ${s.comparados} | ${s.iguais} | ${s.explicadas.length} | ${s.semExplicacao.length} |`);
    }
    linhas.push("");

    const listar = (titulo: string, itens: { chave: string; antigo: number; novo: number; causa?: string }[]) => {
        if (itens.length === 0) return;
        linhas.push(`### ${titulo}`, "", "| Item | Antigo | Novo | Diferença | Causa |", "|---|---:|---:|---:|---|");
        for (const d of itens.slice(0, limitePorSecao)) {
            linhas.push(`| ${d.chave} | ${reais(d.antigo)} | ${reais(d.novo)} | ${reais(d.novo - d.antigo)} | ${d.causa ?? ""} |`);
        }
        if (itens.length > limitePorSecao) linhas.push("", `… e mais ${itens.length - limitePorSecao}.`);
        linhas.push("");
    };

    for (const s of conferencia.secoes) {
        if (s.semExplicacao.length + s.explicadas.length === 0) continue;
        linhas.push(`## ${s.nome}`, "");
        listar("Sem explicação", s.semExplicacao);
        const porCausa = new Map<string, number>();
        for (const d of s.explicadas) porCausa.set(d.causa as string, (porCausa.get(d.causa as string) ?? 0) + 1);
        if (porCausa.size > 0) {
            linhas.push("### Explicadas", "");
            for (const [causa, n] of porCausa) linhas.push(`- ${n}: ${causa}`);
            linhas.push("");
            if (!s.nome.startsWith("Total por categoria")) listar("Explicadas, item a item", s.explicadas);
        }
    }

    const ocorrencias = (titulo: string, itens: Transformado["problemas"]) => {
        if (itens.length === 0) return;
        linhas.push(`## ${titulo}`, "");
        const porCodigo = new Map<string, Transformado["problemas"]>();
        for (const o of itens) porCodigo.set(o.codigo, [...(porCodigo.get(o.codigo) ?? []), o]);
        for (const [codigo, lista] of porCodigo) {
            const soma = lista.reduce((s, o) => s + (o.centavos ?? 0), 0);
            linhas.push(`### ${codigo} (${lista.length}${soma ? `, ${reais(soma)}` : ""})`, "");
            for (const o of lista.slice(0, limitePorSecao)) {
                linhas.push(`- \`${o.origem}\`: ${o.mensagem}${o.centavos ? ` (${reais(o.centavos)})` : ""}`);
            }
            if (lista.length > limitePorSecao) linhas.push(`- … e mais ${lista.length - limitePorSecao}.`);
            linhas.push("");
        }
    };
    ocorrencias("Problemas: ficaram de fora da migração", novo.problemas);
    ocorrencias("Avisos: convertidos com uma escolha a conferir", novo.avisos);

    return linhas.join("\n");
}
