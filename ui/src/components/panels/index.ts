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
import StockPreparationPanel from './StockPreparationPanel.vue'
import ToolpathViewer3D from './ToolpathViewer3D.vue'

// Register panel components
Vue.component('nxt-status-widget', StatusWidget)
Vue.component('nxt-action-confirmation-widget', ActionConfirmationWidget)
Vue.component('nxt-machine-status-panel', MachineStatusPanel)
Vue.component('nxt-configuration-panel', ConfigurationPanel)
Vue.component('nxt-stock-preparation-panel', StockPreparationPanel)
Vue.component('toolpath-viewer-3d', ToolpathViewer3D)

export {
  StatusWidget,
  ActionConfirmationWidget,
  MachineStatusPanel,
  ConfigurationPanel,
  StockPreparationPanel,
  ToolpathViewer3D
}