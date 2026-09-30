# Runbook production — mini-PC

Guide d'exploitation condensé. Le détail argumenté vit dans le guide technologique (ch. 13).

## 1. Premier déploiement

```bash
# a) Prérequis machine : Docker + plugin compose, ports box redirigés (80, 443 TCP ;
#    50000-60000 + 3478 + 49160-49200 UDP) — test CGNAT fait AVANT (guide ch. 16).
# b) Variables + config Garage
#    setup.sh génère docker/garage.toml avec des secrets aléatoires (ou openssl à la main)
[ -f docker/garage.toml ] || sed -e "s|0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef|$(openssl rand -hex 32)|" \
    -e "s|dev_admin_token_0000000000000000|$(openssl rand -base64 24)|" \
    -e "s|dev_metrics_token_00000000000000|$(openssl rand -base64 24)|" \
    docker/garage.toml.example > docker/garage.toml
cp .env.prod.example .env && nano .env        # DOMAIN, mots de passe, PUBLIC_IP
# c) Clés LiveKit (une fois)
docker run --rm livekit/livekit-server generate-keys   # → LIVEKIT_API_KEY/SECRET
# d) Builds Flutter statiques
cd apps/admin && flutter create . --platforms web && flutter pub get && flutter build web --release
cd ../app   && flutter build web --release   # optionnel (landing)
# e) Lancer la pile complète
docker compose -f docker-compose.prod.yml up -d --build
# f) Appliquer les migrations sur la base de production
docker compose -f docker-compose.prod.yml exec api npx prisma migrate deploy
```

Vérifications : `docker compose -f docker-compose.prod.yml ps` (tout « healthy/running »),
puis `https://api.DOMAIN/health` depuis l'extérieur, et `http://localhost:8080`
sur le serveur (back-office — cf. § 6).

## 2. Quotidien

| Action | Commande |
|---|---|
| État des services | `docker compose -f docker-compose.prod.yml ps` |
| Logs API | `docker compose -f docker-compose.prod.yml logs -f api` |
| Redémarrer l'API | `docker compose -f docker-compose.prod.yml restart api` |
| Mettre à jour l'API | `git pull && docker compose -f docker-compose.prod.yml up -d --build api` |
| Migrations après pull | `docker compose -f docker-compose.prod.yml exec api npx prisma migrate deploy` |

## 3. Sauvegardes (automatiques + vérifiées)

```bash
./scripts/backup.sh                 # PostgreSQL + Garage → ./backups/
# Cron quotidien 04h00 : crontab -e
0 4 * * * cd /chemin/projet && ./scripts/backup.sh >> backups/backup.log 2>&1
```

Règle du guide : copie **hors machine** (disque USB, PC principal, ou petit stockage
objet chiffré) + **exercice de restauration mensuel** avec `scripts/restore.sh`.

## 4. Incidents connus

- **Certificats** : si Let's Encrypt échoue, vérifier que 80/443 sont bien redirigés
  (Caddy a besoin du 80 pour les challenges HTTP).
- **Vocal haché** : vérifier la plage UDP 50000-60000 sur la box et `PUBLIC_IP`
  dans `.env` / `docker/livekit.yaml`.
- **Machines inactives** : pas de souci sur votre propre mini-PC (pas de récupération
  Oracle ici) — en revanche prévoir l'onduleur pour les micro-coupures.

## 5. Supervision

Sonde externe gratuite (UptimeRobot) sur `https://api.DOMAIN/health` → alerte mail
si le serveur ne répond plus. Le back-office (module Analytics, ANA-01..05) prendra
le relais plus tard.

## 6. Accès au back-office (ADR-0003)

Le BO **n'est jamais exposé sur Internet** : Caddy le sert sur `127.0.0.1:8080`
(seul l'hôte y accède, la box et ufw ne redirigent rien vers ce port).

| Mode | Quand | Commande / accès |
|---|---|---|
| Sur le serveur | devant la machine ou en RDP | navigateur → `http://localhost:8080` |
| À distance (direct) | depuis votre PC | `ssh -L 8080:localhost:8080 utilisateur@serveur` puis `http://localhost:8080` |

Notes :
- la liaison à distance est chiffrée par SSH ; l'authentification BO (connexion
  dédiée + A2F + `is_admin`) reste obligatoire dans tous les cas ;
- les appels API du BO passent par `https://api.DOMAIN` (contrôle `is_admin` côté
  API, origine locale autorisée via `CORS_ORIGINS`) ;
- option future sans rien exposer : VPN privé (WireGuard/Tailscale) vers le serveur.

Diagnostic express : `curl -I http://localhost:8080` sur le serveur doit répondre
`200` ; `curl -m 3 http://IP-publique:8080` depuis l'extérieur doit échouer
(c'est le comportement voulu).
