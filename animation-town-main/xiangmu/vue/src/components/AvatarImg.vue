<script setup>
/**
 * 头像显示组件（统一回显逻辑）
 * ---------------------------------------------------------------
 * 优先级：avatarUrl（已上传图片）→ avatar（emoji）→ 默认占位 emoji
 * 供首页/个人页/好友列表等多处复用，避免每处都写一遍判断。
 */
import { computed } from 'vue'

const props = defineProps({
  /** 头像图片 URL（相对路径，如 /uploads/avatar/xxx.png） */
  avatarUrl: { type: String, default: '' },
  /** 头像 emoji（未上传图片时用） */
  avatar: { type: String, default: '' },
  /** 默认占位 emoji（两者都为空时用） */
  fallback: { type: String, default: '🦄' }
})

const hasImg = computed(() => !!props.avatarUrl)
// 图片 URL 补全：相对路径走 vite 代理 /uploads -> 8081
const imgSrc = computed(() => {
  if (!props.avatarUrl) return ''
  if (props.avatarUrl.startsWith('http')) return props.avatarUrl
  return props.avatarUrl
})
const emojiText = computed(() => props.avatar || props.fallback)
</script>

<template>
  <img v-if="hasImg" class="ava-img" :src="imgSrc" :alt="emojiText" />
  <span v-else class="ava-emoji">{{ emojiText }}</span>
</template>

<style scoped>
.ava-img {
  width: 100%; height: 100%; object-fit: cover;
  border-radius: 50%; display: block;
}
.ava-emoji {
  width: 100%; height: 100%;
  display: flex; align-items: center; justify-content: center;
  font-size: inherit;
}
</style>
