package com.fenglin.springboottest.common;

import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 后台管理系统的轻量登录态存储。
 *
 * 说明：
 *   管理员登录后服务端生成一个 token（UUID），保存在内存 Map 中，
 *   后续管理类接口需在请求头 X-Admin-Token 带上该 token 才会被处理。
 *   这是为后台管理加的一层基础保护，避免管理接口被匿名直接调用。
 *   仅保存在内存中，服务重启后登录态失效（需要重新登录），符合后台管理的使用习惯。
 */
@Component
public class AdminTokenStore {

    /** token -> 管理员 id */
    private final Map<String, Long> tokens = new ConcurrentHashMap<>();

    /** 生成一个新 token 并绑定管理员 */
    public String create(Long adminId) {
        String token = UUID.randomUUID().toString().replace("-", "");
        tokens.put(token, adminId);
        return token;
    }

    /** 判断 token 是否有效 */
    public boolean valid(String token) {
        return token != null && tokens.containsKey(token);
    }

    /** 取出 token 对应的管理员 id */
    public Long adminId(String token) {
        return token == null ? null : tokens.get(token);
    }

    /** 退出登录时移除 */
    public void remove(String token) {
        if (token != null) {
            tokens.remove(token);
        }
    }
}
