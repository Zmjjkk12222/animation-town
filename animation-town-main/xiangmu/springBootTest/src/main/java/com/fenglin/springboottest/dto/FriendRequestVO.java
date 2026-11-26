package com.fenglin.springboottest.dto;

import lombok.Data;

/**
 * 好友申请出参（带申请人公开信息 + 状态）
 */
@Data
public class FriendRequestVO {

    /** 申请记录 id */
    private Long id;

    /** 申请人用户 id */
    private Long fromId;

    /** 接收者用户 id */
    private Long toId;

    /** 状态：pending / accepted / rejected / cancelled */
    private String status;

    /** 附加留言 */
    private String remark;

    /** 申请人昵称 */
    private String nickname;

    /** 申请人头像 emoji */
    private String avatar;

    /** 申请人角色：kid / parent */
    private String role;

    /** 申请时间（毫秒时间戳，前端用于展示） */
    private Long ts;
}
