<script setup>
import { useToast } from '../composables/feedback.js'
const { state } = useToast()
</script>

<template>
  <div class="toast" :class="{ show: state.visible }">{{ state.msg }}</div>
</template>
