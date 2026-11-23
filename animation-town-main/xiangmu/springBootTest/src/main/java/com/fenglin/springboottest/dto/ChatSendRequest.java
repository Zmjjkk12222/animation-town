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

    /** 正文，最多 500 字 */
    private String content;
}
