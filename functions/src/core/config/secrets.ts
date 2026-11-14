import { defineSecret } from "firebase-functions/params";

/**
 * Chave da API do Gemini, guardada no Secret Manager do projeto.
 *
 * Antes era um `defineString` alimentado por `functions/.env.<projeto>`, um
 * arquivo versionado: a chave ficava no git e era gravada em texto puro na
 * configuração de cada função publicada.
 *
 * O segredo é vinculado a TODAS as funções em `setGlobalOptions` (index.ts),
 * e não função a função. O Gemini é alcançado por callables, por crons e por
 * gatilhos do Firestore (nomes de missão, transação automática); vincular um
 * a um deixaria a função esquecida falhando só em produção, na primeira
 * chamada à IA. Todas as funções rodam com a mesma conta de serviço, então o
 * vínculo global não amplia quem consegue ler a chave.
 *
 * Gravar ou trocar o valor (o valor é digitado no terminal, nunca em arquivo):
 *
 *   firebase functions:secrets:set GEMINI_API_KEY --project <projeto>
 *
 * Depois de trocar, as funções precisam ser publicadas de novo para pegar a
 * versão nova. No emulador, o valor vem de `functions/.secret.local`
 * (ignorado pelo git), no formato `GEMINI_API_KEY=...`.
 */
export const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
