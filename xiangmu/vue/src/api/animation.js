import { http, unwrap } from './http'

// 分类对应的代表 emoji（cover 缺失/损坏时的兜底图标）
const CAT_EMOJI = {
  '冒险': '🌳', '治愈': '⭐', '科普': '🦖', '推理': '🐱', '科幻': '🚀', '音乐': '🎵',
  '科学': '🔧', '创意': '🧱', '美食': '☁️', '语文': '📖', '搞笑': '🤡', '友情': '🤝',
  '童话': '👸', '自然': '🦁', '运动': '🏓', '历史': '🏮', '动物': '🐼', '恐龙': '🦕',
  '艺术': '🎨'
}

/**
 * 规范化动画数据：封面缺失或损坏（空串 / 只含“?”）时，
 * 回退到分类代表 emoji，分类也没有则用 🎬，避免页面上出现空图标。
 */
function normalizeAnimation(a) {
  if (!a) return a
  const cover = (a.cover || '').trim()
  if (!cover || /^[?]+$/.test(cover)) {
    a.cover = CAT_EMOJI[a.category] || '🎬'
  }
  return a
}

/** 对列表数据统一做规范化，非数组原样返回 */
function normalizeList(list) {
  return Array.isArray(list) ? list.map(normalizeAnimation) : list
}

/**
 * 今日推荐动画（按热度倒序）
 * @returns {Promise<Array<{id:number,title:string,cover:string,category:string,description:string,hot:number}>>}
 */
export async function getRecommend(limit = 6) {
  return normalizeList(unwrap(await http.get('/animation/recommend', { params: { limit } })))
}

/**
 * 我的收藏
 * @param {number} userId
 */
export async function getFavorites(userId) {
  return normalizeList(unwrap(await http.get(`/animation/favorites/${userId}`)))
}

/**
 * 收藏某个动画
 */
export async function addFavorite(userId, animationId) {
  return unwrap(await http.post('/animation/favorite', { userId, animationId }))
}

/**
 * 取消收藏某个动画
 */
export async function removeFavorite(userId, animationId) {
  return unwrap(await http.post('/animation/unfavorite', { userId, animationId }))
}
