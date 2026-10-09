<script setup>
import { ref, onMounted } from 'vue'
import BgDecor from './components/BgDecor.vue'
import LoginPage from './components/LoginPage.vue'
import RegisterPage from './components/RegisterPage.vue'
import TownPage from './components/TownPage.vue'

// 视图：'login' | 'register' | 'town'
const view = ref('login')
// 当前登录用户（后端返回、已脱敏）
const currentUser = ref(null)

onMounted(() => {
  // 刷新页面后保持登录态
  const saved = localStorage.getItem('town_user')
  if (saved) {
    try {
      currentUser.value = JSON.parse(saved)
      view.value = 'town'
    } catch (e) {
      localStorage.removeItem('town_user')
    }
  }
})

function goRegister() { view.value = 'register' }
function goLogin() { view.value = 'login' }

// 登录 / 注册成功后由子组件抛出，App 保存用户并切换到小镇主页
function onAuthed(user) {
  currentUser.value = user
  localStorage.setItem('town_user', JSON.stringify(user))
  view.value = 'town'
}

function onLogout() {
  currentUser.value = null
  localStorage.removeItem('town_user')
  view.value = 'login'
}
</script>

<template>
  <BgDecor />
  <LoginPage v-if="view === 'login'" @go-register="goRegister" @authed="onAuthed" />
  <RegisterPage v-else-if="view === 'register'" @go-login="goLogin" @authed="onAuthed" />
  <TownPage v-else :user="currentUser" @logout="onLogout" />
</template>
