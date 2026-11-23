package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.Message;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

/**
 * 聊天消息 Mapper
 */
@Mapper
public interface MessageMapper extends BaseMapper<Message> {

    /**
     * 每个好友的未读条数：返回 [{fromId, cnt}, ...]
     * 用于好友列表上的红点气泡，避免一次拉全量消息。
     */
    @Select("SELECT from_id AS fromId, COUNT(*) AS cnt FROM town_message "
            + "WHERE to_id = #{userId} AND read_flag = 0 GROUP BY from_id")
    List<Map<String, Object>> unreadByFriend(@Param("userId") Long userId);
}
