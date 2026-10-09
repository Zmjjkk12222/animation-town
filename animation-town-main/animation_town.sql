/*
 Navicat Premium Dump SQL

 Source Server         : test
 Source Server Type    : MySQL
 Source Server Version : 80039 (8.0.39)
 Source Host           : localhost:3306
 Source Schema         : animation_town

 Target Server Type    : MySQL
 Target Server Version : 80039 (8.0.39)
 File Encoding         : 65001

 Date: 09/10/2026 14:50:22
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for town_animation
-- ----------------------------
DROP TABLE IF EXISTS `town_animation`;
CREATE TABLE `town_animation`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '动画标题',
  `cover` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '' COMMENT '封面 emoji',
  `category` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '' COMMENT '分类',
  `description` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '' COMMENT '简介',
  `hot` int NOT NULL DEFAULT 0 COMMENT '热度（用于今日推荐排序）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0=未删 / 1=已删',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '动画小镇动画表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of town_animation
-- ----------------------------
INSERT INTO `town_animation` VALUES (1, '森林小勇士', '🌳', '冒险', '跟随小松鼠穿越魔法森林，寻找失落的光之种子。', 98, '2026-10-09 14:03:52', '2026-10-09 14:03:52', 0);
INSERT INTO `town_animation` VALUES (2, '星星邮差', '⭐', '治愈', '每晚把小朋友的愿望，送到月亮上去。', 95, '2026-10-09 14:03:52', '2026-10-09 14:03:52', 0);
INSERT INTO `town_animation` VALUES (3, '恐龙博士', '🦖', '科普', '和会说话的恐龙一起破解远古谜题。', 92, '2026-10-09 14:03:52', '2026-10-09 14:03:52', 0);
INSERT INTO `town_animation` VALUES (4, '猫咪侦探社', '🐱', '推理', '和猫咪一起破解小镇里的神秘案件。', 91, '2026-10-09 14:03:52', '2026-10-09 14:03:52', 0);
INSERT INTO `town_animation` VALUES (5, '太空小旅行家', '🚀', '科幻', '坐上纸飞船，去八大行星串个门。', 90, '2026-10-09 14:03:52', '2026-10-09 14:03:52', 0);
INSERT INTO `town_animation` VALUES (6, '海底乐队', '🐠', '音乐', '一群海洋生物组队，开一场深海演唱会。', 88, '2026-10-09 14:03:52', '2026-10-09 14:03:52', 0);
INSERT INTO `town_animation` VALUES (7, '小小发明家', '🔧', '科学', '用身边的材料，做出神奇的小实验。', 87, '2026-10-09 14:03:52', '2026-10-09 14:03:52', 0);
INSERT INTO `town_animation` VALUES (8, '积木城市', '🧱', '创意', '用积木搭出你想象里的城市。', 85, '2026-10-09 14:03:52', '2026-10-09 14:03:52', 0);
INSERT INTO `town_animation` VALUES (9, '云朵厨房', '☁️', '美食', '在云上做会飞的甜甜圈。', 83, '2026-10-09 14:03:52', '2026-10-09 14:03:52', 0);
INSERT INTO `town_animation` VALUES (10, '文字精灵', '📖', '语文', '汉字变成小精灵，陪你一起认字。', 80, '2026-10-09 14:03:52', '2026-10-09 14:03:52', 0);

-- ----------------------------
-- Table structure for town_favorite
-- ----------------------------
DROP TABLE IF EXISTS `town_favorite`;
CREATE TABLE `town_favorite`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint NOT NULL COMMENT '用户 id（town_user.id）',
  `animation_id` bigint NOT NULL COMMENT '动画 id（town_animation.id）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '收藏时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0=未删 / 1=已删',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_user`(`user_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '动画小镇用户收藏表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of town_favorite
-- ----------------------------
INSERT INTO `town_favorite` VALUES (1, 2, 4, '2026-10-09 14:19:07', '2026-10-09 14:19:07', 0);

-- ----------------------------
-- Table structure for town_user
-- ----------------------------
DROP TABLE IF EXISTS `town_user`;
CREATE TABLE `town_user`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '昵称 / 登录账号',
  `role` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '角色：kid=小朋友 / parent=家长',
  `avatar` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '' COMMENT '头像 emoji',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '' COMMENT '家长手机号（小朋友可不填）',
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'BCrypt 加密后的密码',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0=未删 / 1=已删',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_nickname`(`nickname` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '动画小镇用户表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of town_user
-- ----------------------------
INSERT INTO `town_user` VALUES (1, '测试小朋友', 'kid', '🐯', '', '$2a$10$wh1kALz9mg9agWRno5uqO.U65lJrsWOp2uzWWseHx2OyKcB9aetx6', '2026-10-09 14:08:10', '2026-10-09 14:08:10', 0);
INSERT INTO `town_user` VALUES (2, '朵朵', 'kid', '🦄', '', '$2a$10$nZ5367yNfRhoQIQmy29/X.r3ywgpFfpqK7pXJgyOMqjeIaX.6lpEm', '2026-10-09 14:19:02', '2026-10-09 14:19:02', 0);
INSERT INTO `town_user` VALUES (3, 'testkid', 'kid', '🐼', '', '$2a$10$I8DmOxpfMk6azCD1n9PBjO6eDVEUweROOEbXgeK3zX4u27E1X2q8y', '2026-10-09 14:47:49', '2026-10-09 14:47:49', 0);

SET FOREIGN_KEY_CHECKS = 1;
