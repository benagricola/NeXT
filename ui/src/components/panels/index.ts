/**
 * Panel Components Registration
 * 
 * Registers all NeXT panel components globally for use in templates
 */

import Vue from 'vue'
import StatusWidget from './StatusWidget.vue'
import ActionConfirmationWidget from './ActionConfirmationWidget.vue'
import MachineStatusPanel from './MachineStatusPanel.vue'

// Register panel components
Vue.component('nxt-status-widget', StatusWidget)
Vue.component('nxt-action-confirmation-widget', ActionConfirmationWidget)
Vue.component('nxt-machine-status-panel', MachineStatusPanel)

export {
  StatusWidget,
  ActionConfirmationWidget,
  MachineStatusPanel
}