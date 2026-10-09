package com.fenglin.springboottest.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.entity.Animation;
import com.fenglin.springboottest.mapper.AnimationMapper;
import com.fenglin.springboottest.service.AnimationService;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 动画业务实现
 */
@Service
public class AnimationServiceImpl extends ServiceImpl<AnimationMapper, Animation> implements AnimationService {

    @Override
    public List<Animation> recommend(int limit) {
        // 兜底：避免非法 limit 造成 SQL 异常
        if (limit <= 0) {
            limit = 6;
        }
        if (limit > 50) {
            limit = 50;
        }
        return this.lambdaQuery()
                .orderByDesc(Animation::getHot)
                .last("LIMIT " + limit)
                .list();
    }
}
