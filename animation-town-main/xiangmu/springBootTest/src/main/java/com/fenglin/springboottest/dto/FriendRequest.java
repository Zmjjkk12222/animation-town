package com.fenglin.springboottest.dto;

import lombok.Data;

/**
 * 好友请求体（添加/删除好友）
 */
@Data
public class FriendRequest {

    /** 发起操作的用户 id */
    private Long userId;

    /** 目标好友用户 id */
    private Long friendId;
}
