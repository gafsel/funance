module.exports = {
    root: true,
    env: {
        es6: true,
        node: true,
    },
    extends: [
        "eslint:recommended",
        "plugin:import/errors",
        "plugin:import/warnings",
        "plugin:import/typescript",
        "plugin:@typescript-eslint/recommended",
    ],
    parser: "@typescript-eslint/parser",
    parserOptions: {
        project: ["tsconfig.json", "tsconfig.test.json", "tsconfig.dev.json"],
        sourceType: "module",
    },
    ignorePatterns: [
        "/lib/**/*", // Ignore built files.
        "jest.config.js", // Ignore Jest config (not in tsconfig)
        "jest.integration.config.js", // Ignore Jest config (not in tsconfig)
    ],
    plugins: [
        "@typescript-eslint",
        "import",
    ],
    rules: {
        "quotes": ["error", "double"],
        "import/no-unresolved": 0,
        "indent": ["error", 4],
        "max-len": 0,
        "object-curly-spacing": ["error", "always"],
        "require-jsdoc": 0,
        "valid-jsdoc": 0,
        "@typescript-eslint/no-explicit-any": 0,
        "@typescript-eslint/no-non-null-assertion": 0,
        "brace-style": ["error", "stroustrup"],
        "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    },
    overrides: [
        {
            // F1.11 — a CAMADA DE REPOSITÓRIO é a fronteira com o Firestore, e
            // era ali que a tipagem terminava: 22 assinaturas com `any`, e com
            // elas coleções inteiras atravessando o backend sem forma nenhuma.
            //
            // O `any` continua permitido no resto do código (montagem de
            // prompt, payload de IA, mocks de teste), onde ele costuma ser o
            // tipo honesto para "o que o modelo devolveu". Aqui, não: um
            // documento do Firestore TEM forma, e escrevê-la é o que faz o
            // compilador pegar o acesso a campo inexistente.
            //
            // Sem este override o pacote regride na primeira assinatura nova —
            // e regride em silêncio, que é o que o F1.11 existe para acabar.
            files: [
                "src/features/*/domain/repositories/**/*.ts",
                "src/features/*/data/repositories/**/*.ts",
            ],
            rules: {
                "@typescript-eslint/no-explicit-any": "error",
            },
        },
    ],
};
