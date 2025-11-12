<template>
  <div class="toolpath-viewer-3d">
    <canvas
      ref="canvas"
      :width="width"
      :height="height"
      @mousedown="onMouseDown"
      @mousemove="onMouseMove"
      @mouseup="onMouseUp"
      @wheel="onWheel"
      @touchstart="onTouchStart"
      @touchmove="onTouchMove"
      @touchend="onTouchEnd"
    />
  </div>
</template>

<script lang="ts">
import Vue, { PropType } from 'vue'
import { ToolpathPoint } from '../../utils/toolpath'

interface Camera {
  distance: number
  theta: number  // Horizontal rotation
  phi: number    // Vertical rotation
  targetX: number
  targetY: number
  targetZ: number
}

interface Point3D {
  x: number
  y: number
  z: number
}

export default Vue.extend({
  name: 'ToolpathViewer3D',
  
  props: {
    width: {
      type: Number,
      default: 600
    },
    height: {
      type: Number,
      default: 450
    },
    toolpath: {
      type: Array as PropType<ToolpathPoint[][]>,
      required: true
    },
    stockShape: {
      type: String as PropType<'rectangular' | 'circular'>,
      required: true
    },
    stockX: {
      type: Number,
      default: 100
    },
    stockY: {
      type: Number,
      default: 100
    },
    stockDiameter: {
      type: Number,
      default: 100
    },
    totalDepth: {
      type: Number,
      default: 5
    },
    zOffset: {
      type: Number,
      default: 0
    },
    originPosition: {
      type: String,
      default: 'front-left'
    },
    showDirectionArrows: {
      type: Boolean,
      default: false
    }
  },
  
  data() {
    return {
      ctx: null as CanvasRenderingContext2D | null,
      camera: {
        distance: 200,
        theta: Math.PI / 4,  // 45 degrees
        phi: Math.PI / 6,    // 30 degrees
        targetX: 0,
        targetY: 0,
        targetZ: 0
      } as Camera,
      isDragging: false,
      lastMouseX: 0,
      lastMouseY: 0,
      animationFrameId: null as number | null
    }
  },
  
  watch: {
    toolpath: {
      handler() {
        this.render()
      },
      deep: true
    },
    stockShape() {
      this.render()
    },
    stockX() {
      this.render()
    },
    stockY() {
      this.render()
    },
    stockDiameter() {
      this.render()
    },
    totalDepth() {
      this.render()
    },
    zOffset() {
      this.render()
    },
    originPosition() {
      this.render()
    },
    showDirectionArrows() {
      this.render()
    },
    width() {
      this.$nextTick(() => this.render())
    },
    height() {
      this.$nextTick(() => this.render())
    }
  },
  
  mounted() {
    const canvas = this.$refs.canvas as HTMLCanvasElement
    this.ctx = canvas.getContext('2d')
    
    // Set initial camera position to view the stock
    this.resetCamera()
    
    this.render()
  },
  
  beforeDestroy() {
    if (this.animationFrameId !== null) {
      cancelAnimationFrame(this.animationFrameId)
    }
  },
  
  methods: {
    resetCamera() {
      // Position camera to view the entire stock
      const maxDim = Math.max(
        this.stockShape === 'rectangular' ? Math.max(this.stockX, this.stockY) : this.stockDiameter,
        this.totalDepth
      )
      this.camera.distance = maxDim * 2.5
      this.camera.theta = Math.PI / 4
      this.camera.phi = Math.PI / 6
      this.camera.targetX = 0
      this.camera.targetY = 0
      this.camera.targetZ = -this.totalDepth / 2
    },
    
    /**
     * Calculate origin offset based on origin position
     * Returns the offset from WCS origin (0,0) to the front-left corner of the stock
     */
    calculateOriginOffset(): { x: number; y: number } {
      // Parse origin position to determine X and Y position
      const [yPos, xPos] = this.originPosition.split('-')
      
      let xOffset = 0
      let yOffset = 0
      
      // Calculate X offset based on horizontal position
      switch (xPos) {
        case 'left':
          xOffset = 0
          break
        case 'center':
          xOffset = -this.stockX / 2
          break
        case 'right':
          xOffset = -this.stockX
          break
      }
      
      // Calculate Y offset based on vertical position
      switch (yPos) {
        case 'front':
          yOffset = 0
          break
        case 'center':
          yOffset = -this.stockY / 2
          break
        case 'back':
          yOffset = -this.stockY
          break
      }
      
      return { x: xOffset, y: yOffset }
    },
    
    project3DTo2D(point: Point3D): { x: number; y: number } {
      // Calculate camera position from spherical coordinates
      const camX = this.camera.targetX + this.camera.distance * Math.sin(this.camera.phi) * Math.cos(this.camera.theta)
      const camY = this.camera.targetY + this.camera.distance * Math.sin(this.camera.phi) * Math.sin(this.camera.theta)
      const camZ = this.camera.targetZ + this.camera.distance * Math.cos(this.camera.phi)
      
      // Simple perspective projection
      const dx = point.x - camX
      const dy = point.y - camY
      const dz = point.z - camZ
      
      // Distance from camera
      const dist = Math.sqrt(dx * dx + dy * dy + dz * dz)
      
      // Calculate up and right vectors for camera
      const upX = 0
      const upY = 0
      const upZ = 1
      
      // Forward vector (camera to point)
      const forwardX = -Math.sin(this.camera.phi) * Math.cos(this.camera.theta)
      const forwardY = -Math.sin(this.camera.phi) * Math.sin(this.camera.theta)
      const forwardZ = -Math.cos(this.camera.phi)
      
      // Right vector (cross product of forward and up)
      const rightX = forwardY * upZ - forwardZ * upY
      const rightY = forwardZ * upX - forwardX * upZ
      const rightZ = forwardX * upY - forwardY * upX
      const rightLen = Math.sqrt(rightX * rightX + rightY * rightY + rightZ * rightZ)
      const normRightX = rightX / rightLen
      const normRightY = rightY / rightLen
      const normRightZ = rightZ / rightLen
      
      // Corrected up vector
      const corrUpX = normRightY * forwardZ - normRightZ * forwardY
      const corrUpY = normRightZ * forwardX - normRightX * forwardZ
      const corrUpZ = normRightX * forwardY - normRightY * forwardX
      
      // Project point onto camera plane
      const projX = dx * normRightX + dy * normRightY + dz * normRightZ
      const projY = dx * corrUpX + dy * corrUpY + dz * corrUpZ
      
      // Perspective divide and scale to screen coordinates
      const scale = 300 / this.camera.distance
      const screenX = this.width / 2 + projX * scale
      const screenY = this.height / 2 - projY * scale
      
      return { x: screenX, y: screenY }
    },
    
    render() {
      if (!this.ctx) return
      
      // Clear canvas
      this.ctx.fillStyle = '#f5f5f5'
      this.ctx.fillRect(0, 0, this.width, this.height)
      
      // Draw stock
      this.drawStock()
      
      // Draw origin axes
      this.drawOrigin()
      
      // Draw toolpath
      this.drawToolpath()
    },
    
    drawStock() {
      if (!this.ctx) return
      
      this.ctx.save()
      this.ctx.strokeStyle = '#888888'
      this.ctx.lineWidth = 2
      this.ctx.setLineDash([5, 5])
      this.ctx.fillStyle = 'rgba(200, 200, 200, 0.3)'
      
      if (this.stockShape === 'rectangular') {
        this.drawRectangularStock()
      } else {
        this.drawCircularStock()
      }
      
      this.ctx.restore()
    },
    
    drawRectangularStock() {
      if (!this.ctx) return
      
      // Get origin offset to position stock correctly relative to WCS origin
      const originOffset = this.calculateOriginOffset()
      
      // Calculate stock corner positions relative to WCS origin
      // The stock extends from originOffset to originOffset + stockDimensions
      const xMin = originOffset.x
      const xMax = originOffset.x + this.stockX
      const yMin = originOffset.y
      const yMax = originOffset.y + this.stockY
      
      // Define 8 corners of the rectangular stock
      const corners = [
        // Bottom face (Z = zOffset)
        { x: xMin, y: yMin, z: this.zOffset },
        { x: xMax, y: yMin, z: this.zOffset },
        { x: xMax, y: yMax, z: this.zOffset },
        { x: xMin, y: yMax, z: this.zOffset },
        // Top face (Z = zOffset - totalDepth)
        { x: xMin, y: yMin, z: this.zOffset - this.totalDepth },
        { x: xMax, y: yMin, z: this.zOffset - this.totalDepth },
        { x: xMax, y: yMax, z: this.zOffset - this.totalDepth },
        { x: xMin, y: yMax, z: this.zOffset - this.totalDepth }
      ]
      
      // Project all corners
      const projected = corners.map(c => this.project3DTo2D(c))
      
      // Draw faces (only visible ones based on camera position)
      const faces = [
        // Bottom face
        { indices: [0, 1, 2, 3], color: 'rgba(200, 200, 200, 0.4)' },
        // Top face
        { indices: [4, 5, 6, 7], color: 'rgba(200, 200, 200, 0.5)' },
        // Front face
        { indices: [0, 1, 5, 4], color: 'rgba(200, 200, 200, 0.3)' },
        // Back face
        { indices: [2, 3, 7, 6], color: 'rgba(200, 200, 200, 0.3)' },
        // Left face
        { indices: [0, 3, 7, 4], color: 'rgba(200, 200, 200, 0.35)' },
        // Right face
        { indices: [1, 2, 6, 5], color: 'rgba(200, 200, 200, 0.35)' }
      ]
      
      // Draw filled faces
      faces.forEach(face => {
        this.ctx!.beginPath()
        this.ctx!.moveTo(projected[face.indices[0]].x, projected[face.indices[0]].y)
        for (let i = 1; i < face.indices.length; i++) {
          this.ctx!.lineTo(projected[face.indices[i]].x, projected[face.indices[i]].y)
        }
        this.ctx!.closePath()
        this.ctx!.fillStyle = face.color
        this.ctx!.fill()
      })
      
      // Draw edges
      const edges = [
        [0, 1], [1, 2], [2, 3], [3, 0],  // Bottom face
        [4, 5], [5, 6], [6, 7], [7, 4],  // Top face
        [0, 4], [1, 5], [2, 6], [3, 7]   // Vertical edges
      ]
      
      this.ctx!.strokeStyle = '#888888'
      this.ctx!.lineWidth = 1
      this.ctx!.setLineDash([5, 5])
      
      edges.forEach(edge => {
        this.ctx!.beginPath()
        this.ctx!.moveTo(projected[edge[0]].x, projected[edge[0]].y)
        this.ctx!.lineTo(projected[edge[1]].x, projected[edge[1]].y)
        this.ctx!.stroke()
      })
    },
    
    drawCircularStock() {
      if (!this.ctx) return
      
      const radius = this.stockDiameter / 2
      const segments = 32
      
      // Draw top circle
      this.ctx.beginPath()
      for (let i = 0; i <= segments; i++) {
        const angle = (i / segments) * Math.PI * 2
        const x = radius * Math.cos(angle)
        const y = radius * Math.sin(angle)
        const z = this.zOffset
        const point = this.project3DTo2D({ x, y, z })
        if (i === 0) {
          this.ctx.moveTo(point.x, point.y)
        } else {
          this.ctx.lineTo(point.x, point.y)
        }
      }
      this.ctx.fillStyle = 'rgba(200, 200, 200, 0.4)'
      this.ctx.fill()
      this.ctx.stroke()
      
      // Draw bottom circle
      this.ctx.beginPath()
      for (let i = 0; i <= segments; i++) {
        const angle = (i / segments) * Math.PI * 2
        const x = radius * Math.cos(angle)
        const y = radius * Math.sin(angle)
        const z = this.zOffset - this.totalDepth
        const point = this.project3DTo2D({ x, y, z })
        if (i === 0) {
          this.ctx.moveTo(point.x, point.y)
        } else {
          this.ctx.lineTo(point.x, point.y)
        }
      }
      this.ctx.fillStyle = 'rgba(200, 200, 200, 0.5)'
      this.ctx.fill()
      this.ctx.stroke()
      
      // Draw connecting lines (every 8th segment for clarity)
      for (let i = 0; i < segments; i += 8) {
        const angle = (i / segments) * Math.PI * 2
        const x = radius * Math.cos(angle)
        const y = radius * Math.sin(angle)
        const topPoint = this.project3DTo2D({ x, y, z: this.zOffset })
        const bottomPoint = this.project3DTo2D({ x, y, z: this.zOffset - this.totalDepth })
        
        this.ctx.beginPath()
        this.ctx.moveTo(topPoint.x, topPoint.y)
        this.ctx.lineTo(bottomPoint.x, bottomPoint.y)
        this.ctx.stroke()
      }
    },
    
    drawOrigin() {
      if (!this.ctx) return
      
      // Draw XYZ axes at origin
      const origin = this.project3DTo2D({ x: 0, y: 0, z: this.zOffset })
      const xAxis = this.project3DTo2D({ x: 20, y: 0, z: this.zOffset })
      const yAxis = this.project3DTo2D({ x: 0, y: 20, z: this.zOffset })
      const zAxis = this.project3DTo2D({ x: 0, y: 0, z: this.zOffset + 20 })
      
      this.ctx.save()
      this.ctx.setLineDash([])
      this.ctx.lineWidth = 2
      
      // X axis (red)
      this.ctx.strokeStyle = '#ff0000'
      this.ctx.beginPath()
      this.ctx.moveTo(origin.x, origin.y)
      this.ctx.lineTo(xAxis.x, xAxis.y)
      this.ctx.stroke()
      
      // Y axis (green)
      this.ctx.strokeStyle = '#00ff00'
      this.ctx.beginPath()
      this.ctx.moveTo(origin.x, origin.y)
      this.ctx.lineTo(yAxis.x, yAxis.y)
      this.ctx.stroke()
      
      // Z axis (blue)
      this.ctx.strokeStyle = '#0000ff'
      this.ctx.beginPath()
      this.ctx.moveTo(origin.x, origin.y)
      this.ctx.lineTo(zAxis.x, zAxis.y)
      this.ctx.stroke()
      
      // Draw origin point
      this.ctx.fillStyle = '#0000ff'
      this.ctx.beginPath()
      this.ctx.arc(origin.x, origin.y, 3, 0, Math.PI * 2)
      this.ctx.fill()
      
      this.ctx.restore()
    },
    
    drawToolpath() {
      if (!this.ctx || this.toolpath.length === 0) return
      
      this.ctx.save()
      this.ctx.setLineDash([])
      
      // Draw each Z level
      for (let levelIndex = 0; levelIndex < this.toolpath.length; levelIndex++) {
        const level = this.toolpath[levelIndex]
        if (!level || level.length === 0) continue
        
        // Calculate color based on depth (gradient from green to blue)
        const depthRatio = levelIndex / Math.max(1, this.toolpath.length - 1)
        const r = Math.round(76 - depthRatio * 44)
        const g = Math.round(175 - depthRatio * 25)
        const b = Math.round(80 + depthRatio * 163)
        const color = `rgb(${r}, ${g}, ${b})`
        
        // Opacity decreases with depth
        const opacity = 1.0 - depthRatio * 0.3
        
        let prevPoint: Point3D | null = null
        let prevProjected: { x: number; y: number } | null = null
        
        for (let i = 0; i < level.length; i++) {
          const point = level[i]
          const projected = this.project3DTo2D({ x: point.x, y: point.y, z: point.z })
          
          if (prevPoint && prevProjected) {
            this.ctx.beginPath()
            this.ctx.moveTo(prevProjected.x, prevProjected.y)
            this.ctx.lineTo(projected.x, projected.y)
            
            if (point.type === 'rapid') {
              // Rapids in red
              this.ctx.strokeStyle = `rgba(255, 0, 0, ${opacity * 0.7})`
              this.ctx.lineWidth = 1
              this.ctx.setLineDash([3, 3])
            } else {
              // Cutting moves in color
              this.ctx.strokeStyle = color
              this.ctx.globalAlpha = opacity
              this.ctx.lineWidth = 2
              this.ctx.setLineDash([])
            }
            
            this.ctx.stroke()
            this.ctx.globalAlpha = 1.0
            
            // Draw direction arrow if enabled
            if (this.showDirectionArrows && point.type !== 'rapid' && i % 10 === 0) {
              this.drawArrow(prevProjected, projected, color, opacity)
            }
          }
          
          prevPoint = { x: point.x, y: point.y, z: point.z }
          prevProjected = projected
        }
      }
      
      this.ctx.restore()
    },
    
    drawArrow(from: { x: number; y: number }, to: { x: number; y: number }, color: string, opacity: number) {
      if (!this.ctx) return
      
      const dx = to.x - from.x
      const dy = to.y - from.y
      const distance = Math.sqrt(dx * dx + dy * dy)
      
      if (distance < 5) return
      
      const dirX = dx / distance
      const dirY = dy / distance
      
      // Arrow size
      const arrowSize = 4
      
      // Position arrow a bit into the line
      const arrowDist = Math.min(5, distance * 0.3)
      const arrowX = from.x + dirX * arrowDist
      const arrowY = from.y + dirY * arrowDist
      
      // Perpendicular vector
      const perpX = -dirY
      const perpY = dirX
      
      // Arrow triangle
      const tipX = arrowX + dirX * arrowSize
      const tipY = arrowY + dirY * arrowSize
      const baseX1 = arrowX + perpX * arrowSize * 0.5
      const baseY1 = arrowY + perpY * arrowSize * 0.5
      const baseX2 = arrowX - perpX * arrowSize * 0.5
      const baseY2 = arrowY - perpY * arrowSize * 0.5
      
      this.ctx.beginPath()
      this.ctx.moveTo(tipX, tipY)
      this.ctx.lineTo(baseX1, baseY1)
      this.ctx.lineTo(baseX2, baseY2)
      this.ctx.closePath()
      
      this.ctx.fillStyle = color
      this.ctx.globalAlpha = opacity * 0.7
      this.ctx.fill()
      this.ctx.globalAlpha = 1.0
    },
    
    // Mouse interaction handlers
    onMouseDown(event: MouseEvent) {
      this.isDragging = true
      this.lastMouseX = event.clientX
      this.lastMouseY = event.clientY
    },
    
    onMouseMove(event: MouseEvent) {
      if (!this.isDragging) return
      
      const deltaX = event.clientX - this.lastMouseX
      const deltaY = event.clientY - this.lastMouseY
      
      // Rotate camera
      this.camera.theta += deltaX * 0.01
      this.camera.phi = Math.max(0.1, Math.min(Math.PI - 0.1, this.camera.phi + deltaY * 0.01))
      
      this.lastMouseX = event.clientX
      this.lastMouseY = event.clientY
      
      this.render()
    },
    
    onMouseUp() {
      this.isDragging = false
    },
    
    onWheel(event: WheelEvent) {
      event.preventDefault()
      
      // Zoom in/out
      const zoomFactor = event.deltaY > 0 ? 1.1 : 0.9
      this.camera.distance *= zoomFactor
      
      // Limit zoom
      const maxDim = Math.max(
        this.stockShape === 'rectangular' ? Math.max(this.stockX, this.stockY) : this.stockDiameter,
        this.totalDepth
      )
      this.camera.distance = Math.max(maxDim * 0.5, Math.min(maxDim * 5, this.camera.distance))
      
      this.render()
    },
    
    // Touch handlers for mobile
    onTouchStart(event: TouchEvent) {
      if (event.touches.length === 1) {
        this.isDragging = true
        this.lastMouseX = event.touches[0].clientX
        this.lastMouseY = event.touches[0].clientY
      }
    },
    
    onTouchMove(event: TouchEvent) {
      if (event.touches.length === 1 && this.isDragging) {
        event.preventDefault()
        const deltaX = event.touches[0].clientX - this.lastMouseX
        const deltaY = event.touches[0].clientY - this.lastMouseY
        
        this.camera.theta += deltaX * 0.01
        this.camera.phi = Math.max(0.1, Math.min(Math.PI - 0.1, this.camera.phi + deltaY * 0.01))
        
        this.lastMouseX = event.touches[0].clientX
        this.lastMouseY = event.touches[0].clientY
        
        this.render()
      }
    },
    
    onTouchEnd() {
      this.isDragging = false
    }
  }
})
</script>

<style scoped>
.toolpath-viewer-3d {
  display: flex;
  justify-content: center;
  align-items: center;
  background: #f5f5f5;
  border: 1px solid #ddd;
  border-radius: 4px;
  overflow: hidden;
}

canvas {
  cursor: grab;
  touch-action: none;
}

canvas:active {
  cursor: grabbing;
}
</style>
