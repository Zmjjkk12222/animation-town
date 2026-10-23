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
 * 后台管理员实体，对应表 town_admin
 * 与前台用户表 town_user 完全隔离，仅用于后台管理系统登录
 */
@Data
@TableName("town_admin")
public class Admin {

    /** 主键，自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 管理员登录账号（唯一） */
    private String username;

    /** BCrypt 加密后的密码 */
    private String password;

    /** 显示名称 */
    private String nickname;

    /** 创建时间（由数据库默认值填充，ORM 不写入） */
    @TableField(insertStrategy = FieldStrategy.NEVER, updateStrategy = FieldStrategy.NEVER)
    private LocalDateTime createTime;

    /** 更新时间（由数据库 ON UPDATE 维护，ORM 不写入） */
    @TableField(insertStrategy = FieldStrategy.NEVER, updateStrategy = FieldStrategy.NEVER)
    private LocalDateTime updateTime;

    /** 逻辑删除：0=未删 / 1=已删 */
    @TableLogic
    private Integer deleted;
}
