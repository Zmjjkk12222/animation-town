package com.fenglin.springboottest.dto;

import lombok.Data;

/**
 * 发送聊天消息的请求体
 */
@Data
public class ChatSendRequest {

    /** 发送者 id */
    private Long fromId;

    /** 接收者（必须是好友） */
    private Long toId;

    /** 消息类型：text / emoji（默认 text） */
    private String type;

    /** 正文，最多 500 字（emoji 类型存 emoji 字符） */
    private String content;
}
