<template>
  <v-container fluid class="pa-2">
    <!-- NeXT Main Dashboard Layout -->
    <!-- Status strip removed: CNC dashboard override supplies its own status UI -->

    <v-row>
      <!-- Action Confirmation Widget - Full width above main content -->
      <v-col v-if="hasActiveDialog" cols="12">
        <nxt-action-confirmation-widget />
      </v-col>

      <!-- Main Content Area -->
      <v-col cols="12">
        <v-card>
          <v-card-title>
            <v-icon left>mdi-wrench</v-icon>
            {{ $t('plugins.next.title') }}
          </v-card-title>
          
          <v-card-text>
            <!-- Restart Required Alert -->
            <v-alert 
              v-if="restartRequired" 
              type="error" 
              outlined
              class="mb-4"
            >
              <div class="d-flex align-center justify-space-between">
                <div>
                  <div class="font-weight-bold">
                    <v-icon left>mdi-restart</v-icon>
                    {{ $t('plugins.next.messages.restartRequired') }}
                  </div>
                  <div class="text-caption mt-1">
                    {{ $t('plugins.next.messages.restartMessage') }}
                  </div>
                </div>
                <v-btn 
                  color="error" 
                  @click="restartMachine"
                  :loading="restarting"
                >
                  {{ $t('plugins.next.messages.restartButton') }}
                </v-btn>
              </div>
              <v-alert 
                type="warning" 
                dense 
                outlined 
                class="mt-3 mb-0"
              >
                <v-icon left small>mdi-alert</v-icon>
                {{ $t('plugins.next.messages.restartWarning') }}
              </v-alert>
            </v-alert>

            <!-- Loading/Disconnected Alert -->
            <v-alert 
              v-else-if="!nxtReady" 
              :type="isConnected ? 'warning' : 'info'" 
              outlined
              class="mb-4"
            >
              <div class="d-flex align-center">
                <v-progress-circular
                  v-if="isConnected && globals.nxtLoaded !== true"
                  indeterminate
                  size="20"
                  width="2"
                  class="mr-3"
                />
                <v-icon 
                  v-else-if="!isConnected"
                  class="mr-3"
                >
                  mdi-lan-disconnect
                </v-icon>
                <div>
                  <div class="font-weight-bold">
                    {{ !isConnected ? 'Machine Disconnected' : (globals.nxtLoaded === true ? 'UI Initializing...' : 'NeXT System Loading...') }}
                  </div>
                  <div class="text-caption">
                    {{ !isConnected ? 'Connect to a machine to use NeXT features' : (globals.nxtLoaded === true ? 'UI components are starting up' : 'Backend macros are initializing') }}
                  </div>
                </div>
              </div>
            </v-alert>

            <v-alert
              v-else
              type="success"
              outlined
              class="mb-4"
            >
              <v-icon left>mdi-check-circle</v-icon>
              {{ $t('plugins.next.messages.uiReady') }}
            </v-alert>

            <!-- Tab Navigation for different sections -->
            <v-tabs v-model="activeTab" grow>
              <v-tab>{{ statusCaption }}</v-tab>
              <v-tab>{{ configurationCaption }}</v-tab>
              <v-tab>{{ stockPreparationCaption }}</v-tab>
              <v-tab>{{ probingCaption }}</v-tab>
            </v-tabs>

            <v-tabs-items v-model="activeTab">
              <!-- Status Tab -->
              <v-tab-item>
                <div class="pa-4">
                  <nxt-machine-status-panel />
                </div>
              </v-tab-item>

              <!-- Configuration Tab -->
              <v-tab-item>
                <div class="pa-4">
                  <nxt-configuration-panel />
                </div>
              </v-tab-item>

              <!-- Stock Preparation Tab -->
              <v-tab-item>
                <div class="pa-4">
                  <nxt-stock-preparation-panel />
                </div>
              </v-tab-item>

              <!-- Probing Tab -->
              <v-tab-item>
                <div class="pa-4">
                  <v-alert type="info" outlined>
                    <v-icon left>mdi-target</v-icon>
                    Probing UI will be implemented in Phase 3
                  </v-alert>
                </div>
              </v-tab-item>
            </v-tabs-items>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script lang="ts">
import BaseComponent from './components/base/BaseComponent.vue'

/**
 * NeXT Main Dashboard Component
 * 
 * Provides the primary interface for NeXT functionality within DWC.
 * Includes the persistent status widget and action confirmation widget
 * as specified in the Phase 2.1 requirements.
 */
export default BaseComponent.extend({
  name: 'NeXT',
  data() {
    return {
      activeTab: 0,
      restarting: false,
    }
  },
  
  computed: {
    /**
     * Check if we're connected to a machine
     */
    isConnected(): boolean {
      return this.$store.getters["isConnected"]
    },

    /**
     * Check if machine restart is required (nxtLoaded variable doesn't exist)
     * Only check this if we're actually connected to a machine
     */
    restartRequired(): boolean {
      // Don't show restart warning if disconnected
      if (!this.isConnected) {
        return false
      }
      // Check if nxtLoaded global exists
      return !('nxtLoaded' in this.globals)
    },

    /**
     * Check if there's an active dialog requiring user action
     */
    hasActiveDialog(): boolean {
      const messageBox = this.$store.state.machine.model.messageBox
      return messageBox && messageBox.message ? true : false
    },

    statusCaption(): string {
      const key = 'plugins.next.panels.status.caption'
      const t = (this as any).$t(key).toString()
      return t === key ? 'Status' : t
    },

    configurationCaption(): string {
      const key = 'plugins.next.panels.configuration.caption'
      const t = (this as any).$t(key).toString()
      return t === key ? 'Configuration' : t
    },

    stockPreparationCaption(): string {
      const key = 'plugins.next.panels.stockPreparation.caption'
      const t = (this as any).$t(key).toString()
      return t === key ? 'Stock Preparation' : t
    },

    probingCaption(): string {
      const key = 'plugins.next.panels.probing.caption'
      const t = (this as any).$t(key).toString()
      return t === key ? 'Probing' : t
    },
  },

  methods: {
    /**
     * Restart the machine using M999
     */
    async restartMachine() {
      this.restarting = true
      try {
        await this.sendCode('M999')
        // M999 will restart the machine, so UI will disconnect
      } catch (error) {
        console.error('NeXT: Failed to restart machine:', error)
        // Reset loading state if restart fails
        this.restarting = false
      }
    }
  },
  
  mounted() {
    console.log('NeXT: Main dashboard component mounted')
    console.log('NeXT: Connected to machine:', this.isConnected)
    if (this.isConnected && this.restartRequired) {
      console.log('NeXT: Machine restart required - nxtLoaded variable not found')
    } else if (!this.isConnected) {
      console.log('NeXT: Not connected to machine - some features will be unavailable')
    }
  }
})
</script>

<style scoped>
/* Component-specific styles */
.v-card {
  height: 100%;
}

.v-alert {
  border-left: 4px solid currentColor !important;
}
</style>