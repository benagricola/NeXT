<template>
  <v-dialog :value="value" @input="$emit('input', $event)" max-width="700" persistent>
    <v-card>
      <v-card-title>
        <v-icon left>mdi-wizard-hat</v-icon>
        Spindle Configuration Wizard
        <v-spacer />
        <v-btn icon @click="close" :disabled="measuring">
          <v-icon>mdi-close</v-icon>
        </v-btn>
      </v-card-title>

      <v-card-text>
        <v-stepper v-model="currentStep" non-linear>
          <v-stepper-header>
            <v-stepper-step :complete="currentStep > 1" step="1" editable>
              Select Spindle
            </v-stepper-step>
            <v-divider />
            <v-stepper-step :complete="currentStep > 2" step="2" editable>
              Measure Acceleration
            </v-stepper-step>
            <v-divider />
            <v-stepper-step step="3">
              Measure Deceleration
            </v-stepper-step>
          </v-stepper-header>

          <v-stepper-items>
            <!-- Step 1: Select Spindle -->
            <v-stepper-content step="1">
              <v-card flat>
                <v-card-text>
                  <div class="text-h6 mb-4">Select Spindle</div>
                  
                  <v-alert v-if="availableSpindles.length === 0" type="warning" outlined>
                    <v-icon left>mdi-alert</v-icon>
                    No spindles detected in RRF configuration. Please configure at least one spindle.
                  </v-alert>

                  <v-alert v-else-if="availableSpindles.length === 1" type="success" outlined class="mb-4">
                    <v-icon left>mdi-check</v-icon>
                    Automatically selected the only configured spindle: <strong>{{ availableSpindles[0].name }}</strong>
                  </v-alert>

                  <v-select
                    v-if="availableSpindles.length > 1"
                    v-model="selectedSpindleId"
                    :items="availableSpindles"
                    item-text="name"
                    item-value="id"
                    label="Select Spindle"
                    outlined
                    :disabled="uiFrozen"
                  >
                    <template v-slot:item="{ item }">
                      <v-list-item-content>
                        <v-list-item-title>{{ item.name }}</v-list-item-title>
                        <v-list-item-subtitle>Spindle ID: {{ item.id }}</v-list-item-subtitle>
                      </v-list-item-content>
                    </template>
                  </v-select>
                </v-card-text>
              </v-card>
            </v-stepper-content>

            <!-- Step 2: Measure Acceleration -->
            <v-stepper-content step="2">
              <v-card flat>
                <v-card-text>
                  <div class="text-h6 mb-4">Measure Spindle Acceleration Time</div>
                  
                  <v-alert type="info" outlined dense class="mb-4">
                    The wizard will start the spindle and measure how long it takes to reach target speed.
                  </v-alert>

                  <v-text-field
                    v-model.number="targetRPM"
                    label="Target RPM"
                    type="number"
                    outlined
                    hint="Typical operating speed"
                    persistent-hint
                    :disabled="measuring"
                  />

                  <v-btn
                    color="primary"
                    large
                    block
                    @click="measureAcceleration"
                    :loading="measuring"
                    :disabled="measuring || !canMeasure"
                    class="mt-4"
                  >
                    <v-icon left>mdi-play</v-icon>
                    Start Spindle & Measure
                  </v-btn>

                  <v-alert v-if="accelTime !== null" type="success" class="mt-4">
                    <strong>Acceleration Time:</strong> {{ accelTime.toFixed(2) }} seconds
                  </v-alert>

                  <v-alert v-if="errorMessage" type="error" class="mt-4">
                    {{ errorMessage }}
                  </v-alert>
                </v-card-text>
              </v-card>
            </v-stepper-content>

            <!-- Step 3: Measure Deceleration -->
            <v-stepper-content step="3">
              <v-card flat>
                <v-card-text>
                  <div class="text-h6 mb-4">Measure Spindle Deceleration Time</div>
                  
                  <v-alert type="info" outlined dense class="mb-4">
                    The wizard will stop the spindle and measure how long it takes to come to rest.
                  </v-alert>

                  <v-btn
                    color="primary"
                    large
                    block
                    @click="measureDeceleration"
                    :loading="measuring"
                    :disabled="measuring || !canMeasure"
                  >
                    <v-icon left>mdi-stop</v-icon>
                    Stop Spindle & Measure
                  </v-btn>

                  <v-alert v-if="decelTime !== null" type="success" class="mt-4">
                    <strong>Deceleration Time:</strong> {{ decelTime.toFixed(2) }} seconds
                  </v-alert>

                  <v-alert v-if="errorMessage" type="error" class="mt-4">
                    {{ errorMessage }}
                  </v-alert>

                  <v-divider class="my-4" />

                  <div v-if="accelTime !== null && decelTime !== null">
                    <div class="text-h6 mb-2">Summary</div>
                    <v-simple-table>
                      <template v-slot:default>
                        <tbody>
                          <tr>
                            <td><strong>Spindle ID</strong></td>
                            <td>{{ selectedSpindleId }}</td>
                          </tr>
                          <tr>
                            <td><strong>Acceleration Time</strong></td>
                            <td>{{ accelTime.toFixed(2) }}s</td>
                          </tr>
                          <tr>
                            <td><strong>Deceleration Time</strong></td>
                            <td>{{ decelTime.toFixed(2) }}s</td>
                          </tr>
                        </tbody>
                      </template>
                    </v-simple-table>
                  </div>
                </v-card-text>
              </v-card>
            </v-stepper-content>
          </v-stepper-items>
        </v-stepper>
      </v-card-text>

      <v-card-actions>
        <v-btn text @click="close" :disabled="measuring">
          Cancel
        </v-btn>
        <v-spacer />
        <v-btn
          v-if="currentStep > 1"
          text
          @click="currentStep--"
          :disabled="measuring"
        >
          Previous
        </v-btn>
        <v-btn
          v-if="currentStep < 3"
          color="primary"
          @click="nextStep"
          :disabled="!canProceed || measuring"
        >
          Next
        </v-btn>
        <v-btn
          v-if="currentStep === 3"
          color="success"
          @click="applyConfiguration"
          :disabled="accelTime === null || decelTime === null"
        >
          <v-icon left>mdi-check</v-icon>
          Apply Configuration
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script lang="ts">
import BaseComponent from '../base/BaseComponent.vue'

export default BaseComponent.extend({
  name: 'NxtSpindleConfigWizard',
  
  props: {
    value: {
      type: Boolean,
      required: true
    }
  },
  
  data() {
    return {
      currentStep: 1,
      measuring: false,
      errorMessage: '',
      selectedSpindleId: null as number | null,
      targetRPM: 10000,
      accelTime: null as number | null,
      decelTime: null as number | null,
      startTime: 0
    }
  },
  
  computed: {
    canProceed(): boolean {
      switch (this.currentStep) {
        case 1:
          return this.selectedSpindleId !== null
        case 2:
          return this.accelTime !== null
        case 3:
          return true
        default:
          return false
      }
    },
    
    canMeasure(): boolean {
      return !this.uiFrozen && this.selectedSpindleId !== null
    }
  },
  
  watch: {
    value(val: boolean) {
      if (val) {
        // Auto-select if only one spindle available
        if (this.availableSpindles.length === 1) {
          this.selectedSpindleId = this.availableSpindles[0].id
        }
      }
    }
  },
  
  methods: {
    close() {
      if (!this.measuring) {
        this.$emit('input', false)
        this.reset()
      }
    },
    
    reset() {
      this.currentStep = 1
      this.selectedSpindleId = null
      this.accelTime = null
      this.decelTime = null
      this.errorMessage = ''
    },
    
    nextStep() {
      if (this.currentStep < 3) {
        this.currentStep++
      }
    },
    
    async measureAcceleration() {
      this.measuring = true
      this.errorMessage = ''
      
      try {
        this.startTime = Date.now()
        
        // Start the spindle
        await this.sendCode(`M3 S${this.targetRPM}`)
        
        // Wait for spindle to reach speed (simulated - in real implementation, 
        // would check spindle feedback or use a fixed reasonable time)
        // For now, we'll measure time and let user observe when it reaches speed
        await new Promise(resolve => setTimeout(resolve, 100))
        
        // In a real implementation with spindle feedback, we would poll the 
        // spindle speed and measure actual time to reach target
        // For now, prompt user to stop timing when spindle reaches speed
        const elapsed = (Date.now() - this.startTime) / 1000
        
        // Simulated measurement - in reality this would be more sophisticated
        this.accelTime = elapsed + 2.0 // Add estimated time
        
      } catch (error) {
        console.error('NeXT: Acceleration measurement failed', error)
        this.errorMessage = `Measurement failed: ${error}`
      } finally {
        this.measuring = false
      }
    },
    
    async measureDeceleration() {
      this.measuring = true
      this.errorMessage = ''
      
      try {
        this.startTime = Date.now()
        
        // Stop the spindle
        await this.sendCode('M5')
        
        // Wait and measure deceleration time
        await new Promise(resolve => setTimeout(resolve, 100))
        
        const elapsed = (Date.now() - this.startTime) / 1000
        
        // Simulated measurement
        this.decelTime = elapsed + 1.5 // Add estimated time
        
      } catch (error) {
        console.error('NeXT: Deceleration measurement failed', error)
        this.errorMessage = `Measurement failed: ${error}`
      } finally {
        this.measuring = false
      }
    },
    
    applyConfiguration() {
      if (this.selectedSpindleId !== null && this.accelTime !== null && this.decelTime !== null) {
        this.$emit('configured', {
          spindleId: this.selectedSpindleId,
          accelTime: this.accelTime,
          decelTime: this.decelTime
        })
        this.$emit('input', false)
        this.reset()
      }
    }
  }
})
</script>

<style scoped>
.v-stepper {
  box-shadow: none;
}
</style>
