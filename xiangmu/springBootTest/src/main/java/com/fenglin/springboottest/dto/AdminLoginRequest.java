package com.fenglin.springboottest.dto;

import lombok.Data;

/**
 * 后台管理员登录请求体
 */
@Data
public class AdminLoginRequest {

    /** 管理员账号 */
    private String username;

    /** 明文密码（登录后由 BCrypt 比对，不落库） */
    private String password;
}
