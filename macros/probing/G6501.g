; G6501.g: BOSS PROBE (CIRCULAR BOSS)
;
; Probes a circular boss by probing from outside in 4 directions (±X, ±Y) to find the center.
; This implements single-axis probing principles - each probe move is along one axis only.
;
; USAGE: G6501 P<index> D<diameter> L<depth> [F<speed>] [R<retries>] [C<clearance>] [O<overtravel>]
;
; Parameters:
;   P: Result table index (0-based) where results will be stored - REQUIRED
;   D: Boss diameter for move planning - REQUIRED
;   L: Depth to move down before probing - REQUIRED
;   F: Optional speed override in mm/min
;   R: Number of retries for averaging per probe point
;   C: Clearance distance from boss edge for starting position (default: 5mm)
;   O: Overtravel distance beyond expected surface for probe moves (default: 2mm)
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

; Validate required parameters
if { !exists(param.P) || param.P == null || param.P < 0 }
    abort { "G6501: Result index parameter P is required and must be >= 0" }

if { param.P >= #global.nxtProbeResults }
    abort { "G6501: Result index P=" ^ param.P ^ " exceeds table size (" ^ #global.nxtProbeResults ^ ")" }

if { !exists(param.D) || param.D == null || param.D <= 0 }
    abort { "G6501: Diameter parameter D is required and must be positive" }

if { !exists(param.L) || param.L == null || param.L <= 0 }
    abort { "G6501: Depth parameter L is required and must be positive" }

; Set defaults for optional parameters
var feedRate = { exists(param.F) ? param.F : null }
var retries = { exists(param.R) ? param.R : null }
var bossDiameter = { param.D }
var clearance = { exists(param.C) ? param.C : 5.0 }
var overtravel = { exists(param.O) ? param.O : 2.0 }
var probeDepth = { param.L }

echo "G6501: Starting boss probe cycle"

; Get current position (should be approximately at boss center)
M5000
var centerX = { global.nxtAbsPos[0] }
var centerY = { global.nxtAbsPos[1] }
var startZ = { global.nxtAbsPos[2] }

; Calculate approach distances (half diameter plus clearance)
var approachDistance = { var.bossDiameter / 2 + var.clearance }
var probeTarget = { var.bossDiameter / 2 + var.overtravel } ; Probe beyond expected edge

echo "G6501: Probing boss with diameter ~" ^ var.bossDiameter ^ "mm"

; Probe from +X direction (approach from right side)
echo "G6501: Probing from +X direction"
var xPlusStart = { var.centerX + var.approachDistance }
var xPlusTarget = { var.centerX + var.probeTarget }

; Move to approach position and down to probe depth
G6550 X{var.xPlusStart} Y{var.centerY}
var probeZ = { var.startZ - var.probeDepth }
G6550 Z{var.probeZ}

; Execute probe move toward boss center
G6512 X{xPlusTarget} Y{var.centerY} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
var xPlusSurface = { global.nxtLastProbeResult }

; Return to start height before moving to next position
G6550 Z{var.startZ}

; Probe from -X direction (approach from left side)
echo "G6501: Probing from -X direction"
var xMinusStart = { var.centerX - var.approachDistance }
var xMinusTarget = { var.centerX - var.probeTarget }

; Move to approach position and down to probe depth
G6550 X{var.xMinusStart} Y{var.centerY}
G6550 Z{var.probeZ}

; Execute probe move toward boss center
G6512 X{var.xMinusTarget} Y{var.centerY} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
var xMinusSurface = { global.nxtLastProbeResult }

; Return to start height before moving to next position
G6550 Z{var.startZ}

; Probe from +Y direction (approach from front)
echo "G6501: Probing from +Y direction"
var yPlusStart = { var.centerY + var.approachDistance }
var yPlusTarget = { var.centerY + var.probeTarget }

; Move to approach position and down to probe depth
G6550 X{var.centerX} Y{var.yPlusStart}
G6550 Z{var.probeZ}

; Execute probe move toward boss center
G6512 X{var.centerX} Y{var.yPlusTarget} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
var yPlusSurface = { global.nxtLastProbeResult }

; Return to start height before moving to next position
G6550 Z{var.startZ}

; Probe from -Y direction (approach from back)
echo "G6501: Probing from -Y direction"
var yMinusStart = { var.centerY - var.approachDistance }
var yMinusTarget = { var.centerY - var.probeTarget }

; Move to approach position and down to probe depth
G6550 X{var.centerX} Y{var.yMinusStart}
G6550 Z{var.probeZ}

; Execute probe move toward boss center
G6512 X{var.centerX} Y{var.yMinusTarget} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
var yMinusSurface = { global.nxtLastProbeResult }

; Return to start height
G6550 Z{var.startZ}

; Calculate boss center from the 4 probe points
var calculatedCenterX = { (var.xPlusSurface + var.xMinusSurface) / 2 }
var calculatedCenterY = { (var.yPlusSurface + var.yMinusSurface) / 2 }

; Calculate actual boss diameter
var actualDiameterX = { var.xPlusSurface - var.xMinusSurface }
var actualDiameterY = { var.yPlusSurface - var.yMinusSurface }
var avgDiameter = { (var.actualDiameterX + var.actualDiameterY) / 2 }

; Log results to probe results table
; Use the specified result index directly
var resultIndex = { param.P }

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

echo "G6501: Boss probe completed"
echo "G6501: Boss center at X=" ^ var.calculatedCenterX ^ " Y=" ^ var.calculatedCenterY
echo "G6501: Measured diameter: X=" ^ var.actualDiameterX ^ " Y=" ^ var.actualDiameterY ^ " (avg=" ^ var.avgDiameter ^ ")"
echo "G6501: Result logged to table index " ^ var.resultIndex