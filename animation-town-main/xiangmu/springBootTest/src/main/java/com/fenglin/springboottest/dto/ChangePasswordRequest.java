package com.fenglin.springboottest.dto;

import lombok.Data;

/**
 * 修改密码请求体，与前端 UserProfile.vue 提交字段对应
 */
@Data
public class ChangePasswordRequest {

    /** 用户 id（当前登录用户） */
    private Long userId;

    /** 旧密码明文 */
    private String oldPassword;

    /** 新密码明文 */
    private String newPassword;
}
