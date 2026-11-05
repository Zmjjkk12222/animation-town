package com.fenglin.springboottest.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.dto.FriendVO;
import com.fenglin.springboottest.entity.Friend;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.mapper.FriendMapper;
import com.fenglin.springboottest.service.FriendService;
import com.fenglin.springboottest.service.UserService;
import com.fenglin.springboottest.ws.OnlineRegistry;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 好友业务实现
 */
@Service
public class FriendServiceImpl extends ServiceImpl<FriendMapper, Friend> implements FriendService {

    @Autowired
    @Lazy
    private UserService userService;

    @Autowired
    private OnlineRegistry onlineRegistry;

    @Override
    public List<FriendVO> listFriends(Long userId) {
        checkUser(userId);
        List<Long> friendIds = this.lambdaQuery()
                .select(Friend::getFriendId)
                .eq(Friend::getUserId, userId)
                .list()
                .stream()
                .map(Friend::getFriendId)
                .collect(Collectors.toList());
        if (friendIds.isEmpty()) {
            return Collections.emptyList();
        }
        List<User> users = userService.listByIds(friendIds);
        return users.stream()
                .map(u -> {
                    FriendVO vo = FriendVO.of(u.getId(), u.getNickname(), u.getAvatar(), u.getRole());
                    vo.setOnline(onlineRegistry.isOnline(u.getId()));
                    return vo;
                })
                .collect(Collectors.toList());
    }

    @Override
    public List<FriendVO> searchUsers(Long userId, String keyword) {
        checkUser(userId);
        String kw = keyword == null ? "" : keyword.trim();
        if (kw.isEmpty()) {
            return Collections.emptyList();
        }
        List<User> users = userService.lambdaQuery()
                .like(User::getNickname, kw)
                .ne(User::getId, userId)
                .last("LIMIT 20")
                .list();
        List<Long> friendIds = friendIdsOf(userId);
        return users.stream()
                .map(u -> {
                    FriendVO vo = FriendVO.of(u.getId(), u.getNickname(), u.getAvatar(), u.getRole());
                    vo.setIsFriend(friendIds.contains(u.getId()));
                    return vo;
                })
                .collect(Collectors.toList());
    }

    @Override
    public boolean addFriend(Long userId, Long friendId) {
        checkUser(userId);
        if (friendId == null) {
            throw new IllegalArgumentException("要添加的好友不存在");
        }
        if (friendId.equals(userId)) {
            throw new IllegalArgumentException("不能添加自己为好友哦～");
        }
        User target = userService.getById(friendId);
        if (target == null) {
            throw new IllegalArgumentException("要添加的好友不存在");
        }
        if (areFriends(userId, friendId)) {
            return true;   // 幂等：已是好友
        }
        // 双向写两条，双方各自的好友列表都能直接查到
        List<Friend> rows = new ArrayList<>();
        Friend a = new Friend();
        a.setUserId(userId);
        a.setFriendId(friendId);
        rows.add(a);
        Friend b = new Friend();
        b.setUserId(friendId);
        b.setFriendId(userId);
        rows.add(b);
        return this.saveBatch(rows);
    }

    @Override
    public boolean removeFriend(Long userId, Long friendId) {
        checkUser(userId);
        if (friendId == null) {
            throw new IllegalArgumentException("参数不完整");
        }
        return this.lambdaUpdate()
                .and(w -> w
                        .or(x -> x.eq(Friend::getUserId, userId).eq(Friend::getFriendId, friendId))
                        .or(x -> x.eq(Friend::getUserId, friendId).eq(Friend::getFriendId, userId)))
                .remove();
    }

    @Override
    public boolean areFriends(Long userId, Long friendId) {
        return this.lambdaQuery()
                .eq(Friend::getUserId, userId)
                .eq(Friend::getFriendId, friendId)
                .count() > 0;
    }

    private List<Long> friendIdsOf(Long userId) {
        return this.lambdaQuery()
                .select(Friend::getFriendId)
                .eq(Friend::getUserId, userId)
                .list()
                .stream()
                .map(Friend::getFriendId)
                .collect(Collectors.toList());
    }

    private void checkUser(Long userId) {
        if (userId == null) {
            throw new IllegalArgumentException("用户参数不完整");
        }
    }
}
