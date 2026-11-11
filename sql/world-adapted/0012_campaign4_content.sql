USE `echo_world`;













SET NAMES utf8mb4;



DELETE FROM `creature_template` WHERE `entry` IN (70210, 70201, 70202, 70204, 70520);
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(70210,  'Хранительница Аэрис',  'Sentinel Стражей Пустоты',  'Talk',  0,  80,  80, 
 35,  1,  1.0,  1.14286,  1,  1.0,  2,  33554432, 
 2048,  7,  0,  0,  '',  0, 
 1.0,  250.0,  1.0,  1.0, 
 2,  '',  12340),
(70201,  'Осколочный Фантом',  'Обрывок сознания Усмешки',  '',  0,  80,  80, 
 14,  0,  1.0,  1.14286,  0,  1.0,  2,  32768, 
 0,  4,  0,  0,  '',  1, 
 1.0,  50.0,  1.0,  1.0, 
 0,  '',  12340),
(70202,  'Иссушенный Легионер',  'Элита Архонта',  '',  0,  82,  82, 
 14,  0,  1.0,  1.14286,  1,  2.0,  2,  32768, 
 0,  4,  0,  0,  '',  1, 
 1.0,  150.0,  1.0,  1.0, 
 0,  '',  12340),
(70204,  'Осколок Эха',  'Смеющееся семя Пустоты',  '',  0,  80,  80, 
 35,  1,  1.0,  1.14286,  0,  1.0,  2,  33554432, 
 2048,  10,  0,  0,  '',  0, 
 1.0,  100.0,  1.0,  1.0, 
 2,  '',  12340),
(70520,  'Архонт Нехал''тхар',  'Собиратель Усмешки',  '',  0,  83,  83, 
 14,  0,  1.0,  1.14286,  3,  20.0,  2,  32768, 
 0,  4,  0,  0,  '',  1, 
 1.0,  420.0,  1.0,  1.0, 
 0,  '',  12340);



DELETE FROM `creature_template_model` WHERE `CreatureID` IN (70210, 70201, 70202, 70204, 70520);
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(70210,  0,  25880,  1.00,  1.0),
(70201,  0,  26752,  1.00,  1.0),
(70202,  0,  26751,  1.10,  1.0),
(70204,  0,  27456,  0.80,  1.0),
(70520,  0,  27455,  2.20,  1.0);   -- Архонт (крупный)



DELETE FROM `item_template` WHERE `entry` IN (70006, 70007);
INSERT INTO `item_template`
(`entry`, `class`, `subclass`, `soundoverridesubclass`, `name`, `displayid`,
 `Quality`, `Flags`, `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`,
 `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`,
 `RequiredSkill`, `RequiredSkillRank`, `requiredspell`, `requiredhonorrank`,
 `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`,
 `maxcount`, `stackable`, `ContainerSlots`, `StatsCount`,
 `ScalingStatDistribution`, `ScalingStatValue`, `armor`,
 `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`,
 `delay`, `ammo_type`, `RangedModRange`, `bonding`, `description`,
 `PageText`, `LanguageID`, `PageMaterial`, `startquest`, `lockid`, `Material`, `sheath`,
 `RandomProperty`, `RandomSuffix`, `block`, `itemset`, `MaxDurability`, `area`, `Map`,
 `BagFamily`, `TotemCategory`, `socketColor_1`, `socketContent_1`,
 `socketColor_2`, `socketContent_2`,
 `socketColor_3`, `socketContent_3`,
 `socketBonus`, `GemProperties`, `RequiredDisenchantSkill`, `ArmorDamageModifier`,
 `duration`, `ItemLimitCategory`, `HolidayId`, `ScriptName`, `DisenchantID`,
 `FoodType`, `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`, `VerifiedBuild`)
VALUES
(70006, 12, 0, -1, 'Сердце Второго Эха', 64452,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 1, 80,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1, 0, 0,
 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Оно всё ещё бьётся. Если поднести к разлому — может услышать.',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 12340),
(70007, 12, 0, -1, 'Венец Пустоты', 65170,
 4, 32768, 0, 1, 0, 0,
 0, -1, -1, 1, 80,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1, 0, 0,
 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Знак тех, кто дважды остановил Пустоту.',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 12340);



DELETE FROM `creature` WHERE `id` = 70210;
INSERT INTO `creature`
(`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
(7000181,  70210,  571,  4395,  4395,  1,  1,  0, 
 5804.15,  645.30,  647.80,  2.35,  300,  0,  1000000,  0,  0,  0,  0,  0,  12340);







DELETE FROM `creature` WHERE `guid` BETWEEN 7000300 AND 7000339;
INSERT INTO `creature`
(`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
(7000300,  70201,  571,  4080,  4365,  1,  1,  0,  3896.20,  7048.50,  151.20,  1.20,  300,  8,  50000,  0,  1,  0,  0,  0,  12340),
(7000301,  70201,  571,  4080,  4365,  1,  1,  0,  3908.70,  7052.10,  152.40,  2.50,  300,  8,  50000,  0,  1,  0,  0,  0,  12340),
(7000302,  70201,  571,  4080,  4365,  1,  1,  0,  3912.30,  7036.80,  150.80,  3.60,  300,  8,  50000,  0,  1,  0,  0,  0,  12340),
(7000303,  70201,  571,  4080,  4365,  1,  1,  0,  3900.40,  7028.90,  149.90,  4.80,  300,  8,  50000,  0,  1,  0,  0,  0,  12340),
(7000304,  70201,  571,  4080,  4365,  1,  1,  0,  3888.60,  7031.20,  149.40,  0.70,  300,  8,  50000,  0,  1,  0,  0,  0,  12340),
(7000305,  70201,  571,  4080,  4365,  1,  1,  0,  3882.10,  7042.70,  150.10,  1.90,  300,  8,  50000,  0,  1,  0,  0,  0,  12340),
(7000306,  70201,  571,  4080,  4365,  1,  1,  0,  3886.90,  7056.30,  151.60,  2.90,  300,  8,  50000,  0,  1,  0,  0,  0,  12340),
(7000307,  70201,  571,  4080,  4365,  1,  1,  0,  3904.50,  7061.40,  153.10,  4.10,  300,  8,  50000,  0,  1,  0,  0,  0,  12340),
(7000310,  70202,  571,  4080,  4365,  1,  1,  0,  3895.10,  7040.60,  150.60,  1.00,  300,  6,  150000,  0,  1,  0,  0,  0,  12340),
(7000311,  70202,  571,  4080,  4365,  1,  1,  0,  3906.20,  7044.30,  151.80,  2.20,  300,  6,  150000,  0,  1,  0,  0,  0,  12340),
(7000312,  70202,  571,  4080,  4365,  1,  1,  0,  3903.80,  7053.90,  152.60,  3.30,  300,  6,  150000,  0,  1,  0,  0,  0,  12340),
(7000313,  70202,  571,  4080,  4365,  1,  1,  0,  3891.70,  7049.80,  151.40,  4.40,  300,  6,  150000,  0,  1,  0,  0,  0,  12340),
(7000320,  70204,  571,  4080,  4365,  1,  1,  0,  3898.40,  7046.20,  151.00,  1.50,  300,  0,  100000,  0,  0,  0,  0,  0,  12340),
(7000321,  70204,  571,  4080,  4365,  1,  1,  0,  3901.90,  7050.80,  151.90,  2.60,  300,  0,  100000,  0,  0,  0,  0,  0,  12340),
(7000322,  70204,  571,  4080,  4365,  1,  1,  0,  3896.80,  7052.40,  151.50,  3.70,  300,  0,  100000,  0,  0,  0,  0,  0,  12340),
(7000330,  70520,  571,  4080,  4365,  1,  1,  0,  3899.60,  7049.10,  151.40,  0.30,  300,  0,  4200000,  0,  1,  0,  0,  0,  12340);
