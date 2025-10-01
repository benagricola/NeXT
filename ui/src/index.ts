/**
 * NeXT UI Plugin Entry Point
 * 
 * Main entry point for the NeXT (Next-Gen Extended Tooling) DWC plugin.
 * Registers the plugin with DWC, sets up routes, localization, and components.
 */

import Vue from 'vue'
import { registerRoute, registerPluginLocalization, registerPluginData } from '@/utils/plugin'

// Import main components
import NeXT from './NeXT.vue'

// Import and register component modules
import './components/base'
import './components/inputs'
import './components/panels'
import './components/overrides'

// Import localization
import en from './locales/en.json'

// Register plugin localization
registerPluginLocalization('en', en)

// Register plugin-specific data in the machine cache
registerPluginData('nxtUiState', {
  ready: false,
  dialogActive: false,
  dialogMessage: null,
  dialogResponse: null,
  lastProbeResults: [],
  selectedResultIndex: 0
})

// Register the main NeXT route under Control menu
registerRoute(NeXT, {
  Control: {
    NeXT: {
      icon: 'mdi-wrench',
      caption: 'NeXT.title',
      path: '/NeXT'
    }
  }
})

// Set nxtUiReady flag when plugin loads
Vue.nextTick(() => {
  // Send G-code to set the UI ready flag
  const store = Vue.prototype.$store
  if (store) {
    store.dispatch('machine/sendCode', 'set global.nxtUiReady = true')
      .then(() => {
        console.log('NeXT UI: Plugin loaded and ready')
      })
      .catch((error: any) => {
        console.error('NeXT UI: Failed to set ready flag', error)
      })
  }
})

export default NeXT