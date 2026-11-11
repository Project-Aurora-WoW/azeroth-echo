-- ============================================================
-- Migration: 0025_add_pvp_vendor.sql
-- Purpose: lua_scripts/30_PvpShop.lua регистрирует gossip у НПС 70170
--          («Интендант Ордена»), но такого существа не было в БД.
--          ALE писал: Couldn't find a creature with (ID: 70170)!
-- SCHEMA: AzerothCore 3.3.5a — модели в creature_template_model (Idx),
--         в creature_template колонок modelid1..4 нет.
-- Database: echo_world
-- ============================================================
--
-- НПС ставится рядом с остальными кастомными НПС лагеря
-- (70172/70173/70174) на карте 571, координаты взяты по соседям,
-- чтобы точка гарантированно была на земле того же лагеря.
-- ============================================================

SET NAMES utf8mb4;
USE `echo_world`;

DELETE FROM `creature_template_model` WHERE `CreatureID` = 70170;
DELETE FROM `creature`                WHERE `id` = 70170;
DELETE FROM `creature_template`       WHERE `entry` = 70170;

INSERT INTO `creature_template`
    (`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`,
     `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`,
     `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`,
     `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`,
     `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`,
     `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`,
     `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`,
     `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`,
     `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
    (70170, 'Интендант Ордена', 'Награды за Жетоны Эха', NULL, 0, 80, 80,
     2, 35, 129, 1, 1.14286, 1, 1,
     20, 0, 0, 1, 2000,
     2000, 1, 1, 1, 768,
     2048, 0, 0, 7, 138412032, 0,
     0, 0, 0, 0, 0, 0,
     '', 0, 1, 3, 1,
     1, 1, 0, 0, 1,
     0, 0, '', 12340);

-- Модель: та же, что у «Хранителя Золота» (70173) — торговый НПС лагеря.
INSERT INTO `creature_template_model`
    (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
VALUES
    (70170, 0, 24991, 1, 1, 12340);

-- Спавн рядом с 70172/70173 (карта 571, лагерь кастомных НПС).
INSERT INTO `creature`
    (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
     `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`,
     `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`,
     `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`,
     `CreateObject`, `Comment`)
VALUES
    (7000170, 70170, 571, 4395, 4395, 1, 1, 0,
     5797.5, 648.5, 647.75, 4.75, 300,
     0, 0, 1, 0, 0,
     0, 0, 0, '', 12340,
     0, 'Интендант Ордена — магазин жетонов (30_PvpShop.lua)');

-- ============================================================
-- Проверка после применения:
--   SELECT ct.entry, ct.name, ct.npcflag, m.CreatureDisplayID
--     FROM creature_template ct
--     LEFT JOIN creature_template_model m ON m.CreatureID = ct.entry
--    WHERE ct.entry = 70170;
--   SELECT guid, id, map, position_x, position_y, position_z FROM creature WHERE id = 70170;
-- Ожидается одна модель (24991) и один спавн (guid 7000170).
-- ============================================================
