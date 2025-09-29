; G6503.g: RECTANGLE BLOCK PROBE
;
; Probes all 4 edges of a rectangular block from the outside to find the center point.
; Uses single-axis probing for each edge and calculates the geometric center.
;
; USAGE: G6503 W<width> H<height> L<depth> [F<speed>] [R<retries>] [C<clearance>] [O<overtravel>]
;
; Parameters:
;   W: Block width in X direction - REQUIRED
;   H: Block height in Y direction - REQUIRED
;   L: Depth to move down before probing - REQUIRED
;   F: Optional speed override in mm/min
;   R: Number of retries for averaging per probe point
;   C: Clearance distance from block edges for approach (default: 5mm)
;   O: Overtravel distance beyond expected surfaces (default: 2mm)
;
; The block center coordinates are logged to nxtProbeResults table.

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and configured
if { !global.nxtFeatureTouchProbe }
    abort { "G6503: Touch probe feature not enabled" }

if { global.nxtTouchProbeID == null }
    abort { "G6503: Touch probe ID not configured" }

; Ensure we're using the touch probe
if { state.currentTool != global.nxtProbeToolID }
    abort { "G6503: Touch probe (T" ^ global.nxtProbeToolID ^ ") must be selected" }

; Validate required parameters
if { !exists(param.W) || !exists(param.H) || !exists(param.L) }
    abort { "G6503: Width (W), Height (H), and Depth (L) parameters are required" }

; Set parameters
var feedRate = { exists(param.F) ? param.F : null }
var retries = { exists(param.R) ? param.R : null }
var blockWidth = { param.W }
var blockHeight = { param.H }
var probeDepth = { param.L }
var clearance = { exists(param.C) ? param.C : 5.0 }
var overtravel = { exists(param.O) ? param.O : 2.0 }

echo "G6503: Starting rectangle block probe cycle"

; Get current position (should be approximately at block center)
M5000
var centerX = { global.nxtAbsPos[0] }
var centerY = { global.nxtAbsPos[1] }
var startZ = { global.nxtAbsPos[2] }

; Calculate approach and probe distances
var xApproachDistance = { var.blockWidth / 2 + var.clearance }
var yApproachDistance = { var.blockHeight / 2 + var.clearance }
var xProbeTarget = { var.blockWidth / 2 + var.overtravel }
var yProbeTarget = { var.blockHeight / 2 + var.overtravel }

echo "G6503: Probing rectangular block " ^ var.blockWidth ^ "x" ^ var.blockHeight ^ "mm"

; Probe from +X direction (approach from right side)
echo "G6503: Probing from +X direction"
var xPlusStart = { var.centerX + var.xApproachDistance }
var xPlusTarget = { var.centerX + var.xProbeTarget }

; Move to approach position and down to probe depth
G6550 X{var.xPlusStart} Y{var.centerY}
var probeZ = { var.startZ - var.probeDepth }
G6550 Z{var.probeZ}

; Execute probe move toward block center
G6512 X{var.xPlusTarget} Y{var.centerY} Z{var.probeZ} F{var.feedRate} R{var.retries}
var xPlusEdge = { global.nxtLastProbeResult }

; Return to start height before moving to next position
G6550 Z{var.startZ}

; Probe from -X direction (approach from left side)
echo "G6503: Probing from -X direction"
var xMinusStart = { var.centerX - var.xApproachDistance }
var xMinusTarget = { var.centerX - var.xProbeTarget }

; Move to approach position and down to probe depth
G6550 X{var.xMinusStart} Y{var.centerY}
G6550 Z{var.probeZ}

; Execute probe move toward block center
G6512 X{var.xMinusTarget} Y{var.centerY} Z{var.probeZ} F{var.feedRate} R{var.retries}
var xMinusEdge = { global.nxtLastProbeResult }

; Return to start height before moving to next position
G6550 Z{var.startZ}

; Probe from +Y direction (approach from front)
echo "G6503: Probing from +Y direction"

; Calculate the X center from previous probes and use it for Y probes
var calculatedCenterX = { (var.xPlusEdge + var.xMinusEdge) / 2 }

var yPlusStart = { var.centerY + var.yApproachDistance }
var yPlusTarget = { var.centerY + var.yProbeTarget }

; Move to approach position using the calculated X center and down to probe depth
G6550 X{var.calculatedCenterX} Y{var.yPlusStart}
G6550 Z{var.probeZ}

; Execute probe move toward block center
G6512 X{var.calculatedCenterX} Y{var.yPlusTarget} Z{var.probeZ} F{var.feedRate} R{var.retries}
var yPlusEdge = { global.nxtLastProbeResult }

; Return to start height before moving to next position
G6550 Z{var.startZ}

; Probe from -Y direction (approach from back)
echo "G6503: Probing from -Y direction"
var yMinusStart = { var.centerY - var.yApproachDistance }
var yMinusTarget = { var.centerY - var.yProbeTarget }

; Move to approach position using the calculated X center and down to probe depth
G6550 X{var.calculatedCenterX} Y{var.yMinusStart}
G6550 Z{var.probeZ}

; Execute probe move toward block center
G6512 X{var.calculatedCenterX} Y{var.yMinusTarget} Z{var.probeZ} F{var.feedRate} R{var.retries}
var yMinusEdge = { global.nxtLastProbeResult }

; Return to start height
G6550 Z{var.startZ}

; Calculate final block center from all 4 probe points
var calculatedCenterY = { (var.yPlusEdge + var.yMinusEdge) / 2 }

; Calculate actual block dimensions
var actualWidth = { var.xPlusEdge - var.xMinusEdge }
var actualHeight = { var.yPlusEdge - var.yMinusEdge }

; Log results to probe results table
; Find the next available slot in the results table
var resultIndex = 0
while { iterations < #global.nxtProbeResults && (global.nxtProbeResults[iterations][0] != 0 || global.nxtProbeResults[iterations][1] != 0) }
    ; iterations auto-increments, we track the current index
    set var.resultIndex = { iterations + 1 }

; If table is full, use the last slot
if { var.resultIndex >= #global.nxtProbeResults }
    set var.resultIndex = { #global.nxtProbeResults - 1 }

; Initialize the result vector if needed
if { #global.nxtProbeResults[var.resultIndex] < 3 }
    set global.nxtProbeResults[var.resultIndex] = { vector(#move.axes + 1, 0.0) }

; Store the calculated center coordinates
set global.nxtProbeResults[var.resultIndex][0] = { var.calculatedCenterX }
set global.nxtProbeResults[var.resultIndex][1] = { var.calculatedCenterY }

; Move to calculated center
G6550 X{var.calculatedCenterX} Y{var.calculatedCenterY}

; Return to safe height
G27 Z1

echo "G6503: Rectangle block probe completed"
echo "G6503: Block center at X=" ^ var.calculatedCenterX ^ " Y=" ^ var.calculatedCenterY
echo "G6503: Measured dimensions: " ^ var.actualWidth ^ "x" ^ var.actualHeight ^ "mm"
echo "G6503: Result logged to table index " ^ var.resultIndex