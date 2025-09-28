import Vue from 'vue';
import CNCMovementPanel from './CNCMovementPanel.vue';

// Register panel override components
// These replace default DWC panels with NeXT versions
Vue.component('cnc-movement-panel', CNCMovementPanel);