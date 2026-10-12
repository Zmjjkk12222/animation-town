<script setup>
import { ref, computed, onMounted } from 'vue'
import Mascot from './Mascot.vue'
import Toast from './Toast.vue'
import { useToast } from '../composables/feedback.js'
import { getRecommend, getFavorites, addFavorite, removeFavorite } from '../api/animation.js'

const props = defineProps({
  user: { type: Object, default: () => ({}) }
})
const emit = defineEmits(['logout'])
const { toast } = useToast()

const roleLabel = computed(() => (props.user.role === 'parent' ? '👨‍👩‍👧 家长' : '🧒 小朋友'))

// 顶部导航：首页 / 全部动画 / 我的收藏
const tab = ref('home')
const tabs = [
  { key: 'home', label: '首页', icon: '🏠' },
  { key: 'all', label: '全部动画', icon: '🎬' },
  { key: 'fav', label: '我的收藏', icon: '⭐' }
]

// 分类对应的代表 emoji（用于分类导览磁贴与榜单图标）
const CAT_EMOJI = {
  '冒险': '🌳', '治愈': '⭐', '科普': '🦖', '推理': '🐱', '科幻': '🚀', '音乐': '🐠',
  '科学': '🔧', '创意': '🧱', '美食': '☁️', '语文': '📖', '搞笑': '🤡', '友情': '🤝',
  '童话': '👸', '自然': '🦁', '运动': '🏓', '历史': '🏮', '动物': '🐼', '恐龙': '🦕',
  '艺术': '🎨'
}
const catEmoji = (c) => CAT_EMOJI[c] || '🎬'

const kw = ref('')            // 搜索关键词
const cat = ref('全部')       // 全部分类筛选
const all = ref([])           // 全部动画
const favorites = ref([])     // 我的收藏
const loading = ref(true)

// 已收藏 id 集合，用于点亮爱心
const favIds = computed(() => new Set(favorites.value.map(a => a.id)))

// 按热度排序
const byHot = computed(() => [...all.value].sort((a, b) => b.hot - a.hot))
// 今日推荐 = 热度前 6
const recommends = computed(() => byHot.value.slice(0, 6))
// 精选大卡（Top1 spotlight）
const feature = computed(() => recommends.value[0] || null)
// 精选大卡之外的推荐网格
const restRecommends = computed(() => recommends.value.slice(1))
// 人气榜单 Top5
const topList = computed(() => byHot.value.slice(0, 5))
const maxHot = computed(() => (all.value.length ? Math.max(...all.value.map(a => a.hot)) : 1))

// 分类速览（由数据动态生成，带数量）
const categories = computed(() => {
  const map = new Map()
  all.value.forEach(a => {
    if (a.category) map.set(a.category, (map.get(a.category) || 0) + 1)
  })
  return ['全部', ...[...map.entries()].sort((x, y) => y[1] - x[1]).map(e => e[0])]
})
const catCount = (c) => all.value.filter(a => a.category === c).length

// “全部动画”里按分类筛选后的列表
const allByCat = computed(() =>
  cat.value === '全部' ? all.value : all.value.filter(a => a.category === cat.value)
)

// 搜索结果（标题 / 分类 / 简介 模糊匹配）
const searching = computed(() => kw.value.trim().length > 0)
const results = computed(() => {
  const k = kw.value.trim().toLowerCase()
  if (!k) return []
  return all.value.filter(a =>
    (a.title || '').toLowerCase().includes(k) ||
    (a.category || '').toLowerCase().includes(k) ||
    (a.description || '').toLowerCase().includes(k)
  )
})

function clearKw() { kw.value = '' }

// 从分类导览 / 搜索建议跳转到对应分类
function goCat(c) {
  tab.value = 'all'
  cat.value = c
  clearKw()
}

function doSearch() {
  if (!searching.value) {
    toast('先输入想看的动画或分类哦～ 🔍')
    return
  }
  toast(results.value.length ? `找到 ${results.value.length} 部相关动画 ✨` : '没有找到相关动画，换个词试试～')
}

async function load() {
  if (!props.user || !props.user.id) return
  loading.value = true
  try {
    // 后端暂无搜索接口：一次拉全部动画，前端做筛选
    const [list, fav] = await Promise.all([
      getRecommend(100),
      getFavorites(props.user.id)
    ])
    all.value = list || []
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

// 排名勋章
const rankMedal = (i) => (['🥇', '🥈', '🥉'][i] || (i + 1))

onMounted(load)
</script>

<template>
  <!-- ============ 顶部导航栏 ============ -->
  <header class="topbar">
    <div class="topbar-in">
      <div class="brand">
        <span class="brand-badge">🌟</span>
        <span class="brand-name">动画小镇</span>
      </div>

      <nav class="nav" role="tablist">
        <button
          v-for="t in tabs" :key="t.key"
          :class="{ active: tab === t.key && !searching }"
          role="tab"
          @click="tab = t.key; clearKw()"
        >{{ t.icon }} {{ t.label }}</button>
      </nav>

      <div class="me-chip">
        <span class="me-ava">{{ user.avatar || '🦄' }}</span>
        <span class="me-meta">
          <b class="me-name">{{ user.nickname || '小探险家' }}</b>
          <i class="me-role">{{ roleLabel }}</i>
        </span>
        <button class="btn-out" type="button" @click="emit('logout')">退出</button>
      </div>
    </div>
  </header>

  <main class="home">
    <!-- ============ 欢迎横幅 + 搜索栏 ============ -->
    <section class="hero">
      <Mascot variant="login" mood="big" />
      <h1 class="hero-hi">Hi，{{ user.nickname || '小探险家' }}！👋</h1>
      <p class="hero-sub">欢迎来到动画小镇，今天想看点什么呢？</p>

      <div class="search">
        <span class="s-emoji">🔍</span>
        <input
          v-model="kw"
          type="text"
          placeholder="搜索动画、分类，例如：恐龙 / 治愈 / 运动"
          @keyup.enter="doSearch"
        />
        <button v-if="searching" class="s-clear" type="button" @click="clearKw" aria-label="清空">✕</button>
        <button class="s-btn" type="button" @click="doSearch">搜索</button>
      </div>

      <!-- 热门分类快捷入口 -->
      <div class="quick" v-if="!searching">
        <span class="quick-tip">🔥 大家都在看：</span>
        <button
          v-for="c in categories.filter(c => c !== '全部').slice(0, 8)" :key="'q' + c"
          class="quick-chip" type="button" @click="goCat(c)"
        >{{ catEmoji(c) }} {{ c }}</button>
      </div>
    </section>

    <!-- ============ 搜索结果（输入关键词时展示） ============ -->
    <section v-if="searching" class="block">
      <h2 class="block-h">🔎 找到 {{ results.length }} 部相关动画</h2>
      <p v-if="!results.length" class="empty">没有找到相关动画，换个关键词试试～</p>
      <div v-else class="grid">
        <div v-for="a in results" :key="'r' + a.id" class="acard">
          <button class="heart" :class="{ on: favIds.has(a.id) }" type="button" @click="toggleFav(a)">
            {{ favIds.has(a.id) ? '❤️' : '🤍' }}
          </button>
          <div class="acover">{{ a.cover }}</div>
          <div class="atitle" :title="a.title">{{ a.title }}</div>
          <div class="acat">{{ a.category }} · 🔥{{ a.hot }}</div>
          <p class="adesc">{{ a.description }}</p>
        </div>
      </div>
    </section>

    <!-- ============ 正常内容（未搜索时按导航展示） ============ -->
    <template v-else>
      <!-- ============ 首页 ============ -->
      <template v-if="tab === 'home'">
        <!-- 分类导览磁贴 -->
        <section class="block">
          <h2 class="block-h">🧭 分类导览</h2>
          <div class="cat-tiles">
            <button
              v-for="c in categories.filter(c => c !== '全部')" :key="'ct' + c"
              class="ctile" type="button" @click="goCat(c)"
            >
              <span class="ctile-emoji">{{ catEmoji(c) }}</span>
              <span class="ctile-name">{{ c }}</span>
              <span class="ctile-cnt">{{ catCount(c) }} 部</span>
            </button>
          </div>
        </section>

        <!-- 今日推荐：精选大卡 + 网格 -->
        <section class="block">
          <h2 class="block-h">🔥 今日推荐</h2>

          <!-- 精选大卡（Top1） -->
          <div v-if="feature" class="feature" :style="{ '--fc': catEmoji(feature.category) }">
            <div class="feature-cover">{{ feature.cover }}</div>
            <div class="feature-info">
              <span class="feature-badge">✨ 编辑精选</span>
              <h3 class="feature-title">{{ feature.title }}</h3>
              <span class="feature-cat">{{ catEmoji(feature.category) }} {{ feature.category }} · 🔥{{ feature.hot }}</span>
              <p class="feature-desc">{{ feature.description }}</p>
              <button
                class="feature-fav" :class="{ on: favIds.has(feature.id) }" type="button"
                @click="toggleFav(feature)"
              >{{ favIds.has(feature.id) ? '❤️ 已收藏' : '🤍 收藏' }}</button>
            </div>
          </div>

          <div v-if="loading" class="grid">
            <div v-for="n in 5" :key="'sk' + n" class="acard sk">
              <div class="acover">🌈</div>
              <div class="atitle">加载中…</div>
              <div class="acat">马上就好</div>
            </div>
          </div>
          <div v-else class="grid">
            <div v-for="(a, i) in restRecommends" :key="a.id" class="acard">
              <span class="rank" :class="'rk' + (i < 3 ? i + 1 : 0)">{{ rankMedal(i) }}</span>
              <button class="heart" :class="{ on: favIds.has(a.id) }" type="button" @click="toggleFav(a)">
                {{ favIds.has(a.id) ? '❤️' : '🤍' }}
              </button>
              <div class="acover">{{ a.cover }}</div>
              <div class="atitle" :title="a.title">{{ a.title }}</div>
              <div class="acat">{{ a.category }} · 🔥{{ a.hot }}</div>
              <p class="adesc">{{ a.description }}</p>
            </div>
          </div>
        </section>

        <!-- 人气榜单 Top5 -->
        <section class="block">
          <h2 class="block-h">🏆 人气榜单</h2>
          <div class="ranklist">
            <div v-for="(a, i) in topList" :key="'t' + a.id" class="rrow">
              <span class="rrow-no" :class="'rk' + (i < 3 ? i + 1 : 0)">{{ rankMedal(i) }}</span>
              <span class="rrow-emoji">{{ a.cover }}</span>
              <div class="rrow-main">
                <div class="rrow-top">
                  <span class="rrow-title" :title="a.title">{{ a.title }}</span>
                  <span class="rrow-cat">{{ a.category }}</span>
                </div>
                <div class="rbar"><i :style="{ width: (a.hot / maxHot * 100) + '%' }"></i></div>
              </div>
              <span class="rrow-hot">🔥 {{ a.hot }}</span>
              <button class="rrow-fav" :class="{ on: favIds.has(a.id) }" type="button" @click="toggleFav(a)">
                {{ favIds.has(a.id) ? '❤️' : '🤍' }}
              </button>
            </div>
          </div>
        </section>
      </template>

      <!-- ============ 全部动画：分类筛选 + 全量网格 ============ -->
      <section v-if="tab === 'all'" class="block">
        <h2 class="block-h">🎬 全部动画（{{ allByCat.length }} 部）</h2>
        <div class="cats">
          <button
            v-for="c in categories" :key="c"
            :class="{ active: cat === c }"
            @click="cat = c"
          >{{ c === '全部' ? '全部' : catEmoji(c) + ' ' + c }}</button>
        </div>
        <p v-if="!allByCat.length" class="empty">这个分类暂时没有动画～</p>
        <div v-else class="grid">
          <div v-for="a in allByCat" :key="'a' + a.id" class="acard">
            <button class="heart" :class="{ on: favIds.has(a.id) }" type="button" @click="toggleFav(a)">
              {{ favIds.has(a.id) ? '❤️' : '🤍' }}
            </button>
            <div class="acover">{{ a.cover }}</div>
            <div class="atitle" :title="a.title">{{ a.title }}</div>
            <div class="acat">{{ a.category }} · 🔥{{ a.hot }}</div>
            <p class="adesc">{{ a.description }}</p>
          </div>
        </div>
      </section>

      <!-- ============ 我的收藏 ============ -->
      <section v-if="tab === 'fav'" class="block">
        <h2 class="block-h">⭐ 我的收藏</h2>
        <p v-if="!favorites.length" class="empty">还没有收藏，去首页点 ❤️ 收藏喜欢的动画吧～</p>
        <div v-else class="grid">
          <div v-for="a in favorites" :key="'f' + a.id" class="acard">
            <button class="heart on" type="button" @click="toggleFav(a)">❤️</button>
            <div class="acover">{{ a.cover }}</div>
            <div class="atitle" :title="a.title">{{ a.title }}</div>
            <div class="acat">{{ a.category }} · 🔥{{ a.hot }}</div>
            <p class="adesc">{{ a.description }}</p>
          </div>
        </div>
      </section>
    </template>
  </main>

  <Toast />
</template>

<style scoped>
/* ============ 顶部导航栏 ============ */
.topbar {
  position: sticky; top: 0; z-index: 5;
  padding: 12px 16px 0;
}
.topbar-in {
  max-width: 980px; margin: 0 auto;
  display: flex; align-items: center; gap: 16px; flex-wrap: wrap;
  background: rgba(255, 253, 249, .88);
  backdrop-filter: blur(8px);
  border: 4px solid #fff;
  border-radius: 22px;
  padding: 10px 16px;
  box-shadow: 0 12px 28px var(--shadow);
}
.brand { display: flex; align-items: center; gap: 8px; }
.brand-badge {
  width: 36px; height: 36px; display: flex; align-items: center; justify-content: center;
  font-size: 20px; border-radius: 50%;
  background: radial-gradient(circle at 35% 35%, #fff6c8, var(--sun));
  box-shadow: 0 4px 10px rgba(255, 210, 80, .5);
}
.brand-name { font-size: 20px; font-weight: bold; color: var(--pink-d); text-shadow: 1px 1px 0 #ffe0f0; letter-spacing: 1px; }

.nav { display: flex; gap: 6px; background: #f1ecff; border-radius: 16px; padding: 5px; margin: 0 auto; }
.nav button {
  border: none; background: transparent; font-family: var(--font); cursor: pointer;
  padding: 8px 16px; border-radius: 12px; font-size: 14px; color: #7a6aa0; transition: .2s;
  white-space: nowrap;
}
.nav button.active { background: #fff; color: var(--pink-d); box-shadow: 0 4px 12px var(--shadow); transform: scale(1.04); font-weight: bold; }

.me-chip { display: flex; align-items: center; gap: 8px; }
.me-ava {
  font-size: 22px; width: 40px; height: 40px; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center;
  background: #fff; border-radius: 50%; box-shadow: 0 5px 12px var(--shadow);
}
.me-meta { display: flex; flex-direction: column; line-height: 1.15; }
.me-name { font-size: 14px; color: var(--ink); max-width: 90px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.me-role { font-size: 11px; font-style: normal; color: var(--pink-d); }
.btn-out {
  border: none; cursor: pointer; font-family: var(--font);
  padding: 8px 14px; border-radius: 12px; font-size: 13px; color: #fff;
  background: linear-gradient(120deg, var(--blue), #4f8fff);
  box-shadow: 0 6px 14px rgba(111, 184, 255, .4); transition: transform .12s;
}
.btn-out:hover { transform: translateY(-2px); }
.btn-out:active { transform: scale(.96); }

/* ============ 内容容器 ============ */
.home { max-width: 980px; margin: 0 auto; padding: 8px 16px 40px; text-align: center; }

/* ============ 欢迎横幅 + 搜索栏 ============ */
.hero {
  margin: 18px auto 4px;
  background: var(--card);
  border: 5px solid #fff;
  border-radius: 30px;
  padding: 22px 24px 22px;
  box-shadow: 0 22px 50px var(--shadow), inset 0 0 0 6px #fff;
  animation: pop .7s cubic-bezier(.18, 1.4, .4, 1) both;
  position: relative;
}
.hero::before {
  content: ""; position: absolute; top: -13px; left: 50%; transform: translateX(-50%);
  width: 60%; height: 20px;
  background: radial-gradient(circle at 10px 0, var(--pink) 9px, transparent 10px) repeat-x;
  background-size: 20px 20px; opacity: .9;
}
.hero .mascot { margin-top: 2px; }
.hero .mascot :deep(svg) { width: 96px; height: 96px; }
.hero-hi { margin: 4px 0 2px; font-size: 26px; color: var(--pink-d); text-shadow: 2px 2px 0 #ffe0f0; }
.hero-sub { margin: 0 0 16px; font-size: 14px; color: #8a7aa8; }

/* 搜索栏：复用登录页输入框风格 */
.search {
  display: flex; align-items: center; gap: 8px;
  max-width: 560px; margin: 0 auto;
  background: #fbf7ff; border: 3px solid #ece3ff; border-radius: 20px;
  padding: 8px 8px 8px 16px; transition: .25s;
}
.search:focus-within { border-color: var(--pink); background: #fff; box-shadow: 0 0 0 4px rgba(255, 143, 196, .18); }
.s-emoji { font-size: 20px; }
.search input {
  border: none; outline: none; background: transparent; flex: 1; min-width: 0;
  font-family: var(--font); font-size: 16px; color: var(--ink);
}
.search input::placeholder { color: #bcb0d6; }
.s-clear {
  border: none; cursor: pointer; background: #efe6ff; color: #9a8ab8;
  width: 28px; height: 28px; border-radius: 50%; font-size: 13px; flex-shrink: 0;
}
.s-clear:hover { background: #e3d4ff; }
.s-btn {
  border: none; cursor: pointer; font-family: var(--font); flex-shrink: 0;
  padding: 10px 20px; border-radius: 14px; font-size: 15px; color: #fff;
  background: linear-gradient(120deg, var(--pink), var(--pink-d));
  box-shadow: 0 8px 18px rgba(255, 95, 168, .4); transition: transform .12s;
}
.s-btn:hover { transform: translateY(-2px); }
.s-btn:active { transform: scale(.96); }

/* 热门分类快捷入口 */
.quick { margin-top: 14px; display: flex; align-items: center; gap: 8px; flex-wrap: wrap; justify-content: center; }
.quick-tip { font-size: 13px; color: #9a8ab8; }
.quick-chip {
  border: 3px solid #ece3ff; background: #fff; color: #7a6aa0;
  font-family: var(--font); cursor: pointer; font-size: 13px;
  padding: 5px 12px; border-radius: 999px; transition: .18s;
}
.quick-chip:hover { border-color: var(--pink); color: var(--pink-d); transform: translateY(-2px); }

/* ============ 内容区块 ============ */
.block { margin-top: 26px; text-align: left; }
.block-h { font-size: 18px; color: var(--pink-d); margin: 0 0 12px 4px; text-shadow: 1px 1px 0 #ffe0f0; }

/* 分类导览磁贴 */
.cat-tiles { display: grid; grid-template-columns: repeat(auto-fill, minmax(108px, 1fr)); gap: 12px; }
.ctile {
  border: 3px solid #ece3ff; background: linear-gradient(160deg, #fff, #fbf7ff);
  border-radius: 20px; padding: 14px 8px; cursor: pointer; font-family: var(--font);
  display: flex; flex-direction: column; align-items: center; gap: 4px; transition: .18s;
}
.ctile:hover { transform: translateY(-4px); border-color: var(--pink); box-shadow: 0 12px 22px var(--shadow); }
.ctile-emoji { font-size: 30px; line-height: 1; }
.ctile-name { font-size: 14px; font-weight: bold; color: var(--ink); }
.ctile-cnt { font-size: 11px; color: #a99cc4; }

/* 精选大卡 */
.feature {
  display: flex; gap: 18px; align-items: center; text-align: left;
  background: linear-gradient(135deg, #fff, #fff0f7);
  border: 4px solid #fff; border-radius: 26px; padding: 20px;
  box-shadow: 0 18px 40px var(--shadow);
  position: relative; overflow: hidden;
  animation: pop .6s cubic-bezier(.18, 1.3, .4, 1) both;
}
.feature::after {
  content: var(--fc, '🎬'); position: absolute; right: -20px; bottom: -30px;
  font-size: 130px; opacity: .07; transform: rotate(-8deg);
}
.feature-cover {
  font-size: 78px; line-height: 1; flex-shrink: 0;
  width: 120px; height: 120px; display: flex; align-items: center; justify-content: center;
  background: #fff; border-radius: 24px; box-shadow: 0 10px 22px var(--shadow);
}
.feature-info { flex: 1; min-width: 0; }
.feature-badge {
  display: inline-block; font-size: 12px; color: #fff; font-weight: bold;
  background: linear-gradient(120deg, var(--pink), var(--pink-d));
  padding: 4px 12px; border-radius: 999px; box-shadow: 0 6px 14px rgba(255, 95, 168, .35);
}
.feature-title { margin: 10px 0 4px; font-size: 24px; color: var(--pink-d); text-shadow: 1px 1px 0 #ffe0f0; }
.feature-cat { font-size: 13px; color: #9a8ab8; }
.feature-desc { margin: 10px 0 14px; font-size: 14px; color: #6f6190; line-height: 1.6; }
.feature-fav {
  border: none; cursor: pointer; font-family: var(--font);
  padding: 9px 18px; border-radius: 14px; font-size: 14px; font-weight: bold;
  color: var(--pink-d); background: #fff; border: 3px solid var(--pink);
  transition: .15s;
}
.feature-fav.on { color: #fff; background: linear-gradient(120deg, var(--pink), var(--pink-d)); border-color: transparent; }
.feature-fav:hover { transform: translateY(-2px); }

/* 动画卡片网格 */
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 14px; }
.acard {
  position: relative; background: #fbf7ff; border: 3px solid #ece3ff; border-radius: 20px;
  padding: 14px 12px 14px; text-align: center; transition: transform .15s, box-shadow .2s, border-color .2s;
  animation: fadeUp .5s both;
}
.acard:hover { transform: translateY(-4px); border-color: var(--pink); box-shadow: 0 12px 24px var(--shadow); }
.acover { font-size: 44px; line-height: 1.15; }
.atitle { font-size: 15px; font-weight: bold; color: var(--ink); margin-top: 6px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.acat { font-size: 12px; color: #9a8ab8; margin-top: 2px; }
.adesc { font-size: 12px; color: #8a7aa8; margin: 8px 2px 0; line-height: 1.5; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }

/* 排名勋章 */
.rank {
  position: absolute; top: -10px; left: -8px; z-index: 2;
  min-width: 26px; height: 26px; padding: 0 6px; display: flex; align-items: center; justify-content: center;
  font-size: 13px; font-weight: bold; color: #fff; border-radius: 999px;
  background: #b9a9d8; box-shadow: 0 4px 10px var(--shadow);
}
.rank.rk1 { background: linear-gradient(120deg, #ffd34e, #ff9f1c); }
.rank.rk2 { background: linear-gradient(120deg, #c9d6e3, #9fb0c4); }
.rank.rk3 { background: linear-gradient(120deg, #ffb27a, #f0823c); }

.heart {
  position: absolute; top: 8px; right: 8px; z-index: 2; border: none; background: transparent;
  cursor: pointer; font-size: 18px; line-height: 1; padding: 2px; transition: transform .15s;
}
.heart:hover { transform: scale(1.2); }
.heart.on { animation: beat .4s ease; }
@keyframes beat { 0% { transform: scale(1); } 50% { transform: scale(1.4); } 100% { transform: scale(1); } }

/* 人气榜单 */
.ranklist { display: flex; flex-direction: column; gap: 10px; }
.rrow {
  display: flex; align-items: center; gap: 12px;
  background: #fbf7ff; border: 3px solid #ece3ff; border-radius: 18px; padding: 12px 14px;
  transition: .18s;
}
.rrow:hover { border-color: var(--pink); box-shadow: 0 10px 20px var(--shadow); transform: translateX(2px); }
.rrow-no {
  flex-shrink: 0; min-width: 28px; height: 28px; display: flex; align-items: center; justify-content: center;
  font-size: 13px; font-weight: bold; color: #fff; border-radius: 50%; background: #b9a9d8;
}
.rrow-no.rk1 { background: linear-gradient(120deg, #ffd34e, #ff9f1c); }
.rrow-no.rk2 { background: linear-gradient(120deg, #c9d6e3, #9fb0c4); }
.rrow-no.rk3 { background: linear-gradient(120deg, #ffb27a, #f0823c); }
.rrow-emoji { font-size: 30px; flex-shrink: 0; }
.rrow-main { flex: 1; min-width: 0; }
.rrow-top { display: flex; align-items: baseline; gap: 8px; }
.rrow-title { font-size: 15px; font-weight: bold; color: var(--ink); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.rrow-cat { font-size: 11px; color: #a99cc4; flex-shrink: 0; }
.rbar { margin-top: 6px; height: 8px; background: #ece3ff; border-radius: 999px; overflow: hidden; }
.rbar i { display: block; height: 100%; border-radius: 999px; background: linear-gradient(90deg, var(--pink), var(--pink-d)); transition: width .6s ease; }
.rrow-hot { font-size: 13px; color: #f0823c; flex-shrink: 0; font-weight: bold; }
.rrow-fav {
  border: none; background: transparent; cursor: pointer; font-size: 18px; line-height: 1;
  flex-shrink: 0; padding: 2px; transition: transform .15s;
}
.rrow-fav:hover { transform: scale(1.2); }

/* 分类速览小胶囊 */
.cats { display: flex; gap: 8px; flex-wrap: wrap; margin: 0 0 14px 4px; }
.cats button {
  border: 3px solid #ece3ff; background: #fbf7ff; color: #7a6aa0;
  font-family: var(--font); cursor: pointer; font-size: 13px;
  padding: 6px 14px; border-radius: 999px; transition: .2s;
}
.cats button.active { background: linear-gradient(120deg, var(--pink), var(--pink-d)); color: #fff; border-color: transparent; box-shadow: 0 6px 14px rgba(255, 95, 168, .35); }

/* 加载占位卡片：轻微呼吸 */
.acard.sk { animation: breathe 1.4s ease-in-out infinite; opacity: .75; }
@keyframes breathe { 0%, 100% { transform: scale(1); } 50% { transform: scale(.96); } }

.empty { font-size: 13px; color: #a99cc4; background: #fbf7ff; border: 3px dashed #ece3ff; border-radius: 16px; padding: 16px; text-align: center; }

/* 入场动画 */
@keyframes pop { 0% { transform: scale(.9); opacity: 0; } 100% { transform: scale(1); opacity: 1; } }
@keyframes fadeUp { 0% { transform: translateY(10px); opacity: 0; } 100% { transform: translateY(0); opacity: 1; } }

/* 窄屏适配 */
@media (max-width: 560px) {
  .nav { order: 3; width: 100%; justify-content: center; }
  .me-meta { display: none; }
  .hero-hi { font-size: 22px; }
  .feature { flex-direction: column; text-align: center; }
  .feature::after { display: none; }
  .feature-desc { text-align: center; }
}
</style>
