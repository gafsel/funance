# Especificações Técnicas de Melhorias (Funances)

Este diretório contém as especificações técnicas detalhadas das demandas de melhorias para as principais features do **Funances**. Estas especificações foram estruturadas para serem executadas de forma independente por agentes de IA ou engenheiros de software.

## 📂 Estrutura de Especificações

Cada arquivo define o escopo, requisitos de UI/UX, alterações de dados e plano de verificação para uma feature específica:

1. 🧠 **[coaching_spec.md](file:///Users/gabrielsilva/work/benavlabs/funances/.spec/coaching_spec.md)**
   * Melhorias na feature de Inteligência Financeira e Insights.
   * Foco: CTAs contextualizados nos slides e biblioteca/histórico de insights passados.

2. 🎯 **[goals_spec.md](file:///Users/gabrielsilva/work/benavlabs/funances/.spec/goals_spec.md)**
   * Evolução da feature de metas financeiras.
   * Foco: Linha de tempo de progresso histórico e análise de viabilidade com IA.

3. 🎮 **[missions_spec.md](file:///Users/gabrielsilva/work/benavlabs/funances/.spec/missions_spec.md)**
   * Aprimoramento da gamificação do app.
   * Foco: Sistema de XP, níveis de perfil, novas missões comportamentais e badges de conquistas.

4. 🔄 **[reconciliation_spec.md](file:///Users/gabrielsilva/work/benavlabs/funances/.spec/reconciliation_spec.md)**
   * Otimização da conciliação bancária por OFX/PDF.
   * Foco: Arrastar e soltar (Drag & Drop), conexões visuais de matching, confirmação em lote (bulk confirm) e logs de progresso da análise.

---

## 🚀 Como Executar

Para iniciar a execução de uma especificação, o agente de desenvolvimento deve:
1. Ler o arquivo de especificação correspondente na pasta `.spec/`.
2. Criar ou atualizar o plano de tarefas no arquivo `task.md` na raiz do workspace.
3. Executar as modificações de banco de dados, Cloud Functions e telas de UI necessárias.
4. Validar as alterações com testes locais.
