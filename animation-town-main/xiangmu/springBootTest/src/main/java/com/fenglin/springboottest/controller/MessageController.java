package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.dto.ChatMessageVO;
import com.fenglin.springboottest.dto.ChatSendRequest;
import com.fenglin.springboottest.service.MessageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 好友聊天接口（REST）
 * 路径前缀 /api/message。实时推送走 WebSocket（见 MessageServiceImpl#push），
 * 这里的接口负责：发送落库、历史记录、未读数、标记已读。
 */
@RestController
@RequestMapping("/api/message")
public class MessageController {

    @Autowired
    private MessageService messageService;

    /**
     * 发送消息
     * POST /api/message/send {fromId, toId, content}
     */
    @PostMapping("/send")
    public Result<ChatMessageVO> send(@RequestBody ChatSendRequest request) {
        try {
            ChatMessageVO vo = messageService.send(request.getFromId(), request.getToId(), request.getContent());
            return Result.ok("已发送", vo);
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 与某位好友的历史消息（升序），同时把对方发来的未读标记为已读
     * GET /api/message/history?userId=&friendId=&beforeId=&limit=30
     */
    @GetMapping("/history")
    public Result<List<ChatMessageVO>> history(@RequestParam Long userId,
                                               @RequestParam Long friendId,
                                               @RequestParam(required = false) Long beforeId,
                                               @RequestParam(defaultValue = "30") int limit) {
        try {
            return Result.ok("ok", messageService.history(userId, friendId, beforeId, limit));
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 每个好友的未读条数（好友列表红点用）
     * GET /api/message/unread?userId=
     */
    @GetMapping("/unread")
    public Result<Map<Long, Integer>> unread(@RequestParam Long userId) {
        return Result.ok("ok", messageService.unreadCounts(userId));
    }

    /**
     * 把某位好友发来的消息标记为已读
     * POST /api/message/read?userId=&friendId=
     */
    @PostMapping("/read")
    public Result<Boolean> read(@RequestParam Long userId, @RequestParam Long friendId) {
        return Result.ok("ok", messageService.markRead(userId, friendId));
    }
}
