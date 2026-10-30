import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    // 监听所有网卡(true 等价于 0.0.0.0)，本地 localhost 与局域网其他设备均可访问，
    // 不再依赖写死的 LAN IP（原 192.168.68.59 在 IP 变化/换网络时会起不来）。
    host: true,
    port: 5173,
    // 开发环境把 /api 代理到 Spring Boot 后端（8081）。
    // 后端现已监听 0.0.0.0，用 localhost 最稳妥，不受本机 IP 变化影响。
    proxy: {
      '/api': {
        target: 'http://localhost:8081',
        changeOrigin: true
      }
    }
  }
})
