import { http, unwrap } from './http'

/**
 * 今日推荐动画（按热度倒序）
 * @returns {Promise<Array<{id:number,title:string,cover:string,category:string,description:string,hot:number}>>}
 */
export async function getRecommend(limit = 6) {
  return unwrap(await http.get('/animation/recommend', { params: { limit } }))
}

/**
 * 我的收藏
 * @param {number} userId
 */
export async function getFavorites(userId) {
  return unwrap(await http.get(`/animation/favorites/${userId}`))
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
