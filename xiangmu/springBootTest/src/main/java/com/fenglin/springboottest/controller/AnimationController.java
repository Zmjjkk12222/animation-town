package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.dto.FavoriteRequest;
import com.fenglin.springboottest.entity.Animation;
import com.fenglin.springboottest.service.AnimationService;
import com.fenglin.springboottest.service.FavoriteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Collections;
import java.util.List;

/**
 * 动画内容接口（REST）
 * 路径前缀 /api/animation，与前端 vite 代理 /api -> :8081 对应
 */
@RestController
@RequestMapping("/api/animation")
@CrossOrigin(origins = "*")
public class AnimationController {

    @Autowired
    private AnimationService animationService;

    @Autowired
    private FavoriteService favoriteService;

    /**
     * 今日推荐（按热度倒序）
     * GET /api/animation/recommend?limit=6
     */
    @GetMapping("/recommend")
    public Result<List<Animation>> recommend(@RequestParam(defaultValue = "6") int limit) {
        return Result.ok("ok", animationService.recommend(limit));
    }

    /**
     * 我的收藏
     * GET /api/animation/favorites/{userId}
     */
    @GetMapping("/favorites/{userId}")
    public Result<List<Animation>> favorites(@PathVariable Long userId) {
        List<Long> ids = favoriteService.favoriteIds(userId);
        if (ids == null || ids.isEmpty()) {
            return Result.ok("ok", Collections.emptyList());
        }
        return Result.ok("ok", animationService.listByIds(ids));
    }

    /**
     * 收藏
     * POST /api/animation/favorite
     */
    @PostMapping("/favorite")
    public Result<Boolean> favorite(@RequestBody FavoriteRequest request) {
        try {
            return Result.ok("收藏成功 ❤️", favoriteService.favorite(request.getUserId(), request.getAnimationId()));
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 取消收藏
     * POST /api/animation/unfavorite
     */
    @PostMapping("/unfavorite")
    public Result<Boolean> unfavorite(@RequestBody FavoriteRequest request) {
        try {
            return Result.ok("已取消收藏", favoriteService.unfavorite(request.getUserId(), request.getAnimationId()));
        } catch (IllegalArgumentException e) {
            return Result.fail(e.getMessage());
        }
    }
}
