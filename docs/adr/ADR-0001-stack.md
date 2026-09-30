# ADR-0001 — Choix de la stack

Date : septembre 2026 · Statut : accepté

## Contexte
Application de communication type Discord pour mobile + PC simultanés, développée
solo (niveau intermédiaire), auto-hébergée sur un mini-PC pour un cercle d'amis.

## Décision
- **Flutter** pour l'app (Android, iOS, Windows, macOS, Linux) ET le back-office (Web) :
  une seule techno d'interface, 6 cibles couvertes.
- **NestJS + TypeScript** pour l'API : REST + temps réel (Socket.io), OpenAPI auto.
- **PostgreSQL 16 + Prisma** en code-first (voir ADR-0002).
- **LiveKit** auto-hébergé pour la voix/caméra/partage d'écran ; **coturn** dès le premier jour.
- **Garage** pour les fichiers (S3, uploads présignés) ; **Redis** pour présence/états volatils.
  (MinIO prévu initialement : ses images Docker et binaires publics ont été retirés
  en 2026 — remplacé par Garage, S3 open source équivalent côté client aws-sdk.)
- **Caddy** comme unique point d'entrée HTTPS ; Docker Compose « une machine, un fichier ».

## Conséquences
- Une seule stack d'UI à maîtriser ; un seul langage côté serveur.
- Tout est auto-hébergeable sur une machine modeste (empreinte max ~1,6 Go de RAM).
- Alternatives écartées (React Native, Go, PostgreSQL sans ORM, Jitsi…) : comparatifs
  argumentés dans le guide technologique `docs/guide-technologique.pdf` (ch. 3 à 11).

## Références
- Guide technologique, chapitres 3-13.
