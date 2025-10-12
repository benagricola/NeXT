/**
 * Wizard Components Registration
 * 
 * Registers all NeXT wizard components globally for use in templates
 */

import Vue from 'vue'
import ProbeDeflectionWizard from './ProbeDeflectionWizard.vue'
import SpindleConfigWizard from './SpindleConfigWizard.vue'

Vue.component('nxt-probe-deflection-wizard', ProbeDeflectionWizard)
Vue.component('nxt-spindle-config-wizard', SpindleConfigWizard)

export {
  ProbeDeflectionWizard,
  SpindleConfigWizard
}
