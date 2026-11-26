/**
 * 全局实时连接（多账号）
 * ---------------------------------------------------------------
 * 每个 userId 维持一条独立的 /ws/game 连接，互不顶号：
 *   1. 好友聊天：接收服务端推送的 {t:'chat'} 新消息
 *   2. 亲子联机：邀请 / 接受 / 对局消息
 *
 * 为什么支持多账号：
 *   后端 OnlineRegistry 是 Map<userId, session>，天然允许同一台电脑上的
 *   家长、孩子两个账号同时在线、互相邀请联机。前端早期是"单例单账号"
 *   的连接，切换账号会顶掉旧连接，导致一个账号永远显示离线、无法被邀请。
 *   现在按 userId 各连一条，彻底解决。
 *
 * 兼容旧写法：
 *   无参调用 connect()/send()/onMessage() 时，回退到"当前账号"（currentId），
 *   以便现有组件无需大改。新代码建议显式传入 userId。
 */
import { computed, ref } from 'vue'

const RECONNECT_DELAY = 2000
/** 退避上限倍数：2s,4s,6s,8s,10s,12s…（不再有"放弃"这一步） */
const MAX_BACKOFF = 6

/** 每个账号的连接与状态：Map<userId, { ws, retry, manualClose, status }> */
const sessions = new Map()

/** 当前"活跃账号"（最近一次 connect 的 userId），供无参调用回退 */
let currentId = null

// ------------------------------------------------------------
// 全局状态（保留给现有组件）
// ------------------------------------------------------------
/** idle | connecting | online | offline —— 当前账号的连接状态 */
export const status = ref('idle')
/** 当前账号 id（无参 send/onMessage 回退用） */
export const myId = ref(null)
/** 当前账号收到的邀请 { room, from:{id,nickname,avatar,role} } */
export const pendingInvite = ref(null)
/** 当前账号已确定的房间 { room, char, peer } */
export const activeRoom = ref(null)
/** 当前账号每位好友的未读条数：{ [friendId]: count } */
export const unreadBy = ref({})

export const totalUnread = computed(() =>
  Object.values(unreadBy.value).reduce((s, n) => s + n, 0)
)

// 消息订阅：fn(msg, userId)。userId 是被推送消息归属的账号。
const listeners = new Set()

/** 订阅消息（可选指定账号，缺省监听所有账号）。返回取消函数。 */
export function onMessage(fn, userId = null) {
  const item = { fn, userId: userId == null ? null : Number(userId) }
  listeners.add(item)
  return () => listeners.delete(item)
}

// ------------------------------------------------------------
// 连接生命周期
// ------------------------------------------------------------
function sessionOf(userId) {
  const id = Number(userId)
  if (!id) return null
  let s = sessions.get(id)
  if (!s) {
    s = { ws: null, retry: 0, manualClose: false, status: 'idle' }
    sessions.set(id, s)
  }
  return s
}

export function connect(userId) {
  const id = userId == null ? currentId : Number(userId)
  if (!id) return
  currentId = id
  myId.value = id

  const s = sessionOf(id)
  if (s.ws && (s.ws.readyState === 0 || s.ws.readyState === 1)) return
  s.manualClose = false
  s.retry = 0
  open(id, s)
}

function open(userId, s) {
  const proto = typeof location !== 'undefined' && location.protocol === 'https:' ? 'wss' : 'ws'
  const host = typeof location !== 'undefined' ? location.host : 'localhost:5173'
  let ws
  try {
    ws = new WebSocket(`${proto}://${host}/ws/game?userId=${userId}`)
  } catch (e) {
    s.status = 'offline'
    syncStatus()
    return
  }
  s.ws = ws
  s.status = 'connecting'
  syncStatus()

  ws.onopen = () => {
    s.retry = 0
    s.status = 'online'
    syncStatus()
  }
  ws.onclose = () => {
    s.status = 'offline'
    if (s.ws === ws) s.ws = null
    syncStatus()
    if (s.manualClose) return
    // 无限重连（退避封顶 12s）：之前重试 5 次就永久放弃，
    // 后端一重启超过 30 秒，用户就必须手动刷新页面才能恢复，体验极差。
    s.retry = Math.min(s.retry + 1, MAX_BACKOFF)
    setTimeout(() => {
      if (!s.manualClose && !s.ws) open(userId, s)
    }, RECONNECT_DELAY * s.retry)
  }
  ws.onerror = () => {}
  ws.onmessage = (ev) => {
    let msg
    try {
      msg = JSON.parse(ev.data)
    } catch (e) {
      return
    }
    route(userId, msg)
    listeners.forEach(({ fn, userId: only }) => {
      if (only != null && only !== userId) return
      try {
        fn(msg, userId)
      } catch (e) {
        console.warn('[realtime] handler error', e)
      }
    })
  }
}

/** 无参 status 反映"当前账号"的连接状态；多账号时各账号独立在线 */
function syncStatus() {
  const s = currentId ? sessions.get(currentId) : null
  status.value = s ? s.status : 'idle'
}

// ------------------------------------------------------------
// 消息路由（只作用于当前账号的全局状态）
// ------------------------------------------------------------
function route(userId, msg) {
  // 只有"当前账号"的消息才落到全局 pendingInvite/activeRoom/unreadBy
  if (userId !== currentId) return
  if (msg.t === 'invited') {
    pendingInvite.value = { room: msg.room, from: msg.from || {} }
  } else if (msg.t === 'cancelled') {
    pendingInvite.value = null
  } else if (msg.t === 'start') {
    pendingInvite.value = null
    activeRoom.value = { room: msg.room, char: msg.char, peer: msg.peer || {} }
  } else if (msg.t === 'chat') {
    bumpUnread(msg.from)
  }
}

// ------------------------------------------------------------
// 发送
// ------------------------------------------------------------
export function send(obj, userId = null) {
  const id = userId == null ? currentId : Number(userId)
  const s = id ? sessions.get(id) : null
  if (s && s.ws && s.ws.readyState === 1) {
    s.ws.send(JSON.stringify(obj))
    return true
  }
  return false
}

export function bumpUnread(friendId) {
  const k = Number(friendId)
  unreadBy.value = { ...unreadBy.value, [k]: (unreadBy.value[k] || 0) + 1 }
}

export function clearUnread(friendId) {
  const k = Number(friendId)
  if (!unreadBy.value[k]) return
  const next = { ...unreadBy.value }
  delete next[k]
  unreadBy.value = next
}

export function setUnread(map) {
  const next = {}
  Object.entries(map || {}).forEach(([k, v]) => {
    if (Number(v) > 0) next[Number(k)] = Number(v)
  })
  unreadBy.value = next
}

export function acceptInvite(invite) {
  const target = invite || pendingInvite.value
  if (!target) return false
  const ok = send({ t: 'accept', room: target.room })
  if (ok) pendingInvite.value = null
  return ok
}

export function declineInvite(invite) {
  const target = invite || pendingInvite.value
  if (!target) return false
  const ok = send({ t: 'decline', room: target.room })
  pendingInvite.value = null
  return ok
}

export function leaveRoom(room) {
  if (room) send({ t: 'leave', room })
  activeRoom.value = null
}

/** 关闭指定账号的连接；缺省关闭所有账号连接 */
export function close(userId = null) {
  if (userId != null) {
    const id = Number(userId)
    const s = sessions.get(id)
    if (s) {
      s.manualClose = true
      if (s.ws) { try { s.ws.close() } catch (e) {} }
      s.ws = null
      sessions.delete(id)
    }
    if (currentId === id) {
      currentId = null
      myId.value = null
      status.value = 'idle'
      pendingInvite.value = null
      activeRoom.value = null
      unreadBy.value = {}
    }
    return
  }
  sessions.forEach((s) => {
    s.manualClose = true
    if (s.ws) { try { s.ws.close() } catch (e) {} }
  })
  sessions.clear()
  currentId = null
  myId.value = null
  status.value = 'idle'
  pendingInvite.value = null
  activeRoom.value = null
  unreadBy.value = {}
}

/** 调试用：当前有几个账号在线（各自连接已建立） */
export function onlineIds() {
  const ids = []
  sessions.forEach((s, id) => {
    if (s.ws && s.ws.readyState === 1) ids.push(id)
  })
  return ids
}

/** 某个账号的实时连接是否可用（给"邀请前先自检"用） */
export function isConnected(userId = null) {
  const id = userId == null ? currentId : Number(userId)
  const s = id ? sessions.get(id) : null
  return !!(s && s.ws && s.ws.readyState === 1)
}

/**
 * 手动重连：跳过退避计时立即重来。
 * 对应 UI 上「实时连接已断开 → 重试」的按钮。
 */
export function retryNow(userId = null) {
  const id = userId == null ? currentId : Number(userId)
  if (!id) return
  const s = sessionOf(id)
  s.manualClose = false
  s.retry = 0
  if (s.ws) {
    try { s.ws.close() } catch (e) { /* 忽略 */ }
    s.ws = null
  }
  open(id, s)
}
