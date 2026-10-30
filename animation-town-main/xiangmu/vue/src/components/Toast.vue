<script setup>
import { useToast } from '../composables/feedback.js'
const { state } = useToast()
</script>

<template>
  <div class="toast" :class="[{ show: state.visible }, state.type]">
    <span v-if="state.type === 'err'" class="t-ico">😿</span>
    {{ state.msg }}
  </div>
</template>

<style scoped>
.t-ico { margin-right: 4px; }
</style>
