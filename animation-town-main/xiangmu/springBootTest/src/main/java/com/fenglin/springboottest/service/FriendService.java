package com.fenglin.springboottest.service;

import com.fenglin.springboottest.dto.FriendRequestVO;
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
     * 按昵称搜索用户（排除自己，标注是否已是好友 / 是否已发申请）
     */
    List<FriendVO> searchUsers(Long userId, String keyword);

    /**
     * 发起好友申请（申请审批制：对方接受后才成为好友）
     */
    void applyFriend(Long userId, Long friendId, String remark);

    /**
     * 我收到的待处理好友申请
     */
    List<FriendRequestVO> pendingRequests(Long userId);

    /**
     * 接受好友申请：写入双向好友关系，申请标记为 accepted
     */
    void acceptRequest(Long userId, Long requestId);

    /**
     * 拒绝好友申请：申请标记为 rejected
     */
    void declineRequest(Long userId, Long requestId);

    /**
     * 删除好友（双向物理删除）
     */
    boolean removeFriend(Long userId, Long friendId);

    /**
     * 两人是否为好友（任一方向存在即算，正常情况双向都有）
     */
    boolean areFriends(Long userId, Long friendId);
}
