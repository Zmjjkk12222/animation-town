import { http, unwrap } from './http.js'

/**
 * 请求后端启动随项目附带的奶蛙桌宠。
 * 浏览器不能直接启动本地 exe，由 Spring Boot 按固定路径拉起。
 */
export function startNaiwa() {
  return http.post('/naiwa/start').then(unwrap)
}
