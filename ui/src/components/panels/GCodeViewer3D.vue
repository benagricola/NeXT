<template>
  <div class="gcode-viewer-3d">
    <canvas ref="canvas" @mousedown="onCanvasMouseDown" @click="onCanvasClick"></canvas>
    <div v-if="highlightedGcodeText" class="gcode-annotation">
      <span class="annotation-line-number">#{{ highlightedLine + 1 }}:</span> {{ highlightedGcodeText }}
    </div>
    <div v-if="loading" class="loading-overlay">
      <v-progress-circular indeterminate color="primary"></v-progress-circular>
      <div class="mt-2">Parsing G-code...</div>
    </div>
    <div v-if="error" class="error-overlay">
      <v-alert type="error">{{ error }}</v-alert>
    </div>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import * as THREE from 'three'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls'

interface StockMetadata {
  type: 'cuboid' | 'cylinder'
  dimensions: number[]
}

export default Vue.extend({
  name: 'GCodeViewer3D',
  
  props: {
    gcode: {
      type: String,
      required: true
    },
    autoUpdate: {
      type: Boolean,
      default: true
    },
    highlightedLine: {
      type: Number,
      default: null
    },
    highlightedGcodeText: {
      type: String,
      default: ''
    }
  },
  
  data() {
    return {
      loading: false,
      error: null as string | null,
      scene: null as THREE.Scene | null,
      camera: null as THREE.PerspectiveCamera | null,
      renderer: null as THREE.WebGLRenderer | null,
      controls: null as OrbitControls | null,
      animationFrameId: null as number | null,
      lineSegments: new Map<number, { line: THREE.Line, originalColor: number, originalLineWidth: number, from: THREE.Vector3, to: THREE.Vector3 }>(),
      currentHighlightedLine: null as THREE.Line | null,
      highlightedArrows: [] as THREE.Mesh[],
      raycaster: new THREE.Raycaster(),
      mouse: new THREE.Vector2()
    }
  },
  
  watch: {
    gcode(newGcode: string) {
      if (this.autoUpdate && newGcode) {
        this.renderGCode()
      }
    },
    
    highlightedLine(newLineNumber: number | null, oldLineNumber: number | null) {
      // Remove previous arrows if they exist
      this.highlightedArrows.forEach(arrow => this.scene?.remove(arrow))
      this.highlightedArrows = []
      
      // Restore previous highlighted line to original color
      if (this.currentHighlightedLine) {
        const oldSegment = this.lineSegments.get(oldLineNumber!)
        if (oldSegment) {
          const material = oldSegment.line.material as THREE.LineBasicMaterial
          material.color.setHex(oldSegment.originalColor)
          material.linewidth = oldSegment.originalLineWidth
          material.needsUpdate = true
        }
        this.currentHighlightedLine = null
      }
      
      // Highlight new line and create arrow
      if (newLineNumber !== null) {
        const segment = this.lineSegments.get(newLineNumber)
        if (segment) {
          const material = segment.line.material as THREE.LineBasicMaterial
          material.color.setHex(0xFFFF00) // Yellow highlight
          material.linewidth = 4
          material.needsUpdate = true
          this.currentHighlightedLine = segment.line
          
          // Create direction arrow for highlighted line
          this.createHighlightArrow(segment.from, segment.to)
        }
      }
    }
  },
  
  mounted() {
    this.raycaster.params.Line!.threshold = 0.5  // Increase click tolerance for lines
    this.initThreeJS()
    if (this.gcode) {
      this.renderGCode()
    }
    window.addEventListener('resize', this.onWindowResize)
  },
  
  beforeDestroy() {
    window.removeEventListener('resize', this.onWindowResize)
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId)
    }
    if (this.controls) {
      this.controls.dispose()
    }
    if (this.renderer) {
      this.renderer.dispose()
    }
  },
  
  methods: {
    initThreeJS() {
      const canvas = this.$refs.canvas as HTMLCanvasElement
      if (!canvas) return
      
      // Scene
      this.scene = new THREE.Scene()
      this.scene.background = new THREE.Color(0x263238) // DWC dark theme
      
      // Camera
      const aspect = canvas.clientWidth / canvas.clientHeight
      this.camera = new THREE.PerspectiveCamera(50, aspect, 0.1, 10000)
      this.camera.position.set(100, 100, 100)
      this.camera.lookAt(0, 0, 0)
      
      // Renderer
      this.renderer = new THREE.WebGLRenderer({
        canvas: canvas,
        antialias: true,
        alpha: false
      })
      this.renderer.setSize(canvas.clientWidth, canvas.clientHeight)
      this.renderer.setPixelRatio(window.devicePixelRatio)
      
      // Lighting
      const ambientLight = new THREE.AmbientLight(0xffffff, 0.6)
      this.scene.add(ambientLight)
      
      const directionalLight1 = new THREE.DirectionalLight(0xffffff, 0.4)
      directionalLight1.position.set(1, 1, 1)
      this.scene.add(directionalLight1)
      
      const directionalLight2 = new THREE.DirectionalLight(0xffffff, 0.2)
      directionalLight2.position.set(-1, -1, -0.5)
      this.scene.add(directionalLight2)
      
      // Grid
      const gridHelper = new THREE.GridHelper(200, 20, 0x444444, 0x333333)
      this.scene.add(gridHelper)
      
      // Axes
      const axesHelper = new THREE.AxesHelper(50)
      this.scene.add(axesHelper)
      
      // Controls
      this.controls = new OrbitControls(this.camera, canvas)
      this.controls.enableDamping = true
      this.controls.dampingFactor = 0.05
      this.controls.screenSpacePanning = false  // Use target-based rotation instead of screen-space panning
      this.controls.minDistance = 10
      this.controls.maxDistance = 1000
      
      // Mouse button configuration:
      // LEFT (0) = rotate/orbit camera around target
      // MIDDLE (1) = pan camera (screen-space movement)
      // RIGHT (2) = zoom
      this.controls.mouseButtons = {
        LEFT: THREE.MOUSE.ROTATE,
        MIDDLE: THREE.MOUSE.PAN,
        RIGHT: THREE.MOUSE.DOLLY
      }
      
      // Start animation loop
      this.animate()
    },
    
    animate() {
      this.animationFrameId = requestAnimationFrame(this.animate)
      
      if (this.controls) {
        this.controls.update()
      }
      
      if (this.renderer && this.scene && this.camera) {
        this.renderer.render(this.scene, this.camera)
      }
    },
    
    onWindowResize() {
      const canvas = this.$refs.canvas as HTMLCanvasElement
      if (!canvas || !this.camera || !this.renderer) return
      
      const width = canvas.clientWidth
      const height = canvas.clientHeight
      
      this.camera.aspect = width / height
      this.camera.updateProjectionMatrix()
      
      this.renderer.setSize(width, height)
    },
    
    onCanvasMouseDown(event: MouseEvent) {
      // Prevent text selection when dragging
      event.preventDefault()
    },
    
    onCanvasClick(event: MouseEvent) {
      if (!this.camera || !this.scene) return
      
      const canvas = this.$refs.canvas as HTMLCanvasElement
      const rect = canvas.getBoundingClientRect()
      
      // Calculate mouse position in normalized device coordinates (-1 to +1)
      this.mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1
      this.mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1
      
      // Update raycaster
      this.raycaster.setFromCamera(this.mouse, this.camera)
      
      // Find intersected lines
      const lines: THREE.Line[] = []
      this.lineSegments.forEach(segment => lines.push(segment.line))
      
      const intersects = this.raycaster.intersectObjects(lines)
      
      if (intersects.length > 0) {
        // Find which line was clicked
        const clickedLine = intersects[0].object as THREE.Line
        
        // Find the line number for this line
        for (const [lineNumber, segment] of this.lineSegments.entries()) {
          if (segment.line === clickedLine) {
            // Emit event to parent to update highlighted line
            this.$emit('line-selected', lineNumber)
            break
          }
        }
      }
    },
    
    createHighlightArrow(fromVec: THREE.Vector3, toVec: THREE.Vector3) {
      if (!this.scene) return
      
      const direction = new THREE.Vector3().subVectors(toVec, fromVec)
      const lineLength = direction.length()
      direction.normalize()
      
      // Arrow size: 8% of line length, minimum 1mm, maximum 3mm
      const arrowLength = Math.max(1, Math.min(lineLength * 0.08, 3))
      
      // Skip arrows if line is shorter than 1.1x the arrow length
      if (lineLength < arrowLength * 1.1) return
      
      // Minimum spacing between arrows: 15mm
      const minSpacing = 15
      
      // Calculate how many arrows we can fit
      const numArrows = Math.floor(lineLength / minSpacing)
      
      if (numArrows === 0) {
        // Line is shorter than 15mm - show single centered arrow
        this.createSingleArrow(fromVec, toVec, direction, arrowLength, 0.5)
      } else {
        // Calculate actual spacing to distribute arrows evenly
        const actualSpacing = lineLength / (numArrows + 1)
        
        // Create arrows at regular intervals along the line
        for (let i = 1; i <= numArrows; i++) {
          const position = (i * actualSpacing) / lineLength
          this.createSingleArrow(fromVec, toVec, direction, arrowLength, position)
        }
      }
    },
    
    createSingleArrow(fromVec: THREE.Vector3, toVec: THREE.Vector3, direction: THREE.Vector3, arrowLength: number, position: number) {
      if (!this.scene) return
      
      // Position arrow at specified position along line
      const arrowOrigin = fromVec.clone().lerp(toVec, position)
      const arrowRadius = arrowLength * 0.2  // Wider base (was 0.15)
      
      // Create cone geometry for smooth appearance
      const coneGeometry = new THREE.ConeGeometry(arrowRadius, arrowLength, 8)
      // Very bright orange/pink color for highlighted arrow
      const arrowColor = 0xFF1493  // Deep pink - very visible
      const coneMaterial = new THREE.MeshPhongMaterial({ 
        color: arrowColor,
        emissive: arrowColor,
        emissiveIntensity: 0.8  // Very high intensity for maximum visibility
      })
      const cone = new THREE.Mesh(coneGeometry, coneMaterial)
      
      // Position and orient cone
      cone.position.copy(arrowOrigin).add(direction.clone().multiplyScalar(arrowLength / 2))
      
      // Align cone with direction vector
      const upVector = new THREE.Vector3(0, 1, 0)
      const quaternion = new THREE.Quaternion().setFromUnitVectors(upVector, direction)
      cone.setRotationFromQuaternion(quaternion)
      
      this.scene.add(cone)
      this.highlightedArrows.push(cone)
    },
    
    async renderGCode() {
      if (!this.gcode || !this.scene) return
      
      this.loading = true
      this.error = null
      
      try {
        // Clear previous objects (keep helpers)
        const objectsToRemove: any[] = []
        this.scene.traverse((obj: any) => {
          if (obj.type === 'Line' || obj.type === 'LineSegments' || obj.type === 'Mesh') {
            if (obj.name !== 'grid' && obj.name !== 'axes') {
              objectsToRemove.push(obj)
            }
          }
        })
        objectsToRemove.forEach(obj => this.scene!.remove(obj))
        
        // Clear highlighted arrows
        this.highlightedArrows.forEach(arrow => this.scene!.remove(arrow))
        this.highlightedArrows = []
        
        // Clear line segment mappings
        this.lineSegments.clear()
        this.currentHighlightedLine = null
        
        // Parse G-code
        const { stock, toolpaths } = this.parseGCode(this.gcode)
        
        // Render stock
        if (stock) {
          this.renderStock(stock)
        }
        
        // Render toolpaths
        this.renderToolpaths(toolpaths)
        
        // Auto-fit camera
        this.fitCameraToScene()
        
      } catch (err: any) {
        console.error('Error rendering G-code:', err)
        this.error = `Failed to render G-code: ${err.message}`
      } finally {
        this.loading = false
      }
    },
    
    parseGCode(gcode: string): { stock: StockMetadata | null; toolpaths: any[] } {
      const lines = gcode.split('\n')
      let stock: StockMetadata | null = null
      const toolpaths: any[] = []
      
      let currentX = 0
      let currentY = 0
      let currentZ = 0
      let currentLevel: any[] = []
      let lastZ = 0
      
      for (let lineNumber = 0; lineNumber < lines.length; lineNumber++) {
        const line = lines[lineNumber]
        const trimmed = line.trim()
        if (!trimmed || trimmed.startsWith(';')) {
          // Check for stock metadata in comments
          if (trimmed.startsWith('; Stock:')) {
            // Parse stock info from comment (backup if M7500 not found)
          }
          continue
        }
        
        // Parse M7500 stock metadata
        if (trimmed.startsWith('M7500')) {
          const keyMatch = trimmed.match(/K"([^"]+)"/)
          const valueMatch = trimmed.match(/V\{([^}]+)\}/)
          
          if (keyMatch && valueMatch) {
            const key = keyMatch[1]
            const values = valueMatch[1].split(',').map(v => parseFloat(v.trim()))
            
            if (key === 'stock_cuboid' && values.length === 3) {
              stock = { type: 'cuboid', dimensions: values }
            } else if (key === 'stock_cylinder' && values.length === 2) {
              stock = { type: 'cylinder', dimensions: values }
            }
          }
          continue
        }
        
        // Parse movement commands
        const gMatch = trimmed.match(/^(G0|G1|G2|G3)/)
        if (!gMatch) continue
        
        const command = gMatch[1]
        
        // Extract coordinates
        const xMatch = trimmed.match(/X([-\d.]+)/)
        const yMatch = trimmed.match(/Y([-\d.]+)/)
        const zMatch = trimmed.match(/Z([-\d.]+)/)
        const iMatch = trimmed.match(/I([-\d.]+)/)
        const jMatch = trimmed.match(/J([-\d.]+)/)
        
        const x = xMatch ? parseFloat(xMatch[1]) : currentX
        const y = yMatch ? parseFloat(yMatch[1]) : currentY
        const z = zMatch ? parseFloat(zMatch[1]) : currentZ
        
        // Check if we're at a new Z level
        if (z !== lastZ) {
          if (currentLevel.length > 0) {
            toolpaths.push(currentLevel)
          }
          currentLevel = []
          lastZ = z
        }
        
        // Create toolpath segment
        const segment: any = {
          type: command === 'G0' ? 'rapid' : command === 'G2' || command === 'G3' ? 'arc' : 'linear',
          from: { x: currentX, y: currentY, z: currentZ },
          to: { x, y, z },
          lineNumber: lineNumber
        }
        
        // Add arc parameters
        if ((command === 'G2' || command === 'G3') && iMatch && jMatch) {
          segment.arcCenter = {
            x: currentX + parseFloat(iMatch[1]),
            y: currentY + parseFloat(jMatch[1]),
            z: currentZ
          }
          segment.clockwise = command === 'G2'
        }
        
        currentLevel.push(segment)
        
        currentX = x
        currentY = y
        currentZ = z
      }
      
      // Add final level
      if (currentLevel.length > 0) {
        toolpaths.push(currentLevel)
      }
      
      return { stock, toolpaths }
    },
    
    renderStock(stock: StockMetadata) {
      if (!this.scene) return
      
      const material = new THREE.MeshPhongMaterial({
        color: 0x2E7D32,  // Darker green for better contrast
        transparent: true,
        opacity: 0.2,
        side: THREE.DoubleSide
      })
      
      let geometry: any
      
      if (stock.type === 'cuboid') {
        const [x, y, z] = stock.dimensions
        geometry = new THREE.BoxGeometry(x, z, y) // X width, Z height, Y depth
        const mesh = new THREE.Mesh(geometry, material)
        // Position stock so it extends DOWN from Z=0, centered on X and Y
        mesh.position.set(x / 2, -z / 2, -y / 2)
        this.scene.add(mesh)
        
        // Wireframe
        const edges = new THREE.EdgesGeometry(geometry)
        const lineMaterial = new THREE.LineBasicMaterial({ color: 0x1B5E20, linewidth: 1 })  // Dark green
        const wireframe = new THREE.LineSegments(edges, lineMaterial)
        wireframe.position.copy(mesh.position)
        this.scene.add(wireframe)
      } else if (stock.type === 'cylinder') {
        const [diameter, height] = stock.dimensions
        const radius = diameter / 2
        geometry = new THREE.CylinderGeometry(radius, radius, height, 32)
        const mesh = new THREE.Mesh(geometry, material)
        // Center cylinder at origin on XZ plane, extending DOWN from Z=0
        mesh.position.set(0, -height / 2, 0)
        this.scene.add(mesh)
        
        // Wireframe
        const edges = new THREE.EdgesGeometry(geometry)
        const lineMaterial = new THREE.LineBasicMaterial({ color: 0x1B5E20, linewidth: 1 })  // Dark green
        const wireframe = new THREE.LineSegments(edges, lineMaterial)
        wireframe.position.copy(mesh.position)
        this.scene.add(wireframe)
      }
    },
    
    renderToolpaths(toolpaths: any[][]) {
      if (!this.scene || toolpaths.length === 0) return
      
      toolpaths.forEach((level, levelIndex) => {
        if (!level || level.length === 0) return
        
        // Color gradient from green to blue by depth
        const depthRatio = levelIndex / Math.max(1, toolpaths.length - 1)
        const color = new THREE.Color()
        color.setRGB(
          0.3 - depthRatio * 0.1,  // R: 0.3 -> 0.2
          0.7 - depthRatio * 0.1,  // G: 0.7 -> 0.6
          0.3 + depthRatio * 0.7   // B: 0.3 -> 1.0
        )
        
        level.forEach(segment => {
          if (!segment || !segment.from || !segment.to) return
          
          if (segment.type === 'rapid') {
            // Rapid moves: dashed red lines for visibility
            this.renderLine(segment.from, segment.to, 0xFF0000, true, segment.lineNumber, levelIndex)
          } else if (segment.type === 'arc') {
            // Arc moves: curved solid lines
            this.renderArc(segment.from, segment.to, segment.arcCenter, segment.clockwise, color.getHex(), segment.lineNumber, levelIndex)
          } else {
            // Linear cutting moves: solid colored lines
            this.renderLine(segment.from, segment.to, color.getHex(), false, segment.lineNumber, levelIndex)
          }
        })
      })
    },
    
    renderLine(from: any, to: any, color: number, dashed: boolean, lineNumber?: number, levelIndex?: number) {
      if (!this.scene || !from || !to) return
      if (from.x === undefined || from.y === undefined || from.z === undefined) return
      if (to.x === undefined || to.y === undefined || to.z === undefined) return
      
      const fromVec = new THREE.Vector3(from.x, from.z, -from.y) // X stays X, Z→Y (up), Y→-Z (depth)
      const toVec = new THREE.Vector3(to.x, to.z, -to.y)
      
      const points = [fromVec, toVec]
      
      const geometry = new THREE.BufferGeometry().setFromPoints(points)
      const linewidth = dashed ? 1 : 2
      const material = dashed
        ? new THREE.LineDashedMaterial({ color, linewidth, dashSize: 2, gapSize: 1 })
        : new THREE.LineBasicMaterial({ color, linewidth })
      
      const line = new THREE.Line(geometry, material)
      
      if (dashed) {
        line.computeLineDistances()
      }
      
      this.scene.add(line)
      
      // Store line mapping with from/to vectors for arrow creation
      if (lineNumber !== undefined) {
        this.lineSegments.set(lineNumber, {
          line,
          originalColor: color,
          originalLineWidth: linewidth,
          from: fromVec.clone(),
          to: toVec.clone()
        })
      }
    },
    
    renderArc(from: any, to: any, center: any, clockwise: boolean, color: number, lineNumber?: number, levelIndex?: number) {
      if (!this.scene || !from || !to || !center) return
      if (from.x === undefined || from.y === undefined || from.z === undefined) return
      if (to.x === undefined || to.y === undefined || to.z === undefined) return
      if (center.x === undefined || center.y === undefined) return
      
      // Calculate arc parameters
      const startVec = new THREE.Vector2(from.x - center.x, from.y - center.y)
      const endVec = new THREE.Vector2(to.x - center.x, to.y - center.y)
      
      const radius = startVec.length()
      let startAngle = Math.atan2(startVec.y, startVec.x)
      let endAngle = Math.atan2(endVec.y, endVec.x)
      
      // Handle angle wrapping for arcs that cross 0°
      // For counterclockwise (G3), if endAngle < startAngle, add 2π to endAngle
      // For clockwise (G2), if endAngle > startAngle, subtract 2π from endAngle
      if (!clockwise && endAngle < startAngle) {
        endAngle += Math.PI * 2
      } else if (clockwise && endAngle > startAngle) {
        endAngle -= Math.PI * 2
      }
      
      // Create arc curve
      const curve = new THREE.EllipseCurve(
        center.x, center.y,          // center
        radius, radius,               // x radius, y radius
        startAngle, endAngle,         // start angle, end angle
        !clockwise,                   // clockwise (Three.js is opposite)
        0                             // rotation
      )
      
      const points = curve.getPoints(50)  // Increased from 20 for smoother arcs
      const points3D = points.map((p: any) => new THREE.Vector3(p.x, from.z, -p.y))
      
      const geometry = new THREE.BufferGeometry().setFromPoints(points3D)
      const material = new THREE.LineBasicMaterial({ color, linewidth: 2 })
      const line = new THREE.Line(geometry, material)
      
      this.scene.add(line)
      
      // Store line mapping for highlighting
      // NOTE: We store straight-line from/to for arcs since arrows can't follow curves
      // The arrow system will skip rendering for very short effective distances
      if (lineNumber !== undefined) {
        const fromVec = new THREE.Vector3(from.x, from.z, -from.y)
        const toVec = new THREE.Vector3(to.x, to.z, -to.y)
        this.lineSegments.set(lineNumber, {
          line,
          originalColor: color,
          originalLineWidth: 2,
          from: fromVec,
          to: toVec
        })
      }
    },
    
    fitCameraToScene() {
      if (!this.scene || !this.camera || !this.controls) return
      
      // Calculate bounding box of all objects
      const box = new THREE.Box3()
      
      this.scene.traverse((obj: any) => {
        if (obj.type === 'Line' || obj.type === 'LineSegments' || obj.type === 'Mesh') {
          if (obj.name !== 'grid' && obj.name !== 'axes') {
            box.expandByObject(obj)
          }
        }
      })
      
      if (box.isEmpty()) return
      
      const center = box.getCenter(new THREE.Vector3())
      const size = box.getSize(new THREE.Vector3())
      
      const maxDim = Math.max(size.x, size.y, size.z)
      const fov = this.camera.fov * (Math.PI / 180)
      let cameraZ = Math.abs(maxDim / 2 / Math.tan(fov / 2))
      
      cameraZ *= 1.1 // Minimal zoom out for better view (was 1.5)
      
      this.camera.position.set(
        center.x + cameraZ * 0.7,
        center.y + cameraZ * 0.7,
        center.z + cameraZ * 0.7
      )
      
      this.controls.target.copy(center)
      this.controls.update()
    }
  }
})
</script>

<style scoped>
.gcode-viewer-3d {
  position: relative;
  width: 100%;
  height: 100%;
  min-height: 500px;
  border-radius: 4px;
  overflow: hidden;
  background: #263238;
}

canvas {
  display: block;
  width: 100%;
  height: 100%;
  cursor: grab;
}

canvas:active {
  cursor: grabbing;
}

.gcode-annotation {
  position: absolute;
  top: 10px;
  right: 10px;
  background: rgba(0, 0, 0, 0.8);
  color: #FFD700;
  padding: 8px 12px;
  border-radius: 4px;
  font-family: 'Courier New', monospace;
  font-size: 14px;
  font-weight: bold;
  pointer-events: none;
  z-index: 10;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}

.annotation-line-number {
  color: #90CAF9;
  margin-right: 8px;
}

.loading-overlay,
.error-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  background: rgba(38, 50, 56, 0.9);
  color: white;
}

.error-overlay {
  padding: 20px;
}
</style>
