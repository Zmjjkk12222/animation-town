import { reactive } from 'vue'

// 全局提示气泡状态（被 Toast 组件订阅）
const state = reactive({ msg: '', visible: false, type: 'ok' })
let timer = null

/**
 * 弹出提示气泡
 * @param {string} msg 提示文案
 * @param {object} [opts] 可选项
 * @param {number} [opts.duration] 显示时长，默认 2200ms
 * @param {'ok'|'err'} [opts.type] 类型：ok=常规(薄荷绿边框)，err=错误(粉红边框+图标)
 */
export function useToast() {
  function toast(msg, opts = {}) {
    const duration = typeof opts === 'number' ? opts : (opts.duration ?? 2200)
    const type = typeof opts === 'object' ? (opts.type ?? 'ok') : 'ok'
    state.msg = msg
    state.type = type
    state.visible = true
    clearTimeout(timer)
    timer = setTimeout(() => { state.visible = false }, duration)
  }
  return { state, toast }
}

// 撒彩纸动画
export function burstConfetti() {
  const colors = ['#ff8fc4', '#6fb8ff', '#7ee0c0', '#ffd23f', '#c9b8ff']
  for (let i = 0; i < 60; i++) {
    const c = document.createElement('div')
    c.className = 'confetti'
    c.style.left = Math.random() * 100 + 'vw'
    c.style.background = colors[i % colors.length]
    document.body.appendChild(c)
    const fall = 80 + Math.random() * 40
    const dur = 1800 + Math.random() * 1400
    c.animate(
      [
        { transform: 'translateY(0) rotate(0)', opacity: 1 },
        { transform: `translateY(${fall}vh) rotate(${Math.random() * 720}deg)`, opacity: .9 }
      ],
      { duration: dur, easing: 'cubic-bezier(.3,.7,.4,1)' }
    ).onfinish = () => c.remove()
  }
}
