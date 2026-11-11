-- ============================================================
-- Migration: 0022_fix_custom_items.sql
-- Purpose: починка записей кастомных предметов, которые попали в БД
--          с урезанным набором полей (диагностика 2026-11-11)
-- SCHEMA: AzerothCore 3.3.5a (схема этого ядра: item_template без StatsCount)
-- Database: echo_world
-- ============================================================
--
-- Что исправляется:
--   1. displayid = 0 у 8 предметов. Клиент не может отрисовать иконку и
--      модель: в ItemDisplayInfo.dbc ссылка 0 отсутствует. Все выставленные
--      значения проверены на наличие в ItemDisplayInfo.dbc (57 986 записей).
--   2. Material = -1 (в unsigned-колонке превращается в 255) — недопустимое
--      значение, ломает звук/категорию предмета.
--   3. Предмет-маунт 70003 имел subclass 0 вместо 5 (Mount) и
--      spellcategory 76 вместо 330 — из-за этого маунт не попадал в
--      коллекцию маунтов клиента.
--
-- Значения displayid подобраны из существующих предметов того же типа,
-- чтобы модель и иконка гарантированно были в клиентском DBC:
--   37335 — Dilapidated Cloth Vest (лёгкий нагрудник, ilvl 68)
--   35207 — Sylvan Vest              (лёгкий нагрудник, ilvl 60)
--   33527 — Earthpower Vest          (лёгкий нагрудник, ilvl 65)
--    6289 — стандартная иконка квестового предмета
--    6419 — стандартная иконка предмета-знамени
-- ============================================================

SET NAMES utf8mb4;
USE `echo_world`;

-- 1. Знамя: displayid 0 -> валидная иконка
UPDATE `item_template` SET `displayid` = 6419 WHERE `entry` IN (70010, 70011, 70012, 70013) AND `displayid` = 0;

-- 2. Лёгкие нагрудники: displayid 0 -> реальные модели лёгкой брони
UPDATE `item_template` SET `displayid` = 37335, `Material` = 7 WHERE `entry` = 70015 AND `displayid` = 0;
UPDATE `item_template` SET `displayid` = 35207, `Material` = 7 WHERE `entry` = 70016 AND `displayid` = 0;
UPDATE `item_template` SET `displayid` = 33527, `Material` = 7 WHERE `entry` = 70017 AND `displayid` = 0;

-- 3. Артефакт зоны: displayid 0 -> квестовая иконка
UPDATE `item_template` SET `displayid` = 6289, `Material` = 0 WHERE `entry` = 70018 AND `displayid` = 0;

-- 4. Material = -1/255 -> корректное значение
UPDATE `item_template` SET `Material` = 0 WHERE `entry` BETWEEN 70000 AND 70299 AND `Material` IN (-1, 255);

-- 5. Предмет-маунт: subclass Mount (5) и категория Mount (330)
UPDATE `item_template` SET `subclass` = 5, `spellcategory_1` = 330 WHERE `entry` = 70003;

-- ============================================================
-- Проверка после применения:
--   SELECT entry, name, displayid, Material, class, subclass, spellcategory_1
--   FROM item_template WHERE entry BETWEEN 70000 AND 70299 ORDER BY entry;
-- Ни в одной строке не должно остаться displayid = 0 или Material < 0.
-- ============================================================
