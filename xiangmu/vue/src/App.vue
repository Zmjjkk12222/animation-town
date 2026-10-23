<script setup>
import { ref, onMounted } from 'vue'
import BgDecor from './components/BgDecor.vue'
import LoginPage from './components/LoginPage.vue'
import RegisterPage from './components/RegisterPage.vue'
import HomePage from './components/HomePage.vue'
import AdminLoginPage from './components/AdminLoginPage.vue'
import AdminPage from './components/AdminPage.vue'

// 视图：'login' | 'register' | 'town' | 'admin-login' | 'admin'
const view = ref('login')
// 当前登录用户（后端返回、已脱敏）
const currentUser = ref(null)
// 后台管理员信息（token 存在 sessionStorage，由 api/admin.js 管理）
const adminInfo = ref(null)

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

// 登录 / 注册成功后由子组件抛出，App 保存用户并切换到首页
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

// ============================================================
// 后台管理系统
// ============================================================

// 首页导航栏点击「后台管理系统」-> 进入后台登录页
function goAdminLogin() { view.value = 'admin-login' }

// 后台登录成功 -> 进入管理界面
function onAdminAuthed(admin) {
  adminInfo.value = admin
  view.value = 'admin'
}

// 返回小镇（点击「返回小镇」或退出后台登录）
function onAdminBack() {
  adminInfo.value = null
  // 小镇登录态还在就回首页，否则回小镇登录页
  view.value = currentUser.value ? 'town' : 'login'
}

// 后台登录态失效（后端返回 401）
function onAdminExpired() {
  adminInfo.value = null
  view.value = 'admin-login'
}
</script>

<template>
  <BgDecor />
  <LoginPage v-if="view === 'login'" @go-register="goRegister" @authed="onAuthed" />
  <RegisterPage v-else-if="view === 'register'" @go-login="goLogin" @authed="onAuthed" />
  <HomePage v-else-if="view === 'town'" :user="currentUser" @logout="onLogout" @go-admin="goAdminLogin" />
  <AdminLoginPage v-else-if="view === 'admin-login'" @authed="onAdminAuthed" @back="onAdminBack" />
  <AdminPage v-else-if="view === 'admin'" :admin="adminInfo" @back="onAdminBack" @expired="onAdminExpired" />
</template>
