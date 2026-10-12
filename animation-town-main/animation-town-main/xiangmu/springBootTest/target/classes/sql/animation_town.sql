-- ============================================================
-- 动画小镇 animation-town 建库建表语句
-- 说明：在本地 MySQL（8.x）中执行本脚本即可完成初始化。
--       已存在的库 / 表使用 IF NOT EXISTS，可重复执行，不会报错。
-- ============================================================

-- 1) 创建数据库（utf8mb4 以支持 emoji 头像）
CREATE DATABASE IF NOT EXISTS animation_town
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

-- 使用数据库
USE animation_town;

-- 2) 用户表（注册功能核心表）
CREATE TABLE IF NOT EXISTS town_user (
  id           BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  nickname     VARCHAR(50)  NOT NULL                COMMENT '昵称 / 登录账号',
  role         VARCHAR(10)  NOT NULL                COMMENT '角色：kid=小朋友 / parent=家长',
  avatar       VARCHAR(10)  NOT NULL DEFAULT ''     COMMENT '头像 emoji',
  phone        VARCHAR(20)  NOT NULL DEFAULT ''     COMMENT '家长手机号（小朋友可不填）',
  password     VARCHAR(100) NOT NULL                COMMENT 'BCrypt 加密后的密码',
  create_time  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP                 COMMENT '创建时间',
  update_time  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  deleted      TINYINT      NOT NULL DEFAULT 0       COMMENT '逻辑删除：0=未删 / 1=已删',
  PRIMARY KEY (id),
  UNIQUE KEY uk_nickname (nickname)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '动画小镇用户表';

-- ============================================================
-- 执行完成后，请确认 application-dev.properties 中的数据源配置
-- 与你的本地 MySQL 账号密码一致（默认 root / root）。
-- ============================================================
