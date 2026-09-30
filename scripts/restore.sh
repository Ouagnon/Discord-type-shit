#!/usr/bin/env bash
# =============================================================================
#  restore.sh — restauration d'une sauvegarde (EXERCICE MENSUEL recommandé, ch. 13)
#  Usage : ./scripts/restore.sh backups/pg_2026-01-31_0400.sql.gz [backups/garage_XXXX.tar]
#  ⚠ Ne lancez JAMAIS ceci sans vérifier le fichier : le restore écrase la base.
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."

PG_FILE="${1:?fichier pg dump requis (ex: backups/pg_...sql.gz)}"
GARAGE_FILE="${2:-}"

read -rp "Ceci écrase la base de production. Confirmez ? (oui/non) " CONFIRM
[ "$CONFIRM" = "oui" ] || { echo "Abandon."; exit 0; }

echo "▶ Arrêt de l'API (pour éviter les écritures pendant la restauration)"
docker compose -f docker-compose.prod.yml stop api

echo "▶ Restauration PostgreSQL depuis $PG_FILE"
gunzip -c "$PG_FILE" | docker compose -f docker-compose.prod.yml exec -T postgres \
  psql -U "${POSTGRES_USER:-dts}" -d "${POSTGRES_DB:-dts}"

if [ -n "$GARAGE_FILE" ]; then
  echo "▶ Restauration Garage depuis $GARAGE_FILE"
  docker run --rm --volumes-from dts-garage -v "$(pwd):/src" alpine \
    sh -c "rm -rf /var/lib/garage/meta/* /var/lib/garage/data/* && tar xf /src/$GARAGE_FILE -C /"
fi

echo "▶ Redémarrage de l'API"
docker compose -f docker-compose.prod.yml start api
echo "✔ Restauration terminée — vérifiez http://localhost (health) et quelques messages."
