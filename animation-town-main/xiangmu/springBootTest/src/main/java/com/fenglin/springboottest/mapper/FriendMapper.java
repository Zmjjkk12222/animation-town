package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.Friend;
import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 好友表 Mapper，继承 MyBatis-Plus 的 BaseMapper 即可获得 CRUD 能力
 */
@Mapper
public interface FriendMapper extends BaseMapper<Friend> {

    /**
     * 物理删除一对好友关系（双向两条一起删）。
     * <p>
     * 为什么用手写 SQL 而不走 lambdaRemove：
     * Friend.deleted 上标了 @TableLogic，走 ORM 的 remove 只会把 deleted 置 1，
     * 行仍然留在表里；好友关系不需要保留历史，而残留的已删行会占住唯一索引 uk_pair，
     * 导致"删除好友后重新添加"插不进去。所以这里直接 DELETE。
     */
    @Delete("DELETE FROM town_friend "
            + "WHERE (user_id = #{a} AND friend_id = #{b}) "
            + "   OR (user_id = #{b} AND friend_id = #{a})")
    int deletePair(@Param("a") Long a, @Param("b") Long b);
}
