package com.fenglin.springboottest.dto;

import lombok.Data;

/**
 * 好友信息 VO（脱敏后的用户公开信息 + 在线状态）
 */
@Data
public class FriendVO {

    /** 用户 id */
    private Long id;

    /** 昵称 */
    private String nickname;

    /** 头像 emoji */
    private String avatar;

    /** 角色：kid=小朋友 / parent=家长 */
    private String role;

    /** 是否在线（连着游戏 WebSocket） */
    private boolean online;

    /** 是否已经是我的好友（搜索结果用） */
    private Boolean isFriend;

    public static FriendVO of(Long id, String nickname, String avatar, String role) {
        FriendVO vo = new FriendVO();
        vo.setId(id);
        vo.setNickname(nickname);
        vo.setAvatar(avatar);
        vo.setRole(role);
        return vo;
    }
}
