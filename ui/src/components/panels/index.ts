/**
 * Panel Components Registration
 * 
 * Registers all NeXT panel components globally for use in templates
 */

import Vue from 'vue'
import StatusWidget from './StatusWidget.vue'
import ActionConfirmationWidget from './ActionConfirmationWidget.vue'
import MachineStatusPanel from './MachineStatusPanel.vue'
import ConfigurationPanel from './ConfigurationPanel.vue'
import ProbeResultsPanel from './ProbeResultsPanel.vue'
import ProbingCyclesPanel from './ProbingCyclesPanel.vue'

// Register panel components
Vue.component('nxt-status-widget', StatusWidget)
Vue.component('nxt-action-confirmation-widget', ActionConfirmationWidget)
Vue.component('nxt-machine-status-panel', MachineStatusPanel)
Vue.component('nxt-configuration-panel', ConfigurationPanel)
Vue.component('nxt-probe-results-panel', ProbeResultsPanel)
Vue.component('nxt-probing-cycles-panel', ProbingCyclesPanel)

export {
  StatusWidget,
  ActionConfirmationWidget,
  MachineStatusPanel,
  ConfigurationPanel,
  ProbeResultsPanel,
  ProbingCyclesPanel
}