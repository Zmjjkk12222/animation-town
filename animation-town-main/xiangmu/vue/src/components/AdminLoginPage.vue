<script setup>
import { ref } from 'vue'
import Toast from './Toast.vue'
import { useToast } from '../composables/feedback.js'
import { adminLogin, setAdminSession } from '../api/admin.js'

const emit = defineEmits(['authed', 'back'])
const { toast } = useToast()

const username = ref('')
const loading = ref(false)
const shaking = ref(false)

function failFeedback(msg) {
  toast(msg, { type: 'err' })
  shaking.value = true
  setTimeout(() => { shaking.value = false }, 600)
}

// 后台账号「朵朵」为免密登录，只需填写账号即可进入
async function doLogin(e) {
  e.preventDefault()
  if (!username.value.trim()) {
    failFeedback('请输入后台管理账号')
    return
  }
  loading.value = true
  try {
    const data = await adminLogin({ username: username.value.trim() })
    // 保存登录态（token + 管理员信息）
    setAdminSession(data.token, data.admin)
    toast('登录成功，正在进入后台…')
    emit('authed', data.admin)
  } catch (err) {
    failFeedback(err.message || '登录失败，请稍后再试～')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <main class="card admin-card" :class="{ shake: shaking }">
    <div class="badge">🛡️</div>

    <h1 class="title">后台管理系统</h1>
    <p class="subtitle">动画小镇 · 数据管理入口</p>

    <form @submit="doLogin">
      <div class="field">
        <label>后台管理账号</label>
        <div class="box">
          <span class="emoji">👤</span>
          <input v-model="username" type="text" placeholder="请输入后台管理账号" autocomplete="username" />
        </div>
      </div>

      <button class="btn-login" type="submit" :disabled="loading">
        <span v-if="loading" class="spinner">✨</span>{{ loading ? '登录中…' : '🚀 进入后台' }}
      </button>
    </form>

    <p class="tip">仅「朵朵」账号可进入后台，无需输入密码</p>

    <p class="back"><a href="#" @click.prevent="emit('back')">← 返回动画小镇</a></p>
  </main>

  <Toast />
</template>

<style scoped>
.badge {
  width: 76px; height: 76px; margin: 4px auto 6px;
  display: flex; align-items: center; justify-content: center;
  font-size: 38px; border-radius: 50%;
  background: linear-gradient(140deg, #e8f0ff, #d7e4ff);
  box-shadow: 0 8px 18px var(--shadow);
}
.admin-card::before {
  background: radial-gradient(circle at 10px 0, var(--blue) 9px, transparent 10px) repeat-x;
  background-size: 20px 20px;
}

.field { position: relative; margin-bottom: 16px; text-align: left; }
.field label { display: block; font-size: 14px; margin: 0 0 6px 6px; color: #6a5a8a; }
.field .box { display: flex; align-items: center; gap: 8px; background: #fbf7ff; border: 3px solid #ece3ff; border-radius: 18px; padding: 12px 14px; transition: .25s; }
.field .box:focus-within { border-color: var(--blue); background: #fff; box-shadow: 0 0 0 4px rgba(111, 184, 255, .18); }
.field .emoji { font-size: 20px; }
.field input { border: none; outline: none; background: transparent; flex: 1; font-family: var(--font); font-size: 16px; color: var(--ink); }
.field input::placeholder { color: #bcb0d6; }
.toggle-pw { cursor: pointer; user-select: none; font-size: 18px; opacity: .7; border: none; background: none; }

.btn-login {
  width: 100%; border: none; cursor: pointer; font-family: var(--font);
  padding: 16px; border-radius: 20px; font-size: 20px; color: #fff;
  background: linear-gradient(120deg, var(--blue), #8f7bff);
  box-shadow: 0 10px 22px rgba(111, 184, 255, .4);
  transition: transform .12s, box-shadow .2s, filter .2s;
  position: relative; overflow: hidden;
}
.btn-login:hover:not(:disabled) { transform: translateY(-2px); box-shadow: 0 14px 28px rgba(111, 184, 255, .5); }
.btn-login:active:not(:disabled) { transform: scale(.96); }
.btn-login:disabled { filter: saturate(.6) brightness(.94); cursor: wait; }

.tip { margin: 14px 0 0; font-size: 12px; color: #a89bc4; }

.back { margin-top: 14px; font-size: 14px; color: #7a6aa0; }
.back a { color: var(--blue); font-weight: bold; text-decoration: none; }
.back a:hover { text-decoration: underline; }
</style>
