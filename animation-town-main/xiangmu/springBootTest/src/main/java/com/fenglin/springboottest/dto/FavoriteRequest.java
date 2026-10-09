package com.fenglin.springboottest.dto;

import lombok.Data;

/**
 * 收藏 / 取消收藏请求体
 */
@Data
public class FavoriteRequest {

    /** 用户 id */
    private Long userId;

    /** 动画 id */
    private Long animationId;
}
