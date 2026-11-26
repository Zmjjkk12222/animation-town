<script setup>
/**
 * 用户个人页（抽屉式弹层）
 * ---------------------------------------------------------------
 * 点击顶栏/侧栏的头像或昵称打开，包含：
 *   1. 头像展示 + 上传更换（格式/大小校验、失败提示）
 *   2. 修改密码（校验旧密码，成功后需重新登录）
 *   3. 退出登录（从首页迁移至此）
 * 回显规则：avatarUrl（图片）→ avatar（emoji）→ 默认占位 🦄
 */
import { ref, computed } from 'vue'
import AvatarImg from './AvatarImg.vue'
import Toast from './Toast.vue'
import { useToast } from '../composables/feedback.js'
import { uploadAvatar, changePassword } from '../api/auth.js'

const props = defineProps({
  user: { type: Object, default: null }
})
const emit = defineEmits(['close', 'logout', 'updated'])

const { toast } = useToast()

// ============================================================
// 头像上传
// ============================================================
const fileInput = ref(null)
const uploading = ref(false)
const preview = ref('') // 本地预览（blob URL）

const ALLOWED = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
const MAX_SIZE = 2 * 1024 * 1024 // 2MB

const currentAvatarUrl = computed(() => (props.user && props.user.avatarUrl) || '')
const currentAvatarEmoji = computed(() => (props.user && props.user.avatar) || '')

function pickFile() {
  fileInput.value && fileInput.value.click()
}

function onFileChange(e) {
  const file = e.target.files && e.target.files[0]
  e.target.value = '' // 允许重复选择同一文件
  if (!file) return
  // 前端校验：格式
  if (!ALLOWED.includes(file.type)) {
    toast('只支持 jpg / png / gif / webp 格式的图片哦～', { type: 'err' })
    return
  }
  // 前端校验：大小
  if (file.size > MAX_SIZE) {
    toast('图片太大啦，请选择 2MB 以内的图片～', { type: 'err' })
    return
  }
  doUpload(file)
}

async function doUpload(file) {
  uploading.value = true
  try {
    // 先本地预览，让用户即时看到效果
    if (preview.value) URL.revokeObjectURL(preview.value)
    preview.value = URL.createObjectURL(file)
    const updated = await uploadAvatar(file, props.user.id)
    // 用后端返回的最新用户信息同步回父组件
    emit('updated', updated)
    toast('头像更新成功～ 🎉')
  } catch (err) {
    toast(err.message || '头像上传失败，请稍后再试～', { type: 'err' })
    if (preview.value) { URL.revokeObjectURL(preview.value); preview.value = '' }
  } finally {
    uploading.value = false
  }
}

// ============================================================
// 修改密码
// ============================================================
const oldPwd = ref('')
const newPwd = ref('')
const confirmPwd = ref('')
const pwdShow = ref(false)
const changing = ref(false)

async function doChangePassword() {
  if (!oldPwd.value) { toast('请填写当前密码～', { type: 'err' }); return }
  if (newPwd.value.length < 6) { toast('新密码至少 6 位～', { type: 'err' }); return }
  if (newPwd.value !== confirmPwd.value) { toast('两次输入的新密码不一致～', { type: 'err' }); return }
  changing.value = true
  try {
    await changePassword({
      userId: props.user.id,
      oldPassword: oldPwd.value,
      newPassword: newPwd.value
    })
    toast('密码修改成功，请重新登录～ 🔐')
    oldPwd.value = newPwd.value = confirmPwd.value = ''
    // 改密后退出登录，引导用户用新密码重新登录
    setTimeout(() => emit('logout'), 900)
  } catch (err) {
    toast(err.message || '修改失败，请稍后再试～', { type: 'err' })
  } finally {
    changing.value = false
  }
}

function doLogout() {
  emit('logout')
}
</script>

<template>
  <Teleport to="body">
    <div class="up-mask" @click.self="emit('close')">
      <section class="up-panel" role="dialog" aria-label="个人中心">
        <header class="up-head">
          <b>个人中心</b>
          <button class="up-x" type="button" aria-label="关闭" @click="emit('close')">✕</button>
        </header>

        <!-- 头像区 -->
        <div class="up-avatar-block">
          <button class="up-ava" type="button" :title="'点击更换头像'" @click="pickFile" :disabled="uploading">
            <AvatarImg
              :avatar-url="preview || currentAvatarUrl"
              :avatar="currentAvatarEmoji"
              fallback="🦄"
            />
            <span class="up-ava-badge">{{ uploading ? '…' : '📷' }}</span>
          </button>
          <p class="up-tip">{{ uploading ? '正在上传…' : '点击头像上传图片（2MB 内，jpg/png/gif/webp）' }}</p>
          <input
            ref="fileInput" type="file" accept="image/jpeg,image/png,image/gif,image/webp"
            style="display: none" @change="onFileChange"
          />
        </div>

        <!-- 基本信息 -->
        <div class="up-info">
          <div class="up-row">
            <span class="up-k">昵称</span>
            <span class="up-v">{{ user.nickname || '小探险家' }}</span>
          </div>
          <div class="up-row">
            <span class="up-k">身份</span>
            <span class="up-v">{{ user.role === 'parent' ? '家长' : '小朋友' }}</span>
          </div>
        </div>

        <!-- 修改密码 -->
        <div class="up-sec">
          <h3 class="up-h">🔐 修改密码</h3>
          <div class="up-field">
            <label>当前密码</label>
            <input v-model="oldPwd" :type="pwdShow ? 'text' : 'password'" placeholder="请输入当前密码" />
          </div>
          <div class="up-field">
            <label>新密码</label>
            <input v-model="newPwd" :type="pwdShow ? 'text' : 'password'" placeholder="至少 6 位" />
          </div>
          <div class="up-field">
            <label>确认新密码</label>
            <input v-model="confirmPwd" :type="pwdShow ? 'text' : 'password'" placeholder="再输入一次" />
          </div>
          <label class="up-show">
            <input type="checkbox" v-model="pwdShow" /> 显示密码
          </label>
          <button class="up-btn" type="button" :disabled="changing" @click="doChangePassword">
            {{ changing ? '提交中…' : '确认修改密码' }}
          </button>
        </div>

        <!-- 退出登录 -->
        <button class="up-logout" type="button" @click="doLogout">退出登录</button>
      </section>
    </div>
  </Teleport>
  <Toast />
</template>

<style scoped>
.up-mask {
  position: fixed; inset: 0; z-index: 200;
  background: rgba(20, 16, 40, .32);
  display: flex; justify-content: flex-end;
}
.up-panel {
  width: 340px; max-width: 88vw; height: 100%;
  background: var(--card, #fff); box-shadow: -12px 0 32px rgba(40, 30, 80, .18);
  display: flex; flex-direction: column; overflow-y: auto;
  padding: 18px 20px; box-sizing: border-box;
}
.up-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; }
.up-head b { font-size: 16px; color: var(--ink, #2c2a3a); }
.up-x {
  border: none; cursor: pointer; width: 30px; height: 30px; border-radius: 50%;
  background: #f2f0f8; color: #7a7192; font-size: 14px;
}
.up-x:hover { background: #e8e4f4; }

.up-avatar-block { text-align: center; margin: 8px 0 14px; }
.up-ava {
  position: relative; width: 96px; height: 96px; border-radius: 50%;
  border: 3px solid #ffe3f0; cursor: pointer; padding: 0; overflow: hidden;
  background: #f0f3ff; margin: 0 auto;
}
.up-ava-badge {
  position: absolute; right: -2px; bottom: 2px; width: 30px; height: 30px;
  border-radius: 50%; background: linear-gradient(120deg, #ff6fa5, #ff8fc4);
  color: #fff; font-size: 14px; display: flex; align-items: center; justify-content: center;
  box-shadow: 0 2px 8px rgba(255, 111, 165, .4);
}
.up-tip { font-size: 12px; color: var(--ink-faint, #9a94ad); margin-top: 8px; }

.up-info { background: #f7f6fb; border-radius: 12px; padding: 10px 14px; margin-bottom: 14px; }
.up-row { display: flex; justify-content: space-between; padding: 5px 0; font-size: 14px; }
.up-k { color: var(--ink-faint, #9a94ad); }
.up-v { color: var(--ink, #2c2a3a); font-weight: 500; }

.up-sec { margin-bottom: 14px; }
.up-h { font-size: 14px; color: var(--ink, #2c2a3a); margin: 0 0 10px; }
.up-field { margin-bottom: 10px; }
.up-field label { display: block; font-size: 12px; color: var(--ink-faint, #9a94ad); margin-bottom: 4px; }
.up-field input {
  width: 100%; box-sizing: border-box; padding: 10px 12px; border-radius: 10px;
  border: 1px solid #e6e2f0; font-size: 14px; outline: none; font-family: inherit;
}
.up-field input:focus { border-color: #ff8fc4; }
.up-show { display: flex; align-items: center; gap: 6px; font-size: 12px; color: #7a7192; margin: 4px 0 12px; }
.up-btn {
  width: 100%; border: none; cursor: pointer; padding: 12px; border-radius: 12px;
  font-size: 14px; color: #fff; font-family: inherit;
  background: linear-gradient(120deg, #6fb8ff, #7fc4ff);
  box-shadow: 0 4px 12px rgba(111, 184, 255, .35);
}
.up-btn:disabled { opacity: .6; cursor: default; }
.up-logout {
  margin-top: auto; width: 100%; border: 1px solid #ffe0e9; cursor: pointer;
  padding: 12px; border-radius: 12px; font-size: 14px; color: #e07a9a;
  background: #fff5f8; font-family: inherit; transition: background .15s;
}
.up-logout:hover { background: #ffe9f0; }
</style>
