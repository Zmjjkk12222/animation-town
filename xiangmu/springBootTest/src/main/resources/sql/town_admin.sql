-- ============================================================
-- 后台管理系统：管理员表
-- 与前台 town_user 账号体系完全隔离，仅用于后台登录
-- 预置账号由应用启动时自动写入（密码 BCrypt 加密），此处不写死明文
-- ============================================================
CREATE TABLE IF NOT EXISTS town_admin (
  id          BIGINT       AUTO_INCREMENT PRIMARY KEY COMMENT '主键，自增',
  username    VARCHAR(50)  NOT NULL                COMMENT '管理员登录账号（唯一）',
  password    VARCHAR(100) NOT NULL                COMMENT 'BCrypt 加密后的密码',
  nickname    VARCHAR(50)  NOT NULL DEFAULT ''     COMMENT '显示名称',
  create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP                  COMMENT '创建时间',
  update_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  deleted     TINYINT      NOT NULL DEFAULT 0      COMMENT '逻辑删除：0=正常 / 1=已删',
  UNIQUE KEY uk_admin_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='后台管理员表';
