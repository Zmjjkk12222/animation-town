package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.fenglin.springboottest.dto.AdminLoginRequest;
import com.fenglin.springboottest.entity.Admin;

/**
 * 后台管理员业务接口
 */
public interface AdminService extends IService<Admin> {

    /**
     * 管理员登录：按账号查找，并用 BCrypt 比对密码
     * @return 校验通过的管理员（密码已脱敏）
     * @throws IllegalArgumentException 账号不存在或密码错误
     */
    Admin login(AdminLoginRequest request);
}
