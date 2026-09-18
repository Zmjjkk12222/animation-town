<script setup>
import { ref } from 'vue'
import Mascot from './Mascot.vue'
import Toast from './Toast.vue'
import { useToast, burstConfetti } from '../composables/feedback.js'

const emit = defineEmits(['go-register'])
const { toast } = useToast()

const mode = ref('kid')      // 'kid' | 'parent'
const user = ref('')
const pwd = ref('')
const showPwd = ref(false)
const mood = ref('smile')    // 打字时吉祥物变大笑

function setMode(m) { mode.value = m }

function togglePw() { showPwd.value = !showPwd.value }

function onUserInput() {
  mood.value = user.value.length > 0 ? 'big' : 'smile'
}

function doLogin(e) {
  e.preventDefault()
  if (!user.value.trim() || !pwd.value) {
    toast('要把昵称和密码都填好哦～ 🥺')
    return
  }
  toast('登入成功！正在打开动画小镇… 🎉')
  burstConfetti()
}
</script>

<template>
  <main class="card">
    <Mascot variant="login" :mood="mood" />

    <h1 class="title">动画小镇</h1>
    <p class="subtitle">欢迎回来，小探险家！🎈</p>

    <div class="mode" role="tablist">
      <button :class="{ active: mode === 'kid' }" @click="setMode('kid')">🧒 小朋友</button>
      <button :class="{ active: mode === 'parent' }" @click="setMode('parent')">👨‍👩‍👧 爸爸妈妈</button>
    </div>

    <form @submit="doLogin">
      <div class="field">
        <label>你的昵称 / 账号</label>
        <div class="box">
          <span class="emoji">🦄</span>
          <input v-model="user" type="text" placeholder="例如：爱画画的朵朵" autocomplete="username" @input="onUserInput" />
        </div>
      </div>

      <div class="field">
        <label>魔法密码</label>
        <div class="box">
          <span class="emoji">🔑</span>
          <input v-model="pwd" :type="showPwd ? 'text' : 'password'" placeholder="输入你的秘密密码" autocomplete="current-password" />
          <button type="button" class="toggle-pw" @click="togglePw" aria-label="显示密码">👁️</button>
        </div>
      </div>

      <div class="row">
        <label class="remember"><input type="checkbox" checked /> 记住我</label>
        <a class="link" href="#" @click.prevent="toast('密码找回小精灵正在赶来～')">忘记密码？</a>
      </div>

      <button class="btn-login" type="submit">🚀 进入动画小镇</button>
    </form>

    <div class="divider"><span>或者用卡通朋友登入</span></div>
    <div class="socials">
      <button title="微信" @click="toast('微信小恐龙带你飞～')">🐉</button>
      <button title="QQ" @click="toast('QQ 企鹅来啦～')">🐧</button>
      <button title="Apple" @click="toast('苹果精灵已就位～')">🍎</button>
    </div>

    <p class="signup">还没有账号？ <a href="#" @click.prevent="emit('go-register')">免费加入小镇 ✨</a></p>
  </main>

  <Toast />
</template>

<style scoped>
.mode { display: flex; gap: 8px; background: #f1ecff; border-radius: 18px; padding: 6px; margin: 0 auto 20px; width: fit-content; }
.mode button { border: none; background: transparent; font-family: var(--font); cursor: pointer; padding: 9px 18px; border-radius: 14px; font-size: 15px; color: #7a6aa0; transition: .25s; }
.mode button.active { background: #fff; color: var(--pink-d); box-shadow: 0 4px 12px var(--shadow); transform: scale(1.04); }

.field { position: relative; margin-bottom: 16px; text-align: left; }
.field label { display: block; font-size: 14px; margin: 0 0 6px 6px; color: #6a5a8a; }
.field .box { display: flex; align-items: center; gap: 8px; background: #fbf7ff; border: 3px solid #ece3ff; border-radius: 18px; padding: 12px 14px; transition: .25s; }
.field .box:focus-within { border-color: var(--pink); background: #fff; box-shadow: 0 0 0 4px rgba(255, 143, 196, .18); }
.field .emoji { font-size: 20px; }
.field input { border: none; outline: none; background: transparent; flex: 1; font-family: var(--font); font-size: 16px; color: var(--ink); }
.field input::placeholder { color: #bcb0d6; }
.toggle-pw { cursor: pointer; user-select: none; font-size: 18px; opacity: .7; border: none; background: none; }

.row { display: flex; align-items: center; justify-content: space-between; font-size: 13px; margin: 2px 4px 20px; }
.remember { display: flex; align-items: center; gap: 6px; cursor: pointer; color: #7a6aa0; }
.remember input { width: 16px; height: 16px; accent-color: var(--pink); }
.link { color: var(--blue); text-decoration: none; }
.link:hover { text-decoration: underline; }

.btn-login { width: 100%; border: none; cursor: pointer; font-family: var(--font); padding: 16px; border-radius: 20px; font-size: 20px; color: #fff;
  background: linear-gradient(120deg, var(--pink), var(--pink-d)); box-shadow: 0 10px 22px rgba(255, 95, 168, .4); transition: transform .12s, box-shadow .2s; position: relative; overflow: hidden; }
.btn-login:hover { transform: translateY(-2px); box-shadow: 0 14px 28px rgba(255, 95, 168, .5); }
.btn-login:active { transform: scale(.96); }
.btn-login::after { content: ""; position: absolute; top: 0; left: -60%; width: 40%; height: 100%; background: linear-gradient(120deg, transparent, rgba(255,255,255,.6), transparent); transform: skewX(-20deg); animation: shine 3.5s ease-in-out infinite; }
@keyframes shine { 0%, 60% { left: -60%; } 100% { left: 130%; } }

.divider { margin: 20px 0 14px; font-size: 13px; color: #b3a6cf; position: relative; }
.divider span { background: var(--card); padding: 0 12px; position: relative; z-index: 1; }
.divider::before { content: ""; position: absolute; top: 50%; left: 0; right: 0; height: 1px; background: #ece3ff; }
.socials { display: flex; justify-content: center; gap: 14px; }
.socials button { width: 54px; height: 54px; border-radius: 50%; border: 3px solid #fff; cursor: pointer; font-size: 24px; background: #fbf7ff; box-shadow: 0 6px 14px var(--shadow); transition: .2s; }
.socials button:hover { transform: translateY(-4px) rotate(-6deg); }

.signup { margin-top: 18px; font-size: 14px; color: #7a6aa0; }
.signup a { color: var(--pink-d); font-weight: bold; text-decoration: none; }
</style>
