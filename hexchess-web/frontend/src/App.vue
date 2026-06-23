<template>
  <!-- 应用主入口 - 包含对局面板组件 -->
  <main class="app-shell">
    <MatchPanel />
  </main>
</template>

<script>
import MatchPanel from './components/MatchPanel.vue';

// 根应用组件 - 作为应用入口，引入对局面板
export default {
  name: 'App',
  components: { MatchPanel }
};
</script>
