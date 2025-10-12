<template>
  <v-card>
    <v-card-title>
      <v-icon left>mdi-cog</v-icon>
      NeXT Configuration
    </v-card-title>
    
    <v-card-text>
      <v-alert type="info" outlined dense class="mb-4">
        <v-icon left small>mdi-information</v-icon>
        Changes are saved immediately to the object model. Use "Save Configuration" to persist to nxt-user-vars.g
      </v-alert>

      <!-- Feature Toggles -->
      <v-expansion-panels v-model="openPanels" multiple class="mb-4">
        <!-- Features Section -->
        <v-expansion-panel>
          <v-expansion-panel-header>
            <div>
              <v-icon left>mdi-toggle-switch</v-icon>
              <strong>Features</strong>
            </div>
          </v-expansion-panel-header>
          <v-expansion-panel-content>
            <v-row>
              <v-col cols="12" sm="4">
                <v-switch
                  v-model="localConfig.nxtFeatureTouchProbe"
                  label="Touch Probe"
                  :disabled="uiFrozen"
                  @change="updateFeature('nxtFeatureTouchProbe', $event)"
                  hide-details
                  class="mt-0"
                />
              </v-col>
              <v-col cols="12" sm="4">
                <v-switch
                  v-model="localConfig.nxtFeatureToolSetter"
                  label="Tool Setter"
                  :disabled="uiFrozen"
                  @change="updateFeature('nxtFeatureToolSetter', $event)"
                  hide-details
                  class="mt-0"
                />
              </v-col>
              <v-col cols="12" sm="4">
                <v-switch
                  v-model="localConfig.nxtFeatureCoolantControl"
                  label="Coolant Control"
                  :disabled="uiFrozen"
                  @change="updateFeature('nxtFeatureCoolantControl', $event)"
                  hide-details
                  class="mt-0"
                />
              </v-col>
            </v-row>
          </v-expansion-panel-content>
        </v-expansion-panel>

        <!-- Spindle Configuration -->
        <v-expansion-panel>
          <v-expansion-panel-header>
            <div>
              <v-icon left>mdi-fan</v-icon>
              <strong>Spindle Configuration</strong>
            </div>
          </v-expansion-panel-header>
          <v-expansion-panel-content>
            <v-row>
              <v-col cols="12" md="4">
                <v-text-field
                  v-model.number="localConfig.nxtSpindleID"
                  label="Spindle ID"
                  type="number"
                  :disabled="uiFrozen"
                  @blur="updateVariable('nxtSpindleID', localConfig.nxtSpindleID)"
                  hint="RRF spindle index (0-based)"
                  persistent-hint
                />
              </v-col>
              <v-col cols="12" md="4">
                <v-text-field
                  v-model.number="localConfig.nxtSpindleAccelSec"
                  label="Acceleration Time (s)"
                  type="number"
                  step="0.1"
                  :disabled="uiFrozen"
                  @blur="updateVariable('nxtSpindleAccelSec', localConfig.nxtSpindleAccelSec)"
                  hint="Time for spindle to reach speed"
                  persistent-hint
                />
              </v-col>
              <v-col cols="12" md="4">
                <v-text-field
                  v-model.number="localConfig.nxtSpindleDecelSec"
                  label="Deceleration Time (s)"
                  type="number"
                  step="0.1"
                  :disabled="uiFrozen"
                  @blur="updateVariable('nxtSpindleDecelSec', localConfig.nxtSpindleDecelSec)"
                  hint="Time for spindle to stop"
                  persistent-hint
                />
              </v-col>
            </v-row>
          </v-expansion-panel-content>
        </v-expansion-panel>

        <!-- Touch Probe Configuration -->
        <v-expansion-panel>
          <v-expansion-panel-header>
            <div>
              <v-icon left>mdi-target</v-icon>
              <strong>Touch Probe Configuration</strong>
            </div>
          </v-expansion-panel-header>
          <v-expansion-panel-content>
            <v-row>
              <v-col cols="12" md="4">
                <v-text-field
                  v-model.number="localConfig.nxtTouchProbeID"
                  label="Touch Probe Sensor ID"
                  type="number"
                  :disabled="uiFrozen"
                  @blur="updateVariable('nxtTouchProbeID', localConfig.nxtTouchProbeID)"
                  hint="RRF probe index"
                  persistent-hint
                />
              </v-col>
              <v-col cols="12" md="4">
                <v-text-field
                  v-model.number="localConfig.nxtProbeTipRadius"
                  label="Probe Tip Radius (mm)"
                  type="number"
                  step="0.001"
                  :disabled="uiFrozen"
                  @blur="updateVariable('nxtProbeTipRadius', localConfig.nxtProbeTipRadius)"
                  hint="For horizontal compensation"
                  persistent-hint
                />
              </v-col>
              <v-col cols="12" md="4">
                <v-text-field
                  v-model.number="localConfig.nxtProbeDeflection"
                  label="Probe Deflection (mm)"
                  type="number"
                  step="0.001"
                  :disabled="uiFrozen"
                  @blur="updateVariable('nxtProbeDeflection', localConfig.nxtProbeDeflection)"
                  hint="Measured deflection value"
                  persistent-hint
                />
              </v-col>
            </v-row>
            <v-row>
              <v-col cols="12">
                <v-btn
                  color="primary"
                  outlined
                  @click="showDeflectionWizard = true"
                  :disabled="uiFrozen || !localConfig.nxtFeatureTouchProbe"
                >
                  <v-icon left>mdi-wizard-hat</v-icon>
                  Measure Probe Deflection
                </v-btn>
              </v-col>
            </v-row>
          </v-expansion-panel-content>
        </v-expansion-panel>

        <!-- Tool Setter Configuration -->
        <v-expansion-panel>
          <v-expansion-panel-header>
            <div>
              <v-icon left>mdi-wrench</v-icon>
              <strong>Tool Setter Configuration</strong>
            </div>
          </v-expansion-panel-header>
          <v-expansion-panel-content>
            <v-row>
              <v-col cols="12" md="4">
                <v-text-field
                  v-model.number="localConfig.nxtToolSetterID"
                  label="Tool Setter Sensor ID"
                  type="number"
                  :disabled="uiFrozen"
                  @blur="updateVariable('nxtToolSetterID', localConfig.nxtToolSetterID)"
                  hint="RRF probe index"
                  persistent-hint
                />
              </v-col>
              <v-col cols="12" md="8">
                <v-text-field
                  :value="formatToolSetterPos"
                  label="Tool Setter Position [X, Y, Z]"
                  readonly
                  hint="Position in machine coordinates"
                  persistent-hint
                >
                  <template v-slot:append>
                    <v-btn
                      icon
                      small
                      @click="showToolSetterPosDialog = true"
                      :disabled="uiFrozen"
                    >
                      <v-icon small>mdi-pencil</v-icon>
                    </v-btn>
                  </template>
                </v-text-field>
              </v-col>
            </v-row>
          </v-expansion-panel-content>
        </v-expansion-panel>

        <!-- Coolant Control Configuration -->
        <v-expansion-panel>
          <v-expansion-panel-header>
            <div>
              <v-icon left>mdi-water</v-icon>
              <strong>Coolant Control Configuration</strong>
            </div>
          </v-expansion-panel-header>
          <v-expansion-panel-content>
            <v-row>
              <v-col cols="12" md="4">
                <v-text-field
                  v-model.number="localConfig.nxtCoolantAirID"
                  label="Air Blast Pin ID"
                  type="number"
                  :disabled="uiFrozen"
                  @blur="updateVariable('nxtCoolantAirID', localConfig.nxtCoolantAirID)"
                  hint="GP Output port number"
                  persistent-hint
                  clearable
                />
              </v-col>
              <v-col cols="12" md="4">
                <v-text-field
                  v-model.number="localConfig.nxtCoolantMistID"
                  label="Mist Coolant Pin ID"
                  type="number"
                  :disabled="uiFrozen"
                  @blur="updateVariable('nxtCoolantMistID', localConfig.nxtCoolantMistID)"
                  hint="GP Output port number"
                  persistent-hint
                  clearable
                />
              </v-col>
              <v-col cols="12" md="4">
                <v-text-field
                  v-model.number="localConfig.nxtCoolantFloodID"
                  label="Flood Coolant Pin ID"
                  type="number"
                  :disabled="uiFrozen"
                  @blur="updateVariable('nxtCoolantFloodID', localConfig.nxtCoolantFloodID)"
                  hint="GP Output port number"
                  persistent-hint
                  clearable
                />
              </v-col>
            </v-row>
          </v-expansion-panel-content>
        </v-expansion-panel>
      </v-expansion-panels>

      <!-- Action Buttons -->
      <v-row class="mt-4">
        <v-col cols="12">
          <v-btn
            color="success"
            @click="saveConfiguration"
            :disabled="uiFrozen || !nxtReady"
            :loading="saving"
          >
            <v-icon left>mdi-content-save</v-icon>
            Save Configuration
          </v-btn>
          <v-btn
            color="secondary"
            class="ml-2"
            @click="loadConfiguration"
            :disabled="uiFrozen"
            :loading="loading"
          >
            <v-icon left>mdi-refresh</v-icon>
            Reload
          </v-btn>
        </v-col>
      </v-row>

      <!-- Status Messages -->
      <v-alert
        v-if="statusMessage"
        :type="statusType"
        dismissible
        class="mt-4"
        @input="statusMessage = ''"
      >
        {{ statusMessage }}
      </v-alert>
    </v-card-text>

    <!-- Probe Deflection Wizard Dialog -->
    <nxt-probe-deflection-wizard
      v-model="showDeflectionWizard"
      @measured="onDeflectionMeasured"
    />

    <!-- Tool Setter Position Dialog -->
    <v-dialog v-model="showToolSetterPosDialog" max-width="500">
      <v-card>
        <v-card-title>Edit Tool Setter Position</v-card-title>
        <v-card-text>
          <v-row>
            <v-col cols="4">
              <v-text-field
                v-model.number="toolSetterPosEdit.x"
                label="X"
                type="number"
                step="0.001"
              />
            </v-col>
            <v-col cols="4">
              <v-text-field
                v-model.number="toolSetterPosEdit.y"
                label="Y"
                type="number"
                step="0.001"
              />
            </v-col>
            <v-col cols="4">
              <v-text-field
                v-model.number="toolSetterPosEdit.z"
                label="Z"
                type="number"
                step="0.001"
              />
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn text @click="showToolSetterPosDialog = false">Cancel</v-btn>
          <v-btn color="primary" @click="saveToolSetterPos">Save</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-card>
</template>

<script lang="ts">
import BaseComponent from '../base/BaseComponent.vue'

/**
 * NeXT Configuration Panel
 * 
 * Replaces G8000 wizard with direct UI-based configuration editing.
 * Allows configuration of all NeXT settings including features, spindle,
 * touch probe, tool setter, and coolant control.
 */
export default BaseComponent.extend({
  name: 'NxtConfigurationPanel',
  
  data() {
    return {
      openPanels: [0], // Open features panel by default
      showDeflectionWizard: false,
      showToolSetterPosDialog: false,
      saving: false,
      loading: false,
      statusMessage: '',
      statusType: 'success' as 'success' | 'error' | 'warning' | 'info',
      
      // Local configuration state
      localConfig: {
        nxtFeatureTouchProbe: false,
        nxtFeatureToolSetter: false,
        nxtFeatureCoolantControl: false,
        nxtSpindleID: null as number | null,
        nxtSpindleAccelSec: null as number | null,
        nxtSpindleDecelSec: null as number | null,
        nxtTouchProbeID: 0,
        nxtProbeTipRadius: 0.0,
        nxtProbeDeflection: 0.0,
        nxtToolSetterID: 1,
        nxtToolSetterPos: null as number[] | null,
        nxtCoolantAirID: null as number | null,
        nxtCoolantMistID: null as number | null,
        nxtCoolantFloodID: null as number | null
      },
      
      // Tool setter position editing
      toolSetterPosEdit: {
        x: 0,
        y: 0,
        z: 0
      }
    }
  },
  
  computed: {
    formatToolSetterPos(): string {
      if (!this.localConfig.nxtToolSetterPos || !Array.isArray(this.localConfig.nxtToolSetterPos)) {
        return 'Not configured'
      }
      return `[${this.localConfig.nxtToolSetterPos.map((v: number) => v.toFixed(3)).join(', ')}]`
    }
  },
  
  mounted() {
    console.log('NeXT: Configuration panel mounted')
    this.loadConfiguration()
  },
  
  methods: {
    /**
     * Load configuration from object model
     */
    loadConfiguration() {
      this.loading = true
      try {
        const globals = this.nxtGlobals
        
        // Load all configuration values
        this.localConfig.nxtFeatureTouchProbe = globals.nxtFeatureTouchProbe || false
        this.localConfig.nxtFeatureToolSetter = globals.nxtFeatureToolSetter || false
        this.localConfig.nxtFeatureCoolantControl = globals.nxtFeatureCoolantControl || false
        this.localConfig.nxtSpindleID = globals.nxtSpindleID
        this.localConfig.nxtSpindleAccelSec = globals.nxtSpindleAccelSec
        this.localConfig.nxtSpindleDecelSec = globals.nxtSpindleDecelSec
        this.localConfig.nxtTouchProbeID = globals.nxtTouchProbeID || 0
        this.localConfig.nxtProbeTipRadius = globals.nxtProbeTipRadius || 0.0
        this.localConfig.nxtProbeDeflection = globals.nxtProbeDeflection || 0.0
        this.localConfig.nxtToolSetterID = globals.nxtToolSetterID || 1
        this.localConfig.nxtToolSetterPos = globals.nxtToolSetterPos
        this.localConfig.nxtCoolantAirID = globals.nxtCoolantAirID
        this.localConfig.nxtCoolantMistID = globals.nxtCoolantMistID
        this.localConfig.nxtCoolantFloodID = globals.nxtCoolantFloodID
        
        console.log('NeXT: Configuration loaded', this.localConfig)
      } catch (error) {
        console.error('NeXT: Failed to load configuration', error)
        this.showStatus('Failed to load configuration', 'error')
      } finally {
        this.loading = false
      }
    },
    
    /**
     * Update a feature flag
     */
    async updateFeature(key: string, value: boolean) {
      try {
        await this.sendCode(`set global.${key} = ${value}`)
        this.showStatus(`${key} ${value ? 'enabled' : 'disabled'}`, 'success')
      } catch (error) {
        console.error('NeXT: Failed to update feature', key, error)
        this.showStatus(`Failed to update ${key}`, 'error')
        // Revert local state
        this.loadConfiguration()
      }
    },
    
    /**
     * Update a variable value
     */
    async updateVariable(key: string, value: any) {
      try {
        // Handle null values
        if (value === null || value === undefined || value === '') {
          await this.sendCode(`set global.${key} = null`)
        } else if (typeof value === 'number') {
          await this.sendCode(`set global.${key} = ${value}`)
        } else {
          await this.sendCode(`set global.${key} = "${value}"`)
        }
        console.log(`NeXT: Updated ${key} to ${value}`)
      } catch (error) {
        console.error('NeXT: Failed to update variable', key, error)
        this.showStatus(`Failed to update ${key}`, 'error')
      }
    },
    
    /**
     * Save configuration to nxt-user-vars.g
     */
    async saveConfiguration() {
      this.saving = true
      try {
        // TODO: Implement M-code to save configuration to file
        // For now, just show a warning that this needs backend implementation
        this.showStatus(
          'Configuration saved to object model. Backend M-code for persisting to nxt-user-vars.g needs to be implemented.',
          'warning'
        )
      } catch (error) {
        console.error('NeXT: Failed to save configuration', error)
        this.showStatus('Failed to save configuration', 'error')
      } finally {
        this.saving = false
      }
    },
    
    /**
     * Handle probe deflection measurement result
     */
    onDeflectionMeasured(deflection: number) {
      this.localConfig.nxtProbeDeflection = deflection
      this.updateVariable('nxtProbeDeflection', deflection)
      this.showStatus(`Probe deflection set to ${deflection.toFixed(4)} mm`, 'success')
    },
    
    /**
     * Save tool setter position
     */
    async saveToolSetterPos() {
      try {
        const pos = [
          this.toolSetterPosEdit.x,
          this.toolSetterPosEdit.y,
          this.toolSetterPosEdit.z
        ]
        await this.sendCode(`set global.nxtToolSetterPos = {${pos.join(', ')}}`)
        this.localConfig.nxtToolSetterPos = pos
        this.showToolSetterPosDialog = false
        this.showStatus('Tool setter position updated', 'success')
      } catch (error) {
        console.error('NeXT: Failed to update tool setter position', error)
        this.showStatus('Failed to update tool setter position', 'error')
      }
    },
    
    /**
     * Show status message
     */
    showStatus(message: string, type: 'success' | 'error' | 'warning' | 'info') {
      this.statusMessage = message
      this.statusType = type
    }
  },
  
  watch: {
    showToolSetterPosDialog(val: boolean) {
      if (val && this.localConfig.nxtToolSetterPos && Array.isArray(this.localConfig.nxtToolSetterPos)) {
        // Initialize edit values from current position
        this.toolSetterPosEdit.x = this.localConfig.nxtToolSetterPos[0] || 0
        this.toolSetterPosEdit.y = this.localConfig.nxtToolSetterPos[1] || 0
        this.toolSetterPosEdit.z = this.localConfig.nxtToolSetterPos[2] || 0
      }
    }
  }
})
</script>

<style scoped>
.v-expansion-panel-content >>> .v-expansion-panel-content__wrap {
  padding-top: 16px;
}
</style>
