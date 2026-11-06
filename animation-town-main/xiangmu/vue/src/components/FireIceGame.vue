<script setup>
/**
 * 亲子双人小游戏：冰娃与火娃 · 闯关
 * ---------------------------------------------------------------
 * 玩法：同屏双人协作闯关（类似《冰娃与火娃》）
 *   · 冰娃（蓝）用 W A D 控制：可以走进水池，碰到岩浆会失败
 *   · 火娃（红）用 方向键 控制：可以走进岩浆，碰到水池会失败
 *   · 绿色毒液两个都不能碰；机关踏板踩下去会永久打开闸门
 *   · 两人都站进自己的门，本关通过
 * 实现：固定步长物理 + 瓦片地图碰撞，Canvas 渲染，无外部依赖。
 */
import { ref, computed, onMounted, onUnmounted } from 'vue'

// ============================================================
// 基础参数
// ============================================================
const T = 32                 // 瓦片尺寸
const COLS = 28
const ROWS = 15
const W = COLS * T
const H = ROWS * T

// 背景星点（静态分布，轻微闪烁）
const STARS = Array.from({ length: 46 }, () => ({
  x: Math.random() * W,
  y: Math.random() * H * 0.55,
  r: Math.random() * 1.4 + 0.4,
  p: Math.random() * Math.PI * 2
}))

const GRAVITY = 2200
const MOVE = 205
const JUMP = 640
const MAX_FALL = 950
const CW = 20                // 角色宽
const CH = 28                // 角色高

// ============================================================
// 关卡数据
//   platforms: [x0, y0, x1, y1] 实心砖块范围（含端点）
//   pools:     { t:'L'岩浆 | 'W'水池 | 'G'毒液, x0, x1, y } 一格深的液体
//   gates:     [x0, y0, x1, y1] 闸门（踩到踏板后打开）
//   plates:    [x, y] 机关踏板
//   gems:      { t:'o' 冰宝石 | '*' 火宝石, x, y }
//   doors/starts: { ice: [x,y], fire: [x,y] }
// ============================================================
const LEVELS = [
  {
    name: '初次相遇',
    hint: '两个人一起爬到右上角的小房子，冰娃走水路、火娃跳岩浆。',
    platforms: [[4, 11, 7, 11], [9, 9, 12, 9], [14, 7, 17, 7], [19, 5, 23, 5]],
    pools: [{ t: 'L', x0: 10, x1: 11, y: 12 }, { t: 'W', x0: 21, x1: 22, y: 12 }],
    gates: [],
    plates: [],
    gems: [
      { t: 'o', x: 5, y: 10 }, { t: 'o', x: 10, y: 8 }, { t: 'o', x: 15, y: 6 },
      { t: '*', x: 6, y: 10 }, { t: '*', x: 11, y: 8 }, { t: '*', x: 20, y: 4 }
    ],
    doors: { ice: [19, 4], fire: [22, 4] },
    starts: { ice: [2, 12], fire: [3, 12] }
  },
  {
    name: '水与火的桥',
    hint: '闸门挡着去路：让一个人爬上左边高台踩住踏板，门就会一直开着。',
    platforms: [[3, 11, 6, 11]],
    pools: [
      { t: 'L', x0: 12, x1: 13, y: 12 },
      { t: 'W', x0: 17, x1: 18, y: 12 }
    ],
    gates: [[21, 4, 21, 12]],
    plates: [[5, 10]],
    gems: [
      { t: 'o', x: 4, y: 10 }, { t: 'o', x: 11, y: 12 }, { t: 'o', x: 22, y: 12 },
      { t: '*', x: 6, y: 10 }, { t: '*', x: 15, y: 12 }, { t: '*', x: 24, y: 12 }
    ],
    doors: { ice: [23, 12], fire: [25, 12] },
    starts: { ice: [2, 12], fire: [3, 12] }
  },
  {
    name: '高塔挑战',
    hint: '先爬上左边高台踩踏板开闸门，跳过毒液池，再一层层爬上高塔。',
    platforms: [[3, 11, 6, 11], [14, 11, 17, 11], [18, 9, 21, 9], [22, 7, 25, 7]],
    pools: [{ t: 'G', x0: 12, x1: 13, y: 12 }],
    gates: [[9, 3, 9, 12]],
    plates: [[5, 10]],
    gems: [
      { t: 'o', x: 15, y: 10 }, { t: 'o', x: 19, y: 8 }, { t: 'o', x: 22, y: 6 },
      { t: '*', x: 16, y: 10 }, { t: '*', x: 20, y: 8 }, { t: '*', x: 24, y: 6 }
    ],
    doors: { ice: [23, 6], fire: [25, 6] },
    starts: { ice: [2, 12], fire: [3, 12] }
  },
  {
    name: '毒沼双桥',
    hint: '中间立着一道光门，先让一人踩下左侧踏板打开它，两人再一起过桥登顶。',
    platforms: [[3, 11, 7, 11], [10, 11, 14, 11], [17, 9, 20, 9], [22, 7, 25, 7]],
    pools: [
      { t: 'L', x0: 16, x1: 16, y: 12 },
      { t: 'W', x0: 19, x1: 19, y: 12 }
    ],
    gates: [[8, 1, 8, 12]],
    plates: [[5, 10]],
    gems: [
      { t: 'o', x: 4, y: 10 }, { t: 'o', x: 11, y: 10 }, { t: 'o', x: 18, y: 8 }, { t: 'o', x: 23, y: 6 },
      { t: '*', x: 6, y: 10 }, { t: '*', x: 12, y: 10 }, { t: '*', x: 19, y: 8 }, { t: '*', x: 24, y: 6 }
    ],
    doors: { ice: [22, 6], fire: [25, 6] },
    starts: { ice: [2, 12], fire: [3, 12] }
  },
  {
    name: '岩浆回廊',
    hint: '地面是一片岩浆，火娃可以大步走过；冰娃要踩着悬浮的冰台一跳一跳过去。',
    platforms: [[2, 11, 4, 11], [7, 10, 9, 10], [12, 9, 14, 9], [17, 8, 19, 8], [22, 7, 24, 7], [24, 5, 26, 5]],
    pools: [
      { t: 'L', x0: 5, x1: 11, y: 12 },
      { t: 'L', x0: 15, x1: 21, y: 12 },
      { t: 'L', x0: 25, x1: 26, y: 12 }
    ],
    gates: [],
    plates: [],
    gems: [
      { t: 'o', x: 8, y: 9 }, { t: 'o', x: 13, y: 8 }, { t: 'o', x: 18, y: 7 }, { t: 'o', x: 23, y: 6 }, { t: 'o', x: 25, y: 4 },
      { t: '*', x: 6, y: 12 }, { t: '*', x: 16, y: 12 }, { t: '*', x: 20, y: 12 }, { t: '*', x: 25, y: 6 }
    ],
    doors: { ice: [24, 4], fire: [26, 4] },
    starts: { ice: [1, 12], fire: [2, 12] }
  },
  {
    name: '毒液高塔',
    hint: '高塔上散落着毒液，两人都不能碰。先踩踏板开门，再一层层往上爬。',
    platforms: [[3, 11, 6, 11], [9, 11, 12, 11], [15, 9, 18, 9], [21, 7, 24, 7], [24, 4, 26, 4]],
    pools: [
      { t: 'G', x0: 7, x1: 8, y: 12 },
      { t: 'G', x0: 13, x1: 14, y: 12 },
      { t: 'W', x0: 19, x1: 19, y: 12 },
      { t: 'L', x0: 22, x1: 22, y: 12 }
    ],
    gates: [[20, 5, 20, 12]],
    plates: [[4, 10]],
    gems: [
      { t: 'o', x: 5, y: 10 }, { t: 'o', x: 10, y: 10 }, { t: 'o', x: 16, y: 8 }, { t: 'o', x: 22, y: 6 }, { t: 'o', x: 25, y: 3 },
      { t: '*', x: 11, y: 10 }, { t: '*', x: 17, y: 8 }, { t: '*', x: 23, y: 6 }, { t: '*', x: 26, y: 3 }
    ],
    doors: { ice: [24, 3], fire: [26, 3] },
    starts: { ice: [2, 12], fire: [3, 12] }
  },
  {
    name: '镜像迷阵',
    hint: '左边岩浆、右边水池，路线像镜子一样对称。各自走安全半边，再到中间会合。',
    platforms: [[3, 11, 7, 11], [10, 9, 13, 9], [17, 11, 21, 11], [20, 7, 23, 7], [24, 5, 26, 5]],
    pools: [
      { t: 'L', x0: 8, x1: 9, y: 12 },
      { t: 'W', x0: 18, x1: 19, y: 12 },
      { t: 'G', x0: 13, x1: 14, y: 12 }
    ],
    gates: [[15, 6, 15, 12]],
    plates: [[5, 10]],
    gems: [
      { t: 'o', x: 4, y: 10 }, { t: 'o', x: 11, y: 8 }, { t: 'o', x: 18, y: 10 }, { t: 'o', x: 21, y: 6 }, { t: 'o', x: 25, y: 4 },
      { t: '*', x: 6, y: 10 }, { t: '*', x: 12, y: 8 }, { t: '*', x: 19, y: 10 }, { t: '*', x: 22, y: 6 }, { t: '*', x: 26, y: 4 }
    ],
    doors: { ice: [24, 4], fire: [26, 4] },
    starts: { ice: [2, 12], fire: [3, 12] }
  },
  {
    name: '终极协作',
    hint: '毒液、岩浆、水池、光门全到齐了。两人密切配合，一起登顶！',
    platforms: [[3, 11, 6, 11], [9, 10, 11, 10], [14, 9, 16, 9], [19, 8, 21, 8], [23, 6, 25, 6], [25, 4, 27, 4]],
    pools: [
      { t: 'L', x0: 7, x1: 8, y: 12 },
      { t: 'G', x0: 12, x1: 13, y: 12 },
      { t: 'W', x0: 17, x1: 18, y: 12 },
      { t: 'L', x0: 22, x1: 22, y: 12 },
      { t: 'G', x0: 24, x1: 24, y: 12 }
    ],
    gates: [[10, 4, 10, 12], [20, 5, 20, 12]],
    plates: [[4, 10], [15, 8]],
    gems: [
      { t: 'o', x: 5, y: 10 }, { t: 'o', x: 10, y: 9 }, { t: 'o', x: 15, y: 8 }, { t: 'o', x: 24, y: 5 }, { t: 'o', x: 26, y: 3 },
      { t: '*', x: 6, y: 10 }, { t: '*', x: 11, y: 9 }, { t: '*', x: 19, y: 7 }, { t: '*', x: 23, y: 5 }, { t: '*', x: 27, y: 3 }
    ],
    doors: { ice: [26, 3], fire: [27, 3] },
    starts: { ice: [2, 12], fire: [3, 12] }
  }
]

// ============================================================
// 运行时状态
// ============================================================
const canvasEl = ref(null)
const state = ref('ready')        // ready | playing | paused | dead | win | done
const level = ref(0)
const levelName = ref(LEVELS[0].name)
const hint = ref(LEVELS[0].hint)
const deadReason = ref('')
const gemsGot = ref(0)
const gemsTotal = ref(0)
const elapsed = ref(0)
const cleared = ref(JSON.parse(localStorage.getItem('town_game_cleared') || '[]'))
const isTouch = ref(false)

let ctx = null
let grid = []                     // 瓦片字符二维数组
let chars = { ice: null, fire: null }
let gemList = []                  // { t, x, y, taken }
let plateOn = false
let raf = null
let lastTs = 0
let acc = 0
let timeAcc = 0
let dpr = 1

// ============================================================
// 粒子系统（宝石闪光 / 通关彩带 / 失败溅射）
// ============================================================
let particles = []
function spawnParticles(x, y, n, opt = {}) {
  for (let i = 0; i < n; i++) {
    const a = Math.random() * Math.PI * 2
    const sp = (opt.speed || 60) * (0.4 + Math.random() * 0.9)
    particles.push({
      x, y,
      vx: Math.cos(a) * sp + (opt.vx || 0),
      vy: Math.sin(a) * sp - (opt.up || 30),
      life: 0,
      max: opt.life || (0.5 + Math.random() * 0.5),
      size: opt.size || (2 + Math.random() * 3),
      color: opt.color || '#fff',
      grav: opt.grav != null ? opt.grav : 240,
      shape: opt.shape || 'dot',
      rot: Math.random() * Math.PI,
      spin: (Math.random() - 0.5) * 8
    })
  }
  if (particles.length > 600) particles.splice(0, particles.length - 600)
}
function updateParticles(dt) {
  for (let i = particles.length - 1; i >= 0; i--) {
    const p = particles[i]
    p.life += dt
    if (p.life >= p.max) { particles.splice(i, 1); continue }
    p.vy += p.grav * dt
    p.x += p.vx * dt
    p.y += p.vy * dt
    p.rot += p.spin * dt
  }
}
function drawStar(cx, cy, R, r, points, color) {
  ctx.beginPath()
  for (let i = 0; i < points * 2; i++) {
    const rad = i % 2 ? r : R
    const a = (Math.PI / points) * i - Math.PI / 2
    const x = cx + Math.cos(a) * rad
    const y = cy + Math.sin(a) * rad
    i ? ctx.lineTo(x, y) : ctx.moveTo(x, y)
  }
  ctx.closePath()
  ctx.fillStyle = color
  ctx.fill()
}
function drawParticles() {
  for (const p of particles) {
    const k = 1 - p.life / p.max
    ctx.globalAlpha = Math.max(0, k)
    ctx.fillStyle = p.color
    if (p.shape === 'rect') {
      ctx.save()
      ctx.translate(p.x, p.y)
      ctx.rotate(p.rot)
      ctx.fillRect(-p.size, -p.size * 0.6, p.size * 2, p.size * 1.2)
      ctx.restore()
    } else if (p.shape === 'star') {
      drawStar(p.x, p.y, p.size * 1.6, p.size * 0.7, 4, p.color)
    } else {
      ctx.beginPath()
      ctx.arc(p.x, p.y, p.size * k + 0.4, 0, Math.PI * 2)
      ctx.fill()
    }
  }
  ctx.globalAlpha = 1
}

const keys = new Set()

// ============================================================
// 关卡构建
// ============================================================
function buildLevel(i) {
  const def = LEVELS[i]
  grid = Array.from({ length: ROWS }, () => Array(COLS).fill('.'))
  // 四周墙体 + 底部两层地面
  for (let y = 0; y < ROWS; y++) { grid[y][0] = '#'; grid[y][COLS - 1] = '#' }
  for (let x = 0; x < COLS; x++) { grid[ROWS - 1][x] = '#'; grid[ROWS - 2][x] = '#' }

  def.platforms.forEach(([x0, y0, x1, y1]) => {
    for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) if (grid[y]) grid[y][x] = '#'
  })
  def.pools.forEach(p => {
    for (let x = p.x0; x <= p.x1; x++) grid[p.y][x] = p.t
  })
  def.gates.forEach(([x0, y0, x1, y1]) => {
    for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) grid[y][x] = 'D'
  })
  def.plates.forEach(([x, y]) => { grid[y][x] = 'P' })

  gemList = def.gems.map(g => ({ ...g, taken: false }))
  plateOn = false

  chars = {
    ice: makeChar('ice', def.starts.ice),
    fire: makeChar('fire', def.starts.fire)
  }

  levelName.value = def.name
  hint.value = def.hint
  gemsGot.value = 0
  gemsTotal.value = gemList.length
  elapsed.value = 0
  timeAcc = 0
}

function makeChar(type, [col, row]) {
  return {
    type,
    x: col * T + (T - CW) / 2,
    y: row * T + (T - CH),
    w: CW, h: CH,
    vx: 0, vy: 0,
    onGround: false,
    coyote: 0,
    face: 1,
    atDoor: false,
    atDoorLatch: false,   // 到达过自己的门即点亮，两人都点亮即通关
    bob: 0
  }
}

// ============================================================
// 碰撞
// ============================================================
const tile = (c, r) => (grid[r] && grid[r][c] !== undefined ? grid[r][c] : '#')

function solid(c, r) {
  const t = tile(c, r)
  if (t === '#') return true
  if (t === 'D') return !plateOn          // 闸门：踩下踏板前是实心
  return false
}

function resolveX(ch) {
  const r0 = Math.floor(ch.y / T)
  const r1 = Math.floor((ch.y + ch.h - 1) / T)
  if (ch.vx > 0) {
    const c = Math.floor((ch.x + ch.w - 1) / T)
    for (let r = r0; r <= r1; r++) if (solid(c, r)) { ch.x = c * T - ch.w; ch.vx = 0; return }
  } else if (ch.vx < 0) {
    const c = Math.floor(ch.x / T)
    for (let r = r0; r <= r1; r++) if (solid(c, r)) { ch.x = (c + 1) * T; ch.vx = 0; return }
  }
}

function resolveY(ch) {
  const c0 = Math.floor(ch.x / T)
  const c1 = Math.floor((ch.x + ch.w - 1) / T)
  if (ch.vy > 0) {
    const r = Math.floor((ch.y + ch.h - 1) / T)
    for (let c = c0; c <= c1; c++) if (solid(c, r)) { ch.y = r * T - ch.h; ch.vy = 0; ch.onGround = true; return }
  } else if (ch.vy < 0) {
    const r = Math.floor(ch.y / T)
    for (let c = c0; c <= c1; c++) if (solid(c, r)) { ch.y = (r + 1) * T; ch.vy = 0; return }
  }
}

/** 角色覆盖到的所有瓦片坐标 */
function tilesOf(ch, inset = 2) {
  const c0 = Math.floor((ch.x + inset) / T)
  const c1 = Math.floor((ch.x + ch.w - 1 - inset) / T)
  const r0 = Math.floor((ch.y + inset) / T)
  const r1 = Math.floor((ch.y + ch.h - 1 - inset) / T)
  const out = []
  for (let r = r0; r <= r1; r++) for (let c = c0; c <= c1; c++) out.push([c, r])
  return out
}

// ============================================================
// 更新
// ============================================================
function update(dt) {
  const ice = chars.ice
  const fire = chars.fire

  stepChar(ice, dt, {
    left: keys.has('KeyA'), right: keys.has('KeyD'), jump: keys.has('KeyW')
  })
  stepChar(fire, dt, {
    left: keys.has('ArrowLeft'), right: keys.has('ArrowRight'), jump: keys.has('ArrowUp')
  })

  // 踏板（踩一下永久打开闸门）
  if (!plateOn) {
    for (const ch of [ice, fire]) {
      if (tilesOf(ch, 4).some(([c, r]) => tile(c, r) === 'P')) { plateOn = true; break }
    }
  }

  // 危险液体
  for (const ch of [ice, fire]) {
    for (const [c, r] of tilesOf(ch, 3)) {
      const t = tile(c, r)
      if (t === 'G') return die(ch, '毒液')
      if (t === 'W' && ch.type === 'fire') return die(ch, '水')
      if (t === 'L' && ch.type === 'ice') return die(ch, '岩浆')
    }
  }

  // 宝石
  for (const g of gemList) {
    if (g.taken) continue
    const owner = g.t === 'o' ? ice : fire
    const gx = g.x * T + T / 2
    const gy = g.y * T + T / 2
    if (gx > owner.x - 6 && gx < owner.x + owner.w + 6 && gy > owner.y - 6 && gy < owner.y + owner.h + 6) {
      g.taken = true
      gemsGot.value++
      const isIce = g.t === 'o'
      spawnParticles(gx, gy, 14, {
        color: isIce ? '#7cc7ff' : '#ff9a5c',
        speed: 95, up: 25, life: 0.7, size: 2.6, shape: 'star'
      })
    }
  }

  // 门（到达即点亮，两人各自到过自己的门即可通关，不再要求同帧同格站位）
  const def = LEVELS[level.value]
  ice.atDoor = inTile(ice, def.doors.ice)
  fire.atDoor = inTile(fire, def.doors.fire)
  ice.atDoorLatch = ice.atDoorLatch || ice.atDoor
  fire.atDoorLatch = fire.atDoorLatch || fire.atDoor

  // 掉出画面保护
  for (const ch of [ice, fire]) {
    if (ch.y > H + 80) return die(ch, '掉落')
  }

  if (ice.atDoorLatch && fire.atDoorLatch) win()

  timeAcc += dt
  elapsed.value = timeAcc
}

function inTile(ch, [c, r]) {
  const cx = ch.x + ch.w / 2
  const feet = ch.y + ch.h - 6
  // 放宽判定：横向容忍半格偏差，纵向覆盖门前平台，落地即可
  return cx > (c - 0.5) * T && cx < (c + 1.5) * T && feet > r * T && feet < (r + 2) * T && ch.onGround
}

function stepChar(ch, dt, input) {
  ch.vx = (input.right ? 1 : 0) - (input.left ? 1 : 0)
  ch.vx *= MOVE
  if (ch.vx) ch.face = Math.sign(ch.vx)

  if (input.jump && (ch.onGround || ch.coyote > 0)) {
    ch.vy = -JUMP
    ch.onGround = false
    ch.coyote = 0
  }

  ch.vy = Math.min(ch.vy + GRAVITY * dt, MAX_FALL)

  ch.x += ch.vx * dt
  resolveX(ch)
  ch.y += ch.vy * dt
  ch.onGround = false
  resolveY(ch)

  ch.coyote = ch.onGround ? 0.1 : Math.max(0, ch.coyote - dt)
  ch.bob += dt * (ch.onGround && ch.vx ? 12 : 4)
}

function die(ch, reason) {
  if (state.value !== 'playing') return
  const cx = ch.x + ch.w / 2
  const cy = ch.y + ch.h / 2
  const col = ch.type === 'ice' ? '#5bb8ff' : '#ff8a5c'
  spawnParticles(cx, cy, 28, { color: col, speed: 140, up: 40, life: 0.85, size: 3 })
  state.value = 'dead'
  deadReason.value = ch.type === 'ice'
    ? `冰娃碰到${reason}啦！`
    : `火娃碰到${reason}啦！`
}

function win() {
  if (state.value !== 'playing') return
  const def = LEVELS[level.value]
  ;[def.doors.ice, def.doors.fire].forEach(([c, r]) => {
    const x = c * T + T / 2
    const y = r * T
    spawnParticles(x, y, 46, { color: '#ff6fa5', speed: 170, up: 130, life: 1.4, size: 3, shape: 'rect', grav: 340 })
    spawnParticles(x, y, 30, { color: '#6db8ff', speed: 150, up: 110, life: 1.4, size: 3, shape: 'rect', grav: 340 })
  })
  state.value = 'win'
  const done = new Set(cleared.value)
  done.add(level.value)
  cleared.value = [...done]
  localStorage.setItem('town_game_cleared', JSON.stringify(cleared.value))
  if (level.value === LEVELS.length - 1 && done.size === LEVELS.length) state.value = 'done'
}

// ============================================================
// 渲染
// ============================================================
function draw(ts) {
  if (!ctx) return
  const t = ts / 1000
  drawBackground(t)
  drawTiles(t)
  drawGems(t)
  drawDoors(t)
  drawChars(t)
  drawParticles()
  drawVignette()
}

// 动态背景：天空渐变 + 星空 + 双层远山视差 + 漂移云朵
function drawBackground(t) {
  const bg = ctx.createLinearGradient(0, 0, 0, H)
  bg.addColorStop(0, '#cfe9ff')
  bg.addColorStop(0.5, '#e9e2ff')
  bg.addColorStop(1, '#ffe9f6')
  ctx.fillStyle = bg
  ctx.fillRect(0, 0, W, H)

  // 星星（柔光轻闪）
  for (const s of STARS) {
    const tw = 0.5 + 0.5 * Math.sin(t * 1.6 + s.p)
    ctx.globalAlpha = 0.3 + tw * 0.5
    ctx.fillStyle = '#ffffff'
    ctx.beginPath(); ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2); ctx.fill()
  }
  ctx.globalAlpha = 1

  // 远山两层视差
  drawHill(H * 0.72, '#cfe3ff', 0.15, 70)
  drawHill(H * 0.83, '#bcd6ff', 0.26, 54)

  // 云朵缓慢漂移
  const off = (t * 11) % (W + 220)
  const cloud = (cx, cy, s, a) => {
    ctx.globalAlpha = a
    ctx.fillStyle = '#ffffff'
    ctx.beginPath()
    ctx.ellipse(cx, cy, 26 * s, 14 * s, 0, 0, Math.PI * 2)
    ctx.ellipse(cx + 22 * s, cy + 4 * s, 20 * s, 11 * s, 0, 0, Math.PI * 2)
    ctx.ellipse(cx - 22 * s, cy + 5 * s, 18 * s, 10 * s, 0, 0, Math.PI * 2)
    ctx.fill()
  }
  cloud((off) - 110, H * 0.16, 1.1, 0.85)
  cloud((off * 0.8 + W * 0.5) % (W + 220) - 110, H * 0.3, 0.85, 0.6)
  ctx.globalAlpha = 1
}

function drawHill(baseY, color, amp, step) {
  ctx.fillStyle = color
  ctx.beginPath()
  ctx.moveTo(0, H)
  ctx.lineTo(0, baseY)
  for (let x = 0; x <= W; x += step) {
    const y = baseY - Math.abs(Math.sin(x * 0.012)) * 40 * amp - Math.sin(x * 0.03) * 8
    ctx.lineTo(x, y)
  }
  ctx.lineTo(W, H)
  ctx.closePath()
  ctx.fill()
}

// 暗角，聚焦画面中心
function drawVignette() {
  const g = ctx.createRadialGradient(W / 2, H / 2, H * 0.35, W / 2, H / 2, H * 0.88)
  g.addColorStop(0, 'rgba(0,0,0,0)')
  g.addColorStop(1, 'rgba(70,60,110,0.18)')
  ctx.fillStyle = g
  ctx.fillRect(0, 0, W, H)
}

function drawTiles(t) {
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
      const ch = grid[r][c]
      const x = c * T, y = r * T
      if (ch === '#') {
        const top = tile(c, r - 1) !== '#'
        // 砖体
        const g = ctx.createLinearGradient(x, y, x, y + T)
        g.addColorStop(0, top ? '#ffffff' : '#eaf1ff')
        g.addColorStop(1, '#cdd9f6')
        ctx.fillStyle = g
        ctx.fillRect(x, y, T, T)
        if (top) {
          // 草边
          ctx.fillStyle = '#9be08a'
          ctx.fillRect(x, y, T, 6)
          ctx.fillStyle = '#7fd06f'
          for (let i = 0; i < T; i += 6) ctx.fillRect(x + i, y + 5, 3, 3)
          ctx.fillStyle = '#ffffff'
          ctx.globalAlpha = 0.5
          ctx.fillRect(x, y, T, 2)
          ctx.globalAlpha = 1
        }
        // 边缘阴影 / 高光
        if (tile(c, r + 1) !== '#') { ctx.fillStyle = '#b9c8ee'; ctx.fillRect(x, y + T - 3, T, 3) }
        if (tile(c - 1, r) !== '#') { ctx.fillStyle = 'rgba(255,255,255,.5)'; ctx.fillRect(x, y, 2, T) }
        if (tile(c + 1, r) !== '#') { ctx.fillStyle = 'rgba(150,170,220,.3)'; ctx.fillRect(x + T - 2, y, 2, T) }
        // 砖缝
        ctx.strokeStyle = 'rgba(150,170,220,.18)'
        ctx.lineWidth = 1
        ctx.strokeRect(x + 0.5, y + 0.5, T - 1, T - 1)
      } else if (ch === 'L' || ch === 'W' || ch === 'G') {
        drawLiquid(x, y, ch, t)
      } else if (ch === 'D') {
        drawGate(x, y)
      } else if (ch === 'P') {
        drawPlate(x, y)
      }
    }
  }
}

function drawLiquid(x, y, kind, t) {
  const palette = {
    L: { top: '#ffd29a', bot: '#ff6f61', glow: 'rgba(255,111,97,.5)' },
    W: { top: '#bfeaff', bot: '#3fa9f5', glow: 'rgba(63,169,245,.5)' },
    G: { top: '#c7f59a', bot: '#5fb82f', glow: 'rgba(95,184,47,.5)' }
  }[kind]
  // 外发光
  ctx.save()
  ctx.shadowColor = palette.glow
  ctx.shadowBlur = 12
  const g = ctx.createLinearGradient(x, y + 5, x, y + T)
  g.addColorStop(0, palette.top)
  g.addColorStop(1, palette.bot)
  ctx.fillStyle = g
  ctx.beginPath()
  ctx.moveTo(x, y + T)
  ctx.lineTo(x, y + 7)
  // 波浪表面（相位按全局坐标，相邻格子自然衔接）
  for (let i = 0; i <= T; i += 4) {
    const wy = y + 7 + Math.sin(t * 2.4 + (x + i) * 0.12) * 2.2
    ctx.lineTo(x + i, wy)
  }
  ctx.lineTo(x + T, y + T)
  ctx.closePath()
  ctx.fill()
  ctx.restore()

  // 上升气泡
  ctx.fillStyle = 'rgba(255,255,255,.5)'
  for (let i = 0; i < 3; i++) {
    const bx = x + 6 + ((i * 11 + t * 14) % (T - 10))
    const by = y + T - 4 - ((t * 18 + i * 13) % (T - 8))
    ctx.beginPath(); ctx.arc(bx, by, 1.5 + (i % 2), 0, Math.PI * 2); ctx.fill()
  }
  // 表面高光
  ctx.fillStyle = 'rgba(255,255,255,.6)'
  ctx.fillRect(x, y + 7, T, 2)
}

function drawGate(x, y) {
  if (plateOn) {
    // 已开启：只留一点淡淡的残影
    ctx.globalAlpha = 0.16
    ctx.fillStyle = '#8fb7ff'
    ctx.fillRect(x + 4, y, T - 8, T)
    ctx.globalAlpha = 1
    return
  }
  // 关闭：整块连续的栅栏，只在上下左右边界画框，避免逐格拼缝
  ctx.fillStyle = '#b3abff'
  ctx.fillRect(x + 2, y, T - 4, T)
  const above = tile(Math.floor(x / T), Math.floor(y / T) - 1) === 'D'
  const below = tile(Math.floor(x / T), Math.floor(y / T) + 1) === 'D'
  if (!above) { ctx.fillStyle = '#9b91f5'; ctx.fillRect(x + 2, y, T - 4, 3) }
  if (!below) { ctx.fillStyle = '#9b91f5'; ctx.fillRect(x + 2, y + T - 3, T - 4, 3) }
  // 横向栏杆
  ctx.fillStyle = 'rgba(255,255,255,.8)'
  ctx.fillRect(x + 6, y + 9, T - 12, 3)
  ctx.fillRect(x + 6, y + 20, T - 12, 3)
  ctx.fillStyle = 'rgba(255,255,255,.35)'
  ctx.fillRect(x + 5, y, 3, T)
}

function drawPlate(x, y) {
  ctx.fillStyle = plateOn ? '#8ee6b4' : '#ffd76e'
  ctx.beginPath()
  ctx.roundRect(x + 4, y + T - 10, T - 8, 9, 4)
  ctx.fill()
  ctx.fillStyle = 'rgba(255,255,255,.75)'
  ctx.beginPath()
  ctx.roundRect(x + 7, y + T - 8, T - 14, 3, 2)
  ctx.fill()
}

function drawGems(t) {
  for (const gm of gemList) {
    if (gm.taken) continue
    const cx = gm.x * T + T / 2
    const cy = gm.y * T + T / 2 + Math.sin(t * 3 + gm.x) * 2
    const isIce = gm.t === 'o'
    const c1 = isIce ? '#dff4ff' : '#ffe2c4'
    const c2 = isIce ? '#3fa9f5' : '#ff7a45'
    // 宝石本体（旋转 + 发光）
    ctx.save()
    ctx.translate(cx, cy)
    ctx.rotate(Math.sin(t * 1.5 + gm.x) * 0.25)
    ctx.shadowColor = isIce ? 'rgba(63,169,245,.8)' : 'rgba(255,122,69,.8)'
    ctx.shadowBlur = 14
    const g = ctx.createLinearGradient(0, -10, 0, 10)
    g.addColorStop(0, c1); g.addColorStop(1, c2)
    ctx.fillStyle = g
    ctx.beginPath()
    ctx.moveTo(0, -10); ctx.lineTo(9, 0); ctx.lineTo(0, 10); ctx.lineTo(-9, 0); ctx.closePath()
    ctx.fill()
    ctx.restore()
    // 十字闪光
    const sp = (Math.sin(t * 4 + gm.x * 2) + 1) * 0.5
    ctx.globalAlpha = 0.35 + sp * 0.5
    drawStar(cx + 11, cy - 9, 3 + sp * 2, 1.2, 4, '#fff')
    ctx.globalAlpha = 1
  }
}

function drawDoors(t) {
  const def = LEVELS[level.value]
  ;[['ice', def.doors.ice], ['fire', def.doors.fire]].forEach(([type, [c, r]]) => {
    const ch = chars[type]
    const x = c * T + 3
    const bottom = (r + 1) * T
    const h = T * 1.15
    const y = bottom - h
    const on = ch && (ch.atDoor || ch.atDoorLatch)   // 站门口或已到达过都点亮
    const col = type === 'ice' ? ['#8fd8ff', '#3fa9f5'] : ['#ffb27a', '#ff6b3d']

    ctx.save()
    if (on) {
      ctx.shadowColor = type === 'ice' ? 'rgba(63,169,245,.85)' : 'rgba(255,107,61,.85)'
      ctx.shadowBlur = 22
    }
    const g = ctx.createLinearGradient(x, y, x, bottom)
    g.addColorStop(0, col[0])
    g.addColorStop(1, col[1])
    ctx.fillStyle = g
    ctx.beginPath()
    ctx.moveTo(x, bottom)
    ctx.lineTo(x, y + 14)
    ctx.quadraticCurveTo(x + (T - 6) / 2, y - 6, x + T - 6, y + 14)
    ctx.lineTo(x + T - 6, bottom)
    ctx.closePath()
    ctx.fill()
    ctx.restore()

    // 门楣小旗（飘动）
    const fx = x + (T - 6) / 2
    const fw = 6 + Math.sin(t * 4 + (type === 'ice' ? 0 : 1.5)) * 2
    ctx.fillStyle = on ? '#ffffff' : 'rgba(255,255,255,.9)'
    ctx.beginPath()
    ctx.moveTo(fx, y - 2)
    ctx.lineTo(fx + fw, y + 2)
    ctx.lineTo(fx, y + 6)
    ctx.closePath(); ctx.fill()

    // 门内图标
    ctx.globalAlpha = 0.95
    ctx.font = '13px sans-serif'
    ctx.textAlign = 'center'
    ctx.fillStyle = '#ffffff'
    ctx.fillText(type === 'ice' ? '❄' : '🔥', fx, bottom - h / 2 + 6)
    ctx.globalAlpha = 1
  })
}

function drawChars(t) {
  ;['ice', 'fire'].forEach(type => {
    const ch = chars[type]
    if (!ch) return
    const cx = ch.x + ch.w / 2
    const cy = ch.y + ch.h / 2 + Math.sin(ch.bob) * 1.2
    const col = type === 'ice'
      ? ['#a8e4ff', '#3fa9f5']
      : ['#ffc48f', '#ff7a45']
    // 起跳/落地轻微挤压
    const squash = ch.vy < 0 ? 0.92 : 1.06
    const w = ch.w
    const hh = ch.h * squash
    const topY = cy - hh / 2

    // 影子
    ctx.globalAlpha = 0.16
    ctx.fillStyle = '#4a3a6b'
    ctx.beginPath()
    ctx.ellipse(cx, ch.y + ch.h + 2, ch.w * 0.55, 4, 0, 0, Math.PI * 2)
    ctx.fill()
    ctx.globalAlpha = 1

    // 身体（发光 + 描边）
    const g = ctx.createLinearGradient(cx, topY, cx, topY + hh)
    g.addColorStop(0, col[0]); g.addColorStop(1, col[1])
    ctx.save()
    ctx.shadowColor = type === 'ice' ? 'rgba(63,169,245,.35)' : 'rgba(255,122,69,.35)'
    ctx.shadowBlur = 8
    ctx.fillStyle = g
    ctx.beginPath()
    ctx.roundRect(ch.x, topY, w, hh, 9)
    ctx.fill()
    ctx.restore()
    ctx.strokeStyle = 'rgba(255,255,255,.85)'
    ctx.lineWidth = 1.5
    ctx.beginPath(); ctx.roundRect(ch.x + 0.8, topY + 0.8, w - 1.6, hh - 1.6, 8); ctx.stroke()

    // 围巾
    ctx.fillStyle = type === 'ice' ? '#ff8fb0' : '#ffd24d'
    ctx.beginPath(); ctx.roundRect(ch.x + 2, topY + hh * 0.42, w - 4, 4, 2); ctx.fill()

    // 高光
    ctx.globalAlpha = 0.5
    ctx.fillStyle = '#ffffff'
    ctx.beginPath(); ctx.roundRect(ch.x + 3, topY + 3, 5, 8, 3); ctx.fill()
    ctx.globalAlpha = 1

    // 眼睛
    const eyeX = ch.face > 0 ? 3 : -3
    ctx.fillStyle = '#3a2f55'
    ctx.beginPath(); ctx.arc(cx + eyeX - 3, cy - 3, 2.1, 0, Math.PI * 2); ctx.fill()
    ctx.beginPath(); ctx.arc(cx + eyeX + 3, cy - 3, 2.1, 0, Math.PI * 2); ctx.fill()
    // 微笑
    ctx.strokeStyle = '#3a2f55'
    ctx.lineWidth = 1.4
    ctx.beginPath()
    ctx.arc(cx + eyeX, cy + 3, 3, 0.25 * Math.PI, 0.75 * Math.PI)
    ctx.stroke()

    // 头顶小装饰
    ctx.font = '11px sans-serif'
    ctx.textAlign = 'center'
    ctx.globalAlpha = 0.9 + Math.sin(t * 3) * 0.1
    ctx.fillText(type === 'ice' ? '❄' : '🔥', cx, topY - 1)
    ctx.globalAlpha = 1
  })
}

// ============================================================
// 主循环
// ============================================================
function loop(ts) {
  raf = requestAnimationFrame(loop)
  if (!lastTs) lastTs = ts
  let dt = Math.min((ts - lastTs) / 1000, 0.1)
  lastTs = ts

  if (state.value === 'playing') {
    acc += dt
    const step = 1 / 120
    let guard = 0
    while (acc >= step && guard < 12) { update(step); acc -= step; guard++ }
    if (guard >= 12) acc = 0
  }
  updateParticles(dt)
  draw(ts)
}

// ============================================================
// 交互
// ============================================================
const TIME_TEXT = computed(() => {
  const s = Math.floor(elapsed.value)
  return `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`
})

const stars = computed(() => {
  if (!gemsTotal.value) return 0
  const p = gemsGot.value / gemsTotal.value
  return p >= 1 ? 3 : p >= 0.6 ? 2 : p >= 0.3 ? 1 : 0
})

function loadLevel(i) {
  level.value = i
  buildLevel(i)
  state.value = 'ready'
  acc = 0
  lastTs = 0
}

function start() {
  if (state.value === 'win' || state.value === 'done') {
    // 下一关或从头再来
    const next = level.value + 1
    loadLevel(next < LEVELS.length ? next : 0)
  } else if (state.value === 'dead') {
    loadLevel(level.value)
  }
  buildIfNeeded()
  state.value = 'playing'
  lastTs = 0
}

function buildIfNeeded() {
  if (!grid.length) buildLevel(level.value)
}

function restart() { loadLevel(level.value); state.value = 'playing' }

/** 关卡按钮：直接进入该关开始玩 */
function playLevel(i) {
  loadLevel(i)
  state.value = 'playing'
}

function pause() {
  if (state.value === 'playing') state.value = 'paused'
  else if (state.value === 'paused') { state.value = 'playing'; lastTs = 0 }
}

// ---- 键盘 ----
const GAME_KEYS = new Set([
  'KeyA', 'KeyD', 'KeyW', 'ArrowLeft', 'ArrowRight', 'ArrowUp', 'Space', 'KeyR', 'KeyP'
])

function onKeyDown(e) {
  if (!GAME_KEYS.has(e.code)) return
  e.preventDefault()
  keys.add(e.code)
  if (e.code === 'Space' && state.value !== 'playing') start()
  if (e.code === 'KeyR') restart()
  if (e.code === 'KeyP') pause()
}

function onKeyUp(e) {
  if (!GAME_KEYS.has(e.code)) return
  e.preventDefault()
  keys.delete(e.code)
}

function clearKeys() { keys.clear() }

// ---- 触屏按键 ----
const touchMap = {
  'ice-left': 'KeyA', 'ice-jump': 'KeyW', 'ice-right': 'KeyD',
  'fire-left': 'ArrowLeft', 'fire-jump': 'ArrowUp', 'fire-right': 'ArrowRight'
}

function pressPad(key) {
  keys.add(touchMap[key])
  if (state.value !== 'playing') start()
}
function releasePad(key) { keys.delete(touchMap[key]) }

// ============================================================
// 生命周期
// ============================================================
onMounted(() => {
  buildLevel(0)
  ctx = canvasEl.value.getContext('2d')
  dpr = Math.min(window.devicePixelRatio || 1, 2)
  canvasEl.value.width = W * dpr
  canvasEl.value.height = H * dpr
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
  ctx.lineJoin = 'round'
  ctx.lineCap = 'round'

  isTouch.value = window.matchMedia('(pointer: coarse)').matches
  window.addEventListener('keydown', onKeyDown)
  window.addEventListener('keyup', onKeyUp)
  window.addEventListener('blur', clearKeys)
  raf = requestAnimationFrame(loop)

  // 仅开发环境：给自动化测试留一个轻量观察/摆位入口
  if (import.meta.env.DEV) {
    window.__fireIce = {
      state,
      ready: () => chars,
      put: (t, col, row) => {
        const ch = chars[t]
        if (!ch) return
        ch.x = col * T + (T - CW) / 2
        ch.y = row * T + (T - CH)
        ch.vy = 0
      }
    }
  }
})

onUnmounted(() => {
  if (raf) cancelAnimationFrame(raf)
  window.removeEventListener('keydown', onKeyDown)
  window.removeEventListener('keyup', onKeyUp)
  window.removeEventListener('blur', clearKeys)
})

defineExpose({ loadLevel, start, playLevel })
</script>

<template>
  <div class="game">
    <header class="g-head">
      <div>
        <span class="g-badge">🎮 亲子双人</span>
        <h2 class="g-title">冰娃与火娃 · 闯关</h2>
        <p class="g-sub">
          一个按 <b>W A D</b> 控冰娃 ❄，一个按 <b>← → ↑</b> 控火娃 🔥，一起走进各自的门
        </p>
      </div>
      <div class="g-levels">
        <button
          v-for="(lv, i) in LEVELS" :key="i"
          class="lv-btn" :class="{ on: level === i }" type="button"
          @click="playLevel(i)"
        >
          {{ i + 1 }}
          <i v-if="cleared.includes(i)" class="lv-ok">✓</i>
        </button>
        <button class="lv-btn ghost" type="button" title="重新开始 (R)" @click="restart">↻</button>
      </div>
    </header>

    <div class="g-stage">
      <canvas ref="canvasEl" class="g-canvas"></canvas>

      <div v-if="state !== 'playing'" class="g-overlay">
        <div class="g-panel">
          <template v-if="state === 'ready'">
            <div class="g-emoji">❄️🔥</div>
            <h3>第 {{ level + 1 }} 关 · {{ levelName }}</h3>
            <p class="g-tip">{{ hint }}</p>
            <ul class="g-rules">
              <li><span class="dot ice"></span>冰娃（蓝）：可走水池，怕岩浆</li>
              <li><span class="dot fire"></span>火娃（红）：可走岩浆，怕水池</li>
              <li><span class="dot goo"></span>绿色毒液：两个都不能碰</li>
            </ul>
            <button class="g-btn" type="button" @click="start">开始游戏（空格）</button>
          </template>

          <template v-else-if="state === 'dead'">
            <div class="g-emoji">💥</div>
            <h3>{{ deadReason }}</h3>
            <p class="g-tip">没关系，再试一次就好啦～</p>
            <button class="g-btn" type="button" @click="start">再来一次（空格）</button>
          </template>

          <template v-else-if="state === 'paused'">
            <div class="g-emoji">⏸️</div>
            <h3>休息一下</h3>
            <button class="g-btn" type="button" @click="pause">继续（P）</button>
          </template>

          <template v-else>
            <div class="g-emoji">🎉</div>
            <h3>{{ state === 'done' ? '全部关卡都通关啦！' : '通关成功！' }}</h3>
            <p class="g-tip">
              宝石 {{ gemsGot }}/{{ gemsTotal }} · 用时 {{ TIME_TEXT }} · 评价 {{ '⭐'.repeat(stars) || '—' }}
            </p>
            <div class="g-row">
              <button class="g-btn" type="button" @click="start">
                {{ state === 'done' ? '再玩一次' : '下一关（空格）' }}
              </button>
              <button class="g-btn ghost" type="button" @click="restart">重玩本关</button>
            </div>
          </template>
        </div>
      </div>
    </div>

    <div class="g-bar">
      <span class="g-chip">第 {{ level + 1 }} 关 · {{ levelName }}</span>
      <span class="g-chip">💎 {{ gemsGot }}/{{ gemsTotal }}</span>
      <span class="g-chip">⏱ {{ TIME_TEXT }}</span>
      <div class="g-spacer"></div>
      <button class="g-btn tiny" type="button" @click="pause">{{ state === 'paused' ? '▶ 继续' : '⏸ 暂停' }}</button>
      <button class="g-btn tiny ghost" type="button" @click="restart">↻ 重开</button>
    </div>

    <div v-if="isTouch" class="g-pads">
      <div class="pad-group">
        <span class="pad-label">❄ 冰娃</span>
        <div class="pad-row">
          <button class="pad" type="button"
            @pointerdown.prevent="pressPad('ice-left')" @pointerup="releasePad('ice-left')" @pointerleave="releasePad('ice-left')">◀</button>
          <button class="pad jump" type="button"
            @pointerdown.prevent="pressPad('ice-jump')" @pointerup="releasePad('ice-jump')" @pointerleave="releasePad('ice-jump')">▲</button>
          <button class="pad" type="button"
            @pointerdown.prevent="pressPad('ice-right')" @pointerup="releasePad('ice-right')" @pointerleave="releasePad('ice-right')">▶</button>
        </div>
      </div>
      <div class="pad-group">
        <span class="pad-label">🔥 火娃</span>
        <div class="pad-row">
          <button class="pad" type="button"
            @pointerdown.prevent="pressPad('fire-left')" @pointerup="releasePad('fire-left')" @pointerleave="releasePad('fire-left')">◀</button>
          <button class="pad jump" type="button"
            @pointerdown.prevent="pressPad('fire-jump')" @pointerup="releasePad('fire-jump')" @pointerleave="releasePad('fire-jump')">▲</button>
          <button class="pad" type="button"
            @pointerdown.prevent="pressPad('fire-right')" @pointerup="releasePad('fire-right')" @pointerleave="releasePad('fire-right')">▶</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.game {
  position: relative; z-index: 1;   /* 压在页面背景装饰之上 */
  background: var(--card, #fffdf9);
  border: 1px solid var(--line, #e8e2f5);
  border-radius: 22px;
  padding: 18px;
  box-shadow: 0 14px 34px rgba(120, 140, 190, .16);
}

.g-head { display: flex; align-items: flex-start; gap: 14px; flex-wrap: wrap; margin-bottom: 14px; }
.g-badge {
  display: inline-block; font-size: 12px; font-weight: bold; color: #fff;
  background: linear-gradient(120deg, #7ec8ff, #6f9bff);
  padding: 3px 10px; border-radius: 999px;
}
.g-title { margin: 8px 0 4px; font-size: 22px; color: var(--ink, #4a3a6b); }
.g-sub { margin: 0; font-size: 13px; color: #7c74a0; }
.g-sub b { color: #ff5fa8; }

.g-levels { margin-left: auto; display: flex; gap: 6px; align-items: center; }
.lv-btn {
  position: relative; width: 34px; height: 34px; border-radius: 11px; cursor: pointer;
  border: 1px solid #e2dcf5; background: #fff; color: var(--ink, #4a3a6b);
  font-family: var(--font); font-size: 13px; font-weight: bold; transition: .18s;
}
.lv-btn:hover { border-color: #ff9fc9; }
.lv-btn.on { background: linear-gradient(120deg, #ff8fc4, #ff6fa5); color: #fff; border-color: transparent; }
.lv-btn.ghost { background: #f6f3ff; border-style: dashed; }
.lv-ok { position: absolute; right: -4px; top: -6px; font-size: 10px; color: #28b06b; font-style: normal; }

.g-stage { position: relative; border-radius: 16px; overflow: hidden; background: #f3f7ff; }
.g-canvas { display: block; width: 100%; height: auto; }

.g-overlay {
  position: absolute; inset: 0; display: flex; align-items: center; justify-content: center;
  background: rgba(245, 248, 255, .78); backdrop-filter: blur(3px); padding: 16px;
}
.g-panel {
  text-align: center; max-width: 460px; background: #fffdf9;
  border: 1px solid #ebe5fb; border-radius: 18px; padding: 20px 22px 22px;
  box-shadow: 0 18px 40px rgba(120, 140, 190, .22);
}
.g-emoji { font-size: 34px; line-height: 1; }
.g-panel h3 { margin: 8px 0 6px; font-size: 19px; color: var(--ink, #4a3a6b); }
.g-tip { margin: 0 0 10px; font-size: 13px; color: #7c74a0; line-height: 1.7; }
.g-rules { list-style: none; margin: 0 0 14px; padding: 0; text-align: left; display: grid; gap: 5px; }
.g-rules li { font-size: 12.5px; color: #6b6490; display: flex; align-items: center; gap: 8px; }
.dot { width: 9px; height: 9px; border-radius: 50%; flex-shrink: 0; }
.dot.ice { background: linear-gradient(120deg, #a8e4ff, #4fb4f0); }
.dot.fire { background: linear-gradient(120deg, #ffc48f, #ff7a45); }
.dot.goo { background: linear-gradient(120deg, #b6e86a, #5fb82f); }

.g-row { display: flex; gap: 8px; justify-content: center; flex-wrap: wrap; }
.g-btn {
  border: none; cursor: pointer; font-family: var(--font); font-size: 14px; font-weight: bold;
  color: #fff; padding: 10px 22px; border-radius: 999px;
  background: linear-gradient(120deg, #ff6fa5, #ff8fc4);
  box-shadow: 0 8px 20px rgba(255, 111, 165, .35); transition: .16s;
}
.g-btn:hover { transform: translateY(-1px); }
.g-btn.ghost { background: #f3f0ff; color: var(--ink, #4a3a6b); box-shadow: none; border: 1px solid #e2dcf5; }
.g-btn.tiny { font-size: 12px; padding: 7px 14px; }

.g-bar { display: flex; align-items: center; gap: 8px; margin-top: 12px; flex-wrap: wrap; }
.g-chip {
  font-size: 12px; color: #6b6490; background: #f6f3ff;
  border: 1px solid #ece7fb; border-radius: 999px; padding: 5px 12px;
}
.g-spacer { flex: 1; }

.g-pads { display: flex; gap: 10px; margin-top: 14px; }
.pad-group { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 6px; }
.pad-label { font-size: 12px; color: #7c74a0; text-align: center; }
.pad-row { display: flex; gap: 6px; justify-content: center; }
.pad {
  width: 52px; height: 46px; border-radius: 13px; cursor: pointer;
  border: 1px solid #e2dcf5; background: #fff; color: var(--ink, #4a3a6b);
  font-size: 16px; touch-action: none;
}
.pad.jump { background: linear-gradient(120deg, #eef4ff, #e3ecff); }
.pad:active { background: #ffe3f0; }

@media (max-width: 720px) {
  .game { padding: 12px; border-radius: 16px; }
  .g-title { font-size: 18px; }
  .g-sub { font-size: 12px; }
  .g-levels { margin-left: 0; }
  .pad { width: 44px; height: 42px; }
  .g-pads { gap: 8px; }
  .pad-row { gap: 5px; }
}
</style>
