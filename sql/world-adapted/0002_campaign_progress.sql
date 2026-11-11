USE `echo_characters`;







CREATE TABLE IF NOT EXISTS `realm_campaign_progress` (
  `guid`            INT UNSIGNED NOT NULL COMMENT 'GUID игрока (characters.guid)',
  `campaign_id`     TINYINT UNSIGNED NOT NULL COMMENT 'ID кампании (см. docs/campaigns/README.md)',
  `chapter`         TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Текущая глава кампании',
  `completed`       TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 — кампания пройдена',
  `progress_data`   TEXT NULL COMMENT 'Свободное поле для состояния (JSON)',
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `campaign_id`)
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COMMENT = 'Прогресс игроков в кампаниях кастомного реалма';

ALTER TABLE `realm_campaign_progress` ADD INDEX `idx_campaign_progress_guid` (`guid`);