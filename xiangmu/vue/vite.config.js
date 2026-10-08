import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    host: true,
    port: 5173,
    // 开发环境把 /api 代理到 Spring Boot 后端（默认 8081），
    // 这样前端无需处理跨域，请求路径与后端 @RequestMapping("/api/user") 对齐。
    proxy: {
      '/api': {
        target: 'http://localhost:8081',
        changeOrigin: true
      }
    }
  }
})
