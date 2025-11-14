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
  spiralSegmentsPerRevolution?: number  // Number of line segments per full revolution for spiral patterns
  spiralDirection?: 'outside-in' | 'inside-out'
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
 * Stepover is expressed as a percentage of tool diameter.
 * For example, 25% stepover means tool centers are 25% of diameter apart.
 * Higher stepover = more distance between passes = faster but rougher cut.
 */
export function calculateEffectiveCuttingWidth(
  toolRadius: number,
  stepover: number
): number {
  const toolDiameter = toolRadius * 2
  return toolDiameter * (stepover / 100)
}

/**
 * Calculate number of passes needed
 */
export function calculateNumberOfPasses(
  stockDimension: number,
  effectiveCuttingWidth: number
): number {
  // Ensure we have at least one pass and handle edge cases
  if (effectiveCuttingWidth <= 0 || stockDimension <= 0) {
    return 1
  }
  // At 100% stepover (effectiveWidth = toolDiameter), we still need proper coverage
  const passes = Math.ceil(stockDimension / effectiveCuttingWidth)
  return Math.max(1, passes)
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
  
  // For circular stock, we need to scan across the full diameter.
  // The boundaries should be based on the un-rotated frame.
  const scanDimension = isCircular ? stock.diameter || 0 : stockY;
  const numPasses = calculateNumberOfPasses(scanDimension, effectiveWidth)
  
  const boundaries = calculateBoundaries(stockX, stockY, cutting.toolRadius, cutting.clearStockExit, stock.originPosition)
  
  // For circular stock, center is at origin (0,0). For rectangular, calculate from origin position
  const centerX = isCircular ? 0 : (calculateOriginOffset(stockX, stockY, stock.originPosition).x + stockX / 2)
  const centerY = isCircular ? 0 : (calculateOriginOffset(stockX, stockY, stock.originPosition).y + stockY / 2)
  
  const zLevels = calculateZLevels(cutting)
  const allPasses: ToolpathPoint[][] = []
  
  for (const zLevel of zLevels) {
    const levelPasses: ToolpathPoint[] = []
    
    for (let i = 0; i < numPasses; i++) {
      // Compute un-rotated pass Y position
      const passOffset = isCircular
        ? (-(scanDimension / 2) + i * effectiveWidth + effectiveWidth / 2)
        : (boundaries.yMin + i * effectiveWidth)
      const yRaw = isCircular ? passOffset : Math.min(passOffset, boundaries.yMax)
      
      // Always cut left -> right
      const startXRaw = isCircular ? -circularRadius : boundaries.xMin
      const endXRaw   = isCircular ?  circularRadius : boundaries.xMax
      
      // Rotate
      const startRot = rotatePoint(startXRaw, yRaw, centerX, centerY, pattern.angle)
      const endRot   = rotatePoint(endXRaw,   yRaw, centerX, centerY, pattern.angle)
      
      // Clip for circular
      let finalStart = startRot
      let finalEnd   = endRot
      if (isCircular) {
        const clipped = clipLineToCircle(startRot.x, startRot.y, endRot.x, endRot.y, centerX, centerY, circularRadius)
        if (!clipped) {
          continue
        }
        finalStart = { x: clipped.x1, y: clipped.y1 }
        finalEnd   = { x: clipped.x2, y: clipped.y2 }
      }
      
      // Rapid to start
      levelPasses.push({
        x: finalStart.x,
        y: finalStart.y,
        z: cutting.zOffset + cutting.safeZHeight,
        feedRate: 0,
        type: 'rapid'
      })
      // Plunge
      levelPasses.push({
        x: finalStart.x,
        y: finalStart.y,
        z: zLevel.depth,
        feedRate: feeds.z,
        type: 'linear'
      })
      // Cutting move
      levelPasses.push({
        x: finalEnd.x,
        y: finalEnd.y,
        z: zLevel.depth,
        feedRate: feeds.xy,
        type: 'linear'
      })
      // Retract
      levelPasses.push({
        x: finalEnd.x,
        y: finalEnd.y,
        z: cutting.zOffset + cutting.safeZHeight,
        feedRate: 0,
        type: 'rapid'
      })
      
      // Rapid back to start of next pass (if any)
      if (i < numPasses - 1) {
        const nextPassOffset = isCircular
          ? (-(scanDimension / 2) + (i + 1) * effectiveWidth + effectiveWidth / 2)
          : (boundaries.yMin + (i + 1) * effectiveWidth)
        const nextYRaw = isCircular ? nextPassOffset : Math.min(nextPassOffset, boundaries.yMax)
        
        // For circular stock, we need to find where the next cutting line intersects the circle
        // Rotate the unrotated start/end points, then clip the line to get the entry point
        const nextStartRotUnclipped = rotatePoint(startXRaw, nextYRaw, centerX, centerY, pattern.angle)
        const nextEndRotUnclipped = rotatePoint(endXRaw, nextYRaw, centerX, centerY, pattern.angle)
        
        let nextStart = nextStartRotUnclipped
        if (isCircular) {
          // Clip the full line to find the actual entry point
          const clipped = clipLineToCircle(
            nextStartRotUnclipped.x, nextStartRotUnclipped.y,
            nextEndRotUnclipped.x, nextEndRotUnclipped.y,
            centerX, centerY, circularRadius
          )
          if (clipped) {
            nextStart = { x: clipped.x1, y: clipped.y1 }
          } else {
            // Fallback to point clipping if line is outside (shouldn't happen)
            nextStart = clipToCircle(nextStartRotUnclipped.x, nextStartRotUnclipped.y, centerX, centerY, circularRadius)
          }
        }
        
        levelPasses.push({
          x: nextStart.x,
          y: nextStart.y,
          z: cutting.zOffset + cutting.safeZHeight,
          feedRate: 0,
          type: 'rapid'
        })
      }
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
  const scanDimension = isCircular ? stock.diameter || 0 : stockY;
  const numPasses = calculateNumberOfPasses(scanDimension, effectiveWidth)
  const boundaries = calculateBoundaries(stockX, stockY, cutting.toolRadius, cutting.clearStockExit, stock.originPosition)
  
  // For circular stock, center is at origin (0,0). For rectangular, calculate from origin position
  const centerX = isCircular ? 0 : (calculateOriginOffset(stockX, stockY, stock.originPosition).x + stockX / 2)
  const centerY = isCircular ? 0 : (calculateOriginOffset(stockX, stockY, stock.originPosition).y + stockY / 2)
  
  const zLevels = calculateZLevels(cutting)
  const allPasses: ToolpathPoint[][] = []
  
  for (const zLevel of zLevels) {
    const levelPasses: ToolpathPoint[] = []

    // Determine the starting point for the entire Z-level
    const firstPassOffset = -(scanDimension / 2) + effectiveWidth / 2;
    let startX, startY;
    if (isCircular) {
      startX = -circularRadius;
      startY = firstPassOffset;
    } else {
      startX = boundaries.xMin;
      startY = boundaries.yMin;
    }

    let startPoint = rotatePoint(startX, startY, centerX, centerY, pattern.angle);
    if (isCircular) {
        const clipped = clipLineToCircle(
            rotatePoint(-circularRadius, firstPassOffset, centerX, centerY, pattern.angle).x,
            rotatePoint(-circularRadius, firstPassOffset, centerX, centerY, pattern.angle).y,
            rotatePoint(circularRadius, firstPassOffset, centerX, centerY, pattern.angle).x,
            rotatePoint(circularRadius, firstPassOffset, centerX, centerY, pattern.angle).y,
            centerX, centerY, circularRadius
        );
        if (clipped) {
            startPoint = { x: clipped.x1, y: clipped.y1 };
        } else {
            // Fallback if the first pass is somehow outside
            startPoint = clipToCircle(startPoint.x, startPoint.y, centerX, centerY, circularRadius);
        }
    }
    
    // Rapid to start
    levelPasses.push({
      x: startPoint.x,
      y: startPoint.y,
      z: cutting.zOffset + cutting.safeZHeight,
      feedRate: 0,
      type: 'rapid'
    })
    
    // Plunge to depth
    levelPasses.push({
      x: startPoint.x,
      y: startPoint.y,
      z: zLevel.depth,
      feedRate: feeds.z,
      type: 'linear'
    })
    
    let prevPoint = startPoint
    
    for (let i = 0; i < numPasses; i++) {
      const passOffset = -(scanDimension / 2) + (i * effectiveWidth) + effectiveWidth / 2;
      
      const isReversed = i % 2 !== 0;
      let currentX1, currentX2, currentY;

      if (isCircular) {
          currentY = passOffset;
          currentX1 = -circularRadius;
          currentX2 = circularRadius;
      } else {
          currentY = boundaries.yMin + (i * effectiveWidth);
          currentX1 = boundaries.xMin;
          currentX2 = boundaries.xMax;
      }

      if (isReversed) {
          [currentX1, currentX2] = [currentX2, currentX1];
      }

      // Rotate the target point for the main cutting move
      const targetPoint = rotatePoint(currentX2, currentY, centerX, centerY, pattern.angle);

      // Clip the line segment from the previous point to the target point
      if (isCircular) {
          const clipped = clipLineToCircle(prevPoint.x, prevPoint.y, targetPoint.x, targetPoint.y, centerX, centerY, circularRadius);
          if (clipped) {
              // Add the main cutting move
              levelPasses.push({ x: clipped.x2, y: clipped.y2, z: zLevel.depth, feedRate: feeds.xy, type: 'linear' });
              prevPoint = { x: clipped.x2, y: clipped.y2 };
          }
      } else {
          levelPasses.push({ x: targetPoint.x, y: targetPoint.y, z: zLevel.depth, feedRate: feeds.xy, type: 'linear' });
          prevPoint = targetPoint;
      }
      
      // Step over to the next pass
      if (i < numPasses - 1) {
        const nextPassOffset = -(scanDimension / 2) + ((i + 1) * effectiveWidth) + effectiveWidth / 2;
        let nextY, nextX;

        if (isCircular) {
            nextY = nextPassOffset;
            nextX = isReversed ? circularRadius : -circularRadius;
        } else {
            nextY = boundaries.yMin + ((i + 1) * effectiveWidth);
            nextX = currentX2;
        }

        const stepOverTargetRot = rotatePoint(nextX, nextY, centerX, centerY, pattern.angle);

        if (isCircular) {
          // For circular stock, join passes along the circle edge using an arc
          // Clip to circle to ensure endpoints lie on boundary
          const clippedEnd = clipToCircle(stepOverTargetRot.x, stepOverTargetRot.y, centerX, centerY, circularRadius)
          // Both prevPoint and clippedEnd should lie on circle; create shortest arc between them
          const a1 = Math.atan2(prevPoint.y - centerY, prevPoint.x - centerX)
          const a2 = Math.atan2(clippedEnd.y - centerY, clippedEnd.x - centerX)
          let delta = a2 - a1
          // Normalize to [-PI, PI]
          while (delta > Math.PI) delta -= 2 * Math.PI
          while (delta < -Math.PI) delta += 2 * Math.PI
          const clockwise = delta < 0 // negative delta => clockwise (G2)
          // Center offsets relative to start point (I,J in G-code semantics)
          const iOff = centerX - prevPoint.x
            const jOff = centerY - prevPoint.y
          levelPasses.push({
            x: clippedEnd.x,
            y: clippedEnd.y,
            z: zLevel.depth,
            feedRate: feeds.xy,
            type: 'arc',
            i: iOff,
            j: jOff,
            clockwise
          })
          prevPoint = { x: clippedEnd.x, y: clippedEnd.y }
        } else {
          // Rectangular stock: simple linear step-over
          levelPasses.push({ x: stepOverTargetRot.x, y: stepOverTargetRot.y, z: zLevel.depth, feedRate: feeds.xy, type: 'linear' })
          prevPoint = stepOverTargetRot
        }
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
  
  // Handle both circular and rectangular stock
  const isCircular = stock.shape === 'circular'
  const stockX = isCircular ? stock.diameter || 0 : stock.x || 0
  const stockY = isCircular ? stock.diameter || 0 : stock.y || 0
  
  const effectiveWidth = calculateEffectiveCuttingWidth(cutting.toolRadius, cutting.stepover)
  
  // For circular stock, center is at origin (0,0)
  // For rectangular stock, calculate based on origin position
  const centerX = isCircular ? 0 : (calculateOriginOffset(stockX, stockY, stock.originPosition).x + stockX / 2)
  const centerY = isCircular ? 0 : (calculateOriginOffset(stockX, stockY, stock.originPosition).y + stockY / 2)
  
  const zLevels = calculateZLevels(cutting)
  const allPasses: ToolpathPoint[][] = []
  
  for (const zLevel of zLevels) {
    const levelPasses: ToolpathPoint[] = []
    
    // Use higher resolution for finishing passes (1.5x segments, max 60 segments/rev)
    const segmentsMultiplier = zLevel.isFinishing ? 1.5 : 1
    
    // Determine spiral direction: climb = CCW (positive angle), conventional = CW (negative angle)
    const spiralDirectionMultiplier = pattern.millingDirection === 'climb' ? 1 : -1
    
    // Determine if we're going outside-in or inside-out
    const isOutsideIn = pattern.spiralDirection !== 'inside-out'
    
    // Calculate initial radius based on stock shape
    let outerRadius: number
    let innerRadius: number = cutting.toolRadius
    
    if (isCircular) {
      // For circular stock, outer edge is stock radius minus tool radius
      outerRadius = (stock.diameter || 0) / 2 - cutting.toolRadius
      
      // Add clearance if clear stock exit is enabled
      if (cutting.clearStockExit) {
        outerRadius += cutting.toolRadius * 2 + 1  // Full diameter + 1mm clearance
      }
    } else {
      // For rectangular stock, use diagonal to encompass entire stock
      const boundaries = calculateBoundaries(stockX, stockY, cutting.toolRadius, cutting.clearStockExit, stock.originPosition)
      const halfWidth = (boundaries.xMax - boundaries.xMin) / 2
      const halfHeight = (boundaries.yMax - boundaries.yMin) / 2
      outerRadius = Math.sqrt(halfWidth * halfWidth + halfHeight * halfHeight)
    }
    
    // Set starting radius based on spiral direction
    const initialRadius = isOutsideIn ? outerRadius : innerRadius
    const finalRadius = isOutsideIn ? innerRadius : outerRadius
    
    // Start at the appropriate edge of the spiral at the pattern angle
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
    
    // Generate spiral as a series of line segments
    // Total segments per revolution controlled by spiralSegmentsPerRevolution parameter
    const baseSegments = pattern.spiralSegmentsPerRevolution || 30  // Default to 30 if not specified
    const segmentsPerRevolution = baseSegments * segmentsMultiplier  // 1.5x for finishing passes (max 60)
    const anglePerSegment = spiralDirectionMultiplier * (2 * Math.PI) / segmentsPerRevolution
    const radiusDecrementPerRevolution = effectiveWidth
    const radiusChangePerSegment = (isOutsideIn ? -1 : 1) * radiusDecrementPerRevolution / segmentsPerRevolution
    
    // Number of complete revolutions based on stepover
    const totalRadialDistance = Math.abs(outerRadius - innerRadius)
    const numRevolutions = totalRadialDistance / effectiveWidth
    const totalSegments = Math.floor(numRevolutions * segmentsPerRevolution)
    
    let currentRadius = initialRadius
    let currentAngle = startAngle
    let prevX = startX
    let prevY = startY
    
    for (let seg = 0; seg < totalSegments; seg++) {
      // Calculate next radius
      const nextRadius = currentRadius + radiusChangePerSegment
      
      // Stop if we've reached the final radius (with small tolerance)
      if (isOutsideIn && nextRadius < finalRadius) break
      if (!isOutsideIn && nextRadius > finalRadius) break
      
      // Calculate end angle for this segment
      const endAngle = currentAngle + anglePerSegment
      
      // Calculate endpoint for this line segment
      const endX = centerX + nextRadius * Math.cos(endAngle)
      const endY = centerY + nextRadius * Math.sin(endAngle)
      
      levelPasses.push({
        x: endX,
        y: endY,
        z: zLevel.depth,
        feedRate: feeds.xy,
        type: 'linear'
      })
      
      // Update for next iteration
      currentRadius = nextRadius
      currentAngle = endAngle
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
