-- ============================================================
-- 用户头像上传功能：给 town_user 增加 avatar_url 列
-- 幂等：重复执行不会报错
-- ============================================================

-- 1. 增加头像图片地址列（varchar(255) 存相对路径 /uploads/avatar/xxx.png）
ALTER TABLE town_user
    ADD COLUMN avatar_url VARCHAR(255) NOT NULL DEFAULT '' COMMENT '头像图片相对路径，空表示未上传'
    AFTER avatar;
