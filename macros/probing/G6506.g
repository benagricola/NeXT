; G6506.g: ROTATION PROBE
;
; Probes 2 points along a single surface to determine the rotation angle
; of that surface relative to the machine axes.
;
; USAGE: G6506 P<index> N<axis> D<direction> S<spacing> L<depth> [F<speed>] [R<retries>] [O<overtravel>]
;
; Parameters:
;   P: Result table index (0-based) where results will be stored - REQUIRED
;   N: Axis along which the surface runs (0 for X, 1 for Y) - REQUIRED
;   D: Direction to probe (0 for negative, 1 for positive) - REQUIRED  
;   S: Spacing between the two probe points - REQUIRED
;   L: Depth to move down before probing - REQUIRED
;   F: Optional speed override in mm/min
;   R: Number of retries for averaging per probe point
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

; Validate required parameters
if { !exists(param.P) || param.P == null || param.P < 0 }
    abort { "G6506: Result index parameter P is required and must be >= 0" }

if { param.P >= #global.nxtProbeResults }
    abort { "G6506: Result index P=" ^ param.P ^ " exceeds table size (" ^ #global.nxtProbeResults ^ ")" }

if { !exists(param.N) || !exists(param.D) || !exists(param.S) || !exists(param.L) }
    abort { "G6506: Axis (N), Direction (D), Spacing (S), and Depth (L) parameters are required" }

if { param.N != 0 && param.N != 1 }
    abort { "G6506: Axis parameter N must be 0 (X surface) or 1 (Y surface)" }

if { param.D != 0 && param.D != 1 }
    abort { "G6506: Direction parameter D must be 0 (negative) or 1 (positive)" }

; Set parameters
var surfaceAxis = { param.N }
var direction = { param.D }
var feedRate = { exists(param.F) ? param.F : null }
var retries = { exists(param.R) ? param.R : null }
var spacing = { param.S }
var probeDepth = { param.L }
var overtravel = { exists(param.O) ? param.O : 2.0 }

var surfaceName = { var.surfaceAxis == 0 ? "X" : "Y" }
var directionName = { var.direction == 0 ? "negative" : "positive" }

echo "G6506: Starting rotation probe cycle for " ^ var.surfaceName ^ " surface in " ^ var.directionName ^ " direction"

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
    G6512 X{var.centerX} Y{var.probeTargetY} Z{var.probeZ} F{var.feedRate} R{var.retries}
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
    G6512 X{var.centerX} Y{var.probeTargetY2} Z{var.probeZ} F{var.feedRate} R{var.retries}
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
    G6512 X{var.probeTargetX} Y{var.centerY} Z{var.probeZ} F{var.feedRate} R{var.retries}
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
    G6512 X{var.probeTargetX2} Y{var.centerY} Z{var.probeZ} F{var.feedRate} R{var.retries}
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

; Rotation probe complete - coordinates not needed, only rotation angle matters

; Log results to probe results table
; Use the specified result index directly
var resultIndex = { param.P }

; Initialize the result vector if needed (should already be done by nxt-boot.g)
var resultVectorSize = { #move.axes + 1 }
if { #global.nxtProbeResults[var.resultIndex] != var.resultVectorSize }
    set global.nxtProbeResults[var.resultIndex] = { vector(var.resultVectorSize, 0.0) }

; Store only rotation angle in dedicated rotation slot (last position)
set global.nxtProbeResults[var.resultIndex][#move.axes] = { var.rotationDeg }

; Return to safe height
G27 Z1

echo "G6506: Rotation probe completed"
echo "G6506: Surface midpoint at X=" ^ var.midpointX ^ " Y=" ^ var.midpointY
echo "G6506: Surface rotation: " ^ var.rotationDeg ^ " degrees"
echo "G6506: Result logged to table index " ^ var.resultIndex