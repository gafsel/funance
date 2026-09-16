/**
 * Testes de integração e de security rules.
 *
 * Exigem o emulador do Firestore em execução; use `npm run test:integration`,
 * que envolve o Jest em `firebase emulators:exec --only firestore`.
 */
module.exports = {
    preset: "ts-jest",
    testEnvironment: "node",
    testMatch: [
        "**/src/test/integration/**/*.test.ts",
        "**/src/test/rules/**/*.test.ts",
    ],
    testPathIgnorePatterns: ["/node_modules/"],
    setupFilesAfterEnv: ["<rootDir>/src/test/integration/setup.ts"],
    verbose: true,
    forceExit: true,
    testTimeout: 30000,
    maxWorkers: 1,
};
