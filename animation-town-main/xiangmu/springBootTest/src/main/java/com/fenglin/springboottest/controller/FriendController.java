package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.dto.FriendRequest;
import com.fenglin.springboottest.dto.FriendVO;
import com.fenglin.springboottest.service.FriendService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 好友接口（REST）
 * 路径前缀 /api/friend，与前端 vite 代理 /api -> :8081 对应
 */
@RestController
@RequestMapping("/api/friend")
@CrossOrigin(origins = "*")
public class FriendController {

    @Autowired
    private FriendService friendService;

    /**
     * 我的好友列表（带在线状态）
     * GET /api/friend/list/{userId}
     */
    @GetMapping("/list/{userId}")
    public Result<List<FriendVO>> list(@PathVariable Long userId) {
        return Result.ok("ok", friendService.listFriends(userId));
    }

    /**
     * 按昵称搜索可添加的用户
     * GET /api/friend/search?userId=&keyword=
     */
    @GetMapping("/search")
    public Result<List<FriendVO>> search(@RequestParam Long userId, @RequestParam(defaultValue = "") String keyword) {
        return Result.ok("ok", friendService.searchUsers(userId, keyword));
    }

    /**
     * 添加好友（双向，幂等）
     * POST /api/friend/add {userId, friendId}
     */
    @PostMapping("/add")
    public Result<Boolean> add(@RequestBody FriendRequest request) {
        try {
            friendService.addFriend(request.getUserId(), request.getFriendId());
            return Result.ok("添加成功，你们现在是好朋友啦 🤝", true);
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 删除好友（双向）
     * POST /api/friend/remove {userId, friendId}
     */
    @PostMapping("/remove")
    public Result<Boolean> remove(@RequestBody FriendRequest request) {
        try {
            friendService.removeFriend(request.getUserId(), request.getFriendId());
            return Result.ok("已删除好友", true);
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        }
    }
}
