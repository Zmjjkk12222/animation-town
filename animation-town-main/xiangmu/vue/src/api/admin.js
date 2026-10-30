import { http, unwrap } from './http'

// ============================================================
// 后台管理系统接口
// 登录后后端返回 token，后续管理类接口都需在请求头带上 X-Admin-Token
// token 存在 sessionStorage：关闭浏览器标签即失效，比 localStorage 更适合后台场景
// ============================================================

const TOKEN_KEY = 'town_admin_token'
const ADMIN_KEY = 'town_admin_info'

export function getAdminToken() {
  return sessionStorage.getItem(TOKEN_KEY) || ''
}

export function setAdminSession(token, admin) {
  sessionStorage.setItem(TOKEN_KEY, token)
  sessionStorage.setItem(ADMIN_KEY, JSON.stringify(admin || {}))
}

export function getAdminInfo() {
  const raw = sessionStorage.getItem(ADMIN_KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw)
  } catch (e) {
    return null
  }
}

export function clearAdminSession() {
  sessionStorage.removeItem(TOKEN_KEY)
  sessionStorage.removeItem(ADMIN_KEY)
}

/** 统一带上登录态请求头 */
function authHeaders() {
  return { 'X-Admin-Token': getAdminToken() }
}

// ---------- 登录 / 退出 ----------

/** 管理员登录，返回 { token, admin }（不含注册，后台账号由系统预置） */
export async function adminLogin({ username, password }) {
  return unwrap(await http.post('/admin/login', { username, password }))
}

/** 退出登录：通知后端清除 token，并清掉本地会话 */
export async function adminLogout() {
  try {
    await http.post('/admin/logout', {}, { headers: authHeaders() })
  } catch (e) {
    // 退出失败也要清本地，避免卡在失效的登录态里
  }
  clearAdminSession()
}

// ---------- 动画数据管理 ----------

export async function adminListAnimations() {
  return unwrap(await http.get('/admin/animations', { headers: authHeaders() }))
}

export async function adminCreateAnimation(animation) {
  return unwrap(await http.post('/admin/animation', animation, { headers: authHeaders() }))
}

export async function adminUpdateAnimation(animation) {
  return unwrap(await http.put('/admin/animation', animation, { headers: authHeaders() }))
}

export async function adminDeleteAnimation(id) {
  return unwrap(await http.delete(`/admin/animation/${id}`, { headers: authHeaders() }))
}

// ---------- 用户管理 ----------

export async function adminListUsers() {
  return unwrap(await http.get('/admin/users', { headers: authHeaders() }))
}

export async function adminUpdateUser(user) {
  return unwrap(await http.put('/admin/user', user, { headers: authHeaders() }))
}

export async function adminDeleteUser(id) {
  return unwrap(await http.delete(`/admin/user/${id}`, { headers: authHeaders() }))
}
