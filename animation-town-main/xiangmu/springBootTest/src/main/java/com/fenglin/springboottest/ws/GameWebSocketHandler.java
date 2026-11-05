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
 *     invited / inviting / start / declined / cancelled / peer-left / error
 */
@Component
public class GameWebSocketHandler extends TextWebSocketHandler {

    private static final Logger log = LoggerFactory.getLogger(GameWebSocketHandler.class);

    private final OnlineRegistry onlineRegistry;
    private final FriendService friendService;
    private final UserService userService;
    private final ObjectMapper om = new ObjectMapper();

    /** roomId -> 房间 */
    private final ConcurrentHashMap<String, GameRoom> rooms = new ConcurrentHashMap<>();
    /** userId -> 当前所在 roomId */
    private final ConcurrentHashMap<Long, String> userRoom = new ConcurrentHashMap<>();

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
        log.info("[game-ws] user {} connected", userId);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        Long userId = userIdOf(session);
        if (userId == null) return;
        onlineRegistry.unregister(userId, session);
        String roomId = userRoom.remove(userId);
        if (roomId != null) {
            GameRoom room = rooms.get(roomId);
            if (room != null) {
                room.sendToPeer(userId, "{\"t\":\"peer-left\"}");
                destroyRoom(room);
            }
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
        WebSocketSession peer = onlineRegistry.get(to);
        if (!onlineRegistry.isOnline(to) || peer == null) {
            send(session, error("对方现在不在线，稍后再邀请吧～"));
            return;
        }
        if (userRoom.containsKey(to)) {
            send(session, error("对方正在游戏中，等 TA 打完这一局～"));
            return;
        }
        // 已发出的旧邀请作废
        String oldRoom = userRoom.remove(userId);
        if (oldRoom != null) destroyRoom(rooms.remove(oldRoom));

        GameRoom room = new GameRoom(newRoomId(), userId, session);
        rooms.put(room.getId(), room);
        userRoom.put(userId, room.getId());
        userRoom.put(to, room.getId());

        send(session, om.createObjectNode()
                .put("t", "inviting")
                .put("room", room.getId())
                .set("to", profile(to)).toString());
        send(peer, om.createObjectNode()
                .put("t", "invited")
                .put("room", room.getId())
                .set("from", profile(userId)).toString());
    }

    private void onAccept(WebSocketSession session, Long userId, JsonNode msg) {
        String roomId = msg.path("room").asText("");
        GameRoom room = rooms.get(roomId);
        if (room == null || room.isAccepted() || userId.equals(room.getHostId())
                || !roomId.equals(userRoom.get(userId))) {
            send(session, error("邀请已失效"));
            return;
        }
        room.accept(userId, session);

        // 角色分配：家长扮演大人，其余由发起者扮演大人
        String hostRole = roleOf(room.getHostId());
        String guestRole = roleOf(userId);
        String hostChar = "parent".equals(hostRole) || !"parent".equals(guestRole) ? "adult" : "kid";
        String guestChar = "adult".equals(hostChar) ? "kid" : "adult";

        send(room.getHostSession(), startNode(room.getId(), hostChar, profile(userId)));
        send(session, startNode(room.getId(), guestChar, profile(room.getHostId())));
    }

    private void onDecline(Long userId, JsonNode msg) {
        String roomId = msg.path("room").asText("");
        GameRoom room = rooms.get(roomId);
        if (room == null) return;
        room.sendTo(room.getHostId(), declinedNode(profile(userId)));
        destroyRoom(room);
    }

    private void onCancel(Long userId, JsonNode msg) {
        String roomId = msg.path("room").asText("");
        GameRoom room = rooms.get(roomId);
        if (room == null || !userId.equals(room.getHostId()) || room.isAccepted()) return;
        // 通知被邀请者：邀请已取消（guestId 在接受前为空，从 userRoom 反查）
        userRoom.forEach((uid, rid) -> {
            if (rid.equals(roomId) && !uid.equals(userId)) {
                WebSocketSession s = onlineRegistry.get(uid);
                send(s, "{\"t\":\"cancelled\"}");
            }
        });
        destroyRoom(room);
    }

    private void onLeave(Long userId, JsonNode msg) {
        String roomId = msg.path("room").asText("");
        GameRoom room = rooms.get(roomId);
        if (room == null) return;
        room.sendToPeer(userId, "{\"t\":\"peer-left\"}");
        destroyRoom(room);
    }

    /** 游戏内消息：原样转发给房间里另一位玩家 */
    private void forward(Long userId, JsonNode msg) {
        GameRoom room = rooms.get(msg.path("room").asText(""));
        if (room == null || !room.isAccepted()) return;
        if (!userId.equals(room.getHostId()) && !userId.equals(room.getGuestId())) return;
        room.sendToPeer(userId, msg.toString());
    }

    // ============================================================
    // 工具
    // ============================================================
    private void destroyRoom(GameRoom room) {
        if (room == null) return;
        rooms.remove(room.getId());
        userRoom.remove(room.getHostId(), room.getId());
        if (room.getGuestId() != null) {
            userRoom.remove(room.getGuestId(), room.getId());
        } else {
            // 还没接受：从 userRoom 里找到被邀请者清掉
            userRoom.entrySet().removeIf(e -> e.getValue().equals(room.getId()));
        }
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
