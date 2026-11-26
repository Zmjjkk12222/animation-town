package com.fenglin.springboottest.ws;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 在线用户注册表：userId -> 该账号的所有活着的 WebSocket 会话。
 * 供好友列表展示在线状态、邀请好友前判断对方是否在线、聊天消息实时推送使用。
 * <p>
 * 一个 userId 可以对应多条会话（同一账号开了多个标签页），
 * 因此这里用 Set 而不是单个 session：
 * · 关掉一个标签页不会让账号变成"离线"，
 * · 推送时会发到该账号的每一个标签页，哪个标签页在前台哪个就能看到。
 */
@Component
public class OnlineRegistry {

    /** userId -> 会话集合。集合本身用并发 Set，外层 Map 的增删用 compute 保证原子性 */
    private final Map<Long, Set<WebSocketSession>> online = new ConcurrentHashMap<>();

    public void register(Long userId, WebSocketSession session) {
        if (userId == null || session == null) return;
        // computeIfAbsent + compute 在同一 key 上互斥，避免"清空集合"和"新增会话"打架
        online.computeIfAbsent(userId, k -> ConcurrentHashMap.newKeySet()).add(session);
    }

    public void unregister(Long userId, WebSocketSession session) {
        if (userId == null) return;
        online.computeIfPresent(userId, (k, set) -> {
            set.remove(session);
            set.removeIf(s -> !s.isOpen());   // 顺手清掉已关闭的僵尸会话
            return set.isEmpty() ? null : set; // 全部关光了才把 key 摘掉
        });
    }

    /** 该账号是否还有活着的会话 */
    public boolean isOnline(Long userId) {
        if (userId == null) return false;
        Set<WebSocketSession> set = online.get(userId);
        if (set == null || set.isEmpty()) return false;
        for (WebSocketSession s : set) {
            if (s.isOpen()) return true;
        }
        return false;
    }

    /**
     * 取该账号的一个可用会话（优先返回活着的）。
     * 用于"需要一对一发送"的场景，例如对局里的对手会话。
     * 注意：多标签页时它只代表其中一个，广播请用 push / pushAll。
     */
    public WebSocketSession get(Long userId) {
        if (userId == null) return null;
        Set<WebSocketSession> set = online.get(userId);
        if (set == null) return null;
        for (WebSocketSession s : set) {
            if (s.isOpen()) return s;
        }
        return null;
    }

    /** 该账号当前所有可用会话（只读快照，永不返回 null） */
    public List<WebSocketSession> sessionsOf(Long userId) {
        if (userId == null) return Collections.emptyList();
        Set<WebSocketSession> set = online.get(userId);
        if (set == null || set.isEmpty()) return Collections.emptyList();
        List<WebSocketSession> out = new ArrayList<>(set.size());
        for (WebSocketSession s : set) {
            if (s.isOpen()) out.add(s);
        }
        return out;
    }

    /**
     * 向指定用户的<b>所有</b>在线会话推送一条文本帧。
     * 对方不在线 / 发送失败都只返回 false、不抛异常——
     * 调用方（如聊天）已经把消息落库，推送失败不影响业务正确性。
     *
     * @return 是否至少送达一个会话
     */
    public boolean push(Long userId, String payload) {
        boolean any = false;
        for (WebSocketSession s : sessionsOf(userId)) {
            if (sendQuietly(s, payload)) any = true;
        }
        return any;
    }

    /** push 的语义化别名：明确表达"发给他所有端" */
    public boolean pushAll(Long userId, String payload) {
        return push(userId, payload);
    }

    private boolean sendQuietly(WebSocketSession s, String payload) {
        try {
            synchronized (s) {
                s.sendMessage(new TextMessage(payload));
            }
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /** 当前在线账号 id 快照（调试用） */
    public Set<Long> onlineIds() {
        return Collections.unmodifiableSet(online.keySet());
    }
}
