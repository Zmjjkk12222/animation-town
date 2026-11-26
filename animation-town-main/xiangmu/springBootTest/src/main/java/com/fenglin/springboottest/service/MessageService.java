package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.fenglin.springboottest.dto.ChatMessageVO;
import com.fenglin.springboottest.entity.Message;

import java.util.List;
import java.util.Map;

/**
 * 好友聊天业务
 */
public interface MessageService extends IService<Message> {

    /** 发送一条消息：校验好友关系与长度，落库后推送给在线接收方 */
    ChatMessageVO send(Long fromId, Long toId, String type, String content);

    /**
     * 拉取与某位好友的历史消息（按 id 升序返回，最多 limit 条）。
     * 拉取时会把对方发给我的未读一并标记为已读。
     */
    List<ChatMessageVO> history(Long userId, Long friendId, Long beforeId, int limit);

    /** 每个好友的未读条数：friendId -> count */
    Map<Long, Integer> unreadCounts(Long userId);

    /** 把某位好友发给我的消息全部标记为已读 */
    boolean markRead(Long userId, Long friendId);
}
