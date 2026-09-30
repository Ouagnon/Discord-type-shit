-- ============================================================================
--  SCHÉMA DE BASE DE DONNÉES OPTIMISÉ — Projet « Discord type shit »
--  SGBD cible : PostgreSQL 16+          Encodage : UTF8
--  Version : 2.0 (révision complète du schéma initial dbdiagram.io)
--  Date : septembre 2026
--
--  PRINCIPALES OPTIMISATIONS APPORTÉES AU SCHÉMA D'ORIGINE
--  ---------------------------------------------------------------------------
--  1.  Fusion CHANNEL + CONVERSATION en une seule table `channel` typée
--      (text / voice / dm / group_dm). C'est le modèle réel de Discord : un MP
--      ou un groupe privé EST un canal privé. Avantages : une seule table
--      `message`, une seule logique de membres, une seule logique de
--      pagination et de permissions. La double FK ambiguë
--      (message.conversation_id + message.channel_id) disparaît.
--  2.  Corrections de cohérence : SOUNDBORAD -> soundboard,
--      soundboard_iUUID -> soundboard_id, guild_UUID -> server_id
--      (convention : toute FK se nomme <table_référencée>_id).
--  3.  Ajout du champ `email` sur le compte utilisateur (exigé par US1/US2 :
--      création et connexion par adresse mail + mot de passe).
--  4.  Sécurité des identifiants : colonne unique `password_hash` (Argon2id,
--      sel intégré au hash) remplaçant le couple mdp/salt manipulé à la main ;
--      champ `totp_secret` pour l'A2F (US2).
--  5.  Le champ `code` devient `discriminator` (tag utilisateur #0000-9999),
--      avec unicité (pseudo, discriminator) pour reproduire le tag Discord.
--  6.  Toutes les tables de jonction reçoivent des clés primaires composites
--      correctes + clés étrangères avec règles ON DELETE explicites.
--  7.  Ajout des tables manquantes indispensables aux US existantes :
--      réactions (US14), réponses (US16), réglages utilisateur (US4/US6),
--      partage d'emoji/soundboard sous forme de message (US17),
--      état vocal persistant (US19), catégories de salons (maquettes).
--  8.  Ajout des tables pour les fonctionnalités futures demandées :
--      création de serveurs + invitations + rôles, police du pseudo/note
--      (table `font`), activité de jeu (`activity`), live-chat complet
--      (live_chat, live_chat_element, live_chat_sent).
--  9.  Ajout des tables du panneau d'administration : signalements,
--      sanctions, journal d'audit, annonces globales, configuration système.
--  10. Index ciblés : pagination des messages (US12 : chargement par lots de
--      30 via keyset pagination), files de modération, recherche d'amis,
--      cooldown live-chat, etc.
--  11. Types : TIMESTAMPTZ partout (fuseaux horaires), UUID pour toutes les
--      PK (préférer des UUID v7 générés côté application pour la localité
--      des index B-tree), SMALLINT pour les compteurs bornés.
--  12. Conventions : snake_case minuscule (standard PostgreSQL), ENUM
--      natifs, CHECK constraints pour les invariants, COMMENT ON pour la
--      documentation intégrée.
--
--  REMARQUES D'ARCHITECTURE
--  ---------------------------------------------------------------------------
--  - Pas de partitionnement : volume « famille d'amis » largement insuffisant.
--    Prévoir un partitionnement par plage de `created_at` sur `message`
--    seulement si la table dépasse ~50-100 millions de lignes.
--  - L'état vocal (`voice_state`) et la présence (statut en ligne) vivent
--    principalement en mémoire (Redis) au runtime ; les tables SQL servent
--    de référence durable / audit. C'est un choix assumé.
--  - Les limites métier (30 messages par page, 10 pièces jointes, 50 Mo
--    par fichier, cooldown live-chat) sont reflétées dans les contraintes
--    quand c'est pertinent, sinon appliquées côté application (validation).
--  - Ce fichier peut servir de base de migration initiale (baseline) : voir
--    le guide technologique, section « Code-first vs DB-first ».
-- ============================================================================

BEGIN;

-- Extensions ---------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS citext;     -- emails insensibles à la casse
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;  -- à activer si recherche floue sur les pseudos (voir fin de fichier)

-- ============================================================================
--  TYPES ÉNUMÉRÉS
-- ============================================================================

CREATE TYPE user_status AS ENUM (
    'online',      -- en ligne
    'idle',        -- inactif
    'dnd',         -- ne pas déranger
    'invisible',   -- invisible (apparaît hors ligne aux autres)
    'offline'      -- hors ligne (dérivé de last_seen_at côté application)
);

CREATE TYPE friendship_status AS ENUM (
    'pending',     -- demande envoyée, en attente
    'accepted',    -- amis
    'blocked'      -- bloqué (relation rompue)
);

CREATE TYPE channel_type AS ENUM (
    'text',        -- salon textuel de serveur
    'voice',       -- salon vocal de serveur
    'dm',          -- message privé (exactement 2 membres, géré applicativement)
    'group_dm'     -- groupe privé (plusieurs membres, nom + icône facultatifs)
);

CREATE TYPE group_role AS ENUM (
    'member',      -- membre
    'owner'        -- propriétaire (créateur du groupe privé)
);

CREATE TYPE shared_item_kind AS ENUM (
    'emoji',       -- message de partage d'un emoji personnalisé
    'soundboard'   -- message de partage d'une soundboard
);

CREATE TYPE activity_type AS ENUM (
    'game',        -- activité de jeu (détection processus / déclaration)
    'media',       -- média en cours de lecture (extension future)
    'custom'       -- activité personnalisée (extension future)
);

CREATE TYPE live_chat_element_type AS ENUM (
    'text',        -- bloc de texte
    'image',       -- image positionnée
    'video',       -- vidéo positionnée
    'sound'        -- piste audio (avec délai de départ)
);

CREATE TYPE sanction_type AS ENUM (
    'warning',     -- avertissement
    'mute',        -- muet temporaire (global)
    'kick',        -- expulsion (des serveurs)
    'ban',         -- bannissement permanent
    'temp_ban'     -- bannissement temporaire
);

CREATE TYPE report_status AS ENUM (
    'open',        -- à traiter
    'reviewing',   -- en cours d'examen
    'resolved',    -- résolu (sanction appliquée)
    'dismissed'    -- rejeté (pas de suite)
);

-- ============================================================================
--  FONCTION GÉNÉRIQUE : updated_at
--  (Prisma gère ce champ via @updatedAt ; ce trigger rend le SQL autonome)
-- ============================================================================

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
--  TABLE : font  (polices autorisées — liste gérée depuis l'admin)
--  Sert au choix de police du pseudo et de la note/statut personnalisé
--  (fonctionnalité future « changer la police d'écriture »).
--  Liste blanche = sécurité : impossible d'injecter une police arbitraire.
-- ============================================================================

CREATE TABLE font (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    family_key  text        NOT NULL,                    -- identifiant technique (ex: 'lxgw_wenkai')
    display_name text       NOT NULL,                    -- nom affiché (ex: 'LXGW WenKai')
    is_active   boolean     NOT NULL DEFAULT true,       -- désactivable sans suppression
    created_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT font_family_key_unique UNIQUE (family_key),
    CONSTRAINT font_display_name_unique UNIQUE (display_name)
);

COMMENT ON TABLE font IS 'Liste blanche des polices utilisables pour le pseudo et la note de profil ; gérée par les administrateurs.';

-- ============================================================================
--  TABLE : user_account  (compte utilisateur — ex-ACCOUNT)
--  + email (US1/US2), + Argon2id, + A2F, + discriminator explicite,
--  + soft-delete (suppression administrative), + police du pseudo/note.
-- ============================================================================

CREATE TABLE user_account (
    id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email                citext      NOT NULL,           -- connexion (US1/US2), insensible à la casse
    password_hash        text        NOT NULL,           -- Argon2id (sel intégré, PAS de colonne salt)
    totp_secret          text,                           -- secret A2F chiffré applicativement (US2/US4)
    totp_enabled         boolean     NOT NULL DEFAULT false,
    pseudo               text        NOT NULL CHECK (length(pseudo) BETWEEN 2 AND 32),
    discriminator        smallint    NOT NULL CHECK (discriminator BETWEEN 0 AND 9999),  -- tag #1234 (ex-`code`)
    avatar_url           text,                           -- icône de profil
    banner_url           text,                           -- bannière de profil
    profile_background_url text,                         -- fond de profil
    custom_status        text        CHECK (length(custom_status) <= 128),   -- note / statut personnalisé
    custom_status_font_id uuid REFERENCES font(id) ON DELETE SET NULL,       -- police de la note (futur)
    pseudo_font_id       uuid REFERENCES font(id) ON DELETE SET NULL,        -- police du pseudo (futur)
    status               user_status NOT NULL DEFAULT 'offline',
    activity_public      boolean     NOT NULL DEFAULT true,   -- afficher ou non son activité de jeu
    is_admin             boolean     NOT NULL DEFAULT false,  -- accès au back-office
    is_suspended         boolean     NOT NULL DEFAULT false,  -- compte suspendu (sanction)
    deleted_at           timestamptz,                        -- soft-delete : profil supprimé par l'admin
    last_seen_at         timestamptz,                        -- présence durable (statut dérivé)
    created_at           timestamptz NOT NULL DEFAULT now(),
    updated_at           timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT user_email_unique UNIQUE (email),
    CONSTRAINT user_tag_unique UNIQUE (pseudo, discriminator)   -- le « tag » complet est unique
);

CREATE INDEX user_account_pseudo_idx ON user_account (pseudo);        -- recherche d'amis (US9)
CREATE INDEX user_account_admin_idx  ON user_account (is_admin) WHERE is_admin;

COMMENT ON TABLE user_account IS 'Comptes utilisateurs. Le tag public est « pseudo#discriminator ». password_hash : Argon2id uniquement, jamais de mot de passe en clair.';
COMMENT ON COLUMN user_account.discriminator IS 'Ancien champ « code » : discriminateur numérique du tag utilisateur, ex. 4242 pour Jean#4242.';

CREATE TRIGGER trg_user_account_updated BEFORE UPDATE ON user_account
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================================
--  TABLE : user_settings  (réglages par utilisateur — US4/US6)
--  Correspond à l'onglet « personnalisation de l'application » + notifications
--  + préférences live-chat (document Projet Live-chat).
-- ============================================================================

CREATE TABLE user_settings (
    user_id                       uuid PRIMARY KEY REFERENCES user_account(id) ON DELETE CASCADE,
    -- Apparence / lisibilité (US6 : zoom, taille de police, couleurs)
    ui_zoom_percent               smallint   NOT NULL DEFAULT 100 CHECK (ui_zoom_percent BETWEEN 50 AND 200),
    font_size_pt                  smallint   NOT NULL DEFAULT 14 CHECK (font_size_pt BETWEEN 10 AND 24),
    theme_mode                    text       NOT NULL DEFAULT 'dark' CHECK (theme_mode IN ('dark', 'light', 'custom')),
    background_color_1            text       CHECK (background_color_1 ~ '^#[0-9A-Fa-f]{6}$'),
    background_color_2            text       CHECK (background_color_2 ~ '^#[0-9A-Fa-f]{6}$'),  -- dégradé 2 couleurs
    language                      text       NOT NULL DEFAULT 'fr',
    -- Notifications (US4)
    notify_private                boolean    NOT NULL DEFAULT true,   -- MP / groupes privés
    notify_server                 boolean    NOT NULL DEFAULT true,   -- salons de serveur
    notify_sound                  boolean    NOT NULL DEFAULT true,
    notify_vibration              boolean    NOT NULL DEFAULT true,   -- mobile
    -- Live-chat (document Projet Live-chat : panneau de paramètres)
    live_chat_accept              boolean    NOT NULL DEFAULT true,   -- accepter de recevoir (sinon ne peut pas envoyer)
    live_chat_allow_fullscreen    boolean    NOT NULL DEFAULT true,   -- accepter en plein écran exclusif
    live_chat_cooldown_seconds    integer    NOT NULL DEFAULT 60 CHECK (live_chat_cooldown_seconds >= 0),
    extra                         jsonb      NOT NULL DEFAULT '{}'::jsonb  -- extension sans migration
);

COMMENT ON TABLE user_settings IS 'Préférences applicatives (apparence, notifications, live-chat). extra: jsonb pour futures options sans ALTER TABLE.';

CREATE TRIGGER trg_user_settings_updated BEFORE UPDATE ON user_settings
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================================
--  TABLE : activity  (activité de jeu — fonctionnalité future)
--  Une seule activité « en cours » par utilisateur (index partiel unique).
--  La détection (processus locaux côté client) remplit ces lignes.
-- ============================================================================

CREATE TABLE activity (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     uuid        NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    type        activity_type NOT NULL DEFAULT 'game',
    name        text        NOT NULL,                        -- ex: 'Elden Ring'
    details     text,                                         -- précisions libres
    started_at  timestamptz NOT NULL DEFAULT now(),
    ended_at    timestamptz                                  -- NULL = en cours
);

CREATE UNIQUE INDEX activity_open_unique ON activity (user_id) WHERE ended_at IS NULL;

CREATE INDEX activity_history_idx ON activity (user_id, started_at DESC);

COMMENT ON TABLE activity IS 'Activité affichée sur le profil/liste (jeu en cours). Une ligne active max par utilisateur.';

-- ============================================================================
--  TABLES : server / server_member  (+ serveur par défaut, ex-« serveur général »)
-- ============================================================================

CREATE TABLE server (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name        text        NOT NULL CHECK (length(name) BETWEEN 1 AND 100),
    icon_url    text,
    owner_id    uuid        NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    is_default  boolean     NOT NULL DEFAULT false,        -- LE serveur général où tout le monde est inscrit d'office
    description text,
    created_at  timestamptz NOT NULL DEFAULT now()
);

-- Un seul serveur par défaut possible (index unique partiel) :
CREATE UNIQUE INDEX server_default_unique ON server (is_default) WHERE is_default;

CREATE INDEX server_owner_idx ON server (owner_id);

CREATE TABLE server_member (
    server_id   uuid        NOT NULL REFERENCES server(id) ON DELETE CASCADE,
    user_id     uuid        NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    nickname    text,                                            -- surnom local au serveur (facultatif)
    joined_at   timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT server_member_pk PRIMARY KEY (server_id, user_id)
);

CREATE INDEX server_member_user_idx ON server_member (user_id);   -- « mes serveurs »

COMMENT ON TABLE server IS 'Serveurs. is_default=true : serveur général d''inscription automatique (US architecture).';
COMMENT ON TABLE server_member IS 'Adhésions. Lors de la création d''un compte, l''application insère automatiquement la ligne vers le serveur par défaut.';

-- ============================================================================
--  TABLES : role / member_role  (rôles et permissions par serveur)
--  Nécessaire dès que l'on peut créer des serveurs (futur) : modération,
--  gestion des salons. Permissions = masque binaire (bitfield BIGINT).
--  Bits suggérés (à documenter côté application) :
--    1 administrer le serveur, 2 gérer les salons, 4 gérer les rôles,
--    8 kicker, 16 bannir, 32 modérer (supprimer des messages), 64 parler,
--    128 envoyer des messages, 256 gérer emojis/soundboards du serveur,
--    512 mentionner @everyone, 1024 déplacer en vocal...
-- ============================================================================

CREATE TABLE role (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    server_id   uuid        NOT NULL REFERENCES server(id) ON DELETE CASCADE,
    name        text        NOT NULL CHECK (length(name) BETWEEN 1 AND 50),
    color       text        CHECK (color ~ '^#[0-9A-Fa-f]{6}$'),
    position    integer     NOT NULL DEFAULT 0,             -- ordre d'affichage + priorité (plus grand = prioritaire)
    permissions bigint      NOT NULL DEFAULT 0,             -- masque binaire, cf. commentaire de table
    is_default  boolean     NOT NULL DEFAULT false,         -- rôle attribué automatiquement à chaque membre
    created_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT role_server_name_unique UNIQUE (server_id, name)
);

CREATE INDEX role_server_idx ON role (server_id, position DESC);

CREATE TABLE member_role (
    server_id   uuid NOT NULL,
    user_id     uuid NOT NULL,
    role_id     uuid NOT NULL,
    CONSTRAINT member_role_pk PRIMARY KEY (server_id, user_id, role_id),
    CONSTRAINT member_role_membership_fk FOREIGN KEY (server_id, user_id)
        REFERENCES server_member (server_id, user_id) ON DELETE CASCADE,
    CONSTRAINT member_role_role_fk FOREIGN KEY (role_id)
        REFERENCES role (id) ON DELETE CASCADE
);

COMMENT ON TABLE role IS 'Rôles de serveur. permissions : bitfield BIGINT — 1=admin, 2=salons, 4=rôles, 8=kick, 16=ban, 32=modération, 64=parler, 128=écrire, 256=gérer emojis serveur.';

-- ============================================================================
--  TABLE : server_invite  (rejoindre les nouveaux serveurs — futur)
-- ============================================================================

CREATE TABLE server_invite (
    code         text        PRIMARY KEY,                  -- code court aléatoire (ex: 'aB3xK9')
    server_id    uuid        NOT NULL REFERENCES server(id) ON DELETE CASCADE,
    created_by   uuid        NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    uses         integer     NOT NULL DEFAULT 0,
    max_uses     integer,                                  -- NULL = illimité
    expires_at   timestamptz,                              -- NULL = permanent
    created_at   timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT server_invite_uses_check CHECK (max_uses IS NULL OR uses <= max_uses)
);

CREATE INDEX server_invite_server_idx ON server_invite (server_id);

-- ============================================================================
--  TABLE : channel_category  (regroupement visuel des salons — maquettes)
-- ============================================================================

CREATE TABLE channel_category (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    server_id   uuid        NOT NULL REFERENCES server(id) ON DELETE CASCADE,
    name        text        NOT NULL CHECK (length(name) BETWEEN 1 AND 50),
    position    integer     NOT NULL DEFAULT 0,
    CONSTRAINT category_unique UNIQUE (server_id, name)
);

-- ============================================================================
--  TABLE : channel  (FUSION de CHANNEL + CONVERSATION)
--  type dm/group_dm => server_id NULL ; type text/voice => server_id requis.
--  Un MP = canal dm avec exactement 2 channel_member (invariant applicatif).
-- ============================================================================

CREATE TABLE channel (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    server_id         uuid REFERENCES server(id) ON DELETE CASCADE,   -- NULL si dm/group_dm
    category_id       uuid REFERENCES channel_category(id) ON DELETE SET NULL,  -- salons non catégorisés = NULL
    type              channel_type NOT NULL,
    name              text,                        -- requis pour text/voice/group_dm (app.)
    icon_url          text,                        -- icône de groupe privé (US10, facultatif)
    topic             text,                        -- description (salons textuels)
    position          integer      NOT NULL DEFAULT 0,           -- tri dans la catégorie
    slowmode_seconds  smallint     NOT NULL DEFAULT 0 CHECK (slowmode_seconds BETWEEN 0 AND 21600),
    user_limit        smallint     CHECK (user_limit BETWEEN 1 AND 99),        -- salons vocaux
    last_message_at   timestamptz,                 -- tri de la liste des conversations (US10)
    created_at        timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT channel_type_server_check CHECK (
        (type IN ('text', 'voice')   AND server_id IS NOT NULL)
        OR
        (type IN ('dm', 'group_dm')  AND server_id IS NULL)
    )
);

CREATE INDEX channel_server_idx       ON channel (server_id, category_id, position);
CREATE INDEX channel_last_message_idx ON channel (last_message_at DESC) WHERE type IN ('dm', 'group_dm');

COMMENT ON TABLE channel IS 'Canaux unifiés : salons de serveur (text/voice) ET conversations privées (dm/group_dm). Fusion des anciennes tables CHANNEL et CONVERSATION — une seule table de messages, une seule logique de membres.';
COMMENT ON COLUMN channel.type IS 'text: salon textuel ; voice: salon vocal ; dm: message privé (2 membres) ; group_dm: groupe privé.';

-- ============================================================================
--  TABLE : channel_member  (membres d'un canal privé / participants)
--  Pour dm : exactement 2 lignes (invariant garanti applicativement).
--  last_read_message_id : repère de lecture (badge « nouveaux messages »).
-- ============================================================================

CREATE TABLE channel_member (
    channel_id            uuid NOT NULL REFERENCES channel(id) ON DELETE CASCADE,
    user_id               uuid NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    group_role            group_role NOT NULL DEFAULT 'member',     -- owner = créateur du groupe privé
    joined_at             timestamptz NOT NULL DEFAULT now(),
    last_read_message_id  uuid,                                      -- FK ajoutée après création de `message`
    CONSTRAINT channel_member_pk PRIMARY KEY (channel_id, user_id)
);

CREATE INDEX channel_member_user_idx ON channel_member (user_id);

COMMENT ON TABLE channel_member IS 'Appartenance aux canaux privés (dm/group_dm). Pour les salons de serveur, l''adhésion passe par server_member + permissions, pas par cette table.';

-- ============================================================================
--  TABLE : message  (+ réponses US16, édition, suppression douce)
--  INDEX de pagination : (channel_id, created_at, id) — keyset pagination
--  pour le chargement par lots de 30 (US12).
-- ============================================================================

CREATE TABLE message (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_id   uuid        NOT NULL REFERENCES channel(id) ON DELETE CASCADE,
    author_id    uuid        REFERENCES user_account(id) ON DELETE SET NULL,  -- NULL = compte supprimé, message conservé
    content      text,                                                              -- markdown brut (rendu côté client)
    reply_to_id  uuid        REFERENCES message(id) ON DELETE SET NULL,         -- réponse (US16)
    created_at   timestamptz NOT NULL DEFAULT now(),
    edited_at    timestamptz,
    deleted_at   timestamptz,                                                     -- suppression douce (tous les contextes)
    CONSTRAINT message_no_self_reply CHECK (reply_to_id IS NULL OR reply_to_id <> id)
);

-- Keyset pagination (US12) : « où je me suis arrêté » sans OFFSET
CREATE INDEX message_pagination_idx ON message (channel_id, created_at DESC, id DESC);
CREATE INDEX message_reply_idx       ON message (reply_to_id) WHERE reply_to_id IS NOT NULL;
CREATE INDEX message_author_idx      ON message (author_id) WHERE deleted_at IS NULL;

COMMENT ON TABLE message IS 'Messages de tous les contextes (salons textuels, MP, groupes). Une seule FK canal grâce à la fusion CHANNEL/CONVERSATION. Suppression douce : le contenu n''est plus affiché mais la ligne reste (audit + réponses).';

-- Contrainte FK retardée pour channel_member.last_read_message_id
-- (déclarée ici car message est créée après channel_member) :
ALTER TABLE channel_member
    ADD CONSTRAINT channel_member_last_read_fk
    FOREIGN KEY (last_read_message_id) REFERENCES message (id) ON DELETE SET NULL;

-- ============================================================================
--  TABLE : message_attachment  (pièces jointes — US13 : 10 max, 50 Mo max)
--  L'ancienne contrainte « UNIQUE attachment-message » est supprimée :
--  elle contredisait l'US13 (jusqu'à 10 fichiers par message).
-- ============================================================================

CREATE TABLE message_attachment (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id  uuid        NOT NULL REFERENCES message(id) ON DELETE CASCADE,
    position    smallint    NOT NULL CHECK (position BETWEEN 0 AND 9),     -- US13 : 10 pièces max
    file_url    text        NOT NULL,                                     -- URL S3/Garage (signée à la lecture)
    file_name   text        NOT NULL,
    file_type   text        NOT NULL,                                     -- type MIME
    file_size   bigint      NOT NULL CHECK (file_size > 0 AND file_size <= 52428800),  -- 50 Mo max (US13)
    width       integer,                                                   -- dimensions si image/vidéo (miniatures)
    height      integer,
    created_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT message_attachment_unique UNIQUE (message_id, position)
);

COMMENT ON TABLE message_attachment IS 'Pièces jointes. position 0-9 => 10 fichiers max par message (US13). file_size plafonné à 52 428 800 octets (50 Mo).';

-- ============================================================================
--  TABLE : message_reaction  (réactions — US14)
--  Clé réaction : emoji Unicode direct (« 👍 ») OU « :nom_emoji: » pour un
--  emoji personnalisé (résolution applicative vers la table emoji).
-- ============================================================================

CREATE TABLE message_reaction (
    message_id  uuid        NOT NULL REFERENCES message(id) ON DELETE CASCADE,
    user_id     uuid        NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    emoji_key   text        NOT NULL CHECK (length(emoji_key) BETWEEN 1 AND 64),
    created_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT message_reaction_pk PRIMARY KEY (message_id, user_id, emoji_key)
);

COMMENT ON TABLE message_reaction IS 'Une ligne = un utilisateur pose UNE réaction sur un message. emoji_key : caractère Unicode ou « :nom: » pour les emojis personnalisés.';

-- (table message_share créée plus bas, après emoji et soundboard, car elle
--  référence leurs identifiants)

-- ============================================================================
--  TABLES : emoji / soundboard  (+ partages — US7/US17/US23)
--  Suppression par le créateur => CASCADE sur les partages
--  (US7 : « les supprime aussi pour les gens à qui je les ai partagés »).
-- ============================================================================

CREATE TABLE emoji (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id  uuid        NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    name        text        NOT NULL CHECK (name ~ '^[a-z0-9_]{2,32}$'),   -- utilisable en :nom:
    image_url   text        NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT emoji_creator_name_unique UNIQUE (creator_id, name)
);

CREATE TABLE emoji_share (
    emoji_id    uuid        NOT NULL REFERENCES emoji(id) ON DELETE CASCADE,
    user_id     uuid        NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    granted_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT emoji_share_pk PRIMARY KEY (emoji_id, user_id)
);

CREATE INDEX emoji_share_user_idx ON emoji_share (user_id);   -- « mes emojis reçus » (US7)

CREATE TABLE soundboard (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id   uuid        NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    name         text        NOT NULL CHECK (length(name) BETWEEN 1 AND 50),
    audio_url    text        NOT NULL,
    volume       real        NOT NULL DEFAULT 1.0 CHECK (volume BETWEEN 0.0 AND 2.0),
    duration_ms  integer     CHECK (duration_ms > 0),
    created_at   timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT soundboard_creator_name_unique UNIQUE (creator_id, name)
);

CREATE TABLE soundboard_share (
    soundboard_id uuid       NOT NULL REFERENCES soundboard(id) ON DELETE CASCADE,
    user_id       uuid       NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    granted_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT soundboard_share_pk PRIMARY KEY (soundboard_id, user_id)
);

CREATE INDEX soundboard_share_user_idx ON soundboard_share (user_id);

COMMENT ON TABLE soundboard IS 'Ex-table SOUNDBORAD (faute de frappe corrigée). volume : 0.0 à 2.0 (1.0 = normal).';

-- ============================================================================
--  TABLE : message_share  (partage emoji/soundboard dans un message — US17)
--  Rend le message « cadre emoji/soundboard + bouton ajouter ».
--  (déclarée ici car elle référence emoji et soundboard)
-- ============================================================================

CREATE TABLE message_share (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id    uuid               NOT NULL REFERENCES message(id) ON DELETE CASCADE,
    kind          shared_item_kind   NOT NULL,
    emoji_id      uuid               REFERENCES emoji(id) ON DELETE CASCADE,
    soundboard_id uuid               REFERENCES soundboard(id) ON DELETE CASCADE,
    CONSTRAINT message_share_unique UNIQUE (message_id, kind),
    CONSTRAINT message_share_exactly_one CHECK (
        (kind = 'emoji'      AND emoji_id      IS NOT NULL AND soundboard_id IS NULL)
        OR
        (kind = 'soundboard' AND soundboard_id IS NOT NULL AND emoji_id      IS NULL)
    )
);

COMMENT ON TABLE message_share IS 'Rend le message de partage US17 (cadre avec emoji/soundboard + bouton « ajouter »).';

-- ============================================================================
--  TABLE : friendship  (demandes/blocages — US9, live-chat par ami)
--  Paire ordonnée en base : user_lo < user_hi garantit l'unicité de la
--  relation quelle que soit la direction de la demande.
-- ============================================================================

CREATE TABLE friendship (
    user_lo           uuid              NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,  -- plus petit UUID
    user_hi           uuid              NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,  -- plus grand UUID
    requester_id      uuid              NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,  -- qui a envoyé la demande
    status            friendship_status NOT NULL DEFAULT 'pending',
    live_chat_enabled boolean           NOT NULL DEFAULT true,   -- toggle live-chat propre à cette amitié
    created_at        timestamptz       NOT NULL DEFAULT now(),
    responded_at      timestamptz,
    CONSTRAINT friendship_pk PRIMARY KEY (user_lo, user_hi),
    CONSTRAINT friendship_ordered_check CHECK (user_lo < user_hi),
    CONSTRAINT friendship_requester_check CHECK (requester_id IN (user_lo, user_hi))
);

CREATE INDEX friendship_lo_idx ON friendship (user_lo) WHERE status = 'accepted';
CREATE INDEX friendship_hi_idx ON friendship (user_hi) WHERE status = 'accepted';
CREATE INDEX friendship_pending_idx ON friendship (user_hi, status) WHERE status = 'pending';  -- demandes reçues

COMMENT ON TABLE friendship IS 'Remplace FRIENDSHIP(id_user_1, id_user_2, action_user_id) : la paire (user_lo, user_hi) est ordonnée pour garantir l''unicité ; requester_id conserve l''origine de la demande. live_chat_enabled : autorisation live-chat propre à cette amitié.';

-- ============================================================================
--  TABLE : voice_state  (états vocaux persistants — US19/US20)
--  ⚠ Au runtime, la source de vérité est Redis (TTL + pub/sub) ; cette table
--  sert de référence durable (reprise après redémarrage, statistiques).
-- ============================================================================

CREATE TABLE voice_state (
    user_id      uuid PRIMARY KEY REFERENCES user_account(id) ON DELETE CASCADE,  -- un état vocal max par utilisateur
    channel_id   uuid        NOT NULL REFERENCES channel(id) ON DELETE CASCADE,
    session_id   text        NOT NULL,                -- identifiant de session LiveKit/WebRTC
    self_mute    boolean     NOT NULL DEFAULT false,
    self_deaf    boolean     NOT NULL DEFAULT false,
    server_mute  boolean     NOT NULL DEFAULT false,  -- muet infligé (US27)
    camera       boolean     NOT NULL DEFAULT false,  -- caméra active (US26)
    screen_share boolean     NOT NULL DEFAULT false,  -- partage d'écran (US24)
    joined_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX voice_state_channel_idx ON voice_state (channel_id);   -- « qui est dans le salon vocal » (US19)

COMMENT ON TABLE voice_state IS 'Instantané durable des états vocaux. La vue live (animation d''élocution, etc.) passe par les événements LiveKit, pas par la BDD.';

-- ============================================================================
--  TABLES : live_chat / live_chat_element / live_chat_sent
--  (fonctionnalité « live-chat », document dédié)
--  Coordonnées RELATIVES (0.0-1.0) : indépendant de la résolution écran.
-- ============================================================================

CREATE TABLE live_chat (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id    uuid        NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    name        text        NOT NULL CHECK (length(name) BETWEEN 1 AND 64),
    duration_ms integer     NOT NULL CHECK (duration_ms BETWEEN 1000 AND 300000),   -- 1 s à 5 min
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX live_chat_owner_idx ON live_chat (owner_id);

CREATE TRIGGER trg_live_chat_updated BEFORE UPDATE ON live_chat
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE live_chat_element (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    live_chat_id    uuid                  NOT NULL REFERENCES live_chat(id) ON DELETE CASCADE,
    type            live_chat_element_type NOT NULL,
    text_content    text,                 -- requis si type = 'text'
    font_id         uuid REFERENCES font(id) ON DELETE SET NULL,
    font_size_pt    smallint   CHECK (font_size_pt BETWEEN 8 AND 72),
    asset_url       text,                 -- requis si type <> 'text' (image/vidéo/son)
    asset_duration_ms integer,            -- durée du média son/vidéo
    x               real       NOT NULL CHECK (x BETWEEN 0.0 AND 1.0),
    y               real       NOT NULL CHECK (y BETWEEN 0.0 AND 1.0),
    width           real       CHECK (width  BETWEEN 0.0 AND 1.0),
    height          real       CHECK (height BETWEEN 0.0 AND 1.0),
    start_time_ms   integer    NOT NULL DEFAULT 0 CHECK (start_time_ms >= 0),   -- décalage de départ (sons)
    sort_order      smallint   NOT NULL DEFAULT 0,
    CONSTRAINT live_chat_element_content_check CHECK (
        (type = 'text' AND text_content IS NOT NULL)
        OR
        (type <> 'text' AND asset_url IS NOT NULL)
    )
);

CREATE INDEX live_chat_element_live_chat_idx ON live_chat_element (live_chat_id, sort_order);

COMMENT ON TABLE live_chat_element IS 'Éléments du live-chat. x/y/width/height en coordonnées relatives (0-1) : le rendu s''adapte à toutes les résolutions d''écran.';

CREATE TABLE live_chat_sent (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    live_chat_id  uuid        NOT NULL REFERENCES live_chat(id) ON DELETE CASCADE,
    sender_id     uuid        NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    receiver_id   uuid        NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    sent_at       timestamptz NOT NULL DEFAULT now(),
    delivered_at  timestamptz,             -- reçu par le client du destinataire
    viewed_at     timestamptz              -- affiché jusqu'au bout
);

-- Cooldown : « dernier live-chat reçu » (contrôle applicatif rapide)
CREATE INDEX live_chat_sent_receiver_idx ON live_chat_sent (receiver_id, sent_at DESC);

COMMENT ON TABLE live_chat_sent IS 'Historique d''envoi. Sert au contrôle du cooldown côté destinataire (index receiver_id + sent_at DESC).';

-- ============================================================================
--  TABLES DU PANNEAU D'ADMINISTRATION (back-office)
-- ============================================================================

-- Signalements (file de modération) -----------------------------------------
CREATE TABLE report (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id       uuid          NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    reported_user_id  uuid          NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    message_id        uuid          REFERENCES message(id) ON DELETE SET NULL,   -- message signalé (peut être purgé)
    evidence_snapshot jsonb,                                                      -- copie du contenu au moment du signalement
    reason            text          NOT NULL CHECK (length(reason) BETWEEN 1 AND 1000),
    status            report_status NOT NULL DEFAULT 'open',
    handled_by        uuid          REFERENCES user_account(id) ON DELETE SET NULL,   -- admin traitant
    resolution_note   text,
    created_at        timestamptz   NOT NULL DEFAULT now(),
    updated_at        timestamptz   NOT NULL DEFAULT now()
);

CREATE INDEX report_queue_idx     ON report (status, created_at);        -- file de modération
CREATE INDEX report_reported_idx  ON report (reported_user_id, created_at DESC);   -- historique d'un utilisateur

CREATE TRIGGER trg_report_updated BEFORE UPDATE ON report
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

COMMENT ON TABLE report IS 'Signalements utilisateur. evidence_snapshot conserve une copie du message (le message original pouvant être supprimé).';

-- Sanctions globales ---------------------------------------------------------
CREATE TABLE sanction (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id    uuid          NOT NULL REFERENCES user_account(id) ON DELETE SET NULL,
    user_id     uuid          NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    type        sanction_type NOT NULL,
    reason      text          NOT NULL CHECK (length(reason) BETWEEN 1 AND 1000),
    expires_at  timestamptz,                                 -- NULL = permanent (ban)
    created_at  timestamptz   NOT NULL DEFAULT now(),
    CONSTRAINT sanction_temp_needs_expiry CHECK (
        (type IN ('mute', 'temp_ban') AND expires_at IS NOT NULL)
        OR
        (type NOT IN ('mute', 'temp_ban'))
    )
);

CREATE INDEX sanction_user_idx ON sanction (user_id, created_at DESC);   -- historique disciplinaire

COMMENT ON TABLE sanction IS 'Sanctions applicables par les administrateurs : avertissement, muet global temporaire, kick, bannissement. Les kicks/bans de serveur peuvent aussi être gérés par les rôles (permissions bitfield).';

-- Journal d'audit -------------------------------------------------------------
CREATE TABLE audit_log (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id    uuid        REFERENCES user_account(id) ON DELETE SET NULL,   -- NULL = action système/automate
    action      text        NOT NULL,                     -- ex: 'user.delete', 'message.purge', 'config.update'
    target_type text,                                     -- 'user' | 'server' | 'message' | 'config' | ...
    target_id   uuid,                                     -- identifiant de la cible
    details     jsonb       NOT NULL DEFAULT '{}'::jsonb, -- contexte libre (avant/après)
    ip_address  inet,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX audit_log_created_idx ON audit_log (created_at DESC);
CREATE INDEX audit_log_admin_idx   ON audit_log (admin_id, created_at DESC);
CREATE INDEX audit_log_target_idx  ON audit_log (target_type, target_id);

COMMENT ON TABLE audit_log IS 'Journal d''audit de toutes les actions sensibles du back-office (traçabilité). Chaque action admin écrit une ligne ici.';

-- Annonces globales ------------------------------------------------------------
CREATE TABLE announcement (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id     uuid        NOT NULL REFERENCES user_account(id) ON DELETE SET NULL,
    title         text        NOT NULL CHECK (length(title) BETWEEN 1 AND 128),
    body          text        NOT NULL,
    published_at  timestamptz NOT NULL DEFAULT now(),
    expires_at    timestamptz
);

CREATE INDEX announcement_published_idx ON announcement (published_at DESC);

-- Configuration système / feature flags -----------------------------------------
CREATE TABLE system_config (
    key         text PRIMARY KEY,                          -- ex: 'maintenance_mode', 'feature.live_chat'
    value       jsonb       NOT NULL,                      -- {"enabled": true} ...
    description text,
    updated_by  uuid REFERENCES user_account(id) ON DELETE SET NULL,
    updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_system_config_updated BEFORE UPDATE ON system_config
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

COMMENT ON TABLE system_config IS 'Clé/valeur pour les feature flags et réglages globaux : mode maintenance, activation des modules, limites dynamiques.';

-- ============================================================================
--  SECTION OPTIONNELLE : recherche floue des pseudos (activer si besoin)
-- ----------------------------------------------------------------------------
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- CREATE INDEX user_account_pseudo_trgm_idx ON user_account USING gin (pseudo gin_trgm_ops);
-- ============================================================================

COMMIT;

-- ============================================================================
--  RÉCAPITULATIF DES CORRESPONDANCES AVEC LE SCHÉMA D'ORIGINE
-- ----------------------------------------------------------------------------
--  ACCOUNT               -> user_account (+email, +password_hash Argon2id,
--                            +totp_*, +custom_status, +fonts, +is_admin, ...)
--  SERVER                -> server (+is_default)
--  CHANNEL               -> channel (fusion avec CONVERSATION, +categories)
--  CONVERSATION          -> (supprimée) = channel dm/group_dm
--  CONVERSATION_MEMBERS  -> channel_member
--  MESSAGE               -> message (+reply_to_id, +edited_at, +deleted_at)
--  ATTACHMENT            -> message_attachment (UNIQUE corrigée : 10 max)
--                            + table message_reaction (US14)
--                            + table message_share (US17)
--  EMOJI / EMOJI_SHARE   -> emoji / emoji_share
--  SOUNDBORAD (typo)     -> soundboard / soundboard_share
--  SERVER_MEMBER         -> server_member (+role, +member_role, +server_invite)
--  FRIENDSHIP            -> friendship (paire ordonnée + statut + live-chat)
--  (nouvelles)           -> font, user_settings, activity, voice_state,
--                            channel_category, live_chat, live_chat_element,
--                            live_chat_sent, report, sanction, audit_log,
--                            announcement, system_config
-- ============================================================================
