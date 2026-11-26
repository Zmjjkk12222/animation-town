package com.fenglin.springboottest.dto;

import lombok.Data;

/**
 * 好友申请请求体
 */
@Data
public class FriendApplyRequest {

    /** 发起申请的用户 id */
    private Long userId;

    /** 目标好友用户 id */
    private Long friendId;

    /** 附加留言（可选） */
    private String remark;
}
