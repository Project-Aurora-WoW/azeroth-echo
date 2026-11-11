USE `echo_characters`;











CREATE TABLE IF NOT EXISTS realm_fixgear (
    guid          INT UNSIGNED NOT NULL,
    item_entry    INT UNSIGNED NOT NULL,
    fixed_at      INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (guid, item_entry)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
