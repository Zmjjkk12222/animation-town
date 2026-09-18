<script setup>
import { ref } from 'vue'
import BgDecor from './components/BgDecor.vue'
import LoginPage from './components/LoginPage.vue'
import RegisterPage from './components/RegisterPage.vue'

// 视图切换：'login' | 'register'
const view = ref('login')
</script>

<template>
  <BgDecor />
  <LoginPage v-if="view === 'login'" @go-register="view = 'register'" />
  <RegisterPage v-else @go-login="view = 'login'" />
</template>
