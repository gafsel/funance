# Demanda Técnica: Melhorias no Coaching de IA (Insight Slides)

## 🎯 Objetivo
Melhorar a utilidade prática e o engajamento da feature de Coaching de IA, permitindo que o usuário execute ações diretas com base nos conselhos gerados pela IA e consiga rever o histórico de conselhos antigos recebidos.

---

## 🏗️ Requisitos Técnicos

### 1. CTAs Contextualizados (Ações Diretas nos Slides)
*   **Alteração no Modelo de Dados (Backend & Frontend):**
    *   No model `SlideModel` (localizado em [coaching_model.dart](file:///Users/gabrielsilva/work/benavlabs/funances/lib/features/coaching/domain/models/coaching_model.dart) e na respectiva definição no TypeScript em `functions/src/features/coaching`), adicionar dois novos campos opcionais:
        *   `actionLabel: string?` (Texto do botão, ex: "Ver Planejamento").
        *   `actionPath: string?` (Caminho de rota interna do app para redirecionamento, ex: `/finance/planning`).
    *   Atualizar o prompt de geração do Gemini no backend (`functions/src/features/coaching/domain/services/coaching.service.ts`) para instruir a IA a preencher de forma condicional estes campos caso o slide recomende uma ação específica no app (ex: se falar sobre cortar custos de mercado, preencher com `/finance/planning` ou `/category-details?type=expense`).
*   **Ajuste na UI ([coaching_slides_screen.dart](file:///Users/gabrielsilva/work/benavlabs/funances/lib/features/coaching/presentation/screens/coaching_slides_screen.dart)):**
    *   Se `actionLabel` e `actionPath` estiverem presentes no slide ativo, renderizar um botão proeminente de CTA (Call to Action) logo abaixo da mensagem do slide.
    *   Ao clicar no botão, navegar o usuário utilizando `context.push(slide.actionPath)` e fechar o fluxo de slides.

### 2. Biblioteca de Histórico de Insights
*   **Criação de Tela ([coaching_history_screen.dart](file:///Users/gabrielsilva/work/benavlabs/funances/lib/features/coaching/presentation/screens/coaching_history_screen.dart)):**
    *   Criar uma nova tela que exibe uma lista de todos os registros de coaching anteriores gerados no workspace atual (ordenados por data de forma decrescente).
    *   Exibir cada insight em um card contendo: a data de geração, o resumo do insight (`message`) e um botão "Rever Dicas".
    *   Ao clicar em "Rever Dicas", abrir a tela [coaching_slides_screen.dart](file:///Users/gabrielsilva/work/benavlabs/funances/lib/features/coaching/presentation/screens/coaching_slides_screen.dart) passando o objeto `CoachingModel` selecionado como parâmetro.
*   **Navegação e Atalho:**
    *   No card de coaching na home ([coaching_insight_card.dart](file:///Users/gabrielsilva/work/benavlabs/funances/lib/features/home/presentation/widgets/coaching_insight_card.dart)), adicionar um pequeno botão/link "Ver histórico" no canto superior direito para dar acesso rápido à tela de histórico.

---

## 🔍 Critérios de Aceitação
*   [ ] O backend gera payloads de slides contendo caminhos de rotas corretos e válidos do `go_router` no campo `actionPath`.
*   [ ] Os botões de ação aparecem centralizados nos slides que possuem o atributo `actionPath` e redirecionam o usuário corretamente sem quebrar o fluxo.
*   [ ] O usuário consegue acessar a nova tela de Histórico e rever slides gerados em semanas passadas de forma offline (usando o cache do Firestore).
