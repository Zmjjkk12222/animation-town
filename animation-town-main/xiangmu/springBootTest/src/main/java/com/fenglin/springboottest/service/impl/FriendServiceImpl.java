package com.fenglin.springboottest.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.dto.FriendRequestVO;
import com.fenglin.springboottest.dto.FriendVO;
import com.fenglin.springboottest.entity.Friend;
import com.fenglin.springboottest.entity.FriendRequestEntity;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.mapper.FriendMapper;
import com.fenglin.springboottest.mapper.FriendRequestMapper;
import com.fenglin.springboottest.service.FriendService;
import com.fenglin.springboottest.service.UserService;
import com.fenglin.springboottest.ws.OnlineRegistry;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 好友业务实现（申请审批制）
 * <p>
 * 流程：A 向 B 发起申请（pending）→ B 接受（写入双向好友关系）或拒绝（rejected）。
 * 旧版「直接添加即好友」已升级为审批制，addFriend 语义由 applyFriend 替代。
 */
@Service
public class FriendServiceImpl extends ServiceImpl<FriendMapper, Friend> implements FriendService {

    @Autowired
    @Lazy
    private UserService userService;

    @Autowired
    private OnlineRegistry onlineRegistry;

    @Autowired
    private FriendRequestMapper friendRequestMapper;

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
        Set<Long> friendIds = new HashSet<>(friendIdsOf(userId));
        // 我已向对方发起、且仍在待处理的申请，用于前端显示「已申请」
        Set<Long> appliedIds = friendRequestMapper.selectList(
                new LambdaQueryWrapper<FriendRequestEntity>()
                        .select(FriendRequestEntity::getToId)
                        .eq(FriendRequestEntity::getFromId, userId)
                        .eq(FriendRequestEntity::getStatus, "pending"))
                .stream()
                .map(FriendRequestEntity::getToId)
                .collect(Collectors.toSet());
        return users.stream()
                .map(u -> {
                    FriendVO vo = FriendVO.of(u.getId(), u.getNickname(), u.getAvatar(), u.getRole());
                    vo.setIsFriend(friendIds.contains(u.getId()));
                    vo.setIsApplied(appliedIds.contains(u.getId()));
                    return vo;
                })
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void applyFriend(Long userId, Long friendId, String remark) {
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
            throw new IllegalArgumentException("你们已经是好友啦～");
        }
        // 对方已向我发过待处理申请：直接接受，免去两边各发一次
        FriendRequestEntity incoming = friendRequestMapper.selectOne(
                new LambdaQueryWrapper<FriendRequestEntity>()
                        .eq(FriendRequestEntity::getFromId, friendId)
                        .eq(FriendRequestEntity::getToId, userId)
                        .eq(FriendRequestEntity::getStatus, "pending")
                        .last("LIMIT 1"));
        if (incoming != null) {
            acceptRequest(userId, incoming.getId());
            return;
        }
        // 我已发过待处理申请：幂等返回，不重复发
        Long exist = friendRequestMapper.selectList(
                new LambdaQueryWrapper<FriendRequestEntity>()
                        .select(FriendRequestEntity::getId)
                        .eq(FriendRequestEntity::getFromId, userId)
                        .eq(FriendRequestEntity::getToId, friendId)
                        .eq(FriendRequestEntity::getStatus, "pending"))
                .stream()
                .map(FriendRequestEntity::getId)
                .findFirst()
                .orElse(null);
        if (exist != null) {
            return;
        }
        FriendRequestEntity req = new FriendRequestEntity();
        req.setFromId(userId);
        req.setToId(friendId);
        req.setStatus("pending");
        req.setRemark(remark == null ? "" : remark.trim());
        friendRequestMapper.insert(req);
    }

    @Override
    public List<FriendRequestVO> pendingRequests(Long userId) {
        checkUser(userId);
        List<FriendRequestEntity> rows = friendRequestMapper.selectList(
                new LambdaQueryWrapper<FriendRequestEntity>()
                        .eq(FriendRequestEntity::getToId, userId)
                        .eq(FriendRequestEntity::getStatus, "pending")
                        .orderByDesc(FriendRequestEntity::getId));
        if (rows.isEmpty()) {
            return Collections.emptyList();
        }
        List<Long> fromIds = rows.stream().map(FriendRequestEntity::getFromId).collect(Collectors.toList());
        java.util.Map<Long, User> users = userService.listByIds(fromIds).stream()
                .collect(Collectors.toMap(User::getId, u -> u, (a, b) -> a));
        List<FriendRequestVO> out = new ArrayList<>(rows.size());
        for (FriendRequestEntity r : rows) {
            FriendRequestVO vo = new FriendRequestVO();
            vo.setId(r.getId());
            vo.setFromId(r.getFromId());
            vo.setToId(r.getToId());
            vo.setStatus(r.getStatus());
            vo.setRemark(r.getRemark());
            User u = users.get(r.getFromId());
            if (u != null) {
                vo.setNickname(u.getNickname());
                vo.setAvatar(u.getAvatar());
                vo.setRole(u.getRole());
            }
            if (r.getCreateTime() != null) {
                vo.setTs(r.getCreateTime().atZone(ZoneId.systemDefault()).toInstant().toEpochMilli());
            }
            out.add(vo);
        }
        return out;
    }

    @Override
    @Transactional
    public void acceptRequest(Long userId, Long requestId) {
        checkUser(userId);
        if (requestId == null) {
            throw new IllegalArgumentException("申请不存在");
        }
        FriendRequestEntity req = friendRequestMapper.selectById(requestId);
        if (req == null || !req.getToId().equals(userId)) {
            throw new IllegalArgumentException("申请不存在");
        }
        if (!"pending".equals(req.getStatus())) {
            throw new IllegalArgumentException("这条申请已经处理过啦～");
        }
        Long fromId = req.getFromId();
        if (areFriends(userId, fromId)) {
            // 已经是好友：把申请标记为 accepted 收尾即可
            req.setStatus("accepted");
            friendRequestMapper.updateById(req);
            return;
        }
        // 写入双向好友关系（唯一索引 uk_pair 兜底并发）
        List<Friend> rows = new ArrayList<>();
        Friend a = new Friend();
        a.setUserId(userId);
        a.setFriendId(fromId);
        rows.add(a);
        Friend b = new Friend();
        b.setUserId(fromId);
        b.setFriendId(userId);
        rows.add(b);
        try {
            this.saveBatch(rows);
        } catch (DuplicateKeyException ignored) {
            // 并发 / 重复接受时后到的一方被数据库挡下，关系已存在，按成功处理
        }
        req.setStatus("accepted");
        friendRequestMapper.updateById(req);
    }

    @Override
    public void declineRequest(Long userId, Long requestId) {
        checkUser(userId);
        if (requestId == null) {
            throw new IllegalArgumentException("申请不存在");
        }
        FriendRequestEntity req = friendRequestMapper.selectById(requestId);
        if (req == null || !req.getToId().equals(userId)) {
            throw new IllegalArgumentException("申请不存在");
        }
        if (!"pending".equals(req.getStatus())) {
            throw new IllegalArgumentException("这条申请已经处理过啦～");
        }
        req.setStatus("rejected");
        friendRequestMapper.updateById(req);
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
