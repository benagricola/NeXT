<template>
  <v-container fluid class="pa-2">
    <!-- NeXT Main Dashboard Layout -->
    <v-row>
      <!-- Status Panel - Persistent across all views -->
      <v-col cols="12">
        <nxt-status-widget />
      </v-col>
    </v-row>

    <v-row>
      <!-- Main Content Area -->
      <v-col cols="12" md="8">
        <v-card>
          <v-card-title>
            <v-icon left>mdi-wrench</v-icon>
            {{ $t('NeXT.title') }}
          </v-card-title>
          
          <v-card-text>
            <v-alert 
              v-if="!nxtReady" 
              type="warning" 
              outlined
              class="mb-4"
            >
              <div class="d-flex align-center">
                <v-progress-circular
                  v-if="!globals.nxtLoaded"
                  indeterminate
                  size="20"
                  width="2"
                  class="mr-3"
                />
                <div>
                  <div class="font-weight-bold">
                    {{ globals.nxtLoaded ? 'UI Initializing...' : 'NeXT System Loading...' }}
                  </div>
                  <div class="text-caption">
                    {{ globals.nxtLoaded ? 'UI components are starting up' : 'Backend macros are initializing' }}
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
              {{ $t('NeXT.messages.uiReady') }}
            </v-alert>

            <!-- Tab Navigation for different sections -->
            <v-tabs v-model="activeTab" grow>
              <v-tab>{{ $t('NeXT.panels.status') }}</v-tab>
              <v-tab>{{ $t('NeXT.panels.configuration') }}</v-tab>
              <v-tab>{{ $t('NeXT.panels.stockPreparation') }}</v-tab>
              <v-tab>{{ $t('NeXT.panels.probing') }}</v-tab>
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

      <!-- Action Confirmation Widget -->
      <v-col cols="12" md="4">
        <nxt-action-confirmation-widget />
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
      activeTab: 0
    }
  },
  
  mounted() {
    console.log('NeXT: Main dashboard component mounted')
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