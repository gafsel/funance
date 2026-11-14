/**
 * Região das Cloud Functions, decidida pelo projeto em que o código roda.
 *
 * Gatilhos do Firestore precisam estar na região do banco. O projeto antigo
 * (`funance-cef1b`) tem o banco na multirregião dos EUA e as funções em
 * `us-central1`; mudar isso lá recriaria todas as funções. Os projetos do
 * Funances 2 nascem com o Firestore em `southamerica-east1` (São Paulo).
 *
 * O app precisa chamar as callables na MESMA região — ver
 * `lib/firebase_ambiente.dart`.
 */
const LEGACY_PROJECT_ID = "funance-cef1b";
const LEGACY_REGION = "us-central1";
const DEFAULT_REGION = "southamerica-east1";

export function resolveFunctionsRegion(
    projectId: string | undefined = process.env.GCLOUD_PROJECT ?? process.env.GOOGLE_CLOUD_PROJECT
): string {
    return projectId === LEGACY_PROJECT_ID ? LEGACY_REGION : DEFAULT_REGION;
}
