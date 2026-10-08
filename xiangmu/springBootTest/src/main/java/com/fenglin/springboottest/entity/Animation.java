package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.FieldStrategy;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 动画实体，对应表 town_animation
 */
@Data
@TableName("town_animation")
public class Animation {

    /** 主键，自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 动画标题 */
    private String title;

    /** 封面 emoji */
    private String cover;

    /** 分类（冒险 / 科普 / 治愈 ...） */
    private String category;

    /** 简介 */
    private String description;

    /** 热度，用于「今日推荐」排序 */
    private Integer hot;

    /** 创建时间（数据库维护，ORM 不写入） */
    @TableField(insertStrategy = FieldStrategy.NEVER, updateStrategy = FieldStrategy.NEVER)
    private LocalDateTime createTime;

    /** 更新时间（数据库维护，ORM 不写入） */
    @TableField(insertStrategy = FieldStrategy.NEVER, updateStrategy = FieldStrategy.NEVER)
    private LocalDateTime updateTime;

    /** 逻辑删除：0=未删 / 1=已删 */
    @TableLogic
    private Integer deleted;
}
