import { onCall, HttpsError } from "firebase-functions/v2/https";
import { container } from "../../../../core/container";

export const analyzeOnboarding = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
  }

  const { workspaceType, transactions } = request.data;

  if (!workspaceType || !transactions || !Array.isArray(transactions)) {
    throw new HttpsError("invalid-argument", "Dados de entrada inválidos.");
  }

  try {
    const suggestions = await container.onboardingService.analyzeAccounts(workspaceType, transactions);
    return { suggestions };
  }
  catch (error: any) {
    console.error("Erro na análise da IA:", error);
    throw new HttpsError("internal", error.message || "Erro ao processar análise de IA.");
  }
});

export const analyzeAccountDocument = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "O usuário deve estar autenticado.");
  }

  const { storagePath, fileName, existingCategories } = request.data;

  if (!storagePath || !fileName) {
    throw new HttpsError("invalid-argument", "Caminho no storage e nome do arquivo são obrigatórios.");
  }

  try {
    const analysis = await container.onboardingService.analyzeAccountDocument(
      storagePath,
      fileName,
      existingCategories || []
    );
    return analysis;
  }
  catch (error: any) {
    console.error("Erro na análise do documento:", error);
    throw new HttpsError("internal", error.message || "Erro ao processar análise do documento.");
  }
});
