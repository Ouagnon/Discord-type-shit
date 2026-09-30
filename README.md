# Discord type shit

Application de communication style Discord (mobile + PC + back-office web)

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

→ API sur <http://localhost:3000> · santé : <http://localhost:3000/health> ·
doc Swagger : <http://localhost:3000/docs>

## Services de développement

| Service | URL / port | Rôle |
|---|---|---|
| PostgreSQL 16 | `localhost:5432` | base de données (`dts`) |
| Redis 7 | `localhost:6379` | présence / états volatils |
| Garage (S3) | `localhost:3900` (API) · `:3902` (web) | fichiers (avatars, pièces jointes) — bucket unique `dts-files` |
| MailPit | `localhost:8025` (SMTP `:1025`) | intercepte les mails transactionnels en dev |
| Adminer | `--profile tools` → `localhost:8080` | explorateur BDD optionnel |

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

## Conventions

- Commits « conventional » : `feat(messages): …`, `fix(voice): …`, `db: …` (guide ch. 14)
- Fusion par pull request
- Décisions d'architecture consignées dans `docs/adr/`
