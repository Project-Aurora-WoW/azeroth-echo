































SET NAMES utf8mb4;



USE `echo_world`;




DELETE FROM `creature_template` WHERE `entry` = 70172;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(70172,  'Рунный Обжиг',  'Зачарователь Ордена Рассвета',  'Talk',  0,  80,  80, 
 35,  1,  1.0,  1.14286,  0,  1.0,  2,  33554432, 
 2048,  7,  0,  0,  '',  0, 
 1.0,  71.0,  1.0,  1.0, 
 2,  '',  12340);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 70172;
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(70172,  0,  24991,  1.00,  1.0);


DELETE FROM `creature` WHERE `id` = 70172;
INSERT INTO `creature`
(`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
(7000172,  70172,  571,  4395,  4395,  1,  1,  0, 
 5796.50,  647.10,  647.75,  4.75,  300,  0,  1000000,  0,  0,  0,  0,  0,  12340);




DELETE FROM `creature_template` WHERE `entry` = 70173;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(70173,  'Хранитель Золота',  'Казначей Ордена Рассвета',  'Banker',  0,  80,  80, 
 35,  1,  1.0,  1.14286,  0,  1.0,  2,  33554432, 
 2048,  7,  0,  0,  '',  0, 
 1.0,  71.0,  1.0,  1.0, 
 2,  '',  12340);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 70173;
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(70173,  0,  24991,  1.00,  1.0);


DELETE FROM `creature` WHERE `id` = 70173;
INSERT INTO `creature`
(`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
(7000173,  70173,  571,  4395,  4395,  1,  1,  0, 
 5798.90,  650.40,  647.75,  4.75,  300,  0,  1000000,  0,  0,  0,  0,  0,  12340);







DELETE FROM `creature_template` WHERE `entry` = 70190;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(70190,  'Разлом Пустоты',  '',  '',  0,  80,  80, 
 35,  0,  1.0,  1.14286,  0,  1.0,  2,  33554432, 
 2048,  10,  0,  0,  '',  0, 
 1.0,  1.0,  1.0,  1.0, 
 2,  '',  12340);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 70190;
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(70190,  0,  26501,  1.20,  1.0);





DELETE FROM `creature_template` WHERE `entry` = 70191;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(70191,  'Иссушенный из Разлома',  'Порождение Пустоты',  '',  0,  80,  80, 
 14,  0,  1.0,  1.14286,  0,  1.0,  2,  64, 
 2048,  10,  0,  0,  '',  1, 
 1.0,  1.0,  1.0,  1.0, 
 0,  '',  12340);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 70191;
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(70191,  0,  25272,  1.00,  1.0);





DELETE FROM `item_template` WHERE `entry` = 70008;
INSERT INTO `item_template`
(`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `Material`)
VALUES
(70008,  12,  -1,  'Осколок Пустоты',  6289,  2,  0, 
 0,  0,  0,  -1,  -1, 
 80,  70,  0,  20,  0, 
 'Тяжёлый осколок с побережья разлома. Чем больше их при тебе, тем громче шёпот Пустоты в твоей голове...',  -1);











DELETE FROM `spell_dbc` WHERE `Id` = 70050;
INSERT INTO `spell_dbc`
(`Id`, `SpellNameLang`, `DispelType`, `Mechanic`, `Attributes`,
 `Stances`, `CastingTimeIndex`, `DurationIndex`, `RangeIndex`,
 `StackAmount`, `EquippedItemClass`, `AuraDescriptionLang`,
 `Effect_1`, `EffectDieSides_1`, `EffectBasePoints_1`, `EffectApplyAuraName_1`)
VALUES
(70050, 'Пустотная порча', 0, 0, 0,
 0, 1, 21, 1,
 100, -1, 'Пустота просачивается в тебя сквозь осколки...',
 6, 1, 0, 0);



USE `echo_characters`;

CREATE TABLE IF NOT EXISTS `realm_gold_storage` (
  `account` INT UNSIGNED NOT NULL,
  `name`    VARCHAR(255) NOT NULL,
  `gold`    BIGINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Казна золота НПС-банкира (16_GoldStorage.lua, 0018)';
