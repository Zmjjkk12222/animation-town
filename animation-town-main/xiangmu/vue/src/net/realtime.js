/**
 * 全局实时连接（单例）
 * ---------------------------------------------------------------
 * 全站只维持一条 /ws/game 连接，供两处共用：
 *   1. 好友聊天：接收服务端推送的 {t:'chat'} 新消息
 *   2. 亲子联机：邀请 / 接受 / 对局消息
 *
 * 为什么不是每个组件各连一条：
 *   后端 OnlineRegistry 按 userId 只保留最后一个会话，两条连接会互相顶掉；
 *   而且"在线"状态应该表示"用户打开了应用"，而不是"用户正停在游戏页"。
 */
import { computed, ref } from 'vue'

const RECONNECT_DELAY = 2000
const MAX_RETRY = 5

/** idle | connecting | online | offline */
export const status = ref('idle')
export const myId = ref(null)
/** 收到的邀请 { room, from:{id,nickname,avatar,role} } */
export const pendingInvite = ref(null)
/** 已确定的房间 { room, char, peer } —— 组件未挂载时先存这里，挂载后自己取用 */
export const activeRoom = ref(null)
/** 每位好友的未读条数：{ [friendId]: count } */
export const unreadBy = ref({})

export const totalUnread = computed(() =>
  Object.values(unreadBy.value).reduce((s, n) => s + n, 0)
)

let ws = null
let currentUserId = null
let retry = 0
let manualClose = false
const listeners = new Set()

/** 订阅消息：返回取消订阅函数 */
export function onMessage(fn) {
  listeners.add(fn)
  return () => listeners.delete(fn)
}

export function connect(userId) {
  const id = Number(userId)
  if (!id) return
  if (currentUserId === id && ws && (ws.readyState === 0 || ws.readyState === 1)) return
  if (currentUserId !== id) {
    // 换了账号：清掉上一个账号的残留状态
    pendingInvite.value = null
    activeRoom.value = null
    unreadBy.value = {}
  }
  currentUserId = id
  myId.value = id
  manualClose = false
  retry = 0
  open()
}

function open() {
  if (!currentUserId) return
  const proto = typeof location !== 'undefined' && location.protocol === 'https:' ? 'wss' : 'ws'
  const host = typeof location !== 'undefined' ? location.host : 'localhost:5173'
  try {
    ws = new WebSocket(`${proto}://${host}/ws/game?userId=${currentUserId}`)
  } catch (e) {
    status.value = 'offline'
    return
  }
  status.value = 'connecting'
  ws.onopen = () => {
    retry = 0
    status.value = 'online'
  }
  ws.onclose = () => {
    status.value = 'offline'
    ws = null
    if (!manualClose && retry < MAX_RETRY) {
      retry += 1
      setTimeout(() => {
        if (!manualClose) open()
      }, RECONNECT_DELAY * retry)
    }
  }
  ws.onerror = () => {}
  ws.onmessage = (ev) => {
    let msg
    try {
      msg = JSON.parse(ev.data)
    } catch (e) {
      return
    }
    route(msg)
    listeners.forEach((fn) => {
      try {
        fn(msg)
      } catch (e) {
        console.warn('[realtime] handler error', e)
      }
    })
  }
}

/** 连接层自己关心的少数消息，先落到全局状态里 */
function route(msg) {
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

export function send(obj) {
  if (ws && ws.readyState === 1) {
    ws.send(JSON.stringify(obj))
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

export function close() {
  manualClose = true
  if (ws) {
    try {
      ws.close()
    } catch (e) {}
  }
  ws = null
  currentUserId = null
  status.value = 'idle'
}
