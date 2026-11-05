package com.fenglin.springboottest.service;

import com.fenglin.springboottest.dto.FriendVO;

import java.util.List;

/**
 * 好友业务接口
 */
public interface FriendService {

    /**
     * 我的好友列表（带在线状态）
     */
    List<FriendVO> listFriends(Long userId);

    /**
     * 按昵称搜索用户（排除自己，标注是否已是好友）
     */
    List<FriendVO> searchUsers(Long userId, String keyword);

    /**
     * 添加好友（双向写两条记录，幂等）
     */
    boolean addFriend(Long userId, Long friendId);

    /**
     * 删除好友（双向逻辑删除）
     */
    boolean removeFriend(Long userId, Long friendId);

    /**
     * 两人是否为好友（任一方向存在即算，正常情况双向都有）
     */
    boolean areFriends(Long userId, Long friendId);
}
