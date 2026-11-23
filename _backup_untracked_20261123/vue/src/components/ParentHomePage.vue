<script setup>
/**
 * 家长首页
 * 对应 App.vue 中的 'parent-home' 视图。
 * 目前与儿童首页共用 HomePage.vue —— 该组件内部会根据 user.role 显示「家长」标识，
 * 并提供对应的导航与能力。这里做一层薄封装，透传 user / logout / go-admin。
 * 后续如果要做独立的家长首页，直接替换本文件内容即可，App.vue 无需改动。
 */
import HomePage from './HomePage.vue'

defineProps({
  user: { type: Object, default: () => ({}) }
})
defineEmits(['logout', 'go-admin'])
</script>

<template>
  <HomePage
    :user="user"
    @logout="$emit('logout')"
    @go-admin="$emit('go-admin')"
  />
</template>
