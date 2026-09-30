# User Stories enrichies — Application « Discord type shit »

> **Version :** 2.0 · **Date :** septembre 2026
> **Sources :** « Application Discord type shit.md » (v1, 27 US) + « Projet Live-chat — intégration à Discord type shit.md » + fonctionnalités futures listées par le porteur de projet + panneau d'administration.
> **Format :** chaque story suit le modèle « En tant que … je veux … afin de … », complété par des **critères d'acceptation** au format Given/When/Then (Gherkin) et des **points d'attention** (cas limites, sécurité, ergonomie).
> Les stories marquées 🆕 sont des ajouts par rapport au document d'origine ; les autres reprennent et précisent les US existantes.

---

## Personas

| Persona | Description | Accès |
|---|---|---|
| **Utilisateur lambda** | Personne inscrite utilisant l'application au quotidien : messagerie, vocal, personnalisation, live-chat. | Application mobile / PC |
| **Administrateur** | Utilisateur disposant du rôle `admin`. Gère l'application depuis le back-office (BO) hébergé sur le serveur, servi en local uniquement (ADR-0003 : serveur ou tunnel SSH). Ne modère pas à la place des utilisateurs, il arbitre. | BO web (connexion dédiée, A2F obligatoire ; accès local : serveur ou tunnel SSH) |

---

## Table de correspondance avec les US d'origine

Le document d'origine contenait deux « US6 », une US9 étiquetée « US8 » et quelques imprécisions. La numérotation est refondue par thème :

| US d'origine | Nouvelle référence | Thématique |
|---|---|---|
| US1 | CPT-01 | Création de compte |
| US2 | CPT-02 | Connexion + A2F |
| — | CPT-03 à CPT-06 🆕 | Email, mot de passe oublié, sessions, suppression de compte |
| US3 | NAV-01 | Navigation principale |
| US4 | SET-01 | Paramètres |
| US5 | PERS-01 | Personnalisation (structure) |
| US6 (1re, profil) | PERS-02 | Personnalisation du profil |
| US6 (2e, application) | PERS-03 | Personnalisation de l'application |
| US7 | PERS-04 | Emojis et soundboards personnels |
| US8 | PRE-01 | Cadre de présence + statut |
| US9 | FRD-01 | Liste d'amis + demande par tag |
| — | FRD-02, FRD-03 🆕 | Demandes reçues, blocage |
| US10 | MP-01 | Messages et groupes privés |
| — | MP-02, MP-03 🆕 | Gestion des groupes privés |
| US11 | SRV-01 | Accès aux salons du serveur général |
| US12 | MSG-01 | Historique paginé |
| US13 | MSG-02 | Rédaction, markdown, pièces jointes |
| US14 | MSG-03 | Réactions |
| US15 | MSG-04 | Copier un message |
| US16 | MSG-05 | Répondre à un message |
| US17 | MSG-06 | Partage emoji / soundboard |
| — | MSG-07, MSG-08, MSG-09, MSG-10 🆕 | Éditer, supprimer, indicateur de saisie, repères de lecture |
| US18–US27 | VOC-01 à VOC-10 | Vocal et appels |
| — | SRV-02 à SRV-04 🆕 | Création de serveurs (futur) |
| — | PERS-05, PERS-06 🆕 | Polices du pseudo et de la note (futur) |
| — | GAM-01 à GAM-03 🆕 | Activité de jeu (futur) |
| — | OVL-01 à OVL-03 🆕 | Overlay vocal (futur) |
| — | LC-01 à LC-09 🆕 | Live-chat (intégration future) |
| — | ADM-01, MOD-01 à 05, CSR-01 à 06, ANA-01 à 05, CFG-01 à 06 🆕 | Panneau d'administration |

---

## 1. Compte & authentification

### CPT-01 — Création de compte
**En tant qu'** visiteur, **je veux** créer un compte avec une adresse mail et un mot de passe, puis choisir un pseudo et éventuellement une image de profil, **afin de** rejoindre l'application.

**Critères d'acceptation :**
- Given un visiteur sur l'écran d'inscription, When il saisit une adresse mail valide, un mot de passe conforme aux exigences (8 caractères min., lettres + chiffres) et un pseudo unique, Then le compte est créé, un tag `#0000–9999` lui est attribué automatiquement et il arrive connecté sur l'écran d'accueil.
- Given une adresse mail déjà utilisée, When le visiteur valide, Then un message d'erreur explicite s'affiche sans révéler d'informations sensibles.
- Given un pseudo déjà pris, When le visiteur valide, Then le système propose le pseudo avec le tag le plus proche disponible (le couple pseudo + tag est unique).
- Given l'étape « image de profil », When le visiteur la saute, Then une image par défaut générée (initiales sur fond coloré) est utilisée.
- Given un compte créé, Then il est automatiquement membre du serveur général par défaut.

**Points d'attention :** vérification du format de l'image (PNG/JPG/WebP, ≤ 2 Mo, redimensionnement serveur) ; limitation du taux de création de comptes par IP (anti-spam) ; envoi d'un mail de bienvenue/vérification (voir CPT-03).

### CPT-02 — Connexion et A2F
**En tant qu'** utilisateur, **je veux** me connecter avec mon adresse mail et mon mot de passe — avec demande de code A2F si je l'ai activée, **afin d'** accéder à mon compte en toute sécurité.

**Critères d'acceptation :**
- Given des identifiants corrects et l'A2F désactivée, When je me connecte, Then j'accède directement à l'écran d'accueil (mes messages privés).
- Given des identifiants corrects et l'A2F activée, When je me connecte, Then un code à 6 chiffres (TOTP) m'est demandé avant l'ouverture de session.
- Given un code A2F erroné, When je le soumets, Then un message d'erreur apparaît et le compteur de tentatives s'incrémente ; au bout de 5 échecs, la tentative de connexion est bloquée temporairement.
- Given un mot de passe erroné, When je me connecte, Then le message est volontairement générique (« identifiants incorrects ») ; après 10 échecs, un délai croissant s'applique.
- Given l'A2F activée, When je dispose d'un appareil de secours, Then je peux utiliser un code de récupération à usage unique.

**Points d'attention :** hachage Argon2id côté serveur (jamais de mot de passe en cl ni de sel géré manuellement) ; expiration des sessions ; journalisation des connexions (date, IP) consultable dans les paramètres.

### CPT-03 — Vérification de l'adresse mail 🆕
**En tant qu'** utilisateur, **je veux** recevoir un mail de vérification après mon inscription (et pouvoir en redemander un), **afin de** sécuriser mon compte et permettre la réinitialisation de mot de passe.

**Critères d'acceptation :**
- Given un compte fraîchement créé, When l'inscription se termine, Then un mail contenant un lien à validité limitée (24 h) est envoyé.
- Given un lien valide, When je clique dessus, Then mon adresse est marquée vérifiée et la bannière « vérifiez votre mail » disparaît.
- Given un lien expiré, When je clique dessus, Then on me propose d'en générer un nouveau.
- Given une adresse non vérifiée, When je demande une réinitialisation de mot de passe, Then le mail de réinitialisation n'est pas envoyé (prévention d'usurpation d'adresse).

**Points d'attention :** cadence de renvoi du mail (anti-spam : 1 par minute) ; la vérification peut rester optionnelle pour un usage entre amis, mais l'activation de l'A2F la requiert.

### CPT-04 — Réinitialisation du mot de passe 🆕
**En tant qu'** utilisateur, **je veux** réinitialiser mon mot de passe via un lien reçu par mail, **afin de** reprendre accès à mon compte si je l'ai perdu.

**Critères d'acceptation :**
- Given une adresse vérifiée, When je demande une réinitialisation, Then un mail avec un lien à usage unique (valable 1 h) part ; la réponse est identique que l'adresse existe ou non (pas de divulgation).
- Given un lien valide, When je saisis deux fois un nouveau mot de passe conforme, Then le mot de passe est changé et toutes mes autres sessions sont déconnectées.
- Given un lien déjà utilisé ou expiré, When je tente de l'ouvrir, Then une erreur s'affiche et je dois redemander un lien.

**Points d'attention :** invalidation des jetons de session existants après réinitialisation ; notification par mail « votre mot de passe a été modifié ».

### CPT-05 — Gestion des sessions et déconnexion 🆕
**En tant qu'** utilisateur, **je veux** me déconnecter, changer de compte et voir/gérer mes sessions actives (appareils), **afin de** garder le contrôle de mes accès.

**Critères d'acceptation :**
- Given une session ouverte, When je choisis « Se déconnecter », Then la session locale est fermée et le jeton serveur révoqué.
- Given plusieurs appareils connectés, When j'ouvre « Sessions actives » dans les paramètres, Then je vois la liste (appareil, plateforme, date, IP) et peux révoquer chaque session individuellement ou toutes les autres.
- Given une session révoquée, When l'appareil tente une requête, Then il est renvoyé à l'écran de connexion.

**Points d'attention :** « Changer de compte » = déconnexion + retour à l'écran de connexion avec le dernier mail pré-rempli ; révocation à distance notifiée sur l'appareil concerné.

### CPT-06 — Suppression de mon compte 🆕
**En tant qu'** utilisateur, **je veux** supprimer mon compte depuis les paramètres après confirmation renforcée, **afin d'** exercer mon droit à l'effacement.

**Critères d'acceptation :**
- Given les paramètres du compte, When je choisis « Supprimer le compte », Then on me demande mon mot de passe, puis une confirmation en deux temps (saisie du mot « SUPPRIMER »).
- Given la confirmation, When je valide, Then mon profil est supprimé, mes connexions révoquées, mes emojis/soundboards personnels supprimés, mes amitiés rompues ; mes messages deviennent « Utilisateur supprimé » (contenu conservé pour la continuité des conversations, conformément au schéma).
- Given un compte supprimé, When quelqu'un tente de se connecter, Then les identifiants sont refusés et l'adresse mail est libérée après 30 jours.

**Points d'attention :** cohérence avec la stratégie de suppression retenue en BDD (messages conservés, auteur anonymisé) ; export des données personnelles proposé avant suppression (RGPD).

---

## 2. Navigation & structure de l'application

### NAV-01 — Écran d'accueil et navigation
**En tant qu'** utilisateur connecté, **je veux** arriver sur la liste de mes messages et groupes privés au lancement, et basculer entre les zones (messages, serveur général, personnalisation, paramètres) via une zone en haut de l'écran, **afin de** me repérer instantanément.

**Critères d'acceptation :**
- Given un lancement de l'application avec session valide, Then j'arrive sur la liste de mes conversations privées.
- Given la barre de navigation, When je sélectionne une zone, Then un indicateur (barre blanche sous l'icône) marque ma position actuelle.
- Given un changement de zone, Then la zone précédente conserve son état (position de scroll, conversation ouverte) quand j'y reviens.
- Given une session expirée au lancement, Then je suis renvoyé vers l'écran de connexion.

**Points d'attention :** l'indicateur de position doit rester visible dans tous les états (clavier ouvert mobile, fenêtre redimensionnée PC) ; navigation clavier accessible sur desktop.

---

## 3. Paramètres de l'application

### SET-01 — Paramètres du compte et de l'application
**En tant qu'** utilisateur connecté, **je veux** accéder aux paramètres pour gérer mon adresse mail, mon mot de passe, l'A2F, les notifications et mon compte (déconnexion, changement, suppression), **afin de** contrôler mon identité et mes préférences.

**Critères d'acceptation :**
- Given la page paramètres, Then je trouve les sections : compte et sécurité (mail, mot de passe, A2F, sessions), préférences (notifications, langue), assistance.
- Given un changement d'adresse mail, When je saisis la nouvelle adresse, Then un mail de vérification part et l'ancienne adresse reste active jusqu'à validation.
- Given un changement de mot de passe, When je fournis l'ancien et le nouveau, Then les autres sessions sont invalidées.
- Given l'activation de l'A2F, Then je dois scanner un QR code, saisir un code de validation, et je reçois des codes de secours à conserver.
- Given les préférences de notification, Then je peux régler séparément messages privés, salons, son et vibration.

**Points d'attention :** toute action sensible demande le mot de passe courant ; les paramètres sont synchronisés entre appareils via le compte.

---

## 4. Personnalisation

### PERS-01 — Espace de personnalisation
**En tant qu'** utilisateur connecté, **je veux** accéder à la personnalisation divisée en trois sous-écrans (profil, application, emojis & soundboards), **afin de** personnaliser sans fouiller dans des menus confus.

**Critères d'acceptation :**
- Given la zone personnalisation, Then trois sous-entrées sont accessibles : « Profil », « Application », « Emojis & soundboards ».
- Given un sous-écran, When je quitte et reviens, Then mes modifications non enregistrées sont soit conservées en brouillon, soit signalées comme perdues (message de confirmation avant sortie).

### PERS-02 — Personnalisation du profil
**En tant qu'** utilisateur connecté, **je veux** modifier mon pseudo, mon icône, ma bannière, mon fond de profil, mon statut (en ligne, inactif, ne pas déranger, invisible), mon statut personnalisé (court texte affiché sur mon profil) et copier mon tag, **afin de** me présenter comme je l'entends.

**Critères d'acceptation :**
- Given l'écran profil, When je change mon pseudo, Then le système vérifie la disponibilité du couple (pseudo, tag) et propose le tag le plus proche si conflit ; mes amis sont notifiés du changement.
- Given les champs visuels (icône, bannière, fond), When je téléverse une image, Then un aperçu s'affiche, la découpe/l'ajustement est possible, puis l'image est redimensionnée côté serveur.
- Given le sélecteur de statut, When je choisis « invisible », Then j'apparais hors ligne aux autres tout en voyant la vraie présence de mes amis.
- Given mon tag `#1234`, When je clique sur « Copier mon tag », Then il est copié dans le presse-papier avec confirmation visuelle.
- Given un statut personnalisé trop long (> 128 caractères), When je valide, Then l'entrée est refusée avec un compteur de caractères.

**Points d'attention :** la bannière et le fond peuvent être des dégradés générés (couleur 1 / couleur 2) en alternative aux images ; modération possible des images par l'administration (voir MOD).

### PERS-03 — Personnalisation de l'application
**En tant qu'** utilisateur connecté, **je veux** définir le niveau de zoom, la taille de police, la couleur de fond ou un dégradé de deux couleurs et les réglages classiques, **afin d'** adapter l'application à mes yeux et à mon matériel.

**Critères d'acceptation :**
- Given les réglages d'apparence, When je modifie zoom ou taille de police, Then l'aperçu s'applique en direct et se synchronise sur mes autres appareils.
- Given le choix de fond, When je définis une ou deux couleurs, Then un dégradé (si deux couleurs) s'applique aux zones de fond ; un bouton « Réinitialiser » revient au thème par défaut.
- Given des réglages incompatibles avec l'accessibilité (contraste trop faible), Then un avertissement s'affiche (sans bloquer).

**Points d'attention :** les réglages sont persistés par compte (table `user_settings`) avec repli local si hors-ligne ; respecter les préférences système (mode sombre/clair par défaut).

### PERS-04 — Emojis et soundboards personnels
**En tant qu'** utilisateur connecté, **je veux** créer, voir, supprimer mes emojis et soundboards personnalisés, retirer de ma liste ceux qu'on m'a partagés, **afin de** personnaliser mes échanges (la suppression d'un élément partagé le retire aussi chez les destinataires).

**Critères d'acceptation :**
- Given la sous-section emojis, When j'ajoute un emoji, Then je fournis un nom unique (format `nom_emoji`, minuscules/underscores, 2 à 32 caractères) et une image carrée (PNG/GIF, ≤ 256 Ko) ; il devient utilisable via `:nom_emoji:`.
- Given la sous-section soundboards, When j'ajoute une soundboard, Then je fournis un nom, un fichier audio (≤ 500 Ko, OGG/MP3) et un niveau de volume ; la durée est détectée automatiquement.
- Given un emoji/soundboard que j'ai créé, When je le supprime, Then il disparaît de ma liste ET des listes des utilisateurs à qui je l'avais partagé (suppression en cascade côté serveur).
- Given un emoji/soundboard partagé par un ami, When je clique « Retirer de ma liste », Then il disparaît de MA liste uniquement, sans affecter les autres.

**Points d'attention :** quota par utilisateur (ex. 50 emojis + 20 soundboards) pour protéger le stockage ; les réactions utilisant un emoji supprimé retombent sur un rendu « emoji inconnu ».

### PERS-05 — Police d'écriture du pseudo 🆕 (futur)
**En tant qu'** utilisateur connecté, **je veux** choisir la police d'écriture de mon pseudo parmi une liste proposée par l'application, **afin de** rendre mon profil plus personnel.

**Critères d'acceptation :**
- Given la personnalisation du profil, When j'ouvre le sélecteur de police du pseudo, Then seules les polices de la liste blanche (gérées en administration) sont proposées, avec aperçu.
- Given une police choisie, When je valide, Then mon pseudo s'affiche dans cette police partout où il apparaît (chat, listes, vocal, profil).
- Given une police retirée de la liste par un administrateur, Then les profils concernés retombent automatiquement sur la police par défaut.

**Points d'attention :** licence des polices (n'utiliser que des polices libres — OFL/Apache) ; la police est identifiée par clé technique côté base (table `font`), jamais par un chemin ou une valeur libre.

### PERS-06 — Police d'écriture de la note / statut personnalisé 🆕 (futur)
**En tant qu'** utilisateur connecté, **je veux** choisir la police de mon statut personnalisé (ma « note »), **afin de** compléter la personnalisation de mon profil.

**Critères d'acceptation :**
- Identiques à PERS-05, appliqués au champ note/statut personnalisé (champ `custom_status_font`).
- Given un statut personnalisé vide, Then le sélecteur de police n'a aucun effet visible (le champ est masqué).

---

## 5. Présence & cadre utilisateur

### PRE-01 — Cadre de présence et statut
**En tant qu'** utilisateur connecté, **je veux** voir en bas de mon écran un cadre rectangulaire avec mon icône (et mon statut en pastille), mon pseudo, mon statut personnalisé en dessous et un bouton « Amis », **afin de** toujours savoir sous quelle identité je communique.

**Critères d'acceptation :**
- Given le cadre de présence affiché dans les listes de messages et les salons, Then mon icône, ma pastille de statut, mon pseudo et mon statut personnalisé sont présents et à jour en temps réel.
- Given un clic sur mon icône, Then un menu permet de changer de statut (en ligne, inactif, ne pas déranger, invisible).
- Given un clic sur mon statut personnalisé, Then une zone d'édition s'ouvre (modification ou effacement, limite 128 caractères).
- Given le bouton « Amis », When je clique dessus, Then j'accède à ma liste d'amis (FRD-01).

**Points d'attention :** le statut « inactif » passe automatiquement après une période sans activité (paramétrable) ; cohérence du statut entre tous mes appareils.

---

## 6. Amis

### FRD-01 — Liste d'amis et demande par tag
**En tant qu'** utilisateur connecté, **je veux** voir mes amis triés alphabétiquement, les rechercher par pseudo, envoyer une demande d'ami via un tag, retirer un ami (double confirmation), **afin de** gérer mon cercle.

**Critères d'acceptation :**
- Given la liste d'amis, Then les amis sont triés par ordre alphabétique du pseudo ; une barre de recherche filtre en direct par pseudo.
- Given un ami dans la liste, Then deux actions « Envoyer un MP » et « Retirer l'ami » sont disponibles.
- Given « Retirer l'ami », When je clique, Then une fenêtre contextuelle demande confirmation DEUX fois avant l'exécution ; la relation, les partages d'emojis/soundboards en cours et l'autorisation live-chat sont supprimés.
- Given un tag complet `pseudo#1234`, When je l'entre dans « Ajouter un ami », Then une demande part si le couple existe et n'est pas déjà en relation (sinon message explicite sans révéler l'existence du compte).
- Given un tag inexistant, When je valide, Then le message reste volontairement ambigu (« aucune demande envoyée »).

**Points d'attention :** limitation du nombre de demandes simultanées en attente (ex. 10) ; une demande refusée reste refusable silencieusement (le demandeur voit juste « en attente ») ; anti-harcèlement : blocage possible (FRD-03).

### FRD-02 — Gérer les demandes reçues 🆕
**En tant qu'** utilisateur, **je veux** voir les demandes d'amitié reçues et les accepter ou les refuser, **afin de** contrôler qui m'ajoute.

**Critères d'acceptation :**
- Given des demandes en attente, Then un badge indique leur nombre sur l'entrée « Amis ».
- Given une demande reçue, When je clique « Accepter », Then la relation passe à « amis » et la conversation privée devient disponible.
- Given une demande reçue, When je clique « Refuser », Then la demande disparaît ; le demandeur ne reçoit pas de notification (silence volontaire).

**Points d'attention :** expiration automatique des demandes sans réponse après 30 jours ; possibilité de refuser silencieusement sans que le demandeur puisse distinguer refus et expiration.

### FRD-03 — Bloquer un utilisateur 🆕
**En tant qu'** utilisateur, **je veux** bloquer un utilisateur, **afin de** ne plus recevoir ni ses messages, ni ses demandes, ni ses live-chats.

**Critères d'acceptation :**
- Given le profil d'un utilisateur, When je choisis « Bloquer », Then la relation passe à « bloquée » : ses messages n'apparaissent plus dans mes salons communs (remplacés par un espaceur « message masqué »), il ne peut plus m'ajouter ni me joindre.
- Given un utilisateur bloqué, When il tente de m'envoyer un message privé, Then son envoi échoue avec un message générique.
- Given un blocage actif, When je décide de débloquer, Then l'utilisateur redevient un inconnu (plus ami) : une nouvelle demande d'ami est nécessaire.

**Points d'attention :** le blocage est unidirectionnel et discret (pas de notification) ; un utilisateur bloquant ne peut pas envoyer de live-chat à la personne bloquée (cohérent avec le document live-chat).

---

## 7. Messages & groupes privés

### MP-01 — Liste des messages et groupes privés
**En tant qu'** utilisateur connecté, **je veux** voir mes conversations existantes, en rechercher, en démarrer une nouvelle avec un ami (MP) ou créer un groupe privé (plusieurs utilisateurs, nom, icône facultative), **afin d'** organiser mes discussions.

**Critères d'acceptation :**
- Given la liste, Then les conversations sont triées par dernier message reçu ; l'avatar, le nom, un aperçu du dernier message et un badge de non-lus sont affichés.
- Given la recherche, When je tape, Then les conversations (et amis éligibles) sont filtrées en direct.
- Given « Nouvelle conversation », When je choisis un seul ami, Then un MP s'ouvre (canal `dm` à 2 membres exactement).
- Given « Nouveau groupe », When je choisis au moins 2 autres amis, un nom (obligatoire) et une icône (facultative), Then le groupe privé est créé (canal `group_dm`), j'en suis propriétaire.
- Given un ami retiré de mes relations entre-temps, Then il n'apparaît plus dans les sélecteurs de création.

**Points d'attention :** une seule conversation MP possible par paire d'amis (l'ouvrir recrée/retrouve la même) ; limite de membres par groupe privé (ex. 10) adaptée à l'usage familial.

### MP-02 — Quitter ou supprimer un groupe privé 🆕
**En tant que** membre d'un groupe privé, **je veux** quitter le groupe, et en tant que propriétaire, le supprimer pour tous, **afin de** nettoyer mes conversations.

**Critères d'acceptation :**
- Given un groupe dont je suis simple membre, When je quitte, Then je n'y ai plus accès ; l'historique reste pour les autres membres.
- Given un groupe dont je suis propriétaire, When je le supprime, Then une confirmation explicite (« supprime le groupe et l'historique pour TOUS les membres ») est requise ; tous les membres perdent l'accès.
- Given un propriétaire qui quitte sans supprimer, Then la propriété est transférée automatiquement au membre le plus ancien (ou à un membre désigné).

### MP-03 — Gérer les membres d'un groupe privé 🆕
**En tant que** propriétaire d'un groupe privé, **je veux** ajouter/retirer des membres, renommer le groupe, changer son icône, **afin de** maintenir le groupe pertinent.

**Critères d'acceptation :**
- Given les réglages du groupe, Then ajouter (parmi mes amis), retirer, renommer (nom 1–100 caractères) et changer l'icône sont accessibles au propriétaire.
- Given un retrait de membre, Then le membre concerné perd l'accès et les futurs messages ; l'historique antérieur reste inaccessible pour lui.
- Given un ajout de membre, Then le nouvel entrant voit l'historique à partir de son arrivée (ou intégral — décision produit à confirmer, l'option « historique visible dès l'arrivée » est recommandée pour un usage entre amis).

**Points d'attention :** notification système dans le groupe pour chaque arrivée/départ ; seuls des amis du propriétaire peuvent être ajoutés.

---

## 8. Messagerie (salons, MP, groupes)

### MSG-01 — Historique des messages paginé
**En tant qu'** utilisateur connecté dans un salon textuel, un MP ou un groupe privé, **je veux** voir les 30 derniers messages et charger les 30 précédents en remontant, **afin de** naviguer l'historique sans saturer mon appareil.

**Critères d'acceptation :**
- Given l'ouverture d'une conversation, Then les 30 derniers messages sont chargés et je suis positionné en bas.
- Given un scroll vers le haut jusqu'au message le plus ancien affiché, Then le lot des 30 messages précédents est chargé et inséré sans saut visuel (indicateur de chargement discret).
- Given un message supprimé, Then il apparaît comme « message supprimé » (contenu retiré) afin de préserver le fil.
- Given une connexion lente, Then les lots se chargent séquentiellement sans doublon ni trou.

**Points d'attention :** pagination « keyset » côté serveur (index `channel_id, created_at, id`) — jamais de `OFFSET` qui se dégrade ; timestamp serveur comme référence d'ordre.

### MSG-02 — Rédiger un message (markdown + pièces jointes)
**En tant qu'** utilisateur connecté dans un salon textuel, MP ou groupe privé, **je veux** écrire un message avec du markdown et jusqu'à 10 fichiers/intégrations de 50 Mo maximum chacun, **afin de** m'exprimer richement.

**Critères d'acceptation :**
- Given la zone d'écriture, When j'envoie un message (Entrée / bouton), Then il apparaît immédiat dans le fil avec mon avatar et l'heure ; le markdown (gras, italique, souligné, barré, code, blocs de code, citations, liens, listes, titres limités) est rendu.
- Given un markdown invalide ou incomplet, Then le rendu dégrade proprement en texte brut (jamais d'erreur bloquante).
- Given l'ajout de pièces jointes, Then jusqu'à 10 fichiers par message, 50 Mo maximum chacun ; une barre de progression puis une miniature (image/vidéo) ou une carte de fichier s'affichent.
- Given un dépassement (11e fichier ou fichier > 50 Mo), Then l'ajout est refusé avec un message clair.
- Given un envoi lent, Then le message reste modifiable annulable tant que l'envoi n'est pas confirmé.

**Points d'attention :** assainissement strict du markdown côté client ET serveur (pas de HTML brut, pas de scripts — le rendu est un sous-ensemble markdown sûr) ; stockage des fichiers sur l'objet-storage avec URL signées à durée de vie limitée ; antivirus/analyse MIME optionnels ; liens d'image intégrés en aperçu (intégration) comptés dans la limite de 10.

### MSG-03 — Réagir avec un emoji
**En tant qu'** utilisateur connecté dans un salon textuel, MP ou groupe privé, **je veux** ajouter une réaction emoji à un message, **afin de** réagir rapidement sans écrire.

**Critères d'acceptation :**
- Given un message, When j'ouvre son menu et choisis « Ajouter une réaction », Then le sélecteur d'emojis s'ouvre (Unicode + mes emojis personnalisés).
- Given une réaction posée, Then le compteur de la réaction s'incrémente et mon pseudo apparaît dans la liste des réagissants.
- Given une réaction que j'ai déjà posée, When je reclique dessus, Then ma réaction est retirée (toggle).
- Given un emoji personnalisé supprimé depuis, Then la réaction affiche un rendu dégradé « emoji inconnu ».

**Points d'attention :** limite d'emojis distincts par message (ex. 20) ; les réactions sont éphémères à l'affichage mais persistantes en base.

### MSG-04 — Copier un message
**En tant qu'** utilisateur connecté dans un salon textuel, MP ou groupe privé, **je veux** copier un message et son markdown source, **afin de** le réutiliser ailleurs.

**Critères d'acceptation :**
- Given le menu d'un message, When je choisis « Copier le texte », Then le texte affiché (rendu) est copié.
- Given le menu d'un message, When je choisis « Copier le markdown », Then le contenu source (markdown brut) est copié.

### MSG-05 — Répondre à un message
**En tant qu'** utilisateur connecté dans un salon textuel, MP ou groupe privé, **je veux** répondre à un message précis, **afin de** garder le fil de la discussion.

**Critères d'acceptation :**
- Given le menu d'un message, When je choisis « Répondre », Then ma zone d'écriture affiche un cadre avec l'auteur et un extrait du message visé (tronqué si trop long).
- Given un message envoyé en réponse, Then il apparaît avec le cadre de référence au-dessus.
- Given un clic sur le cadre de référence, Then la vue remonte au message d'origine qui est mis en surbrillance temporairement.
- Given le message d'origine supprimé depuis, Then le cadre affiche « message supprimé » et le clic ne remonte plus.

**Points d'attention :** une seule référence par réponse (pas de fil de réponses imbriquées — hors périmètre, version 1) ; charger le contexte si le message d'origine n'est pas dans les 30 chargés.

### MSG-06 — Partager un emoji ou une soundboard
**En tant qu'** utilisateur connecté dans un salon textuel, MP ou groupe privé, **je veux** partager un de mes emojis ou soundboards via un bouton à droite de la zone d'écriture, **afin que** les destinataires puissent l'ajouter à leur bibliothèque d'un clic.

**Critères d'acceptation :**
- Given le bouton de partage, When je clique, Then le sélecteur s'ouvre sur mes emojis et soundboards personnels.
- Given un emoji partagé, Then un message spécial s'affiche : cadre avec l'image de l'emoji, son nom, et un bouton « Ajouter ».
- Given une soundboard partagée, Then le cadre affiche le lecteur audio (pré-écoute), son nom et le bouton « Ajouter ».
- Given un clic sur « Ajouter » (destinataire), Then l'élément rejoint SA bibliothèque personnelle (enregistrement d'un partage côté serveur).
- Given un partage d'un élément que je possède déjà, Then le bouton affiche « Déjà dans ma bibliothèque » (grisé).

**Points d'attention :** le créateur qui supprime l'élément le retire aussi des bibliothèques où il avait été ajouté (cf. PERS-04) ; les boutons « Ajouter » des anciens messages deviennent inactifs avec un libellé explicite.

### MSG-07 — Éditer un message 🆕
**En tant qu'** auteur d'un message, **je veux** modifier mon message, **afin de** corriger une erreur sans le supprimer.

**Critères d'acceptation :**
- Given un de mes messages, When j'ouvre le menu, Then « Modifier » est disponible.
- Given une modification enregistrée, Then le message affiche le nouveau contenu avec la mention « modifié » et l'heure d'édition.
- Given une modification, Then les autres membres connectés voient la mise à jour en temps réel.

**Points d'attention :** la modification est réservée à l'auteur (ou à la modération avec mention différente) ; conserver le markdown source édité ; fenêtre d'édition éventuelle (ex. illimitée entre amis).

### MSG-08 — Supprimer un message 🆕
**En tant qu'** auteur d'un message, **je veux** supprimer mon message, **afin de** retirer une erreur ou un contenu malencontreux.

**Critères d'acceptation :**
- Given un de mes messages, When je choisis « Supprimer » (confirmation légère « Supprimer le message ? »), Then le contenu disparaît, remplacé par « message supprimé ».
- Given une suppression, Then les réactions au message sont retirées, les réponses conservent leur cadre « message supprimé ».

**Points d'attention :** suppression douce en base (audit, modération) ; la modération peut supprimer tout message (permission adaptée, action journalisée).

### MSG-09 — Indicateur de saisie 🆕
**En tant qu'** utilisateur dans une conversation, **je veux** voir que mon interlocuteur est en train d'écrire, **afin de** ne pas couper sa réponse.

**Critères d'acceptation :**
- Given un membre en train de taper (frappe dans les 5 dernières secondes), Then « X est en train d'écrire… » s'affiche au-dessus de la zone d'écriture.
- Given plusieurs membres, Then la liste est agrégée (« X, Y et Z écrivent… »).
- Given une pause de saisie > 5 s, Then l'indicateur disparaît.

**Points d'attention :** l'événement ne transite QUE par le temps réel (jamais persisté) ; désactivable dans les préférences (discrétion).

### MSG-10 — Repères de lecture (non-lus) 🆕
**En tant qu'** utilisateur, **je veux** que le nombre de messages non lus d'une conversation soit visible et remis à zéro quand je lis, **afin de** suivre ce que j'ai manqué.

**Critères d'acceptation :**
- Given une conversation avec des messages non lus depuis ma dernière lecture, Then un badge numérique s'affiche sur la conversation (et l'icône de l'app).
- Given l'ouverture de la conversation et l'affichage des messages, Then mon repère de lecture avance et le badge se met à jour.
- Given une mention explicite de mon pseudo, Then le badge se distingue (couleur accent).

**Points d'attention :** repère stocké par membre de canal (dernier message lu) ; synchronisation multi-appareils.

---

## 9. Serveurs

### SRV-01 — Accès aux salons du serveur général
**En tant qu'** utilisateur connecté, **je veux** accéder aux salons textuels et vocaux du serveur général de l'application, **afin d'** échanger avec la communauté.

**Critères d'acceptation :**
- Given la zone serveur, Then les catégories, salons textuels et salons vocaux du serveur général sont listés (catégories repliables).
- Given un salon textuel, When je le sélectionne, Then je deviens lecteur des messages ; l'écriture suit les permissions du salon.
- Given un salon vocal, Then les membres connectés sont affichés dessous (icône et pseudo — cf. VOC-02).
- Given un compte fraîchement créé, Then l'accès au serveur général est immédiat (adhésion automatique).

**Points d'attention :** le tri et le regroupement reposent sur (catégorie, position) — cf. schéma BDD ; salons masqués si permissions insuffisantes.

### SRV-02 — Créer un serveur 🆕 (futur)
**En tant qu'** utilisateur, **je veux** créer un nouveau serveur (nom, icône facultative), **afin de** disposer de mon propre espace pour une communauté.

**Critères d'acceptation :**
- Given la liste de mes serveurs, When je clique « Créer un serveur », Then un nom (1–100 caractères) et une icône (facultative) me sont demandés.
- Given une création validée, Then le serveur est créé, j'en suis propriétaire, les salons par défaut (un textuel, un vocal) et le rôle par défaut sont générés.
- Given le serveur créé, Then il apparaît dans ma barre de serveurs et devient invitable (SRV-03).

**Points d'attention :** quota de serveurs créés par utilisateur (ex. 5) ; modèle de rôles minimal au départ (rôle par défaut = accès lecture/écriture de base).

### SRV-03 — Inviter et rejoindre via code 🆕 (futur)
**En tant que** propriétaire d'un serveur, **je veux** générer des codes d'invitation (limités en usages et/ou dans le temps), **afin de** contrôler les entrées ; **en tant qu'** utilisateur invité, **je veux** rejoindre un serveur avec un code.

**Critères d'acceptation :**
- Given les réglages du serveur, When je crée une invitation, Then je peux fixer un nombre max d'utilisations et une expiration ; un code court est généré (copiable).
- Given un code valide, When un utilisateur le saisit, Then il rejoint le serveur avec le rôle par défaut.
- Given un code épuisé ou expiré, When on le saisit, Then un message d'erreur s'affiche.

**Points d'attention :** la révocation d'une invitation ne retire pas les membres déjà entrés ; le serveur général n'est pas quittable (par conception).

### SRV-04 — Gérer les salons et rôles d'un serveur 🆕 (futur)
**En tant que** propriétaire (ou membre disposant de la permission), **je veux** créer, renommer, déplacer, supprimer des salons et catégories, et gérer les rôles et permissions, **afin d'** organiser mon serveur.

**Critères d'acceptation :**
- Given la gestion des salons, Then créer (type textuel/vocal, catégorie, position), renommer, supprimer (avec confirmation) sont disponibles selon les permissions.
- Given la suppression d'un salon, Then ses messages sont supprimés (cascade) après confirmation explicite.
- Given la gestion des rôles, Then créer un rôle (nom, couleur, permissions par masque binaire), l'attribuer/retirer à un membre est possible.
- Given un membre sans permission « gérer les salons », Then les actions correspondantes sont invisibles.

**Points d'attention :** permissions en masque binaire (bitfield) conformes au schéma ; permission « administrer » = délégation quasi totale (prudence) ; journaliser les actions sensibles côté serveur.

---

## 10. Vocal & appels

### VOC-01 — Appel vocal privé
**En tant qu'** utilisateur dans un MP ou un groupe privé, **je veux** lancer un appel vocal avec le membre du MP ou les membres du groupe, **afin de** parler sans passer par un serveur.

**Critères d'acceptation :**
- Given un MP, When je clique « Appeler », Then une sonnerie part chez l'interlocuteur ; s'il décroche, le canal vocal privé s'ouvre pour nous deux.
- Given un groupe privé, When je lance l'appel, Then tous les membres sont invités (sonnerie) et peuvent rejoindre en cours.
- Given un appel refusé ou manqué (30 s sans réponse), Then l'appelant est notifié et l'appel se referme.
- Given un appel en cours, Then les fonctionnalités du vocal s'appliquent (VOC-04 à VOC-10).

**Points d'attention :** un appel = un salon vocal éphémère rattaché à la conversation ; reconnexion automatique en cas de coupure réseau (< 30 s).


### VOC-02 — Voir les participants d'un salon vocal
**En tant qu'** utilisateur connecté dans le serveur général, **je veux** voir sous chaque salon vocal les utilisateurs actuellement connectés (icône et pseudo), **afin de** choisir qui rejoindre.

**Critères d'acceptation :**
- Given la liste des salons, Then les membres en vocal apparaissent sous le salon concerné, mis à jour en temps réel (arrivées/départs).
- Given un membre muet, Then son statut vocal (muet/sourdine/caméra/partage) est visible en pastille.

### VOC-03 — Rejoindre un salon vocal
**En tant qu'** utilisateur connecté, **je veux** me connecter à un salon vocal pour discuter au micro avec les membres présents.

**Critères d'acceptation :**
- Given un salon vocal non plein, When je clique dessus, Then je rejoins le salon ; mon entrée est annoncée discrètement aux participants.
- Given un salon plein (limite `user_limit`), Then l'entrée est refusée avec un message clair.
- Given la permission « parler » manquante, Then je peux écouter mais pas émettre.

**Points d'attention :** une seule connexion vocale active par compte (rejoindre un autre salon déconnecte du précédent) ; demande de permission micro au niveau système si jamais accordée.

### VOC-04 — Choisir ses périphériques
**En tant qu'** utilisateur en salon vocal ou en appel, **je veux** choisir mes périphériques d'entrée (micro) et de sortie (audio), **afin d'** adapter le son à mon matériel.

**Critères d'acceptation :**
- Given les réglages vocaux, Then les périphériques détectés sont listés (micro, sortie) et sélectionnables à chaud, avec test de niveau (VU-mètre).
- Given un périphérique débranché, Then le système bascule sur le périphérique par défaut sans coupure de session.

### VOC-05 — Se mettre en sourdine / couper le micro
**En tant qu'** utilisateur en salon vocal ou en appel, **je veux** désactiver mon micro, le son, ou les deux, **afin de** contrôler ce que j'émets et ce que j'entends.

**Critères d'acceptation :**
- Given les boutons du cadre vocal, Then micro et son se coupent/rétablissent par un clic, avec retour visuel clair (icône barrée, pastille sur mon avatar).
- Given mon micro coupé, Then personne ne m'entend ; given le son coupé, Then je n'entends plus personne MAIS les autres m'entendent encore.

**Points d'attention :** la sourdine n'entraîne PAS la coupure du micro (comportement Discord) ; persistance des choix entre les sessions.

### VOC-06 — Déclencher une soundboard
**En tant qu'** utilisateur en salon vocal ou en appel, **je veux** jouer une soundboard que j'ai créée ou reçue, via un bouton ouvrant mon panneau ou via raccourci, **afin d'** animer la conversation.

**Critères d'acceptation :**
- Given le panneau soundboard, Then mes sons s'affichent (nom, durée) et se jouent pour TOUS les participants au clic (ou raccourci clavier configurable).
- Given un son en cours, Then le re-déclenchement du même son le relance depuis le début.
- Given un participant qui m'a rendu ses soundboards muettes (VOC-10), Then il ne les entend pas.

**Points d'attention :** anti-spam : cooldown de déclenchement (ex. 1 son toutes les 3 s) ; le volume respecte le réglage propre de chaque soundboard.

### VOC-07 — Partager son écran
**En tant qu'** utilisateur en salon vocal ou en appel, **je veux** partager mon écran ou une application précise, **afin de** montrer ce que je fais.

**Critères d'acceptation :**
- Given le bouton de partage, When je clique, Then un cadre de configuration s'ouvre : FPS, qualité, source (application ou écran complet).
- Given un partage actif, Then mon flux remplace/complete mon cadre dans la vue (badge « partage en cours »), et les autres peuvent le plein-écran.
- Given l'arrêt du partage, Then le flux disparaît pour tous sans couper mon audio.

**Points d'attention :** limites par plateforme : sur PC, sélection d'application native ; sur Android, partage de tout l'écran via l'API système ; sur iOS v1, le partage d'écran en direct est complexe (reporté — cf. guide technique) ; plafonner FPS/qualité selon l'abonnement matériel du serveur (usage entre amis).

### VOC-08 — Vue du salon vocal (grille adaptative)
**En tant qu'** utilisateur en salon vocal ou en appel, **je veux** une vue en cadres reprenant le fond de profil, l'icône et le pseudo de chaque participant, avec une organisation adaptée au nombre et des boutons d'action en bas, **afin de** voir et contrôler la discussion.

**Critères d'acceptation :**
- Given N participants, Then les cadres se réorganisent automatiquement (taille et disposition selon N) en préservant les fonds de profil, l'icône centrée, le pseudo en bas à gauche.
- Given la barre d'action, Then les boutons : se déconnecter, se mettre en sourdine, couper le micro, partager son écran, activer sa caméra, ouvrir la liste des soundboards, sont présents.
- Given un participant qui parle, Then une animation d'élocution l'entoure (cf. OVL-02 pour l'overlay ; même retour dans la vue).

**Points d'attention :** performance : limiter les rendus vidéo simultanés (préférer « haut-parleur actif » si > 9 participants) ; fonds de profil mis en cache.

### VOC-09 — Activer sa caméra
**En tant qu'** utilisateur en salon vocal ou en appel, **je veux** activer ma caméra qui remplace mon cadre (fond + icône) par mon flux vidéo, **afin de** me montrer.

**Critères d'acceptation :**
- Given le bouton caméra, When je l'active, Then mon cadre devient mon flux (avec miroir local pour moi) ; les autres voient le flux non miroir.
- Given la caméra désactivée, Then mon cadre revient au fond de profil + icône.

**Points d'attention :** demande de permission caméra au niveau système ; qualité adaptée à la bande passante.

### VOC-10 — Menu contextuel d'un participant
**En tant qu'** utilisateur en salon vocal ou en appel, **je veux** cliquer droit sur un participant (liste sous le salon ou cadre dans la vue) pour accéder à : profil, régler son volume, le rendre muet pour moi, rendre ses soundboards muettes, **afin de** gérer mon confort audio.

**Critères d'acceptation :**
- Given un clic droit (ou appui long mobile) sur un participant, Then le menu propose : « Profil », « Volume de l'utilisateur » (curseur 0–200 %), « Rendre muet » (je ne l'entends plus), « Rendre ses soundboards muettes ».
- Given « Rendre muet », Then je ne l'entends plus mais les autres l'entendent encore (réglage purement local).

**Points d'attention :** ces réglages sont locaux et persistés par appareil ; le « rendre muet » local est distinct du server_mute infligé par la modération.

---

## 11. Activité de jeu 🆕 (futur)

### GAM-01 — Afficher son activité
**En tant qu'** utilisateur, **je veux** que l'application détecte le jeu auquel je joue et l'affiche comme activité, **afin de** partager ce que je fais sans le taper.

**Critères d'acceptation :**
- Given l'application lancée (PC) et la détection activée, When je lance un jeu reconnu, Then mon activité passe à « Joue à X » sur mon profil, dans la liste d'amis et mon cadre en vocal.
- Given la fermeture du jeu, Then l'activité disparaît après quelques secondes.
- Given un jeu inconnu, Then l'activité peut être déclarée manuellement (saisie libre) ou ignorée.

**Points d'attention :** détection par énumération des processus locaux (PC) avec base de correspondance nom de processus → nom de jeu (table `activity`) ; sur mobile, déclaration manuelle uniquement ; durée minimale d'activité avant affichage (anti-flicker, ex. 60 s).

### GAM-02 — Voir l'activité des autres
**En tant qu'** utilisateur, **je veux** voir l'activité de mes amis (liste d'amis, profil, cadre vocal), **afin de** savoir à quoi ils jouent et les rejoindre.

**Critères d'acceptation :**
- Given un ami actif, Then son activité s'affiche sous son pseudo (liste d'amis) et sur son cadre vocal.
- Given un ami qui masque son activité, Then rien ne s'affiche (cf. GAM-03).

### GAM-03 — Masquer son activité
**En tant qu'** utilisateur, **je veux** désactiver l'affichage public de mon activité (tout ou partie), **afin de** préserver ma vie privée.

**Critères d'acceptation :**
- Given les paramètres de confidentialité, Then un interrupteur « Afficher mon activité » (activé par défaut) contrôle la publication de l'activité.
- Given l'interrupteur désactivé, Then mon activité n'est visible par personne (même en vocal), sans affects pour moi.

---

## 12. Overlay vocal 🆕 (futur)

### OVL-01 — Overlay quand je quitte l'application
**En tant qu'** utilisateur en salon vocal (PC), **je veux** qu'un overlay persistant liste les participants quand je change d'application, **afin de** continuer à voir qui est présent sans revenir sur l'app.

**Critères d'acceptation :**
- Given une session vocale active sur PC, When je passe sur une autre application (perte de focus / minimisation), Then l'overlay apparaît : petite fenêtre toujours au-dessus listant icône + pseudo des participants.
- Given mon retour sur l'application, Then l'overlay se referme automatiquement.
- Given la déconnexion vocale, Then l'overlay disparaît.
- Given l'overlay, Then je peux le déplacer et le faire disparaître via un réglage (option « overlay activé » dans les paramètres vocaux).

**Points d'attention :** fenêtre transparente always-on-top (gestionnaire de fenêtres) ; sur mobile, équivalent = mode Picture-in-Picture Android / tuile iOS (périmètre v1 : Android PiP, iOS reporté) ; le comportement Wayland (Linux) peut différer de X11 — cf. guide technique.

### OVL-02 — Animation d'élocution dans l'overlay
**En tant qu'** utilisateur en vocal, **je veux** que l'opacité/l'accentuation du cadre d'un participant augmente quand il parle, **afin de** suivre qui parle du coin de l'œil.

**Critères d'acceptation :**
- Given l'overlay (ou la vue vocale), When un participant parle (événement de détection d'activité audio), Then son cadre s'intensifie (opacité accrue / bordure accentuée) avec une transition douce (~200 ms).
- Given l'arrêt de la parole, Then le cadre revient à l'état de repos avec la même transition.

**Points d'attention :** la détection « parle » est fournie par le moteur vocal (événements speaking du SFU), jamais par analyse locale ; lisibilité sur fond clair ET sombre.

### OVL-03 — Contrôler le vocal depuis l'overlay
**En tant qu'** utilisateur, **je veux** me couper le micro ou me déconnecter directement depuis l'overlay, **afin de** réagir sans rouvrir l'application.

**Critères d'acceptation :**
- Given l'overlay, Then des boutons minimalistes (micro, quitter) sont accessibles au survol.
- Given « Quitter », Then la session vocale se ferme et l'overlay disparaît.

---

## 13. Live-chat 🆕 (intégration future)

> Rappel du besoin (document d'origine) : le live-chat permet d'envoyer sons, images, textes et vidéos en **overlay sur l'écran d'un ami**. Il se paramètre (réception, plein écran, cooldown), s'édite (durée, position/taille des éléments), s'enregistre et se réutilise.

### LC-01 — Paramètres du live-chat
**En tant qu'** utilisateur, **je veux** configurer ma réception du live-chat : accepter ou non d'en recevoir, autoriser par ami, autoriser en plein écran exclusif, définir un cooldown entre deux live-chats reçus, **afin de** garder la maîtrise de mon écran.

**Critères d'acceptation :**
- Given le panneau de paramètres live-chat, Then je trouve : « J'accepte de recevoir du live-chat » (si NON : je ne peux plus en envoyer non plus), la liste de mes amis avec un toggle live-chat individuel, « Accepter quand je suis en plein écran exclusif », « Cooldown entre deux live-chats reçus ».
- Given mon toggle global désactivé, When quelqu'un tente de m'envoyer un live-chat, Then l'envoi est refusé (et je ne peux plus en envoyer moi-même).
- Given le toggle d'un ami désactivé (de mon côté), Then ni lui ne peut m'en envoyer, ni moi je ne peux lui en envoyer (symétrie exigée par le document d'origine).
- Given un cooldown défini (ex. 60 s), Then tout live-chat reçu dans la fenêtre est refusé silencieusement côté expéditeur (« cooldown actif »).

**Points d'attention :** ces réglages vivent dans `user_settings` (globaux) et `friendship.live_chat_enabled` (par ami) ; renommer le cooldown « délai de protection » côté UI pour la compréhension.

### LC-02 — Envoyer un live-chat : sélection du destinataire
**En tant qu'** utilisateur, **je veux** lancer l'envoi d'un live-chat par un bouton dédié qui me présente la liste des amis autorisés, **afin de** choisir à qui l'envoyer.

**Critères d'acceptation :**
- Given le bouton « Envoyer un live-chat », When je clique, Then la liste de mes amis avec live-chat autorisé (des deux côtés) s'affiche ; les amis non autorisés apparaissent grisés avec la raison.
- Given un ami sélectionné, Then j'accède à la zone de configuration (LC-03) ou à mes live-chats enregistrés (LC-05).

### LC-03 — Éditeur de live-chat
**En tant qu'** utilisateur, **je veux** composer un live-chat dans un cadre représentant l'écran : définir la durée, ajouter/redimensionner/positionner des vidéos, images et textes (police + taille), ajouter des sons (durée, décalage de départ), **afin de** créer l'effet souhaité chez mon ami.

**Critères d'acceptation :**
- Given l'éditeur, Then un cadre ratio écran (~16:9) sert de zone de composition ; la durée totale est réglable (1 s à 5 min).
- Given un élément ajouté (texte/image/vidéo/son), Then je peux le déplacer (glisser), le redimensionner (poignées), et il reste dans les limites du cadre.
- Given un texte, Then je peux choisir la police (liste blanche) et la taille (8–72 pt) ; l'aperçu est fidèle au rendu final.
- Given un son, Then je règle sa durée de lecture et son décalage de départ (à combien de temps dans le live-chat il commence).
- Given la prévisualisation, Then un bouton « Prévisualiser » rejoue le live-chat dans le cadre exactement comme le destinataire le verra.
- Given un live-chat non conforme (durée < somme des éléments), Then la validation est bloquée avec un message précis.

**Points d'attention :** coordonnées RELATIVES (0–1) en base pour l'indépendance de résolution ; taille limite des médias (reprendre les limites MSG-02 : 50 Mo) ; sauvegarde automatique du brouillon.

### LC-04 — Enregistrer un live-chat
**En tant qu'** utilisateur, **je veux** enregistrer un live-chat pour le réutiliser plus tard, **afin de** ne pas recomposer mes effets favoris.

**Critères d'acceptation :**
- Given un live-chat composé (ou modifié), When je clique « Enregistrer », Then il rejoint ma bibliothèque de live-chats enregistrés (nom obligatoire).
- Given ma bibliothèque, Then je peux renommer, dupliquer et supprimer mes live-chats enregistrés.

### LC-05 — Envoyer un live-chat enregistré
**En tant qu'** utilisateur, **je veux** envoyer directement un live-chat enregistré, ou en modifier une copie avant envoi sans altérer l'original, **afin de** gagner du temps tout en gardant la flexibilité.

**Critères d'acceptation :**
- Given un live-chat enregistré sélectionné, When je choisis « Envoyer directement », Then il part tel quel au destinataire choisi.
- Given un live-chat enregistré sélectionné, When je choisis « Modifier avant envoi », Then l'éditeur s'ouvre sur une COPIE ; les modifications n'affectent PAS la version enregistrée.
- Given la copie modifiée, When je clique « Enregistrer les modifications » avant d'envoyer, Then l'original enregistré est mis à jour (comme un premier enregistrement) puis l'envoi se fait avec la version modifiée.

**Points d'attention :** distinguer clairement « Enregistrer (remplace l'original) » et « Enregistrer une copie » pour éviter les pertes ; quota de live-chats enregistrés par utilisateur (ex. 20).

### LC-06 — Composer plus tard
**En tant qu'** utilisateur, **je veux** configurer et enregistrer un live-chat sans destinataire, **afin de** le préparer pour plus tard.

**Critères d'acceptation :**
- Given le bouton « Envoyer un live-chat », Then une entrée « Composer un live-chat » permet d'ouvrir l'éditeur sans choisir de destinataire.
- Given un live-chat composé sans envoi, Then « Enregistrer » l'ajoute à ma bibliothèque (LC-04).

### LC-07 — Recevoir et afficher un live-chat
**En tant que** destinataire, **je veux** que le live-chat reçu s'affiche en overlay pendant sa durée exacte, **afin de** profiter de l'effet sans action de ma part.

**Critères d'acceptation :**
- Given un live-chat accepté reçu, Then un overlay plein écran (ou fenêtré selon plateforme) affiche chaque élément : position, taille, timing de départ et durée respectés à l'échelle de MON écran.
- Given la fin de la durée, Then l'overlay disparaît automatiquement.
- Given un overlay en cours, Then un bouton discret « Fermer » (ou Échap) me permet de l'interrompre.
- Given un live-chat contenant uniquement un son, Then AUCUN overlay visuel n'est ouvert : le son est joué directement (comportement du document d'origine).

### LC-08 — Live-chat et plein écran exclusif
**En tant que** destinataire en plein écran exclusif (jeu), **je veux** que mon réglage décide du comportement : sortie du plein écran pour afficher le live-chat, ou simple lecture du son, **afin de** ne pas être interrompu en pleine partie.

**Critères d'acceptation :**
- Given « Accepter en plein écran » activé, When un live-chat visuel arrive pendant mon plein écran exclusif, Then le plein écran est quitté pour afficher l'overlay, puis mon application retrouve le focus ensuite.
- Given « Accepter en plein écran » désactivé, When un live-chat arrive, Then la partie VISUELLE est ignorée silencieusement ; si le live-chat contient un son, il est joué (sans rien quitter).
- Given un live-chat son seul, Then le son est toujours joué, quel que soit le réglage (conforme au document d'origine).

**Points d'attention :** la sortie de plein écran exclusif dépend de l'OS et du jeu (risque de bandes noires / minimisation) ; sur Wayland la manipulation du focus est restreinte — prévenir dans la doc utilisateur.

### LC-09 — Historique et cooldown côté destinataire
**En tant que** destinataire, **je veux** que mon cooldown bloque les live-chats trop rapprochés, **afin de** ne pas être spamé.

**Critères d'acceptation :**
- Given un live-chat reçu il y a moins que mon cooldown, When un autre arrive, Then il est refusé ; l'expéditeur voit « cooldown actif chez X ».
- Given un live-chat refusé, Then il N'EST PAS rejoué automatiquement après le cooldown (ni mis en file).

**Points d'attention :** le contrôle s'appuie sur l'index `(receiver_id, sent_at DESC)` de `live_chat_sent` ; le refus consomme quand même la tentative côté historique d'envoi (audit léger).

---

## 14. Panneau d'administration (back-office)

> **Accès (ADR-0003) :** le BO est une interface web distincte, hébergée sur le serveur (Docker), **servie uniquement en local** (`127.0.0.1:8080`) — accessible depuis le serveur lui-même (navigateur local ou session bureau à distance) ou via une connexion directe à distance (tunnel SSH : `ssh -L 8080:localhost:8080 utilisateur@serveur`). Il n'est jamais exposé sur Internet (aucun sous-domaine public). La connexion exige un compte disposant du rôle administrateur et l'A2F. Chaque action sensible est journalisée dans `audit_log`.

### ADM-01 — Connexion au back-office
**En tant qu'** administrateur, **je veux** me connecter au BO avec mon compte administrateur et une A2F obligatoire, **afin de** gérer l'application de façon sécurisée.

**Critères d'acceptation :**
- Given la page de connexion du BO, Then les identifiants + code A2F sont exigés (même si l'A2F est facultative côté application utilisateur).
- Given un compte sans rôle administrateur, Then la connexion au BO est refusée (journalisée comme tentative suspecte).
- Given 5 échecs, Then un délai croissant s'applique ; les tentatives sont journalisées (IP, horodatage).

**Points d'attention :** jamais d'inscription depuis le BO (les administrateurs sont promus depuis la base par le super-administrateur initial) ; session courte avec expiration.

---

### Module A — Modération

### MOD-01 — File des signalements
**En tant qu'** administrateur, **je veux** consulter la file des signalements utilisateurs filtrable par statut (ouvert, en cours, résolu, rejeté) et par date, **afin de** traiter les incidents dans l'ordre.

**Critères d'acceptation :**
- Given le BO, Then la file des signalements s'affiche triée par ancienneté (les plus anciens d'abord) ; des filtres (statut, période) affinent.
- Given un signalement ouvert, When je l'ouvre, Then son statut passe automatiquement à « en cours » et je deviens responsable du dossier.

### MOD-02 — Examiner un signalement
**En tant qu'** administrateur, **je veux** examiner un signalement : contenu incriminé (ou sa copie d'archive si supprimé), auteur, contexte, historique disciplinaire du compte, **afin de** décider en connaissance de cause.

**Critères d'acceptation :**
- Given un signalement ouvert, Then je vois : le message signalé (ou le snapshot conservé au moment du signalement), son auteur, son canal, le motif et le commentaire du plaignant.
- Given l'utilisateur signalé, Then un lien direct ouvre sa fiche (CSR-02) et son historique de sanctions.

### MOD-03 — Sanctionner un utilisateur
**En tant qu'** administrateur, **je veux** appliquer une sanction (avertissement, muet global temporaire, kick, bannissement temporaire ou permanent) avec un motif obligatoire, **afin de** faire respecter les règles.

**Critères d'acceptation :**
- Given une sanction choisie, Then un motif (1–1000 caractères) est OBLIGATOIRE ; les sanctions temporaires exigent une durée d'expiration.
- Given un bannissement appliqué, Then toutes les sessions de l'utilisateur sont révoquées et ses futurs accès refusés (message générique).
- Given un muet appliqué, Then l'utilisateur ne peut plus envoyer de messages ni parler en vocal jusqu'à expiration.
- Given une sanction, Then l'utilisateur concerné reçoit une notification explicative (motif, durée) et la sanction est journalisée dans l'audit.

**Points d'attention :** distinction avec les sanctions de serveur (rôles) : le BO sanctionne au niveau global ; possibilité de lever une sanction avant expiration.

### MOD-04 — Historique disciplinaire
**En tant qu'** administrateur, **je veux** consulter l'historique disciplinaire complet d'un utilisateur (sanctions passées, signalements), **afin d'** évaluer la récidive.

**Critères d'acceptation :**
- Given la fiche d'un utilisateur, Then ses sanctions (type, motif, admin, date, expiration) et signalements sont listés chronologiquement.

### MOD-05 — Journal d'audit
**En tant qu'** administrateur (super-admin), **je veux** consulter le journal d'audit de toutes les actions du BO, filtrable (admin, type d'action, cible, période), **afin de** garantir la traçabilité.

**Critères d'acceptation :**
- Given le journal, Then chaque entrée affiche : date, administrateur, action, cible, détails (avant/après), IP.
- Given un filtre, Then la recherche est rapide (index dédié) et paginée.
- Given une action sensible effectuée, Then elle apparaît dans le journal en moins d'une seconde.

**Points d'attention :** le journal est en ajout seul (immuable) ; rétention longue (ex. 1 an) avant purge automatique.

---

### Module B — Comptes & serveurs

### CSR-01 — Rechercher un utilisateur
**En tant qu'** administrateur, **je veux** rechercher un utilisateur par pseudo, tag, ou adresse mail, **afin de** retrouver rapidement un compte.

**Critères d'acceptation :**
- Given la recherche, Then les résultats affichent pseudo, tag, email, statut du compte (actif/suspendu/supprimé), date d'inscription.

### CSR-02 — Fiche d'un utilisateur
**En tant qu'** administrateur, **je veux** consulter la fiche complète d'un utilisateur (identité, email, statut, sessions, statistiques d'usage, sanctions), **afin de** instruire un dossier.

**Critères d'acceptation :**
- Given la fiche, Then les informations personnelles (email vérifié, tag), l'activité (dernière connexion, messages/jour), les sanctions et le statut sont présentés.
- Given un compte supprimé, Then la fiche reste consultable en lecture seule (mention « compte supprimé »).

### CSR-03 — Supprimer un profil
**En tant qu'** administrateur, **je veux** supprimer le profil d'un utilisateur (avec confirmation renforcée), **afin de** retirer un compte malveillant.

**Critères d'acceptation :**
- Given la fiche d'un utilisateur, When je choisis « Supprimer le profil », Then une confirmation en deux temps (motif obligatoire + saisie du tag de l'utilisateur) est exigée.
- Given la suppression, Then le compte est désactivé immédiatement, ses sessions révoquées, ses emojis/soundboards supprimés ; ses messages passent en « Utilisateur supprimé » ; l'action est journalisée.

**Points d'attention :** préférer la suspension (réversible) à la suppression ; la suppression est irréversible — cf. CPT-06 pour les effets détaillés.

### CSR-04 — Gérer le serveur par défaut
**En tant qu'** administrateur, **je veux** gérer le serveur général où tous les utilisateurs sont inscrits d'office : renommer, changer l'icône, créer/renommer/déplacer/supprimer des salons et catégories, **afin d'** entretenir l'espace commun.

**Critères d'acceptation :**
- Given l'onglet serveurs du BO, Then le serveur par défaut est identifiable en premier ; les mêmes actions de gestion que côté client sont disponibles (et journalisées).

### CSR-05 — Gérer les serveurs existants
**En tant qu'** administrateur, **je veux** inspecter et gérer tous les serveurs de l'application (membres, salons), et supprimer un serveur en cas d'abus, **afin de** garder la plateforme saine.

**Critères d'acceptation :**
- Given la liste des serveurs, Then nom, propriétaire, nombre de membres, date de création et activité sont visibles.
- Given un serveur, Then je peux inspecter ses salons et membres, contacter le propriétaire (outil de contact), ou supprimer le serveur (confirmation renforcée + motif, journalisé, membres notifiés).

### CSR-06 — Purge et rétention des données
**En tant qu'** administrateur, **je veux** purger les données anciennes : messages plus vieux qu'une date donnée (par serveur ou globalement), soundboards et emojis inutilisés ou orphelins, **afin de** maîtriser le stockage.

**Critères d'acceptation :**
- Given l'outil de purge, Then je peux sélectionner le type (messages antérieurs à X, emojis/soundboards non utilisés depuis Y / orphelins) et PRENDRE CONNAISSANCE du volume concerné avant exécution (mode simulation).
- Given une purge confirmée, Then l'exécution est progressive (par lots) avec compte-rendu final (nombre d'éléments, espace libéré) et journalisation.

**Points d'attention :** la purge des messages respecte la contrainte « auteur conservé, contenu supprimé » ou supprime les lignes selon la politique retenue (recommandé : suppression dure en lot + vacuum périodique) ; toujours en dehors des heures de pointe.

---

### Module C — Analytics

### ANA-01 — Tableau de bord d'usage
**En tant qu'** administrateur, **je veux** un tableau de bord des usages : utilisateurs actifs (jour/semaine/mois), messages envoyés par jour, nouveaux comptes, **afin de** piloter l'application.

**Critères d'acceptation :**
- Given le tableau de bord, Then des indicateurs clés (DAU, WAU, MAU, messages/jour, inscriptions/jour) s'affichent avec tendance vs période précédente et graphiques.
- Given une période, Then je peux changer la granularité (jour/semaine/mois) et l'intervalle.

### ANA-02 — Statistiques des serveurs et canaux
**En tant qu'** administrateur, **je veux** voir les serveurs et canaux les plus actifs (messages, minutes vocales), **afin de** comprendre où se joue l'activité.

**Critères d'acceptation :**
- Given la section serveurs, Then un classement (messages, participants actifs, minutes vocales) est disponible pour la période choisie.

### ANA-03 — Rétention et croissance
**En tant qu'** administrateur, **je veux** suivre la croissance (inscriptions) et la rétention (retour à J+7/J+30), **afin de** mesurer la santé de la communauté.

**Critères d'acceptation :**
- Given la section croissance, Then les cohortes d'inscription et leur taux de retour s'affichent (J+7, J+30).

### ANA-04 — Santé du vocal
**En tant qu'** administrateur, **je veux** suivre l'usage vocal : minutes cumulées, pic de participants simultanés, qualité moyenne perçue, **afin d'** ajuster les ressources du serveur.

**Critères d'acceptation :**
- Given la section vocal, Then minutes/jour, pic simultané, et taux de déconnexion anomique (pertes réseau) s'affichent.

### ANA-05 — Exporter les statistiques
**En tant qu'** administrateur, **je veux** exporter les statistiques affichées en CSV, **afin de** les analyser ailleurs.

**Critères d'acceptation :**
- Given n'importe quelle vue statistique, Then un bouton « Exporter CSV » produit un fichier téléchargé avec les données affichées (mêmes filtres/période).

**Points d'attention :** les statistiques sont calculées en lecture seule, idéalement à partir de vues matérialisées rafraîchies périodiquement (pas de requêtes lourdes à la volée sur les tables de production).

---

### Module D — Configuration système

### CFG-01 — Feature flags
**En tant qu'** administrateur, **je veux** activer/désactiver des fonctionnalités (live-chat, partage d'écran, soundboards, activité de jeu…) sans redéploiement, **afin de** réagir vite en cas de problème.

**Critères d'acceptation :**
- Given la liste des fonctionnalités, Then chaque module expose un interrupteur actif/inactif avec description et date de dernière modification.
- Given une fonctionnalité désactivée, Then les clients la masquent immédiatement (à leur prochaine synchronisation de configuration, < 1 min) et les API correspondantes refusent les requêtes.

### CFG-02 — Annonce globale
**En tant qu'** administrateur, **je veux** publier une annonce globale (titre + corps, avec expiration facultative), **afin d'** informer tous les utilisateurs (maintenance, événement).

**Critères d'acceptation :**
- Given la rédaction d'une annonce, When je publie, Then tous les utilisateurs connectés la voient (bandeau discret, non bloquant) et les connexions suivantes l'affichent aussi.
- Given une expiration atteinte, Then l'annonce disparaît automatiquement.

### CFG-03 — Mode maintenance
**En tant qu'** administrateur, **je veux** activer un mode maintenance, **afin de** couper proprement l'accès pendant une intervention.

**Critères d'acceptation :**
- Given le mode maintenance activé, Then les clients affichent une page dédiée « maintenance en cours » ; les sessions actives reçoivent un avertissement puis sont éteintes progressivement ; le BO reste accessible.
- Given le mode désactivé, Then l'accès est rétabli sans redémarrage côté client.

**Points d'attention :** prévenir par annonce (CFG-02) AVANT l'activation ; conserver l'accès BO et un canal d'urgence ; le mode maintenance vit dans `system_config`.

### CFG-04 — Supervision des services
**En tant qu'** administrateur, **je veux** consulter l'état de santé des composants serveur (API, base, cache, vocal, stockage) avec métriques de base, **afin d'** intervenir avant que les utilisateurs ne le remarquent.

**Critères d'acceptation :**
- Given la page supervision, Then chaque composant affiche son état (OK/dégradé/hors service), son temps de réponse et sa version.
- Given un composant dégradé, Then une alerte visuelle apparaît (et l'historique des incidents est consultable).

**Points d'attention :** s'appuyer sur les sondes Docker/health-checks existants plutôt que de réinventer un monitoring complet (cf. guide technique : Uptime Kuma + sondes).

### CFG-05 — Gérer les polices disponibles
**En tant qu'** administrateur, **je veux** ajouter/retirer les polices proposées aux utilisateurs (pour le pseudo et la note), **afin de** contrôler le catalogue typographique (licences incluses).

**Critères d'acceptation :**
- Given la gestion des polices, Then je peux ajouter une police (fichier + nom d'affichage), activer/désactiver ou retirer une police de la liste.
- Given une police retirée, Then les profils l'utilisant retombent sur la police par défaut (sans action utilisateur).

**Points d'attention :** vérifier la licence de chaque police (OFL/Apache uniquement) ; bundler les fichiers côté client (download au lancement) pour éviter les téléchargements à répétition.

### CFG-06 — Gérer les administrateurs
**En tant que** super-administrateur, **je veux** gérer les comptes administrateurs (ajouter, retirer, niveaux : super-admin, admin, lecteur), **afin de** déléguer sans perdre le contrôle.

**Critères d'acceptation :**
- Given la gestion des administrateurs, Then la liste des comptes BO avec leur niveau s'affiche ; un super-admin peut promouvoir/rétrograder/retirer (jamais le dernier super-admin).
- Given un niveau « lecteur », Then l'accès est limité à la consultation (aucune action d'écriture possible, masquée).

**Points d'attention :** protection anti-verrouillage : impossible de retirer le DERNIER super-administrateur ; toute modification de la liste est journalisée.

---

## Récapitulatif

| Thème | Stories | Dont nouvelles |
|---|---|---|
| Compte & authentification (CPT) | 6 | 4 |
| Navigation (NAV) | 1 | 0 |
| Paramètres (SET) | 1 | 0 |
| Personnalisation (PERS) | 6 | 2 |
| Présence (PRE) | 1 | 0 |
| Amis (FRD) | 3 | 2 |
| Messages privés & groupes (MP) | 3 | 2 |
| Messagerie (MSG) | 10 | 4 |
| Serveurs (SRV) | 4 | 3 |
| Vocal & appels (VOC) | 10 | 0 |
| Activité de jeu (GAM) | 3 | 3 |
| Overlay vocal (OVL) | 3 | 3 |
| Live-chat (LC) | 9 | 9 |
| Panneau d'administration (ADM/MOD/CSR/ANA/CFG) | 18 | 18 |
| **Total** | **78** | **50** |

Les 27 user stories d'origine sont intégralement couvertes (renumérotées et enrichies de critères d'acceptation) ; 50 stories nouvelles comblent les lacunes détectées (édition/suppression de message, gestion des groupes, blocage, vérification email, réinitialisation de mot de passe) et spécifient les fonctionnalités futures demandées (serveurs, polices, activité de jeu, overlay, live-chat) ainsi que l'intégralité du panneau d'administration (4 modules).
