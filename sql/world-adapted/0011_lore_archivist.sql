USE `echo_world`;









SET NAMES utf8mb4;


DELETE FROM `creature_template` WHERE `entry` = 70180;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(70180,  'Хронист Ордена',  'Хранитель архива Эха Пустоты',  'Talk',  0,  80,  80, 
 35,  1,  1.0,  1.14286,  0,  1.0,  2,  33554432, 
 2048,  7,  0,  0,  '',  0, 
 1.0,  71.0,  1.0,  1.0, 
 2,  '',  12340);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 70180;
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(70180,  0,  24991,  1.00,  1.0);


DELETE FROM `creature` WHERE `id` = 70180;
INSERT INTO `creature`
(`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
(7000180,  70180,  571,  4395,  4395,  1,  1,  0, 
 5800.32,  640.85,  647.75,  4.60,  300,  0,  1000000,  0,  0,  0,  0,  0,  12340);
