<script setup>
// 卡通星星吉祥物：login = 黄色星星，register = 绿色星星
// mood: 'smile' 平静微笑 | 'big' 大笑 | 'sad' 难过（登录失败等场景）
const props = defineProps({
  variant: { type: String, default: 'login' }, // 'login' | 'register'
  mood: { type: String, default: 'smile' }
})
</script>

<template>
  <div class="mascot" :class="'mood-' + mood">
    <svg viewBox="0 0 120 120" aria-hidden="true">
      <defs>
        <radialGradient :id="variant === 'register' ? 'bodyReg' : 'bodyLogin'" cx="40%" cy="35%" r="70%">
          <stop offset="0%" :stop-color="variant === 'register' ? '#b6f0d8' : '#ffe27a'" />
          <stop offset="100%" :stop-color="variant === 'register' ? '#5fd6a8' : '#ffb83f'" />
        </radialGradient>
      </defs>

      <!-- 星星身体 -->
      <path d="M60 8 L72 40 L104 40 L78 60 L90 94 L60 72 L30 94 L42 60 L16 40 L48 40 Z"
            :fill="variant === 'register' ? 'url(#bodyReg)' : 'url(#bodyLogin)'"
            :stroke="variant === 'register' ? '#2fbf95' : '#ff9a2e'"
            stroke-width="3" stroke-linejoin="round" />

      <!-- 眼睛：正常为圆眼，难过时变成 >< -->
      <g v-if="mood !== 'sad'">
        <circle cx="48" cy="50" r="7" fill="#4a3a6b" />
        <circle cx="72" cy="50" r="7" fill="#4a3a6b" />
        <circle cx="50" cy="48" r="2.4" fill="#fff" />
        <circle cx="74" cy="48" r="2.4" fill="#fff" />
      </g>
      <g v-else stroke="#4a3a6b" stroke-width="3.5" stroke-linecap="round" fill="none">
        <path d="M42 46 L54 52 L42 58" />
        <path d="M78 46 L66 52 L78 58" />
      </g>

      <!-- 腮红 -->
      <circle cx="40" cy="62" r="6" fill="#ff9ec4" opacity=".8" />
      <circle cx="80" cy="62" r="6" fill="#ff9ec4" opacity=".8" />

      <!-- 嘴巴：big=大笑 / smile=微笑 / sad=难过下弯 -->
      <path v-if="mood === 'big'" d="M50 62 Q60 80 70 62" stroke="#4a3a6b" stroke-width="3" fill="none" stroke-linecap="round" />
      <path v-else-if="mood === 'smile'" d="M52 64 Q60 74 68 64" stroke="#4a3a6b" stroke-width="3" fill="none" stroke-linecap="round" />
      <path v-else d="M52 72 Q60 62 68 72" stroke="#4a3a6b" stroke-width="3" fill="none" stroke-linecap="round" />

      <!-- 难过时的汗滴 -->
      <path v-if="mood === 'sad'" d="M92 30 q4 7 0 10 q-4 -3 0 -10" fill="#6fb8ff" opacity=".9" />
    </svg>
  </div>
</template>

<style scoped>
/* mood 切换时给吉祥物一个小弹跳，让表情变化更有生命感 */
.mascot { animation: bob 3.2s ease-in-out infinite; }
.mascot.mood-sad { animation: bob 3.2s ease-in-out infinite, wooble .5s ease; }
.mascot.mood-big { animation: bob 3.2s ease-in-out infinite, wooble .4s ease; }
@keyframes wooble {
  0% { transform: scale(1) rotate(0); }
  30% { transform: scale(1.1) rotate(-6deg); }
  60% { transform: scale(.96) rotate(4deg); }
  100% { transform: scale(1) rotate(0); }
}
</style>
