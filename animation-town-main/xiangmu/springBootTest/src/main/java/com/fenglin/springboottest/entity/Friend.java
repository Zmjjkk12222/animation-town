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
 * 好友关系实体，对应表 town_friend。
 * 好友关系为双向存储：A 加 B 时写入 (A,B) 与 (B,A) 两条记录。
 */
@Data
@TableName("town_friend")
public class Friend {

    /** 主键，自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 用户 id（town_user.id） */
    private Long userId;

    /** 好友 id（town_user.id） */
    private Long friendId;

    /** 成为好友时间（数据库维护，ORM 不写入） */
    @TableField(insertStrategy = FieldStrategy.NEVER, updateStrategy = FieldStrategy.NEVER)
    private LocalDateTime createTime;

    /** 更新时间（数据库维护，ORM 不写入） */
    @TableField(insertStrategy = FieldStrategy.NEVER, updateStrategy = FieldStrategy.NEVER)
    private LocalDateTime updateTime;

    /** 逻辑删除：0=未删 / 1=已删 */
    @TableLogic
    private Integer deleted;
}
