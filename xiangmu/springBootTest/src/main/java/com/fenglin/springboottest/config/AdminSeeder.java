package com.fenglin.springboottest.config;

import com.fenglin.springboottest.entity.Admin;
import com.fenglin.springboottest.service.AdminService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * 后台管理员账号初始化。
 *
 * 应用启动时检查是否已有默认管理员，没有则自动创建一个，
 * 密码使用 BCrypt 加密后落库（不在 SQL 里写死明文）。
 * 已存在则跳过，重复启动不会重复创建、也不会覆盖已有密码。
 */
@Slf4j
@Component
public class AdminSeeder implements CommandLineRunner {

    /** 预置管理员账号 */
    private static final String DEFAULT_USERNAME = "admin";
    /** 预置管理员密码 */
    private static final String DEFAULT_PASSWORD = "admin123";

    @Autowired
    private AdminService adminService;

    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        try {
            long exists = adminService.lambdaQuery()
                    .eq(Admin::getUsername, DEFAULT_USERNAME)
                    .count();
            if (exists > 0) {
                return;
            }
            Admin admin = new Admin();
            admin.setUsername(DEFAULT_USERNAME);
            admin.setPassword(passwordEncoder.encode(DEFAULT_PASSWORD));
            admin.setNickname("小镇管理员");
            adminService.save(admin);
            log.info("已初始化默认管理员账号：{} / {}", DEFAULT_USERNAME, DEFAULT_PASSWORD);
        } catch (Exception e) {
            // 表不存在等异常不影响主流程启动，仅记录告警
            log.warn("初始化管理员账号失败：{}", e.getMessage());
        }
    }
}
