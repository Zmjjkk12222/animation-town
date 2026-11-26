package com.fenglin.springboottest.dto;

import com.fenglin.springboottest.entity.Message;
import lombok.Data;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

/**
 * 聊天消息出参。
 * ts 为毫秒时间戳，前端用它排序/分组；time 为便于直接展示的短时间。
 */
@Data
public class ChatMessageVO {

    private static final DateTimeFormatter HHMM = DateTimeFormatter.ofPattern("HH:mm");

    private Long id;
    private Long from;
    private Long to;
    private String type;
    private String content;
    private Integer read;
    private Long ts;
    private String time;

    public static ChatMessageVO of(Message m) {
        ChatMessageVO vo = new ChatMessageVO();
        vo.setId(m.getId());
        vo.setFrom(m.getFromId());
        vo.setTo(m.getToId());
        vo.setType(m.getType() == null ? "text" : m.getType());
        vo.setContent(m.getContent());
        vo.setRead(m.getReadFlag() == null ? 0 : m.getReadFlag());
        LocalDateTime t = m.getCreateTime() == null ? LocalDateTime.now() : m.getCreateTime();
        vo.setTs(t.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli());
        vo.setTime(t.format(HHMM));
        return vo;
    }
}
