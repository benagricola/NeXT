<template>
  <v-card class="nxt-action-widget" :class="{ 'elevation-8': hasActiveDialog }">
    <v-card-title class="py-2">
      <v-icon left small>mdi-check-circle</v-icon>
      Action Required
    </v-card-title>
    
    <!-- Active Dialog Display -->
    <v-card-text v-if="hasActiveDialog" class="py-2">
      <div class="dialog-container">
        <div class="dialog-title">{{ dialogTitle }}</div>
        <div class="dialog-message">{{ dialogMessage }}</div>
        
        <v-divider class="my-3" />
        
        <div class="dialog-actions">
          <v-btn
            v-for="(button, index) in dialogButtons"
            :key="index"
            :color="getButtonColor(button, index)"
            :outlined="index !== 0"
            small
            class="mr-2 mb-2"
            @click="respondToDialog(index)"
          >
            {{ button }}
          </v-btn>
        </div>
      </div>
    </v-card-text>

    <!-- No Active Dialog State -->
    <v-card-text v-else class="py-2">
      <div class="no-dialog-state">
        <v-icon large color="grey lighten-1">mdi-check-circle-outline</v-icon>
        <div class="mt-2 text-caption text--secondary">
          No actions pending
        </div>
      </div>
    </v-card-text>
  </v-card>
</template>

<script lang="ts">
import BaseComponent from '../base/BaseComponent.vue'

/**
 * NeXT Action Confirmation Widget
 * 
 * Displays persistent dialog interface for M1000 dialogs and other
 * confirmation actions. Replaces blocking modal dialogs with a
 * persistent panel when NeXT UI is active.
 */
export default BaseComponent.extend({
  name: 'NxtActionConfirmationWidget',
  
  data() {
    return {
      // Local dialog state for UI responsiveness
      localDialogActive: false,
      localDialogMessage: '',
      localDialogTitle: 'NeXT',
      localDialogButtons: ['OK']
    }
  },

  computed: {
    hasActiveDialog(): boolean {
      return this.nxtGlobals.nxtDialogActive === true || this.localDialogActive
    },

    dialogMessage(): string {
      return this.nxtGlobals.nxtDialogMessage || this.localDialogMessage || ''
    },

    dialogTitle(): string {
      return this.nxtGlobals.nxtDialogTitle || this.localDialogTitle || 'NeXT'
    },

    dialogButtons(): string[] {
      const buttons = this.nxtGlobals.nxtDialogButtons || this.localDialogButtons
      if (Array.isArray(buttons)) {
        return buttons
      }
      if (typeof buttons === 'string') {
        try {
          return JSON.parse(buttons)
        } catch {
          return [buttons]
        }
      }
      return ['OK']
    }
  },

  methods: {
    getButtonColor(button: string, index: number): string {
      const lowerButton = button.toLowerCase()
      
      // Primary action (usually first button)
      if (index === 0) {
        if (lowerButton.includes('cancel') || lowerButton.includes('abort')) {
          return 'error'
        }
        return 'primary'
      }
      
      // Secondary actions
      if (lowerButton.includes('cancel') || lowerButton.includes('abort')) {
        return 'error'
      }
      if (lowerButton.includes('continue') || lowerButton.includes('ok')) {
        return 'success'
      }
      
      return 'default'
    },

    async respondToDialog(buttonIndex: number): Promise<void> {
      try {
        // Send response via G-code to set global variable
        await this.sendCode(`set global.nxtDialogResponse = ${buttonIndex}`)
        
        // Clear local dialog state
        this.localDialogActive = false
        this.localDialogMessage = ''
        this.localDialogTitle = 'NeXT'
        this.localDialogButtons = ['OK']
        
        console.log(`NeXT UI: Dialog response sent: ${buttonIndex}`)
      } catch (error) {
        console.error('NeXT UI: Failed to send dialog response:', error)
        this.$store.dispatch('machine/showMessage', {
          type: 'error',
          message: 'Failed to send response'
        })
      }
    },

    showTestDialog(): void {
      this.localDialogActive = true
      this.localDialogMessage = 'This is a test dialog for UI development'
      this.localDialogTitle = 'Test Dialog'
      this.localDialogButtons = ['Continue', 'Cancel']
    }
  },

  mounted() {
    // Listen for dialog state changes from RRF object model
    this.$store.subscribe((mutation: any) => {
      if (mutation.type === 'machine/model/update') {
        // React to dialog state changes
        const globals = mutation.payload.global || {}
        if (globals.nxtDialogActive !== undefined) {
          console.log('NeXT UI: Dialog state changed:', globals.nxtDialogActive)
        }
      }
    })

    // For development: show test dialog in 3 seconds if in dev environment
    if (process.env.NODE_ENV === 'development') {
      setTimeout(() => {
        this.showTestDialog()
      }, 3000)
    }
  }
})
</script>

<style scoped>
.nxt-action-widget {
  position: sticky;
  top: 180px; /* Below status widget */
  z-index: 9;
  transition: box-shadow 0.3s ease;
}

.nxt-action-widget.elevation-8 {
  border-left: 4px solid var(--v-primary-base);
}

.dialog-container {
  min-height: 120px;
}

.dialog-title {
  font-size: 1rem;
  font-weight: 600;
  color: var(--v-primary-base);
  margin-bottom: 8px;
}

.dialog-message {
  font-size: 0.9rem;
  line-height: 1.4;
  margin-bottom: 12px;
  white-space: pre-wrap;
  word-wrap: break-word;
}

.dialog-actions {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-start;
}

.no-dialog-state {
  text-align: center;
  padding: 20px 0;
  opacity: 0.6;
}

.v-card-title {
  font-size: 0.875rem !important;
  background-color: rgba(0, 0, 0, 0.03);
}

.v-card-text {
  padding-top: 12px !important;
  padding-bottom: 12px !important;
}

/* Responsive adjustments */
@media (max-width: 600px) {
  .dialog-actions {
    justify-content: center;
  }
  
  .dialog-actions .v-btn {
    margin: 2px;
    min-width: 80px;
  }
}
</style>