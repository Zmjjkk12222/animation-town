package com.fenglin.springboottest.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.dto.LoginRequest;
import com.fenglin.springboottest.dto.RegisterRequest;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.mapper.UserMapper;
import com.fenglin.springboottest.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * 用户业务实现
 */
@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {

    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @Override
    public boolean nicknameExists(String nickname) {
        return this.lambdaQuery()
                .eq(User::getNickname, nickname)
                .count() > 0;
    }

    @Override
    public User register(RegisterRequest request) {
        // 1. 基础校验（前端已校验，后端兜底）
        if (request.getNickname() == null || request.getNickname().trim().isEmpty()) {
            throw new IllegalArgumentException("昵称不能为空");
        }
        if (request.getPassword() == null || request.getPassword().length() < 6) {
            throw new IllegalArgumentException("密码至少 6 位");
        }
        if (nicknameExists(request.getNickname())) {
            throw new IllegalStateException("昵称已被占用");
        }

        // 2. 组装实体并加密密码
        User user = new User();
        user.setNickname(request.getNickname().trim());
        user.setRole(request.getRole() == null ? "kid" : request.getRole());
        user.setAvatar(request.getAvatar() == null ? "" : request.getAvatar());
        user.setPhone(request.getPhone() == null ? "" : request.getPhone());
        user.setPassword(passwordEncoder.encode(request.getPassword()));

        // 3. 落库
        this.save(user);

        // 4. 脱敏返回（不带回加密密码）
        user.setPassword(null);
        return user;
    }

    @Override
    public User login(LoginRequest request) {
        // 1. 基础校验
        if (request.getNickname() == null || request.getNickname().trim().isEmpty()
                || request.getPassword() == null || request.getPassword().isEmpty()) {
            throw new IllegalArgumentException("昵称和密码都要填哦～ 🥺");
        }

        // 2. 按昵称查找用户
        User user = this.lambdaQuery()
                .eq(User::getNickname, request.getNickname().trim())
                .one();
        if (user == null) {
            throw new IllegalArgumentException("这个昵称还没有注册呢，先去加入小镇吧～ 🌟");
        }

        // 3. BCrypt 比对密码
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException("密码不对哦，再试一次～ 🔐");
        }

        // 4. 脱敏返回
        user.setPassword(null);
        return user;
    }
}
