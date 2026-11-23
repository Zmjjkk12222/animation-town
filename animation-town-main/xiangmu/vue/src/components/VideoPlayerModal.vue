<script setup>
/**
 * 站内浮动播放器弹层
 *
 * 交互约束：
 * - 全程不跳转页面：不调用 window.open、不修改 location、不渲染外链 <a>
 *   iframe 内部发生的一切跳转都只发生在 iframe 自己的文档里
 * - 关闭即停止：v-if 卸载整个弹层，iframe 从 DOM 移除，视频自然停止
 * - 切换即重建：iframe 的 :key 绑定片源地址，换片会销毁旧节点再建新节点
 */
import { computed, ref, watch, onBeforeUnmount } from 'vue'
import { resolvePlayUrl, toPlaySource } from '../config/video.js'

const props = defineProps({
  open: { type: Boolean, default: false },
  animation: { type: Object, default: null },
  list: { type: Array, default: () => [] }
})

const emit = defineEmits(['close', 'navigate'])

const LOAD_TIMEOUT = 8000

const source = computed(() => toPlaySource(resolvePlayUrl(props.animation)))
const title = computed(() => (props.animation && props.animation.title) || '视频')

const index = computed(() => {
  if (!props.animation || !props.list.length) return -1
  return props.list.findIndex(x => x && x.id === props.animation.id)
})
const canPrev = computed(() => index.value > 0)
const canNext = computed(() => index.value > -1 && index.value < props.list.length - 1)

const loaded = ref(false)
const failed = ref(false)

let loadTimer = null

function clearLoadTimer() {
  if (loadTimer) {
    clearTimeout(loadTimer)
    loadTimer = null
  }
}

function resetState() {
  loaded.value = false
  failed.value = false
  clearLoadTimer()
  if (source.value.kind === 'none') {
    failed.value = true
    return
  }
  loadTimer = setTimeout(() => {
    if (!loaded.value) failed.value = true
  }, LOAD_TIMEOUT)
}

function markLoaded() {
  loaded.value = true
  failed.value = false
  clearLoadTimer()
}

function close() {
  emit('close')
}

function lockScroll(locked) {
  if (typeof document === 'undefined') return
  document.body.style.overflow = locked ? 'hidden' : ''
}

function bindKeys(bind) {
  if (typeof window === 'undefined') return
  if (bind) window.addEventListener('keydown', onKeydown)
  else window.removeEventListener('keydown', onKeydown)
}

function go(step) {
  const i = index.value + step
  if (i < 0 || i >= props.list.length) return
  emit('navigate', props.list[i])
}

function onKeydown(e) {
  if (!props.open) return
  if (e.key === 'Escape') {
    e.preventDefault()
    close()
  } else if (e.key === 'ArrowLeft') {
    e.preventDefault()
    go(-1)
  } else if (e.key === 'ArrowRight') {
    e.preventDefault()
    go(1)
  }
}

watch(
  () => props.open,
  (v) => {
    if (v) {
      resetState()
      lockScroll(true)
      bindKeys(true)
    } else {
      clearLoadTimer()
      lockScroll(false)
      bindKeys(false)
    }
  },
  { immediate: true }
)

watch(source, () => {
  if (props.open) resetState()
})

onBeforeUnmount(() => {
  clearLoadTimer()
  lockScroll(false)
  bindKeys(false)
})
</script>

<template>
  <Teleport to="body">
    <Transition name="vp">
      <div v-if="open" class="vp-mask" @click.self="close">
        <div class="vp-box" role="dialog" aria-modal="true" :aria-label="`播放 ${title}`">
          <header class="vp-head">
            <span class="vp-title">▶ {{ title }}</span>
            <span class="vp-site">
              {{ source.site }}
              <template v-if="index > -1 && list.length > 1">· {{ index + 1 }} / {{ list.length }}</template>
            </span>
            <button class="vp-close" type="button" aria-label="关闭播放器" @click="close">✕</button>
          </header>

          <div class="vp-stage">
            <video
              v-if="source.kind === 'video'"
              :key="source.src"
              class="vp-media"
              :src="source.src"
              controls
              autoplay
              playsinline
              @loadeddata="markLoaded"
              @error="failed = true"
            ></video>

            <iframe
              v-else-if="source.kind === 'iframe'"
              :key="source.src"
              class="vp-media"
              :src="source.src"
              :title="title"
              frameborder="0"
              scrolling="no"
              allow="autoplay; fullscreen; encrypted-media; picture-in-picture"
              allowfullscreen
              @load="markLoaded"
            ></iframe>

            <div v-if="!loaded && !failed" class="vp-hint">
              <span class="vp-spin"></span>
              <span>正在加载视频…</span>
            </div>

            <div v-if="failed" class="vp-hint vp-hint--err">
              <strong>这个片源不允许站内播放</strong>
              <span>请把 src/config/video.js 或数据库 play_url 换成本站可内嵌的地址</span>
            </div>
          </div>

          <footer class="vp-foot">
            <button class="vp-nav" type="button" :disabled="!canPrev" @click="go(-1)">← 上一个</button>
            <span class="vp-tip">Esc 关闭 · ← → 切换 · 点空白处也可关闭</span>
            <button class="vp-nav" type="button" :disabled="!canNext" @click="go(1)">下一个 →</button>
          </footer>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.vp-mask {
  position: fixed; inset: 0; z-index: 90;
  display: flex; align-items: center; justify-content: center;
  padding: 20px;
  background: rgba(26, 30, 52, .58);
  -webkit-backdrop-filter: blur(6px);
  backdrop-filter: blur(6px);
}

.vp-box {
  width: min(94vw, 1040px);
  max-height: 90vh;
  display: flex; flex-direction: column;
  background: #fff; border-radius: 16px; overflow: hidden;
  box-shadow: 0 28px 64px rgba(30, 40, 80, .38);
  font-family: var(--font, "PingFang SC", "Microsoft YaHei", system-ui, sans-serif);
  animation: vpUp .22s ease both;
}

.vp-head {
  display: flex; align-items: center; gap: 10px;
  padding: 12px 16px; color: #fff;
  background: linear-gradient(120deg, #ff8fc4, #ff6fa5);
}

.vp-title {
  flex: 1; min-width: 0;
  font-size: 16px; font-weight: 500;
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}

.vp-site { flex-shrink: 0; font-size: 12px; opacity: .92; }

.vp-close {
  flex-shrink: 0; width: 32px; height: 32px;
  border: none; border-radius: 50%; cursor: pointer;
  background: rgba(255, 255, 255, .25); color: #fff;
  font-size: 15px; line-height: 1;
  transition: background .15s, transform .15s;
}

.vp-close:hover { background: rgba(255, 255, 255, .45); transform: rotate(90deg); }

.vp-stage {
  position: relative; width: 100%;
  aspect-ratio: 16 / 9;
  background: #0a0a12;
}

.vp-media {
  position: absolute; inset: 0;
  width: 100%; height: 100%;
  border: 0; display: block; background: #000;
}

.vp-hint {
  position: absolute; inset: 0;
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  gap: 10px; padding: 20px; text-align: center;
  color: #d8dcf0; font-size: 14px;
}

.vp-hint--err strong { font-size: 15px; font-weight: 500; color: #ffd7d7; }
.vp-hint--err span { font-size: 12px; color: #b9bdd6; max-width: 420px; line-height: 1.6; }

.vp-spin {
  width: 22px; height: 22px; border-radius: 50%;
  border: 2px solid rgba(255, 255, 255, .25);
  border-top-color: #ff8fc4;
  animation: vpSpin .8s linear infinite;
}

.vp-foot {
  display: flex; align-items: center; gap: 12px;
  padding: 12px 16px;
  background: #fff; border-top: 1px solid #f2eef6;
}

.vp-tip { flex: 1; text-align: center; font-size: 12px; color: #8b90a8; }

.vp-nav {
  flex-shrink: 0;
  padding: 8px 14px; border-radius: 10px; cursor: pointer;
  border: 1px solid #ffd3e4; background: #fff6fa; color: #e0488a;
  font-size: 13px; font-family: inherit;
  transition: background .15s;
}

.vp-nav:hover:not(:disabled) { background: #ffe4f0; }
.vp-nav:disabled { opacity: .4; cursor: not-allowed; }

@media (max-width: 640px) {
  .vp-mask { padding: 0; }
  .vp-box { width: 100vw; height: 100dvh; max-height: none; border-radius: 0; }
  .vp-stage { aspect-ratio: auto; flex: 1 1 auto; }
  .vp-tip { display: none; }
}

.vp-enter-active, .vp-leave-active { transition: opacity .18s ease; }
.vp-enter-from, .vp-leave-to { opacity: 0; }

@keyframes vpUp { from { opacity: 0; transform: translateY(12px); } to { opacity: 1; transform: none; } }
@keyframes vpSpin { to { transform: rotate(360deg); } }
</style>
