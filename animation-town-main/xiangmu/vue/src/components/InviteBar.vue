<script setup>
/**
 * 全局联机邀请条
 * ---------------------------------------------------------------
 * 之前的问题：受邀方收到 {t:'invited'} 后只把它存进 realtime.js 的
 * pendingInvite，全项目没有任何组件读取它 —— 邀请像掉进了黑洞，
 * 发起方永远停在「等 TA 接受…」。
 *
 * 这个组件就是那个"门铃"：
 *   · 任意页面收到邀请，底部弹出邀请条
 *   · 点「接受」→ 走 WS 发 accept，并请求界面自动跳到联机游戏
 *   · 点「拒绝」/ 45 秒不处理 → 自动发 decline，服务端房间立刻回收
 *   · 顺带兜底实时连接：连不上时给出可见提示和「重试」按钮
 */
import { computed, onUnmounted, ref, watch } from 'vue'
import {
  acceptInvite,
  declineInvite,
  pendingInvite,
  status as netStatus,
  myId,
  connect
} from '../net/realtime.js'
import { requestOpenGame } from '../composables/gameEntry.js'

/** 邀请自动过期时间（服务端 90 秒，这里留出余量） */
const EXPIRE_SEC = 45

const left = ref(EXPIRE_SEC)
const busy = ref(false)
const notice = ref('')
let timer = null

const showInvite = computed(() => !!pendingInvite.value)
/** 已登录但实时连接断开 —— 需要让用户看见，否则会以为"对方不在线" */
const showOffline = computed(() => !!myId.value && netStatus.value === 'offline')

function stopTimer() {
  if (timer) { clearInterval(timer); timer = null }
}

function startTimer() {
  stopTimer()
  left.value = EXPIRE_SEC
  timer = setInterval(() => {
    left.value -= 1
    if (left.value <= 0) {
      stopTimer()
      // 超时自动拒绝，避免服务端留下一条永远没人处理、还占着"对方正在游戏中"的房间
      if (pendingInvite.value) declineInvite()
      notice.value = ''
    }
  }, 1000)
}

watch(showInvite, (v) => { v ? startTimer() : stopTimer() }, { immediate: true })

onUnmounted(stopTimer)

function onAccept() {
  if (busy.value) return
  busy.value = true
  const ok = acceptInvite()
  busy.value = false
  if (!ok) {
    notice.value = '联机服务还没连上，等两秒再试～'
    return
  }
  notice.value = ''
  stopTimer()
  requestOpenGame()
}

function onDecline() {
  declineInvite()
  stopTimer()
}

function onRetry() {
  if (myId.value) connect(myId.value)
}
</script>

<template>
  <div class="rt-layer">
    <!-- 邀请条 -->
    <div v-if="showInvite" class="invite-card" role="dialog" aria-live="polite">
      <span class="iva">{{ pendingInvite.from.avatar || '🧒' }}</span>
      <div class="itxt">
        <b class="iname">{{ pendingInvite.from.nickname || '好友' }}</b>
        <span class="isub">邀请你一起玩「冰娃与火娃」</span>
      </div>
      <span class="icount">{{ left }}s</span>
      <button class="iok" type="button" @click="onAccept">接受</button>
      <button class="ino" type="button" @click="onDecline">拒绝</button>
    </div>

    <!-- 实时连接断开提示 -->
    <div v-else-if="showOffline" class="offline-chip">
      <span class="odot"></span>
      <span>实时连接已断开，好友看不到你在线</span>
      <button type="button" @click="onRetry">重试</button>
    </div>

    <p v-if="notice" class="inet-notice">{{ notice }}</p>
  </div>
</template>

<style scoped>
.rt-layer {
  position: fixed;
  left: 50%;
  bottom: 22px;
  transform: translateX(-50%);
  z-index: 900;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  pointer-events: none;
  font-family: var(--font, inherit);
}
.rt-layer > * { pointer-events: auto; }

.invite-card {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px 10px 14px;
  background: #fff;
  border: 1px solid #ffd8e2;
  border-radius: 999px;
  box-shadow: 0 12px 32px rgba(255, 107, 129, .22), 0 2px 8px rgba(120, 140, 190, .12);
  animation: pop .22s ease-out;
  max-width: min(92vw, 460px);
}
@keyframes pop {
  from { opacity: 0; transform: translateY(10px) scale(.96); }
  to   { opacity: 1; transform: translateY(0) scale(1); }
}

.iva {
  width: 34px; height: 34px; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center;
  font-size: 19px; border-radius: 50%;
  background: linear-gradient(135deg, #ffe9f0, #e8f3ff);
}
.itxt { display: flex; flex-direction: column; min-width: 0; line-height: 1.35; }
.iname {
  font-size: 14px; color: #3a3a5e; font-weight: 600;
  max-width: 150px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
.isub { font-size: 12px; color: #7a7a9c; }

.icount {
  font-size: 11px; color: #b0b0c8; font-variant-numeric: tabular-nums;
  min-width: 26px; text-align: right;
}

.iok, .ino {
  border: none; border-radius: 999px; cursor: pointer;
  font-family: inherit; font-size: 13px; font-weight: 600;
  padding: 7px 15px; transition: transform .15s, box-shadow .15s;
}
.iok {
  color: #fff;
  background: linear-gradient(135deg, #ff9a9e, #ff6b81);
  box-shadow: 0 4px 12px rgba(255, 107, 129, .32);
}
.iok:hover { transform: translateY(-1px); box-shadow: 0 6px 16px rgba(255, 107, 129, .4); }
.ino { background: #f4f2fa; color: #7a7a9c; }
.ino:hover { background: #ebe8f6; }

.offline-chip {
  display: flex; align-items: center; gap: 8px;
  padding: 7px 12px;
  background: rgba(255, 251, 235, .96);
  border: 1px solid #ffe0a8;
  border-radius: 999px;
  font-size: 12px; color: #a4781f;
  box-shadow: 0 6px 18px rgba(180, 140, 40, .14);
}
.offline-chip button {
  border: none; border-radius: 999px; cursor: pointer;
  font-family: inherit; font-size: 12px; font-weight: 600;
  padding: 4px 11px; color: #fff; background: #f2b73c;
}
.odot {
  width: 7px; height: 7px; border-radius: 50%; background: #f2b73c;
  animation: blink 1.4s ease-in-out infinite;
}
@keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: .28; } }

.inet-notice {
  margin: 0;
  padding: 6px 12px;
  font-size: 12px; color: #c2410c;
  background: rgba(255, 247, 237, .97);
  border: 1px solid #ffd9b8;
  border-radius: 999px;
}
</style>
