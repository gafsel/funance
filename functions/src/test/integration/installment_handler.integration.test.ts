// ofx-js é ESM puro e não é transformado pelo ts-jest; é alcançado via
// container -> ai.service, mas não é exercitado por este teste.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

import * as admin from "firebase-admin";

import {
    handleInstallmentWritten,
    INSTALLMENT_DERIVED_FIELDS,
} from "../../features/finance/presentation/functions/installment_handler";
import { getChangedFields } from "../../core/utils/diff.utils";
import { FinanceRepositoryImpl } from "../../features/finance/data/repositories/finance.repository.impl";
import {
    AccountModel,
    AccountType,
    InstallmentStatus,
    InstallmentType,
    OrderModel,
    OrderStatus,
    OrderType,
    ReplicationCascade,
} from "../../features/finance/domain/models/finance.models";
import { CategoryModel, CategoryType } from "../../features/workspace/domain/models/category.model";
import { ExpectedIncomeService } from "../../features/finance/domain/services/expected_income.service";

/**
 * F1.1 — guarda por conteúdo no gatilho de parcela.
 *
 * O emulador do Firestore NÃO dispara triggers nos testes, então o segundo
 * evento (o eco da escrita de xp feita pelo próprio handler) é simulado
 * chamando `handleInstallmentWritten` com before = documento antes do xp e
 * after = documento depois do xp — exatamente o par que o Eventarc entregaria.
 */
const WORKSPACE_ID = `ws-handler-${Date.now()}`;
const ACCOUNT_ID = "acc-checking";
const ORDER_ID = "order-curso-2x";

const CATEGORY: CategoryModel = {
    id: "cat-educacao",
    name: "Educação",
    icon: "school",
    color: "#7E57C2",
    type: CategoryType.expense,
    isDeleted: false,
    allocation: "essential",
};

describe("Gatilho de parcela: guarda por conteúdo (integração com emulador)", () => {
    let firestore: admin.firestore.Firestore;
    let repository: FinanceRepositoryImpl;
    let installmentId: string;

    const installmentRef = () =>
        firestore.collection(`workspaces/${WORKSPACE_ID}/installments`).doc(installmentId);

    beforeAll(async () => {
        if (admin.apps.length === 0) {
            admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
            admin.firestore().settings({ ignoreUndefinedProperties: false });
        }

        firestore = admin.firestore();
        repository = new FinanceRepositoryImpl();

        const account: Omit<AccountModel, "id"> = {
            name: "Conta Corrente",
            icon: "account_balance",
            color: "#4CAF50",
            runtimeType: AccountType.checking,
            isDeleted: false,
            initialBalance: 0,
            initialBalanceDate: new Date(2025, 0, 1, 12),
        };
        await firestore.doc(`workspaces/${WORKSPACE_ID}/accounts/${ACCOUNT_ID}`).set(account);
        await firestore.doc(`workspaces/${WORKSPACE_ID}/categories/${CATEGORY.id}`).set(CATEGORY);

        const order: Omit<OrderModel, "id"> = {
            amount: 200,
            dueDay: 10,
            description: "Curso de inglês",
            startMonth: "2025-03",
            installmentCount: 2,
            installmentType: InstallmentType.installment,
            status: OrderStatus.active,
            type: OrderType.expense,
            accounts: { [ACCOUNT_ID]: "debt" },
            accountIds: [ACCOUNT_ID],
            category: CATEGORY,
        };
        await repository.createOrder(WORKSPACE_ID, order, ORDER_ID);

        await repository.createInstallments(WORKSPACE_ID, [
            {
                orderId: ORDER_ID,
                amount: 100,
                dueDate: new Date(2025, 2, 10, 12),
                description: "Curso de inglês",
                status: InstallmentStatus.pending,
                type: OrderType.expense,
                installmentType: InstallmentType.installment,
                installmentNumber: 1,
                installmentCount: 2,
                accounts: { [ACCOUNT_ID]: "debt" },
                accountIds: [ACCOUNT_ID],
                category: CATEGORY,
            },
            {
                orderId: ORDER_ID,
                amount: 100,
                dueDate: new Date(2025, 3, 10, 12),
                description: "Curso de inglês",
                status: InstallmentStatus.pending,
                type: OrderType.expense,
                installmentType: InstallmentType.installment,
                installmentNumber: 2,
                installmentCount: 2,
                accounts: { [ACCOUNT_ID]: "debt" },
                accountIds: [ACCOUNT_ID],
                category: CATEGORY,
            },
        ]);

        const created = await firestore
            .collection(`workspaces/${WORKSPACE_ID}/installments`)
            .where("orderId", "==", ORDER_ID)
            .where("installmentNumber", "==", 1)
            .get();

        installmentId = created.docs[0].id;
    });

    it("pagar uma parcela gera exatamente 1 evento derivado, e ele sai cedo", async () => {
        const beforePay = (await installmentRef().get()).data()!;
        const paidDate = new Date(2025, 2, 9, 12);

        // 1) O cliente paga a parcela (mesma escrita que o app faz).
        await installmentRef().update({
            status: InstallmentStatus.paid,
            paidAmount: 100,
            paidDate: admin.firestore.Timestamp.fromDate(paidDate),
        });
        const afterPay = (await installmentRef().get()).data()!;

        const updateInstallmentSpy = jest.spyOn(FinanceRepositoryImpl.prototype, "updateInstallment");
        const updateOrderSpy = jest.spyOn(FinanceRepositoryImpl.prototype, "updateOrder");

        // 2) Primeiro evento: a escrita do usuário.
        await handleInstallmentWritten(beforePay, afterPay, {
            workspaceId: WORKSPACE_ID,
            installmentId,
            eventId: `evt-pagamento-${Date.now()}`,
        });

        // A ÚNICA escrita derivada na parcela é o xp (com a cascata zerada
        // junto, na mesma escrita).
        expect(updateInstallmentSpy).toHaveBeenCalledTimes(1);
        expect(updateInstallmentSpy).toHaveBeenCalledWith(WORKSPACE_ID, installmentId, {
            xp: 15,
            replicationCascade: ReplicationCascade.none,
        });
        // Pagar não cascateia: a order não é tocada (e portanto não nasce
        // documento em orders/{id}/history).
        expect(updateOrderSpy).not.toHaveBeenCalled();

        const afterXp = (await installmentRef().get()).data()!;
        expect(afterXp.xp).toBe(15);
        expect(afterXp.replicationCascade).toBe(ReplicationCascade.none);

        // 3) O evento derivado: só campos derivados mudaram.
        const derivedChange = getChangedFields(afterPay, afterXp);
        expect(derivedChange.length).toBeGreaterThan(0);
        expect(derivedChange.every((field) => INSTALLMENT_DERIVED_FIELDS.has(field))).toBe(true);

        updateInstallmentSpy.mockClear();
        updateOrderSpy.mockClear();

        await handleInstallmentWritten(afterPay, afterXp, {
            workspaceId: WORKSPACE_ID,
            installmentId,
            eventId: `evt-derivado-${Date.now()}`,
        });

        // Saída antecipada: nenhum bloco rodou.
        expect(updateInstallmentSpy).not.toHaveBeenCalled();
        expect(updateOrderSpy).not.toHaveBeenCalled();

        const history = await firestore
            .collection(`workspaces/${WORKSPACE_ID}/orders/${ORDER_ID}/history`)
            .get();
        expect(history.empty).toBe(true);

        // O documento não foi tocado de novo (o eco não gerou terceiro evento).
        const afterEcho = (await installmentRef().get()).data()!;
        expect(getChangedFields(afterXp, afterEcho)).toEqual([]);

        updateInstallmentSpy.mockRestore();
        updateOrderSpy.mockRestore();
    });

    it("uma escrita com mudança real de conteúdo NÃO sai cedo", async () => {
        const before = (await installmentRef().get()).data()!;
        const after = { ...before, description: "Curso de inglês avançado" };

        const updateOrderSpy = jest.spyOn(FinanceRepositoryImpl.prototype, "updateOrder");
        const updateInstallmentSpy = jest.spyOn(FinanceRepositoryImpl.prototype, "updateInstallment");

        await handleInstallmentWritten(before, { ...after, replicationCascade: ReplicationCascade.all }, {
            workspaceId: WORKSPACE_ID,
            installmentId,
            eventId: `evt-descricao-${Date.now()}`,
        });

        // Com cascata `all` e descrição alterada, a order é atualizada.
        expect(updateOrderSpy).toHaveBeenCalledWith(
            WORKSPACE_ID,
            ORDER_ID,
            expect.objectContaining({ description: "Curso de inglês avançado" })
        );

        // E a cascata é zerada no documento de ORIGEM: sem pagamento não há
        // escrita de xp, então é esta que impede a cascata de ficar grudada.
        expect(updateInstallmentSpy).toHaveBeenCalledWith(WORKSPACE_ID, installmentId, {
            replicationCascade: ReplicationCascade.none,
        });
        expect((await installmentRef().get()).data()!.replicationCascade)
            .toBe(ReplicationCascade.none);

        updateOrderSpy.mockRestore();
        updateInstallmentSpy.mockRestore();
    });
});

/**
 * HUD mensal — o FIO INTEIRO: gatilho de parcela -> sumário -> receita prevista
 * publicada em `workspaces/{w}.expectedIncome`.
 *
 * Os unitários provam a REGRA da previsão com o repositório mockado. O que só
 * este teste prova é que o gatilho de fato a aciona: a parcela de receita passa
 * por `processSummaryChange`, o sumário mensal ganha o
 * `specificPlannedAmount`, e a previsão sai DAQUELE documento — o mesmo que o
 * app lê.
 *
 * `publishCurrentMonth` usa o relógio real, então as parcelas deste bloco são
 * agendadas para o mês CORRENTE (dia 10, meio-dia: longe de qualquer borda de
 * fuso).
 */
describe("Gatilho de parcela: receita prevista do mês (integração com emulador)", () => {
    const HUD_WORKSPACE_ID = `ws-hud-${Date.now()}`;
    const HUD_ACCOUNT_ID = "acc-hud";

    const SALARIO: CategoryModel = {
        id: "cat-salario",
        name: "Salário",
        icon: "payments",
        color: "#43A047",
        type: CategoryType.income,
        isDeleted: false,
    };
    const MERCADO: CategoryModel = {
        id: "cat-mercado",
        name: "Mercado",
        icon: "shopping_cart",
        color: "#EF5350",
        type: CategoryType.expense,
        isDeleted: false,
        allocation: "essential",
    };

    let firestore: admin.firestore.Firestore;
    let repository: FinanceRepositoryImpl;

    /** Dia 10 do mês CORRENTE, meio-dia. */
    const dueDateThisMonth = () => {
        const now = new Date();
        return new Date(now.getFullYear(), now.getMonth(), 10, 12);
    };

    const readExpectedIncome = async () =>
        (await firestore.doc(`workspaces/${HUD_WORKSPACE_ID}`).get()).data()?.expectedIncome;

    /** Cria a parcela e dispara o gatilho com o par (null, documento novo). */
    async function writeInstallment(
        id: string,
        type: OrderType,
        amount: number,
        category: CategoryModel
    ): Promise<Record<string, any>> {
        const ref = firestore.doc(`workspaces/${HUD_WORKSPACE_ID}/installments/${id}`);
        await ref.set({
            orderId: `order-${id}`,
            amount,
            amountCents: Math.round(amount * 100),
            dueDate: admin.firestore.Timestamp.fromDate(dueDateThisMonth()),
            referenceDate: admin.firestore.Timestamp.fromDate(dueDateThisMonth()),
            referenceAmount: amount,
            referenceAmountCents: Math.round(amount * 100),
            description: id,
            status: InstallmentStatus.pending,
            type,
            installmentType: InstallmentType.single,
            accounts: { [HUD_ACCOUNT_ID]: type === OrderType.income ? "credit" : "debt" },
            accountIds: [HUD_ACCOUNT_ID],
            category,
            paidDate: null,
        });

        const data = (await ref.get()).data()!;
        await handleInstallmentWritten(null, data, {
            workspaceId: HUD_WORKSPACE_ID,
            installmentId: id,
            eventId: `evt-${id}-${Date.now()}`,
        });
        return data;
    }

    beforeAll(async () => {
        if (admin.apps.length === 0) {
            admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT });
            admin.firestore().settings({ ignoreUndefinedProperties: false });
        }
        firestore = admin.firestore();
        repository = new FinanceRepositoryImpl();

        await firestore.doc(`workspaces/${HUD_WORKSPACE_ID}`).set({
            name: "Casa", type: "personal", members: ["uid"], xp: 0, level: 1,
        });
        await firestore.doc(`workspaces/${HUD_WORKSPACE_ID}/categories/${SALARIO.id}`).set(SALARIO);
        await firestore.doc(`workspaces/${HUD_WORKSPACE_ID}/categories/${MERCADO.id}`).set(MERCADO);

        const account: Omit<AccountModel, "id"> = {
            name: "Conta Corrente",
            icon: "account_balance",
            color: "#4CAF50",
            runtimeType: AccountType.checking,
            isDeleted: false,
            initialBalance: 0,
            initialBalanceDate: new Date(2025, 0, 1, 12),
        };
        await firestore.doc(`workspaces/${HUD_WORKSPACE_ID}/accounts/${HUD_ACCOUNT_ID}`).set(account);
    });

    afterAll(async () => {
        await firestore.recursiveDelete(firestore.doc(`workspaces/${HUD_WORKSPACE_ID}`));
    });

    it("uma receita AGENDADA nova publica a previsão com origem `planned`", async () => {
        expect(await readExpectedIncome()).toBeUndefined();

        await writeInstallment("inst-salario", OrderType.income, 5000, SALARIO);

        expect(await readExpectedIncome()).toMatchObject({
            monthKey: expect.stringMatching(/^\d{4}-\d{2}$/),
            cents: 500_000,
            source: "planned",
        });
    });

    it("editar o valor da receita REPUBLICA a previsão", async () => {
        const before = (await firestore
            .doc(`workspaces/${HUD_WORKSPACE_ID}/installments/inst-salario`).get()).data()!;

        // A mesma escrita que o app faz ao corrigir o valor: o `double` novo e
        // o inteiro AINDA VELHO (o passo derivado do gatilho é que o acerta).
        await firestore.doc(`workspaces/${HUD_WORKSPACE_ID}/installments/inst-salario`)
            .update({ amount: 7000 });
        const after = (await firestore
            .doc(`workspaces/${HUD_WORKSPACE_ID}/installments/inst-salario`).get()).data()!;

        await handleInstallmentWritten(before, after, {
            workspaceId: HUD_WORKSPACE_ID,
            installmentId: "inst-salario",
            eventId: `evt-edicao-${Date.now()}`,
        });

        expect(await readExpectedIncome()).toMatchObject({ cents: 700_000, source: "planned" });
    });

    it("uma DESPESA não toca na receita prevista", async () => {
        const antes = await readExpectedIncome();

        const publishSpy = jest.spyOn(ExpectedIncomeService.prototype, "publishCurrentMonth");

        await writeInstallment("inst-mercado", OrderType.expense, 900, MERCADO);

        // O gatilho nem chega a chamar a publicação: a guarda é pelo `type` da
        // parcela, antes de qualquer leitura.
        expect(publishSpy).not.toHaveBeenCalled();
        // E o número publicado continua o mesmo — a despesa entrou no sumário
        // do mês sem mexer no denominador do HUD.
        expect(await readExpectedIncome()).toEqual(antes);

        // O espião FUNCIONA: uma receita escrita logo em seguida, com ele
        // ainda instalado, é capturada. Sem esta segunda metade, a asserção
        // acima passaria também se o espião estivesse pendurado no lugar
        // errado — que é o jeito mais silencioso de um teste de negativa
        // mentir.
        await writeInstallment("inst-bonus", OrderType.income, 100, SALARIO);
        expect(publishSpy).toHaveBeenCalledWith(HUD_WORKSPACE_ID);

        publishSpy.mockRestore();
    });

    it("a previsão gravada é a que sai do sumário do mês, não um número solto", async () => {
        const monthKey = (await readExpectedIncome()).monthKey;
        const summary = await repository.getPeriodSummary(
            HUD_WORKSPACE_ID,
            Number(monthKey.slice(0, 4)),
            Number(monthKey.slice(5, 7))
        );

        // R$ 7.000 do salário corrigido + R$ 100 do bônus do teste anterior.
        expect(summary?.categories[SALARIO.id]?.specificPlannedAmountCents).toBe(710_000);
        expect((await readExpectedIncome()).cents).toBe(710_000);
    });
});
