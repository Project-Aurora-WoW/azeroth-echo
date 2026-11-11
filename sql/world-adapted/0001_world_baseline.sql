USE `echo_world`;










SET NAMES utf8mb4;

DELETE FROM `creature_template` WHERE `entry` = 70001;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(70001,  'Портальный Страж',  'Смотритель Эха Пустоты',  'Talk',  0,  80,  80, 
 35,  1,  1.0,  1.14286,  1,  1.0,  2,  33554432, 
 2048,  7,  0,  0,  '',  0, 
 1.0,  71.0,  1.0,  1.0, 
 2,  '',  12340);


DELETE FROM `creature` WHERE `id` = 70001;
INSERT INTO `creature`
(`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
(7000101,  70001,  0,  1519,  1519,  1,  1,  0, 
 -8960.14,  1335.64,  96.10,  5.21, 
 300,  0,  1000000,  0,  0,  0,  0,  0,  12340),
(7000102,  70001,  1,  1637,  1637,  1,  1,  0, 
 1591.31,  -4434.98,  39.42,  3.32, 
 300,  0,  1000000,  0,  0,  0,  0,  0,  12340);
