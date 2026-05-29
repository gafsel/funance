Este é o seu **Blueprint v5.0**. Com a adoção do modelo contábil de **`orders`** (Intenção/Contrato) e **`installments`** (Realidade/Caixa), além do **`category_plannings`** para metas, você elevou o projeto de um simples app de controle para uma arquitetura de nível profissional (ERP-ready).

---

# Blueprint: Projeto "Finance Gamified App" (v5.0)

## 1. Arquitetura de Dados: O Modelo "CategoryPlanning-Order-Installment"

A separação entre o planejamento (`category_plannings`), a intenção da compra (`orders`) e o movimento contábil (`installments`) é a chave para a integridade dos dados.

* **`workspaces/{wid}/category_plannings`** (O Planejado):
  * `id`, `categoryId`, `amount`, `startMonth`, `endMonth`.

* **`workspaces/{wid}/orders`** (A Intenção):
  * `id`, `description`, `amount`, `category`, `installmentType` (single, installment, recurring), `installmentCount`, `dueDay`, `startMonth`, `status` (active, cancelled), `accounts` (mapa de IDs para 'debt'|'credit').

* **`workspaces/{wid}/installments`** (A Realidade):
  * `id`, `orderId` (FK para `orders`), `amount`, `dueDate` (competência), `paidAmount`, `paidDate` (caixa), `status` (pending, paid, settled, removed), `type` (expense, income, transfer), `accounts`, `category`.

* **`workspaces/{wid}/period_summaries`** (A Consolidação):
  * `id` (YYYY-MM-categoryId ou YYYY-categoryId), `year`, `month`, `category`, `generalPlannedAmount` (da planning), `specificPlannedAmount` (das installments projetadas), `actualAmount` (realizado).



---

## 2. Fluxo Estratégico (O Motor Financeiro)

### A. Fluxo de Compra Parcelada

1. **Lançamento:** App cria um registro em `orders` (ex: iPhone, 12x).
2. **Engine:** A Cloud Function de `orderHandler` lê o `order` e gera 12 `installments` com `status: 'pending'` e `dueDate` distribuídas mensalmente.

### B. Fluxo de Conciliação (OFX/PDF)

1. **Ingestão:** Parser extrai transações do arquivo do banco.
2. **Match:** O sistema busca um `installment` em `pending` que coincida com o valor e data.
3. **Liquidação:** Se encontrado, o status muda para `paid`, registra-se `paidAmount`/`paidDate` e a transação é vinculada. Se não encontrado (ex: compra à vista sem pedido), cria-se um `installment` avulso.

---

## 3. Planejamento de Releases (Matriz de Priorização)

| Release | Foco | Features Principais |
| --- | --- | --- |
| **R1** | **Foundation** | Estrutura `orders`, `installments` e `category_plannings`, Auth compartilhado, CRUD básico. |
| **R2** | **Inteligência** | Parser de PDF/OFX com `match` inteligente entre `order` e `installment`. |
| **R3** | **Coaching & Dashboards** | LLM para insights (semanais) e projeções (competência). |
| **R4** | **Portal Contador** | Exportação de `installments` em formato contábil (CSV/XML). |

---

## 4. Matriz de Priorização (Eisenhower)

* **P1 (Essencial/Urgente):** Estrutura de subcoleções `orders`, `installments` e `category_plannings`, `orderHandler`, Security Rules.
* **P2 (Importante/Não Urgente):** Parser de PDF com IA, Lógica de Coaching (Insights via Gemini).
* **P3 (Urgente/Não Importante):** Exportação para Contabilidade (pode ser feita via query no console do Firebase no início).
* **P4 (Não Importante/Não Urgente):** Gamificação (badges/pontos) e simulações avançadas.

---

## 5. Arquitetura de Infraestrutura (Checklist)

* **Firestore:**
  * `Collection Group Index`: Essencial na subcoleção `installments` para consultas de "todos os workspaces" (Relatórios Contábeis).


* **Cloud Functions (Node.js):**
  * `orderHandler`: Dispara ao criar um `order`, criando N `installments`.
  * `installmentHandler`: Dispara ao alterar um `installment`, atualizando saldos e sumários.
  * `reconciliationEngine`: Compara entradas do banco (PDF/OFX) com `installments` existentes.
  * `taxReporter`: Gera relatórios padronizados lendo `installments` de um `workspace` do tipo "business".


* **Front-end (Flutter):**
  * **Context Management:** `WorkspaceProvider` injeta o `wid` atual.
  * **Data Binding:** Telas de histórico leem `orders`; Telas de fluxo de caixa leem `installments`.



---

## 6. Diferencial Contábil

Com a estrutura de `installments`, a sua contadora terá um **Livro Diário** pronto. Se você adicionar um campo `is_deductible` (boolean) na `installment`, ela poderá filtrar o que é despesa operacional da empresa com apenas um clique.
