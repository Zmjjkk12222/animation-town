/**
 * 联机入口信号
 * ---------------------------------------------------------------
 * 场景：用户在「我的好友」页或任意页面收到联机邀请并点「接受」，
 * 需要把界面切到「亲子游戏乐园 → 冰娃与火娃」。
 * 这个模块只做一件事：把"请打开联机游戏"这个意图从全局邀请条
 * 传递到 HomePage / ParentHomePage（切 Tab）再到 GameHall（开弹窗）。
 *
 * 采用「一次性消费」而不是布尔开关，是为了抹平挂载顺序问题：
 * 发出请求时 GameHall 可能还没挂载，它挂载后调用 consumeOpenGame() 也能拿到。
 */
import { ref } from 'vue'

/** 自增计数：仅用于触发 watch，具体含义由 consumeOpenGame 负责 */
export const gameEntryTick = ref(0)

let pending = false

/** 请求打开联机游戏（接受邀请成功后调用） */
export function requestOpenGame() {
  pending = true
  gameEntryTick.value += 1
}

/** 取走一次打开请求；没有待处理请求时返回 false */
export function consumeOpenGame() {
  if (!pending) return false
  pending = false
  return true
}

/** 丢弃待处理请求（例如用户已手动打开游戏，避免重复弹窗） */
export function dropOpenGame() {
  pending = false
}
