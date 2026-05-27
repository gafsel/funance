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
- **Security Rules:** Regras granulares por workspace e nível de acesso.

---

## 📊 Modelo de Dados: "Order-Ledger-Planning" (v5.0)

A integridade dos dados é garantida pela separação entre **Planejamento**, **Intenção** e **Realidade**:

- **Planning (O Futuro):** Projeções mensais únicas, parceladas ou recorrentes por categoria.
- **Orders (As "Virtuais"):** Compromissos assumidos, contratos ou compras parceladas em andamento.
- **Ledger Entries (As "Físicas"):** Movimentações contábeis reais (débitos/créditos) efetivadas no caixa.
- **Accounts & Balances:** Controle de contas bancárias e cartões com saldos diários automatizados e suporte a saldo inicial.
- **Summaries:** Agregadores mensais por categoria e planejamento que permitem dashboards em tempo real.
- **Goals (Metas):** Sistema de metas gamificadas vinculadas a contas e categorias com cálculo de progresso dinâmico.

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
- [ ] **Conciliação Bancária:** Parser de PDF/OFX com match inteligente (Próximo passo).
- [ ] **Faturas de Cartão:** Fechamento automático e gestão de ciclos de fatura (Planejado).

### R3: Insights & Coaching (Planejado 🚀)
- [ ] **Insights via LLM:** Análise de gastos e sugestões de economia usando Gemini.
- [ ] **Projeções de Fluxo de Caixa:** Visão de competência para os próximos 12 meses.
- [ ] **Gamificação Avançada:** Sistema de conquistas, badges e pontuação por saúde financeira.

---

## 🏗️ Padrões de Código

O projeto preza pela **Tipagem Forte** e **Segurança de Dados**:

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
