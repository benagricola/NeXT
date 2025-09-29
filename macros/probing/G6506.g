; G6506.g: ROTATION PROBE
;
; Probes 2 points along a single surface to determine the rotation angle
; of that surface relative to the machine axes.
;
; USAGE: G6506 N<axis> [F<speed>] [R<retries>] [S<spacing>] [L<depth>] [O<overtravel>]
;
; Parameters:
;   N: Axis along which the surface runs (0 for X, 1 for Y) - REQUIRED
;   F: Optional speed override in mm/min
;   R: Number of retries for averaging per probe point
;   S: Spacing between the two probe points (default: 20mm)
;   L: Depth to move down before probing (default: 5mm)
;   O: Overtravel distance beyond expected surface (default: 2mm)
;
; The rotation angle and surface coordinates are logged to nxtProbeResults table.

; Make sure this file is not executed by the secondary motion system
if { !inputs[state.thisInput].active }
    M99

; Validate that touch probe feature is enabled and configured
if { !global.nxtFeatureTouchProbe }
    abort { "G6506: Touch probe feature not enabled" }

if { global.nxtTouchProbeID == null }
    abort { "G6506: Touch probe ID not configured" }

; Ensure we're using the touch probe
if { state.currentTool != global.nxtProbeToolID }
    abort { "G6506: Touch probe (T" ^ global.nxtProbeToolID ^ ") must be selected" }

; Validate axis parameter
if { !exists(param.N) || param.N == null }
    abort { "G6506: Axis parameter N is required (0 for X surface, 1 for Y surface)" }

if { param.N != 0 && param.N != 1 }
    abort { "G6506: Axis parameter N must be 0 (X surface) or 1 (Y surface)" }

; Set defaults
var surfaceAxis = { param.N }
var feedRate = { exists(param.F) ? param.F : null }
var retries = { exists(param.R) ? param.R : null }
var spacing = { exists(param.S) ? param.S : 20.0 }
var probeDepth = { exists(param.L) ? param.L : 5.0 }
var overtravel = { exists(param.O) ? param.O : 2.0 }

var surfaceName = { var.surfaceAxis == 0 ? "X" : "Y" }

echo "G6506: Starting rotation probe cycle for " ^ var.surfaceName ^ " surface"

; Get current position (should be approximately at midpoint of surface)
M5000
var centerX = { global.nxtAbsPos[0] }
var centerY = { global.nxtAbsPos[1] }
var startZ = { global.nxtAbsPos[2] }

; Calculate probe positions
var halfSpacing = { var.spacing / 2 }
var probeZ = { var.startZ - var.probeDepth }

echo "G6506: Probing " ^ var.surfaceName ^ " surface with " ^ var.spacing ^ "mm spacing"

if { var.surfaceAxis == 0 }
    ; Probing X surface (probe moves in Y direction, surface runs along X)
    ; The surface is perpendicular to Y axis, so we probe from different Y positions
    
    ; First probe point
    echo "G6506: Probing first point"
    var firstY = { var.centerY - var.halfSpacing }
    var probeTargetY = { var.centerY - var.halfSpacing - var.overtravel }
    
    ; Move to first probe position and down to probe depth
    G6550 X{var.centerX} Y{var.firstY}
    G6550 Z{var.probeZ}
    
    ; Execute probe move toward surface
    G6512 X{var.centerX} Y{var.probeTargetY} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
    var firstPoint = { global.nxtLastProbeResult }
    var firstX = { var.centerX }
    var firstY = { var.firstPoint }
    
    ; Return to start height
    G6550 Z{var.startZ}
    
    ; Second probe point
    echo "G6506: Probing second point"
    var secondY = { var.centerY + var.halfSpacing }
    var probeTargetY2 = { var.centerY + var.halfSpacing + var.overtravel }
    
    ; Move to second probe position and down to probe depth
    G6550 X{var.centerX} Y{var.secondY}
    G6550 Z{var.probeZ}
    
    ; Execute probe move toward surface
    G6512 X{var.centerX} Y{var.probeTargetY2} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
    var secondPoint = { global.nxtLastProbeResult }
    var secondX = { var.centerX }
    var secondY = { var.secondPoint }
    
    ; Calculate rotation angle (in degrees)
    var deltaY = { var.secondY - var.firstY }
    var deltaX = { var.spacing } ; Distance between probe positions along X
    var rotationRad = { atan2(var.deltaY, var.deltaX) }
    var rotationDeg = { var.rotationRad * 180 / pi }
    
else
    ; Probing Y surface (probe moves in X direction, surface runs along Y)
    ; The surface is perpendicular to X axis, so we probe from different X positions
    
    ; First probe point
    echo "G6506: Probing first point"
    var firstX = { var.centerX - var.halfSpacing }
    var probeTargetX = { var.centerX - var.halfSpacing - var.overtravel }
    
    ; Move to first probe position and down to probe depth
    G6550 X{var.firstX} Y{var.centerY}
    G6550 Z{var.probeZ}
    
    ; Execute probe move toward surface
    G6512 X{var.probeTargetX} Y{var.centerY} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
    var firstPoint = { global.nxtLastProbeResult }
    var firstX = { var.firstPoint }
    var firstY = { var.centerY }
    
    ; Return to start height
    G6550 Z{var.startZ}
    
    ; Second probe point
    echo "G6506: Probing second point"
    var secondX = { var.centerX + var.halfSpacing }
    var probeTargetX2 = { var.centerX + var.halfSpacing + var.overtravel }
    
    ; Move to second probe position and down to probe depth
    G6550 X{var.secondX} Y{var.centerY}
    G6550 Z{var.probeZ}
    
    ; Execute probe move toward surface
    G6512 X{var.probeTargetX2} Y{var.centerY} Z{var.probeZ} I{global.nxtTouchProbeID} F{var.feedRate} R{var.retries}
    var secondPoint = { global.nxtLastProbeResult }
    var secondX = { var.secondPoint }
    var secondY = { var.centerY }
    
    ; Calculate rotation angle (in degrees)
    var deltaX = { var.secondX - var.firstX }
    var deltaY = { var.spacing } ; Distance between probe positions along Y
    var rotationRad = { atan2(var.deltaX, var.deltaY) }
    var rotationDeg = { var.rotationRad * 180 / pi }

; Return to start height
G6550 Z{var.startZ}

; Calculate midpoint of the two probe points
var midpointX = { (var.firstX + var.secondX) / 2 }
var midpointY = { (var.firstY + var.secondY) / 2 }

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

; Store the midpoint coordinates and rotation in Z position (as degrees * 1000 for precision)
set global.nxtProbeResults[var.resultIndex][0] = { var.midpointX }
set global.nxtProbeResults[var.resultIndex][1] = { var.midpointY }
set global.nxtProbeResults[var.resultIndex][2] = { var.rotationDeg * 1000 }

; Move to calculated midpoint
G6550 X{var.midpointX} Y{var.midpointY}

; Return to safe height
G27 Z1

echo "G6506: Rotation probe completed"
echo "G6506: Surface midpoint at X=" ^ var.midpointX ^ " Y=" ^ var.midpointY
echo "G6506: Surface rotation: " ^ var.rotationDeg ^ " degrees"
echo "G6506: Result logged to table index " ^ var.resultIndex