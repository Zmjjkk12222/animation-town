package com.fenglin.springboottest.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.dto.AdminLoginRequest;
import com.fenglin.springboottest.entity.Admin;
import com.fenglin.springboottest.mapper.AdminMapper;
import com.fenglin.springboottest.service.AdminService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * 后台管理员业务实现
 */
@Service
public class AdminServiceImpl extends ServiceImpl<AdminMapper, Admin> implements AdminService {

    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @Override
    public Admin login(AdminLoginRequest request) {
        // 1. 基础校验
        if (request.getUsername() == null || request.getUsername().trim().isEmpty()
                || request.getPassword() == null || request.getPassword().isEmpty()) {
            throw new IllegalArgumentException("请输入管理员账号和密码");
        }

        // 2. 按账号查找
        Admin admin = this.lambdaQuery()
                .eq(Admin::getUsername, request.getUsername().trim())
                .one();
        if (admin == null) {
            throw new IllegalArgumentException("管理员账号不存在");
        }

        // 3. BCrypt 比对密码
        if (!passwordEncoder.matches(request.getPassword(), admin.getPassword())) {
            throw new IllegalArgumentException("密码不正确");
        }

        // 4. 脱敏返回
        admin.setPassword(null);
        return admin;
    }
}
