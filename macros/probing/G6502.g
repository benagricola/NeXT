; G6502.g: RECTANGLE POCKET PROBE
;
; Probes all 4 edges of a rectangular pocket to find the center point.
; Uses single-axis probing for each edge and calculates the geometric center.
;
; USAGE: G6502 [F<speed>] [R<retries>] [W<width>] [H<height>] [L<depth>] [C<clearance>] [O<overtravel>]
;
; Parameters:
;   F: Optional speed override in mm/min
;   R: Number of retries for averaging per probe point
;   W: Approximate pocket width in X direction (default: 20mm)
;   H: Approximate pocket height in Y direction (default: 20mm)
;   L: Depth to move down into pocket before probing (default: 5mm)
;   C: Clearance distance from pocket edges (default: 5mm)
;   O: Overtravel distance beyond expected surfaces (default: 2mm)
;
; The pocket center coordinates are logged to nxtProbeResults table.

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and configured
if { !global.nxtFeatureTouchProbe }
    abort { "G6502: Touch probe feature not enabled" }

if { global.nxtTouchProbeID == null }
    abort { "G6502: Touch probe ID not configured" }

; Ensure we're using the touch probe
if { state.currentTool != global.nxtProbeToolID }
    abort { "G6502: Touch probe (T" ^ global.nxtProbeToolID ^ ") must be selected" }

; Set defaults
var feedRate = { exists(param.F) ? param.F : null }
var retries = { exists(param.R) ? param.R : null }
var pocketWidth = { exists(param.W) ? param.W : 20.0 }
var pocketHeight = { exists(param.H) ? param.H : 20.0 }
var probeDepth = { exists(param.L) ? param.L : 5.0 }
var clearance = { exists(param.C) ? param.C : 5.0 }
var overtravel = { exists(param.O) ? param.O : 2.0 }

echo "G6502: Starting rectangle pocket probe cycle"

; Get current position (should be approximately at pocket center)
M5000
var centerX = { global.nxtAbsPos[0] }
var centerY = { global.nxtAbsPos[1] }
var startZ = { global.nxtAbsPos[2] }

; Calculate probe distances (half dimension plus overtravel)
var xProbeDistance = { var.pocketWidth / 2 + var.overtravel }
var yProbeDistance = { var.pocketHeight / 2 + var.overtravel }

; Move down into the pocket before starting probes
var probeZ = { var.startZ - var.probeDepth }
G6550 Z{var.probeZ}

echo "G6502: Probing rectangular pocket " ^ var.pocketWidth ^ "x" ^ var.pocketHeight ^ "mm"

; Probe +X edge (right side of pocket)
echo "G6502: Probing +X edge"
var xPlusTarget = { var.centerX + var.xProbeDistance }
G6512 X{var.xPlusTarget} Y{var.centerY} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
var xPlusEdge = { global.nxtLastProbeResult }

; Move back to center for next probe
G6550 X{var.centerX}

; Probe -X edge (left side of pocket)
echo "G6502: Probing -X edge"
var xMinusTarget = { var.centerX - var.xProbeDistance }
G6512 X{var.xMinusTarget} Y{var.centerY} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
var xMinusEdge = { global.nxtLastProbeResult }

; Move back to center for next probe
G6550 X{var.centerX}

; Probe +Y edge (front of pocket)
echo "G6502: Probing +Y edge"
var yPlusTarget = { var.centerY + var.yProbeDistance }
G6512 X{var.centerX} Y{var.yPlusTarget} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
var yPlusEdge = { global.nxtLastProbeResult }

; Move back to center for next probe
G6550 Y{var.centerY}

; Probe -Y edge (back of pocket)
echo "G6502: Probing -Y edge"
var yMinusTarget = { var.centerY - var.yProbeDistance }
G6512 X{var.centerX} Y{var.yMinusTarget} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
var yMinusEdge = { global.nxtLastProbeResult }

; Calculate pocket center from the 4 probe points
var calculatedCenterX = { (var.xPlusEdge + var.xMinusEdge) / 2 }
var calculatedCenterY = { (var.yPlusEdge + var.yMinusEdge) / 2 }

; Calculate actual pocket dimensions
var actualWidth = { var.xPlusEdge - var.xMinusEdge }
var actualHeight = { var.yPlusEdge - var.yMinusEdge }

; Log results to probe results table
; Find the next available slot in the results table
var resultIndex = 0
while { var.resultIndex < #global.nxtProbeResults && 
        (global.nxtProbeResults[var.resultIndex][0] != 0 || global.nxtProbeResults[var.resultIndex][1] != 0) }
    set var.resultIndex = { var.resultIndex + 1 }

; If table is full, use the last slot
if { var.resultIndex >= #global.nxtProbeResults }
    set var.resultIndex = { #global.nxtProbeResults - 1 }

; Initialize the result vector if needed
if { #global.nxtProbeResults[var.resultIndex] < 3 }
    set global.nxtProbeResults[var.resultIndex] = { vector(3, 0.0) }

; Store the calculated center coordinates
set global.nxtProbeResults[var.resultIndex][0] = { var.calculatedCenterX }
set global.nxtProbeResults[var.resultIndex][1] = { var.calculatedCenterY }

; Move to calculated center
G6550 X{var.calculatedCenterX} Y{var.calculatedCenterY}

; Return to start height
G6550 Z{var.startZ}

echo "G6502: Rectangle pocket probe completed"
echo "G6502: Pocket center at X=" ^ var.calculatedCenterX ^ " Y=" ^ var.calculatedCenterY
echo "G6502: Measured dimensions: " ^ var.actualWidth ^ "x" ^ var.actualHeight ^ "mm"
echo "G6502: Result logged to table index " ^ var.resultIndex