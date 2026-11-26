package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.dto.FriendApplyRequest;
import com.fenglin.springboottest.dto.FriendRequest;
import com.fenglin.springboottest.dto.FriendRequestVO;
import com.fenglin.springboottest.dto.FriendVO;
import com.fenglin.springboottest.service.FriendService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 好友接口（REST）
 * 路径前缀 /api/friend，与前端 vite 代理 /api -> :8081 对应
 * 好友关系采用「申请审批制」：申请 -> 接受/拒绝 -> 成为好友。
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
     * 发起好友申请
     * POST /api/friend/apply {userId, friendId, remark}
     */
    @PostMapping("/apply")
    public Result<Boolean> apply(@RequestBody FriendApplyRequest request) {
        try {
            friendService.applyFriend(request.getUserId(), request.getFriendId(), request.getRemark());
            return Result.ok("好友申请已发出，等 TA 同意吧～", true);
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 我收到的待处理好友申请
     * GET /api/friend/pending/{userId}
     */
    @GetMapping("/pending/{userId}")
    public Result<List<FriendRequestVO>> pending(@PathVariable Long userId) {
        return Result.ok("ok", friendService.pendingRequests(userId));
    }

    /**
     * 接受好友申请
     * POST /api/friend/accept {userId, friendId(=requestId)}
     */
    @PostMapping("/accept")
    public Result<Boolean> accept(@RequestBody FriendRequest request) {
        try {
            friendService.acceptRequest(request.getUserId(), request.getFriendId());
            return Result.ok("已同意，你们现在是好朋友啦 🤝", true);
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 拒绝好友申请
     * POST /api/friend/decline {userId, friendId(=requestId)}
     */
    @PostMapping("/decline")
    public Result<Boolean> decline(@RequestBody FriendRequest request) {
        try {
            friendService.declineRequest(request.getUserId(), request.getFriendId());
            return Result.ok("已拒绝", true);
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
