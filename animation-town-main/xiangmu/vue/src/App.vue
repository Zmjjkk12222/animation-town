<script setup>
import { ref, onMounted, watch } from 'vue'
import BgDecor from './components/BgDecor.vue'
import LoginPage from './components/LoginPage.vue'
import RegisterPage from './components/RegisterPage.vue'
import HomePage from './components/HomePage.vue'
import ParentHomePage from './components/ParentHomePage.vue'
import AdminLoginPage from './components/AdminLoginPage.vue'
import AdminPage from './components/AdminPage.vue'
import InviteBar from './components/InviteBar.vue'
import { adminLogin, setAdminSession } from './api/admin.js'
import { connect as connectRealtime, close as closeRealtime, setUnread } from './net/realtime.js'
import { gameEntryTick } from './composables/gameEntry.js'
import { getUnread } from './api/message.js'

// 唯一可进入后台的账号，与后端 AdminServiceImpl.SUPER_ADMIN_USERNAME 保持一致
const BACKEND_ADMIN_NAME = '朵朵'

// 视图：'login' | 'register' | 'town' | 'parent-home' | 'admin-login' | 'admin'
const view = ref('login')
// 当前登录用户（后端返回、已脱敏）
const currentUser = ref(null)
// 后台管理员信息（token 存在 sessionStorage，由 api/admin.js 管理）
const adminInfo = ref(null)

onMounted(() => {
  // 刷新页面后保持登录态：家长回到家长首页，小朋友回到儿童首页
  // 优先读 sessionStorage（每个标签页独立，支持同机多账号）；
  // 兼容旧版存 localStorage 的数据，回退读取一次
  const saved = sessionStorage.getItem('town_user') || localStorage.getItem('town_user')
  if (saved) {
    try {
      const u = JSON.parse(saved)
      currentUser.value = u
      view.value = u.role === 'parent' ? 'parent-home' : 'town'
      startRealtime(u)
    } catch (e) {
      sessionStorage.removeItem('town_user')
      localStorage.removeItem('town_user')
    }
  }
})

// ============================================================
// 全站实时连接（好友聊天 + 联机邀请的唯一一条 /ws/game）
// ------------------------------------------------------------
// 登录后立刻建连，这样「在线状态」表示的是「打开了小镇」，
// 而不是「正停在游戏页」；离线好友的未读数在登录时补拉一次。
// ============================================================
function startRealtime(u) {
  if (!u || !u.id) return
  connectRealtime(u.id)
  getUnread(u.id)
    .then((map) => setUnread(map || {}))
    .catch(() => {})
}

function goRegister() { view.value = 'register' }
function goLogin() { view.value = 'login' }

// 登录 / 注册成功后由子组件抛出，App 保存用户并切换到对应首页
// 儿童(role=kid) -> 儿童首页；家长(role=parent) -> 家长首页
function onAuthed(user) {
  currentUser.value = user
  sessionStorage.setItem('town_user', JSON.stringify(user))
  localStorage.removeItem('town_user') // 清理旧版残留，避免下次误读
  view.value = user && user.role === 'parent' ? 'parent-home' : 'town'
  startRealtime(user)
}

function onLogout() {
  // 退出登录只断开当前账号的连接，不影响其他标签页里仍在线的账号
  const id = currentUser.value && currentUser.value.id
  if (id) closeRealtime(id)
  currentUser.value = null
  sessionStorage.removeItem('town_user')
  localStorage.removeItem('town_user')
  view.value = 'login'
}

// 接受联机邀请后：如果当时不在首页（例如正在后台管理页），先切回首页，
// 由首页把 Tab 切到「亲子游戏乐园」并把游戏弹窗打开。
watch(gameEntryTick, () => {
  if (!currentUser.value) return
  if (view.value !== 'town' && view.value !== 'parent-home') {
    view.value = currentUser.value.role === 'parent' ? 'parent-home' : 'town'
  }
})

// 头像等信息更新后，刷新当前用户（响应式回流到所有子组件，头像即时回显）
function onUserUpdated(updated) {
  if (!updated) return
  currentUser.value = updated
  sessionStorage.setItem('town_user', JSON.stringify(updated))
}

// ============================================================
// 后台管理系统
// ============================================================

// 首页导航栏点击「后台管理系统」
// 若当前登录的正是「朵朵」，直接免密进入后台；否则进入后台登录页要求输入账号
async function goAdminLogin() {
  if (currentUser.value && currentUser.value.nickname === BACKEND_ADMIN_NAME) {
    try {
      const data = await adminLogin({ username: BACKEND_ADMIN_NAME })
      setAdminSession(data.token, data.admin)
      adminInfo.value = data.admin
      view.value = 'admin'
      return
    } catch (e) {
      // 自动进入失败时回退到登录页，不影响用户手动登录
    }
  }
  view.value = 'admin-login'
}

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
  <HomePage v-else-if="view === 'town'" :user="currentUser" @logout="onLogout" @go-admin="goAdminLogin" @update-user="onUserUpdated" />
  <ParentHomePage v-else-if="view === 'parent-home'" :user="currentUser" @logout="onLogout" @go-admin="goAdminLogin" @update-user="onUserUpdated" />
  <AdminLoginPage v-else-if="view === 'admin-login'" @authed="onAdminAuthed" @back="onAdminBack" />
  <AdminPage v-else-if="view === 'admin'" :admin="adminInfo" @back="onAdminBack" @expired="onAdminExpired" />

  <!-- 全局联机邀请条 + 实时连接兜底提示（任意页面都能收到邀请） -->
  <InviteBar />
</template>
