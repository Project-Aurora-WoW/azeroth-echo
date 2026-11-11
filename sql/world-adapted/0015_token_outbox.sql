
















USE `echo_characters`;



CREATE TABLE IF NOT EXISTS `realm_token_outbox` (
  `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `reward_key`   CHAR(64)  CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `guid`         INT UNSIGNED NOT NULL,
  `account`      INT UNSIGNED NOT NULL,
  `tokens`       INT UNSIGNED NOT NULL,
  `reason`       VARCHAR(64) CHARACTER SET utf8mb4 NOT NULL DEFAULT '',
  `created_at`   INT UNSIGNED NOT NULL DEFAULT 0,
  `delivered`    TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `reward_key` (`reward_key`),
  KEY `pending_member` (`guid`, `delivered`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Outbox наград реалма (жетоны Эха): durable intent + delivery';


CREATE TABLE IF NOT EXISTS `realm_token_receipt` (
  `reward_key`   CHAR(64)  CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `guid`         INT UNSIGNED NOT NULL,
  `tokens`       INT UNSIGNED NOT NULL,
  `delivered_at` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`reward_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Квитанции выдачи Жетонов Эха (realm_token_outbox)';
