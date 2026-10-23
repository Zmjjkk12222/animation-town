<script setup>
import { ref, computed, onMounted } from 'vue'
import Toast from './Toast.vue'
import { useToast } from '../composables/feedback.js'
import {
  adminListAnimations, adminCreateAnimation, adminUpdateAnimation, adminDeleteAnimation,
  adminListUsers, adminUpdateUser, adminDeleteUser,
  adminLogout, clearAdminSession
} from '../api/admin.js'

const props = defineProps({
  admin: { type: Object, default: () => ({}) }
})
const emit = defineEmits(['back', 'expired'])
const { toast } = useToast()

const tab = ref('anim')   // 'anim' 动画管理 | 'user' 用户管理

/** 统一错误处理：登录失效则清会话并回到登录页 */
function handleErr(err) {
  const msg = (err && err.message) || '请求失败，请稍后再试'
  if (msg.includes('登录已失效')) {
    clearAdminSession()
    emit('expired')
    return
  }
  toast(msg, { type: 'err' })
}

// ============================================================
// 动画数据管理
// ============================================================
const CATS = ['冒险', '治愈', '科普', '推理', '科幻', '音乐', '科学', '创意', '美食', '语文',
  '搞笑', '友情', '童话', '自然', '运动', '历史', '动物', '恐龙', '艺术']

const anims = ref([])
const animLoading = ref(false)
const animKw = ref('')

const animFiltered = computed(() => {
  const k = animKw.value.trim().toLowerCase()
  if (!k) return anims.value
  return anims.value.filter(a =>
    (a.title || '').toLowerCase().includes(k) || (a.category || '').toLowerCase().includes(k)
  )
})

async function loadAnims() {
  animLoading.value = true
  try {
    anims.value = await adminListAnimations()
  } catch (err) {
    handleErr(err)
  } finally {
    animLoading.value = false
  }
}

// 新增 / 编辑共用一个弹窗表单
const animForm = ref(null)      // null 表示关闭
const animSaving = ref(false)

function openAnimCreate() {
  animForm.value = { id: null, title: '', cover: '🎬', category: '', description: '', hot: 50, playUrl: '' }
}

function openAnimEdit(a) {
  animForm.value = { ...a }
}

async function saveAnim() {
  const f = animForm.value
  if (!f.title.trim()) { toast('动画标题不能为空', { type: 'err' }); return }
  if (!f.category.toString().trim()) { toast('分类不能为空', { type: 'err' }); return }
  animSaving.value = true
  try {
    if (f.id) {
      await adminUpdateAnimation(f)
      toast('保存成功')
    } else {
      await adminCreateAnimation(f)
      toast('新增成功')
    }
    animForm.value = null
    await loadAnims()
  } catch (err) {
    handleErr(err)
  } finally {
    animSaving.value = false
  }
}

async function removeAnim(a) {
  if (!window.confirm(`确定删除动画《${a.title}》吗？删除后首页将不再展示。`)) return
  try {
    await adminDeleteAnimation(a.id)
    toast('已删除')
    await loadAnims()
  } catch (err) {
    handleErr(err)
  }
}

// ============================================================
// 用户管理
// ============================================================
const ROLE_LABEL = { kid: '小朋友', parent: '家长' }

const users = ref([])
const userLoading = ref(false)
const userKw = ref('')

const userFiltered = computed(() => {
  const k = userKw.value.trim().toLowerCase()
  if (!k) return users.value
  return users.value.filter(u =>
    (u.nickname || '').toLowerCase().includes(k) ||
    (ROLE_LABEL[u.role] || '').toLowerCase().includes(k) ||
    (u.phone || '').includes(k)
  )
})

async function loadUsers() {
  userLoading.value = true
  try {
    users.value = await adminListUsers()
  } catch (err) {
    handleErr(err)
  } finally {
    userLoading.value = false
  }
}

const userForm = ref(null)
const userSaving = ref(false)

function openUserEdit(u) {
  userForm.value = { ...u }
}

async function saveUser() {
  const f = userForm.value
  if (!f.nickname.trim()) { toast('昵称不能为空', { type: 'err' }); return }
  userSaving.value = true
  try {
    await adminUpdateUser(f)
    toast('保存成功')
    userForm.value = null
    await loadUsers()
  } catch (err) {
    handleErr(err)
  } finally {
    userSaving.value = false
  }
}

async function removeUser(u) {
  if (!window.confirm(`确定删除用户「${u.nickname}」吗？该账号将无法再登录。`)) return
  try {
    await adminDeleteUser(u.id)
    toast('已删除该账号')
    await loadUsers()
  } catch (err) {
    handleErr(err)
  }
}

// ============================================================
// 退出 / 初始化
// ============================================================
async function doLogout() {
  await adminLogout()
  emit('back')
}

function fmtTime(t) {
  return (t || '').replace('T', ' ').slice(0, 16)
}

onMounted(() => {
  loadAnims()
  loadUsers()
})
</script>

<template>
  <div class="admin">
    <!-- ============ 顶栏 ============ -->
    <header class="ahead">
      <div class="a-title">🛡️ 后台管理系统</div>

      <div class="a-tabs">
        <button :class="{ on: tab === 'anim' }" @click="tab = 'anim'">🎬 动画管理（{{ anims.length }}）</button>
        <button :class="{ on: tab === 'user' }" @click="tab = 'user'">👥 用户管理（{{ users.length }}）</button>
      </div>

      <div class="a-right">
        <span class="a-admin">👤 {{ admin.nickname || admin.username || 'admin' }}</span>
        <button class="a-btn ghost" @click="emit('back')">🏠 返回小镇</button>
        <button class="a-btn out" @click="doLogout">退出登录</button>
      </div>
    </header>

    <!-- ============ 内容区 ============ -->
    <main class="abody">
      <!-- 动画管理 -->
      <section v-if="tab === 'anim'">
        <div class="toolbar">
          <input v-model="animKw" class="a-input" placeholder="🔍 搜索标题 / 分类" />
          <button class="a-btn primary" @click="openAnimCreate">＋ 新增动画</button>
        </div>

        <p v-if="animLoading" class="a-empty">正在加载数据…</p>
        <p v-else-if="!animFiltered.length" class="a-empty">没有符合条件的动画</p>

        <div v-else class="twrap">
          <table class="atable">
            <thead>
              <tr>
                <th class="w-id">ID</th><th class="w-cov">封面</th><th>标题</th><th>分类</th>
                <th>简介</th><th class="w-hot">热度</th><th class="w-time">创建时间</th><th class="w-ops">操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="a in animFiltered" :key="a.id">
                <td class="dim">{{ a.id }}</td>
                <td class="cov">{{ a.cover }}</td>
                <td class="strong">{{ a.title }}</td>
                <td><span class="cat">{{ a.category }}</span></td>
                <td class="desc" :title="a.description">{{ a.description }}</td>
                <td class="dim">🔥{{ a.hot }}</td>
                <td class="dim">{{ fmtTime(a.createTime) }}</td>
                <td class="ops">
                  <button class="op edit" @click="openAnimEdit(a)">编辑</button>
                  <button class="op del" @click="removeAnim(a)">删除</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- 用户管理 -->
      <section v-else>
        <div class="toolbar">
          <input v-model="userKw" class="a-input" placeholder="🔍 搜索昵称 / 角色 / 手机号" />
          <button class="a-btn ghost" @click="loadUsers">↻ 刷新</button>
        </div>

        <p v-if="userLoading" class="a-empty">正在加载数据…</p>
        <p v-else-if="!userFiltered.length" class="a-empty">没有符合条件的用户</p>

        <div v-else class="twrap">
          <table class="atable">
            <thead>
              <tr>
                <th class="w-id">ID</th><th class="w-cov">头像</th><th>昵称</th><th>角色</th>
                <th>手机号</th><th class="w-time">注册时间</th><th class="w-ops">操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="u in userFiltered" :key="u.id">
                <td class="dim">{{ u.id }}</td>
                <td class="cov">{{ u.avatar || '🙂' }}</td>
                <td class="strong">{{ u.nickname }}</td>
                <td><span class="cat" :class="u.role === 'parent' ? 'p' : 'k'">{{ ROLE_LABEL[u.role] || u.role }}</span></td>
                <td class="dim">{{ u.phone || '—' }}</td>
                <td class="dim">{{ fmtTime(u.createTime) }}</td>
                <td class="ops">
                  <button class="op edit" @click="openUserEdit(u)">编辑</button>
                  <button class="op del" @click="removeUser(u)">删除</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </main>

    <!-- ============ 动画 新增/编辑 弹窗 ============ -->
    <div v-if="animForm" class="mask" @click.self="animForm = null">
      <div class="modal">
        <h3 class="m-h">{{ animForm.id ? '✏️ 编辑动画' : '✨ 新增动画' }}</h3>
        <div class="m-grid">
          <div class="m-field">
            <label>标题 *</label>
            <input v-model="animForm.title" placeholder="动画标题" />
          </div>
          <div class="m-field">
            <label>封面 emoji</label>
            <input v-model="animForm.cover" placeholder="例如 🌳" maxlength="4" />
          </div>
          <div class="m-field">
            <label>分类 *</label>
            <input v-model="animForm.category" list="admin-cat-list" placeholder="选择或输入分类" />
            <datalist id="admin-cat-list">
              <option v-for="c in CATS" :key="c" :value="c" />
            </datalist>
          </div>
          <div class="m-field">
            <label>热度（0-100）</label>
            <input v-model.number="animForm.hot" type="number" min="0" max="100" />
          </div>
          <div class="m-field wide">
            <label>简介</label>
            <textarea v-model="animForm.description" rows="2" placeholder="一句话介绍这部动画" />
          </div>
          <div class="m-field wide">
            <label>播放地址（外链，可留空）</label>
            <input v-model="animForm.playUrl" placeholder="https://…" />
          </div>
        </div>
        <div class="m-btns">
          <button class="a-btn ghost" @click="animForm = null">取消</button>
          <button class="a-btn primary" :disabled="animSaving" @click="saveAnim">{{ animSaving ? '保存中…' : '保存' }}</button>
        </div>
      </div>
    </div>

    <!-- ============ 用户 编辑弹窗 ============ -->
    <div v-if="userForm" class="mask" @click.self="userForm = null">
      <div class="modal">
        <h3 class="m-h">✏️ 编辑用户</h3>
        <div class="m-grid">
          <div class="m-field">
            <label>昵称 *</label>
            <input v-model="userForm.nickname" placeholder="用户昵称" />
          </div>
          <div class="m-field">
            <label>角色</label>
            <select v-model="userForm.role">
              <option value="kid">小朋友</option>
              <option value="parent">家长</option>
            </select>
          </div>
          <div class="m-field">
            <label>头像 emoji</label>
            <input v-model="userForm.avatar" placeholder="例如 🦄" maxlength="4" />
          </div>
          <div class="m-field">
            <label>手机号</label>
            <input v-model="userForm.phone" placeholder="家长手机号，可留空" />
          </div>
        </div>
        <p class="m-tip">💡 后台不提供修改密码，如需重置请联系开发</p>
        <div class="m-btns">
          <button class="a-btn ghost" @click="userForm = null">取消</button>
          <button class="a-btn primary" :disabled="userSaving" @click="saveUser">{{ userSaving ? '保存中…' : '保存' }}</button>
        </div>
      </div>
    </div>

    <Toast />
  </div>
</template>

<style scoped>
/* ============================================================
   后台管理：清爽的浅色管理风格（与小镇的可爱风稍作区分）
   ============================================================ */
.admin {
  min-height: 100vh;
  background: linear-gradient(165deg, #f2f6ff 0%, #eef2fb 60%, #f6f1ff 100%);
  color: #33395a;
}

/* 顶栏 */
.ahead {
  position: sticky; top: 0; z-index: 30;
  display: flex; align-items: center; gap: 18px; flex-wrap: wrap;
  padding: 14px 24px;
  background: rgba(255, 255, 255, .92);
  backdrop-filter: blur(8px);
  border-bottom: 1px solid rgba(120, 140, 190, .16);
}
.a-title { font-size: 18px; font-weight: bold; letter-spacing: 1px; }
.a-tabs { display: flex; gap: 8px; }
.a-tabs button {
  border: 1px solid rgba(120, 140, 190, .2); background: #fff; cursor: pointer;
  font-family: var(--font); font-size: 14px; color: #6a7396;
  padding: 8px 16px; border-radius: 999px; transition: .18s;
}
.a-tabs button:hover { color: #33395a; }
.a-tabs button.on {
  color: #fff; border-color: transparent; font-weight: bold;
  background: linear-gradient(120deg, #6fb8ff, #8f7bff);
  box-shadow: 0 6px 14px rgba(111, 184, 255, .35);
}
.a-right { display: flex; align-items: center; gap: 10px; margin-left: auto; }
.a-admin { font-size: 13px; color: #6a7396; }

/* 通用按钮 */
.a-btn {
  border: none; cursor: pointer; font-family: var(--font); font-size: 14px;
  padding: 9px 18px; border-radius: 12px; transition: .15s; flex-shrink: 0;
}
.a-btn.primary {
  color: #fff;
  background: linear-gradient(120deg, #6fb8ff, #8f7bff);
  box-shadow: 0 6px 14px rgba(111, 184, 255, .35);
}
.a-btn.primary:hover:not(:disabled) { transform: translateY(-1px); box-shadow: 0 9px 20px rgba(111, 184, 255, .45); }
.a-btn.primary:disabled { filter: saturate(.6); cursor: wait; }
.a-btn.ghost { color: #6a7396; background: #fff; border: 1px solid rgba(120, 140, 190, .25); }
.a-btn.ghost:hover { color: #33395a; background: #f3f6ff; }
.a-btn.out { color: #e0567f; background: #fff0f5; border: 1px solid rgba(224, 86, 127, .3); }
.a-btn.out:hover { background: #ffe3ec; }

/* 内容区 */
.abody { padding: 22px 24px 40px; }
.toolbar { display: flex; align-items: center; gap: 12px; margin-bottom: 16px; flex-wrap: wrap; }
.a-input {
  flex: 1; max-width: 380px;
  border: 1px solid rgba(120, 140, 190, .25); border-radius: 12px;
  padding: 10px 16px; font-family: var(--font); font-size: 14px;
  background: #fff; color: #33395a; outline: none; transition: .2s;
}
.a-input:focus { border-color: #6fb8ff; box-shadow: 0 0 0 3px rgba(111, 184, 255, .15); }

.a-empty {
  font-size: 14px; color: #6a7396; text-align: center;
  background: #fff; border: 1px dashed rgba(120, 140, 190, .3);
  border-radius: 16px; padding: 26px;
}

/* 表格 */
.twrap {
  background: #fff; border-radius: 18px; overflow: hidden;
  border: 1px solid rgba(120, 140, 190, .16);
  box-shadow: 0 10px 28px rgba(120, 140, 190, .12);
}
.atable { width: 100%; border-collapse: collapse; font-size: 13.5px; }
.atable thead tr { background: linear-gradient(120deg, #f0f5ff, #f5f0ff); }
.atable th {
  text-align: left; font-size: 12.5px; color: #6a7396; letter-spacing: 1px;
  padding: 12px 14px; white-space: nowrap;
}
.atable td { padding: 11px 14px; border-top: 1px solid rgba(120, 140, 190, .12); vertical-align: middle; }
.atable tbody tr { transition: background .15s; }
.atable tbody tr:hover { background: #f7faff; }

.w-id { width: 52px; }
.w-cov { width: 60px; }
.w-hot { width: 70px; }
.w-time { width: 130px; }
.w-ops { width: 130px; }
.cov { font-size: 22px; text-align: center; }
.dim { color: #98a0bd; }
.strong { font-weight: bold; color: #33395a; }
.desc {
  max-width: 260px; color: #6a7396;
  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}
.cat {
  display: inline-block; font-size: 12px; padding: 3px 10px; border-radius: 999px;
  background: #eef4ff; color: #5b86c9;
}
.cat.k { background: #eafaf3; color: #3aa981; }
.cat.p { background: #fff0e8; color: #e08a4f; }

.ops { white-space: nowrap; }
.op {
  border: none; cursor: pointer; font-family: var(--font); font-size: 12.5px;
  padding: 6px 12px; border-radius: 9px; margin-right: 6px; transition: .15s;
}
.op.edit { background: #eef4ff; color: #5b86c9; }
.op.edit:hover { background: #dbe9ff; }
.op.del { background: #fff0f5; color: #e0567f; }
.op.del:hover { background: #ffe3ec; }

/* 弹窗 */
.mask {
  position: fixed; inset: 0; z-index: 80;
  background: rgba(70, 80, 130, .4); backdrop-filter: blur(3px);
  display: flex; align-items: center; justify-content: center; padding: 18px;
  animation: mFade .2s ease both;
}
@keyframes mFade { from { opacity: 0; } to { opacity: 1; } }
.modal {
  width: min(94vw, 560px); max-height: 90vh; overflow-y: auto;
  background: #fff; border-radius: 20px; padding: 22px 24px;
  box-shadow: 0 30px 70px rgba(60, 70, 120, .35);
  animation: mUp .25s ease both;
  text-align: left;
}
@keyframes mUp { from { transform: translateY(16px); opacity: 0; } to { transform: none; opacity: 1; } }
.m-h { margin: 0 0 16px; font-size: 17px; color: #33395a; }
.m-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px 14px; }
.m-field { display: flex; flex-direction: column; gap: 6px; }
.m-field.wide { grid-column: 1 / -1; }
.m-field label { font-size: 12.5px; color: #6a7396; }
.m-field input, .m-field textarea, .m-field select {
  border: 1px solid rgba(120, 140, 190, .3); border-radius: 11px;
  padding: 9px 12px; font-family: var(--font); font-size: 14px;
  color: #33395a; background: #fbfcff; outline: none; transition: .18s;
}
.m-field textarea { resize: vertical; }
.m-field input:focus, .m-field textarea:focus, .m-field select:focus {
  border-color: #6fb8ff; background: #fff; box-shadow: 0 0 0 3px rgba(111, 184, 255, .15);
}
.m-tip { margin: 12px 0 0; font-size: 12px; color: #a6aec9; }
.m-btns { display: flex; justify-content: flex-end; gap: 10px; margin-top: 18px; }

/* 窄屏 */
@media (max-width: 760px) {
  .ahead { padding: 12px 14px; gap: 10px; }
  .a-admin { display: none; }
  .abody { padding: 14px 12px 30px; }
  .m-grid { grid-template-columns: 1fr; }
  .twrap { overflow-x: auto; }
  .atable { min-width: 640px; }
}
</style>
