/**
 * Avisos (notificações) de um espaço: o que vale a pena dizer hoje.
 *
 * Aqui só há regra pura: recebe o que foi lido do banco e devolve os avisos.
 * Quem lê, grava e envia é o `avisos.service`. O id do aviso é estável por
 * tipo e dia: rodar duas vezes não manda duas vezes.
 */

import { Categoria, Conta, DiaChave, Fatura, Lancamento, ResumoMes } from "../models/modelo";

export type TipoAviso = "semLancar" | "vencimentos" | "fimDeSemana";
export const TIPOS_DE_AVISO: TipoAviso[] = ["semLancar", "vencimentos", "fimDeSemana"];

export interface Aviso {
    id: string;
    tipo: TipoAviso;
    titulo: string;
    texto: string;
    dia: DiaChave;
}

/** Dias sem lançar a partir dos quais o app lembra, uma vez por dia. */
export const DIAS_SEM_LANCAR = 7;
/** Fração do limite a partir da qual a categoria está "perto". */
export const PERTO_DO_LIMITE = 0.8;

export const reais = (centavos: number): string => {
    const negativo = centavos < 0;
    const abs = Math.abs(Math.round(centavos));
    const inteiro = Math.floor(abs / 100).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".");
    return `${negativo ? "-" : ""}R$ ${inteiro},${(abs % 100).toString().padStart(2, "0")}`;
};

const diasEntre = (de: DiaChave, ate: DiaChave): number =>
    Math.round((Date.parse(`${ate}T00:00:00Z`) - Date.parse(`${de}T00:00:00Z`)) / 86_400_000);

/**
 * Uma semana ou mais sem nenhum lançamento feito: lembra de atualizar.
 * `ultimoDia` é a data do lançamento efetivado mais recente; nulo quando o
 * espaço ainda não tem nenhum (aí não há o que cobrar).
 */
export function avisoSemLancar(ultimoDia: DiaChave | null, hoje: DiaChave): Aviso | null {
    if (!ultimoDia) return null;
    const dias = diasEntre(ultimoDia, hoje);
    if (dias < DIAS_SEM_LANCAR) return null;
    return {
        id: `semLancar-${hoje}`,
        tipo: "semLancar",
        dia: hoje,
        titulo: "Faz tempo que você não lança",
        texto: `O último lançamento foi há ${dias} dias. Dois minutos para pôr em dia e o seu "livre para gastar" volta a valer.`,
    };
}

/**
 * O que vence hoje: contas a pagar e a receber fora do cartão, e faturas
 * fechadas ainda sem pagamento. Compra agendada no cartão não avisa: quem
 * vence é a fatura.
 */
export function avisoDeVencimentos(
    previstosDeHoje: Lancamento[],
    faturasDeHoje: Fatura[],
    contas: Record<string, Conta>,
    hoje: DiaChave,
): Aviso | null {
    const itens: { nome: string; centavos: number; receber: boolean }[] = [];
    for (const l of previstosDeHoje) {
        if (l.situacao !== "previsto" || l.data !== hoje || l.tipo === "transferencia") continue;
        if (contas[l.contaId]?.tipo === "cartao") continue;
        itens.push({ nome: l.descricao || "Sem descrição", centavos: l.previstoCentavos ?? 0, receber: l.tipo === "entrada" });
    }
    for (const f of faturasDeHoje) {
        // Fatura com pagamento registrado não está mais pendente.
        if (f.vencimento !== hoje || f.totalCentavos <= 0 || f.pagoCentavos > 0) continue;
        itens.push({ nome: `Fatura ${contas[f.contaId]?.nome ?? "do cartão"}`, centavos: f.totalCentavos, receber: false });
    }
    if (itens.length === 0) return null;

    const pagar = itens.filter((i) => !i.receber);
    const receber = itens.filter((i) => i.receber);
    const soma = (lista: typeof itens) => lista.reduce((s, i) => s + i.centavos, 0);
    const descrever = (lista: typeof itens) =>
        (lista.length <= 2
            ? lista.map((i) => `${i.nome} (${reais(i.centavos)})`).join(" e ")
            : `${lista.length} contas, ${reais(soma(lista))}`);
    const partes: string[] = [];
    if (pagar.length > 0) partes.push(`A pagar: ${descrever(pagar)}.`);
    if (receber.length > 0) partes.push(`A receber: ${descrever(receber)}.`);
    return {
        id: `vencimentos-${hoje}`,
        tipo: "vencimentos",
        dia: hoje,
        titulo: itens.length === 1 ? "Vence hoje" : `${itens.length} vencimentos hoje`,
        texto: `${partes.join(" ")} Ao pagar, marque no app.`,
    };
}

/**
 * Começo do fim de semana: o que do estilo de vida já está perto do limite
 * ou passou dele. Olha o limite de cada categoria e, se houver, o teto do
 * grupo inteiro (a parte da renda que a referência reserva para ele).
 */
export function avisoDeFimDeSemana(
    resumo: ResumoMes | null,
    categorias: Record<string, Categoria>,
    tetoDoGrupoCentavos: number | null,
    hoje: DiaChave,
): Aviso | null {
    const gasto = (id: string): number => resumo?.categorias?.[id]?.realizadoCentavos ?? 0;
    // Sem grupo definido conta como estilo de vida: é o grupo em que dá para mexer.
    const doGrupo = Object.entries(categorias)
        .filter(([, c]) => c.tipo === "saida" && !c.arquivada && (c.grupo === "conforto" || c.grupo === null || c.grupo === undefined));

    const passaram: string[] = [];
    const perto: string[] = [];
    for (const [id, c] of doGrupo) {
        const limite = c.limiteMensalCentavos ?? 0;
        if (limite <= 0) continue;
        const usado = gasto(id);
        if (usado >= limite) passaram.push(`${c.nome} (${reais(usado)} de ${reais(limite)})`);
        else if (usado >= limite * PERTO_DO_LIMITE) perto.push(`${c.nome} (${Math.round(usado * 100 / limite)}%)`);
    }

    const partes: string[] = [];
    if (passaram.length > 0) partes.push(`Já ${passaram.length === 1 ? "passou" : "passaram"} do limite: ${passaram.join(", ")}.`);
    if (perto.length > 0) partes.push(`Perto do limite: ${perto.join(", ")}.`);

    if (tetoDoGrupoCentavos && tetoDoGrupoCentavos > 0) {
        const total = doGrupo.reduce((s, [id]) => s + gasto(id), 0);
        if (total >= tetoDoGrupoCentavos) {
            partes.push(`O estilo de vida inteiro passou do teto do mês em ${reais(total - tetoDoGrupoCentavos)}.`);
        }
        else if (total >= tetoDoGrupoCentavos * PERTO_DO_LIMITE) {
            partes.push(`O estilo de vida usou ${Math.round(total * 100 / tetoDoGrupoCentavos)}% do teto do mês: restam ${reais(tetoDoGrupoCentavos - total)}.`);
        }
    }
    if (partes.length === 0) return null;
    return {
        id: `fimDeSemana-${hoje}`,
        tipo: "fimDeSemana",
        dia: hoje,
        titulo: passaram.length > 0 ? "Fim de semana com limite estourado" : "Fim de semana: atenção aos limites",
        texto: partes.join(" "),
    };
}

const REFERENCIAS: Record<string, number> = { "equilibrio": 30, "acelerar": 20, "fixo-alto": 20 };

/**
 * Teto mensal do estilo de vida: a parte da renda média dos meses fechados
 * que a referência escolhida reserva para o grupo. Nulo sem renda conhecida.
 */
export function tetoDoEstiloDeVida(rendasDosMesesFechados: number[], referencia: string | null | undefined): number | null {
    const comRenda = rendasDosMesesFechados.filter((r) => r > 0);
    if (comRenda.length === 0) return null;
    const media = Math.floor(comRenda.reduce((s, r) => s + r, 0) / comRenda.length);
    return Math.floor(media * (REFERENCIAS[referencia ?? ""] ?? REFERENCIAS.equilibrio) / 100);
}
