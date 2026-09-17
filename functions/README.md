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

### `actionPath` dos slides de coaching

O `actionPath` de um slide vira `context.push` no app, então ele é validado
contra uma **allowlist de rotas** (`sanitizeActionPath`, em
`coaching.service.ts` — a mesma lista que o prompt em `ai.config.ts` enumera).
Rota fora da lista: o slide vai **sem botão**.

A allowlist casa só o **caminho**; a **query string sobrevive filtrada**, um
parâmetro conhecido por vez, com valor dentro da lista e em ordem
determinística. Parâmetro ou valor desconhecido é descartado em silêncio — a IA
alucina query string com a mesma facilidade com que alucina rota.

**`/transactions/form` exige `?status=`.** Desde que o app passou a assumir
`paid` por padrão, um path sem `status` abre o formulário já como "Registrei" —
o lançamento dado como feito. As duas formas válidas são:

| Intenção do slide | Path |
|---|---|
| agendar, planejar, reservar, criar teto para o futuro | `/transactions/form?status=pending` |
| registrar algo que já foi pago ou recebido | `/transactions/form?status=paid` |

Opcionalmente com `&type=expense|income|transfer`. O prompt instrui a IA nos
dois casos; quando ela ainda assim omite o `status` (ou manda um valor fora da
lista), o validador injeta **`pending`** — um slide de coaching propõe uma ação
a TOMAR, e é mais seguro o usuário marcar como pago do que dar por registrado o
que não aconteceu.

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
| `cycleStart`/`cycleEnd`/`closingDate` | **Só em fatura** (order e parcela com `isInvoice`): a janela de compras daquela fatura, escrita pelo servidor (F1.8). Ausente em tudo que não é fatura e nas faturas anteriores ao pacote. |

Atenção a um detalhe que confunde: **pagar pelo app não zera o `amount`** — o
cliente preenche `paidAmount` e mantém o planejado (`finance_view_models.dart`).
O `amount` zerado só aparece nas parcelas que **nascem** pagas (saldo inicial,
compra já liquidada no cartão), onde `syncInstallments` zera o planejado de
propósito para a cobrança contar como não planejada. É por isso que o total da
order usa `referenceAmount` nas pagas: é o único campo que vale o realizado nos
dois casos.

## Categoria sem id: fora dos sumários

Existem em produção parcelas e orders com a categoria embutida **sem id**:

```json
{ "category": { "id": "", "name": "Supermercado", "type": "expense" } }
```

Elas vieram da conciliação/transação automática, que gravava o nome sugerido
pela IA antes de resolver o documento da categoria. O estrago é desproporcional
ao defeito: o sumário grava `categories.<id>`, e um id vazio vira um **segmento
vazio de `FieldPath`** — o SDK rejeita o documento inteiro com
`Error: Element at index 0 should not be an empty string`. O gatilho de sumário
quebrava, e o `rebuild_workspace --apply` morria no commit (o **dry-run não
acusa nada**, porque nem chega a montar a referência).

**REGRA ÚNICA** (`hasCategoryId`, em `workspace/domain/models/category.model.ts`):
categoria sem id é tratada como **sem categoria** para efeito de sumário.

| Onde | O que acontece |
|------|----------------|
| `summary.service.ts` (projetado e realizado) | a parcela **não entra** em `period_summaries`, com um `console.warn` **por parcela** citando workspace e parcela |
| `rebuild.service.ts` (acumulador) | idem, e a parcela é contada em `scanned.installmentsWithoutCategory` no relatório |
| `finance.repository.impl.ts` (`updatePeriodSummary`) | **defesa final**: lança erro citando workspace, período e nome da categoria, em vez de deixar o SDK explodir com uma mensagem sem contexto |
| `finance.repository.impl.ts` (`applyPlanningImpacts`) | um `category_planning` com id vazio é **pulado com `console.warn`**, em vez de montar `categories[""]` e derrubar o gatilho/cron de planejamento inteiro |

**Quem é avisado e contado** (`isCategoryRefBroken`, no mesmo arquivo). Ficar
"sem categoria utilizável" não é defeito por si só: **transferência nunca tem
categoria por desenho** — quem lhe dá chave de sumário é o caminho das
categorias virtuais, e uma transferência sem contrapartida de
dívida/investimento fica fora do sumário como sempre ficou. Fatura entra na
mesma regra, porque também é `type: "transfer"`. A regra é:

| Parcela | Avisa e conta? |
|---|---|
| `category = {id: "", name: "..."}` (qualquer `type`) | **sim** — é o defeito real |
| categoria **ausente** e `type !== "transfer"` | **sim** |
| categoria **ausente** e `type === "transfer"` (transferência, fatura) | **não** — silêncio |

Antes desta regra o relatório de um rebuild de produção acusou **98 parcelas
"sem categoria", todas transferências saudáveis**, e o log do gatilho enchia do
mesmo falso positivo.

**Saldo e XP continuam contando normalmente** — nenhum dos dois depende de
categoria. O que essas parcelas perdem é só a linha no sumário, até serem
corrigidas pelo script [`fix_empty_category.ts`](#fix_empty_categoryts).

Testes: `src/test/empty_category.test.ts` (gatilho), os casos de
`src/test/rebuild.test.ts` e `src/test/finance_repository.test.ts`, e
`src/test/integration/empty_category.integration.test.ts`, que prova o sintoma
com o SDK de verdade (a escrita de `categories.""` é rejeitada) e que gatilho e
`rebuild --apply` agora atravessam a parcela quebrada sem falhar.

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
   Reaplicar aqui dobraria o planejado de toda a base. A varredura tem teto por
   execução — 2000 **adoções** (as escritas) e 10000 leituras — e guarda onde
   parou em `config/cron_checkpoints.planningLegacyScanPath`, retomando dali na
   execução seguinte em vez de recomeçar do início do grupo de coleções. Quando
   a varredura chega ao fim, o checkpoint é zerado. Rodar
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

### Ordem de execução

A ordem completa do rollout está em [Ordem de rollout](#ordem-de-rollout) — em
resumo: **migrações primeiro, rebuild depois**, e o rebuild com
`--rebuild-planning` **antes do segundo cron mensal**.

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

### O mês do sumário também é do fuso do produto

Dia, semana, **mês e ano** dos `period_summaries` vêm todos do mesmo fuso. O mês
e o ano ficaram para trás numa primeira versão (`getFullYear()/getMonth()`, ou
seja, UTC no servidor): um pagamento às 23h30 de 31/10 em São Paulo é 01/11 em
UTC e ia para o sumário de **novembro**, enquanto o saldo do mesmo pagamento
ficava em outubro. `SummaryService` e `rebuild.service.ts` usam
`getZonedParts` (reexportado por `core/utils/date_key.ts`, junto de `toDateKey`
e `toMonthKey` — é o ponto único de entrada da "data do produto").

### Migração dos ids antigos

Os documentos `period_summaries/{YYYY|YYYY-MM|YYYY-Www}` e
`weekly_xp/{YYYY-Www}` gravados com as regras antigas podem estar no id errado
quando o movimento caiu perto da meia-noite de Brasília — a semana, quando foi
no sábado à noite; **o mês e o ano, quando foi na virada do mês** (um realizado
de 31/10 contabilizado em novembro). Não há script dedicado: **o
`rebuild_workspace.ts` reconstrói as três coleções com as regras novas** — rode
o dry-run, revise o diff (ele mostra `criar 2026-10` / `alterar 2026-11`, por
exemplo) e só então aplique. Nada disso foi executado contra o projeto real.

## Metas (`goals`): progresso automático nos quatro tipos

Os quatro tipos de meta são `saveMoney`, `reduceExpense`, `reduceCreditCard` e
`payDebt`. O discriminador gravado é **`runtimeType`** (nome do factory freezed
do cliente); o campo `type` do modelo Flutter é um getter e **não** é
serializado — por isso o servidor lê tudo por `resolveGoalType`.

Até aqui só `saveMoney` e `reduceCreditCard` andavam. `reduceExpense` (ligada a
uma **categoria**) e `payDebt` (ligada a uma **conta de dívida**) nunca
progrediam, e mesmo assim a Jornada mostrava barra e "Faltam R$ X" — números
que ninguém atualizava.

### De onde sai o `currentAmount` de cada tipo

| Tipo | Fonte da verdade | Quando é recalculado |
|---|---|---|
| `saveMoney` em conta **de investimento** (cofrinho) | **saldo atual da conta** (piso zero) | **recálculo total** quando uma parcela daquela conta muda |
| `saveMoney` em qualquer outra conta | parcelas pagas da conta desde `startDate`: crédito soma, débito subtrai | **delta** do evento de parcela |
| `reduceCreditCard` | parcelas pagas da conta desde `startDate`: só os débitos | **delta** do evento de parcela |
| `reduceExpense` | `actualAmount` da categoria nos `period_summaries` **mensais** do período da meta | **recálculo total** quando uma parcela daquela categoria muda |
| `payDebt` | `saldo atual da conta − saldo no fim do dia ANTERIOR ao startDate` (piso zero) | **recálculo total** quando uma parcela daquela conta muda |

Em `saveMoney` e `payDebt`, `currentAmount` é **conquista**: quanto já foi
juntado ou amortizado, e alcançar o alvo é vencer. Em `reduceExpense` e
`reduceCreditCard` ele é **gasto contra um teto**: passar do alvo é **estourar o
orçamento**, e é por isso que a conclusão de uma meta não pode ser inferida
desse número — ver "Contrato: meta ativa e desfecho".

**Decisão — `saveMoney` de cofrinho mede SALDO, não aportes.** Quando a conta da
meta é do tipo `investment` (cofrinho, reserva, caixinha), o progresso é o
**saldo atual da conta**, com piso zero: o dinheiro que está lá **é** o que foi
guardado, inclusive o que já estava antes de a meta existir. Somar apenas os
aportes desde o `startDate` fazia uma meta criada hoje sobre um cofrinho cheio
nascer em zero — caso real: meta "Disney 2030" na conta "Cofrinho Disney" com
R$ 263,41 e `startDate` = hoje, mostrando **0 de 263,41 guardados**.

Em qualquer outro tipo de conta (corrente, cartão, dívida) a regra continua
sendo **o que entrou desde o início** — créditos menos débitos das parcelas
pagas. Uma conta corrente tem saldo por mil motivos alheios à meta; ali o saldo
não é progresso nenhum, só o aporte conta.

A consequência operacional é a mesma de `payDebt`: `saveMoney` de cofrinho sai
do caminho do **delta** e passa a ser **recálculo total** no gatilho de parcela,
lendo o saldo mais recente da conta. O tipo da conta custa **uma leitura de
documento por conta do evento**, reaproveitada por todas as metas dela e buscada
só quando existe alguma `saveMoney`. Cofrinho sem nenhum saldo gravado mantém o
progresso, em vez de zerá-lo.

**Decisão — `reduceExpense` lê os sumários mensais, não as parcelas.** O
documento mensal já é a consolidação que o próprio servidor mantém
(`actualAmount` = soma de `paidAmount ?? amount` das parcelas pagas, por
`paidDate`), então a regra é a mesma; muda o custo. Uma varredura de parcelas
cresce com o histórico da categoria e seria refeita a cada pagamento; a leitura
mensal custa um documento por mês do período (com máscara de campo, só a entrada
daquela categoria) e não cresce com o uso. **Consequência aceita:** os meses
entram inteiros — uma meta que começa dia 10 conta também os dias 1 a 9 daquele
mês. Contar meio mês exigiria exatamente a varredura que estamos evitando.
Períodos acima de 120 meses são truncados nos meses mais recentes, com aviso no
log.

**Como os saldos são lidos.** `orderBy(documentId(), "desc")` e
`limitToLast(1)` são recusados pelo Firestore com
`FAILED_PRECONDITION: Firestore does not support descending key scans`. A
leitura usa o mesmo caminho duplo do repositório de finanças: query indexada
por `dateKey` descendente (uma leitura numa base migrada) e varredura
ASCENDENTE por id no intervalo aberto `(candidato, limite]`, que recupera os
documentos legados sem `dateKey`. Enquanto a migração de `dateKey` não rodar,
é a varredura que responde.

**`payDebt` e o sinal do saldo.** O saldo de uma conta de dívida é **negativo**
(é o que o app assume, ver `goal_form_provider.dart`), e amortizar aproxima o
saldo de zero. Daí `amortizado = saldoAtual − saldoNoInício`, que é a mesma
conta que "dívida no início − dívida hoje" em módulo. Dívida que **cresceu** não
vira progresso negativo: o piso é zero.

**O marco zero é o saldo no FIM DO DIA ANTERIOR ao início.** O documento diário
guarda o saldo **acumulado ao fim do dia**, então o saldo do próprio
`startDate` já inclui o que foi pago naquele dia. Ler `dateKey <= startKey`
fazia o primeiro pagamento da meta nascer dentro do marco zero e sumir do
progresso; o limite é **exclusivo** (`dateKey < startKey`, nos dois caminhos —
query indexada e varredura legada). Caso real de produção: meta "Pagar dívida
Itaú" com `startDate` 2026-06-22 e saldos `2026-06-08 = −19058,90` e
`2026-06-22 = −15247,16`. O marco correto é **−19058,90** (progresso
**11435,00**); o limite inclusivo tomava −15247,16 e mostrava 7623,00 — faltava
exatamente o pagamento feito no dia 22. Uma meta que começa num dia **sem**
documento de saldo não muda de comportamento: os dois limites caem no mesmo
documento anterior.

**Ordem dentro do gatilho de parcela.** O bloco `processGoalChange` roda
**depois** de `processSummaryChange` e de `updateAccountBalance`
(`installment_handler.ts`): as duas metas recalculadas leem exatamente o que
esses dois blocos acabaram de escrever. Antes da mudança de ordem elas ficariam
sempre um evento atrasadas.

Metas também são recalculadas **na escrita da própria meta** (`onGoalWritten`,
ação de idempotência `gamification:goalRecompute`), para uma meta nova nascer
com o progresso real do histórico. O recálculo só escreve quando o valor muda,
então a escrita que ele provoca não reentra.

### Contrato: meta ativa e desfecho

O documento de meta **não tem `status`** — o cliente nunca gravou um. Os badges
liam `status === "active"`/`"completed"` e por isso jamais disparavam.

O desfecho de uma meta é um campo **gravado**, não inferido de `currentAmount`:

```
outcome: "success" | "failed" | ausente     # ausente = ainda em andamento
completedAt: Timestamp                      # instante do sucesso
failedAt:    Timestamp                      # instante da falha
```

Por que gravado. Numa meta de **redução**, `currentAmount` é o quanto já foi
**gasto** contra um teto: passar do alvo é **fracasso**, e o sucesso só se
conhece quando o prazo termina com o gasto ainda dentro do teto. Nenhuma
comparação instantânea entre valor e alvo distingue "vai bem, ainda dentro do
teto" de "terminou dentro do teto" — a comparação que existia antes tratava o
estouro como conclusão, tirava a meta do pool de ativas e **concedia os badges
de conclusão por ter estourado o orçamento**.

| Família | Sucesso | Falha |
|---|---|---|
| acúmulo (`saveMoney`, `payDebt`) | alcançou o alvo, a qualquer momento | prazo venceu sem alcançar |
| redução (`reduceExpense`, `reduceCreditCard`) | prazo venceu com o gasto **dentro** do teto | passou do teto, a qualquer momento |

```ts
isGoalActive(goal)    // !isDeleted && outcome == null &&
                      // (sem deadline || deadline >= hoje)
isGoalCompleted(goal) // outcome === "success"
isGoalFailed(goal)    // outcome === "failed"
```

- O desfecho é **terminal**: uma meta que já desfechou não é reavaliada. Ele tem
  efeito fora do documento (badges concedidos, XP creditado) e badge não se
  devolve — um estorno que derruba o valor depois não pode desconceder nada.
- Escrito **só pelo servidor**, em dois caminhos: junto do recálculo do
  progresso (`GoalServiceImpl.writeProgress`) e pelo cron de vencimento
  (`closeExpiredGoals`). As security rules negam ao cliente criar ou alterar
  `outcome`, `completedAt` e `failedAt` — o app grava a meta com `update`, que
  só toca os campos enviados, então o desfecho sobrevive a uma edição.
- Badges de conclusão (`savings_seed`, `goal_bronze`, `goal_silver`,
  `goal_under_deadline`, `short_term_goal`, `goal_debt_paid`) exigem
  `outcome === "success"`. Os de progresso (`goal_halfway`, `goal_75pct`,
  `goal_deposit`, `savings_start`) só valem para meta de **acúmulo**: "Na Metade
  do Caminho" por ter consumido metade do orçamento premiava o contrário do que
  a meta pede.
- No app: sucesso é "Concluída em"; falha é "Limite estourado em" (redução) ou
  "Prazo encerrado sem atingir" (acúmulo), com o visual de erro. Metas
  encerradas ficam numa seção própria, fora da lista das que ainda correm.
- **`currentAmount` continua gravável pelo cliente** (a meta nasce em zero pelo
  formulário), mas o formulário não pede mais esse valor: quem o mantém é o
  servidor.

### Cron `closeExpiredGoals`

Roda todo dia às **03:15** (America/Sao_Paulo) e carimba o desfecho das metas
com `outcome` ausente e `deadline` já vencido.

Existe porque o sucesso de uma meta de redução é a **ausência** de um evento: o
gasto não passou do teto até o vencimento. Nenhum gatilho dispara no dia do
vencimento, então sem o cron essas metas ficariam "em andamento" para sempre — e
o mesmo vale para a meta de acúmulo que vence sem alcançar o alvo.

- Varredura paginada com checkpoint (`forEachWorkspacePaged`, chave
  `close_expired_goals`): um timeout retoma do ponto exato na execução seguinte.
- **Idempotente**: só toca meta sem desfecho, e não altera `currentAmount`.
- Dispara as checagens de badge para cada meta fechada — só as de sucesso
  concedem alguma coisa.
- O mesmo veredito é aplicado no `onGoalWritten` e no recálculo: uma meta cujo
  prazo venceu desfecha na primeira escrita que passar por ela, mesmo que o
  valor não mude.

## Catálogo de badges (`config/badges`)

O catálogo de badges era espelhado **à mão** no Flutter
(`badges_cabinet_screen.dart`: ~130 entradas com o XP como string, mais as
descrições nos ARB), e o nível era recalculado no app com a inversa de
`calculateLevel`, em dois lugares. O servidor passou a publicar tudo:

```
config/badges
  version: string            # hash do conteúdo (16 hex)
  badges: [{ id, name: {pt, en}, icon, xpReward, category, description: {pt, en} }]
  levelThresholds: number[]  # XP mínimo de cada nível, 20 níveis
  xpSources: [{ id, name: {pt, en}, xp, description: {pt, en} }]   # F2.3
  updatedAt: timestamp
```

- `name` e `description` são mapas **por locale**. O português vem da definição
  do badge (`BADGES`); o inglês, de `badge_catalog.i18n.ts` — as mesmas strings
  que saíram dos ARB do app quando o catálogo virou responsabilidade do
  servidor. O app escolhe pelo idioma do usuário com **fallback para `pt`**, e
  também aceita o formato antigo (texto em string pura), que fica publicado até
  o cron republicar depois do deploy.
- `category` ∈ `advanced | first_steps | consistency | savings | goals | team`.
- `icon` é o nome do ícone Material (o app mapeia nome → `IconData`).
- `levelThresholds[n-1]` é o XP que abre o nível `n` — a tabela é a inversa
  fiel de `calculateLevel` (`300 * (2^(n-1) - 1)`), coberta por teste.
- `xpSources` (F2.3) é a tabela "como ganhar XP" que o app exibe — ver
  [XP que premia planejar](#xp-que-premia-planejar-f23). Ela mora aqui, e não
  num documento por workspace, porque é configuração do PRODUTO: os valores são
  iguais para todo mundo e mudam por deploy. **`workspaces/{w}.xpSources` não
  existe.**
- `xpReward: 0` é um valor **legítimo**: desde F2.3 os badges de contagem
  continuam na vitrine como conquista, mas não pagam mais XP.
- `version` é o **hash do conteúdo** (badges + limiares + `xpSources`): ninguém
  precisa lembrar de incrementar nada. Mudou um nome, um XP, um limiar ou uma
  fonte de XP, muda o hash e a próxima execução publica.

**Quem publica:** o cron diário `publishBadgeCatalog` (`maxInstances: 1`), que
lê a versão publicada e só escreve se ela mudou. É o caminho mais simples que
não depende de evento de usuário nenhum: um deploy que mexe no catálogo se
propaga sozinho em até 24 h. O **primeiro** publish (antes da primeira execução
do cron) é feito pelo script `publish_badge_catalog.ts`.

**Rules:** `config/badges` é legível por **qualquer usuário autenticado** e
fechado para escrita. Os demais documentos de `config` (`ai`,
`cron_checkpoints`) continuam negados pelo `match /{document=**}`.

**Pendência de i18n:** `name` e `description` são servidos em **português**. O
app não tem mais as strings de badge nos ARB — internacionalizar o catálogo
(campo por locale, ou um documento por idioma) fica para quando houver um
segundo idioma de verdade.

## Fatura: uma implementação, no servidor (F1.8)

A regra de fatura existia **duas vezes**: em `invoice.service.ts` e numa cópia
Dart (`lib/features/finance/domain/services/invoice_service.dart`). As duas já
divergiam — a Dart não clampava o dia em `calculateInvoiceDueDate`, só em
`calculateInvoiceCycleRange` —, e como o **id da order de fatura deriva da
data** (`invoice-{accountId}-{YYYY-MM-DD}`), cliente e servidor podiam apontar
para faturas diferentes. Com vencimento 31, o app calculava 03/03 e o servidor
28/02: duas faturas, uma para cada lado.

A cópia Dart foi **removida**. O servidor é a única fonte de vencimento,
fechamento e janela de ciclo; o app lê.

### O que mudou em `invoice.service.ts`

| Antes | Agora |
|-------|-------|
| 8 feriados fixos, com um comentário dizendo que os móveis "exigiriam cálculo mais complexo" | os móveis saem da Páscoa (Meeus/Gauss): Carnaval (terça, −47), Sexta-feira Santa (−2), Corpus Christi (+60), memoizados por ano |
| `getDay()`/`getDate()`/`toISOString()` — UTC no servidor | `getZonedParts`/`toDateKey` (`America/Sao_Paulo`) |
| clamp só no VENCIMENTO | clamp no vencimento **e** no fechamento |
| sem `calculateInvoiceCycleRange` | a janela do ciclo vive aqui |

O clamp do fechamento é o que conserta fevereiro: com fechamento 31, o cartão
fecha no dia 28 (ou 29). Antes, `refDay < closingDay` era sempre verdadeiro em
fevereiro e a compra do dia 28 — o próprio dia do fechamento efetivo — caía na
fatura errada.

> **O feriado adia a compra, nunca o vencimento.** O dia útil seguinte é
> aplicado à data de REFERÊNCIA da compra. Mover o vencimento mudaria o id da
> order e o mês do ciclo (que é derivado do mês do vencimento), criando uma
> fatura nova a cada recálculo. Uma fatura que vence em Corpus Christi continua
> vencendo em Corpus Christi.

Coberto por `src/test/invoice.test.ts` — feriados móveis de 2025 a 2027 com
datas conhecidas, clamp nos dois lados, virada de ano, o teste de que a janela
é o inverso do vencimento para toda compra em dia útil, e os casos de fuso
(compra às 22h em São Paulo, que em UTC já é o dia seguinte).

### `accounts/{accountId}.nextInvoice`

Resumo da próxima fatura, denormalizado no documento da conta de cartão:

| Campo | Tipo | Semântica |
|-------|------|-----------|
| `dueDate` | Timestamp | vencimento (meio-dia no fuso do produto) |
| `closingDate` | Timestamp | fechamento que gerou esta fatura (00:00) |
| `cycleStart` | Timestamp | primeira compra da fatura — 00:00, **inclusive** |
| `cycleEnd` | Timestamp | última compra da fatura — 23:59:59.999, **inclusive** |
| `amount` | number | valor em aberto; `0` quando o ciclo ainda não acumulou nada |
| `orderId` | string | `invoice-{accountId}-{YYYY-MM-DD}` |
| `installmentId` | string \| null | parcela da fatura, `null` enquanto ela não existe |
| `status` | string | status da parcela (`pending` quando não existe) |
| `updatedAt` | Timestamp | carimbo da última sincronização |

A fonte é a **fatura em aberto mais próxima** (`isInvoice` + `accountIds` +
`status: pending`, ordenada por `dueDate`) — a mesma consulta que o app fazia em
`watchNextInvoice`, agora feita de um lado só. Uma fatura **vencida e não paga**
continua sendo a próxima: é justamente a que o usuário precisa ver. Sem fatura
em aberto (cartão novo, ou fatura zerada e apagada), o ciclo corrente é
calculado e o valor vai zero, para o app ter a janela e a data certas.

Quem escreve é `InvoiceSyncService`, por três caminhos:

1. **`processInvoiceUpdate`**, para os cartões que o evento de fato tocou — a
   parcela de fatura em si, ou um cartão que recebeu delta. Uma parcela pendente
   de cartão não mexe em fatura e não custa leitura nenhuma;
2. **`onAccountCreated`/`onAccountUpdated`**, quando `closingDay`, `dueDay` ou
   `runtimeType` mudam, e quando a conta é apagada logicamente (aí o resumo é
   REMOVIDO — um cartão apagado não cobra mais nada);
3. **o cron diário `syncNextInvoices`** (03:45 de Brasília), que cobre o único
   caso sem evento: o vencimento chega e o ciclo vira num cartão parado. Usa
   `forEachWorkspacePaged` (checkpoint `next_invoice_sync`) e só toca em cartão
   sem resumo ou com o vencimento já vencido.

> ⚠️ **Escrever só quando MUDA é obrigatório, não otimização.** A escrita
> acontece no documento da conta, que é exatamente o que dispara
> `onAccountUpdated`. Sem a comparação (`isSameNextInvoice`, que ignora
> `updatedAt`) e sem a guarda estreita no handler, o gatilho se realimentaria em
> laço.

**Convergência.** `updateInvoiceWithDelta` escreve a ORDER; a parcela da fatura
só ganha o novo valor quando `onOrderWritten` roda. A sincronização feita logo
depois do delta enxerga a parcela anterior — mas a escrita da parcela dispara
`onInstallmentWritten` → `processInvoiceUpdate` de novo, e é essa passagem que
grava o valor certo. O cron é a terceira rede. Falhar na sincronização nunca
derruba o pagamento que disparou o gatilho.

### A janela do ciclo também fica na fatura

`nextInvoice` fala de UMA fatura — a próxima. A tela de detalhe abre qualquer
uma, inclusive antigas vindas do histórico. Por isso a **order e a parcela de
fatura** carregam `cycleStart`/`cycleEnd`/`closingDate`, escritos por
`updateInvoiceWithDelta` e copiados para a parcela por `syncInstallments`.

Efeito colateral desejado: a janela fica **congelada** no que valia quando a
fatura nasceu. Mudar o dia de fechamento do cartão hoje não reescreve o que uma
fatura de três meses atrás continha. É também por isso que a janela GRAVADA tem
precedência sobre a recalculada ao montar `nextInvoice`: cabeçalho e lista de
compras não podem divergir.

### Id da order: dois formatos válidos

O id canônico passou a usar `toDateKey` (dia no **fuso do produto**); o antigo
usava `toISOString()` (dia em **UTC**). Enquanto o servidor rodou em UTC com o
vencimento ao meio-dia os dois coincidiam, mas nem toda order da base nasceu
assim.

`resolveInvoiceOrderRef` reconhece os dois: quando os ids **diferem** e só o
antigo existe, o delta continua sendo somado nele. Criar a order canônica ao
lado **duplicaria** a fatura daquele mês. Quando os ids coincidem — o caso da
base atual — não há leitura extra nenhuma. Os dois caminhos (legado existente,
order inexistente) são cobertos em `invoice_next.integration.test.ts`.

O `rebuild_workspace.ts` **não é afetado**: ele reconstrói saldo, sumário e XP a
partir das `installments` e nunca resolve uma order de fatura por id.

### Security rules

`accounts.nextInvoice` é negado ao cliente no **create** (`!('nextInvoice' in
request.resource.data)`) e no **update** (por diferença de valor, via
`affectedKeys().hasAny`). Reenviar exatamente o que o servidor gravou é um
no-op e passa; apagar o campo num `setDoc` que serialize a conta inteira é
barrado.

`installments.cycleStart`/`cycleEnd`/`closingDate` são negados da mesma forma no
update — a janela decide quais compras a tela lista, e reescrevê-la no cliente
traria de volta, por outro caminho, a regra duplicada que o pacote tirou. Vale a
mesma exceção do `xp`: a build que grava o documento inteiro manda `null` nesses
campos em toda parcela que não é fatura, e isso não é alteração de valor. O
**create** de parcela não precisa de cláusula: a coleção não tem `allow create`
nenhum.

Tudo coberto em `src/test/rules/firestore_rules.test.ts`.

### Contrato com o cliente Flutter

- `AccountModel.creditCard` ganhou `nextInvoice` (nullable). O app **lê**;
  `includeToJson: false` garante que ele nunca reenvie o campo;
- `nextInvoice` ausente significa **"ainda não sei"** — conta anterior ao
  backfill. A lista de contas mostra *"calculando…"* no lugar do valor, e o
  total do grupo entra em carregamento. R$ 0,00 ali seria um valor errado com
  cara de definitivo;
- as parcelas de fatura ganharam `cycleStart`/`cycleEnd` (nullable, somente
  leitura). Sem eles a tela de detalhe mostra *"fatura em fechamento"* em vez de
  listar o extrato de um intervalo chutado;
- `watchNextInvoice` continua existindo no app, num provider usado **só para
  navegar** até a tela de detalhe (que recebe o `InstallmentModel` inteiro).
  Fallback temporário e documentado: o que saiu do cliente foi o CÁLCULO da
  fatura, não a leitura. Quando a rota passar a receber só o id, ele sai.

### `backfill_next_invoice.ts`

Preenche `accounts/{id}.nextInvoice` nas contas de cartão existentes e a janela
do ciclo (`cycleStart`/`cycleEnd`/`closingDate`) nas orders e parcelas de fatura
já gravadas.

- **Duas etapas independentes por cartão.** A janela do ciclo roda SEMPRE,
  inclusive na conta que já tem `nextInvoice` — senão bastaria o cron das 03:45
  passar uma vez para o histórico de faturas nunca mais ser preenchido. O resumo
  é que pode ser pulado.
- **Idempotente**: pula quem já tem os campos (`--force` recalcula).
- **Dry-run por padrão**: só escreve com `--apply`.
- **Sem regra própria**: usa a mesma consulta e o mesmo `InvoiceService` do
  caminho em tempo real.
- Escritas em lotes de no máximo 400 operações (`commitInChunks`). Uma falha de
  lote invalida os números daquele workspace no resumo — o log diz isso e a
  execução seguinte refaz.

```bash
cd functions
npm run build

# 1) Simulação (padrão — não escreve nada)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/backfill_next_invoice.js --project=<projectId>

# 2) Um workspace só, para conferir o efeito
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/backfill_next_invoice.js --project=<projectId> --workspace=<wid> --apply

# 3) Base inteira (somente após revisar o dry-run)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/backfill_next_invoice.js --project=<projectId> --apply
```

| Flag              | Efeito                                                        |
|-------------------|---------------------------------------------------------------|
| _(nenhuma)_       | dry-run: apenas relata o que seria gravado                     |
| `--apply`         | executa as escritas                                            |
| `--project=<id>`  | projectId do Firebase (default: `GOOGLE_CLOUD_PROJECT`)         |
| `--workspace=<id>`| limita a execução a um único workspace                          |
| `--force`         | RECALCULA contas e faturas que já têm os campos (não é preciso para preencher o que falta) |

Resumo final: `workspaces`, `cartões`, `preenchidas` (resumos), `ignoradas`,
`ciclos` (com quantos já tinham a janela) e `falhas`. Saída de código: `0` se não
houve falhas, `1` caso contrário. Coberto por
`src/test/backfill_next_invoice.test.ts`. **NÃO foi executado contra nenhum
projeto.**

### Índices

Nenhum índice novo: a consulta da próxima fatura
(`accountIds` CONTAINS + `isInvoice` + `status` + `dueDate` ASC) já existia em
`firebase/firestore.indexes.json`, porque era a mesma que o app fazia.

## Bússola da Liberdade (F2.2)

O jogo já premiava planejar — XP, badges, missões. O que não existia era um
**placar**: nada no produto media a distância entre o usuário e a liberdade
financeira. XP responde "você jogou bem esta semana"; a Bússola responde "você
está a quantos passos de não depender mais do salário".

É um número de **0 a 100**, recalculado pelo servidor, **sem IA** — ele precisa
ser determinístico, senão a barra do app oscila sozinha e o placar perde o
sentido.

### Os quatro componentes

| Componente | Pergunta que responde | Como é medido | Peso |
|---|---|---|---|
| **Fôlego** | quantos meses eu aguento sem receita? | saldo líquido (`checking` + `investment`) ÷ (despesa realizada dos **últimos 90 dias** ÷ 3); 0 a 6+ meses → 0 a 100 | 30 |
| **Poupança** | quanto do que entra eu guardo? | `(receita − despesa) / receita` do mês; −∞ a 30%+ → 0 a 100 | 25 |
| **Disciplina** | eu respeito os limites que eu mesmo pus? | % das categorias com limite que fecharam o **mês anterior** dentro do limite | 25 |
| **Alívio** | minha dívida está encolhendo? | variação do saldo somado de `debt` + `creditCard` nos **últimos 30 dias**: encolheu → 100, estável → 50, cresceu → 0 | 20 |

Os pesos somam 100 (há um teste para isso: um peso esquecido faria o índice
nunca chegar a 100 e ninguém perceberia olhando o app). A regra de pontuação
inteira é **função pura** em `features/health/domain/models/financial_health.model.ts`.

### Patentes

| Faixa | Patente |
|---|---|
| 0–19 | **Aprendiz** |
| 20–39 | **Guardião** |
| 40–59 | **Estrategista** |
| 60–79 | **Mestre** |
| 80–100 | **Livre** |

### As janelas de tempo: por que são MÓVEIS

> ⚠️ **A virada do mês não pode mexer no placar.** A primeira versão media
> Fôlego em meses de calendário e Alívio "contra o fim do mês anterior". As
> duas janelas **saltavam no dia 1**: o usuário ia dormir Mestre em 30/09 e
> acordava Estrategista em 01/10 sem ter feito nada. Um placar que se mexe
> sozinho ensina o usuário a ignorá-lo. Três dos quatro componentes passaram a
> usar janelas móveis por causa disso.

- **Fôlego: 90 dias que terminam HOJE, divididos por 3.** A janela anda um dia
  por dia e nunca troca trinta dias de despesa de uma vez. O divisor continua
  **fixo em 3**, não "meses com movimento": quem tem pouco histórico não tem
  despesa média baixa, tem pouco histórico — e a média cheia é a leitura
  conservadora. A despesa vem das **parcelas pagas** (`paidDate`), não dos
  `period_summaries`: estes são mensais e não se encaixam numa janela móvel.
  Ficam de fora fatura, categorias de sistema e parcelas não pagas.
- **Alívio: 30 dias que terminam HOJE.** Comparar com "o fim do mês anterior"
  fazia a janela ENCOLHER a cada dia e **zerar na virada** — quem passou
  setembro amortizando via 100 em 30/09 e 50 em 01/10, porque a comparação
  recomeçava contra um saldo de ontem. Saldo de dívida é **negativo**, então
  amortizar aproxima de zero e o delta é positivo. Há uma faixa morta de
  R$ 1,00: sem ela, um centavo de juros viraria "a dívida aumentou" e
  derrubaria o componente de 50 para 0.
- **Poupança: o mês corrente, mas só quando já é comparável.** Ele precisa ter
  ao menos **50% da receita do último mês completo**; abaixo disso vale o mês
  completo. Sem esse piso, a primeira receita do mês — um reembolso de R$ 100
  no dia 2 — virava o denominador inteiro da taxa e derrubava o componente de
  67 para 0. O gatilho de "já dá para julgar este mês" não é "existe alguma
  receita", é "a receita deste mês já se parece com a de um mês normal". No
  primeiro mês do workspace não há a quem recuar, e o corrente vale.
- **Disciplina: o mês ANTERIOR — e esta troca na virada de propósito.** Um
  limite só pode ser julgado depois de o mês fechar; reprovar quem ainda tem 20
  dias para se ajustar seria mentira. É o único componente que muda de janela
  no dia 1, e muda porque o mês fechado de fato mudou. O limite comparado é o
  `category_planning.amount` vigente, e "dentro" é `<=`: gastar exatamente o
  planejado é o alvo, não uma falha por um centavo.

### Casos de borda que o índice trata de propósito

| Situação | O que acontece | Por quê |
|---|---|---|
| workspace **sem conta nenhuma** | retorno imediato do retrato zerado (score 0, Aprendiz) | sem conta não há saldo, dívida nem despesa; é o estado inicial, não um erro — o app desenha a bússola vazia em vez de uma tela de falha |
| sem despesa nos últimos 90 dias | Fôlego = 0 | dividir por zero daria `Infinity`, e "reserva infinita" para quem acabou de chegar é uma mentira confortável |
| receita zero nos dois meses | Poupança = 0 | tratar "não ganhei nada" como 100% de poupança premiaria o mês vazio |
| nenhuma categoria com limite | Disciplina = 0 | quem não planejou não tem disciplina a medir — e é esse zero que o app usa para convidar o usuário a criar o primeiro limite |
| nenhuma conta de dívida | Alívio = 100 | quem não tem dívida não pode ser punido por não estar amortizando |
| conta `isDeleted` | fora de tudo | o saldo dela é resíduo de um histórico que ninguém mantém (ver o aviso do rebuild) |
| categoria de sistema/virtual | fora de receita, despesa e disciplina | não é escolha de consumo: com ela, um aporte para a poupança contaria como gasto |

### Onde o retrato é gravado

```
workspaces/{w}.financialHealth          # o retrato corrente
workspaces/{w}/health_history/{YYYY-MM} # um documento por mês
```

Os dois têm **a mesma forma**:

| Campo | Tipo | Semântica |
|---|---|---|
| `score` | number | 0 a 100 |
| `tier` | string | `aprendiz` \| `guardiao` \| `estrategista` \| `mestre` \| `livre` |
| `components.folego` | map | `{value, score, months}` |
| `components.poupanca` | map | `{value, score, rate}` |
| `components.disciplina` | map | `{value, score, within, total}` |
| `components.alivio` | map | `{value, score, delta}` |
| `computedAt` | Timestamp | quando o retrato foi calculado |
| `monthKey` | string | `YYYY-MM` do mês a que o retrato se refere |

`value` é o valor **bruto** da métrica, na unidade do componente (meses, taxa,
razão, variação em reais); o campo nomeado ao lado (`months`, `rate`, `delta`)
é o mesmo número com o nome do contrato, para o app não precisar saber qual
componente está lendo.

O documento do histórico é **sobrescrito enquanto o mês corre** e congela
quando o mês vira — a última escrita do mês já é o retrato de fechamento.

**Ele só é reescrito quando o retrato MUDA.** O histórico é um ponto de
tendência: regravá-lo a cada 15 minutos com o mesmo score é uma escrita por
workspace por ciclo que não conta nada a ninguém. A comparação olha o score, a
patente e as **notas** dos componentes (mais as contagens da Disciplina), não os
valores brutos — `months`, `rate` e `delta` se mexem na terceira casa decimal a
cada centavo lançado, e compará-los tornaria a guarda inútil. O retrato
**corrente** (`financialHealth`), esse, é reescrito sempre: é dele que sai o
`computedAt` que ancora o debounce, e é ele que carrega os valores exatos.

`saveCurrent` usa `update`, e não `set(..., {merge: true})`: o retrato **nunca
pode criar** um documento de workspace. Um workspace apagado entre a leitura e
a escrita voltaria à vida com um único campo, e a lista de workspaces do
usuário passaria a mostrar um fantasma.

### Recálculo: marcar é barato, calcular é caro

O índice lê os saldos de **todas** as contas, três meses de sumário e os
planejamentos vigentes. Fazer isso a cada parcela paga transformaria um
pagamento em dezenas de leituras — e uma conciliação de extrato com 80
lançamentos, em 80 recálculos do mesmo número.

Por isso o caminho é em dois tempos:

1. **`markHealthDirty(workspaceId)`** — chamado de três gatilhos, todos os que
   mexem numa fonte do índice:

   | Gatilho | Por quê |
   |---|---|
   | `onInstallmentWritten` | acabou de mexer no `period_summaries` do mês e no `balance` da conta |
   | `onAccountUpdated` (conta apagada) | o saldo dela deixa de contar como reserva (ou como dívida) |
   | `onCategoryPlanningWritten` | o limite é o denominador da Disciplina; num mês em que o usuário só planejou, nada mais sujaria o workspace |

   É **uma escrita, zero leituras** (`healthDirtyAt` = timestamp do
   servidor). Fica **fora** do `runIdempotency` de propósito: reexecutar um
   carimbo é inofensivo, e o índice não pode ficar desatualizado porque o
   marcador daquele evento já estava gravado. Ele **nunca lança** para quem
   chama — sujar a Bússola não pode derrubar um pagamento;
2. **o cron `refreshFinancialHealth`** (a cada 15 minutos) recalcula os sujos,
   respeitando um **intervalo mínimo de 10 minutos por workspace**. Um
   workspace adiado pelo debounce **continua sujo** e entra no ciclo seguinte:
   o marcador só é apagado quando o retrato é de fato recalculado, e é isso que
   garante que nenhuma mudança se perde.

A varredura consulta `where("healthDirtyAt", ">", epoch)`. O Firestore não
consulta "campo que existe", mas `> epoch` só casa documentos que **têm** o
campo — então o custo é o número de workspaces **sujos**, não o tamanho da
base. É uma consulta de campo único, coberta pelo índice automático: **não há
índice novo a criar**.

O cursor da paginação é o próprio `healthDirtyAt` (a consulta ordena por ele),
e não um checkpoint persistido: a fila se esvazia sozinha porque recalcular
apaga o marcador, e o cursor por valor evita que um workspace adiado pelo
debounce seja relido para sempre dentro da mesma execução.

> **Empate de timestamp.** Dois workspaces marcados no mesmo microssegundo
> podem fazer o `startAfter` pular um deles. Ele continua sujo e é pego no
> ciclo seguinte, 15 minutos depois — o pior caso é atraso, nunca perda.

### O cron mensal fecha o mês

`closeFinancialHealthMonth` roda **todo dia 1 às 04:30** e faz duas passadas
por workspace:

1. `computeHealth` com `now` no **último instante do mês que acabou**,
   gravando só o `health_history/{mês anterior}` — o retrato corrente não pode
   ficar apontando para o passado;
2. `computeHealth` com o `now` real, que reabre `financialHealth` e cria o
   documento do mês novo.

**IDEMPOTENTE: um mês já fechado não é reescrito.** O carimbo de fechamento é o
próprio `computedAt` — durante o mês ele é sempre anterior ao fim do mês, e o
fechamento grava exatamente o último instante. Sem essa guarda, uma segunda
execução do cron (reentrega, execução manual) recalcularia o mês fechado com os
dados de HOJE: a Disciplina passaria a julgar outro mês e o retrato congelado
mudaria depois de congelado. É por isso — e só por isso — que a escrita do
fechamento ignora a guarda de "só grava se mudou": o que ela precisa gravar é o
carimbo.

Existe porque a Bússola de um mês só está completa quando o mês acaba, e
nenhum evento acontece no dia 1 para provocar essa última passada num workspace
parado. Sem ele, o `health_history` de quem não abriu o app na virada ficaria
congelado no retrato do dia 20, e o gráfico de evolução mostraria um degrau que
nunca existiu.

### Security rules

- `workspaces/{w}.financialHealth` e `healthDirtyAt` caem na lista fechada
  (`affectedKeys().hasOnly`) do `allow update` do workspace — o cliente não os
  escreve nem os apaga. A criação também os nega explicitamente;
- `workspaces/{w}/health_history/{YYYY-MM}`: **leitura por membro, escrita
  negada**. É o placar do usuário; poder escrever ali seria reescrever a
  própria história até a patente ficar bonita.

### Testes

- `src/test/financial_health.test.ts` — a regra de pontuação e os **quatro
  cenários de perfil** (endividado, equilibrado, poupador, sem dados), mais as
  janelas de tempo e o debounce;
- `src/test/integration/financial_health.integration.test.ts` — emulador:
  score determinístico a partir de saldos e sumários reais (inclusive um
  documento de saldo **legado**, sem `dateKey`), segunda execução sem efeito,
  virada de mês congelando o histórico, a varredura dos sujos e a garantia de
  que um workspace inexistente não é criado pelo retrato.

## XP que premia planejar (F2.3)

O propósito do produto é ensinar planejamento. O XP dizia outra coisa: quase
todo ele vinha de badges de **contagem** — cadastrar cinco contas, registrar
cem transações, completar um ano de workspace. Um usuário que lançasse cem
transações desorganizadas subia de nível mais rápido do que quem manteve três
limites em dia por dois meses.

F2.3 move o XP para onde o produto quer que ele esteja.

### A tabela de fontes de XP

| Fonte | XP | Quando |
|---|---|---|
| **Lançamento planejado pago** | 15 | pagar um lançamento que estava planejado (regra antiga, inalterada) |
| **Categoria dentro do limite** | 20 | por categoria com limite que fecha a semana sem estourar |
| **Semana redonda** | 50 | bônus quando **todas** as categorias com limite fecham dentro |
| **Sequência no plano** | 10 × streak | semanas consecutivas dentro do plano, **teto de 100** |
| **Limite criado** | 30 | ao definir o primeiro limite de uma categoria — **uma vez por categoria** |
| **Recorrência criada** | 30 | ao criar o primeiro lançamento recorrente de uma categoria — **uma vez por categoria** |
| **Missão semanal** | 150–250 | por missão concluída (regra antiga, inalterada) |
| **Gasto não planejado** | **0** | a parcela que nasce paga (ver `unplannedReason`) |

Os valores vivem em `XP_VALUES`/`XP_SOURCES` (`gamification.service.ts`) e são
**publicados** em `config/badges.xpSources` — é a tabela que o app mostra na
tela "como ganhar XP". Mudar um número muda o hash do catálogo e o cron
`publishBadgeCatalog` republica sozinho.

> **`workspaces/{w}.xpSources` NÃO existe.** A tabela é configuração do
> produto, igual para todo mundo, e muda por deploy, não por usuário.

### Badges de contagem: XP zero, conquista mantida

Vinte e quatro badges passaram a `xpReward: 0` — eles **continuam existindo** na
vitrine, continuam sendo desbloqueados e continuam contando como conquista;
só não pagam mais XP:

`two_accounts`, `three_accounts`, `five_accounts`, `five_transactions`,
`twenty_transactions`, `fifty_transactions`, `hundred_transactions`,
`five_categories`, `ten_categories`, `three_categories_month`,
`five_categories_month`, `round_number`, `workspace_one_year`,
`first_category`, `first_income`, `first_expense`, `first_transfer`,
`first_month`, `reconcile_five`, `five_active_goals`, `two_active_goals`,
`two_months_active`, `small_transactions_ten`, `big_transaction`.

O corte foi na **contagem**, não no mérito: `under_control`, `golden_rule`,
`planner`, `iron_consistency` e os badges de meta continuam pagando.

### O XP semanal, a partir dos sumários

`evaluateWeeklyPlanXp` roda dentro do `weeklyGamificationCron` (segunda,
03:00) e avalia a **semana anterior**, já encerrada, lendo
`period_summaries/{YYYY-Www}` — o mesmo documento que o app mostra.
`generalPlannedAmount` é a proporção semanal do limite mensal (ver F1.5) e
`actualAmount` é o realizado da semana.

Categorias de **sistema** e de **receita** ficam de fora; só entram as de
despesa com `generalPlannedAmount > 0`.

- **Sem nenhuma categoria com limite, a streak ZERA.** "Semanas dentro do
  plano" pressupõe um plano: apagar todos os limites não pode ser uma forma de
  congelar a sequência indefinidamente;
- **Estourar um limite zera a streak**, mas o XP das categorias que ficaram em
  dia continua sendo pago — a semana não foi redonda, e ainda assim a categoria
  em dia foi mérito;
- é **idempotente** pela chave `workspaceId_weekId` (ação `weeklyPlanXp`): uma
  reexecução do cron não paga de novo.

### O XP de planejar também entra na BARRA DA SEMANA

O XP total do workspace e o XP semanal (`weekly_xp/{YYYY-Www}`) são contadores
distintos: o primeiro move o nível, o segundo desenha a barra de progresso da
semana no app. Só o **pagamento de parcela** alimentava o segundo — então a
semana em que o usuário criou cinco limites e fechou todos dentro do plano
aparecia **vazia** na barra, que é o oposto da mensagem do produto.

Agora as três fontes novas creditam os dois:

| Fonte | Semana creditada |
|---|---|
| semana dentro do limite (+20/+50/streak) | a semana **avaliada** (a que acabou) |
| limite criado (+30) | a semana **corrente** |
| recorrência criada (+30) | a semana **corrente** |

O XP da semana avaliada vai para o bucket **daquela** semana, não da corrente: o
mérito é dela e é nela que a barra histórica precisa mostrá-lo.

Quem escreve é `FinanceService.updateWeeklyTotalXp` — a **única** implementação
dessa escrita desde F1.9, que deixou de ser privada. A gamificação a recebe
**injetada** pelo container (`WeeklyXpWriter`) em vez de importá-la: alcançá-la
por `import { container }` arrastaria o container inteiro — e, com ele, o SDK do
Gemini e o `ofx-js` — para dentro de qualquer arquivo que apenas leia o catálogo
de badges.

Duas garantias, nessa ordem:

- **o total é a fonte da verdade.** A barra é creditada DEPOIS, e uma falha
  nela é logada sem desfazer o XP já concedido nem derrubar o cron;
- **a barra só é creditada quando o XP saiu de fato.** Quem decide é a
  transação do marcador: creditar antes faria a segunda criação do mesmo limite
  inflar a semana sem inflar o total.

### Os streaks: um campo NOVO, e o antigo intacto

```
weeklyStreaks: number                        # LEGADO, vivo: = streaks.missions
streaks: { missions: number, plan: number }  # F2.3
```

`weeklyStreaks` era um número só (a sequência de semanas com todas as missões
concluídas). Com o streak de **plano** passaram a ser dois.

> ⚠️ **Transformar `weeklyStreaks` num mapa quebraria todo app instalado.** O
> cliente o desserializa como `num?` (`workspace_model.g.dart`), então um mapa
> ali vira `TypeError` ao abrir o workspace. E o cron semanal escreve nesse
> campo em **todos** os workspaces: a quebra chegaria a todo mundo na
> segunda-feira seguinte ao deploy, sem nenhuma ação do usuário. Foi o que a
> primeira versão deste pacote fazia.

O mapa vive num campo **novo**, que o app antigo ignora:

- os dois são escritos na **mesma transação**, e
  `weeklyStreaks === streaks.missions` é **invariante**;
- a leitura tolera as duas gerações: sem o mapa, `missions` vem do número
  legado e o plano começa em zero — nenhuma sequência é perdida;
- a escrita é read-modify-write do campo INTEIRO, nunca
  `update({"streaks.plan": n})`: é também o que impede que o cron de missões e
  o de plano, que rodam na mesma execução, sobrescrevam um ao outro;
- as rules mantêm `weeklyStreaks` como **número** na criação (um mapa ali é
  negado) e negam `streaks` ao cliente por completo.

### XP único por categoria

| Gatilho | Marcador | XP |
|---|---|---|
| `onCategoryPlanningWrittenGamification` | `xpAwardedFor.planning.<categoryId>` | 30 |
| `onOrderWrittenGamification` (**novo**) | `xpAwardedFor.recurring.<categoryId>` | 30 |

O marcador e o XP vão na **mesma transação** (igual ao `unlockBadge`): é o
Firestore que serializa a disputa, então duas escritas paralelas do mesmo
planejamento pagam uma vez só. Sem o marcador, apagar e recriar o mesmo limite
renderia 30 XP a cada vez, e o jogo passaria a premiar mexer no formulário em
vez de planejar.

O mapa `xpAwardedFor` é reescrito **inteiro**, nunca por caminho pontilhado: um
id de categoria com ponto viraria dois níveis de aninhamento e o marcador nunca
mais casaria.

Não pagam nada: limite **zerado** (é desligar o planejamento, não criar um),
categoria **sem id** ou **de sistema**, order **avulsa/parcelada**, **fatura**
(criada pelo servidor — premiar seria dar XP por ter cartão) e order
**cancelada**. Limite e recorrência são contadores **independentes**: a mesma
categoria pode render pelos dois, porque são dois atos de planejamento
diferentes.

`onOrderWrittenGamification` é novo e observa a mesma coleção que o
`onOrderWritten` de finanças, com um nome de ação próprio
(`gamification:orderWritten`) para que os dois não disputem a chave de
idempotência quando a plataforma entregar o mesmo `event.id` para ambos. Ele
sai antes da idempotência quando a order não é recorrente: a maioria das
escritas não é, e nenhuma delas precisa custar um documento em `_idempotency`.

### `installments.unplannedReason`: a punição deixa de ser muda

`calculateXp` devolve **0** quando o planejado (`amount`) é zero — o caso da
parcela que **nasce paga** (saldo inicial, compra já liquidada no cartão), em
que `syncInstallments` zera o planejado de propósito para a cobrança contar
como não planejada. A regra não mudou; o que mudou é que ela **passou a se
explicar**.

```
installment.unplannedReason: "born_paid" | ausente
```

- É gravado na **mesma escrita** do `xp` e do `replicationCascade: none` (uma
  escrita só, no caso 2 de `updateXpOnInstallmentChange`);
- entrou em `INSTALLMENT_DERIVED_FIELDS`. Fora dali, toda parcela que nasce
  paga dispararia o gatilho inteiro de novo — sumário, meta, saldo, fatura,
  XP — só para registrar o motivo do zero;
- a **fatura fica de fora**, mesmo com planejado zero: o valor dela é a soma
  das compras do ciclo, mantida pelo servidor, e não um planejamento que o
  usuário deixou de fazer. Marcá-la convidaria o app a pedir um limite para
  algo que já é consequência de outros lançamentos;
- as rules negam ao cliente gravar ou apagar o campo, com a mesma exceção do
  `xp`: uma build que grave o documento inteiro manda `null` nas parcelas que
  não têm o campo, e isso não é alteração de valor.

O app (outro pacote) usa esse motivo para mostrar o nudge que converte o gasto
em limite ou recorrência — e **essa conversão rende XP**, pelas duas fontes de
30 acima. É o ciclo que fecha a punição: o gasto não planejado vale zero, e a
saída do zero é planejar.

### Testes

- `src/test/plan_xp.test.ts` — XP semanal (dentro/fora do limite, bônus de
  semana redonda, streak crescendo, zerando e batendo no teto), XP único por
  categoria, `unplannedReason` e o catálogo publicado;
- `src/test/integration/plan_xp.integration.test.ts` — emulador: fixtures reais
  de sumário semanal, migração do `weeklyStreaks` legado, concessão única
  **concorrente** (três chamadas paralelas pagam uma vez) e `unplannedReason`
  de fato gravado na parcela.

### Contrato com o cliente Flutter (F2.2 + F2.3)

Os nomes abaixo são **contrato**: o pacote da Jornada depende deles.

| Caminho | Forma | Quem escreve |
|---|---|---|
| `workspaces/{w}.financialHealth` | `{score, tier, components:{folego:{score,months}, poupanca:{score,rate}, disciplina:{score,within,total}, alivio:{score,delta}}, computedAt, monthKey}` | só o servidor |
| `workspaces/{w}/health_history/{YYYY-MM}` | a mesma forma | só o servidor |
| `workspaces/{w}.streaks` | `{missions: number, plan: number}` | só o servidor |
| `workspaces/{w}.weeklyStreaks` | `number` (**inalterado**, = `streaks.missions`) | só o servidor |
| `installments.unplannedReason` | `"born_paid"` \| ausente | só o servidor |
| `config/badges.xpSources` | `[{id, name:{pt,en}, xp, description:{pt,en}}]` | só o servidor |

Cada componente carrega também um `value` — o valor bruto da métrica, na
unidade do componente — além do campo nomeado do contrato.

> **`weeklyStreaks` NÃO mudou de tipo — de propósito.** A primeira versão deste
> pacote transformava o campo num mapa, e isso quebraria **todo app instalado**:
> `workspace_model.g.dart` o desserializa como `num?`, e o cron semanal escreve
> nele em TODOS os workspaces — a quebra chegaria a todo mundo na segunda-feira
> seguinte ao deploy, sem nenhuma ação do usuário. O mapa vive no campo NOVO
> `streaks`, que o app antigo simplesmente ignora. Os dois são escritos na mesma
> transação e `weeklyStreaks === streaks.missions` é invariante.

> **`financialHealth` ausente** significa "ainda não calculei", não "score 0".
> Isso acontece num workspace que nunca foi marcado como sujo e ainda não
> passou pelo `recompute_health`. O app deve mostrar a bússola em carregamento,
> e não a patente Aprendiz — que é um veredito, não um estado de espera.

## Crons de manutenção

| Function                            | Agendamento               | Fuso              |
|-------------------------------------|---------------------------|-------------------|
| `generateRecurringInstallments`     | `30 3 * * *` (diário)     | `America/Sao_Paulo` |
| `syncNextInvoices`                  | `45 3 * * *` (diário)     | `America/Sao_Paulo` |
| `generateCategoryPlanningSummaries` | `0 0 1 * *` (dia 1)       | `America/Sao_Paulo` |
| `syncWorkspaceCurrentWeek`          | `10 0 * * 0` (domingo)    | `America/Sao_Paulo` |
| `weeklyGamificationCron`            | `0 3 * * 1` (segunda)     | `America/Sao_Paulo` |
| `monthlyGamificationCron`           | `0 3 1 * *` (dia 1)       | `America/Sao_Paulo` |
| `publishBadgeCatalog`               | `0 4 * * *` (diário)      | `America/Sao_Paulo` |
| `refreshFinancialHealth`            | `*/15 * * * *` (15 min)   | `America/Sao_Paulo` |
| `closeFinancialHealthMonth`         | `30 4 1 * *` (dia 1)      | `America/Sao_Paulo` |

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

## Ordem de rollout

Os pacotes F1.4/F1.5/F1.8/F1.9 mudam formato de documento, consultas e ids. A
ordem abaixo é a que evita janela quebrada — **nada disso foi executado contra o
projeto real**.

```
1. rules + índices   firebase deploy --only firestore:rules,firestore:indexes
                     ⏳ ESPERAR os índices ficarem READY antes de seguir
2. functions         firebase deploy --only functions
3. migração          node lib/scripts/migrate_balance_date_key.js      (dry-run → --apply)
4. migração          node lib/scripts/migrate_planning_summaries.js    (dry-run → --apply)
5. correção          node lib/scripts/fix_empty_category.js            (levantamento → --apply, uma categoria por vez)

5. backfill          node lib/scripts/backfill_next_invoice.js                                  (dry-run → --apply)
6. rebuild           node lib/scripts/rebuild_workspace.js --all-workspaces                     (dry-run → --apply)
7. rebuild planejado node lib/scripts/rebuild_workspace.js --all-workspaces --rebuild-planning  (dry-run → --apply)
8. bússola           node lib/scripts/recompute_health.js                                           (dry-run → --apply)
```

**1. Rules e índices primeiro, e espere ficarem READY.** O código novo consulta
`balance.dateKey` (descendente) e `category_planning.summarizedUntil` (no grupo
de coleções). Enquanto o índice estiver `CREATING`, essas consultas respondem
`FAILED_PRECONDITION` e o gatilho de saldo/cron de planejamento falha. Confira
com:

```bash
gcloud firestore indexes fields list --project=funance-cef1b
```

As rules podem ir junto: elas só **negam** campos novos ao cliente
(`currentWeekId`, `currentWeekStart`, os quatro marcadores do planejamento e o
`nextInvoice` da conta), e o app ainda não os envia. F1.8 **não acrescenta
índice**: a consulta da próxima fatura já existia, porque era a que o app
fazia.

> ⚠️ **As rules de conta e o app andam juntos.** A partir deste deploy, um
> `setDoc` que serialize a conta inteira sem `nextInvoice` é rejeitado (apagar o
> campo conta como alteração). O app atual usa `update` com `toJson()`, e
> `nextInvoice` não é serializado — mas uma build antiga que reescreva o
> documento inteiro quebraria. Se houver clientes antigos em campo, suba as
> rules junto com a versão nova do app.

**2. Depois as functions.** Elas convivem com os documentos no formato antigo
(ver "Compatibilidade com o formato antigo"), então não há janela de indisponi-
bilidade entre o passo 2 e o 3 — só um custo de leitura maior por pagamento, em
contas com histórico longo, até a migração rodar.

**3 e 4. Migrações, na ordem.** `migrate_balance_date_key` preenche
`dateKey`/`delta` nos saldos; `migrate_planning_summaries` grava os marcadores
dos planejamentos. Ambas são idempotentes, dry-run por padrão e não mexem em
`period_summaries`. Rodar a segunda também encerra a varredura de legados do
cron mensal.

**5. Correção de categoria sem id.** `fix_empty_category` é um levantamento por
padrão: rode-o sem `--category-id` para ver quantas parcelas/orders estão com
`category.id` vazio e com que nomes. A correção é feita uma categoria de cada
vez, e só onde o nome bate — ver
[Categoria sem id](#categoria-sem-id-fora-dos-sumários). Ela vem ANTES do
rebuild porque é o rebuild que recoloca essas parcelas nos `period_summaries`.

**5. Backfill da fatura — rode LOGO depois do passo 2.** `backfill_next_invoice`
preenche duas coisas independentes: `accounts/{id}.nextInvoice` e a janela do
ciclo (`cycleStart`/`cycleEnd`/`closingDate`) das faturas já existentes.

O resumo da conta tem uma segunda rede: o cron das 03:45 o preenche sozinho na
primeira madrugada depois do deploy. **A janela do ciclo não tem.** Ela é o que
faz a tela de detalhe listar as compras de uma fatura antiga; sem backfill, todo
o histórico fica em "fatura em fechamento" para sempre. Rodar cedo encurta a
janela em que o app mostra "calculando" no lugar do valor.

Se o cron já passou, **o script continua servindo**: as duas etapas são
independentes, e a janela é preenchida mesmo nas contas que já têm `nextInvoice`
(o `skipped` do resumo não pula os ciclos). `--force` não é necessário nesse
caso — ele só existe para RECALCULAR o que já está gravado.

O backfill não toca em saldo, sumário nem XP, então a ordem em relação ao
rebuild é indiferente.

**6. Rebuild.** Corrige o que as migrações não corrigem: dias e meses gravados
em UTC (pagamento perto da meia-noite de Brasília), ids de semana antigos e
saldos acumulados divergentes. `--all-workspaces` percorre a base um workspace
de cada vez, com um relatório por workspace e um resumo final; um workspace que
falha não interrompe os demais.

**7. Rebuild com `--rebuild-planning`, ANTES do segundo cron mensal.** Este é o
único passo que reescreve o `generalPlannedAmount`. O motivo do prazo: o valor
gravado hoje carrega a acumulação do regime antigo (aplicação repetida sem
estorno), e **cada execução do cron mensal soma mais um mês por cima desse
valor errado**. A primeira execução depois do deploy é inevitável; rodar o
`--rebuild-planning` antes da segunda impede que o erro continue crescendo.

> ⚠️ **O rebuild não é transacional.** Escolha uma janela sem uso e refaça o
> dry-run imediatamente antes de cada `--apply`.

**8. Bússola da Liberdade, por ÚLTIMO.** `recompute_health` lê saldos e
`period_summaries`; rodá-lo antes do rebuild gravaria um placar calculado sobre
os números que o rebuild ainda vai corrigir — e o usuário veria a patente mudar
sozinha no dia seguinte. Ele é a primeira passada da base existente: sem ela, um
workspace só ganha bússola quando alguém mexe nele, e quem tem três anos de
histórico mas não abriu o app veria o estado vazio. Depois dele, o carimbo no
gatilho + o cron de 15 minutos mantêm tudo em dia sozinhos.

> ⚠️ **Contas apagadas logicamente.** `onAccountUpdated` apaga as
> orders/parcelas da conta marcada como `isDeleted`, mas **não** a subcoleção
> `balance`. Sem parcelas não há como reconstruir aquele histórico, então o
> rebuild **propõe apagar** os saldos remanescentes dessas contas. Numa
> execução com `--all-workspaces` isso aparece espalhado pelos relatórios —
> revise as amostras (`apagar accounts/<id>/balance/...`) antes do `--apply`,
> workspace a workspace se necessário.

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
| `fix_empty_category.ts` | corrige `category.id` vazio em parcelas/orders | aqui |
| `recompute_health.ts` | base inicial da Bússola da Liberdade | aqui |

| `backfill_next_invoice.ts` | `nextInvoice` nas contas de cartão e a janela do ciclo nas faturas | [Fatura (F1.8)](#fatura-uma-implementação-no-servidor-f18) |
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

### `recompute_goals.ts`

Recalcula o `currentAmount` de **todas** as metas pela regra nova (ver
"Metas (`goals`): progresso automático nos quatro tipos"), usando a mesma
função que o gatilho usa (`GoalServiceImpl.computeCurrentAmount`). Serve para a
base legada, onde `reduceExpense` e `payDebt` estão paradas em zero desde
sempre e as de conta podem ter derivado por um evento perdido. É também o
caminho para trazer as metas `saveMoney` de **cofrinho** para o saldo da conta:
elas só se corrigem sozinhas no próximo evento de parcela daquela conta.

- **Idempotente**: pula a meta cujo valor já bate (tolerância de 1 centavo).
- **Dry-run por padrão**: só escreve com `--apply`.
- **Carimba o desfecho** (`outcome` + `completedAt`/`failedAt`) pela mesma regra
  do serviço; **nunca** reescreve o desfecho de uma meta que já desfechou.
- **Meta de tipo desconhecido é mantida**, não zerada.
- **Isola falha**: uma meta que lança é contada e não derruba as outras.
- **Log por meta**, com resumo final
  (`workspaces/metas/atualizadas/iguais/sucesso/falha/ativas/falhas`).

### `fix_empty_category.ts`

Conserta as parcelas e orders com `category.id` vazio (ver
[Categoria sem id](#categoria-sem-id-fora-dos-sumários)). O código já não quebra
mais por causa delas, mas elas ficam **fora dos `period_summaries`** até serem
corrigidas — e é o `installmentsWithoutCategory` do relatório do rebuild que
diz quantas são.

O script **não adivinha categoria**. Ele grava o `id` da categoria de destino
(`--category-id`, lida de `workspaces/{wid}/categories/{id}`) **somente** nos
documentos cujo `category.name` embutido bate com o `name` dela — comparação
sem diferenciar maiúsculas/minúsculas, ignorando espaços nas pontas. Os demais
são apenas **listados**, para decisão humana. Por isso a correção é feita uma
categoria de cada vez.

- **Dry-run por padrão**: só escreve com `--apply`.
- **`--category-id` é obrigatório com `--apply`** — sem ele o script só lista.
- **Idempotente**: depois da correção o `category.id` deixa de ser vazio e o
  documento não é mais encontrado pela consulta.
- **Preserva** os demais campos da categoria embutida (nome, ícone, cor, tipo):
  a escrita é um `set({category: {...atual, id}}, {merge: true})`.
- Varre `installments` **e** `orders`; sem `--workspace`, pelo grupo de coleções
  (base inteira).

```bash
cd functions
npm run build

# 1) Simulação (padrão — não escreve nada)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/recompute_goals.js --project=<projectId>

# 2) Um único workspace, para validar o efeito antes da base inteira
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/recompute_goals.js --project=<projectId> --workspace=<workspaceId> --apply

# 3) Execução real na base inteira (somente após revisar o dry-run)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/recompute_goals.js --project=<projectId> --apply
```

| Flag              | Efeito                                                        |
|-------------------|---------------------------------------------------------------|
| _(nenhuma)_       | dry-run: apenas relata o que seria gravado                     |
| `--apply`         | executa as escritas                                            |
| `--project=<id>`  | projectId do Firebase (default: `GOOGLE_CLOUD_PROJECT`)         |
| `--workspace=<id>`| limita a execução a um único workspace                          |

Saída de código: `0` se não houve falhas, `1` caso contrário.

Coberto por testes com mocks em `src/test/recompute_goals.test.ts` (dry-run,
idempotência, desfecho, escopo por workspace e contabilização de falhas).

> ⚠️ **NÃO EXECUTADO** contra o projeto real (`funance-cef1b`).
>
> ⚠️ **Não rode este script numa base que ainda não tenha o deploy do desfecho
> (`outcome`).** A versão anterior carimbava `completedAt` por
> `currentAmount >= targetAmount`, o que numa base com metas de redução
> significa marcar em massa como concluídas justamente as que estouraram o teto
> — e conceder os badges correspondentes, que não se desfazem.

### `publish_badge_catalog.ts`

Publica `config/badges` na hora, para o **primeiro deploy** — depois dele o cron
diário `publishBadgeCatalog` mantém o documento em dia sozinho. Enquanto o
documento não existe, a vitrine de badges do app mostra o estado "catálogo
indisponível" em vez de quebrar.

- **Idempotente**: compara a `version` (hash do conteúdo) e não escreve se ela
  já é a publicada.
- **Dry-run por padrão**: só escreve com `--apply`.
- Não toca em dado de usuário nenhum: `config/badges` é configuração do projeto.

```bash
cd functions
npm run build

# 1) Simulação (padrão)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/publish_badge_catalog.js --project=<projectId>

# 2) Publicação real
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/publish_badge_catalog.js --project=<projectId> --apply
```

Coberto por testes com mocks em `src/test/recompute_goals.test.ts` (dry-run,
publicação e idempotência) e em `src/test/badge_catalog.test.ts` (o catálogo
contém todos os ids de `BADGES`; os limiares são a inversa de `calculateLevel`).

> ⚠️ **NÃO EXECUTADO** contra o projeto real (`funance-cef1b`).

# 1) Levantamento (padrão — não escreve nada): lista tudo que está quebrado
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/fix_empty_category.js --project=<projectId>

# 2) Simulação da correção de UMA categoria num workspace
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/fix_empty_category.js --project=<projectId> \
    --workspace=<workspaceId> --category-id=<categoryId>

# 3) Execução real (somente após revisar o dry-run)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/fix_empty_category.js --project=<projectId> \
    --workspace=<workspaceId> --category-id=<categoryId> --apply
```

| Flag                | Efeito                                                                  |
|---------------------|-------------------------------------------------------------------------|
| _(nenhuma)_         | dry-run: apenas lista os documentos quebrados                            |
| `--apply`           | executa as escritas (exige `--category-id`)                              |
| `--project=<id>`    | projectId do Firebase (default: `GOOGLE_CLOUD_PROJECT`)                  |
| `--workspace=<id>`  | limita a varredura a um workspace (sem ela, base inteira)                |
| `--category-id=<id>`| categoria de destino em `workspaces/{wid}/categories/{id}`               |

Saída de código: `0` se não houve falhas, `1` caso contrário.

> **Depois de aplicar, rode o `rebuild_workspace`** (dry-run e depois `--apply`)
> no workspace afetado: é ele quem recoloca essas parcelas nos
> `period_summaries`. O gatilho só reage a escritas novas.

Coberto por testes com mocks em `src/test/fix_empty_category.test.ts` (flags,
comparação de nome, dry-run, correção, recusa por nome divergente e
idempotência).

### `recompute_health.ts`

Primeira passada da **Bússola da Liberdade** (F2.2) sobre a base existente:
calcula e grava `workspaces/{w}.financialHealth` e o
`health_history/{YYYY-MM}` do mês corrente de todos os workspaces.

Existe porque o índice nasce de um cron que só recalcula workspaces **sujos**,
e um workspace só fica sujo quando alguém mexe nele. Sem esta passada, quem não
abrir o app não ganha bússola nenhuma — e o produto mostraria o estado vazio
para um usuário com três anos de histórico. Depois dele, o caminho normal
(carimbo no gatilho + cron de 15 minutos) mantém tudo em dia sozinho.

- **Dry-run por padrão**: só escreve com `--apply`. O dry-run **calcula** o
  índice (é leitura) e imprime o que gravaria, junto com o retrato atual quando
  já existe — é assim que se revisa o efeito antes de aplicar.
- **Idempotente**: o índice é determinístico dado `now`; recalcular não muda
  nada se o estado do workspace não mudou.
- **Isola falha**: um workspace que lança é contado e não derruba os demais.
- **Não toca em XP, badge nem saldo**: ele só escreve o placar.

```bash
cd functions
npm run build

# 1) Simulação (padrão — não escreve nada)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/recompute_health.js --project=<projectId>

# 2) Um workspace só, para conferir o efeito
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/recompute_health.js --project=<projectId> --workspace=<wid> --apply

# 3) Base inteira (somente após revisar o dry-run)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/recompute_health.js --project=<projectId> --apply
```

| Flag              | Efeito                                                        |
|-------------------|---------------------------------------------------------------|
| _(nenhuma)_       | dry-run: apenas relata o que seria gravado                     |
| `--apply`         | executa as escritas                                            |
| `--project=<id>`  | projectId do Firebase (default: `GOOGLE_CLOUD_PROJECT`)         |
| `--workspace=<id>`| limita a execução a um único workspace                          |

Resumo final: `workspaces`, `gravados`, `iguais` e `falhas`. Saída de código:
`0` se não houve falhas, `1` caso contrário.

> ⚠️ **NÃO EXECUTADO** contra o projeto real (`funance-cef1b`).
>
> ⚠️ **Rode-o DEPOIS do rebuild.** Ele lê saldos e `period_summaries`; rodá-lo
> antes gravaria um placar calculado sobre números que o rebuild ainda vai
> corrigir, e o usuário veria a patente mudar sozinha no dia seguinte.

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
- **Parcelas com `category.id` vazio** ficam fora dos `period_summaries` (mas
  contam em saldo e XP) e aparecem no relatório como
  `parcelas sem categoria (category.id vazio, ...)`. Conserte-as com
  [`fix_empty_category.ts`](#fix_empty_categoryts) e refaça o rebuild.
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

# 3) Base inteira, um workspace de cada vez (dry-run e, depois, --apply)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/rebuild_workspace.js --project=<projectId> --all-workspaces
```

| Flag                | Efeito                                                              |
|---------------------|---------------------------------------------------------------------|
| _(nenhuma)_         | dry-run: só relata o que mudaria                                     |
| `--workspace=<id>`  | workspace a reconstruir (obrigatória sem `--all-workspaces`)          |
| `--all-workspaces`  | percorre TODOS os workspaces (`listDocuments()`), um de cada vez, com um relatório por workspace e um resumo final; um que falha não interrompe os demais |
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
