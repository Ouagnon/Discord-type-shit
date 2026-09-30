-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "user_status" AS ENUM ('online', 'idle', 'dnd', 'invisible', 'offline');

-- CreateEnum
CREATE TYPE "friendship_status" AS ENUM ('pending', 'accepted', 'blocked');

-- CreateEnum
CREATE TYPE "channel_type" AS ENUM ('text', 'voice', 'dm', 'group_dm');

-- CreateEnum
CREATE TYPE "group_role" AS ENUM ('member', 'owner');

-- CreateEnum
CREATE TYPE "shared_item_kind" AS ENUM ('emoji', 'soundboard');

-- CreateEnum
CREATE TYPE "activity_type" AS ENUM ('game', 'media', 'custom');

-- CreateEnum
CREATE TYPE "live_chat_element_type" AS ENUM ('text', 'image', 'video', 'sound');

-- CreateEnum
CREATE TYPE "sanction_type" AS ENUM ('warning', 'mute', 'kick', 'ban', 'temp_ban');

-- CreateEnum
CREATE TYPE "report_status" AS ENUM ('open', 'reviewing', 'resolved', 'dismissed');

-- CreateTable
CREATE TABLE "font" (
    "id" TEXT NOT NULL,
    "family_key" TEXT NOT NULL,
    "display_name" TEXT NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "font_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_account" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "totp_secret" TEXT,
    "totp_enabled" BOOLEAN NOT NULL DEFAULT false,
    "pseudo" TEXT NOT NULL,
    "discriminator" INTEGER NOT NULL,
    "avatar_url" TEXT,
    "banner_url" TEXT,
    "profile_background_url" TEXT,
    "custom_status" TEXT,
    "custom_status_font_id" TEXT,
    "pseudo_font_id" TEXT,
    "status" "user_status" NOT NULL DEFAULT 'offline',
    "activity_public" BOOLEAN NOT NULL DEFAULT true,
    "is_admin" BOOLEAN NOT NULL DEFAULT false,
    "is_suspended" BOOLEAN NOT NULL DEFAULT false,
    "deleted_at" TIMESTAMP(3),
    "last_seen_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_account_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_settings" (
    "user_id" TEXT NOT NULL,
    "ui_zoom_percent" INTEGER NOT NULL DEFAULT 100,
    "font_size_pt" INTEGER NOT NULL DEFAULT 14,
    "theme_mode" TEXT NOT NULL DEFAULT 'dark',
    "background_color_1" TEXT,
    "background_color_2" TEXT,
    "language" TEXT NOT NULL DEFAULT 'fr',
    "notify_private" BOOLEAN NOT NULL DEFAULT true,
    "notify_server" BOOLEAN NOT NULL DEFAULT true,
    "notify_sound" BOOLEAN NOT NULL DEFAULT true,
    "notify_vibration" BOOLEAN NOT NULL DEFAULT true,
    "live_chat_accept" BOOLEAN NOT NULL DEFAULT true,
    "live_chat_allow_fullscreen" BOOLEAN NOT NULL DEFAULT true,
    "live_chat_cooldown_seconds" INTEGER NOT NULL DEFAULT 60,
    "extra" JSONB NOT NULL,

    CONSTRAINT "user_settings_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "activity" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "type" "activity_type" NOT NULL DEFAULT 'game',
    "name" TEXT NOT NULL,
    "details" TEXT,
    "started_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ended_at" TIMESTAMP(3),

    CONSTRAINT "activity_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "server" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "icon_url" TEXT,
    "owner_id" TEXT NOT NULL,
    "is_default" BOOLEAN NOT NULL DEFAULT false,
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "server_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "server_member" (
    "server_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "nickname" TEXT,
    "joined_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "server_member_pkey" PRIMARY KEY ("server_id","user_id")
);

-- CreateTable
CREATE TABLE "role" (
    "id" TEXT NOT NULL,
    "server_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "color" TEXT,
    "position" INTEGER NOT NULL DEFAULT 0,
    "permissions" BIGINT NOT NULL DEFAULT 0,
    "is_default" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "role_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "member_role" (
    "server_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "role_id" TEXT NOT NULL,

    CONSTRAINT "member_role_pkey" PRIMARY KEY ("server_id","user_id","role_id")
);

-- CreateTable
CREATE TABLE "server_invite" (
    "code" TEXT NOT NULL,
    "server_id" TEXT NOT NULL,
    "created_by" TEXT NOT NULL,
    "uses" INTEGER NOT NULL DEFAULT 0,
    "max_uses" INTEGER,
    "expires_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "server_invite_pkey" PRIMARY KEY ("code")
);

-- CreateTable
CREATE TABLE "channel_category" (
    "id" TEXT NOT NULL,
    "server_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "position" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "channel_category_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "channel" (
    "id" TEXT NOT NULL,
    "server_id" TEXT,
    "category_id" TEXT,
    "type" "channel_type" NOT NULL,
    "name" TEXT,
    "icon_url" TEXT,
    "topic" TEXT,
    "position" INTEGER NOT NULL DEFAULT 0,
    "slowmode_seconds" INTEGER NOT NULL DEFAULT 0,
    "user_limit" INTEGER,
    "last_message_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "channel_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "channel_member" (
    "channel_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "group_role" "group_role" NOT NULL DEFAULT 'member',
    "joined_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "last_read_message_id" TEXT,

    CONSTRAINT "channel_member_pkey" PRIMARY KEY ("channel_id","user_id")
);

-- CreateTable
CREATE TABLE "message" (
    "id" TEXT NOT NULL,
    "channel_id" TEXT NOT NULL,
    "author_id" TEXT,
    "content" TEXT,
    "reply_to_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "edited_at" TIMESTAMP(3),
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "message_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "message_attachment" (
    "id" TEXT NOT NULL,
    "message_id" TEXT NOT NULL,
    "position" INTEGER NOT NULL,
    "file_url" TEXT NOT NULL,
    "file_name" TEXT NOT NULL,
    "file_type" TEXT NOT NULL,
    "file_size" BIGINT NOT NULL,
    "width" INTEGER,
    "height" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "message_attachment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "message_reaction" (
    "message_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "emoji_key" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "message_reaction_pkey" PRIMARY KEY ("message_id","user_id","emoji_key")
);

-- CreateTable
CREATE TABLE "emoji" (
    "id" TEXT NOT NULL,
    "creator_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "image_url" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "emoji_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "emoji_share" (
    "emoji_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "granted_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "emoji_share_pkey" PRIMARY KEY ("emoji_id","user_id")
);

-- CreateTable
CREATE TABLE "soundboard" (
    "id" TEXT NOT NULL,
    "creator_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "audio_url" TEXT NOT NULL,
    "volume" DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    "duration_ms" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "soundboard_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "soundboard_share" (
    "soundboard_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "granted_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "soundboard_share_pkey" PRIMARY KEY ("soundboard_id","user_id")
);

-- CreateTable
CREATE TABLE "message_share" (
    "id" TEXT NOT NULL,
    "message_id" TEXT NOT NULL,
    "kind" "shared_item_kind" NOT NULL,
    "emoji_id" TEXT,
    "soundboard_id" TEXT,

    CONSTRAINT "message_share_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "friendship" (
    "user_lo" TEXT NOT NULL,
    "user_hi" TEXT NOT NULL,
    "requester_id" TEXT NOT NULL,
    "status" "friendship_status" NOT NULL DEFAULT 'pending',
    "live_chat_enabled" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "responded_at" TIMESTAMP(3),

    CONSTRAINT "friendship_pkey" PRIMARY KEY ("user_lo","user_hi")
);

-- CreateTable
CREATE TABLE "voice_state" (
    "user_id" TEXT NOT NULL,
    "channel_id" TEXT NOT NULL,
    "session_id" TEXT NOT NULL,
    "self_mute" BOOLEAN NOT NULL DEFAULT false,
    "self_deaf" BOOLEAN NOT NULL DEFAULT false,
    "server_mute" BOOLEAN NOT NULL DEFAULT false,
    "camera" BOOLEAN NOT NULL DEFAULT false,
    "screen_share" BOOLEAN NOT NULL DEFAULT false,
    "joined_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "voice_state_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "live_chat" (
    "id" TEXT NOT NULL,
    "owner_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "duration_ms" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "live_chat_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "live_chat_element" (
    "id" TEXT NOT NULL,
    "live_chat_id" TEXT NOT NULL,
    "type" "live_chat_element_type" NOT NULL,
    "text_content" TEXT,
    "font_id" TEXT,
    "font_size_pt" INTEGER,
    "asset_url" TEXT,
    "asset_duration_ms" INTEGER,
    "x" DOUBLE PRECISION NOT NULL,
    "y" DOUBLE PRECISION NOT NULL,
    "width" DOUBLE PRECISION,
    "height" DOUBLE PRECISION,
    "start_time_ms" INTEGER NOT NULL DEFAULT 0,
    "sort_order" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "live_chat_element_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "live_chat_sent" (
    "id" TEXT NOT NULL,
    "live_chat_id" TEXT NOT NULL,
    "sender_id" TEXT NOT NULL,
    "receiver_id" TEXT NOT NULL,
    "sent_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "delivered_at" TIMESTAMP(3),
    "viewed_at" TIMESTAMP(3),

    CONSTRAINT "live_chat_sent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "report" (
    "id" TEXT NOT NULL,
    "reporter_id" TEXT NOT NULL,
    "reported_user_id" TEXT NOT NULL,
    "message_id" TEXT,
    "evidence_snapshot" JSONB,
    "reason" TEXT NOT NULL,
    "status" "report_status" NOT NULL DEFAULT 'open',
    "handled_by_id" TEXT,
    "resolution_note" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "report_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sanction" (
    "id" TEXT NOT NULL,
    "admin_id" TEXT,
    "user_id" TEXT NOT NULL,
    "type" "sanction_type" NOT NULL,
    "reason" TEXT NOT NULL,
    "expires_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sanction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_log" (
    "id" TEXT NOT NULL,
    "admin_id" TEXT,
    "action" TEXT NOT NULL,
    "target_type" TEXT,
    "target_id" TEXT,
    "details" JSONB NOT NULL,
    "ip_address" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_log_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "announcement" (
    "id" TEXT NOT NULL,
    "author_id" TEXT,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "published_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMP(3),

    CONSTRAINT "announcement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "system_config" (
    "key" TEXT NOT NULL,
    "value" JSONB NOT NULL,
    "description" TEXT,
    "updated_by_id" TEXT,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "system_config_pkey" PRIMARY KEY ("key")
);

-- CreateIndex
CREATE UNIQUE INDEX "font_family_key_unique" ON "font"("family_key");

-- CreateIndex
CREATE UNIQUE INDEX "font_display_name_unique" ON "font"("display_name");

-- CreateIndex
CREATE UNIQUE INDEX "user_email_unique" ON "user_account"("email");

-- CreateIndex
CREATE INDEX "user_account_pseudo_idx" ON "user_account"("pseudo");

-- CreateIndex
CREATE UNIQUE INDEX "user_tag_unique" ON "user_account"("pseudo", "discriminator");

-- CreateIndex
CREATE INDEX "activity_history_idx" ON "activity"("user_id", "started_at" DESC);

-- CreateIndex
CREATE INDEX "server_owner_idx" ON "server"("owner_id");

-- CreateIndex
CREATE INDEX "server_member_user_idx" ON "server_member"("user_id");

-- CreateIndex
CREATE INDEX "role_server_idx" ON "role"("server_id", "position" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "role_server_name_unique" ON "role"("server_id", "name");

-- CreateIndex
CREATE INDEX "server_invite_server_idx" ON "server_invite"("server_id");

-- CreateIndex
CREATE UNIQUE INDEX "category_unique" ON "channel_category"("server_id", "name");

-- CreateIndex
CREATE INDEX "channel_server_idx" ON "channel"("server_id", "category_id", "position");

-- CreateIndex
CREATE INDEX "channel_member_user_idx" ON "channel_member"("user_id");

-- CreateIndex
CREATE INDEX "message_pagination_idx" ON "message"("channel_id", "created_at" DESC, "id" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "message_attachment_unique" ON "message_attachment"("message_id", "position");

-- CreateIndex
CREATE UNIQUE INDEX "emoji_creator_name_unique" ON "emoji"("creator_id", "name");

-- CreateIndex
CREATE INDEX "emoji_share_user_idx" ON "emoji_share"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "soundboard_creator_name_unique" ON "soundboard"("creator_id", "name");

-- CreateIndex
CREATE INDEX "soundboard_share_user_idx" ON "soundboard_share"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "message_share_unique" ON "message_share"("message_id", "kind");

-- CreateIndex
CREATE INDEX "live_chat_owner_idx" ON "live_chat"("owner_id");

-- CreateIndex
CREATE INDEX "live_chat_element_live_chat_idx" ON "live_chat_element"("live_chat_id", "sort_order");

-- CreateIndex
CREATE INDEX "live_chat_sent_receiver_idx" ON "live_chat_sent"("receiver_id", "sent_at" DESC);

-- CreateIndex
CREATE INDEX "report_queue_idx" ON "report"("status", "created_at");

-- CreateIndex
CREATE INDEX "report_reported_idx" ON "report"("reported_user_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "sanction_user_idx" ON "sanction"("user_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "audit_log_created_idx" ON "audit_log"("created_at" DESC);

-- CreateIndex
CREATE INDEX "audit_log_admin_idx" ON "audit_log"("admin_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "audit_log_target_idx" ON "audit_log"("target_type", "target_id");

-- CreateIndex
CREATE INDEX "announcement_published_idx" ON "announcement"("published_at" DESC);

-- AddForeignKey
ALTER TABLE "user_account" ADD CONSTRAINT "user_account_custom_status_font_id_fkey" FOREIGN KEY ("custom_status_font_id") REFERENCES "font"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_account" ADD CONSTRAINT "user_account_pseudo_font_id_fkey" FOREIGN KEY ("pseudo_font_id") REFERENCES "font"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_settings" ADD CONSTRAINT "user_settings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "activity" ADD CONSTRAINT "activity_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "server" ADD CONSTRAINT "server_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "server_member" ADD CONSTRAINT "server_member_server_id_fkey" FOREIGN KEY ("server_id") REFERENCES "server"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "server_member" ADD CONSTRAINT "server_member_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "role" ADD CONSTRAINT "role_server_id_fkey" FOREIGN KEY ("server_id") REFERENCES "server"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "member_role" ADD CONSTRAINT "member_role_server_id_user_id_fkey" FOREIGN KEY ("server_id", "user_id") REFERENCES "server_member"("server_id", "user_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "member_role" ADD CONSTRAINT "member_role_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "role"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "server_invite" ADD CONSTRAINT "server_invite_server_id_fkey" FOREIGN KEY ("server_id") REFERENCES "server"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "server_invite" ADD CONSTRAINT "server_invite_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "channel_category" ADD CONSTRAINT "channel_category_server_id_fkey" FOREIGN KEY ("server_id") REFERENCES "server"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "channel" ADD CONSTRAINT "channel_server_id_fkey" FOREIGN KEY ("server_id") REFERENCES "server"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "channel" ADD CONSTRAINT "channel_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "channel_category"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "channel_member" ADD CONSTRAINT "channel_member_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "channel"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "channel_member" ADD CONSTRAINT "channel_member_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message" ADD CONSTRAINT "message_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "channel"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message" ADD CONSTRAINT "message_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "user_account"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message" ADD CONSTRAINT "message_reply_to_id_fkey" FOREIGN KEY ("reply_to_id") REFERENCES "message"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_attachment" ADD CONSTRAINT "message_attachment_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "message"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_reaction" ADD CONSTRAINT "message_reaction_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "message"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_reaction" ADD CONSTRAINT "message_reaction_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "emoji" ADD CONSTRAINT "emoji_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "emoji_share" ADD CONSTRAINT "emoji_share_emoji_id_fkey" FOREIGN KEY ("emoji_id") REFERENCES "emoji"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "emoji_share" ADD CONSTRAINT "emoji_share_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "soundboard" ADD CONSTRAINT "soundboard_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "soundboard_share" ADD CONSTRAINT "soundboard_share_soundboard_id_fkey" FOREIGN KEY ("soundboard_id") REFERENCES "soundboard"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "soundboard_share" ADD CONSTRAINT "soundboard_share_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_share" ADD CONSTRAINT "message_share_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "message"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_share" ADD CONSTRAINT "message_share_emoji_id_fkey" FOREIGN KEY ("emoji_id") REFERENCES "emoji"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message_share" ADD CONSTRAINT "message_share_soundboard_id_fkey" FOREIGN KEY ("soundboard_id") REFERENCES "soundboard"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "friendship" ADD CONSTRAINT "friendship_user_lo_fkey" FOREIGN KEY ("user_lo") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "friendship" ADD CONSTRAINT "friendship_user_hi_fkey" FOREIGN KEY ("user_hi") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "friendship" ADD CONSTRAINT "friendship_requester_id_fkey" FOREIGN KEY ("requester_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "voice_state" ADD CONSTRAINT "voice_state_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "voice_state" ADD CONSTRAINT "voice_state_channel_id_fkey" FOREIGN KEY ("channel_id") REFERENCES "channel"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "live_chat" ADD CONSTRAINT "live_chat_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "live_chat_element" ADD CONSTRAINT "live_chat_element_live_chat_id_fkey" FOREIGN KEY ("live_chat_id") REFERENCES "live_chat"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "live_chat_element" ADD CONSTRAINT "live_chat_element_font_id_fkey" FOREIGN KEY ("font_id") REFERENCES "font"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "live_chat_sent" ADD CONSTRAINT "live_chat_sent_live_chat_id_fkey" FOREIGN KEY ("live_chat_id") REFERENCES "live_chat"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "live_chat_sent" ADD CONSTRAINT "live_chat_sent_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "live_chat_sent" ADD CONSTRAINT "live_chat_sent_receiver_id_fkey" FOREIGN KEY ("receiver_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "report" ADD CONSTRAINT "report_reporter_id_fkey" FOREIGN KEY ("reporter_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "report" ADD CONSTRAINT "report_reported_user_id_fkey" FOREIGN KEY ("reported_user_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "report" ADD CONSTRAINT "report_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "message"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "report" ADD CONSTRAINT "report_handled_by_id_fkey" FOREIGN KEY ("handled_by_id") REFERENCES "user_account"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sanction" ADD CONSTRAINT "sanction_admin_id_fkey" FOREIGN KEY ("admin_id") REFERENCES "user_account"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sanction" ADD CONSTRAINT "sanction_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user_account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_log" ADD CONSTRAINT "audit_log_admin_id_fkey" FOREIGN KEY ("admin_id") REFERENCES "user_account"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "announcement" ADD CONSTRAINT "announcement_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "user_account"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "system_config" ADD CONSTRAINT "system_config_updated_by_id_fkey" FOREIGN KEY ("updated_by_id") REFERENCES "user_account"("id") ON DELETE SET NULL ON UPDATE CASCADE;

