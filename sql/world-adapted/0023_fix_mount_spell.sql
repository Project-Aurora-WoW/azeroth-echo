-- ============================================================
-- Migration: 0023_fix_mount_spell.sql
-- Purpose: спелл 70010 «Призыв: Бездна-Пегас» был клоном 45991 с эффектом
--          SPELL_EFFECT_SUMMON_OBJECT_WILD (76) и misc 187903 — это
--          GameObject «Portable Oil Collector», а не маунт. Верхом такой
--          спелл не сажает.
-- SCHEMA: AzerothCore 3.3.5a (spell_dbc, 234 колонки = 1:1 поля Spell.dbc)
-- Database: echo_world
-- ============================================================
--
-- Исправление: запись переписана по образцу штатного маунт-спелла 5784
-- (Summon Felsteed). Каноническая структура всех маунт-спеллов 3.3.5a:
--     Effect_1   = 6        SPELL_EFFECT_APPLY_AURA
--     EffectAura_1 = 78     SPELL_AURA_MOUNTED
--     EffectMiscValue_1 = entry существа-маунта (здесь 29767, «Spectral
--                          Gryphon, Mount», displayid 26691)
--     DurationIndex = 21    «до отмены»
--     Effect_2 = 6 / EffectAura_2 = 32  SPELL_AURA_MOD_INCREASE_SPEED (+60%)
--
-- ВАЖНО: те же значения обязаны быть в клиентском Spell.dbc, иначе клиент
-- отрисует спелл по своей таблице и верхом не посадит. DBC правится
-- скриптом tools/dbc/patch_spell_effect.py и попадает в patch-x.mpq.
-- Значения ниже — его вывод; ID и строковые смещения имён в БД не значимы.
-- ============================================================

SET NAMES utf8mb4;
USE `echo_world`;

UPDATE `spell_dbc` SET
    `Mechanic` = 21,
    `Attributes` = 269844480,
    `AttributesEx` = 131072,
    `AttributesEx2` = 0,
    `AttributesEx3` = 536870912,
    `AttributesEx6` = 131072,
    `CastingTimeIndex` = 16,
    `InterruptFlags` = 15,
    `BaseLevel` = 20,
    `SpellLevel` = 20,
    `DurationIndex` = 21,
    `PowerType` = 3,
    `Effect_1` = 6,
    `Effect_2` = 6,
    `Effect_3` = 77,
    `EffectDieSides_2` = 1,
    `EffectBasePoints_2` = 59,
    `ImplicitTargetA_1` = 1,
    `ImplicitTargetA_2` = 1,
    `ImplicitTargetA_3` = 1,
    `EffectAura_1` = 78,
    `EffectAura_2` = 32,
    `EffectMiscValue_1` = 29767,
    `SpellVisualID_1` = 656,
    `SpellIconID` = 115
WHERE `ID` = 70010;

-- Проверка после применения:
--   SELECT ID, Name_Lang_enUS, Effect_1, EffectAura_1, EffectMiscValue_1,
--          Effect_2, EffectAura_2, DurationIndex
--   FROM spell_dbc WHERE ID = 70010;
-- Ожидается: 6 / 78 / 29767 / 6 / 32 / 21
-- ============================================================
