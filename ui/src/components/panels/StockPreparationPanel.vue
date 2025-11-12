<template>
  <v-card class="nxt-stock-preparation-panel">
    <v-card-title>
      <v-icon left>mdi-cube-outline</v-icon>
      Stock Preparation
      <v-spacer />
      <v-btn
        icon
        small
        @click="$emit('close')"
      >
        <v-icon>mdi-close</v-icon>
      </v-btn>
    </v-card-title>

    <v-card-text>
      <!-- Two-column layout: Settings on left, Preview on right -->
      <v-row>
        <!-- Left Column: Setup/Settings -->
        <v-col cols="12" md="6">
          <v-form ref="setupForm" v-model="formValid">
            <!-- Tool Configuration -->
            <v-card flat class="mb-4">
              <v-card-subtitle class="font-weight-bold">
                <v-icon left small>mdi-tools</v-icon>
                Tool Configuration
              </v-card-subtitle>
              <v-card-text>
                  <v-row>
                    <v-col cols="12">
                      <v-alert
                        v-if="!currentTool"
                        type="warning"
                        dense
                        outlined
                        class="mb-2"
                      >
                        <v-icon left small>mdi-alert</v-icon>
                        No tool selected - using manual radius
                      </v-alert>
                      <div v-else class="text-body-2 mb-2">
                        Current Tool: T{{ currentTool.number }}
                      </div>
                    </v-col>
                    <v-col cols="12" md="6">
                      <v-text-field
                        v-model.number="toolRadius"
                        label="Tool Radius *"
                        type="number"
                        step="0.1"
                        suffix="mm"
                        :rules="[v => v > 0 || 'Must be positive', v => v < 50 || 'Must be less than 50mm']"
                        :hint="toolRadiusHint"
                        persistent-hint
                        :disabled="uiFrozen"
                      />
                    </v-col>
                  </v-row>
                </v-card-text>
              </v-card>

              <!-- Stock Geometry -->
              <v-card flat class="mb-4">
                <v-card-subtitle class="font-weight-bold">
                  <v-icon left small>mdi-cube</v-icon>
                  Stock Geometry
                </v-card-subtitle>
                <v-card-text>
                  <v-row>
                    <v-col cols="12">
                      <v-radio-group v-model="stockShape" row dense>
                        <v-radio label="Rectangular" value="rectangular" />
                        <v-radio label="Circular" value="circular" />
                      </v-radio-group>
                    </v-col>
                  </v-row>

                  <!-- Rectangular Stock -->
                  <v-row v-if="stockShape === 'rectangular'">
                    <v-col cols="12" md="6">
                      <v-text-field
                        v-model.number="stockX"
                        label="X Dimension *"
                        type="number"
                        step="1"
                        suffix="mm"
                        :rules="[v => v > 0 || 'Must be positive', v => v <= 1000 || 'Must be <= 1000mm']"
                        :disabled="uiFrozen"
                      />
                    </v-col>
                    <v-col cols="12" md="6">
                      <v-text-field
                        v-model.number="stockY"
                        label="Y Dimension *"
                        type="number"
                        step="1"
                        suffix="mm"
                        :rules="[v => v > 0 || 'Must be positive', v => v <= 1000 || 'Must be <= 1000mm']"
                        :disabled="uiFrozen"
                      />
                    </v-col>
                    <v-col cols="12">
                      <v-select
                        v-model="originPosition"
                        :items="originPositions"
                        label="Origin Position"
                        :disabled="uiFrozen"
                      />
                    </v-col>
                  </v-row>

                  <!-- Circular Stock -->
                  <v-row v-if="stockShape === 'circular'">
                    <v-col cols="12" md="6">
                      <v-text-field
                        v-model.number="stockDiameter"
                        label="Diameter *"
                        type="number"
                        step="1"
                        suffix="mm"
                        :rules="[v => v > 0 || 'Must be positive', v => v <= 500 || 'Must be <= 500mm']"
                        :disabled="uiFrozen"
                      />
                    </v-col>
                    <v-col cols="12" md="6">
                      <v-alert dense outlined type="info" class="ma-0">
                        <div class="text-caption">
                          Origin: Center (fixed for circular stock)
                        </div>
                      </v-alert>
                    </v-col>
                  </v-row>
                </v-card-text>
              </v-card>

              <!-- Facing Pattern -->
              <v-card flat class="mb-4">
                <v-card-subtitle class="font-weight-bold">
                  <v-icon left small>mdi-axis-arrow</v-icon>
                  Facing Pattern
                </v-card-subtitle>
                <v-card-text>
                  <v-row>
                    <v-col cols="12" md="6">
                      <v-select
                        v-model="facingPattern"
                        :items="facingPatterns"
                        label="Pattern Type"
                        :disabled="uiFrozen"
                      />
                    </v-col>
                    <v-col v-if="facingPattern !== 'spiral'" cols="12" md="6">
                      <v-text-field
                        v-model.number="patternAngle"
                        label="Pattern Angle"
                        type="number"
                        step="45"
                        suffix="°"
                        :rules="[v => v >= 0 && v <= 360 || 'Must be 0-360°']"
                        :disabled="uiFrozen"
                      />
                    </v-col>
                    <v-col cols="12">
                      <v-radio-group v-model="millingDirection" row dense>
                        <v-radio label="Climb Milling (Recommended)" value="climb" />
                        <v-radio label="Conventional Milling" value="conventional" />
                      </v-radio-group>
                    </v-col>
                  </v-row>
                </v-card-text>
              </v-card>

              <!-- Cutting Parameters -->
              <v-card flat class="mb-4">
                <v-card-subtitle class="font-weight-bold">
                  <v-icon left small>mdi-sine-wave</v-icon>
                  Cutting Parameters
                </v-card-subtitle>
                <v-card-text>
                  <v-row>
                    <v-col cols="12" md="6">
                      <v-text-field
                        v-model.number="stepover"
                        label="Stepover"
                        type="number"
                        step="5"
                        suffix="%"
                        :rules="[v => v > 0 && v <= 100 || 'Must be 1-100%']"
                        hint="Percentage of tool diameter"
                        persistent-hint
                        :disabled="uiFrozen"
                      />
                    </v-col>
                    <v-col cols="12" md="6">
                      <v-text-field
                        v-model.number="stepdown"
                        label="Stepdown"
                        type="number"
                        step="0.1"
                        suffix="mm"
                        :rules="[v => v > 0 && v <= 10 || 'Must be 0.01-10mm']"
                        :disabled="uiFrozen"
                      />
                    </v-col>
                    <v-col cols="12" md="6">
                      <v-text-field
                        v-model.number="totalDepth"
                        label="Total Depth"
                        type="number"
                        step="0.1"
                        suffix="mm"
                        :rules="[v => v > 0 && v <= 100 || 'Must be 0.01-100mm']"
                        :disabled="uiFrozen"
                      />
                    </v-col>
                    <v-col cols="12" md="6">
                      <v-text-field
                        v-model.number="zOffset"
                        label="Z Offset"
                        type="number"
                        step="0.1"
                        suffix="mm"
                        hint="Starting Z height from WCS origin"
                        persistent-hint
                        :disabled="uiFrozen"
                      />
                    </v-col>
                    <v-col cols="12" md="6">
                      <v-text-field
                        v-model.number="safeZHeight"
                        label="Safe Z Height"
                        type="number"
                        step="1"
                        suffix="mm"
                        :rules="[v => v > 0 && v <= 100 || 'Must be 0-100mm']"
                        hint="Clearance for rapid moves (relative to cutting depth)"
                        persistent-hint
                        :disabled="uiFrozen"
                      />
                    </v-col>
                    <v-col cols="12" md="6">
                      <v-checkbox
                        v-model="clearStockExit"
                        label="Clear Stock Exit"
                        hint="Tool exits stock completely during direction changes"
                        persistent-hint
                        :disabled="uiFrozen"
                      />
                    </v-col>
                    <v-col cols="12">
                      <v-checkbox
                        v-model="finishingPass"
                        label="Finishing Pass"
                        :disabled="uiFrozen"
                      />
                    </v-col>
                    <v-col v-if="finishingPass" cols="12" md="6">
                      <v-text-field
                        v-model.number="finishingPassHeight"
                        label="Finishing Pass Height"
                        type="number"
                        step="0.1"
                        suffix="mm"
                        :rules="finishingPassRules"
                        :disabled="uiFrozen"
                      />
                    </v-col>
                    <v-col v-if="finishingPass" cols="12" md="6">
                      <v-text-field
                        v-model.number="finishingPassOffset"
                        label="Finishing Pass Offset"
                        type="number"
                        step="0.1"
                        suffix="mm"
                        hint="XY offset (negative = inward, positive = outward)"
                        persistent-hint
                        :disabled="uiFrozen"
                      />
                    </v-col>
                  </v-row>
                </v-card-text>
              </v-card>

              <!-- Feed and Speed -->
              <v-card flat class="mb-4">
                <v-card-subtitle class="font-weight-bold">
                  <v-icon left small>mdi-speedometer</v-icon>
                  Feed and Speed
                </v-card-subtitle>
                <v-card-text>
                  <v-row>
                    <v-col cols="12" md="4">
                      <v-text-field
                        v-model.number="feedRateXY"
                        label="Horizontal Feed"
                        type="number"
                        step="100"
                        suffix="mm/min"
                        :rules="[v => v > 0 || 'Must be positive']"
                        :disabled="uiFrozen"
                      />
                    </v-col>
                    <v-col cols="12" md="4">
                      <v-text-field
                        v-model.number="feedRateZ"
                        label="Vertical Feed"
                        type="number"
                        step="50"
                        suffix="mm/min"
                        :rules="[v => v > 0 || 'Must be positive']"
                        :disabled="uiFrozen"
                      />
                    </v-col>
                    <v-col cols="12" md="4">
                      <v-text-field
                        v-model.number="spindleSpeed"
                        label="Spindle Speed"
                        type="number"
                        step="1000"
                        suffix="RPM"
                        :rules="[v => v > 0 || 'Must be positive']"
                        :disabled="uiFrozen"
                      />
                    </v-col>
                  </v-row>
                </v-card-text>
              </v-card>
            </v-form>
          </v-col>

          <!-- Right Column: Preview & Run -->
          <v-col cols="12" md="6">
            <v-card flat>
              <v-card-subtitle class="font-weight-bold d-flex align-center">
                <v-icon left small>mdi-eye</v-icon>
                Toolpath Preview
                <v-spacer />
                <v-btn
                  small
                  outlined
                  color="primary"
                  :disabled="!generatedGcode"
                  @click="openInGCodeViewer"
                >
                  <v-icon small left>mdi-file-eye</v-icon>
                  View in DWC G-code Viewer
                </v-btn>
              </v-card-subtitle>
              <v-card-text>
                <!-- Placeholder for future Three.js-based G-code viewer -->
                <div class="toolpath-preview-placeholder">
                  <v-icon size="64" color="grey lighten-1">mdi-cube-outline</v-icon>
                  <p class="text-center grey--text text--lighten-1 mt-4">
                    3D G-code viewer coming soon
                  </p>
                  <p class="text-center grey--text text--darken-1 caption">
                    Use "View in DWC G-code Viewer" to preview toolpath
                  </p>
                </div>

                <!-- Statistics -->
                <v-card outlined class="mt-4">
                  <v-card-text>
                    <v-row dense>
                      <v-col cols="6" sm="3">
                        <div class="text-caption">Roughing Passes</div>
                        <div class="text-h6">{{ statistics.roughingPasses }}</div>
                      </v-col>
                      <v-col cols="6" sm="3">
                        <div class="text-caption">Finishing Pass</div>
                        <div class="text-h6">{{ statistics.finishingPass ? 'Yes' : 'No' }}</div>
                      </v-col>
                      <v-col cols="6" sm="3">
                        <div class="text-caption">Total Distance</div>
                        <div class="text-h6">{{ statistics.totalDistance }} mm</div>
                      </v-col>
                      <v-col cols="6" sm="3">
                        <div class="text-caption">Est. Time</div>
                        <div class="text-h6">{{ formatTime(statistics.estimatedTime) }}</div>
                      </v-col>
                    </v-row>
                  </v-card-text>
                </v-card>

                <!-- G-code Preview -->
                <v-expansion-panels class="mt-4">
                  <v-expansion-panel>
                    <v-expansion-panel-header>
                      <div>
                        <v-icon left>mdi-code-tags</v-icon>
                        Show G-code ({{ gcodeLineCount }} lines)
                      </div>
                    </v-expansion-panel-header>
                    <v-expansion-panel-content>
                      <v-textarea
                        :value="generatedGcode"
                        readonly
                        outlined
                        auto-grow
                        rows="15"
                        class="code-preview"
                      />
                    </v-expansion-panel-content>
                  </v-expansion-panel>
                </v-expansion-panels>

                <!-- File Management -->
                <v-card outlined class="mt-4">
                  <v-card-subtitle class="font-weight-bold">
                    <v-icon left small>mdi-content-save</v-icon>
                    File Management
                  </v-card-subtitle>
                  <v-card-text>
                    <v-row>
                      <v-col cols="12" md="8">
                        <v-text-field
                          v-model="filename"
                          label="Filename"
                          suffix=".gcode"
                          :rules="[v => !!v || 'Filename required', v => /^[a-zA-Z0-9_-]+$/.test(v) || 'Invalid filename']"
                          hint="Alphanumeric, dash, and underscore only"
                          persistent-hint
                        />
                      </v-col>
                      <v-col cols="12" md="4">
                        <v-select
                          v-model="saveLocation"
                          :items="saveLocations"
                          label="Save Location"
                        />
                      </v-col>
                    </v-row>
                    <v-row>
                      <v-col cols="12" class="d-flex justify-space-between">
                        <v-btn
                          color="secondary"
                          :disabled="!filename || uiFrozen"
                          @click="saveAsFile"
                        >
                          <v-icon left>mdi-content-save</v-icon>
                          Save as File
                        </v-btn>
                        <v-btn
                          color="primary"
                          :disabled="!filename || uiFrozen"
                          @click="runImmediately"
                        >
                          <v-icon left>mdi-play</v-icon>
                          Run Immediately
                        </v-btn>
                      </v-col>
                    </v-row>
                  </v-card-text>
                </v-card>
              </v-card-text>
            </v-card>
          </v-col>
        </v-row>
      </v-card-text>
    </v-card>
  </template>

<script lang="ts">
import BaseComponent from '../base/BaseComponent.vue'
import {
  generateToolpath,
  calculateToolpathStatistics,
  ToolpathGenerationParams,
  ToolpathPoint
} from '../../utils/toolpath'
import { generateGCode, validateGCodeParameters } from '../../utils/gcode'

export default BaseComponent.extend({
  name: 'NxtStockPreparationPanel',
  
  data() {
    return {
      formValid: false,
      
      // Tool Configuration
      toolRadius: 3.0,
      
      // Stock Geometry
      stockShape: 'rectangular' as 'rectangular' | 'circular',
      stockX: 100,
      stockY: 75,
      stockDiameter: 100,
      originPosition: 'front-left',
      originPositions: [
        { text: 'Front Left', value: 'front-left' },
        { text: 'Front Center', value: 'front-center' },
        { text: 'Front Right', value: 'front-right' },
        { text: 'Center Left', value: 'center-left' },
        { text: 'Center Center', value: 'center-center' },
        { text: 'Center Right', value: 'center-right' },
        { text: 'Back Left', value: 'back-left' },
        { text: 'Back Center', value: 'back-center' },
        { text: 'Back Right', value: 'back-right' }
      ],
      
      // Facing Pattern
      facingPattern: 'zigzag',
      facingPatterns: [
        { text: 'Rectilinear', value: 'rectilinear' },
        { text: 'Zigzag (Recommended)', value: 'zigzag' },
        { text: 'Spiral', value: 'spiral' }
      ],
      patternAngle: 0,
      millingDirection: 'climb' as 'climb' | 'conventional',
      
      // Cutting Parameters
      stepover: 30,
      stepdown: 1.0,
      totalDepth: 2.0,
      zOffset: 0.0,
      safeZHeight: 5.0,
      clearStockExit: false,
      finishingPass: false,
      finishingPassHeight: 0.2,
      finishingPassOffset: 1.5,  // Default to half of default tool radius (3.0mm)
      
      // Feed and Speed
      feedRateXY: 1000,
      feedRateZ: 300,
      spindleSpeed: 10000,
      
      // Preview and Generation
      generatedToolpath: [] as ToolpathPoint[][],
      generatedGcode: '',
      statistics: {
        totalDistance: 0,
        estimatedTime: 0,
        materialRemoved: 0,
        roughingPasses: 0,
        finishingPass: false
      },
      
      // File Management
      filename: 'stock-prep-001',
      saveLocation: '/gcodes/',
      saveLocations: [
        { text: '/gcodes/', value: '/gcodes/' },
        { text: '/macros/', value: '/macros/' }
      ]
    }
  },
  
  computed: {
    toolRadiusHint(): string {
      if (this.currentTool) {
        const toolNum = this.currentTool.number
        const radius = this.globals.nxtToolRadius?.[toolNum]
        if (radius !== undefined && radius !== null) {
          return `Tool T${toolNum} radius from NeXT: ${radius}mm`
        }
      }
      return 'Enter tool radius manually'
    },
    
    isSetupValid(): boolean {
      return this.formValid && this.validateParameters().length === 0
    },
    
    finishingPassRules(): Array<(v: number) => boolean | string> {
      return [
        (v: number) => v > 0 || 'Must be positive',
        (v: number) => v < this.totalDepth || 'Must be less than total depth',
        (v: number) => v < this.stepdown || 'Should be less than stepdown'
      ]
    },
    
    gcodeLineCount(): number {
      return this.generatedGcode.split('\n').length
    }
  },
  
  watch: {
    toolRadius(newRadius: number) {
      // Update finishing pass offset to half of tool radius when tool radius changes
      // Only update if user hasn't manually changed it from the default
      if (this.finishingPassOffset === 0.0 || this.finishingPassOffset === 1.5) {
        this.finishingPassOffset = newRadius / 2
      }
      this.generatePreview()
    },
    
    // Watch all settings that affect toolpath generation
    stockShape() {
      this.generatePreview()
    },
    stockX() {
      this.generatePreview()
    },
    stockY() {
      this.generatePreview()
    },
    stockDiameter() {
      this.generatePreview()
    },
    originPosition() {
      this.generatePreview()
    },
    facingPattern() {
      this.generatePreview()
    },
    patternAngle() {
      this.generatePreview()
    },
    millingDirection() {
      this.generatePreview()
    },
    stepover() {
      this.generatePreview()
    },
    stepdown() {
      this.generatePreview()
    },
    totalDepth() {
      this.generatePreview()
    },
    zOffset() {
      this.generatePreview()
    },
    safeZHeight() {
      this.generatePreview()
    },
    clearStockExit() {
      this.generatePreview()
    },
    finishingPass() {
      this.generatePreview()
    },
    finishingPassHeight() {
      this.generatePreview()
    },
    finishingPassOffset() {
      this.generatePreview()
    },
    feedRateXY() {
      this.generatePreview()
    },
    feedRateZ() {
      this.generatePreview()
    },
    spindleSpeed() {
      this.generatePreview()
    }
  },
  
  mounted() {
    this.initializeFromMachineState()
    // Set initial finishing pass offset to half of tool radius
    this.finishingPassOffset = this.toolRadius / 2
    // Generate initial toolpath
    this.generatePreview()
  },
  
  methods: {
    initializeFromMachineState() {
      // Initialize tool radius from current tool if available
      if (this.currentTool) {
        const toolNum = this.currentTool.number
        const radius = this.globals.nxtToolRadius?.[toolNum]
        if (radius !== undefined && radius !== null) {
          this.toolRadius = radius
        }
      }
      
      // Initialize feed rates from machine limits
      const axes = this.$store.state.machine.model.move?.axes
      if (axes) {
        const maxFeedXY = Math.min(
          axes[0]?.maxFeedrate || 10000,
          axes[1]?.maxFeedrate || 10000
        )
        const maxFeedZ = axes[2]?.maxFeedrate || 1000
        
        this.feedRateXY = Math.min(1000, maxFeedXY)
        this.feedRateZ = Math.min(300, maxFeedZ * 0.5)
      }
      
      // Initialize spindle speed
      const spindleId = this.globals.nxtSpindleID
      if (spindleId !== undefined && spindleId !== null) {
        const spindle = this.$store.state.machine.model.spindles?.[spindleId]
        if (spindle) {
          const minSpeed = spindle.min || 0
          const maxSpeed = spindle.max || 30000
          this.spindleSpeed = Math.min(10000, (minSpeed + maxSpeed) / 2)
        }
      }
    },
    
    validateParameters(): string[] {
      const params = this.buildGenerationParams()
      return validateGCodeParameters(params)
    },
    
    buildGenerationParams(): ToolpathGenerationParams {
      return {
        stock: {
          shape: this.stockShape,
          x: this.stockShape === 'rectangular' ? this.stockX : undefined,
          y: this.stockShape === 'rectangular' ? this.stockY : undefined,
          diameter: this.stockShape === 'circular' ? this.stockDiameter : undefined,
          originPosition: this.originPosition
        },
        cutting: {
          toolRadius: this.toolRadius,
          stepover: this.stepover,
          stepdown: this.stepdown,
          zOffset: this.zOffset,
          totalDepth: this.totalDepth,
          safeZHeight: this.safeZHeight,
          clearStockExit: this.clearStockExit,
          finishingPass: this.finishingPass,
          finishingPassHeight: this.finishingPassHeight,
          finishingPassOffset: this.finishingPassOffset
        },
        pattern: {
          type: this.facingPattern as any,
          angle: this.patternAngle,
          millingDirection: this.millingDirection
        },
        feeds: {
          xy: this.feedRateXY,
          z: this.feedRateZ,
          spindleSpeed: this.spindleSpeed
        }
      }
    },
    
    generatePreview() {
      try {
        const params = this.buildGenerationParams()
        
        // Validate parameters
        const errors = validateGCodeParameters(params)
        if (errors.length > 0) {
          alert('Validation errors:\n' + errors.join('\n'))
          return
        }
        
        // Generate toolpath
        this.generatedToolpath = generateToolpath(params)
        
        // Calculate statistics
        this.statistics = calculateToolpathStatistics(this.generatedToolpath, params.cutting)
        
        // Generate G-code
        const currentToolNum = this.currentTool?.number || 0
        const workplace = this.currentWorkplace || 1
        this.generatedGcode = generateGCode(
          this.generatedToolpath,
          params,
          currentToolNum,
          workplace
        )
      } catch (error) {
        console.error('Error generating toolpath:', error)
        alert('Error generating toolpath: ' + error)
      }
    },
    
    async saveAsFile() {
      try {
        const fullPath = `${this.saveLocation}${this.filename}.gcode`
        
        // Use RRF file upload API
        const formData = new FormData()
        const blob = new Blob([this.generatedGcode], { type: 'text/plain' })
        formData.append('file', blob, `${this.filename}.gcode`)
        
        const response = await fetch(
          `/rr_upload?name=${encodeURIComponent(fullPath)}`,
          {
            method: 'POST',
            body: formData
          }
        )
        
        if (response.ok) {
          alert(`File saved successfully: ${fullPath}`)
        } else {
          throw new Error('File upload failed')
        }
      } catch (error) {
        console.error('Error saving file:', error)
        alert('Error saving file: ' + error)
      }
    },
    
    async runImmediately() {
      try {
        // First save the file
        await this.saveAsFile()
        
        // Then run it
        const fullPath = `${this.saveLocation}${this.filename}.gcode`
        await this.sendCode(`M98 P"${fullPath}"`)
        
        alert('G-code is running. Monitor progress in DWC.')
        this.$emit('close')
      } catch (error) {
        console.error('Error running G-code:', error)
        alert('Error running G-code: ' + error)
      }
    },
    
    async openInGCodeViewer() {
      try {
        // Save G-code to a temporary file
        const tempFilename = `next-stock-prep-preview-${Date.now()}`
        const tempPath = `0:/gcodes/${tempFilename}.gcode`
        
        // Upload the file
        const formData = new FormData()
        const blob = new Blob([this.generatedGcode], { type: 'text/plain' })
        formData.append('file', blob, `${tempFilename}.gcode`)
        
        const response = await fetch(
          `/rr_upload?name=${encodeURIComponent(tempPath)}`,
          {
            method: 'POST',
            body: formData
          }
        )
        
        if (!response.ok) {
          throw new Error('Failed to upload temporary file')
        }
        
        // Navigate to Job Status page to view the file
        // DWC will automatically load the file in the G-code viewer
        this.$router.push(`/Job/Status?file=${encodeURIComponent(tempPath)}`)
        
        // Optionally close this panel
        // this.$emit('close')
      } catch (error) {
        console.error('Error opening in G-code viewer:', error)
        alert('Error opening G-code viewer: ' + error)
      }
    },
    
    formatTime(seconds: number): string {
      const mins = Math.floor(seconds / 60)
      const secs = seconds % 60
      return `${mins}m ${secs}s`
    }
  }
})
</script>

<style scoped>
.nxt-stock-preparation-panel {
  max-width: 1200px;
  margin: 0 auto;
}

.toolpath-preview-placeholder {
  min-height: 450px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 40px;
}

.toolpath-preview-container {
  border: 1px solid #ddd;
  border-radius: 4px;
  overflow: hidden;
  background: #f5f5f5;
  display: flex;
  justify-content: center;
  align-items: center;
}

.toolpath-preview {
  display: block;
}

.code-preview {
  font-family: 'Courier New', monospace;
  font-size: 12px;
}

.v-stepper {
  box-shadow: none !important;
}
</style>
