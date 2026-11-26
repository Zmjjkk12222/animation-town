package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.FriendRequestEntity;
import org.apache.ibatis.annotations.Mapper;

/**
 * 好友申请表 Mapper，继承 MyBatis-Plus 的 BaseMapper 获得 CRUD 能力
 */
@Mapper
public interface FriendRequestMapper extends BaseMapper<FriendRequestEntity> {
}
