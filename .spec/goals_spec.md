# Demanda Técnica: Evolução das Metas Financeiras (Goals)

## 🎯 Objetivo
Tornar a gestão de metas (Goals) mais informativa, oferecendo ao usuário um histórico visual do progresso da meta e uma análise de inteligência artificial sobre a viabilidade de atingimento do valor no prazo estipulado.

---

## 🏗️ Requisitos Técnicos

### 1. Linha do Tempo e Gráfico de Progresso Histórico
*   **Ajuste na Tela de Detalhes ([goal_detail_screen.dart](file:///Users/gabrielsilva/work/benavlabs/funances/lib/features/goal/presentation/screen/goal_detail_screen.dart)):**
    *   Substituir a exibição estática do percentual atual por uma seção gráfica contendo um gráfico de linha (`LineChart` do pacote `fl_chart`).
    *   O gráfico deve cruzar:
        *   **Eixo X:** Datas desde a criação da meta até o dia de vencimento (deadline).
        *   **Eixo Y:** Valores monetários acumulados.
        *   **Linha Guia (Tracejada):** O ritmo de progresso ideal para bater a meta no prazo.
        *   **Linha Real (Cheia):** Os valores reais acumulados com base nas transações consolidadas.
    *   Para obter os pontos do gráfico, realizar uma consulta paginada no histórico de transações vinculadas à meta (de acordo com as regras de busca de transação por tipo de meta).

### 2. Comemoração de Milestones (Marcos de Progresso)
*   **Indicadores Visuais de Milestone:**
    *   No header da tela de detalhes, desenhar uma trilha com pequenos badges indicadores de marcos: `25%`, `50%`, `75%` e `100%`. Os marcos alcançados devem ficar acesos (coloridos) e os futuros em tom de cinza.
*   **Confetti e Animação:**
    *   Utilizar o pacote `confetti` (já listado no `pubspec.yaml`).
    *   Quando a tela de detalhes for aberta e o estado detectar que um novo milestone foi ultrapassado recentemente (ou que a meta atingiu 100%), disparar o widget de confetti na tela para celebrar a conquista financeira do usuário.

### 3. Analisador de Viabilidade de Meta com IA
*   **Botão de Validação com Gemini:**
    *   Na tela de criação/edição de metas ([goal_form_screen.dart](file:///Users/gabrielsilva/work/benavlabs/funances/lib/features/goal/presentation/screen/goal_form_screen.dart)), adicionar um botão secundário: "Analisar Meta com IA".
*   **Fluxo de Execução:**
    *   Ao clicar, disparar uma chamada para a Cloud Function `ai_handler` enviando o payload da meta proposta (valor total, deadline, categoria/conta associada).
    *   A Cloud Function deve analisar o histórico de receitas e despesas médias daquele workspace nos últimos 3 meses.
    *   **Retorno da IA:** O Gemini retorna uma análise no formato:
        *   `status`: 'feasible' (viável), 'challenging' (desafiadora) ou 'unrealistic' (irrealista).
        *   `reason`: Justificativa curta (ex: "Sua receita média é de R$ 5.000 e poupar R$ 2.000 mensais comprometerá seus gastos essenciais que hoje somam R$ 3.800").
        *   `suggestion`: Alternativa viável (ex: "Sugerimos estender o prazo em mais 3 meses ou reduzir o teto final para R$ 6.500").
    *   Exibir esse retorno em uma caixa de diálogo informativa (alert card) flutuante na tela de formulário.

---

## 🔍 Critérios de Aceitação
*   [ ] O gráfico de progresso ideal vs. real plota as linhas corretamente na tela de detalhes sem distorcer o layout em telas menores.
*   [ ] O confetti é disparado apenas uma vez quando a meta atinge os marcos, evitando repetições inconvenientes ao reabrir a tela.
*   [ ] A análise de viabilidade por IA fornece feedbacks contextualizados baseados nos dados financeiros reais do workspace e não apenas simulações genéricas.
