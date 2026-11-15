/**
 * Gatilhos do motor do Funances 2. São dois porque há duas fontes: o
 * lançamento e a conta (o cartão que começa devendo entra na fatura).
 *
 * O evento só diz QUAL documento mudou; o estado é lido de novo pelo motor.
 */

import * as admin from "firebase-admin";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { COLECOES, RAIZ } from "../../domain/models/modelo";
import { MotorService } from "../../domain/services/motor.service";

let motor: MotorService | null = null;
const obterMotor = (): MotorService => (motor ??= new MotorService(admin.firestore()));

export const aoGravarLancamento = onDocumentWritten(
    `${RAIZ}/{espacoId}/${COLECOES.lancamentos}/{lancamentoId}`,
    async (event) => {
        await obterMotor().processarLancamento(event.params.espacoId, event.params.lancamentoId);
    }
);

export const aoGravarConta = onDocumentWritten(
    `${RAIZ}/{espacoId}/${COLECOES.contas}/{contaId}`,
    async (event) => {
        await obterMotor().processarConta(event.params.espacoId, event.params.contaId);
    }
);
