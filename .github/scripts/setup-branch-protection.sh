#!/usr/bin/env bash
# Configura proteção das branches main e develop via GitHub API.
# Execute como owner do repositório:
#
#   GITHUB_TOKEN=ghp_... bash .github/scripts/setup-branch-protection.sh
#
# O token precisa ter permissão de Admin no repositório.

set -euo pipefail

OWNER="GUSTAVOHOOO"
REPO="ProjetoIntegrador2"
API="https://api.github.com/repos/${OWNER}/${REPO}/branches"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "❌  Defina a variável GITHUB_TOKEN antes de rodar este script."
  exit 1
fi

AUTH_HEADER="Authorization: Bearer ${GITHUB_TOKEN}"
ACCEPT_HEADER="Accept: application/vnd.github+json"

# ── Função auxiliar ──────────────────────────────────────────────────────────
protect() {
  local branch="$1"
  local payload="$2"
  echo "→ Protegendo branch '${branch}'..."
  http_code=$(curl -s -o /tmp/bp_response.json -w "%{http_code}" \
    -X PUT \
    -H "${AUTH_HEADER}" \
    -H "${ACCEPT_HEADER}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -d "${payload}" \
    "${API}/${branch}/protection")

  if [[ "${http_code}" == "200" ]]; then
    echo "   ✅  Branch '${branch}' protegida com sucesso."
  else
    echo "   ❌  Erro (HTTP ${http_code}):"
    cat /tmp/bp_response.json
    exit 1
  fi
}

# ── main: PR obrigatório + 1 aprovação + CI verde ────────────────────────────
protect "main" '{
  "required_status_checks": {
    "strict": true,
    "contexts": ["TypeScript", "Lint", "Tests"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}'

# ── develop: PR obrigatório + 1 aprovação + CI verde ─────────────────────────
protect "develop" '{
  "required_status_checks": {
    "strict": true,
    "contexts": ["TypeScript", "Lint", "Tests"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}'

echo ""
echo "✅  Proteção configurada para 'main' e 'develop'."
echo "   Nenhum membro pode fazer push direto — somente via PR com 1 aprovação + CI verde."
