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
  // Arc parameters (only for type: 'arc')
  i?: number  // X offset to arc center
  j?: number  // Y offset to arc center
  clockwise?: boolean  // true for G2, false for G3
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
  clearStockExit: boolean,
  originPosition: string = 'front-left'
): { xMin: number; xMax: number; yMin: number; yMax: number } {
  // Calculate origin offset from stock geometry
  const originOffset = calculateOriginOffset(stockX, stockY, originPosition)
  
  if (clearStockExit) {
    // Exit stock by full diameter + 1mm clearance
    const clearance = toolRadius * 2 + 1
    return {
      xMin: originOffset.x - clearance,
      xMax: originOffset.x + stockX + clearance,
      yMin: originOffset.y - clearance,
      yMax: originOffset.y + stockY + clearance
    }
  } else {
    // Standard tool center compensation
    return {
      xMin: originOffset.x + toolRadius,
      xMax: originOffset.x + stockX - toolRadius,
      yMin: originOffset.y + toolRadius,
      yMax: originOffset.y + stockY - toolRadius
    }
  }
}

/**
 * Calculate origin offset based on origin position
 * Returns the offset from the WCS origin (0,0) to the front-left corner of the stock
 */
export function calculateOriginOffset(
  stockX: number,
  stockY: number,
  originPosition: string
): { x: number; y: number } {
  // Parse origin position to determine X and Y position
  const [yPos, xPos] = originPosition.split('-')
  
  let xOffset = 0
  let yOffset = 0
  
  // Calculate X offset based on horizontal position
  switch (xPos) {
    case 'left':
      xOffset = 0
      break
    case 'center':
      xOffset = -stockX / 2
      break
    case 'right':
      xOffset = -stockX
      break
  }
  
  // Calculate Y offset based on vertical position
  switch (yPos) {
    case 'front':
      yOffset = 0
      break
    case 'center':
      yOffset = -stockY / 2
      break
    case 'back':
      yOffset = -stockY
      break
  }
  
  return { x: xOffset, y: yOffset }
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
 * Clip line segment to circular boundary
 * Returns null if line is entirely outside circle
 * Returns clipped start and end points if line intersects circle
 */
export function clipLineToCircle(
  x1: number,
  y1: number,
  x2: number,
  y2: number,
  centerX: number,
  centerY: number,
  radius: number
): { x1: number; y1: number; x2: number; y2: number } | null {
  // Check if both points are inside
  const dx1 = x1 - centerX
  const dy1 = y1 - centerY
  const dist1 = Math.sqrt(dx1 * dx1 + dy1 * dy1)
  
  const dx2 = x2 - centerX
  const dy2 = y2 - centerY
  const dist2 = Math.sqrt(dx2 * dx2 + dy2 * dy2)
  
  const inside1 = dist1 <= radius
  const inside2 = dist2 <= radius
  
  // Both inside - no clipping needed
  if (inside1 && inside2) {
    return { x1, y1, x2, y2 }
  }
  
  // Both outside - check if line intersects circle
  // Line equation: P = P1 + t * (P2 - P1), where 0 <= t <= 1
  const dx = x2 - x1
  const dy = y2 - y1
  
  // Quadratic formula for circle-line intersection
  const a = dx * dx + dy * dy
  const b = 2 * (dx * dx1 + dy * dy1)
  const c = dx1 * dx1 + dy1 * dy1 - radius * radius
  
  const discriminant = b * b - 4 * a * c
  
  // No intersection
  if (discriminant < 0) {
    return null
  }
  
  // Calculate intersection points
  const sqrtDisc = Math.sqrt(discriminant)
  const t1 = (-b - sqrtDisc) / (2 * a)
  const t2 = (-b + sqrtDisc) / (2 * a)
  
  // Clip to line segment bounds [0, 1]
  const tMin = Math.max(0, Math.min(t1, t2))
  const tMax = Math.min(1, Math.max(t1, t2))
  
  // No intersection within segment
  if (tMin > tMax || tMax < 0 || tMin > 1) {
    return null
  }
  
  // Calculate clipped points
  let clippedX1 = x1
  let clippedY1 = y1
  let clippedX2 = x2
  let clippedY2 = y2
  
  if (!inside1) {
    clippedX1 = x1 + dx * tMin
    clippedY1 = y1 + dy * tMin
  }
  
  if (!inside2) {
    clippedX2 = x1 + dx * tMax
    clippedY2 = y1 + dy * tMax
  }
  
  return { x1: clippedX1, y1: clippedY1, x2: clippedX2, y2: clippedY2 }
}

/**
 * Generate rectilinear pattern toolpath
 */
export function generateRectilinearPattern(
  params: ToolpathGenerationParams
): ToolpathPoint[][] {
  const { stock, cutting, pattern, feeds } = params
  
  // Handle circular stock differently
  const isCircular = stock.shape === 'circular'
  const stockX = isCircular ? stock.diameter || 0 : stock.x || 0
  const stockY = isCircular ? stock.diameter || 0 : stock.y || 0
  const circularRadius = isCircular ? (stock.diameter || 0) / 2 - cutting.toolRadius : 0
  
  const effectiveWidth = calculateEffectiveCuttingWidth(cutting.toolRadius, cutting.stepover)
  const numPasses = calculateNumberOfPasses(stockY, effectiveWidth)
  const boundaries = calculateBoundaries(stockX, stockY, cutting.toolRadius, cutting.clearStockExit, stock.originPosition)
  
  const originOffset = isCircular ? { x: 0, y: 0 } : calculateOriginOffset(stockX, stockY, stock.originPosition)
  const centerX = originOffset.x + stockX / 2
  const centerY = originOffset.y + stockY / 2
  
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
      
      // Clip to circular boundary if needed
      let clippedStart = start
      let clippedEnd = end
      
      if (isCircular) {
        const clipped = clipLineToCircle(start.x, start.y, end.x, end.y, centerX, centerY, circularRadius)
        if (!clipped) {
          // Line is entirely outside circle, skip this pass
          continue
        }
        clippedStart = { x: clipped.x1, y: clipped.y1 }
        clippedEnd = { x: clipped.x2, y: clipped.y2 }
      }
      
      // Add start point (rapid positioning)
      if (levelPasses.length === 0) {
        levelPasses.push({
          x: clippedStart.x,
          y: clippedStart.y,
          z: cutting.zOffset + cutting.safeZHeight,
          feedRate: 0,
          type: 'rapid'
        })
        
        // Plunge to depth
        levelPasses.push({
          x: clippedStart.x,
          y: clippedStart.y,
          z: zLevel.depth,
          feedRate: feeds.z,
          type: 'linear'
        })
      }
      
      // Cutting move
      levelPasses.push({
        x: clippedEnd.x,
        y: clippedEnd.y,
        z: zLevel.depth,
        feedRate: feeds.xy,
        type: 'linear'
      })
      
      // Retract at end of pass
      if (i < numPasses - 1) {
        levelPasses.push({
          x: clippedEnd.x,
          y: clippedEnd.y,
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
  
  // Handle circular stock differently
  const isCircular = stock.shape === 'circular'
  const stockX = isCircular ? stock.diameter || 0 : stock.x || 0
  const stockY = isCircular ? stock.diameter || 0 : stock.y || 0
  const circularRadius = isCircular ? (stock.diameter || 0) / 2 - cutting.toolRadius : 0
  
  const effectiveWidth = calculateEffectiveCuttingWidth(cutting.toolRadius, cutting.stepover)
  const numPasses = calculateNumberOfPasses(stockY, effectiveWidth)
  const boundaries = calculateBoundaries(stockX, stockY, cutting.toolRadius, cutting.clearStockExit, stock.originPosition)
  
  const originOffset = isCircular ? { x: 0, y: 0 } : calculateOriginOffset(stockX, stockY, stock.originPosition)
  const centerX = originOffset.x + stockX / 2
  const centerY = originOffset.y + stockY / 2
  
  const zLevels = calculateZLevels(cutting)
  const allPasses: ToolpathPoint[][] = []
  
  for (const zLevel of zLevels) {
    const levelPasses: ToolpathPoint[] = []
    
    // Start at first position
    const startX = boundaries.xMin
    const startY = boundaries.yMin
    let start = rotatePoint(startX, startY, centerX, centerY, pattern.angle)
    
    // Clip starting position to circle if needed
    if (isCircular) {
      start = clipToCircle(start.x, start.y, centerX, centerY, circularRadius)
    }
    
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
    let currentY = boundaries.yMin
    let prevPoint = start
    
    for (let i = 0; i < numPasses; i++) {
      const yPos = boundaries.yMin + (i * effectiveWidth)
      const clampedY = Math.min(yPos, boundaries.yMax)
      
      const targetX = (i % 2 === 0) ? boundaries.xMax : boundaries.xMin
      
      // Cutting move along X
      let cutPoint = rotatePoint(targetX, clampedY, centerX, centerY, pattern.angle)
      
      // Clip to circular boundary if needed
      if (isCircular) {
        const clipped = clipLineToCircle(prevPoint.x, prevPoint.y, cutPoint.x, cutPoint.y, centerX, centerY, circularRadius)
        if (clipped) {
          cutPoint = { x: clipped.x2, y: clipped.y2 }
        } else {
          // Skip this segment if entirely outside
          continue
        }
      }
      
      levelPasses.push({
        x: cutPoint.x,
        y: cutPoint.y,
        z: zLevel.depth,
        feedRate: feeds.xy,
        type: 'linear'
      })
      
      currentX = targetX
      currentY = clampedY
      prevPoint = cutPoint
      
      // Step over to next pass (if not last pass)
      if (i < numPasses - 1) {
        const nextY = boundaries.yMin + ((i + 1) * effectiveWidth)
        const clampedNextY = Math.min(nextY, boundaries.yMax)
        let stepPoint = rotatePoint(currentX, clampedNextY, centerX, centerY, pattern.angle)
        
        // Clip to circular boundary if needed
        if (isCircular) {
          const clipped = clipLineToCircle(prevPoint.x, prevPoint.y, stepPoint.x, stepPoint.y, centerX, centerY, circularRadius)
          if (clipped) {
            stepPoint = { x: clipped.x2, y: clipped.y2 }
          } else {
            continue
          }
        }
        
        levelPasses.push({
          x: stepPoint.x,
          y: stepPoint.y,
          z: zLevel.depth,
          feedRate: feeds.xy,
          type: 'linear'
        })
        
        prevPoint = stepPoint
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
  let boundaries = calculateBoundaries(stockX, stockY, cutting.toolRadius, cutting.clearStockExit, stock.originPosition)
  
  const originOffset = calculateOriginOffset(stockX, stockY, stock.originPosition)
  const centerX = originOffset.x + stockX / 2
  const centerY = originOffset.y + stockY / 2
  
  const zLevels = calculateZLevels(cutting)
  const allPasses: ToolpathPoint[][] = []
  
  for (const zLevel of zLevels) {
    const levelPasses: ToolpathPoint[] = []
    
    // Reset boundaries for each Z level
    let xMin = boundaries.xMin
    let xMax = boundaries.xMax
    let yMin = boundaries.yMin
    let yMax = boundaries.yMax
    
    // Calculate initial radius to encompass entire rectangular stock
    // For a rectangle, the diagonal from center to corner gives us the radius needed
    // to fully encompass the stock within the spiral
    const halfWidth = (xMax - xMin) / 2
    const halfHeight = (yMax - yMin) / 2
    const initialRadius = Math.sqrt(halfWidth * halfWidth + halfHeight * halfHeight) + cutting.toolRadius
    
    // Start at the outer edge of the spiral at the pattern angle
    const startAngle = pattern.angle * Math.PI / 180
    const startX = centerX + initialRadius * Math.cos(startAngle)
    const startY = centerY + initialRadius * Math.sin(startAngle)
    
    // Rapid to start
    levelPasses.push({
      x: startX,
      y: startY,
      z: cutting.zOffset + cutting.safeZHeight,
      feedRate: 0,
      type: 'rapid'
    })
    
    // Plunge to depth
    levelPasses.push({
      x: startX,
      y: startY,
      z: zLevel.depth,
      feedRate: feeds.z,
      type: 'linear'
    })
    
    // Spiral inward using smooth path
    // For a facing spiral, we create a smooth inward spiral path
    // The radius decreases linearly with angle (Archimedean spiral)
    
    // Number of complete revolutions based on stepover
    const totalInwardDistance = initialRadius - cutting.toolRadius
    const numRevolutions = totalInwardDistance / effectiveWidth
    const totalAngle = numRevolutions * 2 * Math.PI
    
    // Generate spiral path with small angular steps for smooth motion
    // Use 10-degree increments for smooth appearance
    const angleStep = (10 * Math.PI) / 180  // 10 degrees per step
    const numSteps = Math.ceil(totalAngle / angleStep)
    const radiusDecrement = totalInwardDistance / numSteps
    
    let currentAngle = pattern.angle * Math.PI / 180  // Start angle from pattern angle
    let currentRadius = initialRadius
    
    for (let step = 0; step < numSteps; step++) {
      if (currentRadius <= cutting.toolRadius) break
      
      currentAngle += angleStep
      currentRadius -= radiusDecrement
      
      if (currentRadius < cutting.toolRadius) {
        currentRadius = cutting.toolRadius
      }
      
      // Calculate position on spiral
      let x = centerX + currentRadius * Math.cos(currentAngle)
      let y = centerY + currentRadius * Math.sin(currentAngle)
      
      // Clip to rectangular stock boundaries
      // Only include points if they're within or near the stock boundaries
      // Check if point is within expanded boundaries (tool radius + small margin)
      const margin = cutting.toolRadius * 1.5
      const inBounds = x >= (xMin - margin) && x <= (xMax + margin) && 
                       y >= (yMin - margin) && y <= (yMax + margin)
      
      if (inBounds) {
        // Clamp to actual boundaries for tool center
        x = Math.max(xMin, Math.min(xMax, x))
        y = Math.max(yMin, Math.min(yMax, y))
        
        levelPasses.push({
          x,
          y,
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
