package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.Favorite;
import org.apache.ibatis.annotations.Mapper;

/**
 * 收藏表 Mapper，继承 BaseMapper 即获得 CRUD 能力
 */
@Mapper
public interface FavoriteMapper extends BaseMapper<Favorite> {
}
