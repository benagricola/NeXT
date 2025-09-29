; G6500.g: BORE PROBE (CIRCULAR BORE)
;
; Probes a circular bore by probing in 4 directions (±X, ±Y) to find the center.
; This implements single-axis probing principles - each probe move is along one axis only.
;
; USAGE: G6500 [F<speed>] [R<retries>] [D<diameter>] [O<overtravel>] [L<depth>]
;
; Parameters:
;   F: Optional speed override in mm/min
;   R: Number of retries for averaging per probe point
;   D: Approximate bore diameter for move planning (default: 10mm)
;   O: Overtravel distance beyond expected surface (default: 2mm)
;   L: Depth to move down into bore before probing (default: 5mm)
;
; The bore center coordinates are logged to nxtProbeResults table.

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and configured
if { !global.nxtFeatureTouchProbe }
    abort { "G6500: Touch probe feature not enabled" }

if { global.nxtTouchProbeID == null }
    abort { "G6500: Touch probe ID not configured" }

; Ensure we're using the touch probe
if { state.currentTool != global.nxtProbeToolID }
    abort { "G6500: Touch probe (T" ^ global.nxtProbeToolID ^ ") must be selected" }

; Set defaults
var feedRate = { exists(param.F) ? param.F : null }
var retries = { exists(param.R) ? param.R : null }
var boreDiameter = { exists(param.D) ? param.D : 10.0 }
var overtravel = { exists(param.O) ? param.O : 2.0 }
var probeDepth = { exists(param.L) ? param.L : 5.0 }

; Park in Z before starting
G27 Z1

echo "G6500: Starting bore probe cycle"

; Get current position (should be approximately at bore center)
M5000
var centerX = { global.nxtAbsPos[0] }
var centerY = { global.nxtAbsPos[1] }
var startZ = { global.nxtAbsPos[2] }

; Move down into the bore before starting probes
var probeZ = { var.startZ - var.probeDepth }
G6550 Z{var.probeZ}

; Calculate probe distances (half diameter plus overtravel)
var probeDistance = { var.boreDiameter / 2 + var.overtravel }

echo "G6500: Probing bore with diameter ~" ^ var.boreDiameter ^ "mm"

; Probe +X direction (right side of bore)
echo "G6500: Probing +X surface"
var xPlusTarget = { var.centerX + var.probeDistance }

G6512 X{var.xPlusTarget} Y{var.centerY} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
var xPlusSurface = { global.nxtLastProbeResult }

; Move back to center for next probe
G6550 X{var.centerX}

; Probe -X direction (left side of bore)
echo "G6500: Probing -X surface"
var xMinusTarget = { var.centerX - var.probeDistance }

G6512 X{var.xMinusTarget} Y{var.centerY} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
var xMinusSurface = { global.nxtLastProbeResult }

; Move back to center for next probe
G6550 X{var.centerX}

; Probe +Y direction (front of bore)
echo "G6500: Probing +Y surface"
var yPlusTarget = { var.centerY + var.probeDistance }

G6512 X{var.centerX} Y{var.yPlusTarget} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
var yPlusSurface = { global.nxtLastProbeResult }

; Move back to center for next probe
G6550 Y{var.centerY}

; Probe -Y direction (back of bore)
echo "G6500: Probing -Y surface"
var yMinusTarget = { var.centerY - var.probeDistance }

G6512 X{var.centerX} Y{var.yMinusTarget} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
var yMinusSurface = { global.nxtLastProbeResult }

; Calculate bore center from the 4 probe points
var calculatedCenterX = { (var.xPlusSurface + var.xMinusSurface) / 2 }
var calculatedCenterY = { (var.yPlusSurface + var.yMinusSurface) / 2 }

; Calculate actual bore diameter
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
G6550 X{var.calculatedCenterX} Y{var.calculatedCenterY}

; Return to safe height
G6550 Z{var.startZ}

echo "G6500: Bore probe completed"
echo "G6500: Bore center at X=" ^ var.calculatedCenterX ^ " Y=" ^ var.calculatedCenterY
echo "G6500: Measured diameter: X=" ^ var.actualDiameterX ^ " Y=" ^ var.actualDiameterY ^ " (avg=" ^ var.avgDiameter ^ ")"
echo "G6500: Result logged to table index " ^ var.resultIndex