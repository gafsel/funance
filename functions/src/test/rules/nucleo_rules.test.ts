import { readFileSync } from "fs";
import { resolve } from "path";

import {
    assertFails,
    assertSucceeds,
    initializeTestEnvironment,
    RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { deleteDoc, doc, getDoc, setDoc, setLogLevel } from "firebase/firestore";

/** Rules do modelo novo (`espacos/`), contra o emulador. */

const RULES_PATH = resolve(__dirname, "../../../../firebase/firestore.rules");
const ESPACO = "esp-rules";
const DONO = "u-dono";
const CONVIDADO = "u-convidado";
const DE_FORA = "u-fora";

const lancamento = (extra: Record<string, unknown> = {}) => ({
    tipo: "saida", descricao: "Mercado", previstoCentavos: null, realizadoCentavos: 1000,
    data: "2026-03-12", dataEfetiva: "2026-03-12", situacao: "efetivado", contaId: "cc", ...extra,
});

describe("rules do Funances 2", () => {
    let env: RulesTestEnvironment;
    const db = (uid: string) => env.authenticatedContext(uid).firestore();
    const caminho = (resto: string) => `espacos/${ESPACO}/${resto}`;

    beforeAll(async () => {
        setLogLevel("error");
        env = await initializeTestEnvironment({
            projectId: "demo-funances-nucleo",
            firestore: { rules: readFileSync(RULES_PATH, "utf8") },
        });
    });

    beforeEach(async () => {
        await env.clearFirestore();
        await env.withSecurityRulesDisabled(async (ctx) => {
            const admin = ctx.firestore();
            await setDoc(doc(admin, `espacos/${ESPACO}`), { nome: "Casa", tipo: "pessoal" });
            await setDoc(doc(admin, caminho(`membros/${DONO}`)), { papel: "dono" });
            await setDoc(doc(admin, caminho(`membros/${CONVIDADO}`)), { papel: "convidado" });
            await setDoc(doc(admin, caminho("resumos/2026-03")), { saidas: { realizadoCentavos: 1 } });
            await setDoc(doc(admin, caminho("aplicados/l_x")), { celulas: [] });
            await setDoc(doc(admin, caminho("contas/cc")), { nome: "Corrente", tipo: "corrente", saldoInicialCentavos: 0 });
        });
    });

    afterAll(async () => {
        await env.cleanup();
    });

    it("membro lê e grava lançamento; quem é de fora não", async () => {
        await assertSucceeds(setDoc(doc(db(CONVIDADO), caminho("lancamentos/a")), lancamento()));
        await assertSucceeds(getDoc(doc(db(DONO), caminho("lancamentos/a"))));
        await assertSucceeds(deleteDoc(doc(db(DONO), caminho("lancamentos/a"))));
        await assertFails(setDoc(doc(db(DE_FORA), caminho("lancamentos/b")), lancamento()));
        await assertFails(getDoc(doc(db(DE_FORA), `espacos/${ESPACO}`)));
    });

    it("recusa lançamento malformado", async () => {
        const gravar = (extra: Record<string, unknown>) => setDoc(doc(db(DONO), caminho("lancamentos/x")), lancamento(extra));
        await assertFails(gravar({ realizadoCentavos: 10.5 }));
        await assertFails(gravar({ realizadoCentavos: -1 }));
        await assertFails(gravar({ data: "12/03/2026" }));
        await assertFails(gravar({ tipo: "despesa" }));
        await assertFails(gravar({ realizadoCentavos: null }));
        await assertFails(gravar({ tipo: "transferencia" }));
        await assertFails(gravar({ tipo: "transferencia", contaDestinoId: "cc" }));
        await assertSucceeds(gravar({ tipo: "transferencia", contaDestinoId: "poupanca" }));
        await assertSucceeds(gravar({ situacao: "previsto", realizadoCentavos: null, dataEfetiva: null, previstoCentavos: 500 }));
    });

    it("o que o servidor calcula é só leitura; o registro do motor é fechado", async () => {
        await assertSucceeds(getDoc(doc(db(DONO), caminho("resumos/2026-03"))));
        await assertFails(setDoc(doc(db(DONO), caminho("resumos/2026-03")), { saidas: {} }));
        await assertFails(setDoc(doc(db(DONO), caminho("faturas/f1")), { totalCentavos: 0 }));
        await assertFails(setDoc(doc(db(DONO), caminho("contas/cc/dias/2026-03-12")), { deltaCentavos: 1 }));
        await assertFails(getDoc(doc(db(DONO), caminho("aplicados/l_x"))));
    });

    it("conta é validada e não pode ser apagada; espaço e membros são do servidor", async () => {
        await assertSucceeds(setDoc(doc(db(DONO), caminho("contas/nova")), { nome: "Cartão", tipo: "cartao", saldoInicialCentavos: -100, diaFechamento: 5 }));
        await assertFails(setDoc(doc(db(DONO), caminho("contas/ruim")), { nome: "X", tipo: "poupanca", saldoInicialCentavos: 0 }));
        await assertFails(deleteDoc(doc(db(DONO), caminho("contas/cc"))));
        await assertFails(setDoc(doc(db(DONO), `espacos/${ESPACO}`), { nome: "Outro" }));
        await assertFails(setDoc(doc(db(DONO), caminho(`membros/${DE_FORA}`)), { papel: "dono" }));
    });

    it("membro grava nas coleções de apoio", async () => {
        await assertSucceeds(setDoc(doc(db(CONVIDADO), caminho("categorias/c1")), { nome: "Mercado", tipo: "saida" }));
        await assertSucceeds(setDoc(doc(db(CONVIDADO), caminho("metas/m1")), { nome: "Reserva" }));
        await assertFails(setDoc(doc(db(DE_FORA), caminho("categorias/c2")), { nome: "X", tipo: "saida" }));
        await assertFails(setDoc(doc(db(CONVIDADO), caminho("qualquer/c2")), { a: 1 }));
    });
});
