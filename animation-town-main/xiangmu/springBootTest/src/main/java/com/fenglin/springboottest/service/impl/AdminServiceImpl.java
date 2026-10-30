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

    /**
     * 唯一可进入后台管理系统的账号。
     * 需求：只有「朵朵」能进后台，且登录时不需要输入密码；其他任何账号一律拒绝。
     */
    public static final String SUPER_ADMIN_USERNAME = "朵朵";
    /** 后台账号展示名 */
    public static final String SUPER_ADMIN_NICKNAME = "朵朵";

    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @Override
    public Admin login(AdminLoginRequest request) {
        // 1. 基础校验（免密登录，只校验账号）
        if (request == null || request.getUsername() == null || request.getUsername().trim().isEmpty()) {
            throw new IllegalArgumentException("请输入后台管理账号");
        }
        String username = request.getUsername().trim();

        // 2. 白名单校验：仅「朵朵」可进入后台，其余账号（含预置 admin）一律拒绝
        if (!SUPER_ADMIN_USERNAME.equals(username)
                && !"duoduo".equalsIgnoreCase(username)) {
            throw new IllegalArgumentException("该账号没有后台管理权限，仅「朵朵」可进入后台管理系统");
        }

        // 3. 免密登录：「朵朵」无需密码，账号不存在时自动兜底创建
        Admin admin = this.lambdaQuery()
                .eq(Admin::getUsername, SUPER_ADMIN_USERNAME)
                .one();
        if (admin == null) {
            admin = new Admin();
            admin.setUsername(SUPER_ADMIN_USERNAME);
            // 免密登录不比对密码，这里仅存一个 BCrypt 占位值，避免字段为空
            admin.setPassword(passwordEncoder.encode(SUPER_ADMIN_USERNAME));
            admin.setNickname(SUPER_ADMIN_NICKNAME);
            this.save(admin);
        }

        // 4. 脱敏返回
        admin.setPassword(null);
        return admin;
    }
}
