package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.fenglin.springboottest.entity.Favorite;

import java.util.List;

/**
 * 用户收藏业务接口
 */
public interface FavoriteService extends IService<Favorite> {

    /**
     * 某用户已收藏的动画 id 列表
     */
    List<Long> favoriteIds(Long userId);

    /**
     * 收藏（幂等：已收藏则直接返回成功）
     * @return 是否已处于收藏状态
     */
    boolean favorite(Long userId, Long animationId);

    /**
     * 取消收藏
     * @return 是否发生了取消操作
     */
    boolean unfavorite(Long userId, Long animationId);
}
