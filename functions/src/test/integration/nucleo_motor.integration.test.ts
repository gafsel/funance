import * as admin from "firebase-admin";
import * as fs from "fs";
import * as os from "os";
import * as path from "path";

import { COLECOES, RAIZ } from "../../features/nucleo/domain/models/modelo";
import { MotorService } from "../../features/nucleo/domain/services/motor.service";
import { ReconstrucaoService } from "../../features/nucleo/domain/services/reconstrucao.service";
import { migrarWorkspace, parseArgs } from "../../scripts/migrar_funances2";
import { workspaceAntigo } from "../fixtures/nucleo_workspace_antigo";

/**
 * Motor e reconstrução do Funances 2 contra o emulador.
 *
 * O emulador não dispara gatilhos: o teste grava o documento e chama o motor,
 * como o gatilho faria. A reconstrução é o oráculo: depois de qualquer
 * sequência de gravações, ela não pode achar divergência.
 */
describe("motor do Funances 2", () => {
    let firestore: admin.firestore.Firestore;
    let motor: MotorService;
    let reconstrucao: ReconstrucaoService;
    const espacoId = `esp-motor-${Date.now()}`;
    const espaco = () => firestore.collection(RAIZ).doc(espacoId);

    const base = {
        tipo: "saida", descricao: "Mercado", previstoCentavos: null, realizadoCentavos: 1000,
        data: "2026-03-12", dataEfetiva: "2026-03-12", situacao: "efetivado", contaId: "cc",
        contaDestinoId: null, categoriaId: "mercado", origem: "manual",
    };

    const gravar = async (id: string, dados: Record<string, unknown> | null) => {
        const ref = espaco().collection(COLECOES.lancamentos).doc(id);
        if (dados) await ref.set(dados);
        else await ref.delete();
        return motor.processarLancamento(espacoId, id);
    };
    const ler = async (caminho: string) => (await firestore.doc(`${espaco().path}/${caminho}`).get()).data();

    beforeAll(async () => {
        if (admin.apps.length === 0) admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
        firestore = admin.firestore();
        motor = new MotorService(firestore);
        reconstrucao = new ReconstrucaoService(firestore);

        await espaco().set({ nome: "Teste", tipo: "pessoal" });
        await espaco().collection(COLECOES.contas).doc("cc").set({ nome: "Corrente", tipo: "corrente", saldoInicialCentavos: 0 });
        await espaco().collection(COLECOES.contas).doc("cartao").set({
            nome: "Cartão", tipo: "cartao", diaFechamento: 5, diaVencimento: 10,
            saldoInicialCentavos: -5000, saldoInicialData: "2026-03-01",
        });
        await motor.processarConta(espacoId, "cc");
        await motor.processarConta(espacoId, "cartao");
    });

    afterAll(async () => {
        await firestore.recursiveDelete(espaco());
    });

    it("aplica um lançamento em saldo e resumo", async () => {
        expect((await gravar("a", base)).alteradas).toBe(4);
        expect(await ler("contas/cc/dias/2026-03-12")).toEqual({ deltaCentavos: -1000 });
        expect(await ler("resumos/2026-03")).toEqual({
            categorias: { mercado: { realizadoCentavos: 1000 } },
            saidas: { realizadoCentavos: 1000 },
            contas: { cc: { deltaCentavos: -1000 } },
        });
    });

    it("o mesmo evento entregue de novo não soma duas vezes", async () => {
        expect((await motor.processarLancamento(espacoId, "a")).alteradas).toBe(0);
        expect(await ler("contas/cc/dias/2026-03-12")).toEqual({ deltaCentavos: -1000 });
    });

    it("editar valor e data move o efeito", async () => {
        await gravar("a", { ...base, realizadoCentavos: 2500, dataEfetiva: "2026-04-02" });
        expect(await ler("contas/cc/dias/2026-03-12")).toEqual({ deltaCentavos: 0 });
        expect(await ler("contas/cc/dias/2026-04-02")).toEqual({ deltaCentavos: -2500 });
        expect((await ler("resumos/2026-04"))?.categorias.mercado.realizadoCentavos).toBe(2500);
    });

    it("compra no cartão e dívida inicial entram na fatura; pagamento soma em pago", async () => {
        expect(await ler("faturas/cartao_2026-03-10")).toMatchObject({
            contaId: "cartao", vencimento: "2026-03-10", inicio: "2026-02-05", fim: "2026-03-04", totalCentavos: 5000,
        });
        await gravar("b", { ...base, contaId: "cartao", realizadoCentavos: 700, dataEfetiva: "2026-03-02", data: "2026-03-02" });
        expect((await ler("faturas/cartao_2026-03-10"))?.totalCentavos).toBe(5700);

        await gravar("p", {
            ...base, tipo: "transferencia", contaId: "cc", contaDestinoId: "cartao", categoriaId: null,
            realizadoCentavos: 5700, dataEfetiva: "2026-03-10", data: "2026-03-10", pagaFaturaId: "cartao_2026-03-10",
        });
        expect(await ler("faturas/cartao_2026-03-10")).toMatchObject({ totalCentavos: 5700, pagoCentavos: 5700 });
    });

    it("cancelar e apagar desfazem o efeito", async () => {
        await gravar("b", { ...base, contaId: "cartao", realizadoCentavos: 700, dataEfetiva: "2026-03-02", situacao: "cancelado" });
        expect((await ler("faturas/cartao_2026-03-10"))?.totalCentavos).toBe(5000);
        await gravar("a", null);
        expect(await ler("contas/cc/dias/2026-04-02")).toEqual({ deltaCentavos: 0 });
        expect((await espaco().collection(COLECOES.aplicados).doc("l_a").get()).exists).toBe(false);
    });

    it("documento ilegível não derruba o motor nem contribui", async () => {
        expect((await gravar("ruim", { tipo: "saida", realizadoCentavos: "dez" })).alteradas).toBe(0);
    });

    it("depois de uma sequência qualquer de gravações, a reconstrução não acha divergência", async () => {
        let semente = 42;
        const sorteio = (n: number) => {
            semente = (semente * 1103515245 + 12345) % 2147483648;
            return semente % n;
        };
        const dia = () => `2026-0${3 + sorteio(3)}-${String(1 + sorteio(28)).padStart(2, "0")}`;

        for (let passo = 0; passo < 80; passo++) {
            const id = `r${sorteio(15)}`;
            if (sorteio(6) === 0) {
                await gravar(id, null);
                continue;
            }
            const tipo = ["saida", "entrada", "transferencia"][sorteio(3)];
            const contaId = ["cc", "cartao"][sorteio(2)];
            const efetivado = sorteio(4) !== 0;
            await gravar(id, {
                tipo,
                descricao: "x",
                previstoCentavos: sorteio(2) ? 100 * (1 + sorteio(50)) : null,
                realizadoCentavos: efetivado ? 100 * (1 + sorteio(50)) : null,
                data: dia(),
                dataEfetiva: efetivado ? dia() : null,
                situacao: efetivado ? "efetivado" : (sorteio(5) === 0 ? "cancelado" : "previsto"),
                contaId,
                contaDestinoId: tipo === "transferencia" ? (contaId === "cc" ? "cartao" : "cc") : null,
                categoriaId: ["mercado", "lazer", null][sorteio(3)],
                origem: "manual",
            });
        }

        const resultado = await reconstrucao.reconstruir(espacoId, { aplicar: false });
        expect(resultado.divergencias).toEqual([]);
        expect(resultado.ilegiveis).toEqual(["ruim"]);
    });

    it("a reconstrução corrige um derivado adulterado e deixa o motor coerente", async () => {
        await firestore.doc(`${espaco().path}/resumos/2026-03`).set({ saidas: { realizadoCentavos: 999999 } }, { merge: true });
        await firestore.doc(`${espaco().path}/contas/cc/dias/2020-01-01`).set({ deltaCentavos: 123 });

        const antes = await reconstrucao.reconstruir(espacoId, { aplicar: false });
        expect(antes.divergencias.length).toBe(2);

        await reconstrucao.reconstruir(espacoId, { aplicar: true });
        expect((await reconstrucao.reconstruir(espacoId, { aplicar: false })).divergencias).toEqual([]);

        // O motor continua aplicando só a diferença depois da reconstrução.
        expect((await motor.processarLancamento(espacoId, "r1")).alteradas).toBe(0);
        await gravar("novo", base);
        expect((await reconstrucao.reconstruir(espacoId, { aplicar: false })).divergencias).toEqual([]);
    });
});

describe("carga da migração", () => {
    let firestore: admin.firestore.Firestore;
    const workspaceId = `w-mig-${Date.now()}`;
    const pasta = fs.mkdtempSync(path.join(os.tmpdir(), "relatorios-"));

    beforeAll(async () => {
        if (admin.apps.length === 0) admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
        firestore = admin.firestore();

        // Semeia o workspace antigo no próprio emulador.
        const dados = workspaceAntigo();
        const ws = firestore.collection("workspaces").doc(workspaceId);
        await ws.set(dados.workspace);
        const colecoes: [string, Record<string, Record<string, unknown>>][] = [
            ["accounts", dados.accounts], ["orders", dados.orders], ["installments", dados.installments],
            ["categories", dados.categories], ["category_planning", dados.plannings],
            ["automatic_transactions", dados.automaticas], ["reconciliations", dados.reconciliations],
            ["period_summaries", dados.resumos],
        ];
        const limpar = (doc: Record<string, unknown>) => JSON.parse(JSON.stringify(doc, (_, v) => v), (_, v) =>
            (typeof v === "string" && /^\d{4}-\d{2}-\d{2}T[\d:.]+Z$/.test(v) ? new Date(v) : v));
        for (const [nome, docs] of colecoes) {
            for (const [id, doc] of Object.entries(docs)) await ws.collection(nome).doc(id).set(limpar(doc));
        }
        for (const [contaId, dias] of Object.entries(dados.saldos)) {
            for (const [dia, doc] of Object.entries(dias)) {
                await ws.collection("accounts").doc(contaId).collection("balance").doc(dia).set(doc);
            }
        }
    });

    afterAll(async () => {
        await firestore.recursiveDelete(firestore.collection("workspaces").doc(workspaceId));
        await firestore.recursiveDelete(firestore.collection(RAIZ).doc(workspaceId));
        fs.rmSync(pasta, { recursive: true, force: true });
    });

    const opcoes = (extra: string[]) => parseArgs([
        "--origem=demo-antigo", "--destino=demo-novo", `--workspace=${workspaceId}`, `--relatorios=${pasta}`,
        "--hoje=2026-01-25", ...extra,
    ]);

    it("simulação escreve o relatório e não grava nada no destino", async () => {
        const resumo = await migrarWorkspace(firestore, null, workspaceId, opcoes([]), () => undefined);
        expect(resumo).toMatchObject({ problemas: 1, semExplicacao: 0, carregado: false });
        expect(fs.readFileSync(path.join(pasta, `${workspaceId}.md`), "utf8")).toContain("lancamento-contas");
        expect((await firestore.collection(RAIZ).doc(workspaceId).get()).exists).toBe(false);
    });

    it("com problema pendente, não carrega sem a flag explícita", async () => {
        const resumo = await migrarWorkspace(firestore, firestore, workspaceId, opcoes(["--aplicar"]), () => undefined);
        expect(resumo.carregado).toBe(false);
        expect((await firestore.collection(RAIZ).doc(workspaceId).get()).exists).toBe(false);
    });

    it("carrega, reconstrói os derivados e pode ser repetida", async () => {
        for (let vez = 0; vez < 2; vez++) {
            const resumo = await migrarWorkspace(
                firestore, firestore, workspaceId, opcoes(["--aplicar", "--mesmo-com-diferencas"]), () => undefined);
            expect(resumo.carregado).toBe(true);
        }
        const espaco = firestore.collection(RAIZ).doc(workspaceId);
        expect((await espaco.get()).data()).toMatchObject({ nome: "Casa", migradoDe: { workspaceId } });
        expect((await espaco.collection("lancamentos").get()).size).toBe(3);
        expect((await espaco.collection("contas").doc("cc").collection("dias").doc("2026-01-05").get()).data())
            .toEqual({ deltaCentavos: 500000 });
        expect((await espaco.collection("faturas").doc("cartao_2026-02-10").get()).data())
            .toMatchObject({ totalCentavos: 20000, pagoCentavos: 0, inicio: "2026-01-05" });
        // O workspace antigo continua como estava.
        expect((await firestore.collection("workspaces").doc(workspaceId).collection("installments").get()).size).toBe(6);
    });

    it("recusa sobrescrever um espaço que não veio da migração", async () => {
        const espaco = firestore.collection(RAIZ).doc(workspaceId);
        await espaco.set({ nome: "Criado no app novo", tipo: "pessoal" });
        await expect(migrarWorkspace(
            firestore, firestore, workspaceId, opcoes(["--aplicar", "--mesmo-com-diferencas"]), () => undefined
        )).rejects.toThrow("não veio desta migração");
    });
});
