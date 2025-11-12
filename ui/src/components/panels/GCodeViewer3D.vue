<template>
  <div class="gcode-viewer-3d">
    <canvas ref="canvas" @mousedown="onCanvasMouseDown"></canvas>
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
      animationFrameId: null as number | null
    }
  },
  
  watch: {
    gcode(newGcode: string) {
      if (this.autoUpdate && newGcode) {
        this.renderGCode()
      }
    }
  },
  
  mounted() {
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
      this.controls.screenSpacePanning = true
      this.controls.minDistance = 10
      this.controls.maxDistance = 1000
      
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
    
    async renderGCode() {
      const THREE = window.THREE
      if (!this.gcode || !this.scene || !THREE) return
      
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
      
      for (const line of lines) {
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
          to: { x, y, z }
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
      const THREE = window.THREE
      if (!this.scene || !THREE) return
      
      const material = new THREE.MeshPhongMaterial({
        color: 0x4CAF50,
        transparent: true,
        opacity: 0.15,
        side: THREE.DoubleSide
      })
      
      let geometry: any
      
      if (stock.type === 'cuboid') {
        const [x, y, z] = stock.dimensions
        geometry = new THREE.BoxGeometry(x, z, y) // Note: Three.js Y is up, G-code Z is up
        const mesh = new THREE.Mesh(geometry, material)
        mesh.position.set(x / 2, z / 2, y / 2)
        this.scene.add(mesh)
        
        // Wireframe
        const edges = new THREE.EdgesGeometry(geometry)
        const lineMaterial = new THREE.LineBasicMaterial({ color: 0x4CAF50, linewidth: 1 })
        const wireframe = new THREE.LineSegments(edges, lineMaterial)
        wireframe.position.copy(mesh.position)
        this.scene.add(wireframe)
      } else if (stock.type === 'cylinder') {
        const [diameter, height] = stock.dimensions
        const radius = diameter / 2
        geometry = new THREE.CylinderGeometry(radius, radius, height, 32)
        const mesh = new THREE.Mesh(geometry, material)
        mesh.position.set(0, height / 2, 0)
        this.scene.add(mesh)
        
        // Wireframe
        const edges = new THREE.EdgesGeometry(geometry)
        const lineMaterial = new THREE.LineBasicMaterial({ color: 0x4CAF50, linewidth: 1 })
        const wireframe = new THREE.LineSegments(edges, lineMaterial)
        wireframe.position.copy(mesh.position)
        this.scene.add(wireframe)
      }
    },
    
    renderToolpaths(toolpaths: any[][]) {
      const THREE = window.THREE
      if (!this.scene || toolpaths.length === 0 || !THREE) return
      
      toolpaths.forEach((level, levelIndex) => {
        // Color gradient from green to blue by depth
        const depthRatio = levelIndex / Math.max(1, toolpaths.length - 1)
        const color = new THREE.Color()
        color.setRGB(
          0.3 - depthRatio * 0.1,  // R: 0.3 -> 0.2
          0.7 - depthRatio * 0.1,  // G: 0.7 -> 0.6
          0.3 + depthRatio * 0.7   // B: 0.3 -> 1.0
        )
        
        level.forEach(segment => {
          if (segment.type === 'rapid') {
            // Rapid moves: dashed gray lines
            this.renderLine(segment.from, segment.to, 0x666666, true)
          } else if (segment.type === 'arc') {
            // Arc moves: curved solid lines
            this.renderArc(segment.from, segment.to, segment.arcCenter, segment.clockwise, color.getHex())
          } else {
            // Linear cutting moves: solid colored lines
            this.renderLine(segment.from, segment.to, color.getHex(), false)
          }
        })
      })
    },
    
    renderLine(from: any, to: any, color: number, dashed: boolean) {
      const THREE = window.THREE
      if (!this.scene || !THREE) return
      
      const points = [
        new THREE.Vector3(from.x, from.z, from.y), // Convert G-code coords to Three.js
        new THREE.Vector3(to.x, to.z, to.y)
      ]
      
      const geometry = new THREE.BufferGeometry().setFromPoints(points)
      const material = dashed
        ? new THREE.LineDashedMaterial({ color, linewidth: 1, dashSize: 2, gapSize: 1 })
        : new THREE.LineBasicMaterial({ color, linewidth: 2 })
      
      const line = new THREE.Line(geometry, material)
      
      if (dashed) {
        line.computeLineDistances()
      }
      
      this.scene.add(line)
    },
    
    renderArc(from: any, to: any, center: any, clockwise: boolean, color: number) {
      const THREE = window.THREE
      if (!this.scene || !THREE) return
      
      // Calculate arc parameters
      const startVec = new THREE.Vector2(from.x - center.x, from.y - center.y)
      const endVec = new THREE.Vector2(to.x - center.x, to.y - center.y)
      
      const radius = startVec.length()
      const startAngle = Math.atan2(startVec.y, startVec.x)
      const endAngle = Math.atan2(endVec.y, endVec.x)
      
      // Create arc curve
      const curve = new THREE.EllipseCurve(
        center.x, center.y,          // center
        radius, radius,               // x radius, y radius
        startAngle, endAngle,         // start angle, end angle
        !clockwise,                   // clockwise (Three.js is opposite)
        0                             // rotation
      )
      
      const points = curve.getPoints(20)
      const points3D = points.map((p: any) => new THREE.Vector3(p.x, from.z, p.y))
      
      const geometry = new THREE.BufferGeometry().setFromPoints(points3D)
      const material = new THREE.LineBasicMaterial({ color, linewidth: 2 })
      const line = new THREE.Line(geometry, material)
      
      this.scene.add(line)
    },
    
    fitCameraToScene() {
      const THREE = window.THREE
      if (!this.scene || !this.camera || !this.controls || !THREE) return
      
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
      
      cameraZ *= 1.5 // Zoom out a bit for better view
      
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
  height: 500px;
  min-height: 400px;
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
