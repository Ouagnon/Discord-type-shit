# Résumé du projet « Discord type shit » — Mission de cadrage technologique

> **Date :** septembre 2026 · **Auteur :** assistant de cadrage (Z.ai)
> **Objet :** synthèse complète de la demande, de l'analyse des fichiers, des livrables produits et des recommandations. Ce document sert de point d'entrée : il renvoie vers les trois livrables détaillés (guide PDF, schéma SQL, user stories).

---

## 1 · Résumé de la demande

Le porteur du projet prépare une **application de communication style Discord** (messagerie, vocal, personnalisation) destinée à **mobile et PC**, pour un usage personnel entre amis. Il a déjà produit un schéma de base de données (dbdiagram.io), des maquettes d'écrans (dont l'apparence n'est pas contractuelle) et un fichier markdown de user stories.

La demande formulée était exclusivement du **conseil, sans aucun code applicatif** :

1. Recommander **langage(s), architecture, méthode de travail, outils et technologies** pour réaliser l'application de la façon la plus efficace et efficiente possible.
2. Trancher la question **code-first ou DB-first** pour la base de données.
3. **Vérifier et optimiser le schéma de base de données**, et livrer un fichier SQL corrigé/amélioré.
4. **Compléter les user stories** existantes si nécessaire.
5. **Rédiger les user stories du panneau d'administration** de l'application.

Précisions recueillies en amont : couverture **mobile + PC simultanée**, développeur **solo de niveau intermédiaire**, **aucune préférence d'écosystème**, hébergement **serveur unique tout-Docker** (serveur applicatif + back-office sur la même machine, le BO n'étant accessible que depuis le serveur lui-même ou via une connexion directe à distance — tunnel SSH/RDP, cf. ADR-0003) — plan précisé ensuite : **dev en local sur le PC, puis mini-PC physique personnel type Minisforum pour la publication** (zéro abonnement, voir § 4), guide attendu **très complet (« bible »)**, user stories au **format enrichi avec critères d'acceptation**, et les 4 modules d'administration souhaités (modération, comptes & serveurs, analytics, configuration système).

Fonctionnalités futures explicitement annoncées : création de nouveaux serveurs, changement de police d'écriture du pseudo ou de la note, affichage de l'activité de jeu, overlay vocal au changement d'application (avec animation d'opacité quand un participant parle), et intégration du **live-chat** (décrit dans un document dédié : envoi de sons, images, textes et vidéos en overlay sur l'écran d'un ami).

---

## 2 · Compréhension du sujet et des fichiers fournis

Le dépôt GitHub fourni (`Ouagnon/Discord-type-shit`, dossier « Starting ressources ») a été intégralement analysé :

| Fichier | Contenu compris | Observations d'analyse |
|---|---|---|
| `Application Discord type shit.md` | Architecture en segments (serveur général où tout le monde est inscrit, coin personnel MP/groupes, paramètres, personnalisation) + 27 user stories « utilisateur lambda » + ébauche de périmètre admin (suppression de profils, gestion serveurs/salons, purge de données, maintenance) | Bonne couverture fonctionnelle ; numérotation à corriger (deux US6, US9 étiquetée US8) ; manques identifiés : édition/suppression de message, vérification email, reset de mot de passe, blocage, gestion de groupes, réception des demandes d'ami |
| `Projet Live-chat - intégration...md` | Fonctionnalité d'envoi d'overlays multimédias (texte, image, vidéo, son positionnés et programmés) sur l'écran d'un ami, avec paramètres de réception, permissions par ami, cooldown, plein écran exclusif, live-chats enregistrés et réutilisables | Document complet et cohérent ; traduit en 9 user stories (LC-01 à LC-09) |
| `image.png` | Schéma BDD dbdiagram.io : 14 tables (SERVER, CHANNEL, CONVERSATION, MESSAGE, ATTACHMENT, ACCOUNT, EMOJI, SOUNDBORAD + 5 tables de jonction) | Défauts détectés : fautes de frappe (SOUNDBORAD, soundboard_iUUID, guild_UUID), **email absent du compte alors que US1/US2 exigent un login email**, couple mdp+salt (à remplacer par un hash Argon2id), double FK ambiguë sur MESSAGE (conversation + salon), contrainte UNIQUE sur les pièces jointes contredisant l'US13 (10 fichiers), aucun index, ENUM non définis, tables manquantes (réactions, réponses, réglages, rôles, live-chat, admin…) |
| 8 maquettes PNG | Écrans mobiles : liste de conversations, salon textuel, liste de salons avec catégories, personnalisation de profil (bannière, fond, statut), profil (tag, statuts), paramètres (mobile et desktop) | Apparence explicitement non contractuelle ; servent à confirmer les écrans et la notion de catégories de salons (intégrée au schéma) |

**Compréhension du projet :** un clone familial de Discord — comptes par email avec A2F, amis par tag #0000, messages privés et groupes, serveur général par défaut (extension future : création de serveurs), salons textuels et vocaux, markdown et pièces jointes, emojis et soundboards personnels partageables, appels vocaux privés avec caméra et partage d'écran, personnalisation poussée, back-office d'administration — le tout auto-hébergé sur un VPS Docker, pour un cercle d'amis, maintenu par une seule personne.

---

## 3 · Résumé de la réponse — livrables produits

Quatre livrables, conçus pour s'utiliser ensemble :

| Livrable | Fichier | Contenu |
|---|---|---|
| **Guide technologique** | `guide-technologique.pdf` | 39 pages, 19 chapitres : compréhension du projet, principes de choix, stack recommandée avec comparatifs argumentés (front-end, back-end, BDD, temps réel, vocal, stockage, sécurité, back-office), infrastructure Docker, méthode de travail (Git/CI/kanban/ADR), feuille de route en 7 phases, hébergement maison (mini-PC) et coûts, registre des risques, synthèse de la revue BDD. 3 schémas d'architecture, 27 tableaux |
| **Schéma BDD optimisé** | `schema-bdd-optimise.sql` | PostgreSQL 16 — 30 tables (vs 14), 9 types ENUM, 25 index ciblés, contraintes CHECK, commentaires intégrés, syntaxe validée automatiquement (113 instructions, 0 erreur) |
| **User stories enrichies** | `user-stories-enrichies.md` | 78 stories (vs 27) avec table de correspondance, format « En tant que… + critères Given/When/Then + points d'attention » ; inclut les 18 stories du panneau d'administration (4 modules) et les 9 stories live-chat |
| **Présent résumé** | `resume-projet.md` | Synthèse de la mission (ce document) |

---

## 4 · Conseils et recommandations (l'essentiel)

### La stack recommandée

- **Front-end : Flutter (Dart)** — un seul code pour Android, iOS, Windows, macOS, Linux **et** le back-office web (Flutter Web compilé). Seule techno mature couvrant les 6 cibles ; SDK LiveKit officiel ; fenêtrage overlay possible via `window_manager` + platform channels.
- **Back-end : Node.js + NestJS (TypeScript)** — API REST + passerelle Socket.io intégrée, structure modulaire, OpenAPI automatique (qui permet de **générer le client Dart typé**), écosystème idéal pour un développeur intermédiaire solo.
- **Base de données : PostgreSQL 16 + Prisma** — et la réponse à la question posée : **oui, code-first**. Le schéma dessiné et le SQL optimisé servent de spécification ; le `schema.prisma` devient la source de vérité versionnée, les migrations sont générées, relisibles et rejouables, le client est typé. Jamais de `ALTER TABLE` manuel en production.
- **Temps réel : Socket.io** — une salle par canal, événements typés ; l'historique et les uploads restent en REST.
- **Vocal / caméra / écran : LiveKit (SFU) auto-hébergé** — jetons JWT courts délivrés par l'API, événements « speaking » (pour l'animation d'opacité), partage d'écran géré. TURN (coturn) déployé dès le premier jour.
- **Fichiers : Garage (S3)** — uploads **présignés** directement du client (l'API ne proxyfie jamais les 50 Mo), URL signées à durée limitée, quotas.
- **Présence et états volatils : Redis** — le durable en PostgreSQL, l'instantané en mémoire.
- **Passerelle : Caddy** — HTTPS automatique, un seul point d'entrée public (app., api, vocal, files) ; le back-office est servi en local uniquement (`127.0.0.1:8080`, serveur ou tunnel SSH — ADR-0003).
- **Hébergement : un serveur unique, un `docker-compose.yml`** — réseau privé Docker, seuls 443 et l'UDP vocal sortent ; sauvegardes chiffrées externes + exercice mensuel de restauration. **0 € possible** : voir « Héberger sans rien payer » ci-dessous.
- **CI : GitHub Actions** — analyse statique, tests, migrations rejouées sur base éphémère, builds ; fusion par PR même en solo.

### Les décisions structurantes à retenir

1. **Fusion des concepts « salon » et « conversation »** en une seule table de canaux typés (modèle réel de Discord) : une seule table de messages, une seule logique de membres et de permissions — suppression de la double FK ambiguë du schéma initial.
2. **Sécurité des comptes refondue** : email + hash Argon2id unique (plus de couple mdp/salt), tag #0000 (l'ancien champ `code` devient `discriminator`), A2F TOTP.
3. **Le volatile n'est pas persisté** : présence et sessions vocales vivent dans Redis ; la base reste réservée au durable.
4. **Pagination par repère** (keyset) sur l'index `(canal, date, id)` : les pages de 30 messages restent stables et rapides.
5. **Back-office = build Flutter Web statique** : zéro service supplémentaire, zéro troisième stack à apprendre ; A2F obligatoire, journal d'audit en ajout seul, 3 niveaux de droits — et **accès local uniquement** (ADR-0003 : sur le serveur ou via tunnel SSH, jamais de sous-domaine public).
6. **Preuves de concept dès la première semaine** (fenêtre overlay, salon vocal, événement temps réel) : les fonctionnalités les plus risquées (overlay, live-chat) touchent à l'OS — les valider avant de construire dessus.

### Hébergement : zéro abonnement (plan en deux temps)

Le plan d'hébergement a été précisé : **le serveur de développement tourne en Docker sur votre PC** (0 €), et la publication à long terme se fera sur un **serveur physique personnel — mini-PC type Minisforum** — acheté une fois. Aucun abonnement, aucun cloud obligatoire. Le chapitre 16 du guide a été réécrit autour de ce plan.

- **Phase de développement (0 €)** : toute la pile tourne en local via Docker, exactement comme le guide le recommande (chapitre 14). C'est aussi la phase des trois POC.
- **Production : mini-PC dédié** — classe Intel N100/N150, 16 Go de RAM, SSD NVMe 500 Go (ex. Minisforum UN100, ~200-350 € complets). Consommation 6-25 W ≈ **1-2 €/mois d'électricité**, aucune autre charge. Machine x86 : les images Docker officielles marchent telles quelles. Accessoires utiles : onduleur (~50 €), second disque pour les sauvegardes. Migration depuis le PC de dev = recopier le `docker-compose.yml` + rediriger le DNS (10 minutes).
- **⚠ Le point à vérifier AVANT l'achat : l'IP publique.** Si votre box est en CGNAT (adresse WAN de la box ≠ adresse vue sur monip.org), aucun port de la maison n'est joignable — et le **vocal UDP est le premier touché**. Parades : demander une IP publique au FAI (gratuite chez certains), tunnel Cloudflare gratuit pour le web (mais pas l'UDP vocal), ou petit relais (micro-VPS WireGuard ou l'instance Oracle gratuite) qui achemine le trafic vers la maison — le mini-PC garde tout le travail.
- **Sécurité maison** : seuls le 443 (Caddy) et la plage UDP vocale sont redirigés ; base/Redis/Garage restent sur le réseau Docker privé ; le back-office reste en localhost:8080 (jamais exposé, accès serveur/tunnel SSH — ADR-0003) ; SSH par clés ; machine idéalement en DMZ ; `restart: unless-stopped` + Watchtower + sonde externe (UptimeRobot) pour la robustesse.
- **Domaine : DuckDNS gratuit** (agent de mise à jour sur le mini-PC) + HTTPS automatique Caddy/Let's Encrypt. Un vrai domaine (~10 €/an) resterait purement esthétique.
- **Replis réversibles** : Oracle Cloud « Always Free » (gratuit à vie : 4 cœurs ARM, 24 Go, 200 Go, 10 To/mois ; carte bancaire vérifiée à l'inscription sans débit) ou VPS Hetzner/OVH (4-9 €/mois). Même Compose, migration en 10 minutes — le choix n'engage à rien.

### Feuille de route (résumé)

P0 socle + POC (1-2 sem.) · P1 comptes/auth (2-3 sem.) · P2 social + messagerie (3-4 sem.) · P3 vocal (3 sem.) · P4 personnalisation (2 sem.) · P5 back-office (2-3 sem.) · P6 futures : serveurs, activité de jeu, overlay, live-chat (4-8 sem.). Soit **4 à 6 mois** à rythme réaliste en solo. Coût d'infrastructure : **aucun abonnement** — dev en local (0 €), puis mini-PC personnel (achat unique ~200-350 €, ~1-2 €/mois d'électricité) ; replis : Oracle Always Free (0 €) ou VPS (5-10 €/mois). Tous les logiciels sont open source.

---

## 5 · Prochaines étapes suggérées

1. **Valider les choix structurants** (Flutter, NestJS, PostgreSQL/Prisma, LiveKit, Caddy) et consigner les éventuels refus motivés.
2. Créer le monodépôt + le `docker-compose.yml` de développement (chapitre 14 du guide).
3. Traduire `schema-bdd-optimise.sql` en `schema.prisma`, générer la migration initiale, semer le serveur par défaut.
4. Réaliser les **trois POC** de la semaine 1 : fenêtre transparente toujours au-dessus (Windows), salon vocal LiveKit depuis Flutter, événement Socket.io de bout en bout.
5. Importer les **78 user stories** dans un tableau GitHub Projects et démarrer par CPT-01.
6. **Faire le test CGNAT** (IP WAN de la box vs monip.org — 2 minutes, voir § 4) pour savoir à l'avance si le vocal passera quand le mini-PC sera en place.

---

## 6 · Inventaire des fichiers de la mission

```
download/
├── guide-technologique.pdf      # 39 pages — stack, architecture, méthode, hébergement maison, risques
├── schema-bdd-optimise.sql      # 30 tables, contraintes et index — syntaxe validée
├── user-stories-enrichies.md    # 78 stories (27 d'origine renumérotées + 50 nouvelles)
└── resume-projet.md             # le présent document
```

Mise à jour ADR-0003 (alignement de tous les livrables) : **le back-office n'est plus exposé publiquement** — Caddy le sert en `127.0.0.1:8080`, accessible uniquement depuis le serveur lui-même ou via tunnel SSH (`ssh -L 8080:localhost:8080`). Caddyfile, compose de production et ops.md alignés ; décision consignée dans `docs/adr/ADR-0003-backoffice-acces-local.md`.

Sources analysées : dépôt GitHub `Ouagnon/Discord-type-shit` (dossier « Starting ressources ») — 2 documents markdown, 1 schéma de BDD (image), 8 maquettes.
