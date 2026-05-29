# Documentação de Engenharia de Software: Modelagem de Pedidos e Parcelas

Este documento especifica a modelagem arquitetural e as regras de negócio para o motor de gestão financeira, detalhando as entidades `Order` (Pedido/Contrato) e `Installment` (Parcela/Lançamento), bem como os fluxos automatizados executados via Cloud Functions.

---

## 1. Modelo de Dados (Schemas)

### 1.1 Entidade: `Order`

A entidade `Order` representa o contrato ou a intenção financeira original (única, parcelada ou recorrente). Ela serve como matriz para a geração dos lançamentos efetivos.

| Campo | Tipo / Estrutura | Obrigatoriedade                                    | Descrição / Regra                                                                                                 |
| --- | --- |----------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| `id` | String (UUID) | Obrigatório                                        | Identificador único do pedido.                                                                                    |
| `amount` | Numeric (Decimal) | Obrigatório                                        | Valor total do pedido ou valor base da recorrência.                                                               |
| `dueDay` | Integer (1-31) | Obrigatório                                        | Dia fixo de vencimento das parcelas.                                                                              |
| `startMonth` | String (YYYY-MM) | Obrigatório                                        | Mês de início da cobrança/fluxo.                                                                                  |
| `endMonth` | String (YYYY-MM) | Calculado                                          | Definido dinamicamente com base em `startMonth`, `installmentType` e `installmentCount`.                          |
| `installmentCount` | Integer | Obrigatório | Só existe quando installmentType for `installment`. Quantidade de parcelas (relevante para o tipo `installment`). |
| `installmentType` | Enum | Obrigatório                                        | Opções: `single` (único), `installment` (parcelado), `recurring` (recorrente).                                    |
| `status` | Enum | Obrigatório                                        | Opções: `active` (ativo), `cancelled` (cancelado).                                                                |
| `type` | Enum | Obrigatório                                        | Opções: `expense` (despesa), `income` (receita), `transfer` (transferência).                                      |
| `accounts` | Map / Objeto | Opcional                                           | Mapeamento de contas envolvidas: `{ [accountId]: 'debt' \| 'credit' }`.                                           |
| `category` | Objeto | Condicional                                        | **Não existe se `type == 'transfer'`.** Contém: `id`, `name`, `icon`, `color`.                                    |

### 1.2 Entidade: `Installment`

A entidade `Installment` representa a parcela ou o lançamento financeiro real atrelado a um período específico. É a unidade fundamental para o extrato e balanços.

| Campo | Tipo / Estrutura | Obrigatoriedade | Descrição / Regra                                                                         |
| --- | --- | --- |-------------------------------------------------------------------------------------------|
| `id` | String (UUID) | Obrigatório | Identificador único da parcela.                                                           |
| `orderId` | String (UUID) | Obrigatório | Chave estrangeira de associação com a `Order` de origem.                                  |
| `amount` | Numeric (Decimal) | Obrigatório | Valor nominal planejado para a parcela específica.                                        |
| `dueDate` | Date (YYYY-MM-DD) | Obrigatório | Data exata do vencimento da parcela.                                                      |
| `paidAmount` | Numeric (Decimal) | Opcional | Valor efetivamente pago/realizado.                                                        |
| `paidDate` | Date (YYYY-MM-DD) | Opcional | Data em que o pagamento foi realizado.                                                    |
| `status` | Enum | Obrigatório | Opções: `pending`, `paid`, `settled`, `removed`.                                          |
| `type` | Enum | Obrigatório | Opções: `expense`, `income`, `transfer`.                                                  |
| `accounts` | Map / Objeto | Condicional | **Obrigatório se `status == 'paid'`.** Mapeamento: `{ [accountId]: 'debt' \| 'credit' }`. |
| `category` | Objeto | Condicional | **Não existe se `type == 'transfer'`.** Contém: `id`, `name`, `icon`, `color`.            |
| `replicationCascade` | Enum | Edição Apenas | Opções: `none`, `all`, `future`. Controla a propagação de alterações.                     |


---

## 2. Regras de Negócio e Funcionalidades (Features)

### 2.1 Extrato (Consultas e Filtros)

A listagem do extrato financeiro opera estritamente sobre a entidade `Installment`. A query de busca deve aplicar cumulativamente os seguintes critérios de filtragem:

* **Período:** Filtrado pelo campo `dueDate`.
* **Vínculo de Conta:** O ID da conta pesquisada deve estar contido na chave do objeto `accounts` tanto como `debt` quanto como `credit` (`accounts.{id} IN ['debt', 'credit']`).
* **Expurgo de Removidos:** Excluir registros cujo `status == 'removed'`.

### 2.2 Cadastro de Pedidos (Processamento via Cloud Functions)

O gatilho de criação de uma `Order` dispara uma Cloud Function responsável por instanciar os respectivos `Installments` com base no `installmentType`:

```
                  [Criação de Order]
                          |
         +----------------+----------------+
         |                                 |
 [Tipo: single]                    [Tipo: installment]
         |                                 |
Gera 1 Installment                 Gera N Installments
(Mês de início)                 (Mês início até N meses)
         |                                 |
         +----------------+----------------+
                          |
                  [Tipo: recurring]
                          |
               Gera 12 Installments inicialmente
               + Rotina mensal (Cron) adicionando
               novos meses se Order estiver "active"

```

* **`single`:** Instancia exatamente 1 `Installment` posicionado no mês correspondente ao `startMonth` com o `dueDay` especificado.
* **`installment`:** Instancia $N$ parcelas (onde $N$ é o valor de `installmentCount`), distribuídas sequencialmente mês a mês a partir de `startMonth`.
* **`recurring`:** Instancia inicialmente 12 `Installments` subsequentes. Uma rotina cronometrada mensal avalia se a `Order` permanece com o status `active` e, em caso positivo, provisiona recursivamente o próximo mês, estendendo o horizonte de projeção.

### 2.3 Edição de Parcelas e Replicação em Cascata (Processamento via Cloud Functions)

Qualquer mutação em um `Installment` interceptada pelas Cloud Functions deve avaliar o escopo definido pelo atributo transiente `replicationCascade`:

* **`none`:** As alterações de propriedades (valor, data, categoria, status) aplicam-se estritamente ao documento do `Installment` atual.
* **`all`:** Propaga as modificações para todos os `Installments` vinculados ao mesmo `orderId`. Se a operação disparada for uma exclusão lógica (`status = 'removed'`), a Cloud Function deve atualizar a `Order` pai para `status = 'cancelled'`.
* **`future`:** Propaga as modificações para o `Installment` atual e todos os lançamentos irmãos cujo `dueDate` seja cronologicamente igual ou posterior ao `dueDate` modificado. Se a operação for uma exclusão lógica, a `Order` pai também deve ser marcada como `status = 'cancelled'`.

### 2.4 Motor de Contabilização do Sumário de Categorias

O sumário analítico por categorias é derivado exclusivamente dos dados de `Installment`. O pipeline de agregação deve computar as duas dimensões temporais de forma distinta:

1. **Valor Planejado (Projeção Orçamentária):** O impacto financeiro do `amount` é computado no período (mês/ano) correspondente ao **`dueDate`**.
2. **Valor Realizado (Fluxo de Caixa Efetivo):** O impacto financeiro do `paidAmount` é computado no período correspondente ao **`paidDate`**.

#### Mecanismo de Idempotência e Mutabilidade:

Para suportar reajustes retroativos, a lógica de persistência (Gatilho de Banco de Dados: `onUpdate`) deve calcular o delta entre o estado anterior (`change.before`) and o novo estado (`change.after`). Qualquer alteração em `dueDate`, `paidDate`, `status`, `amount` ou `category` deve engajar um processo de estorno do valor antigo no balanço do período anterior e incremento correspondente no novo período/categoria alvo.

### 2.5 Gerenciamento do Saldo de Contas (Processamento via Cloud Functions)

Os saldos históricos e correntes das contas bancárias são atualizados de forma assíncrona através de Cloud Functions disparadas apenas quando um `Installment` transiciona ou é criado com o status `paid`.

* **Gatilho Temporal:** O cálculo do saldo afeta o período correspondente ao **`paidDate`**.
* **Cálculo Base:** A função localiza o mapeamento de contas no `Installment`. Para contas marcadas como `credit`, o valor de `paidAmount` é incrementado; para contas mapeadas como `debt`, o valor é decrementado.
* **Regra de Continuidade (Efeito Cascata Cronológico):**
* O sistema consulta os registros de saldo a partir do período impactado.
* Se não houver um registro de saldo consolidado para o período exato do `paidDate`, o sistema realiza uma busca regressiva para encontrar o saldo consolidado mais recente anterior a esta data. Este valor servirá como saldo inicial para o novo período gerado, aplicando o incremento/decremento do `paidAmount`.
* Todas as partições de saldo de períodos posteriores à data do pagamento devem ser atualizadas em efeito cascata para refletir o novo saldo acumulado corrigido.

Aqui está a documentação atualizada, integrando o impacto dos registros de `category_planning` no sumário de categorias e detalhando o comportamento de recálculo por deltas nos períodos vigentes.

---

### 2.6 Planejamento e Previsão de Categorias (`category_planning`)

O controle de orçamento por categorias utiliza um modelo de versionamento baseado em vigência (`startMonth` e `endMonth`). O objetivo é garantir que alterações no planejamento atual não afetem retroativamente os relatórios de meses anteriores, a menos que seja a intenção do usuário.

**Arquitetura e Delegação (Client-Side Responsibility):**
Toda a lógica de decisão e orquestração do versionamento histórico ocorre no **Frontend**. O sistema cliente é responsável por interrogar o usuário sobre o escopo da ação (Geral vs. Futuro) e executar as mutações (Inserts, Updates, Deletes) diretamente no banco de dados, preferencialmente agrupadas em uma transação para garantir atomicidade.

#### A. Fluxo de Criação (Frontend)

Quando o usuário cria um novo planejamento para uma categoria, o frontend monta e envia o seguinte payload:

* `startMonth`: Definido automaticamente como o **mês/ano corrente**.
* `endMonth`: Projetado para **3 anos no futuro** (ex: `2029-12`), configurando o planejamento como ativo por tempo indeterminado.

#### B. Fluxo de Edição e Versionamento (Frontend)

Quando o valor (`amount`) de um planejamento existente é alterado, o frontend exibe um prompt interrogando o usuário: *"Aplicar essa alteração a todo o período ou somente para o futuro?"*

* **Opção 1: Todo o período (Geral)**
  O frontend executa uma operação simples de **UPDATE** no registro existente, atualizando exclusivamente a propriedade `amount`. As datas de vigência permanecem intactas, alterando o histórico retroativo.
* **Opção 2: Somente para o futuro (Preservação de Histórico)**
  O frontend orquestra duas operações simultâneas (em batch/transação):
1. **UPDATE no registro atual (Corte de Vigência):** Atualiza o `endMonth` do registro existente para o **mês imediatamente anterior** ao mês corrente.
2. **INSERT de um novo registro (Nova Vigência):** Cria um novo documento `category_planning` com o novo `amount`, recebendo o `startMonth` como o **mês corrente** e o `endMonth` projetado para 99 anos no futuro.



#### C. Fluxo de Exclusão (Frontend)

Ao solicitar a exclusão de um planejamento, o frontend novamente interroga o usuário sobre o escopo da remoção:

* **Opção 1: Todo o período (Geral)**
  O frontend executa um **DELETE** físico (ou lógico) do registro alvo, apagando a previsão para todos os meses associados.
* **Opção 2: Somente para o futuro (Encerramento)**
  O registro original não é excluído. O frontend executa um **UPDATE** no registro existente, alterando o `endMonth` para o **mês imediatamente anterior** ao corrente.

#### D. Impacto no Sumário de Categorias (Processamento via Cloud Functions / Triggers)

Os registros da entidade `category_planning` alimentam diretamente a meta/previsão orçamentária nos consolidados mensais. Qualquer mutação nesta entidade deve disparar um processo assíncrono de recalculo para sincronizar os sumários:

* **Escopo Temporal de Impacto:** O valor definido em `amount` deve ser replicado e contabilizado no sumário de categorias em **todos os meses/períodos contidos no intervalo inclusivo** entre o `startMonth` e o `endMonth`.
* **Cálculo por Diferença (Deltas) e Idempotência:** Para evitar inconsistências e garantir o comportamento correto diante de atualizações, as funções de banco de dados (`onWrite`) devem calcular a variação matemática entre o estado anterior (`change.before`) e o novo estado (`change.after`):
* **Na Criação:** Incrementa o valor de `amount` no campo de teto planejado do sumário de cada mês do intervalo.
* **Na Edição (Alteração de Valor ou Vigência):** * O sistema avalia os meses afetados. Se o valor mudou de $100$ para $120$, o delta de $+20$ é somado aos meses correspondentes. Se o valor diminuiu, o delta negativo é aplicado.
* Se houver alteração nas datas de vigência (como no corte de `endMonth` para o mês anterior), o sistema remove integralmente o valor planejado dos meses que deixaram de fazer parte do intervalo de cobertura.


* **Na Exclusão:** Decrementa o valor total (`amount`) de todos os meses que estavam cobertos pelo período do planejamento excluído, zerando ou subtraindo a previsão correspondente no sumário.
