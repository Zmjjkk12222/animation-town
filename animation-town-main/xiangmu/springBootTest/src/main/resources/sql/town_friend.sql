-- ============================================================
-- 动画小镇 · 好友表（在 animation_town.sql 之后执行）
-- 好友关系为双向：添加好友时写入两条记录（A→B、B→A），
-- 删除好友时同步删除两条，可重复执行。
-- ============================================================

USE animation_town;

CREATE TABLE IF NOT EXISTS town_friend (
  id           BIGINT   NOT NULL AUTO_INCREMENT COMMENT '主键',
  user_id      BIGINT   NOT NULL                COMMENT '用户 id（town_user.id）',
  friend_id    BIGINT   NOT NULL                COMMENT '好友 id（town_user.id）',
  create_time  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP                 COMMENT '成为好友时间',
  update_time  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  deleted      TINYINT  NOT NULL DEFAULT 0      COMMENT '逻辑删除：0=未删 / 1=已删',
  PRIMARY KEY (id),
  KEY idx_user (user_id),
  KEY idx_friend (friend_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '动画小镇好友表';
