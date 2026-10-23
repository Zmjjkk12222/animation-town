package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.AdminTokenStore;
import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.dto.AdminLoginRequest;
import com.fenglin.springboottest.entity.Animation;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.mapper.AnimationMapper;
import com.fenglin.springboottest.mapper.UserMapper;
import com.fenglin.springboottest.service.AdminService;
import com.fenglin.springboottest.service.AnimationService;
import com.fenglin.springboottest.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 后台管理系统接口
 * 路径前缀 /api/admin，与前端 vite 代理 /api -> :8081 对应
 *
 * 除登录接口外，其余接口都需要在请求头带上 X-Admin-Token，
 * 否则返回 401 由前端跳回登录页。
 */
@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
public class AdminController {

    /** 登录态请求头 */
    private static final String TOKEN_HEADER = "X-Admin-Token";

    @Autowired
    private AdminService adminService;

    @Autowired
    private AnimationService animationService;

    @Autowired
    private UserService userService;

    @Autowired
    private AnimationMapper animationMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private AdminTokenStore tokenStore;

    // ============================================================
    // 登录 / 退出
    // ============================================================

    /**
     * 管理员登录（仅登录，不提供注册）
     * POST /api/admin/login
     */
    @PostMapping("/login")
    public Result<Map<String, Object>> login(@RequestBody AdminLoginRequest request) {
        try {
            if (request == null) {
                return Result.fail("请输入管理员账号和密码");
            }
            com.fenglin.springboottest.entity.Admin admin = adminService.login(request);
            String token = tokenStore.create(admin.getId());

            Map<String, Object> adminVo = new HashMap<>();
            adminVo.put("id", admin.getId());
            adminVo.put("username", admin.getUsername());
            adminVo.put("nickname", admin.getNickname());

            Map<String, Object> data = new HashMap<>();
            data.put("token", token);
            data.put("admin", adminVo);
            return Result.ok("登录成功，欢迎回来～", data);
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 退出登录
     * POST /api/admin/logout
     */
    @PostMapping("/logout")
    public Result<Boolean> logout(@RequestHeader(value = TOKEN_HEADER, required = false) String token) {
        tokenStore.remove(token);
        return Result.ok("已退出登录", true);
    }

    // ============================================================
    // 动画数据管理（对应首页展示的动画内容）
    // ============================================================

    /**
     * 动画列表（按热度倒序）
     * GET /api/admin/animations
     */
    @GetMapping("/animations")
    public Result<List<Animation>> listAnimations(@RequestHeader(value = TOKEN_HEADER, required = false) String token) {
        if (!tokenStore.valid(token)) {
            return Result.fail(401, "登录已失效，请重新登录");
        }
        List<Animation> list = animationService.lambdaQuery()
                .orderByDesc(Animation::getHot)
                .orderByDesc(Animation::getId)
                .list();
        return Result.ok("ok", list);
    }

    /**
     * 新增动画
     * POST /api/admin/animation
     */
    @PostMapping("/animation")
    public Result<Animation> createAnimation(
            @RequestHeader(value = TOKEN_HEADER, required = false) String token,
            @RequestBody Animation animation) {
        if (!tokenStore.valid(token)) {
            return Result.fail(401, "登录已失效，请重新登录");
        }
        try {
            validateAnimation(animation);
            animation.setId(null);
            animationService.save(animation);
            return Result.ok("新增成功", animation);
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 修改动画
     * PUT /api/admin/animation
     */
    @PutMapping("/animation")
    public Result<Boolean> updateAnimation(
            @RequestHeader(value = TOKEN_HEADER, required = false) String token,
            @RequestBody Animation animation) {
        if (!tokenStore.valid(token)) {
            return Result.fail(401, "登录已失效，请重新登录");
        }
        try {
            if (animation == null || animation.getId() == null) {
                throw new IllegalArgumentException("缺少动画 ID");
            }
            validateAnimation(animation);
            animationService.updateById(animation);
            return Result.ok("保存成功", true);
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 删除动画（物理删除，真正从数据库移除该行）
     * DELETE /api/admin/animation/{id}
     */
    @DeleteMapping("/animation/{id}")
    public Result<Boolean> deleteAnimation(
            @RequestHeader(value = TOKEN_HEADER, required = false) String token,
            @PathVariable Long id) {
        if (!tokenStore.valid(token)) {
            return Result.fail(401, "登录已失效，请重新登录");
        }
        animationMapper.deletePhysically(id);
        return Result.ok("删除成功", true);
    }

    // ============================================================
    // 用户管理（前台注册的小朋友 / 家长账号）
    // ============================================================

    /**
     * 用户列表（按 ID 倒序）
     * GET /api/admin/users
     */
    @GetMapping("/users")
    public Result<List<User>> listUsers(@RequestHeader(value = TOKEN_HEADER, required = false) String token) {
        if (!tokenStore.valid(token)) {
            return Result.fail(401, "登录已失效，请重新登录");
        }
        List<User> list = userService.lambdaQuery()
                .orderByDesc(User::getId)
                .list();
        // 密码一律不下发到前端
        list.forEach(u -> u.setPassword(null));
        return Result.ok("ok", list);
    }

    /**
     * 修改用户（昵称 / 角色 / 头像 / 手机号）
     * PUT /api/admin/user
     */
    @PutMapping("/user")
    public Result<Boolean> updateUser(
            @RequestHeader(value = TOKEN_HEADER, required = false) String token,
            @RequestBody User user) {
        if (!tokenStore.valid(token)) {
            return Result.fail(401, "登录已失效，请重新登录");
        }
        try {
            if (user == null || user.getId() == null) {
                throw new IllegalArgumentException("缺少用户 ID");
            }
            if (user.getNickname() == null || user.getNickname().trim().isEmpty()) {
                throw new IllegalArgumentException("昵称不能为空");
            }
            // 后台不允许改密码，置空后 MyBatis-Plus 不会更新该字段
            user.setPassword(null);
            userService.updateById(user);
            return Result.ok("保存成功", true);
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 删除用户（物理删除，真正从数据库移除该行）
     * DELETE /api/admin/user/{id}
     */
    @DeleteMapping("/user/{id}")
    public Result<Boolean> deleteUser(
            @RequestHeader(value = TOKEN_HEADER, required = false) String token,
            @PathVariable Long id) {
        if (!tokenStore.valid(token)) {
            return Result.fail(401, "登录已失效，请重新登录");
        }
        userMapper.deletePhysically(id);
        return Result.ok("已删除该账号", true);
    }

    // ============================================================
    // 私有工具
    // ============================================================

    /** 动画字段校验 + 默认值兜底 */
    private void validateAnimation(Animation a) {
        if (a == null) {
            throw new IllegalArgumentException("动画内容不能为空");
        }
        if (a.getTitle() == null || a.getTitle().trim().isEmpty()) {
            throw new IllegalArgumentException("动画标题不能为空");
        }
        if (a.getCategory() == null || a.getCategory().trim().isEmpty()) {
            throw new IllegalArgumentException("分类不能为空");
        }
        if (a.getCover() == null || a.getCover().trim().isEmpty()) {
            a.setCover("🎬");
        }
        if (a.getHot() == null) {
            a.setHot(0);
        }
        if (a.getHot() < 0) {
            a.setHot(0);
        }
        if (a.getHot() > 100) {
            a.setHot(100);
        }
        if (a.getDescription() == null) {
            a.setDescription("");
        }
        if (a.getPlayUrl() == null) {
            a.setPlayUrl("");
        }
    }
}
