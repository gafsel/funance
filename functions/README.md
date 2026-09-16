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

## Planejamento de categoria: horizonte rolante (F1.5)

O `generalPlannedAmount` dos `period_summaries` vem de `category_planning`. O
regime antigo tinha três defeitos que se somavam:

1. **o gatilho reaplicava sem estornar**: cada escrita no planejamento jogava 12
   meses de impacto por cima do que já estava lá. Editar o valor duas vezes
   triplicava o planejado;
2. **o cron mensal era inerte**: procurava `lastSummaryMonth < mês`, um campo
   que nenhum planejamento criado pelo app tinha. E, se achasse alguém, somaria
   tudo de novo — sem estorno;
3. **a semana era contada duas vezes**: a proporção semanal era emitida no dia 1
   *e* em todos os domingos, então o mês que começa no meio da semana contava a
   semana da virada duas vezes.

### O que o planejamento guarda agora

| Campo | Tipo | Semântica |
|-------|------|-----------|
| `summarizedUntil` | string | último mês já sumarizado (`YYYY-MM`). `"9999-12"` = o planejamento cabe inteiro no horizonte, nada mais a aplicar |
| `appliedAmount` | number \| null | valor efetivamente lançado |
| `appliedFrom` | string \| null | primeiro mês lançado (`YYYY-MM`) |
| `appliedUntil` | string \| null | último mês lançado (`YYYY-MM`) |
| `lastSummaryMonth` | string | **legado**: ninguém grava mais |

Os cinco são **escritos apenas pelo servidor** — as security rules negam ao
cliente tanto criar quanto alterar qualquer um deles.

### O gatilho

`onCategoryPlanningWritten` (`processCategoryPlanningChange`):

1. **estorna exatamente o que está marcado** como aplicado
   (`appliedAmount` no intervalo `appliedFrom..appliedUntil`) — e não um chute
   baseado no dia de hoje;
2. **reaplica** de `max(startMonth, mês corrente)` até
   `min(endMonth, mês corrente + 11)`;
3. grava os marcadores de volta no planejamento.

Estorno e reaplicação são **somados antes de virar escrita**: alterar só o fim
do período escreve apenas os meses que mudaram. A escrita dos marcadores gera um
novo evento, que o handler descarta pela guarda por conteúdo
(`CATEGORY_PLANNING_DERIVED_FIELDS`) — sem ela, o ciclo estorna e reaplica em
laço.

> Um planejamento **legado** (sem marcadores) é estornado pela janela que o
> gatilho antigo teria aplicado — exata se ele foi escrito neste mês, aproximada
> se foi antes. O conserto definitivo dos valores é o rebuild.

### A semana pertence ao mês do seu domingo

Cada semana (id `YYYY-Www`, pela função única de F1.9) pertence **ao mês em que
cai o seu domingo inicial**, e recebe `amount / diasNoMês * 7` **uma vez**.
Consequências:

- nenhuma semana é contada por dois meses;
- a semana da virada pertence ao mês do domingo, não aos dois;
- a soma das semanas de um mês fica entre ~93% e ~117% do valor mensal (4 ou 5
  semanas de 7 dias contra 28-31 dias de mês). É proporção semanal, não rateio
  exato — e é assim que o app a apresenta.

O documento do **ano** recebe `amount` por mês aplicado (a regra antiga jogava
`amount * 12` de uma vez em janeiro, contando meses fora do período).

### O cron mensal

`generateCategoryPlanningSummaries` (dia 1, 00:00 de Brasília) faz duas
passagens, ambas paginadas por cursor — o `GLOBAL_LIMIT = 500` sumiu:

1. `where("summarizedUntil", "<", horizonte)`: aplica **só os meses novos**, de
   `summarizedUntil + 1` até o horizonte, e atualiza os marcadores. Na virada de
   mês isso é exatamente um mês;
2. varredura dos **legados** (o Firestore não consulta "campo que não existe"):
   quem não tem `summarizedUntil` é **adotado** — o cron grava os marcadores
   **sem reaplicar impacto nenhum**, porque o gatilho antigo já os aplicou.
   Reaplicar aqui dobraria o planejado de toda a base. A varredura é limitada a
   2000 documentos por execução e avisa no log quando trunca; rodar
   `migrate_planning_summaries.ts` encerra essa passagem de vez.

### `migrate_planning_summaries.ts`

Grava nos planejamentos existentes os marcadores que eles deveriam ter
(`appliedFrom = max(startMonth, mês corrente)`,
`appliedUntil = min(endMonth, horizonte)`, `appliedAmount = amount`,
`summarizedUntil = horizonte` ou `"9999-12"`).

- **Idempotente**: pula quem já tem `summarizedUntil` (`--force` recalcula).
- **Dry-run por padrão**: só escreve com `--apply`.
- **Não toca em `period_summaries`**: os VALORES acumulados errados pelo regime
  antigo são corrigidos pelo rebuild (abaixo).

```bash
cd functions
npm run build

# 1) Simulação (padrão — não escreve nada)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/migrate_planning_summaries.js --project=<projectId>

# 2) Um workspace só
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/migrate_planning_summaries.js --project=<projectId> --workspace=<wid> --apply

# 3) Base inteira (somente após revisar o dry-run)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/migrate_planning_summaries.js --project=<projectId> --apply
```

| Flag              | Efeito                                                        |
|-------------------|---------------------------------------------------------------|
| _(nenhuma)_       | dry-run: apenas relata o que seria gravado                     |
| `--apply`         | executa as escritas                                            |
| `--project=<id>`  | projectId do Firebase (default: `GOOGLE_CLOUD_PROJECT`)         |
| `--workspace=<id>`| limita a execução a um único workspace                          |
| `--page-size=<n>` | planejamentos lidos por página (default 200)                    |
| `--force`         | recalcula os marcadores mesmo de quem já os tem                 |

### Ordem recomendada de execução

Nada disso foi executado contra o projeto real. A ordem é **migrações primeiro,
rebuild depois**:

```
1. migrate_balance_date_key.js      (dry-run → revisar → --apply)
2. migrate_planning_summaries.js    (dry-run → revisar → --apply)
3. rebuild_workspace.js --workspace=<wid>                 (dry-run → revisar → --apply)
4. rebuild_workspace.js --workspace=<wid> --rebuild-planning  (idem, por último)
```

O passo 4 é o que conserta os `generalPlannedAmount` acumulados pelo regime
antigo e os ids de semana gravados em UTC. Ele é **por workspace**, então numa
base grande o roteiro é um laço sobre os workspaces, sempre com o dry-run
revisado imediatamente antes.

### Contrato com o cliente Flutter

- `category_planning` ganhou quatro campos **somente leitura** para o app
  (`summarizedUntil`, `appliedAmount`, `appliedFrom`, `appliedUntil`). O app
  **não** deve enviá-los ao criar/editar um planejamento — as rules negam a
  escrita, e um formulário que reenvie o documento inteiro passa a ser rejeitado;
- `period_summaries` não mudou de forma: continua
  `categories.{categoryId}.generalPlannedAmount`. O que mudou é o valor — ele
  deixa de crescer sozinho a cada edição.

## Saldo diário: `dateKey` e `delta` (F1.4)

O documento `workspaces/{wid}/accounts/{aid}/balance/{dateKey}` mudou de forma:

| Campo | Tipo | Semântica |
|-------|------|-----------|
| _id do documento_ | string | **igual ao `dateKey`** — contrato preservado: o app lê os últimos saldos por `orderBy(documentId, desc)` |
| `dateKey` | string | `YYYY-MM-DD` no **fuso do produto** (`core/utils/date_key.ts#toDateKey`). Campo indexado |
| `delta` | number | soma dos movimentos **do dia** |
| `balance` | number | saldo **acumulado** ao fim do dia (inalterado) |
| `updatedAt` | Timestamp | carimbo da última escrita |

Três defeitos foram corrigidos de uma vez:

1. **o dia era em UTC** (`date.toISOString()`): um pagamento às 23h30 de
   Brasília entrava no dia seguinte;
2. **a transação estourava**: ela lia o dia, lia TODOS os saldos futuros e
   atualizava cada um lá dentro. Um pagamento retroativo de três anos passa de
   500 escritas e o commit falha por inteiro;
3. **a busca do dia anterior usava `orderBy(documentId(), "desc")`**, que o
   emulador rejeita (`does not support descending key scans`) e que em produção
   dependia do índice `balance __name__ DESC`.

O fluxo novo:

```
transação pequena  ──►  lê o doc do dia + o último doc anterior
                        grava delta += x e balance = anterior.balance + delta
propagação (fora)  ──►  pagina os dias seguintes e soma x ao balance,
                        em lotes de no máximo 400 escritas (commitInChunks)
```

- a busca do dia anterior é `where("dateKey", "<", key).orderBy("dateKey", "desc").limit(1)`
  — descendente por **campo**, não por chave. O índice de campo único está em
  `firebase/firestore.indexes.json` (`fieldOverrides` de `balance.dateKey`);
- a propagação pagina por **documentId ascendente**. O id É o `dateKey`, então a
  ordem é a mesma — e assim a varredura enxerga também os documentos legados,
  que ainda não têm o campo (e aproveita para preenchê-lo);
- a idempotência por evento continua vindo do `runIdempotency` do handler.

> **Concorrência.** O `delta` do dia é sempre exato (a transação serializa o
> dia) e a propagação usa `FieldValue.increment`, que é atômico. Resta uma
> janela de milissegundos: um segundo evento que **crie** um dia posterior
> entre o commit da transação e a consulta de propagação faz esse dia nascer já
> com o efeito do primeiro evento e receber o incremento outra vez. Só o
> acumulado é afetado, nunca o `delta`, e o `rebuild_workspace.ts` é o conserto.

### Compatibilidade com o formato antigo

Enquanto a migração não roda, convivem documentos com e sem `dateKey`/`delta`:

- **dia anterior**: depois da consulta indexada, o código faz uma sonda
  ascendente por id no intervalo `(candidato, dia)`. Numa base migrada o
  intervalo é vazio e custa uma leitura; numa base legada ele acha o documento
  sem `dateKey` que a consulta indexada não casaria;
- **dia atual sem `delta`**: o movimento do dia é inferido como
  `balance - saldo do dia anterior` — a mesma conta do script de migração;
- **propagação**: preenche o `dateKey` dos documentos por onde passa.

### `migrate_balance_date_key.ts`

Preenche `dateKey` (= id) e `delta` (= `balance` − `balance` do dia anterior)
nos documentos de saldo já existentes.

- **Idempotente**: pula o que já está correto e corrige `delta` divergente.
- **Dry-run por padrão**: só escreve com `--apply`.
- **Não move documento de dia**: ids gravados em UTC que deveriam estar no dia
  anterior continuam onde estão — corrigir isso é papel do
  `rebuild_workspace.ts`, que recalcula a série a partir das parcelas.
- **Não recalcula `balance`**: o acumulado gravado é a verdade para o script.
- Lê em páginas (`--page-size`, default 500) e escreve em lotes de 400.

```bash
cd functions
npm run build

# 1) Simulação (padrão — não escreve nada)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/migrate_balance_date_key.js --project=<projectId>

# 2) Um workspace só, para conferir o efeito
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/migrate_balance_date_key.js --project=<projectId> --workspace=<wid> --apply

# 3) Base inteira (somente após revisar o dry-run)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/migrate_balance_date_key.js --project=<projectId> --apply
```

| Flag              | Efeito                                                        |
|-------------------|---------------------------------------------------------------|
| _(nenhuma)_       | dry-run: apenas relata o que seria gravado                     |
| `--apply`         | executa as escritas                                            |
| `--project=<id>`  | projectId do Firebase (default: `GOOGLE_CLOUD_PROJECT`)         |
| `--workspace=<id>`| limita a execução a um único workspace                          |
| `--page-size=<n>` | documentos de saldo lidos por página (default 500)              |

Saída de código: `0` se não houve falhas, `1` caso contrário. Coberto por
`src/test/migrate_balance_date_key.test.ts`.

### Contrato com o cliente Flutter

O **id continua sendo `YYYY-MM-DD`**, então o app não quebra: ele pode seguir
lendo os últimos saldos por `documentId` descendente. Quando quiser, pode migrar
para `orderBy("dateKey", desc)`, que é equivalente e não depende de varredura
por chave. O campo `delta` é novo e opcional para o app — ele responde "quanto
se movimentou neste dia" sem precisar subtrair dois documentos.

## Semana: uma definição só (F1.9)

O id de semana `YYYY-Www` aparece em três lugares (`weekly_xp`,
`period_summaries` semanais e `weekly_missions`) e antes era calculado por três
aritméticas diferentes — duas em UTC (uma cópia privada dentro de
`finance.service.ts` e `core/utils/week.utils.ts`) e uma em `America/Sao_Paulo`
(`gamification_time.util.ts`). Um pagamento feito **sábado às 21h em São Paulo**
já é domingo em UTC: o XP caía numa semana e a missão em outra.

Agora existe **uma** implementação:

| Arquivo | Papel |
|---------|-------|
| `core/utils/timezone.utils.ts` | aritmética de calendário no fuso do produto (`PRODUCT_TIME_ZONE = America/Sao_Paulo`) — dia, mês, DST |
| `core/utils/week.utils.ts` | **única** definição de semana: `getWeekStart`, `getWeekRef`, `getWeekId`, `formatWeekId`, `weekStartFromRef` |
| `features/goal/domain/services/gamification_time.util.ts` | só reexporta os dois acima (mantido para não quebrar importações) |

Regra: a semana começa no **domingo 00:00 no fuso do produto**; o número é o
legado (`floor(diaDoAno(domingo) / 7) + 1`) e o ano é o **do domingo** que
inicia a semana — é isso que decide a virada de ano.

### Vetor de teste compartilhado com o app

`src/test/fixtures/week_vectors.json` lista instantes de borda (sábado 21h em SP
= domingo 00h UTC, viradas de ano, 1º de janeiro que cai num domingo, 29 de
fevereiro, entradas/saídas do antigo horário de verão) com o id esperado. Ele foi
gerado fora do TypeScript, de propósito, para não validar a implementação contra
ela mesma. `src/test/week_utils.test.ts` lê o arquivo e cobre todos os casos.

> **O cliente Dart deve passar no mesmo vetor.** A parte Dart é de outro pacote
> de trabalho; o arquivo JSON é o contrato entre os dois.

### Enquanto o app ainda calcula: `currentWeekId` no workspace

Para tirar a decisão do cliente, o servidor grava no documento do workspace:

| Campo | Tipo | Semântica |
|-------|------|-----------|
| `currentWeekId` | string | `YYYY-Www` da semana corrente (mesma regra de `weekly_xp`) |
| `currentWeekStart` | Timestamp | domingo 00:00 no fuso do produto |
| `currentWeekUpdatedAt` | Timestamp | quando o marcador foi reafirmado |

Quem escreve é `core/services/week_sync.service.ts`, por dois caminhos:

1. o cron `syncWorkspaceCurrentWeek` (**domingo, 00:10 de Brasília**), que
   varre os workspaces paginando por id e só escreve nos que estão atrasados;
2. sob demanda: todo handler que mexe em XP semanal chama `ensureCurrentWeek`,
   que tem memória por instância (uma leitura por workspace por semana) e
   **nunca cria** o documento do workspace.

Os três campos são exclusivos do servidor — o `allow update` do workspace usa
`affectedKeys().hasOnly([...])` com uma lista fechada que não os inclui.

### Migração dos ids antigos

Os documentos `period_summaries/{YYYY-Www}` e `weekly_xp/{YYYY-Www}` gravados
com a regra antiga (UTC) podem estar no id errado quando o movimento caiu no
sábado à noite. Não há script dedicado: **o `rebuild_workspace.ts` já
reconstrói as duas coleções com a regra nova** — rode o dry-run, revise o diff
(ele mostra `criar 2026-W37` / `apagar 2026-W36`, por exemplo) e só então
aplique. Nada disso foi executado contra o projeto real.

## Crons de manutenção

| Function                            | Agendamento               | Fuso              |
|-------------------------------------|---------------------------|-------------------|
| `generateRecurringInstallments`     | `30 3 * * *` (diário)     | `America/Sao_Paulo` |
| `generateCategoryPlanningSummaries` | `0 0 1 * *` (dia 1)       | `America/Sao_Paulo` |
| `syncWorkspaceCurrentWeek`          | `10 0 * * 0` (domingo)    | `America/Sao_Paulo` |
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

| Script | O que faz | Documentado em |
|--------|-----------|----------------|
| `migrate_system_categories.ts` | garante as categorias de sistema | aqui |
| `backfill_last_generated_due_date.ts` | marca onde a série recorrente parou | aqui |
| `migrate_balance_date_key.ts` | `dateKey`/`delta` nos saldos diários | [Saldo diário (F1.4)](#saldo-diário-datekey-e-delta-f14) |
| `migrate_planning_summaries.ts` | marcadores do planejamento | [Planejamento (F1.5)](#planejamento-de-categoria-horizonte-rolante-f15) |
| `rebuild_workspace.ts` | reconstrói saldos, sumários e XP | aqui |

**Ordem recomendada quando este pacote for para produção**: as duas migrações
novas (na ordem acima), depois `rebuild_workspace` e, por último, o mesmo
rebuild com `--rebuild-planning`. O detalhamento está na seção de F1.5.

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
| `accounts/{id}/balance/{dateKey}` | `FinanceService.applyInstallmentBalance` + `FinanceRepositoryImpl.updateAccountBalance` (`dateKey`/`delta`/`balance` — dia no fuso do produto; `credit` soma, `debt` subtrai; só parcelas pagas/liquidadas com `paidAmount` e `paidDate`) |
| `period_summaries/{YYYY|YYYY-MM|YYYY-Www}` | `SummaryService` (`specificPlannedAmount` por `dueDate`, `actualAmount` por `paidDate` com `paidAmount ?? amount`, categorias virtuais de transferência) |
| `weekly_xp/{YYYY-Www}` | `FinanceService.updateXpOnInstallmentChange` (soma de `calculateXp` das parcelas pagas; semana pela definição única de F1.9, domingo no fuso do produto) |

> Os **gatilhos são o oráculo**: o job não redefine regra de negócio, ele
> reproduz o que `installment_handler`/`summary.service`/`finance.service`
> produzem. O saldo inicial entra naturalmente, porque a order sintética
> `initial-balance-{accountId}` gera uma parcela liquidada como qualquer outra.

> ⚠️ **`generalPlannedAmount` por padrão é PRESERVADO.** Esse campo vem de
> `category_planning`, e o rebuild lê o documento atual e copia o valor de cada
> categoria tal como está. Ele só é recalculado com `--rebuild-planning`
> (`rebuildPlanning: true`). O relatório conta à parte, por coleção, quantos
> documentos teriam o `generalPlannedAmount` alterado
> (`generalPlannedChanges`), para o dono saber de onde vem cada mudança.
>
> Desde F1.5 esse recálculo é **determinístico**: ele cobre todos os meses de
> `startMonth` até `min(endMonth, horizonte)`, e a única dependência de "hoje" é
> o horizonte (mês corrente + 11). Rodar hoje e amanhã dá o mesmo resultado;
> rodar no mês que vem só acrescenta o mês da ponta. Não é mais verdade que o
> recálculo "zera o passado" — ao contrário, ele **preenche** os meses passados
> do período, que o incremental nunca preencheu (o gatilho nunca reescreve o
> passado). Por isso a flag continua sendo uma escolha consciente, e não o
> padrão: o dry-run mostra exatamente quais documentos mudam.

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
