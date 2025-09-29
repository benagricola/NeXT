; G6505.g: POCKET PROBE (X OR Y)
;
; Probes a pocket feature in either X OR Y direction to find the center point.
; Uses single-axis probing from inside the pocket and calculates the center along the specified axis.
;
; USAGE: G6505 N<axis> [F<speed>] [R<retries>] [W<width>] [L<depth>] [C<clearance>] [O<overtravel>]
;
; Parameters:
;   N: Axis to probe (0 for X, 1 for Y) - REQUIRED
;   F: Optional speed override in mm/min
;   R: Number of retries for averaging per probe point
;   W: Approximate pocket width along the specified axis (default: 10mm)
;   L: Depth to move down into pocket before probing (default: 5mm)
;   C: Clearance distance from pocket edges (default: 2mm)
;   O: Overtravel distance beyond expected surfaces (default: 2mm)
;
; The pocket center coordinate is logged to nxtProbeResults table.

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and configured
if { !global.nxtFeatureTouchProbe }
    abort { "G6505: Touch probe feature not enabled" }

if { global.nxtTouchProbeID == null }
    abort { "G6505: Touch probe ID not configured" }

; Ensure we're using the touch probe
if { state.currentTool != global.nxtProbeToolID }
    abort { "G6505: Touch probe (T" ^ global.nxtProbeToolID ^ ") must be selected" }

; Validate axis parameter
if { !exists(param.N) || param.N == null }
    abort { "G6505: Axis parameter N is required (0 for X, 1 for Y)" }

if { param.N != 0 && param.N != 1 }
    abort { "G6505: Axis parameter N must be 0 (X) or 1 (Y)" }

; Set defaults
var probeAxis = { param.N }
var feedRate = { exists(param.F) ? param.F : null }
var retries = { exists(param.R) ? param.R : null }
var pocketWidth = { exists(param.W) ? param.W : 10.0 }
var probeDepth = { exists(param.L) ? param.L : 5.0 }
var clearance = { exists(param.C) ? param.C : 2.0 }
var overtravel = { exists(param.O) ? param.O : 2.0 }

var axisName = { var.probeAxis == 0 ? "X" : "Y" }

echo "G6505: Starting pocket probe cycle along " ^ var.axisName ^ " axis"

; Get current position (should be approximately at pocket center)
M5000
var centerX = { global.nxtAbsPos[0] }
var centerY = { global.nxtAbsPos[1] }
var startZ = { global.nxtAbsPos[2] }

; Calculate probe distances (half width plus overtravel)
var probeDistance = { var.pocketWidth / 2 + var.overtravel }

; Move down into the pocket before starting probes
var probeZ = { var.startZ - var.probeDepth }
G6550 Z{var.probeZ}

echo "G6505: Probing pocket with width ~" ^ var.pocketWidth ^ "mm along " ^ var.axisName ^ " axis"

if { var.probeAxis == 0 }
    ; Probe X axis pocket
    ; Probe +X edge (right side of pocket)
    echo "G6505: Probing +X edge"
    var xPlusTarget = { var.centerX + var.probeDistance }
    G6512 X{var.xPlusTarget} Y{var.centerY} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
    var plusEdge = { global.nxtLastProbeResult }

    ; Move back to center for next probe
    G6550 X{var.centerX}

    ; Probe -X edge (left side of pocket)
    echo "G6505: Probing -X edge"
    var xMinusTarget = { var.centerX - var.probeDistance }
    G6512 X{var.xMinusTarget} Y{var.centerY} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
    var minusEdge = { global.nxtLastProbeResult }

    ; Move back to center
    G6550 X{var.centerX}

    ; Calculate pocket center
    var calculatedCenter = { (var.plusEdge + var.minusEdge) / 2 }
    var actualWidth = { var.plusEdge - var.minusEdge }

    ; Store result in X position
    var resultX = { var.calculatedCenter }
    var resultY = { var.centerY }
else
    ; Probe Y axis pocket
    ; Probe +Y edge (front of pocket)
    echo "G6505: Probing +Y edge"
    var yPlusTarget = { var.centerY + var.probeDistance }
    G6512 X{var.centerX} Y{var.yPlusTarget} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
    var plusEdge = { global.nxtLastProbeResult }

    ; Move back to center for next probe
    G6550 Y{var.centerY}

    ; Probe -Y edge (back of pocket)
    echo "G6505: Probing -Y edge"
    var yMinusTarget = { var.centerY - var.probeDistance }
    G6512 X{var.centerX} Y{var.yMinusTarget} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
    var minusEdge = { global.nxtLastProbeResult }

    ; Move back to center
    G6550 Y{var.centerY}

    ; Calculate pocket center
    var calculatedCenter = { (var.plusEdge + var.minusEdge) / 2 }
    var actualWidth = { var.plusEdge - var.minusEdge }

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
    set global.nxtProbeResults[var.resultIndex] = { vector(3, 0.0) }

; Store the calculated center coordinate
set global.nxtProbeResults[var.resultIndex][0] = { var.resultX }
set global.nxtProbeResults[var.resultIndex][1] = { var.resultY }

; Move to calculated center
G6550 X{var.resultX} Y{var.resultY}

; Return to start height
G6550 Z{var.startZ}

echo "G6505: Pocket probe completed"
echo "G6505: Pocket center along " ^ var.axisName ^ " axis: " ^ var.calculatedCenter
echo "G6505: Measured width: " ^ var.actualWidth ^ "mm"
echo "G6505: Result logged to table index " ^ var.resultIndex