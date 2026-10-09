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
