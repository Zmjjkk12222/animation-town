package com.fenglin.springboottest.ws;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketSession;

import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 在线用户注册表：userId -> WebSocketSession。
 * 供好友列表展示在线状态、邀请好友前判断对方是否在线使用。
 * 只做轻量登记，不涉及业务。
 */
@Component
public class OnlineRegistry {

    private final ConcurrentHashMap<Long, WebSocketSession> online = new ConcurrentHashMap<>();

    public void register(Long userId, WebSocketSession session) {
        if (userId == null) return;
        // 同一账号多开时保留最后一个会话
        online.put(userId, session);
    }

    public void unregister(Long userId, WebSocketSession session) {
        if (userId == null) return;
        // 只有当前会话仍是登记的那个才移除，避免误踢新会话
        online.remove(userId, session);
    }

    public boolean isOnline(Long userId) {
        WebSocketSession s = online.get(userId);
        return s != null && s.isOpen();
    }

    public WebSocketSession get(Long userId) {
        return online.get(userId);
    }

    public Set<Long> onlineIds() {
        return online.keySet();
    }
}
