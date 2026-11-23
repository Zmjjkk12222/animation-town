-- ============================================================
-- 动画小镇 · 好友表（在 animation_town.sql 之后执行）
-- 好友关系为双向：添加好友时写入两条记录（A→B、B→A），
-- 删除好友时物理删除两条，脚本可重复执行。
-- ============================================================

USE animation_town;

CREATE TABLE IF NOT EXISTS town_friend (
  id           BIGINT   NOT NULL AUTO_INCREMENT COMMENT '主键',
  user_id      BIGINT   NOT NULL                COMMENT '用户 id（town_user.id）',
  friend_id    BIGINT   NOT NULL                COMMENT '好友 id（town_user.id）',
  create_time  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP                 COMMENT '成为好友时间',
  update_time  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  deleted      TINYINT  NOT NULL DEFAULT 0      COMMENT '逻辑删除：0=未删 / 1=已删（历史字段，现改为物理删除）',
  PRIMARY KEY (id),
  UNIQUE KEY uk_pair (user_id, friend_id),
  KEY idx_friend (friend_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '动画小镇好友表';

-- ------------------------------------------------------------
-- 老库升级（幂等）：
--   1) 清掉历史逻辑删除行与重复行，否则唯一索引加不上
--   2) 补唯一索引 uk_pair（(user_id, friend_id)，天然覆盖 idx_user）
--   3) 删掉被 uk_pair 覆盖的冗余索引 idx_user
-- ------------------------------------------------------------
DELETE FROM town_friend WHERE deleted = 1;

DELETE f1 FROM town_friend f1
  JOIN town_friend f2
    ON f1.user_id = f2.user_id
   AND f1.friend_id = f2.friend_id
   AND f1.id > f2.id;

SET @has_uk := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'town_friend'
     AND INDEX_NAME = 'uk_pair'
);
SET @sql := IF(@has_uk = 0,
  'ALTER TABLE town_friend ADD UNIQUE KEY uk_pair (user_id, friend_id)',
  'DO 0');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_dup_idx := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'town_friend'
     AND INDEX_NAME = 'idx_user'
);
SET @sql2 := IF(@has_dup_idx > 0,
  'ALTER TABLE town_friend DROP INDEX idx_user',
  'DO 0');
PREPARE stmt2 FROM @sql2;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;
