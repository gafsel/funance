# Etapa 7: virada (preparada, não executada)

Nada desta etapa foi feito. Ela muda onde os seus dados de verdade passam a
viver, e o plano condiciona a virada a dois critérios que só você cumpre: a
conferência final fechar e uma semana de uso do app novo sem voltar ao antigo.

## Antes de marcar a data

1. **Usar o app novo no ambiente de testes** (https://funances2-testes.web.app)
   com os dados migrados. O que aparecer de errado volta para as etapas 3 a 6.
2. **Ligar o login com Google em `funances2-testes`**: no console do Firebase,
   em Authentication, ativar o provedor Google (o console cria o cliente OAuth).
   Três dos quatro usuários entram por ele.
3. **Decidir sobre os defeitos que a conferência achou no banco antigo**
   (`etapa-2-modelo-motor-migracao.md`): a fatura com valor a mais, o
   lançamento datado de 2036 e as metas sem categoria.
4. **Registrar Android, iOS e macOS** no projeto novo e gerar os arquivos de
   configuração, se o app novo for para o celular na virada.

## No dia

| Passo | Comando ou ação |
|---|---|
| 1. Criar o projeto de produção `funances2` | Console; a primeira publicação tem de ser feita por um dono |
| 2. Publicar regras, índices e funções nele | `deploy-producao.yml` (a criar, igual ao de testes, com aprovação manual) |
| 3. Guardar a chave do Gemini no projeto | `firebase functions:secrets:set GEMINI_API_KEY --project funances2` |
| 4. Parar de usar o app antigo | A partir daqui, nada novo é lançado nele |
| 5. Copiar os usuários | `node lib/scripts/migrar_usuarios.js --origem=funance-cef1b --destino=funances2 --aplicar` |
| 6. Simular a migração | `node lib/scripts/migrar_funances2.js --origem=funance-cef1b --todos` e ler os relatórios |
| 7. Carregar | o mesmo comando com `--destino=funances2 --workspace=<id> --aplicar --espera=30`, para cada workspace em uso |
| 8. Conferir | `node lib/scripts/reconstruir_espaco.js --project=funances2 --todos` deve dar zero divergências |
| 9. Publicar o app novo apontando para produção | build com `AMBIENTE=producao` (a criar em `lib/firebase_ambiente.dart`) |

## Volta atrás

O projeto antigo não é alterado em nenhum passo. Se algo der errado, o app
antigo volta a ser usado. O que tiver sido lançado no app novo nesse intervalo
precisa ser relançado; por isso a semana de observação deve ser combinada
antes.

## Limpeza, depois da semana de observação

- Tirar do código o app antigo (`lib/features`, `lib/core`) e as funções
  antigas (`functions/src/features/{finance,goal,coaching,health,workspace}`),
  que hoje continuam publicadas no projeto de testes.
- Apagar os espaços de teste que não forem mais úteis.
