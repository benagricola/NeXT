<template>
  <v-dialog :value="value" @input="$emit('input', $event)" max-width="800" persistent>
    <v-card>
      <v-card-title>
        <v-icon left>mdi-wizard-hat</v-icon>
        Probe Deflection Measurement Wizard
        <v-spacer />
        <v-btn icon @click="close" :disabled="measuring">
          <v-icon>mdi-close</v-icon>
        </v-btn>
      </v-card-title>

      <v-card-text>
        <!-- Step Indicator -->
        <v-stepper v-model="currentStep" non-linear>
          <v-stepper-header>
            <v-stepper-step :complete="currentStep > 1" step="1" editable>
              Setup
            </v-stepper-step>
            <v-divider />
            <v-stepper-step :complete="currentStep > 2" step="2" editable>
              Block Dimensions
            </v-stepper-step>
            <v-divider />
            <v-stepper-step :complete="currentStep > 3" step="3" editable>
              Measure X
            </v-stepper-step>
            <v-divider />
            <v-stepper-step :complete="currentStep > 4" step="4" editable>
              Measure Y
            </v-stepper-step>
            <v-divider />
            <v-stepper-step step="5">
              Results
            </v-stepper-step>
          </v-stepper-header>

          <v-stepper-items>
            <!-- Step 1: Setup Instructions -->
            <v-stepper-content step="1">
              <v-card flat>
                <v-card-text>
                  <v-alert type="info" outlined>
                    <div class="text-h6 mb-2">Prerequisites</div>
                    <ul>
                      <li>Machine must be homed</li>
                      <li>Touch probe must be installed and configured</li>
                      <li>Secure a precision reference block (e.g., 1-2-3 block) to the work surface</li>
                      <li>Jog the machine to position probe over the center of the block</li>
                    </ul>
                  </v-alert>

                  <v-alert v-if="!allAxesHomed" type="warning" class="mt-4">
                    <v-icon left>mdi-alert</v-icon>
                    Machine is not homed. Please home all axes before proceeding.
                  </v-alert>

                  <v-alert v-if="!probeTool" type="warning" class="mt-4">
                    <v-icon left>mdi-alert</v-icon>
                    Touch probe tool not configured. Check configuration settings.
                  </v-alert>
                </v-card-text>
              </v-card>
            </v-stepper-content>

            <!-- Step 2: Block Dimensions -->
            <v-stepper-content step="2">
              <v-card flat>
                <v-card-text>
                  <div class="text-h6 mb-4">Enter Reference Block Dimensions</div>
                  <v-alert type="info" outlined dense class="mb-4">
                    These are the known, precision dimensions of your reference block
                  </v-alert>
                  
                  <v-row>
                    <v-col cols="12" md="6">
                      <v-text-field
                        v-model.number="blockDimensions.x"
                        label="X Dimension (mm)"
                        type="number"
                        step="0.001"
                        :rules="[rules.required, rules.positive]"
                        hint="Width in X direction"
                        persistent-hint
                      />
                    </v-col>
                    <v-col cols="12" md="6">
                      <v-text-field
                        v-model.number="blockDimensions.y"
                        label="Y Dimension (mm)"
                        type="number"
                        step="0.001"
                        :rules="[rules.required, rules.positive]"
                        hint="Width in Y direction"
                        persistent-hint
                      />
                    </v-col>
                  </v-row>
                </v-card-text>
              </v-card>
            </v-stepper-content>

            <!-- Step 3: Measure X -->
            <v-stepper-content step="3">
              <v-card flat>
                <v-card-text>
                  <div class="text-h6 mb-4">Measure X Dimension</div>
                  <v-alert type="info" outlined dense class="mb-4">
                    The wizard will probe both sides of the block in the X direction
                  </v-alert>

                  <v-btn
                    color="primary"
                    large
                    @click="measureXAxis"
                    :loading="measuring"
                    :disabled="measuring || !canMeasure"
                  >
                    <v-icon left>mdi-axis-x-arrow</v-icon>
                    Probe X Surfaces
                  </v-btn>

                  <v-alert v-if="measurements.x !== null" type="success" class="mt-4">
                    <strong>X Measurement Complete:</strong> {{ measurements.x.toFixed(4) }} mm
                  </v-alert>

                  <v-alert v-if="measurementError" type="error" class="mt-4">
                    {{ measurementError }}
                  </v-alert>
                </v-card-text>
              </v-card>
            </v-stepper-content>

            <!-- Step 4: Measure Y -->
            <v-stepper-content step="4">
              <v-card flat>
                <v-card-text>
                  <div class="text-h6 mb-4">Measure Y Dimension</div>
                  <v-alert type="info" outlined dense class="mb-4">
                    The wizard will probe both sides of the block in the Y direction
                  </v-alert>

                  <v-btn
                    color="primary"
                    large
                    @click="measureYAxis"
                    :loading="measuring"
                    :disabled="measuring || !canMeasure"
                  >
                    <v-icon left>mdi-axis-y-arrow</v-icon>
                    Probe Y Surfaces
                  </v-btn>

                  <v-alert v-if="measurements.y !== null" type="success" class="mt-4">
                    <strong>Y Measurement Complete:</strong> {{ measurements.y.toFixed(4) }} mm
                  </v-alert>

                  <v-alert v-if="measurementError" type="error" class="mt-4">
                    {{ measurementError }}
                  </v-alert>
                </v-card-text>
              </v-card>
            </v-stepper-content>

            <!-- Step 5: Results -->
            <v-stepper-content step="5">
              <v-card flat>
                <v-card-text>
                  <div class="text-h6 mb-4">Measurement Results</div>
                  
                  <v-simple-table>
                    <template v-slot:default>
                      <thead>
                        <tr>
                          <th>Axis</th>
                          <th>Known Dimension</th>
                          <th>Measured Dimension</th>
                          <th>Deflection</th>
                        </tr>
                      </thead>
                      <tbody>
                        <tr>
                          <td><strong>X</strong></td>
                          <td>{{ blockDimensions.x.toFixed(4) }} mm</td>
                          <td>{{ measurements.x !== null ? measurements.x.toFixed(4) : 'N/A' }} mm</td>
                          <td>
                            <span v-if="calculatedDeflection.x !== null" :class="deflectionColor">
                              {{ calculatedDeflection.x.toFixed(4) }} mm
                            </span>
                            <span v-else>N/A</span>
                          </td>
                        </tr>
                        <tr>
                          <td><strong>Y</strong></td>
                          <td>{{ blockDimensions.y.toFixed(4) }} mm</td>
                          <td>{{ measurements.y !== null ? measurements.y.toFixed(4) : 'N/A' }} mm</td>
                          <td>
                            <span v-if="calculatedDeflection.y !== null" :class="deflectionColor">
                              {{ calculatedDeflection.y.toFixed(4) }} mm
                            </span>
                            <span v-else>N/A</span>
                          </td>
                        </tr>
                      </tbody>
                    </template>
                  </v-simple-table>

                  <v-alert v-if="averageDeflection !== null" type="success" class="mt-4">
                    <div class="text-h6">Average Deflection: {{ averageDeflection.toFixed(4) }} mm</div>
                    <div class="text-caption mt-2">
                      This value will be applied to nxtProbeDeflection
                    </div>
                  </v-alert>

                  <v-alert v-if="deflectionWarning" type="warning" class="mt-4">
                    {{ deflectionWarning }}
                  </v-alert>
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
          v-if="currentStep < 5"
          color="primary"
          @click="nextStep"
          :disabled="!canProceed || measuring"
        >
          Next
        </v-btn>
        <v-btn
          v-if="currentStep === 5"
          color="success"
          @click="applyDeflection"
          :disabled="averageDeflection === null"
        >
          <v-icon left>mdi-check</v-icon>
          Apply Deflection
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script lang="ts">
import BaseComponent from '../base/BaseComponent.vue'

export default BaseComponent.extend({
  name: 'NxtProbeDeflectionWizard',
  
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
      measurementError: '',
      
      blockDimensions: {
        x: 25.4,
        y: 50.8
      },
      
      measurements: {
        x: null as number | null,
        y: null as number | null
      },
      
      rules: {
        required: (v: any) => v !== null && v !== undefined && v !== '' || 'Required',
        positive: (v: number) => v > 0 || 'Must be positive'
      }
    }
  },
  
  computed: {
    canProceed(): boolean {
      switch (this.currentStep) {
        case 1:
          return this.allAxesHomed && this.probeTool !== null
        case 2:
          return this.blockDimensions.x > 0 && this.blockDimensions.y > 0
        case 3:
          return this.measurements.x !== null
        case 4:
          return this.measurements.y !== null
        default:
          return true
      }
    },
    
    canMeasure(): boolean {
      return this.allAxesHomed && !this.uiFrozen
    },
    
    calculatedDeflection(): { x: number | null, y: number | null } {
      return {
        x: this.measurements.x !== null ? this.measurements.x - this.blockDimensions.x : null,
        y: this.measurements.y !== null ? this.measurements.y - this.blockDimensions.y : null
      }
    },
    
    averageDeflection(): number | null {
      const { x, y } = this.calculatedDeflection
      if (x === null || y === null) return null
      return (x + y) / 2
    },
    
    deflectionColor(): string {
      const avg = this.averageDeflection
      if (avg === null) return ''
      if (Math.abs(avg) > 0.1) return 'error--text'
      if (Math.abs(avg) > 0.05) return 'warning--text'
      return 'success--text'
    },
    
    deflectionWarning(): string | null {
      const avg = this.averageDeflection
      if (avg === null) return null
      
      if (Math.abs(avg) > 0.1) {
        return 'Warning: Deflection exceeds 0.1mm. Check probe spring tension or configuration.'
      }
      
      const diff = Math.abs((this.calculatedDeflection.x || 0) - (this.calculatedDeflection.y || 0))
      if (diff > 0.02) {
        return 'Warning: X and Y deflection differ significantly. This may indicate a problem with the reference block or measurement.'
      }
      
      return null
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
      this.measurements.x = null
      this.measurements.y = null
      this.measurementError = ''
    },
    
    nextStep() {
      if (this.currentStep < 5) {
        this.currentStep++
      }
    },
    
    async measureXAxis() {
      this.measuring = true
      this.measurementError = ''
      
      try {
        const response = await this.sendCode('G6504 X1')
        
        await this.$nextTick()
        
        const probeResult = this.nxtGlobals.nxtLastProbeResult
        if (probeResult && probeResult.dimension) {
          this.measurements.x = probeResult.dimension
        } else {
          throw new Error('Failed to get probe result')
        }
      } catch (error) {
        console.error('NeXT: X axis measurement failed', error)
        this.measurementError = `X measurement failed: ${error}`
      } finally {
        this.measuring = false
      }
    },
    
    async measureYAxis() {
      this.measuring = true
      this.measurementError = ''
      
      try {
        const response = await this.sendCode('G6504 Y1')
        
        await this.$nextTick()
        
        const probeResult = this.nxtGlobals.nxtLastProbeResult
        if (probeResult && probeResult.dimension) {
          this.measurements.y = probeResult.dimension
        } else {
          throw new Error('Failed to get probe result')
        }
      } catch (error) {
        console.error('NeXT: Y axis measurement failed', error)
        this.measurementError = `Y measurement failed: ${error}`
      } finally {
        this.measuring = false
      }
    },
    
    applyDeflection() {
      if (this.averageDeflection !== null) {
        this.$emit('measured', this.averageDeflection)
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
