<script setup>
/**
 * 亲子游戏大厅
 * ---------------------------------------------------------------
 * · 25 款单文件 HTML5 小游戏（MIT，源自 free-html5-games，位于 public/games/）
 *   通过 iframe 嵌入，零外部依赖、离线可玩。
 * · 1 款内置双人游戏「冰娃与火娃」（FireIceGame.vue 直接内嵌渲染）。
 * · 点击卡片弹出全屏游戏窗口，支持关闭/点击遮罩返回大厅。
 */
import { ref, onMounted, watch } from 'vue'
import FireIceGame from './FireIceGame.vue'
import { consumeOpenGame, gameEntryTick } from '../composables/gameEntry.js'

const props = defineProps({
  user: { type: Object, default: null }
})

const active = ref(null) // 当前打开的游戏对象

// key 对应 public/games/<key>/；builtin 表示内置组件，不走 iframe
const games = [
  { key: 'fireice', name: '冰娃与火娃', en: '双人协作闯关', icon: '🧊🔥', tag: '双人', builtin: true },
  { key: 'snake', name: '贪吃蛇', en: 'Snake', icon: '🐍', tag: '经典' },
  { key: 'tetris', name: '方块坠落', en: 'Block Drop', icon: '🧊', tag: '经典' },
  { key: '2048', name: '数字 2048', en: '2048 Puzzle', icon: '🔢', tag: '益智' },
  { key: 'breakout', name: '爆裂打砖块', en: 'Brick Burst', icon: '🧱', tag: '街机' },
  { key: 'whack-a-mole', name: '打地鼠', en: 'Burrow Bop', icon: '🔨', tag: '反应' },
  { key: 'memory-game', name: '记忆翻牌', en: 'Memory Match', icon: '🃏', tag: '益智' },
  { key: 'maze-game', name: '迷宫冲刺', en: 'Maze Dash', icon: '🌀', tag: '闯关' },
  { key: 'platformer', name: '树叶跳跃', en: 'Leaf Leap', icon: '🍃', tag: '闯关' },
  { key: 'endless-runner', name: '机器人跑酷', en: 'Sprint Bot', icon: '🤖', tag: '跑酷' },
  { key: 'puzzle-game', name: '数字华容道', en: 'Slide 15', icon: '📐', tag: '益智' },
  { key: 'match-3', name: '宝石三消', en: 'Gem Swap', icon: '💎', tag: '消除' },
  { key: 'board-game', name: '井字棋', en: 'Tic-Tac-Toe', icon: '⭕', tag: '棋类' },
  { key: 'pong', name: '弹球对决', en: 'Paddle Duel', icon: '🏓', tag: '双人对战' },
  { key: 'space-shooter', name: '星际巡逻', en: 'Nova Patrol', icon: '🚀', tag: '射击' },
  { key: 'racing-game', name: '落日赛车', en: 'Sunset Sprint', icon: '🏎️', tag: '竞速' },
  { key: 'sports-game', name: '投篮高手', en: 'Buzzer Hoops', icon: '🏀', tag: '体育' },
  { key: 'tower-defense', name: '森林守卫', en: 'Grove Guard', icon: '🌳', tag: '策略' },
  { key: 'quiz-game', name: '快速问答', en: 'Quick Quiz', icon: '❓', tag: '知识' },
  { key: 'word-game', name: '单词搜索', en: 'Word Search', icon: '🔤', tag: '知识' },
  { key: 'card-game', name: '高尔夫纸牌', en: 'Golf Solitaire', icon: '🂡', tag: '牌类' },
  { key: 'dress-up-game', name: '换装小屋', en: 'Wardrobe Studio', icon: '👗', tag: '创意' },
  { key: 'drag-and-drop-game', name: '分分类', en: 'Sort It Out', icon: '🧺', tag: '益智' },
  { key: 'clicker-game', name: '闪电工坊', en: 'Bolt Workshop', icon: '⚡', tag: '休闲' },
  { key: 'game-of-life', name: '生命奥秘', en: 'Game of Life', icon: '🔬', tag: '探索' },
  { key: 'casino-games', name: '幸运摇摇乐', en: 'Reel Rush', icon: '🎰', tag: '休闲' },
  { key: 'milk-frog-park', name: '午夜奶片', en: '奶蛙乐园 · 第一人称惊悚迷宫', icon: '👻', tag: '恐怖', dark: true }
]

function open(g) { active.value = g }
function close() { active.value = null }

/** 接受好友邀请后自动打开「冰娃与火娃」（联机入口就在这个游戏里） */
function openNetGame() {
  const g = games.find((x) => x.key === 'fireice')
  if (g) open(g)
}

/** 按 key 打开指定游戏（侧边栏「恐怖游戏」等入口） */
function openByKey(key) {
  if (!key || key === 'fireice') { openNetGame(); return }
  const g = games.find((x) => x.key === key)
  if (g) open(g)
}

// 两种情况都要处理：
// 1. 已经停留在大厅 → watch 直接响应
// 2. 大厅还没挂载（刚切 Tab）→ onMounted 时把请求取走
// consumeOpenGame 返回目标游戏 key（联机邀请默认 'fireice'）；无请求返回 null
function handleEntry() {
  const key = consumeOpenGame()
  if (key) openByKey(key)
}
watch(gameEntryTick, handleEntry)
onMounted(handleEntry)


// 注意：必须用完整文件名 index.html。
// Vite dev server 会把 /games/<key>/ 这种尾斜杠目录请求 fallback 到 SPA 首页，
// 而 /games/<key>/index.html 能正确命中 public 静态文件。
// 这些游戏均为零引用的单文件 HTML，带文件名访问不影响资源解析。
function iframeUrl(key) { return '/games/' + key + '/index.html' }
</script>

<template>
  <div class="hall">
    <h2 class="hall-h">🎮 亲子游戏乐园 <span class="hall-cnt">{{ games.length }} 款</span></h2>
    <p class="hall-tip">点开即玩，全都不需要联网～ 和爸爸妈妈比比谁更厉害吧！</p>

    <div class="hall-grid">
      <button
        v-for="g in games" :key="g.key" class="gcard" :class="{ dark: g.dark }" type="button"
        @click="open(g)"
      >
        <span class="g-tag">{{ g.tag }}</span>
        <span class="g-icon">{{ g.icon }}</span>
        <span class="g-name">{{ g.name }}</span>
        <span class="g-en">{{ g.en }}</span>
        <span class="g-play">▶ 开始</span>
      </button>
    </div>

    <!-- 游戏弹窗 -->
    <div v-if="active" class="gm-mask" @click.self="close">
      <div class="gm-window" :class="{ dark: active.dark }">
        <div class="gm-head">
          <span class="gm-title">{{ active.icon }} {{ active.name }}</span>
          <button class="gm-close" type="button" @click="close" aria-label="关闭">✕</button>
        </div>
        <div class="gm-body">
          <FireIceGame v-if="active.builtin" :user="user" />
          <iframe
            v-else :src="iframeUrl(active.key)" :title="active.name"
            class="gm-frame" allow="autoplay" allowfullscreen
          ></iframe>
        </div>
        <div class="gm-foot">
          <span class="gm-tip">点小按钮 ✕ 或四周灰色区域返回游戏乐园</span>
          <button class="gm-back" type="button" @click="close">← 返回乐园</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.hall { max-width: 900px; margin: 0 auto; }
.hall-h { font-size: 20px; margin: 0 0 4px; }
.hall-cnt {
  font-size: 12px; color: #7a7a9c; font-weight: 400;
  background: #f0f0f8; border-radius: 999px; padding: 2px 10px; vertical-align: 2px;
}
.hall-tip { color: #7a7a9c; font-size: 13px; margin: 0 0 18px; }

.hall-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(148px, 1fr));
  gap: 12px;
}
.gcard {
  position: relative;
  background: #fff;
  border: 1px solid #eee9f5;
  border-radius: 14px;
  padding: 16px 10px 12px;
  display: flex; flex-direction: column; align-items: center; gap: 4px;
  cursor: pointer;
  transition: transform .15s, border-color .15s, box-shadow .15s;
  font-family: inherit;
}
.gcard:hover {
  transform: translateY(-3px);
  border-color: #ff8fa3;
  box-shadow: 0 8px 20px rgba(255, 143, 163, .18);
}
.g-tag {
  position: absolute; top: 8px; left: 8px;
  font-size: 10px; color: #b06ab3;
  background: #f5ecfa; border-radius: 999px; padding: 1px 7px;
}
.g-icon { font-size: 34px; line-height: 1.2; margin-top: 6px; }
.g-name { font-size: 14px; font-weight: 600; color: #3a3a5e; }
.g-en { font-size: 11px; color: #a6a6c4; }
.g-play {
  margin-top: 8px; font-size: 12px; color: #ff6b81; font-weight: 600;
}
/* 恐怖游戏：暗色卡片，和普通益智游戏区分开 */
.gcard.dark {
  background: linear-gradient(160deg, #241d33, #17131f);
  border-color: #3a2f4d;
}
.gcard.dark:hover {
  border-color: #b98cff;
  box-shadow: 0 8px 22px rgba(120, 70, 200, .35);
}
.gcard.dark .g-tag { color: #d9b8ff; background: rgba(185, 140, 255, .18); }
.gcard.dark .g-name { color: #f2eaff; }
.gcard.dark .g-en { color: #a89ac0; }
.gcard.dark .g-play { color: #c79bff; }

/* 弹窗 */
.gm-mask {
  position: fixed; inset: 0; z-index: 200;
  background: rgba(30, 25, 55, .55);
  display: flex; align-items: center; justify-content: center;
  padding: 20px;
}
.gm-window {
  background: #fff; border-radius: 16px;
  width: min(980px, 100%); height: min(700px, 92vh);
  display: flex; flex-direction: column;
  overflow: hidden;
}
.gm-head {
  display: flex; align-items: center; justify-content: space-between;
  padding: 10px 14px; border-bottom: 1px solid #f0eef8;
}
.gm-title { font-size: 15px; font-weight: 600; color: #3a3a5e; }
.gm-close {
  border: none; background: #f3f1fa; color: #7a7a9c;
  width: 30px; height: 30px; border-radius: 50%;
  font-size: 14px; cursor: pointer;
}
.gm-close:hover { background: #ffe3e8; color: #ff6b81; }
.gm-body { flex: 1; background: #1e1937; display: flex; min-height: 0; }
.gm-frame { flex: 1; border: none; width: 100%; height: 100%; background: #fff; }
.gm-body > :deep(div) { flex: 1; }
/* 恐怖游戏弹窗：深色外壳，配合第一人称迷宫的暗色画面 */
.gm-window.dark { background: #17131f; }
.gm-window.dark .gm-head,
.gm-window.dark .gm-foot { border-color: #332a45; }
.gm-window.dark .gm-title { color: #f2eaff; }
.gm-window.dark .gm-close { background: #332a45; color: #d9b8ff; }
.gm-window.dark .gm-tip { color: #8d7fa8; }
.gm-window.dark .gm-back { background: linear-gradient(135deg, #7a5cc0, #5b3fa0); }
/* iframe 内是 pointer-lock 的第一人称游戏：必须允许键盘/焦点，禁掉刷新拖拽 */
.gm-window.dark .gm-frame { background: #0b0809; }
.gm-foot {
  display: flex; align-items: center; justify-content: space-between;
  padding: 8px 14px; border-top: 1px solid #f0eef8;
}
.gm-tip { font-size: 12px; color: #a6a6c4; }
.gm-back {
  border: none; background: linear-gradient(135deg, #ff9a9e, #ff6b81);
  color: #fff; font-size: 13px; font-weight: 600;
  padding: 7px 16px; border-radius: 999px; cursor: pointer;
}
</style>
