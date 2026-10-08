package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.dto.LoginRequest;
import com.fenglin.springboottest.dto.RegisterRequest;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * 注册接口（REST）
 * 路径前缀 /api/user，与前端 vite 代理 /api -> :8081 对应
 */
@RestController
@RequestMapping("/api/user")
@CrossOrigin(origins = "*")
public class RegisterController {

    @Autowired
    private UserService userService;

    /**
     * 注册
     * POST /api/user/register
     */
    @PostMapping("/register")
    public Result<User> register(@RequestBody RegisterRequest request) {
        try {
            User user = userService.register(request);
            return Result.ok("角色创建成功！欢迎来到动画小镇 🎉", user);
        } catch (IllegalStateException e) {
            // 昵称重复等可预期业务异常
            return Result.fail(e.getMessage());
        } catch (IllegalArgumentException e) {
            // 参数校验失败
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 校验昵称是否可用（前端可实时调用）
     * GET /api/user/check?nickname=xxx
     */
    @GetMapping("/check")
    public Result<Boolean> checkNickname(@RequestParam String nickname) {
        boolean available = !userService.nicknameExists(nickname);
        return Result.ok("ok", available);
    }

    /**
     * 登录
     * POST /api/user/login
     */
    @PostMapping("/login")
    public Result<User> login(@RequestBody LoginRequest request) {
        try {
            User user = userService.login(request);
            return Result.ok("登入成功！正在打开动画小镇… 🎉", user);
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        }
    }
}
