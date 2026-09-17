/**
 * `stripUndefined` — o descarte de `undefined` deixou de ser mágica do SDK.
 *
 * Com `ignoreUndefinedProperties: false` (F1.11), gravar `undefined` LANÇA. O
 * descarte continua existindo onde ele é legítimo, mas agora passa por esta
 * função — e o que ela NÃO pode fazer é tão importante quanto o que ela faz:
 * um `FieldValue.increment` recriado como objeto literal viraria um mapa
 * `{}` no documento e destruiria o contador.
 */

import * as admin from "firebase-admin";
import { stripUndefined } from "../core/utils/firestore.utils";

describe("stripUndefined", () => {
    it("remove a chave undefined e preserva null, zero, string vazia e false", () => {
        const result = stripUndefined({
            a: undefined,
            b: null,
            c: 0,
            d: "",
            e: false,
        });

        expect(Object.keys(result).sort()).toEqual(["b", "c", "d", "e"]);
        expect("a" in result).toBe(false);
        expect(result.b).toBeNull();
    });

    it("desce em objetos aninhados", () => {
        const result = stripUndefined({
            nextInvoice: { amount: 10, installmentId: undefined, status: "pending" },
        });

        expect(result.nextInvoice).toEqual({ amount: 10, status: "pending" });
        expect("installmentId" in result.nextInvoice).toBe(false);
    });

    it("desce nos objetos de dentro de um array", () => {
        const result = stripUndefined({
            slides: [{ title: "a", actionPath: undefined }, { title: "b" }],
        });

        expect(result.slides).toEqual([{ title: "a" }, { title: "b" }]);
    });

    it("não altera o objeto recebido", () => {
        const original: Record<string, unknown> = { keep: 1, drop: undefined };
        stripUndefined(original);

        expect("drop" in original).toBe(true);
    });

    it("preserva Date sem transformá-lo em objeto literal", () => {
        const date = new Date("2026-03-10T12:00:00Z");
        const result = stripUndefined({ dueDate: date });

        expect(result.dueDate).toBeInstanceOf(Date);
        expect(result.dueDate.getTime()).toBe(date.getTime());
    });

    it("preserva os sentinelas do SDK (Timestamp e FieldValue)", () => {
        // Um `increment` recriado como `{}` zeraria o contador em silêncio:
        // é exatamente o estrago que a checagem de prototype evita.
        const timestamp = admin.firestore.Timestamp.fromDate(new Date("2026-03-10T12:00:00Z"));
        const increment = admin.firestore.FieldValue.increment(5);
        const remove = admin.firestore.FieldValue.delete();

        const result = stripUndefined({ ts: timestamp, inc: increment, gone: remove });

        expect(result.ts).toBe(timestamp);
        expect(result.inc).toBe(increment);
        expect(result.gone).toBe(remove);
    });
});
