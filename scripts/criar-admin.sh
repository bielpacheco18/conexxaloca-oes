#!/usr/bin/env bash
# Cria o usuário admin (Auth) e o autoriza na tabela public.admins.
# A chave SECRET fica só no seu terminal — nunca no código nem no GitHub.
#
# Uso:
#   export SUPABASE_URL="https://olbppjlcstlvhiwumsdg.supabase.co"
#   export SUPABASE_SECRET_KEY="sb_secret_..."      # Project Settings > API Keys
#   export ADMIN_EMAIL="voce@email.com"
#   read -rs -p "Senha do admin: " ADMIN_PASSWORD; export ADMIN_PASSWORD; echo
#   bash scripts/criar-admin.sh
set -euo pipefail
: "${SUPABASE_URL:?defina SUPABASE_URL}" "${SUPABASE_SECRET_KEY:?defina SUPABASE_SECRET_KEY}"
: "${ADMIN_EMAIL:?defina ADMIN_EMAIL}" "${ADMIN_PASSWORD:?defina ADMIN_PASSWORD}"
[ ${#ADMIN_PASSWORD} -ge 12 ] || { echo "Use uma senha com 12+ caracteres."; exit 1; }

json() { python3 -c 'import json,sys;print(json.dumps(dict(zip(sys.argv[1::2],sys.argv[2::2]))))' "$@"; }

echo "→ criando usuário no Auth…"
curl -fsS -X POST "$SUPABASE_URL/auth/v1/admin/users" \
  -H "apikey: $SUPABASE_SECRET_KEY" -H "Content-Type: application/json" \
  -d "$(python3 -c 'import json,os;print(json.dumps({"email":os.environ["ADMIN_EMAIL"],"password":os.environ["ADMIN_PASSWORD"],"email_confirm":True}))')" >/dev/null \
  && echo "  ok" || echo "  (usuário já existe ou falhou — seguindo)"

echo "→ autorizando como admin…"
curl -fsS -X POST "$SUPABASE_URL/rest/v1/admins" \
  -H "apikey: $SUPABASE_SECRET_KEY" -H "Content-Type: application/json" \
  -H "Prefer: resolution=ignore-duplicates,return=minimal" \
  -d "$(json email "$ADMIN_EMAIL")" && echo "  ok"
echo "Pronto. Entre em /gestao com $ADMIN_EMAIL"
