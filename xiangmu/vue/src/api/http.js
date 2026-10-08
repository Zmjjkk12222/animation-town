import axios from 'axios'

// 统一的 axios 实例：dev 阶段请求走 vite 代理 /api -> http://localhost:8081
export const http = axios.create({
  baseURL: '/api',
  timeout: 10000
})

// 把"连不上后端"这类网络错误翻译成看得懂的提示，方便定位（如后端未启动 / 端口不对）
http.interceptors.response.use(
  (res) => res,
  (err) => {
    if (!err.response) {
      throw new Error('连不上后端服务，请确认后端已在 8081 端口启动 🚀')
    }
    return Promise.reject(err)
  }
)

// 拆包后端统一返回结构 { code, message, data }：code=200 视为成功，返回 data；否则抛后端 message
export function unwrap(res) {
  const result = res.data
  if (result && result.code === 200) {
    return result.data
  }
  throw new Error((result && result.message) || '请求失败，请稍后再试～')
}
