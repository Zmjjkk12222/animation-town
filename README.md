# 动画小镇 🎡

> 以动画为主题的儿童购物 App —— 登录 / 注册页面（Vue 3 + Vite）

「动画小镇」是一套面向儿童的卡通风格登录与注册界面，主打明亮配色、会互动的星星吉祥物、流畅动效，并内置儿童账号安全机制（双模式、密码强度、安全公约）。

---

## ✨ 功能特性

- 🎨 **动画 / 卡通主题**：渐变天空背景、漂浮云朵、脉动太阳、闪烁星星与上升气球
- 🐱 **会互动的吉祥物**：星星小怪兽，登录页打字时它会变成大笑表情
- 🧒👨‍👩‍👧 **双模式**：小朋友 / 爸爸妈妈，自动切换文案与字段（家长模式含手机号）
- 🔐 **儿童友好安全**：密码强度实时提示、再输一次校验、《安全公约》勾选
- 🎉 **趣味反馈**：登录 / 注册成功撒彩纸雨，操作缺失时气泡提示
- 📱 **响应式**：窄屏自适应，触控友好

---

## 📁 目录结构

```
动画小镇/
├── login.html            # 纯 HTML 版登录页（可直接双击打开）
├── register.html         # 纯 HTML 版注册页
├── README.md             # 本项目说明
└── vue/                  # Vue 3 + Vite 工程（推荐）
    ├── index.html
    ├── package.json
    ├── vite.config.js
    └── src/
        ├── main.js
        ├── style.css
        ├── App.vue                 # 根组件，login/register 视图切换
        ├── composables/
        │   └── feedback.js          # 全局提示气泡 + 撒彩纸动画
        └── components/
            ├── BgDecor.vue         # 背景装饰
            ├── Mascot.vue          # 星星吉祥物（login 黄 / register 绿）
            ├── Toast.vue           # 提示气泡
            ├── LoginPage.vue       # 登录页
            └── RegisterPage.vue    # 注册页
```

---

## 🚀 本地运行（Vue 版）

需要 Node.js 18+。

```bash
# 进入工程目录
cd vue

# 安装依赖
npm install

# 启动开发服务器（默认 http://localhost:5173）
npm run dev

# 生产构建（产物在 vue/dist）
npm run build

# 预览生产构建
npm run preview
```

> 不想装环境？直接双击根目录的 `login.html` / `register.html` 即可在浏览器体验（纯前端，无需构建）。

---

## 🔧 技术栈

- [Vue 3](https://vuejs.org/)（`<script setup>` 组合式 API）
- [Vite 5](https://vitejs.dev/) 构建工具
- 纯 CSS 动画 + SVG 矢量吉祥物，无额外 UI 库依赖

---

## 🛡️ 儿童账号安全说明

- 注册强制勾选《安全公约》，并建议家长陪同创建账号
- 家长模式额外采集手机号用于账号安全与找回
- 密码强度分三档引导（长度 / 字母+数字 / 长度≥10）
- 均为前端演示，接入真实后端时请补充服务端校验与加密传输

---

## 📝 待办 / 可扩展

- [ ] 家长守护滑块验证（拖动拼图防误触）
- [ ] 深色模式
- [ ] 吉祥物换成具体 IP 形象
- [ ] 接入真实登录 / 注册接口
- [ ] 多语言（中 / 英）

---

© 动画小镇 Demo · 仅供学习与演示使用
