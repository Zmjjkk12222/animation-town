package com.fenglin.springboottest.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.entity.Favorite;
import com.fenglin.springboottest.mapper.FavoriteMapper;
import com.fenglin.springboottest.service.FavoriteService;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 用户收藏业务实现
 */
@Service
public class FavoriteServiceImpl extends ServiceImpl<FavoriteMapper, Favorite> implements FavoriteService {

    @Override
    public List<Long> favoriteIds(Long userId) {
        return this.lambdaQuery()
                .select(Favorite::getAnimationId)
                .eq(Favorite::getUserId, userId)
                .list()
                .stream()
                .map(Favorite::getAnimationId)
                .collect(Collectors.toList());
    }

    @Override
    public boolean favorite(Long userId, Long animationId) {
        checkArgs(userId, animationId);
        // 幂等：已收藏则直接返回
        boolean exists = this.lambdaQuery()
                .eq(Favorite::getUserId, userId)
                .eq(Favorite::getAnimationId, animationId)
                .count() > 0;
        if (exists) {
            return true;
        }
        Favorite favorite = new Favorite();
        favorite.setUserId(userId);
        favorite.setAnimationId(animationId);
        return this.save(favorite);
    }

    @Override
    public boolean unfavorite(Long userId, Long animationId) {
        checkArgs(userId, animationId);
        // 逻辑删除（实体带 @TableLogic，自动更新 deleted=1）
        return this.lambdaUpdate()
                .eq(Favorite::getUserId, userId)
                .eq(Favorite::getAnimationId, animationId)
                .remove();
    }

    private void checkArgs(Long userId, Long animationId) {
        if (userId == null || animationId == null) {
            throw new IllegalArgumentException("用户或动画参数不完整");
        }
    }
}
