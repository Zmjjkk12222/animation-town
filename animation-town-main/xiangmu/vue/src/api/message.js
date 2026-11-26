import { http, unwrap } from './http'

/**
 * 好友聊天 API（对应后端 MessageController /api/message）
 * 消息结构：{ id, from, to, type, content, read, ts, time }
 */

/** 发送消息（落库 + 服务端推送给在线接收方）；type 默认 text，表情传 emoji */
export async function sendMessage(fromId, toId, content, type = 'text') {
  return unwrap(await http.post('/message/send', { fromId, toId, type, content }))
}

/** 与某位好友的历史消息（升序，最多 limit 条；传 beforeId 可往前翻页） */
export async function getHistory(userId, friendId, beforeId = null, limit = 30) {
  const params = { userId, friendId, limit }
  if (beforeId) params.beforeId = beforeId
  return unwrap(await http.get('/message/history', { params }))
}

/** 每个好友的未读条数：{ [friendId]: count } */
export async function getUnread(userId) {
  return unwrap(await http.get('/message/unread', { params: { userId } }))
}

/** 把某位好友发来的消息标记为已读 */
export async function markRead(userId, friendId) {
  return unwrap(await http.post('/message/read', null, { params: { userId, friendId } }))
}
