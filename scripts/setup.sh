#!/usr/bin/env bash
# =============================================================================
#  setup.sh — installation en une commande (Linux / macOS / WSL)
#  Vérifie les prérequis, lance les services Docker, installe l'API,
#  applique la base de données via Prisma. Ne touche jamais aux données existantes.
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."

say()  { printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m✔ %s\033[0m\n' "$*"; }
fail() { printf '\033[1;31m✘ %s\033[0m\n' "$*" >&2; exit 1; }

# ── 1. Prérequis ────────────────────────────────────────────────────────────
say "Vérification des prérequis"
command -v docker >/dev/null 2>&1 || fail "Docker absent — installez Docker Desktop: https://www.docker.com/products/docker-desktop/"
docker compose version >/dev/null 2>&1 || fail "Docker Compose v2 requis (livré avec Docker Desktop récent)."
command -v node    >/dev/null 2>&1 || fail "Node.js 20+ absent — https://nodejs.org/"
command -v npm    >/dev/null 2>&1 || fail "npm absent (installé avec Node)."
command -v git    >/dev/null 2>&1 || echo "  git non trouvé (optionnel)."
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
[ "$NODE_MAJOR" -ge 20 ] || fail "Node 20+ requis (vous avez $(node -v))."
flutter --version >/dev/null 2>&1 || echo "  Flutter non trouvé — requis plus tard pour apps/app (https://docs.flutter.dev)."
ok "Prérequis OK (Node $(node -v))"

# ── 2. Fichiers d'environnement ────────────────────────────────────────────
say "Fichiers .env"
[ -f .env ] || { cp .env.example .env; ok ".env créé depuis l'exemple"; }
[ -f apps/api/.env ] || { cp apps/api/.env.example apps/api/.env; ok "apps/api/.env créé"; }

# ── 2 bis. Config Garage (secrets aléatoires, une seule fois) ─────────────
say "Config Garage (docker/garage.toml)"
if [ ! -f docker/garage.toml ]; then
  RPC_SECRET="$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')"
  ADMIN_TOKEN="$(openssl rand -base64 32 2>/dev/null | tr -d '/+=' || echo "dev_admin_token_$RANDOM$RANDOM")"
  METRICS_TOKEN="$(openssl rand -base64 32 2>/dev/null | tr -d '/+=' || echo "dev_metrics_token_$RANDOM$RANDOM")"
  sed -e "s|0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef|$RPC_SECRET|" \
      -e "s|dev_admin_token_0000000000000000|$ADMIN_TOKEN|" \
      -e "s|dev_metrics_token_00000000000000|$METRICS_TOKEN|" \
      docker/garage.toml.example > docker/garage.toml
  ok "docker/garage.toml généré (secrets aléatoires)"
else
  echo "  docker/garage.toml déjà présent (inchangé)"
fi

# ── 3. Services Docker ─────────────────────────────────────────────────────
say "Démarrage des services (PostgreSQL, Redis, Garage, MailPit)"
docker compose up -d
say "Attente de santé des services"
for i in $(seq 1 30); do
  if [ "$(docker compose ps --status healthy -q | wc -l)" -ge 3 ]; then break; fi
  sleep 2
done
docker compose ps
ok "Services prêts"

# ── 4. API : dépendances + Prisma ──────────────────────────────────────────
say "Installation de l'API (npm install)"
cd apps/api
[ -d node_modules ] || npm install --no-audit --no-fund
say "Génération du client Prisma"
npx prisma generate
say "Application du schéma à la base (migration initiale)"
npx prisma migrate dev

# ── 5. Test de santé ───────────────────────────────────────────────────────
say "L'API peut maintenant être démarrée :"
echo "  cd apps/api && npm run start:dev"
echo "  → santé : http://localhost:3000/health"
echo "  → Swagger : http://localhost:3000/docs"
echo ""
echo "Flutter (nouveau terminal) :"
echo "  cd apps/app && flutter create . --platforms android,windows && flutter run"
ok "Installation terminée ✔"
