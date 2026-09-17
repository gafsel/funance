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

> Se a porta 8080 estiver ocupada, copie o `firebase.json` para um arquivo
> temporário com outra porta em `emulators.firestore.port` e rode com
> `--config`; apague a cópia depois.

## Contratos com o app

Esta é a lista ÚNICA do que o servidor escreve e o app lê — e do que o app
escreve e o servidor lê. Ela existe porque o contrato estava espalhado por uma
dúzia de seções "Contrato com o cliente Flutter", uma por pacote: para saber se
um campo podia mudar era preciso lembrar em qual pacote ele nasceu. As seções
detalhadas continuam onde estavam, com o PORQUÊ de cada decisão; a tabela abaixo
diz o QUE vale hoje e aponta para elas.

Como ler a coluna **Escreve**: "servidor" significa que as security rules negam
o campo ao cliente — não é convenção, é regra. Onde estiver "app", o servidor
apenas reage ao que o cliente gravou.

| Coleção / campo | Escreve | Lê | Desde | Detalhe |
|---|---|---|---|---|
| `workspaces/{w}/period_summaries/{YYYY \| YYYY-MM \| YYYY-Www}` — `{year, month\|null, week\|null, categories: {id: {generalPlannedAmount, specificPlannedAmount, actualAmount}}, runtimeType, lastUpdate}` | servidor | app | F1.4/F1.5/F1.9 (forma), F1.11 (tipada no backend) | [Planejamento (F1.5)](#planejamento-de-categoria-horizonte-rolante-f15) |
| `accounts/{a}/balance/{YYYY-MM-DD}` — `dateKey`, `delta`, `balance` | servidor | app | F1.4 | [Saldo diário (F1.4)](#saldo-diário-datekey-e-delta-f14) |
| `category_planning/{p}` — `summarizedUntil`, `appliedAmount`, `appliedFrom`, `appliedUntil` e o legado `lastSummaryMonth` | servidor (rules negam os cinco campos ao cliente, no create e no update) | app (só lê) | F1.5 | [Planejamento (F1.5)](#planejamento-de-categoria-horizonte-rolante-f15) |
| `workspaces/{w}.currentWeekId` — `YYYY-Www` | servidor | app | F1.9 | [Semana (F1.9)](#semana-uma-definição-só-f19) |
| `weekly_xp/{YYYY-Www}` — `{year, week, xp}` | servidor | app | F1.9 (id), F2.3 (XP de planejar entra aqui) | [XP que premia planejar (F2.3)](#xp-que-premia-planejar-f23) |
| `weekly_missions/{weekId}_{type}` — `{id, name, type, status, rewardXp, progress, target, weekId, createdAt, completedAt}` **+ `templateKey`, `workspaceType`, `actionPath`, `nameKey`, `params`** | servidor | app | F1.9 (id da semana), F1.11 (tipada no backend), wp/missions-by-type (os cinco campos novos) | [Missões por tipo de workspace](#missões-semanais-por-tipo-de-workspace) |
| `accounts/{a}.nextInvoice` — `{dueDate, closingDate, cycleStart, cycleEnd, amount, orderId, installmentId, status, updatedAt}` | servidor | app | F1.8 | [Fatura (F1.8)](#fatura-uma-implementação-no-servidor-f18) |
| `orders`/`installments` — `cycleStart`, `cycleEnd`, `closingDate` (**só em fatura**) | servidor | app | F1.8 | [Contratos de `orders` e `installments`](#contratos-de-orders-e-installments) |
| `installments.unplannedReason` — `"born_paid"` \| ausente | servidor | app | F2.3 | [XP que premia planejar (F2.3)](#xp-que-premia-planejar-f23) |
| `workspaces/{w}.financialHealth` — `{score, tier, components, computedAt, monthKey}` | servidor | app | F2.2 | [Bússola da Liberdade (F2.2)](#bússola-da-liberdade-f22) |
| `workspaces/{w}/health_history/{YYYY-MM}` — a mesma forma | servidor | app | F2.2 | [Bússola da Liberdade (F2.2)](#bússola-da-liberdade-f22) |
| `workspaces/{w}.streaks` — `{missions: number, plan: number}` | servidor | app | F2.3 | [Os streaks (F2.3)](#os-streaks-um-campo-novo-e-o-antigo-intacto) |
| `workspaces/{w}.weeklyStreaks` — `number`, **invariante** `=== streaks.missions` | servidor | app (build antiga) | anterior a F2.3; **o tipo não pode mudar** | [Os streaks (F2.3)](#os-streaks-um-campo-novo-e-o-antigo-intacto) |
| `goals/{g}` — `outcome` (`success`\|`failed`\|`null`), `completedAt`, `failedAt` | servidor | app | wp/gamification-2 | [Meta ativa e desfecho](#contrato-meta-ativa-e-desfecho) |
| `categories/{c}.isSystem` — booleano, **ausente == false** | servidor | app (deve filtrar) | F1.12 | [Categorias de sistema](#categorias-de-sistema-issystem) |
| `categories/{c}.isDeleted` — booleano, **ausente == false** | app e servidor | ambos | F1.7 | [Categorias de sistema](#categorias-de-sistema-issystem) |
| `config/badges` — `{version, badges[], levelThresholds[], xpSources[]}`, com **`audience`** em cada badge e cada `xpSource` | servidor | app (qualquer autenticado) | wp/gamification-2; `xpSources` em F2.3; `audience` em wp/missions-by-type | [Catálogo de badges](#catálogo-de-badges-configbadges) |
| `workspaces/{w}/automatic_transactions/{id}` — `date` é **string** de relógio local (`YYYY-MM-DDTHH:mm:ss.SSS`), nunca `Timestamp` | app | servidor | wp/missions-by-type (as rules passaram a exigir o tipo) | [Missões por tipo de workspace](#missões-semanais-por-tipo-de-workspace) |
| `workspaces/{w}/quotas/{YYYY-MM-DD}` — um campo por função + `createdAt`/`expiresAt` | servidor (rules negam a escrita ao cliente) | app — o membro **lê** para exibir o consumo | F5.1 | [Quotas de IA](#quotas-de-ia) |
| `workspaces/{w}/ai_cache/{fn}_{sha256}` — `{functionName, payload, createdAt, expiresAt}` | servidor | ninguém (rules negam) | F5.6 | [Cache de IA](#cache-de-ia-por-hash-da-entrada-ai_cache) |
| `workspaces/{w}/ai_logs/{id}` — metadados da chamada | servidor | ninguém (rules negam) | F5.3 | [Logs de IA](#logs-de-ia-ai_logs-e-ttl) |
| `workspaces/{w}/financial_coaching/{id}` — `{message, summary, type, slides[], date, generatedBy}` | servidor | app | F1.11 (tipada no backend) | [`actionPath` dos slides](#actionpath-dos-slides-de-coaching) |
| `workspaces/{w}/planning_analysis/{YYYY-MM}` — `{month, summary, groups[], categories[], insights[], projectedIncome, incomeSource, generatedBy, createdAt}` | servidor | app | F1.11 (tipada no backend) | — |
| **Todos os `*Cents`** — `orders.amountCents`, `installments.{amount,paidAmount,referenceAmount}Cents`, `accounts.{initialBalance,limit}Cents`, `accounts.nextInvoice.amountCents`, `goals.{targetAmount,currentAmount}Cents`, `category_planning.{amount,appliedAmount}Cents`, `balance.{delta,balance}Cents`, `period_summaries.categories.{id}.{generalPlannedAmount,specificPlannedAmount,actualAmount}Cents` | servidor (rules negam ao cliente) | ninguém **ainda** — o app passa a ler na etapa C | F1.10 | [Dinheiro em centavos](#dinheiro-em-centavos-f110) |

### O que o app precisa acompanhar

Três pontos em que o app ainda não está alinhado com o servidor:

1. **A allowlist de `actionPath`.** O backend passou a aceitar a UNIÃO das duas
   listas — `/`, `/planning`, `/planning-50-30-20`, `/workspace/categories`,
   `/workspace/accounts`, `/transactions/form` (sempre com `?status=`),
   `/goals/form`, `/accounts/form`, `/category-details`, `/workspace/badges` e
   `/coaching/history`. O cliente
   (`coaching_slides_screen.dart`) precisa aceitar **exatamente esta lista**,
   inclusive `/`, que hoje ele recusa. Enquanto não aceitar, um slide que
   aponte para a tela principal chega com botão que não é desenhado. Ver
   [`actionPath` dos slides](#actionpath-dos-slides-de-coaching).
2. **`financialHealth` ausente** significa "ainda não calculei", não "score 0":
   a bússola deve aparecer em carregamento, não na patente Aprendiz.
3. **`streaks.plan`** é o contrato novo; `weeklyStreaks` continua sendo o
   número de missões e **não pode mudar de tipo**.
4. **Os campos `*Cents`** (F1.10) já existem em produção e são **server-only**.
   Nesta etapa o app **continua lendo e escrevendo só o `double`** e não deve
   enviá-los — as rules rejeitam. Na etapa C ele passa a preferi-los na
   leitura e a escrever os dois. Ver
   [Dinheiro em centavos](#dinheiro-em-centavos-f110).
5. **O CTA da missão semanal** (wp/missions-by-type). O documento passou a
   levar `actionPath`, e o app precisa de três coisas que ainda não tem:
   desenhar o botão no card da missão; aceitar `/reconciliation` na allowlist
   desse botão (o roteador já conhece a rota, com `?accountId=` opcional e um
   seletor de conta quando ele falta — quem não a conhece é a allowlist de
   COACHING, que continua sem ela de propósito); e preferir `nameKey` +
   `params` ao `name` quando souber a chave. O `name` continua vindo pronto em
   português para a build instalada. Ver
   [Missões por tipo de workspace](#missões-semanais-por-tipo-de-workspace).
6. **`audience` nos badges e nas fontes de XP** (wp/missions-by-type). O
   catálogo publicado marca cada badge e cada `xpSource` como `personal`,
   `business` ou `both`, e o campo vem **sempre preenchido**. O app deve
   esconder da vitrine o que não se aplica ao tipo do workspace aberto — o
   servidor já não os concede. Ver
   [Catálogo de badges](#catálogo-de-badges-configbadges).

### `undefined` não é gravado

Desde F1.11 o `ignoreUndefinedProperties` está **desligado** (`src/index.ts`):
gravar `undefined` num documento **lança**. Onde o descarte é legítimo — um
`Partial<Model>` em que a chave ausente quer dizer "não mexer", um campo que só
existe em fatura — ele é explícito, via `stripUndefined`
(`core/utils/firestore.utils.ts`), aplicado na camada de repositório.

Consequência para quem escreve código novo: **um campo opcional que você não
preencher simplesmente não existe no documento**, e um campo obrigatório que
chegar `undefined` derruba a escrita em vez de sumir calado. Os testes de
integração e os scripts rodam com a mesma configuração — sem isso o emulador
perdoaria o que a produção rejeita.

## Dinheiro em centavos (F1.10)

`0.1 + 0.2` vale `0.30000000000000004` em IEEE 754, e era exatamente assim que
este backend somava dinheiro: saldo diário por `FieldValue.increment` de
`double`, totais de `period_summaries` por incremento de `double`, total da
order por `reduce(+)`, progresso de meta por delta acumulado. O erro não some
sozinho — ele **acumula**, pagamento após pagamento. A única defesa espalhada
pelo código eram comparações com épsilon (`Math.abs(diff) > 0.01`, `1e-9`,
`0.005`), que escondem o sintoma e deixam a causa onde estava.

A regra nova é uma frase: **todo cálculo monetário do servidor soma CENTAVOS
INTEIROS, e o `double` gravado é o espelho `round2` do inteiro.**

### O plano, em três etapas

| Etapa | O que muda | Onde está |
|---|---|---|
| **A — aritmética segura já** | `core/utils/money.ts` e todo cálculo do servidor (saldo, sumários, XP, fatura, metas, Bússola, rebuild, análise de planejamento) passando a somar inteiros. As comparações com épsilon saem. **Nenhum campo novo.** | ✅ feita |
| **B — dupla escrita + migração** | campos inteiros paralelos `*Cents` em tudo. O servidor grava sempre os dois; um passo derivado nos gatilhos completa o inteiro do que o CLIENTE escreve. `migrate_money_cents` backfilla o acervo e verifica. | ✅ feita |
| **C — o app vira para o inteiro** | o app passa a **ler** `*Cents` (preferindo-os quando presentes) e a **escrever os dois**. Só depois disso o `double` vira campo derivado, e as rules podem passar a exigir a coerência entre os dois. | ⏳ depois do Flutter |

**Por que três etapas e não uma.** O app em campo lê o `double` — e continua
lendo por semanas, porque nem todo mundo atualiza no mesmo dia. Trocar o campo
de uma vez quebraria toda build instalada. A ordem inverte o risco: primeiro o
número fica certo (A), depois o inteiro passa a existir ao lado (B), e só
quando o app já sabe lê-lo é que o `double` deixa de ser a fonte (C).

### `core/utils/money.ts`

| Função | O que faz |
|---|---|
| `toCents(v)` | reais → centavos inteiros, **half-away-from-zero** e imune ao ruído de representação |
| `fromCents(c)` | centavos → reais com no máximo duas casas |
| `round2(v)` | `fromCents(toCents(v))` — o espelho que vai para o campo `double` |
| `addMoney`/`subtractMoney`/`sumMoney`/`sumCents` | soma e diferença exatas |
| `moneyEquals(a, b)` | "é a mesma quantia?", em substituição ao épsilon |
| `readCents(v)` / `resolveCents(double, cents)` | lê o campo `*Cents` gravado; **o inteiro é a fonte da verdade**, e o `double` só responde enquanto a migração não passou por aquele documento |
| `classifyMoney(v)` | distingue **ausente**, **número** e **presente-mas-inválido** — é o que permite denunciar um campo sujo em vez de gravar zero calado |
| `splitCents(total, n)` | reparte em partes inteiras, 1 centavo de resto por parte |

Dois detalhes que não são estilo:

**`toCents` não é `Math.round(v * 100)`.** `1.005 * 100` vale
`100.49999999999999`, e `Math.round` devolveria 100 centavos para o que o
usuário digitou como R$ 1,005. O literal decimal é a intenção; o `double` é só
a representação mais próxima dela. Antes de arredondar, `toCents` recorta o
valor escalado em **15 dígitos significativos** — o bastante para apagar o ruído
(que vive no 16º/17º dígito) e pouco o bastante para não perder precisão real em
valores grandes (as rules já limitam qualquer valor a ±1e12, e 1e12 × 100 = 1e14
cabe em 15 dígitos).

**O arredondamento é half-away-from-zero, não o `Math.round` do JavaScript.**
`Math.round(-0.5)` é `-0`, e com isso R$ −1,005 viraria −100 centavos enquanto
R$ 1,005 vira 101. O estorno deixaria de cancelar o lançamento. Aqui o módulo é
arredondado e o sinal é reposto depois, de modo que
`toCents(v) + toCents(-v) === 0` para todo `v`.

**Fora do intervalo exato, `toCents` LANÇA** (`MoneyRangeError`). Acima de
`MAX_SAFE_CENTS` (2^53 − 1 centavos, ≈ R$ 90 trilhões) o inteiro deixa de ser
exato, e devolver um número ali seria inventar uma quantia para quem pediu uma
conversão exata. As rules já limitam qualquer valor a ±1e12 — e 1e12 × 100 =
1e14 cabe folgado —, então o erro só alcança dado que entrou por fora delas: é
melhor parar do que seguir com um total silenciosamente errado. A migração
trata o campo como **inválido** em vez de deixar o erro derrubar a execução.

**Um campo que não é número nunca vira zero calado.** `toCents` devolve `0` para
`NaN`/`Infinity` — é o padrão de LEITURA que o resto do backend já adota para
documento sujo —, mas quem precisa SABER que o campo está sujo usa
`classifyMoney`. Uma **string numérica** (`"1000"`) é classificada como
`invalid` com o valor conversível ao lado: o dado é recuperável, mas o campo
está no tipo errado e quem grava precisa ser avisado. Coagir calado
transformaria um defeito de escrita do cliente em número aceito.

Havia **quatro cópias** de `Math.round(value * 100) / 100` no backend
(`finance.repository.impl`, `ai_validation`, `planning_analysis.utils`,
`coaching_context.utils`, `coaching.service`) e as quatro erravam o mesmo caso.
Hoje é uma função só.

### Os campos `*Cents`, por coleção

A lista ÚNICA vive em `MONEY_CENTS_FIELDS`, `SUMMARY_CENTS_FIELDS` e
`BALANCE_CENTS_FIELDS` (`features/finance/domain/models/finance.models.ts`). Ela
é consumida pelo passo derivado dos gatilhos, pelo script de migração e pelo
verificador — três lugares que, com uma cópia cada, divergiriam no primeiro
campo novo.

| Coleção | Campo `double` | Campo inteiro | Quem escreve |
|---|---|---|---|
| `orders` | `amount` | `amountCents` | servidor (criação, fatura, cascata) + passo derivado |
| `installments` | `amount` | `amountCents` | servidor + passo derivado |
| `installments` | `paidAmount` | `paidAmountCents` | servidor + passo derivado |
| `installments` | `referenceAmount` | `referenceAmountCents` | servidor + passo derivado |
| `accounts` | `initialBalance` | `initialBalanceCents` | passo derivado |
| `accounts` | `limit` | `limitCents` | passo derivado |
| `accounts.nextInvoice` | `amount` | `amountCents` | servidor (`InvoiceSyncService`) |
| `accounts/{a}/balance/{d}` | `delta` | `deltaCents` | servidor |
| `accounts/{a}/balance/{d}` | `balance` | `balanceCents` | servidor |
| `goals` | `targetAmount` | `targetAmountCents` | passo derivado |
| `goals` | `currentAmount` | `currentAmountCents` | servidor (progresso) + passo derivado |
| `category_planning` | `amount` | `amountCents` | passo derivado |
| `category_planning` | `appliedAmount` | `appliedAmountCents` | servidor (marcadores de F1.5) |
| `period_summaries.categories.{id}` | `generalPlannedAmount` | `generalPlannedAmountCents` | servidor |
| `period_summaries.categories.{id}` | `specificPlannedAmount` | `specificPlannedAmountCents` | servidor |
| `period_summaries.categories.{id}` | `actualAmount` | `actualAmountCents` | servidor |

**Ausente continua ausente.** Um `paidAmount` que não existe **não** vira
`paidAmountCents: 0` — isso diria que a parcela foi paga com valor zero, que é
uma afirmação diferente de "não foi paga". Um inteiro pendurado sem o `double`
correspondente é resíduo e o passo derivado o **apaga**.

### O passo derivado dos gatilhos

O servidor grava o par em tudo que ele escreve. Mas `orders`, `installments`,
`accounts`, `goals` e `category_planning` também são escritos pelo **app**, que
nesta etapa só conhece o `double`. Uma order criada pelo app nasceria com
`amount` e sem `amountCents` — e o inteiro, que é a fonte da verdade, ficaria em
branco justamente no documento mais novo.

`core/utils/money_cents.ts` resolve isso com um passo no gatilho de cada
coleção, com três propriedades obrigatórias:

1. **idempotente** — calcular duas vezes dá o mesmo patch;
2. **só escreve se MUDAR** — um documento já correto não gera escrita, e sem
   isso o gatilho se realimentaria para sempre;
3. **não dispara o gatilho de novo** — os `*Cents` estão nas guardas por
   conteúdo, então o evento que essa escrita produz sai cedo.

| Gatilho | Guarda por conteúdo |
|---|---|
| `onInstallmentWritten` | `INSTALLMENT_DERIVED_FIELDS` (já existia; ganhou os três `*Cents`) |
| `onOrderWritten` | **`ORDER_DERIVED_FIELDS` — NOVA** |
| `onGoalWritten` | **`GOAL_DERIVED_FIELDS` — NOVA** |
| `onCategoryPlanningWritten` | `CATEGORY_PLANNING_DERIVED_FIELDS` (ganhou os dois `*Cents`) |
| `onAccountCreated`/`onAccountUpdated` | não precisa: o handler já reage por **lista de permissão** estreita, e nenhum `*Cents` está nela |

> ⚠️ **As duas guardas NOVAS não são otimização.** A order não tinha guarda
> nenhuma: qualquer escrita nela dispara `onOrderWritten`, que reexecuta
> `syncInstallments` **e grava um documento em `orders/{id}/history`**. Sem
> `ORDER_DERIVED_FIELDS`, completar o `amountCents` das 1.074 orders de produção
> criaria 1.074 registros de histórico do nada. Em `goals`, o mesmo evento
> recalcula o progresso e reavalia a bateria inteira de badges.

O passo fica **fora** da idempotência por `eventId_action` de propósito:
reexecutá-lo é inofensivo (é uma função do conteúdo do documento, não um
incremento), e ele não pode ser pulado só porque o marcador daquele evento já
existia. Ele usa `update` e nunca `set`: se o documento for apagado entre o
evento e a escrita, o `NOT_FOUND` é engolido — ressuscitar uma order apagada com
um único campo seria pior do que não completar o inteiro.

**O que ele NÃO faz:** nunca corrige o `double` a partir do inteiro. Nesta etapa
o app ainda escreve o `double`, e sobrescrevê-lo seria o servidor discordando do
usuário. Quem reconcilia os dois é o `rebuild_workspace`.

#### O evento carrega o inteiro DEFASADO — os handlers normalizam em memória

Corrigir o banco não basta, e essa foi a lição de um defeito em produção.

O payload de um evento do Firestore é o documento **como ele estava naquele
instante**. Quando o app edita um valor (`amount: 500 → 1000`), ele não toca no
espelho — os `*Cents` são server-only —, então o `afterData` chega com o
`double` NOVO e o inteiro VELHO. O passo derivado conserta o documento, mas o
objeto em memória continua mentindo; e toda a regra de negócio abaixo dele
resolve dinheiro por `resolveCents`, que **prefere o inteiro**.

O resultado observado: uma edição de limite de R$ 500 para R$ 1.000 era aplicada
nos sumários como R$ 500, com `appliedAmount: 500` nos marcadores — e o segundo
evento (o eco da escrita do espelho) saía pela guarda por conteúdo sem corrigir
nada. O mesmo padrão valia para `amount`/`paidAmount` de parcela (um aumento de
R$ 100 para R$ 250 virava delta ZERO no saldo e no sumário) e para o
`targetAmount` de meta (baixar o alvo não desfechava).

**A correção é `withFreshCents(data, fields)`** (`core/utils/money_cents.ts`):
uma CÓPIA do payload com todos os `*Cents` recalculados a partir do `double`,
pela mesma regra de `buildCentsPatch`. Os handlers montam `before` e `after` a
partir dela — os dois lados, porque o `before` também pode carregar um espelho
defasado se o evento anterior ainda não tinha sido patchado.

| Handler | O que normaliza |
|---|---|
| `onInstallmentWritten` | `amount`, `paidAmount`, `referenceAmount` (em `toInstallmentModel`) |
| `onCategoryPlanningWritten` | `amount`, `appliedAmount` |
| `onGoalWritten` | `targetAmount`, `currentAmount` — depois da guarda e do patch |
| `onOrderWritten` | `amount` |
| `onAccountCreated`/`onAccountUpdated` | `initialBalance`, `limit` |

> **Por que NÃO relaxar o `resolveCents`** para só preferir o inteiro quando ele
> bate com o `double`: isso apagaria o sinal. A divergência entre os dois é
> exatamente o que o `--verify` da migração existe para denunciar, e um
> `resolveCents` tolerante faria toda divergência virar "o `double` ganha", em
> silêncio, em todo lugar. `withFreshCents` tem escopo explícito: o payload de
> um evento, onde a divergência tem causa conhecida e inofensiva.

Nos handlers de **order** e de **conta** a normalização é profilaxia: hoje
nenhum consumidor lê o `amountCents` da order nem o `initialBalanceCents` da
conta a partir do evento (`syncInstallments` reparte o `double`,
`syncInitialBalance` monta a order sintética a partir dele). Os testes desses
dois casos travam o CONTRATO do handler — o modelo entregue ao serviço carrega
um par coerente —, para que trocar um `amount` por `resolveCents(...)` lá dentro
amanhã não reintroduza o defeito calado.

Coberto por `src/test/integration/stale_cents.integration.test.ts` (os cinco
caminhos, cada um falhando sem a normalização) e pelos unitários de
`withFreshCents` em `src/test/migrate_money_cents.test.ts`.

### O `FieldValue.increment` saiu de todo caminho de dinheiro

Saldo diário, `period_summaries` e a order de fatura são escritas
**concorrentes**: ler-somar-gravar perderia deltas, e era por isso que elas
usavam `FieldValue.increment`. Com o par (inteiro + espelho), isso deixou de
funcionar por uma razão simples:

> **Incrementar um campo que não existe começa do ZERO.**

Num documento anterior à migração — `actualAmount: 1000`, sem
`actualAmountCents` — um delta de +25 produzia `actualAmount: 1025` (certo) e
`actualAmountCents: 2500` (errado). E o inteiro é a **fonte da verdade**: o
número errado é justamente o que manda. Semear o campo fora da escrita não
resolve: entre ler a semente e commitar, outro evento pode ter criado o campo.

Então os quatro caminhos monetários passaram a **ler e gravar valor absoluto
dentro de uma transação**:

| Caminho | Como era | Como é |
|---|---|---|
| `period_summaries` (gatilho e planejamento) | `set` com 6 `increment` | transação: `getAll` dos documentos do lote → `set` com os valores calculados a partir do inteiro |
| `accounts/{a}/balance` (dia) | já era transacional | idem, agora com o par |
| `accounts/{a}/balance` (propagação) | `increment` em lotes de 400 | transação por página de 100 dias |
| `orders` de fatura (`updateInvoiceWithDelta`) | `set` com 2 `increment` | transação: lê a order, grava o total absoluto |

Dentro da transação o valor lido e o gravado pertencem ao mesmo instante
lógico: o Firestore aborta e repete se qualquer documento lido mudar antes do
commit. **O preço é contenção onde antes não havia** — um documento mensal
tocado por dois pagamentos simultâneos faz um dos dois repetir. É um preço
pequeno perto de gravar um total errado, e os lotes são pequenos de propósito
(100 documentos por transação) para manter a janela estreita.

O `increment` continua onde **não há dinheiro**: o `xp` semanal
(`weekly_xp.xp`), que não tem espelho inteiro e não sofre do problema.

**Consequência colateral, e boa:** o `double` deixou de poder escorregar. Ele é
sempre `fromCents(cents)` na escrita, então a dízima
(`677.4300000000001`) só existe no acervo gravado ANTES deste pacote. O
`rebuild_workspace` continua sabendo corrigi-la.

### O planejado do sumário mudou na SEGUNDA CASA

Esta é a única mudança de VALOR que o pacote grava, e ela é deliberada.

O `generalPlannedAmount` vem de `category_planning` rateado no período, e o
rateio semanal é uma dízima: R$ 1.000,00 num mês de 31 dias dá
`1000 / 31 * 7 = 225.80645161290323`. Antes esse número ia para o documento
inteiro, com dezesseis casas. Agora ele é **arredondado ao centavo na origem**
(`round2`), em `SummaryService.calculatePlanningImpacts`, e o sumário recebe
`225.81`.

O mesmo vale para o valor mensal quando o limite tem mais de duas casas:
`250.555` passa a entrar como `250.56`.

| Onde | Antes | Agora |
|---|---|---|
| semana de um mês de 31 dias, limite R$ 1.000 | `225.80645161290323` | `225.81` |
| mês, limite `250.555` | `250.555` | `250.56` |

**Por que arredondar na origem e não na gravação.** O gatilho e o
`rebuild --rebuild-planning` calculam o mesmo rateio por caminhos diferentes.
Arredondando só na escrita, cada um acumularia o seu resíduo e os dois
divergiriam — que é exatamente o tipo de diferença que o dry-run do rebuild
passaria a acusar todo mês. Arredondando na função única que os dois chamam,
eles chegam ao mesmo inteiro.

**Volume estimado em produção:** cerca de **2.043 totais** de
`period_summaries` mudam na segunda casa decimal (os semanais dos 80
planejamentos vigentes, mais os mensais de limite com mais de duas casas). A
diferença por total é de **menos de um centavo**; a soma das semanas de um mês
continua entre ~93% e ~117% do valor mensal, como sempre esteve — é proporção
semanal, não rateio exato, e é assim que o app a apresenta. Nenhum saldo,
realizado ou projetado muda: esses vêm de parcelas, que já eram valores de duas
casas.

A mudança aparece no dry-run do `rebuild --rebuild-planning` (passo 11 do
rollout) e se consolida ali, ou no primeiro cron mensal depois do deploy.

### Comparações com épsilon: o que saiu

| Onde | Antes | Agora |
|---|---|---|
| `finance.repository.impl` | `PLANNING_DELTA_EPSILON = 1e-9` | `deltaCents === 0` — estorno e reaplicação do mesmo mês se anulam exatamente |
| `goal.model` / `goal.service.impl` | `AMOUNT_EPSILON = 0.005` (duas cópias) | comparação de inteiros: "alcançou o alvo" é ao centavo |
| `rebuild.service` | `epsilon` (opção do job, padrão 0,005) | a opção **sumiu**; a comparação é de inteiros, e o espelho é conferido à parte |
| `finance.service.calculateXp` | `Math.abs(diff) > 0.01` | `Math.abs(diffCents) > 1` — ver abaixo |
| `invoice_sync.isSameNextInvoice` | `current.amount === next.amount` | comparação de inteiros |
| `diffInstallmentForCascade` | `after.amount !== before.amount` | comparação de inteiros |

**A mudança de comportamento no XP é uma correção de inconsistência**, não uma
mudança de regra. A faixa morta continua sendo de **um centavo**, mas antes ela
não valia sempre: em `double`, `0.02 − 0.01` dá `0.010000000000000002` (era
punido) e `3.01 − 3.00` dá `0.009999999999999787` (não era). A **mesma**
diferença de um centavo tinha dois vereditos, conforme os valores envolvidos.
Hoje um centavo nunca conta, dois centavos sempre contam.

**As duas mudanças de resultado do pacote, juntas:** esta e o arredondamento do
rateio do planejado (seção acima). Fora delas, todo cálculo devolve os mesmos
números de antes — é o que as 888 asserções unitárias e as 202 do emulador
verificam, com os fixtures inalterados.

### `rebuild_workspace` com os dois campos

O job passou a:

- **ler** o inteiro como fonte da verdade (`resolveCents`) das parcelas, dos
  saldos e dos sumários;
- **gravar** os dois campos em todo documento que reconstrói;
- **comparar** os dois. Um documento cujo `*Cents` bate mas cujo `double`
  escorregou (resíduo de `FieldValue.increment`) **passou a ser divergência** —
  e é justamente o `double` que o app lê nesta etapa. O contador
  `generalPlannedChanges` continua contando só mudança de QUANTIA, então dá para
  distinguir no dry-run "o planejado mudou" de "o espelho estava sujo".

Um efeito prático: no primeiro rebuild depois deste pacote, é normal ver
documentos de `period_summaries` marcados como `alterar` com
`generalPlannedChanges = 0`. São espelhos com dízima
(`677.4300000000001` onde o inteiro diz `67743`) sendo reescritos — resíduo de
anos de `FieldValue.increment` em `double`, que o caminho de escrita novo já
não produz. Do segundo rebuild em diante o número cai a zero.

### Contrato com o cliente Flutter

**Nesta etapa (B) o app segue lendo e escrevendo o `double`** — mas ele tem UMA
mudança obrigatória, e ela precede o deploy.

Os campos `*Cents` existem ao lado, são **server-only**, e as rules os rejeitam
se o app tentar enviá-los — inclusive num formulário que serialize o documento
inteiro. A negação é por **diferença de valor**: reenviar exatamente o que o
servidor gravou é um no-op e passa. Como o app nunca produziu esses campos, isso
sozinho não o afeta.

> ⚠️ **O que MUDA para o app: `goals.currentAmount` passou a ser server-only no
> update.** Quem o mantém é o servidor desde wp/gamification-2 e o formulário já
> não pede esse valor — mas a build publicada hoje ainda o **reenvia** com o que
> leu ao abrir a tela. Enquanto o valor não muda, passa; se um pagamento cair
> entre abrir e salvar, a edição inteira é rejeitada e o usuário perde a
> alteração que estava fazendo.
>
> Por isso o **passo 0** do [rollout](#ordem-de-rollout) é publicar o app sem
> esse campo no `updateGoal`, e só então subir as rules. Não há versão tolerante
> da regra: aceitar o número defasado desfaria um progresso que o servidor
> acabou de calcular — poder reescrevê-lo é poder declarar a própria meta
> cumprida, com os badges e o XP que vêm junto. O **create** continua aceitando:
> a meta nasce em zero pelo formulário.

**Na etapa C**, em duas escritas e uma leitura:

1. **ler preferindo o inteiro.** Onde hoje o modelo Dart lê `amount`, passa a
   ler `amountCents` quando presente e a cair em `amount` quando não — a mesma
   regra de `resolveCents` no servidor. Enquanto houver documento não migrado
   (ou escrito por uma build antiga), o `double` responde;
2. **escrever os DOIS.** Todo formulário que hoje grava `amount: 10.5` passa a
   gravar `amount: 10.5` **e** `amountCents: 1050`, na mesma escrita. As rules
   deixam de negar os `*Cents` e passam a **exigir a coerência** entre os dois
   (`amountCents == int(amount * 100)`), que é a garantia que só pode existir
   depois que o cliente sabe produzi-la;
3. **o `double` vira derivado.** A partir daí o servidor pode reescrever o
   espelho a partir do inteiro sem discordar do usuário — o que hoje ele
   deliberadamente não faz.

> **Por que o app não pode pular para a etapa C agora.** Enquanto houver build
> em campo que só escreve o `double`, um documento pode chegar com o `double`
> novo e o `*Cents` velho. O passo derivado do gatilho conserta isso em
> segundos, mas nesse intervalo o inteiro está errado — e o inteiro é a fonte da
> verdade. A ordem (servidor primeiro, app depois) é o que garante que o campo
> que manda nunca fique desatualizado por escrita de cliente.

**O que o app pode fazer desde já, sem esperar:** formatar a partir do
`*Cents` quando ele existir, nas telas em que o valor é só exibido. É leitura,
não muda contrato nenhum e acaba com o `R$ 0,30000000000000004` que aparecia em
totais somados no cliente.

### Testes

- `src/test/money.test.ts` — o módulo: `0.1+0.2`, `1.005`, `2.675`, `8.165`,
  negativos simétricos, 1e6 parcelas de um centavo, repartição exaustiva,
  precisão em valores grandes, `-0`;
- `src/test/money_pipeline.test.ts` — a aritmética DENTRO das regras: total da
  order, XP (com a faixa morta de um centavo), impactos de planejamento
  (estorno + reaplicação dão zero exato) e desfecho de meta;
- `src/test/migrate_money_cents.test.ts` — a regra do backfill e do passo
  derivado, lado a lado;
- `src/test/integration/money_cents.integration.test.ts` — o efeito contra o
  emulador: campos criados, `double` intocado, segunda passada sem escrita,
  `--verify` acusando e calando, órfão apagado, checkpoint zerado, e o passo
  derivado que não ressuscita documento apagado;
- `src/test/integration/cents_guards.integration.test.ts` — as guardas por
  conteúdo contra o emulador: o eco da escrita do espelho não gera
  `orders/{id}/history`, não recalcula meta nem badge, não estorna o
  planejamento e não ressincroniza a fatura — e uma mudança REAL ao lado do
  espelho continua passando;
- `src/test/rules/firestore_rules.test.ts` — os `*Cents` negados ao cliente nas
  cinco coleções e o `currentAmount` da meta no update, com o reenvio do mesmo
  valor tolerado e o reenvio DEFASADO negado (o cenário do passo 0 do rollout).

Ao todo: **888** asserções unitárias (`npm run test:unit`) e **202** no
emulador (`npm run test:integration`), das quais **78** são de security rules.

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

## Tipagem: o que o compilador garante (F1.11)

As interfaces de repositório eram o lugar onde a tipagem terminava. `IFinance`,
`IGamification`, `IGoal`, `IWorkspace`, `IHealth` e `IRebuild` somavam 22
assinaturas com `any`, e com elas coleções inteiras — `period_summaries`,
`financial_coaching`, `planning_analysis`, `weekly_missions` — atravessavam o
backend sem forma nenhuma. Nada disso era teórico:

- o modelo `PeriodSummaryModel` descrevia um documento **por categoria**
  (`YYYY-MM-categoryId`) que nunca existiu — por isso ninguém o importava, e
  quem lia o sumário lia `any`;
- a mesma "meta" circulava ora como documento cru (com `Timestamp`), ora como
  `GoalModel` (com `Date`), e três laços que liam `paidDate` tinham três
  tratamentos diferentes para o campo ausente;
- o `ExistingDoc` do rebuild era `Record<string, any>` para as **três**
  coleções comparadas: comparar `doc.data.xp` com um documento de saldo
  compilava sem uma palavra.

Hoje `tsc` pega acesso a campo inexistente nesses caminhos. Três regras que o
código passou a seguir:

1. **Documento cru e modelo são tipos DIFERENTES.** `GamificationGoal` e
   `GamificationInstallment` descrevem o que está no Firestore (datas como
   `RawFirestoreDate`, campos opcionais); `GoalModel` e `InstallmentModel`
   descrevem o que o domínio manipula (datas como `Date`). Prometer `Date` num
   documento cru é a mentira que produzia `NaN` silencioso.
2. **Leitura normaliza; consumidor não repete `?? 0`.** `toPeriodSummaryDocument`,
   `toCoachingAnalysisDocument` e `toPlanningAnalysisDocument` aplicam na
   ENTRADA os padrões que antes estavam espalhados por cada leitor — e que, por
   estarem espalhados, podiam faltar em um deles.
3. **Escrita e leitura de um mesmo documento podem ter tipos diferentes.**
   `weekly_missions` tem `WeeklyMissionWrite` (tudo obrigatório: quem cria é o
   servidor) e `WeeklyMissionDocument` (tudo opcional: a missão pode ser de uma
   versão anterior). Fundir os dois obrigaria a mentir num dos lados.

### O que MUDOU de comportamento

O pacote é um refactor, mas tipar um documento obriga a decidir coisas que o
`any` deixava em aberto. Estas são as decisões com efeito observável — todas
deliberadas, nenhuma incidental:

**Escrita: a data deixou de ter fallback.** `saveCoachingAnalysis` e
`savePlanningAnalysis` faziam
`analysis.date instanceof Date ? Timestamp.fromDate(...) : serverTimestamp()`.
Com `date`/`createdAt` obrigatórios e tipados como `Date` no contrato de
escrita, o `serverTimestamp()` virou código morto e saiu: a conversão é
incondicional. O efeito prático é nenhum (o único chamador sempre passou um
`Date`), mas quem chamar amanhã com outra coisa **não compila**, em vez de
gravar um carimbo do servidor onde se esperava a hora da geração.

**Leitura: o documento é normalizado na entrada.** `getPeriodSummary`,
`getLastCoachingAnalyses` e `getPlanningAnalysis` deixaram de devolver
`{id, ...doc.data()}` cru e passam por um leitor (`toPeriodSummaryDocument`,
`toCoachingAnalysisDocument`, `toPlanningAnalysisDocument`). Três consequências:

- **campo fora do modelo SOME.** Um documento com uma chave que o modelo não
  declara não a entrega mais ao serviço. É o preço de ter um contrato — e o
  ponto: um campo que ninguém declarou é um campo que ninguém mantém;
- **`runtimeType` ausente ou fora do enum vira `"month"`.** Todo documento
  gravado pelo servidor tem o campo; o padrão cobre o legado, e `month` é o
  caso dominante;
- **total não numérico vira `0`.** `generalPlannedAmount`, `specificPlannedAmount`
  e `actualAmount` são sempre `number` no modelo. Antes, um valor sujo chegava
  ao consumidor como estava e só virava zero se aquele leitor tivesse lembrado
  do `|| 0`.

**Ordem do spread: o id do DOCUMENTO vence.** As leituras da gamificação
passaram de `{id: doc.id, ...doc.data()}` (ou `doc.data()` puro) para
`{...doc.data(), id: doc.id}`. Se um dia um documento de workspace, meta,
parcela ou planejamento guardar um campo `id` diferente do id do documento, é o
id do documento que prevalece — que é o que qualquer leitor espera de `.id`.
Hoje nenhum desses documentos tem o campo, então o efeito é nulo; a exceção
consciente é `weekly_missions`, cujo documento **tem** um campo `id` (o tipo da
missão) que o app lê, e cuja leitura por isso não o sobrescreve.

**`getCategoryPlannings` da gamificação passou a devolver o `id`.** Ele não é
campo da coleção: é o id do documento, e era o que faltava para a leitura caber
em `CategoryPlanningModel` em vez de `any[]`. Nenhum consumidor o lê.

**Insight sem `message` e sem `summary` passa a ser GRAVADO com o texto
padrão**, em vez de `summary: ""`. A resposta ao app é a mesma de antes, porque
o `formatResponse` já caía nesse mesmo texto — o que muda é o documento, que
deixa de guardar um vazio que ninguém queria ler.

Fora da tipagem, duas outras mudanças deste pacote têm efeito observável e
estão documentadas onde moram: a **allowlist de `actionPath`** passou a aceitar
a união das rotas do servidor e do app (ver
[`actionPath` dos slides](#actionpath-dos-slides-de-coaching)) e o **aviso de
categoria sem id** passou a julgar a categoria efetiva, denunciando a
transferência com categoria quebrada que antes saía calada (ver
[Categoria sem id](#categoria-sem-id-fora-dos-sumários)).

### Onde a regressão é barrada

`@typescript-eslint/no-explicit-any` está **ligado como erro** para
`src/features/*/domain/repositories/**` e `src/features/*/data/repositories/**`
(override no `.eslintrc.js`). O `any` continua permitido no resto do código,
onde às vezes ele é o tipo honesto para "o que o modelo devolveu"; na camada de
repositório, não — um documento do Firestore tem forma, e escrevê-la é o que
faz o compilador pegar o acesso a campo inexistente. Sem o override, o pacote
regrediria na primeira assinatura nova, e regrediria em silêncio.

Os **17** arquivos de teste de integração (`src/test/integration/*.integration.test.ts`;
`setup.ts` não conta) rodam com `ignoreUndefinedProperties: false`, igual à
produção. A execução do emulador reporta 18 suítes porque a de security rules
entra no mesmo `jest.integration.config.js`.

### Flags do compilador

`strict` já estava ligado. **`noImplicitAny` passou a `true`** — custo medido na
adoção: **zero** erros, em produção e em teste.

**`noUncheckedIndexedAccess` ficou de fora**, com o custo registrado: medido no
mesmo momento, ele custava **47 erros no build de produção e 282 no de teste**
(`map.get()`, `array[0]`, `Object.entries` sobre mapas de sumário). É um ganho
real — um `map.get()` que devolve `undefined` é uma classe de defeito que hoje
não é pega —, mas exigiria centenas de guardas mecânicas misturadas a este
refactor. Um refactor que muda o que se lê em cada linha é o pior lugar
possível para esconder uma mudança de comportamento. Fica como pacote próprio.

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
- **A missão semanal é validada contra o TEMPLATE que o servidor escolheu**, e
  não só contra a forma: `validateWeeklyMissionNames` exige que a resposta ecoe
  o `templateKey`, mantenha o alvo, contenha os radicais do objetivo e não use
  o vocabulário da outra audiência. É o único validador que compara a resposta
  com uma decisão que o servidor já tinha tomado — porque é o único caso em que
  a IA não decide o CONTEÚDO, só a redação. Ver
  [Missões por tipo de workspace](#missões-semanais-por-tipo-de-workspace).

### `actionPath` dos slides de coaching

O `actionPath` de um slide vira `context.push` no app, então ele é validado
contra uma **allowlist de rotas**. A lista vive em UM lugar
(`features/coaching/domain/models/coaching_action_path.model.ts`) e alimenta os
dois consumidores: `sanitizeActionPath` (`coaching.service.ts`) e o trecho do
prompt em `ai.config.ts`, que é **gerado** dela. Rota fora da lista: o slide vai
**sem botão**.

| Rota | Quando a IA deve usá-la |
|---|---|
| `/planning` | definir ou revisar o limite mensal de uma categoria |
| `/planning-50-30-20` | rebalancear essencial/conforto/investimento |
| `/transactions/form?status=pending` | agendar/planejar um lançamento futuro |
| `/transactions/form?status=paid` | registrar algo que já aconteceu |
| `/goals/form` | criar uma meta |
| `/accounts/form` | cadastrar uma conta ou cartão |
| `/workspace/categories` | criar, renomear ou reclassificar categorias |
| `/workspace/accounts` | ver contas e saldos |
| `/category-details` | ver o relatório de gasto por categoria |
| `/workspace/badges` | ver conquistas |
| `/coaching/history` | reler insights anteriores |
| `/` | tela principal — só quando nenhuma outra servir |

**Esta lista é a UNIÃO das duas que existiam.** Até F1.11 o backend aceitava
`/` e recusava as cinco rotas de formulário/detalhe; o cliente fazia
exatamente o contrário. As duas divergências eram **mudas**: a rota que o
backend recusava saía sem botão (o slide pedia "crie uma meta" e não havia como
ir criá-la) e a que o cliente não reconhecia chegava com um botão que não era
desenhado. Nenhum dos dois casos gera erro, log ou teste vermelho.

> **O cliente Flutter precisa aceitar exatamente esta lista**, inclusive `/`,
> que hoje ele recusa (`coaching_slides_screen.dart`). É a única ponta que
> falta — o pacote do app cuida dela.

**A allowlist do CTA da MISSÃO é outra lista** (`MISSION_ACTION_PATHS`, em
`features/goal/domain/models/mission_catalog.ts`): é esta aqui mais
`/reconciliation`. As duas ficam separadas de propósito. `/reconciliation`
existe no roteador do app desde sempre (com `?accountId=` opcional e um seletor
de conta quando ele falta), mas **não** está na allowlist de coaching da build
instalada: oferecê-la ao prompt de coaching produziria um slide com botão que
ninguém desenha — a mesma falha muda que o F1.11 acabou de corrigir. O CTA da
missão é superfície NOVA, sem build antiga para quebrar, então lá a rota pode
entrar já. Um teste (`mission_catalog.test.ts`) trava a diferença entre as duas
listas em exatamente esse item, para a próxima adição ser deliberada.

A allowlist casa só o **caminho**; a **query string sobrevive filtrada**, um
parâmetro conhecido por vez, com valor dentro da lista e em ordem
determinística. Parâmetro ou valor desconhecido é descartado em silêncio — a IA
alucina query string com a mesma facilidade com que alucina rota. Só
`/transactions/form` aceita query: `/planning` e `/category-details` leem `type`
no app, mas o prompt não os oferece com parâmetro, e liberar no validador o que
a IA não foi instruída a mandar só aumentaria a superfície da alucinação.

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

> **F1.11 fechou um buraco aqui.** O aviso decidia olhando `inst.category` — a
> categoria ORIGINAL —, enquanto a guarda que o chamava tinha acabado de
> recusar a categoria EFETIVA, que numa transferência é a VIRTUAL. Duas
> perguntas diferentes sobre o mesmo evento. O efeito: uma transferência com
> categoria quebrada (`{id: ""}`) e **sem** contrapartida de
> dívida/investimento saía do serviço antes da guarda e ficava fora do sumário
> **sem uma palavra no log** — exatamente a primeira linha da tabela acima, que
> diz "sim, avisa, é o defeito real". Hoje o aviso julga sempre a categoria com
> que a parcela saiu do sumário, e o caminho da transferência sem contrapartida
> passa por ele. O silêncio da linha de baixo continua intacto.

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
- **`audience`** (wp/missions-by-type) ∈ `personal | business | both`, e vem
  **sempre preenchido** no documento publicado: o `both` implícito do servidor
  é materializado aqui para o app filtrar com uma comparação, sem ter de
  conhecer o padrão. Cinco badges são `personal` — `under_control`,
  `golden_rule`, `cost_cutter`, `future_focus` e `savings_10pct` —, todos
  ancorados numa regra de finança PESSOAL: a 50-30-20
  (essencial/conforto/investimento) e o "poupar X% da renda". Uma empresa não
  divide faturamento em "conforto", e deixar na vitrine dela uma conquista
  inalcançável é o mesmo defeito da missão "Reduzir gastos com alimentação"
  num workspace de empresa. Todos os demais continuam `both`: conciliar,
  planejar, cadastrar conta e concluir meta valem igual nos dois.
  As `xpSources` carregam o mesmo campo, hoje todas `both`.

  **O filtro NÃO custa leitura.** Ele mora dentro da transação de
  `unlockBadge`, que já lê o documento do workspace para somar o XP. No
  serviço, cada checagem de badge pagaria uma leitura extra — e são dezenas
  por evento. Um badge fora da audiência devolve `false`, exatamente como um
  já desbloqueado.

  **Pendência consciente:** nenhum badge é `business` ainda. O recorte deste
  pacote foi *tirar* da empresa o que não se aplica; dar a ela conquistas
  próprias (margem, fechamento no prazo, conciliação de todas as contas) é
  pacote seguinte, e o campo já está no contrato para isso não exigir outra
  mudança de forma.
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

## Missões semanais por tipo de workspace

O produto atende **dois** tipos de usuário — `workspaces.type` = `personal` |
`business` — e isso vale para funcionalidade e para texto. Até este pacote não
valia: um workspace de EMPRESA recebeu a missão semanal *"Reduzir gastos com
alimentação"*.

A causa não era o prompt. O **objetivo** da missão era escolhido pela IA, que
recebia `workspaceType` como contexto e não como regra, e os fallbacks de
quando ela falhava eram três frases fixas em linguagem doméstica ("Equipe
planeja limites…"). Nada no caminho podia recusar uma missão fora do tipo,
porque nada no caminho sabia o que era estar dentro dele.

O objetivo passou a ser **dado**.

### O catálogo

`features/goal/domain/models/mission_catalog.ts` guarda, por audiência e por
tipo de missão, um template com: `key` estável, `name` em `pt`/`en` com
placeholders (`{category}`, `{target}`), `target`, `rewardXp`, `progressRule`,
`actionPath` (o CTA) e `nameKey` (a chave de i18n para o app).

| Audiência | Tipo | `key` | O que a missão pede | `progressRule` | Alvo | XP | CTA |
|---|---|---|---|---|---|---|---|
| personal | consistency | `personal_consistency_plan_limits` | planejar limite para N categorias | `planned_categories` | 3 | 150 | `/planning` |
| personal | discipline | `personal_discipline_top_category` | manter a maior categoria no orçamento por N dias | `days_within_category_limit` | 5 | 250 | `/planning` |
| personal | organization | `personal_organization_reconcile_items` | conciliar um extrato com ao menos N itens | `reconciled_statement_items` | 5 | 200 | `/reconciliation` |
| business | consistency | `business_consistency_cost_centers` | planejar o limite de N centros de custo do mês | `planned_categories` | 5 | 150 | `/planning` |
| business | consistency | `business_consistency_income_forecast` | receber N% da receita prevista da semana | `income_received_vs_planned` | 80 | 150 | `/planning` |
| business | discipline | `business_discipline_top_cost_center` | manter o maior centro de custo no plano por N dias | `days_within_category_limit` | 5 | 250 | `/planning` |
| business | discipline | `business_discipline_margin` | fechar a semana com margem acima da planejada | `weekly_margin_above_plan` | 1 | 250 | `/planning` |
| business | organization | `business_organization_reconcile_statements` | conciliar N extratos das contas da empresa | `reconciled_statements` | 1 | 200 | `/reconciliation` |
| business | organization | `business_organization_categorize_auto` | categorizar ou descartar N lançamentos automáticos | `categorized_auto_transactions` | 3 | 200 | `/workspace/categories` |
| business | organization | `business_organization_invoice_on_time` | pagar a fatura corporativa até o vencimento | `invoice_paid_on_time` | 1 | 200 | `/workspace/accounts` |

**Pessoal mantém os três objetivos que já existiam** — são os que estão em
produção e os que o jogo já sabe medir. O que mudou neles foi o TEXTO: os
fallbacks diziam "Equipe planeja limites…" dentro de um workspace doméstico de
uma pessoa só.

**Os alvos corporativos são calibrados contra a base real**, não contra o que
soa ambicioso. A única empresa da base fez **duas conciliações na vida inteira**
e recebeu **dois lançamentos automáticos** na semana medida; os alvos originais
(2 extratos e 10 lançamentos POR SEMANA) eram inalcançáveis, e missão
inalcançável não ensina nada — ela só impede a semana perfeita e zera a streak
de quem está fazendo tudo certo.

### Elegibilidade: a peneira antes do sorteio

Duas missões de empresa dependem de um dado que pode simplesmente não existir
naquela semana. A de receita prevista precisa de receita prevista; a de margem
precisa dos DOIS lados do plano. Sortear uma delas numa semana sem esse dado
produz uma missão que o avaliador **não tem como medir**: 0% por sete dias,
semana perfeita impossível e streak zerada, sem que o usuário tenha feito nada
de errado.

Por isso o template pode declarar `isEligible(context)`, e o contexto são os
totais PLANEJADOS da semana, lidos uma vez na geração:

| Template | Elegível quando |
|---|---|
| `business_consistency_income_forecast` | `plannedIncomeCents > 0` |
| `business_discipline_margin` | `plannedIncomeCents > 0` **e** `plannedExpenseCents > 0` |

A peneira roda **antes** do hash: numa semana sem receita prevista, a
consistência da empresa cai sempre em "planejar centros de custo", que é o que
se quer. Se a peneira não deixasse ninguém de pé, o sorteio voltaria a correr
entre todos os candidatos — uma semana sem missão seria pior que uma missão
difícil de medir, porque o card some da tela e a streak quebra sem explicação.
Hoje isso não acontece: cada par audiência×tipo tem ao menos um template sem
`isEligible`, e há teste para continuar assim.

O contexto só é lido em workspace `business` — num pessoal nenhum template tem
`isEligible`, e a leitura seria paga para nada.

> **Quem consulta o catálogo precisa passar o MESMO contexto.** A peneira roda
> antes do hash, então o contexto passou a fazer parte da escolha: sortear sem
> ele é sortear entre um conjunto maior de candidatos e chegar a outro
> template. O `retag_weekly_missions` sorteava sem contexto e divergia do
> gerador em **52 das 53 semanas** do ano (nos dois tipos que têm peneira) —
> ele carimbaria `top_cost_center` numa semana em que o gerador escolheu
> `margin`, e o documento passaria a descrever uma missão que não é a que está
> na tela. Hoje o script lê o sumário do MESMO lugar (`period_summaries/{weekId}`
> + `categories`) e soma com a MESMA função (`sumWeeklyTotals`), e há um teste
> que roda os dois caminhos de código sobre os mesmos dados, nos quatro
> contextos, numa semana em que a peneira de fato troca o template.

**`isEligible` NÃO cobre as missões de `organization`** — é uma lacuna
consciente, não um esquecimento. As três corporativas de organização
(conciliar extrato, triar lançamentos automáticos, pagar a fatura no prazo) são
**prospectivas**: elas pedem algo que o usuário ainda vai fazer durante a
semana. Uma peneira pelo que já aconteceu NAQUELA JANELA as tornaria
permanentemente inelegíveis, porque no instante da geração a semana está vazia
por definição — seria trocar "missão difícil de medir" por "missão que nunca é
sorteada".

A peneira correta para elas é de **capacidade**, não de janela: só ofereça
"pagar a fatura" a quem tem cartão, "conciliar extrato" a quem tem conta, e
"triar lançamentos automáticos" a quem usa a captura por notificação. São fatos
ESTÁVEIS do workspace, e por isso convergem entre gerador e retag. O que
impediu de implementar agora foi o critério de custo: são três leituras que o
gerador **ainda não faz** (contagem de contas, contas de cartão, e um
`limit(1)` em `automatic_transactions`), enquanto a peneira de receita/margem
reaproveita o sumário que ele já lê. Fica como pacote próprio, com o efeito
conhecido: hoje uma empresa sem cartão de crédito recebe "fechar a fatura
corporativa no prazo" a cada três semanas, e não tem como cumpri-la.

> **Uma empresa pode não fechar a semana perfeita numa semana sem receita
> prevista.** A missão de receita some do sorteio (bom), mas a de margem
> também, e sobra o par "centros de custo + maior centro de custo", que exige
> plano. Um workspace de empresa que não planeja nada continua sem streak — e
> isso é o produto funcionando, não um defeito: o jogo premia planejar.

**A escolha da semana é um hash**, não um sorteio nem uma chamada de rede:
`hashString(weekId|audience|type) % candidatos`. A variação entre semanas era o
argumento para usar IA na geração, e ela sai daqui de graça e igual em qualquer
processo — o gatilho, o cron e o script de retag chegam ao mesmo template
**desde que recebam o mesmo contexto** (ver acima), sem precisar reler o que já
foi gravado. Para o avaliador de progresso a questão nem se coloca: ele usa o
`templateKey` GRAVADO no documento, nunca um sorteio novo. Um teste percorre as 53 semanas
do ano e exige que o hash alcance TODOS os candidatos de cada par; um hash que
agrupasse tudo numa posição tornaria o catálogo inútil sem quebrar nada.

**Sem categoria planejada, o `{category}` cai num fallback do próprio
template** ("a categoria **de maior gasto**", "o centro de custo **de maior
peso**"). O código antigo defaultava a categoria para `"Alimentação"` mesmo num
workspace sem plano nenhum — que é, literalmente, metade do defeito relatado.

### O que a IA ainda faz

Ela **tempera o texto**. Nada mais.

O prompt recebe o tipo do workspace, os templates JÁ escolhidos (chave, texto
base, alvo e os radicais obrigatórios) e a lista explícita do que **não cabe**
naquela audiência. A resposta precisa ecoar o `templateKey`, e é aceita só se
passar nas quatro condições de `validateWeeklyMissionNames`:

1. **ecoa o `templateKey`** que o prompt mandou — sem isso não há como saber a
   qual objetivo aquele texto se refere;
2. **mantém o `target`** exatamente — o alvo é o que o avaliador de progresso
   mede, e deixar a IA mexer nele é deixá-la mudar a regra;
3. **contém todos os `aiRequiredTerms`** do template (comparação por
   substring, sem acento e sem caixa) — é o que amarra o texto ao objetivo.
   Os termos são **radicais**, não palavras inteiras: `centro` (e não "centro
   de custo") para casar com "centros de custo", `concilia` para casar com
   "conciliar" e "conciliação". Exigir a flexão exata reprovaria o texto certo
   só por estar no plural;
4. **não usa o vocabulário da outra audiência** (`AUDIENCE_FORBIDDEN_TERMS`):
   empresa não fala de alimentação, lazer, família, delivery, mercado, férias,
   mesada nem reserva de emergência; pessoa não fala de margem, centro de
   custo, fechamento contábil, DRE, CNPJ, folha de pagamento nem capital de
   giro.

Mais duas recusas, que não são sobre audiência:

5. **nome acima de 180 caracteres é REJEITADO, não truncado.** O texto cabe num
   card e o prompt pede uma frase. Truncar no limite de texto livre (500)
   entregava ao usuário uma missão cortada no meio — "Manter o centro de custo
   Marketing dentro do pla" — como se fosse o objetivo dele;
6. **texto com cara de injeção de prompt é rejeitado** ("ignore"/"ignorar"
   junto de "instru…"). O prompt carrega dados que o usuário controla (nomes de
   categoria e de meta), e o nome da missão vai para o Firestore e de lá para a
   tela. Uma missão não tem motivo nenhum para falar em ignorar instruções: ou
   o modelo repetiu o que leu num nome de categoria, ou repetiu o que alguém
   plantou nele.

Falhou qualquer uma: aquela missão volta `null` e vale o texto do catálogo.
**O pior caso da IA passou a ser "o texto não ficou mais bonito", em vez de "a
missão virou outra coisa".** A semana nunca fica sem missão, e uma falha de
rede no Gemini não muda nada além disso.

> **O termo proibido que veio do DADO não reprova o texto.** Uma empresa pode
> ter um centro de custo chamado "Alimentação" (vale-refeição). Os valores
> injetados no nome (`dataValues`) são removidos do texto antes da varredura de
> vocabulário: a palavra estar ali é o Firestore falando, não o modelo
> inventando.
>
> A licença é **por missão**, não por workspace: só a missão cujo template
> declara `{category}` recebe o nome da categoria em `dataValues`. Passá-lo às
> três daria à missão de conciliação permissão para dizer "alimentação" apenas
> porque existe um centro de custo com esse nome — que é exatamente o texto que
> o pacote existe para barrar.

> **Os termos obrigatórios são em português, e o campo se chama
> `aiRequiredTermsPt` para não mentir sobre isso.** O prompt pede o nome em
> português e o documento grava `name` em português para a build instalada; o
> inglês do catálogo é resolvido no app a partir de `nameKey` + `params`, sem
> passar pela IA. No dia em que o prompt pedir outro idioma, o campo vira um
> mapa por locale.

### As regras de progresso

Quem decide o que medir é o `progressRule` do template. O evento virou apenas o
gatilho que AUTORIZA a leitura (`RULE_EVENT_SOURCES`) — antes, o avanço era um
`if/else` escrito em cima do evento (planejamento mexia em consistência,
transação em disciplina, conciliação em organização), e isso deixa de funcionar
quando a missão de organização de uma empresa pode chegar como evento de
TRANSAÇÃO (a fatura paga).

| Regra | O que conta | Fonte | Eventos que a movem |
|---|---|---|---|
| `planned_categories` | categorias com limite > 0 vigente no mês | `category_planning` | transação, planejamento, fechamento |
| `days_within_category_limit` | dias JÁ decorridos em que a maior categoria ficou no limite diário | parcelas pagas na semana | transação, fechamento |
| `reconciled_statement_items` | itens do extrato recém-conciliado | **o evento** | conciliação |
| `reconciled_statements` | extratos concluídos na semana | `reconciliations` (`status` + `createdAt`) | conciliação, fechamento |
| `categorized_auto_transactions` | lançamentos automáticos da semana já RESOLVIDOS | `automatic_transactions` (faixa de `date`) | transação, **triagem**, fechamento |
| `invoice_paid_on_time` | faturas pagas até o DIA do vencimento | parcelas pagas com `isInvoice` | transação, fechamento |
| `weekly_margin_above_plan` | margem realizada ≥ margem planejada | `period_summaries/{YYYY-Www}` | transação, fechamento |
| `income_received_vs_planned` | % da receita **prevista** que entrou | `period_summaries/{YYYY-Www}` (`specificPlannedAmount`) | transação, fechamento |

#### Os dois "planejados" do sumário não são a mesma coisa

Esta foi a correção mais cara do pacote, e vale escrita por extenso.

| Campo | O que é | Onde aparece |
|---|---|---|
| `generalPlannedAmount` | o LIMITE de `category_planning` rateado no período (F1.5) | teto de DESPESA; numa categoria de receita costuma ser **zero** |
| `specificPlannedAmount` | a soma das PARCELAS PROJETADAS que caem no período | é aqui que mora a **receita prevista** (a nota a receber agendada por `dueDate`) e a despesa já agendada |

A primeira versão das missões corporativas leu o `general` para saber a receita
prevista da semana. Em produção (workspace a70134c1, 2026-W37) a categoria
"Serviços" tinha `generalPlanned = 0`, `specificPlanned = 15.850` e
`actual = 3.850`. Duas consequências, as duas silenciosas:

- **a missão de receita nunca avaliava.** `plannedIncome` dava zero, a regra
  devolvia `null` e a barra ficava em 0% a semana inteira — em metade das
  semanas do ano, que é a fatia em que o hash escolhe essa missão;
- **a missão de margem concluía de graça.** Com receita planejada zero, a
  "margem planejada" virava `−despesa` (um número NEGATIVO) e qualquer margem
  realizada passava. A guarda que deveria pegar isso era
  `receita + despesa <= 0`, e ela nunca disparava, porque bastava haver
  despesa planejada. Resultado real: 250 XP numa semana em que a empresa
  recebeu 24% do que previa.

Hoje `sumWeeklyTotals` usa o **`specific` para a receita** e a **soma dos dois
para a despesa** (a empresa pode ter teto de categoria E compromissos já
agendados, e os dois são dinheiro que ela planejou gastar). A conta é feita em
**centavos inteiros**, como manda [F1.10](#dinheiro-em-centavos-f110). E a
margem só é avaliada com os DOIS lados do plano presentes — "margem acima da
planejada" pressupõe uma margem planejada.

#### `automatic_transactions.date` é relógio local, sem fuso

O app serializa `AutomaticTransactionModel.date` com o `toJson` do freezed, sem
conversor: o campo chega como `"2026-09-04T10:50:47.466"` — horário local do
aparelho, **sem sufixo**. Isso quebra de duas formas, e as duas apareceram:

1. **`new Date(...)` no runtime das functions (UTC) desloca três horas.** Um
   lançamento de domingo 01:00 em São Paulo virava sábado 22:00 e caía na
   semana anterior; um de sábado 23:00 pulava para a semana seguinte.
   `automaticTransactionInstant` interpreta o texto no fuso do produto, e trata
   também as outras duas formas possíveis (string com `Z`/offset, e `Timestamp`,
   que as rules aceitam).
2. **`where("date", ">=", <Timestamp>)` devolveria ZERO documentos, calado** —
   o Firestore ordena por TIPO antes de ordenar por valor. Por isso a consulta
   compara **strings de relógio local**: num formato de largura fixa a ordem
   lexicográfica é a ordem cronológica.

   E é por isso que as **rules passaram a aceitar `date` SÓ como string**
   (antes: `data.date is timestamp || isStr(...)`). O tipo errado não daria
   erro em lugar nenhum — o documento simplesmente ficaria invisível para a
   consulta, e a missão contaria menos do que o usuário fez. Recusar na porta o
   que a consulta não enxerga é a única forma de isso não virar outro defeito
   silencioso. O app já grava string; a mudança não fecha nenhum caminho que
   ele use.

A primeira versão desistiu da consulta e leu a coleção inteira com `limit(500)`
e nenhum `orderBy`. Numa caixa de entrada com **532 documentos**, o Firestore
devolvia 500 ordenados por id (UUID), os 12 da semana não entravam na página, a
missão marcava zero para sempre — e cada evento de transação custava **500
leituras**. Hoje a consulta é `where(date >= início) + where(date < fim) +
orderBy(date) + limit(200)`, resolvida pelo índice de campo único que já existe
(faixa e ordenação no mesmo campo não pedem índice composto). Os limites levam
**um dia de folga em cada borda** para o documento legado gravado em UTC vir na
página; a janela exata é conferida em memória.

Cinco decisões que valem explicar:

- **"Resolvido" é `isConsolidated` ou `isIgnored`, nunca `categoryId`.** O
  `categoryId` de um lançamento automático é preenchido **pela própria IA** no
  gatilho de enriquecimento. Contá-lo faria a missão fechar sozinha, sem
  ninguém ter feito nada — XP por o servidor ter trabalhado.
- **Descartar conta, e precisa de gatilho próprio.** Consolidar um lançamento
  automático cria uma transação, e é essa escrita que move a barra. Descartar
  não cria nada — vira `isIgnored: true` no próprio documento. Por isso existe
  `onAutomaticTransactionTriaged` (`onDocumentUpdated` em
  `automatic_transactions`), com guarda por CONTEÚDO: só a **transição para
  triado** dispara. O app reescreve o documento inteiro a cada edição
  (`update(toJson())`), então sem a guarda uma troca de categoria — ou a
  sugestão que o próprio servidor grava — pagaria uma avaliação. Destriar não
  desconta: missão semanal não anda para trás, pela mesma razão que a missão
  concluída nunca é estornada.
- **A fatura é comparada por DIA de calendário**, não por instante. O
  vencimento é gravado ao meio-dia no fuso do produto (ver
  [`nextInvoice`](#accountsaccountidnextinvoice)); comparar instantes
  reprovaria quem pagou às 18h do próprio dia.
- **A margem não premia a AUSÊNCIA de plano.** Sem nenhum valor planejado na
  semana, a regra não avalia: "acima do planejado" pressupõe um planejado, e
  premiar o vazio seria premiar não planejar — o oposto do que o jogo ensina
  (ver [XP que premia planejar](#xp-que-premia-planejar-f23)).
- **Regra que não sabe medir devolve `null`, e o progresso fica como está.**
  Zerar seria pior que não escrever: a barra andaria para trás na tela sem que
  nada tivesse acontecido.

**O cron semanal ganhou uma última passada** (`eventType: "weekly_close"`)
antes de decidir a streak. As duas regras que leem o `period_summaries` semanal
dependeriam, sem ela, de o último evento da semana ter chegado DEPOIS da
escrita do sumário — uma corrida que a plataforma não promete ganhar. No
fechamento a semana está completa e o sumário, parado: é o único momento em que
o número é definitivo. Uma falha ali é registrada e engolida — ela não pode
derrubar a streak nem os badges, que são o trabalho principal do cron.

#### Mudança de comportamento: sem limite, a disciplina não anda

`days_within_category_limit` deixou de inventar um teto. O código antigo, num
workspace **sem nenhum planejamento**, assumia `R$ 250/semana` sobre uma
categoria chamada "Alimentação" — que podia não existir — e a missão avançava
sozinha. Hoje, sem categoria com limite, a regra não mede nada e o progresso
não anda. É deliberado: o jogo premia planejar, e não havia plano.

#### Custo de leitura por evento

O avanço por regra lê mais que o `if/else` que ele substituiu, e a primeira
versão exagerou: um evento de transação num workspace de empresa chegou a
**~87 leituras** (500 delas só na varredura dos lançamentos automáticos, no
pior caso). Três cortes trouxeram isso para dentro do aceitável:

1. **Gate por tipo de missão ANTES de ler o documento.** `RULE_EVENT_SOURCES`
   precisa do template, e o template vem do documento — então um evento de
   conciliação lia as três missões da semana para descartar duas.
   `TYPES_MOVABLE_BY_EVENT`, derivado do catálogo, responde "vale a pena ler?"
   sem ler: a regra de um tipo de missão só pode sair dos templates daquele
   tipo.
2. **A consulta dos lançamentos automáticos virou faixa** (acima): de 500 para
   os documentos da semana.
3. **O join do sumário semanal só toca nas categorias do sumário.**
   `getWeeklySummaryRows` varria a coleção INTEIRA de categorias para
   classificar as poucas que se moveram na semana — barato no cron (uma vez por
   workspace), caro quando margem e receita passaram a ser avaliadas a cada
   transação. Hoje é um `getAll` nos ids presentes no sumário.

Leituras por evento, num workspace de empresa (ordem de grandeza; `C` =
planejamentos, `P` = parcelas pagas na semana, `k` = categorias com movimento
na semana, `A` = lançamentos automáticos da semana):

| Evento | Missões lidas | Dados | Total típico |
|---|---|---|---|
| planejamento | 1 (consistência) | `C` ≈ 10 | **~11** |
| conciliação | 2 (existência + organização) | 1 (`count()`) | **~3** |
| triagem (`auto_transaction`) | 2 (existência + organização) | `A` ≈ 12 | **~14** |
| transação, semana "plano" | 3 | `C` + `P` + `A` ≈ 10+5+12 | **~30** |
| transação, semana "sumário" | 3 | (1 + `k`) + `P` ≈ 7+5 | **~15** |

As leituras são memoizadas por avaliação: as duas missões de empresa que leem o
sumário semanal na mesma semana pagam **uma** leitura, não duas.

#### O que ficou de fora, e o dado que falta

- **"Conciliar 100% dos extratos DAS CONTAS".** O documento de
  `reconciliations` **não carrega `accountId`** (o app grava apenas `id`,
  `status`, as três contagens e `createdAt` — ver
  `reconciliation_repository_impl.dart`). Sem ele não há como saber quais
  contas foram conciliadas, e "100%" não tem denominador. Implementado no
  lugar: **contar extratos concluídos na semana**, que é mensurável hoje. Para
  o 100%, o app precisa passar a gravar `accountId` no resumo da conciliação.
- **"Categorizar 100% dos lançamentos automáticos".** O gatilho de update já
  existe (`onAutomaticTransactionTriaged`), mas o denominador continua móvel: a
  caixa de entrada cresce durante a semana, e "100% do que chegou até agora" é
  um alvo que anda para trás toda vez que chega uma notificação nova.
  Implementado no lugar: **contar N resolvidos na semana** (N = 3). Para o
  100%, falta congelar o denominador — um contador no documento da missão,
  incrementado pelo gatilho de criação.
- **`reconciled_statements` exige índice composto** em `reconciliations`
  (`status` ASC, `createdAt` ASC), acrescentado a `firestore.indexes.json`.
  Ele precisa estar READY **antes** do deploy das functions — ver a ordem de
  rollout. A consulta dos lançamentos automáticos, ao contrário, **não** pede
  índice novo: faixa e ordenação caem no mesmo campo, que o índice de campo
  único já cobre.

### Coaching: tom por tipo

O prompt passou a definir um PAPEL, não só um contexto: **mentor** em
`personal` (fala com a pessoa, economia doméstica, hábitos, reserva de
emergência; sem jargão contábil) e **controller** em `business` (fala com a
área financeira, centros de custo, margem, fluxo de caixa, OpEx; **proibido**
conselho de vida pessoal). O schema não mudou.

A validação **audita** o vocabulário e apenas REGISTRA
(`[coaching:audience] …`). Descartar o slide seria errado aqui, e a diferença
em relação à missão é o ponto: o texto da missão é inventado pela IA sobre um
objetivo fixo, então jogá-lo fora não custa nada; um slide de coaching fala das
categorias **reais** do workspace, e uma empresa pode legitimamente ter
"Alimentação" (vale-refeição) ou "Lazer" (confraternização) no plano de contas.
Apagar o slide pela palavra jogaria fora a análise certa junto com a errada — e
um slide a menos é uma tela vazia. O log é como se descobre que o prompt parou
de ser obedecido, sem depender de outro print do dono.

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
ordem abaixo é a que evita janela quebrada. Executada contra o projeto real em
2026-09-17 (passos 0 a 10 e 12/13; o passo 11 ficou pendente de decisão sobre
planejamentos duplicados no workspace a532d837).

```
0. APP              publicar web + macOS SEM `currentAmount` no updateGoal
                    ⏳ BLOQUEIA o passo 1 — ver o aviso abaixo
1. rules + índices   firebase deploy --only firestore:rules,firestore:indexes
                     ⏳ ESPERAR os índices ficarem READY antes de seguir
2. migração          node lib/scripts/migrate_balance_date_key.js      (dry-run → --apply)
3. migração          node lib/scripts/migrate_planning_summaries.js    (dry-run → --apply)

4. functions         firebase deploy --only functions
                     ⏳ OBRIGATÓRIO antes da migração de centavos — ver "Lição de 2026-09-17"

   ── F1.10, dinheiro em centavos: DEPOIS do deploy das functions ───────────
5. verificação       node lib/scripts/migrate_money_cents.js --all-workspaces --verify   (RETRATO ANTES)
6. centavos          node lib/scripts/migrate_money_cents.js --all-workspaces            (dry-run)
                     node lib/scripts/migrate_money_cents.js --all-workspaces --apply
7. verificação       node lib/scripts/migrate_money_cents.js --all-workspaces --verify   (RETRATO DEPOIS)
   ──────────────────────────────────────────────────────────────────────────

8. correção          node lib/scripts/fix_empty_category.js            (levantamento → --apply, uma categoria por vez)
9. backfill          node lib/scripts/backfill_next_invoice.js         (dry-run → --apply)
10. rebuild           node lib/scripts/rebuild_workspace.js --all-workspaces                     (dry-run → --apply)
11. rebuild planejado node lib/scripts/rebuild_workspace.js --all-workspaces --rebuild-planning  (dry-run → --apply)
12. metas             node lib/scripts/recompute_goals.js                                        (dry-run → --apply)
13. bússola           node lib/scripts/recompute_health.js                                       (dry-run → --apply)
```

### Rollout de wp/missions-by-type (missões por tipo de workspace)

Independente do bloco acima, e muito menor. Três passos, nesta ordem:

```
1. índices     firebase deploy --only firestore:indexes
               ⏳ ESPERAR o índice de `reconciliations` (status, createdAt) ficar READY
2. functions   firebase deploy --only functions
3. retag       node lib/scripts/retag_weekly_missions.js   (dry-run → --apply)
               ⏳ na MESMA semana do deploy — ver o script
```

**1. O índice primeiro.** A regra `reconciled_statements` consulta
`reconciliations` por `status` + faixa de `createdAt`. Sem o índice pronto, a
consulta falha e a missão corporativa de conciliação não avança — calada, do
ponto de vista do usuário, porque a falha vira log e a barra simplesmente não
anda. O índice é aditivo: subi-lo antes não afeta o servidor antigo.

**2. As functions.** Elas convivem com missões no formato antigo — uma missão
sem `templateKey` cai na seleção determinística da audiência `personal`, que é
o comportamento que ela sempre teve. Não há janela quebrada.

**3. O retag, na mesma semana.** É o passo que corrige o que o usuário está
vendo AGORA. Rodá-lo antes do passo 2 não adianta (o gatilho antigo
sobrescreveria), e rodá-lo na semana seguinte não tem efeito (as missões novas
já nascem do catálogo). Depois dele, `config/badges` é republicado sozinho pelo
cron diário com o campo `audience` — ou na hora, com
`node lib/scripts/publish_badge_catalog.js`, se o app já estiver lendo o campo.

> **O app não bloqueia nenhum destes passos.** Os cinco campos novos de
> `weekly_missions` são aditivos e a build instalada os ignora; o `name` em
> português continua sendo gravado exatamente como antes. O que o app ganha
> quando acompanhar está em
> [O que o app precisa acompanhar](#o-que-o-app-precisa-acompanhar).

**0. O app primeiro — e este passo BLOQUEIA o resto.**

As rules de F1.10 negam `goals.currentAmount` no **update**. O app publicado
hoje (`fix/fase-0`) lê o `currentAmount` ao abrir o formulário da meta e o
**reenvia** ao salvar. Isso passa enquanto o valor não muda — a negação é por
diferença —, mas se um pagamento cair entre abrir e salvar, o servidor grava o
progresso novo e o formulário manda o valor velho: **a edição inteira é
rejeitada**, e o usuário perde a alteração de nome, de prazo ou de alvo que
estava fazendo.

O app do pacote `wp/flutter-polish` já parou de enviar o campo. Publique-o
(web + macOS) e só então suba as rules. Não há versão tolerante da regra: o
formulário não edita esse valor, e aceitar o número defasado desfaria um
progresso que o servidor acabou de calcular — que é exatamente o que a regra
existe para impedir.

O cenário está coberto em `src/test/rules/firestore_rules.test.ts` ("NEGA o
reenvio de um `currentAmount` DEFASADO — e isso é o esperado"), junto do update
sem o campo, que é o que o app publicado faz.

**1. Rules e índices, depois do app.** O código novo consulta
`balance.dateKey` (descendente) e `category_planning.summarizedUntil` (no grupo
de coleções). Enquanto o índice estiver `CREATING`, essas consultas respondem
`FAILED_PRECONDITION` e o gatilho de saldo/cron de planejamento falha. Confira
com:

```bash
gcloud firestore indexes fields list --project=funance-cef1b
```

As rules podem ir junto: elas só **negam** campos novos ao cliente
(`currentWeekId`, `currentWeekStart`, os quatro marcadores do planejamento, o
`nextInvoice` da conta e — desde F1.10 — todos os `*Cents`), e o app ainda não
os envia. F1.8 **não acrescenta índice**: a consulta da próxima fatura já
existia, porque era a que o app fazia. **F1.10 também não acrescenta índice**:
os campos `*Cents` não são consultados, só lidos e somados.

> ⚠️ **As rules dos `*Cents` precisam ir ANTES das functions.** É o servidor que
> passa a gravá-los; se o cliente puder escrevê-los primeiro, um documento pode
> nascer com um inteiro forjado que o saldo, o sumário e o XP vão acreditar. A
> negação é por DIFERENÇA de valor, então nenhuma build atual do app é
> rejeitada — ela não envia esses campos.

> ⚠️ **As rules de conta e o app andam juntos.** A partir deste deploy, um
> `setDoc` que serialize a conta inteira sem `nextInvoice` é rejeitado (apagar o
> campo conta como alteração). O app atual usa `update` com `toJson()`, e
> `nextInvoice` não é serializado — mas uma build antiga que reescreva o
> documento inteiro quebraria. Se houver clientes antigos em campo, suba as
> rules junto com a versão nova do app.

**2 e 3. Migrações de F1.4/F1.5, na ordem.** `migrate_balance_date_key` preenche
`dateKey`/`delta` nos saldos (e, desde F1.10, os espelhos inteiros na mesma
escrita); `migrate_planning_summaries` grava os marcadores dos planejamentos.
Ambas são idempotentes, dry-run por padrão e não mexem em `period_summaries`.
Rodar a segunda também encerra a varredura de legados do cron mensal.

Elas rodam ANTES do deploy das functions porque as functions atuais já
convivem com o formato antigo (ver "Compatibilidade com o formato antigo") e
porque os scripts rodam do **build local**, com ADC — não dependem de deploy
nenhum.

**8. Correção de categoria sem id.** `fix_empty_category` é um levantamento por
padrão: rode-o sem `--category-id` para ver quantas parcelas/orders estão com
`category.id` vazio e com que nomes. A correção é feita uma categoria de cada
vez, e só onde o nome bate — ver
[Categoria sem id](#categoria-sem-id-fora-dos-sumários). Ela vem ANTES do
rebuild porque é o rebuild que recoloca essas parcelas nos `period_summaries`.

**9. Backfill da fatura — rode LOGO depois do deploy.** `backfill_next_invoice`
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

**5, 6 e 7. Dinheiro em centavos, DEPOIS do deploy das functions.** O
`--verify` é leitura pura: rode-o **antes** para ter o retrato de partida (e
descobrir se já existe alguma divergência plantada) e **depois** para provar que
o backfill fechou. O que se compara é a linha por coleção: `soma_double` e
`soma_cents` têm de ser **idênticas** nos dois retratos, e `a_migrar` tem de cair
a zero no segundo. As duas somas DIFERINDO é o único sinal que pede parada — ver
[`migrate_money_cents.ts`](#migrate_money_centsts).

> ⚠️ **Lição de 2026-09-17: a migração vem DEPOIS do deploy das functions.**
> A primeira versão deste runbook mandava migrar antes, raciocinando com as
> guardas novas (`ORDER_DERIVED_FIELDS`, `GOAL_DERIVED_FIELDS`, `*Cents` em
> `INSTALLMENT_DERIVED_FIELDS`), que ignoram escritas só de `*Cents`. Só que
> quem reage às 4.540 escritas da migração são as functions **que estão no ar
> naquele momento** — e as antigas não conhecem os campos novos. Na execução
> real, com a ordem invertida: `onInstallmentWritten` antigo rodou 2.378 vezes e
> reprocessou `period_summaries` (a soma caiu de 27.106.686,75 para
> 25.820.776,65), `onOrderWritten` antigo criou 1.074 entradas espúrias em
> `orders/{id}/history`, e a gamificação antiga reavaliou badges/XP (sem dano:
> são idempotentes por id). As fontes de verdade (orders, installments,
> balance, accounts, goals, category_planning) não mudaram. Reparo aplicado:
> deploy das functions novas → `rebuild_workspace --all-workspaces --apply`
> (sumários de volta ao valor exato do retrato ANTES; segunda passada com zero
> mudanças) → exclusão do history espúrio (com backup).
>
> Regra geral para QUALQUER migração que escreva em coleção com gatilho:
> primeiro sobem as functions cujas guardas reconhecem a escrita da migração
> como derivada; só depois a migração; e um `rebuild_workspace` dry-run no fim
> como prova. As functions novas sabem lidar com documentos ainda sem `*Cents`
> (a escrita de sumário é transacional e semeia o inteiro a partir do `double`).
>
> A ordem entre a migração e os passos 8/9 é indiferente — eles não tocam em
> dinheiro. O que **não** pode inverter é migração antes do rebuild: é o rebuild
> que usa o inteiro como fonte da verdade.

> **Depois do deploy o gatilho preenche sozinho.** Toda escrita do app num
> documento monetário completa os `*Cents` dele. Isso não substitui a migração
> (que cobre o acervo que ninguém toca), mas significa que um `--verify` rodado
> semanas depois mostra `a_migrar` menor do que a tabela de volume.

**7. As functions.** Elas convivem com os documentos no formato antigo, então
não há janela de indisponibilidade — só um custo de leitura maior por pagamento,
em contas com histórico longo, até a migração de `dateKey` ter rodado.

**10. Rebuild.** Corrige o que as migrações não corrigem: dias e meses gravados
em UTC (pagamento perto da meia-noite de Brasília), ids de semana antigos e
saldos acumulados divergentes. `--all-workspaces` percorre a base um workspace
de cada vez, com um relatório por workspace e um resumo final; um workspace que
falha não interrompe os demais.

**11. Rebuild com `--rebuild-planning`, ANTES do segundo cron mensal.** Este é o
único passo que reescreve o `generalPlannedAmount`. O motivo do prazo: o valor
gravado hoje carrega a acumulação do regime antigo (aplicação repetida sem
estorno), e **cada execução do cron mensal soma mais um mês por cima desse
valor errado**. A primeira execução depois do deploy é inevitável; rodar o
`--rebuild-planning` antes da segunda impede que o erro continue crescendo.

> ⚠️ **O rebuild não é transacional.** Escolha uma janela sem uso e refaça o
> dry-run imediatamente antes de cada `--apply`.

> **Espere ver documentos semanais de `period_summaries` marcados como
> `alterar` com `generalPlannedChanges = 0`.** Não é o planejado mudando: é o
> ESPELHO `double` sendo reescrito a partir do inteiro, onde anos de
> `FieldValue.increment` deixaram uma dízima (`677.4300000000001` para
> `67743` centavos). A quantia é a mesma; o campo que o app lê é que deixa de
> ser uma dízima. Ver
> [Dinheiro em centavos](#dinheiro-em-centavos-f110).

**12. Metas, depois do rebuild.** `recompute_goals` recalcula o `currentAmount`
de toda meta a partir da fonte de verdade de cada tipo — saldos diários,
`period_summaries` mensais, parcelas pagas. As três fontes acabaram de ser
reconstruídas pelos passos 10 e 11, e desde F1.10 o "mudou?" do script é uma
comparação de centavos inteiros: rodá-lo antes gravaria progresso calculado
sobre números que o rebuild ainda vai corrigir. Ele também é o que dá aos
`*Cents` das metas o valor RECALCULADO, em vez do espelho do que estava lá.

**13. Bússola da Liberdade, por ÚLTIMO.** `recompute_health` lê saldos e
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
| `migrate_money_cents.ts` | espelhos inteiros `*Cents` em todo documento monetário | [Dinheiro em centavos](#dinheiro-em-centavos-f110) |

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

### `retag_weekly_missions.ts`

Migração leve de wp/missions-by-type: carimba `workspaceType`/`templateKey` nas
missões da **semana corrente** e troca as missões ABERTAS de workspaces
`business` pelas do catálogo corporativo.

O servidor novo já gera pelo catálogo, mas as missões da semana em curso foram
criadas pelo servidor antigo: sem este script, um workspace de empresa continua
vendo "Reduzir gastos com alimentação" até o domingo seguinte ao deploy.

| Situação da missão | O que o script faz |
|---|---|
| **concluída** (qualquer tipo de workspace) | só CARIMBA: `templateKey`, `workspaceType`, `actionPath`, `nameKey`, `params`. `name`, `target`, `progress`, `status`, `rewardXp` e `completedAt` ficam intocados |
| **aberta**, workspace `business` | SUBSTITUÍDA pelo template corporativo da semana: nome, alvo, XP, rota e chaves do catálogo, `progress` de volta a 0 |
| **aberta**, workspace `personal` | só CARIMBA. O objetivo já era o certo |

**A missão concluída NÃO é estornada.** O XP dela já entrou no workspace, já
subiu nível e já pode ter desbloqueado badge; desfazer isso exigiria reverter
uma cadeia inteira de efeitos por causa de um texto — e puniria o usuário por
um defeito do servidor. A missão concluída fica como troféu; o que muda daqui
para a frente é o que se gera.

**A missão concluída é carimbada como `personal` mesmo numa empresa.** O
carimbo descreve o que aquela missão FOI, e os fallbacks e o prompt antigos
eram todos de linguagem pessoal, qualquer que fosse o tipo do workspace.
Marcar `workspaceType: business` num texto pessoal seria gravar uma mentira no
documento.

**A missão aberta de workspace pessoal não tem o texto reescrito.** Ela já mede
o que deve medir; trocar a frase só produziria churn na tela de quem não tem
problema nenhum.

É IDEMPOTENTE (pula quem já tem `templateKey`, a não ser com `--force`),
DRY-RUN por padrão e paginado por cursor.

```bash
cd functions
npm run build

# 1) Simulação (padrão — não escreve nada)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/retag_weekly_missions.js --project=funance-cef1b

# 2) Um workspace só, para conferir o efeito
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/retag_weekly_missions.js --project=funance-cef1b --workspace=<wid> --apply

# 3) Base inteira (somente após revisar o dry-run)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/retag_weekly_missions.js --project=funance-cef1b --apply
```

Flags: `--apply`, `--project=<id>`, `--workspace=<id>`, `--week=<YYYY-Www>`,
`--page-size=<n>`, `--force`.

> ⚠️ **NÃO EXECUTADO** contra o projeto real (`funance-cef1b`).
>
> ⚠️ **Rode DEPOIS do deploy das functions**, na mesma semana. Antes do deploy,
> o gatilho antigo não conhece `templateKey` e a próxima escrita de missão
> ignoraria o carimbo; e numa semana diferente da corrente o script não tem o
> que corrigir (as missões da semana nova já nascem do catálogo). É a mesma
> lição de 2026-09-17, aplicada a uma migração muito menor.

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

### `migrate_money_cents.ts`

Preenche os espelhos INTEIROS `*Cents` em todos os documentos monetários da
base — ver [Dinheiro em centavos](#dinheiro-em-centavos-f110) para a lista de
campos por coleção.

- **Dry-run por padrão**: só escreve com `--apply`.
- **Idempotente**: um documento já correto não gera escrita nenhuma. Rodar duas
  vezes seguidas faz a segunda reportar zero.
- **NÃO toca no `double`**: o inteiro é derivado dele, nunca o contrário. Nesta
  etapa o app ainda escreve o `double`, e sobrescrevê-lo seria o servidor
  discordando do usuário. Quem reconcilia os dois é o `rebuild_workspace`.
- **Ausente continua ausente**: um `paidAmount` inexistente não vira
  `paidAmountCents: 0`. Um inteiro pendurado sem o `double` correspondente é
  resíduo e é apagado.
- **Patch ANINHADO nos mapas**: em `period_summaries` e em `nextInvoice` o
  patch é `{categories: {id: {...}}}` gravado com `set(..., {merge: true})`, e
  não um caminho pontilhado `"categories.mercado.actualAmountCents"`. É a mesma
  razão que levou o repositório a usar `FieldPath` em chave de mapa: um id de
  categoria com ponto seria interpretado como caminho aninhado e gravaria no
  lugar errado.
- **Ausente continua ausente, e sujo NÃO vira zero**: um campo monetário
  presente que não é número finito (a string `"1000"`, um booleano, `NaN`) é
  contado em `inválidos`, listado por caminho e faz o `--verify` FALHAR. Gravar
  `amountCents: 0` porque o `double` era a string `"1000"` apagaria mil reais
  com um número de cara legítima. Um valor **acima do intervalo exato** de
  centavos (`MoneyRangeError`) cai na mesma contagem, com o caminho do
  documento: ele é um documento sujo, não um defeito do workspace, e derrubar a
  varredura inteira por causa dele esconderia os outros 4.539.
- **Checkpoint reiniciável, pela LISTA DE PENDENTES**:
  `config/cron_checkpoints.moneyCentsPendingWorkspaces` guarda os workspaces que
  ainda faltam — inclusive os que **falharam**. Um marcador de avanço ("o último
  concluído") faria o workspace que falha ficar atrás do marcador e nunca mais
  ser visitado: a execução seguinte varreria zero, zeraria o checkpoint e sairia
  com código 0, escondendo o defeito exatamente onde ele importa. Ao terminar
  sem pendência o campo é zerado. Use `--restart` para ignorá-lo.
- **Um lote não é perdido por um documento apagado.** `batch.update` é atômico:
  se um documento sumiu entre a leitura e o commit, o lote inteiro é rejeitado
  com `NOT_FOUND`. O script degrada para escrita por documento, descarta os que
  sumiram e propaga qualquer outro erro. (Trocar por `set(..., {merge: true})`
  não falharia, mas CRIARIA o documento apagado — uma order fantasma com um
  único campo. Um patch de espelho não ressuscita nada.)
- Escreve em lotes de no máximo 400 operações (`commitInChunks`).

```bash
cd functions
npm run build

# 1) Simulação (padrão — não escreve nada)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/migrate_money_cents.js --project=<projectId> --all-workspaces

# 2) Um workspace só, para conferir o efeito
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/migrate_money_cents.js --project=<projectId> --workspace=<wid> --apply

# 3) Base inteira (somente após revisar o dry-run)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/migrate_money_cents.js --project=<projectId> --all-workspaces --apply

# 4) Verificação (leitura pura — rode ANTES e DEPOIS do passo 3)
GOOGLE_APPLICATION_CREDENTIALS=/caminho/service-account.json \
  node lib/scripts/migrate_money_cents.js --project=<projectId> --all-workspaces --verify
```

| Flag                | Efeito                                                        |
|---------------------|---------------------------------------------------------------|
| _(nenhuma)_         | dry-run: apenas relata o que seria gravado                     |
| `--apply`           | executa as escritas                                            |
| `--verify`          | não escreve nada; reporta divergências e as somas por coleção   |
| `--project=<id>`    | projectId do Firebase (default: `GOOGLE_CLOUD_PROJECT`)         |
| `--workspace=<id>`  | limita a execução a um único workspace                          |
| `--all-workspaces`  | percorre TODOS os workspaces (é o padrão sem `--workspace`)     |
| `--page-size=<n>`   | documentos lidos por página (default 500)                       |
| `--restart`         | ignora o checkpoint e recomeça do início                        |

**Reparo dirigido.** `--workspace=<id> --apply` conserta UM workspace e o
**remove da lista de pendentes** se ele fechar — o workspace consertado à mão
não fica listado como pendente, e o runbook não passa a mentir sobre o que
ainda falta. O que ele NÃO faz é fechar a varredura: os outros workspaces
pendentes continuam lá, e quem os visita é a execução `--all-workspaces`. O
roteiro depois de uma falha é:

```bash
# 1) a varredura falhou em <wid>; conserte a causa e repare só ele
node lib/scripts/migrate_money_cents.js --project=<p> --workspace=<wid> --apply

# 2) feche a base (o checkpoint já não lista <wid>; se sobrou alguém, é ele que roda)
node lib/scripts/migrate_money_cents.js --project=<p> --all-workspaces --apply

# 3) confira
node lib/scripts/migrate_money_cents.js --project=<p> --all-workspaces --verify
```

Um dry-run ou um `--verify` dirigidos **nunca** tocam no checkpoint: eles não
consertam nada.

**O que o `--verify` responde.** Para cada coleção ele imprime `lidos`,
`a_migrar`, `já_ok`, `divergentes`, `órfãos`, `inválidos` e **duas somas**:
`soma_double` (a soma de todos os valores monetários calculada a partir do
`double`) e `soma_cents` (a mesma soma pelo `*Cents` gravado, caindo no `double`
onde ele ainda não existe). Órfãos e inválidos **não entram nas somas**: o
primeiro é um inteiro sem `double` (resíduo a apagar) e o segundo é um campo que
não é número.

O veredito é explícito, e ele só passa quando **as três** contagens são zero:

| Contagem | O que significa |
|---|---|
| `divergentes > 0` | algum `*Cents` discorda do `double`. O relatório lista até 20 caminhos |
| `a_migrar > 0` | a base ainda **não está migrada** — o inteiro sequer existe nesses documentos |
| `inválidos > 0` | campo monetário presente e não numérico |

> ⚠️ **`a_migrar > 0` FALHA o `--verify`.** Dizer "nenhuma divergência" numa base
> em que o inteiro não existe seria um atestado de saúde para o silêncio: sem
> `*Cents`, não há o que divergir.

- **antes** da migração as duas somas batem e `a_migrar` é alto → `--verify`
  falha, e é o esperado: é o retrato de partida;
- **depois** as duas continuam batendo, `a_migrar` é zero e o veredito é
  `VERIFY: OK`.

Resumo final: `workspaces`, `escritas`, `falhas`, `pendentes`, `a_migrar`,
`órfãos`, `inválidos`, a lista dos workspaces que falharam e a linha por
coleção. Um `--apply` que fecha termina com uma linha afirmativa:

```
[migrate_money_cents] ✔ Migração FECHADA: 4540 documento(s) corrigido(s), 0 pendente(s), 0 divergência(s), 0 campo(s) inválido(s).
```

> **As contagens do veredito são do estado DEPOIS da execução.** As linhas por
> coleção são de ANTES da escrita (é o que a varredura viu); `a_migrar`,
> `divergentes` e `órfãos` do resumo descontam o que o `--apply` corrigiu. Sem
> isso, uma execução que consertou uma divergência sairia com código 1
> reclamando exatamente dela.

Saída de código:

| Modo | Sai 0 quando |
|---|---|
| `--verify` | a base está migrada, coerente e limpa |
| `--apply` | nenhum workspace falhou e nada ficou pendente |
| dry-run | a simulação rodou (`a_migrar > 0` é o RESULTADO dela, não um erro); falha só com workspace ilegível, campo inválido ou divergência |

> ⚠️ **NÃO EXECUTADO** contra o projeto real (`funance-cef1b`).

**Volume e custo em produção** (contagem por leitura, em 2026-09-17):

| Coleção | Documentos a migrar | Campos `*Cents` a criar |
|---|---:|---:|
| `orders` | 1.074 | 1.074 |
| `installments` | 2.378 | 6.217 |
| `accounts` | 24 | 32 |
| `accounts/{a}/balance` | 692 | 1.384 |
| `goals` | 20 | 40 |
| `category_planning` | 80 | 129 |
| `period_summaries` | 272 | 12.255 |
| **total** | **4.540** | **21.131** |

São **3 workspaces**. O custo de uma passada `--apply` é ~4.540 leituras +
~4.540 escritas de documento (o campo dentro do documento não é cobrado à
parte), o que cabe de sobra na cota gratuita diária — **menos de R$ 0,05** pela
tabela do Firestore. Doze lotes de 400. O `--verify` é leitura pura:
~4.540 leituras por execução.

> Escala: mesmo com a base cem vezes maior (~450 mil documentos), a migração
> seria uma execução de poucos minutos e alguns reais. O checkpoint existe para
> o caso de ela ser interrompida no meio, não porque se espere que seja.

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
  são processados em ordem fixa de id. Desde F1.10 o job também **lê** o
  `*Cents` gravado como fonte da verdade e **grava os dois campos**; a
  comparação deixou de ter tolerância (a opção `epsilon` saiu) e passou a
  conferir também se o `double` é o espelho exato do inteiro.
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
