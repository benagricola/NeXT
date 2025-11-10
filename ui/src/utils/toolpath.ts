/**
 * Toolpath Generation Utilities
 * 
 * Implements algorithms for generating facing toolpaths for stock preparation.
 * Supports rectangular and circular stock with rectilinear, zigzag, and spiral patterns.
 */

// Types for toolpath generation

export interface ToolpathPoint {
  x: number
  y: number
  z: number
  feedRate: number
  type: 'rapid' | 'linear' | 'arc'
}

export interface StockGeometry {
  shape: 'rectangular' | 'circular'
  x?: number  // For rectangular
  y?: number  // For rectangular
  diameter?: number  // For circular
  originPosition: string
}

export interface CuttingParameters {
  toolRadius: number
  stepover: number  // Percentage or absolute mm
  stepdown: number
  zOffset: number
  totalDepth: number
  safeZHeight: number
  clearStockExit: boolean
  finishingPass: boolean
  finishingPassHeight: number
  finishingPassOffset: number
}

export interface FacingPattern {
  type: 'rectilinear' | 'zigzag' | 'spiral'
  angle: number
  millingDirection: 'climb' | 'conventional'
}

export interface FeedRates {
  xy: number
  z: number
  spindleSpeed: number
}

export interface ToolpathGenerationParams {
  stock: StockGeometry
  cutting: CuttingParameters
  pattern: FacingPattern
  feeds: FeedRates
}

/**
 * Calculate effective cutting width based on stepover
 */
export function calculateEffectiveCuttingWidth(
  toolRadius: number,
  stepover: number
): number {
  return toolRadius * 2 * (stepover / 100)
}

/**
 * Calculate number of passes needed
 */
export function calculateNumberOfPasses(
  stockDimension: number,
  effectiveCuttingWidth: number
): number {
  return Math.ceil(stockDimension / effectiveCuttingWidth)
}

/**
 * Calculate tool-compensated boundaries
 */
export function calculateBoundaries(
  stockX: number,
  stockY: number,
  toolRadius: number,
  clearStockExit: boolean
): { xMin: number; xMax: number; yMin: number; yMax: number } {
  if (clearStockExit) {
    // Exit stock by full diameter + 1mm clearance
    const clearance = toolRadius * 2 + 1
    return {
      xMin: -clearance,
      xMax: stockX + clearance,
      yMin: -clearance,
      yMax: stockY + clearance
    }
  } else {
    // Standard tool center compensation
    return {
      xMin: toolRadius,
      xMax: stockX - toolRadius,
      yMin: toolRadius,
      yMax: stockY - toolRadius
    }
  }
}

/**
 * Apply pattern rotation around stock center
 */
export function rotatePoint(
  x: number,
  y: number,
  centerX: number,
  centerY: number,
  angleDegrees: number
): { x: number; y: number } {
  if (angleDegrees === 0) {
    return { x, y }
  }
  
  const angleRadians = (angleDegrees * Math.PI) / 180
  const cos = Math.cos(angleRadians)
  const sin = Math.sin(angleRadians)
  
  const translatedX = x - centerX
  const translatedY = y - centerY
  
  return {
    x: translatedX * cos - translatedY * sin + centerX,
    y: translatedX * sin + translatedY * cos + centerY
  }
}

/**
 * Clip point to circular boundary
 */
export function clipToCircle(
  x: number,
  y: number,
  centerX: number,
  centerY: number,
  radius: number
): { x: number; y: number } {
  const dx = x - centerX
  const dy = y - centerY
  const distance = Math.sqrt(dx * dx + dy * dy)
  
  if (distance <= radius) {
    return { x, y }
  }
  
  const angle = Math.atan2(dy, dx)
  return {
    x: centerX + radius * Math.cos(angle),
    y: centerY + radius * Math.sin(angle)
  }
}

/**
 * Generate rectilinear pattern toolpath
 */
export function generateRectilinearPattern(
  params: ToolpathGenerationParams
): ToolpathPoint[][] {
  const { stock, cutting, pattern, feeds } = params
  const stockX = stock.x || 0
  const stockY = stock.y || 0
  
  const effectiveWidth = calculateEffectiveCuttingWidth(cutting.toolRadius, cutting.stepover)
  const numPasses = calculateNumberOfPasses(stockY, effectiveWidth)
  const boundaries = calculateBoundaries(stockX, stockY, cutting.toolRadius, cutting.clearStockExit)
  
  const centerX = stockX / 2
  const centerY = stockY / 2
  
  const zLevels = calculateZLevels(cutting)
  const allPasses: ToolpathPoint[][] = []
  
  for (const zLevel of zLevels) {
    const levelPasses: ToolpathPoint[] = []
    
    for (let i = 0; i < numPasses; i++) {
      const yPos = boundaries.yMin + (i * effectiveWidth)
      const clampedY = Math.min(yPos, boundaries.yMax)
      
      let startX: number, endX: number
      
      if (i % 2 === 0) {
        // Even pass: left to right
        startX = boundaries.xMin
        endX = boundaries.xMax
      } else {
        // Odd pass: right to left
        startX = boundaries.xMax
        endX = boundaries.xMin
      }
      
      // Apply rotation
      const start = rotatePoint(startX, clampedY, centerX, centerY, pattern.angle)
      const end = rotatePoint(endX, clampedY, centerX, centerY, pattern.angle)
      
      // Add start point (rapid positioning)
      if (levelPasses.length === 0) {
        levelPasses.push({
          x: start.x,
          y: start.y,
          z: cutting.zOffset + cutting.safeZHeight,
          feedRate: 0,
          type: 'rapid'
        })
        
        // Plunge to depth
        levelPasses.push({
          x: start.x,
          y: start.y,
          z: zLevel.depth,
          feedRate: feeds.z,
          type: 'linear'
        })
      }
      
      // Cutting move
      levelPasses.push({
        x: end.x,
        y: end.y,
        z: zLevel.depth,
        feedRate: feeds.xy,
        type: 'linear'
      })
      
      // Retract at end of pass
      if (i < numPasses - 1) {
        levelPasses.push({
          x: end.x,
          y: end.y,
          z: zLevel.depth + cutting.safeZHeight,
          feedRate: 0,
          type: 'rapid'
        })
      }
    }
    
    // Final retract for this Z level
    if (levelPasses.length > 0) {
      const lastPoint = levelPasses[levelPasses.length - 1]
      levelPasses.push({
        x: lastPoint.x,
        y: lastPoint.y,
        z: zLevel.depth + cutting.safeZHeight,
        feedRate: 0,
        type: 'rapid'
      })
    }
    
    allPasses.push(levelPasses)
  }
  
  return allPasses
}

/**
 * Generate zigzag pattern toolpath (continuous motion)
 */
export function generateZigzagPattern(
  params: ToolpathGenerationParams
): ToolpathPoint[][] {
  const { stock, cutting, pattern, feeds } = params
  const stockX = stock.x || 0
  const stockY = stock.y || 0
  
  const effectiveWidth = calculateEffectiveCuttingWidth(cutting.toolRadius, cutting.stepover)
  const numPasses = calculateNumberOfPasses(stockY, effectiveWidth)
  const boundaries = calculateBoundaries(stockX, stockY, cutting.toolRadius, cutting.clearStockExit)
  
  const centerX = stockX / 2
  const centerY = stockY / 2
  
  const zLevels = calculateZLevels(cutting)
  const allPasses: ToolpathPoint[][] = []
  
  for (const zLevel of zLevels) {
    const levelPasses: ToolpathPoint[] = []
    
    // Start at first position
    const startX = boundaries.xMin
    const startY = boundaries.yMin
    const start = rotatePoint(startX, startY, centerX, centerY, pattern.angle)
    
    // Rapid to start
    levelPasses.push({
      x: start.x,
      y: start.y,
      z: cutting.zOffset + cutting.safeZHeight,
      feedRate: 0,
      type: 'rapid'
    })
    
    // Plunge to depth
    levelPasses.push({
      x: start.x,
      y: start.y,
      z: zLevel.depth,
      feedRate: feeds.z,
      type: 'linear'
    })
    
    let currentX = boundaries.xMin
    
    for (let i = 0; i < numPasses; i++) {
      const yPos = boundaries.yMin + (i * effectiveWidth)
      const clampedY = Math.min(yPos, boundaries.yMax)
      
      const targetX = (i % 2 === 0) ? boundaries.xMax : boundaries.xMin
      
      // Cutting move along X
      const cutPoint = rotatePoint(targetX, clampedY, centerX, centerY, pattern.angle)
      levelPasses.push({
        x: cutPoint.x,
        y: cutPoint.y,
        z: zLevel.depth,
        feedRate: feeds.xy,
        type: 'linear'
      })
      
      currentX = targetX
      
      // Step over to next pass (if not last pass)
      if (i < numPasses - 1) {
        const nextY = boundaries.yMin + ((i + 1) * effectiveWidth)
        const clampedNextY = Math.min(nextY, boundaries.yMax)
        const stepPoint = rotatePoint(currentX, clampedNextY, centerX, centerY, pattern.angle)
        
        levelPasses.push({
          x: stepPoint.x,
          y: stepPoint.y,
          z: zLevel.depth,
          feedRate: feeds.xy,
          type: 'linear'
        })
      }
    }
    
    // Final retract for this Z level
    if (levelPasses.length > 0) {
      const lastPoint = levelPasses[levelPasses.length - 1]
      levelPasses.push({
        x: lastPoint.x,
        y: lastPoint.y,
        z: zLevel.depth + cutting.safeZHeight,
        feedRate: 0,
        type: 'rapid'
      })
    }
    
    allPasses.push(levelPasses)
  }
  
  return allPasses
}

/**
 * Generate spiral pattern toolpath
 */
export function generateSpiralPattern(
  params: ToolpathGenerationParams
): ToolpathPoint[][] {
  const { stock, cutting, pattern, feeds } = params
  const stockX = stock.x || 0
  const stockY = stock.y || 0
  
  const effectiveWidth = calculateEffectiveCuttingWidth(cutting.toolRadius, cutting.stepover)
  let boundaries = calculateBoundaries(stockX, stockY, cutting.toolRadius, cutting.clearStockExit)
  
  const centerX = stockX / 2
  const centerY = stockY / 2
  
  const zLevels = calculateZLevels(cutting)
  const allPasses: ToolpathPoint[][] = []
  
  for (const zLevel of zLevels) {
    const levelPasses: ToolpathPoint[] = []
    
    // Reset boundaries for each Z level
    let xMin = boundaries.xMin
    let xMax = boundaries.xMax
    let yMin = boundaries.yMin
    let yMax = boundaries.yMax
    
    // Start at bottom-left corner
    const start = rotatePoint(xMin, yMin, centerX, centerY, pattern.angle)
    
    // Rapid to start
    levelPasses.push({
      x: start.x,
      y: start.y,
      z: cutting.zOffset + cutting.safeZHeight,
      feedRate: 0,
      type: 'rapid'
    })
    
    // Plunge to depth
    levelPasses.push({
      x: start.x,
      y: start.y,
      z: zLevel.depth,
      feedRate: feeds.z,
      type: 'linear'
    })
    
    // Spiral inward
    while (xMax - xMin > 0 && yMax - yMin > 0) {
      // Right edge (bottom to top)
      const p1 = rotatePoint(xMax, yMin, centerX, centerY, pattern.angle)
      levelPasses.push({
        x: p1.x,
        y: p1.y,
        z: zLevel.depth,
        feedRate: feeds.xy,
        type: 'linear'
      })
      
      // Top edge (right to left)
      const p2 = rotatePoint(xMax, yMax, centerX, centerY, pattern.angle)
      levelPasses.push({
        x: p2.x,
        y: p2.y,
        z: zLevel.depth,
        feedRate: feeds.xy,
        type: 'linear'
      })
      
      // Left edge (top to bottom)
      const p3 = rotatePoint(xMin, yMax, centerX, centerY, pattern.angle)
      levelPasses.push({
        x: p3.x,
        y: p3.y,
        z: zLevel.depth,
        feedRate: feeds.xy,
        type: 'linear'
      })
      
      // Bottom edge (left to right, with offset)
      const nextYMin = yMin + effectiveWidth
      if (nextYMin >= yMax) break
      
      const p4 = rotatePoint(xMin, nextYMin, centerX, centerY, pattern.angle)
      levelPasses.push({
        x: p4.x,
        y: p4.y,
        z: zLevel.depth,
        feedRate: feeds.xy,
        type: 'linear'
      })
      
      // Shrink boundary
      xMin += effectiveWidth
      xMax -= effectiveWidth
      yMin += effectiveWidth
      yMax -= effectiveWidth
      
      if (xMin >= xMax || yMin >= yMax) break
    }
    
    // Final retract for this Z level
    if (levelPasses.length > 0) {
      const lastPoint = levelPasses[levelPasses.length - 1]
      levelPasses.push({
        x: lastPoint.x,
        y: lastPoint.y,
        z: zLevel.depth + cutting.safeZHeight,
        feedRate: 0,
        type: 'rapid'
      })
    }
    
    allPasses.push(levelPasses)
  }
  
  return allPasses
}

/**
 * Calculate Z levels for roughing and finishing passes
 */
export function calculateZLevels(
  cutting: CuttingParameters
): Array<{ depth: number; isFinishing: boolean }> {
  const levels: Array<{ depth: number; isFinishing: boolean }> = []
  
  let roughingDepth = cutting.totalDepth
  
  if (cutting.finishingPass) {
    roughingDepth = cutting.totalDepth - cutting.finishingPassHeight
  }
  
  // Calculate roughing passes
  const numRoughingPasses = Math.ceil(roughingDepth / cutting.stepdown)
  
  for (let i = 0; i < numRoughingPasses; i++) {
    const depth = cutting.zOffset - Math.min((i + 1) * cutting.stepdown, roughingDepth)
    levels.push({ depth, isFinishing: false })
  }
  
  // Add finishing pass if enabled
  if (cutting.finishingPass) {
    const finishDepth = cutting.zOffset - cutting.totalDepth
    levels.push({ depth: finishDepth, isFinishing: true })
  }
  
  return levels
}

/**
 * Generate complete toolpath based on parameters
 */
export function generateToolpath(
  params: ToolpathGenerationParams
): ToolpathPoint[][] {
  switch (params.pattern.type) {
    case 'rectilinear':
      return generateRectilinearPattern(params)
    case 'zigzag':
      return generateZigzagPattern(params)
    case 'spiral':
      return generateSpiralPattern(params)
    default:
      throw new Error(`Unknown pattern type: ${params.pattern.type}`)
  }
}

/**
 * Calculate toolpath statistics
 */
export function calculateToolpathStatistics(
  toolpath: ToolpathPoint[][],
  cutting: CuttingParameters
): {
  totalDistance: number
  estimatedTime: number
  materialRemoved: number
  roughingPasses: number
  finishingPass: boolean
} {
  let totalDistance = 0
  let estimatedTimeSeconds = 0
  
  for (const level of toolpath) {
    for (let i = 1; i < level.length; i++) {
      const prev = level[i - 1]
      const curr = level[i]
      
      const dx = curr.x - prev.x
      const dy = curr.y - prev.y
      const dz = curr.z - prev.z
      const distance = Math.sqrt(dx * dx + dy * dy + dz * dz)
      
      totalDistance += distance
      
      if (curr.feedRate > 0) {
        estimatedTimeSeconds += (distance / curr.feedRate) * 60
      }
    }
  }
  
  const zLevels = calculateZLevels(cutting)
  const roughingPasses = zLevels.filter(l => !l.isFinishing).length
  const finishingPass = zLevels.some(l => l.isFinishing)
  
  // Calculate material removed (simplified - assumes rectangular stock)
  const materialRemoved = 0  // TODO: Calculate based on stock geometry
  
  return {
    totalDistance: Math.round(totalDistance * 10) / 10,
    estimatedTime: Math.round(estimatedTimeSeconds),
    materialRemoved,
    roughingPasses,
    finishingPass
  }
}
