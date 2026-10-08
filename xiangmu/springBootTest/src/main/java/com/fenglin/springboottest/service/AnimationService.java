package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.fenglin.springboottest.entity.Animation;

import java.util.List;

/**
 * 动画业务接口
 */
public interface AnimationService extends IService<Animation> {

    /**
     * 今日推荐：按热度倒序取前 limit 条
     */
    List<Animation> recommend(int limit);
}
