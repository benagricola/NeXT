; G6501.g: BOSS PROBE (CIRCULAR BOSS)
;
; Probes a circular boss by probing from outside in 4 directions (±X, ±Y) to find the center.
; This implements single-axis probing principles - each probe move is along one axis only.
;
; USAGE: G6501 [F<speed>] [R<retries>] [D<diameter>] [C<clearance>]
;
; Parameters:
;   F: Optional speed override in mm/min
;   R: Number of retries for averaging per probe point
;   D: Approximate boss diameter for move planning (default: 10mm)
;   C: Clearance distance from boss edge for starting position (default: 5mm)
;
; The boss center coordinates are logged to nxtProbeResults table.

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and configured
if { !global.nxtFeatureTouchProbe }
    abort { "G6501: Touch probe feature not enabled" }

if { global.nxtTouchProbeID == null }
    abort { "G6501: Touch probe ID not configured" }

; Ensure we're using the touch probe
if { state.currentTool != global.nxtProbeToolID }
    abort { "G6501: Touch probe (T" ^ global.nxtProbeToolID ^ ") must be selected" }

; Set defaults
var feedRate = { exists(param.F) ? param.F : null }
var retries = { exists(param.R) ? param.R : null }
var bossDiameter = { exists(param.D) ? param.D : 10.0 }
var clearance = { exists(param.C) ? param.C : 5.0 }

; Park in Z before starting
G27 Z1

echo "G6501: Starting boss probe cycle"

; Get current position (should be approximately at boss center)
M5000
var centerX = { global.nxtAbsPos[0] }
var centerY = { global.nxtAbsPos[1] }

; Calculate approach distances (half diameter plus clearance)
var approachDistance = { var.bossDiameter / 2 + var.clearance }
var probeTarget = { var.bossDiameter / 2 - 1 } ; Probe to 1mm inside expected edge

echo "G6501: Probing boss with diameter ~" ^ var.bossDiameter ^ "mm"

; Probe from +X direction (approach from right side)
echo "G6501: Probing from +X direction"
var xPlusStart = { var.centerX + var.approachDistance }
var xPlusTarget = { var.centerX + var.probeTarget }

; Move to approach position
G6550 X{var.xPlusStart} Y{var.centerY} I{global.nxtTouchProbeID}

; Execute probe move toward boss center
if { var.feedRate != null && var.retries != null }
    G6512 X{var.xPlusTarget} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
elif { var.feedRate != null }
    G6512 X{var.xPlusTarget} I{global.nxtTouchProbeID} F{var.feedRate}
elif { var.retries != null }
    G6512 X{var.xPlusTarget} I{global.nxtTouchProbeID} R{var.retries}
else
    G6512 X{var.xPlusTarget} I{global.nxtTouchProbeID}

var xPlusSurface = { global.nxtLastProbeResult }

; Probe from -X direction (approach from left side)
echo "G6501: Probing from -X direction"
var xMinusStart = { var.centerX - var.approachDistance }
var xMinusTarget = { var.centerX - var.probeTarget }

; Move to approach position
G6550 X{var.xMinusStart} Y{var.centerY} I{global.nxtTouchProbeID}

; Execute probe move toward boss center
if { var.feedRate != null && var.retries != null }
    G6512 X{var.xMinusTarget} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
elif { var.feedRate != null }
    G6512 X{var.xMinusTarget} I{global.nxtTouchProbeID} F{var.feedRate}
elif { var.retries != null }
    G6512 X{var.xMinusTarget} I{global.nxtTouchProbeID} R{var.retries}
else
    G6512 X{var.xMinusTarget} I{global.nxtTouchProbeID}

var xMinusSurface = { global.nxtLastProbeResult }

; Probe from +Y direction (approach from front)
echo "G6501: Probing from +Y direction"
var yPlusStart = { var.centerY + var.approachDistance }
var yPlusTarget = { var.centerY + var.probeTarget }

; Move to approach position
G6550 X{var.centerX} Y{var.yPlusStart} I{global.nxtTouchProbeID}

; Execute probe move toward boss center
if { var.feedRate != null && var.retries != null }
    G6512 Y{var.yPlusTarget} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
elif { var.feedRate != null }
    G6512 Y{var.yPlusTarget} I{global.nxtTouchProbeID} F{var.feedRate}
elif { var.retries != null }
    G6512 Y{var.yPlusTarget} I{global.nxtTouchProbeID} R{var.retries}
else
    G6512 Y{var.yPlusTarget} I{global.nxtTouchProbeID}

var yPlusSurface = { global.nxtLastProbeResult }

; Probe from -Y direction (approach from back)
echo "G6501: Probing from -Y direction"
var yMinusStart = { var.centerY - var.approachDistance }
var yMinusTarget = { var.centerY - var.probeTarget }

; Move to approach position
G6550 X{var.centerX} Y{var.yMinusStart} I{global.nxtTouchProbeID}

; Execute probe move toward boss center
if { var.feedRate != null && var.retries != null }
    G6512 Y{var.yMinusTarget} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
elif { var.feedRate != null }
    G6512 Y{var.yMinusTarget} I{global.nxtTouchProbeID} F{var.feedRate}
elif { var.retries != null }
    G6512 Y{var.yMinusTarget} I{global.nxtTouchProbeID} R{var.retries}
else
    G6512 Y{var.yMinusTarget} I{global.nxtTouchProbeID}

var yMinusSurface = { global.nxtLastProbeResult }

; Calculate boss center from the 4 probe points
var calculatedCenterX = { (var.xPlusSurface + var.xMinusSurface) / 2 }
var calculatedCenterY = { (var.yPlusSurface + var.yMinusSurface) / 2 }

; Calculate actual boss diameter
var actualDiameterX = { var.xPlusSurface - var.xMinusSurface }
var actualDiameterY = { var.yPlusSurface - var.yMinusSurface }
var avgDiameter = { (var.actualDiameterX + var.actualDiameterY) / 2 }

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
G6550 X{var.calculatedCenterX} Y{var.calculatedCenterY} I{global.nxtTouchProbeID}

; Return to safe height
G27 Z1

echo "G6501: Boss probe completed"
echo "G6501: Boss center at X=" ^ var.calculatedCenterX ^ " Y=" ^ var.calculatedCenterY
echo "G6501: Measured diameter: X=" ^ var.actualDiameterX ^ " Y=" ^ var.actualDiameterY ^ " (avg=" ^ var.avgDiameter ^ ")"
echo "G6501: Result logged to table index " ^ var.resultIndex