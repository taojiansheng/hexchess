import Vue from 'vue';
import App from './App.vue';
import './styles/base.scss';

// 关闭生产提示
Vue.config.productionTip = false;

// Vue应用入口 - 创建实例并挂载到#app
new Vue({
  render: h => h(App)
}).$mount('#app');
