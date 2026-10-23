package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.Animation;
import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 动画表 Mapper，继承 BaseMapper 即获得 CRUD 能力
 */
@Mapper
public interface AnimationMapper extends BaseMapper<Animation> {

    /**
     * 物理删除：后台管理删除动画时使用，真正从 town_animation 表移除行，
     * 不受 MyBatis-Plus 逻辑删除（@TableLogic）拦截器影响。
     */
    @Delete("DELETE FROM town_animation WHERE id = #{id}")
    int deletePhysically(@Param("id") Long id);
}
