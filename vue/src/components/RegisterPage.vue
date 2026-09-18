<script setup>
import { ref } from 'vue'
import Mascot from './Mascot.vue'
import Toast from './Toast.vue'
import { useToast, burstConfetti } from '../composables/feedback.js'

const emit = defineEmits(['go-login'])
const { toast } = useToast()

const mode = ref('kid')            // 'kid' | 'parent'
const avatar = ref('🦄')
const user = ref('')
const phone = ref('')
const pwd = ref('')
const pwd2 = ref('')
const showPwd = ref(false)
const agree = ref(false)
const strength = ref(0)            // 0~3

function setMode(m) { mode.value = m }

function pickAvatar(emoji, el) {
  avatar.value = emoji
  document.querySelectorAll('#avatars button').forEach(b => b.classList.remove('active'))
  el.classList.add('active')
}

function togglePw() { showPwd.value = !showPwd.value }

function checkStrength() {
  const v = pwd.value
  let s = 0
  if (v.length >= 6) s++
  if (/[a-zA-Z]/.test(v) && /\d/.test(v)) s++
  if (v.length >= 10) s++
  strength.value = s
}

function doRegister(e) {
  e.preventDefault()
  if (!user.value.trim()) { toast('先给自己起个可爱的昵称吧～ 🥺'); return }
  if (mode.value === 'parent' && !phone.value.trim()) { toast('请填写家长手机号哦～ 📱'); return }
  if (pwd.value.length < 6) { toast('密码至少要 6 位哦～ 🔐'); return }
  if (pwd.value !== pwd2.value) { toast('两次密码不一样呢，再检查一下～ 🤔'); return }
  if (!agree.value) { toast('要勾选《安全公约》才能加入哦～ 📜'); return }
  toast('角色创建成功！欢迎来到动画小镇 🎉')
  burstConfetti()
}
</script>

<template>
  <main class="card reg">
    <Mascot variant="register" mood="big" />

    <h1 class="title">加入动画小镇</h1>
    <p class="subtitle">选一个可爱头像，创建你的角色吧！🌟</p>

    <div class="mode" role="tablist">
      <button :class="{ active: mode === 'kid' }" @click="setMode('kid')">🧒 小朋友</button>
      <button :class="{ active: mode === 'parent' }" @click="setMode('parent')">👨‍👩‍👧 爸爸妈妈</button>
    </div>

    <div class="avatars" id="avatars">
      <button type="button" :class="{ active: avatar === '🦄' }" @click="pickAvatar('🦄', $event.currentTarget)">🦄</button>
      <button type="button" :class="{ active: avatar === '🐱' }" @click="pickAvatar('🐱', $event.currentTarget)">🐱</button>
      <button type="button" :class="{ active: avatar === '🐰' }" @click="pickAvatar('🐰', $event.currentTarget)">🐰</button>
      <button type="button" :class="{ active: avatar === '🐻' }" @click="pickAvatar('🐻', $event.currentTarget)">🐻</button>
      <button type="button" :class="{ active: avatar === '🦊' }" @click="pickAvatar('🦊', $event.currentTarget)">🦊</button>
      <button type="button" :class="{ active: avatar === '🐸' }" @click="pickAvatar('🐸', $event.currentTarget)">🐸</button>
    </div>

    <form @submit="doRegister">
      <div class="field">
        <label>你的昵称</label>
        <div class="box">
          <span class="emoji">✨</span>
          <input v-model="user" type="text" placeholder="例如：爱画画的朵朵" autocomplete="username" />
        </div>
      </div>

      <div class="field" v-if="mode === 'parent'">
        <label>家长手机号</label>
        <div class="box">
          <span class="emoji">📱</span>
          <input v-model="phone" type="tel" placeholder="用于账号安全与找回" />
        </div>
      </div>

      <div class="field">
        <label>设置魔法密码</label>
        <div class="box">
          <span class="emoji">🔑</span>
          <input v-model="pwd" :type="showPwd ? 'text' : 'password'" placeholder="至少 6 位，字母+数字更安全" @input="checkStrength" />
          <button type="button" class="toggle-pw" @click="togglePw">👁️</button>
        </div>
        <div class="strength">
          <i :class="strength >= 1 ? (strength === 1 ? 'on1' : strength === 2 ? 'on2' : 'on3') : ''"></i>
          <i :class="strength >= 2 ? (strength === 2 ? 'on2' : 'on3') : ''"></i>
          <i :class="strength >= 3 ? 'on3' : ''"></i>
        </div>
      </div>

      <div class="field">
        <label>再输一次密码</label>
        <div class="box">
          <span class="emoji">🔒</span>
          <input v-model="pwd2" type="password" placeholder="和上面一样哦" />
        </div>
      </div>

      <label class="agree">
        <input type="checkbox" v-model="agree" />
        <span>我已阅读并同意 <a href="#" @click.prevent="toast('打开《动画小镇安全公约》📜')">《安全公约》</a>，答应和爸爸妈妈一起保护账号安全。</span>
      </label>

      <button class="btn-reg" type="submit">🎉 创建我的角色</button>
    </form>

    <p class="login-link">已经是小镇居民？ <a href="#" @click.prevent="emit('go-login')">去登入 →</a></p>
  </main>

  <Toast />
</template>

<style scoped>
.mode { display: flex; gap: 8px; background: #eafaf3; border-radius: 18px; padding: 6px; margin: 0 auto 18px; width: fit-content; }
.mode button { border: none; background: transparent; font-family: var(--font); cursor: pointer; padding: 9px 16px; border-radius: 14px; font-size: 14px; color: #5a8a78; transition: .25s; }
.mode button.active { background: #fff; color: #2f9e7a; box-shadow: 0 4px 12px var(--shadow); transform: scale(1.04); }

.avatars { display: flex; justify-content: center; gap: 10px; margin-bottom: 18px; flex-wrap: wrap; }
.avatars button { width: 50px; height: 50px; border-radius: 50%; border: 3px solid #e3f3ec; background: #f4fbf8; font-size: 24px; cursor: pointer; transition: .2s; }
.avatars button:hover { transform: translateY(-3px); }
.avatars button.active { border-color: var(--mint); background: #fff; box-shadow: 0 0 0 4px rgba(126, 224, 192, .25); transform: scale(1.08); }

.field { position: relative; margin-bottom: 14px; text-align: left; }
.field label { display: block; font-size: 13px; margin: 0 0 6px 6px; color: #6a5a8a; }
.field .box { display: flex; align-items: center; gap: 8px; background: #fbf7ff; border: 3px solid #ece3ff; border-radius: 18px; padding: 11px 14px; transition: .25s; }
.field .box:focus-within { border-color: var(--mint); background: #fff; box-shadow: 0 0 0 4px rgba(126, 224, 192, .18); }
.field .emoji { font-size: 19px; }
.field input { border: none; outline: none; background: transparent; flex: 1; font-family: var(--font); font-size: 15px; color: var(--ink); }
.field input::placeholder { color: #bcb0d6; }
.toggle-pw { cursor: pointer; user-select: none; font-size: 17px; opacity: .7; border: none; background: none; }

.strength { display: flex; gap: 5px; margin: 8px 6px 0; }
.strength i { flex: 1; height: 7px; border-radius: 5px; background: #ece3ff; transition: .3s; }
.strength i.on1 { background: #ff8f8f; }
.strength i.on2 { background: #ffd23f; }
.strength i.on3 { background: #7ee0c0; }

.agree { display: flex; align-items: flex-start; gap: 8px; font-size: 12.5px; color: #7a6aa0; text-align: left; margin: 4px 6px 18px; line-height: 1.5; }
.agree input { width: 16px; height: 16px; accent-color: var(--mint); margin-top: 2px; flex-shrink: 0; }
.agree a { color: var(--blue); text-decoration: none; }

.btn-reg { width: 100%; border: none; cursor: pointer; font-family: var(--font); padding: 15px; border-radius: 20px; font-size: 19px; color: #fff;
  background: linear-gradient(120deg, var(--mint), #2fbf95); box-shadow: 0 10px 22px rgba(47, 191, 149, .4); transition: transform .12s, box-shadow .2s; position: relative; overflow: hidden; }
.btn-reg:hover { transform: translateY(-2px); box-shadow: 0 14px 28px rgba(47, 191, 149, .5); }
.btn-reg:active { transform: scale(.96); }
.btn-reg::after { content: ""; position: absolute; top: 0; left: -60%; width: 40%; height: 100%; background: linear-gradient(120deg, transparent, rgba(255,255,255,.6), transparent); transform: skewX(-20deg); animation: shine 3.5s ease-in-out infinite; }
@keyframes shine { 0%, 60% { left: -60%; } 100% { left: 130%; } }

.login-link { margin-top: 16px; font-size: 14px; color: #7a6aa0; }
.login-link a { color: var(--pink-d); font-weight: bold; text-decoration: none; }
</style>
