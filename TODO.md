# FUNANCE TODO

### Roadmap
1. [ ] Os cartões de crédito terão controle de frchamentos (mes/ano)
2. [ ] Ao cadastrar uma cobrança num cartão o sistema seleciona o fechamento automaticament com base na data do lançamento mas deve permirir que o usuário altere
3. [X] Na lista de cartões o sistema deve mostrar a próxima fatura (usar os fechamentos) e o toral usado do limite
4. [ ] Ao clicar numa meta o sistema deve mostrar o histórico de transações que contabilizam pra meta
5. [X] Planejamento por categoria
6. [X] Sugerir planejamento junto das metas no onboarding (não gerar planejamento no cadastro de account)
7. [X] Não associar account com planejamento
8. [ ] ~~Só trazer card de total quando houver mais de uma conta cadastrada~~
9. [ ] Adicionar informação de mês referencia nas transações feitas com cartão de crédito
10. [X] Usar mês referência como base para sumário de cartão => controle de faturas e não de resumo mensal
11. [X] Separar listagem de categorias de despesas e receitas
12. [X] Adicionar botão de nova categoria no fluxo de cadastro de transação
13. [X] Formatar campos monetários
14. [ ] Permitir modificar a categoria de uma transação

### Defeitos percebidos
1. [X] A análise de extrato está criando Categorias duplicadas
2. [X] O saldo e data inicial idenificados são os finais do extrato e não os iniciais

## PROBLEMAS E MELHORIAS

### Menu
- [X] seleção de empresa no menu lateral não funciona direito
  ```
  Quando o menu lateral está contraído a opção de trocar workspace não funciona e quando o menu lateral está expandido
  a opção de trocar workspace funciona mas fica com um contraste ruim, impossibilitando a leitura. 
  ```
- [X] feature de gestão de perfil
  ```
  O usuário deve ser capaz de editar seu nome, e-mail e foto de perfil.
  O avatar do usuário deve mostrar sua foto ou sua inicial, quando não tiver foto, com uma cor calculada/sortida com base em seu nome -> a lógica de sorteio deve gerar sempre a mesma cor para o mesmo nome.
  A implementação do formulário deve seguir o padrão de arquitetura já estabelecido em outros formulários.
  Um widget deve ser criado para mostrar o avatar do usuário
  ``` 

### Jornada
- [X] card do coach financeiro está ocupando muito espaço
```
    Para aprimorar a usabilidade, o card do coach financeiro deve ter dois comportamentos distintos:
    1. novo insight: nesse comportamento o card deve ser chamativo e grande com um CTA chamativo para que o usuário gere um novo insight, como o card faz hoje
    2. rever o último insight: nesse comportamento o card deve ser menor e mais discreteo (sem o background, aspenas as bordas) e um CTA mais discreto (talvez apenas o link) dando ao usuário a possibilidade de ver o insight novamente, mas indicando que o próximo estará disponível em breve.
```
- [X] permissão de notificações aparecendo em dispositivos que não tem compatibilidade
```
    Como o recurso de ler notificações e registrar transações automaticamente só é possível no Android, o card de solicitação de permissões deve aparecer apenas para Andorids.
```
- [X] apresentar uma mensagem de sucesso quando o usuário concluir as missões semanais
```
    Quando o usuário concluir as atividades o app deve mostrar um "empty state" de sucesso com uma ilustração e um texto de parabenização.
    Deve ser uma ilustração colorida, portanto, use múltiplos icons distribuídos de forma sortida e com uma leve animação.
```
- [X] Criar detalhe de missão para permitir visualizar histórico de progresso -> busca pela account relacionada? e gestão (editar/excluir)
```
    O clique nos goals deve levar para uma tela de detalhe. Nessa tela de detalhe, o usuário deve ser capaz de ver os dados gerais do goal (os mesmos que aparecem no card) num header (vide extrato e fatura)
    abaixo do header, o sistema deve listar as transações relacionadas ao goal -> para achar as transações, use o tipo do goal como base:
    - saveMoney, payDebt -> busque as transações da account associada ao goal (dentro do período do goal)
    - reduceExpense -> busque as transações da categoria associada ao goal (dentro do período do goal)
    - reduceCreditCard -> busque as faturas do account associado ao goal (dentro do período do goal)
    além disso, o usuário deve ser capaz de editar e excluir o goal atrabés dessa tela -> confirmação antes da exclusão, como é feito no transaction form
```
- [X] Equipe aparece como em Perigo mesmo quando o percentual é 97%?
```
    há uma falha na lógica de status no card da equipe. O status da equipe deve seguir o mesmo padrão dos cards de categorias.
```

### Visão Geral
- [ ] card de 50-30-20 está muito diferente do restante
- [ ] relatório de categorias está confuso

### Detalhe de extrato
- [X] opção de consolidação está muito discreta
- [X] header está sem graça
- [X] abas com contraste ruim
- [X] modal de filtros com contraste ruim
```
    padronizar as modais de filtro (history tab / detalhe de account) para que use o mesmo widget base, ocultando ou mostrando filtros com base em configuração.
    - extrair e usar o widget de filtros do history tab como base
    - os filtros disponíveis devem ser disponibilizados num enum e um atributo de ocultar fields pode ser recebido para esconder alguns dos filtros
    - trazer pra dentro do widget de filtros o componente de filtro de período do history tab (o history tab o oculta na modal) 
    - o widget deve englobar tanto o widget de tela (que mostra os filtros selecionados) quanto a modal que abre ao clicar no botão de filtros
```
- [X] busca de saldo parece estar errada (deveria pegar a mais próxima da data quando não encontrar a da data em si)
```
    a lógica de saldo não pode filtrar pela data exata. a lógica deve sempre pegar o último balance mais próximo da data. se existir o da data use-o, se não deve usar o mais recente próximo a data (query pela data até a alvo, order by id desc e limit 1)
```

### Detalhe de fatura
- [X] padronizar header com de extrato
- [X] gráfico de categorias está quebrando o layout quando há muitas categorias
- [X] opção de consolidação está muito discreta
- [X] padronizar opção de lançamento de pagamento junto da consolidação
- [X] mostrar status da fatura quando detalhar
```
    adicionar um chip no header do detalhe de fatura pra mostrar o status da fatura (status da transação)
```
- [X] permitir abrir a edição do lançamento mesmo após o pagamento
```
    enquanto estiver no status pendente o botão de editar a fatura deve ser de registrar o pagamento, mas
    depois do pagamento (paid/settled) o botão deve estar disponível também, mas com outro nome (editar).
    - o botão de editar atual que redireciona para a edição da conta deve ser removido
```
- [X] padronizar lista de lançamentos com detalhe de extrato

### Limites de Receitas/Despesas
- [ ] em telas pequenas o layout está quebrado

### Planejamento 50-30-20
- [ ] melhorar o design para ser visível o header dos pools
- [ ] rever usabilidade em telas pequenas já que não dá pra arrastar e solvar as categorias entre as pools

### Histórico/Extrato
- [ ] flexibilizar header em telas menores
- [ ] ajustar formatação de data no seletor de período
- [ ] organizar e melhorar card de totalizador

### Configurações
- [ ] Feature para editar nome/dados do workspace
- [ ] Feature de manter membros

### Gestão de Categorias
- [ ] ajustar nome do tipo da categoria (não precisa mostrar já que há divisão por aba)

### Gestão de Contas
- [ ] Não permitir editar saldos inicias (nem mostrar no formulário de edição, só no cadastro)
- [ ] Criar logos de bancos com cores automáticas
- [ ] Criar campo de titularidade -> para mostrar nas listagens

### Consolidação
- [ ] Ajustar formulário para usar padrão de infra
- [ ] cadastro de transferências está errado (associando sempre a target account)
- [ ] implementar validação para impedir encerrar a consolidação sem dar resposta para todos os itens da lista

