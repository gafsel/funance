/**
 * Testes unitários (sem emulador).
 * Roda apenas os testes com mocks manuais em src/test/*.test.ts.
 */
module.exports = {
    preset: "ts-jest",
    testEnvironment: "node",
    transform: {
        "^.+\\.tsx?$": ["ts-jest", { tsconfig: "tsconfig.test.json" }],
    },
    testMatch: ["**/src/**/*.test.ts"],
    testPathIgnorePatterns: [
        "/node_modules/",
        "/src/test/integration/",
        "/src/test/rules/",
    ],
    verbose: true,
    forceExit: true,
    clearMocks: true,
    resetMocks: true,
    restoreMocks: true,
};
