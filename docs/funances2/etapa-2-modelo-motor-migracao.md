# Etapa 2: modelo, motor e migração

Estado em 14/11/2026: código e testes prontos no ramo
`etapa-2/modelo-motor-migracao`. A **simulação** rodou com os dados reais e
fecha sem diferença sem explicação nos 5 workspaces (ver "Resultado da
simulação"). A **carga** em `funances2-testes` foi feita para os dois
workspaces em uso, por decisão do dono: o pessoal (2.068 lançamentos) e o da
empresa (551). Os outros três são de teste e não foram carregados. A reconstrução, rodada depois da carga, não achou
divergência.

## Onde está cada coisa

| O quê | Arquivo |
|---|---|
| Modelo de dados | `functions/src/features/nucleo/domain/models/modelo.ts` |
| Regras de saldo, fatura e resumo | `functions/src/features/nucleo/domain/services/contribuicoes.ts` |
| Motor (transação que aplica a diferença) | `functions/src/features/nucleo/domain/services/motor.service.ts` |
| Gatilhos | `functions/src/features/nucleo/presentation/functions/motor_handler.ts` |
| Reconstrução | `functions/src/features/nucleo/domain/services/reconstrucao.service.ts` |
| Progresso de meta | `functions/src/features/nucleo/domain/services/metas.ts` |
| Transformação antigo → novo | `functions/src/features/nucleo/migracao/transformar.ts` |
| Conferência e relatório | `functions/src/features/nucleo/migracao/conferir.ts` |
| Script de migração | `functions/src/scripts/migrar_funances2.ts` |
| Script de reconstrução | `functions/src/scripts/reconstruir_espaco.ts` |
| Rules do modelo novo | `firebase/firestore.rules`, bloco "Funances 2" |

## Decisões tomadas na construção

- **Raiz separada.** O modelo novo vive em `espacos/{id}`, não em
  `workspaces/{id}`. As 39 funções do app antigo continuam publicadas no
  projeto de testes e reagem a `workspaces/`; com raízes diferentes, uma não
  enxerga a gravação da outra.
- **Nomes do domínio em português** (`lancamentos`, `contas`, `faturas`), os
  mesmos do plano. O código antigo é em inglês; a diferença também ajuda a não
  confundir os dois modelos na migração.
- **O motor aplica a diferença, não o evento.** Ele lê o lançamento como está,
  lê o que já tinha aplicado dele (`aplicados/{chave}`) e grava só o que
  falta. Evento repetido ou fora de ordem não estraga o saldo.
- **O motor nunca grava num documento que o app grava.** Derivados ficam em
  documentos próprios: `contas/{id}/dias/{dia}`, `resumos/{mês}` e os totais
  de `faturas/{id}`.
- **Saldo é movimento por dia, sem acumulado gravado.** O saldo numa data é o
  saldo inicial mais os movimentos até ela (`saldoEm`). O app antigo regravava
  todos os dias seguintes a cada lançamento.
- **Progresso de meta e caixa previsto não são guardados.** São calculados na
  leitura a partir dos lançamentos. O plano dizia que o motor os atualizaria;
  calcular na hora elimina mais um derivado que poderia ficar errado.
- **A fatura que recebe uma compra** usa a regra do app antigo
  (`InvoiceService.calculateInvoiceDueDate`), para os totais baterem.
- **Dívida inicial do cartão** entra na fatura do ciclo em que foi informada,
  como no app antigo.
- **Pagar a fatura com valor diferente** deixa de jogar a diferença na fatura
  seguinte: cada fatura guarda total e pago. A conferência reconhece e explica
  essa diferença.

## O que a verificação do cartão mostrou

O app antigo já contabiliza a compra no cartão no mês da compra
(`summary.service.ts`, pelo `paidDate`). A migração não muda os totais mensais
por categoria por esse motivo.

## O que a migração faz com cada caso

| Caso | Tratamento |
|---|---|
| Parcela | Lançamento com o mesmo id; previsto e realizado separados |
| Parcela `removed` | Lançamento cancelado |
| Parcela de saldo inicial | Vira campo da conta |
| Fatura em aberto | Entidade `faturas`, com a janela gravada |
| Fatura paga | Transferência que paga a fatura (`pagaFaturaId`) |
| Order parcelada ou recorrente | Série |
| Categoria sem id | Casa por nome e tipo; se não houver, cria `mig-<nome>-<tipo>` e avisa |
| Categoria apagada ainda citada | Recriada como arquivada, com aviso |
| Categorias de mesmo nome e tipo | Mantidas separadas, com aviso |
| Planejamento por categoria | Limite mensal, do planejamento que cobre o mês atual |
| Transação automática pendente | Caixa de entrada |
| Conciliação | Histórico em `fechamentos` |
| Lançamento com contas fora do esperado, conta inexistente ou valor negativo | **Fica de fora** e aparece em "Problemas", com o valor |

## Como rodar

Simulação: lê o projeto antigo, não grava em banco nenhum e escreve um
relatório por workspace em `functions/relatorios-migracao/` (fora do git, pois
contém dados reais).

```bash
cd functions && npm run build
node lib/scripts/migrar_funances2.js --origem=funance-cef1b --todos
```

Carga no projeto de testes, depois que o relatório estiver limpo:

```bash
node lib/scripts/migrar_funances2.js --origem=funance-cef1b \
  --destino=funances2-testes --todos --aplicar
```

A carga apaga e recria `espacos/{id}` no destino, reconstrói os derivados e
confere que fecharam. Ela recusa: gravar em `funance-cef1b`, usar o mesmo
projeto como origem e destino, sobrescrever um espaço que não veio da
migração, e carregar um workspace com problema ou diferença sem explicação
(a menos de `--mesmo-com-diferencas`).

## Resultado da simulação (14/11/2026)

Cinco workspaces, 2.666 lançamentos no total; nenhum ficou de fora. No maior
(2.068 lançamentos, 17 contas, 93 faturas):

| Comparação | Comparados | Iguais | Explicadas | Sem explicação |
|---|---:|---:|---:|---:|
| Saldo final por conta, refeito das parcelas | 17 | 17 | 0 | 0 |
| Saldo por conta e dia, gravado | 734 | 708 | 26 | 0 |
| Total por categoria e mês | 1010 | 985 | 25 | 0 |
| Total de cada fatura | 93 | 77 | 16 | 0 |
| Quantidade por conta e mês | 192 | 192 | 0 | 0 |
| Progresso das metas em aberto | 1 | 1 | 0 | 0 |

O que as diferenças explicadas revelaram sobre o banco antigo:

- **Saldos futuros de cartão desatualizados (26 dias).** O acumulado gravado
  em datas futuras contradiz os movimentos gravados pelo próprio app antigo.
  O modelo novo dá a soma dos movimentos.
- **Faturas com 1 ou 2 centavos a menos (3)**, resto de quando os valores eram
  guardados com casas decimais.
- **Uma fatura com valor a mais**: o
  total gravado não bate com as compras pagas do ciclo. Provável compra
  removida sem estorno na fatura.
- **Um lançamento datado de 2036**, com
  fatura duplicada no app antigo. Foi migrado como está e avisado; parece erro
  de digitação do ano.
- **Três metas de reduzir gasto sem categoria**, que nunca mediram nada.
  Migram com progresso zero e aviso.

Cada relatório lista as diferenças explicadas item a item.

## O que falta nesta etapa

1. (feito) Carregar no projeto de testes os dois workspaces em uso.
2. Usuários do login: exportar do projeto antigo e importar no novo com os
   mesmos ids. O login ainda não está configurado em `funances2-testes`.
3. Publicar os dois gatilhos novos (vão no próximo push do `main`).
4. Desligar as funções do app antigo no projeto de testes, quando o app novo
   começar a ter tela (etapa 3).

## Limites conhecidos

- Mudar o dia de fechamento ou de vencimento de um cartão não move as compras
  antigas na hora; uma compra antiga editada depois da mudança passa a usar a
  regra nova. A reconstrução recalcula tudo pela regra atual.
- A geração mensal dos lançamentos de uma série recorrente ainda não existe no
  modelo novo; entra com os agendados, na etapa 3.
- A regra de "saldo na data de início" das metas de quitar dívida foi
  reproduzida pela leitura do código antigo; só a conferência com dados reais
  confirma.
