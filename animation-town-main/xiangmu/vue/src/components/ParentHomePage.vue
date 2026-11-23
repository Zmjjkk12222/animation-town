<script setup>
/**
 * 家长首页。
 * App.vue 依据登录用户的 role 切到 'parent-home' 视图并引用本组件，
 * 但项目里此前缺少该文件，导致 App.vue 编译失败、整站白屏。
 *
 * 家长与小朋友共用同一套小镇首页 HomePage（其内部已按 user.role === 'parent'
 * 显示「家长」标识），这里做薄封装：透传 user，并把 logout / go-admin 事件继续向上抛。
 */
import HomePage from './HomePage.vue'

const props = defineProps({
  user: { type: Object, default: () => ({}) }
})
const emit = defineEmits(['logout', 'go-admin'])
</script>

<template>
  <HomePage
    :user="props.user"
    @logout="emit('logout')"
    @go-admin="emit('go-admin')"
  />
</template>
