

















USE `echo_world`;








DELETE FROM `item_template` WHERE `entry` IN (70100, 70101);
INSERT INTO `item_template`
(`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `bonding`, `description`, `Material`)
VALUES
(70100,  12,  -1,  'Паёк Ордена',  6289,  2,  0, 
 0,  0,  0,  -1,  -1, 
 1,  1,  0,  20,  1, 
 'Памятный знак Ордена Рассвета за первые шаги против Пустоты. (Награда за 2-й уровень)',  -1),
(70101,  12,  -1,  'Сумка Эха',  6289,  3,  0, 
 0,  0,  0,  -1,  -1, 
 5,  1,  0,  20,  1, 
 'Мешочек с наградой Ордена за верную службу. (Награда каждые 5 уровней)',  -1);




USE `echo_characters`;

CREATE TABLE IF NOT EXISTS `realm_level_rewards` (
  `guid`        INT UNSIGNED NOT NULL,
  `reward_level` TINYINT UNSIGNED NOT NULL,
  `granted_at`  INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`, `reward_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Выданные level-up награды (06_WaloriaRewards.lua)';
