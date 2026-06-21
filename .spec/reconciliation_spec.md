# Demanda Técnica: Otimização da Conciliação Bancária (OFX/PDF)

## 🎯 Objetivo
Tornar o fluxo de conciliação bancária por extrato (OFX/PDF) extremamente fluido e intuitivo, reduzindo o atrito de carregamento e melhorando o entendimento visual das conexões de lançamentos correspondentes.

---

## 🏗️ Requisitos Técnicos

### 1. Drag & Drop Reativo (Desktop/Web)
*   **Integração do Pacote `desktop_drop`:**
    *   Na tela de upload do extrato ([reconciliation_screen.dart](file:///Users/gabrielsilva/work/benavlabs/funances/lib/features/finance/presentation/screens/reconciliation_screen.dart)), envelopar o painel central de upload com o widget `DropTarget` do pacote `desktop_drop`.
    *   **Comportamento Visual:** Quando o cursor do mouse estiver arrastando um arquivo válido por cima da tela do app:
        *   Mudar a cor de fundo do painel de upload para um gradiente sutil do tema (`AppGradients.turquoiseBlue` com 20% de opacidade).
        *   Exibir uma borda tracejada animada ao redor da área de drop.
        *   Substituir o texto padrão por "Solte o arquivo do extrato aqui".
    *   Ao soltar o arquivo, acionar o mesmo método de processamento do parser (`notifier.uploadFile`).

### 2. Conectores Visuais de Links de Match (Desktop Layout)
*   **Melhoria de UI no Desktop Layout:**
    *   No método `_buildDesktopLayout`, desenhar uma linha de conexão conectando o bloco da transação do extrato (esquerda) com a sugestão do sistema correspondente (direita).
    *   A linha pode ser desenhada usando um CustomPainter simples ou contêineres finos com cantos arredondados.
    *   A cor da linha deve acompanhar o status do matching:
        *   Verde sólido se o status for `matched` (Confirmado).
        *   Laranja tracejado se o status for `suggested` (Sugerido/IA).
        *   Vermelho/Cinza com um ícone de corte se o status for `ignored`.

### 3. Histórico de Logs de Processamento em Tempo Real (Loader)
*   **Substituição do Loader Genérico:**
    *   A análise de PDF com IA pode levar até 45 segundos. Em vez de exibir um spinner estático, o `AnalysisLoadingView` deve mostrar mensagens de progresso reativas.
    *   O endpoint ou a Cloud Function de análise deve retornar um fluxo de progresso (utilizando SSE ou salvando logs parciais de status no Firestore do workspace, ex: `workspaces/{wid}/uploads/{uploadId}`).
    *   **Estados de Progresso a Exibir:**
        *   `[Fase 1/4]` 📄 Lendo o arquivo do extrato...
        *   `[Fase 2/4]` 🔍 Extraindo transações e valores por IA...
        *   `[Fase 3/4]` 🧠 Buscando parcelas e projeções no sistema...
        *   `[Fase 4/4]` ⚡ Preparando sugestões de conciliação...

### 4. Confirmação em Lote (Bulk Confirm)
*   **Botão "Confirmar Sugestões de Alta Confiança":**
    *   Se a lista de correspondências retornar mais de 3 itens marcados como `suggested` com alto grau de confiança matemática, adicionar um botão de atalho proeminente no topo da listagem: **"Confirmar todos os matches sugeridos ($X)"**.
    *   Ao clicar, alterar o status de todos esses matches sugeridos de uma vez para `matched` e navegar para o resumo de confirmação final, poupando tempo de cliques individuais para o usuário.

### 5. Correção de Defeitos Técnicos Existentes
*   **Desassociação de Lançamentos:**
    *   Implementar a possibilidade de "Desvincular" (Unlink) uma transação do extrato de uma parcela do sistema. Se um item estiver associado (manualmente ou via match sugerido), exibir o botão "Desvincular". Ao clicar, limpar o vínculo de `systemInstallment`, redefinindo o status do match para `unmatched`.
*   **Controle de Fluxo em Transferências (Source vs. Target):**
    *   Corrigir o cadastro de transferências originadas na conciliação. Em vez de registrar a conta de conciliação ativa (`accountId`) sempre como `source` (origem), a lógica deve alternar com base no tipo da transação do documento:
        *   **Transações de Débito (Saída / Valor Negativo):** A conta ativa é definida como `source` (origem), forçando o usuário a selecionar a conta `target` (destino).
        *   **Transações de Crédito (Entrada / Valor Positivo):** A conta ativa é definida como `target` (destino), forçando o usuário a selecionar a conta `source` (origem).
*   **Mapeamento de Nomes de Categoria Sugeridos pela IA:**
    *   As categorias sugeridas pelo motor de IA no backend devem ser comparadas contra a lista real de categorias locais do workspace pelo nome (comparação insensível a maiúsculas/minúsculas e acentos). Se houver correspondência, o ID e o objeto da categoria real do workspace devem substituir a sugestão genérica da IA para evitar a criação de lançamentos com categorias inexistentes ou inválidas.
*   **Prevenção de Dupla Associação de Parcelas Locais:**
    *   Na ação de vincular manualmente uma parcela (`installment`), caso essa parcela já esteja previamente associada a outra transação do extrato na sessão de conciliação corrente, o sistema deve desassociá-la da transação anterior antes de vinculá-la à nova, garantindo consistência de um único vínculo (relação 1:1).
*   **Ciclo de Vida de Lançamentos Órfãos (Apenas no Sistema):**
    *   Se uma parcela local for listada inicialmente como "Apenas no Sistema" (órfã / existe no sistema e não consta no extrato) e o usuário vinculá-la manualmente a alguma transação do extrato, o sistema deve removê-la da lista de itens avulsos ("Apenas no Sistema"), exibindo-a apenas como o item vinculado na transação do extrato.
    *   Caso o usuário desvincule (Unlink) essa parcela posteriormente, ela deve retornar imediatamente para a lista de itens órfãos com o status "Apenas no Sistema".

---

## 🔍 Critérios de Aceitação
*   [ ] O arraste de arquivos no desktop funciona em Mac/Windows/Web e filtra apenas as extensões configuradas (`.pdf`, `.ofx`, `.png`, `.jpg`, `.jpeg`).
*   [ ] As linhas de conexão entre transações e parcelas alinham-se dinamicamente na vertical caso a lista de itens sofra scroll.
*   [ ] O usuário consegue concluir a conciliação em menos de 3 cliques caso utilize o botão de confirmação em lote.
*   [ ] Ao clicar em "Desvincular", a transação do extrato perde imediatamente o vínculo visual e retorna para o estado de pendência (`unmatched`).
*   [ ] Transferências criadas a partir de receitas no extrato (valores positivos) são corretamente debitadas da conta de origem selecionada e creditadas na conta ativa de conciliação.
*   [ ] A associação manual de uma parcela que já estava vinculada a outro item remove o vínculo antigo automaticamente sem duplicidade.
*   [ ] Categorias sugeridas pela IA contendo nomes idênticos ou muito próximos de categorias locais são substituídas pelos dados de ID locais corretos.
*   [ ] Parcelas listadas como "Apenas no Sistema" desaparecem da lista de órfãos ao serem vinculadas a um item do extrato e reaparecem na lista caso sejam desvinculadas.
