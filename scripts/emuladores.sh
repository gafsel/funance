#!/usr/bin/env bash
# Sobe os emuladores do Firebase para desenvolvimento local do Funances 2.
# Usa o Node 22 (o mesmo do servidor) quando ele está instalado pelo nvm: o
# emulador de funções não carrega os gatilhos em versões mais novas.
set -euo pipefail
cd "$(dirname "$0")/.."
node22="$(ls -d "${NVM_DIR:-$HOME/.nvm}"/versions/node/v22.* 2>/dev/null | sort -V | tail -1 || true)"
if [ -n "$node22" ]; then
  export PATH="$node22/bin:$PATH"
fi
exec functions/node_modules/.bin/firebase emulators:start \
  --project demo-funances --only auth,firestore,functions "$@"
