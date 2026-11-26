package com.fenglin.springboottest.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.fenglin.springboottest.dto.ChatMessageVO;
import com.fenglin.springboottest.entity.Message;
import com.fenglin.springboottest.mapper.MessageMapper;
import com.fenglin.springboottest.service.FriendService;
import com.fenglin.springboottest.service.MessageService;
import com.fenglin.springboottest.ws.OnlineRegistry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 好友聊天业务实现
 * <p>
 * 设计取舍：消息一律先落库，再尝试 WebSocket 推送。
 * 这样对方离线时消息不丢，在线时又是实时的；
 * 推送失败也不影响发送方——前端会以接口返回的消息为准。
 */
@Service
public class MessageServiceImpl extends ServiceImpl<MessageMapper, Message> implements MessageService {

    private static final Logger log = LoggerFactory.getLogger(MessageServiceImpl.class);
    private static final int MAX_LEN = 500;

    @Autowired
    private FriendService friendService;

    @Autowired
    private OnlineRegistry onlineRegistry;

    private final ObjectMapper om = new ObjectMapper();

    @Override
    public ChatMessageVO send(Long fromId, Long toId, String type, String content) {
        if (fromId == null || toId == null) {
            throw new IllegalArgumentException("用户参数不完整");
        }
        if (fromId.equals(toId)) {
            throw new IllegalArgumentException("不能给自己发消息哦～");
        }
        if (!friendService.areFriends(fromId, toId)) {
            throw new IllegalArgumentException("只能给好友发消息哦～");
        }
        String msgType = type == null ? "text" : type.trim();
        if (!"text".equals(msgType) && !"emoji".equals(msgType)) {
            throw new IllegalArgumentException("不支持的消息类型");
        }
        String text = content == null ? "" : content.trim();
        if (text.isEmpty()) {
            throw new IllegalArgumentException("说点什么吧～");
        }
        // 表情消息只允许单个 emoji 字符（或简单 ZWJ 组合序列），限制长度避免塞入大段文字
        int maxLen = "emoji".equals(msgType) ? 16 : MAX_LEN;
        if (text.length() > maxLen) {
            throw new IllegalArgumentException("消息太长了，最多 " + maxLen + " 字");
        }

        Message m = new Message();
        m.setFromId(fromId);
        m.setToId(toId);
        m.setType(msgType);
        m.setContent(text);
        m.setReadFlag(0);
        m.setCreateTime(LocalDateTime.now());
        this.save(m);

        ChatMessageVO vo = ChatMessageVO.of(m);
        push(toId, vo);
        return vo;
    }

    @Override
    public List<ChatMessageVO> history(Long userId, Long friendId, Long beforeId, int limit) {
        if (userId == null || friendId == null) {
            throw new IllegalArgumentException("用户参数不完整");
        }
        if (userId.equals(friendId)) {
            return Collections.emptyList();
        }
        int size = Math.min(Math.max(limit, 1), 100);
        // 打开会话即视为已读
        markRead(userId, friendId);

        List<Message> rows = this.lambdaQuery()
                .and(w -> w
                        .or(x -> x.eq(Message::getFromId, userId).eq(Message::getToId, friendId))
                        .or(x -> x.eq(Message::getFromId, friendId).eq(Message::getToId, userId)))
                .lt(beforeId != null, Message::getId, beforeId)
                .orderByDesc(Message::getId)
                .last("LIMIT " + size)
                .list();

        // 查出来是倒序（最新在前），前端按时间正序渲染，这里翻回来
        List<ChatMessageVO> out = new ArrayList<>(rows.size());
        for (int i = rows.size() - 1; i >= 0; i--) {
            out.add(ChatMessageVO.of(rows.get(i)));
        }
        return out;
    }

    @Override
    public Map<Long, Integer> unreadCounts(Long userId) {
        if (userId == null) {
            return Collections.emptyMap();
        }
        List<Map<String, Object>> rows = this.baseMapper.unreadByFriend(userId);
        Map<Long, Integer> out = new HashMap<>();
        for (Map<String, Object> row : rows) {
            Object from = row.get("fromId");
            Object cnt = row.get("cnt");
            if (from == null || cnt == null) continue;
            out.put(Long.valueOf(String.valueOf(from)), Integer.valueOf(String.valueOf(cnt)));
        }
        return out;
    }

    @Override
    public boolean markRead(Long userId, Long friendId) {
        if (userId == null || friendId == null) return false;
        return this.lambdaUpdate()
                .eq(Message::getToId, userId)
                .eq(Message::getFromId, friendId)
                .eq(Message::getReadFlag, 0)
                .set(Message::getReadFlag, 1)
                .update();
    }

    /** 推送给在线接收方：{t:'chat', id, from, to, content, ts, time} */
    private void push(Long toId, ChatMessageVO vo) {
        try {
            ObjectNode n = om.createObjectNode();
            n.put("t", "chat");
            n.put("id", vo.getId());
            n.put("from", vo.getFrom());
            n.put("to", vo.getTo());
            n.put("type", vo.getType());
            n.put("content", vo.getContent());
            n.put("ts", vo.getTs());
            n.put("time", vo.getTime());
            boolean ok = onlineRegistry.push(toId, n.toString());
            if (!ok) {
                log.debug("[chat] user {} 离线，消息 {} 仅入库", toId, vo.getId());
            }
        } catch (Exception e) {
            log.warn("[chat] push to {} failed: {}", toId, e.getMessage());
        }
    }
}
