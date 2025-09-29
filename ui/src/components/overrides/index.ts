import Vue from 'vue';
import MessageBox from './MessageBox.vue';

// Register the MessageBox override to replace DWC's message box component
Vue.component('message-box', MessageBox);

// Import other override modules
import './panels';
import './routes';