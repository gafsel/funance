import * as admin from "firebase-admin";

import { COLECOES, RAIZ } from "../../features/nucleo/domain/models/modelo";
import { AvisosService } from "../../features/nucleo/domain/services/avisos.service";

/**
 * Avisos contra o emulador: o que é gravado, para quem vai e o que não se
 * repete. O envio é um dublê que anota o que recebeu.
 */
describe("avisos do Funances 2", () => {
    let firestore: admin.firestore.Firestore;
    let servico: AvisosService;
    const sufixo = Date.now();
    const espacoId = `esp-avisos-${sufixo}`;
    const [ana, bia] = [`ana-${sufixo}`, `bia-${sufixo}`];
    const hoje = "2026-11-20";
    const envios: { tokens: string[]; titulo: string; texto: string }[] = [];
    let mortos: string[] = [];
    const espaco = () => firestore.collection(RAIZ).doc(espacoId);
    const usuario = (uid: string) => firestore.collection("usuarios").doc(uid);

    beforeAll(async () => {
        if (admin.apps.length === 0) admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
        firestore = admin.firestore();
        servico = new AvisosService(firestore, async (tokens, titulo, texto) => {
            envios.push({ tokens, titulo, texto });
            return mortos;
        });

        await espaco().set({ nome: "Casa", tipo: "pessoal" });
        await espaco().collection(COLECOES.membros).doc(ana).set({ uid: ana, papel: "dono" });
        await espaco().collection(COLECOES.membros).doc(bia).set({ uid: bia, papel: "convidado" });
        await usuario(ana).set({ aparelhos: { a1: { token: "tok-ana-1" }, a2: { token: "tok-ana-2" } } });
        // A Bia desligou o aviso de vencimentos.
        await usuario(bia).set({ avisos: { vencimentos: false }, aparelhos: { b1: { token: "tok-bia" } } });

        await espaco().collection(COLECOES.contas).doc("cc").set({ nome: "Nubank", tipo: "corrente" });
        await espaco().collection(COLECOES.contas).doc("cartao").set({ nome: "Cartão Nubank", tipo: "cartao" });
        const lancamentos = espaco().collection(COLECOES.lancamentos);
        await lancamentos.doc("antigo").set({
            tipo: "saida", descricao: "Mercado", realizadoCentavos: 1000, data: "2026-11-10", dataEfetiva: "2026-11-10",
            situacao: "efetivado", contaId: "cc",
        });
        await lancamentos.doc("internet").set({
            tipo: "saida", descricao: "Internet", previstoCentavos: 11990, data: hoje, dataEfetiva: null,
            situacao: "previsto", contaId: "cc",
        });
        await lancamentos.doc("assinatura").set({
            tipo: "saida", descricao: "Assinatura", previstoCentavos: 2190, data: hoje, dataEfetiva: null,
            situacao: "previsto", contaId: "cartao",
        });
        await espaco().collection(COLECOES.faturas).doc("cartao_2026-11-20").set({
            contaId: "cartao", vencimento: hoje, fechamento: "2026-11-15", inicio: "2026-10-16", fim: "2026-11-15",
            totalCentavos: 41200, pagoCentavos: 0,
        });
    });

    afterAll(async () => {
        await firestore.recursiveDelete(espaco());
        await usuario(ana).delete();
        await usuario(bia).delete();
    });

    it("de manhã grava os avisos e manda a cada membro o que ele quer receber", async () => {
        const novos = await servico.manha(espacoId, hoje);
        expect(novos.map((a) => a.id).sort()).toEqual(["semLancar-2026-11-20", "vencimentos-2026-11-20"]);

        const gravado = (await espaco().collection(COLECOES.avisos).doc("vencimentos-2026-11-20").get()).data();
        expect(gravado?.texto).toBe("A pagar: Internet (R$ 119,90) e Fatura Cartão Nubank (R$ 412,00). Ao pagar, marque no app.");

        const paraAna = envios.filter((e) => e.tokens.includes("tok-ana-1"));
        expect(paraAna.map((e) => e.titulo).sort()).toEqual(["2 vencimentos hoje · Casa", "Faz tempo que você não lança · Casa"]);
        expect(paraAna[0].tokens).toEqual(["tok-ana-1", "tok-ana-2"]);
        const paraBia = envios.filter((e) => e.tokens.includes("tok-bia"));
        expect(paraBia.map((e) => e.titulo)).toEqual(["Faz tempo que você não lança · Casa"]);
    });

    it("rodar de novo no mesmo dia não manda nada", async () => {
        const antes = envios.length;
        expect(await servico.manha(espacoId, hoje)).toEqual([]);
        expect(envios.length).toBe(antes);
    });

    it("aparelho que não existe mais sai do cadastro", async () => {
        mortos = ["tok-ana-2"];
        await servico.manha(espacoId, "2026-11-21");
        mortos = [];
        expect(Object.keys((await usuario(ana).get()).get("aparelhos"))).toEqual(["a1"]);
    });

    it("sexta: avisa do limite estourado no estilo de vida", async () => {
        await espaco().collection(COLECOES.categorias).doc("restaurantes").set({
            nome: "Restaurantes", tipo: "saida", grupo: "conforto", limiteMensalCentavos: 50000, arquivada: false,
        });
        await espaco().collection(COLECOES.resumos).doc("2026-11").set({ categorias: { restaurantes: { realizadoCentavos: 62000 } } });
        const novos = await servico.fimDeSemana(espacoId, hoje);
        expect(novos.map((a) => a.titulo)).toEqual(["Fim de semana com limite estourado"]);
        expect(await servico.fimDeSemana(espacoId, hoje)).toEqual([]);
    });
});
