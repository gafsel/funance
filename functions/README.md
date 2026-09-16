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

### `rebuild_workspace.ts`

Reconstrói, para **um** workspace, tudo o que hoje os gatilhos mantêm de forma
incremental, recalculando do zero a partir de `installments` (ignorando as de
status `removed`, que são exclusão lógica) e `category_planning`:

| Coleção reconstruída | Semântica reproduzida |
|----------------------|------------------------|
| `accounts/{id}/balance/{YYYY-MM-DD}` | `FinanceService.applyInstallmentBalance` + `FinanceRepositoryImpl.updateAccountBalance` (saldo acumulado por dia; `credit` soma, `debt` subtrai; só parcelas pagas/liquidadas com `paidAmount` e `paidDate`) |
| `period_summaries/{YYYY|YYYY-MM|YYYY-Www}` | `SummaryService` (`specificPlannedAmount` por `dueDate`, `actualAmount` por `paidDate` com `paidAmount ?? amount`, categorias virtuais de transferência e `generalPlannedAmount` vindo de `category_planning`) |
| `weekly_xp/{YYYY-Www}` | `FinanceService.updateXpOnInstallmentChange` (soma de `calculateXp` das parcelas pagas, semanas iniciadas no domingo) |

> Os **gatilhos são o oráculo**: o job não redefine regra de negócio, ele
> reproduz o que `installment_handler`/`summary.service`/`finance.service`
> produzem. O saldo inicial entra naturalmente, porque a order sintética
> `initial-balance-{accountId}` gera uma parcela liquidada como qualquer outra.

Características:

- **Dry-run por padrão**: sem `--apply` nada é escrito, só o diff é impresso.
- **Idempotente**: aplicar duas vezes seguidas não muda nada; a segunda
  execução reporta zero diferenças.
- **Determinístico**: dinheiro é somado em centavos inteiros e os planejamentos
  são processados em ordem fixa de id.
- Escritas em lotes de no máximo 400 operações (`commitInChunks`); leituras
  paginadas (o workspace inteiro nunca fica em memória).
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
| `--chunk-size=<n>`  | operações por batch (default 400, máximo 500)                        |
| `--prune-residual`  | apaga também os documentos residuais descritos acima                 |

A mesma lógica está exposta no callable **`rebuildWorkspace`**
(`src/features/finance/presentation/functions/rebuild_handler.ts`):
`{ workspaceId, apply?, pruneResidual? }`, dry-run por padrão, restrito ao
**dono do workspace** (`members[0]`, ver `assertWorkspaceOwner` em
`core/services/workspace_access.service.ts`) e **sem cota de IA** — não há
chamada ao Gemini. Usa `REBUILD_CALLABLE_OPTIONS` (512MiB/300s) com
`maxInstances: 1`, para que duas reconstruções não escrevam uma por cima da
outra.

Testes: `src/test/rebuild.test.ts` (unitários com fixtures no formato real) e
`src/test/integration/rebuild.integration.test.ts` (emulador: cenário
determinístico com zero diferenças, correção de saldo/sumário corrompidos e
teste de propriedade com 20 sequências aleatórias de seed fixa comparando
incremental × rebuild).
