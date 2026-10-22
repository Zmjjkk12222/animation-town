package com.fenglin.springboottest.dto;

import lombok.Data;

/**
 * 注册请求体，与前端 RegisterPage.vue 提交字段对应
 */
@Data
public class RegisterRequest {

    /** 昵称（对应前端 user 字段） */
    private String nickname;

    /** 角色：kid / parent（对应前端 mode 字段） */
    private String role;

    /** 头像 emoji（对应前端 avatar 字段） */
    private String avatar;

    /** 家长手机号（对应前端 phone 字段，小朋友可空） */
    private String phone;

    /** 密码明文（对应前端 pwd 字段） */
    private String password;
}
