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
                    <v-col cols="12" md="6">
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

              <!-- Step Actions -->
              <v-row>
                <v-col cols="12" class="text-right">
                  <v-btn
                    color="primary"
                    :disabled="!isSetupValid || uiFrozen"
                    @click="generatePreview"
                  >
                    Generate Preview & G-code
                    <v-icon right>mdi-refresh</v-icon>
                  </v-btn>
                </v-col>
              </v-row>
            </v-form>
          </v-col>

          <!-- Right Column: Preview & Run -->
          <v-col cols="12" md="6">
            <v-card flat>
              <v-card-subtitle class="font-weight-bold d-flex align-center">
                <v-icon left small>mdi-eye</v-icon>
                Toolpath Preview
                <v-spacer />
                <v-checkbox
                  v-model="showDirectionArrows"
                  label="Show Direction Arrows"
                  dense
                  hide-details
                  class="mt-0"
                />
              </v-card-subtitle>
              <v-card-text>
                <!-- SVG Visualization -->
                <div class="toolpath-preview-container">
                  <svg
                    ref="previewSvg"
                    :width="previewWidth"
                    :height="previewHeight"
                    class="toolpath-preview"
                  >
                    <!-- Define gradient for depth -->
                    <defs>
                      <linearGradient id="depthGradient" x1="0%" y1="0%" x2="0%" y2="100%">
                        <stop offset="0%" style="stop-color:#4CAF50;stop-opacity:1" />
                        <stop offset="100%" style="stop-color:#2196F3;stop-opacity:1" />
                      </linearGradient>
                    </defs>
                    
                    <!-- Stock boundary (isometric) -->
                    <g v-if="stockShape === 'rectangular'">
                      <path
                        :d="svgStockBoundaryPath"
                        fill="none"
                        stroke="#888888"
                        stroke-width="2"
                        stroke-dasharray="5,5"
                      />
                    </g>
                    <g v-if="stockShape === 'circular'">
                      <ellipse
                        :cx="svgCenterX"
                        :cy="svgCenterY - totalDepth * svgZScale * 0.5"
                        :rx="svgRadius"
                        :ry="svgRadius * 0.5"
                        fill="none"
                        stroke="#888888"
                        stroke-width="2"
                        stroke-dasharray="5,5"
                      />
                    </g>

                    <!-- WCS Origin indicator -->
                    <g :transform="`translate(${svgOriginX}, ${svgOriginY})`">
                      <line x1="-10" y1="0" x2="10" y2="0" stroke="red" stroke-width="1" />
                      <line x1="0" y1="-10" x2="0" y2="10" stroke="green" stroke-width="1" />
                      <circle cx="0" cy="0" r="3" fill="blue" />
                    </g>

                    <!-- Toolpath layers (all Z levels) -->
                    <g v-for="(layer, index) in svgToolpathLayers" :key="index">
                      <!-- Cutting moves -->
                      <path
                        :d="layer.cuttingPath"
                        fill="none"
                        :stroke="layer.color"
                        :stroke-opacity="layer.opacity"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                      />
                      <!-- Rapid moves -->
                      <path
                        v-if="layer.rapidPath"
                        :d="layer.rapidPath"
                        fill="none"
                        stroke="red"
                        :stroke-opacity="layer.opacity * 0.5"
                        stroke-width="1"
                        stroke-dasharray="3,3"
                      />
                      <!-- Direction arrows -->
                      <g v-if="showDirectionArrows">
                        <polygon
                          v-for="(arrow, arrowIndex) in layer.arrows"
                          :key="`arrow-${index}-${arrowIndex}`"
                          :points="arrow.points"
                          :fill="layer.color"
                          :fill-opacity="layer.opacity * 0.7"
                        />
                      </g>
                    </g>
                  </svg>
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
      ],
      
      // SVG Preview
      previewWidth: 600,
      previewHeight: 450,
      svgScale: 1,
      svgZScale: 3,  // Z axis scale factor for isometric view
      showDirectionArrows: false  // Option to show direction arrows on path
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
    },
    
    // SVG scaling and positioning
    svgStockX(): number {
      return this.stockX * this.svgScale
    },
    
    svgStockY(): number {
      return this.stockY * this.svgScale
    },
    
    svgCenterX(): number {
      return this.previewWidth / 2
    },
    
    svgCenterY(): number {
      return this.previewHeight / 2
    },
    
    svgRadius(): number {
      return (this.stockDiameter / 2) * this.svgScale
    },
    
    svgOriginX(): number {
      if (this.stockShape === 'circular') {
        return this.svgCenterX
      }
      // Rectangular origin positioning based on originPosition
      const position = this.originPosition
      if (position.includes('left')) return 0
      if (position.includes('center')) return this.svgStockX / 2
      if (position.includes('right')) return this.svgStockX
      return 0
    },
    
    svgOriginY(): number {
      if (this.stockShape === 'circular') {
        return this.svgCenterY
      }
      // Rectangular origin positioning
      const position = this.originPosition
      if (position.includes('front')) return 0
      if (position.includes('center')) return this.svgStockY / 2
      if (position.includes('back')) return this.svgStockY
      return 0
    },
    
    svgStockBoundaryPath(): string {
      if (this.stockShape !== 'rectangular') return ''
      
      // Create isometric box representation
      const x = 0
      const y = 0
      const w = this.svgStockX
      const h = this.svgStockY
      const d = this.totalDepth * this.svgZScale
      
      // Isometric transformation: shift Y by Z depth
      return `
        M ${x} ${y}
        L ${x + w} ${y}
        L ${x + w} ${y + h}
        L ${x} ${y + h}
        Z
        M ${x} ${y - d}
        L ${x + w} ${y - d}
        L ${x + w} ${y + h - d}
        L ${x} ${y + h - d}
        Z
        M ${x} ${y} L ${x} ${y - d}
        M ${x + w} ${y} L ${x + w} ${y - d}
        M ${x + w} ${y + h} L ${x + w} ${y + h - d}
        M ${x} ${y + h} L ${x} ${y + h - d}
      `
    },
    
    svgToolpathLayers(): Array<{ 
      cuttingPath: string; 
      rapidPath: string; 
      color: string; 
      opacity: number;
      arrows: Array<{ points: string }>;
    }> {
      if (this.generatedToolpath.length === 0) return []
      
      const layers: Array<{ 
        cuttingPath: string; 
        rapidPath: string; 
        color: string; 
        opacity: number;
        arrows: Array<{ points: string }>;
      }> = []
      
      // Process each Z level
      for (let levelIndex = 0; levelIndex < this.generatedToolpath.length; levelIndex++) {
        const level = this.generatedToolpath[levelIndex]
        if (!level || level.length === 0) continue
        
        // Calculate color based on depth (gradient from green to blue)
        const depthRatio = levelIndex / Math.max(1, this.generatedToolpath.length - 1)
        const r = Math.round(76 - depthRatio * 44)  // 76 -> 32 (green to blue)
        const g = Math.round(175 - depthRatio * 25)  // 175 -> 150
        const b = Math.round(80 + depthRatio * 163)  // 80 -> 243
        const color = `rgb(${r}, ${g}, ${b})`
        
        // Opacity decreases with depth to show layering
        const opacity = 1.0 - depthRatio * 0.3
        
        // Build separate paths for cutting and rapid moves
        let cuttingPath = ''
        let rapidPath = ''
        let firstCuttingPoint = true
        let firstRapidPoint = true
        const arrows: Array<{ points: string }> = []
        
        let prevPoint: any = null
        let prevX = 0
        let prevY = 0
        let lastDirection = { dx: 0, dy: 0 }
        
        for (let i = 0; i < level.length; i++) {
          const point = level[i]
          
          // Apply isometric transformation
          // For isometric: x' = x, y' = y - z * scale
          const x = (point.x * this.svgScale) + this.svgOriginX
          const y = (point.y * this.svgScale) + this.svgOriginY - (Math.abs(point.z - this.zOffset) * this.svgZScale)
          
          if (point.type === 'rapid') {
            // Rapid move - add to rapid path
            if (firstRapidPoint) {
              rapidPath += `M ${x} ${y} `
              firstRapidPoint = false
            } else {
              rapidPath += `L ${x} ${y} `
            }
          } else {
            // Cutting move - add to cutting path
            if (firstCuttingPoint) {
              cuttingPath += `M ${x} ${y} `
              firstCuttingPoint = false
            } else {
              cuttingPath += `L ${x} ${y} `
              
              // Check for direction change (for arrow placement)
              if (prevPoint && prevPoint.type !== 'rapid') {
                const dx = x - prevX
                const dy = y - prevY
                const distance = Math.sqrt(dx * dx + dy * dy)
                
                if (distance > 0) {
                  const currentDirection = { dx: dx / distance, dy: dy / distance }
                  
                  // Check if direction changed significantly (dot product < 0.9)
                  const dotProduct = currentDirection.dx * lastDirection.dx + currentDirection.dy * lastDirection.dy
                  
                  if (lastDirection.dx !== 0 || lastDirection.dy !== 0) {
                    if (dotProduct < 0.9 && distance > 10) {
                      // Direction changed - place arrow a few mm into the line
                      const arrowDist = Math.min(5, distance * 0.3)
                      const arrowX = prevX + currentDirection.dx * arrowDist
                      const arrowY = prevY + currentDirection.dy * arrowDist
                      
                      // Create arrow triangle pointing in direction of travel
                      const arrowSize = 4
                      const perpX = -currentDirection.dy
                      const perpY = currentDirection.dx
                      
                      const tipX = arrowX + currentDirection.dx * arrowSize
                      const tipY = arrowY + currentDirection.dy * arrowSize
                      const baseX1 = arrowX + perpX * arrowSize * 0.5
                      const baseY1 = arrowY + perpY * arrowSize * 0.5
                      const baseX2 = arrowX - perpX * arrowSize * 0.5
                      const baseY2 = arrowY - perpY * arrowSize * 0.5
                      
                      arrows.push({
                        points: `${tipX},${tipY} ${baseX1},${baseY1} ${baseX2},${baseY2}`
                      })
                    }
                  }
                  
                  lastDirection = currentDirection
                }
              }
            }
          }
          
          prevPoint = point
          prevX = x
          prevY = y
        }
        
        if (cuttingPath || rapidPath) {
          layers.push({ cuttingPath, rapidPath, color, opacity, arrows })
        }
      }
      
      return layers
    },
    
    svgToolpathPoints(): string {
      // Deprecated - keeping for compatibility but not used anymore
      return ''
    }
  },
  
  watch: {
    toolRadius(newRadius: number) {
      // Update finishing pass offset to half of tool radius when tool radius changes
      // Only update if user hasn't manually changed it from the default
      if (this.finishingPassOffset === 0.0 || this.finishingPassOffset === 1.5) {
        this.finishingPassOffset = newRadius / 2
      }
    }
  },
  
  mounted() {
    this.initializeFromMachineState()
    this.calculateSvgScale()
    // Set initial finishing pass offset to half of tool radius
    this.finishingPassOffset = this.toolRadius / 2
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
    
    calculateSvgScale() {
      const margin = 50
      const availableWidth = this.previewWidth - margin * 2
      const availableHeight = this.previewHeight - margin * 2
      
      if (this.stockShape === 'rectangular') {
        const scaleX = availableWidth / this.stockX
        const scaleY = availableHeight / this.stockY
        this.svgScale = Math.min(scaleX, scaleY)
      } else {
        const scale = Math.min(availableWidth, availableHeight) / this.stockDiameter
        this.svgScale = scale
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
        
        // Update SVG scale
        this.calculateSvgScale()
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
