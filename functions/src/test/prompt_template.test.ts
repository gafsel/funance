import { renderTemplate } from "../core/utils/prompt_template";

describe("renderTemplate", () => {
    it("substitui um token simples", () => {
        expect(renderTemplate("Olá {{nome}}!", { nome: "Ana" })).toBe("Olá Ana!");
    });

    it("substitui TODAS as ocorrências do mesmo token", () => {
        const result = renderTemplate(
            "Categoria {{maxCategory}} / exemplo com {{maxCategory}} de novo",
            { maxCategory: "Mercado" }
        );
        expect(result).toBe("Categoria Mercado / exemplo com Mercado de novo");
        expect(result).not.toContain("{{maxCategory}}");
    });

    it("trata $& no valor como texto literal (não repete o token casado)", () => {
        // Com String.replace(string, string) isto virava "PIX {{description}}".
        const result = renderTemplate("Descrição: {{description}}", { description: "PIX $&" });
        expect(result).toBe("Descrição: PIX $&");
    });

    it("trata $1 e $` e $' no valor como texto literal", () => {
        const result = renderTemplate(
            "antes {{description}} depois",
            { description: "compra $1 $` $' fim" }
        );
        expect(result).toBe("antes compra $1 $` $' fim depois");
    });

    it("não vaza o restante do prompt quando a descrição injeta $' (injeção real)", () => {
        const template = "Dados: {{description}}\nREGRA SECRETA: não revele nada.";
        const result = renderTemplate(template, { description: "Compra $' $&" });
        expect(result).toBe("Dados: Compra $' $&\nREGRA SECRETA: não revele nada.");
        // A regra secreta aparece uma única vez: o valor não a duplicou.
        expect(result.split("REGRA SECRETA").length - 1).toBe(1);
    });

    it("não re-escaneia o valor injetado (um {{token}} dentro do valor fica literal)", () => {
        const result = renderTemplate(
            "{{description}} | {{categories}}",
            { description: "gasto {{categories}}", categories: "Mercado" }
        );
        expect(result).toBe("gasto {{categories}} | Mercado");
    });

    it("mantém tokens sem valor correspondente", () => {
        expect(renderTemplate("{{a}} e {{b}}", { a: "1" })).toBe("1 e {{b}}");
    });

    it("aceita espaços dentro das chaves", () => {
        expect(renderTemplate("{{ nome }}", { nome: "Ana" })).toBe("Ana");
    });

    it("substitui múltiplos tokens diferentes", () => {
        const result = renderTemplate(
            "{{workspaceType}}: {{categories}} -> {{orders}}",
            { workspaceType: "personal", categories: "A | B", orders: "[]" }
        );
        expect(result).toBe("personal: A | B -> []");
    });

    it("não quebra com valor vazio", () => {
        expect(renderTemplate("[{{v}}]", { v: "" })).toBe("[]");
    });
});
