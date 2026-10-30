<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import Toast from './Toast.vue'
import { useToast } from '../composables/feedback.js'
import { getRecommend, getFavorites, addFavorite, removeFavorite } from '../api/animation.js'

const props = defineProps({
  user: { type: Object, default: () => ({}) }
})
const emit = defineEmits(['logout', 'go-admin'])
const { toast } = useToast()

const roleLabel = computed(() => (props.user.role === 'parent' ? '家长' : '小朋友'))

// ============================================================
// 左侧竖版导航（仿腾讯视频首页布局）
// ============================================================
const tab = ref('home')
const sideOpen = ref(false)   // 移动端侧边栏开关
const navMain = [
  { key: 'home', label: '首页', icon: '🏠' },
  { key: 'all', label: '全部动画', icon: '🎬' },
  { key: 'fav', label: '我的收藏', icon: '⭐' }
]

// ============================================================
// 数据与分类
// ============================================================
const CAT_EMOJI = {
  '冒险': '🌳', '治愈': '⭐', '科普': '🦖', '推理': '🐱', '科幻': '🚀', '音乐': '🐠',
  '科学': '🔧', '创意': '🧱', '美食': '☁️', '语文': '📖', '搞笑': '🤡', '友情': '🤝',
  '童话': '👸', '自然': '🦁', '运动': '🏓', '历史': '🏮', '动物': '🐼', '恐龙': '🦕',
  '艺术': '🎨'
}
const catEmoji = (c) => CAT_EMOJI[c] || '🎬'

// 每个分类一对渐变色，用于海报底色（鲜艳的儿童风格调色板）
const CAT_GRAD = {
  '冒险': ['#9be7b4', '#43c97e'], '治愈': ['#cdbcff', '#9c7cff'], '科普': ['#a6e9f3', '#38c3da'],
  '推理': ['#ffd9a6', '#ffa24d'], '科幻': ['#b3caff', '#6290ff'], '音乐': ['#a6d8ff', '#4fabff'],
  '科学': ['#ffd9b0', '#ff9f5e'], '创意': ['#ffc6e6', '#ff7ec6'], '美食': ['#ffe6a6', '#ffc84f'],
  '语文': ['#d6baff', '#a97cff'], '搞笑': ['#ffbcbc', '#ff7171'], '友情': ['#aef0d2', '#52d3a4'],
  '童话': ['#ffc6e6', '#ff7ec6'], '自然': ['#c0eca6', '#74cc4c'], '运动': ['#b3d4ff', '#549bff'],
  '历史': ['#ecd0a3', '#cc9552'], '动物': ['#cdeba0', '#8ccc4d'], '恐龙': ['#ffe6a6', '#ffc84f'],
  '艺术': ['#dcbaff', '#b27cff']
}
const catGrad = (c) => (CAT_GRAD[c] ? CAT_GRAD[c].join(', ') : '#cfe8ff, #a6d8ff')

const kw = ref('')            // 搜索关键词
const cat = ref('全部')       // "热播"区分类筛选
const all = ref([])           // 全部动画
const favorites = ref([])     // 我的收藏
const loading = ref(true)

const favIds = computed(() => new Set(favorites.value.map(a => a.id)))
const byHot = computed(() => [...all.value].sort((a, b) => b.hot - a.hot))

// 分类列表（由数据动态生成）
const categories = computed(() => {
  const map = new Map()
  all.value.forEach(a => { if (a.category) map.set(a.category, (map.get(a.category) || 0) + 1) })
  return ['全部', ...[...map.entries()].sort((x, y) => y[1] - x[1]).map(e => e[0])]
})
const catCount = (c) => all.value.filter(a => a.category === c).length

// 热播网格：分类筛选 + 热度/默认排序
const hotOnly = ref(false)
const gridList = computed(() => {
  let list = cat.value === '全部' ? all.value : all.value.filter(a => a.category === cat.value)
  return hotOnly.value ? [...list].sort((a, b) => b.hot - a.hot) : list
})

// 搜索
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

// 从侧边栏分类跳转到"全部动画"并选中分类
function goCat(c) {
  tab.value = 'all'
  cat.value = c
  clearKw()
}

// ============================================================
// 轮播 Banner（热度 Top5，自动轮播 6s，右侧缩略图轨可点击切换）
// ============================================================
const banners = computed(() => byHot.value.slice(0, 5))
const bannerIdx = ref(0)
const banner = computed(() => banners.value[bannerIdx.value] || null)
let bannerTimer = null

function startBanner() {
  stopBanner()
  bannerTimer = setInterval(() => {
    if (banners.value.length) bannerIdx.value = (bannerIdx.value + 1) % banners.value.length
  }, 6000)
}
function stopBanner() { if (bannerTimer) { clearInterval(bannerTimer); bannerTimer = null } }
function pickBanner(i) { bannerIdx.value = i; startBanner() }   // 手动切换后重新计时

// 飙升榜（右上角紧凑榜单）
const rankList = computed(() => byHot.value.slice(0, 5))
const rankMedal = (i) => (['🥇', '🥈', '🥉'][i] || (i + 1))

// ============================================================
// 加载 / 收藏
// ============================================================
async function load() {
  if (!props.user || !props.user.id) return
  loading.value = true
  try {
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

// ============================================================
// 视频播放器（保留原有逻辑）
// ============================================================
const playerOpen = ref(false)
const playerUrl = ref('')
const playerTitle = ref('')

const VIDEO_MAP = {
  '海底总动员': 'https://www.baidu.com/sf/vsearch?pd=video&wd=%E6%B5%B7%E5%BA%95%E6%80%BB%E5%8A%A8%E5%91%98%E5%8A%A8%E7%94%BB%E7%89%87&tn=vsearch&lid=c0ccd349000547b6&ie=utf-8&rsv_pq=c0ccd349000547b6&rsv_spt=5&rsv_bp=1&f=8&atn=index',
  '小小发明家': 'https://www.bilibili.com/video/BV1YsBeBmEDo?t=533.5'
}

function play(a) {
  if (!a) return
  const url = VIDEO_MAP[a.title] ||
    ('https://www.baidu.com/sf/vsearch?pd=video&wd=' + encodeURIComponent(a.title + '动画片'))
  if (/bilibili\.(com|tv|cn)/i.test(url)) {
    window.open(url, '_blank', 'noopener')
    return
  }
  playerTitle.value = a.title
  playerUrl.value = url
  playerOpen.value = true
}

function closePlayer() {
  playerOpen.value = false
  playerUrl.value = ''
}

function openExternal() {
  if (playerUrl.value) window.open(playerUrl.value, '_blank', 'noopener')
}

onMounted(() => { load(); startBanner() })
onUnmounted(stopBanner)
</script>

<template>
  <div class="site">
    <!-- ============ 左侧竖版导航栏 ============ -->
    <aside class="side" :class="{ open: sideOpen }">
      <div class="side-logo">
        <span class="logo-badge">🌟</span>
        <span class="logo-name">动画小镇</span>
      </div>

      <nav class="side-nav">
        <button
          v-for="t in navMain" :key="t.key"
          class="snav" :class="{ active: tab === t.key && !searching }"
          type="button" @click="tab = t.key; clearKw(); sideOpen = false"
        >
          <span class="snav-ico">{{ t.icon }}</span>
          <span class="snav-txt">{{ t.label }}</span>
        </button>

        <!-- 后台管理系统入口 -->
        <button class="snav admin-entry" type="button" @click="emit('go-admin'); sideOpen = false">
          <span class="snav-ico">🛡️</span>
          <span class="snav-txt">后台管理系统</span>
        </button>

        <div class="side-sep">动漫频道</div>
        <button
          v-for="c in categories.filter(c => c !== '全部')" :key="'sc' + c"
          class="snav" :class="{ active: tab === 'all' && cat === c && !searching }"
          type="button" @click="goCat(c); sideOpen = false"
        >
          <span class="snav-ico">{{ catEmoji(c) }}</span>
          <span class="snav-txt">{{ c }}</span>
          <span class="snav-cnt">{{ catCount(c) }}</span>
        </button>
      </nav>

      <div class="side-user">
        <span class="u-ava">{{ user.avatar || '🦄' }}</span>
        <span class="u-meta">
          <b class="u-name">{{ user.nickname || '小探险家' }}</b>
          <i class="u-role">{{ roleLabel }}</i>
        </span>
        <button class="u-out" type="button" @click="emit('logout')">退出</button>
      </div>
    </aside>
    <!-- 移动端遮罩 -->
    <div v-if="sideOpen" class="side-mask" @click="sideOpen = false"></div>

    <!-- ============ 右侧主区域 ============ -->
    <div class="main">
      <!-- 顶栏：汉堡(窄屏) + 搜索 + 用户 -->
      <header class="topbar">
        <button class="burger" type="button" @click="sideOpen = !sideOpen" aria-label="菜单">☰</button>

        <div class="search">
          <span class="s-ico">🔍</span>
          <input
            v-model="kw"
            type="text"
            placeholder="搜索动画、分类，例如：恐龙 / 治愈 / 冒险"
            @keyup.enter="tab = 'home'"
          />
          <button v-if="searching" class="s-clear" type="button" @click="clearKw" aria-label="清空">✕</button>
        </div>

        <div class="top-me">
          <span class="top-ava">{{ user.avatar || '🦄' }}</span>
          <span class="top-name">{{ user.nickname || '小探险家' }}</span>
        </div>
      </header>

      <!-- ============ 首页视图 ============ -->
      <template v-if="tab === 'home'">
        <!-- 搜索结果优先展示 -->
        <section v-if="searching" class="sec">
          <h2 class="sec-h">🔎 找到 {{ results.length }} 部相关动画</h2>
          <p v-if="!results.length" class="empty">没有找到相关动画，换个关键词试试～</p>
          <div v-else class="grid">
            <div v-for="a in results" :key="'r' + a.id" class="pcard" :style="{ '--g': catGrad(a.category) }" @click="play(a)">
              <button class="heart" :class="{ on: favIds.has(a.id) }" type="button" @click.stop="toggleFav(a)">
                {{ favIds.has(a.id) ? '❤️' : '🤍' }}
              </button>
              <div class="ppos"><span class="pemoji">{{ a.cover }}</span><span class="pplay">▶</span></div>
              <div class="pinfo">
                <div class="ptitle" :title="a.title">{{ a.title }}</div>
                <div class="pmeta">{{ a.category }} · 🔥{{ a.hot }}</div>
              </div>
            </div>
          </div>
        </section>

        <template v-else>
          <!-- ============ 大幅轮播 Banner（仿腾讯视频首页头图） ============ -->
          <section v-if="banner" class="banner" @mouseenter="stopBanner" @mouseleave="startBanner">
            <div class="bn-bg" :style="{ '--g': catGrad(banner.category) }">
              <span class="bn-emoji">{{ banner.cover }}</span>
            </div>

            <div class="bn-info">
              <span class="bn-badge">✨ 热度 No.{{ bannerIdx + 1 }} · {{ banner.category }}</span>
              <h1 class="bn-title">{{ banner.title }}</h1>
              <p class="bn-desc">{{ banner.description }}</p>
              <div class="bn-meta">
                <span>{{ catEmoji(banner.category) }} {{ banner.category }}</span>
                <i>·</i><span>🔥 热度 {{ banner.hot }}</span>
                <i>·</i><span>{{ favIds.has(banner.id) ? '已收藏' : '未收藏' }}</span>
              </div>
              <div class="bn-btns">
                <button class="bn-play" type="button" @click="play(banner)">▶ 立即播放</button>
                <button
                  class="bn-fav" :class="{ on: favIds.has(banner.id) }" type="button"
                  @click="toggleFav(banner)"
                >{{ favIds.has(banner.id) ? '❤️ 已收藏' : '🤍 收藏' }}</button>
              </div>
            </div>

            <!-- 右侧缩略图轨 -->
            <div class="bn-rail">
              <button
                v-for="(b, i) in banners" :key="'bn' + b.id"
                class="rail-item" :class="{ active: i === bannerIdx }"
                :style="{ '--g': catGrad(b.category) }"
                type="button" @click="pickBanner(i)" :title="b.title"
              >
                <span class="rail-emoji">{{ b.cover }}</span>
                <span class="rail-name">{{ b.title }}</span>
              </button>
            </div>
          </section>

          <!-- ============ 飙升榜（横向紧凑） ============ -->
          <section class="sec">
            <h2 class="sec-h">🔥 飙升榜</h2>
            <div class="ranks">
              <div v-for="(a, i) in rankList" :key="'rk' + a.id" class="rank-chip" @click="play(a)">
                <span class="rk-no" :class="'c' + (i < 3 ? i + 1 : 0)">{{ rankMedal(i) }}</span>
                <span class="rk-emoji" :style="{ '--g': catGrad(a.category) }">{{ a.cover }}</span>
                <div class="rk-main">
                  <div class="rk-title">{{ a.title }}</div>
                  <div class="rk-meta">{{ a.category }} · 🔥{{ a.hot }}</div>
                </div>
                <button class="rk-fav" :class="{ on: favIds.has(a.id) }" type="button" @click.stop="toggleFav(a)">
                  {{ favIds.has(a.id) ? '❤️' : '🤍' }}
                </button>
              </div>
            </div>
          </section>

          <!-- ============ 重烧热播：分类 tabs + 海报网格 ============ -->
          <section class="sec">
            <div class="sec-row">
              <h2 class="sec-h">📺 重烧热播</h2>
              <button class="hot-toggle" :class="{ on: hotOnly }" type="button" @click="hotOnly = !hotOnly">
                {{ hotOnly ? '🔥 热度优先' : '↕ 默认排序' }}
              </button>
            </div>

            <div class="tabs">
              <button
                v-for="c in categories" :key="c"
                :class="{ active: cat === c }" @click="cat = c"
              >{{ c === '全部' ? '全部' : c }}<i v-if="c !== '全部'" class="tab-cnt">{{ catCount(c) }}</i></button>
            </div>

            <p v-if="loading" class="empty">正在加载动画…🌈</p>
            <p v-else-if="!gridList.length" class="empty">这个分类暂时没有动画～</p>
            <div v-else class="grid">
              <div v-for="a in gridList" :key="'g' + a.id" class="pcard" :style="{ '--g': catGrad(a.category) }" @click="play(a)">
                <button class="heart" :class="{ on: favIds.has(a.id) }" type="button" @click.stop="toggleFav(a)">
                  {{ favIds.has(a.id) ? '❤️' : '🤍' }}
                </button>
                <span class="phot">🔥{{ a.hot }}</span>
                <div class="ppos"><span class="pemoji">{{ a.cover }}</span><span class="pplay">▶</span></div>
                <div class="pinfo">
                  <div class="ptitle" :title="a.title">{{ a.title }}</div>
                  <div class="pmeta">{{ a.category }} · {{ a.description }}</div>
                </div>
              </div>
            </div>
          </section>
        </template>
      </template>

      <!-- ============ 全部动画视图 ============ -->
      <section v-else-if="tab === 'all' && !searching" class="sec">
        <h2 class="sec-h">🎬 全部动画（{{ gridList.length }} 部）</h2>
        <div class="tabs">
          <button
            v-for="c in categories" :key="c"
            :class="{ active: cat === c }" @click="cat = c"
          >{{ c === '全部' ? '全部' : catEmoji(c) + ' ' + c }}<i v-if="c !== '全部'" class="tab-cnt">{{ catCount(c) }}</i></button>
        </div>
        <p v-if="loading" class="empty">正在加载动画…🌈</p>
        <p v-else-if="!gridList.length" class="empty">这个分类暂时没有动画～</p>
        <div v-else class="grid">
          <div v-for="a in gridList" :key="'a' + a.id" class="pcard" :style="{ '--g': catGrad(a.category) }" @click="play(a)">
            <button class="heart" :class="{ on: favIds.has(a.id) }" type="button" @click.stop="toggleFav(a)">
              {{ favIds.has(a.id) ? '❤️' : '🤍' }}
            </button>
            <span class="phot">🔥{{ a.hot }}</span>
            <div class="ppos"><span class="pemoji">{{ a.cover }}</span><span class="pplay">▶</span></div>
            <div class="pinfo">
              <div class="ptitle" :title="a.title">{{ a.title }}</div>
              <div class="pmeta">{{ a.category }} · {{ a.description }}</div>
            </div>
          </div>
        </div>
      </section>

      <!-- ============ 我的收藏视图 ============ -->
      <section v-else-if="tab === 'fav' && !searching" class="sec">
        <h2 class="sec-h">⭐ 我的收藏（{{ favorites.length }}）</h2>
        <p v-if="!favorites.length" class="empty">还没有收藏，去首页点 🤍 收藏喜欢的动画吧～</p>
        <div v-else class="grid">
          <div v-for="a in favorites" :key="'f' + a.id" class="pcard" :style="{ '--g': catGrad(a.category) }" @click="play(a)">
            <button class="heart on" type="button" @click.stop="toggleFav(a)">❤️</button>
            <span class="phot">🔥{{ a.hot }}</span>
            <div class="ppos"><span class="pemoji">{{ a.cover }}</span><span class="pplay">▶</span></div>
            <div class="pinfo">
              <div class="ptitle" :title="a.title">{{ a.title }}</div>
              <div class="pmeta">{{ a.category }} · {{ a.description }}</div>
            </div>
          </div>
        </div>
      </section>

      <footer class="foot">动画小镇 · 给小朋友的动画频道 🌟</footer>
    </div>
  </div>

  <!-- ============ 视频播放弹窗（保留） ============ -->
  <div v-if="playerOpen" class="player-mask" @click.self="closePlayer">
    <div class="player">
      <div class="player-head">
        <span class="player-title">▶ {{ playerTitle }}</span>
        <button class="player-close" type="button" @click="closePlayer" aria-label="关闭">✕</button>
      </div>
      <div class="player-frame">
        <iframe v-if="playerUrl" :src="playerUrl" title="动画视频" allow="autoplay; encrypted-media; picture-in-picture" allowfullscreen></iframe>
        <div v-else class="player-loading">稍等，正在打开视频…</div>
      </div>
      <div class="player-foot">
        <span class="player-tip">小提示：若视频未直接播放，点右侧按钮在浏览器中观看 🔗</span>
        <button class="player-open" type="button" @click="openExternal">🔗 在浏览器中打开</button>
      </div>
    </div>
  </div>

  <Toast />
</template>

<style scoped>
/* ============================================================
   明亮儿童风格主题（柔和天空蓝→奶油粉→暖黄，圆润卡片 + 珊瑚粉点缀）
   ============================================================ */
.site {
  --ink: #3a3a5e;          /* 主文字（深蓝紫） */
  --ink-soft: #7a7a9c;     /* 次要文字 */
  --ink-faint: #a6a6c4;    /* 更弱文字 */
  --card: #ffffff;         /* 卡片底色 */
  --line: rgba(120, 140, 190, .16);   /* 描边 */
  --accent: #ff6fa5;       /* 珊瑚粉 */
  --accent2: #6db8ff;      /* 天空蓝 */

  display: flex;
  min-height: 100vh;
  color: var(--ink);
  text-align: left;
  background:
    radial-gradient(circle at 12% 12%, rgba(255, 209, 102, .30), transparent 38%),
    radial-gradient(circle at 88% 8%, rgba(129, 212, 250, .35), transparent 42%),
    radial-gradient(circle at 82% 88%, rgba(186, 255, 201, .30), transparent 45%),
    radial-gradient(circle at 20% 90%, rgba(255, 198, 230, .30), transparent 45%),
    linear-gradient(160deg, #eaf6ff 0%, #fef3ff 46%, #fff7e6 100%);
  background-attachment: fixed;
}

/* ============ 左侧竖版导航栏 ============ */
.side {
  position: fixed; top: 0; bottom: 0; left: 0; z-index: 20;
  width: 200px; flex-shrink: 0;
  display: flex; flex-direction: column;
  background: rgba(255, 255, 255, .85);
  backdrop-filter: blur(10px);
  border-right: 1px solid var(--line);
  box-shadow: 2px 0 24px rgba(120, 140, 190, .12);
  padding: 18px 10px 14px;
  overflow-y: auto;
  scrollbar-width: thin;
  scrollbar-color: #d6def0 transparent;
}
.side::-webkit-scrollbar { width: 4px; }
.side::-webkit-scrollbar-thumb { background: #d6def0; border-radius: 4px; }

.side-logo { display: flex; align-items: center; gap: 8px; padding: 2px 8px 16px; }
.logo-badge {
  width: 34px; height: 34px; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center; font-size: 18px;
  border-radius: 50%;
  background: radial-gradient(circle at 35% 35%, #fff6c8, #ffd23f);
  box-shadow: 0 0 16px rgba(255, 210, 63, .5);
}
.logo-name { font-size: 17px; font-weight: bold; color: var(--ink); letter-spacing: 1px; }

.side-nav { flex: 1; display: flex; flex-direction: column; gap: 2px; }
.side-sep {
  margin: 14px 8px 6px; font-size: 11px; color: var(--ink-faint); letter-spacing: 2px;
}
.snav {
  display: flex; align-items: center; gap: 10px;
  width: 100%; border: none; cursor: pointer; font-family: var(--font);
  background: transparent; color: var(--ink-soft);
  padding: 9px 12px; border-radius: 12px; font-size: 14px;
  transition: .18s; text-align: left;
}
.snav:hover { background: rgba(109, 184, 255, .14); color: var(--ink); }
.snav.active {
  background: linear-gradient(90deg, rgba(255, 111, 165, .20), rgba(109, 184, 255, .12));
  color: var(--accent); font-weight: bold;
}
.snav-ico { font-size: 16px; width: 22px; text-align: center; flex-shrink: 0; }
.snav-txt { flex: 1; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.snav-cnt { font-size: 11px; color: var(--ink-faint); flex-shrink: 0; }

/* 后台管理系统入口：与普通导航稍作区分（蓝紫点缀） */
.admin-entry {
  margin-top: 8px;
  border: 1px dashed rgba(109, 184, 255, .55);
  color: #5b7fd6;
}
.admin-entry:hover { background: rgba(109, 184, 255, .16); color: #3f66c0; }

.side-user {
  display: flex; align-items: center; gap: 8px;
  border-top: 1px solid var(--line);
  padding: 12px 6px 2px; margin-top: 10px;
}
.u-ava {
  font-size: 18px; width: 34px; height: 34px; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center;
  background: #f0f3ff; border-radius: 50%;
}
.u-meta { flex: 1; display: flex; flex-direction: column; line-height: 1.2; min-width: 0; }
.u-name { font-size: 13px; color: var(--ink); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.u-role { font-size: 11px; font-style: normal; color: var(--accent); }
.u-out {
  border: none; cursor: pointer; font-family: var(--font); flex-shrink: 0;
  padding: 6px 10px; border-radius: 10px; font-size: 12px;
  color: var(--ink-soft); background: #f0f3ff; transition: .15s;
}
.u-out:hover { color: var(--ink); background: #e3e9ff; }

.side-mask { display: none; }

/* ============ 主区域 ============ */
.main { flex: 1; min-width: 0; margin-left: 200px; padding: 0 26px 30px; }

/* 顶栏 */
.topbar {
  position: sticky; top: 0; z-index: 15;
  display: flex; align-items: center; gap: 16px;
  padding: 14px 2px;
  background: linear-gradient(180deg, rgba(255, 255, 255, .92), rgba(255, 255, 255, .7) 70%, transparent);
  backdrop-filter: blur(8px);
}
.burger { display: none; }

.search {
  flex: 1; max-width: 560px;
  display: flex; align-items: center; gap: 10px;
  background: #ffffff; border: 1px solid var(--line);
  border-radius: 999px; padding: 9px 18px;
  box-shadow: 0 4px 14px rgba(120, 140, 190, .10);
  transition: .2s;
}
.search:focus-within { border-color: rgba(255, 111, 165, .55); box-shadow: 0 0 0 3px rgba(255, 111, 165, .14); }
.s-ico { font-size: 15px; opacity: .85; }
.search input {
  flex: 1; min-width: 0; border: none; outline: none; background: transparent;
  font-family: var(--font); font-size: 14px; color: var(--ink);
}
.search input::placeholder { color: var(--ink-faint); }
.s-clear {
  border: none; cursor: pointer; background: #eef2ff; color: var(--ink-soft);
  width: 24px; height: 24px; border-radius: 50%; font-size: 12px; line-height: 1; flex-shrink: 0;
}
.s-clear:hover { background: #e0e7ff; color: var(--ink); }

.top-me { display: flex; align-items: center; gap: 8px; margin-left: auto; }
.top-ava { font-size: 20px; }
.top-name { font-size: 13px; color: var(--ink-soft); }

/* ============ 轮播 Banner ============ */
.banner {
  position: relative; display: flex; gap: 20px;
  border-radius: 24px; overflow: hidden;
  min-height: 400px;
  border: 1px solid var(--line);
  box-shadow: 0 16px 40px rgba(120, 140, 190, .18);
  animation: fadeUp .5s ease both;
  isolation: isolate;
}
.bn-bg {
  position: absolute; inset: 0; z-index: -1;
  background: linear-gradient(115deg, #fff6fb 0%, #eaf6ff 100%);
}
.bn-bg::before {
  content: ""; position: absolute; right: -70px; top: -70px;
  width: 360px; height: 360px; border-radius: 50%;
  background: radial-gradient(circle, var(--g, #ffd6e8, #ffb3d9), transparent 70%);
  opacity: .55;
}
.bn-bg::after {
  content: ""; position: absolute; inset: 0;
  background:
    linear-gradient(90deg, rgba(255, 255, 255, .72) 0%, rgba(255, 255, 255, .28) 42%, rgba(255, 255, 255, 0) 72%),
    linear-gradient(0deg, rgba(255, 255, 255, .55), rgba(255, 255, 255, 0) 55%);
}
.bn-emoji {
  position: absolute; right: 12%; top: 50%;
  transform: translateY(-50%) rotate(-6deg);
  font-size: 300px; opacity: .35;
  filter: drop-shadow(0 18px 40px rgba(120, 140, 190, .35));
  animation: bnFloat 7s ease-in-out infinite;
}
@keyframes bnFloat { 0%, 100% { transform: translateY(-52%) rotate(-6deg); } 50% { transform: translateY(-48%) rotate(-3deg); } }

.bn-info {
  align-self: flex-end;
  padding: 34px 30px 34px 34px;
  max-width: 560px;
  animation: fadeUp .6s ease both;
}
.bn-badge {
  display: inline-block; font-size: 12px; font-weight: bold; color: #fff;
  background: linear-gradient(120deg, #ff8fc4, #ff6fa5);
  padding: 4px 12px; border-radius: 999px;
  box-shadow: 0 4px 14px rgba(255, 111, 165, .4);
}
.bn-title {
  margin: 14px 0 8px; font-size: 42px; line-height: 1.15; color: var(--ink);
  text-shadow: 0 2px 10px rgba(255, 255, 255, .6);
}
.bn-desc {
  margin: 0 0 12px; font-size: 14px; color: #5e5e80; line-height: 1.7;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
}
.bn-meta { display: flex; align-items: center; gap: 8px; font-size: 13px; color: var(--ink-soft); margin-bottom: 20px; }
.bn-meta i { font-style: normal; opacity: .5; }
.bn-btns { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.bn-play {
  border: none; cursor: pointer; font-family: var(--font);
  padding: 12px 30px; border-radius: 999px; font-size: 16px; font-weight: bold; color: #fff;
  background: linear-gradient(120deg, #ff6fa5, #ff8fc4);
  box-shadow: 0 8px 22px rgba(255, 111, 165, .4);
  transition: transform .15s, box-shadow .2s;
}
.bn-play:hover { transform: translateY(-2px); box-shadow: 0 12px 28px rgba(255, 111, 165, .5); }
.bn-play:active { transform: scale(.96); }
.bn-fav {
  border: 1px solid rgba(120, 140, 190, .3); cursor: pointer; font-family: var(--font);
  padding: 12px 22px; border-radius: 999px; font-size: 14px; color: var(--ink);
  background: rgba(255, 255, 255, .7); backdrop-filter: blur(4px);
  transition: .18s;
}
.bn-fav:hover { background: rgba(255, 255, 255, .95); }
.bn-fav.on { border-color: transparent; color: #fff; background: linear-gradient(120deg, #ff8fc4, #ff6fa5); }

/* 右侧缩略图轨 */
.bn-rail {
  margin-left: auto; align-self: flex-end;
  display: flex; flex-direction: column; gap: 8px;
  padding: 20px 20px 20px 0;
}
.rail-item {
  position: relative; width: 132px; height: 74px;
  border: 2px solid transparent; border-radius: 14px; overflow: hidden;
  cursor: pointer; font-family: var(--font);
  background: linear-gradient(135deg, var(--g, #cfe8ff, #a6d8ff));
  display: flex; align-items: center; justify-content: center;
  transition: .18s; opacity: .8;
  box-shadow: 0 4px 12px rgba(120, 140, 190, .18);
}
.rail-item:hover { opacity: 1; transform: translateY(-2px); }
.rail-item.active { border-color: #ff6fa5; opacity: 1; box-shadow: 0 6px 18px rgba(255, 111, 165, .4); }
.rail-emoji { font-size: 30px; filter: drop-shadow(0 4px 8px rgba(0, 0, 0, .25)); }
.rail-name {
  position: absolute; left: 0; right: 0; bottom: 0;
  font-size: 11px; color: #fff; text-align: center; padding: 3px 4px;
  background: linear-gradient(transparent, rgba(40, 40, 70, .65));
  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}

/* ============ 内容区块 ============ */
.sec { margin-top: 30px; }
.sec-row { display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
.sec-h {
  margin: 0 0 14px; font-size: 20px; color: var(--ink); letter-spacing: 1px;
  padding-left: 12px; position: relative;
}
.sec-h::before {
  content: ""; position: absolute; left: 0; top: 50%; transform: translateY(-50%);
  width: 4px; height: 18px; border-radius: 4px;
  background: linear-gradient(180deg, #ffb86b, #ff6fa5);
}
.hot-toggle {
  border: 1px solid var(--line); cursor: pointer; font-family: var(--font);
  background: #ffffff; color: var(--ink-soft); font-size: 12px;
  padding: 7px 14px; border-radius: 999px; transition: .18s; margin-bottom: 14px;
  box-shadow: 0 3px 10px rgba(120, 140, 190, .10);
}
.hot-toggle.on {
  color: #fff; border-color: transparent;
  background: linear-gradient(120deg, #ff6fa5, #ff8fc4);
  box-shadow: 0 4px 14px rgba(255, 111, 165, .35);
}

/* 分类 tabs */
.tabs { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 18px; }
.tabs button {
  border: 1px solid var(--line); background: #ffffff; color: var(--ink-soft);
  font-family: var(--font); cursor: pointer; font-size: 13px;
  padding: 7px 16px; border-radius: 999px; transition: .18s;
  display: inline-flex; align-items: center; gap: 6px;
  box-shadow: 0 3px 10px rgba(120, 140, 190, .08);
}
.tabs button:hover { color: var(--ink); border-color: rgba(255, 111, 165, .5); }
.tabs button.active {
  color: #fff; border-color: transparent; font-weight: bold;
  background: linear-gradient(120deg, #ff6fa5, #ff8fc4);
  box-shadow: 0 6px 16px rgba(255, 111, 165, .35);
}
.tab-cnt { font-style: normal; font-size: 11px; opacity: .7; }

/* ============ 海报卡片网格 ============ */
.grid {
  display: grid; gap: 16px;
  grid-template-columns: repeat(auto-fill, minmax(196px, 1fr));
}
.pcard {
  position: relative; border-radius: 16px; overflow: hidden; cursor: pointer;
  background: var(--card); border: 1px solid var(--line);
  box-shadow: 0 8px 20px rgba(120, 140, 190, .14);
  transition: transform .18s, box-shadow .2s, border-color .2s;
  animation: fadeUp .45s ease both;
}
.pcard:hover { transform: translateY(-4px); border-color: rgba(255, 111, 165, .5); box-shadow: 0 16px 34px rgba(120, 140, 190, .24); }
.ppos {
  position: relative; aspect-ratio: 16 / 9;
  background: linear-gradient(135deg, var(--g, #cfe8ff, #a6d8ff));
  display: flex; align-items: center; justify-content: center;
}
.pemoji { font-size: 52px; filter: drop-shadow(0 8px 16px rgba(0, 0, 0, .25)); transition: transform .25s; }
.pcard:hover .pemoji { transform: scale(1.12); }
.pplay {
  position: absolute; inset: 0; display: flex; align-items: center; justify-content: center;
  font-size: 20px; color: #fff;
  background: rgba(40, 40, 70, .42);
  opacity: 0; transition: .2s; pointer-events: none;
}
.pplay::before {
  content: ""; position: absolute; width: 46px; height: 46px; border-radius: 50%;
  background: linear-gradient(120deg, #ff6fa5, #ff8fc4);
  box-shadow: 0 8px 20px rgba(255, 111, 165, .5);
}
.pcard:hover .pplay { opacity: 1; }
.phot {
  position: absolute; top: 8px; left: 8px; z-index: 2;
  font-size: 11px; font-weight: bold; color: #fff;
  background: rgba(40, 40, 70, .55); backdrop-filter: blur(2px);
  padding: 3px 8px; border-radius: 999px;
}
.pinfo { padding: 10px 12px 12px; }
.ptitle { font-size: 14px; font-weight: bold; color: var(--ink); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.pmeta {
  margin-top: 4px; font-size: 12px; color: var(--ink-soft);
  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}
.heart {
  position: absolute; top: 8px; right: 8px; z-index: 2;
  border: none; background: rgba(255, 255, 255, .9);
  cursor: pointer; font-size: 15px; line-height: 1;
  width: 28px; height: 28px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  box-shadow: 0 2px 8px rgba(120, 140, 190, .25);
  transition: transform .15s;
}
.heart:hover { transform: scale(1.18); }
.heart.on { animation: beat .4s ease; }
@keyframes beat { 0% { transform: scale(1); } 50% { transform: scale(1.4); } 100% { transform: scale(1); } }

/* ============ 飙升榜 ============ */
.ranks { display: flex; gap: 12px; flex-wrap: wrap; }
.rank-chip {
  flex: 1; min-width: 210px;
  display: flex; align-items: center; gap: 10px;
  background: var(--card); border: 1px solid var(--line);
  border-radius: 16px; padding: 10px 12px; cursor: pointer;
  box-shadow: 0 8px 20px rgba(120, 140, 190, .14);
  transition: .18s; animation: fadeUp .45s ease both;
}
.rank-chip:hover { border-color: rgba(255, 111, 165, .5); transform: translateY(-2px); box-shadow: 0 12px 26px rgba(120, 140, 190, .22); }
.rk-no { font-size: 14px; flex-shrink: 0; width: 22px; text-align: center; }
.rk-emoji {
  width: 44px; height: 44px; flex-shrink: 0; border-radius: 12px;
  display: flex; align-items: center; justify-content: center; font-size: 24px;
  background: linear-gradient(135deg, var(--g, #cfe8ff, #a6d8ff));
}
.rk-main { flex: 1; min-width: 0; }
.rk-title { font-size: 13px; font-weight: bold; color: var(--ink); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.rk-meta { font-size: 11px; color: var(--ink-soft); margin-top: 2px; }
.rk-fav {
  border: none; background: transparent; cursor: pointer; font-size: 16px; flex-shrink: 0;
  padding: 2px; transition: transform .15s;
}
.rk-fav:hover { transform: scale(1.2); }
.rk-fav.on { animation: beat .4s ease; }
.rk-no.c1 { color: #ff7a59; }
.rk-no.c2 { color: #ffb347; }
.rk-no.c3 { color: #7ec8ff; }
.rk-no.c0 { color: var(--ink-faint); }

/* ============ 通用 ============ */
.empty {
  font-size: 13px; color: var(--ink-soft);
  background: #ffffff; border: 1px dashed var(--line);
  border-radius: 16px; padding: 18px; text-align: center;
}
.foot { margin-top: 40px; text-align: center; font-size: 12px; color: var(--ink-faint); }

@keyframes fadeUp { 0% { transform: translateY(12px); opacity: 0; } 100% { transform: translateY(0); opacity: 1; } }

/* ============ 窄屏适配 ============ */
@media (max-width: 900px) {
  .bn-emoji { font-size: 200px; right: 4%; }
  .bn-rail { flex-direction: row; width: 100%; padding: 0 20px 20px; }
  .rail-item { width: 96px; height: 56px; }
  .banner { flex-wrap: wrap; min-height: 340px; }
  .bn-info { max-width: none; padding: 26px 24px 12px; }
  .bn-title { font-size: 30px; }
}
@media (max-width: 700px) {
  .side {
    transform: translateX(-100%); transition: transform .25s ease;
    width: 230px; box-shadow: 20px 0 50px rgba(80, 100, 160, .25);
  }
  .side.open { transform: translateX(0); }
  .side-mask {
    display: block; position: fixed; inset: 0; z-index: 19;
    background: rgba(60, 80, 140, .35);
  }
  .main { margin-left: 0; padding: 0 14px 24px; }
  .burger {
    display: flex; align-items: center; justify-content: center;
    border: 1px solid var(--line); background: #fff; color: var(--ink);
    width: 38px; height: 38px; border-radius: 12px; font-size: 18px; cursor: pointer; flex-shrink: 0;
  }
  .top-name { display: none; }
  .grid { grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 10px; }
}

/* ============ 视频播放弹窗 ============ */
.player-mask {
  position: fixed; inset: 0; z-index: 60;
  background: rgba(80, 90, 140, .35); backdrop-filter: blur(4px);
  display: flex; align-items: center; justify-content: center; padding: 18px;
  animation: pFade .2s ease both;
}
@keyframes pFade { from { opacity: 0; } to { opacity: 1; } }
.player {
  width: min(96vw, 960px); max-height: 92vh; display: flex; flex-direction: column;
  background: #ffffff; border: 1px solid var(--line); border-radius: 18px; overflow: hidden;
  box-shadow: 0 30px 70px rgba(80, 100, 160, .3);
  animation: fadeUp .3s ease both;
}
.player-head {
  display: flex; align-items: center; justify-content: space-between; gap: 12px;
  padding: 14px 18px; color: #fff;
  background: linear-gradient(120deg, #ff8fc4, #ff6fa5);
}
.player-title { font-size: 17px; font-weight: bold; }
.player-close {
  border: none; cursor: pointer; flex-shrink: 0;
  width: 34px; height: 34px; border-radius: 50%; font-size: 16px; line-height: 1;
  background: rgba(255, 255, 255, .25); color: #fff; transition: .15s;
}
.player-close:hover { background: rgba(255, 255, 255, .45); transform: rotate(90deg); }
.player-frame { position: relative; width: 100%; aspect-ratio: 16 / 9; background: #0a0a12; }
.player-frame iframe { width: 100%; height: 100%; border: none; display: block; }
.player-loading { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; color: #fff; font-size: 15px; }
.player-foot {
  display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap;
  padding: 12px 18px; background: #ffffff;
}
.player-tip { font-size: 12px; color: var(--ink-soft); }
.player-open {
  border: none; cursor: pointer; font-family: var(--font); flex-shrink: 0;
  padding: 10px 18px; border-radius: 12px; font-size: 14px; color: #fff;
  background: linear-gradient(120deg, #ff6fa5, #ff8fc4);
  box-shadow: 0 6px 14px rgba(255, 111, 165, .4); transition: transform .12s;
}
.player-open:hover { transform: translateY(-2px); }
</style>
