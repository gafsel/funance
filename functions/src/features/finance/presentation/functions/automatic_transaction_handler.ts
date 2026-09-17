import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { container } from "../../../../core/container";
import * as admin from "firebase-admin";
import { stripUndefined } from "../../../../core/utils/firestore.utils";

/** Nome de ação ESTÁVEL da idempotência (ver core/services/idempotency.service.ts). */
export const AUTOMATIC_TRANSACTION_ACTION = "enrichAutomaticTransaction";

export const onAutomaticTransactionCreated = onDocumentCreated(
    "workspaces/{workspaceId}/automatic_transactions/{transactionId}",
    async (event) => {
        const { workspaceId, transactionId } = event.params;
        const data = event.data?.data();

        if (!data || data.suggestedCategory || data.suggestedAccount || data.isConsolidated || data.isIgnored) {
            return;
        }

        console.log(`Nova transação automática detectada: ${transactionId} no workspace ${workspaceId}. Iniciando enriquecimento.`);

        // O enriquecimento chama o Gemini (custo por execução): uma reentrega
        // do mesmo evento não pode disparar uma segunda chamada.
        await container.idempotencyService.runIdempotency(event.id, AUTOMATIC_TRANSACTION_ACTION, async () => {
            await enrichAutomaticTransaction(workspaceId, transactionId, data);
        });
    }
);

/**
 * Corpo do enriquecimento, separado do trigger para o marcador de idempotência
 * envolver exatamente a chamada de IA e a escrita resultante.
 *
 * Erros são registrados e engolidos de propósito: uma falha de enriquecimento
 * não deve reprocessar o evento (e gastar cota de IA de novo) — a transação
 * continua existindo, apenas sem sugestão.
 */
export async function enrichAutomaticTransaction(
    workspaceId: string,
    transactionId: string,
    data: any
): Promise<void> {
    try {
        const aiRepository = container.aiRepository;
        const categoryRepository = container.categoryRepository;
        const financeRepository = container.financeRepository;

        // Buscar categorias e contas existentes para contexto
        const categories = await categoryRepository.getCategories(workspaceId);
        const accounts = await financeRepository.getAccounts(workspaceId);

        const result = await aiRepository.enrichAutomaticTransaction(
            workspaceId,
            data.description,
            data.packageName,
            data.type,
            categories,
            accounts
        );

        if (!result) return;

        const updateData: Record<string, unknown> = {};

        if (result.category) {
            // O validador (F5.2) já garante que `id` é ou um id REAL do
            // workspace ou null — o placeholder "id-existente-se-houver" do
            // prompt e qualquer id inventado não chegam mais aqui.
            // `suggestedCategory` é lido pelo cliente como CategoryModel, cujo
            // `id` é String não-nula: categoria nova vai com id vazio.
            updateData.suggestedCategory = { ...result.category, id: result.category.id ?? "" };
            if (result.category.id) {
                updateData.categoryId = result.category.id;
            }
        }

        if (result.accountId) {
            updateData.accountId = result.accountId;
            // Tentar buscar o modelo da conta para o suggestedAccount
            const account = accounts.find((a) => a.id === result.accountId);
            if (account) {
                updateData.suggestedAccount = account;
            }
        }

        if (Object.keys(updateData).length > 0) {
            await admin.firestore()
                .collection("workspaces")
                .doc(workspaceId)
                .collection("automatic_transactions")
                .doc(transactionId)
                // `stripUndefined`: `suggestedAccount` é um `AccountModel`
                // inteiro, com meia dúzia de campos opcionais (`closingDay`,
                // `limit`, `bankLogo`, o `updatedAt` de `nextInvoice`). Sem o
                // descarte, uma conta que não preencha qualquer um deles
                // derruba a escrita — e o `catch` deste handler transforma
                // isso numa transação sem sugestão, sem nada no log do app.
                .update(stripUndefined(updateData));

            console.log(`Transação automática ${transactionId} enriquecida com sucesso.`);
        }
    }
    catch (error) {
        console.error(`Erro ao enriquecer transação automática ${transactionId}:`, error);
    }
}
