import Vue from 'vue';

// Import all panel components
import StatusWidget from './StatusWidget.vue';
import ActionConfirmationWidget from './ActionConfirmationWidget.vue';
import ProbeResultsPanel from './ProbeResultsPanel.vue';
import ProbingCyclesPanel from './ProbingCyclesPanel.vue';
import ConfigurationPanel from './ConfigurationPanel.vue';
import DialogWidget from './DialogWidget.vue';

// Register all panel components globally
Vue.component('nxt-status-widget', StatusWidget);
Vue.component('nxt-action-confirmation-widget', ActionConfirmationWidget);
Vue.component('nxt-probe-results-panel', ProbeResultsPanel);
Vue.component('nxt-probing-cycles-panel', ProbingCyclesPanel);
Vue.component('nxt-configuration-panel', ConfigurationPanel);
Vue.component('nxt-dialog-widget', DialogWidget);