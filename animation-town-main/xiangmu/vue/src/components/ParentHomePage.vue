<script setup>
import { ref, computed, onMounted } from 'vue'
import Toast from './Toast.vue'
import { useToast } from '../composables/feedback.js'
import { getRecommend, getFavorites, addFavorite, removeFavorite } from '../api/animation.js'
import { getFriends } from '../api/friend.js'
import VideoPlayerModal from './VideoPlayerModal.vue'

// ============================================================
// 家长首页（ParentHomePage）
// 与儿童首页 HomePage 共用同一套后端接口，但信息组织方式偏「家长视角」：
// 概览数据 → 为孩子挑选 → 收藏管理 → 家长好友，操作按钮更大、文字更直白。
// ============================================================
const props = defineProps({
  user: { type: Object, default: () => ({}) }
})
const emit = defineEmits(['logout', 'go-admin'])
const { toast } = useToast()

// ============================================================
// 导航
// ============================================================
const tab = ref('overview')
const sideOpen = ref(false)
const navMain = [
  { key: 'overview', label: '家长概览', icon: '📊' },
  { key: 'pick', label: '为孩子挑选', icon: '🎬' },
  { key: 'fav', label: '我的收藏', icon: '⭐' },
  { key: 'friends', label: '家长好友', icon: '🤝' }
]

// ============================================================
// 分类配色（与儿童首页保持一致，避免两套视觉）
// ============================================================
const CAT_EMOJI = {
  '冒险': '🌳', '治愈': '⭐', '科普': '🦖', '推理': '🐱', '科幻': '🚀', '音乐': '🎵',
  '科学': '🔧', '创意': '🧱', '美食': '☁️', '语文': '📖', '搞笑': '🤡', '友情': '🤝',
  '童话': '👸', '自然': '🦁', '运动': '🏓', '历史': '🏮', '动物': '🐼', '恐龙': '🦕',
  '艺术': '🎨', '神话': '🐉', '机器人': '🤖', '益智': '🧩', '舞蹈': '🩰', '校园': '🎒',
  '睡前故事': '🌙', '环保': '🌱', '昆虫': '🦋', '交通': '🚄', '国风': '🏯'
}
const catEmoji = (c) => CAT_EMOJI[c] || '🎬'

const CAT_GRAD = {
  '冒险': ['#9be7b4', '#43c97e'], '治愈': ['#cdbcff', '#9c7cff'], '科普': ['#a6e9f3', '#38c3da'],
  '推理': ['#ffd9a6', '#ffa24d'], '科幻': ['#b3caff', '#6290ff'], '音乐': ['#a6d8ff', '#4fabff'],
  '科学': ['#ffd9b0', '#ff9f5e'], '创意': ['#ffc6e6', '#ff7ec6'], '美食': ['#ffe6a6', '#ffc84f'],
  '语文': ['#d6baff', '#a97cff'], '搞笑': ['#ffbcbc', '#ff7171'], '友情': ['#aef0d2', '#52d3a4'],
  '童话': ['#ffc6e6', '#ff7ec6'], '自然': ['#c0eca6', '#74cc4c'], '运动': ['#b3d4ff', '#549bff'],
  '历史': ['#ecd0a3', '#cc9552'], '动物': ['#cdeba0', '#8ccc4d'], '恐龙': ['#ffe6a6', '#ffc84f'],
  '艺术': ['#dcbaff', '#b27cff'], '神话': ['#ffe0b0', '#ffb25e'], '机器人': ['#c9d6ff', '#7f9bff'],
  '益智': ['#b8f0e2', '#4fd4b0'], '舞蹈': ['#ffd0e8', '#ff85c2'], '校园': ['#c8f0b8', '#7ed460'],
  '睡前故事': ['#c8d0f8', '#8a9bff'], '环保': ['#c0f0c8', '#5cd47e'], '昆虫': ['#e0d0ff', '#a88cff'],
  '交通': ['#d0e8ff', '#6ab0ff'], '国风': ['#f3d9b8', '#d8a05e']
}
const catGrad = (c) => (CAT_GRAD[c] ? CAT_GRAD[c].join(', ') : '#cfe8ff, #a6d8ff')

// ============================================================
// 数据
// ============================================================
const all = ref([])
const favorites = ref([])
const friends = ref([])
const loading = ref(true)
const kw = ref('')
const cat = ref('全部')

const userName = computed(() => props.user.nickname || '家长')
const userAvatar = computed(() => props.user.avatar || '👩')

const favIds = computed(() => new Set(favorites.value.map(a => a.id)))
const onlineCount = computed(() => friends.value.filter(f => f.online).length)

const byHot = computed(() => [...all.value].sort((a, b) => b.hot - a.hot))

const categories = computed(() => {
  const map = new Map()
  all.value.forEach(a => { if (a.category) map.set(a.category, (map.get(a.category) || 0) + 1) })
  return ['全部', ...[...map.entries()].sort((x, y) => y[1] - x[1]).map(e => e[0])]
})

// 概览页的「今日推荐」：取热度最高、且还没被收藏的 3 部
const picks = computed(() => byHot.value.filter(a => !favIds.value.has(a.id)).slice(0, 3))
const ranks = computed(() => byHot.value.slice(0, 5))
const recentFavs = computed(() => favorites.value.slice(-4).reverse())

// 「为孩子挑选」列表：分类 + 关键词过滤
const filtered = computed(() => {
  const k = kw.value.trim().toLowerCase()
  return all.value.filter(a => {
    const okCat = cat.value === '全部' || a.category === cat.value
    if (!okCat) return false
    if (!k) return true
    return (a.title || '').toLowerCase().includes(k) ||
      (a.category || '').toLowerCase().includes(k) ||
      (a.description || '').toLowerCase().includes(k)
  })
})

const greeting = (() => {
  const h = new Date().getHours()
  if (h < 6) return '夜深了，注意休息'
  if (h < 12) return '早上好'
  if (h < 14) return '中午好'
  if (h < 18) return '下午好'
  return '晚上好'
})()

// ============================================================
// 加载 / 操作
// ============================================================
async function load() {
  if (!props.user || !props.user.id) {
    loading.value = false
    return
  }
  loading.value = true
  try {
    const [list, fav, fri] = await Promise.all([
      getRecommend(100),
      getFavorites(props.user.id),
      getFriends(props.user.id)
    ])
    all.value = list || []
    favorites.value = fav || []
    friends.value = fri || []
  } catch (err) {
    toast(err.message || '数据加载失败，请稍后再试～')
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

// 播放：站内弹层播放，不跳转页面（地址来源见 src/config/video.js）
const playerOpen = ref(false)
const playerItem = ref(null)

function play(a) {
  if (!a) return
  playerItem.value = a
  playerOpen.value = true
}

function closePlayer() {
  playerOpen.value = false
  playerItem.value = null
}

function go(key) {
  tab.value = key
  sideOpen.value = false
  if (key !== 'pick') kw.value = ''
}

onMounted(load)
</script>

<template>
  <div class="site">
    <!-- ============ 左侧导航 ============ -->
    <aside class="side" :class="{ open: sideOpen }">
      <div class="side-logo">
        <span class="logo-badge">🌟</span>
        <span class="logo-name">动画小镇</span>
      </div>

      <div class="side-role">家长中心</div>

      <nav class="side-nav">
        <button
          v-for="t in navMain" :key="t.key"
          class="snav" :class="{ active: tab === t.key }"
          type="button" @click="go(t.key)"
        >
          <span class="snav-ico">{{ t.icon }}</span>
          <span class="snav-txt">{{ t.label }}</span>
        </button>

        <button class="snav admin-entry" type="button" @click="emit('go-admin'); sideOpen = false">
          <span class="snav-ico">🛡️</span>
          <span class="snav-txt">后台管理系统</span>
        </button>
      </nav>

      <div class="side-user">
        <span class="u-ava">{{ userAvatar }}</span>
        <span class="u-meta">
          <b class="u-name">{{ userName }}</b>
          <i class="u-role">家长</i>
        </span>
        <button class="u-out" type="button" @click="emit('logout')">退出</button>
      </div>
    </aside>
    <div v-if="sideOpen" class="side-mask" @click="sideOpen = false"></div>

    <!-- ============ 主区域 ============ -->
    <div class="main">
      <header class="topbar">
        <button class="burger" type="button" @click="sideOpen = !sideOpen" aria-label="菜单">☰</button>
        <div class="tb-title">
          <b>{{ greeting }}，{{ userName }}</b>
          <i>{{ tab === 'overview' ? '这里是孩子的观看与收藏概况' : '陪孩子一起，看更好的动画' }}</i>
        </div>
        <div class="top-me">
          <span class="top-ava">{{ userAvatar }}</span>
          <span class="top-name">{{ userName }}</span>
        </div>
      </header>

      <p v-if="loading" class="empty">正在加载家长数据…🌈</p>

      <template v-else>
        <!-- ================= 概览 ================= -->
        <template v-if="tab === 'overview'">
          <section class="hero">
            <div class="hero-txt">
              <span class="hero-badge">👨‍👩‍👧 家长视角</span>
              <h1>陪孩子看动画，<br />也能看得放心</h1>
              <p>在这里查看孩子喜欢的动画、管理收藏清单，还能和其他家长互相加好友，随时约一场亲子游戏。</p>
              <div class="hero-btns">
                <button class="btn-primary" type="button" @click="go('pick')">🎬 为孩子挑选</button>
                <button class="btn-ghost" type="button" @click="tab = 'fav'">⭐ 查看收藏</button>
              </div>
            </div>
            <div class="hero-art" aria-hidden="true">
              <span>🧸</span><span>🎬</span><span>🌈</span>
            </div>
          </section>

          <section class="stats">
            <div class="stat">
              <span class="st-ico">⭐</span>
              <b class="st-num">{{ favorites.length }}</b>
              <span class="st-lbl">已收藏动画</span>
            </div>
            <div class="stat">
              <span class="st-ico">🤝</span>
              <b class="st-num">{{ friends.length }}</b>
              <span class="st-lbl">家长好友</span>
            </div>
            <div class="stat">
              <span class="st-ico">🟢</span>
              <b class="st-num">{{ onlineCount }}</b>
              <span class="st-lbl">当前在线</span>
            </div>
            <div class="stat">
              <span class="st-ico">🎬</span>
              <b class="st-num">{{ all.length }}</b>
              <span class="st-lbl">小镇收录</span>
            </div>
          </section>

          <section class="sec">
            <div class="sec-row">
              <h2 class="sec-h">✨ 今日为孩子推荐</h2>
              <button class="link-more" type="button" @click="go('pick')">全部动画 ›</button>
            </div>
            <p v-if="!picks.length" class="empty">暂时没有新的推荐，去收藏里看看孩子喜欢的吧～</p>
            <div v-else class="grid grid-3">
              <div
                v-for="a in picks" :key="'pk' + a.id"
                class="pcard" :style="{ '--g': catGrad(a.category) }"
              >
                <button class="heart" :class="{ on: favIds.has(a.id) }" type="button" @click.stop="toggleFav(a)">
                  {{ favIds.has(a.id) ? '❤️' : '🤍' }}
                </button>
                <div class="ppos" @click="play(a)">
                  <span class="pemoji">{{ a.cover }}</span><span class="pplay">▶</span>
                </div>
                <div class="pinfo">
                  <div class="ptitle" :title="a.title">{{ a.title }}</div>
                  <div class="pmeta">{{ catEmoji(a.category) }} {{ a.category }} · 🔥{{ a.hot }}</div>
                  <p class="pdesc">{{ a.description }}</p>
                </div>
              </div>
            </div>
          </section>

          <div class="two-col">
            <section class="sec">
              <h2 class="sec-h">🔥 小镇热播榜</h2>
              <div class="ranks">
                <div v-for="(a, i) in ranks" :key="'rk' + a.id" class="rank-row" @click="play(a)">
                  <span class="rk-no">{{ ['🥇', '🥈', '🥉'][i] || i + 1 }}</span>
                  <span class="rk-emoji" :style="{ '--g': catGrad(a.category) }">{{ a.cover }}</span>
                  <span class="rk-main">
                    <b class="rk-title">{{ a.title }}</b>
                    <i class="rk-meta">{{ a.category }} · 🔥{{ a.hot }}</i>
                  </span>
                  <button class="rk-fav" :class="{ on: favIds.has(a.id) }" type="button" @click.stop="toggleFav(a)">
                    {{ favIds.has(a.id) ? '❤️' : '🤍' }}
                  </button>
                </div>
              </div>
            </section>

            <section class="sec">
              <div class="sec-row">
                <h2 class="sec-h">⭐ 最近收藏</h2>
                <button class="link-more" type="button" @click="tab = 'fav'">管理 ›</button>
              </div>
              <p v-if="!recentFavs.length" class="empty">还没有收藏，点卡片上的 🤍 就能收藏啦～</p>
              <div v-else class="fav-mini">
                <div v-for="a in recentFavs" :key="'mf' + a.id" class="mini-row">
                  <span class="mini-emoji" :style="{ '--g': catGrad(a.category) }">{{ a.cover }}</span>
                  <span class="mini-main">
                    <b>{{ a.title }}</b>
                    <i>{{ a.category }} · 🔥{{ a.hot }}</i>
                  </span>
                  <button class="mini-play" type="button" @click="play(a)">▶</button>
                </div>
              </div>
            </section>
          </div>
        </template>

        <!-- ================= 为孩子挑选 ================= -->
        <template v-else-if="tab === 'pick'">
          <section class="sec">
            <div class="sec-row">
              <h2 class="sec-h">🎬 为孩子挑选动画</h2>
              <div class="search">
                <span class="s-ico">🔍</span>
                <input v-model="kw" type="text" placeholder="搜索动画名称 / 分类，例如：恐龙 / 睡前故事" />
                <button v-if="kw" class="s-clear" type="button" @click="kw = ''" aria-label="清空">✕</button>
              </div>
            </div>

            <div class="tabs">
              <button
                v-for="c in categories" :key="'c' + c"
                :class="{ active: cat === c }" type="button" @click="cat = c"
              >{{ c }}</button>
            </div>

            <p v-if="!filtered.length" class="empty">没有符合条件的动画，换个关键词试试～</p>
            <div v-else class="grid">
              <div
                v-for="a in filtered" :key="'g' + a.id"
                class="pcard" :style="{ '--g': catGrad(a.category) }"
              >
                <button class="heart" :class="{ on: favIds.has(a.id) }" type="button" @click.stop="toggleFav(a)">
                  {{ favIds.has(a.id) ? '❤️' : '🤍' }}
                </button>
                <span class="phot">🔥{{ a.hot }}</span>
                <div class="ppos" @click="play(a)">
                  <span class="pemoji">{{ a.cover }}</span><span class="pplay">▶</span>
                </div>
                <div class="pinfo">
                  <div class="ptitle" :title="a.title">{{ a.title }}</div>
                  <div class="pmeta">{{ a.category }}</div>
                </div>
              </div>
            </div>
          </section>
        </template>

        <!-- ================= 我的收藏 ================= -->
        <template v-else-if="tab === 'fav'">
          <section class="sec">
            <h2 class="sec-h">⭐ 我的收藏（{{ favorites.length }}）</h2>
            <p v-if="!favorites.length" class="empty">
              还没有收藏任何动画。去「为孩子挑选」里点 🤍 收藏一部吧～
            </p>
            <div v-else class="grid">
              <div
                v-for="a in favorites" :key="'f' + a.id"
                class="pcard" :style="{ '--g': catGrad(a.category) }"
              >
                <button class="heart on" type="button" @click.stop="toggleFav(a)">❤️</button>
                <div class="ppos" @click="play(a)">
                  <span class="pemoji">{{ a.cover }}</span><span class="pplay">▶</span>
                </div>
                <div class="pinfo">
                  <div class="ptitle" :title="a.title">{{ a.title }}</div>
                  <div class="pmeta">{{ catEmoji(a.category) }} {{ a.category }} · 🔥{{ a.hot }}</div>
                </div>
              </div>
            </div>
          </section>
        </template>

        <!-- ================= 家长好友 ================= -->
        <template v-else>
          <section class="sec">
            <h2 class="sec-h">🤝 家长好友（{{ friends.length }}）</h2>
            <p class="sec-tip">
              好友关系与孩子的账号通用，在孩子的首页「我的好友」里也能看到。
              对方连着亲子游戏时会显示「在线」，可以直接约一局。
            </p>
            <p v-if="!friends.length" class="empty">
              还没有好友。请孩子登录后在「我的好友」里按昵称添加小伙伴～
            </p>
            <div v-else class="friend-grid">
              <div v-for="f in friends" :key="'fr' + f.id" class="fcard">
                <span class="f-ava">{{ f.avatar || '🧒' }}</span>
                <span class="f-main">
                  <b class="f-name">{{ f.nickname }}</b>
                  <i class="f-role">{{ f.role === 'parent' ? '家长' : '小朋友' }}</i>
                </span>
                <span class="f-state" :class="{ on: f.online }">
                  {{ f.online ? '在线' : '离线' }}
                </span>
              </div>
            </div>
          </section>
        </template>
      </template>
    </div>

    <VideoPlayerModal
      :open="playerOpen"
      :animation="playerItem"
      :list="all"
      @close="closePlayer"
      @navigate="play"
    />

    <Toast />
  </div>
</template>

<style scoped>
.site {
  --ink: #3a3a5e;
  --ink-soft: #7a7a9c;
  --ink-faint: #a6a6c4;
  --card: #ffffff;
  --line: rgba(120, 140, 190, .16);
  --accent: #ff6fa5;
  --accent2: #6db8ff;

  display: flex;
  min-height: 100vh;
  color: var(--ink);
  text-align: left;
  background:
    radial-gradient(circle at 12% 12%, rgba(255, 209, 102, .28), transparent 38%),
    radial-gradient(circle at 88% 8%, rgba(129, 212, 250, .32), transparent 42%),
    radial-gradient(circle at 82% 88%, rgba(186, 255, 201, .28), transparent 45%),
    radial-gradient(circle at 20% 90%, rgba(255, 198, 230, .28), transparent 45%),
    linear-gradient(160deg, #eaf6ff 0%, #fef3ff 46%, #fff7e6 100%);
  background-attachment: fixed;
}

/* ============ 左侧导航 ============ */
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
.side-logo { display: flex; align-items: center; gap: 8px; padding: 2px 8px 12px; }
.logo-badge {
  width: 34px; height: 34px; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center; font-size: 18px;
  border-radius: 50%;
  background: radial-gradient(circle at 35% 35%, #fff6c8, #ffd23f);
  box-shadow: 0 0 16px rgba(255, 210, 63, .5);
}
.logo-name { font-size: 17px; font-weight: bold; letter-spacing: 1px; }

.side-role {
  margin: 0 8px 10px; padding: 5px 10px;
  font-size: 11px; letter-spacing: 1px; color: #5b7fd6;
  background: rgba(109, 184, 255, .14);
  border-radius: 8px;
  text-align: center;
}

.side-nav { flex: 1; display: flex; flex-direction: column; gap: 2px; }
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
.main { flex: 1; min-width: 0; margin-left: 200px; padding: 0 26px 40px; }

.topbar {
  position: sticky; top: 0; z-index: 15;
  display: flex; align-items: center; gap: 16px;
  padding: 14px 2px;
  background: linear-gradient(180deg, rgba(255, 255, 255, .92), rgba(255, 255, 255, .7) 70%, transparent);
  backdrop-filter: blur(8px);
}
.burger { display: none; }
.tb-title { display: flex; flex-direction: column; line-height: 1.35; }
.tb-title b { font-size: 16px; }
.tb-title i { font-size: 12px; font-style: normal; color: var(--ink-soft); }
.top-me { display: flex; align-items: center; gap: 8px; margin-left: auto; }
.top-ava { font-size: 22px; }
.top-name { font-size: 13px; color: var(--ink-soft); }

/* ============ Hero ============ */
.hero {
  position: relative; overflow: hidden;
  display: flex; align-items: center; justify-content: space-between; gap: 20px;
  margin-top: 6px; padding: 30px 34px;
  border-radius: 24px;
  background:
    radial-gradient(circle at 88% 20%, rgba(255, 255, 255, .6), transparent 40%),
    linear-gradient(120deg, #ffd9ea 0%, #e8e2ff 52%, #d9f0ff 100%);
  box-shadow: 0 18px 40px rgba(120, 140, 190, .18);
  border: 1px solid rgba(255, 255, 255, .7);
}
.hero-txt { max-width: 560px; position: relative; z-index: 1; }
.hero-badge {
  display: inline-block; margin-bottom: 10px; padding: 5px 12px;
  font-size: 12px; color: #a8427a;
  background: rgba(255, 255, 255, .72);
  border-radius: 999px;
}
.hero h1 { margin: 0 0 10px; font-size: 28px; line-height: 1.35; letter-spacing: .5px; }
.hero p { margin: 0 0 18px; font-size: 14px; line-height: 1.75; color: #6a6a8e; }
.hero-btns { display: flex; gap: 12px; flex-wrap: wrap; }
.btn-primary, .btn-ghost {
  border: none; cursor: pointer; font-family: var(--font);
  padding: 11px 22px; border-radius: 999px; font-size: 14px; font-weight: bold;
  transition: .18s;
}
.btn-primary {
  color: #fff;
  background: linear-gradient(120deg, #ff8fc4, #ff5fa8);
  box-shadow: 0 10px 22px rgba(255, 95, 168, .34);
}
.btn-primary:hover { transform: translateY(-2px); box-shadow: 0 14px 26px rgba(255, 95, 168, .42); }
.btn-ghost { color: #5b5b86; background: rgba(255, 255, 255, .8); }
.btn-ghost:hover { background: #fff; }

.hero-art {
  display: flex; align-items: flex-end; gap: 6px;
  font-size: 54px; line-height: 1;
  filter: drop-shadow(0 10px 18px rgba(120, 140, 190, .28));
}
.hero-art span:nth-child(2) { font-size: 66px; transform: translateY(-8px); }

/* ============ 统计卡 ============ */
.stats {
  display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px;
  margin-top: 20px;
}
.stat {
  display: flex; flex-direction: column; align-items: flex-start; gap: 2px;
  padding: 16px 18px;
  background: rgba(255, 255, 255, .92);
  border: 1px solid var(--line);
  border-radius: 18px;
  box-shadow: 0 8px 20px rgba(120, 140, 190, .10);
}
.st-ico { font-size: 18px; }
.st-num { font-size: 26px; line-height: 1.2; }
.st-lbl { font-size: 12px; color: var(--ink-soft); }

/* ============ 通用区块 ============ */
.sec { margin-top: 28px; }
.sec-row {
  display: flex; align-items: center; justify-content: space-between; gap: 16px;
  flex-wrap: wrap;
}
.sec-h { margin: 0 0 12px; font-size: 18px; letter-spacing: .5px; }
.sec-row .sec-h { margin-bottom: 12px; }
.sec-tip {
  margin: 0 0 14px; padding: 10px 14px;
  font-size: 12.5px; line-height: 1.7; color: #5b7fd6;
  background: rgba(109, 184, 255, .12);
  border-left: 3px solid rgba(109, 184, 255, .6);
  border-radius: 10px;
}
.link-more {
  border: none; background: transparent; cursor: pointer; font-family: var(--font);
  font-size: 13px; color: var(--accent2);
}
.link-more:hover { color: #3f8fe0; text-decoration: underline; }
.empty {
  margin: 18px 0; padding: 26px 16px;
  text-align: center; font-size: 13px; color: var(--ink-faint);
  background: rgba(255, 255, 255, .6);
  border-radius: 16px;
  border: 1px dashed var(--line);
}

.two-col {
  display: grid; grid-template-columns: 1fr 1fr; gap: 26px;
}

/* ============ 海报网格 ============ */
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(168px, 1fr)); gap: 16px; }
.grid-3 { grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); }

.pcard {
  position: relative; overflow: hidden;
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 18px;
  box-shadow: 0 8px 20px rgba(120, 140, 190, .12);
  transition: .2s;
}
.pcard:hover { transform: translateY(-4px); border-color: rgba(255, 111, 165, .5); box-shadow: 0 16px 34px rgba(120, 140, 190, .24); }

.heart {
  position: absolute; top: 10px; right: 10px; z-index: 2;
  width: 30px; height: 30px; border: none; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-size: 14px; cursor: pointer;
  background: rgba(255, 255, 255, .86);
  box-shadow: 0 4px 10px rgba(120, 140, 190, .18);
  transition: .16s;
}
.heart:hover { transform: scale(1.12); }
.phot {
  position: absolute; top: 12px; left: 12px; z-index: 2;
  padding: 3px 9px; font-size: 11px; color: #fff;
  background: rgba(255, 111, 165, .9);
  border-radius: 999px;
}

.ppos {
  position: relative; cursor: pointer;
  height: 130px;
  display: flex; align-items: center; justify-content: center;
  background: linear-gradient(135deg, var(--g, #cfe8ff));
}
.grid-3 .ppos { height: 150px; }
.pemoji { font-size: 46px; filter: drop-shadow(0 6px 10px rgba(0, 0, 0, .12)); transition: .22s; }
.pcard:hover .pemoji { transform: scale(1.12); }
.pplay {
  position: absolute; inset: 0;
  display: flex; align-items: center; justify-content: center;
  font-size: 30px; color: #fff;
  background: rgba(58, 58, 94, .22);
  opacity: 0; transition: .2s;
}
.pcard:hover .pplay { opacity: 1; }

.pinfo { padding: 12px 14px 14px; }
.ptitle {
  font-size: 14px; font-weight: bold;
  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}
.pmeta { margin-top: 4px; font-size: 11.5px; color: var(--ink-soft); }
.pdesc {
  margin: 6px 0 0; font-size: 12px; line-height: 1.6; color: var(--ink-faint);
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
}

/* ============ 榜单 ============ */
.ranks { display: flex; flex-direction: column; gap: 8px; }
.rank-row {
  display: flex; align-items: center; gap: 12px;
  padding: 10px 14px; cursor: pointer;
  background: rgba(255, 255, 255, .9);
  border: 1px solid var(--line);
  border-radius: 14px;
  transition: .16s;
}
.rank-row:hover { transform: translateX(3px); border-color: rgba(255, 111, 165, .45); }
.rk-no { width: 24px; text-align: center; font-size: 14px; color: var(--ink-faint); flex-shrink: 0; }
.rk-emoji {
  width: 40px; height: 40px; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center;
  font-size: 20px; border-radius: 12px;
  background: linear-gradient(135deg, var(--g, #cfe8ff));
}
.rk-main { flex: 1; min-width: 0; display: flex; flex-direction: column; line-height: 1.35; }
.rk-title { font-size: 13.5px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.rk-meta { font-size: 11.5px; font-style: normal; color: var(--ink-faint); }
.rk-fav {
  width: 30px; height: 30px; flex-shrink: 0;
  border: none; border-radius: 50%; cursor: pointer;
  background: #f0f3ff; font-size: 13px; transition: .16s;
}
.rk-fav:hover { transform: scale(1.1); background: #e3e9ff; }

/* ============ 最近收藏 ============ */
.fav-mini { display: flex; flex-direction: column; gap: 8px; }
.mini-row {
  display: flex; align-items: center; gap: 12px;
  padding: 9px 12px;
  background: rgba(255, 255, 255, .9);
  border: 1px solid var(--line);
  border-radius: 14px;
}
.mini-emoji {
  width: 38px; height: 38px; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center;
  font-size: 18px; border-radius: 12px;
  background: linear-gradient(135deg, var(--g, #cfe8ff));
}
.mini-main { flex: 1; min-width: 0; display: flex; flex-direction: column; line-height: 1.35; }
.mini-main b { font-size: 13.5px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.mini-main i { font-size: 11.5px; font-style: normal; color: var(--ink-faint); }
.mini-play {
  width: 30px; height: 30px; flex-shrink: 0;
  border: none; border-radius: 50%; cursor: pointer;
  color: #fff; background: linear-gradient(120deg, #ff8fc4, #ff5fa8);
  font-size: 12px; transition: .16s;
}
.mini-play:hover { transform: scale(1.1); }

/* ============ 搜索 / 分类 tabs ============ */
.search {
  display: flex; align-items: center; gap: 9px;
  background: #fff; border: 1px solid var(--line);
  border-radius: 999px; padding: 8px 16px;
  min-width: 280px;
  box-shadow: 0 4px 14px rgba(120, 140, 190, .10);
}
.search:focus-within { border-color: rgba(255, 111, 165, .55); box-shadow: 0 0 0 3px rgba(255, 111, 165, .14); }
.s-ico { font-size: 14px; opacity: .85; }
.search input {
  flex: 1; min-width: 0; border: none; outline: none; background: transparent;
  font-family: var(--font); font-size: 13.5px; color: var(--ink);
}
.search input::placeholder { color: var(--ink-faint); }
.s-clear {
  width: 22px; height: 22px; flex-shrink: 0;
  border: none; border-radius: 50%; cursor: pointer;
  background: #eef2ff; color: var(--ink-soft); font-size: 11px;
}

.tabs { display: flex; flex-wrap: wrap; gap: 8px; margin: 4px 0 16px; }
.tabs button {
  border: 1px solid var(--line); cursor: pointer; font-family: var(--font);
  background: rgba(255, 255, 255, .86); color: var(--ink-soft);
  padding: 7px 16px; border-radius: 999px; font-size: 13px;
  transition: .16s;
}
.tabs button:hover { color: var(--ink); border-color: rgba(109, 184, 255, .5); }
.tabs button.active {
  color: #fff; font-weight: bold; border-color: transparent;
  background: linear-gradient(120deg, #ff8fc4, #ff5fa8);
  box-shadow: 0 8px 18px rgba(255, 95, 168, .3);
}

/* ============ 好友 ============ */
.friend-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 12px; }
.fcard {
  display: flex; align-items: center; gap: 12px;
  padding: 14px 16px;
  background: rgba(255, 255, 255, .92);
  border: 1px solid var(--line);
  border-radius: 16px;
  box-shadow: 0 8px 18px rgba(120, 140, 190, .10);
}
.f-ava {
  width: 42px; height: 42px; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center;
  font-size: 20px; border-radius: 50%;
  background: #f0f3ff;
}
.f-main { flex: 1; min-width: 0; display: flex; flex-direction: column; line-height: 1.3; }
.f-name { font-size: 14px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.f-role { font-size: 11.5px; font-style: normal; color: var(--ink-faint); }
.f-state {
  flex-shrink: 0; padding: 4px 10px;
  font-size: 11px; border-radius: 999px;
  color: var(--ink-faint); background: #f0f3ff;
}
.f-state.on { color: #1f9d63; background: rgba(126, 224, 192, .24); }

/* ============ 响应式 ============ */
@media (max-width: 1100px) {
  .two-col { grid-template-columns: 1fr; gap: 4px; }
  .stats { grid-template-columns: repeat(2, 1fr); }
  .hero-art { display: none; }
}

@media (max-width: 860px) {
  .side {
    transform: translateX(-100%);
    transition: transform .24s;
  }
  .side.open { transform: translateX(0); }
  .side-mask {
    display: block; position: fixed; inset: 0; z-index: 19;
    background: rgba(58, 58, 94, .32);
    backdrop-filter: blur(2px);
  }
  .main { margin-left: 0; padding: 0 16px 32px; }
  .burger {
    display: flex; align-items: center; justify-content: center;
    width: 38px; height: 38px; flex-shrink: 0;
    border: 1px solid var(--line); border-radius: 12px;
    background: #fff; font-size: 16px; cursor: pointer; color: var(--ink);
  }
  .top-me { display: none; }
  .hero { padding: 22px 20px; }
  .hero h1 { font-size: 22px; }
  .search { min-width: 0; width: 100%; }
}
</style>
