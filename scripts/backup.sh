#!/usr/bin/env bash
# =============================================================================
#  backup.sh — sauvegarde de production (à lancer sur le mini-PC)
#  Usage : ./scripts/backup.sh [dossier_cible]
#  Planifier : crontab -e → 0 4 * * * /chemin/vers/projet/scripts/backup.sh
#  Sauvegarde : PostgreSQL (dump compressé) + fichiers Garage.
#  ⚠ Le guide (ch. 13) impose un EXERCICE DE RESTAURATION mensuel (restore.sh).
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."

DEST="${1:-backups}"
STAMP="$(date +%Y-%m-%d_%H%M)"
mkdir -p "$DEST"

echo "▶ Sauvegarde PostgreSQL → $DEST/pg_$STAMP.sql.gz"
docker compose -f docker-compose.prod.yml exec -T postgres \
  pg_dump -U "${POSTGRES_USER:-dts}" "${POSTGRES_DB:-dts}" | gzip > "$DEST/pg_$STAMP.sql.gz"

echo "▶ Sauvegarde Garage → $DEST/garage_$STAMP.tar"
docker run --rm --volumes-from dts-garage -v "$(pwd)/$DEST:/backup" alpine \
  tar cf "/backup/garage_$STAMP.tar" var/lib/garage

# Rétention : garder 14 jours
find "$DEST" -name 'pg_*.sql.gz' -mtime +14 -delete
find "$DEST" -name 'garage_*.tar' -mtime +14 -delete

echo "✔ Sauvegarde terminée : $DEST (pg_$STAMP.sql.gz, garage_$STAMP.tar)"
echo "  Copiez régulièrement ce dossier sur un AUTRE support (guide ch. 13)."
