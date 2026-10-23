package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.User;
import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 用户表 Mapper，继承 MyBatis-Plus 的 BaseMapper 即可获得 CRUD 能力
 */
@Mapper
public interface UserMapper extends BaseMapper<User> {

    /**
     * 物理删除：后台管理删除用户时使用，真正从 town_user 表移除行，
     * 不受 MyBatis-Plus 逻辑删除（@TableLogic）拦截器影响。
     */
    @Delete("DELETE FROM town_user WHERE id = #{id}")
    int deletePhysically(@Param("id") Long id);
}
