package com.fenglin.springboottest.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/**
 * MyBatis-Plus 配置：
 *   1. 注册 BCrypt 密码加密器 Bean
 *   2. Mapper 接口通过 @Mapper 注解扫描（见 UserMapper）
 *
 * 说明：MyBatis-Plus 3.5.x 已将 @MapperScan 从注解包移除，
 *       分页插件在注册/登录场景非必需，故此处保持精简。
 */
@Configuration
public class MybatisPlusConfig {

    /** 密码加密器（BCrypt） */
    @Bean
    public BCryptPasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
