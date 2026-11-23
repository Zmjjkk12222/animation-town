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
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
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
        List<FriendVO> list = users.stream()
                .map(u -> {
                    FriendVO vo = FriendVO.of(u.getId(), u.getNickname(), u.getAvatar(), u.getRole());
                    vo.setOnline(onlineRegistry.isOnline(u.getId()));
                    return vo;
                })
                .collect(Collectors.toList());
        // 在线优先，其次按昵称——否则顺序取决于 listByIds 的返回次序，刷新一次可能换一个样
        list.sort(Comparator
                .comparing((FriendVO v) -> v.isOnline() ? 0 : 1)
                .thenComparing(v -> v.getNickname() == null ? "" : v.getNickname()));
        return list;
    }

    @Override
    public List<FriendVO> searchUsers(Long userId, String keyword) {
        checkUser(userId);
        String kw = keyword == null ? "" : keyword.trim();
        if (kw.isEmpty()) {
            return Collections.emptyList();
        }
        if (kw.length() > 20) {
            throw new IllegalArgumentException("搜索词太长了，最多 20 个字");
        }
        List<User> users = userService.lambdaQuery()
                .like(User::getNickname, kw)
                .ne(User::getId, userId)
                .orderByAsc(User::getNickname)
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
        try {
            return this.saveBatch(rows);
        } catch (DuplicateKeyException e) {
            // 唯一索引 uk_pair 兜底：并发 / 重复点击时后到的那条会被数据库挡下，
            // 此时关系其实已经建好，按幂等成功处理，不把异常抛给前端
            return true;
        }
    }

    @Override
    public boolean removeFriend(Long userId, Long friendId) {
        checkUser(userId);
        if (friendId == null) {
            throw new IllegalArgumentException("参数不完整");
        }
        // 物理删除双向两条：好友关系不必留历史，
        // 也避免"已删行"占住唯一索引导致重新添加失败
        return this.baseMapper.deletePair(userId, friendId) > 0;
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
