<template>
  <div class="match-page">
    <aside class="side-panel player-panel">
      <div class="brand-block">
        <span class="brand-mark">HC</span>
        <div>
          <h1>Hexchess Arena</h1>
          <p>11x11 六边形棋人机对战</p>
        </div>
      </div>

      <section class="setup-panel">
        <h2>开局设置</h2>
        <div class="segmented-control" role="group" aria-label="选择先后手">
          <button
            :class="{ active: selectedHumanColor === 'RED' }"
            :disabled="loading"
            @click="selectedHumanColor = 'RED'"
          >
            执红先手
          </button>
          <button
            :class="{ active: selectedHumanColor === 'BLUE' }"
            :disabled="loading"
            @click="selectedHumanColor = 'BLUE'"
          >
            执蓝后手
          </button>
        </div>
        <div class="difficulty-block">
          <span class="field-label">AI 难度</span>
          <div class="segmented-control difficulty-control" role="group" aria-label="选择 AI 难度">
            <button
              :class="{ active: selectedDifficulty === 'EASY' }"
              :disabled="loading"
              @click="selectedDifficulty = 'EASY'"
            >
              入门
            </button>
            <button
              :class="{ active: selectedDifficulty === 'NORMAL' }"
              :disabled="loading"
              @click="selectedDifficulty = 'NORMAL'"
            >
              标准
            </button>
            <button
              :class="{ active: selectedDifficulty === 'HARD' }"
              :disabled="loading"
              @click="selectedDifficulty = 'HARD'"
            >
              困难
            </button>
          </div>
        </div>
      </section>

      <section class="score-strip">
        <div class="player-card is-red" :class="{ active: match.currentTurn === 'RED' }">
          <span class="player-dot"></span>
          <strong>红方</strong>
          <small>{{ match.humanColor === 'RED' ? '你' : 'AI' }}</small>
        </div>
        <div class="player-card is-blue" :class="{ active: match.currentTurn === 'BLUE' }">
          <span class="player-dot"></span>
          <strong>蓝方</strong>
          <small>{{ match.humanColor === 'BLUE' ? '你' : 'AI' }}</small>
        </div>
      </section>

      <dl class="status-list">
        <div>
          <dt>对局编号</dt>
          <dd>{{ match.id || '-' }}</dd>
        </div>
        <div>
          <dt>当前回合</dt>
          <dd>{{ turnLabel }}</dd>
        </div>
        <div>
          <dt>胜利目标</dt>
          <dd>红上下，蓝左右</dd>
        </div>
        <div>
          <dt>状态</dt>
          <dd>{{ statusLabel }}</dd>
        </div>
        <div>
          <dt>AI 难度</dt>
          <dd>{{ difficultyLabel }}</dd>
        </div>
      </dl>

      <div class="actions">
        <button class="primary-button" @click="startNewMatch" :disabled="loading">
          新开一局
        </button>
        <button class="secondary-button" @click="loadAiHint" :disabled="!match.id || loading || match.status !== 'IN_PROGRESS'">
          AI 提示
        </button>
      </div>

      <p v-if="message" class="message">{{ message }}</p>
    </aside>

    <GameBoard
      :board="displayMatch.board"
      :moves="displayMatch.moves"
      :winning-path="displayMatch.winningPath"
      :selected-hint="aiHint"
      :disabled="boardDisabled"
      @play="handlePlay"
    />

    <aside class="side-panel move-panel">
      <header class="panel-header">
        <div>
          <h2>走子记录</h2>
          <span>{{ match.moves.length }} 手</span>
        </div>
        <button class="icon-button" title="刷新当前对局" :disabled="!match.id || loading" @click="refreshMatch">
          ↻
        </button>
      </header>

      <ol class="move-list">
        <li
          v-for="move in reversedMoves"
          :key="move.moveNumber"
          :class="{ active: move.moveNumber === reviewStep }"
          @click="jumpToStep(move.moveNumber)"
        >
          <span class="move-no">{{ move.moveNumber }}</span>
          <span class="move-piece" :class="move.player === 'RED' ? 'red' : 'blue'"></span>
          <strong>{{ moveLabel(move) }}</strong>
          <em>{{ coordLabel(move) }}</em>
        </li>
      </ol>

      <div class="review-controls">
        <button class="secondary-button" :disabled="loading || reviewStep === 0" @click="jumpToStep(0)">
          回到开局
        </button>
        <button class="secondary-button" :disabled="loading || reviewStep === 0" @click="stepBackward">
          上一步
        </button>
        <button class="secondary-button" :disabled="loading || reviewStep === match.moves.length" @click="stepForward">
          下一步
        </button>
        <button class="secondary-button" :disabled="loading || reviewStep === match.moves.length" @click="jumpToStep(match.moves.length)">
          跳到最后
        </button>
      </div>

      <div class="review-actions">
        <button
          class="secondary-button"
          :disabled="loading || !canUndo"
          @click="undoRound"
        >
          悔棋
        </button>
      </div>

      <div class="rules-box">
        <h2>规则</h2>
        <p>红方连接棋盘上下两侧获胜，蓝方连接棋盘左右两侧获胜。选择执蓝时，AI 执红先走。</p>
      </div>
    </aside>
  </div>
</template>

<script>
// 导入棋盘组件和API接口
import GameBoard from './GameBoard.vue';
import { createMatch, getMatch, playMove, suggestAiMove, undoLastRound } from '../api/matches';

// 创建空棋盘 - 默认11x11
function emptyBoard(size = 11) {
  return Array.from({ length: size }, () => Array.from({ length: size }, () => 0));
}

// 对局主面板组件 - 管理整个游戏流程和UI
export default {
  name: 'MatchPanel',
  components: { GameBoard },
  data() {
    return {
      loading: false,       // 加载状态
      message: '',          // 提示消息
      aiHint: null,         // AI提示位置
      reviewStep: 0,        // 复盘步数
      selectedHumanColor: 'RED',    // 用户选择的颜色
      selectedDifficulty: 'NORMAL', // 用户选择的难度
      match: {              // 当前对局状态
        id: null, size: 11, board: emptyBoard(),
        currentTurn: 'RED', humanColor: 'RED', aiColor: 'BLUE',
        difficulty: 'NORMAL', status: 'IN_PROGRESS',
        winner: null, winningPath: [], moves: []
      }
    };
  },
  computed: {
    // 当前显示的对局状态（支持复盘）
    displayMatch() {
      return this.reviewStep === this.match.moves.length ? this.match : this.snapshotAt(this.reviewStep);
    },
    
    // 棋盘是否禁用（加载中/复盘模式/游戏结束/非玩家回合）
    boardDisabled() {
      return this.loading || this.reviewStep !== this.match.moves.length 
        || this.match.status !== 'IN_PROGRESS' 
        || this.match.currentTurn !== this.match.humanColor;
    },
    
    // 当前回合标签
    turnLabel() {
      if (this.match.status !== 'IN_PROGRESS') return '-';
      const color = this.match.currentTurn === 'RED' ? '红方' : '蓝方';
      const actor = this.match.currentTurn === this.match.humanColor ? '你' : 'AI';
      return `${color} ${actor}`;
    },
    
    // 状态标签
    statusLabel() {
      if (this.match.status === 'RED_WIN') return '红方胜利';
      if (this.match.status === 'BLUE_WIN') return '蓝方胜利';
      return '进行中';
    },
    
    // 难度标签
    difficultyLabel() {
      if (this.match.difficulty === 'EASY') return '入门';
      if (this.match.difficulty === 'HARD') return '困难';
      return '标准';
    },
    
    // 反转的走子记录（最新的在前）
    reversedMoves() { return [...this.match.moves].reverse(); },
    
    // 是否可以悔棋
    canUndo() {
      return this.reviewStep === this.match.moves.length 
        && this.match.status === 'IN_PROGRESS' 
        && this.match.moves.length > 0;
    }
  },
  mounted() {
    this.startNewMatch(); // 初始化时自动开始新对局
  },
  methods: {
    // 开始新对局
    async startNewMatch() {
      await this.request(async () => {
        this.match = await createMatch(this.selectedHumanColor, this.selectedDifficulty);
        this.reviewStep = this.match.moves.length;
        this.aiHint = null;
        this.message = this.selectedHumanColor === 'RED'
          ? `新对局已创建，你执红先手，当前为${this.difficultyLabel}。`
          : `新对局已创建，AI 已执红先走，当前为${this.difficultyLabel}。`;
      });
    },
    
    // 刷新当前对局
    async refreshMatch() {
      if (!this.match.id) return;
      await this.request(async () => {
        this.match = await getMatch(this.match.id);
        this.reviewStep = this.match.moves.length;
        this.message = '对局已刷新。';
      });
    },
    
    // 处理玩家落子
    async handlePlay(row, col) {
      if (!this.match.id || this.boardDisabled) return;
      await this.request(async () => {
        this.aiHint = null;
        this.match = await playMove(this.match.id, row, col);
        this.reviewStep = this.match.moves.length;
        this.message = this.match.status === 'IN_PROGRESS' ? 'AI 已完成回合。' : this.statusLabel;
      });
    },
    
    // 悔棋（撤销上一轮）
    async undoRound() {
      if (!this.canUndo) return;
      await this.request(async () => {
        this.aiHint = null;
        this.match = await undoLastRound(this.match.id);
        this.reviewStep = this.match.moves.length;
        this.message = '已撤销上一轮走子。';
      });
    },
    
    // 获取AI提示
    async loadAiHint() {
      await this.request(async () => {
        this.aiHint = await suggestAiMove(this.match.id);
        this.message = `AI 倾向落在 ${this.coordLabel(this.aiHint)}。`;
      });
    },
    
    // 跳转到指定步数
    jumpToStep(step) {
      this.reviewStep = Math.max(0, Math.min(step, this.match.moves.length));
      this.aiHint = null;
      this.message = this.reviewStep !== this.match.moves.length 
        ? `正在查看第 ${this.reviewStep} 手后的局面。` 
        : '已回到最新局面。';
    },
    
    // 上一步
    stepBackward() { this.jumpToStep(this.reviewStep - 1); },
    
    // 下一步
    stepForward() { this.jumpToStep(this.reviewStep + 1); },
    
    // 获取指定步数的棋盘快照（用于复盘）
    snapshotAt(step) {
      const board = emptyBoard(this.match.size);
      const moves = this.match.moves.slice(0, step);
      moves.forEach(m => board[m.row][m.col] = m.player === 'RED' ? 1 : 2);
      
      let currentTurn = 'RED';
      if (moves.length > 0) {
        currentTurn = moves[moves.length - 1].player === 'RED' ? 'BLUE' : 'RED';
      }
      
      return { ...this.match, board, currentTurn, 
        status: step === this.match.moves.length ? this.match.status : 'IN_PROGRESS',
        winner: step === this.match.moves.length ? this.match.winner : null,
        winningPath: step === this.match.moves.length ? this.match.winningPath : [], moves };
    },
    
    // 请求包装器 - 统一处理加载状态和错误
    async request(action) {
      this.loading = true; this.message = '';
      try { await action(); } 
      catch (error) {
        this.message = error.response?.data?.message 
          || '请求失败，请确认后端服务和 MySQL 已启动。';
      } finally { this.loading = false; }
    },
    
    // 走子标签（显示颜色和操作者）
    moveLabel(move) {
      const color = move.player === 'RED' ? '红方' : '蓝方';
      const actor = move.player === this.match.humanColor ? '你' : 'AI';
      return `${color} ${actor}`;
    },
    
    // 坐标标签（如 A1, B2）
    coordLabel(move) { return `${String.fromCharCode(65 + move.col)}${move.row + 1}`; }
  }
};
</script>

<style scoped lang="scss">
.match-page {
  min-height: 100vh;
  display: grid;
  grid-template-columns: minmax(280px, 330px) minmax(720px, 1fr) minmax(280px, 340px);
  background: #0a0f15;
}

.side-panel {
  padding: 24px;
  background: #111922;
  border-color: rgba(205, 216, 230, 0.12);
}

.player-panel {
  border-right: 1px solid rgba(205, 216, 230, 0.12);
}

.move-panel {
  border-left: 1px solid rgba(205, 216, 230, 0.12);
}

.brand-block {
  display: flex;
  gap: 14px;
  align-items: center;
  padding-bottom: 22px;
  border-bottom: 1px solid var(--line);
}

.brand-mark {
  width: 52px;
  height: 52px;
  border-radius: 8px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-weight: 900;
  color: #17120b;
  background: var(--gold);
  box-shadow: 0 10px 20px rgba(0, 0, 0, 0.34);
}

h1,
h2,
p {
  margin: 0;
}

h1 {
  font-size: 22px;
}

h2 {
  font-size: 16px;
}

.brand-block p,
.panel-header span,
.status-list dt,
.rules-box p {
  color: var(--muted);
}

.setup-panel {
  margin-top: 22px;
}

.difficulty-block {
  margin-top: 14px;
}

.field-label {
  display: inline-block;
  margin-top: 2px;
  color: var(--muted);
  font-size: 13px;
  font-weight: 700;
}

.segmented-control {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 6px;
  margin-top: 10px;
  padding: 4px;
  border-radius: 8px;
  border: 1px solid var(--line);
  background: #17222e;
}

.difficulty-control {
  grid-template-columns: repeat(3, 1fr);
}

.segmented-control button {
  min-height: 38px;
  border-radius: 6px;
  color: var(--muted);
  background: transparent;
  font-weight: 800;
}

.segmented-control button.active {
  color: #17120b;
  background: var(--gold);
}

.score-strip {
  display: grid;
  gap: 12px;
  margin: 24px 0;
}

.player-card {
  display: grid;
  grid-template-columns: 18px 1fr auto;
  align-items: center;
  gap: 10px;
  min-height: 54px;
  padding: 12px;
  border-radius: 8px;
  border: 1px solid var(--line);
  background: #17222e;
}

.player-card.active {
  border-color: var(--gold);
  box-shadow: inset 0 0 0 1px rgba(200, 164, 93, 0.22);
}

.player-dot,
.move-piece {
  width: 14px;
  height: 16px;
  clip-path: polygon(50% 0, 93% 25%, 93% 75%, 50% 100%, 7% 75%, 7% 25%);
}

.is-red .player-dot,
.move-piece.red {
  background: var(--red);
}

.is-blue .player-dot,
.move-piece.blue {
  background: var(--blue);
}

.status-list {
  margin: 0;
  display: grid;
  gap: 12px;
}

.status-list div {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  padding-bottom: 12px;
  border-bottom: 1px solid var(--line);
}

.status-list dd {
  margin: 0;
  font-weight: 800;
  text-align: right;
}

.actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  margin-top: 24px;
}

.actions button:disabled,
.icon-button:disabled,
.segmented-control button:disabled {
  opacity: 0.55;
  cursor: wait;
}

.message {
  margin-top: 16px;
  padding: 12px;
  border-left: 3px solid var(--gold);
  background: #17222e;
  color: var(--text);
  line-height: 1.6;
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 18px;
}

.move-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: grid;
  gap: 8px;
  max-height: 58vh;
  overflow: auto;
}

.move-list li {
  display: grid;
  grid-template-columns: 34px 16px 1fr auto;
  align-items: center;
  gap: 10px;
  min-height: 40px;
  padding: 8px 10px;
  border: 1px solid var(--line);
  border-radius: 6px;
  background: #17222e;
  cursor: pointer;
}

.move-list li.active {
  border-color: var(--gold);
  background: rgba(200, 164, 93, 0.12);
}

.move-no {
  color: var(--muted);
  font-variant-numeric: tabular-nums;
}

.move-list em {
  color: var(--gold);
  font-style: normal;
  font-weight: 800;
}

.rules-box {
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px solid var(--line);
}

.review-controls,
.review-actions {
  display: grid;
  gap: 10px;
  margin-top: 18px;
}

.review-controls {
  grid-template-columns: 1fr 1fr;
}

.rules-box p {
  margin-top: 8px;
  line-height: 1.7;
}

@media (max-width: 1180px) {
  .match-page {
    grid-template-columns: 300px minmax(560px, 1fr);
  }

  .move-panel {
    grid-column: 1 / -1;
  }
}

@media (max-width: 780px) {
  .match-page {
    grid-template-columns: 1fr;
  }

  .side-panel {
    padding: 18px;
  }
}
</style>
