# Funances — Cloud Functions

Backend do Funances em **Cloud Functions v2 (TypeScript)** sobre Firestore.

## Estrutura

```
src/
  core/            # container IoC, serviços transversais (IA, idempotência) e utilitários
  features/<f>/    # Clean Architecture por feature:
    data/repositories/       # implementações (Admin SDK)
    domain/models/           # modelos e enums
    domain/repositories/     # interfaces (o container injeta a implementação)
    domain/services/         # regras de negócio (sem Firestore direto)
    presentation/functions/  # handlers (triggers, callables, schedulers)
  scripts/         # scripts operacionais/migrações — NUNCA rodam em produção sozinhos
  test/            # Jest: unitários (mocks) + integração e rules no emulador (src/test/integration, src/test/rules)
```

## Comandos

```bash
npm install              # use --engine-strict=false se o Node local for > 20
npm run lint             # eslint
npm run build            # tsc -> lib/ (src/test fica de fora do build de produção)
npm run test:unit        # jest com mocks (src/test/*.test.ts)
npm run test:integration # sobe o emulador do Firestore (--project demo-funances; exige Java 17+)
npm run test:rules       # testes das security rules no emulador
npm test                 # unit + integration
```

## Configuração global

`src/index.ts` define `setGlobalOptions` com os padrões dos triggers leves
(`maxInstances: 10`, `memory: "256MiB"`, `timeoutSeconds: 60`). A **região não é
definida**: Firestore e Functions já estão na mesma região padrão e mudá-la
exigiria recriar todas as funções.

As funções de IA sobrescrevem esses padrões com os presets de
`src/core/config/functions.config.ts` (`AI_CALLABLE_OPTIONS`,
`AI_CALLABLE_OPTIONS_SHORT`, `AI_SCHEDULE_OPTIONS`): mais memória e timeout,
porém `maxInstances` baixo, já que cada instância simultânea é uma chamada paga
ao Gemini.

## SDK do Gemini e modelos

O backend usa o SDK **`@google/genai`** (o pacote atual do Google). O anterior,
`@google/generative-ai`, está descontinuado e foi removido. Diferenças que
aparecem no código e nos mocks de teste:

| `@google/generative-ai` (removido)            | `@google/genai` (atual)                      |
|-----------------------------------------------|----------------------------------------------|
| `new GoogleGenerativeAI(apiKey)`              | `new GoogleGenAI({ apiKey })`                |
| `getGenerativeModel({model, generationConfig})` + `model.generateContent(req)` | `ai.models.generateContent({model, contents, config})` |
| `(await result.response).text()` (método)     | `result.text` (**getter**, pode ser `undefined`) |
| `SchemaType.OBJECT`                           | `Type.OBJECT`                                |
| `ResponseSchema`                              | `Schema`                                     |

Os modelos padrão são **versões pinadas** (`src/core/config/ai.config.ts`):
`gemini-2.5-flash` para tudo, `gemini-2.5-pro` para análise de documento. Alias
rolante (`-latest`) foi abandonado de propósito: ele troca o modelo por baixo do
código, mudando resposta, custo e latência sem nenhum deploy.

O override por `config/ai.models.*` continua valendo, mas passa por
`sanitizeModel` (`ai.service.ts`), que remapeia para o modelo pinado
equivalente: nomes inválidos, a família aposentada `gemini-1.5-*` (responde 404)
e qualquer alias `*-latest`. Para trocar de modelo sem deploy, use um nome
pinado (ex.: `gemini-2.5-pro`).

Quando o modelo primário responde 503/429/500, `generateResilient` tenta de novo
e depois cai para `gemini-2.5-flash` → `gemini-2.5-flash-lite`. O `ai_log`
registra o modelo que **de fato** respondeu.

## Análise de documento: limites e transporte do arquivo

Extrato/fatura em PDF ou imagem sobem para o Storage e as callables
`analyzeAccountDocument` e `analyzeReconciliationDocument` os enviam ao Gemini.
Duas fronteiras (`src/core/utils/document_limits.ts`):

| Tamanho          | O que acontece |
|------------------|----------------|
| até **4 MB**     | vai **inline** no prompt (base64) — um round-trip a menos |
| 4 MB a **10 MB** | sobe pela **Files API** do Gemini; o prompt referencia só a URI (`fileData`) e o arquivo remoto é apagado logo após a resposta |
| acima de **10 MB** | `invalid-argument` com mensagem em português |

Por que a fronteira de 4 MB: base64 infla o arquivo em ~33%, e o payload
inteiro precisa caber no limite de request do Gemini e na memória da function.

O teto de 10 MB é verificado **no handler, só pelos metadados do Storage** —
antes de consumir cota e antes de baixar o arquivo. Um upload de 40 MB não
custa cota nem memória. O serviço reconfere pelo tamanho do buffer: ele não
confia em quem o chama.

As duas callables usam o preset `AI_DOCUMENT_CALLABLE_OPTIONS`
(**1GiB**, 300s): no pior caso legítimo convivem no processo o buffer de 10 MB
baixado do Storage, o base64 e a resposta do modelo.

### Contrato com o cliente Flutter

- Arquivo acima de 10 MB: `FirebaseFunctionsException` com
  `code: "invalid-argument"` e a mensagem
  *"O arquivo tem X MB e o limite para análise é de 10,0 MB. Envie um período
  menor (um mês por vez) ou o arquivo OFX do seu banco, que é bem mais leve."*
  Vale checar o tamanho no app antes do upload, para não gastar banda à toa.
- Arquivo inexistente no Storage: agora `not-found` (antes vinha `internal`).
- As duas callables de documento **preservam o código do `HttpsError`** em vez
  de reembrulhar tudo em `internal`: `invalid-argument` (tamanho/argumento),
  `resource-exhausted` (cota) e `not-found` chegam ao app com o código certo,
  como já acontecia em `analysePlanning` e `analyzeGoalFeasibility`. Só erro
  inesperado vira `internal`.

## Quotas de IA

`src/core/services/quota.service.ts` aplica um limite diário por workspace em
cada callable de IA. O contador fica em
`workspaces/{workspaceId}/quotas/{YYYY-MM-DD}` (um campo por função,
`FieldValue.increment` dentro de transação; a data usa o fuso
`America/Sao_Paulo`). Acima do limite a function responde
`HttpsError("resource-exhausted")`. Os limites estão em
`src/core/config/quota.config.ts`.

Duas regras importantes:

- **A cota só é consumida quando a IA é realmente chamada.** Nas funções com
  cache server-side — `generateCoaching` (5 dias), `analyze503020Ideal`
  (3 dias), `analysePlanning` e `analyzeGoalFeasibility` (cache por hash da
  entrada, 7 dias; ver abaixo) — o handler não chama `assertQuota`: ele monta
  um `QuotaGuard` e passa para o serviço, que faz `consume()` imediatamente
  antes de invocar o Gemini. Reabrir um insight/análise já existente não gasta
  nada.
- **Com a cota esgotada, nada de caro roda.** Esses dois handlers chamam
  `guard.check()` logo depois de `assertWorkspaceMember`: é uma leitura
  somente-leitura do contador, que já responde `resource-exhausted` sem
  incrementar. Sem isso, o servidor montaria todo o contexto financeiro — e
  possivelmente chamaria o Gemini para classificar categorias novas
  (`CategoryGroupService.resolveCategoryGroups`, cacheado em `coaching_meta`)
  — para depois descartar tudo no `consume()`.
- **Falha de infraestrutura é estornada.** Se o Gemini responder 5xx/429 ou
  der timeout, quem invocou chama `refund()` e a unidade volta. Resposta
  inválida ou erro de validação **não** gera estorno — ver `isTransientAiError`
  em `src/core/services/ai.service.ts`. Nas quatro funções com cache o
  `consume()`/`refund()` vive no serviço; nas **duas de documento**, que não
  têm cache, o handler consome depois de checar o tamanho do arquivo e estorna
  no `catch`.

O documento de quota também recebe `createdAt` e `expiresAt` (criação + 90
dias) na primeira escrita do dia, para ser recolhido pela mesma política de
TTL descrita abaixo.

## Validação das saídas de IA

Toda chamada ao Gemini usa **`responseSchema`** (JSON estruturado) e passa por
um **validador server-side** em `src/core/services/ai_validation.ts` antes de
virar escrita no Firestore ou resposta para o cliente. O schema garante a
*forma*; o validador garante o *conteúdo* — o modelo continua podendo inventar
um id, mandar `NaN`, uma data que não existe ou uma string de 40 mil caracteres.

Regras comuns a todos os validadores:

- **Item ruim é descartado, nunca derruba a resposta.** Uma fatura com 80
  lançamentos não se perde porque o modelo errou a data de um deles. Os
  descartes saem em UM `console.warn` por chamada (`[ai_validation:<escopo>]`).
- **Id só é aceito se o prompt o enviou.** Dos seis prompts, só
  `automaticTransaction` recebe ids (categorias e contas do workspace); nos
  outros o prompt manda apenas nomes, então qualquer id na resposta é
  alucinação e vira `null` — semântica de "categoria nova". Um `accountId`
  desconhecido também vira `null`.
- **Texto é truncado** (120 para nomes, 500 para texto livre), não descartado,
  a menos que fique vazio.
- **Número precisa ser finito.** Valor de lançamento é sempre POSITIVO (o sinal
  vive no `type`); saldo de conta pode ser negativo (dívida).
- **Lançamento sem `type` válido é descartado**, nunca adivinhado. O caso
  perigoso é o valor positivo sem `type`: assumir `income` transformaria uma
  compra em receita no extrato do usuário, calado. `type` é obrigatório nos
  schemas, então a resposta sem ele já está fora do contrato.
- **Data é normalizada para `YYYY-MM-DD`**, aceitando ISO completo e
  `DD/MM/YYYY`; data inexistente (2026-02-30) ou ano fora de 1970–2100 descarta
  o item.
- **Enum fora da lista** cai no padrão do campo ou descarta o item, conforme o
  campo ser opcional ou definir a semântica.

### Entrada do cliente

`analyzeGoalFeasibility` valida o `goalPayload` **antes** de montar o prompt e
antes de consumir cota (`validateGoalFeasibilityPayload`). Este é o único
validador que **lança** — `invalid-argument` — porque é entrada do usuário, não
saída do modelo. Campos fora do contrato são descartados: só
`name`, `targetAmount`, `deadlineDays`, `monthlyRequired` e `type` entram no
template.

### Contrato com o cliente Flutter

- `analyzeReconciliationDocument` devolve `transactions[].date` sempre como
  `YYYY-MM-DD` (antes podia vir um ISO completo no fallback). Transação sem
  `type` é omitida da lista em vez de chegar ao app classificada como receita.
- `automatic_transactions.suggestedCategory.id` é `""` quando a IA sugeriu uma
  categoria NOVA (antes vinha o placeholder do prompt,
  `"id-existente-se-houver"`, ou um id inventado). `categoryId` só é gravado
  quando o id existe de fato no workspace.

## Cache de IA por hash da entrada (`ai_cache`)

`analysePlanning` (sugestão de metas no onboarding) e `analyzeGoalFeasibility`
(viabilidade de meta) eram chamadas repetidamente com a **mesma entrada**: o
usuário volta uma tela e avança de novo, mexe no prazo e desfaz, o app reabre a
sugestão. Cada repetição era uma chamada paga ao Gemini e uma unidade de cota.

`src/core/services/ai_cache.service.ts` grava a resposta **já validada** em:

```
workspaces/{workspaceId}/ai_cache/{functionName}_{sha256(entrada normalizada)}
  functionName, payload, createdAt, expiresAt   # createdAt + 7 dias
```

- A entrada é normalizada antes do hash (`stableStringify`): chaves de objeto
  em ordem alfabética, `Date`/`Timestamp` em ISO. A ordem dos **arrays** conta
  (a ordem dos lançamentos é informação).
- Mudou qualquer coisa na entrada, muda o hash: não existe servir análise velha
  para dado novo. Só o tempo invalida uma entrada — `expiresAt` é conferido na
  **leitura**, então a validade vale mesmo sem a política de TTL ativa.
- **Cache-hit não consome cota**: o `QuotaGuard.consume()` fica imediatamente
  antes da chamada real ao Gemini, dentro do serviço.
- Falha do Firestore no cache vira cache-miss; o cache nunca derruba a chamada.
- As security rules negam leitura e escrita do cliente (`ai_cache`).

Para ativar a política de TTL desta coleção (uma vez, manualmente — mesmo
formato dos comandos da seção seguinte):

```bash
gcloud firestore fields ttls update expiresAt \
  --collection-group=ai_cache \
  --project=funance-cef1b \
  --enable-ttl
```

## Logs de IA (`ai_logs`) e TTL

Cada chamada ao Gemini grava um documento de **metadados** em
`workspaces/{workspaceId}/ai_logs/{id}`: `functionName`, `model`, `latencyMs`,
`promptSha256`, `promptLength`, `status` (`ok`/`erro`), `errorCode`,
`inputTokens`/`outputTokens`/`totalTokens` (quando o modelo devolve
`usageMetadata`), `createdAt` e `expiresAt`.

Prompt e resposta crus **não** são gravados por padrão — são dados financeiros
do usuário. Eles só entram (nos campos `debugPrompt`/`debugResponse`) quando o
documento `config/ai` tem `debugLogging: true`; nesse caso `expiresAt` passa a
ser `createdAt + 7 dias` em vez de `createdAt + 90 dias`.

### Ativar a política de TTL (executar uma vez, manualmente)

O campo `expiresAt` só apaga documentos depois que a política de TTL estiver
ativa na coleção. Como `ai_logs` e `quotas` são subcoleções, a política é
criada sobre o **grupo de coleções** — uma por grupo:

```bash
gcloud firestore fields ttls update expiresAt \
  --collection-group=ai_logs \
  --project=funance-cef1b \
  --enable-ttl

gcloud firestore fields ttls update expiresAt \
  --collection-group=quotas \
  --project=funance-cef1b \
  --enable-ttl

# Cache de IA por hash da entrada (TTL de 7 dias). NÃO EXECUTADO.
gcloud firestore fields ttls update expiresAt \
  --collection-group=ai_cache \
  --project=funance-cef1b \
  --enable-ttl

# Marcadores de idempotência (coleção RAIZ `_idempotency`, TTL de 30 dias —
# ver a seção "Idempotência dos gatilhos" abaixo). NÃO EXECUTADO.
gcloud firestore fields ttls update expiresAt \
  --collection-group=_idempotency \
  --project=funance-cef1b \
  --enable-ttl
```

Para conferir o estado da política:

```bash
gcloud firestore fields ttls list --project=funance-cef1b
```

Para desativar:

```bash
gcloud firestore fields ttls update expiresAt \
  --collection-group=ai_logs \
  --project=funance-cef1b \
  --disable-ttl
```

> A criação da política roda como uma operação de longa duração e pode levar
> algum tempo para começar a apagar documentos. Documentos gravados antes da
> ativação que já tenham `expiresAt` no passado são removidos quando a política
> entra em vigor.

### Coleção raiz legada

Os logs antigos ficam na coleção raiz `ai_logs`, com prompt e resposta
completos e sem expiração. Nada mais escreve lá; o expurgo desses documentos é
uma tarefa manual separada (as regras do Firestore já negam leitura e escrita
pelo cliente).

## Idempotência dos gatilhos

Um gatilho do Firestore tem entrega **at-least-once**: o mesmo evento pode
chegar mais de uma vez (retry da plataforma, reentrega após timeout). Como os
handlers somam XP, movem saldo e atualizam faturas, reprocessar um evento
corrompe dados. `src/core/services/idempotency.service.ts` resolve isso com um
marcador em `_idempotency/{eventId}_{actionName}`.

A chave é `eventId_action` — **por ação, não por evento**: um mesmo evento
dispara vários blocos independentes (sumário, meta, saldo, fatura, XP,
cascata), e cada um precisa poder ser reexecutado sozinho. É também o que
permite que dois handlers observando o mesmo documento (finanças e
gamificação) não roubem a chave um do outro: os nomes de ação são distintos e
**estáveis** (`GAMIFICATION_ACTIONS` em `gamification_handler.ts`,
`AUTOMATIC_TRANSACTION_ACTION` em `automatic_transaction_handler.ts`). Mudar
um desses nomes faz o marcador antigo deixar de casar e a ação roda de novo
para eventos em voo.

O marcador é escrito **antes** da ação:

1. `create({status: "running", startedAt, expiresAt})` — `create` falha com
   `ALREADY_EXISTS` se alguém já reivindicou a chave, e é o Firestore que
   serializa a disputa. Nesse caso o handler sai sem rodar nada.
2. roda a ação;
3. `update({status: "done", finishedAt})`.

Se a ação **lançar**, o marcador é apagado e o erro é repropagado. Isso não
quer dizer que a plataforma vá tentar de novo: **nenhum trigger deste projeto
declara `retry: true`**, então hoje uma falha só é reexecutada se o evento for
reentregue (a entrega é at-least-once) — ou se o retry for ligado no futuro.
Apagar o marcador é o que mantém essa porta aberta: preso em `running`/`done`,
a ação nunca mais rodaria para aquele evento.

Um marcador `running` parado há mais de 10 minutos é considerado abandonado
(a instância morreu no meio): ele é apagado e a ação roda de novo.

`expiresAt` = criação + **30 dias**, recolhido pela política de TTL descrita
acima (a política de `_idempotency` ainda **não foi ativada** — o comando
`gcloud` está na seção anterior).

## Categorias de sistema (`isSystem`)

Algumas categorias existem para dar suporte a lançamentos sintéticos do servidor
e **não devem aparecer nas telas de gestão de categorias do cliente**. Elas são
criadas e mantidas exclusivamente pelas Cloud Functions (Admin SDK) e marcadas
com `isSystem: true`.

| Id                            | Nome                | Usada por                                      |
|-------------------------------|---------------------|------------------------------------------------|
| `initial-balance`             | Saldo Inicial       | orders `initial-balance-{accountId}`            |
| `virtual_debt_expense`        | Empréstimo/Dívidas  | contrapartida de transferência (summary.service)|
| `virtual_debt_income`         | Empréstimo/Dívidas  | contrapartida de transferência (summary.service)|
| `virtual_investment_expense`  | Investimentos       | contrapartida de transferência (summary.service)|
| `virtual_investment_income`   | Investimentos       | contrapartida de transferência (summary.service)|

Todas são criadas por `createDefaultCategories` (`onWorkspaceCreated`). Além de
sumirem das telas de gestão, elas são **ignoradas nas avaliações de badge**
(`under_control`, saúde financeira, missões mensais): não representam uma
escolha de consumo do usuário.

Contrato com o cliente Flutter:

- `isSystem`: booleano, **ausente == false**.
- `isDeleted`: booleano, **ausente == false**.
- As security rules impedem o cliente de criar uma categoria com
  `isSystem: true` e de editar/apagar uma categoria de sistema já existente.

## Contratos de `orders` e `installments`

Campos que o servidor mantém e o cliente Flutter lê:

| Campo                              | Semântica |
|------------------------------------|-----------|
| `order.amount`                     | **Realizado + planejado em aberto**: parcela paga entra pelo que de fato custou (`referenceAmount`), parcela em aberto pelo `amount`, parcela `removed` **não entra**. |
| `order.dueDay`                     | Só é reescrito quando o **vencimento** de uma parcela muda. Um pagamento não mexe nele. |
| `order.status = cancelled`         | Só quando **todas** as parcelas estão `removed` (inclusive removidas uma a uma). Junto vai `amount: 0`. |
| `installment.referenceAmount`      | Valor acurado da parcela: `paidAmount ?? amount` (o cliente já calcula assim em `installment_model.dart`). |
| `installment.replicationCascade`    | Zerado (`none`) pelo servidor assim que a cascata é consumida — pela escrita de xp num pagamento, ou por uma escrita própria no fim da cascata. **Nunca assuma o campo ausente.** |
| `installment.paidDate`             | `null` explícito quando não paga, em toda parcela criada pelo servidor (fluxo normal e cron de recorrência). |

Atenção a um detalhe que confunde: **pagar pelo app não zera o `amount`** — o
cliente preenche `paidAmount` e mantém o planejado (`finance_view_models.dart`).
O `amount` zerado só aparece nas parcelas que **nascem** pagas (saldo inicial,
compra já liquidada no cartão), onde `syncInstallments` zera o planejado de
propósito para a cobrança contar como não planejada. É por isso que o total da
order usa `referenceAmount` nas pagas: é o único campo que vale o realizado nos
dois casos.

## Crons de manutenção

| Function                            | Agendamento               | Fuso              |
|-------------------------------------|---------------------------|-------------------|
| `generateRecurringInstallments`     | `30 3 * * *` (diário)     | `America/Sao_Paulo` |
| `generateCategoryPlanningSummaries` | `0 0 1 * *` (dia 1)       | `America/Sao_Paulo` |
| `weeklyGamificationCron`            | `0 3 * * 1` (segunda)     | `America/Sao_Paulo` |
| `monthlyGamificationCron`           | `0 3 1 * *` (dia 1)       | `America/Sao_Paulo` |

`generateRecurringInstallments` rodava a cada 4 horas — 6 varreduras por dia de
uma tarefa cuja unidade de avanço é o **mês** (a order recorrente só ganha
parcela quando o horizonte de previsibilidade vira de mês). Passou a rodar uma
vez por dia, de madrugada.

As parcelas geradas pelo cron passam pela **mesma** função de criação das
parcelas normais (`FinanceRepositoryImpl.createInstallments`), de modo que o
documento gravado tenha sempre o mesmo formato — `Timestamp` em todas as datas,
`paidDate: null` explícito, `referenceDate`/`referenceAmount` preenchidos. Antes
o cron montava o documento por conta própria e as parcelas nasciam com um
schema ligeiramente diferente das criadas pelo app.

## Varredura de workspaces nos crons

Três crons tocam **todos** os workspaces: `generateWeeklyCoaching`,
`weeklyGamificationCron` e `monthlyGamificationCron`. Antes, cada um lia a
coleção inteira (`getAllWorkspaces()`) e percorria a lista em série dentro do
timeout. Com a base crescendo isso quebra de três jeitos: a lista toda na
memória, o tempo total como SOMA de todos os workspaces e — o pior — quando o
timeout estoura a execução morre no meio e a **próxima recomeça do zero**, de
modo que os workspaces do fim da coleção nunca são processados.

`forEachWorkspacePaged` (`src/core/utils/cron_runner.ts`) resolve os três:

- pagina por `documentId()` ascendente (`CRON_PAGE_SIZE`, 50 por query);
- processa em lotes paralelos (`CRON_WORKSPACE_CONCURRENCY` = 5;
  `CRON_AI_WORKSPACE_CONCURRENCY` = 3 no coaching, que chama o Gemini por
  workspace);
- grava **checkpoint a cada lote** e **para antes do deadline**
  (`CRON_SCAN_DEADLINE_MS` = 540s − 90s de margem), retomando do ponto exato na
  execução seguinte;
- **zera o checkpoint ao completar** a varredura, para a próxima começar do
  início;
- **isola falha**: um workspace que lança é logado, contado em `failed` e
  considerado consumido — um dado corrompido não trava o cron para todos os
  outros, execução após execução.

### Checkpoints

Um documento só, `config/cron_checkpoints`, com **um campo por cron**:

```
config/cron_checkpoints
  weekly_coaching:        { lastWorkspaceId: "...", updatedAt: <ts> }
  gamification_weekly:    { lastWorkspaceId: "...", updatedAt: <ts> }
  gamification_monthly:   { lastWorkspaceId: "...", updatedAt: <ts> }
```

Campo ausente = varredura começa do início. As chaves são **estáveis**: mudar
uma delas faz o cron recomeçar do zero uma vez. O documento é fechado para o
cliente pelo `match /{document=**} { allow read, write: if false }` das
security rules.

`monthlyGamificationCron` passou a usar `AI_SCHEDULE_OPTIONS`: ele herdava o
padrão global de **60 segundos**, e a varredura morria no meio do primeiro
minuto.

## Scripts de migração

Os scripts em `src/scripts/` são compilados para `lib/scripts/` junto com o
resto do projeto (`npm run build`) e executados manualmente com `node`.

> ⚠️ **Nenhum script deste diretório foi executado contra o projeto real
> (`funance-cef1b`).** Eles escrevem via Admin SDK e ignoram as security rules.
> Rode sempre o dry-run primeiro, revise a saída e só então aplique.

### `migrate_system_categories.ts`

Garante as cinco categorias de sistema em todos os workspaces: cria as que
faltam (tipicamente `initial-balance`) e acrescenta `isSystem: true` às que já
existem sem a flag (tipicamente as `virtual_*`). Workspaces novos já nascem
corretos; este script cobre a base legada.

- **Idempotente**: pula o que já está correto; pode rodar N vezes.
- **Não sobrescreve** nome/ícone/cor de documentos existentes — a atualização é
  um `set({isSystem: true}, {merge: true})`.
- **Dry-run por padrão**: só escreve com `--apply`.
- **Log por workspace/categoria**, com resumo final
  (`workspaces/criadas/marcadas/ignoradas/falhas`).

```bash
cd functions
npm run build

# 1) Simulação (padrão — não escreve nada)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/migrate_system_categories.js --project=<projectId>

# 2) Um único workspace, para validar o efeito antes da base inteira
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/migrate_system_categories.js --project=<projectId> --workspace=<workspaceId> --apply

# 3) Execução real na base inteira (somente após revisar o dry-run)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/migrate_system_categories.js --project=<projectId> --apply
```

| Flag              | Efeito                                                        |
|-------------------|---------------------------------------------------------------|
| _(nenhuma)_       | dry-run: apenas relata o que seria criado                      |
| `--apply`         | executa as escritas                                            |
| `--project=<id>`  | projectId do Firebase (default: `GOOGLE_CLOUD_PROJECT`)         |
| `--workspace=<id>`| limita a execução a um único workspace                          |

Saída de código: `0` se não houve falhas, `1` caso contrário.

A lógica do script é coberta por testes com mocks em
`src/test/migrate_system_categories.test.ts` (dry-run, idempotência, escopo por
workspace e contabilização de falhas).

### `backfill_last_generated_due_date.ts`

Preenche `lastGeneratedDueDate` nas orders **recorrentes** que estão sem o
campo, usando o vencimento da **última parcela já existente** da order.

Contexto: o cron `generateRecurringInstallments` estende uma order recorrente a
partir de `lastGeneratedDueDate`, e a query usa
`where("lastGeneratedDueDate", "<", threshold)` — o Firestore **não casa
documentos em que o campo não existe**, então uma order legada sem a marca
nunca é estendida. O serviço também se recusa a estendê-la: sem a marca não há
como saber onde a série parou (o fallback antigo assumia "hoje" e inventava
parcelas fora da série).

- **Idempotente**: pula orders que já têm o campo; pode rodar N vezes.
- **Não cria parcela nenhuma**: só grava a marca na order. Quem gera as parcelas
  faltantes é o cron diário, no formato normal.
- **Dry-run por padrão**: só escreve com `--apply`.
- **Log por order**, com resumo final
  (`orders/preenchidas/já_preenchidas/sem_parcelas/falhas`).

```bash
cd functions
npm run build

# 1) Simulação (padrão — não escreve nada)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/backfill_last_generated_due_date.js --project=<projectId>

# 2) Um único workspace, para validar antes da base inteira
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/backfill_last_generated_due_date.js --project=<projectId> --workspace=<workspaceId> --apply

# 3) Execução real na base inteira (somente após revisar o dry-run)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/backfill_last_generated_due_date.js --project=<projectId> --apply
```

| Flag              | Efeito                                                        |
|-------------------|---------------------------------------------------------------|
| _(nenhuma)_       | dry-run: apenas relata o que seria gravado                     |
| `--apply`         | executa as escritas                                            |
| `--project=<id>`  | projectId do Firebase (default: `GOOGLE_CLOUD_PROJECT`)         |
| `--workspace=<id>`| limita a execução a um único workspace                          |

Saída de código: `0` se não houve falhas, `1` caso contrário.

Coberto por testes com mocks em
`src/test/backfill_last_generated_due_date.test.ts` (dry-run, idempotência,
escolha da última parcela, escopo por workspace e contabilização de falhas).

### `rebuild_workspace.ts`

Reconstrói, para **um** workspace, tudo o que hoje os gatilhos mantêm de forma
incremental, recalculando do zero a partir de `installments` (ignorando as de
status `removed`, que são exclusão lógica) e `category_planning`:

| Coleção reconstruída | Semântica reproduzida |
|----------------------|------------------------|
| `accounts/{id}/balance/{YYYY-MM-DD}` | `FinanceService.applyInstallmentBalance` + `FinanceRepositoryImpl.updateAccountBalance` (saldo acumulado por dia; `credit` soma, `debt` subtrai; só parcelas pagas/liquidadas com `paidAmount` e `paidDate`) |
| `period_summaries/{YYYY|YYYY-MM|YYYY-Www}` | `SummaryService` (`specificPlannedAmount` por `dueDate`, `actualAmount` por `paidDate` com `paidAmount ?? amount`, categorias virtuais de transferência) |
| `weekly_xp/{YYYY-Www}` | `FinanceService.updateXpOnInstallmentChange` (soma de `calculateXp` das parcelas pagas, semanas iniciadas no domingo) |

> Os **gatilhos são o oráculo**: o job não redefine regra de negócio, ele
> reproduz o que `installment_handler`/`summary.service`/`finance.service`
> produzem. O saldo inicial entra naturalmente, porque a order sintética
> `initial-balance-{accountId}` gera uma parcela liquidada como qualquer outra.

> ⚠️ **`generalPlannedAmount` NÃO é reconstruível e por padrão é preservado.**
> Esse campo vem de `category_planning` através de `calculatePlanningImpacts`,
> que só projeta da data-base para a frente (12 meses). Recalcular **zera o
> planejado dos meses passados** e dá um resultado diferente a cada dia em que
> o job roda (rodar um mês depois come mais um mês de histórico). Por isso o
> rebuild lê o documento atual e **copia o `generalPlannedAmount` de cada
> categoria** tal como está; ele só é recalculado com `--rebuild-planning`
> (`rebuildPlanning: true`), que é destrutivo. O relatório conta à parte, por
> coleção, quantos documentos teriam o `generalPlannedAmount` alterado
> (`generalPlannedChanges`), para o dono saber de onde vem cada mudança.
>
> Consequência prática: um `generalPlannedAmount` errado **não** é corrigido
> pelo rebuild. Para refazê-lo, reescreva o planejamento pelo app (o gatilho
> `onCategoryPlanningWritten` recalcula) ou use a flag, com dry-run revisado.

> ⚠️ **O job não é transacional.** Ele lê o workspace, calcula em memória e só
> então commita em lotes: um pagamento feito no app entre a leitura e o commit
> é **sobrescrito**. Rode numa janela sem uso (ou com o app parado) e refaça o
> dry-run imediatamente antes do `--apply`.

Características:

- **Dry-run por padrão**: sem `--apply` nada é escrito, só o diff é impresso.
- **Idempotente**: aplicar duas vezes seguidas não muda nada; a segunda
  execução reporta zero diferenças.
- **Determinístico**: dinheiro é somado em centavos inteiros e os planejamentos
  são processados em ordem fixa de id.
- Escritas em lotes de no máximo 400 operações (`commitInChunks`). As parcelas
  são lidas em streaming, página a página — nenhuma lista de parcelas fica
  retida —, mas os **agregados** (saldo por conta/dia, sumários por período e
  XP por semana) ficam em memória e são eles que dimensionam o job.
- **Documentos residuais** não contam como divergência: um `period_summaries`/
  `weekly_xp` zerado (sobra de lançamento estornado/removido) ou um documento de
  saldo em dia sem movimento cujo valor é o próprio saldo acumulado. Eles são
  reportados à parte e só são apagados com `--prune-residual`.

> ⚠️ **Conta apagada logicamente**: `onAccountUpdated` apaga as orders/parcelas
> da conta marcada como `isDeleted`, mas não a subcoleção `balance`. Sem
> parcelas não há como reconstruir aquele histórico, então o rebuild propõe
> apagar os saldos remanescentes dela. Revise o dry-run antes de aplicar num
> workspace com contas apagadas.

```bash
cd functions
npm run build

# 1) Simulação (padrão — não escreve nada)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/rebuild_workspace.js --project=<projectId> --workspace=<workspaceId>

# 2) Execução real (somente após revisar a saída do dry-run)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/rebuild_workspace.js --project=<projectId> --workspace=<workspaceId> --apply
```

| Flag                | Efeito                                                              |
|---------------------|---------------------------------------------------------------------|
| _(nenhuma)_         | dry-run: só relata o que mudaria                                     |
| `--workspace=<id>`  | **obrigatória**: workspace a reconstruir                             |
| `--apply`           | executa as escritas                                                  |
| `--project=<id>`    | projectId do Firebase (default: `GOOGLE_CLOUD_PROJECT`)              |
| `--page-size=<n>`   | tamanho da página nas leituras (default 500)                         |
| `--chunk-size=<n>`  | operações por batch (default e máximo 400)                            |
| `--sample-limit=<n>`| caminhos listados por coleção no relatório (default 50)               |
| `--prune-residual`  | apaga também os documentos residuais descritos acima                 |
| `--rebuild-planning`| **destrutivo**: recalcula o `generalPlannedAmount` (zera o passado)   |

A mesma lógica está exposta no callable **`rebuildWorkspace`**
(`src/features/finance/presentation/functions/rebuild_handler.ts`), que é
**somente simulação**: aceita `{ workspaceId, rebuildPlanning? }` e **rejeita
`apply`/`pruneResidual` com `invalid-argument`**. Aplicar é exclusividade do
script operacional, que roda com service account, sob supervisão e depois de um
dry-run revisado. É restrito ao **dono do workspace** (`members[0]`, ver
`assertWorkspaceOwner` em `core/services/workspace_access.service.ts`) e **não
consome cota de IA** — não há chamada ao Gemini. Usa
`REBUILD_CALLABLE_OPTIONS` (512MiB/300s) com `maxInstances: 1`.

Testes: `src/test/rebuild.test.ts` (unitários com fixtures no formato real) e
`src/test/integration/rebuild.integration.test.ts` (emulador: cenário
determinístico com zero diferenças, planejamento antigo já acumulado, correção
de saldo/sumário corrompidos e teste de propriedade com 20 sequências
aleatórias de seed fixa — criar/pagar/estornar/remover, transferências para
conta de investimento e de dívida, `paidAmount` zerado e planejamentos —
comparando incremental × rebuild).
