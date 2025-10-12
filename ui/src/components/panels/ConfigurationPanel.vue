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
                  :input-value="nxtGlobals.nxtFeatureTouchProbe"
                  label="Touch Probe"
                  :disabled="uiFrozen"
                  @change="updateFeature('nxtFeatureTouchProbe', $event)"
                  hide-details
                  class="mt-0"
                />
              </v-col>
              <v-col cols="12" sm="4">
                <v-switch
                  :input-value="nxtGlobals.nxtFeatureToolSetter"
                  label="Tool Setter"
                  :disabled="uiFrozen"
                  @change="updateFeature('nxtFeatureToolSetter', $event)"
                  hide-details
                  class="mt-0"
                />
              </v-col>
              <v-col cols="12" sm="4">
                <v-switch
                  :input-value="nxtGlobals.nxtFeatureCoolantControl"
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
                  :value="nxtGlobals.nxtSpindleID"
                  :items="availableSpindles"
                  item-text="name"
                  item-value="id"
                  label="Spindle"
                  :disabled="uiFrozen"
                  @input="updateVariable('nxtSpindleID', $event)"
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
                          :disabled="uiFrozen || nxtGlobals.nxtSpindleID === null"
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
                  :value="nxtGlobals.nxtSpindleAccelSec"
                  label="Acceleration Time (s)"
                  type="number"
                  step="0.1"
                  :disabled="uiFrozen"
                  @input="updateVariable('nxtSpindleAccelSec', $event)"
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
                          :disabled="uiFrozen || nxtGlobals.nxtSpindleID === null || measuringAccel"
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
                  :value="nxtGlobals.nxtSpindleDecelSec"
                  label="Deceleration Time (s)"
                  type="number"
                  step="0.1"
                  :disabled="uiFrozen"
                  @input="updateVariable('nxtSpindleDecelSec', $event)"
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
                          :disabled="uiFrozen || nxtGlobals.nxtSpindleID === null || measuringDecel"
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
                  v-model="nxtGlobals.nxtTouchProbeID"
                  :items="availableProbes"
                  item-text="name"
                  item-value="id"
                  label="Touch Probe Sensor"
                  :disabled="uiFrozen"
                  @change="updateVariable('nxtTouchProbeID', nxtGlobals.nxtTouchProbeID)"
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
                      v-if="nxtGlobals.nxtTouchProbeID !== null"
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
                  v-model.number="nxtGlobals.nxtProbeTipRadius"
                  label="Probe Tip Radius (mm)"
                  type="number"
                  step="0.001"
                  :disabled="uiFrozen"
                  @blur="updateVariable('nxtProbeTipRadius', nxtGlobals.nxtProbeTipRadius)"
                  hint="For horizontal compensation"
                  persistent-hint
                />
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field
                  v-model.number="nxtGlobals.nxtProbeDeflection"
                  label="Probe Deflection (mm)"
                  type="number"
                  step="0.001"
                  :disabled="uiFrozen"
                  @blur="updateVariable('nxtProbeDeflection', nxtGlobals.nxtProbeDeflection)"
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
                          :disabled="uiFrozen || !nxtGlobals.nxtFeatureTouchProbe"
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
                  v-model="nxtGlobals.nxtToolSetterID"
                  :items="availableProbes"
                  item-text="name"
                  item-value="id"
                  label="Tool Setter Sensor"
                  :disabled="uiFrozen"
                  @change="updateVariable('nxtToolSetterID', nxtGlobals.nxtToolSetterID)"
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
                      v-if="nxtGlobals.nxtToolSetterID !== null"
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
                  v-model="nxtGlobals.nxtCoolantAirID"
                  :items="availableGpOutputs"
                  item-text="name"
                  item-value="id"
                  label="Air Blast Output"
                  :disabled="uiFrozen"
                  @change="updateVariable('nxtCoolantAirID', nxtGlobals.nxtCoolantAirID)"
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
                  v-model="nxtGlobals.nxtCoolantMistID"
                  :items="availableGpOutputs"
                  item-text="name"
                  item-value="id"
                  label="Mist Coolant Output"
                  :disabled="uiFrozen"
                  @change="updateVariable('nxtCoolantMistID', nxtGlobals.nxtCoolantMistID)"
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
                  v-model="nxtGlobals.nxtCoolantFloodID"
                  :items="availableGpOutputs"
                  item-text="name"
                  item-value="id"
                  label="Flood Coolant Output"
                  :disabled="uiFrozen"
                  @change="updateVariable('nxtCoolantFloodID', nxtGlobals.nxtCoolantFloodID)"
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
      accelDialog: false,
      decelDialog: false,
      
      // Probe test states
      touchProbeTriggered: false,
      toolSetterTriggered: false,
      
      // Spindle test state
      spindleTesting: false,
      
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
      if (!this.nxtGlobals.nxtToolSetterPos || !Array.isArray(this.nxtGlobals.nxtToolSetterPos)) {
        return 'Not configured'
      }
      return `[${this.nxtGlobals.nxtToolSetterPos.map((v: number) => v.toFixed(3)).join(', ')}]`
    },
    
    /**
     * Get minimum RPM for the selected spindle
     */
    selectedSpindleMinRpm(): number {
      if (this.nxtGlobals.nxtSpindleID === null) return 1000
      
      const spindles = this.$store.state.machine.model.spindles || []
      const spindle = spindles[this.nxtGlobals.nxtSpindleID]
      
      if (spindle && spindle.min !== undefined) {
        return spindle.min
      }
      
      // Default to 1000 RPM if not specified
      return 1000
    },
    
    /**
     * Get maximum RPM for the selected spindle
     */
    selectedSpindleMaxRpm(): number {
      if (this.nxtGlobals.nxtSpindleID === null) return 10000
      
      const spindles = this.$store.state.machine.model.spindles || []
      const spindle = spindles[this.nxtGlobals.nxtSpindleID]
      
      if (spindle && spindle.max !== undefined) {
        return spindle.max
      }
      
      // Default to 10000 RPM if not specified
      return 10000
    }
  },
  
  mounted() {
    console.log('NeXT: Configuration panel mounted')
  },
  
  methods: {
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
     * Save configuration to /sys/nxt-user-vars.g
     */
    async saveConfiguration() {
      this.saving = true
      try {
        const g = this.nxtGlobals
        const filePath = '/sys/nxt-user-vars.g'
        
        // Build configuration file content
        const lines = [
          '; NeXT User Configuration',
          '; Auto-generated - Do not edit manually',
          '; Last updated: ' + new Date().toISOString(),
          '',
          '; Feature Flags',
          `global nxtFeatureTouchProbe = ${g.nxtFeatureTouchProbe || false}`,
          `global nxtFeatureToolSetter = ${g.nxtFeatureToolSetter || false}`,
          `global nxtFeatureCoolantControl = ${g.nxtFeatureCoolantControl || false}`,
          '',
          '; Spindle Configuration',
          `global nxtSpindleID = ${g.nxtSpindleID !== null && g.nxtSpindleID !== undefined ? g.nxtSpindleID : 'null'}`,
          `global nxtSpindleAccelSec = ${g.nxtSpindleAccelSec !== null && g.nxtSpindleAccelSec !== undefined ? g.nxtSpindleAccelSec : 'null'}`,
          `global nxtSpindleDecelSec = ${g.nxtSpindleDecelSec !== null && g.nxtSpindleDecelSec !== undefined ? g.nxtSpindleDecelSec : 'null'}`,
          '',
          '; Touch Probe Configuration',
          `global nxtTouchProbeID = ${g.nxtTouchProbeID !== null && g.nxtTouchProbeID !== undefined ? g.nxtTouchProbeID : 'null'}`,
          `global nxtProbeTipRadius = ${g.nxtProbeTipRadius !== null && g.nxtProbeTipRadius !== undefined ? g.nxtProbeTipRadius : 'null'}`,
          `global nxtProbeDeflection = ${g.nxtProbeDeflection !== null && g.nxtProbeDeflection !== undefined ? g.nxtProbeDeflection : 'null'}`,
          '',
          '; Tool Setter Configuration',
          `global nxtToolSetterID = ${g.nxtToolSetterID !== null && g.nxtToolSetterID !== undefined ? g.nxtToolSetterID : 'null'}`,
          `global nxtToolSetterPos = ${g.nxtToolSetterPos && Array.isArray(g.nxtToolSetterPos) ? `{${g.nxtToolSetterPos.join(', ')}}` : 'null'}`,
          '',
          '; Coolant Configuration',
          `global nxtCoolantAirID = ${g.nxtCoolantAirID !== null && g.nxtCoolantAirID !== undefined ? g.nxtCoolantAirID : 'null'}`,
          `global nxtCoolantMistID = ${g.nxtCoolantMistID !== null && g.nxtCoolantMistID !== undefined ? g.nxtCoolantMistID : 'null'}`,
          `global nxtCoolantFloodID = ${g.nxtCoolantFloodID !== null && g.nxtCoolantFloodID !== undefined ? g.nxtCoolantFloodID : 'null'}`
        ]
        
        // Write each line to the file using echo with append
        // First, create/clear the file
        await this.sendCode(`M28 "${filePath}"`)
        
        // Write all lines
        for (const line of lines) {
          // Escape quotes in the line
          const escapedLine = line.replace(/"/g, '""')
          await this.sendCode(`echo >>"${filePath}" "${escapedLine}"`)
        }
        
        // Close the file
        await this.sendCode('M29')
        
        this.showStatus('Configuration saved to /sys/nxt-user-vars.g', 'success')
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
      if (this.nxtGlobals.nxtSpindleID === null || this.spindleTesting) return
      
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
      if (this.nxtGlobals.nxtSpindleID === null) return
      
      this.measuringAccel = true
      try {
        const maxRpm = this.selectedSpindleMaxRpm
        
        // Start spindle at maximum speed
        this.accelStartTime = Date.now()
        await this.sendCode(`M3 S${maxRpm}`)
        
        // Wait for user to confirm spindle at speed with M291 dialog
        await this.sendCode('M291 P"Click OK when spindle reaches full speed" R"Measuring Acceleration" S3 T15')
        
        const elapsed = (Date.now() - this.accelStartTime) / 1000
        const measuredTime = parseFloat(elapsed.toFixed(2))
        
        await this.updateVariable('nxtSpindleAccelSec', measuredTime)
        
        this.showStatus(`Acceleration time measured: ${measuredTime}s`, 'success')
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
      if (this.nxtGlobals.nxtSpindleID === null) return
      
      this.measuringDecel = true
      try {
        // Stop spindle
        this.decelStartTime = Date.now()
        await this.sendCode('M5')
        
        // Wait for user to confirm spindle stopped with M291 dialog
        await this.sendCode('M291 P"Click OK when spindle stops completely" R"Measuring Deceleration" S3 T15')
        
        const elapsed = (Date.now() - this.decelStartTime) / 1000
        const measuredTime = parseFloat(elapsed.toFixed(2))
        
        await this.updateVariable('nxtSpindleDecelSec', measuredTime)
        
        this.showStatus(`Deceleration time measured: ${measuredTime}s`, 'success')
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
      if (this.nxtGlobals.nxtTouchProbeID === null) return
      
      try {
        // Check probe state from sensors
        const probes = this.$store.state.machine.model.sensors?.probes || []
        const probe = probes[this.nxtGlobals.nxtTouchProbeID]
        
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
      if (this.nxtGlobals.nxtToolSetterID === null) return
      
      try {
        // Check probe state from sensors
        const probes = this.$store.state.machine.model.sensors?.probes || []
        const probe = probes[this.nxtGlobals.nxtToolSetterID]
        
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
        this.nxtGlobals.nxtToolSetterPos = pos
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
        this.nxtGlobals.nxtToolSetterPos = pos
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
      if (val && this.nxtGlobals.nxtToolSetterPos && Array.isArray(this.nxtGlobals.nxtToolSetterPos)) {
        // Initialize edit values from current position
        this.toolSetterPosEdit.x = this.nxtGlobals.nxtToolSetterPos[0] || 0
        this.toolSetterPosEdit.y = this.nxtGlobals.nxtToolSetterPos[1] || 0
        this.toolSetterPosEdit.z = this.nxtGlobals.nxtToolSetterPos[2] || 0
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
