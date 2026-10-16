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
 * 动画小镇用户实体，对应表 town_user
 */
@Data
@TableName("town_user")
public class User {

    /** 主键，自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 昵称 / 登录账号（唯一） */
    private String nickname;

    /** 角色：kid=小朋友 / parent=家长 */
    private String role;

    /** 头像 emoji */
    private String avatar;

    /** 家长手机号（小朋友可不填） */
    private String phone;

    /** BCrypt 加密后的密码 */
    private String password;

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
