package com.fenglin.springboottest.ws;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.service.FriendService;
import com.fenglin.springboottest.service.UserService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ThreadLocalRandom;

/**
 * 联机闯关 WebSocket 处理器
 * <p>
 * 消息协议（JSON 文本帧）：
 *   客户端 -> 服务端：
 *     {t:'invite', to}             邀请好友（创建待接受房间）
 *     {t:'accept', room}           接受邀请（进入游戏）
 *     {t:'decline', room}          拒绝邀请
 *     {t:'cancel', room}           发起方取消等待中的邀请
 *     {t:'leave', room}            离开房间
 *     {t:'pos'|'gem'|'plate'|'dead'|'restart', room, ...}  游戏内消息，原样转发给对方
 *   服务端 -> 客户端：
 *     invited / inviting / start / declined / cancelled / peer-left / peer-online / peer-offline / error
 * <p>
 * 健壮性约定：
 * · 邀请 90 秒无人接受自动作废（避免"对方正在游戏中"的幽灵状态）
 * · 一方掉线只发 peer-offline，保留房间 30 秒等重连；超时才销毁并通知 peer-left
 * · 同一账号多标签页时，关掉一个标签页不会销毁对局
 * · 所有房间操作都会校验调用者确实是房间成员
 */
@Component
public class GameWebSocketHandler extends TextWebSocketHandler {

    private static final Logger log = LoggerFactory.getLogger(GameWebSocketHandler.class);

    /** 掉线宽限期：超过这个时间还没重连回来，才真正销毁房间 */
    private static final long OFFLINE_GRACE_MS = 30_000L;

    private final OnlineRegistry onlineRegistry;
    private final FriendService friendService;
    private final UserService userService;
    private final ObjectMapper om = new ObjectMapper();

    /** roomId -> 房间 */
    private final ConcurrentHashMap<String, GameRoom> rooms = new ConcurrentHashMap<>();
    /** userId -> 当前所在 roomId */
    private final ConcurrentHashMap<Long, String> userRoom = new ConcurrentHashMap<>();
    /** roomId -> 掉线开始时间（宽限期内可重连恢复） */
    private final ConcurrentHashMap<String, Long> orphanedAt = new ConcurrentHashMap<>();

    public GameWebSocketHandler(OnlineRegistry onlineRegistry, FriendService friendService, UserService userService) {
        this.onlineRegistry = onlineRegistry;
        this.friendService = friendService;
        this.userService = userService;
    }

    // ============================================================
    // 连接生命周期
    // ============================================================
    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        Long userId = userIdOf(session);
        if (userId == null) {
            closeQuietly(session, CloseStatus.BAD_DATA);
            return;
        }
        onlineRegistry.register(userId, session);

        // 掉线重连：只有房间里记录的那条会话已经死了，才让新连接接管，
        // 避免"用户开着对局的标签页还在、又开了个新标签页把消息抢走"
        GameRoom room = roomOf(userId);
        if (room != null && room.rebindIfDead(userId, session)) {
            if (orphanedAt.remove(room.getId()) != null) {
                room.sendToPeer(userId, "{\"t\":\"peer-online\"}");
                log.info("[game-ws] user {} reconnected into room {}", userId, room.getId());
            }
        }
        log.info("[game-ws] user {} connected", userId);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        Long userId = userIdOf(session);
        if (userId == null) return;
        onlineRegistry.unregister(userId, session);

        // 同一账号还开着别的标签页：只摘掉这一条会话，房间和对局都不动。
        // 但如果被关掉的正是房间里记录的那条，要把房间改指到还活着的标签页上，
        // 否则之后所有转发都会发进一条已关闭的会话里，对方像断了线。
        if (onlineRegistry.isOnline(userId)) {
            GameRoom alive = roomOf(userId);
            if (alive != null) {
                WebSocketSession another = onlineRegistry.get(userId);
                if (another != null) alive.rebindIfDead(userId, another);
            }
            log.info("[game-ws] user {} closed one of several sessions ({})", userId, status);
            return;
        }

        GameRoom room = roomOf(userId);
        if (room != null) {
            // 不立刻拆房：先进入宽限期，让对手看到"对方掉线，等待重连…"
            orphanedAt.put(room.getId(), System.currentTimeMillis());
            room.sendToPeer(userId, "{\"t\":\"peer-offline\"}");
        }
        log.info("[game-ws] user {} disconnected ({})", userId, status);
    }

    // ============================================================
    // 消息分发
    // ============================================================
    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        Long userId = userIdOf(session);
        if (userId == null) return;
        JsonNode msg;
        try {
            msg = om.readTree(message.getPayload());
        } catch (Exception e) {
            send(session, error("消息格式不正确"));
            return;
        }
        String t = msg.path("t").asText("");
        try {
            sweep();   // 顺手清掉过期邀请 / 掉线超时的房间，实现很轻（房间数极少）
            switch (t) {
                case "invite":  onInvite(session, userId, msg); break;
                case "accept":  onAccept(session, userId, msg); break;
                case "decline": onDecline(userId, msg); break;
                case "cancel":  onCancel(userId, msg); break;
                case "leave":   onLeave(userId, msg); break;
                case "pos":
                case "gem":
                case "plate":
                case "dead":
                case "restart":
                    forward(userId, msg); break;
                default:
                    send(session, error("未知的消息类型"));
            }
        } catch (Exception e) {
            log.warn("[game-ws] handle '{}' failed: {}", t, e.getMessage());
            send(session, error("操作失败，请稍后再试"));
        }
    }

    // ============================================================
    // 邀请 / 接受 / 拒绝
    // ============================================================
    private void onInvite(WebSocketSession session, Long userId, JsonNode msg) {
        Long to = msg.hasNonNull("to") ? msg.get("to").asLong() : null;
        if (to == null || to.equals(userId)) {
            send(session, error("邀请对象不正确"));
            return;
        }
        if (!friendService.areFriends(userId, to)) {
            send(session, error("先加对方为好友才能邀请哦～"));
            return;
        }
        if (!onlineRegistry.isOnline(to)) {
            send(session, error("对方现在不在线，稍后再邀请吧～"));
            return;
        }

        // 自己已经在一局进行中的游戏里
        GameRoom mine = roomOf(userId);
        if (mine != null && mine.isFull()) {
            send(session, error("你正在联机中，先退出当前对局吧～"));
            return;
        }
        // 对方真在进行中的对局里（等接受的旧邀请不算"游戏中"）
        GameRoom target = roomOf(to);
        if (target != null && target.isFull()) {
            send(session, error("对方正在游戏中，等 TA 打完这一局～"));
            return;
        }

        // 双方的待接受房间都作废，重新开一间
        if (mine != null) destroyRoom(mine);
        if (target != null) destroyRoom(target);

        GameRoom room = new GameRoom(newRoomId(), userId, to, session);
        rooms.put(room.getId(), room);
        userRoom.put(userId, room.getId());
        userRoom.put(to, room.getId());

        send(session, om.createObjectNode()
                .put("t", "inviting")
                .put("room", room.getId())
                .set("to", profile(to)).toString());
        // 推给他所有标签页：哪个在前台哪个就能看到邀请
        onlineRegistry.pushAll(to, om.createObjectNode()
                .put("t", "invited")
                .put("room", room.getId())
                .set("from", profile(userId)).toString());
        log.info("[game-ws] user {} invited {} room={}", userId, to, room.getId());
    }

    private void onAccept(WebSocketSession session, Long userId, JsonNode msg) {
        String roomId = msg.path("room").asText("");
        GameRoom room = rooms.get(roomId);
        if (room == null) {
            userRoom.remove(userId, roomId);
            send(session, error("邀请已失效，让对方重新邀请一次吧"));
            return;
        }
        if (userId.equals(room.getHostId())) {
            send(session, error("不能接受自己的邀请"));
            return;
        }
        if (room.isAccepted()) {
            send(session, error("这条邀请已经被接受了"));
            return;
        }
        if (room.isExpired()) {
            destroyRoom(room);
            send(session, error("邀请已过期，让对方重新邀请一次吧"));
            return;
        }
        // 用户自己也挂着一条待接受的邀请（他同时在邀请别人）：先作废那条，再接管当前邀请
        if (!roomId.equals(userRoom.get(userId))) {
            GameRoom stale = roomOf(userId);
            if (stale != null && !stale.getId().equals(roomId) && !stale.isFull()) {
                stale.sendTo(stale.getHostId(), declinedNode(profile(userId)));
                destroyRoom(stale);
            }
            userRoom.put(userId, roomId);
        }

        room.accept(userId, session);
        userRoom.put(room.getHostId(), roomId);
        userRoom.put(userId, roomId);
        orphanedAt.remove(roomId);

        // 角色分配：家长扮演大人（冰娃），孩子扮演小孩（火娃）
        String hostRole = roleOf(room.getHostId());
        String guestRole = roleOf(userId);
        String hostChar = "parent".equals(hostRole) || !"parent".equals(guestRole) ? "adult" : "kid";
        String guestChar = "adult".equals(hostChar) ? "kid" : "adult";

        send(room.getHostSession(), startNode(room.getId(), hostChar, profile(userId)));
        send(session, startNode(room.getId(), guestChar, profile(room.getHostId())));
        log.info("[game-ws] room {} started: host={} guest={}", room.getId(), room.getHostId(), userId);
    }

    private void onDecline(Long userId, JsonNode msg) {
        String roomId = msg.path("room").asText("");
        GameRoom room = rooms.get(roomId);
        if (room == null) {
            userRoom.remove(userId, roomId);
            return;
        }
        // 只有被邀请的那个人可以拒绝
        if (!room.contains(userId) || userId.equals(room.getHostId()) || room.isAccepted()) {
            return;
        }
        room.sendTo(room.getHostId(), declinedNode(profile(userId)));
        destroyRoom(room);
        log.info("[game-ws] user {} declined room {}", userId, roomId);
    }

    private void onCancel(Long userId, JsonNode msg) {
        String roomId = msg.path("room").asText("");
        GameRoom room = rooms.get(roomId);
        if (room == null) return;
        if (!userId.equals(room.getHostId()) || room.isAccepted()) return;
        // 接受前 guestId 还是空的，用 inviteeId 定位对方（并发到他所有标签页）
        Long invitee = room.getInviteeId();
        if (invitee != null) onlineRegistry.pushAll(invitee, "{\"t\":\"cancelled\"}");
        destroyRoom(room);
    }

    private void onLeave(Long userId, JsonNode msg) {
        String roomId = msg.path("room").asText("");
        GameRoom room = rooms.get(roomId);
        if (room == null) {
            userRoom.remove(userId, roomId);
            return;
        }
        // 只有房间成员能退房
        if (!room.contains(userId)) return;
        room.sendToPeer(userId, "{\"t\":\"peer-left\"}");
        destroyRoom(room);
    }

    /** 游戏内消息：原样转发给房间里另一位玩家 */
    private void forward(Long userId, JsonNode msg) {
        GameRoom room = rooms.get(msg.path("room").asText(""));
        if (room == null || !room.isAccepted()) return;
        if (!room.contains(userId)) return;
        room.sendToPeer(userId, msg.toString());
    }

    // ============================================================
    // 清理
    // ============================================================
    /** 过期邀请 / 掉线超时的房间统一回收 */
    private void sweep() {
        if (rooms.isEmpty()) return;
        long now = System.currentTimeMillis();
        for (GameRoom room : rooms.values()) {
            if (room.isExpired()) {
                room.sendTo(room.getHostId(), "{\"t\":\"cancelled\"}");
                log.info("[game-ws] room {} expired (nobody accepted)", room.getId());
                destroyRoom(room);
                continue;
            }
            Long since = orphanedAt.get(room.getId());
            if (since != null && now - since > OFFLINE_GRACE_MS) {
                // 掉线方一直没回来：通知还活着的那位，然后回收
                Long alive = onlineRegistry.isOnline(room.getHostId())
                        ? room.getHostId()
                        : (onlineRegistry.isOnline(room.getGuestId()) ? room.getGuestId() : null);
                if (alive != null) room.sendToPeer(alive, "{\"t\":\"peer-left\"}");
                log.info("[game-ws] room {} dropped (peer stayed offline)", room.getId());
                destroyRoom(room);
            }
        }
    }

    private void destroyRoom(GameRoom room) {
        if (room == null) return;
        rooms.remove(room.getId(), room);
        orphanedAt.remove(room.getId());
        userRoom.remove(room.getHostId(), room.getId());
        if (room.getGuestId() != null) {
            userRoom.remove(room.getGuestId(), room.getId());
        } else {
            // 还没接受：把被邀请者那条映射也清掉
            userRoom.entrySet().removeIf(e -> e.getValue().equals(room.getId()));
        }
    }

    private GameRoom roomOf(Long userId) {
        if (userId == null) return null;
        String roomId = userRoom.get(userId);
        return roomId == null ? null : rooms.get(roomId);
    }

    private String newRoomId() {
        String chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        StringBuilder sb = new StringBuilder(6);
        for (int i = 0; i < 6; i++) {
            sb.append(chars.charAt(ThreadLocalRandom.current().nextInt(chars.length())));
        }
        return sb.toString();
    }

    /** 用户公开信息（邀请/开始对局时携带） */
    private ObjectNode profile(Long userId) {
        ObjectNode n = om.createObjectNode();
        n.put("id", userId);
        n.put("nickname", "");
        n.put("avatar", "");
        n.put("role", "");
        try {
            User u = userService.getById(userId);
            if (u != null) {
                n.put("nickname", u.getNickname() == null ? "" : u.getNickname());
                n.put("avatar", u.getAvatar() == null ? "" : u.getAvatar());
                n.put("role", u.getRole() == null ? "" : u.getRole());
            }
        } catch (Exception ignored) { }
        return n;
    }

    private String roleOf(Long userId) {
        try {
            User u = userService.getById(userId);
            return u != null ? u.getRole() : null;
        } catch (Exception e) {
            return null;
        }
    }

    private String startNode(String roomId, String character, ObjectNode peer) {
        return om.createObjectNode()
                .put("t", "start")
                .put("room", roomId)
                .put("char", character)
                .set("peer", peer).toString();
    }

    private String declinedNode(ObjectNode from) {
        return om.createObjectNode()
                .put("t", "declined")
                .set("from", from).toString();
    }

    private String error(String msg) {
        return om.createObjectNode().put("t", "error").put("msg", msg).toString();
    }

    private void send(WebSocketSession session, String payload) {
        try {
            if (session != null && session.isOpen()) {
                synchronized (session) {
                    session.sendMessage(new TextMessage(payload));
                }
            }
        } catch (Exception ignored) { }
    }

    private void closeQuietly(WebSocketSession session, CloseStatus status) {
        try { session.close(status); } catch (Exception ignored) { }
    }

    // ============================================================
    // 连接参数解析：/ws/game?userId=1
    // ============================================================
    private Long userIdOf(WebSocketSession session) {
        URI uri = session.getUri();
        if (uri == null) return null;
        try {
            Map<String, String> params = UriComponentsBuilder.fromUri(uri).build()
                    .getQueryParams().toSingleValueMap();
            String id = params.get("userId");
            return id == null ? null : Long.parseLong(id);
        } catch (Exception e) {
            return null;
        }
    }
}
