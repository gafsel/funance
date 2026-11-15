/**
 * Semeia os emuladores locais com um usuário e um espaço de exemplo, para
 * abrir o app do Funances 2 sem tocar em nenhum projeto real.
 *
 * Só roda contra emuladores: recusa se as variáveis dos emuladores não
 * estiverem definidas.
 *
 * Uso (com os emuladores no ar):
 *   cd functions && npm run build
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
 *     node lib/scripts/semear_emulador.js
 *
 * Login de teste: e-mail e senha abaixo (existem só no emulador).
 */

import * as admin from "firebase-admin";
import { shiftDateKey, toDateKey } from "../core/utils/date_key";
import { shiftMonthKey } from "../core/utils/month_key";
import { Lancamento, RAIZ } from "../features/nucleo/domain/models/modelo";
import { CATEGORIAS_PADRAO } from "../features/nucleo/domain/services/espaco.service";
import { ReconstrucaoService } from "../features/nucleo/domain/services/reconstrucao.service";
import { vencimentoNoMes } from "../features/nucleo/domain/services/series";

export const EMAIL_DE_TESTE = "teste@funances.test";
export const EMAIL_SEM_ESPACO = "nova@funances.test";
export const EMAIL_DA_SEGUNDA_PESSOA = "barbara@funances.test";
export const SENHA_DE_TESTE = "funances-teste";
const PROJETO = "demo-funances";

async function main(): Promise<void> {
    if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
        throw new Error("defina FIRESTORE_EMULATOR_HOST e FIREBASE_AUTH_EMULATOR_HOST: este script só roda contra emuladores");
    }
    admin.initializeApp({ projectId: PROJETO });
    const db = admin.firestore();

    let uid: string;
    try {
        uid = (await admin.auth().getUserByEmail(EMAIL_DE_TESTE)).uid;
    }
    catch {
        uid = (await admin.auth().createUser({ email: EMAIL_DE_TESTE, password: SENHA_DE_TESTE, displayName: "Pessoa de Teste" })).uid;
    }

    // Um segundo usuário, sem espaço nenhum, para testar o começo guiado.
    try {
        await admin.auth().getUserByEmail(EMAIL_SEM_ESPACO);
    }
    catch {
        await admin.auth().createUser({ email: EMAIL_SEM_ESPACO, password: SENHA_DE_TESTE, displayName: "Pessoa Nova" });
    }

    const hoje = toDateKey(new Date());
    const mes = hoje.slice(0, 7);
    const dia = (n: number) => vencimentoNoMes(mes, n);

    for (const [id, nome, tipo] of [["casa", "Casa de teste", "pessoal"], ["loja", "Loja de teste", "empresa"]]) {
        const espaco = db.collection(RAIZ).doc(id);
        await db.recursiveDelete(espaco);
        await espaco.set({ nome, tipo, criadoEm: new Date() });
        await espaco.collection("membros").doc(uid).set({ uid, papel: "dono", entrada: null, nome: "Pessoa de Teste", foto: null });
    }

    // Segunda pessoa na casa: o caso de duas pessoas com conta no mesmo banco.
    let bia: string;
    try {
        bia = (await admin.auth().getUserByEmail(EMAIL_DA_SEGUNDA_PESSOA)).uid;
    }
    catch {
        bia = (await admin.auth().createUser({ email: EMAIL_DA_SEGUNDA_PESSOA, password: SENHA_DE_TESTE, displayName: "Bárbara de Teste" })).uid;
    }
    await db.collection(RAIZ).doc("casa").collection("membros").doc(bia)
        .set({ uid: bia, papel: "convidado", entrada: null, nome: "Bárbara de Teste", foto: null });

    const casa = db.collection(RAIZ).doc("casa");
    const conta = (id: string, dados: Record<string, unknown>) => casa.collection("contas").doc(id).set({
        icone: null, cor: null, banco: null, saldoInicialCentavos: 0, saldoInicialData: null, arquivada: false,
        limiteCentavos: null, diaFechamento: null, diaVencimento: null, taxaJuros: null, donos: [uid], ...dados,
    });
    const inicio = shiftMonthKey(mes, -2) + "-01";
    await conta("azul", { nome: "Nubank", tipo: "corrente", banco: "nubank", saldoInicialCentavos: 320000, saldoInicialData: inicio });
    await conta("roxo", { nome: "Cartão Nubank", tipo: "cartao", banco: "nubank", limiteCentavos: 500000, diaFechamento: 5, diaVencimento: 10 });
    await conta("nubia", { nome: "Nubank", tipo: "corrente", banco: "nubank", donos: [bia], saldoInicialCentavos: 150000, saldoInicialData: inicio });
    await conta("cartaobia", { nome: "Cartão Nubank", tipo: "cartao", banco: "nubank", donos: [bia], limiteCentavos: 300000, diaFechamento: 5, diaVencimento: 10 });
    await conta("itau", { nome: "Itaú conjunta", tipo: "corrente", banco: "itau", donos: [uid, bia], saldoInicialCentavos: 90000, saldoInicialData: inicio });
    await conta("cartaoitau", { nome: "Cartão Itaú", tipo: "cartao", banco: "itau", limiteCentavos: 400000, diaFechamento: 20, diaVencimento: 27 });
    await conta("reserva", { nome: "Reserva", tipo: "investimento", banco: "xp", donos: [uid, bia], saldoInicialCentavos: 800000, saldoInicialData: inicio });

    for (const [id, nome, tipo, grupo, icone, cor] of CATEGORIAS_PADRAO.pessoal) {
        await casa.collection("categorias").doc(id).set({ nome, tipo, icone, cor, grupo, limiteMensalCentavos: id === "lazer" ? 30000 : null, arquivada: false });
    }

    await casa.collection("metas").doc("reserva").set({
        nome: "Reserva de emergência", tipo: "juntar", alvoCentavos: 2000000, inicio: `${mes}-01`, prazo: `${shiftMonthKey(mes, 12)}-01`,
        parcelaMensalCentavos: 60000, contaId: "reserva", categoriaId: null, adiamentos: 0, arquivada: false, resultado: null, encerradaEm: null,
    });

    const base: Lancamento = {
        tipo: "saida", descricao: "", previstoCentavos: null, realizadoCentavos: null, data: hoje, dataEfetiva: null,
        situacao: "previsto", contaId: "azul", contaDestinoId: null, categoriaId: null, serieId: null, parcela: null,
        contraparteId: null, pagaFaturaId: null, origem: "manual", loteId: null, autorId: uid,
    };
    const feito = (descricao: string, centavos: number, quando: string, extra: Partial<Lancamento> = {}): Lancamento =>
        ({ ...base, descricao, realizadoCentavos: centavos, data: quando, dataEfetiva: quando, situacao: "efetivado", ...extra });
    const agendado = (descricao: string, centavos: number, quando: string, extra: Partial<Lancamento> = {}): Lancamento =>
        ({ ...base, descricao, previstoCentavos: centavos, data: quando, ...extra });

    const ontem = shiftDateKey(hoje, -1);
    const lancamentos: Record<string, Lancamento> = {
        salario: feito("Salário", 650000, dia(5), { tipo: "entrada", categoriaId: "salario" }),
        aluguel: feito("Aluguel", 210000, dia(6), { categoriaId: "moradia", serieId: "aluguel" }),
        mercado1: feito("Mercado da semana", 38450, dia(8), { categoriaId: "mercado", contaId: "roxo" }),
        uber: feito("Uber", 2390, ontem, { categoriaId: "transporte", contaId: "roxo" }),
        cinema: feito("Cinema", 6400, ontem, { categoriaId: "lazer" }),
        guardar: feito("Guardar na reserva", 60000, dia(7), { tipo: "transferencia", contaDestinoId: "reserva" }),
        luz: agendado("Conta de luz", 18900, shiftDateKey(hoje, 3), { categoriaId: "moradia" }),
        internet: agendado("Internet", 11990, shiftDateKey(hoje, -2), { categoriaId: "moradia" }),
        freela: agendado("Freela do site", 120000, shiftDateKey(hoje, 6), { tipo: "entrada", categoriaId: "salario" }),
        mesPassado: feito("Mercado", 41200, shiftMonthKey(mes, -1) + "-20", { categoriaId: "mercado", contaId: "roxo" }),
        farmaciaBia: feito("Farmácia", 8900, dia(9), { categoriaId: "saude", contaId: "cartaobia" }),
        restaurante: feito("Jantar", 14500, dia(10), { categoriaId: "restaurantes", contaId: "cartaoitau" }),
        lazerPassado: feito("Show", 22000, shiftMonthKey(mes, -1) + "-12", { categoriaId: "lazer" }),
        aluguelPassado: feito("Aluguel", 210000, shiftMonthKey(mes, -1) + "-06", { categoriaId: "moradia" }),
        salarioPassado: feito("Salário", 650000, shiftMonthKey(mes, -1) + "-05", { tipo: "entrada", categoriaId: "salario" }),
        mercadoRetrasado: feito("Mercado", 36000, shiftMonthKey(mes, -2) + "-18", { categoriaId: "mercado" }),
        aluguelRetrasado: feito("Aluguel", 210000, shiftMonthKey(mes, -2) + "-06", { categoriaId: "moradia" }),
        salarioRetrasado: feito("Salário", 650000, shiftMonthKey(mes, -2) + "-05", { tipo: "entrada", categoriaId: "salario" }),
    };
    // Um mês cheio na conta principal, para ver as listas com volume real.
    const variados: [string, string, number][] = [
        ["Padaria", "mercado", 1850], ["Uber", "transporte", 2390], ["Farmácia", "saude", 4720], ["Almoço", "restaurantes", 3900],
        ["Feira", "mercado", 8640], ["Streaming", "assinaturas", 3990], ["Estacionamento", "transporte", 1500],
    ];
    const diaDeHoje = Number(hoje.slice(8, 10));
    for (let i = 0; i < 48; i++) {
        const [descricao, categoriaId, centavos] = variados[i % variados.length];
        lancamentos[`cheio${i}`] = feito(descricao, centavos + i * 37, dia(1 + (i % diaDeHoje)), { categoriaId });
    }
    for (let i = 0; i < 9; i++) {
        lancamentos[`agendado${i}`] = agendado(`Parcela ${i + 1}`, 12000 + i * 500, shiftDateKey(hoje, 2 + i), { categoriaId: "compras" });
    }

    for (const [id, l] of Object.entries(lancamentos)) {
        await casa.collection("lancamentos").doc(id).set(l);
    }
    await casa.collection("series").doc("aluguel").set({
        forma: "recorrente", frequencia: "mensal", tipo: "saida", descricao: "Aluguel", valorCentavos: 210000, parcelas: null,
        diaVencimento: 6, inicioMes: mes, geradoAte: dia(6), contaId: "azul", contaDestinoId: null, categoriaId: "moradia", ativa: true,
    });

    // ---- Empresa de exemplo --------------------------------------------------
    const loja = db.collection(RAIZ).doc("loja");
    await loja.collection("contas").doc("caixa").set({
        nome: "Conta PJ", tipo: "corrente", icone: null, cor: null, banco: null, saldoInicialCentavos: 1200000,
        saldoInicialData: shiftMonthKey(mes, -1) + "-01", arquivada: false, limiteCentavos: null, diaFechamento: null,
        diaVencimento: null, taxaJuros: null, donos: [uid],
    });
    for (const [id, nome, tipo, grupo, icone, cor] of CATEGORIAS_PADRAO.empresa) {
        await loja.collection("categorias").doc(id).set({ nome, tipo, icone, cor, grupo, limiteMensalCentavos: null, arquivada: false });
    }
    await loja.collection("contrapartes").doc("acme").set({ nome: "Acme", tipo: "cliente" });
    await loja.collection("contrapartes").doc("papelaria").set({ nome: "Papelaria Central", tipo: "fornecedor" });
    const daLoja: Record<string, Lancamento> = {
        venda1: feito("Projeto de site", 900000, dia(3), { tipo: "entrada", categoriaId: "servicos", contaId: "caixa", contraparteId: "acme" }),
        fornecedor1: feito("Material de escritório", 85000, dia(4), { categoriaId: "fornecedores", contaId: "caixa", contraparteId: "papelaria" }),
        sistema: feito("Sistema de notas", 19900, dia(6), { categoriaId: "ferramentas", contaId: "caixa" }),
        prolabore: feito("Pró-labore", 400000, dia(5), { categoriaId: "pro-labore", contaId: "caixa" }),
        receberVencido: agendado("Suporte de outubro", 150000, shiftDateKey(hoje, -9), { tipo: "entrada", categoriaId: "servicos", contaId: "caixa", contraparteId: "acme" }),
        receber: agendado("Manutenção mensal", 250000, shiftDateKey(hoje, 12), { tipo: "entrada", categoriaId: "servicos", contaId: "caixa", contraparteId: "acme" }),
        pagar: agendado("Reposição de estoque", 320000, shiftDateKey(hoje, 5), { categoriaId: "fornecedores", contaId: "caixa", contraparteId: "papelaria" }),
        aluguel: agendado("Aluguel da sala", 280000, shiftDateKey(hoje, 16), { categoriaId: "aluguel-e-estrutura", contaId: "caixa" }),
    };
    for (const [id, l] of Object.entries(daLoja)) {
        await loja.collection("lancamentos").doc(id).set(l);
    }

    await new ReconstrucaoService(db).reconstruir("casa", { aplicar: true });
    await new ReconstrucaoService(db).reconstruir("loja", { aplicar: true });
    console.log(`Emulador semeado. Usuário de teste: ${EMAIL_DE_TESTE}`);
}

if (require.main === module) {
    main().catch((error) => {
        console.error(error instanceof Error ? error.message : error);
        process.exit(1);
    });
}
