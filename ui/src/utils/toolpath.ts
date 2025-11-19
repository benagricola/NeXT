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
  // Optional text comment to include in generated G-code. Will be emitted as `; comment` line
  comment?: string
  // Arc parameters (only for type: 'arc')
  i?: number  // X offset to arc center
  j?: number  // Y offset to arc center
  clockwise?: boolean  // true for G2, false for G3
}

export interface StockGeometry {
  shape: 'rectangular' | 'circular'
  x?: number  // For rectangular
  y?: number  // For rectangular
  z?: number  // Height (used for both rectangular and circular in viewer)
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
  // Spiral-specific options (kept for future implementation)
  spiralSegmentsPerRevolution?: number  // Number of line segments per full revolution for spiral visual fidelity
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

export interface GenerationOptions {
  shouldAbort?: () => boolean
  onProgress?: (percent: number, message?: string) => void
  onDebug?: (message: string) => void
  disableClipping?: boolean
}

/**
 * Calculate effective cutting width based on stepover
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
  if (effectiveCuttingWidth <= 0 || stockDimension <= 0) return 1
  const passes = Math.ceil(stockDimension / effectiveCuttingWidth)
  return Math.max(1, passes)
}

/**
 * Calculate origin offset based on origin position
 */
export function calculateOriginOffset(
  stockX: number,
  stockY: number,
  originPosition: string
): { x: number; y: number } {
  const [yPos, xPos] = originPosition.split('-')
  let xOffset = 0
  let yOffset = 0
  switch (xPos) {
    case 'center': xOffset = -stockX / 2; break
    case 'right': xOffset = -stockX; break
  }
  switch (yPos) {
    case 'center': yOffset = -stockY / 2; break
    case 'back': yOffset = -stockY; break
  }
  return { x: xOffset, y: yOffset }
}


export function computeSegmentIntersectionCircle(
  x1: number, y1: number, x2: number, y2: number,
  cx: number, cy: number, radius: number
): { x: number; y: number } | null {
  const dx = x2 - x1, dy = y2 - y1;
  const a = dx * dx + dy * dy;
  const b = 2 * (dx * (x1 - cx) + dy * (y1 - cy));
  const c = (x1 - cx) * (x1 - cx) + (y1 - cy) * (y1 - cy) - radius * radius;
  const discriminant = b * b - 4 * a * c;
  if (discriminant < 0) return null;

  const sqrtDisc = Math.sqrt(discriminant);
  const t1 = (-b - sqrtDisc) / (2 * a);
  const t2 = (-b + sqrtDisc) / (2 * a);

  if (t1 >= 0 && t1 <= 1) return { x: x1 + t1 * dx, y: y1 + t1 * dy };
  if (t2 >= 0 && t2 <= 1) return { x: x1 + t2 * dx, y: y1 + t2 * dy };
  return null;
}

export function clipLineToRect(
  x1: number, y1: number, x2: number, y2: number,
  xMin: number, yMin: number, xMax: number, yMax: number
): { x1: number; y1: number; x2: number; y2: number } | null {
  let dx = x2 - x1, dy = y2 - y1;
  let t0 = 0, t1 = 1;
  const p = [-dx, dx, -dy, dy];
  const q = [x1 - xMin, xMax - x1, y1 - yMin, yMax - y1];
  for (let i = 0; i < 4; i++) {
    if (p[i] === 0) {
      if (q[i] < 0) return null;
    } else {
      const r = q[i] / p[i];
      if (p[i] < 0) {
        if (r > t1) return null;
        if (r > t0) t0 = r;
      } else {
        if (r < t0) return null;
        if (r < t1) t1 = r;
      }
    }
  }
  return { x1: x1 + t0 * dx, y1: y1 + t0 * dy, x2: x1 + t1 * dx, y2: y1 + t1 * dy };
}

/**
 * Generate rectilinear pattern toolpath
 */
export async function generateRectilinearPattern(
  params: ToolpathGenerationParams,
  options?: GenerationOptions
): Promise<ToolpathPoint[][]> {
  const { stock, cutting, pattern, feeds } = params;
  const isCircular = stock.shape === 'circular';
  const stockX = isCircular ? stock.diameter || 0 : stock.x || 0;
  const stockY = isCircular ? stock.diameter || 0 : stock.y || 0;

  const effectiveWidth = calculateEffectiveCuttingWidth(cutting.toolRadius, cutting.stepover);
  const originOffset = calculateOriginOffset(stockX, stockY, stock.originPosition);
  const zLevels = calculateZLevels(cutting);
  const allPasses: ToolpathPoint[][] = [];

  for (const zLevel of zLevels) {
    const levelPasses: ToolpathPoint[] = [];
    const toolCenterBoundaries = {
      xMin: originOffset.x + cutting.toolRadius, xMax: originOffset.x + stockX - cutting.toolRadius,
      yMin: originOffset.y + cutting.toolRadius, yMax: originOffset.y + stockY - cutting.toolRadius
    };
    const numPasses = calculateNumberOfPasses(stockY, effectiveWidth);

    for (let i = 0; i < numPasses; i++) {
      const y = toolCenterBoundaries.yMin + i * effectiveWidth;
      const startX = (i % 2 === 0) ? toolCenterBoundaries.xMin : toolCenterBoundaries.xMax;
      const endX = (i % 2 === 0) ? toolCenterBoundaries.xMax : toolCenterBoundaries.xMin;

      levelPasses.push({ x: startX, y, z: cutting.safeZHeight, feedRate: 0, type: 'rapid' });
      levelPasses.push({ x: startX, y, z: zLevel.depth, feedRate: feeds.z, type: 'linear' });
      levelPasses.push({ x: endX, y, z: zLevel.depth, feedRate: feeds.xy, type: 'linear' });
      levelPasses.push({ x: endX, y, z: cutting.safeZHeight, feedRate: 0, type: 'rapid' });
    }
    allPasses.push(normalizeLevelPasses(levelPasses, feeds));
  }
  return allPasses;
}

/**
 * Generate zigzag pattern toolpath
 */
export async function generateZigzagPattern(
  params: ToolpathGenerationParams,
  options?: GenerationOptions
): Promise<ToolpathPoint[][]> {
  const { stock, cutting, pattern, feeds } = params;
  const isCircular = stock.shape === 'circular';
  const stockX = isCircular ? stock.diameter || 0 : stock.x || 0;
  const stockY = isCircular ? stock.diameter || 0 : stock.y || 0;

  const effectiveWidth = calculateEffectiveCuttingWidth(cutting.toolRadius, cutting.stepover);
  const originOffset = calculateOriginOffset(stockX, stockY, stock.originPosition);
  const zLevels = calculateZLevels(cutting);
  const allPasses: ToolpathPoint[][] = [];

  for (const zLevel of zLevels) {
    const levelPasses: ToolpathPoint[] = [];
    const toolCenterBoundaries = {
      xMin: originOffset.x + cutting.toolRadius, xMax: originOffset.x + stockX - cutting.toolRadius,
      yMin: originOffset.y + cutting.toolRadius, yMax: originOffset.y + stockY - cutting.toolRadius
    };
    const numPasses = calculateNumberOfPasses(stockY, effectiveWidth);

    let startX = toolCenterBoundaries.xMin;
    let startY = toolCenterBoundaries.yMin;

    levelPasses.push({ x: startX, y: startY, z: cutting.safeZHeight, feedRate: 0, type: 'rapid' });
    levelPasses.push({ x: startX, y: startY, z: zLevel.depth, feedRate: feeds.z, type: 'linear' });

    for (let i = 0; i < numPasses; i++) {
      const y = toolCenterBoundaries.yMin + i * effectiveWidth;
      const endX = (i % 2 === 0) ? toolCenterBoundaries.xMax : toolCenterBoundaries.xMin;
      levelPasses.push({ x: endX, y, z: zLevel.depth, feedRate: feeds.xy, type: 'linear' });

      if (i < numPasses - 1) {
        const nextY = y + effectiveWidth;
        levelPasses.push({ x: endX, y: nextY, z: zLevel.depth, feedRate: feeds.xy, type: 'linear' });
      }
    }
    const lastPoint = levelPasses[levelPasses.length - 1];
    if (lastPoint) {
      levelPasses.push({ x: lastPoint.x, y: lastPoint.y, z: cutting.safeZHeight, feedRate: 0, type: 'rapid' });
    }
    allPasses.push(normalizeLevelPasses(levelPasses, feeds));
  }
  return allPasses;
}


// =================================================================================
// START: New Spiral Generation Implementation
// =================================================================================

type EffectiveBoundary = {
  isCircular: boolean;
  xMin: number; xMax: number; yMin: number; yMax: number;
  radius: number; centerX: number; centerY: number;
};
type Corner = 'top-left' | 'top-right' | 'bottom-right' | 'bottom-left';
type Side = 'top' | 'bottom' | 'left' | 'right';

function getCornerCoords(corner: Corner, boundary: EffectiveBoundary): { x: number, y: number } {
  switch (corner) {
    case 'top-left': return { x: boundary.xMin, y: boundary.yMax };
    case 'top-right': return { x: boundary.xMax, y: boundary.yMax };
    case 'bottom-right': return { x: boundary.xMax, y: boundary.yMin };
    case 'bottom-left': return { x: boundary.xMin, y: boundary.yMin };
  }
}

function getLineIntersection(radius: number, lineVal: number, isHorizontal: boolean, centerX: number, centerY: number, pickPositiveRoot: boolean): { x: number, y: number } | null {
  const rSq = radius * radius;
  if (isHorizontal) {
    const dy = lineVal - centerY;
    if (dy * dy > rSq) {
      console.log(`Failed getLineIntersection (H): dy^2 (${(dy * dy).toFixed(2)}) > r^2 (${rSq.toFixed(2)})`);
      return null;
    }
    const dx_abs = Math.sqrt(rSq - dy * dy);
    const x = centerX + dx_abs * (pickPositiveRoot ? 1 : -1);
    return { x, y: lineVal };
  } else {
    const dx = lineVal - centerX;
    if (dx * dx > rSq) {
      console.log(`Failed getLineIntersection (V): dx^2 (${(dx * dx).toFixed(2)}) > r^2 (${rSq.toFixed(2)})`);
      return null;
    }
    const dy_abs = Math.sqrt(rSq - dx * dx);
    const y = centerY + dy_abs * (pickPositiveRoot ? 1 : -1);
    return { x: lineVal, y };
  }
}


function calculateCornerArc(radius: number, corner: Corner, boundary: EffectiveBoundary, millingDirection: number): { start: { x: number, y: number }, end: { x: number, y: number } } | null {
  const { centerX, centerY, xMin, xMax, yMin, yMax } = boundary;
  let p1: { x: number, y: number } | null = null;
  let p2: { x: number, y: number } | null = null;

  switch (corner) {
    case 'top-left':
      p1 = getLineIntersection(radius, yMax, true, centerX, centerY, false);
      p2 = getLineIntersection(radius, xMin, false, centerX, centerY, true);
      break;
    case 'top-right':
      p1 = getLineIntersection(radius, xMax, false, centerX, centerY, true);
      p2 = getLineIntersection(radius, yMax, true, centerX, centerY, true);
      break;
    case 'bottom-right':
      p1 = getLineIntersection(radius, yMin, true, centerX, centerY, true);
      p2 = getLineIntersection(radius, xMax, false, centerX, centerY, false);
      break;
    case 'bottom-left':
      p1 = getLineIntersection(radius, xMin, false, centerX, centerY, false);
      p2 = getLineIntersection(radius, yMin, true, centerX, centerY, false);
      break;
  }

  if (!p1 || !p2) return null;

  return millingDirection === 1 ? { start: p1, end: p2 } : { start: p2, end: p1 };
}

function calculateSideArc(radius: number, side: Side, boundary: EffectiveBoundary, millingDirection: number): { start: { x: number, y: number }, end: { x: number, y: number } } | null {
  const { centerX, centerY, xMin, xMax, yMin, yMax } = boundary;
  let p1: { x: number, y: number } | null = null;
  let p2: { x: number, y: number } | null = null;

  console.log(`Calculating side arc for side: ${side}, radius: ${radius}`);

  // When peeling a side (e.g., Left), we are cutting an arc that is bounded by the *adjacent* sides (Top/Bottom).
  // The circle of 'radius' is smaller than the side we are peeling (e.g. radius < abs(xMin)),
  // so it intersects the perpendicular boundaries.

  switch (side) {
    case 'top': // Peeling Top (reducing Y), bounded by Left/Right (xMin/xMax)
      p1 = getLineIntersection(radius, xMax, false, centerX, centerY, true); // Top-Right
      p2 = getLineIntersection(radius, xMin, false, centerX, centerY, true); // Top-Left
      break;
    case 'bottom': // Peeling Bottom (reducing Y), bounded by Left/Right (xMin/xMax)
      p1 = getLineIntersection(radius, xMin, false, centerX, centerY, false); // Bottom-Left
      p2 = getLineIntersection(radius, xMax, false, centerX, centerY, false); // Bottom-Right
      break;
    case 'left': // Peeling Left (reducing X), bounded by Top/Bottom (yMax/yMin)
      p1 = getLineIntersection(radius, yMax, true, centerX, centerY, false); // Top-Left
      p2 = getLineIntersection(radius, yMin, true, centerX, centerY, false); // Bottom-Left
      break;
    case 'right': // Peeling Right (reducing X), bounded by Top/Bottom (yMax/yMin)
      p1 = getLineIntersection(radius, yMin, true, centerX, centerY, true); // Bottom-Right
      p2 = getLineIntersection(radius, yMax, true, centerX, centerY, true); // Top-Right
      break;
  }
  if (!p1 || !p2) {
    console.log(` -> Failed to calculate p1 or p2 for side ${side}`);
    return null;
  }

  console.log(` -> Success for side ${side}. p1: (${p1.x.toFixed(2)}, ${p1.y.toFixed(2)}), p2: (${p2.x.toFixed(2)}, ${p2.y.toFixed(2)})`);
  return millingDirection === 1 ? { start: p1, end: p2 } : { start: p2, end: p1 };
}

function getDogLegMove(from: { x: number, y: number }, to: { x: number, y: number }, centerX: number, centerY: number): { x: number, y: number }[] {
  const pA = { x: from.x, y: to.y };
  const pB = { x: to.x, y: from.y };

  const distA = Math.hypot(pA.x - centerX, pA.y - centerY);
  const distB = Math.hypot(pB.x - centerX, pB.y - centerY);

  const intermediate = distA > distB ? pA : pB;

  const moves = [];
  if (Math.hypot(intermediate.x - from.x, intermediate.y - from.y) > 1e-6) {
    moves.push(intermediate);
  }
  if (Math.hypot(to.x - intermediate.x, to.y - intermediate.y) > 1e-6) {
    moves.push(to);
  }
  return moves.length > 0 ? moves : [to];
}

export async function generateSpiralPattern(
  params: ToolpathGenerationParams,
  options?: GenerationOptions
): Promise<ToolpathPoint[][]> {
  const { stock, cutting, pattern, feeds } = params;
  const shouldAbort = options?.shouldAbort ?? (() => false);

  const isCircular = stock.shape === 'circular';
  const stockX = isCircular ? stock.diameter || 0 : stock.x || 0;
  const stockY = isCircular ? stock.diameter || 0 : stock.y || 0;
  const effectiveWidth = calculateEffectiveCuttingWidth(cutting.toolRadius, cutting.stepover);
  const tolerance = 1.0;

  const originOffset = calculateOriginOffset(stockX, stockY, stock.originPosition);
  const centerX = isCircular ? 0 : originOffset.x + stockX / 2;
  const centerY = isCircular ? 0 : originOffset.y + stockY / 2;

  const effectiveBoundary: EffectiveBoundary = {
    isCircular,
    xMin: originOffset.x - cutting.toolRadius - tolerance,
    xMax: originOffset.x + stockX + cutting.toolRadius + tolerance,
    yMin: originOffset.y - cutting.toolRadius - tolerance,
    yMax: originOffset.y + stockY + cutting.toolRadius + tolerance,
    radius: isCircular ? (stock.diameter! / 2) + cutting.toolRadius + tolerance : 0,
    centerX,
    centerY,
  };

  const stockBoundary: EffectiveBoundary = {
    isCircular,
    xMin: originOffset.x, xMax: originOffset.x + stockX,
    yMin: originOffset.y, yMax: originOffset.y + stockY,
    radius: isCircular ? stock.diameter! / 2 : 0,
    centerX, centerY
  };

  const zLevels = calculateZLevels(cutting);
  const allPasses: ToolpathPoint[][] = [];

  const spiralDirection = pattern.spiralDirection || 'inside-out';
  if (spiralDirection === 'inside-out') {
    console.log("Inside-out spiral is not implemented in this version.");
    return [];
  }
  const millingDirection = pattern.millingDirection === 'climb' ? 1 : -1;

  // Helper to calculate side arc even if it doesn't intersect boundaries (returns semi-circle)
  const getRobustSideArc = (radius: number, side: Side): { start: { x: number, y: number }, end: { x: number, y: number } } => {
    const arc = calculateSideArc(radius, side, effectiveBoundary, millingDirection);
    if (arc) return arc;

    // Fallback for deep peeling (semi-circles)
    let p1 = { x: 0, y: 0 }, p2 = { x: 0, y: 0 };
    switch (side) {
      case 'left': // Left semi-circle: Top(0,r) to Bottom(0,-r)
        p1 = { x: centerX, y: centerY + radius };
        p2 = { x: centerX, y: centerY - radius };
        // CW (millingDir -1): Bottom -> Top. CCW (1): Top -> Bottom.
        return millingDirection === 1 ? { start: p1, end: p2 } : { start: p2, end: p1 };
      case 'right': // Right semi-circle
        p1 = { x: centerX, y: centerY + radius };
        p2 = { x: centerX, y: centerY - radius };
        // CW: Top -> Bottom. CCW: Bottom -> Top.
        return millingDirection === 1 ? { start: p2, end: p1 } : { start: p1, end: p2 };
      case 'top': // Top semi-circle
        p1 = { x: centerX - radius, y: centerY };
        p2 = { x: centerX + radius, y: centerY };
        // CW: Left -> Right. CCW: Right -> Left.
        return millingDirection === 1 ? { start: p2, end: p1 } : { start: p1, end: p2 };
      case 'bottom': // Bottom semi-circle
        p1 = { x: centerX - radius, y: centerY };
        p2 = { x: centerX + radius, y: centerY };
        // CW: Right -> Left. CCW: Left -> Right.
        return millingDirection === 1 ? { start: p1, end: p2 } : { start: p2, end: p1 };
    }
    return { start: p1, end: p2 }; // Should not happen
  };

  for (const zLevel of zLevels) {
    if (shouldAbort()) return allPasses;

    const levelPasses: ToolpathPoint[] = [];
    const currentZ = zLevel.depth;
    const append = (p: ToolpathPoint) => {
      const last = levelPasses.length > 0 ? levelPasses[levelPasses.length - 1] : null;
      // Fix: Check for Z change as well. If XY is same but Z is different, we MUST append.
      if (!last || Math.hypot(p.x - last.x, p.y - last.y) > 1e-6 || Math.abs(p.z - last.z) > 1e-6) {
        levelPasses.push(p);
      }
    };

    // Define Sequence
    type Task = { type: 'corner', id: Corner } | { type: 'side', id: Side } | { type: 'spiral' };
    const queue: Task[] = [];

    if (isCircular) {
      queue.push({ type: 'spiral' });
    } else {
      // Smart Sequence: Peel sides that are outside the central spiral
      // The spiral starts at radius = min(stockX, stockY)/2, touching the closest sides.
      // We only need to peel the sides that are further away.

      if (stockX > stockY) {
        // Landscape: Spiral touches Top/Bottom. Peel Left and Right.

        // Group 1: Left Side
        queue.push({ type: 'corner', id: 'top-left' });
        queue.push({ type: 'corner', id: 'bottom-left' });
        queue.push({ type: 'side', id: 'left' });

        // Group 2: Right Side
        queue.push({ type: 'corner', id: 'top-right' });
        queue.push({ type: 'corner', id: 'bottom-right' });
        queue.push({ type: 'side', id: 'right' });
      } else if (stockY > stockX) {
        // Portrait: Spiral touches Left/Right. Peel Top and Bottom.

        // Group 1: Top Side
        queue.push({ type: 'corner', id: 'top-left' });
        queue.push({ type: 'corner', id: 'top-right' });
        queue.push({ type: 'side', id: 'top' });

        // Group 2: Bottom Side
        queue.push({ type: 'corner', id: 'bottom-left' });
        queue.push({ type: 'corner', id: 'bottom-right' });
        queue.push({ type: 'side', id: 'bottom' });
      } else {
        // Square: Spiral touches all 4 sides. Just peel corners.
        queue.push({ type: 'corner', id: 'top-left' });
        queue.push({ type: 'corner', id: 'top-right' });
        queue.push({ type: 'corner', id: 'bottom-right' });
        queue.push({ type: 'corner', id: 'bottom-left' });
      }

      queue.push({ type: 'spiral' });
    }

    // Initial Rapid
    let startX = centerX, startY = centerY;
    if (!isCircular && queue.length > 0 && queue[0].type === 'corner') {
      const c = getCornerCoords((queue[0] as any).id, stockBoundary);
      const dirX = Math.sign(c.x - centerX);
      const dirY = Math.sign(c.y - centerY);
      startX = c.x + (cutting.toolRadius + tolerance) * dirX;
      startY = c.y + (cutting.toolRadius + tolerance) * dirY;
    } else if (isCircular) {
      startX = centerX + (stock.diameter! / 2 + cutting.toolRadius + tolerance);
      startY = centerY;
    }
    append({ x: startX, y: startY, z: cutting.safeZHeight, feedRate: 0, type: 'rapid', comment: 'Initial Rapid to Safe Z' });
    append({ x: startX, y: startY, z: currentZ, feedRate: 0, type: 'rapid', comment: 'Initial Rapid to Cut Z' });

    let currentRadius = 0; // Track radius for spiral transition

    // Helper for safe rapid moves (Z-lift)
    const rapidTo = (target: { x: number, y: number }, comment?: string) => {
      const last = levelPasses.length > 0 ? levelPasses[levelPasses.length - 1] : { x: startX, y: startY, z: currentZ };

      // If we are very close, just slide
      if (Math.hypot(target.x - last.x, target.y - last.y) < 0.01) return;

      // Retract to Safe Z
      append({ x: last.x, y: last.y, z: cutting.safeZHeight, feedRate: 0, type: 'rapid', comment: `Retract for ${comment || 'rapid'}` });
      // Move to Target XY
      append({ x: target.x, y: target.y, z: cutting.safeZHeight, feedRate: 0, type: 'rapid', comment: `Move to ${comment || 'target'}` });
      // Plunge to Cut Z
      append({ x: target.x, y: target.y, z: currentZ, feedRate: feeds.z, type: 'linear', comment: `Plunge for ${comment || 'cut'}` }); // Plunge is linear G1
    };

    for (const task of queue) {
      if (shouldAbort()) return allPasses;

      if (task.type === 'corner') {
        const corner = task.id as Corner;
        console.log(`Processing Corner: ${corner}`);
        const cornerPos = getCornerCoords(corner, stockBoundary);
        const maxR = Math.hypot(cornerPos.x - centerX, cornerPos.y - centerY) + effectiveWidth;

        let peelRadius = maxR;
        while (true) {
          // 1. Calculate arc
          const arc = calculateCornerArc(peelRadius, corner, effectiveBoundary, millingDirection);
          if (!arc) { break; }

          // 2. Move to start (DogLeg for Corners at Current Z - Keep Tool Down)
          const lastPoint = levelPasses[levelPasses.length - 1];
          // We assume we are already at currentZ from previous cut or initial plunge.
          // If not (e.g. first move), we might need to plunge.
          if (Math.abs(lastPoint.z - currentZ) > 1e-3) {
            // Should have been handled by initial rapid or previous rapidTo
            append({ x: lastPoint.x, y: lastPoint.y, z: currentZ, feedRate: feeds.z, type: 'linear', comment: 'Plunge for corner peel' });
          }

          getDogLegMove(lastPoint, arc.start, centerX, centerY).forEach(p => append({ ...p, z: currentZ, feedRate: 0, type: 'rapid', comment: `DogLeg to ${corner}` }));

          // 3. Cut
          // We are at arc.start at currentZ.
          append({ ...arc.end, z: currentZ, feedRate: feeds.xy, type: 'arc', i: centerX - arc.start.x, j: centerY - arc.start.y, clockwise: millingDirection === -1, comment: `Corner Peel ${corner}` });

          // 4. Check completion
          const radiusForDecision = peelRadius - cutting.toolRadius;
          if (!calculateCornerArc(radiusForDecision, corner, stockBoundary, millingDirection)) {
            break;
          }
          peelRadius -= effectiveWidth;
        }
      }
      else if (task.type === 'side') {
        const side = task.id as Side;
        console.log(`Processing Side: ${side}`);

        let sideStartRadius = 0;
        if (side === 'left' || side === 'right') sideStartRadius = stockX / 2 + cutting.toolRadius + tolerance;
        else sideStartRadius = stockY / 2 + cutting.toolRadius + tolerance;

        let peelRadius = sideStartRadius;
        const minStockDim = Math.min(stockX, stockY);
        const stopRadius = (minStockDim / 2) - (2 * cutting.toolRadius);

        while (peelRadius > stopRadius) {
          const arc = getRobustSideArc(peelRadius, side);

          // Move to start (Z-lift for Sides)
          rapidTo(arc.start, `Side Peel ${side}`);

          // Split arc into two segments to avoid viewer issues with vertical chords or large arcs
          // Calculate midpoint angle
          const startAngle = Math.atan2(arc.start.y - centerY, arc.start.x - centerX);
          let endAngle = Math.atan2(arc.end.y - centerY, arc.end.x - centerX);

          // Adjust endAngle for direction
          const isClockwise = millingDirection === -1;
          if (!isClockwise && endAngle < startAngle) endAngle += 2 * Math.PI; // CCW
          if (isClockwise && endAngle > startAngle) endAngle -= 2 * Math.PI; // CW

          const midAngle = (startAngle + endAngle) / 2;
          const midPoint = {
            x: centerX + peelRadius * Math.cos(midAngle),
            y: centerY + peelRadius * Math.sin(midAngle)
          };

          // Segment 1: Start -> Mid
          append({ ...midPoint, z: currentZ, feedRate: feeds.xy, type: 'arc', i: centerX - arc.start.x, j: centerY - arc.start.y, clockwise: isClockwise, comment: `Side Peel ${side} Seg 1` });

          // Segment 2: Mid -> End
          append({ ...arc.end, z: currentZ, feedRate: feeds.xy, type: 'arc', i: centerX - midPoint.x, j: centerY - midPoint.y, clockwise: isClockwise, comment: `Side Peel ${side} Seg 2` });

          peelRadius -= effectiveWidth;
        }
        currentRadius = peelRadius; // Update for spiral
      }
      else if (task.type === 'spiral') {
        console.log("Processing Spiral");

        let engageRadius = 0;
        let engageAngle = 0;
        let startPoint = { x: 0, y: 0 };

        if (isCircular) {
          engageRadius = (stock.diameter! / 2 + cutting.toolRadius + tolerance);
          engageAngle = 0; // Arbitrary start for circle
          startPoint = { x: centerX + engageRadius, y: centerY };
        } else {
          // Join smoothly from the last point
          if (levelPasses.length > 0) {
            const lastPoint = levelPasses[levelPasses.length - 1];
            engageRadius = Math.hypot(lastPoint.x - centerX, lastPoint.y - centerY);
            engageAngle = Math.atan2(lastPoint.y - centerY, lastPoint.x - centerX);
            startPoint = lastPoint;
          } else {
            engageRadius = Math.min(stockX, stockY) / 2;
            engageAngle = 0;
            startPoint = { x: centerX + engageRadius, y: centerY };
          }
        }

        // If we are not at the start point (e.g. circular start), rapid there (Z-lift safe)
        const last = levelPasses.length > 0 ? levelPasses[levelPasses.length - 1] : { x: startX, y: startY };
        if (Math.hypot(startPoint.x - last.x, startPoint.y - last.y) > 0.01) {
          rapidTo(startPoint, 'Spiral Start');
        }

        // Ensure we have a point at the start of the spiral
        append({ x: startPoint.x, y: startPoint.y, z: currentZ, feedRate: feeds.xy, type: 'linear', comment: 'Spiral Start Point' });

        const finalRadius = cutting.toolRadius;
        const totalRadialDistance = engageRadius - finalRadius;

        if (totalRadialDistance > 0) {
          const revolutions = totalRadialDistance / effectiveWidth;
          const segments = Math.max(36, Math.ceil(revolutions * 36));
          const angleStep = (revolutions * 2 * Math.PI) / segments * millingDirection;
          const radiusStep = totalRadialDistance / segments;

          let spiralRadius = engageRadius;
          let spiralAngle = engageAngle;

          for (let i = 0; i < segments; i++) {
            spiralAngle += angleStep;
            spiralRadius -= radiusStep;
            const nextX = centerX + spiralRadius * Math.cos(spiralAngle);
            const nextY = centerY + spiralRadius * Math.sin(spiralAngle);
            append({ x: nextX, y: nextY, z: currentZ, feedRate: feeds.xy, type: 'linear' });
          }
        }

        // Center cleanout circle
        append({ x: centerX + finalRadius * Math.cos(0), y: centerY + finalRadius * Math.sin(0), z: currentZ, feedRate: feeds.xy, type: 'linear', comment: 'Center Cleanout Start' });
        append({ x: centerX - finalRadius, y: centerY, z: currentZ, feedRate: feeds.xy, type: 'arc', i: -finalRadius, j: 0, clockwise: millingDirection === -1, comment: 'Center Cleanout 1' });
        append({ x: centerX + finalRadius, y: centerY, z: currentZ, feedRate: feeds.xy, type: 'arc', i: finalRadius, j: 0, clockwise: millingDirection === -1, comment: 'Center Cleanout 2' });
      }
    }

    const lastP = levelPasses[levelPasses.length - 1];
    if (lastP) {
      append({ x: lastP.x, y: lastP.y, z: cutting.safeZHeight, feedRate: 0, type: 'rapid' });
    }
    allPasses.push(normalizeLevelPasses(levelPasses, feeds));
  }
  return allPasses;
}

// =================================================================================
// END: New Spiral Generation Implementation
// =================================================================================


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

  const numRoughingPasses = Math.ceil(roughingDepth / cutting.stepdown)

  for (let i = 0; i < numRoughingPasses; i++) {
    const depth = cutting.zOffset - Math.min((i + 1) * cutting.stepdown, roughingDepth)
    levels.push({ depth, isFinishing: false })
  }

  if (cutting.finishingPass) {
    const finishDepth = cutting.zOffset - cutting.totalDepth
    levels.push({ depth: finishDepth, isFinishing: true })
  }

  return levels
}

/**
 * Normalize a level's moves to avoid combined XY+Z in a single command.
 */
export function normalizeLevelPasses(levelPasses: ToolpathPoint[], defaultFeeds?: FeedRates): ToolpathPoint[] {
  const normalized: ToolpathPoint[] = []
  for (const p of levelPasses) {
    const prev = normalized[normalized.length - 1]
    if (!prev) {
      normalized.push(p)
      continue
    }
    if ((prev.x !== p.x || prev.y !== p.y) && prev.z !== p.z) {
      if (p.z > prev.z) {
        normalized.push({ x: prev.x, y: prev.y, z: p.z, feedRate: 0, type: 'rapid' })
        normalized.push({ x: p.x, y: p.y, z: p.z, feedRate: 0, type: 'rapid' })
      } else {
        normalized.push({ x: p.x, y: p.y, z: prev.z, feedRate: 0, type: 'rapid' })
        normalized.push({ x: p.x, y: p.y, z: p.z, feedRate: p.feedRate || (defaultFeeds?.z ?? 0), type: 'linear' })
      }
    } else {
      normalized.push(p)
    }
  }
  return normalized
}

/**
 * Generate complete toolpath based on parameters
 */
export async function generateToolpath(
  params: ToolpathGenerationParams,
  options?: GenerationOptions
): Promise<ToolpathPoint[][]> {
  let toolpath: ToolpathPoint[][]
  switch (params.pattern.type) {
    case 'rectilinear':
      toolpath = await generateRectilinearPattern(params, options)
      break
    case 'zigzag':
      toolpath = await generateZigzagPattern(params, options)
      break
    case 'spiral':
      toolpath = await generateSpiralPattern(params, options)
      break
    default:
      throw new Error(`Unsupported facing pattern: ${params.pattern.type}`)
  }
  return toolpath;
}

export function detectCombinedXYZMoves(toolpath: ToolpathPoint[][]): Array<{ level: number; index: number; prev: ToolpathPoint | null; curr: ToolpathPoint }> { return []; }
export function detectVerticalLinearRetracts(toolpath: ToolpathPoint[][]): Array<{ level: number; index: number; prev: ToolpathPoint | null; curr: ToolpathPoint }> { return []; }
export function detectXYLinearAtSafeZ(toolpath: ToolpathPoint[][], safeZ: number): Array<{ level: number; index: number; prev: ToolpathPoint | null; curr: ToolpathPoint }> { return []; }

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
  // Dummy implementation
  return {
    totalDistance: 0,
    estimatedTime: 0,
    materialRemoved: 0,
    roughingPasses: 0,
    finishingPass: false
  }
}