-- ============================================================
-- 动画小镇 · 好友聊天消息表
-- 单聊消息落库：离线也能看到历史，在线时由 WebSocket 实时推送。
-- 可重复执行。
-- ============================================================

USE animation_town;

CREATE TABLE IF NOT EXISTS town_message (
  id           BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键（越大越新）',
  from_id      BIGINT       NOT NULL                COMMENT '发送者 id（town_user.id）',
  to_id        BIGINT       NOT NULL                COMMENT '接收者 id（town_user.id）',
  content      VARCHAR(500) NOT NULL                COMMENT '消息正文（最多 500 字）',
  read_flag    TINYINT      NOT NULL DEFAULT 0      COMMENT '是否已读：0=未读 / 1=已读',
  create_time  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
  PRIMARY KEY (id),
  KEY idx_pair (from_id, to_id, id),
  KEY idx_to_read (to_id, read_flag)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '动画小镇好友聊天消息';
