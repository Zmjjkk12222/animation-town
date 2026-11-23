package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.FieldStrategy;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 好友聊天消息实体，对应表 town_message。
 * <p>
 * 注意：这里刻意不加 deleted 字段——消息不做逻辑删除，
 * 否则会被全局逻辑删除配置加上 deleted = 0 的查询条件。
 */
@Data
@TableName("town_message")
public class Message {

    /** 主键，自增（越大越新，可直接当游标用） */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 发送者 id（town_user.id） */
    private Long fromId;

    /** 接收者 id（town_user.id） */
    private Long toId;

    /** 消息正文 */
    private String content;

    /** 是否已读：0=未读 / 1=已读（数据库维护默认值） */
    private Integer readFlag;

    /** 发送时间（服务端写入，数据库另有默认值兜底） */
    @TableField(updateStrategy = FieldStrategy.NEVER)
    private LocalDateTime createTime;
}
