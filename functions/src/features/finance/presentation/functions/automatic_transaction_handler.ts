import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { container } from "../../../../core/container";
import * as admin from "firebase-admin";

export const onAutomaticTransactionCreated = onDocumentCreated(
    "workspaces/{workspaceId}/automatic_transactions/{transactionId}",
    async (event) => {
        const { workspaceId, transactionId } = event.params;
        const data = event.data?.data();

        if (!data || data.suggestedCategory || data.suggestedAccount || data.isConsolidated || data.isIgnored) {
            return;
        }

        console.log(`Nova transação automática detectada: ${transactionId} no workspace ${workspaceId}. Iniciando enriquecimento.`);

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

            if (result) {
                const updateData: any = {};
                
                if (result.category) {
                    updateData.suggestedCategory = result.category;
                    if (result.category.id && !result.category.id.startsWith("id-existente")) {
                        updateData.categoryId = result.category.id;
                    }
                }
                
                if (result.accountId) {
                    updateData.accountId = result.accountId;
                    // Tentar buscar o modelo da conta para o suggestedAccount
                    const account = accounts.find(a => a.id === result.accountId);
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
                        .update(updateData);
                    
                    console.log(`Transação automática ${transactionId} enriquecida com sucesso.`);
                }
            }
        }
        catch (error) {
            console.error(`Erro ao enriquecer transação automática ${transactionId}:`, error);
        }
    }
);
