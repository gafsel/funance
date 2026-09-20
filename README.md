# Funances

Projeto de gestão financeira gamificado com foco em integridade contábil e escalabilidade. O Funances utiliza uma arquitetura moderna para oferecer uma experiência multi-tenant de workspaces, separando a intenção financeira da movimentação real de caixa.

## 🚀 Arquitetura e Tecnologias

O projeto segue princípios de **Clean Architecture** com **DDD (Domain-Driven Design)** e **Vertical Split**, garantindo que cada funcionalidade seja independente e fácil de manter.

### Frontend (Flutter)
- **Gerenciamento de Estado:** [Riverpod](https://riverpod.dev/) (Providers, Notifiers e AsyncNotifiers).
- **Arquitetura:** Vertical Split por features (`lib/features/`).
- **Injeção de Dependências:** Utilizando o sistema de Providers do Riverpod.
- **Internacionalização:** Suporte nativo via `flutter_localizations` (ARB files).
- **UI/UX:** Design responsivo e adaptável para Mobile, Tablet e Desktop.

### Backend (Firebase & Cloud Functions)
- **Runtime:** Node.js 20.
- **Linguagem:** TypeScript 5+.
- **Firebase Functions v2:** Utiliza a API de 2ª Geração para melhor escalabilidade (Cloud Run).
- **Cloud Firestore:** Banco de dados NoSQL estruturado em subcoleções para Multi-Tenancy.
- **Processamento Assíncrono:** Triggers de Firestore para automação de saldos, metas e sumários.
- **Scheduler:** Funções programadas para processamento de recorrências mensais.
- **Authentication:** Google Sign-In e E-mail/Senha integrados.
- **Cloud Storage:** Armazenamento de documentos e avatares com regras de acesso por workspace.
- **Security Rules:** Regras granulares por workspace e nível de acesso para Firestore e Storage.

---

## 📊 Modelo de Dados: CategoryPlanning-Order-Installment (v6.0)

A integridade dos dados é garantida pela separação entre **Planejamento**, **Intenção** e **Realidade**:

- **Category Planning (O Planejado):** Metas mensais por categoria (`category_plannings`).
- **Orders (A Intenção):** A matriz de um lançamento financeiro, definindo recorrência e regras (`orders`).
- **Installments (A Realidade):** Parcelas individuais vinculadas a uma Order, com ciclo de vida (pending, paid, etc) e impacto real no saldo (`installments`).
- **Accounts & Balances:** Controle de contas bancárias e cartões com saldos diários automatizados.
- **Period Summaries:** Consolidação de dados por período (Ano/Mês) e Categoria, unificando metas e realizado (`period_summaries`).
- **Goals (Metas):** Sistema de metas gamificadas vinculadas a contas e categorias.

Este modelo permite gerar um **Livro Diário** profissional e facilita a conciliação bancária futura.

---

## 🗺️ Roadmap & Progresso

Acompanhamento do desenvolvimento baseado nos requisitos do Blueprint e evoluções das sessões:

### R1: Foundation (Concluído ✅)
- [x] **Arquitetura Base:** Setup de Clean Architecture (DDD + Vertical Split).
- [x] **Multi-Tenancy:** Estrutura de Workspaces isolados no Firestore.
- [x] **Autenticação:** Google Sign-In e E-mail/Senha com persistência no Firestore.
- [x] **Onboarding:** Fluxo de boas-vindas e criação do primeiro workspace.
- [x] **Gestão de Convites:** Sistema de convites via e-mail com processamento no backend.
- [x] **Categorias:** Gestão de categorias com ícones, cores e padrões por tipo de workspace.
- [x] **Contas & Saldos:** CRUD de contas bancárias/cartões e controle de saldo inicial.

### R2: Inteligência Financeira & Core (Em Progresso 🏗️)
- [x] **Modelo Order-Ledger-Planning:** Separação entre Projeção (Planning), Intenção (Orders) e Realidade (Ledger).
- [x] **Automação de Saldos:** Atualização atômica de saldos diários via Cloud Functions.
- [x] **Gerenciamento de Metas (Goals):** Metas gamificadas com progresso automático.
- [x] **Dashboard:** Visão Geral com gráfico de pizza, totalizadores e navegação por período.
- [x] **Extrato (History):** Listagem paginada com scroll infinito e ações de swipe.
- [x] **Recorrências:** Processamento automático de transações mensais (Scheduler).
- [x] **Conciliação Bancária:** Parser de PDF/OFX com match inteligente (Próximo passo).
- [x] **Faturas de Cartão:** Fechamento automático e gestão de ciclos de fatura (Planejado).

### R3: Insights & Coaching (Planejado 🚀)
- [x] **Insights via LLM:** Análise de gastos e sugestões de economia usando Gemini.
- [x] **Projeções de Fluxo de Caixa:** Visão de competência para os próximos 12 meses.
- [ ] **Gamificação Avançada:** Sistema de conquistas, badges e pontuação por saúde financeira.

---

## 🏗️ Padrões de Código

O projeto preza pela **Tipagem Forte**, **Segurança de Dados** e **Redução de Boilerplate**:

### Padrão de Formulários (Riverpod State Management)
Adotamos o padrão de **Form Controllers** utilizando Riverpod para gerenciar a lógica de formulários, eliminando o uso manual de `TextEditingController` e `setState` dentro dos Widgets.

**Estrutura:**
1. **FormState:** Classe imutável que representa todos os campos, estados de carregamento e erro do formulário.
2. **FormNotifier:** Um `StateNotifier` que gerencia as mudanças de estado, validações e submissão dos dados.
3. **ConsumerWidget:** A UI "escuta" o estado do provider e reage de forma declarativa, utilizando `initialValue` e `onChanged` vinculados ao notifier.

Este padrão garante que a lógica de negócio esteja isolada da UI, facilitando testes unitários e mantendo os Widgets limpos e focados na renderização.

- **Enums:** Todos os status e tipos (Order, Ledger, Account, Workspace) são gerenciados via Enums tanto no Flutter quanto no Cloud Functions.
- **Resiliência:** Models possuem tratamento defensivo para dados nulos e conversão segura de Timestamps do Firestore.
- **IoC:** Inversão de Controle no backend para facilitar testes e manutenibilidade.

---

## 📂 Estrutura de Pastas

### Frontend (Flutter)
```
lib/
├── core/               # Componentes transversais (temas, exceptions, i18n)
└── features/
    ├── auth/           # Login social e e-mail/senha
    ├── finance/        # Gestão de Orders, Ledger Entries, Planning e Accounts
    ├── onboarding/     # Fluxo inicial para novos usuários
    ├── user/           # Perfil e gestão de usuários
    └── workspace/      # Multi-tenancy, membros, convites e categorias
```

### Backend (Cloud Functions)
```
functions/src/
├── core/               # Container IoC e interfaces globais
└── features/           # Lógica de negócio por domínio
    ├── finance/        # Motores de saldo, sumários e recorrências
    ├── goal/           # Automação de progresso de metas
    ├── user/           # Gestão e persistência de usuários
    └── workspace/      # Convites, categorias padrão e segurança
```

---

## 🛠️ Configuração de Desenvolvimento

### Pré-requisitos
- Flutter SDK (Canal Stable)
- Node.js (Para Cloud Functions)
- Firebase CLI

### Comandos Úteis

**Gerar modelos e mocks:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Gerar traduções:**
```bash
flutter gen-l10n
```

**Compilar e Validar Cloud Functions:**
```bash
cd functions
npm run lint    # Valida estilo e tipos
npm run build   # Compila TypeScript para JS
```

**Deploy de Cloud Functions:**
```bash
# Deploy completo
firebase deploy --only functions

# Deploy de uma função específica
firebase deploy --only functions:onOrderWritten
```

---

## 🧪 Testes e CI

### Rodando os testes das Cloud Functions

Pré-requisito: **Java 17+** (o emulador do Firestore é um JAR). O Firebase CLI
vem do devDependency `firebase-tools`, então um `npm ci` basta.

```bash
cd functions
npm ci

npm run test:unit         # testes com mocks manuais, sem emulador
npm run test:integration  # integração + rules no emulador do Firestore
npm run test:rules        # só as security rules
npm test                  # test:unit + test:integration
```

Os scripts com emulador usam `firebase emulators:exec --project demo-funances
--only firestore`. O prefixo `demo-` garante que o CLI trabalhe em modo
totalmente emulado — **nenhum teste toca o projeto real `funance-cef1b`**. O
setup em `src/test/integration/setup.ts` aborta se `FIRESTORE_EMULATOR_HOST`
não estiver definido, então rodar `jest` direto nesses testes falha de
propósito em vez de vazar escrita para produção. As portas ficam fixas em
`firebase.json` (Firestore 8080, Functions 5001).

Os testes de integração instanciam os repositórios reais (sem mocks) e
verificam documentos no formato de produção; os de rules rodam com
`@firebase/rules-unit-testing` contra `firebase/firestore.rules`.

### O que o CI verifica

`.github/workflows/verify.yml` é um workflow reutilizável com três jobs,
chamado tanto no pull request quanto no push para `main`:

| Job | O que roda |
|---|---|
| `flutter` | `pub get`, `gen-l10n`, `build_runner`, `analyze`, `test`, `build web` (Flutter pinado em 3.44.3 stable) |
| `functions` | Node 20 + Java 17, `npm ci`, `lint`, `build`, `npm test` |
| `rules` | Node 20 + Java 17, `npm ci`, `npm run test:rules` |

No PR, o preview do Hosting só publica depois que os três jobs passam. No push
para `main`, o deploy (Hosting, Functions, rules do Firestore e do Storage e
indexes) também só roda depois dos três verdes. O build web é feito uma única
vez e reaproveitado pelos jobs de deploy via artifact.

> `flutter analyze` roda com `--no-fatal-warnings --no-fatal-infos` enquanto
> houver warnings/infos pré-existentes no projeto. Remova os flags depois da
> limpeza do analyzer.

### Pendência: IAM do service account para o `deploy_backend`

O job `deploy_backend` reaproveita o secret `FIREBASE_SERVICE_ACCOUNT_FUNANCE_CEF1B`
como credencial do Firebase CLI. Esse service account foi criado pelo
`firebase init hosting:github` apenas com *Firebase Hosting Admin* e
*API Keys Viewer* — **ele ainda não consegue publicar Functions, rules nem
indexes**. Antes do primeiro deploy é preciso conceder a ele, no IAM do
projeto, os seis papéis:

- Cloud Functions Admin
- Service Account User
- Firebase Rules Admin
- Cloud Datastore Index Admin
- Artifact Registry Writer
- Cloud Build Editor

Alternativa, se preferir isolar as permissões: criar um service account
dedicado ao backend, gravá-lo num novo secret (ex.:
`FIREBASE_SERVICE_ACCOUNT_DEPLOY_BACKEND`) e trocar a referência em
`.github/workflows/firebase-hosting-merge.yml`.

Os secrets do Gemini usados via `defineSecret` continuam no Secret Manager do
projeto — não são configurados no GitHub.

---

## 📜 Blueprint v4.0 (Destaques)
- **Multi-Tenant:** Cada `Workspace` é um silo de dados isolado.
- **Parcelamento Inteligente:** Cloud Functions automatizam a criação de parcelas (`ledger_entries`) em tempo real.
- **Gestão de Convites:** Fluxo seguro para adicionar membros via e-mail com processamento no backend.

---

## 🍎 Notas Específicas (Apple Platforms)
Para rodar no **macOS/iOS** e evitar erros de Keychain:
1. Abra o projeto no Xcode.
2. Em **Signing & Capabilities**, selecione um **Development Team**.
3. Adicione a capability **Keychain Sharing**.

---

## 🏠 Decisões de produto da Home

A Home é a tela que se abre todo dia, e a decisão principal dela é a ORDEM.
Ela responde a uma pergunta só — "o que eu preciso saber agora?" — e o teto
de altura é de **duas rolagens com dados típicos**, medido em
`test/home_height_test.dart`.

1. a conquista do momento (chega por cima, no `CelebrationHost`);
2. quanto sobra no mês;
3. o que vence hoje e amanhã;
4. as pendências do leitor de notificação;
5. as missões da semana, em resumo e com um botão só;
6. **o empurrão: o coaching, em uma linha**;
7. a linha da Bússola;
8. uma meta em destaque.

### "Gasto fora do plano" NÃO é bloco de Home

O nudge de gasto fora do plano fica onde já está: na **folha que aparece
depois do lançamento**. Ele é uma reação a uma decisão que a pessoa acabou de
tomar, e é ali — com o valor ainda na tela e o dedo ainda no aparelho — que
ele pode virar uma correção. Repetido na Home, no dia seguinte, ele vira um
boletim sobre algo que já passou.

O slot 6 da Home fica com o **coaching em uma linha**, que é o empurrão que
olha para frente.

### O que NÃO mora na Home

- a lista completa de metas → `/goals` (na Home fica a de prazo mais curto);
- a semana de missões, com cartões, XP e checklist → `/missions`;
- a Bússola completa → a folha que abre pela linha;
- a Party → a Visão Geral, ao lado da distribuição 50-30-20;
- "como ganhar XP" → a vitrine de emblemas.
