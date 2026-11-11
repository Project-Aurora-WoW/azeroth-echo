-- ============================================================
-- Migration: 0024_fix_spawn_warnings.sql
-- Purpose: убрать предупреждения загрузки контента, которые писал
--          worldserver при старте (logs/Errors.log)
-- SCHEMA: AzerothCore 3.3.5a
-- Database: echo_world, echo_auth
-- ============================================================
--
-- Что было в Errors.log после первого запуска новой сборки:
--
-- 1) шесть спавнов с MovementType=1 (random movement) и wander_distance=0,
--    сервер молча заменял движение на idle и писал предупреждение:
--      700540/700541/700542/700543 (70500? нет: 70080-70083), 7000140 (70500),
--      7000163 (70510)
--    Для торговцев и тренеров блуждание не нужно — ставим idle (0) явно.
--
-- 2) существо 70510 «Усмешка Бездны» имеет в flags_extra бит
--    CREATURE_FLAG_EXTRA_INSTANCE_BIND (0x1), но стоит в открытом мире
--    (карта 571). Бит привязывает точку возрождения к инстансу — снимаем.
--    Было 617 (0x269), станет 616 (0x268).
--
-- 3) предупреждение «Script named 'npc_conversing_with_the_depths_trigger'
--    is not assigned in the database» приходит из модуля mod_archivist:
--    такого ScriptName нет ни у одного creature_template. Отключить его
--    можно в configs/modules/mod_archivist.conf, SQL не нужен.
--
-- Дополнительно: имя реалма в списке персонажей было техническим
-- «AzerothCore». Меняем на игровое.
-- ============================================================

SET NAMES utf8mb4;

USE `echo_world`;

-- 1. Движение: random movement без дистанции -> idle
UPDATE `creature`
SET `MovementType` = 0
WHERE `MovementType` = 1 AND `wander_distance` = 0
;

-- 2. 70510: снять CREATURE_FLAG_EXTRA_INSTANCE_BIND (0x1)
UPDATE `creature_template`
SET `flags_extra` = `flags_extra` & ~1
WHERE `entry` = 70510
;

USE `echo_auth`;

-- 3. Имя реалма в окне выбора
UPDATE `realmlist` SET `name` = 'Эхо Пустоты' WHERE `id` = 1;

-- ============================================================
-- Проверка после применения:
--   USE echo_world;
--   SELECT guid, id, MovementType, wander_distance FROM creature
--    WHERE guid IN (700540,700541,700542,700543,7000140,7000163);
--   SELECT entry, name, flags_extra FROM creature_template WHERE entry = 70510;
--   USE echo_auth; SELECT id, name FROM realmlist;
-- Ожидается: MovementType=0 у всех, flags_extra=616, name='Эхо Пустоты'.
-- ============================================================
