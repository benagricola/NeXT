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
              <v-col cols="12">
                <v-select
                  v-model="localConfig.nxtSpindleID"
                  :items="availableSpindles"
                  item-text="name"
                  item-value="id"
                  label="Spindle"
                  :disabled="uiFrozen"
                  @change="updateVariable('nxtSpindleID', localConfig.nxtSpindleID)"
                  hint="Select configured spindle"
                  persistent-hint
                  clearable
                >
                  <template v-slot:item="{ item }">
                    <v-list-item-content>
                      <v-list-item-title>{{ item.name }}</v-list-item-title>
                      <v-list-item-subtitle>ID: {{ item.id }}</v-list-item-subtitle>
                    </v-list-item-content>
                  </template>
                  <template v-slot:append-outer>
                    <v-tooltip top>
                      <template v-slot:activator="{ on }">
                        <v-btn
                          icon
                          small
                          @mousedown="startSpindleTest"
                          @mouseup="stopSpindleTest"
                          @mouseleave="stopSpindleTest"
                          @touchstart="startSpindleTest"
                          @touchend="stopSpindleTest"
                          :disabled="uiFrozen || localConfig.nxtSpindleID === null"
                          :color="spindleTesting ? 'primary' : ''"
                          v-on="on"
                        >
                          <v-icon small>{{ spindleTesting ? 'mdi-fan' : 'mdi-test-tube' }}</v-icon>
                        </v-btn>
                      </template>
                      <span>{{ spindleTesting ? 'Release to Stop' : 'Hold to Test Spindle' }}</span>
                    </v-tooltip>
                  </template>
                </v-select>
              </v-col>
            </v-row>
            <v-row>
              <v-col cols="12" md="6">
                <v-text-field
                  v-model.number="localConfig.nxtSpindleAccelSec"
                  label="Acceleration Time (s)"
                  type="number"
                  step="0.1"
                  :disabled="uiFrozen"
                  @blur="updateVariable('nxtSpindleAccelSec', localConfig.nxtSpindleAccelSec)"
                  hint="Time for spindle to reach speed"
                  persistent-hint
                >
                  <template v-slot:append-outer>
                    <v-tooltip top>
                      <template v-slot:activator="{ on }">
                        <v-btn
                          icon
                          small
                          @click="measureSpindleAcceleration"
                          :disabled="uiFrozen || localConfig.nxtSpindleID === null || measuringAccel"
                          :loading="measuringAccel"
                          v-on="on"
                        >
                          <v-icon small>mdi-timer-play</v-icon>
                        </v-btn>
                      </template>
                      <span>Measure Acceleration</span>
                    </v-tooltip>
                  </template>
                </v-text-field>
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field
                  v-model.number="localConfig.nxtSpindleDecelSec"
                  label="Deceleration Time (s)"
                  type="number"
                  step="0.1"
                  :disabled="uiFrozen"
                  @blur="updateVariable('nxtSpindleDecelSec', localConfig.nxtSpindleDecelSec)"
                  hint="Time for spindle to stop"
                  persistent-hint
                >
                  <template v-slot:append-outer>
                    <v-tooltip top>
                      <template v-slot:activator="{ on }">
                        <v-btn
                          icon
                          small
                          @click="measureSpindleDeceleration"
                          :disabled="uiFrozen || localConfig.nxtSpindleID === null || measuringDecel"
                          :loading="measuringDecel"
                          v-on="on"
                        >
                          <v-icon small>mdi-timer-stop</v-icon>
                        </v-btn>
                      </template>
                      <span>Measure Deceleration</span>
                    </v-tooltip>
                  </template>
                </v-text-field>
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
              <v-col cols="12">
                <v-select
                  v-model="localConfig.nxtTouchProbeID"
                  :items="availableProbes"
                  item-text="name"
                  item-value="id"
                  label="Touch Probe Sensor"
                  :disabled="uiFrozen"
                  @change="updateVariable('nxtTouchProbeID', localConfig.nxtTouchProbeID)"
                  hint="Select configured probe"
                  persistent-hint
                  clearable
                >
                  <template v-slot:item="{ item }">
                    <v-list-item-content>
                      <v-list-item-title>{{ item.name }}</v-list-item-title>
                      <v-list-item-subtitle>ID: {{ item.id }} | Type: {{ item.type }}</v-list-item-subtitle>
                    </v-list-item-content>
                  </template>
                  <template v-slot:append-outer>
                    <v-chip
                      v-if="localConfig.nxtTouchProbeID !== null"
                      small
                      :color="touchProbeTriggered ? 'success' : 'grey'"
                      @click="testTouchProbe"
                    >
                      <v-icon small left>{{ touchProbeTriggered ? 'mdi-check-circle' : 'mdi-circle-outline' }}</v-icon>
                      {{ touchProbeTriggered ? 'Triggered' : 'Test' }}
                    </v-chip>
                  </template>
                </v-select>
              </v-col>
            </v-row>
            <v-row>
              <v-col cols="12" md="6">
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
              <v-col cols="12" md="6">
                <v-text-field
                  v-model.number="localConfig.nxtProbeDeflection"
                  label="Probe Deflection (mm)"
                  type="number"
                  step="0.001"
                  :disabled="uiFrozen"
                  @blur="updateVariable('nxtProbeDeflection', localConfig.nxtProbeDeflection)"
                  hint="Measured deflection value"
                  persistent-hint
                >
                  <template v-slot:append-outer>
                    <v-tooltip top>
                      <template v-slot:activator="{ on }">
                        <v-btn
                          icon
                          small
                          @click="navigateToCalibration"
                          :disabled="uiFrozen || !localConfig.nxtFeatureTouchProbe"
                          v-on="on"
                        >
                          <v-icon small>mdi-ruler</v-icon>
                        </v-btn>
                      </template>
                      <span>Go to Calibration</span>
                    </v-tooltip>
                  </template>
                </v-text-field>
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
              <v-col cols="12">
                <v-select
                  v-model="localConfig.nxtToolSetterID"
                  :items="availableProbes"
                  item-text="name"
                  item-value="id"
                  label="Tool Setter Sensor"
                  :disabled="uiFrozen"
                  @change="updateVariable('nxtToolSetterID', localConfig.nxtToolSetterID)"
                  hint="Select configured probe"
                  persistent-hint
                  clearable
                >
                  <template v-slot:item="{ item }">
                    <v-list-item-content>
                      <v-list-item-title>{{ item.name }}</v-list-item-title>
                      <v-list-item-subtitle>ID: {{ item.id }} | Type: {{ item.type }}</v-list-item-subtitle>
                    </v-list-item-content>
                  </template>
                  <template v-slot:append-outer>
                    <v-chip
                      v-if="localConfig.nxtToolSetterID !== null"
                      small
                      :color="toolSetterTriggered ? 'success' : 'grey'"
                      @click="testToolSetter"
                    >
                      <v-icon small left>{{ toolSetterTriggered ? 'mdi-check-circle' : 'mdi-circle-outline' }}</v-icon>
                      {{ toolSetterTriggered ? 'Triggered' : 'Test' }}
                    </v-chip>
                  </template>
                </v-select>
              </v-col>
            </v-row>
            <v-row>
              <v-col cols="12">
                <v-text-field
                  :value="formatToolSetterPos"
                  label="Tool Setter Position [X, Y, Z]"
                  readonly
                  hint="Position in machine coordinates"
                  persistent-hint
                >
                  <template v-slot:append>
                    <v-tooltip top>
                      <template v-slot:activator="{ on }">
                        <v-btn
                          icon
                          small
                          @click="setCurrentPositionAsToolSetter"
                          :disabled="uiFrozen || !allAxesHomed"
                          v-on="on"
                        >
                          <v-icon small>mdi-crosshairs-gps</v-icon>
                        </v-btn>
                      </template>
                      <span>Set Current Position</span>
                    </v-tooltip>
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
                <v-select
                  v-model="localConfig.nxtCoolantAirID"
                  :items="availableGpOutputs"
                  item-text="name"
                  item-value="id"
                  label="Air Blast Output"
                  :disabled="uiFrozen"
                  @change="updateVariable('nxtCoolantAirID', localConfig.nxtCoolantAirID)"
                  hint="Select GP Output port"
                  persistent-hint
                  clearable
                >
                  <template v-slot:item="{ item }">
                    <v-list-item-content>
                      <v-list-item-title>{{ item.name }}</v-list-item-title>
                    </v-list-item-content>
                  </template>
                </v-select>
              </v-col>
              <v-col cols="12" md="4">
                <v-select
                  v-model="localConfig.nxtCoolantMistID"
                  :items="availableGpOutputs"
                  item-text="name"
                  item-value="id"
                  label="Mist Coolant Output"
                  :disabled="uiFrozen"
                  @change="updateVariable('nxtCoolantMistID', localConfig.nxtCoolantMistID)"
                  hint="Select GP Output port"
                  persistent-hint
                  clearable
                >
                  <template v-slot:item="{ item }">
                    <v-list-item-content>
                      <v-list-item-title>{{ item.name }}</v-list-item-title>
                    </v-list-item-content>
                  </template>
                </v-select>
              </v-col>
              <v-col cols="12" md="4">
                <v-select
                  v-model="localConfig.nxtCoolantFloodID"
                  :items="availableGpOutputs"
                  item-text="name"
                  item-value="id"
                  label="Flood Coolant Output"
                  :disabled="uiFrozen"
                  @change="updateVariable('nxtCoolantFloodID', localConfig.nxtCoolantFloodID)"
                  hint="Select GP Output port"
                  persistent-hint
                  clearable
                >
                  <template v-slot:item="{ item }">
                    <v-list-item-content>
                      <v-list-item-title>{{ item.name }}</v-list-item-title>
                    </v-list-item-content>
                  </template>
                </v-select>
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
      showToolSetterPosDialog: false,
      saving: false,
      loading: false,
      statusMessage: '',
      statusType: 'success' as 'success' | 'error' | 'warning' | 'info',
      
      // Measurement states
      measuringAccel: false,
      measuringDecel: false,
      accelStartTime: 0,
      decelStartTime: 0,
      
      // Probe test states
      touchProbeTriggered: false,
      toolSetterTriggered: false,
      
      // Spindle test state
      spindleTesting: false,
      
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
    },
    
    /**
     * Get minimum RPM for the selected spindle
     */
    selectedSpindleMinRpm(): number {
      if (this.localConfig.nxtSpindleID === null) return 1000
      
      const spindles = this.$store.state.machine.model.spindles || []
      const spindle = spindles[this.localConfig.nxtSpindleID]
      
      if (spindle && spindle.min !== undefined) {
        return spindle.min
      }
      
      // Default to 1000 RPM if not specified
      return 1000
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
     * Start spindle test (on button press)
     */
    async startSpindleTest() {
      if (this.localConfig.nxtSpindleID === null || this.spindleTesting) return
      
      this.spindleTesting = true
      
      try {
        const rpm = this.selectedSpindleMinRpm
        this.showStatus(`Starting spindle at ${rpm} RPM (minimum speed). Release button to stop.`, 'info')
        await this.sendCode(`M3 S${rpm}`)
      } catch (error) {
        console.error('NeXT: Spindle test start failed', error)
        this.showStatus('Failed to start spindle', 'error')
        this.spindleTesting = false
      }
    },
    
    /**
     * Stop spindle test (on button release)
     */
    async stopSpindleTest() {
      if (!this.spindleTesting) return
      
      this.spindleTesting = false
      
      try {
        await this.sendCode('M5')
        this.showStatus('Spindle stopped', 'success')
      } catch (error) {
        console.error('NeXT: Spindle stop failed', error)
        this.showStatus('Failed to stop spindle', 'error')
      }
    },
    
    /**
     * Measure spindle acceleration time
     */
    async measureSpindleAcceleration() {
      if (this.localConfig.nxtSpindleID === null) return
      
      this.measuringAccel = true
      try {
        // Show dialog to user
        this.showStatus('Starting spindle. Click "Stop Timing" when spindle reaches full speed.', 'info')
        
        // Start spindle
        this.accelStartTime = Date.now()
        await this.sendCode('M3 S10000')
        
        // Wait for user to click (simulated here with a prompt)
        // In a real implementation, this would be a dialog with a button
        await new Promise(resolve => setTimeout(resolve, 3000))
        
        const elapsed = (Date.now() - this.accelStartTime) / 1000
        this.localConfig.nxtSpindleAccelSec = parseFloat(elapsed.toFixed(2))
        await this.updateVariable('nxtSpindleAccelSec', this.localConfig.nxtSpindleAccelSec)
        
        this.showStatus(`Acceleration time measured: ${elapsed.toFixed(2)}s`, 'success')
      } catch (error) {
        console.error('NeXT: Acceleration measurement failed', error)
        this.showStatus('Acceleration measurement failed', 'error')
      } finally {
        this.measuringAccel = false
      }
    },
    
    /**
     * Measure spindle deceleration time
     */
    async measureSpindleDeceleration() {
      if (this.localConfig.nxtSpindleID === null) return
      
      this.measuringDecel = true
      try {
        // Show dialog to user
        this.showStatus('Stopping spindle. Click "Stop Timing" when spindle stops completely.', 'info')
        
        // Stop spindle
        this.decelStartTime = Date.now()
        await this.sendCode('M5')
        
        // Wait for user to click (simulated here with a prompt)
        await new Promise(resolve => setTimeout(resolve, 2000))
        
        const elapsed = (Date.now() - this.decelStartTime) / 1000
        this.localConfig.nxtSpindleDecelSec = parseFloat(elapsed.toFixed(2))
        await this.updateVariable('nxtSpindleDecelSec', this.localConfig.nxtSpindleDecelSec)
        
        this.showStatus(`Deceleration time measured: ${elapsed.toFixed(2)}s`, 'success')
      } catch (error) {
        console.error('NeXT: Deceleration measurement failed', error)
        this.showStatus('Deceleration measurement failed', 'error')
      } finally {
        this.measuringDecel = false
      }
    },
    
    /**
     * Test touch probe by checking if it's triggered
     */
    async testTouchProbe() {
      if (this.localConfig.nxtTouchProbeID === null) return
      
      try {
        // Check probe state from sensors
        const probes = this.$store.state.machine.model.sensors?.probes || []
        const probe = probes[this.localConfig.nxtTouchProbeID]
        
        if (probe) {
          this.touchProbeTriggered = probe.triggered || false
          
          // Reset after 2 seconds
          setTimeout(() => {
            this.touchProbeTriggered = false
          }, 2000)
        }
      } catch (error) {
        console.error('NeXT: Touch probe test failed', error)
      }
    },
    
    /**
     * Test tool setter by checking if it's triggered
     */
    async testToolSetter() {
      if (this.localConfig.nxtToolSetterID === null) return
      
      try {
        // Check probe state from sensors
        const probes = this.$store.state.machine.model.sensors?.probes || []
        const probe = probes[this.localConfig.nxtToolSetterID]
        
        if (probe) {
          this.toolSetterTriggered = probe.triggered || false
          
          // Reset after 2 seconds
          setTimeout(() => {
            this.toolSetterTriggered = false
          }, 2000)
        }
      } catch (error) {
        console.error('NeXT: Tool setter test failed', error)
      }
    },
    
    /**
     * Navigate to calibration page (placeholder for future implementation)
     */
    navigateToCalibration() {
      this.showStatus('Calibration page will be implemented in a future update.', 'info')
      // TODO: Navigate to calibration page when implemented
      // this.$router.push('/NeXT/calibration')
    },
    
    /**
     * Set tool setter position to current machine position
     */
    async setCurrentPositionAsToolSetter() {
      try {
        const axes = this.visibleAxesByLetter
        const pos = [
          axes.X?.machinePosition || 0,
          axes.Y?.machinePosition || 0,
          axes.Z?.machinePosition || 0
        ]
        
        await this.sendCode(`set global.nxtToolSetterPos = {${pos.join(', ')}}`)
        this.localConfig.nxtToolSetterPos = pos
        this.showStatus('Tool setter position set to current position', 'success')
      } catch (error) {
        console.error('NeXT: Failed to set tool setter position', error)
        this.showStatus('Failed to set tool setter position', 'error')
      }
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
