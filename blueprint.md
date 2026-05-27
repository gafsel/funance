Este é o seu **Blueprint v4.0**. Com a adoção do modelo contábil de **`orders`** (Intenção/Contrato) e **`ledger_entries`** (Realidade/Caixa), você elevou o projeto de um simples app de controle para uma arquitetura de nível profissional (ERP-ready).

---

# Blueprint: Projeto "Finance Gamified App" (v4.0)

## 1. Arquitetura de Dados: O Modelo "Order-Ledger"

A separação entre a intenção da compra (`orders`) e o movimento contábil (`ledger_entries`) é a chave para a integridade dos dados.

* **`workspaces/{wid}/orders`** (As "Virtuais"):
* `id`, `description`, `total_amount`, `category`, `installments_count`, `date` (origem), `status` (active, paid, cancelled), `metadata` (ticker, juros, etc).


* **`workspaces/{wid}/ledger_entries`** (As "Físicas"):
* `id`, `order_id` (FK para `orders`), `amount`, `due_date` (competência), `status` (forecast, cleared), `type` (debit, credit), `account_id`.



---

## 2. Fluxo Estratégico (O Motor Financeiro)

### A. Fluxo de Compra Parcelada

1. **Lançamento:** App cria um registro em `orders` (ex: iPhone, 12x).
2. **Engine:** A Cloud Function de `parcelamentoEngine` lê o `order` e gera 12 `ledger_entries` com `status: 'forecast'` e `due_date` distribuídas mensalmente.

### B. Fluxo de Conciliação (OFX/PDF)

1. **Ingestão:** Parser extrai transações do arquivo do banco.
2. **Match:** O sistema busca um `ledger_entry` em `forecast` que coincida com o valor e data.
3. **Liquidação:** Se encontrado, o status muda para `cleared` e a transação é vinculada ao ID do extrato. Se não encontrado (ex: compra à vista sem pedido), cria-se um `ledger_entry` avulso.

---

## 3. Planejamento de Releases (Matriz de Priorização)

| Release | Foco | Features Principais |
| --- | --- | --- |
| **R1** | **Foundation** | Estrutura `orders` e `ledger_entries`, Auth compartilhado, CRUD básico. |
| **R2** | **Inteligência** | Parser de PDF/OFX com `match` inteligente entre `order` e `ledger`. |
| **R3** | **Coaching & Dashboards** | LLM para insights (semanais) e projeções (competência). |
| **R4** | **Portal Contador** | Exportação de `ledger_entries` em formato contábil (CSV/XML). |

---

## 4. Matriz de Priorização (Eisenhower)

* **P1 (Essencial/Urgente):** Estrutura de subcoleções `orders` e `ledger_entries`, `parcelamentoEngine`, Security Rules.
* **P2 (Importante/Não Urgente):** Parser de PDF com IA, Lógica de Coaching (Insights via Gemini).
* **P3 (Urgente/Não Importante):** Exportação para Contabilidade (pode ser feita via query no console do Firebase no início).
* **P4 (Não Importante/Não Urgente):** Gamificação (badges/pontos) e simulações avançadas.

---

## 5. Arquitetura de Infraestrutura (Checklist)

* **Firestore:**
* `Collection Group Index`: Essencial na subcoleção `ledger_entries` para consultas de "todos os workspaces" (Relatórios Contábeis).


* **Cloud Functions (Node.js):**
* `orderHandler`: Dispara ao criar um `order`, criando N `ledger_entries`.
* `reconciliationEngine`: Compara entradas do banco (PDF/OFX) com `ledger_entries` existentes.
* `taxReporter`: Gera relatórios padronizados lendo `ledger_entries` de um `workspace` do tipo "business".


* **Front-end (Flutter):**
* **Context Management:** `WorkspaceProvider` injeta o `wid` atual.
* **Data Binding:** Telas de histórico leem `orders`; Telas de fluxo de caixa leem `ledger_entries`.



---

## 6. Diferencial Contábil

Com a estrutura de `ledger_entries`, a sua contadora terá um **Livro Diário** pronto. Se você adicionar um campo `is_deductible` (boolean) na `ledger_entry`, ela poderá filtrar o que é despesa operacional da empresa com apenas um clique.
