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
  cache server-side (`generateCoaching`, 5 dias; `analyze503020Ideal`, 3 dias)
  o handler não chama `assertQuota`: ele monta um `QuotaGuard` e passa para o
  serviço, que faz `consume()` imediatamente antes de invocar o Gemini.
  Reabrir um insight/análise já existente não gasta nada.
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
  em `src/core/services/ai.service.ts`. Vale para os seis callables: os quatro
  sem cache (`analysePlanning`, os dois de documento e `analyzeGoalFeasibility`)
  fazem `consume()` no próprio handler e estornam no `catch`.

O documento de quota também recebe `createdAt` e `expiresAt` (criação + 90
dias) na primeira escrita do dia, para ser recolhido pela mesma política de
TTL descrita abaixo.

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

Se a ação **lançar**, o marcador é apagado e o erro é repropagado — sem isso o
retry automático da Function encontraria a chave e pularia a ação para sempre.
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
