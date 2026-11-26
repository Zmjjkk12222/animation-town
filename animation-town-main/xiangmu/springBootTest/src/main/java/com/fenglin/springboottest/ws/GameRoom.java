package com.fenglin.springboottest.ws;

import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import java.io.IOException;

/**
 * 联机闯关房间：一个房间两位玩家（发起邀请者 = host，接受者 = guest）。
 * <p>
 * 会话在建立/接受时记录，但发送前会检查是否还活着；
 * 掉线重连后由 {@link GameWebSocketHandler#afterConnectionEstablished} 调 {@link #rebind} 换新，
 * 避免"房间抓着一条已关闭的会话、对方永远收不到包"。
 */
public class GameRoom {

    /** 等待接受的最长时间：超过后视为失效，允许发起方重新邀请或被别人邀请 */
    public static final long INVITE_TTL_MS = 90_000L;

    /** 房间号（短码） */
    private final String id;

    /** 发起邀请的用户 */
    private final Long hostId;

    /** 接受邀请的用户（接受后写入） */
    private Long guestId;

    /** 被邀请的用户（邀请发出时即确定，接受前就能用来通知对方"邀请已取消"） */
    private final Long inviteeId;

    /** 发起者会话 */
    private WebSocketSession hostSession;

    /** 接受者会话（接受后写入） */
    private WebSocketSession guestSession;

    /** 是否已被接受（进入游戏中） */
    private volatile boolean accepted;

    /** 创建时间，用于过期清理 */
    private final long createdAt = System.currentTimeMillis();

    public GameRoom(String id, Long hostId, Long inviteeId, WebSocketSession hostSession) {
        this.id = id;
        this.hostId = hostId;
        this.inviteeId = inviteeId;
        this.hostSession = hostSession;
    }

    public String getId() { return id; }
    public Long getHostId() { return hostId; }
    public Long getInviteeId() { return inviteeId; }
    public Long getGuestId() { return guestId; }
    public WebSocketSession getHostSession() { return hostSession; }
    public boolean isAccepted() { return accepted; }
    public long getCreatedAt() { return createdAt; }

    /** 还在等人接受、并且已经等太久了 */
    public boolean isExpired() {
        return !accepted && System.currentTimeMillis() - createdAt > INVITE_TTL_MS;
    }

    /** 房间是否包含该用户（host / guest / 已被邀请但还没接受的人） */
    public boolean contains(Long userId) {
        return userId != null
                && (userId.equals(hostId) || userId.equals(guestId) || userId.equals(inviteeId));
    }

    /** 是否已经满员（两人都在） */
    public boolean isFull() {
        return accepted && guestId != null;
    }

    public void accept(Long guestId, WebSocketSession guestSession) {
        this.guestId = guestId;
        this.guestSession = guestSession;
        this.accepted = true;
    }

    /** 掉线重连：把房间里记录的旧会话换成新会话 */
    public void rebind(Long userId, WebSocketSession session) {
        if (session == null || userId == null) return;
        if (userId.equals(hostId)) {
            hostSession = session;
        } else if (userId.equals(guestId)) {
            guestSession = session;
        }
    }

    /**
     * 只有当房间里记录的那条会话已经死了，才换成新会话。
     * <p>
     * 不能无条件 rebind：用户开着对局的标签页还在，又随手开了新标签页，
     * 无条件替换会把消息改发到一个没开游戏的标签页上，两边都像卡住了。
     *
     * @return 是否真的发生了接管（用于判断要不要通知对手"人回来了"）
     */
    public boolean rebindIfDead(Long userId, WebSocketSession session) {
        if (session == null || userId == null) return false;
        WebSocketSession cur = sessionOf(userId);
        if (cur != null && cur.isOpen()) return false;
        if (!userId.equals(hostId) && !userId.equals(guestId)) return false;
        rebind(userId, session);
        return true;
    }

    /** 房间里另一个人的 userId（接受前返回被邀请者） */
    public Long peerOf(Long userId) {
        if (userId == null) return null;
        if (userId.equals(hostId)) return guestId != null ? guestId : inviteeId;
        return hostId;
    }

    public WebSocketSession sessionOf(Long userId) {
        if (userId == null) return null;
        return userId.equals(hostId) ? hostSession : guestSession;
    }

    /** 给房间里的另一位玩家发消息（转发） */
    public void sendToPeer(Long senderId, String payload) {
        send(sessionOf(peerOf(senderId)), payload);
    }

    public void sendTo(Long userId, String payload) {
        send(sessionOf(userId), payload);
    }

    public void broadcast(String payload) {
        send(hostSession, payload);
        if (guestSession != null && guestSession != hostSession) {
            send(guestSession, payload);
        }
    }

    private void send(WebSocketSession session, String payload) {
        if (session == null || !session.isOpen()) return;
        try {
            synchronized (session) {
                session.sendMessage(new TextMessage(payload));
            }
        } catch (IOException ignored) {
            // 发送失败视同掉线，由 afterConnectionClosed 兜底清理
        }
    }
}
