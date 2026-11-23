/**
 * 视频播放地址配置 —— 全站唯一的播放地址来源
 *
 * 取址优先级（高 → 低）：
 *   1. 动画数据自带的 playUrl（来自后端 town_animation.play_url 字段，可后台/数据库直接改）
 *   2. VIDEO_MAP 里按标题配置的地址（前端常量，适合临时覆盖个别动画）
 *   3. DEFAULT_PLAY_URL 全局默认地址
 *
 * 注意：任何情况下都不会再拼接搜索页地址。没配就是没配，不会跳去百度。
 */

// 全局默认播放地址：DB 和 VIDEO_MAP 都没配时的兜底。
// 换成你们选定的视频地址即可（B 站 / 腾讯视频 / 自有 CDN 的 mp4 都行）。
export const DEFAULT_PLAY_URL = 'https://www.bilibili.com/video/BV1YsBeBmEDo'

// 按动画标题覆盖。标题需与数据库 town_animation.title 完全一致。
export const VIDEO_MAP = {
  '小小发明家': 'https://www.bilibili.com/video/BV1YsBeBmEDo'
}

/**
 * 解析某个动画应该打开的视频地址
 * @param {object} animation 动画对象，至少含 title，可选 playUrl
 * @returns {string} 视频地址；理论上恒非空（最差返回 DEFAULT_PLAY_URL）
 */
export function resolvePlayUrl(animation) {
  if (!animation) return DEFAULT_PLAY_URL

  const own = typeof animation.playUrl === 'string' ? animation.playUrl.trim() : ''
  if (own) return own

  const mapped = VIDEO_MAP[animation.title]
  if (mapped) return mapped

  return DEFAULT_PLAY_URL
}

/* ------------------------------------------------------------------
 * 站内弹层播放：把「观看页地址」规范化成「可被 iframe 嵌入的播放器地址」
 *
 * 这一步是必须的：B 站 / YouTube 的观看页都返回 X-Frame-Options: DENY
 * 或 CSP frame-ancestors，直接塞进 iframe 会白屏。必须换成官方 embed 端。
 * ------------------------------------------------------------------ */

const RE_BV = /bilibili\.com\/video\/(BV[0-9A-Za-z]+)/i
const RE_AV = /bilibili\.com\/video\/av(\d+)/i
const RE_YT = /(?:youtube\.com\/watch\?(?:[^#]*&)?v=|youtu\.be\/)([\w-]{6,})/i
const RE_VIMEO = /vimeo\.com\/(\d+)/
const RE_FILE = /\.(mp4|webm|ogg|m3u8)(\?|#|$)/i

/**
 * @param {string} rawUrl 任意视频地址
 * @returns {{kind:'video'|'iframe'|'none', src:string, site:string}}
 *   kind='video'  用原生 <video> 播放（直链 mp4/webm/ogg）
 *   kind='iframe' 用 iframe 嵌播放器
 *   kind='none'   没有地址，不发起任何请求
 */
export function toPlaySource(rawUrl) {
  const url = String(rawUrl || '').trim()
  if (!url) return { kind: 'none', src: '', site: '' }

  const t = (url.match(/[?&]t=([\d.]+)/) || [])[1]
  const start = t ? Math.floor(Number(t)) : 0
  const at = start ? `&t=${start}` : ''

  let m = url.match(RE_BV)
  if (m) {
    return {
      kind: 'iframe',
      src: `https://player.bilibili.com/player.html?bvid=${m[1]}&page=1&autoplay=1&high_quality=1&danmaku=0${at}`,
      site: '哔哩哔哩'
    }
  }

  m = url.match(RE_AV)
  if (m) {
    return {
      kind: 'iframe',
      src: `https://player.bilibili.com/player.html?aid=${m[1]}&page=1&autoplay=1&danmaku=0${at}`,
      site: '哔哩哔哩'
    }
  }

  m = url.match(RE_VIMEO)
  if (m) return { kind: 'iframe', src: `https://player.vimeo.com/video/${m[1]}?autoplay=1`, site: 'Vimeo' }

  m = url.match(RE_YT)
  if (m) return { kind: 'iframe', src: `https://www.youtube.com/embed/${m[1]}?autoplay=1&rel=0`, site: 'YouTube' }

  // 直链视频文件：交给原生 <video>
  if (RE_FILE.test(url)) return { kind: 'video', src: url, site: '直链视频' }

  // 其它站点原样尝试内嵌（若对方禁止，组件会给出提示，而不是偷偷跳走）
  return { kind: 'iframe', src: url, site: '外部片源' }
}
