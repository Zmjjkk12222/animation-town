package com.fenglin.springboottest.common;

import lombok.Data;

/**
 * 统一接口返回结构
 *   code    : 200 成功，其余为业务失败码
 *   message : 提示信息（前端直接 toast 展示）
 *   data    : 业务数据
 */
@Data
public class Result<T> {

    private int code;
    private String message;
    private T data;

    public static <T> Result<T> ok(T data) {
        return ok("操作成功", data);
    }

    public static <T> Result<T> ok(String message, T data) {
        Result<T> r = new Result<>();
        r.setCode(200);
        r.setMessage(message);
        r.setData(data);
        return r;
    }

    public static <T> Result<T> fail(String message) {
        Result<T> r = new Result<>();
        r.setCode(400);
        r.setMessage(message);
        return r;
    }
}
