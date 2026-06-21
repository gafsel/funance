# Demanda Técnica: Expansão da Gamificação (Missions, XP & Badges por Workspace)

## 🎯 Objetivo
Transformar o sistema de missões em um motor de gamificação colaborativo, introduzindo níveis e insígnias **por Workspace** (e não por usuário individual). A ideia é que os membros da equipe trabalhem juntos para atingir os objetivos financeiros comuns da empresa ou da família. Todo o controle de ganho de XP, cálculo de níveis e desbloqueio de badges deve ocorrer estritamente no **backend** (via Cloud Functions/Triggers) ao reagir a eventos do banco de dados, mantendo o frontend puramente como exibição e emissão de transações.

---

## 🏗️ Requisitos Técnicos

### 1. Sistema de Nível e XP por Workspace
*   **Modelo de Dados (Backend & Frontend):**
    *   No model do workspace (`WorkspaceModel` e no respectivo documento `/workspaces/{wid}` do Firestore), adicionar os atributos:
        *   `xp: int` (XP **Total Acumulado** do workspace desde a criação, inicializado em 0).
        *   `level: int` (Nível atual do workspace, inicializado em 1).
    *   **Fórmula de Progressão Geométrica Infinita (Dobro de Dificuldade):**
        Para permitir que o sistema escale infinitamente sem limites de nível fixo, o XP exigido em cada nível para atingir o próximo dobrará em relação ao nível anterior:
        *   **XP do Degrau do Nível ($XP_{degrau}$):** É o XP necessário exclusivamente para transicionar do nível $L$ para o nível $L+1$:
            $$XP_{degrau}(L) = 300 \times 2^{(L-1)}$$
        *   **XP Total Acumulado ($XP_{total\_acumulado}$):** É a soma de todos os degraus anteriores necessária para alcançar o nível $L$ partindo do nível 1:
            $$XP_{total\_acumulado}(L) = 300 \times (2^{(L-1)} - 1)$$
        *   *Tabela resultante da fórmula:*
            *   Nível 1: $0$ XP acumulado. (Para ir ao Nível 2: $+300$ XP).
            *   Nível 2: $300$ XP acumulado. (Para ir ao Nível 3: $+600$ XP).
            *   Nível 3: $900$ XP acumulado. (Para ir ao Nível 4: $+1.200$ XP).
            *   Nível 4: $2.100$ XP acumulado. (Para ir ao Nível 5: $+2.400$ XP).
            *   Nível 5: $4.500$ XP acumulado. (Para ir ao Nível 6: $+4.800$ XP).
            *   Nível 6: $9.300$ XP acumulado. (Para ir ao Nível 7: $+9.600$ XP).
            *   Nível $L$: Escala infinitamente.
    *   **Regra de Cálculo de Level Up (Backend):**
        *   O nível atual $L$ é derivado diretamente do $XP_{total}$ acumulado no banco de dados através da fórmula inversa logarítmica:
            $$L = \lfloor \log_2(XP_{total} / 300 + 1) \rfloor + 1$$
        *   Ao computar novos ganhos de XP, o backend recalcula a fórmula. Caso o novo nível calculado seja maior que o `level` atual registrado no documento, o campo `level` é atualizado e o timestamp `lastLevelUpAt` é gravado.
    *   **Regra de Cálculo da Barra de Progresso (Frontend & UI):**
        *   Para exibir a barra de progresso, o frontend consulta o $XP_{total}$ e o nível $L$ do workspace e calcula:
            *   XP acumulado dentro do nível atual: $XP_{atual} = XP_{total} - (300 \times (2^{(L-1)} - 1))$
            *   XP exigido no degrau do nível atual: $XP_{degrau} = 300 \times 2^{(L-1)}$
            *   Fração da barra: $\text{Fração} = XP_{atual} / XP_{degrau}$
        *   *Exemplos de cálculo de progresso:*
            *   Com $150$ XP acumulado: Nível 1. Barra em $150 / 300$ XP (50%).
            *   Com $600$ XP acumulado: Nível 2. Barra em $300 / 600$ XP (50%, pois ultrapassou a marca de 300 XP e faltam 300 para a marca de 900 XP do Nível 3).
            *   Com $1.500$ XP acumulado: Nível 3. Barra em $600 / 1.200$ XP (50%, pois ultrapassou a marca de 900 XP e faltam 600 para a marca de 2100 XP do Nível 4).
            *   Com $3.300$ XP acumulado: Nível 4. Barra em $1.200 / 2.400$ XP (50%, pois ultrapassou a marca de 2100 XP e faltam 1200 para a marca de 4500 XP do Nível 5).
*   **Ajustes na UI (Frontend):**
    *   Remover referências de XP/Level individuais do perfil de usuário.
    *   No menu lateral (drawer) e na aba Jornada ([journey_tab.dart](file:///Users/gabrielsilva/work/benavlabs/funances/lib/features/home/presentation/widgets/journey_tab.dart)), exibir uma barra de progresso horizontal do **Workspace Ativo**. Essa barra mostra o nível do workspace (ex: "Equipe Nível 4"), o XP acumulado no nível atual e o XP restante para subir de nível.

### 2. Controle de XP e Nível no Backend (Cloud Functions)
*   **Trigger de Conclusão de Missões/Transações:**
    *   Criar ou ajustar uma trigger no backend (ex: `onInstallmentWritten` em `installment_handler.ts`) que monitore quando uma parcela (`installment`) muda seu status para `paid` (Paga).
    *   Ao quitar uma parcela que estava vinculada a uma missão ou com data válida, o backend calcula o XP ganho e o adiciona atonicamente ao documento do workspace correspondente.
    *   A Cloud Function deve ser o único ponto que incrementa o XP e valida se o workspace subiu de nível. Se o workspace subir de nível, gravar um campo `lastLevelUpAt: Timestamp` no workspace. O frontend ouvirá esse campo e exibirá a animação de comemoração correspondente.

### 3. Missões de Hábito Comportamental da Equipe
*   **Tipos de Missões de Equipe:**
    *   A cada semana, uma rotina cron gera missões dinâmicas no escopo do workspace:
        *   *Missão de Consistência:* "Equipe registra pelo menos 1 gasto por dia durante 3 dias nesta semana." (Recompensa: 150 XP).
        *   *Missão de Disciplina:* "Equipe mantém a categoria Alimentação dentro do orçamento previsto por 5 dias." (Recompensa: 250 XP).
        *   *Missão de Organização:* "Fazer a conciliação bancária completa de um extrato contendo pelo menos 5 itens." (Recompensa: 200 XP).
*   **Backend de Rastreamento:**
    *   A Cloud Function de cron semanal gera as missões na subcoleção do workspace: `workspaces/{wid}/weekly_missions`.
    *   Triggers do Firestore (ex: `onTransactionCreated`, `onReconciliationConfirmed`) são responsáveis por computar o progresso dessas metas semanais e marcar as missões como concluídas no backend, incrementando o XP do workspace.

### 4. Armário de Conquistas da Equipe (Badges por Workspace)
*   **Estrutura de Badges no Workspace:**
    *   No documento `/workspaces/{wid}`, adicionar um campo `unlockedBadges: map` contendo o ID da insígnia mapeado para a data da conquista (ex: `{ "unlockedBadges": { "first_step": "2026-06-21T00:00:00Z" } }`).
    *   O desbloqueio das insígnias deve ser feito exclusivamente no backend através de Cloud Functions, avaliando o progresso agregado da equipe:
*   **Lista de 20 Conquistas (Badges) Iniciais:**

| ID Badge | Nome da Insígnia | Ícone | Regra de Desbloqueio (Trigger no Backend) | Recompensa |
| --- | --- | --- | --- | --- |
| `first_step` | **Primeiro Passo** | `rocket_launch` | O workspace é criado e o onboarding é concluído com sucesso. | `+100 XP` |
| `first_account` | **Primeira Conta** | `account_balance` | A primeira conta bancária ou cartão é cadastrado no workspace. | `+150 XP` |
| `first_transaction` | **Ponto de Partida** | `add_circle` | A primeira transação real (`installment`) é registrada com status `paid`. | `+150 XP` |
| `planner` | **Planejador Estrategista** | `assignment` | Limites de planejamento (`category_plannings`) são criados para pelo menos 5 categorias. | `+200 XP` |
| `reconcile_junior` | **Conciliador Júnior** | `point_of_sale` | A primeira conciliação bancária bem-sucedida é concluída (pelo menos 1 match confirmado). | `+300 XP` |
| `cash_detective` | **Detetive de Caixa** | `fact_check` | Conciliação completa de um arquivo de extrato contendo $\ge 10$ transações. | `+500 XP` |
| `reconcile_master` | **Mestre da Conciliação** | `workspace_premium` | O workspace acumula 10 conciliações de extratos concluídas com sucesso. | `+1000 XP` |
| `zero_friction` | **Atrito Zero** | `bolt` | Conciliar um extrato mensal inteiro sem necessitar criar lançamentos manuais extras. | `+800 XP` |
| `savings_seed` | **Semente de Poupança** | `savings` | A primeira meta (`goal`) cadastrada no workspace atinge 100% de progresso. | `+500 XP` |
| `goal_bronze` | **Colecionador de Metas** | `military_tech` | O workspace conclui com sucesso 3 metas financeiras diferentes. | `+1000 XP` |
| `goal_silver` | **Foco Inabalável** | `stars` | O workspace conclui com sucesso 5 metas financeiras diferentes. | `+2000 XP` |
| `emergency_shield` | **Escudo de Emergência** | `shield` | Atingir 100% de progresso em uma meta criada com a categoria/tag "Emergência". | `+800 XP` |
| `under_control` | **Tudo Sob Controle** | `check_circle` | Fechar o mês sem estourar nenhuma categoria planejada na regra 50-30-20. | `+1500 XP` |
| `golden_rule` | **Regra de Ouro** | `pie_chart` | Alocar limites em todos os 3 pools (Essencial, Conforto, Investimento) no mesmo mês. | `+1200 XP` |
| `future_focus` | **Visão de Futuro** | `trending_up` | Poupar e investir efetivamente pelo menos 20% das receitas totais do workspace no mês. | `+1000 XP` |
| `cost_cutter` | **Tesoura de Gastos** | `content_cut` | Reduzir os gastos totais do pool de Conforto (supérfluos) em 20% em relação ao mês anterior. | `+800 XP` |
| `dynamic_duo` | **Dupla Dinâmica** | `people` | Workspace com 2 membros ativos registrando transações pagas no mesmo mês. | `+400 XP` |
| `united_front` | **Equipe Unida** | `groups` | Workspace com 3 ou mais membros ativos adicionados e aceitos. | `+600 XP` |
| `financial_synapsis` | **Sinergia Financeira** | `hub` | Concluir uma missão semanal onde todos os membros ativos registraram ao menos 1 transação. | `+800 XP` |
| `iron_consistency` | **Consistência de Aço** | `calendar_month` | Concluir com sucesso as missões semanais por 4 semanas consecutivas. | `+2500 XP` |

*   **UI - Armário de Conquistas da Equipe (`badges_cabinet_screen.dart`):**
    *   Mudar a tela de conquistas para exibir as conquistas **do Workspace**, permitindo que qualquer membro veja os troféus que a equipe ganhou junta. As insígnias continuam cinzas (bloqueadas) ou coloridas (conquistadas com a data logo abaixo).

### 5. Regras Técnicas de Verificação de Conquistas (Badges) no Backend
Para que o motor de Cloud Functions avalie o desbloqueio das badges de forma eficiente e sem loops infinitos, cada insígnia deve possuir uma trigger de banco de dados específica associada:

1.  **`first_step` (Primeiro Passo):**
    *   *Trigger:* `onUpdate` em `workspaces/{wid}`.
    *   *Regra:* O campo boolean `onboardingCompleted` transiciona de `false` para `true`.
2.  **`first_account` (Primeira Conta):**
    *   *Trigger:* `onCreate` em `workspaces/{wid}/accounts/{accountId}`.
    *   *Regra:* Realizar uma contagem de documentos na subcoleção `/accounts`. Desbloquear se `count == 1`.
3.  **`first_transaction` (Ponto de Partida):**
    *   *Trigger:* `onWrite` em `workspaces/{wid}/installments/{installmentId}`.
    *   *Regra:* O status do documento transiciona para `paid` e a contagem histórica de parcelas com status `paid` no banco é `== 1`.
4.  **`planner` (Planejador Estrategista):**
    *   *Trigger:* `onWrite` em `workspaces/{wid}/category_plannings/{planningId}`.
    *   *Regra:* Contar documentos em `/category_plannings` que tenham `amount > 0`. Desbloquear se `count >= 5`.
5.  **`reconcile_junior` (Conciliador Júnior):**
    *   *Trigger:* `onUpdate` em `workspaces/{wid}/reconciliations/{recId}` (ou coleção de logs de consolidação).
    *   *Regra:* O status da conciliação muda para `completed` e o total de matches confirmados (`confirmedMatchesCount`) é $\ge 1$.
6.  **`cash_detective` (Detetive de Caixa):**
    *   *Trigger:* `onUpdate` em `workspaces/{wid}/reconciliations/{recId}`.
    *   *Regra:* O status muda para `completed` e o número de itens processados no extrato (`totalTransactionsProcessed`) é $\ge 10$.
7.  **`reconcile_master` (Mestre da Conciliação):**
    *   *Trigger:* `onUpdate` em `workspaces/{wid}/reconciliations/{recId}`.
    *   *Regra:* Contar documentos na coleção de reconciliações com status `completed`. Desbloquear se `count >= 10`.
8.  **`zero_friction` (Atrito Zero):**
    *   *Trigger:* `onUpdate` em `workspaces/{wid}/reconciliations/{recId}`.
    *   *Regra:* O status muda para `completed` e a contagem de transações criadas do zero (avulsas sem match prévio) durante o processo é `== 0`.
9.  **`savings_seed` (Semente de Poupança):**
    *   *Trigger:* `onWrite` em `workspaces/{wid}/goals/{goalId}`.
    *   *Regra:* O status do goal muda para `completed` (ou `currentAmount >= targetAmount` e a meta é a primeira concluída).
10. **`goal_bronze` (Colecionador de Metas):**
    *   *Trigger:* `onWrite` em `workspaces/{wid}/goals/{goalId}`.
    *   *Regra:* Contar documentos em `/goals` com status `completed`. Desbloquear se `count >= 3`.
11. **`goal_silver` (Foco Inabalável):**
    *   *Trigger:* `onWrite` em `workspaces/{wid}/goals/{goalId}`.
    *   *Regra:* Contar documentos em `/goals` com status `completed`. Desbloquear se `count >= 5`.
12. **`emergency_shield` (Escudo de Emergência):**
    *   *Trigger:* `onWrite` em `workspaces/{wid}/goals/{goalId}`.
    *   *Regra:* Um goal com o atributo `type` igual a `"emergency"` transiciona seu status para `completed`.
13. **`under_control` (Tudo Sob Controle):**
    *   *Trigger:* Rotina Cron Mensal (disparada às 00:05 do dia 1 de cada mês).
    *   *Regra:* Buscar todos os registros de `period_summaries` do workspace referentes ao mês recém-encerrado. Verificar se, para todos os itens retornados, `actualAmount <= plannedAmount`.
14. **`golden_rule` (Regra de Ouro):**
    *   *Trigger:* `onWrite` em `workspaces/{wid}/category_plannings/{planningId}`.
    *   *Regra:* Consultar a coleção de categorias do workspace e verificar se existem planejamentos ativos com `amount > 0` nas 3 categorias de alocação: `essential`, `comfort` e `investment`.
15. **`future_focus` (Visão de Futuro):**
    *   *Trigger:* Rotina Cron Mensal.
    *   *Regra:* Consultar as receitas totais recebidas no mês anterior e verificar se a soma de parcelas salvas no pool de investimentos (`investment`) totaliza $\ge 20\%$ das receitas no período contábil.
16. **`cost_cutter` (Tesoura de Gastos):**
    *   *Trigger:* Rotina Cron Mensal.
    *   *Regra:* Buscar a soma das despesas do pool `comfort` do mês $M-1$ e do mês $M-2$. Desbloquear se a soma do mês $M-1$ for $\le 0.8 \times$ a soma do mês $M-2$.
17. **`dynamic_duo` (Dupla Dinâmica):**
    *   *Trigger:* `onWrite` em `workspaces/{wid}/installments/{installmentId}`.
    *   *Regra:* Verificar se há transações pagas no mês atual registradas por pelo menos dois `userIds` distintos (campo `createdBy` ou `paidBy`).
18. **`united_front` (Equipe Unida):**
    *   *Trigger:* `onUpdate` em `workspaces/{wid}` (ao adicionar membros).
    *   *Regra:* O tamanho do array `members` (membros ativos aceitos) é $\ge 3$.
19. **`financial_synapsis` (Sinergia Financeira):**
    *   *Trigger:* Rotina Cron Semanal (disparada aos domingos às 23:55).
    *   *Regra:* Avaliar as missões semanais concluídas. Desbloquear se a missão semanal for concluída e houver registro de transações pagas na semana criada por cada um dos IDs de membros ativos listados no workspace.
20. **`iron_consistency` (Consistência de Aço):**
    *   *Trigger:* Rotina Cron Semanal.
    *   *Regra:* Incrementar um contador de sequências semanais (`weeklyStreaks`) no documento do workspace caso a missão semanal atual tenha sido concluída com sucesso (100%). Desbloquear quando `weeklyStreaks >= 4`.

---

## 🔍 Critérios de Aceitação
*   [ ] O XP, nível e insígnias são armazenados e atualizados estritamente no documento do `workspace` no Firestore.
*   [ ] Nenhuma operação de alteração ou soma de XP ocorre no frontend do Flutter; a UI apenas reage e renderiza os dados calculados e gravados pelas Cloud Functions do Firebase.
*   [ ] Quando múltiplos membros realizam lançamentos, o progresso do XP é somado de forma colaborativa no mesmo workspace.
*   [ ] Ao subir de nível no backend, a gravação da data de level up faz o frontend disparar um alerta visual temporário de comemoração de subida de nível.
*   [ ] A visualização do Armário de Conquistas reflete exatamente os troféus da equipe do workspace ativo.
*   [ ] O backend possui testes simulados para cada uma das triggers de Cloud Functions de badges, provando que elas são ativadas e atualizadas corretamente.

