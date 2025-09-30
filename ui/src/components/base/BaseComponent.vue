<template>
  <!-- Base component - not meant to be rendered directly -->
  <div></div>
</template>

<script lang="ts">
import Vue from 'vue'

/**
 * BaseComponent - Foundation component for all NeXT UI components
 * 
 * Provides common computed properties and methods for consistent
 * interaction with the DWC store and RRF object model.
 */
export default Vue.extend({
  name: 'BaseComponent',
  computed: {
    /**
     * Check if UI is frozen (during macro execution, etc.)
     */
    uiFrozen(): boolean {
      return this.$store.state.machine.model.state.status === 'processing'
    },

    /**
     * Check if all visible axes are homed
     */
    allAxesHomed(): boolean {
      const axes = this.$store.state.machine.model.move.axes
      const visibleAxes = this.$store.state.machine.settings.displayedAxes
      return visibleAxes.every((axis: number) => axes[axis] && axes[axis].homed)
    },

    /**
     * Get visible axes mapped by letter (X, Y, Z, etc.)
     */
    visibleAxesByLetter(): Record<string, any> {
      const axes = this.$store.state.machine.model.move.axes
      const visibleAxes = this.$store.state.machine.settings.displayedAxes
      const result: Record<string, any> = {}
      
      visibleAxes.forEach((axisIndex: number) => {
        const axis = axes[axisIndex]
        if (axis) {
          result[axis.letter] = axis
        }
      })
      
      return result
    },

    /**
     * Get the currently selected tool
     */
    currentTool(): any {
      const tools = this.$store.state.machine.model.tools
      const currentToolIndex = this.$store.state.machine.model.state.currentTool
      return tools[currentToolIndex] || null
    },

    /**
     * Get the configured probe tool (last tool by default)
     */
    probeTool(): any {
      const tools = this.$store.state.machine.model.tools
      const probeToolId = this.$store.state.machine.model.global?.nxtProbeToolID
      if (probeToolId !== undefined && tools[probeToolId]) {
        return tools[probeToolId]
      }
      // Default to last tool if nxtProbeToolID not set
      return tools[tools.length - 1] || null
    },

    /**
     * Get/Set current workplace coordinate system
     */
    currentWorkplace: {
      get(): number {
        return this.$store.state.machine.model.move.currentWorkplace || 1
      },
      set(workplace: number) {
        this.sendCode(`G${54 + workplace - 1}`)
      }
    },

    /**
     * Calculate absolute machine position for visible axes
     */
    absolutePosition(): Record<string, number> {
      const axes = this.visibleAxesByLetter
      const workplaceOffsets = this.$store.state.machine.model.move.workplaceOffsets
      const currentWP = this.currentWorkplace - 1
      const result: Record<string, number> = {}

      Object.keys(axes).forEach(letter => {
        const axis = axes[letter]
        const offset = workplaceOffsets[currentWP] ? workplaceOffsets[currentWP][axis.letter] : 0
        result[letter] = (axis.machinePosition || 0) - offset
      })

      return result
    },

    /**
     * Get NeXT global variables from RRF object model
     */
    nxtGlobals(): Record<string, any> {
      return this.$store.state.machine.model.global || {}
    },

    /**
     * Check if NeXT system is loaded and ready
     */
    nxtReady(): boolean {
      return this.nxtGlobals.nxtLoaded === true && this.nxtGlobals.nxtUiReady === true
    }
  },

  methods: {
    /**
     * Send G-code command to the machine
     */
    async sendCode(code: string): Promise<any> {
      try {
        return await this.$store.dispatch('machine/sendCode', code)
      } catch (error) {
        console.error('NeXT UI: Failed to send code:', code, error)
        throw error
      }
    }
  }
})
  }
})
</script>