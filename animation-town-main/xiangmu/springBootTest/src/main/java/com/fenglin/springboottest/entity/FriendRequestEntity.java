package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.FieldStrategy;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 好友申请表实体，对应表 town_friend_request。
 * 好友关系改为「申请审批制」：A 向 B 发起申请（pending），
 * B 接受（accepted）后才写入 town_friend 双向关系；
 * 拒绝（rejected）或取消则申请作废。
 */
@Data
@TableName("town_friend_request")
public class FriendRequestEntity {

    /** 主键，自增 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 申请发起者 id（town_user.id） */
    private Long fromId;

    /** 接收者 id（town_user.id） */
    private Long toId;

    /** 状态：pending=待处理 / accepted=已接受 / rejected=已拒绝 / cancelled=已取消 */
    private String status;

    /** 附加留言（可选） */
    private String remark;

    /** 创建时间（数据库维护，ORM 不写入） */
    @TableField(insertStrategy = FieldStrategy.NEVER, updateStrategy = FieldStrategy.NEVER)
    private LocalDateTime createTime;

    /** 更新时间（数据库维护，ORM 不写入） */
    @TableField(insertStrategy = FieldStrategy.NEVER, updateStrategy = FieldStrategy.NEVER)
    private LocalDateTime updateTime;
}
