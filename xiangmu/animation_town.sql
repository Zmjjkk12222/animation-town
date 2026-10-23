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

 Date: 23/10/2026 15:07:08
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for town_admin
-- ----------------------------
DROP TABLE IF EXISTS `town_admin`;
CREATE TABLE `town_admin`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '管理员登录账号（唯一）',
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'BCrypt 加密后的密码',
  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT '显示名称',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0=正常 / 1=已删',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_admin_username`(`username` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '后台管理员表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of town_admin
-- ----------------------------
INSERT INTO `town_admin` VALUES (1, 'admin', '$2a$10$dBTVeuZMILcpgDF1BvtaW./voPDOkE2CDObLDL8NgOB73mR2cysSy', '小镇管理员', '2026-10-23 14:29:51', '2026-10-23 14:29:51', 0);

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
  `play_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '' COMMENT '播放地址',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 34 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '动画小镇动画表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of town_animation
-- ----------------------------
INSERT INTO `town_animation` VALUES (1, '森林小勇士', '🌳', '冒险', '跟随小松鼠穿越魔法森林，寻找失落的光之种子。', 98, '2026-10-12 08:40:42', '2026-10-12 09:53:24', 0, 'https://deeteeenterprises.com/play/139376-1-0.html');
INSERT INTO `town_animation` VALUES (2, '星星邮差', '⭐', '治愈', '每晚把小朋友的愿望，送到月亮上去。', 95, '2026-10-12 08:40:42', '2026-10-12 08:40:42', 0, '');
INSERT INTO `town_animation` VALUES (3, '恐龙博士', '🦖', '科普', '和会说话的恐龙一起破解远古谜题。', 92, '2026-10-12 08:40:42', '2026-10-12 08:40:42', 0, '');
INSERT INTO `town_animation` VALUES (4, '猫咪侦探社', '🐱', '推理', '和猫咪一起破解小镇里的神秘案件。', 91, '2026-10-12 08:40:42', '2026-10-12 08:40:42', 0, '');
INSERT INTO `town_animation` VALUES (5, '太空小旅行家', '🚀', '科幻', '坐上纸飞船，去八大行星串个门。', 90, '2026-10-12 08:40:42', '2026-10-12 08:40:42', 0, '');
INSERT INTO `town_animation` VALUES (6, '海底乐队', '🐠', '音乐', '一群海洋生物组队，开一场深海演唱会。', 88, '2026-10-12 08:40:42', '2026-10-12 08:40:42', 0, '');
INSERT INTO `town_animation` VALUES (7, '小小发明家', '🔧', '科学', '用身边的材料，做出神奇的小实验。', 87, '2026-10-12 08:40:42', '2026-10-12 08:40:42', 0, '');
INSERT INTO `town_animation` VALUES (8, '积木城市', '🧱', '创意', '用积木搭出你想象里的城市。', 85, '2026-10-12 08:40:42', '2026-10-12 08:40:42', 0, '');
INSERT INTO `town_animation` VALUES (9, '云朵厨房', '☁️', '美食', '在云上做会飞的甜甜圈。', 83, '2026-10-12 08:40:42', '2026-10-12 08:40:42', 0, '');
INSERT INTO `town_animation` VALUES (10, '文字精灵', '📖', '语文', '汉字变成小精灵，陪你一起认字。', 80, '2026-10-12 08:40:42', '2026-10-12 08:40:42', 0, '');
INSERT INTO `town_animation` VALUES (16, '彩虹小丑团', '🤡', '搞笑', '一群爱闹腾的小丑，把笑声撒满整个小镇。', 78, '2026-10-12 09:41:45', '2026-10-15 14:11:16', 0, '');
INSERT INTO `town_animation` VALUES (17, '好朋友日记', '🤝', '友情', '记录小伙伴们一起度过的暖心小日子。', 77, '2026-10-12 09:41:45', '2026-10-15 14:11:16', 0, '');
INSERT INTO `town_animation` VALUES (18, '睡美人新传', '👸', '童话', '公主醒来后，决定自己去闯荡城堡外的世界。', 76, '2026-10-12 09:41:45', '2026-10-15 14:11:16', 0, '');
INSERT INTO `town_animation` VALUES (19, '草原大迁徙', '🦁', '自然', '跟着角马家族，见识非洲大草原的四季轮回。', 75, '2026-10-12 09:41:45', '2026-10-15 14:11:16', 0, '');
INSERT INTO `town_animation` VALUES (20, '乒乓小将', '🏓', '运动', '小区球台走出的小冠军，一拍一拍拼出自信。', 74, '2026-10-12 09:41:45', '2026-10-15 14:11:16', 0, '');
INSERT INTO `town_animation` VALUES (21, '古代小神医', '🏮', '历史', '穿越回古代，用聪明办法帮乡亲们治病。', 73, '2026-10-12 09:41:45', '2026-10-15 14:11:16', 0, '');
INSERT INTO `town_animation` VALUES (22, '动物幼儿园', '🐼', '动物', '小熊猫小兔子一起上学，学习怎么照顾自己。', 72, '2026-10-12 09:41:45', '2026-10-15 14:11:16', 0, '');
INSERT INTO `town_animation` VALUES (23, '恐龙幼儿园', '🦕', '恐龙', '霸王龙宝宝也有温柔的一面，和伙伴快乐成长。', 71, '2026-10-12 09:41:45', '2026-10-15 14:11:16', 0, '');
INSERT INTO `town_animation` VALUES (24, '魔法画笔', '🎨', '艺术', '画笔画下的东西都会变成真的，快来创作吧。', 70, '2026-10-12 09:41:45', '2026-10-15 14:11:16', 0, '');
INSERT INTO `town_animation` VALUES (25, '星星足球队', '⚽', '运动', '夜空下的小球员，把流星当足球踢来踢去。', 69, '2026-10-12 09:41:45', '2026-10-15 14:11:16', 0, '');
INSERT INTO `town_animation` VALUES (26, '海底总动员', '🐙', '冒险', '小章鱼勇闯深海遗迹，营救走丢的朋友。', 68, '2026-10-12 09:41:45', '2026-10-15 14:11:16', 0, '');
INSERT INTO `town_animation` VALUES (27, '森林音乐会', '🎵', '音乐', '动物们用树叶和溪水，奏响森林交响曲。', 67, '2026-10-12 09:41:45', '2026-10-15 14:11:16', 0, '');
INSERT INTO `town_animation` VALUES (28, '太空农场', '🛰️', '科幻', '在太空站种出会发光的蔬菜，超级有趣。', 66, '2026-10-12 09:41:45', '2026-10-15 14:11:16', 0, '');
INSERT INTO `town_animation` VALUES (29, '拼音王国', '🅰️', '语文', '声母韵母化身小兵，陪你闯关学拼音。', 65, '2026-10-12 09:41:45', '2026-10-15 14:11:16', 0, '');

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
) ENGINE = InnoDB AUTO_INCREMENT = 11 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '动画小镇用户收藏表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of town_favorite
-- ----------------------------
INSERT INTO `town_favorite` VALUES (1, 1, 1, '2026-10-12 08:55:23', '2026-10-12 08:55:24', 1);
INSERT INTO `town_favorite` VALUES (2, 2, 2, '2026-10-12 09:30:34', '2026-10-12 09:30:34', 0);
INSERT INTO `town_favorite` VALUES (3, 2, 1, '2026-10-12 09:30:35', '2026-10-12 09:30:35', 0);
INSERT INTO `town_favorite` VALUES (4, 2, 3, '2026-10-12 09:30:36', '2026-10-12 09:30:36', 0);
INSERT INTO `town_favorite` VALUES (5, 3, 4, '2026-10-15 14:46:49', '2026-10-15 14:46:52', 1);
INSERT INTO `town_favorite` VALUES (6, 3, 1, '2026-10-15 14:48:16', '2026-10-15 14:48:16', 0);
INSERT INTO `town_favorite` VALUES (7, 3, 2, '2026-10-15 14:48:17', '2026-10-15 14:48:17', 0);
INSERT INTO `town_favorite` VALUES (8, 3, 3, '2026-10-15 14:48:18', '2026-10-15 14:48:18', 0);
INSERT INTO `town_favorite` VALUES (9, 4, 7, '2026-10-16 14:09:12', '2026-10-16 14:09:12', 0);
INSERT INTO `town_favorite` VALUES (10, 4, 1, '2026-10-16 14:51:26', '2026-10-16 14:51:26', 0);

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
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '动画小镇用户表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of town_user
-- ----------------------------
INSERT INTO `town_user` VALUES (1, 'testkid', 'kid', '🐱', '', '$2a$10$IduSnMaUd47w/uMF.5uujekO4i3P3ai6Cun.9oV8d07JWx2Ts1ccS', '2026-10-12 08:54:48', '2026-10-23 14:40:35', 1);
INSERT INTO `town_user` VALUES (2, '朵朵', 'kid', '🦄', '', '$2a$10$d2X6BqgW/1IqjmwGziY/.OP9t9jDe1IibYTzIOZswnJcGDWBwygLi', '2026-10-12 09:17:30', '2026-10-23 15:04:49', 0);
INSERT INTO `town_user` VALUES (3, '宁宁', 'kid', '🦄', '', '$2a$10$y2s4RuK08Hwvd59e5Xr6q.NwmISw6GuaQf7XfRa77YNg.O8OUl2py', '2026-10-15 14:03:22', '2026-10-23 14:40:28', 1);
INSERT INTO `town_user` VALUES (4, '王星', 'kid', '🦄', '', '$2a$10$EGf86NVRM8OUHOPasvhSwee3r3G9YPI0TD3fnl88V0Gg47W3t4xV.', '2026-10-16 14:08:41', '2026-10-23 14:34:41', 0);
INSERT INTO `town_user` VALUES (5, '罗磊', 'kid', '🦄', '', '$2a$10$9eoNMxuNBq07LseDXcN32OnLmh7/1yDvsYgoGqpwlzz7aDzzTz/ne', '2026-10-23 15:03:27', '2026-10-23 15:03:27', 0);

SET FOREIGN_KEY_CHECKS = 1;
