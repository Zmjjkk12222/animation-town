package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.fenglin.springboottest.dto.LoginRequest;
import com.fenglin.springboottest.dto.RegisterRequest;
import com.fenglin.springboottest.entity.User;

/**
 * 用户业务接口
 */
public interface UserService extends IService<User> {

    /**
     * 昵称是否已被占用
     */
    boolean nicknameExists(String nickname);

    /**
     * 执行注册：校验昵称唯一性 -> 加密密码 -> 落库
     * @return 已保存的用户（密码已脱敏）
     */
    User register(RegisterRequest request);

    /**
     * 登录校验：根据昵称查找用户，并用 BCrypt 比对密码
     * @return 校验通过的用户
     * @throws IllegalArgumentException 昵称不存在或密码错误
     */
    User login(LoginRequest request);
}
