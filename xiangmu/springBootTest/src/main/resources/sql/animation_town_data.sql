-- ============================================================
-- 动画小镇 · 动画内容与收藏（在 animation_town.sql 之后执行）
-- 可重复执行：表用 IF NOT EXISTS，种子数据仅在表为空时插入。
-- ============================================================

USE animation_town;

-- 1) 动画表
CREATE TABLE IF NOT EXISTS town_animation (
  id           BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  title        VARCHAR(100) NOT NULL                COMMENT '动画标题',
  cover        VARCHAR(20)  NOT NULL DEFAULT ''     COMMENT '封面 emoji',
  category     VARCHAR(50)  NOT NULL DEFAULT ''     COMMENT '分类',
  description  VARCHAR(500) NOT NULL DEFAULT ''     COMMENT '简介',
  hot          INT          NOT NULL DEFAULT 0      COMMENT '热度（用于今日推荐排序）',
  create_time  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP                 COMMENT '创建时间',
  update_time  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  deleted      TINYINT      NOT NULL DEFAULT 0      COMMENT '逻辑删除：0=未删 / 1=已删',
  PRIMARY KEY (id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '动画小镇动画表';

-- 2) 用户收藏表（user_id + animation_id 唯一由业务层保证）
CREATE TABLE IF NOT EXISTS town_favorite (
  id            BIGINT   NOT NULL AUTO_INCREMENT COMMENT '主键',
  user_id       BIGINT   NOT NULL                COMMENT '用户 id（town_user.id）',
  animation_id  BIGINT   NOT NULL                COMMENT '动画 id（town_animation.id）',
  create_time   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP                 COMMENT '收藏时间',
  update_time   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  deleted       TINYINT  NOT NULL DEFAULT 0      COMMENT '逻辑删除：0=未删 / 1=已删',
  PRIMARY KEY (id),
  KEY idx_user (user_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '动画小镇用户收藏表';

-- 3) 动画种子数据（仅当表为空时插入，避免重复执行产生脏数据）
INSERT INTO town_animation (title, cover, category, description, hot)
SELECT t.title, t.cover, t.category, t.description, t.hot
FROM (
            SELECT '森林小勇士' AS title, '🌳' AS cover, '冒险' AS category, '跟随小松鼠穿越魔法森林，寻找失落的光之种子。' AS description, 98 AS hot
  UNION ALL SELECT '星星邮差', '⭐', '治愈', '每晚把小朋友的愿望，送到月亮上去。', 95
  UNION ALL SELECT '恐龙博士', '🦖', '科普', '和会说话的恐龙一起破解远古谜题。', 92
  UNION ALL SELECT '猫咪侦探社', '🐱', '推理', '和猫咪一起破解小镇里的神秘案件。', 91
  UNION ALL SELECT '太空小旅行家', '🚀', '科幻', '坐上纸飞船，去八大行星串个门。', 90
  UNION ALL SELECT '海底乐队', '🐠', '音乐', '一群海洋生物组队，开一场深海演唱会。', 88
  UNION ALL SELECT '小小发明家', '🔧', '科学', '用身边的材料，做出神奇的小实验。', 87
  UNION ALL SELECT '积木城市', '🧱', '创意', '用积木搭出你想象里的城市。', 85
  UNION ALL SELECT '云朵厨房', '☁️', '美食', '在云上做会飞的甜甜圈。', 83
  UNION ALL SELECT '文字精灵', '📖', '语文', '汉字变成小精灵，陪你一起认字。', 80
) t
WHERE NOT EXISTS (SELECT 1 FROM town_animation);

-- ============================================================
-- 执行完成后，动画表应有 10 条数据，收藏表为空。
-- ============================================================
