/**
 * Wizard Components Registration
 * 
 * Registers all NeXT wizard components globally for use in templates
 */

import Vue from 'vue'
import ProbeDeflectionWizard from './ProbeDeflectionWizard.vue'

Vue.component('nxt-probe-deflection-wizard', ProbeDeflectionWizard)

export {
  ProbeDeflectionWizard
}
