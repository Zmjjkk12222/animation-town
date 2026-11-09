import { http, unwrap } from './http'

/**
 * 好友功能 API（对应后端 FriendController /api/friend）
 * 返回的好友对象 FriendVO：{ id, nickname, avatar, role, online, isFriend }
 */

/** 我的好友列表（带在线状态：连着游戏 WebSocket 即在线） */
export async function getFriends(userId) {
  return unwrap(await http.get(`/friend/list/${userId}`))
}

/** 按昵称搜索可添加的用户（后端已排除自己与已有好友） */
export async function searchUsers(userId, keyword) {
  return unwrap(await http.get('/friend/search', { params: { userId, keyword } }))
}

/** 添加好友（后端双向写入、幂等） */
export async function addFriend(userId, friendId) {
  return unwrap(await http.post('/friend/add', { userId, friendId }))
}

/** 删除好友（后端双向删除） */
export async function removeFriend(userId, friendId) {
  return unwrap(await http.post('/friend/remove', { userId, friendId }))
}
