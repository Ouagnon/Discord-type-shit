# Discord type shit — Kit de démarrage

Monodépôt de l'application de communication style Discord (mobile + PC + back-office web),
conforme à l'architecture du **guide technologique** (voir `docs/`).

## Stack

| Brique | Techno | Emplacement |
|---|---|---|
| Application mobile + desktop | **Flutter** (Dart) | `apps/app` |
| Back-office web | **Flutter Web** | `apps/admin` |
| API + temps réel | **Node.js 20+ / NestJS / TypeScript** | `apps/api` |
| Base de données | **PostgreSQL 16 + Prisma** (code-first) | `apps/api/prisma` |
| Cache / présence | **Redis 7** | conteneur Docker |
| Fichiers (S3) | **Garage** | conteneur Docker |
| Passerelle HTTPS | **Caddy** (prod) | `docker/Caddyfile` |
| Vocal / écran | **LiveKit** + **coturn** (prod) | `docker/livekit.yaml` |

## Prérequis

- **Docker Desktop** (Windows : WSL2 activé) — [docker.com](https://www.docker.com/products/docker-desktop/)
- **Node.js 20 LTS ou plus** — [nodejs.org](https://nodejs.org/) (la version `node -v` doit commencer par 20, 22 ou 24)
- **Flutter stable** (SDK installé sur la machine) — [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
  puis `flutter doctor` doit être vert.
- **Git**

> ⚠️ Les `node_modules` et le SDK Flutter ne peuvent pas être livrés dans une archive
> (binaires propres à chaque OS). Les scripts d'installation ci-dessous font tout en 1 commande.

> 📌 **Note (sept. 2026)** : MinIO a retiré toutes ses images Docker et binaires
> publics → le kit utilise **Garage** (S3 open source ultra-léger, auto-hébergeable).
> L'API parle le protocole S3 standard (aws-sdk) : aucun code applicatif n'en dépend.

## Démarrage rapide (3 commandes)

```bash
# 1. Copier les variables d'environnement + la config Garage
#    (Windows : Copy-Item au lieu de cp)
cp .env.example .env
cp apps/api/.env.example apps/api/.env
cp docker/garage.toml.example docker/garage.toml

# 2. Lancer les services de dev (PostgreSQL + Redis + Garage + MailPit)
docker compose up -d

# 3. Installer l'API, générer le client Prisma et appliquer la BDD
cd apps/api && npm install && npx prisma migrate dev && npm run start:dev
```

→ API sur <http://localhost:3000> · santé : <http://localhost:3000/health> ·
doc Swagger : <http://localhost:3000/docs>

Ou tout-en-un : `./scripts/setup.sh` (Linux/macOS) / `scripts/setup.ps1` (Windows PowerShell).

Sur **Windows**, remplacez `cp` par `copy` (cmd) ou utilisez PowerShell :
`Copy-Item .env.example .env` ; `Copy-Item apps/api/.env.example apps/api/.env`.

## Application Flutter

```bash
cd apps/app
flutter create . --platforms android,windows,ios,linux,macos   # génère les dossiers de plateformes manquants
flutter pub get
flutter run            # cible par défaut (Windows si sur PC)
```

> dart:io est utilisé pour la détection de plateforme : le web n'est pas
> une cible de apps/app (il l'est pour apps/admin).

## Back-office (admin)

```bash
cd apps/admin
flutter create . --platforms web
flutter pub get
flutter run -d chrome
```

## Services de développement

| Service | URL / port | Rôle |
|---|---|---|
| PostgreSQL 16 | `localhost:5432` | base de données (`dts`) |
| Redis 7 | `localhost:6379` | présence / états volatils |
| Garage (S3) | `localhost:3900` (API) · `:3902` (web) | fichiers (avatars, pièces jointes) — bucket unique `dts-files` |
| MailPit | `localhost:8025` (SMTP `:1025`) | intercepte les mails transactionnels en dev |
| Adminer | `--profile tools` → `localhost:8080` | explorateur BDD optionnel |

Commandes utiles :

```bash
docker compose ps                  # état + santé
docker compose logs -f postgres    # suivre les logs
docker compose --profile tools up -d   # ajouter Adminer
docker compose down                # arrêter (les données persistent)
docker compose down -v             # arrêter ET effacer les données de dev
```

## Structure du dépôt

```
discord-type-shit/
├── apps/
│   ├── api/          # API NestJS (REST + temps réel plus tard) + Prisma
│   ├── app/          # application Flutter (Android, iOS, Windows, Linux, macOS)
│   └── admin/        # back-office Flutter Web
├── packages/
│   └── api-client/   # client Dart typé généré depuis l'OpenAPI de l'API
├── docker/           # Caddyfile, garage.toml.example, livekit.yaml, turnserver.conf
├── scripts/          # setup.sh / setup.ps1, backup.sh, restore.sh
├── docs/             # guide, user stories, schéma SQL de référence, ADR
└── .github/          # CI (lint + tests + migrations rejouées)
```

## Déploiement (mini-PC / production)

Voir `docs/ops.md` : `docker compose -f docker-compose.prod.yml up -d --build`
après avoir renseigné `.env` (domaine, secrets) et généré les builds Flutter.

## Étapes suivantes recommandées (guide, ch. 15 — feuille de route)

1. ✅ Socle + environnement (ce kit)
2. Les **trois POC de la semaine 1** : fenêtre overlay, salon vocal LiveKit, événement temps réel
3. P1 : comptes / authentification (`user_account` existe déjà dans le schéma Prisma)
4. Importer les user stories (`docs/user-stories-enrichies.md`) dans GitHub Projects

## Conventions

- Commits « conventional » : `feat(messages): …`, `fix(voice): …`, `db: …` (guide ch. 14)
- Fusion par pull request même en solo (CI verte obligatoire)
- Décisions d'architecture consignées dans `docs/adr/`
