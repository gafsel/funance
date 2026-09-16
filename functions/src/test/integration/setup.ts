/**
 * Setup compartilhado dos testes que dependem do emulador do Firestore.
 *
 * Não inicializa nada por si só: apenas garante que o processo está apontando
 * para o emulador (e nunca para o projeto real) antes de qualquer teste rodar.
 */

const DEFAULT_PROJECT_ID = "demo-funances";

if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error(
        "FIRESTORE_EMULATOR_HOST não está definido. Rode os testes de integração " +
        "com `npm run test:integration` (que usa `firebase emulators:exec`)."
    );
}

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || DEFAULT_PROJECT_ID;
process.env.FIREBASE_PROJECT_ID = process.env.FIREBASE_PROJECT_ID || DEFAULT_PROJECT_ID;

// Evita que qualquer código tente usar credenciais reais.
delete process.env.GOOGLE_APPLICATION_CREDENTIALS;

export const TEST_PROJECT_ID = process.env.GCLOUD_PROJECT;
