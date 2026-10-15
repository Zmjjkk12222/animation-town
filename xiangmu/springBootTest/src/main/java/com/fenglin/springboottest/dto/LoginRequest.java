package com.fenglin.springboottest.dto;

import lombok.Data;

/**
 * 登录请求体，与前端 LoginPage.vue 提交字段对应
 */
@Data
public class LoginRequest {

    /** 昵称（对应前端 user 字段） */
    private String nickname;

    /** 密码明文（对应前端 pwd 字段） */
    private String password;
}
