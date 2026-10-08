<script setup>
// 卡通星星吉祥物：login = 黄色星星，register = 绿色星星
// mood: 'smile' 平静微笑 | 'big' 大笑
defineProps({
  variant: { type: String, default: 'login' }, // 'login' | 'register'
  mood: { type: String, default: 'smile' }
})
</script>

<template>
  <div class="mascot">
    <svg viewBox="0 0 120 120" aria-hidden="true">
      <defs>
        <radialGradient :id="variant === 'register' ? 'bodyReg' : 'bodyLogin'" cx="40%" cy="35%" r="70%">
          <stop offset="0%" :stop-color="variant === 'register' ? '#b6f0d8' : '#ffe27a'" />
          <stop offset="100%" :stop-color="variant === 'register' ? '#5fd6a8' : '#ffb83f'" />
        </radialGradient>
      </defs>

      <path d="M60 8 L72 40 L104 40 L78 60 L90 94 L60 72 L30 94 L42 60 L16 40 L48 40 Z"
            :fill="variant === 'register' ? 'url(#bodyReg)' : 'url(#bodyLogin)'"
            :stroke="variant === 'register' ? '#2fbf95' : '#ff9a2e'"
            stroke-width="3" stroke-linejoin="round" />

      <circle cx="48" cy="50" r="7" fill="#4a3a6b" />
      <circle cx="72" cy="50" r="7" fill="#4a3a6b" />
      <circle cx="50" cy="48" r="2.4" fill="#fff" />
      <circle cx="74" cy="48" r="2.4" fill="#fff" />
      <circle cx="40" cy="62" r="6" fill="#ff9ec4" opacity=".8" />
      <circle cx="80" cy="62" r="6" fill="#ff9ec4" opacity=".8" />
      <path :d="mood === 'big' ? 'M50 62 Q60 80 70 62' : 'M52 64 Q60 74 68 64'"
            stroke="#4a3a6b" stroke-width="3" fill="none" stroke-linecap="round" />
    </svg>
  </div>
</template>
