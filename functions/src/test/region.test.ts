import { resolveFunctionsRegion } from "../core/config/region";

describe("resolveFunctionsRegion", () => {
    it("mantém o projeto antigo em us-central1", () => {
        expect(resolveFunctionsRegion("funance-cef1b")).toBe("us-central1");
    });

    it("põe os projetos do Funances 2 em São Paulo", () => {
        expect(resolveFunctionsRegion("funances2-testes")).toBe("southamerica-east1");
        expect(resolveFunctionsRegion("funances2")).toBe("southamerica-east1");
    });

    it("sem projeto conhecido, usa a região nova", () => {
        expect(resolveFunctionsRegion("")).toBe("southamerica-east1");
    });
});
