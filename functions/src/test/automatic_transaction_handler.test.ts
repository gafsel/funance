/**
 * Enriquecimento da transação automática: a escrita não pode levar `undefined`.
 *
 * `suggestedAccount` é um `AccountModel` INTEIRO, copiado para dentro do
 * documento. O modelo tem meia dúzia de campos opcionais (`closingDay`,
 * `limit`, `bankLogo`, `ownerIds`, e o `updatedAt` de `nextInvoice`), e com o
 * `ignoreUndefinedProperties` desligado (F1.11) qualquer um deles presente e
 * valendo `undefined` derruba a escrita inteira.
 *
 * O que torna esse defeito especialmente silencioso: o handler ENGOLE os
 * próprios erros de propósito (uma falha não pode reprocessar o evento e gastar
 * cota de IA de novo). A chamada ao Gemini já teria sido paga, e a transação
 * ficaria sem sugestão nenhuma — sem erro no app e sem nada além de um
 * `console.error` no log.
 */

// ofx-js é ESM puro e não é transformado pelo ts-jest; chega aqui pela cadeia
// do container, mas não é exercitado.
jest.mock("ofx-js", () => ({ parse: jest.fn() }));

const updates: Array<Record<string, unknown>> = [];

/** O SDK real com `ignoreUndefinedProperties: false`: `undefined` derruba tudo. */
function assertNoUndefined(value: unknown, path: string): void {
    if (value === undefined) {
        throw new Error(`Cannot use "undefined" as a Firestore value (found in field ${path}).`);
    }
    if (value === null || typeof value !== "object") return;
    if (value instanceof Date) return;
    if (Array.isArray(value)) {
        value.forEach((item, index) => assertNoUndefined(item, `${path}[${index}]`));
        return;
    }
    for (const [key, item] of Object.entries(value as Record<string, unknown>)) {
        assertNoUndefined(item, path ? `${path}.${key}` : key);
    }
}

jest.mock("firebase-admin", () => {
    const docRef = {
        collection: () => ({ doc: () => docRef }),
        update: async (data: Record<string, unknown>) => {
            assertNoUndefined(data, "");
            updates.push(data);
        },
    };
    const firestore: any = () => ({ collection: () => ({ doc: () => docRef }) });
    firestore.Timestamp = { fromDate: (date: Date) => date };
    firestore.FieldValue = { serverTimestamp: () => "ts" };
    return { firestore };
});

const fakeContainer: any = {
    aiRepository: { enrichAutomaticTransaction: jest.fn() },
    categoryRepository: { getCategories: jest.fn() },
    financeRepository: { getAccounts: jest.fn() },
};

jest.mock("../core/container", () => ({ container: fakeContainer }));

import { enrichAutomaticTransaction } from "../features/finance/presentation/functions/automatic_transaction_handler";
import { AccountModel, AccountType, InstallmentStatus } from "../features/finance/domain/models/finance.models";

/**
 * Cartão como `toAccountModel` o devolve para uma conta cuja `nextInvoice`
 * ainda não tem carimbo de sincronização: a chave `updatedAt` NÃO existe.
 */
const CARD_WITHOUT_UPDATED_AT: AccountModel = {
    id: "acc-card",
    name: "Cartão",
    icon: "credit_card",
    color: "#7E57C2",
    runtimeType: AccountType.creditCard,
    isDeleted: false,
    initialBalance: 0,
    initialBalanceDate: new Date("2026-01-01T12:00:00Z"),
    nextInvoice: {
        dueDate: new Date("2026-04-10T12:00:00Z"),
        closingDate: new Date("2026-04-03T00:00:00Z"),
        cycleStart: new Date("2026-03-04T00:00:00Z"),
        cycleEnd: new Date("2026-04-03T23:59:59Z"),
        amount: 1200,
        amountCents: 120000,
        orderId: "invoice-acc-card-2026-04-10",
        installmentId: "inst-1",
        status: InstallmentStatus.pending,
    },
};

const TRANSACTION = {
    description: "Mercado do Bairro",
    packageName: "com.nubank",
    type: "expense",
};

describe("enrichAutomaticTransaction — a escrita de `suggestedAccount`", () => {
    let error: jest.SpyInstance;

    beforeEach(() => {
        updates.length = 0;
        error = jest.spyOn(console, "error").mockImplementation(() => undefined);
        jest.spyOn(console, "log").mockImplementation(() => undefined);

        fakeContainer.categoryRepository.getCategories = jest.fn(async () => []);
        fakeContainer.financeRepository.getAccounts = jest.fn(async () => [CARD_WITHOUT_UPDATED_AT]);
        fakeContainer.aiRepository.enrichAutomaticTransaction = jest.fn(async () => ({
            category: { id: "cat-mercado", name: "Mercado" },
            accountId: "acc-card",
        }));
    });

    afterEach(() => {
        jest.restoreAllMocks();
    });

    it("grava a conta sugerida mesmo sem `nextInvoice.updatedAt`", async () => {
        await enrichAutomaticTransaction("w1", "tx-1", TRANSACTION);

        // O BUG: a escrita lançava, o `catch` engolia, e a transação ficava
        // sem sugestão nenhuma — depois de a chamada de IA já ter sido paga.
        expect(error).not.toHaveBeenCalled();
        expect(updates).toHaveLength(1);
        expect(updates[0].accountId).toBe("acc-card");
        expect((updates[0].suggestedAccount as AccountModel).id).toBe("acc-card");
    });

    it("os campos opcionais que a conta não tem ficam FORA do documento", async () => {
        await enrichAutomaticTransaction("w1", "tx-1", TRANSACTION);

        const account = updates[0].suggestedAccount as Record<string, unknown>;
        expect("closingDay" in account).toBe(false);
        expect("limit" in account).toBe(false);
        expect("bankLogo" in account).toBe(false);
        expect("updatedAt" in (account.nextInvoice as Record<string, unknown>)).toBe(false);
    });

    /**
     * A segunda linha de defesa, independente de `toAccountModel`: mesmo que
     * ALGUÉM entregue ao handler um modelo com chave presente valendo
     * `undefined`, o `stripUndefined` da escrita a descarta. `AccountModel`
     * tem seis campos opcionais, e este handler copia o modelo INTEIRO para
     * dentro do documento — o descarte não pode depender de quem o montou.
     */
    it("descarta chave `undefined` que chegue no modelo, venha ela de onde vier", async () => {
        fakeContainer.financeRepository.getAccounts = jest.fn(async () => [{
            ...CARD_WITHOUT_UPDATED_AT,
            bankLogo: undefined,
            closingDay: undefined,
            ownerIds: undefined,
        }]);

        await enrichAutomaticTransaction("w1", "tx-1", TRANSACTION);

        expect(error).not.toHaveBeenCalled();
        const account = updates[0].suggestedAccount as Record<string, unknown>;
        expect("bankLogo" in account).toBe(false);
        expect("closingDay" in account).toBe(false);
        expect("ownerIds" in account).toBe(false);
    });

    it("a categoria nova continua indo com id vazio, e sem `categoryId`", async () => {
        fakeContainer.aiRepository.enrichAutomaticTransaction = jest.fn(async () => ({
            category: { id: null, name: "Padaria" },
            accountId: null,
        }));

        await enrichAutomaticTransaction("w1", "tx-1", TRANSACTION);

        expect(updates[0].suggestedCategory).toEqual({ id: "", name: "Padaria" });
        expect("categoryId" in updates[0]).toBe(false);
        expect("suggestedAccount" in updates[0]).toBe(false);
    });

    it("sem sugestão nenhuma, não escreve nada", async () => {
        fakeContainer.aiRepository.enrichAutomaticTransaction = jest.fn(async () => null);

        await enrichAutomaticTransaction("w1", "tx-1", TRANSACTION);

        expect(updates).toHaveLength(0);
        expect(error).not.toHaveBeenCalled();
    });
});
