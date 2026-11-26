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

 Date: 26/11/2026 14:55:46
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
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '后台管理员表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of town_admin
-- ----------------------------
INSERT INTO `town_admin` VALUES (1, '朵朵', '$2a$10$FKrke2KmXR5G0OXJtAtXvuCtnO35dVFgIZSZeDTiPvhmWqoG9cNWq', '朵朵', '2026-11-09 08:44:41', '2026-11-09 08:44:41', 0);

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
  `play_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '' COMMENT '播放地址（外链视频，点击卡片跳转观看）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0=未删 / 1=已删',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 67 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '动画小镇动画表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of town_animation
-- ----------------------------
INSERT INTO `town_animation` VALUES (1, '森林小勇士', '🌳', '冒险', '跟随小松鼠穿越魔法森林，寻找失落的光之种子。', 98, 'https://deeteeenterprises.com/play/139376-1-0.html', '2026-11-09 08:38:25', '2026-11-09 08:38:25', 0);
INSERT INTO `town_animation` VALUES (2, '星星邮差', '⭐', '治愈', '每晚把小朋友的愿望，送到月亮上去。', 95, 'https://www.bilibili.com/video/BV16A336FEcH', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (3, '恐龙博士', '🦖', '科普', '和会说话的恐龙一起破解远古谜题。', 92, 'https://www.bilibili.com/video/BV1NrihBpEBn', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (4, '猫咪侦探社', '🐱', '推理', '和猫咪一起破解小镇里的神秘案件。', 91, 'https://www.bilibili.com/video/BV1odsr6GEwZ', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (5, '太空小旅行家', '🚀', '科幻', '坐上纸飞船，去八大行星串个门。', 90, 'https://www.bilibili.com/video/BV1eHyGzQEbR', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (6, '海底乐队', '🐠', '音乐', '一群海洋生物组队，开一场深海演唱会。', 88, 'https://www.bilibili.com/video/BV1awyazTEM5', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (7, '小小发明家', '🔧', '科学', '用身边的材料，做出神奇的小实验。', 87, 'https://www.bilibili.com/video/BV1Et4y1A7aR', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (8, '积木城市', '🧱', '创意', '用积木搭出你想象里的城市。', 85, 'https://www.bilibili.com/video/BV16dy5zTEiB', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (9, '云朵厨房', '☁️', '美食', '在云上做会飞的甜甜圈。', 83, 'https://www.bilibili.com/video/BV1AWNFzvEwJ', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (10, '文字精灵', '📖', '语文', '汉字变成小精灵，陪你一起认字。', 80, 'https://www.bilibili.com/video/BV1jt4y1c7Lf', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (11, '彩虹小丑团', '🤡', '搞笑', '一群爱闹腾的小丑，把笑声撒满整个小镇。', 78, 'https://www.bilibili.com/video/BV1Rsz8Y1EgB', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (12, '好朋友日记', '🤝', '友情', '记录小伙伴们一起度过的暖心小日子。', 77, 'https://www.bilibili.com/video/BV1Pot6zyELh', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (13, '睡美人新传', '👸', '童话', '公主醒来后，决定自己去闯荡城堡外的世界。', 76, 'https://www.bilibili.com/video/BV1rhK46tEGU', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (14, '草原大迁徙', '🦁', '自然', '跟着角马家族，见识非洲大草原的四季轮回。', 75, 'https://www.bilibili.com/video/BV1Ey4y1v7o5', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (15, '乒乓小将', '🏓', '运动', '小区球台走出的小冠军，一拍一拍拼出自信。', 74, 'https://www.bilibili.com/video/BV13a4y1Z7fs', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (16, '古代小神医', '🏮', '历史', '穿越回古代，用聪明办法帮乡亲们治病。', 73, 'https://www.bilibili.com/video/BV1Sy421v7YJ', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (17, '动物幼儿园', '🐼', '动物', '小熊猫小兔子一起上学，学习怎么照顾自己。', 72, 'https://www.bilibili.com/video/BV1HxGC6tE6W', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (18, '恐龙幼儿园', '🦕', '恐龙', '霸王龙宝宝也有温柔的一面，和伙伴快乐成长。', 71, 'https://www.bilibili.com/video/BV1GPuw6DEVc', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (19, '魔法画笔', '🎨', '艺术', '画笔画下的东西都会变成真的，快来创作吧。', 70, 'https://www.bilibili.com/video/BV1F5DvBtE4G', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (20, '星星足球队', '⚽', '运动', '夜空下的小球员，把流星当足球踢来踢去。', 69, 'https://www.bilibili.com/video/BV1yYbwzzE9b', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (21, '海底总动员', '🐙', '冒险', '小章鱼勇闯深海遗迹，营救走丢的朋友。', 68, 'https://www.bilibili.com/video/BV1fppG6sEAY', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (22, '森林音乐会', '🎵', '音乐', '动物们用树叶和溪水，奏响森林交响曲。', 67, 'https://www.bilibili.com/video/BV1Ab411j7p5', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (23, '太空农场', '🛰️', '科幻', '在太空站种出会发光的蔬菜，超级有趣。', 66, 'https://www.bilibili.com/video/BV19BVTeTE9j', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (24, '拼音王国', '🅰️', '语文', '声母韵母化身小兵，陪你闯关学拼音。', 65, 'https://www.bilibili.com/video/BV1eW8g6aEPM', '2026-11-09 08:38:25', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (32, '小哪吒闹海', '🌀', '神话', '脚踩风火轮的小英雄，大闹东海救回好朋友。', 89, 'https://www.bilibili.com/video/BV1fT421C7uq', '2026-11-09 08:56:21', '2026-11-23 09:41:19', 0);
INSERT INTO `town_animation` VALUES (33, '山海小灵兽', '🦊', '神话', '跟着小灵兽游历山海经里的奇幻世界。', 76, 'https://www.bilibili.com/video/BV1sHJe6REKp', '2026-11-09 08:56:21', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (34, '铁皮小伙伴', '🤖', '机器人', '会修理玩具的小机器人，成了全班最好的朋友。', 84, 'https://www.bilibili.com/video/BV1gLyLzWEam', '2026-11-09 08:56:21', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (35, '机器人足球赛', '🥅', '机器人', '看小机器人们踢出一场爆笑的世界杯。', 71, 'https://www.bilibili.com/video/BV1bc8x6YEgs', '2026-11-09 08:56:21', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (36, '谜题小岛', '🧩', '益智', '每集一个趣味谜题，动动脑筋就能出岛。', 82, 'https://www.bilibili.com/video/BV1zJK1zZENs', '2026-11-09 08:56:21', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (37, '数字小超人', '🔢', '益智', '加减乘除变成超能力，数学也能拯救世界。', 69, 'https://www.bilibili.com/video/BV1yRyuzaEuu', '2026-11-09 08:56:21', '2026-11-23 09:41:19', 0);
INSERT INTO `town_animation` VALUES (38, '芭蕾小天鹅', '🩰', '舞蹈', '大脚丫小天鹅也能跳出最美的舞蹈。', 80, 'https://www.bilibili.com/video/BV16A411t7gb', '2026-11-09 08:56:21', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (39, '街舞小子', '🕺', '舞蹈', '戴上帽子踩着节拍，跳出自我的风采。', 67, 'https://www.bilibili.com/video/BV1za411r7uL', '2026-11-09 08:56:21', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (40, '一年级奇妙日', '🎒', '校园', '开学第一天的爆笑与温暖，全都值得纪念。', 78, 'https://www.bilibili.com/video/BV1upDLBnEyD', '2026-11-09 08:56:21', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (41, '课桌里的秘密', '📚', '校园', '课桌里藏着一只会说话的铅笔盒。', 66, 'https://www.bilibili.com/video/BV1t2WpzXEPp', '2026-11-09 08:56:21', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (42, '月亮晚安曲', '🌙', '睡前故事', '柔柔的故事伴你入睡，做个甜甜的梦。', 86, 'https://www.bilibili.com/video/BV1e7qWBUE7T', '2026-11-09 08:56:21', '2026-11-23 09:41:19', 0);
INSERT INTO `town_animation` VALUES (43, '星星摇篮曲', '🌟', '睡前故事', '数着星星听故事，慢慢闭上眼睛。', 73, 'https://www.bilibili.com/video/BV1bLJ4zdEnb', '2026-11-09 08:56:21', '2026-11-23 09:41:19', 0);
INSERT INTO `town_animation` VALUES (44, '地球小卫士', '🌱', '环保', '垃圾分类大作战，守护我们的蓝色星球。', 83, 'https://www.bilibili.com/video/BV1Q1DCBME26', '2026-11-09 08:56:21', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (45, '海洋清洁队', '🌊', '环保', '小鱼们组队清理大海里的塑料垃圾。', 70, 'https://www.bilibili.com/video/BV1ma4y1L7QA', '2026-11-09 08:56:21', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (46, '瓢虫小侦探', '🐞', '昆虫', '七星瓢虫侦查花园里的每一个小秘密。', 79, 'https://www.bilibili.com/video/BV1hJ411L7ap', '2026-11-09 08:56:21', '2026-11-23 09:41:19', 0);
INSERT INTO `town_animation` VALUES (47, '蝴蝶变变变', '🦋', '昆虫', '毛毛虫破茧成蝶的美丽成长记。', 68, 'https://www.bilibili.com/video/BV1ru4y1k7zS', '2026-11-09 08:56:21', '2026-11-23 09:41:19', 0);
INSERT INTO `town_animation` VALUES (48, '高铁小飞侠', '🚄', '交通', '跟着小高铁穿越山脉和城市，认识大中国。', 81, 'https://www.bilibili.com/video/BV1ry4y1a7mX', '2026-11-09 08:56:21', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (49, '小飞机起飞', '✈️', '交通', '小飞机练习排队起飞，学会耐心与合作。', 72, 'https://www.bilibili.com/video/BV1F4sh6pELE', '2026-11-09 08:56:21', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (50, '水墨小侠客', '🏯', '国风', '一笔一划画出江湖，小小侠客行侠仗义。', 85, 'https://www.bilibili.com/video/BV1r2miYPEq2', '2026-11-09 08:56:21', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (51, '皮影戏之夜', '🎭', '国风', '灯影里的小人偶，演绎千年古老传说。', 74, 'https://www.bilibili.com/video/BV1YL4M6EESX', '2026-11-09 08:56:21', '2026-11-23 09:38:01', 0);
INSERT INTO `town_animation` VALUES (63, '罗磊', '🎬', '神话', '像只猪', 57, 'https://baike.baidu.com/item/%E7%8C%AA/147315', '2026-11-09 09:43:42', '2026-11-09 09:43:42', 0);
INSERT INTO `town_animation` VALUES (64, '熊出没', '🎬', '童话', '问问', 100, 'https://www.bilibili.com/video/BV1NreA6rE2L', '2026-11-09 09:45:10', '2026-11-23 09:41:19', 0);
INSERT INTO `town_animation` VALUES (65, '王者荣耀', '🎬', '冒险', '', 100, 'https://www.bilibili.com/video/BV1kQyjzmELr', '2026-11-09 09:58:27', '2026-11-23 09:41:19', 0);
INSERT INTO `town_animation` VALUES (66, '和平精英', '🎬', '冒险', '', 92, 'https://www.bilibili.com/video/BV1n3s16fEvv', '2026-11-09 09:59:19', '2026-11-23 09:41:19', 0);

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
) ENGINE = InnoDB AUTO_INCREMENT = 23 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '动画小镇用户收藏表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of town_favorite
-- ----------------------------
INSERT INTO `town_favorite` VALUES (1, 1, 3, '2026-11-09 08:47:57', '2026-11-09 08:47:57', 0);
INSERT INTO `town_favorite` VALUES (2, 1, 2, '2026-11-09 08:47:58', '2026-11-09 08:47:58', 0);
INSERT INTO `town_favorite` VALUES (3, 1, 1, '2026-11-09 08:47:59', '2026-11-09 08:47:59', 0);
INSERT INTO `town_favorite` VALUES (4, 1, 4, '2026-11-09 08:48:03', '2026-11-09 08:48:03', 0);
INSERT INTO `town_favorite` VALUES (5, 1, 5, '2026-11-09 08:48:04', '2026-11-09 08:48:04', 0);
INSERT INTO `town_favorite` VALUES (6, 3, 1, '2026-11-09 08:52:36', '2026-11-09 08:52:36', 0);
INSERT INTO `town_favorite` VALUES (7, 3, 3, '2026-11-09 08:52:39', '2026-11-09 08:52:39', 0);
INSERT INTO `town_favorite` VALUES (8, 3, 4, '2026-11-09 08:52:40', '2026-11-09 08:52:40', 0);
INSERT INTO `town_favorite` VALUES (9, 3, 5, '2026-11-09 08:52:42', '2026-11-09 08:52:42', 0);
INSERT INTO `town_favorite` VALUES (10, 7, 1, '2026-11-09 09:23:10', '2026-11-09 09:23:10', 0);
INSERT INTO `town_favorite` VALUES (11, 7, 2, '2026-11-09 09:23:16', '2026-11-09 09:23:16', 0);
INSERT INTO `town_favorite` VALUES (12, 9, 42, '2026-11-09 09:27:56', '2026-11-09 09:28:03', 1);
INSERT INTO `town_favorite` VALUES (13, 9, 43, '2026-11-09 09:28:01', '2026-11-09 09:28:02', 1);
INSERT INTO `town_favorite` VALUES (14, 9, 42, '2026-11-09 09:28:07', '2026-11-09 09:28:08', 1);
INSERT INTO `town_favorite` VALUES (15, 9, 5, '2026-11-09 09:28:12', '2026-11-09 09:28:15', 1);
INSERT INTO `town_favorite` VALUES (16, 9, 5, '2026-11-09 09:28:24', '2026-11-09 09:28:24', 0);
INSERT INTO `town_favorite` VALUES (17, 7, 3, '2026-11-09 09:29:44', '2026-11-09 09:29:44', 0);
INSERT INTO `town_favorite` VALUES (18, 7, 64, '2026-11-09 09:45:16', '2026-11-09 09:45:16', 0);
INSERT INTO `town_favorite` VALUES (19, 7, 65, '2026-11-09 09:58:45', '2026-11-09 09:58:45', 0);
INSERT INTO `town_favorite` VALUES (20, 1, 65, '2026-11-12 14:06:06', '2026-11-12 14:06:06', 0);
INSERT INTO `town_favorite` VALUES (21, 1, 64, '2026-11-12 14:07:04', '2026-11-12 14:07:04', 0);
INSERT INTO `town_favorite` VALUES (22, 1, 66, '2026-11-12 14:07:05', '2026-11-12 14:07:05', 0);

-- ----------------------------
-- Table structure for town_friend
-- ----------------------------
DROP TABLE IF EXISTS `town_friend`;
CREATE TABLE `town_friend`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint NOT NULL COMMENT '用户 id（town_user.id）',
  `friend_id` bigint NOT NULL COMMENT '好友 id（town_user.id）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '成为好友时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0=未删 / 1=已删',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_pair`(`user_id` ASC, `friend_id` ASC) USING BTREE,
  INDEX `idx_friend`(`friend_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 15 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '动画小镇好友表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of town_friend
-- ----------------------------
INSERT INTO `town_friend` VALUES (1, 3, 1, '2026-11-09 09:10:53', '2026-11-09 09:10:53', 0);
INSERT INTO `town_friend` VALUES (2, 1, 3, '2026-11-09 09:10:53', '2026-11-09 09:10:53', 0);
INSERT INTO `town_friend` VALUES (3, 1, 5, '2026-11-09 09:11:37', '2026-11-09 09:11:37', 0);
INSERT INTO `town_friend` VALUES (4, 5, 1, '2026-11-09 09:11:37', '2026-11-09 09:11:37', 0);
INSERT INTO `town_friend` VALUES (5, 3, 4, '2026-11-09 09:12:46', '2026-11-09 09:12:46', 0);
INSERT INTO `town_friend` VALUES (6, 4, 3, '2026-11-09 09:12:46', '2026-11-09 09:12:46', 0);
INSERT INTO `town_friend` VALUES (7, 7, 1, '2026-11-09 09:23:30', '2026-11-09 09:23:30', 0);
INSERT INTO `town_friend` VALUES (8, 1, 7, '2026-11-09 09:23:30', '2026-11-09 09:23:30', 0);
INSERT INTO `town_friend` VALUES (9, 13, 10, '2026-11-09 09:43:22', '2026-11-09 09:43:22', 0);
INSERT INTO `town_friend` VALUES (10, 10, 13, '2026-11-09 09:43:22', '2026-11-09 09:43:22', 0);
INSERT INTO `town_friend` VALUES (13, 1, 20, '2026-11-26 14:21:08', '2026-11-26 14:21:08', 0);
INSERT INTO `town_friend` VALUES (14, 20, 1, '2026-11-26 14:21:08', '2026-11-26 14:21:08', 0);

-- ----------------------------
-- Table structure for town_friend_request
-- ----------------------------
DROP TABLE IF EXISTS `town_friend_request`;
CREATE TABLE `town_friend_request`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `from_id` bigint NOT NULL COMMENT '申请发起者 id（town_user.id）',
  `to_id` bigint NOT NULL COMMENT '接收者 id（town_user.id）',
  `status` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'pending' COMMENT '状态：pending=待处理 / accepted=已接受 / rejected=已拒绝 / cancelled=已取消',
  `remark` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '' COMMENT '附加留言',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '申请时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_to_status`(`to_id` ASC, `status` ASC) USING BTREE,
  INDEX `idx_from_to`(`from_id` ASC, `to_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '动画小镇好友申请表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of town_friend_request
-- ----------------------------
INSERT INTO `town_friend_request` VALUES (2, 20, 1, 'accepted', '', '2026-11-26 14:21:02', '2026-11-26 14:21:08');

-- ----------------------------
-- Table structure for town_message
-- ----------------------------
DROP TABLE IF EXISTS `town_message`;
CREATE TABLE `town_message`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键（越大越新）',
  `from_id` bigint NOT NULL COMMENT '发送者 id（town_user.id）',
  `to_id` bigint NOT NULL COMMENT '接收者 id（town_user.id）',
  `type` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'text' COMMENT '消息类型：text/emoji',
  `content` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '消息正文（最多 500 字）',
  `read_flag` tinyint NOT NULL DEFAULT 0 COMMENT '是否已读：0=未读 / 1=已读',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_pair`(`from_id` ASC, `to_id` ASC, `id` ASC) USING BTREE,
  INDEX `idx_to_read`(`to_id` ASC, `read_flag` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 8 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '动画小镇好友聊天消息' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of town_message
-- ----------------------------
INSERT INTO `town_message` VALUES (2, 20, 1, 'emoji', '😁', 1, '2026-11-26 14:23:07');
INSERT INTO `town_message` VALUES (3, 1, 20, 'text', '你好', 1, '2026-11-26 14:23:28');
INSERT INTO `town_message` VALUES (5, 1, 20, 'emoji', '💪', 1, '2026-11-26 14:45:37');
INSERT INTO `town_message` VALUES (6, 20, 1, 'emoji', '🙏', 1, '2026-11-26 14:45:43');
INSERT INTO `town_message` VALUES (7, 1, 20, 'emoji', '😂', 1, '2026-11-26 14:49:13');

-- ----------------------------
-- Table structure for town_user
-- ----------------------------
DROP TABLE IF EXISTS `town_user`;
CREATE TABLE `town_user`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '昵称 / 登录账号',
  `role` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '角色：kid=小朋友 / parent=家长',
  `avatar` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '' COMMENT '头像 emoji',
  `avatar_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '' COMMENT '头像图片相对路径，空表示未上传',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '' COMMENT '家长手机号（小朋友可不填）',
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'BCrypt 加密后的密码',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '逻辑删除：0=未删 / 1=已删',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_nickname`(`nickname` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 21 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '动画小镇用户表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of town_user
-- ----------------------------
INSERT INTO `town_user` VALUES (1, '朵朵', 'kid', '🦄', '', '', '$2a$10$q3oh1VWzoikHOvYhsdMFP.GsIslpJZcbKD6ixoX3hNfwaIkKlVW9.', '2026-11-09 08:47:17', '2026-11-26 14:49:18', 0);
INSERT INTO `town_user` VALUES (2, '吴盛', 'kid', '🦄', '', '', '$2a$10$EamDsGlEx9K4ufQLW5q.puec6Rn630LsclCJl.r/qz7anaAT9D9aa', '2026-11-09 08:50:14', '2026-11-09 08:50:14', 0);
INSERT INTO `town_user` VALUES (3, '王星', 'kid', '🦄', '', '', '$2a$10$ARQy5KKTeegyhrKHAkfaD.onjRibLYd4e9W6.nWP9i3.NliMfIujC', '2026-11-09 08:51:49', '2026-11-09 08:51:49', 0);
INSERT INTO `town_user` VALUES (4, 'wso', 'parent', '🦄', '', '18345784578', '$2a$10$VK/mxwemoutQmnThg2l/FujzXxHyR7GdWQ46ghVIRrCgYv6HBqeda', '2026-11-09 09:09:23', '2026-11-09 09:09:23', 0);
INSERT INTO `town_user` VALUES (5, '乐乐', 'kid', '🐼', '', '', '$2a$10$eHlDlz/bEu1y2izLdQskt.m/M3u6D/hEWQnwJ9AX3OgpxpD7bLpYm', '2026-11-09 09:11:26', '2026-11-09 09:11:26', 0);
INSERT INTO `town_user` VALUES (6, '996762919', 'kid', '🐻', '', '', '$2a$10$.ihq2n/d.H3DoWW/K/o/W.LcFLIydNd5BM9rcbrW57JufYqxFMM7y', '2026-11-09 09:22:25', '2026-11-09 09:22:25', 0);
INSERT INTO `town_user` VALUES (7, '罗磊', 'kid', '🦄', '', '', '$2a$10$HX6KE2mJHldP4eJep1nsxu5vgGYy7VmK4WzfEOG/KWhXa7gA8Wl2a', '2026-11-09 09:22:36', '2026-11-09 09:22:36', 0);
INSERT INTO `town_user` VALUES (8, 'zyz', 'parent', '🦄', '', '12345678901', '$2a$10$s.jOBXgz1kf4PhQewoYMP.O0aTjX2/IpqGe.PnfNLLmEnpfCXx88O', '2026-11-09 09:23:08', '2026-11-09 09:23:08', 0);
INSERT INTO `town_user` VALUES (9, 'xx', 'kid', '🦄', '', '', '$2a$10$2UNQZ5drlcRKt0K4880BW.o3ewqwH3CTBQgohV81U4xxH6fZ0vsli', '2026-11-09 09:27:19', '2026-11-09 09:27:19', 0);
INSERT INTO `town_user` VALUES (10, '刘佳琦', 'kid', '🦄', '', '', '$2a$10$1AkyU.6cj1b7gYF.30FH1OsbKZ2UPGZQ2vNXrN3NbfM7ShYEstWb6', '2026-11-09 09:27:58', '2026-11-09 09:27:58', 0);
INSERT INTO `town_user` VALUES (11, '111', 'parent', '🦄', '', '11111111111', '$2a$10$WjswYvHVdLVjq66uP.zgaeCXI1O5yP1fN2b1NS7tB3JzPIaaE18W6', '2026-11-09 09:28:06', '2026-11-09 09:28:06', 0);
INSERT INTO `town_user` VALUES (12, '爸爸', 'parent', '🦄', '', '12345678911', '$2a$10$gsHlQcFLwmKU1bIcq6Dis.X8uzRJf4POqzcgrOtjZ7P8fu2hy7Qe6', '2026-11-09 09:28:07', '2026-11-09 09:28:07', 0);
INSERT INTO `town_user` VALUES (13, '方芳', 'parent', '🦄', '', '13366373843', '$2a$10$aHz66eGqXECFdK9.Gm/biOairhUtjpb7vhSRU4pTLBJe1YUQRbKCe', '2026-11-09 09:28:55', '2026-11-09 09:28:55', 0);
INSERT INTO `town_user` VALUES (14, '的理念和', 'kid', '🦄', '', '', '$2a$10$sUIoGOFkApofHsk9NK9iGe/4AFVmfqBohEORdBYcakDMQdZx5RUZC', '2026-11-09 09:29:18', '2026-11-09 09:29:18', 0);
INSERT INTO `town_user` VALUES (15, '哈哈', 'kid', '🦄', '', '', '$2a$10$bkA05ld6ZByWU32Fxy9CMeAqIhwWrmQSVg4u/4pQbs.pcoLaOVxP2', '2026-11-09 09:29:18', '2026-11-09 09:29:18', 0);
INSERT INTO `town_user` VALUES (18, '妈妈', 'parent', '🦄', '', '12345678911', '$2a$10$pdYL7naBc5ev6LOt3LtO9.hjw80byghWv5tUiQMJrkV8pWZgg9TR.', '2026-11-12 14:53:07', '2026-11-12 14:53:07', 0);
INSERT INTO `town_user` VALUES (19, '家长验证11', 'parent', '', '', '', '$2a$10$Tfs5Rzq28rjFEfrT.ivutO.JK1sJjIzQV.mUpMtsIp2wLH/tLpIum', '2026-11-12 15:04:46', '2026-11-12 15:04:46', 0);
INSERT INTO `town_user` VALUES (20, '燕霜', 'kid', '🦄', '', '', '$2a$10$ThCt/u.gXDLQFyJ8NpjyyuIRi6G7QpoUnet/n0aws756LWjRphCp.', '2026-11-26 14:18:08', '2026-11-26 14:18:08', 0);

SET FOREIGN_KEY_CHECKS = 1;
