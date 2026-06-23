<template>
  <section class="board-stage" aria-label="11x11 hexchess board">
    <div class="board-frame">
      <svg class="hex-svg" :viewBox="viewBox" role="img" aria-label="Hexchess board">
        <g class="board-cells">
          <g
            v-for="cell in cells"
            :key="cell.key"
            class="cell-hit"
            :class="{ disabled: disabled || cell.value !== 0 }"
            @click="handleCellClick(cell)"
          >
            <title>{{ cellTitle(cell) }}</title>
            <polygon
              class="hex-cell"
              :class="cellClasses(cell)"
              :points="cell.points"
            />
          </g>
        </g>

        <g class="edge-lines">
          <line
            v-for="(edge, index) in edgeSegments.red"
            :key="`red-${index}`"
            class="edge-line red-edge"
            :x1="edge.x1"
            :y1="edge.y1"
            :x2="edge.x2"
            :y2="edge.y2"
          />
          <line
            v-for="(edge, index) in edgeSegments.blue"
            :key="`blue-${index}`"
            class="edge-line blue-edge"
            :x1="edge.x1"
            :y1="edge.y1"
            :x2="edge.x2"
            :y2="edge.y2"
          />
        </g>

        <g class="stones">
          <g
            v-for="cell in occupiedCells"
            :key="`stone-${cell.key}`"
            class="stone"
            :class="stoneClasses(cell)"
            :style="stoneStyle(cell)"
          >
            <polygon class="stone-body" :points="stonePoints(cell)" />
            <polygon class="stone-face" :points="stoneInnerPoints(cell)" />
            <text :x="cell.cx" :y="cell.cy + 4" text-anchor="middle">
              {{ cell.moveNumber || '' }}
            </text>
          </g>
        </g>

        <g v-if="winningPathSegments.length" class="winning-route">
          <line
            v-for="(segment, index) in winningPathSegments"
            :key="`path-${index}`"
            class="winning-route-segment"
            :class="winningColorClass"
            :style="{ animationDelay: `${index * 90}ms` }"
            :x1="segment.x1"
            :y1="segment.y1"
            :x2="segment.x2"
            :y2="segment.y2"
          />
        </g>
      </svg>
    </div>
  </section>
</template>

<script>
// 六边形棋盘尺寸常量 - 控制棋盘和棋子大小
const HEX_SIZE = 25;
const STONE_SIZE = HEX_SIZE * 0.9;
const HEX_WIDTH = Math.sqrt(3) * HEX_SIZE;
const HEX_HEIGHT = HEX_SIZE * 2;
const X_STEP = HEX_WIDTH;
const Y_STEP = HEX_SIZE * 1.5;
const MARGIN = 54;

// 六边形棋盘组件 - 渲染棋盘、棋子、落子动画和获胜路径
export default {
  name: 'GameBoard',
  props: {
    board: { type: Array, required: true },      // 棋盘状态数组
    moves: { type: Array, default: () => [] },   // 落子历史记录
    selectedHint: { type: Object, default: null }, // 提示位置
    winningPath: { type: Array, default: () => [] }, // 获胜路径
    disabled: { type: Boolean, default: false } // 是否禁用点击
  },
  computed: {
    // 获取棋盘大小
    size() { return this.board.length || 11; },
    
    // SVG视口范围
    viewBox() { return `${this.bounds.minX} ${this.bounds.minY} ${this.bounds.width} ${this.bounds.height}`; },
    
    // 落子索引映射 - 用于显示落子序号
    moveIndex() {
      return this.moves.reduce((map, move) => {
        map[`${move.row}:${move.col}`] = move.moveNumber;
        return map;
      }, {});
    },
    
    // 生成所有格子数据
    cells() {
      const list = [];
      for (let row = 0; row < this.size; row += 1) {
        for (let col = 0; col < this.size; col += 1) {
          const center = this.center(row, col);
          list.push({
            row, col, key: `${row}-${col}`, value: this.board[row][col],
            moveNumber: this.moveIndex[`${row}:${col}`],
            cx: center.x, cy: center.y,
            points: this.hexPoints(center.x, center.y, HEX_SIZE)
          });
        }
      }
      return list;
    },
    
    // 已有棋子的格子
    occupiedCells() { return this.cells.filter(cell => cell.value !== 0); },
    
    // 最近两步落子位置
    latestMoveKey() {
      return this.moves.length ? this.moves.slice(-2).map(m => `${m.row}:${m.col}`) : [];
    },
    
    // 获胜路径集合
    winningPathKeySet() { return new Set(this.winningPath.map(c => `${c.row}:${c.col}`)); },
    
    // 获胜路径线段 - 用于动画绘制
    winningPathSegments() {
      if (this.winningPath.length < 2) return [];
      return this.winningPath.slice(0, -1).map((cell, i) => {
        const start = this.center(cell.row, cell.col);
        const end = this.center(this.winningPath[i + 1].row, this.winningPath[i + 1].col);
        return { x1: start.x, y1: start.y, x2: end.x, y2: end.y };
      });
    },
    
    // 获胜方颜色类名
    winningColorClass() {
      if (!this.winningPath.length) return '';
      return this.board[this.winningPath[0].row][this.winningPath[0].col] === 1 ? 'route-red' : 'route-blue';
    },
    
    // 计算SVG边界
    bounds() {
      const all = [];
      for (let row = 0; row < this.size; row += 1) {
        for (let col = 0; col < this.size; col += 1) {
          all.push(...this.vertices(row, col));
        }
      }
      const xs = all.map(p => p.x); const ys = all.map(p => p.y);
      return {
        minX: Math.min(...xs) - MARGIN, maxX: Math.max(...xs) + MARGIN,
        minY: Math.min(...ys) - MARGIN, maxY: Math.max(...ys) + MARGIN,
        width: Math.max(...xs) - Math.min(...xs) + MARGIN * 2,
        height: Math.max(...ys) - Math.min(...ys) + MARGIN * 2
      };
    },
    
    // 边界线 - 红方顶底边界，蓝方左右边界
    edgeSegments() {
      const red = [], blue = [];
      for (let col = 0; col < this.size; col += 1) {
        red.push(this.edgeSegment(0, col, 5, 0));
        red.push(this.edgeSegment(0, col, 0, 1));
        red.push(this.edgeSegment(this.size - 1, col, 2, 3));
        red.push(this.edgeSegment(this.size - 1, col, 3, 4));
      }
      for (let row = 0; row < this.size; row += 1) {
        blue.push(this.edgeSegment(row, 0, 4, 5));
        blue.push(this.edgeSegment(row, 0, 3, 4));
        blue.push(this.edgeSegment(row, this.size - 1, 1, 2));
        blue.push(this.edgeSegment(row, this.size - 1, 0, 1));
      }
      return { red, blue };
    }
  },
  methods: {
    // 计算六边形中心坐标
    center(row, col) {
      return {
        x: MARGIN + HEX_WIDTH / 2 + col * X_STEP + row * X_STEP / 2,
        y: MARGIN + HEX_SIZE + row * Y_STEP
      };
    },
    
    // 获取六边形六个顶点坐标
    vertices(row, col, size = HEX_SIZE) {
      const { x, y } = this.center(row, col);
      return [
        { x, y: y - size },
        { x: x + Math.sqrt(3) * size / 2, y: y - size / 2 },
        { x: x + Math.sqrt(3) * size / 2, y: y + size / 2 },
        { x, y: y + size },
        { x: x - Math.sqrt(3) * size / 2, y: y + size / 2 },
        { x: x - Math.sqrt(3) * size / 2, y: y - size / 2 }
      ];
    },
    
    // 生成SVG六边形路径点
    hexPoints(cx, cy, size) {
      return [[cx, cy - size], [cx + Math.sqrt(3) * size / 2, cy - size / 2],
        [cx + Math.sqrt(3) * size / 2, cy + size / 2], [cx, cy + size],
        [cx - Math.sqrt(3) * size / 2, cy + size / 2], [cx - Math.sqrt(3) * size / 2, cy - size / 2]]
        .map(p => p.join(',')).join(' ');
    },
    
    // 获取边界线段
    edgeSegment(row, col, startIndex, endIndex) {
      const points = this.vertices(row, col);
      return { x1: points[startIndex].x, y1: points[startIndex].y, x2: points[endIndex].x, y2: points[endIndex].y };
    },
    
    // 棋子外轮廓点
    stonePoints(cell) { return this.hexPoints(cell.cx, cell.cy, STONE_SIZE); },
    
    // 棋子内轮廓点
    stoneInnerPoints(cell) { return this.hexPoints(cell.cx, cell.cy, STONE_SIZE * 0.64); },
    
    // 棋子CSS类名
    stoneClasses(cell) {
      return {
        'stone-red': cell.value === 1, 'stone-blue': cell.value === 2,
        'stone-latest': this.latestMoveKey.includes(`${cell.row}:${cell.col}`),
        'stone-winning': this.winningPathKeySet.has(`${cell.row}:${cell.col}`)
      };
    },
    
    // 棋子样式 - 动画延迟
    stoneStyle(cell) {
      const idx = this.latestMoveKey.indexOf(`${cell.row}:${cell.col}`);
      return idx >= 0 ? { animationDelay: `${idx * 120}ms` } : {};
    },
    
    // 格子CSS类名
    cellClasses(cell) {
      return {
        'is-hint': this.isHint(cell), 'is-empty': cell.value === 0,
        'is-winning-cell': this.winningPathKeySet.has(`${cell.row}:${cell.col}`)
      };
    },
    
    // 是否是提示位置
    isHint(cell) { return this.selectedHint && this.selectedHint.row === cell.row && this.selectedHint.col === cell.col; },
    
    // 处理格子点击 - 触发落子事件
    handleCellClick(cell) {
      if (this.disabled || cell.value !== 0) return;
      this.$emit('play', cell.row, cell.col);
    },
    
    // 格子标题提示
    cellTitle(cell) {
      const coord = `${String.fromCharCode(65 + cell.col)}${cell.row + 1}`;
      if (cell.value === 1) return `${coord} 红方`;
      if (cell.value === 2) return `${coord} 蓝方`;
      return `${coord} 可落子`;
    }
  }
};
</script>

<style scoped lang="scss">
.board-stage {
  min-height: 100vh;
  padding: 28px;
  background:
    linear-gradient(135deg, rgba(255, 255, 255, 0.04), transparent 34%),
    #0c1117;
  overflow: auto;
  display: flex;
  align-items: center;
  justify-content: center;
}

.board-frame {
  width: min(100%, 900px);
  padding: 28px;
  border: 1px solid rgba(205, 216, 230, 0.14);
  border-radius: 10px;
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.055), rgba(255, 255, 255, 0.02)),
    #111923;
  box-shadow: 0 24px 50px rgba(0, 0, 0, 0.38);
}

.hex-svg {
  width: 100%;
  min-width: 620px;
  height: auto;
  display: block;
}

.cell-hit:not(.disabled) {
  cursor: pointer;
}

.cell-hit.disabled {
  cursor: default;
}

.hex-cell {
  fill: #18222e;
  stroke: #53606c;
  stroke-width: 2.4;
  stroke-linejoin: round;
  transition: fill 0.15s ease, stroke 0.15s ease;
}

.hex-cell.is-empty:hover {
  fill: #213044;
  stroke: #8ba0b4;
}

.hex-cell.is-hint {
  fill: #2f2a18;
  stroke: var(--gold);
  stroke-width: 4;
}

.hex-cell.is-winning-cell {
  fill: rgba(244, 231, 188, 0.14);
  stroke: rgba(250, 235, 184, 0.82);
  stroke-width: 3.6;
}

.edge-line {
  stroke-width: 6.5;
  stroke-linecap: round;
  pointer-events: none;
}

.red-edge {
  stroke: #e35757;
}

.blue-edge {
  stroke: #4387ff;
}

.stone {
  filter: drop-shadow(0 7px 10px rgba(0, 0, 0, 0.42));
  transform-box: fill-box;
  transform-origin: center center;
}

.stone-body {
  stroke-width: 2.4;
  stroke-linejoin: round;
}

.stone-red .stone-body {
  fill: #e64e4e;
  stroke: #ff8585;
}

.stone-blue .stone-body {
  fill: #3478e5;
  stroke: #8bb8ff;
}

.stone-face {
  fill: none;
  stroke: rgba(255, 255, 255, 0.35);
  stroke-width: 1.5;
}

.stone text {
  fill: #ffffff;
  font-size: 12px;
  font-weight: 800;
  pointer-events: none;
}

.stone-latest {
  animation: stone-pop 240ms cubic-bezier(0.2, 0.9, 0.24, 1.2);
}

.stone-winning .stone-body {
  stroke-width: 3.2;
  filter: brightness(1.12);
}

.stone-winning .stone-face {
  stroke: rgba(255, 255, 255, 0.65);
}

.winning-route-segment {
  fill: none;
  stroke-width: 13;
  stroke-linecap: round;
  stroke-linejoin: round;
  opacity: 0;
  pointer-events: none;
  filter: drop-shadow(0 0 16px rgba(255, 255, 255, 0.34));
  animation: route-reveal 480ms ease forwards;
}

.winning-route-segment.route-red {
  stroke: rgba(255, 133, 133, 0.9);
}

.winning-route-segment.route-blue {
  stroke: rgba(139, 184, 255, 0.92);
}

@keyframes stone-pop {
  0% {
    opacity: 0.3;
    transform: scale(0.72);
  }
  65% {
    opacity: 1;
    transform: scale(1.08);
  }
  100% {
    opacity: 1;
    transform: scale(1);
  }
}

@keyframes route-reveal {
  0% {
    opacity: 0;
    stroke-width: 5;
  }
  45% {
    opacity: 1;
  }
  100% {
    opacity: 1;
    stroke-width: 13;
  }
}

@media (max-width: 980px) {
  .board-stage {
    min-height: 620px;
    padding: 14px;
  }

  .board-frame {
    padding: 16px;
  }

  .hex-svg {
    min-width: 520px;
  }
}
</style>
