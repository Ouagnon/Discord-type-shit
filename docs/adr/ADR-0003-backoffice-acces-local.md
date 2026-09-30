# ADR-0003 — Accès au back-office : local uniquement

Date : septembre 2026 · Statut : accepté

## Contexte
Le back-office (BO, build Flutter Web servi par Caddy) administre toute l'instance :
modération, comptes, sanctions, configuration. La conception initiale le servait sur
un sous-domaine public (`bo.domaine`) protégé par authentification + A2F + rôle
`is_admin`. Pour une instance personnelle administrée par une seule personne, la
question s'est posée : faut-il exposer cette surface d'administration à Internet ?

## Décision
**Le back-office n'est jamais exposé sur Internet.** Il est servi par Caddy sur le
port 8080, publié en `127.0.0.1:8080` sur l'hôte (loopback uniquement). Il n'est
accessible que par :

1. **Le serveur lui-même** — navigateur local sur la machine (ou session bureau à
   distance / console).
2. **Une connexion directe à distance au serveur** — tunnel SSH :
   `ssh -L 8080:localhost:8080 utilisateur@serveur`, puis `http://localhost:8080`
   dans le navigateur de son PC. Le trafic est chiffré de bout en bout par SSH.

Aucun sous-domaine `bo.` n'existe dans le Caddyfile ; aucun port 8080 n'est ouvert
sur la box ni dans ufw.

## Conséquences
- **Surface d'attaque réduite** : la page d'administration est invisible d'Internet
  (scan de ports, phishing d'URL admin, brute force du formulaire — supprimés).
- **L'API reste la seule porte** : les routes BO de `api.domaine` restent publiques
  (le BO appelé depuis le navigateur admin y accède en HTTPS) — le contrôle
  `is_admin` + JWT + A2F y est **non négociable**. Cacher la page ne remplace pas
  l'autorisation côté API.
- **CORS** : autoriser l'origine locale du BO (`CORS_ORIGINS` inclut
  `http://localhost:8080`) pour les appels API depuis le navigateur admin.
- **Coût d'usage** : administrer depuis l'extérieur exige une commande SSH (ou une
  session RDP) — accepté : c'est l'administrateur unique, usage peu fréquent.
- Évolution possible sans conflit : un VPN privé (WireGuard/Tailscale) si le besoin
  d'un accès admin plus fluide apparaît ; le principe « pas d'exposition publique »
  reste le même.

## Références
- Guide technologique ch. 12 (panneau d'administration) et ch. 13 (infrastructure),
  mise à jour alignée sur cette décision.
- `docker/Caddyfile` (bloc `:8080`) et `docker-compose.prod.yml` (port
  `127.0.0.1:8080:8080`, `CORS_ORIGINS`).
- `docs/ops.md` § 6 — modes d'accès et commandes.
