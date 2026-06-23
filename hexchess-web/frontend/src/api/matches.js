import axios from 'axios';

// 创建API实例 - 基础路径/api，超时10秒
const api = axios.create({
  baseURL: '/api',
  timeout: 10000
});

// 创建新对局 - 默认玩家执红，标准难度
export function createMatch(humanColor = 'RED', difficulty = 'NORMAL') {
  return api.post('/matches', { humanColor, difficulty }).then(response => response.data);
}

// 获取对局详情 - 根据对局ID
export function getMatch(id) {
  return api.get(`/matches/${id}`).then(response => response.data);
}

// 玩家落子 - 参数：对局ID、行、列
export function playMove(id, row, col) {
  return api.post(`/matches/${id}/moves`, { row, col }).then(response => response.data);
}

// 撤销上一轮走子
export function undoLastRound(id) {
  return api.post(`/matches/${id}/undo`).then(response => response.data);
}

// 获取AI建议的落子位置
export function suggestAiMove(id) {
  return api.get(`/matches/${id}/ai/suggestion`).then(response => response.data);
}
