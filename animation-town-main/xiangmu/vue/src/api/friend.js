import { http, unwrap } from './http'

/**
 * 好友功能 API（对应后端 FriendController /api/friend）
 * 返回的好友对象 FriendVO：{ id, nickname, avatar, role, online, isFriend, isApplied }
 */

/** 我的好友列表（带在线状态：连着游戏 WebSocket 即在线） */
export async function getFriends(userId) {
  return unwrap(await http.get(`/friend/list/${userId}`))
}

/** 按昵称搜索可添加的用户（后端已排除自己与已有好友） */
export async function searchUsers(userId, keyword) {
  return unwrap(await http.get('/friend/search', { params: { userId, keyword } }))
}

/** 发起好友申请（申请审批制） */
export async function applyFriend(userId, friendId, remark = '') {
  return unwrap(await http.post('/friend/apply', { userId, friendId, remark }))
}

/** 我收到的待处理好友申请 */
export async function getPendingRequests(userId) {
  return unwrap(await http.get(`/friend/pending/${userId}`))
}

/** 接受好友申请（friendId 传申请记录 id） */
export async function acceptFriend(userId, requestId) {
  return unwrap(await http.post('/friend/accept', { userId, friendId: requestId }))
}

/** 拒绝好友申请（friendId 传申请记录 id） */
export async function declineFriend(userId, requestId) {
  return unwrap(await http.post('/friend/decline', { userId, friendId: requestId }))
}

/** 删除好友（后端双向删除） */
export async function removeFriend(userId, friendId) {
  return unwrap(await http.post('/friend/remove', { userId, friendId }))
}
