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
  play_url     VARCHAR(255) NOT NULL DEFAULT ''     COMMENT '播放地址（外链视频，点击卡片跳转观看）',
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

-- 3) 动画种子数据（按标题幂等：仅当同标题不存在时插入，可重复执行、可增量扩充）
INSERT INTO town_animation (title, cover, category, description, hot, play_url)
SELECT t.title, t.cover, t.category, t.description, t.hot, t.play_url FROM (
            SELECT '森林小勇士' AS title, '🌳' AS cover, '冒险' AS category, '跟随小松鼠穿越魔法森林，寻找失落的光之种子。' AS description, 98 AS hot, 'https://deeteeenterprises.com/play/139376-1-0.html' AS play_url
  UNION ALL SELECT '星星邮差', '⭐', '治愈', '每晚把小朋友的愿望，送到月亮上去。', 95, ''
  UNION ALL SELECT '恐龙博士', '🦖', '科普', '和会说话的恐龙一起破解远古谜题。', 92, ''
  UNION ALL SELECT '猫咪侦探社', '🐱', '推理', '和猫咪一起破解小镇里的神秘案件。', 91, ''
  UNION ALL SELECT '太空小旅行家', '🚀', '科幻', '坐上纸飞船，去八大行星串个门。', 90, ''
  UNION ALL SELECT '海底乐队', '🐠', '音乐', '一群海洋生物组队，开一场深海演唱会。', 88, ''
  UNION ALL SELECT '小小发明家', '🔧', '科学', '用身边的材料，做出神奇的小实验。', 87, ''
  UNION ALL SELECT '积木城市', '🧱', '创意', '用积木搭出你想象里的城市。', 85, ''
  UNION ALL SELECT '云朵厨房', '☁️', '美食', '在云上做会飞的甜甜圈。', 83, ''
  UNION ALL SELECT '文字精灵', '📖', '语文', '汉字变成小精灵，陪你一起认字。', 80, ''
  UNION ALL SELECT '彩虹小丑团', '🤡', '搞笑', '一群爱闹腾的小丑，把笑声撒满整个小镇。', 78, ''
  UNION ALL SELECT '好朋友日记', '🤝', '友情', '记录小伙伴们一起度过的暖心小日子。', 77, ''
  UNION ALL SELECT '睡美人新传', '👸', '童话', '公主醒来后，决定自己去闯荡城堡外的世界。', 76, ''
  UNION ALL SELECT '草原大迁徙', '🦁', '自然', '跟着角马家族，见识非洲大草原的四季轮回。', 75, ''
  UNION ALL SELECT '乒乓小将', '🏓', '运动', '小区球台走出的小冠军，一拍一拍拼出自信。', 74, ''
  UNION ALL SELECT '古代小神医', '🏮', '历史', '穿越回古代，用聪明办法帮乡亲们治病。', 73, ''
  UNION ALL SELECT '动物幼儿园', '🐼', '动物', '小熊猫小兔子一起上学，学习怎么照顾自己。', 72, ''
  UNION ALL SELECT '恐龙幼儿园', '🦕', '恐龙', '霸王龙宝宝也有温柔的一面，和伙伴快乐成长。', 71, ''
  UNION ALL SELECT '魔法画笔', '🎨', '艺术', '画笔画下的东西都会变成真的，快来创作吧。', 70, ''
  UNION ALL SELECT '星星足球队', '⚽', '运动', '夜空下的小球员，把流星当足球踢来踢去。', 69, ''
  UNION ALL SELECT '海底总动员', '🐙', '冒险', '小章鱼勇闯深海遗迹，营救走丢的朋友。', 68, ''
  UNION ALL SELECT '森林音乐会', '🎵', '音乐', '动物们用树叶和溪水，奏响森林交响曲。', 67, ''
  UNION ALL SELECT '太空农场', '🛰️', '科幻', '在太空站种出会发光的蔬菜，超级有趣。', 66, ''
  UNION ALL SELECT '拼音王国', '🅰️', '语文', '声母韵母化身小兵，陪你闯关学拼音。', 65, ''
) t
WHERE NOT EXISTS (SELECT 1 FROM town_animation WHERE title = t.title);

-- 4) 分类扩充种子数据（新增 10 个动画类型：神话/机器人/益智/舞蹈/校园/睡前故事/环保/昆虫/交通/国风）
INSERT INTO town_animation (title, cover, category, description, hot, play_url)
SELECT t.title, t.cover, t.category, t.description, t.hot, t.play_url FROM (
            SELECT '小哪吒闹海' AS title, '🌀' AS cover, '神话' AS category, '脚踩风火轮的小英雄，大闹东海救回好朋友。' AS description, 89 AS hot, '' AS play_url
  UNION ALL SELECT '山海小灵兽', '🦊', '神话', '跟着小灵兽游历山海经里的奇幻世界。', 76, ''
  UNION ALL SELECT '铁皮小伙伴', '🤖', '机器人', '会修理玩具的小机器人，成了全班最好的朋友。', 84, ''
  UNION ALL SELECT '机器人足球赛', '🥅', '机器人', '看小机器人们踢出一场爆笑的世界杯。', 71, ''
  UNION ALL SELECT '谜题小岛', '🧩', '益智', '每集一个趣味谜题，动动脑筋就能出岛。', 82, ''
  UNION ALL SELECT '数字小超人', '🔢', '益智', '加减乘除变成超能力，数学也能拯救世界。', 69, ''
  UNION ALL SELECT '芭蕾小天鹅', '🩰', '舞蹈', '大脚丫小天鹅也能跳出最美的舞蹈。', 80, ''
  UNION ALL SELECT '街舞小子', '🕺', '舞蹈', '戴上帽子踩着节拍，跳出自我的风采。', 67, ''
  UNION ALL SELECT '一年级奇妙日', '🎒', '校园', '开学第一天的爆笑与温暖，全都值得纪念。', 78, ''
  UNION ALL SELECT '课桌里的秘密', '📚', '校园', '课桌里藏着一只会说话的铅笔盒。', 66, ''
  UNION ALL SELECT '月亮晚安曲', '🌙', '睡前故事', '柔柔的故事伴你入睡，做个甜甜的梦。', 86, ''
  UNION ALL SELECT '星星摇篮曲', '🌟', '睡前故事', '数着星星听故事，慢慢闭上眼睛。', 73, ''
  UNION ALL SELECT '地球小卫士', '🌱', '环保', '垃圾分类大作战，守护我们的蓝色星球。', 83, ''
  UNION ALL SELECT '海洋清洁队', '🌊', '环保', '小鱼们组队清理大海里的塑料垃圾。', 70, ''
  UNION ALL SELECT '瓢虫小侦探', '🐞', '昆虫', '七星瓢虫侦查花园里的每一个小秘密。', 79, ''
  UNION ALL SELECT '蝴蝶变变变', '🦋', '昆虫', '毛毛虫破茧成蝶的美丽成长记。', 68, ''
  UNION ALL SELECT '高铁小飞侠', '🚄', '交通', '跟着小高铁穿越山脉和城市，认识大中国。', 81, ''
  UNION ALL SELECT '小飞机起飞', '✈️', '交通', '小飞机练习排队起飞，学会耐心与合作。', 72, ''
  UNION ALL SELECT '水墨小侠客', '🏯', '国风', '一笔一划画出江湖，小小侠客行侠仗义。', 85, ''
  UNION ALL SELECT '皮影戏之夜', '🎭', '国风', '灯影里的小人偶，演绎千年古老传说。', 74, ''
) t
WHERE NOT EXISTS (SELECT 1 FROM town_animation WHERE title = t.title);

-- ============================================================
-- 执行完成后，动画表应有 44 条数据（24 基础 + 20 新类型扩充），收藏表为空。
-- 其中「森林小勇士」已配置播放地址 play_url，点击卡片即可跳转观看。
-- ============================================================
