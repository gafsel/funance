/**
 * Transforma um workspace do app antigo no modelo do Funances 2.
 *
 * É uma função pura: recebe os documentos antigos e devolve os novos, mais a
 * lista do que não pôde ser convertido. Ela não adivinha: um lançamento que
 * não cabe no modelo novo fica de fora e aparece em `problemas`, com o valor,
 * para ser decidido antes da carga.
 */

import { toDateKey } from "../../../core/utils/date_key";
import { toCents } from "../../../core/utils/money";
import { InvoiceService } from "../../finance/domain/services/invoice.service";
import {
    COLECOES,
    Categoria,
    Conta,
    Espaco,
    Fatura,
    Fechamento,
    ItemEntrada,
    Lancamento,
    Membro,
    Meta,
    Serie,
    TipoConta,
    TipoLancamento,
    TipoMeta,
    idDaFatura,
} from "../domain/models/modelo";
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

export interface Ocorrencia {
    /** Código estável, para agrupar no relatório. */
    codigo: string;
    /** Documento antigo, ex.: `installments/abc`. */
    origem: string;
    mensagem: string;
    centavos?: number;
}

export interface Transformado {
    espaco: Espaco;
    membros: Record<string, Membro>;
    contas: Record<string, Conta>;
    lancamentos: Record<string, Lancamento>;
    series: Record<string, Serie>;
    faturas: Record<string, Fatura>;
    categorias: Record<string, Categoria>;
    metas: Record<string, Meta>;
    entrada: Record<string, ItemEntrada>;
    fechamentos: Record<string, Fechamento>;
    /** Ficou de fora da migração. Cada item precisa de decisão. */
    problemas: Ocorrencia[];
    /** Foi convertido com uma escolha que vale conferir. */
    avisos: Ocorrencia[];
}

const TIPO_CONTA: Record<string, TipoConta> = {
    checking: "corrente",
    investment: "investimento",
    creditCard: "cartao",
    debt: "divida",
};

const TIPO_LANCAMENTO: Record<string, TipoLancamento> = {
    income: "entrada",
    expense: "saida",
    transfer: "transferencia",
};

const TIPO_META: Record<string, TipoMeta> = {
    saveMoney: "juntar",
    payDebt: "quitar",
    reduceCreditCard: "reduzirCartao",
    reduceExpense: "reduzirGasto",
};

const GRUPO: Record<string, Categoria["grupo"]> = {
    essential: "essencial",
    comfort: "conforto",
    investment: "investimento",
};

const texto = (v: unknown): string | null => (typeof v === "string" && v.length > 0 ? v : null);

const slug = (s: string): string =>
    s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "sem-nome";

export function transformar(dados: DadosAntigos, opcoes: { hoje: string }): Transformado {
    const problemas: Ocorrencia[] = [];
    const avisos: Ocorrencia[] = [];
    const mesAtual = opcoes.hoje.slice(0, 7);

    // ---- Espaço e membros -------------------------------------------------
    const ws = dados.workspace;
    const espaco: Espaco = {
        nome: texto(ws.name) ?? "Sem nome",
        tipo: ws.type === "business" ? "empresa" : "pessoal",
        criadoEm: instante(ws.createdAt) ?? new Date(0),
        migradoDe: { projeto: dados.projeto, workspaceId: dados.workspaceId },
    };

    const membros: Record<string, Membro> = {};
    (Array.isArray(ws.members) ? ws.members : []).forEach((uid: unknown, i: number) => {
        if (typeof uid === "string") membros[uid] = { papel: i === 0 ? "dono" : "convidado", entrada: null };
    });

    // ---- Categorias -------------------------------------------------------
    const categorias: Record<string, Categoria> = {};
    const paraCategoria = (c: Bruto, arquivada: boolean): Categoria => ({
        nome: texto(c.name) ?? "Sem nome",
        tipo: c.type === "income" ? "entrada" : "saida",
        icone: texto(c.icon),
        cor: texto(c.color),
        grupo: GRUPO[c.allocation] ?? null,
        limiteMensalCentavos: null,
        arquivada,
    });

    for (const [id, c] of Object.entries(dados.categories)) {
        if (ehCategoriaDeSistema(id, c)) continue;
        categorias[id] = paraCategoria(c, c.isDeleted === true);
    }

    const porNome = new Map<string, string[]>();
    for (const [id, c] of Object.entries(categorias)) {
        const chave = `${c.tipo}|${slug(c.nome)}`;
        porNome.set(chave, [...(porNome.get(chave) ?? []), id]);
    }
    for (const [chave, ids] of porNome) {
        const ativas = ids.filter((id) => !categorias[id].arquivada);
        if (ativas.length > 1) {
            avisos.push({
                codigo: "categoria-duplicada",
                origem: ativas.map((id) => `categories/${id}`).join(", "),
                mensagem: `${ativas.length} categorias ativas com o mesmo nome e tipo (${chave}); foram mantidas separadas`,
            });
        }
    }

    /** Resolve a cópia de categoria embutida num documento antigo. */
    const categoriaDe = (copia: Bruto | undefined | null, origem: string): string | null => {
        if (!copia || ehCategoriaDeSistema(copia.id, copia)) return null;
        const id = texto(copia.id);
        if (id && categorias[id]) return id;

        if (id) {
            categorias[id] = paraCategoria(copia, true);
            avisos.push({
                codigo: "categoria-apagada",
                origem,
                mensagem: `categoria "${categorias[id].nome}" (${id}) não existe mais; recriada como arquivada`,
            });
            return id;
        }

        // Id vazio: procura uma categoria de mesmo nome e tipo; se não houver, cria.
        const tipo = copia.type === "income" ? "entrada" : "saida";
        const nome = texto(copia.name);
        if (!nome) return null;
        const candidatas = porNome.get(`${tipo}|${slug(nome)}`) ?? [];
        const escolhida = candidatas.find((c) => !categorias[c].arquivada) ?? candidatas[0];
        if (escolhida) return escolhida;

        const novoId = `mig-${slug(nome)}-${tipo}`;
        if (!categorias[novoId]) {
            categorias[novoId] = paraCategoria(copia, false);
            porNome.set(`${tipo}|${slug(nome)}`, [novoId]);
            avisos.push({
                codigo: "categoria-sem-id",
                origem,
                mensagem: `categoria "${nome}" estava sem id; criada como ${novoId}`,
            });
        }
        return novoId;
    };

    // Limite mensal: o planejamento que cobre o mês atual.
    const limites = new Map<string, number[]>();
    for (const [id, p] of Object.entries(dados.plannings)) {
        const categoriaId = categoriaDe(p.category, `category_planning/${id}`);
        if (!categoriaId) continue;
        const inicio = texto(p.startMonth) ?? "0000-00";
        const fim = texto(p.endMonth) ?? "9999-12";
        if (inicio <= mesAtual && mesAtual <= fim) {
            limites.set(categoriaId, [...(limites.get(categoriaId) ?? []), centavos(p, "amount")]);
        }
    }
    for (const [categoriaId, valores] of limites) {
        categorias[categoriaId].limiteMensalCentavos = valores.reduce((a, b) => a + b, 0);
        if (valores.length > 1) {
            avisos.push({
                codigo: "limite-somado",
                origem: `categories/${categoriaId}`,
                mensagem: `${valores.length} planejamentos valem para ${mesAtual}; o limite ficou com a soma`,
            });
        }
    }

    // ---- Contas -----------------------------------------------------------
    const contas: Record<string, Conta> = {};
    for (const [id, a] of Object.entries(dados.accounts)) {
        const tipo = TIPO_CONTA[a.runtimeType];
        if (!tipo) {
            problemas.push({ codigo: "conta-tipo", origem: `accounts/${id}`, mensagem: `tipo de conta desconhecido: ${a.runtimeType}` });
            continue;
        }
        contas[id] = {
            nome: texto(a.name) ?? "Sem nome",
            tipo,
            icone: texto(a.icon),
            cor: texto(a.color),
            banco: a.bankLogo && a.bankLogo !== "none" ? String(a.bankLogo) : null,
            saldoInicialCentavos: 0,
            saldoInicialData: null,
            arquivada: a.isDeleted === true,
            limiteCentavos: tipo === "cartao" && temValor(a, "limit") ? centavos(a, "limit") : null,
            diaFechamento: tipo === "cartao" && Number.isInteger(a.closingDay) ? a.closingDay : null,
            diaVencimento: tipo === "cartao" && Number.isInteger(a.dueDay) ? a.dueDay : null,
            taxaJuros: typeof a.interestRate === "number" ? a.interestRate : null,
            donos: Array.isArray(a.ownerIds) ? a.ownerIds.filter((d: unknown) => typeof d === "string") : [],
        };
    }

    // O saldo inicial vem da parcela sintética, que é o que de fato entrou no
    // saldo do app antigo.
    const comSaldoInicial = new Set<string>();
    for (const [id, inst] of Object.entries(dados.installments)) {
        if (!ehSaldoInicial(inst) || !estaPaga(inst)) continue;
        const { debito, credito } = lados(inst);
        const contaId = credito[0] ?? debito[0];
        const conta = contaId ? contas[contaId] : undefined;
        if (!conta) {
            problemas.push({ codigo: "saldo-inicial-sem-conta", origem: `installments/${id}`, mensagem: "saldo inicial de uma conta que não existe", centavos: centavos(inst, "paidAmount") });
            continue;
        }
        const valor = centavos(inst, "paidAmount") * (credito.length > 0 ? 1 : -1);
        conta.saldoInicialCentavos += valor;
        conta.saldoInicialData = diaDe(inst.paidDate) ?? diaDe(inst.dueDate);
        if (comSaldoInicial.has(contaId)) {
            avisos.push({ codigo: "saldo-inicial-repetido", origem: `installments/${id}`, mensagem: "a conta tinha mais de um saldo inicial; os valores foram somados" });
        }
        comSaldoInicial.add(contaId);
    }

    // ---- Faturas ----------------------------------------------------------
    const parcelasPorOrder = new Map<string, string[]>();
    for (const [id, inst] of Object.entries(dados.installments)) {
        if (typeof inst.orderId === "string") {
            parcelasPorOrder.set(inst.orderId, [...(parcelasPorOrder.get(inst.orderId) ?? []), id]);
        }
    }

    const faturas: Record<string, Fatura> = {};
    const faturaDaOrder = new Map<string, string>();
    for (const [id, order] of Object.entries(dados.orders)) {
        if (order.isInvoice !== true) continue;
        const cartaoId = lados(order).credito[0];
        const conta = cartaoId ? contas[cartaoId] : undefined;
        const parcelasDaFatura = (parcelasPorOrder.get(id) ?? []).map((p) => dados.installments[p]);
        const parcela = parcelasDaFatura.find((p) => p.status !== "removed");
        // Fatura cuja parcela foi removida já não valia no app antigo.
        if (!parcela && parcelasDaFatura.length > 0) continue;
        const vencimentoData = instante(parcela?.dueDate);
        if (!conta || !vencimentoData) {
            problemas.push({ codigo: "fatura-incompleta", origem: `orders/${id}`, mensagem: "fatura sem cartão ou sem parcela com vencimento", centavos: centavos(order, "amount") });
            continue;
        }
        const dias = { closingDay: conta.diaFechamento ?? undefined, dueDay: conta.diaVencimento ?? undefined };
        const janela = InvoiceService.calculateInvoiceCycleRange(vencimentoData, dias);
        const vencimento = toDateKey(vencimentoData);
        const faturaId = idDaFatura(cartaoId, vencimento);
        faturas[faturaId] = {
            contaId: cartaoId,
            vencimento,
            fechamento: diaDe(order.closingDate) ?? toDateKey(janela.closingDate),
            inicio: diaDe(order.cycleStart) ?? toDateKey(janela.start),
            fim: diaDe(order.cycleEnd) ?? toDateKey(janela.end),
            totalCentavos: 0,
            pagoCentavos: 0,
        };
        faturaDaOrder.set(id, faturaId);
    }

    // ---- Lançamentos ------------------------------------------------------
    const lancamentos: Record<string, Lancamento> = {};
    for (const [id, inst] of Object.entries(dados.installments)) {
        const origem = `installments/${id}`;
        if (ehSaldoInicial(inst)) continue;

        const paga = estaPaga(inst);
        // Fatura em aberto é a própria entidade fatura; só o pagamento vira lançamento.
        if (inst.isInvoice === true && !paga) continue;

        const valorDoProblema = paga ? centavos(inst, "paidAmount") : centavos(inst, "amount");
        const recusar = (codigo: string, mensagem: string) => {
            // Parcela removida não entra em conta nenhuma: não é perda.
            if (inst.status === "removed") return;
            problemas.push({ codigo, origem, mensagem, centavos: valorDoProblema });
        };

        const tipo = TIPO_LANCAMENTO[inst.type];
        const data = diaDe(inst.dueDate);
        if (!tipo || !data) {
            recusar("lancamento-ilegivel", `tipo (${inst.type}) ou vencimento ausente`);
            continue;
        }

        const { debito, credito } = lados(inst);
        let contaId: string | undefined;
        let contaDestinoId: string | null = null;
        if (tipo === "saida" && debito.length === 1 && credito.length === 0) contaId = debito[0];
        else if (tipo === "entrada" && credito.length === 1 && debito.length === 0) contaId = credito[0];
        else if (tipo === "transferencia" && debito.length === 1 && credito.length === 1) {
            contaId = debito[0];
            contaDestinoId = credito[0];
        }
        if (!contaId) {
            recusar("lancamento-contas", `${inst.type} com contas fora do esperado: ${JSON.stringify(inst.accounts ?? {})}`);
            continue;
        }
        if (!contas[contaId] || (contaDestinoId && !contas[contaDestinoId])) {
            recusar("lancamento-conta-inexistente", "cita uma conta que não existe mais");
            continue;
        }

        const planejado = centavos(inst, "amount");
        const realizado = paga && temValor(inst, "paidAmount") ? centavos(inst, "paidAmount") : null;
        if (planejado < 0 || (realizado !== null && realizado < 0)) {
            recusar("lancamento-negativo", "valor negativo");
            continue;
        }

        const dataEfetiva = paga ? diaDe(inst.paidDate) : null;
        if (paga && (realizado === null || !dataEfetiva)) {
            avisos.push({ codigo: "pago-sem-valor-ou-data", origem, mensagem: "marcado como pago, mas sem valor pago ou sem data; não entra em saldo (como no app antigo)" });
        }

        const limiteFuturo = `${Number(opcoes.hoje.slice(0, 4)) + 5}${opcoes.hoje.slice(4)}`;
        if (inst.status !== "removed" && (dataEfetiva ?? data) > limiteFuturo) {
            avisos.push({ codigo: "data-muito-no-futuro", origem, mensagem: `"${inst.description ?? ""}" está datado de ${dataEfetiva ?? data}; parece erro de digitação do ano`, centavos: valorDoProblema });
        }

        const order = typeof inst.orderId === "string" ? dados.orders[inst.orderId] : undefined;
        const emSerie = order && (order.installmentType === "installment" || order.installmentType === "recurring");
        const numero = Number.isInteger(inst.installmentNumber) ? inst.installmentNumber : null;
        const total = Number.isInteger(inst.installmentCount) ? inst.installmentCount : null;

        lancamentos[id] = {
            tipo,
            descricao: typeof inst.description === "string" ? inst.description : "",
            previstoCentavos: planejado === 0 && (paga || inst.unplannedReason === "born_paid") ? null : planejado,
            realizadoCentavos: realizado,
            data,
            dataEfetiva,
            situacao: inst.status === "removed" ? "cancelado" : (paga ? "efetivado" : "previsto"),
            contaId,
            contaDestinoId,
            categoriaId: tipo === "transferencia" ? null : categoriaDe(inst.category, origem),
            serieId: emSerie ? inst.orderId : null,
            parcela: numero !== null && total !== null ? { numero, total } : null,
            contraparteId: null,
            pagaFaturaId: inst.isInvoice === true ? (faturaDaOrder.get(inst.orderId) ?? idDaFatura(contaDestinoId ?? contaId, data)) : null,
            origem: typeof inst.orderId === "string" && inst.orderId.startsWith("rec-") ? "extrato" : "manual",
            loteId: null,
            autorId: null,
        };
    }

    // ---- Séries -----------------------------------------------------------
    const series: Record<string, Serie> = {};
    for (const [id, order] of Object.entries(dados.orders)) {
        const forma = order.installmentType === "installment" ? "parcelado" : (order.installmentType === "recurring" ? "recorrente" : null);
        if (!forma || order.isInvoice === true) continue;

        const parcelas = (parcelasPorOrder.get(id) ?? [])
            .filter((p) => lancamentos[p] && lancamentos[p].situacao !== "cancelado")
            .map((p) => lancamentos[p])
            .sort((a, b) => a.data.localeCompare(b.data));
        if (parcelas.length === 0) continue;

        const valorDe = (l: Lancamento) => l.previstoCentavos ?? l.realizadoCentavos ?? 0;
        const ultima = parcelas[parcelas.length - 1];
        series[id] = {
            forma,
            frequencia: "mensal",
            tipo: ultima.tipo,
            descricao: typeof order.description === "string" ? order.description : ultima.descricao,
            valorCentavos: forma === "recorrente" ? valorDe(ultima) : parcelas.reduce((soma, l) => soma + valorDe(l), 0),
            parcelas: forma === "parcelado" ? (Number.isInteger(order.installmentCount) ? order.installmentCount : parcelas.length) : null,
            diaVencimento: Number.isInteger(order.dueDay) ? order.dueDay : Number(ultima.data.slice(8, 10)),
            inicioMes: texto(order.startMonth) ?? parcelas[0].data.slice(0, 7),
            geradoAte: forma === "recorrente" ? (diaDe(order.lastGeneratedDueDate) ?? ultima.data) : null,
            contaId: ultima.contaId,
            contaDestinoId: ultima.contaDestinoId,
            categoriaId: ultima.categoriaId,
            ativa: order.status === "active",
        };
    }
    for (const [id, l] of Object.entries(lancamentos)) {
        if (l.serieId && !series[l.serieId]) lancamentos[id] = { ...l, serieId: null };
    }

    // ---- Metas ------------------------------------------------------------
    const metas: Record<string, Meta> = {};
    for (const [id, g] of Object.entries(dados.goals)) {
        const tipo = TIPO_META[g.runtimeType];
        const prazo = diaDe(g.deadline);
        const inicio = diaDe(g.startDate ?? g.start_date);
        if (!tipo || !prazo || !inicio) {
            problemas.push({ codigo: "meta-ilegivel", origem: `goals/${id}`, mensagem: `tipo (${g.runtimeType}), início ou prazo ausente`, centavos: centavos(g, "targetAmount") });
            continue;
        }
        if (tipo === "reduzirGasto" && !categoriaDe(g.category, `goals/${id}`)) {
            avisos.push({ codigo: "meta-sem-categoria", origem: `goals/${id}`, mensagem: `meta "${g.name ?? ""}" de reduzir gasto não aponta para nenhuma categoria; o progresso fica em zero` });
        }
        metas[id] = {
            nome: texto(g.name) ?? "Sem nome",
            tipo,
            alvoCentavos: centavos(g, "targetAmount"),
            inicio,
            prazo,
            parcelaMensalCentavos: null,
            contaId: texto(g.accountId),
            categoriaId: tipo === "reduzirGasto" ? categoriaDe(g.category, `goals/${id}`) : null,
            adiamentos: 0,
            arquivada: g.isDeleted === true,
            resultado: g.outcome === "success" ? "atingida" : (g.outcome === "failed" ? "nao_atingida" : null),
            encerradaEm: diaDe(g.completedAt ?? g.failedAt),
        };
    }

    // ---- Caixa de entrada -------------------------------------------------
    const entrada: Record<string, ItemEntrada> = {};
    for (const [id, t] of Object.entries(dados.automaticas)) {
        if (t.isConsolidated === true || t.isIgnored === true) continue;
        const data = diaDe(t.date);
        if (!data) {
            problemas.push({ codigo: "entrada-sem-data", origem: `automatic_transactions/${id}`, mensagem: "transação automática sem data" });
            continue;
        }
        entrada[id] = {
            descricao: typeof t.description === "string" ? t.description : "",
            valorCentavos: Math.abs(toCents(t.amount)),
            data,
            tipo: TIPO_LANCAMENTO[t.type] ?? "saida",
            origem: "notificacao",
            situacao: "pendente",
            sugestao: {
                contaId: texto(t.accountId) && contas[t.accountId] ? t.accountId : null,
                categoriaId: texto(t.categoryId) && categorias[t.categoryId] ? t.categoryId : null,
            },
            loteId: null,
            bruto: { packageName: t.packageName ?? null, originNotificationId: t.originNotificationId ?? null },
        };
    }

    // ---- Conciliações antigas, só como histórico ---------------------------
    const fechamentos: Record<string, Fechamento> = {};
    for (const [id, r] of Object.entries(dados.reconciliations)) {
        const quando = instante(r.createdAt);
        fechamentos[`antigo-${id}`] = {
            mes: quando ? toDateKey(quando).slice(0, 7) : "0000-00",
            situacao: "historico",
            extratoCentavos: {},
            fechadoPor: null,
            fechadoEm: quando,
            historico: {
                confirmados: r.confirmedMatchesCount ?? null,
                processados: r.totalTransactionsProcessed ?? null,
                criados: r.createdTransactionsCount ?? null,
            },
        };
    }

    return { espaco, membros, contas, lancamentos, series, faturas, categorias, metas, entrada, fechamentos, problemas, avisos };
}

/** Os documentos novos, por caminho relativo ao espaço. */
export function documentos(t: Transformado): Record<string, Record<string, unknown>> {
    const docs: Record<string, Record<string, unknown>> = {};
    const por = (colecao: string, itens: Record<string, object>) => {
        for (const [id, dados] of Object.entries(itens)) docs[`${colecao}/${id}`] = dados as Record<string, unknown>;
    };
    por(COLECOES.membros, t.membros);
    por(COLECOES.contas, t.contas);
    por(COLECOES.lancamentos, t.lancamentos);
    por(COLECOES.series, t.series);
    por(COLECOES.faturas, t.faturas);
    por(COLECOES.categorias, t.categorias);
    por(COLECOES.metas, t.metas);
    por(COLECOES.entrada, t.entrada);
    por(COLECOES.fechamentos, t.fechamentos);
    return docs;
}
