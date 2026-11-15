# Etapa 1: como o CI passa a publicar no projeto novo

Estado em 14/11/2026: aplicado. O push no `main` verifica e publica Hosting,
Functions, rules e índices em `funances2-testes` (rodada 43656380100, toda
verde). A seção "Como está hoje" descreve o estado anterior.

O que existe no projeto de testes:

- Firestore e Storage em `southamerica-east1`; as 39 funções na mesma região
  (o servidor escolhe a região pelo projeto em
  `functions/src/core/config/region.ts`; o app, em `lib/firebase_ambiente.dart`);
- plano Blaze; `GEMINI_API_KEY` no gerenciador de segredos;
- conta de serviço `ci-deploy`, com a chave no segredo
  `FIREBASE_SERVICE_ACCOUNT` do ambiente `testes` do GitHub. Papéis que o
  deploy de fato exigiu: Firebase Hosting Admin, Cloud Functions Admin, Cloud
  Run Admin, Service Account User, Firebase Rules Admin, Cloud Datastore Index
  Admin, Artifact Registry Writer, Cloud Build Editor, Secret Manager Viewer,
  API Keys Viewer, Cloud Scheduler Admin, Firebase Storage Admin e Storage
  Admin.

O que aprendemos no caminho:

- a primeira publicação de um projeto novo tem de ser feita por um dono, uma
  vez: ela ativa APIs e configura as funções de segunda geração, coisas que a
  conta do CI não pode fazer. Vale para o projeto de produção na etapa 7;
- o Node.js 20 foi desativado nas Cloud Functions em 30/10/2026; o servidor e
  o CI estão em Node 22;
- o `firebase-tools` 15 exige Java 21;
- os testes de imagem só batem no macOS e ficam fora do CI (tag `golden`).

Ainda não existe: login configurado em `funances2-testes` (o app web
publicado abre e não entra), apps Android, iOS e macOS no projeto novo, e o
projeto e o workflow de produção (etapa 7).

Diferença em relação à proposta: o padrão de `AMBIENTE` num build local é
`legado`, e não `testes`, porque só o projeto antigo tem Android, iOS e macOS
registrados. O CI sempre passa `testes`.

## Como está hoje

- `.firebaserc` tem um único projeto, `funance-cef1b`, como `default`.
- `verify.yml` roda três jobs (Flutter, Functions, rules). Não muda.
- `firebase-hosting-merge.yml` publica em `funance-cef1b` a cada push no
  `main`: Hosting, Functions, rules e índices, com `--force`.
- `firebase-hosting-pull-request.yml` publica um preview do Hosting em
  `funance-cef1b` a cada PR.
- O GitHub tem o segredo `FIREBASE_SERVICE_ACCOUNT_FUNANCE_CEF1B` (criado em
  27/05/2026). O README registra que essa conta só tem papel de Hosting.
- No GitHub, o `main` só tem o commit inicial. Os 79 commits seguintes do
  `main` local e os 444 de `fix/fase-0` nunca foram enviados.

## Dois riscos que existem antes de qualquer mudança

1. **O primeiro push do `main` dispara publicação em produção.** O workflow
   atual publicaria em `funance-cef1b` na hora. O projeto atual deve ficar
   intacto como cópia de segurança, então a troca dos workflows precisa ir no
   mesmo push que leva `fix/fase-0` ao `main`, ou o segredo
   `FIREBASE_SERVICE_ACCOUNT_FUNANCE_CEF1B` precisa ser apagado antes.
2. **O repositório `gafsel/funance` é público e a chave do Gemini está no
   histórico** (commit `20d2fe2`, de 28/05/2026, ainda não enviado). Um push
   do histórico como está publica a chave. Ver "Ordem de aplicação".

## Proposta

### Projetos e apelidos

Dois projetos Firebase novos, um por ambiente, e o atual fora do caminho da
publicação. Os ids abaixo são sugestões; o id é definitivo depois de criado.

| Apelido no `.firebaserc` | Projeto | Papel |
|---|---|---|
| `testes` (e `default`) | `funances2-testes` | recebe toda publicação do CI |
| `producao` | `funances2` | só publica por disparo manual, a partir da etapa 7 |
| `legado` | `funance-cef1b` | cópia de segurança; o CI não publica nele |

```json
{
  "projects": {
    "default": "funances2-testes",
    "testes": "funances2-testes",
    "producao": "funances2",
    "legado": "funance-cef1b"
  }
}
```

Com `default` apontando para testes, um `firebase deploy` sem `--project`
nunca atinge produção nem o projeto antigo.

O projeto de produção pode ser criado só na etapa 7. Para a etapa 1 basta o
de testes.

### Workflows

| Arquivo | Quando roda | O que faz |
|---|---|---|
| `verify.yml` | chamado pelos outros | igual a hoje, com o build web recebendo o ambiente |
| `pull-request.yml` (renomeado) | PR | verify + preview do Hosting no projeto de testes |
| `deploy-testes.yml` (substitui `firebase-hosting-merge.yml`) | push no `main` | verify + publica Hosting, Functions, rules e índices em `testes` |
| `deploy-producao.yml` (novo) | manual (`workflow_dispatch`) | verify + publica em `producao`, com aprovação no ambiente `producao` do GitHub |

Mudanças concretas em relação ao `firebase-hosting-merge.yml` de hoje:

```yaml
# deploy-testes.yml
env:
  FIREBASE_PROJECT_ID: funances2-testes     # era funance-cef1b

jobs:
  verify:
    uses: ./.github/workflows/verify.yml
    with:
      ambiente: testes                      # novo parâmetro

  deploy_hosting:
    environment: testes                     # ambiente do GitHub guarda o segredo
    steps:
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: funances2-testes

  deploy_backend:
    environment: testes
    # mesmo passo de hoje, lendo secrets.FIREBASE_SERVICE_ACCOUNT
```

`deploy-producao.yml` é a mesma coisa com `on: workflow_dispatch`,
`environment: producao` e o id de produção. O ambiente `producao` do GitHub
fica com revisor obrigatório, então nada vai para produção sem um clique seu.

Nenhum workflow passa a citar `funance-cef1b`.

### Credenciais

- Uma conta de serviço por projeto, guardada como segredo
  `FIREBASE_SERVICE_ACCOUNT` dentro do ambiente do GitHub correspondente
  (`testes`, `producao`). O nome do segredo é o mesmo nos dois; o ambiente
  decide qual vale.
- Papéis da conta no projeto: Firebase Hosting Admin, Cloud Functions Admin,
  Service Account User, Firebase Rules Admin, Cloud Datastore Index Admin,
  Artifact Registry Writer, Cloud Build Editor (os mesmos que o README já
  lista) e Secret Manager Viewer, para o deploy conferir que
  `GEMINI_API_KEY` existe.
- O segredo antigo `FIREBASE_SERVICE_ACCOUNT_FUNANCE_CEF1B` é apagado do
  GitHub. Publicar no projeto antigo, se um dia for preciso, volta a ser
  manual.
- A chave do Gemini não vai para o GitHub. Cada projeto tem a sua no
  gerenciador de segredos (`firebase functions:secrets:set GEMINI_API_KEY`).

Alternativa sem arquivo de chave: federação de identidade (o GitHub se
autentica no Google sem segredo guardado). É mais segura e dá mais trabalho de
configurar. Sugiro começar com a conta de serviço e trocar depois.

### O app sabe para qual projeto apontar

Hoje `lib/firebase_options.dart` aponta fixo para `funance-cef1b`. Com um
código só para os três projetos:

- `flutterfire configure` gera um arquivo por ambiente
  (`firebase_options_testes.dart`, `firebase_options_producao.dart`; o atual
  vira `firebase_options_legado.dart`).
- O `main.dart` escolhe pelo parâmetro de build `AMBIENTE`, com `testes` como
  padrão.
- O CI compila a web com `flutter build web --release --dart-define=AMBIENTE=testes`.
- Android, iOS e macOS precisam do arquivo de configuração de cada projeto
  (`google-services.json`, `GoogleService-Info.plist`). Isso fica para o
  início da etapa 3, quando o app novo ganha tela; a etapa 1 só precisa da
  web e do servidor publicando.

### O que o ambiente de testes recebe

Os mesmos índices e as mesmas rules que produção, pelo mesmo comando. Isso
cobre o risco já registrado de consulta nova sem índice.

## Ordem de aplicação

1. Trocar a chave do Gemini (a atual passa a não valer nada).
2. Criar o projeto de testes, a conta de serviço e os ambientes no GitHub.
3. Aplicar esta proposta num commit sobre o ramo `ensaio/novo-main`.
4. Apagar o segredo `FIREBASE_SERVICE_ACCOUNT_FUNANCE_CEF1B` do GitHub.
5. Só então levar o ramo ao `main` e fazer o push.

## Decisões em aberto

- Ids dos projetos (sugestão: `funances2-testes` e `funances2`).
- Região do Firestore e das Functions no projeto novo. Não dá para mudar
  depois. O projeto atual usa a região padrão; para usuários no Brasil,
  `southamerica-east1` reduz a espera.
- Reescrever o histórico para tirar a chave antes do primeiro push, ou só
  trocar a chave e aceitar a antiga, já sem valor, no histórico público.
- Manter o repositório público ou torná-lo privado.
