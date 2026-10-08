<script setup>
import { ref, computed, onMounted } from 'vue'
import Toast from './Toast.vue'
import { useToast } from '../composables/feedback.js'
import { getRecommend, getFavorites, addFavorite, removeFavorite } from '../api/animation.js'

const props = defineProps({
  user: { type: Object, default: () => ({}) }
})
const emit = defineEmits(['logout'])
const { toast } = useToast()

const roleLabel = computed(() => (props.user.role === 'parent' ? '👨‍👩‍👧 家长' : '🧒 小朋友'))

const recommends = ref([])   // 今日推荐
const favorites = ref([])    // 我的收藏
const loading = ref(true)
// 已收藏的动画 id 集合，用于点亮爱心
const favIds = computed(() => new Set(favorites.value.map(a => a.id)))

async function load() {
  if (!props.user || !props.user.id) return
  loading.value = true
  try {
    const [rec, fav] = await Promise.all([
      getRecommend(6),
      getFavorites(props.user.id)
    ])
    recommends.value = rec || []
    favorites.value = fav || []
  } catch (err) {
    toast(err.message || '加载失败，请稍后再试～')
  } finally {
    loading.value = false
  }
}

async function toggleFav(a) {
  if (!props.user || !props.user.id) return
  try {
    if (favIds.value.has(a.id)) {
      await removeFavorite(props.user.id, a.id)
      favorites.value = favorites.value.filter(x => x.id !== a.id)
      toast(`已取消收藏《${a.title}》`)
    } else {
      await addFavorite(props.user.id, a.id)
      favorites.value = [...favorites.value, a]
      toast(`已收藏《${a.title}》❤️`)
    }
  } catch (err) {
    toast(err.message || '操作失败，请稍后再试～')
  }
}

onMounted(load)
</script>

<template>
  <main class="card town">
    <div class="me">
      <div class="avatar">{{ user.avatar || '🦄' }}</div>
      <div class="info">
        <div class="name">{{ user.nickname || '小探险家' }}</div>
        <div class="role">{{ roleLabel }}</div>
      </div>
      <button class="btn-out" type="button" @click="emit('logout')">退出</button>
    </div>

    <p class="hint">今天想看哪部动画呀？点 ❤️ 收藏喜欢的吧～ 🚀</p>

    <section class="sec">
      <h2 class="sec-h">🔥 今日推荐</h2>
      <p v-if="loading" class="empty">加载中…</p>
      <div v-else class="rec-row">
        <div v-for="a in recommends" :key="a.id" class="rec-card">
          <div class="rec-cover">{{ a.cover }}</div>
          <div class="rec-title" :title="a.title">{{ a.title }}</div>
          <div class="rec-cat">{{ a.category }} · 🔥{{ a.hot }}</div>
          <button class="heart" :class="{ on: favIds.has(a.id) }" type="button" @click="toggleFav(a)">
            {{ favIds.has(a.id) ? '❤️' : '🤍' }}
          </button>
        </div>
      </div>
    </section>

    <section class="sec">
      <h2 class="sec-h">⭐ 我的收藏</h2>
      <p v-if="!favorites.length" class="empty">还没有收藏，点上面的 ❤️ 收藏喜欢的动画吧～</p>
      <ul v-else class="fav-list">
        <li v-for="a in favorites" :key="a.id">
          <span class="fav-cover">{{ a.cover }}</span>
          <span class="fav-info">
            <b>{{ a.title }}</b>
            <i>{{ a.category }} · 🔥{{ a.hot }}</i>
          </span>
          <button class="heart on" type="button" @click="toggleFav(a)">❤️</button>
        </li>
      </ul>
    </section>
  </main>

  <Toast />
</template>

<style scoped>
.town { width: min(94vw, 560px); text-align: left; }

.me { display: flex; align-items: center; gap: 12px;
  background: #fbf7ff; border: 3px solid #ece3ff; border-radius: 20px; padding: 12px 14px; }
.avatar { font-size: 34px; width: 54px; height: 54px; flex-shrink: 0; display: flex; align-items: center;
  justify-content: center; background: #fff; border-radius: 50%; box-shadow: 0 6px 14px var(--shadow); }
.info { flex: 1; min-width: 0; }
.name { font-size: 19px; font-weight: bold; color: var(--ink); }
.role { font-size: 13px; color: var(--pink-d); margin-top: 2px; }
.btn-out { flex-shrink: 0; border: none; cursor: pointer; font-family: var(--font);
  padding: 9px 16px; border-radius: 14px; font-size: 14px; color: #fff;
  background: linear-gradient(120deg, var(--blue), #4f8fff); box-shadow: 0 6px 14px rgba(111,184,255,.4);
  transition: transform .12s; }
.btn-out:hover { transform: translateY(-2px); }
.btn-out:active { transform: scale(.96); }

.hint { font-size: 13px; color: #8a7aa8; margin: 14px 2px 6px; }

.sec { margin-top: 18px; }
.sec-h { font-size: 16px; color: var(--pink-d); margin: 0 0 10px; }

.rec-row { display: flex; gap: 10px; overflow-x: auto; padding: 2px 2px 8px; scrollbar-width: thin; }
.rec-card { position: relative; flex: 0 0 116px; width: 116px; background: #fbf7ff;
  border: 3px solid #ece3ff; border-radius: 18px; padding: 10px 8px 12px; text-align: center; }
.rec-cover { font-size: 34px; line-height: 1.2; }
.rec-title { font-size: 13px; font-weight: bold; color: var(--ink); margin-top: 4px;
  white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.rec-cat { font-size: 11px; color: #9a8ab8; margin-top: 2px; }

.heart { position: absolute; top: 6px; right: 6px; border: none; background: transparent;
  cursor: pointer; font-size: 16px; line-height: 1; padding: 2px; transition: transform .15s; }
.heart:hover { transform: scale(1.2); }
.heart.on { animation: beat .4s ease; }
@keyframes beat { 0% { transform: scale(1); } 50% { transform: scale(1.4); } 100% { transform: scale(1); } }

.fav-list { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 8px; }
.fav-list li { display: flex; align-items: center; gap: 10px; background: #fbf7ff;
  border: 3px solid #ece3ff; border-radius: 16px; padding: 8px 12px; }
.fav-cover { font-size: 26px; }
.fav-info { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.fav-info b { font-size: 14px; color: var(--ink); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.fav-info i { font-size: 11px; font-style: normal; color: #9a8ab8; }
.fav-list .heart { position: static; }

.empty { font-size: 13px; color: #a99cc4; background: #fbf7ff; border: 3px dashed #ece3ff;
  border-radius: 16px; padding: 14px; text-align: center; }
</style>
