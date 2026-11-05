package com.fenglin.springboottest.ws;

import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import java.io.IOException;

/**
 * 联机闯关房间：一个房间两位玩家（发起邀请者 = host，接受者 = guest）。
 */
public class GameRoom {

    /** 房间号（短码） */
    private final String id;

    /** 发起邀请的用户 */
    private final Long hostId;

    /** 接受邀请的用户（接受后写入） */
    private Long guestId;

    /** 发起者会话 */
    private final WebSocketSession hostSession;

    /** 接受者会话（接受后写入） */
    private WebSocketSession guestSession;

    /** 是否已被接受（进入游戏中） */
    private volatile boolean accepted;

    public GameRoom(String id, Long hostId, WebSocketSession hostSession) {
        this.id = id;
        this.hostId = hostId;
        this.hostSession = hostSession;
    }

    public String getId() { return id; }
    public Long getHostId() { return hostId; }
    public Long getGuestId() { return guestId; }
    public WebSocketSession getHostSession() { return hostSession; }
    public boolean isAccepted() { return accepted; }

    public void accept(Long guestId, WebSocketSession guestSession) {
        this.guestId = guestId;
        this.guestSession = guestSession;
        this.accepted = true;
    }

    /** 给房间里的另一位玩家发消息（转发） */
    public void sendToPeer(Long senderId, String payload) {
        WebSocketSession peer = senderId.equals(hostId) ? guestSession : hostSession;
        send(peer, payload);
    }

    public void sendTo(Long userId, String payload) {
        WebSocketSession s = userId.equals(hostId) ? hostSession : guestSession;
        send(s, payload);
    }

    public void broadcast(String payload) {
        send(hostSession, payload);
        if (guestSession != null && guestSession != hostSession) {
            send(guestSession, payload);
        }
    }

    /** 房间里另一个人的 userId */
    public Long peerOf(Long userId) {
        return userId.equals(hostId) ? guestId : hostId;
    }

    public WebSocketSession peerSessionOf(Long userId) {
        return userId.equals(hostId) ? guestSession : hostSession;
    }

    private void send(WebSocketSession session, String payload) {
        try {
            if (session != null && session.isOpen()) {
                synchronized (session) {
                    session.sendMessage(new TextMessage(payload));
                }
            }
        } catch (IOException ignored) {
            // 发送失败视同掉线，由 afterConnectionClosed 兜底清理
        }
    }
}
