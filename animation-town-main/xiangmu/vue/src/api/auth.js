import { http, unwrap } from './http'

/**
 * 校验昵称是否可用
 * @returns {Promise<boolean>} true 表示可用（未被占用）
 */
export async function checkNickname(nickname) {
  return unwrap(await http.get('/user/check', { params: { nickname } }))
}

/**
 * 注册新用户
 * @param {{nickname:string, role:string, avatar:string, phone:string, password:string}} payload
 * @returns {Promise<object>} 脱敏后的用户对象（不含密码）
 */
export async function registerUser(payload) {
  return unwrap(await http.post('/user/register', payload))
}

/**
 * 登录
 * @param {{nickname:string, password:string}} payload
 * @returns {Promise<object>} 脱敏后的用户对象（不含密码）
 */
export async function loginUser(payload) {
  return unwrap(await http.post('/user/login', payload))
}

/**
 * 上传头像（multipart/form-data）
 * @param {File} file 图片文件（jpg/png/gif/webp，<=2MB）
 * @param {number} userId 用户 id
 * @returns {Promise<object>} 更新后的用户对象（含 avatarUrl）
 */
export async function uploadAvatar(file, userId) {
  const fd = new FormData()
  fd.append('file', file)
  fd.append('userId', userId)
  return unwrap(await http.post('/user/avatar', fd, {
    headers: { 'Content-Type': 'multipart/form-data' }
  }))
}

/**
 * 修改密码
 * @param {{userId:number, oldPassword:string, newPassword:string}} payload
 * @returns {Promise<void>}
 */
export async function changePassword(payload) {
  return unwrap(await http.post('/user/password', payload))
}
