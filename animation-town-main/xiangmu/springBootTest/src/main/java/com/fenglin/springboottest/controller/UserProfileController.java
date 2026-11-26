package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.config.WebMvcConfig;
import com.fenglin.springboottest.dto.ChangePasswordRequest;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

/**
 * 用户个人中心接口（头像上传、修改密码）
 * 路径前缀 /api/user，与前端 vite 代理 /api -> :8081 对应
 */
@RestController
@RequestMapping("/api/user")
@CrossOrigin(origins = "*")
public class UserProfileController {

    @Autowired
    private UserService userService;

    /** 允许的图片格式（按扩展名） */
    private static final Set<String> ALLOWED_EXT = new HashSet<>(Arrays.asList("jpg", "jpeg", "png", "gif", "webp"));

    /** 单张头像大小上限：2MB */
    private static final long MAX_SIZE = 2L * 1024 * 1024;

    /**
     * 上传并更新头像
     * POST /api/user/avatar  (multipart/form-data: file + userId)
     * @return 更新后的用户（脱敏），含 avatarUrl
     */
    @PostMapping("/avatar")
    public Result<User> uploadAvatar(@RequestParam("file") MultipartFile file,
                                     @RequestParam("userId") Long userId) {
        // 1. 基础校验
        if (userId == null) {
            return Result.fail("用户参数不完整");
        }
        if (file == null || file.isEmpty()) {
            return Result.fail("请先选择一张图片哦～");
        }
        // 2. 大小校验
        if (file.getSize() > MAX_SIZE) {
            return Result.fail("图片太大啦，请选择 2MB 以内的图片～");
        }
        // 3. 格式校验（按扩展名 + 内容类型兜底）
        String original = file.getOriginalFilename();
        String ext = "";
        if (original != null && original.contains(".")) {
            ext = original.substring(original.lastIndexOf('.') + 1).toLowerCase();
        }
        if (!ALLOWED_EXT.contains(ext)) {
            return Result.fail("只支持 jpg / png / gif / webp 格式的图片～");
        }

        // 4. 落盘：uploads/avatar/{userId}_{uuid}.{ext}
        try {
            String filename = userId + "_" + UUID.randomUUID().toString().replace("-", "") + "." + ext;
            Path dir = Paths.get(WebMvcConfig.UPLOAD_DIR, "avatar");
            Files.createDirectories(dir);
            Path target = dir.resolve(filename);
            Files.write(target, file.getBytes());

            // 5. 落库：保存相对访问路径
            String avatarUrl = "/uploads/avatar/" + filename;
            userService.updateAvatar(userId, avatarUrl);

            // 6. 返回更新后的用户（脱敏）
            User user = userService.getById(userId);
            if (user != null) user.setPassword(null);
            return Result.ok("头像更新成功～ 🎉", user);
        } catch (IOException e) {
            e.printStackTrace();
            return Result.fail("头像保存失败，请稍后再试～");
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 修改密码
     * POST /api/user/password
     */
    @PostMapping("/password")
    public Result<Void> changePassword(@RequestBody ChangePasswordRequest request) {
        try {
            userService.changePassword(request.getUserId(), request.getOldPassword(), request.getNewPassword());
            return Result.ok("密码修改成功，下次登录请用新密码～ 🔐", null);
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        }
    }
}
