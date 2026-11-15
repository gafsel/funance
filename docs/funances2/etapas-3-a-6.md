# Etapas 3 a 6: o app novo

Estado em 15/11/2026: construído e publicado no ambiente de testes
(`funances2-testes`). O app novo mora em `lib/novo/` e é o que sobe quando o
build é feito com `AMBIENTE=testes`; o app atual continua sendo o padrão
(`AMBIENTE=legado`) e não foi alterado.

## O que cada etapa entregou

| Etapa | Entrega | Onde |
|---|---|---|
| 3. Lançar | Identidade nova; Início com o livre para gastar; lançar por texto (uma linha por lançamento), modo avançado, parcelado e recorrente; cartão e fatura; desfazer em tudo | `lib/novo/telas/{inicio,lancar,formulario,detalhe,fatura,lancamentos}.dart`, `lib/novo/regras/{leitura_frase,montar,livre}.dart` |
| 4. Consolidar | Importar OFX, CSV e células coladas; caixa de entrada; regras de classificação; edição direto na grade da web; fechamento do mês | `lib/novo/telas/{entrada,fechamento}.dart`, `lib/novo/regras/importar.dart` |
| 5. Metas e caminho | Começo em quatro perguntas; caminho com cinco degraus; metas com conta ligada; mês apertado; revisão da semana; limites por categoria | `lib/novo/telas/{comeco,metas,revisao,categorias}.dart`, `lib/novo/regras/{caminho,metas}.dart` |
| 6. Empresa | Caixa previsto; a pagar e a receber por prazo; clientes e fornecedores; cobrança; resultado por centro de custo; pró-labore ligado | `lib/novo/telas/empresa.dart`, `lib/novo/regras/empresa.dart` |

No servidor (`functions/src/features/nucleo/`): `interpretarFrase` (segunda
camada da leitura, pela IA), `estenderSeries` (gera os previstos das séries
recorrentes), `criarEspaco` e os dois gatilhos do motor.

## Acabamento e usabilidade (15/11/2026)

Depois do primeiro uso pelo dono:

- **Visual refeito conforme o protótipo**: tokens, barra do topo, menu lateral
  na web, barra inferior com o botão de lançar no centro, cartões e botões
  compactos (`lib/novo/tema/`, `lib/novo/telas/pecas.dart`, `casca.dart`).
- **Titularidade**: cada conta mostra o logo do banco com a foto (ou as
  iniciais) do titular. O seletor de contas traz as usadas há pouco, depois
  as de quem está lançando agrupadas por banco, depois as conjuntas e as dos
  outros. Só membro do espaço pode ser titular; nome e foto ficam no vínculo
  (`membros/{uid}`).
- **Conta citada no texto** (`regras/contas_na_frase.dart`): entende "meu
  nubank", "nubank da Bárbara", "cartão de crédito nubank", "na conjunta" e o
  apelido da conta. O banco sozinho é a conta, não o cartão. Se não der para
  decidir, a conta fica em aberto e a tela pergunta.
- **Detalhe de conta** (`telas/conta.dart`): extrato com saldo corrido,
  lançar e importar já na conta, itens da caixa de entrada daquela conta e o
  ponto de conferência ("conferida até o dia X").
- **Detalhe de meta** (`telas/meta.dart`) e **Relatórios**
  (`telas/relatorios.dart`), que leem só os resumos mensais.
- **Categorias com ícone e cor**, as mesmas nas listas e nos gráficos.
- **Folhas** no lugar de diálogos; tela de entrada nova; terceira coluna em
  telas largas.
- **Leituras limitadas**: agendados até 60 dias à frente (antes, todos os
  meses), últimos 150 lançamentos para o aprendizado (antes, o mês anterior
  inteiro) e caixa de entrada com teto de 200. O mês exibido continua sendo
  lido inteiro, porque o livre para gastar e os saldos dependem dele; a lista
  só desenha 60 linhas por vez.

## Como foi verificado

- Testes automatizados: regras do app novo (`test/novo/`), servidor
  (`functions/src/test/nucleo_*`, integração e rules).
- Uso real das telas contra emuladores locais, com dados de exemplo: entrar,
  lançar por texto, desfazer, lista na web e no celular, importar, confirmar,
  fechamento, começo guiado, caminho, tela da empresa e cobrança.
- Gatilhos publicados em `funances2-testes`: conferidos com um espaço de
  rascunho, apagado em seguida.

### Rodar localmente, sem tocar em nenhum projeto real

```bash
scripts/emuladores.sh
```

```bash
cd functions && npm run build && FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 node lib/scripts/semear_emulador.js
```

```bash
flutter run -d chrome --dart-define=AMBIENTE=testes --dart-define=EMULADORES=true
```

O usuário e a senha de teste do emulador estão em
`functions/src/scripts/semear_emulador.ts`.

## O que NÃO foi verificado

- **Login com os usuários reais em `funances2-testes`.** Os quatro usuários
  foram copiados com os mesmos ids; entrar com senha deve funcionar, mas
  ninguém entrou ainda. O login com Google está desligado nesse projeto: ligar
  exige criar o cliente OAuth no console (ver etapa 7).
- **O app novo com os dados reais migrados.** As telas foram exercitadas com
  dados de exemplo. O espaço pessoal real tem 2.068 lançamentos, 17 contas e
  93 faturas; desempenho e leitura com esse volume não foram observados.
- **`interpretarFrase` com a IA de verdade.** A validação da resposta é
  testada; a chamada ao Gemini não foi exercitada.
- **Android, iOS e macOS.** O projeto novo só tem a web registrada.
- **Copiar a mensagem de cobrança**: o navegador de teste negou a área de
  transferência. O app trata a negação e pede para selecionar o texto.
- **Pró-labore ligado**, de ponta a ponta na tela.

## Diferenças em relação ao plano e ao protótipo

- O protótipo tinha um passeio guiado de 21 passos; o app tem os avisos do
  Início e o caminho, sem passeio.
- Foto e PDF de extrato não entram na importação (só OFX, CSV e texto colado).
  O leitor de notificações do Android ainda não alimenta a caixa de entrada
  nova.
- A grade da web edita descrição e categoria na linha; valor, data e conta
  são editados pelo formulário.
- Fechar o mês registra a conferência, mas não impede editar lançamentos de
  um mês fechado.
- Convidar outra pessoa para um espaço ainda não existe no app novo (os
  membros migrados continuam valendo).
- O caminho usa critérios simples, calculados na hora; nenhum degrau é
  "gravado como concluído".
