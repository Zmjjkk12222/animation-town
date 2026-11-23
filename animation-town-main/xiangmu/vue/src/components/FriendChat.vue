<script setup>
/**
 * 好友聊天面板（抽屉式，不跳页面）
 * ---------------------------------------------------------------
 * · 历史消息走 REST（打开即已读），新消息走全局 WebSocket 推送
 * · 只有一条全局连接（见 src/net/realtime.js），不在这里重复建连
 * · Enter 发送、Shift+Enter 换行、Esc 关闭、手机端全屏
 */
import { computed, nextTick, onMounted, onUnmounted, ref } from 'vue'
import { getHistory, sendMessage, markRead } from '../api/message.js'
import { clearUnread, connect, onMessage } from '../net/realtime.js'

const props = defineProps({
  user: { type: Object, default: null },
  friend: { type: Object, required: true }
})
const emit = defineEmits(['close'])

const MAX = 500

const messages = ref([])
const text = ref('')
const loading = ref(true)
const loadingMore = ref(false)
const sending = ref(false)
const hasMore = ref(false)
const error = ref('')
const listEl = ref(null)
const inputEl = ref(null)

const myId = computed(() => (props.user && props.user.id) || 0)
const friendId = computed(() => props.friend && props.friend.id)

let unsub = null

function scrollBottom(smooth) {
  nextTick(() => {
    const el = listEl.value
    if (el) el.scrollTo({ top: el.scrollHeight, behavior: smooth ? 'smooth' : 'auto' })
  })
}

function push(msg) {
  if (!msg || !msg.id) return
  if (messages.value.some((m) => m.id === msg.id)) return
  messages.value = [...messages.value, msg].sort((a, b) => (a.id || 0) - (b.id || 0))
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    const rows = await getHistory(myId.value, friendId.value)
    messages.value = rows || []
    hasMore.value = messages.value.length >= 30
    markRead(myId.value, friendId.value).catch(() => {})
    clearUnread(friendId.value)
    scrollBottom(false)
  } catch (e) {
    error.value = e.message || '聊天记录加载失败'
  } finally {
    loading.value = false
  }
}

async function loadMore() {
  if (!messages.value.length || loadingMore.value) return
  loadingMore.value = true
  try {
    const before = messages.value[0].id
    const rows = await getHistory(myId.value, friendId.value, before)
    if (!rows || !rows.length) {
      hasMore.value = false
    } else {
      const el = listEl.value
      const prevHeight = el ? el.scrollHeight : 0
      messages.value = [...rows, ...messages.value]
      hasMore.value = rows.length >= 30
      nextTick(() => {
        if (el) el.scrollTop = el.scrollHeight - prevHeight
      })
    }
  } catch (e) {
    /* 翻页失败保持现状即可 */
  } finally {
    loadingMore.value = false
  }
}

async function send() {
  const content = text.value.trim()
  if (!content || sending.value) return
  if (content.length > MAX) {
    error.value = '消息最多 ' + MAX + ' 字'
    return
  }
  sending.value = true
  error.value = ''
  try {
    const saved = await sendMessage(myId.value, friendId.value, content)
    push(saved)
    text.value = ''
    scrollBottom(true)
    if (inputEl.value) inputEl.value.focus()
  } catch (e) {
    error.value = e.message || '发送失败，请稍后再试'
  } finally {
    sending.value = false
  }
}

function onInputKeydown(e) {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault()
    send()
  }
}

function onGlobalKey(e) {
  if (e.key === 'Escape') emit('close')
}

/** 相邻消息间隔超过 5 分钟才显示时间，避免每条都顶着时间戳 */
function showTime(i) {
  if (i === 0) return true
  const prev = messages.value[i - 1]
  const cur = messages.value[i]
  return (cur.ts || 0) - (prev.ts || 0) > 5 * 60 * 1000
}

function formatTime(ts) {
  if (!ts) return ''
  const d = new Date(ts)
  const now = new Date()
  const hh = String(d.getHours()).padStart(2, '0')
  const mm = String(d.getMinutes()).padStart(2, '0')
  if (d.toDateString() === now.toDateString()) return hh + ':' + mm
  return (d.getMonth() + 1) + '月' + d.getDate() + '日 ' + hh + ':' + mm
}

onMounted(() => {
  if (myId.value) connect(myId.value)
  load()
  unsub = onMessage((msg) => {
    if (msg.t !== 'chat' || msg.from !== friendId.value) return
    push(msg)
    scrollBottom(true)
    markRead(myId.value, friendId.value).catch(() => {})
    clearUnread(friendId.value)
  })
  window.addEventListener('keydown', onGlobalKey)
  nextTick(() => {
    if (inputEl.value) inputEl.value.focus()
  })
})

onUnmounted(() => {
  if (unsub) unsub()
  window.removeEventListener('keydown', onGlobalKey)
})
</script>

<template>
  <Teleport to="body">
    <div class="fc-mask" @click.self="emit('close')">
      <section class="fc-panel" role="dialog" aria-label="好友聊天">
        <header class="fc-head">
          <span class="fc-ava">{{ friend.avatar || '🧒' }}</span>
          <div class="fc-who">
            <b class="fc-name">{{ friend.nickname }}</b>
            <small class="fc-state" :class="{ on: friend.online }">
              {{ friend.online ? '· 在线' : '· 离线，消息会先存着' }}
            </small>
          </div>
          <button class="fc-x" type="button" aria-label="关闭" @click="emit('close')">✕</button>
        </header>

        <div ref="listEl" class="fc-body">
          <p v-if="loading" class="fc-hint">正在加载聊天记录…</p>
          <template v-else>
            <button
              v-if="hasMore" class="fc-more" type="button"
              :disabled="loadingMore" @click="loadMore"
            >{{ loadingMore ? '加载中…' : '看更早的消息' }}</button>
            <p v-if="!messages.length" class="fc-hint">还没聊过，发个消息打个招呼吧 👋</p>
            <div
              v-for="(m, i) in messages" :key="m.id"
              class="fc-item" :class="{ mine: m.from === myId }"
            >
              <span v-if="showTime(i)" class="fc-time">{{ formatTime(m.ts) }}</span>
              <span class="fc-bubble">{{ m.content }}</span>
            </div>
          </template>
        </div>

        <p v-if="error" class="fc-err">{{ error }}</p>

        <footer class="fc-foot">
          <textarea
            ref="inputEl" v-model="text" class="fc-input" :maxlength="MAX" rows="1"
            placeholder="说点什么…（Enter 发送，Shift+Enter 换行）"
            @keydown="onInputKeydown"
          ></textarea>
          <button
            class="fc-send" type="button"
            :disabled="sending || !text.trim()" @click="send"
          >{{ sending ? '…' : '发送' }}</button>
        </footer>
        <div class="fc-count">{{ text.length }}/{{ MAX }}</div>
      </section>
    </div>
  </Teleport>
</template>

<style scoped>
.fc-mask {
  position: fixed; inset: 0; z-index: 95;
  background: rgba(26, 30, 52, .35);
  backdrop-filter: blur(3px);
  display: flex; justify-content: flex-end;
  animation: fcFade .18s ease both;
}
@keyframes fcFade { from { opacity: 0 } to { opacity: 1 } }

.fc-panel {
  width: min(94vw, 400px); height: 100%;
  display: flex; flex-direction: column;
  background: #fff;
  border-left: 1px solid #ffe0ec;
  box-shadow: -18px 0 48px rgba(120, 90, 130, .18);
  animation: fcIn .24s ease both;
}
@keyframes fcIn { from { transform: translateX(28px); opacity: .6 } to { transform: none; opacity: 1 } }

.fc-head {
  display: flex; align-items: center; gap: 10px;
  padding: 14px 16px;
  color: #fff;
  background: linear-gradient(120deg, #ff8fc4, #ff6fa5);
}
.fc-ava {
  width: 38px; height: 38px; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center;
  font-size: 20px; border-radius: 50%;
  background: rgba(255, 255, 255, .25);
}
.fc-who { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.fc-name { font-size: 15px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.fc-state { font-size: 11px; opacity: .85; }
.fc-state.on { opacity: 1; }
.fc-x {
  flex-shrink: 0; width: 32px; height: 32px; border: none; cursor: pointer;
  border-radius: 50%; font-size: 15px; color: #fff;
  background: rgba(255, 255, 255, .22); transition: .15s;
}
.fc-x:hover { background: rgba(255, 255, 255, .4); transform: rotate(90deg); }

.fc-body {
  flex: 1; overflow-y: auto; padding: 14px 14px 8px;
  background: linear-gradient(180deg, #fff9fc, #ffffff 40%);
  display: flex; flex-direction: column; gap: 8px;
}
.fc-hint { text-align: center; color: #a9a4bb; font-size: 12px; padding: 26px 10px; }
.fc-more {
  align-self: center; border: 1px dashed #ffd0e2; background: #fff;
  color: #ff6fa5; font-size: 12px; padding: 5px 12px; border-radius: 999px; cursor: pointer;
}
.fc-more:disabled { opacity: .6; cursor: default; }

.fc-item { display: flex; flex-direction: column; align-items: flex-start; gap: 3px; }
.fc-item.mine { align-items: flex-end; }
.fc-time { font-size: 11px; color: #b8b2c7; padding: 2px 4px; }
.fc-bubble {
  max-width: 84%; padding: 9px 12px; font-size: 14px; line-height: 1.55;
  color: #4b4560; background: #f4f2fa; border-radius: 14px 14px 14px 4px;
  white-space: pre-wrap; word-break: break-word;
}
.fc-item.mine .fc-bubble {
  color: #fff; background: linear-gradient(120deg, #ff7fb2, #ff6fa5);
  border-radius: 14px 14px 4px 14px;
}

.fc-err {
  margin: 0; padding: 6px 16px; font-size: 12px; color: #e2537c;
  background: #fff1f6;
}
.fc-foot {
  display: flex; align-items: flex-end; gap: 8px;
  padding: 10px 14px 4px; border-top: 1px solid #ffe9f2;
}
.fc-input {
  flex: 1; resize: none; max-height: 96px; min-height: 38px;
  padding: 9px 12px; font-size: 14px; font-family: inherit; color: #4b4560;
  border: 1px solid #ffe0ec; border-radius: 12px; outline: none;
  background: #fffafc;
}
.fc-input:focus { border-color: #ffb4d3; box-shadow: 0 0 0 3px rgba(255, 143, 196, .16); }
.fc-send {
  flex-shrink: 0; height: 38px; padding: 0 16px; border: none; cursor: pointer;
  font-family: inherit; font-size: 14px; color: #fff; border-radius: 12px;
  background: linear-gradient(120deg, #ff6fa5, #ff8fc4);
  box-shadow: 0 6px 14px rgba(255, 111, 165, .35);
}
.fc-send:disabled { opacity: .5; cursor: default; box-shadow: none; }
.fc-count { padding: 2px 16px 8px; text-align: right; font-size: 11px; color: #c3bdcd; }

@media (max-width: 640px) {
  .fc-panel { width: 100vw; height: 100dvh; border-left: none; }
}
</style>
