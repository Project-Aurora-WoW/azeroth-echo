-- ============================================================
-- Migration: 0027_pvp_stats_characters.sql
-- Purpose: таблица PvP-статистики должна жить в базе персонажей.
--          В 0009_event_pvp.sql стоял `USE echo_world`, поэтому таблица
--          создалась в world-базе, а скрипты (20_PvpSystem.lua,
--          AddonBridge.lua) обращаются к ней через CharDBQuery.
--          На входе игрока ALE получал [1146] Table 'echo_characters.
--          realm_pvp_stats' doesn't exist и ронял worldserver через
--          Acore::Abort.
-- SCHEMA: AzerothCore 3.3.5a
-- Database: echo_characters (создание), echo_world (уборка копии)
-- ============================================================

SET NAMES utf8mb4;

USE `echo_characters`;

CREATE TABLE IF NOT EXISTS `realm_pvp_stats` (
  `guid`           INT UNSIGNED NOT NULL COMMENT 'GUID игрока (characters.guid)',
  `kills`          INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Всего PvP-убийств (зачётные)',
  `deaths`         INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Смертей от игроков (зачётные)',
  `streak`         INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Текущая серия убийств',
  `best_streak`    INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Лучшая серия',
  `zone_kills`     INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Киллов в PvP-зоне (Драконий Погост)',
  `tokens_earned`  INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Жетонов Эха заработано в PvP',
  `last_victim`    INT UNSIGNED NULL COMMENT 'GUID последней жертвы (анти-фарм)',
  `last_kill_time` INT UNSIGNED NULL COMMENT 'Время последнего зачётного килла (unix)',
  `updated_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`)
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COMMENT = 'PvP-статистика реалма Эхо Пустоты';

-- Копию в world-базе убираем: она не используется и вводит в заблуждение.
USE `echo_world`;
DROP TABLE IF EXISTS `realm_pvp_stats`;

-- ============================================================
-- Проверка после применения:
--   SHOW TABLES LIKE 'realm_pvp_stats';            -- в echo_characters: есть
--   SHOW TABLES LIKE 'realm_pvp_stats';            -- в echo_world: пусто
--   SELECT * FROM echo_characters.realm_pvp_stats; -- без ошибок
-- ============================================================
