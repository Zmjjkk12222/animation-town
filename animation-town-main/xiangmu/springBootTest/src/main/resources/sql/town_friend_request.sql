-- ============================================================
-- 动画小镇 · 好友申请表（好友关系改为「申请审批制」）
-- 在 animation_town.sql 之后执行，可重复执行（幂等）。
-- ============================================================

USE animation_town;

CREATE TABLE IF NOT EXISTS town_friend_request (
  id           BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  from_id      BIGINT       NOT NULL                COMMENT '申请发起者 id（town_user.id）',
  to_id        BIGINT       NOT NULL                COMMENT '接收者 id（town_user.id）',
  status       VARCHAR(16)  NOT NULL DEFAULT 'pending' COMMENT '状态：pending=待处理 / accepted=已接受 / rejected=已拒绝 / cancelled=已取消',
  remark       VARCHAR(100) NOT NULL DEFAULT ''     COMMENT '附加留言',
  create_time  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '申请时间',
  update_time  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (id),
  KEY idx_to_status (to_id, status),
  KEY idx_from_to (from_id, to_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '动画小镇好友申请表';

-- ============================================================
-- 消息表新增 type 列（text=文本 / emoji=表情），老库升级幂等
-- ============================================================
SET @has_type := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'town_message'
     AND COLUMN_NAME = 'type'
);
SET @sql_type := IF(@has_type = 0,
  'ALTER TABLE town_message ADD COLUMN type VARCHAR(16) NOT NULL DEFAULT ''text'' COMMENT ''消息类型：text/emoji'' AFTER to_id',
  'DO 0');
PREPARE stmt_type FROM @sql_type;
EXECUTE stmt_type;
DEALLOCATE PREPARE stmt_type;
