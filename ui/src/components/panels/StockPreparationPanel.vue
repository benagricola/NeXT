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

    <!-- Progress Dialog -->
    <v-dialog
      v-model="showProgressDialog"
      persistent
      max-width="400"
    >
      <v-card>
        <v-card-title>
          <v-icon left>mdi-cog</v-icon>
          Generating Toolpath
        </v-card-title>
        <v-card-text>
          <div class="text-center mb-4">
            {{ generationMessage }}
          </div>
          <v-progress-linear
            :value="generationProgress"
            color="primary"
            height="25"
            striped
          >
            <template v-slot:default="{ value }">
              <strong>{{ Math.ceil(value) }}%</strong>
            </template>
          </v-progress-linear>
        </v-card-text>
      </v-card>
    </v-dialog>

    <v-card-text>
      <v-row>
        <!-- Left Column: 3D Viewer (70-80% width) -->
        <v-col cols="12" lg="8">
          <v-card flat>
            <v-card-subtitle class="font-weight-bold d-flex align-center">
              <v-icon left small>mdi-eye</v-icon>
              Toolpath Preview
            </v-card-subtitle>
            <v-card-text>
              <!-- Three.js-based G-code Viewer -->
                          <g-code-viewer-3-d
              ref="gcodeViewer"
              :gcode="generatedGcode"
              :auto-update="true"
              :highlighted-lines="highlightedGcodeLines"
              @line-selected="onLineSelectedFrom3D"
              @lines-selected="onLinesSelectedFromOverlay"
            />
            </v-card-text>
          </v-card>
        </v-col>
        
        <!-- Right Column: Tool Configuration (20-30% width) -->
        <v-col cols="12" lg="4">
          <v-form ref="setupForm" v-model="formValid">
            <v-expansion-panels accordion multiple>
              <!-- Tool Configuration -->
              <v-expansion-panel>
                <v-expansion-panel-header>
                  <div>
                    <v-icon left small>mdi-tools</v-icon>
                    Tool Configuration
                  </div>
                </v-expansion-panel-header>
                <v-expansion-panel-content>
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
                </v-expansion-panel-content>
              </v-expansion-panel>

              <!-- Stock Geometry -->
              <v-expansion-panel>
                <v-expansion-panel-header>
                  <div>
                    <v-icon left small>mdi-cube</v-icon>
                    Stock Geometry
                  </div>
                </v-expansion-panel-header>
                <v-expansion-panel-content>
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
                    <v-col cols="12" md="4">
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
                    <v-col cols="12" md="4">
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
                    <v-col cols="12" md="4">
                      <v-text-field
                        v-model.number="stockZ"
                        label="Z Height *"
                        type="number"
                        step="1"
                        suffix="mm"
                        :rules="[v => v > 0 || 'Must be positive', v => v <= 500 || 'Must be <= 500mm']"
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
                      <v-text-field
                        v-model.number="stockZ"
                        label="Z Height *"
                        type="number"
                        step="1"
                        suffix="mm"
                        :rules="[v => v > 0 || 'Must be positive', v => v <= 500 || 'Must be <= 500mm']"
                        :disabled="uiFrozen"
                      />
                    </v-col>
                    <v-col cols="12">
                      <v-alert dense outlined type="info" class="ma-0">
                        <div class="text-caption">
                          Origin: Center (fixed for circular stock)
                        </div>
                      </v-alert>
                    </v-col>
                  </v-row>
                </v-expansion-panel-content>
              </v-expansion-panel>

              <!-- Facing Pattern -->
              <v-expansion-panel>
                <v-expansion-panel-header>
                  <div>
                    <v-icon left small>mdi-axis-arrow</v-icon>
                    Facing Pattern
                  </div>
                </v-expansion-panel-header>
                <v-expansion-panel-content>
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
                    <v-col v-if="facingPattern === 'spiral'" cols="12">
                      <v-radio-group v-model="spiralDirection" row dense>
                        <v-radio label="Outside-In (Recommended)" value="outside-in" />
                        <v-radio label="Inside-Out" value="inside-out" />
                      </v-radio-group>
                    </v-col>
                    <v-col v-if="facingPattern === 'spiral'" cols="12">
                      <v-subheader class="px-0">
                        Spiral Resolution: {{ spiralSegmentsPerRevolution }} segments/revolution
                        <v-spacer />
                        <span class="text-caption">
                          {{ (360 / spiralSegmentsPerRevolution).toFixed(1) }}° per segment
                        </span>
                      </v-subheader>
                      <v-slider
                        v-model="spiralSegmentsPerRevolution"
                        :min="10"
                        :max="40"
                        :step="10"
                        thumb-label="always"
                        :disabled="uiFrozen"
                      >
                        <template v-slot:prepend>
                          <v-icon small>mdi-speedometer-slow</v-icon>
                          <span class="text-caption ml-1">Fast</span>
                        </template>
                        <template v-slot:append>
                          <span class="text-caption mr-1">Accurate</span>
                          <v-icon small>mdi-speedometer</v-icon>
                        </template>
                      </v-slider>
                    </v-col>
                  </v-row>
                </v-expansion-panel-content>
              </v-expansion-panel>

              <!-- Cutting Parameters -->
              <v-expansion-panel>
                <v-expansion-panel-header>
                  <div>
                    <v-icon left small>mdi-sine-wave</v-icon>
                    Cutting Parameters
                  </div>
                </v-expansion-panel-header>
                <v-expansion-panel-content>
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
                </v-expansion-panel-content>
              </v-expansion-panel>

              <!-- Feed and Speed -->
              <v-expansion-panel>
                <v-expansion-panel-header>
                  <div>
                    <v-icon left small>mdi-speedometer</v-icon>
                    Feed and Speed
                  </div>
                </v-expansion-panel-header>
                <v-expansion-panel-content>
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
                </v-expansion-panel-content>
              </v-expansion-panel>
            </v-expansion-panels>
          </v-form>
          
          <!-- Statistics (in right column) -->

          <!-- Statistics (in right column) -->
          <v-card outlined class="mt-4">
            <v-card-subtitle class="font-weight-bold">
              <v-icon left small>mdi-chart-box</v-icon>
              Statistics
            </v-card-subtitle>
            <v-card-text>
              <v-row dense>
                <v-col cols="12">
                  <div class="text-caption">Roughing Passes</div>
                  <div class="text-h6">{{ statistics.roughingPasses }}</div>
                </v-col>
                <v-col cols="12">
                  <div class="text-caption">Finishing Pass</div>
                  <div class="text-h6">{{ statistics.finishingPass ? 'Yes' : 'No' }}</div>
                </v-col>
                <v-col cols="12">
                  <div class="text-caption">Total Distance</div>
                  <div class="text-h6">{{ statistics.totalDistance }} mm</div>
                </v-col>
                <v-col cols="12">
                  <div class="text-caption">Est. Time</div>
                  <div class="text-h6">{{ formatTime(statistics.estimatedTime) }}</div>
                </v-col>
              </v-row>
            </v-card-text>
          </v-card>

          <!-- File Management (in right column) -->
          <v-card outlined class="mt-4">
            <v-card-subtitle class="font-weight-bold">
              <v-icon left small>mdi-content-save</v-icon>
              File Management
            </v-card-subtitle>
            <v-card-text>
              <v-row>
                <v-col cols="12">
                  <v-text-field
                    v-model="filename"
                    label="Filename"
                    suffix=".gcode"
                    :rules="[v => !!v || 'Filename required', v => /^[a-zA-Z0-9_-]+$/.test(v) || 'Invalid filename']"
                    hint="Alphanumeric, dash, and underscore only"
                    persistent-hint
                    dense
                  />
                </v-col>
                <v-col cols="12">
                  <v-select
                    v-model="saveLocation"
                    :items="saveLocations"
                    label="Save Location"
                    dense
                  />
                </v-col>
              </v-row>
              <v-row>
                <v-col cols="12">
                  <v-btn
                    block
                    color="secondary"
                    :disabled="!filename || uiFrozen"
                    @click="saveAsFile"
                    class="mb-2"
                  >
                    <v-icon left>mdi-content-save</v-icon>
                    Save as File
                  </v-btn>
                </v-col>
                <v-col cols="12">
                  <v-btn
                    block
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
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>

<script lang="ts">
// @ts-nocheck - Vue 2 component with Vuex store integration
import BaseComponent from '../base/BaseComponent.vue'
import GCodeViewer3D from './GCodeViewer3D.vue'
import {
  generateToolpath,
  calculateToolpathStatistics,
  ToolpathGenerationParams,
  ToolpathPoint
} from '../../utils/toolpath'
import { generateGCode, validateGCodeParameters } from '../../utils/gcode'

export default BaseComponent.extend({
  name: 'NxtStockPreparationPanel',
  
  components: {
    GCodeViewer3D
  },
  
  data() {
    return {
      formValid: false,
      
      // Tool Configuration
      toolRadius: 3.0,
      
      // Stock Geometry
      stockShape: 'rectangular' as 'rectangular' | 'circular',
      stockX: 100,
      stockY: 75,
      stockZ: 20,
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
      spiralSegmentsPerRevolution: 30,
      spiralDirection: 'outside-in' as 'outside-in' | 'inside-out',
      
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
      ],
      
      // Viewer Options
      highlightedGcodeLines: [] as number[],  // Array for multi-selection
      lastClickedLine: null as number | null,  // Track last clicked line for shift-select
      
      // Worker and Progress
      toolpathWorker: null as Worker | null,
      isGenerating: false,
      showProgressDialog: false,
      progressDialogTimer: null as NodeJS.Timeout | null,
      generationProgress: 0,
      generationMessage: ''
    }
  },
  
  computed: {
    gcodeLines(): string[] {
      return this.generatedGcode ? this.generatedGcode.split('\n') : []
    },
    
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
    },
    
    // Computed property that combines all toolpath settings
    // When this changes, we need to regenerate the preview
    toolpathSettings(): string {
      return JSON.stringify({
        stockShape: this.stockShape,
        stockX: this.stockX,
        stockY: this.stockY,
        stockZ: this.stockZ,
        stockDiameter: this.stockDiameter,
        originPosition: this.originPosition,
        facingPattern: this.facingPattern,
        patternAngle: this.patternAngle,
        millingDirection: this.millingDirection,
        spiralSegmentsPerRevolution: this.spiralSegmentsPerRevolution,
        spiralDirection: this.spiralDirection,
        stepover: this.stepover,
        stepdown: this.stepdown,
        totalDepth: this.totalDepth,
        zOffset: this.zOffset,
        safeZHeight: this.safeZHeight,
        clearStockExit: this.clearStockExit,
        finishingPass: this.finishingPass,
        finishingPassHeight: this.finishingPassHeight,
        finishingPassOffset: this.finishingPassOffset,
        feedRateXY: this.feedRateXY,
        feedRateZ: this.feedRateZ,
        spindleSpeed: this.spindleSpeed,
        toolRadius: this.toolRadius
      })
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
    
    // Watch the computed toolpathSettings property
    // Any change to toolpath parameters triggers regeneration
    toolpathSettings() {
      this.generatePreview()
    }
  },
  
  mounted() {
    this.initializeFromMachineState()
    // Set initial finishing pass offset to half of tool radius
    this.finishingPassOffset = this.toolRadius / 2
    
    // Initialize Web Worker for toolpath generation
    this.toolpathWorker = new Worker(
      new URL('../../workers/toolpath.worker.ts', import.meta.url),
      { type: 'module' }
    )
    
    // Set up worker message handler
    this.toolpathWorker.onmessage = (event) => {
      const message = event.data
      
      if (message.type === 'progress') {
        this.generationProgress = message.progress
        this.generationMessage = message.message
      } else if (message.type === 'complete') {
        this.isGenerating = false
        this.showProgressDialog = false
        if (this.progressDialogTimer) {
          clearTimeout(this.progressDialogTimer)
          this.progressDialogTimer = null
        }
        
        this.generatedToolpath = message.toolpath || []
        this.statistics = message.statistics || {
          totalDistance: 0,
          estimatedTime: 0,
          materialRemoved: 0,
          roughingPasses: 0,
          finishingPass: false
        }
        
        // Generate G-code from the toolpath
        const currentToolNum = this.currentTool?.number || 0
        const workplace = this.currentWorkplace || 1
        const params = this.buildGenerationParams()
        this.generatedGcode = generateGCode(
          this.generatedToolpath,
          params,
          currentToolNum,
          workplace
        )
      } else if (message.type === 'error') {
        this.isGenerating = false
        this.showProgressDialog = false
        if (this.progressDialogTimer) {
          clearTimeout(this.progressDialogTimer)
          this.progressDialogTimer = null
        }
        alert('Error generating toolpath: ' + message.error)
      }
    }
    
    this.toolpathWorker.onerror = (error) => {
      this.isGenerating = false
      this.showProgressDialog = false
      if (this.progressDialogTimer) {
        clearTimeout(this.progressDialogTimer)
        this.progressDialogTimer = null
      }
      console.error('Worker error:', error)
      alert('Worker error: ' + error.message)
    }
    
    // Generate initial toolpath
    this.generatePreview()
  },
  
  beforeDestroy() {
    // Clean up worker when component is destroyed
    if (this.toolpathWorker) {
      this.toolpathWorker.terminate()
      this.toolpathWorker = null
    }
    
    // Clean up progress dialog timer
    if (this.progressDialogTimer) {
      clearTimeout(this.progressDialogTimer)
      this.progressDialogTimer = null
    }
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
          z: this.stockZ,
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
          millingDirection: this.millingDirection,
          spiralSegmentsPerRevolution: this.spiralSegmentsPerRevolution,
          spiralDirection: this.spiralDirection
        },
        feeds: {
          xy: this.feedRateXY,
          z: this.feedRateZ,
          spindleSpeed: this.spindleSpeed
        }
      }
    },
    
    generatePreview() {
      // Don't generate if already generating
      if (this.isGenerating) {
        return
      }
      
      try {
        const params = this.buildGenerationParams()
        
        // Validate parameters
        const errors = validateGCodeParameters(params)
        if (errors.length > 0) {
          alert('Validation errors:\n' + errors.join('\n'))
          return
        }
        
        // Clear any existing progress dialog timer
        if (this.progressDialogTimer) {
          clearTimeout(this.progressDialogTimer)
          this.progressDialogTimer = null
        }
        
        // Start generation in worker
        this.isGenerating = true
        this.showProgressDialog = false
        this.generationProgress = 0
        this.generationMessage = 'Starting generation...'
        
        // Show progress dialog after 1 second if still generating
        this.progressDialogTimer = setTimeout(() => {
          if (this.isGenerating) {
            this.showProgressDialog = true
          }
          this.progressDialogTimer = null
        }, 1000)
        
        if (this.toolpathWorker) {
          this.toolpathWorker.postMessage({
            type: 'generate',
            params
          })
        } else {
          // Fallback to synchronous generation if worker not available
          this.generatedToolpath = generateToolpath(params)
          this.statistics = calculateToolpathStatistics(this.generatedToolpath, params.cutting)
          
          const currentToolNum = this.currentTool?.number || 0
          const workplace = this.currentWorkplace || 1
          this.generatedGcode = generateGCode(
            this.generatedToolpath,
            params,
            currentToolNum,
            workplace
          )
          this.isGenerating = false
          this.showProgressDialog = false
        }
      } catch (error) {
        this.isGenerating = false
        this.showProgressDialog = false
        if (this.progressDialogTimer) {
          clearTimeout(this.progressDialogTimer)
          this.progressDialogTimer = null
        }
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
    
    formatTime(seconds: number): string {
      const mins = Math.floor(seconds / 60)
      const secs = seconds % 60
      return `${mins}m ${secs}s`
    },
    
    isMovementCommand(line: string): boolean {
      const trimmed = line.trim()
      // Only G0, G1, G2, G3 movement commands are clickable
      return /^(G0|G1|G2|G3)\s/.test(trimmed)
    },
    
    onLineSelectedFrom3D(lineNumber: number, isShiftKey: boolean = false) {
      // Update highlighted line from 3D viewer click
      if (lineNumber >= 0 && lineNumber < this.gcodeLines.length) {
        if (isShiftKey && this.lastClickedLine !== null) {
          // Range select - select all lines between last clicked and current
          const start = Math.min(this.lastClickedLine, lineNumber)
          const end = Math.max(this.lastClickedLine, lineNumber)
          this.highlightedGcodeLines = []
          for (let i = start; i <= end; i++) {
            this.highlightedGcodeLines.push(i)
          }
          // Don't update lastClickedLine on shift-click to preserve anchor
        } else {
          // Single select
          this.highlightedGcodeLines = [lineNumber]
          this.lastClickedLine = lineNumber
        }
      }
    },
    
    onLinesSelectedFromOverlay(lineNumbers: number[]) {
      // Update selection from overlay clicks
      this.highlightedGcodeLines = lineNumbers
      if (lineNumbers.length > 0) {
        this.lastClickedLine = lineNumbers[lineNumbers.length - 1]
      }
    },
  }
})
</script>

<style scoped>
.nxt-stock-preparation-panel {
  width: 100%;
}

.toolpath-preview-placeholder {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 40px;
  background: #263238;
  border-radius: 4px;
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

.gcode-lines-container {
  font-family: 'Courier New', monospace;
  font-size: 12px;
  max-height: 400px;
  overflow-y: auto;
  border: 1px solid rgba(0, 0, 0, 0.12);
  border-radius: 4px;
}

.gcode-line {
  display: flex;
  padding: 2px 8px;
  white-space: pre;
  line-height: 1.5;
}

.gcode-line.even-line {
  background-color: rgba(0, 0, 0, 0.02);
}

.gcode-line.odd-line {
  background-color: rgba(0, 0, 0, 0.04);
}

.gcode-line.clickable-line {
  cursor: pointer;
}

.gcode-line.clickable-line:hover {
  background-color: rgba(33, 150, 243, 0.1) !important;
}

.gcode-line.highlighted-line {
  background-color: rgba(255, 235, 59, 0.3) !important;
  font-weight: bold;
}

.line-number {
  display: inline-block;
  min-width: 40px;
  text-align: right;
  margin-right: 12px;
  color: rgba(255, 255, 255, 0.4);
  user-select: none;
}

.theme--light .line-number {
  color: rgba(0, 0, 0, 0.4);
}

.line-content {
  flex: 1;
}

.v-stepper {
  box-shadow: none !important;
}
</style>
