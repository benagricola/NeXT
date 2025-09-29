; G6504.g: WEB PROBE (BLOCK IN X OR Y)
;
; Probes a protruding web feature in either X OR Y direction to find the center point.
; Uses single-axis probing from both sides and calculates the center along the specified axis.
;
; USAGE: G6504 N<axis> [F<speed>] [R<retries>] [W<width>] [L<depth>] [C<clearance>] [O<overtravel>]
;
; Parameters:
;   N: Axis to probe (0 for X, 1 for Y) - REQUIRED
;   F: Optional speed override in mm/min
;   R: Number of retries for averaging per probe point
;   W: Approximate web width along the specified axis (default: 10mm)
;   L: Depth to move down before probing (default: 5mm)
;   C: Clearance distance from web edges for approach (default: 5mm)
;   O: Overtravel distance beyond expected surfaces (default: 2mm)
;
; The web center coordinate is logged to nxtProbeResults table.

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and configured
if { !global.nxtFeatureTouchProbe }
    abort { "G6504: Touch probe feature not enabled" }

if { global.nxtTouchProbeID == null }
    abort { "G6504: Touch probe ID not configured" }

; Ensure we're using the touch probe
if { state.currentTool != global.nxtProbeToolID }
    abort { "G6504: Touch probe (T" ^ global.nxtProbeToolID ^ ") must be selected" }

; Validate axis parameter
if { !exists(param.N) || param.N == null }
    abort { "G6504: Axis parameter N is required (0 for X, 1 for Y)" }

if { param.N != 0 && param.N != 1 }
    abort { "G6504: Axis parameter N must be 0 (X) or 1 (Y)" }

; Set defaults
var probeAxis = { param.N }
var feedRate = { exists(param.F) ? param.F : null }
var retries = { exists(param.R) ? param.R : null }
var webWidth = { exists(param.W) ? param.W : 10.0 }
var probeDepth = { exists(param.L) ? param.L : 5.0 }
var clearance = { exists(param.C) ? param.C : 5.0 }
var overtravel = { exists(param.O) ? param.O : 2.0 }

var axisName = { var.probeAxis == 0 ? "X" : "Y" }

echo "G6504: Starting web probe cycle along " ^ var.axisName ^ " axis"

; Get current position (should be approximately at web center)
M5000
var centerX = { global.nxtAbsPos[0] }
var centerY = { global.nxtAbsPos[1] }
var startZ = { global.nxtAbsPos[2] }

; Calculate approach and probe distances
var approachDistance = { var.webWidth / 2 + var.clearance }
var probeTarget = { var.webWidth / 2 + var.overtravel }

echo "G6504: Probing web with width ~" ^ var.webWidth ^ "mm along " ^ var.axisName ^ " axis"

if { var.probeAxis == 0 }
    ; Probe X axis web
    ; Probe from +X direction (approach from right side)
    echo "G6504: Probing from +X direction"
    var xPlusStart = { var.centerX + var.approachDistance }
    var xPlusTarget = { var.centerX + var.probeTarget }

    ; Move to approach position and down to probe depth
    G6550 X{var.xPlusStart} Y{var.centerY}
    var probeZ = { var.startZ - var.probeDepth }
    G6550 Z{var.probeZ}

    ; Execute probe move toward web center
    G6512 X{var.xPlusTarget} Y{var.centerY} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
    var plusSurface = { global.nxtLastProbeResult }

    ; Return to start height before moving to next position
    G6550 Z{var.startZ}

    ; Probe from -X direction (approach from left side)
    echo "G6504: Probing from -X direction"
    var xMinusStart = { var.centerX - var.approachDistance }
    var xMinusTarget = { var.centerX - var.probeTarget }

    ; Move to approach position and down to probe depth
    G6550 X{var.xMinusStart} Y{var.centerY}
    G6550 Z{var.probeZ}

    ; Execute probe move toward web center
    G6512 X{var.xMinusTarget} Y{var.centerY} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
    var minusSurface = { global.nxtLastProbeResult }

    ; Return to start height
    G6550 Z{var.startZ}

    ; Calculate web center
    var calculatedCenter = { (var.plusSurface + var.minusSurface) / 2 }
    var actualWidth = { var.plusSurface - var.minusSurface }

    ; Store result in X position
    var resultX = { var.calculatedCenter }
    var resultY = { var.centerY }
else
    ; Probe Y axis web
    ; Probe from +Y direction (approach from front)
    echo "G6504: Probing from +Y direction"
    var yPlusStart = { var.centerY + var.approachDistance }
    var yPlusTarget = { var.centerY + var.probeTarget }

    ; Move to approach position and down to probe depth
    G6550 X{var.centerX} Y{var.yPlusStart}
    var probeZ = { var.startZ - var.probeDepth }
    G6550 Z{var.probeZ}

    ; Execute probe move toward web center
    G6512 X{var.centerX} Y{var.yPlusTarget} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
    var plusSurface = { global.nxtLastProbeResult }

    ; Return to start height before moving to next position
    G6550 Z{var.startZ}

    ; Probe from -Y direction (approach from back)
    echo "G6504: Probing from -Y direction"
    var yMinusStart = { var.centerY - var.approachDistance }
    var yMinusTarget = { var.centerY - var.probeTarget }

    ; Move to approach position and down to probe depth
    G6550 X{var.centerX} Y{var.yMinusStart}
    G6550 Z{var.probeZ}

    ; Execute probe move toward web center
    G6512 X{var.centerX} Y{var.yMinusTarget} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
    var minusSurface = { global.nxtLastProbeResult }

    ; Return to start height
    G6550 Z{var.startZ}

    ; Calculate web center
    var calculatedCenter = { (var.plusSurface + var.minusSurface) / 2 }
    var actualWidth = { var.plusSurface - var.minusSurface }

    ; Store result in Y position
    var resultX = { var.centerX }
    var resultY = { var.calculatedCenter }

; Log results to probe results table
; Find the next available slot in the results table
var resultIndex = 0
while { var.resultIndex < #global.nxtProbeResults && 
        global.nxtProbeResults[var.resultIndex][var.probeAxis] != 0 }
    set var.resultIndex = { var.resultIndex + 1 }

; If table is full, use the last slot
if { var.resultIndex >= #global.nxtProbeResults }
    set var.resultIndex = { #global.nxtProbeResults - 1 }

; Initialize the result vector if needed
if { #global.nxtProbeResults[var.resultIndex] < 3 }
    set global.nxtProbeResults[var.resultIndex] = { vector(#move.axes + 1, 0.0) }

; Store the calculated center coordinate
set global.nxtProbeResults[var.resultIndex][0] = { var.resultX }
set global.nxtProbeResults[var.resultIndex][1] = { var.resultY }

; Move to calculated center
G6550 X{var.resultX} Y{var.resultY}

; Return to safe height
G27 Z1

echo "G6504: Web probe completed"
echo "G6504: Web center along " ^ var.axisName ^ " axis: " ^ var.calculatedCenter
echo "G6504: Measured width: " ^ var.actualWidth ^ "mm"
echo "G6504: Result logged to table index " ^ var.resultIndex